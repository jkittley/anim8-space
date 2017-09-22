//
//  ProjectsViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 05/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class ProjectsViewController: UITableViewController {
    
    var projects = [Project]()
    var selection: Project?
    
    let CellIdentifier = "Cell Identifier"
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        // Custom Title Image
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "navbar.png"))
        self.navigationController?.navigationBar.tintColor = UIColor.white;
        
        // Load Items
        //loadItems()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register Class
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: CellIdentifier)
    }
    
//    
//    // MARK: -
//    // MARK: Helper Methods
//    private func loadItems() {
//        if let filePath = pathForItems(), FileManager.default.fileExists(atPath: filePath) {
//            if let archivedProjects = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [Project] {
//                projects = archivedProjects
//            }
//        }
//    }
//    
//    private func pathForItems() -> String? {
//        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
//        if let documents = paths.first, let documentsURL = NSURL(string: documents) {
//            return documentsURL.appendingPathComponent("projects.plist")?.path
//        }
//        return nil
//    }
//    
//    
//    private func saveItems() {
//        print ("--> Saving")
//        DispatchQueue.global().async {
//            if let filePath = self.pathForItems() {
//                NSKeyedArchiver.archiveRootObject(self.projects, toFile: filePath)
//            }
//        }
//    }
//    
//    
//    @IBAction func addProject(sender: UIBarButtonItem) {
//        performSegue(withIdentifier: "AddProjectViewController", sender: self)
//    }
//    
//    @IBAction func helpTutorial(sender: UIBarButtonItem) {
//        performSegue(withIdentifier: "HelpTutorial", sender: self)
//    }
//    
//    @IBAction func showAsCollection(sender: UIBarButtonItem) {
//        performSegue(withIdentifier: "showAsCollection", sender: self)
//    }
//    
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//
//    
//    // MARK: - Table view data source
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 1
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return projects.count
//    }
//
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        // Dequeue Reusable Cell
//        let cell = tableView.dequeueReusableCell(withIdentifier: "projCell", for: indexPath) as! ProjectCellTableViewCell
//        
//        // Fetch Item
//        let project = projects[indexPath.row]
//        
//        let frameString = " - [" + String(project.frames.count) + " frames]"
//        
//        // Configure Table View Cell
//        cell.titleLabel?.text = project.name + frameString
//        cell.thumbView?.image = project.getThumb()
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
//        let dateStringCreated = dateFormatter.string(from:project.timeCreated as Date)
//        let dateStringUpdated = dateFormatter.string(from:project.timeUpdated as Date)
//        cell.dateCreatedLabel?.text = "Created: " + dateStringCreated
//        cell.dateUpdatedLabel?.text = "Last Editted: " + dateStringUpdated
//        
//        return cell
//    }
//    
//    
//    func openProject(project: Project) {
//        print("openning project", project.name)
//        // Update Selection
//        selection = project
//        // Perform Segue
//        DispatchQueue.main.async {
//            self.performSegue(withIdentifier: "EditProjectViewController", sender: self)
//        }
//    }
//    
//    
//    override func tableView(_: UITableView, didSelectRowAt: IndexPath) {
//        openProject(project: projects[didSelectRowAt.row])
//    }
//    
//    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 100.0;//Choose your custom row height
//    }
//    
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return true
//    }
//    
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            
//            let refreshAlert = UIAlertController(title: "Are You Sure?", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
//            
//            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
//                // Delete project
//                self.projects.remove(at: indexPath.row)
//                // Delete row from table view
//                tableView.deleteRows(at: [indexPath], with: .fade)
//                // Save
//                self.saveItems()
//            }))
//            
//            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
//                print("Handle Cancel Logic here")
//            }))
//            
//            present(refreshAlert, animated: true, completion: nil)
//            
//        } else if editingStyle == .insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table
//        }
//    }
//
//    func tableViewScrollToBottom(animated: Bool) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
//            let numberOfSections = self.tableView.numberOfSections
//            let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections-1)
//            
//            if numberOfRows > 0 {
//                let indexPath = IndexPath(row: numberOfRows-1, section: (numberOfSections-1))
//                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
//            }
//        }
//    }
//    
//
//    // MARK: -
//    // MARK: Add Item View Controller Delegate Methods
//    func projectAdded(controller: AddProjectViewController, name: String, desc: String) {
//        // Create Item
//        let project = Project(name: name)
//        project.desc = desc
//        
//        // Add Item to Items
//        projects.append(project)
//        // Add Row to Table View
//        let indexPath = IndexPath(row: (projects.count - 1), section: 0)
//        tableView.insertRows(at: [indexPath], with: .none)
//        // Save Items
//        saveItems()
//        
//        // Scroll to bottom
//        tableViewScrollToBottom(animated: false)
//        
//        // Open
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.openProject(project: project)
//        }
//    }
//    
//    
//    // MARK: -
//    // MARK: Edit Item View Controller Delegate Methods
//    func projectEdited(didUpdateItem project: Project) {
//        
//        project.timeUpdated = NSDate()
//        
//        // Fetch Index for Item
//        if let index = projects.index(of: project) {
//            // Update Table View
//            DispatchQueue.main.async {
//              let indexPath = IndexPath(row: index, section: 0)
//              self.tableView.reloadRows(at: [indexPath], with: .fade)
//            }
//        }
//        
//        // Save Items
//        saveItems()
//    }
//    
//
//    
//    // MARK: - Navigation
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//       
//        if segue.identifier == "AddProjectViewController" {
//            if let navigationController = segue.destination as? UINavigationController,
//                let controller = navigationController.viewControllers.first as? AddProjectViewController {
//                    controller.addProjectDelegate = self
//            }
//            
//        } else if segue.identifier == "EditProjectViewController" {
//            if let navigationController = segue.destination as? UINavigationController,
//                let controller = navigationController.viewControllers.first as? EditProjectViewController,
//                let project = selection {
//                    controller.editProjectDelegate = self
//                    controller.project = project
//            }
//        }
//    }
    
    
    
    
}
