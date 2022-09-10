//
//  availableFriendsView.swift
//  tictactoe3
//
//  Created by Ethan Bootehsaz on 8/14/22.
//

//import Foundation
import SwiftUI



class availableFriends: UIViewController {
    
    @AppStorage("user") private var userData: Data?
    
    @AppStorage("isDarkMode") private var isDark: Bool?
    
    @Published var currentUser: User!
    
    @Published var lastClicked: UIButton!
    
    @Published var noFriendsButton: UIButton!
    
    
    
    @IBAction func refresh(_ sender: UIButton) {
        self.clearStack()
        
        self.addFriendsToStack()
        
        
    }
    
    
    
    
    var noFrend = true
    
    @IBOutlet weak var friendStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getColorScheme()
        
        self.retrieveUser()
       
        self.noFriendsButton = getButton("No Friends Available!" , "")
        
        self.addFriendsToStack()
    }
    
    func getColorScheme() {
        guard let isDark = isDark else { return }
        overrideUserInterfaceStyle = isDark ? .dark : .light
    }
    
    func clearStack() {
        var c = 1
        for aView in self.friendStack.subviews {
            if c == 1 {
                c = 0
                continue
            }
            
            self.friendStack.removeArrangedSubview(aView)
            aView.removeFromSuperview()
            
        }
        
    }
    
   
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    }
    
    
    
    func retrieveUser() {
        guard let userData = userData else { return }
        
        do {
            print("decoding user")
            currentUser = try JSONDecoder().decode(User.self, from: userData)
            print("Retrieved user,", currentUser.name)
            print(currentUser.name)
            
        } catch {
            print("No user saved")
        }
        
    }
    
    func addFriendsToStack() {
//        go through in reverse order -- most recently added friends first
//        for friend in self.currentUser.friends {
        var count = 0
        if self.currentUser.friends.count == 0 { self.friendStack.addArrangedSubview(self.noFriendsButton) }
        for (index, friend) in self.currentUser.friends.enumerated() {
            
            FirebaseReference(.Game).whereField("player2Id", isEqualTo: "").whereField("player1Id", isEqualTo:  friend[1]).getDocuments { querySnapshot, error in
                print("FirebaseService Line 91")

                if error != nil {
                    print("Error finding open game with given friend ID")
                    return
                }

                if let gameExists = querySnapshot?.documents.first {

                    let data = gameExists.data()

                    let name = data["player1Name"] as! String

                    var printName = name

                    let gameId = data["id"] as! String

                    if name != friend[0] {
                        printName = friend[0] + " is now-> " + name
                        self.currentUser.friends[index][0] = name
                        
                        do {
                            let data = try JSONEncoder().encode(self.currentUser)
                            self.userData = data
                        } catch {
                            print("Couldn't save user object")
                        }
                        
                    }

                    
                    let button = self.getButton(printName , gameId)

                    self.friendStack.addArrangedSubview(button)

                } else {
                    count += 1
                    if count == self.currentUser.friends.count {
                        self.friendStack.addArrangedSubview(self.noFriendsButton)
                    }
                }
            }
        }
        
        return // count != 0
    }
            
    func getButton(_ name: String, _ id: String) -> UIButton {
        
        let button = UIButton()

        button.setTitleColor(.black, for: .normal)

        button.setTitleColor(.systemBlue, for: .highlighted)

        button.setTitle("   " + name, for: .normal)
        
        button.setTitle(id, for: .highlighted)
        
        button.setImage(UIImage(systemName: "play"), for: .normal)
//
        button.backgroundColor = .white
        
//        button.tintColor = .systemBlue
        
//        button.layer.backgroundColor = UIColor.systemBlue.cgColor
//        button.superview?.backgroundColor = .systemBlue
        
        
        
        button.layer.cornerRadius = 25

        button.layer.borderColor = UIColor.systemGray2.cgColor //CGColor.init(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)

        button.layer.borderWidth = 3
//
        button.addTarget(self, action: #selector(self.buttonClicked), for: .touchUpInside)
//
        let heightConstraint = NSLayoutConstraint(
                item: button,
                attribute: NSLayoutConstraint.Attribute.height,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: nil,
                attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                multiplier: 1.0,
                constant: 60
            )
//
        button.addConstraint(heightConstraint)
        
        return button
        
    }
    
    @objc func buttonClicked(sender: UIButton) {
        let id = sender.title(for: .highlighted) ?? "Error"

        UIPasteboard.general.string = id

        print("Copied ID:", id)
        
        if (self.lastClicked != nil) {
            self.lastClicked.backgroundColor = .white
        }
        
        sender.backgroundColor = .systemGreen
        
        self.lastClicked = sender
        
        

    }
    
    
}
