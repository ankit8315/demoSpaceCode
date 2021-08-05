//
//  BaseViewController.swift
//  demoMap
//
//  Created by Ankit on 05/08/21.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    func showAlert(message: String?) {
        
      
        let alertCtroller = UIAlertController.init(title: "Maps", message: message, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction.init(title: "Ok", style: .default) { (alert) in
          print("action")
        }
        alertCtroller.addAction(action)
        self.present(alertCtroller, animated: true, completion: nil)
    }
    
    
    
    }
