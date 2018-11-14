//
//  CaptureViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 10/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit


class CaptureViewController: UIViewController, PreviewFrameExtractorDelegate {
    
    var frameExtractor: FrameExtractor!
    var project: Project?
    var newPhotoDeligate: NewPhotoDelegate?
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var debugLabel: UILabel!
    @IBOutlet weak var processingView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.previewDelegate = self
        frameExtractor.newPhotoDeligate = newPhotoDeligate
        frameExtractor.project = self.project
        frameExtractor.parentController = self
        
        debugLabel.text = (project?.algFeatures)! + " - " + (project?.feedback)!
        
        hideProcessingMessage()
        
        // Hide debug options if devmode is off
        debugLabel.isHidden = !(project?.devMode)!
    }

    func processFrame(image: UIImage) {
        imageView.image = image
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        frameExtractor.close()
        dismiss(animated: true, completion: nil)
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -
    // MARK: Actions
    @IBAction func back(sender: UIBarButtonItem) {
        frameExtractor.close()
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: -
    // MARK: Actions
    @IBAction func save(sender: UIBarButtonItem) {
        showProcessingMessage();
        frameExtractor.capturePhoto()
    }

    func showProcessingMessage() {
        processingView.isHidden = false
    }
    
    func hideProcessingMessage() {
        processingView.isHidden = true
    }

    
}
