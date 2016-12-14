//
//  ViewController.swift
//  Demo
//
//  Created by Ido Mizrachi on 12/14/16.
//  Copyright © 2016 Ido Mizrachi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var aboutBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("title.login", comment: "Login")
        self.aboutBarButtonItem.title = NSLocalizedString("title.about", comment: "About")
        self.textFieldUsername.placeholder = NSLocalizedString("input.username", comment: "Username")
        self.textFieldPassword.placeholder = NSLocalizedString("input.password", comment: "Password")
    }

    


}

