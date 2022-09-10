//
//  onlineVC.swift
//
//
//  Created by Ethan Bootehsaz on 7/27/22.
//
// This will be auto matchmaking button
//import Foundation

import SwiftUI
import Combine

import Firebase
import FirebaseFirestoreSwift


class onlineVC: UIViewController {

    @AppStorage("user") private var userData: Data?

    @AppStorage("isDarkMode") private var isDark: Bool?

    var hasGameStarted = false

    //optional because don't want crash if empty or nil obj, tf am i saying XD?
    @Published var game: Game!

    @Published var Listener: ListenerRegistration!

    @IBOutlet weak var stackView: UIStackView!

    @Published var board = [UIButton]()


    @Published var currentUser: User!

    private var cancellables: Set<AnyCancellable> = []

    @IBOutlet weak var idLabel: UILabel!

    @IBOutlet weak var xPlayer: UILabel!
    @IBOutlet weak var oPlayer: UILabel!

    @IBOutlet weak var xWinDisplay: UIButton!
    @IBOutlet weak var oWinDisplay: UIButton!


    @IBOutlet weak var player1Name: UIButton!
    @IBOutlet weak var player2Name: UIButton!

    @IBOutlet weak var waitingLabel: UIButton!


    @IBAction func addFriend(_ sender: UIButton) {
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




    override func viewDidLoad()
    {
        super.viewDidLoad()
        initBoard()
        getColorScheme()

        initOnlineVC() // identifies current user
        startGame(with: currentUser.id)

    }

    func getColorScheme() {
        guard let isDark = isDark else { return }
        overrideUserInterfaceStyle = isDark ? .dark : .light
    }


    func initOnlineVC() {
        retrieveUser()

//        if currentUser == nil {
//            saveUser()
//        }

    }


    func startGame(with userId: String) {
        //create new game
        // i am player 1 of new game
        self.createNewGame(with: userId)
        print("FirebaseService Line 91")
        self.xPlayer.isHighlighted = true
        self.xPlayer.highlightedTextColor = UIColor(red:0.0, green:0.55, blue:0.15, alpha:1.0)
        self.updatePlayerLabels()

        self.listenForGameChanges()

    }

    func createOnlineGame() {
        //save game online

        do {
            try FirebaseReference(.Game).document(self.game.id).setData(from: self.game)
            print("Game is online")
            self.waitingLabel.setTitle(" Game is online ", for: .normal)
        } catch {
            print("Error creating online game", error.localizedDescription)
        }

    }


    func listenForGameChanges() {
        guard self.game != nil else { return }
        //I dont pull up here
//        self.updatePlayerLabels()
        let listener = FirebaseReference(.Game).document(self.game.id).addSnapshotListener { documentSnapshot, error in

            if error != nil {
                print("Error getting updates") //, error?.localizedDescription)
                return
            }

            if let snapshot = documentSnapshot {
//
                self.game = try? snapshot.data(as: Game.self)
                guard self.game != nil else { return }
                if (self.game.prevGameId != "") {
                    self.game.blockMoveForPlayerId = self.currentUser.id // temp block myself and check for prev game

                    FirebaseReference(.Game).whereField("id", isEqualTo: self.game.prevGameId).getDocuments { querySnapshot, error in
                        print("FirebaseService Line 117")

                        if error != nil {
                            print("Error joing PrevGame, line 186")
                            self.waitingLabel.setTitle(" Error With Database Joining Game ", for: .normal)
                            return
                        }

                        if let prevGameData = querySnapshot?.documents.first {
                            print("quitting prev game and joining new game")
                            self.waitingLabel.setTitle(" Loading Game ", for: .normal)

                            self.moveGames(with: prevGameData)

                        }

                    }
//                    print("Game moved to game with Id ", self.game.id)
                }


                print("changes received from Firebase, move: ", self.game != nil ? self.game!.move : "Game quit")

                if !(self.game != nil) {
                    //wut
                    //its 2 am
                    self.waitingLabel.setTitle("Opponent Left", for: .normal)
                    return
                }

                print("line 139", self.checkGamePlayerStatus())

                self.updatePlayerLabels()

                self.waitingLabel.setTitle((self.game.blockMoveForPlayerId != self.currentUser.id) ? " Your Move " : " Opponent's Move ", for: .normal)
                if self.game.player2Id == "" {
                    self.waitingLabel.setTitle(" Waiting For Opponent ", for: .normal)
                }
                if (self.checkGamePlayerStatus() && self.game.move != -1 && !self.game.waitForResetPlayer1 && !self.game.waitForResetPlayer2) {

                    print("line 240")
                    self.game.blockMoveForPlayerId = self.currentUser.id
                    self.updateOpponent()

                }
            }
        }

        self.Listener = listener

    }

    func moveGames(with prevGameData: QueryDocumentSnapshot) {
        FirebaseReference(.Game).document(self.game.id).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Old Game successfully removed!")

                self.Listener.remove()

                self.game = try? prevGameData.data(as: Game.self)

                if self.game.player1Id != self.currentUser.id {
                    // i am now player 2
                    print("I am player 2")
                    self.xPlayer.isHighlighted = false
                    self.xPlayer.highlightedTextColor = UIColor.black
                    self.oPlayer.isHighlighted = true
                    self.oPlayer.highlightedTextColor = UIColor(red:0.0, green:0.55, blue:0.15, alpha:1.0)

                    self.waitingLabel.setTitle("...Game Started...", for: .normal)

                    if self.game.player2Name != self.currentUser.name {
                        self.game.player2Name = self.currentUser.name // user has changed names
                    }

                } else {
                    print("I am player 1")
                    self.waitingLabel.setTitle("...Game Started...", for: .normal)
                    if self.game.player1Name != self.currentUser.name {
                        self.game.player1Name = self.currentUser.name // user has changed names
                    }
                }

                print("GameId: ", self.game.id)

                self.game.blockMoveForPlayerId = self.game.player2Id

                self.updateScore()

                self.updatePlayerLabels()

                self.clearBoth()

                self.updatePlayerLabels()

                self.updateGame(self.game)

                self.listenForGameChanges()

                self.updateGame(self.game)

                self.waitingLabel.setTitle("", for: .normal)


            }
        }
    }

    func checkGamePlayerStatus() -> Bool {
        return game != nil && game!.blockMoveForPlayerId != currentUser.id
//        return game != nil ? game!.blockMoveForPlayerId == currentUser.id : false
    }




    func updateOpponent() {
        if (checkGamePlayerStatus()) {

            self.receiveDataBaseChange()
                print("Board tapped by opponent")

//            self.updateGame(self.game!)

            }


    }

    func createNewGame(with userId: String) {
        //create new game object
        print("creating game for user", userId)
        let anId = (UUID().uuidString).prefix(8)
        //new game object
        self.game = Game(id: String(anId), player1Name: self.currentUser.name, player2Name: "", player1Id: userId, player2Id: "", player1Score: 0, player2Score: 0, blockMoveForPlayerId: userId, waitForResetPlayer1: false, waitForResetPlayer2: false, move: -1, prevGameId: "")

        self.createOnlineGame()
        self.listenForGameChanges()
    }

    func updateGame(_ game: Game) {
        print("updateGame() line 258")
        do {
            //setData is efficient, only updates changed stuff
            try FirebaseReference(.Game).document(game.id).setData(from: self.game)
        } catch {
            print("Error updating game")
        }
    }

    func quitGame() {
        //what if second person quits game -- game is already nil
        guard game != nil else { return } //** deprecated? (not anymore), if 2 people in a game and leave, the game object now still exists
        self.resetPlayer()
        self.Listener.remove()
        print("self.resetPlayer() line 262")
        FirebaseReference(.Game).document(self.game.id).updateData(["move" : self.game.move])

        if (self.game.player2Id == "" || self.game.player1Score == 0 && self.game.player2Score == 0) {
            FirebaseReference(.Game).document(self.game.id).delete()
            print("Quitting game")
        }

        self.game = nil
    }




    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
            //FirebaseService.shared.game ???
//            deleteGame()**
        print("quitting game")
        self.quitGame()

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


    func updatePlayerLabels() {
        guard self.game != nil else { return }
        self.player1Name.setTitle(self.game.player1Name, for: .normal)
        self.player2Name.setTitle(self.game.player2Name, for: .normal)
    }


    @IBAction func shareID(_ sender: UIButton) {
        guard self.game != nil else {
            UIPasteboard.general.string = "No Game"
            return
        }
        let longId = self.game.id
        let shortId = String(longId.prefix(8))
        idLabel.text = "Game ID copied!"
        UIPasteboard.general.string = shortId
        print("Label is selfID")
//        sendToBoardTap(3)
//        self.quitGame()
    }














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



    func resetMove() {
        guard self.game != nil else { return  }
        self.game.move = -1
    }


//     @IBAction func ClearBoard(_ sender: UIButton) {
//         resetBoard()
//     }

    func anyWinner() -> Bool {
        print("checking for winner line 379")
        guard self.game != nil else { return true }

        if checkForVictory("X") {

            resetPlayer()
            print("self.resetPlayer() line 440")
            self.game.player1Score += 1
            print("X += 1")
            crossesScore = self.game.player1Score
            updateGame(self.game)
            updateScore()
//            resetMove()
            resultAlert(title: "X Wins!")
            self.waitingLabel.setTitle(" Waiting for Opponent to Rematch ", for: .normal)


            return true
        }

        if checkForVictory("O") {

            resetPlayer()
            print("self.resetPlayer() line 454")
            self.game.player2Score += 1
            print("O += 1")
            noughtsScore = self.game.player2Score
            updateGame(self.game)
//            resetMove()
            updateScore()
            resultAlert(title: "O Wins!")
            self.waitingLabel.setTitle(" Waiting for Opponent to Rematch ", for: .normal)

            return true
        }


        if(fullBoard()) {
            resetPlayer()
            print("self.resetPlayer() line 474")
            self.updateGame(self.game)
            resultAlert(title: "Draw")
            self.waitingLabel.setTitle(" Waiting for Opponent to Rematch ", for: .normal)
//            resetMove()

            return true

        }

//        self.updateGame(self.game)
        return false

    }

    func updateScore() {
        xWinDisplay.setTitle(String(self.game.player1Score), for: .normal)
        oWinDisplay.setTitle(String(self.game.player2Score), for: .normal)
    }


    func resetPlayer() {
        guard self.game != nil else { return  }
        self.game.waitForResetPlayer1 = true
        self.game.waitForResetPlayer2 = true
        resetMove()
    }

    func clearPlayerForGame() {
        if self.game.player1Id == self.currentUser.id {
            self.game.waitForResetPlayer1 = false
        }
        else {
            self.game.waitForResetPlayer2 = false
        }
    }

    func clearBoth() {
        self.game.waitForResetPlayer1 = false
        self.game.waitForResetPlayer2 = false
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
         self.present(ac, animated: true, completion: nil)
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
        print("Board tap")
        guard self.game != nil else {
            print("No Game")
            return
        }
//        self.updateGame(game!)

        if self.game.waitForResetPlayer1 || self.game.waitForResetPlayer2 {

            print("line 446, waitForResetPlayer2: ", self.game.waitForResetPlayer2)
            print("line 447, waitForResetPlayer1: ", self.game.waitForResetPlayer1)
            self.waitingLabel.setTitle(" Waiting for Opponent to Rematch ", for: .normal)
            if self.anyWinner() {
                self.clearPlayerForGame()
                self.updateGame(self.game)
            }
            return
        }



        print("Board tap, player.id: ", self.currentUser.id)
        print("Blocked: ", self.game.blockMoveForPlayerId)
        print("line 465, waitForResetPlayer2: ", self.game.waitForResetPlayer2)
        print("line 466, waitForResetPlayer1: ", self.game.waitForResetPlayer1)

        if self.checkGamePlayerStatus() && !(self.game.waitForResetPlayer1 || self.game.waitForResetPlayer2) {
//            self.game!.blockMoveForPlayerId = currentUser.id
            var boardInt = 0
            for i in 0...9 {
                if sender == board[i] {
                    boardInt = i
                    break
                }
            }
            self.game.move = boardInt

            addToBoard(sender)
            print("OnlineVC line 476, move: ", self.game.move)
            self.updateGame(game)
            self.anyWinner()

        }
     }


    func addToBoard (_ sender: UIButton) {

        if (currentTurn && self.game.player1Id == self.currentUser.id && self.game.blockMoveForPlayerId != self.game.player1Id) ||
               (!currentTurn && self.game.player2Id == self.currentUser.id && self.game.blockMoveForPlayerId != self.game.player2Id) {
            self.game.blockMoveForPlayerId = self.currentUser.id

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
