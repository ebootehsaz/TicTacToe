//  Created by Ethan Bootehsaz on 7/27/22.
//
// This will be auto matchmaking button
//import Foundation

import SwiftUI
import Combine

import Firebase
import FirebaseFirestoreSwift


class joinOnlineGame: UIViewController {
    
    @AppStorage("user") private var userData: Data?
    
    @AppStorage("isDarkMode") private var isDark: Bool?
    
    var hasGameStarted = false
    
    @Published var Listener: ListenerRegistration!
    
//    var isUpdateToGame: Bool = onlineCreatedGame.shared.updatePending
    
//    @Published var enteredId: String = ""
    
    //optional because don't want crash if empty or nil obj
    @Published var game: Game!
    
    @Published var prevGame: Game!
    
    @IBOutlet weak var stackView: UIStackView!
  
    @Published var board = [UIButton]()
    
    
    @Published var currentUser: User!
    
    
    private var cancellables: Set<AnyCancellable> = []
    
    
    
    
    @IBOutlet weak var xPlayer: UILabel!
    @IBOutlet weak var oPlayer: UILabel!
    
    @IBOutlet weak var xWinDisplay: UIButton!
    @IBOutlet weak var oWinDisplay: UIButton!
    
    @IBOutlet weak var player1Name: UIButton!
    @IBOutlet weak var player2Name: UIButton!
    
    @IBOutlet weak var waitingLabel: UIButton!
    
    @IBAction func addAFriend(_ sender: UIButton) {
        guard self.game != nil else { return  }
            
            if self.currentUser.id == self.game.player1Id {
                if self.game.player2Id != "" && self.game.player2Name != "" {
                    if checkIfFriends(self.game.player2Id) {
                        sender.setTitle(" Already Friends!", for: .normal)
                        sender.isEnabled = false
                        sender.setImage(UIImage(systemName: "person.crop.circle.badge.checkmark") , for: .normal)
                        return
                    }
                    
                    //add friend
                    self.currentUser.addUserFriend(self.game.player2Name, self.game.player2Id)
                    
                    // save data
                    do {
                        let data = try JSONEncoder().encode(self.currentUser)
                        self.userData = data
                    } catch {
                        print("Couldn't save user object")
                    }
                    
                    //change button
                    sender.setTitle("Added!", for: .normal)
                    sender.isEnabled = false
                    sender.setImage(UIImage(systemName: "person.crop.circle.badge.checkmark") , for: .normal)
                    
                }
            } else {
                if self.game.player1Id != "" && self.game.player1Name != "" {
                    if checkIfFriends(self.game.player1Id) {
                        sender.setTitle(" Already Friends!", for: .normal)
                        sender.isEnabled = false
                        sender.setImage(UIImage(systemName: "person.crop.circle.badge.checkmark") , for: .normal)
                        return
                    }
                    //add friend
                    self.currentUser.addUserFriend(self.game.player1Name, self.game.player1Id)
                    
                    //save user data
                    do {
                        let data = try JSONEncoder().encode(self.currentUser)
                        self.userData = data
                    } catch {
                        print("Couldn't save user object")
                    }
                    
                    //change button
                    sender.setTitle("Added!", for: .normal)
                    sender.isEnabled = false
                    sender.setImage(UIImage(systemName: "person.crop.circle.badge.checkmark") , for: .normal)
                }
            }
    }
    
    
    func checkIfFriends(_ friendId: String) -> Bool{
        let myFriends = self.currentUser.friends
        for friend in myFriends {
            print("Friend, ", friend[0])
            if friend[1] == friendId {
                return true
            }
        }
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBoard()
        getColorScheme()
        initOnlineVC() // identifies current user
        
        let potentialId = UIPasteboard.general.string
        
        if 8 == potentialId?.count {
            startGame(with: self.currentUser.id, with: potentialId ?? "")
        } else {
            startGame(with: self.currentUser.id, with: "")
        }
        
    }
    
    func getColorScheme() {
        guard let isDark = isDark else { return }
        overrideUserInterfaceStyle = isDark ? .dark : .light
    }
    
    
    
    
    func initOnlineVC() {
        retrieveUser()
        
        if currentUser == nil {
//            saveUser()
        }
        
    }
    
    
    
    func createOnlineGame() {
        //save game online
        
        do {
            try FirebaseReference(.Game).document(self.game.id).setData(from: self.game)
            print("Game is online")
        } catch {
            print("Error creating online game", error.localizedDescription)
        }
        
    }
    
    func startGame(with userId: String, with gameId: String) {
        print("168")
        FirebaseReference(.Game).whereField("player2Id", isEqualTo: "").whereField("id", isEqualTo:  gameId).getDocuments { querySnapshot, error in
            print("FirebaseService Line 91")
        
            if error != nil {
                print("Error joining with given gameId")
                self.waitingLabel.setTitle("Unable to join game", for: .normal)
                return
            }
            
            if let gameData = querySnapshot?.documents.first {
                
                self.game = try? gameData.data(as: Game.self)
                self.game.player2Id = userId
                self.game.player2Name = self.currentUser.name
                
                self.game.blockMoveForPlayerId = userId // ** // this might get messy here
                self.updateGame(self.game)
                print("Player2joinedGame")      // i am player 2
                self.checkForPrevGame(with: userId) // maybe move this up before updating player 2 id
            }
            else { // gameId was not given or is wrong
                // check for game where player 2 is empty and player 1 is not myself
                print("118")
                FirebaseReference(.Game).whereField("player2Id", isEqualTo: "").whereField("player1Id", isNotEqualTo: userId).getDocuments { querySnapshot, error in
                    print("FirebaseService Line 120")
                    
                    if error != nil {
                        print("Error starting game 123")
                        return
                    }
                                            //array of documents
                    if let gameData = querySnapshot?.documents.first {
                        print("FirebaseService Line 120 ** Game found")
                        
                        self.game = try? gameData.data(as: Game.self)
                        self.game.player2Id = userId // locally i am player 2
                        self.game.player2Name = self.currentUser.name
                        
                        self.game.blockMoveForPlayerId = userId // ** // this might get messy here
                        print("132")
                        self.checkForPrevGame(with: userId)
                        print("134")
                        
                        //update game and listen for game changes in check for prev game func
                    }
                    else {
                        // create new game?
                        print("146 ** ** \nunable to join game try again")
                        self.waitingLabel.setTitle(" Unable To Join Game ", for: .normal)
                        
                    }
                }
            }
        }
        print("line 227")
    }
    
    
    
    func checkForPrevGame(with userId: String, _ deleteCurrGame: Bool = false) {
        
        // I am now player 2 in a game, have I and this player played a game before?
        // ** where I was player 2
        self.waitingLabel.setTitle("...Loading Game...", for: .normal)
        print("checkprev Line 168")
        FirebaseReference(.Game).whereField("player2Id", isEqualTo: self.currentUser.id).whereField("player1Id", isEqualTo: self.game.player1Id).whereField("id", isNotEqualTo: self.game.id).getDocuments { querySnapshot, error in
                print("FirebaseService Line 170")
            
            if error != nil {
                print("Error joing game, line 173 ")
//                self.createNewGame(with: userId)
                return
            }
            
            if let prevGameData = querySnapshot?.documents.first {
               
                self.prevGame = try? prevGameData.data(as: Game.self)
                
                // have to block game for myself, I am "O", and i gotta wait for x
                self.prevGame.blockMoveForPlayerId = userId // **
                // ^^^
                // i was player 2 in our previous game
                print("I joined a prev game where i was player 2, 185")
//                self.oPlayer.isHighlighted = true
//                self.oPlayer.highlightedTextColor = UIColor(red:0.0, green:0.55, blue:0.15, alpha:1.0)
                
                self.game.prevGameId = self.prevGame.id
                print("**********1********")
                self.updateGame(self.game)
                print("**********2********")
                self.hasGameStarted = true
                
                self.game = self.prevGame
                
                if self.game.player2Name != self.currentUser.name {
                    self.game.player2Name = self.currentUser.name // user has changed names
                }
                
                self.updatePlayerLabels()
                
                print("I am player 2")
                self.oPlayer.isHighlighted = true
                self.oPlayer.highlightedTextColor = UIColor(red:0.0, green:0.55, blue:0.15, alpha:1.0)
                
                self.crossesScore = self.game.player1Score
                self.noughtsScore = self.game.player2Score
                
                self.updateScore()
                
                self.waitingLabel.setTitle("...Opponents Move...", for: .normal)
                
                self.listenForGameChanges()
                
                return
                
            }
            
            else {
                // have we played a game before where I was player1 ?
                print("checkprev Line 204")
                FirebaseReference(.Game).whereField("player2Id", isEqualTo: self.game.player1Id).whereField("player1Id", isEqualTo: self.currentUser.id).whereField("id", isNotEqualTo: self.game.id).getDocuments { querySnapshot, error in
                        print("FirebaseService Line 206")
        
                    if error != nil {
                        print("Error joing game, line 209")
//                        self.createNewGame(with: userId)
                        return
                    }
                    
                    if let prevGameData = querySnapshot?.documents.first {
                        // we have, I was player1 and other was player 2
                        print("We have, line 214")
                        
                        self.prevGame = try? prevGameData.data(as: Game.self)
                        
                        // have to block game for myself, am "X", need to wait for "O"
                        self.prevGame.blockMoveForPlayerId = userId // **
                        
                        
                        
                        // need to check if i was player I or 2 in our previous game
                        // i am player 1 from prev game
                        print("I joined a prev game where i was player 1, line 213")
                        self.xPlayer.isHighlighted = true
                        self.xPlayer.highlightedTextColor = UIColor(red:0.0, green:0.55, blue:0.15, alpha:1.0)
                        
                        
                        self.game.prevGameId = self.prevGame.id
                        
                        print("**********1********")
                        self.updateGame(self.game)
                        print("**********2********")
//                                self.listenForGameChanges()
                        self.hasGameStarted = true
                        
                        self.game = self.prevGame
                        
                        if self.game.player1Name != self.currentUser.name {
                            self.game.player1Name = self.currentUser.name // user has changed names
                        }
                        
                        self.updatePlayerLabels()
                        
                        
                        print("I am player 1")
                        self.xPlayer.isHighlighted = true
                        self.xPlayer.highlightedTextColor = UIColor(red:0.0, green:0.55, blue:0.15, alpha:1.0)
                        
                        self.crossesScore = self.game.player1Score
                        self.noughtsScore = self.game.player2Score
                        
                        self.updateScore()
                        
                        self.waitingLabel.setTitle("Game Started", for: .normal)
                        
                        self.listenForGameChanges()
                        
                        return
                        
                    } else {
                        print("No prev game found 238")
                        //i am p 2
                        
                        self.game.blockMoveForPlayerId = userId
                        
                        self.updateGame(self.game)
                        self.waitingLabel.setTitle("Game Started", for: .normal)
                        self.listenForGameChanges()
                        
                        self.updatePlayerLabels()
                        
                        print("I am player 2")
                        self.oPlayer.isHighlighted = true
                        self.oPlayer.highlightedTextColor = UIColor(red:0.0, green:0.55, blue:0.15, alpha:1.0)
                        
                    }
                }
            }
//            return "" // uhuh
        }
//        return ""
        print("No prev game found, line 245")
        return
    }
    
    func checkGamePlayerStatus() -> Bool {
        return game != nil && game!.blockMoveForPlayerId != currentUser.id
//        return game != nil ? game!.blockMoveForPlayerId == currentUser.id : false
    }
    
    func updatePlayerLabels() {
        guard game != nil else { return }
        self.player1Name.setTitle(self.game.player1Name, for: .normal)
        self.player2Name.setTitle(self.game.player2Name, for: .normal)
    }
    
    
    func listenForGameChanges() {
        print("listenForGameChanges line 258")
        guard game != nil else { return }
        //I dont pull up here
        
//        let isPlayer2Here = !(self.game.player2Id == "")
        
        let listener = FirebaseReference(.Game).document(self.game.id).addSnapshotListener { documentSnapshot, error in
            
            
            if error != nil {
                print("Error getting updates line 245") //, error?.localizedDescription)
                return
            }
            
            if let snapshot = documentSnapshot {
                guard self.game != nil else { return }
                self.game = try? snapshot.data(as: Game.self)
                print("Game updated line 283")
//                }
                
                
                print("changes received from Firebase, move: ", self.game != nil ? self.game!.move : "Game quit")
//
                if !(self.game != nil) {
                    //wut
                    //its 2 am
                    self.waitingLabel.setTitle("Opponent Left", for: .normal)
                    return
                }
                guard self.game != nil else { return }
                self.updatePlayerLabels()
                print("line 449", self.checkGamePlayerStatus())
                
                self.waitingLabel.setTitle((self.game.blockMoveForPlayerId != self.currentUser.id) ? " Your Move " : " Opponent's Move ", for: .normal)
                
                self.updatePlayerLabels()
                print("line 451", self.checkGamePlayerStatus())
                if (self.checkGamePlayerStatus() && self.game.move != -1 && !self.game.waitForResetPlayer1 && !self.game.waitForResetPlayer2) {
                    self.game.blockMoveForPlayerId = self.currentUser.id
                    print("line 468")
                    self.updateOpponent()
                    
                }
            }
            
        }
        
        self.Listener = listener
        
            
    }
    
    
    
    func updateOpponent() {
        if (checkGamePlayerStatus()) {
            
            self.receiveDataBaseChange()
                print("Board tapped by opponent")
            
            self.updateGame(self.game!)
            
            }
        
        
    }
    
    func createNewGame(with userId: String) {
        //create new game object
        print("creating game for user", userId)
        
        //new game object
        self.game = Game(id: UUID().uuidString, player1Name: self.currentUser.name, player2Name: "" ,player1Id: userId, player2Id: "", player1Score: 0, player2Score: 0, blockMoveForPlayerId: userId, waitForResetPlayer1: false, waitForResetPlayer2: false, move: -1, prevGameId: "")
        
        self.createOnlineGame()
//        self.listenForGameChanges()
    }
    
    func updateGame(_ game: Game) {
        print("updateGame() line 396")
        do {
            //setData is efficient, only updates changed stuff
            try FirebaseReference(.Game).document(game.id).setData(from: self.game)
        } catch {
            print("Error updating game")
        }
    }
    
    func quitGame() {
        //what if second person quits game -- game is already nil
        guard game != nil else { return } //** deprecated, if 2 people in a game and leave, the game object now still exists
        self.resetPlayer()
        self.Listener.remove()
        print("self.resetPlayer() line 404")
        FirebaseReference(.Game).document(self.game.id).updateData(["move" : self.game.move])
        
        if self.game.player2Id == "" || self.game.player1Score == 0 && self.game.player2Score == 0 {
            FirebaseReference(.Game).document(self.game.id).delete()
            print("deleting game")
        }
        
        
    }
    
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        if self.game?.id != nil {
            //FirebaseService.shared.game ???
//            deleteGame()**
            self.quitGame()
        }
    }
    
    func makeOpponentMove() {
        self.updateOpponent()
    }


    

    
    
    
    
    
    func retrieveUser() {
        guard let userData = userData else { return }
        
        do {
            print("decoding user")
            currentUser = try JSONDecoder().decode(User.self, from: userData)
        } catch {
            print("No user saved")
        }
    }
    
//    func saveUser() {
//        currentUser = User()
//        do {
//            let data = try JSONEncoder().encode(currentUser)
//            userData = data
//        } catch {
//            print("Couldn't save user object")
//        }
//    }
    
    
    
    @State var isOn = false
    
    
    func sendToBoardTap(_ boardInt: Int) {
        print(board.count, " sending to board ", boardInt)
        self.addOpponentMoveToBoard(board[boardInt])
//        self.game!.blockMoveForPlayerId = self.game!.player2Id
    }
    
    
    func receiveDataBaseChange() {
        print("data base change")
//        self.waitingLabel.setTitle("", for: .normal)
        let myInt = game.move
        self.sendToBoardTap(myInt)
    }
    
    
    
    
    
    
    
     
     
     @IBOutlet var gameView: UIViewController!
     

     @IBOutlet weak var turnLabel: UILabel!
     
     @IBOutlet weak var a1: UIButton!
     @IBOutlet weak var a2: UIButton!
     @IBOutlet weak var a3: UIButton!
     @IBOutlet weak var b1: UIButton!
     @IBOutlet weak var b2: UIButton!
     @IBOutlet weak var b3: UIButton!
     @IBOutlet weak var c1: UIButton!
     @IBOutlet weak var c2: UIButton!
     @IBOutlet weak var c3: UIButton!
     
     
     
     var currentTurn = true
     

     
    
    
     var char1 = "X"
     var char2 = "O"
     
     var noughtsScore = 0
     var crossesScore = 0
     
    
     
     func initBoard () {
         board.append(a1)
         board.append(a2)
         board.append(a3)
         board.append(b1)
         board.append(b2)
         board.append(b3)
         board.append(c1)
         board.append(c2)
         board.append(c3)
//         sendToBoardTap(5)
     }
     

     

     
//     @IBAction func ClearBoard(_ sender: UIButton) {
//         resetBoard()
//     }
    
    func anyWinner() -> Bool {
        guard self.game != nil else { return true }
        
        if checkForVictory("X") {
            resetPlayer()
            print("self.resetPlayer() line 568")
            self.game.player1Score += 1
            crossesScore = self.game.player1Score
            updateGame(self.game)
            xWinDisplay.setTitle(String(crossesScore), for: .normal)
            resultAlert(title: "X Wins!")
            
            return true
        }
        
        if checkForVictory("O") {
            resetPlayer()
            print("self.resetPlayer() line 580")
            self.game.player2Score += 1
            noughtsScore = self.game.player2Score
            updateGame(self.game)
            oWinDisplay.setTitle(String(noughtsScore), for: .normal)
            resultAlert(title: "O Wins!")

            return true
        }
        
        
        if(fullBoard()) {
            resetPlayer()
            print("self.resetPlayer() line 594")
            self.updateGame(self.game)
            resultAlert(title: "Draw")
            return true
        }
        self.updateGame(self.game)
        return false
    }
    
    func updateScore() {
        xWinDisplay.setTitle(String(self.game.player1Score), for: .normal)
        oWinDisplay.setTitle(String(self.game.player2Score), for: .normal)
    }

     
    func resetPlayer() {
        self.game.waitForResetPlayer1 = true
        self.game.waitForResetPlayer2 = true
        self.game.move = -1
    }
    
    func clearPlayerForGame() {
        if self.game.player1Id == self.currentUser.id {
            self.game.waitForResetPlayer1 = false
        }
        else {
            self.game.waitForResetPlayer2 = false
        }
    }
     

    
     
     func thisSymbol(_ button: UIButton, _ symbol: String) -> Bool
         {
             return button.title(for: .normal) == symbol
         }
     
     
     
     func checkForVictory(_ s :String) -> Bool
         {
             // Horizontal Victory
             if thisSymbol(a1, s) && thisSymbol(a2, s) && thisSymbol(a3, s)
             {
                 return true
             }
             if thisSymbol(b1, s) && thisSymbol(b2, s) && thisSymbol(b3, s)
             {
                 return true
             }
             if thisSymbol(c1, s) && thisSymbol(c2, s) && thisSymbol(c3, s)
             {
                 return true
             }
             
             // Vertical Victory
             if thisSymbol(a1, s) && thisSymbol(b1, s) && thisSymbol(c1, s)
             {
                 return true
             }
             if thisSymbol(a2, s) && thisSymbol(b2, s) && thisSymbol(c2, s)
             {
                 return true
             }
             if thisSymbol(a3, s) && thisSymbol(b3, s) && thisSymbol(c3, s)
             {
                 return true
             }
             
             // Diagonal Victory
             if thisSymbol(a1, s) && thisSymbol(b2, s) && thisSymbol(c3, s)
             {
                 return true
             }
             if thisSymbol(a3, s) && thisSymbol(b2, s) && thisSymbol(c1, s)
             {
                 return true
             }
             
             return false
         }
    
     
     
     func resultAlert(title: String) {
         let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
         ac.addAction(UIAlertAction(title: "Rematch", style: .default, handler:
                                        { (_) in self.resetBoard()
             if self.game != nil {
                 self.clearPlayerForGame()
                 //this basically does update game
                 FirebaseReference(.Game).document(self.game.id).updateData([
                    ((self.currentUser.id == self.game.player1Id) ?
                                            "waitForResetPlayer1" :
                                            "waitForResetPlayer2" )
                                                          : false ])
             }
         }))
         self.present(ac, animated: true)
     }
     
     
     func resetBoard()
     {
         for button in board
         {
             button.setTitle(nil, for: .normal)
             button.isEnabled = true
         }
         
     }
     
     
     func fullBoard() -> Bool
     {
         for button in board
         {
             if button.title(for: .normal) == nil
             {
                 return false
             }
         }
         return true
     }
    
    
    @IBAction func boardTap(_ sender: UIButton) {
//        self.updateGame(game!)
        guard self.game != nil else { return }
        
        if self.game.waitForResetPlayer1 || self.game.waitForResetPlayer2 {
            
            print("line 446, waitForResetPlayer2: ", self.game.waitForResetPlayer2)
            print("line 447, waitForResetPlayer1: ", self.game.waitForResetPlayer1)
            self.waitingLabel.setTitle(" Waiting for Opponent to Rematch ", for: .normal)
            return
        }
        
        print("Board tap, player.id: ", self.currentUser.id)
        print("Blocked: ", self.game.blockMoveForPlayerId)
        print("line 415, waitForResetPlayer2: ", self.game.waitForResetPlayer2)
        print("line 416, waitForResetPlayer1: ", self.game.waitForResetPlayer1)
        
        if self.checkGamePlayerStatus() && !(self.game.waitForResetPlayer1 || self.game.waitForResetPlayer2){
//            self.game!.blockMoveForPlayerId = currentUser.id
            var boardInt = 0
            for i in 0...9 {
                if sender == board[i] {
                    boardInt = i
                    break
                }
            }
            self.game.move = boardInt
            
            print("JOInOnlinegame line 803, move: ", self.game.move)
            
            addToBoard(sender)
            self.updateGame(game!) // self.game
            self.anyWinner()
        }
     }
     
    func addToBoard (_ sender: UIButton) {
        
        if (currentTurn && self.game.player1Id == self.currentUser.id && self.game.blockMoveForPlayerId != self.game.player1Id) ||
               (!currentTurn && self.game.player2Id == self.currentUser.id && self.game.blockMoveForPlayerId != self.game.player2Id) {
            self.game.blockMoveForPlayerId = self.currentUser.id
            print("Other player blocked")
            
            if sender.title(for: .normal) == nil {
                
                sender.setTitle(currentTurn ? char1 : char2, for: .normal)
                sender.setTitleColor(currentTurn ? .blue : .red, for: .normal)
                currentTurn = !currentTurn
            }
            turnLabel.text = currentTurn ? "X" : "O"
            turnLabel.textColor = currentTurn ?  .blue: .red
            
            sender.isEnabled = false
            
        }
    }
   
   
   func addOpponentMoveToBoard(_ sender: UIButton) {
       if sender.title(for: .normal) == nil {
           
           sender.setTitle(currentTurn ? char1 : char2, for: .normal)
           sender.setTitleColor(currentTurn ? .blue : .red, for: .normal)
           currentTurn = !currentTurn
       }
       turnLabel.text = currentTurn ? "X" : "O"
       turnLabel.textColor = currentTurn ?  .blue: .red
       
       sender.isEnabled = false
       self.game.blockMoveForPlayerId = self.game.id == self.game.player1Id ? self.game.player2Id : self.game.player1Id
       self.anyWinner()
   }
    
    
    
}
