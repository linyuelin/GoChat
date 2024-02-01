//
//  ViewController.swift
//  Messenger
//
//  Created by dreaMTank on 2024/01/31.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
      
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAyth()
        
    }
    
    private func validateAyth(){
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

}

