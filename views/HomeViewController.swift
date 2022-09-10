//
//  HomeViewController.swift
//  TicTacToe
//
//  Created by Ethan Bootehsaz on 7/23/22.
//

import UIKit
import SwiftUI

class HomeViewController: UIViewController {
    
    @AppStorage("isDarkMode") private var isDark = false
    
    @Published var isDarkMode: Bool = false
    
    @IBOutlet weak var titleView: UIView!
    
    @IBAction func darkModeToggle(_ sender: UISwitch) {
        self.isDarkMode.toggle()
        
        self.setUIColor()
        
        print("Dark Mode: ", self.isDarkMode)
    }
    
    let col1 = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.9)
    let skyBlue = UIColor(red: 0.4627, green: 0.84, blue: 1.0, alpha: 1.0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUIColor()
        
//        titleView.layer.shadowColor = UIColor.blue.cgColor
//        titleView.layer.shadowOpacity = 1
//        titleView.layer.shadowOffset = .zero
//        titleView.layer.shadowRadius = 10
//        titleView.layer.shouldRasterize = true
//        titleView.layer.rasterizationScale = UIScreen.main.scale
//        titleView.backgroundColor = .systemBlue
//        titleView.layer.backgroundColor = UIColor.systemBlue.cgColor
        
        

        // Do any additional setup after loading the view.
    }
    
    func setUIColor() {
        overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
        self.isDark = self.isDarkMode
//        view.backgroundColor = self.isDarkMode ? .black : skyBlue
    }
}
