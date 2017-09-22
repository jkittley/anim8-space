//
//  Tut2ViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 25/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class Tut2ViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    var playTimer: Timer?
    var counter = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playTimer = Timer.scheduledTimer(timeInterval: 0.15, target: self, selector: #selector(self.playback), userInfo: nil, repeats: true)
    }
    
    @objc func playback() {
        
        print("a\(counter).png")
        
        if let img = UIImage(named: "a\(counter).png") {
            imageView.image = img
        }
        if counter < 14 {
            counter += 1
        } else {
            counter = 0
        }
        // Stop when tutorial closed
        if (view.window == nil) {
            playTimer?.invalidate()
        }
    }

}
