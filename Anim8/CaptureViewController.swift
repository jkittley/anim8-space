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
    var editProjectDelegate: EditProjectDelegate?
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var debugLabel: UILabel!
    @IBOutlet weak var processingView: UIView!
    @IBOutlet weak var toggleVisualisationButton: UIButton!
    @IBOutlet weak var visViewIndicator: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.previewDelegate = self
        frameExtractor.newPhotoDeligate = newPhotoDeligate
        frameExtractor.project = self.project
        frameExtractor.parentController = self
        
        debugLabel.text = (project?.algFeatures)! + " - " + (project?.feedback)!
        
        hideProcessingMessage()
        setFeedbackButton(frameExtractor.showFeedback)
        
        // Hide debug options if devmode is off
        debugLabel.isHidden = !(project?.devMode)!
        
        // Swiping
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        // Swipe indicator
        visViewIndicator.isHidden = !frameExtractor.showFeedback
        visViewIndicator.numberOfPages = Project.CHOICES_VISUALISATIONS.count
        if let proj = project {
            visViewIndicator.currentPage = Project.CHOICES_VISUALISATIONS.index(of: proj.feedback) ?? 0
        }
        
    }

    func processFrame(image: UIImage) {
        imageView.image = image
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        frameExtractor.close()
        frameExtractor = nil;
        dismiss(animated: false, completion: nil)
        newPhotoDeligate?.newPhotoError(message:"Memory Low!", dismiss: false)
    }
    
    // Swipes
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        var swiped = false
        if frameExtractor.showFeedback, let proj = project, let deligate = editProjectDelegate {
            let choices = Project.CHOICES_VISUALISATIONS
            let current = choices.index(of: proj.feedback) ?? 0
            
            if gesture.direction == UISwipeGestureRecognizer.Direction.left {
                print("Swipe left")
                let next = current + 1 < choices.count ? current + 1 : 0
                proj.feedback = choices[next]
                swiped = true
            }
            else if gesture.direction == UISwipeGestureRecognizer.Direction.right {
                print("Swipe right")
                let prev = current > 0 ? current - 1 : choices.count - 1
                proj.feedback = choices[prev]
                swiped = true
            }
            
            if swiped {
                deligate.projectEdited(didUpdateItem: proj)
                visViewIndicator.currentPage = Project.CHOICES_VISUALISATIONS.index(of: proj.feedback) ?? 0
            }
            
        }
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

    @IBAction func toggleVisualisationClick(_ sender: Any) {
        frameExtractor.showFeedback = !frameExtractor.showFeedback
        setFeedbackButton(frameExtractor.showFeedback)
    }
    
    func setFeedbackButton(_ val: Bool) {
        if val {
            toggleVisualisationButton.setImage(UIImage(named: "camVisToggleOn.png"), for: .normal)
            visViewIndicator.isHidden = false
        } else {
            toggleVisualisationButton.setImage(UIImage(named: "camVisToggle.png"), for: .normal)
            visViewIndicator.isHidden = true
        }
    }
    
    func showProcessingMessage() {
        processingView.isHidden = false
    }
    
    func hideProcessingMessage() {
        processingView.isHidden = true
    }

    
}
