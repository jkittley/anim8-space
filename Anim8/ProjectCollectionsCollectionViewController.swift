//
//  ProjectCollectionsCollectionViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 25/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class ProjectCollectionsCollectionViewController: UICollectionViewController, EditProjectDelegate {
    
    var projects = [Project]()
    var selection: Project?
    var delMode = false
    
    @IBOutlet weak var welcomeImageView: UIImageView!
    
    @IBAction func addNewProjectAction(_ sender: Any) {
        addProject();
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        // Load Items
        loadItems()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Custom Title Image
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "navbar.png"))
        self.navigationController?.navigationBar.tintColor = UIColor.white;
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
        
        let versionString = "V" + version + ".b" + build
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: versionString, style: .plain, target: self, action: nil)
        
        let numCols = CGFloat(4.0)
        let pad = CGFloat(15)
        
        //Define Layout here
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        //Get device width
        let width = UIScreen.main.bounds.width
        
        //set section inset as per your requirement.
        layout.sectionInset = UIEdgeInsets(top: pad, left: pad, bottom: pad, right: pad)
        
        //set cell item size here
        let w = (width - (numCols * pad)) / numCols
        layout.itemSize = CGSize(width: w, height: w)
        
        //set Minimum spacing between 2 items
        layout.minimumInteritemSpacing = 0
        
        //set minimum vertical line spacing here between two lines in collectionview
        layout.minimumLineSpacing = 0
        
        //apply defined layout to collectionview
        collectionView!.collectionViewLayout = layout
        
    }
    
    //
    // Load / Save Data
    //
    
    private func loadItems() {
        if let filePath = pathForItems(), FileManager.default.fileExists(atPath: filePath) {
            if let archivedProjects = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [Project] {
                projects = archivedProjects
            }
        }
    }
    
    private func pathForItems() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if let documents = paths.first, let documentsURL = NSURL(string: documents) {
            return documentsURL.appendingPathComponent("projects.plist")?.path
        }
        return nil
    }

    private func saveItems() {
        print ("--> Saving")
        DispatchQueue.global().async {
            if let filePath = self.pathForItems() {
                NSKeyedArchiver.archiveRootObject(self.projects, toFile: filePath)
            }
        }
    }
    
    //
    // UI Interactions
    //
    
    @IBAction func toggleDeleteMode(_ sender: Any) {
        delMode = !delMode
        print("Delete Mode", delMode)
        self.collectionView?.reloadData()
    }
    
    
    @IBAction func helpButtonClick(_ sender: Any) {
        performSegue(withIdentifier: "helpSeg", sender: self)
    }
    
    @IBAction func AddButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "addSeg", sender: self)
    }
    
    
    func deleteProject(project: Project, indexPath: IndexPath) {
        print("Deleting ",indexPath.row)
        
        let deleteAlert = UIAlertController(title: "Are You Sure?", message: "All photos from '\(project.name)' will be perminantly deleted.", preferredStyle: UIAlertControllerStyle.alert)
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            // Delete project
            self.projects.remove(at: indexPath.row)
            // Delete row from table view
            self.collectionView?.deleteItems(at: [indexPath])
            // Save
            self.saveItems()
        }))
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(deleteAlert, animated: true, completion: nil)
    }
    
    
    func openProject(project: Project) {
        // Update Selection
        selection = project
        // Perform Segue
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "editSeg", sender: self)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if delMode {
            deleteProject(project: projects[indexPath.row], indexPath:indexPath)
        } else {
            openProject(project: projects[indexPath.row])
        }
    }
    
    //
    // Manage Collections View
    //
    

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Show hide welcome message
        welcomeImageView.isHidden = (projects.count > 0)
        return projects.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Fetch Item
        let project = projects[indexPath.row]
        
        //Sequeue Reusable Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "projCollectCell", for: indexPath) as! ProjectCollectionCell
        
        cell.thumbView.layer.borderWidth = 1.0
        cell.thumbView.layer.borderColor = UIColor.black.cgColor
        cell.thumbView.layer.cornerRadius = 4
        cell.thumbView.backgroundColor = UIColor.white
        
        cell.deleteIcon.isHidden = true
        
        cell.numFramesLabel.text = "\(project.frames.count) frames"
        
        // Configure Table View Cell
        cell.titleText?.text = project.name + " (" + String(project.frames.count) + " frames)"
        cell.thumbView?.image = project.getThumb()
        
        if delMode {
            cell.thumbView.layer.borderColor = UIColor.red.cgColor
            cell.thumbView.layer.borderWidth = 4.0
            cell.deleteIcon.isHidden = false
        } else {
            cell.thumbView.layer.borderColor = UIColor.black.cgColor
            cell.thumbView.layer.borderWidth = 1.0
            cell.deleteIcon.isHidden = true
        }
        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
//        let dateStringCreated = dateFormatter.string(from:project.timeCreated as Date)
//        let dateStringUpdated = dateFormatter.string(from:project.timeUpdated as Date)
//        cell.dateCreatedLabel?.text = "Created: " + dateStringCreated
//        cell.dateUpdatedLabel?.text = "Last Editted: " + dateStringUpdated
        
        return cell
    }

    
    //
    // Deligates
    //
    
    func addProject() {
        print("Adding project")
        
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm E dd MMM yyyy"

        // Create Item
        let project = Project(name: dateFormatter.string(from:date as Date))
        
        // Add Item to Items
        projects.append(project)
        // Add Row to Table View
        let indexPath = IndexPath(row: (projects.count - 1), section: 0)
        collectionView?.insertItems(at: [indexPath])

        // Save Items
        saveItems()
        
        // Scroll to bottom
        //tableViewScrollToBottom(animated: false)
        
        // Open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.openProject(project: project)
        }
    }
    
    
    func projectEdited(didUpdateItem project: Project) {
        
        print("Updating project")
        project.timeUpdated = NSDate()
        
        // Fetch Index for Item
        if let index = projects.index(of: project) {
            // Update Table View
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: index, section: 0)
                self.collectionView?.reloadItems(at: [indexPath])
            }
        }
        
        // Save Items
        saveItems()
    }
    
    //
    // Segue managment
    //
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = "Projects"
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "editSeg" {
            if let navigationController = segue.destination as? UINavigationController,
                let controller = navigationController.viewControllers.first as? EditProjectViewController,
                let project = selection {
                controller.editProjectDelegate = self
                controller.project = project
            }
        }
    }
}
