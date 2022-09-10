//
//  User.swift
//  TicTacToe
//
//  Created by Ethan Bootehsaz on 7/27/22.
//

import Foundation // needed

class User: Codable { // struct
    var id = UUID().uuidString
    var name: String
    var friends: [[String]]
    var friendToJoin: String
    
    
    init(_ personName: String) {
        self.name = personName
        self.friends = []
        self.friendToJoin = ""
//        if personName == "Ethan" {
//            for i in 1...20 {
//                friends.append(["Fakey", "00045678"])
//            }
//        }
    }
    
    func changeNameTo(_ aName: String) {
        self.name = aName
    }
    
    func addUserFriend(_ friendName: String, _ friendId: String) {
        let fr = [friendName, friendId]
        self.friends.append(fr)
    }
}
