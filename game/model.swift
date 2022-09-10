//
//  Model.swift
//  TicTacToe
//
//  Created by Ethan Bootehsaz on 7/28/22.
//

//import Foundation
import UIKit

struct Game: Codable {
    var id: String
    
    var player1Name: String
    var player2Name: String
    
    var player1Id: String
    var player2Id: String
    
    
    
    var player1Score: Int
    var player2Score: Int
    
    var blockMoveForPlayerId: String
    var waitForResetPlayer1 : Bool
    var waitForResetPlayer2 : Bool
    
    
    
    var move : Int
    
    var prevGameId : String
}
