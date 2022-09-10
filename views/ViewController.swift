//
//  ViewController.swift
//  TicTacToe
//
//  Created by Ethan Bootehsaz on 7/9/22.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {
    
    @AppStorage("isDarkMode") private var isDark: Bool?

    
//    @State var isOn = false
    
    
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
    
    @IBOutlet weak var xWinDisplay: UIButton!
    @IBOutlet weak var oWinDisplay: UIButton!
    
    
    
    var char1 = "X"
    var char2 = "O"
    
    var noughtsScore = 0
    var crossesScore = 0
    
    var board = [UIButton]()
    
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
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initBoard()
        getColorScheme()
    }
    
    func getColorScheme() {
        guard let isDark = isDark else { return }
        overrideUserInterfaceStyle = isDark ? .dark : .light
    }
    

    
    @IBAction func ClearBoard(_ sender: UIButton) {
        resetBoard()
    }
    
    
    

    @IBAction func boardTap(_ sender: UIButton)
    {
        
        addToBoard(sender)
        
//        if sender == a1 {
//            boardTap(a3)
//        }
        
        
        if checkForVictory("X")
        {
            crossesScore += 1
            xWinDisplay.setTitle(String(crossesScore), for: .normal)
            resultAlert(title: "X Wins!")
        }
        
        if checkForVictory("O")
        {
            noughtsScore += 1
            oWinDisplay.setTitle(String(noughtsScore), for: .normal)
            resultAlert(title: "O Wins!")
        }
        
        
        if(fullBoard())
        {
           resultAlert(title: "Draw")
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
   
    
    
    func resultAlert(title: String)
    {
        let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Reset", style: .default, handler:{ (_) in self.resetBoard()
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
    
    func addToBoard (_ sender: UIButton)
    {
        if sender.title(for: .normal) == nil
        {
            
            sender.setTitle(currentTurn ? char1 : char2, for: .normal)
            sender.setTitleColor(currentTurn ? .blue : .red, for: .normal)
            currentTurn = !currentTurn
        }
        turnLabel.text = currentTurn ? "X" : "O"
        turnLabel.textColor = currentTurn ?  .blue: .red
        
        sender.isEnabled = false
    }
    
    
}



