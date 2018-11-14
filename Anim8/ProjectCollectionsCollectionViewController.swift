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
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
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
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(imageLiteralResourceName: "headPattern.png"), for: .default)
        
        // Version label
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
        let versionString = "V" + version + ".b" + build
        let verButton = UIBarButtonItem(title: versionString, style: .plain, target: self, action: nil)
        verButton.tintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        self.navigationItem.leftBarButtonItem = verButton
        
        // Init Collection
        let numCols = CGFloat(4.0)
        let pad = CGFloat(15)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        //Get device width
        let width = UIScreen.main.bounds.width
        
        // Set section inset as per your requirement.
        layout.sectionInset = UIEdgeInsets(top: pad, left: pad, bottom: pad, right: pad)
        
        // Set cell item size here
        let w = (width - (numCols * pad)) / numCols
        layout.itemSize = CGSize(width: w, height: w)
        
        // Set Minimum spacing between 2 items
        layout.minimumInteritemSpacing = 0
        
        // Set minimum vertical line spacing here between two lines in collectionview
        layout.minimumLineSpacing = 10
        
        // Apply defined layout to collectionview
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
        setDeleteMode(!delMode);
    }
    
    func setDeleteMode(_ val: Bool) {
        print("Delete Mode", val)
        delMode = val
        self.collectionView?.reloadData()
    }
    
    
    @IBAction func helpButtonClick(_ sender: Any) {
        performSegue(withIdentifier: "helpSeg", sender: self)
    }
    
    func deleteProject(project: Project, indexPath: IndexPath) {
        print("Deleting ",indexPath.row)
        
        let deleteAlert = UIAlertController(title: "Are You Sure?", message: "All photos from '\(project.name)' will be perminantly deleted.", preferredStyle: UIAlertController.Style.alert)
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
        // Disable delete if no projects left
        if projects.count == 0 {
            setDeleteMode(false)
            deleteButton.isEnabled = false
        } else {
            deleteButton.isEnabled = true
        }
        return projects.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Fetch Item
        let project = projects[indexPath.row]
        
        //Sequeue Reusable Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "projCollectCell", for: indexPath) as! ProjectCollectionCell
        
        cell.deleteIcon.isHidden = true
        
        cell.numFramesLabel.text = "\(project.frames.count) frames"
        
        // Configure Table View Cell
        cell.titleText?.text = project.name
        cell.thumbView?.image = project.getThumb()
        
        let cellColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0).cgColor;
        let cellDeleteColor = UIColor(red: 0.38, green: 0.18, blue: 0.18, alpha: 1.0).cgColor;
        
        cell.layer.borderColor = cellColor
        cell.layer.backgroundColor = cellColor
        cell.layer.borderWidth = 8.0
        cell.layer.cornerRadius = 4
        
        if delMode {
            cell.deleteIcon.isHidden = false
            cell.layer.borderColor = cellDeleteColor
        } else {
            cell.layer.borderColor = cellColor
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
        projects.insert(project, at: 0)
        
        // Add Row to Table View
//        let indexPath = IndexPath(row: (projects.count - 1), section: 0)
//        collectionView?.insertItems(at: [indexPath])

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
        
        // Turn off delete mode if we transition away.
        setDeleteMode(false)
        
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
