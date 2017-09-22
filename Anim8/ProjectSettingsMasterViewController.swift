//
//  ProjectSettingsMasterViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 18/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

protocol SaveProjectSettingsDelegate {
    func saveSettings()
}

class ProjectSettingsMasterViewController: UIViewController {
    
    var project: Project?
    var editProjectDelegate: EditProjectDelegate?
    var saveProjectSettingsDelegate: SaveProjectSettingsDelegate?
    
    //@IBOutlet var embeddedTableView: UIContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Custom Title Image
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "navbar.png"))
        
        
        //saveProjectSettingsDelegate =
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func save(sender: UIBarButtonItem) {
        print("SAVE")
        
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let embeddedVC = segue.destination as? ProjectSettingsViewController, segue.identifier == "EmbedSegue" {
            
            embeddedVC.project = self.project
            embeddedVC.editProjectDelegate = self.editProjectDelegate
            
        }
    }

}
