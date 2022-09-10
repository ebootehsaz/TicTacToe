//
//  createOrJoinVC.swift
//  TicTacToe
//
//  Created by Ethan Bootehsaz on 7/29/22.
//

//import Foundation
import SwiftUI



class createOrJoinVC: UIViewController { // UIViewController , HomeViewController
    
    // person.crop.circle.badge.checkmark
    
    
    
    @IBOutlet weak var textField: UITextField!
    
    
    @IBAction func done(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    
    @IBAction func joinedButton(_ sender: UIButton) {
        let txt = self.textField.text
        UIPasteboard.general.string = txt ?? ""
        print(txt ?? "empy string")
    }
    
    
    
    @AppStorage("isDarkMode") private var isDark: Bool?
    
    @AppStorage("user") private var userData: Data?
    
    @Published var currentUser: User!
    
    @IBAction func changeName(_ sender: UIButton) {
        print("Changing name ")
        let alertController = UIAlertController(title: "Enter Name", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Enter", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                // operations
//                while text == "" {
//                    self.present(alertController, animated: true, completion: nil)
//                }
                print("Name Given ==> " + text)
                self.currentUser.changeNameTo(text)
                do {
                    let data = try JSONEncoder().encode(self.currentUser)
                    self.userData = data
                } catch {
                    print("Couldn't save user object")
                }
            }
        })
        alertController.addTextField { (textField) in
            textField.placeholder = "Tim"
        }
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getColorScheme()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initUser()
    }
    
    func getName() {
        print("Asking for name ")
        let alertController = UIAlertController(title: "Enter Name", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Enter", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                // operations
//                while text == "" {
//                    self.present(alertController, animated: true, completion: nil)
//                }
                print("Name Given ==> " + text)
                self.saveUser(with: text)
            }
        })
        alertController.addTextField { (textField) in
            textField.placeholder = "Tim"
        }
        
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    func initUser() {
        retrieveUser()
        if currentUser == nil {
            getName()
//            saveUser()
        }
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
    
    func getColorScheme() {
        guard let isDark = isDark else { return }
        overrideUserInterfaceStyle = isDark ? .dark : .light
    }
    
    func saveUser(with name: String) {
        currentUser = User(name)
        do {
            let data = try JSONEncoder().encode(currentUser)
            userData = data
        } catch {
            print("Couldn't save user object")
        }
    }
    
    
    

}
