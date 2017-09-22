//
//  AddProjectViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 10/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

protocol AddProjectDelegate {
    func projectAdded(controller: AddProjectViewController, name: String, desc: String)
}

class AddProjectViewController: UIViewController {
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var descTextField: UITextView!
    
    var addProjectDelegate: AddProjectDelegate?
    
    
    // MARK: -
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create a New Project"
        
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm E dd MMM yyyy"
        nameTextField.text = dateFormatter.string(from:date as Date)
        
        nameTextField.layer.borderColor = UIColor.black.cgColor
        nameTextField.layer.cornerRadius = 4
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.backgroundColor = UIColor.white.cgColor
    
        descTextField.layer.borderColor = UIColor.black.cgColor
        descTextField.layer.cornerRadius = 4
        descTextField.layer.borderWidth = 1
        descTextField.layer.backgroundColor = UIColor.white.cgColor
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -
    // MARK: Actions
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        if let name = nameTextField.text, let desc = descTextField.text {
                        
            // Notify Delegate
            addProjectDelegate?.projectAdded(controller: self, name: name, desc: desc)
            
            // Dismiss View Controller
            dismiss(animated: true, completion: nil)
        }
    }
    



}
