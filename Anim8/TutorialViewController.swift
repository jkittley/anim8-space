//
//  TutorialViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 24/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class TutorialViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        // Custom Title Image
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "navbar.png"))
        self.navigationController?.navigationBar.tintColor = UIColor.white;
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(imageLiteralResourceName: "headPattern.png"), for: .default)
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
        
//        let pageControl = UIPageControl()
//        pageControl.pageIndicatorTintColor = UIColor.white
//        pageControl.currentPageIndicatorTintColor = UIColor.yellow
//        pageControl.backgroundColor = UIColor.black
//        self.view.addSubview(pageControl)
        
       // self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        
        return [self.tutorialViewController(slide: "tut1"),
                self.tutorialViewController(slide: "tut3"),
                self.tutorialViewController(slide: "tut2")]
    }()
    
    private func tutorialViewController(slide: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "\(slide)ViewController")
    }
    
}


extension TutorialViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
}
