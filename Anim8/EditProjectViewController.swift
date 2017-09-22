//
//  EditProjectViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 10/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
import AVFoundation

protocol EditProjectDelegate {
    func projectEdited(didUpdateItem project: Project)
}

class EditProjectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NewPhotoDelegate {
    
    var editProjectDelegate: EditProjectDelegate?
    var project: Project?
    let CellIdentifier = "cell"
    weak var playTimer: Timer?
    var playPos = 0
    var selectedFrame: Frame?
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var debugLabel: UILabel!
    @IBOutlet var captureButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var playButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Custom Title Image
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "navbar.png"))
        // Other
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: CellIdentifier)
        // Backl button
        let backButton = UIBarButtonItem(title: "Projects", style: .plain, target: self, action: #selector(self.goBack))
        backButton.tintColor = UIColor.white
        self.navigationItem.leftBarButtonItem = backButton
        // On reload of table
        tableView.reloadData {
            if !self.tableView.isHidden {
                self.scrollToBottom()
            }
        }
        // Set init frame
        showFrame(frame: self.project!.getMostRecentFrame())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDebugLabel()
    }
    
    //
    // UI Interactions
    //
    
    //
    func showFrame(frame: Frame?) {
        imageView.clipsToBounds = true;
        
        selectedFrame = frame
        if (selectedFrame == nil) {
            imageView.contentMode = .center
            
            imageView.image = UIImage(named: "defaultFrame2.png")
                //?.resizeImageWith(newSize: imageView.frame.size)
        } else {
            imageView.contentMode = .scaleAspectFit
            imageView.image = selectedFrame?.image
        }
        
        updateDebugLabel()
    }
    
    @objc func goBack(sender: UIBarButtonItem) {
        // Pop View Controller
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
            navController.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func settings(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "EditProjectSettings", sender: self)
    }
    
    @IBAction func capture(sender: UIBarButtonItem) {
        // Has the camera been authorised?
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.authorized {
            // Yes
            performSegue(withIdentifier: "CaptureViewController", sender: self)
        } else if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.denied {
            // Declined
            let title = "Permission Denied"
            let message = "You have previously denied access to the camera. Please grant permission by visiting the devices main settings."
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            present(alertController, animated: true, completion: nil)
        } else {
            // Not asked
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
                if granted {
                    self.performSegue(withIdentifier: "CaptureViewController", sender: self)
                } else {
                    let title = "Permission Denied"
                    let message = "You have denied access to the camera. To take pictures you must grant access. Please grant permission by visiting the devices main settings."
                    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(OKAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    @IBAction func delete(sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    @IBAction func share(sender: UIBarButtonItem) {
        var images = [UIImage]()
        let frames = project?.frames
        for frame in frames! {
            if let image:UIImage = frame.image {
                images.append(image)
            }
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let gifPath = documentsURL!.appendingPathComponent("anim8.gif")
        
        // Make gif
        createGIF(with: images, name: gifPath, frameDelay: (project?.playbackFrameRate)!)
        
        let pathURL = URL(fileURLWithPath: gifPath.path)
        do {
            let imageData: NSData = try NSData(contentsOf: pathURL)
            let objectsToShare: [AnyObject] = [imageData]
            let vc = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            vc.popoverPresentationController?.barButtonItem = sender
            self.present(vc, animated: true, completion: nil)
        } catch {
            let title = "Something went wrong!"
            let message = "The animated GIF creation failed, Please try again."
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //
    // Create GIF
    //

    func createGIF(with images: [UIImage], name: URL, loopCount: Int = 0, frameDelay: Double)  {
        let destinationURL = name
        let destinationGIF = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypeGIF, images.count, nil)!
        // This dictionary controls the delay between frames
        // If you don't specify this, CGImage will apply a default delay
        let properties = [
            (kCGImagePropertyGIFDictionary as String): [(kCGImagePropertyGIFDelayTime as String): frameDelay]
        ]
        for img in images {
            // Convert an UIImage to CGImage, fitting within the specified rect
      
            let rot = OpenCVWrapper.rotate(img, arg2: 270)
            let cgImage = rot.cgImage
        
            // Add the frame to the GIF image
            CGImageDestinationAddImage(destinationGIF, cgImage!, properties as CFDictionary?)
        }
        // Write the GIF file to disk
      
        CGImageDestinationFinalize(destinationGIF)
    }

    
    //
    // Playback
    //
    
    func deselectAll() {
        if let selectedItems = tableView.indexPathsForSelectedRows {
            for indexPath in selectedItems {
                tableView.deselectRow(at: indexPath, animated: true)
                if let cell = tableView.cellForRow(at: indexPath) as? ProjFrameTableViewCell {
                    cell.layer.borderColor = UIColor.clear.cgColor
                }
            }
        }
    }
    
    func UpdateBarButtonIcon(button: UIBarButtonItem, newStyle: UIBarButtonSystemItem) {
        // Update playPauseButton type.
        let newButton = UIBarButtonItem(barButtonSystemItem: newStyle, target: self, action:button.action)
        newButton.tintColor = UIColor.white;
        var navItems = self.navigationController?.toolbar.items
        if navItems != nil {
            guard let idx = navItems?.index(of: button) else { return }
            if (idx >= 0) {
                navItems?[idx] = newButton;
                self.navigationController?.toolbar.setItems(navItems!, animated: false);
            }
        }
    }
    
    @IBAction func play(sender: UIBarButtonItem) {
        if (playTimer == nil) {
            deselectAll()
            playPos = 0
            if (project?.frames.count)! > 1 {
                playTimer = Timer.scheduledTimer(timeInterval: self.project!.playbackFrameRate, target: self, selector: #selector(EditProjectViewController.playback), userInfo: nil, repeats: true)
                UpdateBarButtonIcon(button: sender, newStyle: UIBarButtonSystemItem.pause)
                activateControls()
            }
        } else {
            UpdateBarButtonIcon(button: sender, newStyle: UIBarButtonSystemItem.play)
            playTimer?.invalidate()
            activateControls()
        }
    }
    
    @objc func playback() {
        let indexPath = IndexPath(row: playPos, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        showFrame(frame: self.project!.frames[indexPath.row])
        playPos = playPos + 1
        if playPos >= self.tableView.numberOfRows(inSection: 0) {
            playPos = 0
        }
    }
    
    
    //
    // Thumbnails Manager
    //
    
    func activateControls() {
        self.tableView.isHidden = true
        self.deleteButton.isEnabled = false
        self.playButton.isEnabled = false
        self.shareButton.isEnabled = false
        self.captureButton.isEnabled = true
        
        if self.project!.frames.count > 0 {
            self.tableView.isHidden = false
            self.deleteButton.isEnabled = (playTimer == nil)
        }
        if self.project!.frames.count > 1 {
            self.playButton.isEnabled = true
            self.shareButton.isEnabled = true
        }
        if playTimer != nil {
            self.captureButton.isEnabled = false
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activateControls()
        return self.project!.frames.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let frame = (project?.frames[indexPath.row])!
        let cell = tableView.dequeueReusableCell(withIdentifier: "frameCell", for: indexPath) as! ProjFrameTableViewCell
        cell.thumbView?.image = frame.image
        return cell
    }
    
    func tableView(_: UITableView, didSelectRowAt: IndexPath) {
        // Fetch Item
        selectedFrame = project!.frames[didSelectRowAt.row]
        showFrame(frame: selectedFrame)
        let cell  = tableView.cellForRow(at: didSelectRowAt)
        cell!.layer.borderColor = UIColor.orange.cgColor
        cell!.layer.borderWidth = 4.0
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell!.layer.borderColor = UIColor.clear.cgColor
        cell!.layer.borderWidth = 4.0
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // If not animating then allow delete
        return (playTimer == nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
    
            var newRowToSelect = -1
            
            if indexPath.row >= 1 {
                newRowToSelect = indexPath.row - 1
            } else if indexPath.row == 0 && (project?.frames.count)! > 1 {
                newRowToSelect = indexPath.row + 1
            }
            
            if newRowToSelect >= 0 {
                let newIndexPath = IndexPath(row: newRowToSelect, section: 0)
                self.tableView.selectRow(at: newIndexPath, animated: true, scrollPosition: .bottom)
                showFrame(frame: self.project!.frames[newIndexPath.row])
            } else {
                // This will pick the empty cell
                showFrame(frame: nil)
            }
                
            // Delete frame
            self.project?.frames.remove(at: indexPath.row)
                
            // Delete row from table view
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Update controls
            activateControls()
            
            // Notify Delegate
            self.editProjectDelegate?.projectEdited(didUpdateItem: self.project!)
            
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func scrollToBottom() {
        if let project = self.project, project.frames.count > 0 {
            let lastIndex = IndexPath(row: project.frames.count - 1, section: 0)
            self.tableView.scrollToRow(at: lastIndex, at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    

    
    
    //
    // Other
    //
    
    func updateDebugLabel() {
        if selectedFrame == nil {
            debugLabel.text = "Please select a frame or capture an image."
        } else {
            debugLabel.text = selectedFrame?.madeBy
        }
        debugLabel.isHidden = !(project?.devMode)!
    }    
    
    
    //
    // Deligates
    //
    
    func currentTopViewController() -> UIViewController {
        var topVC: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
        while ((topVC?.presentedViewController) != nil) {
            topVC = topVC?.presentedViewController
        }
        return topVC!
    }
    
    
    func newPhotoError(message: String, dismiss: Bool) {
        if dismiss {
            // Dismiss the camera preview window
            self.dismiss(animated: false, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let title = "Processing failed"
            let message = message + " Please try again."
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            let currentTopVC: UIViewController = self.currentTopViewController()
            currentTopVC.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    func newPhoto(newImage: UIImage?, message: String) {
        if let image = newImage {
            
            let madeBy = (project?.algFeatures)! + " - " + (project?.feedback)!
            let frame = Frame(name: "BOB", image: image, madeBy: madeBy)
            project?.frames.append(frame)
            
            // Notify Delegate
            self.editProjectDelegate?.projectEdited(didUpdateItem: self.project!)
            
            // Reload table
            tableView.reloadData()
            showFrame(frame: frame)
            scrollToBottom()
            
            // Dismiss the camera preview window
            dismiss(animated: false, completion: nil)
            
        } else {
            newPhotoError(message: message, dismiss: false)
        }
    }
    
    
    //
    // Segue
    //
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CaptureViewController" {
            if let captureViewController = segue.destination as? CaptureViewController {
                captureViewController.project = project
                captureViewController.newPhotoDeligate = self
            }
        }
        
        if segue.identifier == "EditProjectSettings" {
            if let navigationController = segue.destination as? UINavigationController,
                let controller = navigationController.viewControllers.first as? SettingsMainTableViewController {
                controller.project = project
                controller.editProjectDelegate = editProjectDelegate
            }
        }
        
    }
    
}



//
// Extensions
//

extension UITableView {
    func reloadData(completion: @escaping ()->()) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() })
        { _ in completion() }
    }
}

extension UIImage {
    func resizeImageWith(newSize: CGSize) -> UIImage {
    
 
        let horizontalRatio = newSize.width / self.size.width
        let verticalRatio = newSize.height / self.size.height
    
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
        var newImage: UIImage
    
        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newSize.width, height: newSize.height), format: renderFormat)
        newImage = renderer.image {
            (context) in self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        }
        return newImage
    }
}

