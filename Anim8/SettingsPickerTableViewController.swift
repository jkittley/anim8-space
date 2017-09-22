//
//  SettingsPickerTableViewController.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 30/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

protocol SettingsPickerDelegate {
    func settingChosen(choice: String)
}

class SettingsPickerTableViewController: UITableViewController {
    
    // Variables set by segue
    var settingsPickerDelegate: SettingsPickerDelegate?
    var choicesTitle = "Choices"
    var choices = [String]()
    var selected: Int?
    
    // Variables for grouped choices
    var sections = [String]()
    var choicesBySection = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Custom Title Image
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "navbar.png"))
        self.navigationController?.navigationBar.tintColor = UIColor.white;
        
        // Initialise by group choices variables
        sections.append(choicesTitle)
        choicesBySection[choicesTitle] = [String]()
        
        // Debug output
        print("----- Settings Picker Openned -----")
        print("choicesTitle", choicesTitle)
        print("choices", choices)
        print("selected", selected!, choices[selected ?? 0])
        
        // Divide chices into groups based on first word
        for choice in choices {
            let parts = choice.components(separatedBy: " ")
            let grp = (parts.count==1) ? choicesTitle : parts[0]
            // Add blank if group name not seen before
            if choicesBySection[grp] == nil {
                choicesBySection[grp] = [String]()
                sections.append(grp)
            }
            if choicesBySection[grp] != nil {
                choicesBySection[grp]!.append(choice)
            }
        }
    }

    //
    // Table view functions
    //
    
    // Section titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].capitalized
    }
    
    // Number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    // Number of rows for section x
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choicesBySection[sections[section]]!.count
    }

    // Populate cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Init cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "choiceCell", for: indexPath)
        cell.textLabel?.text = "Error"
        // Get choices
        if let sectionChoices = choicesBySection[sections[indexPath.section]] {
            if indexPath.row < sectionChoices.count {
                let sectionChoice = sectionChoices[indexPath.row]
                cell.textLabel?.text = sectionChoice.capitalized
                cell.accessoryType = (sectionChoice == choices[selected!]) ? .checkmark : .none
            }
        }
        return cell
    }
 
    // Disable editing
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // On row selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get choices for section
        if let sectionChoices = choicesBySection[sections[indexPath.section]] {
            let sectionChoice = sectionChoices[indexPath.row]
            // Selt selected
            selected = choices.index(of: sectionChoice)
            // On table reload
            tableView.reloadData {
                self.settingsPickerDelegate?.settingChosen(choice: self.choices[self.selected!])
                self.navigationController?.popViewController(animated: true)
            }
            // Reload table
            tableView.reloadData()
        }
    }
 
}
