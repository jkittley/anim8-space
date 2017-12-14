//
//  SettingsMainTableViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 30/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class SettingsMainTableViewController: UITableViewController, SettingsPickerDelegate {
    
    // Set by Segue
    var project: Project?
    var editProjectDelegate: EditProjectDelegate?
    
    //
    var playbackIntervalOptions = Project.CHOICES_PLAYBACK_INTERVAL
    
    // Setting pickers variables
    var settingsRespondIndex: IndexPath?
    var settingsPickerTitle = "Choices"
    var settingsPickerChoices: [String]?
    var settingsPickerInitial: Int?
    var newFeatureChoice: String?
    var newDescriptorChoice: String?
    var newVisualisationChoice: String?
    
    
    let section_description_ip = IndexPath(row: 1, section: 0)
    let section_dev_and_debug = 5
    let section_algorithms = 2
    let section_visualisations = 3
    let section_save_as_default = 6
    
    var showDeveloperDebugOptions = false
    var showAlgorithmOptions = true
    var showVisualisationOptions = true
    var hideFrame1Option = false
    
    let userDefaults = UserDefaults.standard
    
    // General
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var descriptionText: UITextView!
    // Playback
    @IBOutlet weak var playbackLabel: UILabel!
    @IBOutlet weak var plackbackStepper: UIStepper!
    // Feedback & Processing
    @IBOutlet weak var featureAlgLabel: UILabel!
    @IBOutlet weak var descriptorAlgLabel: UILabel!
    @IBOutlet weak var visualisationLabel: UILabel!
    // Advanced
    @IBOutlet weak var transformChoice: UISegmentedControl!
    // Dev & Debug
    @IBOutlet weak var debugMessagesSwitch: UISwitch!
    @IBOutlet weak var overlayKeypointsSwitch: UISwitch!
    @IBOutlet weak var advancedKeypointsSwitch: UISwitch!
    @IBOutlet weak var advancedHideFramne1Switch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get app settings
        UserDefaults.standard.register(defaults: ["enabled_dev_options":showDeveloperDebugOptions, "allow_algorithm_options":showAlgorithmOptions, "allow_visualisation_options":showVisualisationOptions, "hide_first_frame":hideFrame1Option])
        showDeveloperDebugOptions   = userDefaults.bool(forKey: "enabled_dev_options")
        showAlgorithmOptions        = userDefaults.bool(forKey: "allow_algorithm_options")
        showVisualisationOptions    = userDefaults.bool(forKey: "allow_visualisation_options")
        hideFrame1Option            = userDefaults.bool(forKey: "hide_first_frame")
        
        // Custom Title Image
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "navbar.png"))
        self.navigationController?.navigationBar.tintColor = UIColor.white;
        
        // UI Tweeks
        descriptionText.layer.cornerRadius = 4
        descriptionText.layer.borderWidth = 1
        descriptionText.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        plackbackStepper.wraps = true
        plackbackStepper.autorepeat = true
        plackbackStepper.maximumValue = Double(playbackIntervalOptions.count) - 1
        
        // Init state
        if let proj = project {
            // General
            titleText.text = proj.name
            descriptionText.text = proj.desc
            // Playback
            playbackLabel.text = getPlaybackLabelText(t: proj.playbackFrameRate)
            if let pbid = playbackIntervalOptions.index(of: proj.playbackFrameRate) {
                plackbackStepper.value = Double(Int(pbid))
            }
            // Feedback and Processing
            newFeatureChoice       = project!.algFeatures
            newDescriptorChoice    = project!.algDescriptor
            newVisualisationChoice = project!.feedback
            featureAlgLabel.text    = getFeatureText(algorithm: newFeatureChoice!)
            descriptorAlgLabel.text = getDescriptorText(algorithm: newDescriptorChoice!)
            visualisationLabel.text = getVisualisationeText(visualisation: newVisualisationChoice!)
            // Advanced
            transformChoice.selectedSegmentIndex = proj.compareFrameWithFirst ? 0 : 1
            // Developer
            debugMessagesSwitch.setOn(proj.devMode, animated: false)
            overlayKeypointsSwitch.setOn(proj.keypoints, animated: false)
            advancedKeypointsSwitch.setOn(proj.keypointsAdv, animated: false)
            advancedHideFramne1Switch.setOn(proj.hideFrame1, animated: false)
            
            printAll();
            
        } else {
            // Throw error when no project
            showAlert(title: "Error", message: "Sorry an error has occurred, please close and reopen the app.")
            dismiss(animated: false, completion: nil)
        }
    }
    
    //
    // Hide Dev and debig section
    //
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == section_dev_and_debug && !showDeveloperDebugOptions {
            return 0.0
        } else if indexPath.section == section_algorithms && !showAlgorithmOptions {
            return 0.0
        } else if indexPath.section == section_visualisations && !showVisualisationOptions {
            return 0.0
        } else if indexPath == section_description_ip {
            print("Making")
            return 100.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == section_dev_and_debug && !showDeveloperDebugOptions {
            return CGFloat.leastNonzeroMagnitude
        } else if section == section_algorithms && !showAlgorithmOptions {
            return CGFloat.leastNonzeroMagnitude
        } else if section == section_visualisations && !showVisualisationOptions {
            return CGFloat.leastNonzeroMagnitude
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.clipsToBounds = true
    }
    
    //
    // Helpers
    //
    
    // Show alert
    func showAlert(title: String, message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Debug messages
    func printAll() {
        print("editProjectDelegate: ", editProjectDelegate ?? "No deligate")
        
        print("Name ------------------", project!.name)
        print("Playback Rate ---------", project!.playbackFrameRate)
        print("UUID ------------------", project!.uuid)
        print("Algorithm Features ----", project!.algFeatures)
        print("Algorithm Descriptors -", project!.algDescriptor)
        print("Feeback Visualisation -", project!.feedback)
        print("Keypoints On ----------", project!.keypoints)
        print("Keypoints Adv ---------", project!.keypointsAdv)
        print("Dev Mode --------------", project!.devMode)
        print("Hide Frame 1 --------------", project!.hideFrame1)
        
    }
    
    //
    // UI Interactions
    //
   
    func saveAsDefaults() {
        print("Saving as defaults")
        // Other
        userDefaults.set((transformChoice.selectedSegmentIndex==0), forKey: "defaultTranformToFirstFrame")
        userDefaults.set(playbackIntervalOptions[Int(plackbackStepper.value)], forKey: "defaultPlaybackInterval")
        // Feedback
        if let choice = newFeatureChoice { userDefaults.set(choice, forKey:"defaultAlgFeatures") }
        if let choice = newDescriptorChoice { userDefaults.set(choice, forKey:"defaultAlgDescriptors") }
        if let choice = newVisualisationChoice { userDefaults.set(choice, forKey:"defaultVisualisation") }
        
        showAlert(title: "Saved", message: "Settings saved as defaults.")
    }
    
    // Cancel
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    // Save
    @IBAction func save(_ sender: Any) {
        if let proj = project {
            // General
            proj.name = titleText.text ?? "No title"
            proj.desc = descriptionText.text ?? ""
            // Advanced
            proj.compareFrameWithFirst = (transformChoice.selectedSegmentIndex==0)
            // Feedback
            if let choice = newFeatureChoice { proj.algFeatures = choice }
            if let choice = newDescriptorChoice { proj.algDescriptor = choice }
            if let choice = newVisualisationChoice { proj.feedback = choice }
            // Dev
            proj.devMode = debugMessagesSwitch.isOn
            proj.keypoints = overlayKeypointsSwitch.isOn
            proj.keypointsAdv = advancedKeypointsSwitch.isOn
            proj.hideFrame1 = advancedHideFramne1Switch.isOn
            // Playback
            proj.playbackFrameRate = playbackIntervalOptions[Int(plackbackStepper.value)]
            // Notify deligate of changes
            editProjectDelegate?.projectEdited(didUpdateItem: proj)
        }
        printAll()
        dismiss(animated: true, completion: nil)
    }
    
    // Stepper - Play interval
    @IBAction func playIntervalStepperChnaged(_ sender: UIStepper) {
        let idx = Int(sender.value)
        playbackLabel.text = getPlaybackLabelText(t: playbackIntervalOptions[idx])
    }
    
    //
    // Format strings
    //
    
    func getPlaybackLabelText(t: Double) -> String {
        return String(t) + " seconds"
    }
    
    func getFeatureText(algorithm: String) -> String {
        return algorithm.capitalized
    }
    
    func getDescriptorText(algorithm: String) -> String {
        return algorithm.capitalized
    }
    
    func getVisualisationeText(visualisation: String) -> String {
        return visualisation.capitalized
    }
    
    // On row click - show settings picker view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.section)
        if (indexPath.section == section_algorithms || indexPath.section == section_visualisations) {
            openSettingsPicker(index: indexPath)
        } else if (indexPath.section == section_save_as_default) {
            saveAsDefaults()
        }
    }
    
    // Open swttings picker
    func openSettingsPicker (index: IndexPath) {
        settingsPickerChoices = nil
        settingsPickerInitial = nil
        settingsRespondIndex = index
        
        if (index.section==section_algorithms && index.row == 0) {
            settingsPickerTitle   = "Feature Identification Algorithms"
            settingsPickerChoices = Project.CHOICES_FEATURE_ALGORITHMS
            settingsPickerInitial = Project.CHOICES_FEATURE_ALGORITHMS.index(of: newFeatureChoice!)
        } else if (index.section==section_algorithms && index.row == 1) {
            settingsPickerTitle   = "Feature Matching Algorithms"
            settingsPickerChoices = Project.CHOICES_DESCRIPTOR_ALGORITHMS
            settingsPickerInitial = Project.CHOICES_DESCRIPTOR_ALGORITHMS.index(of: newDescriptorChoice!)
        } else if (index.section==section_visualisations && index.row == 0){
            settingsPickerTitle   = "Visualisations"
            settingsPickerChoices = Project.CHOICES_VISUALISATIONS
            settingsPickerInitial = Project.CHOICES_VISUALISATIONS.index(of: newVisualisationChoice!)
        }
        // If there are choices
        if settingsPickerChoices != nil {
            // Set default is unknown
            print(settingsPickerInitial ?? "Error no init value, so picking first")
            if settingsPickerInitial == nil { settingsPickerInitial = 0 }
            // Launch settings picker
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "settingsPicker", sender: self)
            }
        }
    }
   
    // Pass variables on segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        backItem.tintColor = UIColor.white
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "settingsPicker" {
            if let controller = segue.destination as? SettingsPickerTableViewController {
                controller.settingsPickerDelegate = self
                controller.choicesTitle = settingsPickerTitle
                controller.choices = settingsPickerChoices!
                print("settingsPickerInitial", settingsPickerInitial!)
                controller.selected = settingsPickerInitial
            }
         }
    }
    
    // Return from settings picker
    func settingChosen(choice: String) {
        if let index = settingsRespondIndex {
            if (index.section == section_algorithms && index.row == 0) {
                newFeatureChoice = choice.lowercased()
                featureAlgLabel.text = getFeatureText(algorithm: choice)
            } else if (index.section == section_algorithms && index.row == 1) {
                newDescriptorChoice = choice.lowercased()
                descriptorAlgLabel.text = getDescriptorText(algorithm: choice)
            } else if (index.section == section_visualisations && index.row == 0){
                newVisualisationChoice = choice.lowercased()
                visualisationLabel.text = getVisualisationeText(visualisation: choice)
            }
        }
    }

}
