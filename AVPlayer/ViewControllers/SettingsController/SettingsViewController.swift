//
//  SettingsViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 11/14/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    let kSettingsDeleteMode = "delete"
    let kSettingsSort = "sort"
    
    @IBOutlet weak var deleteAutomaticalySwitcher: UISwitch!
    @IBOutlet weak var sortControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
    }
    
    @IBAction func deleteAutomaticalyValueChanged(_ sender: Any) {
        saveSettings()
    }
    
    @IBAction func sortValueChanged(_ sender: Any) {
        saveSettings()
    }
    
    @IBAction func resetAction(_ sender: Any) {
        deleteAutomaticalySwitcher.setOn(false, animated: true)
        sortControl.selectedSegmentIndex = 0
        saveSettings()
    }
    //MARK: - Save and Load
    
    func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(deleteAutomaticalySwitcher.isOn, forKey: kSettingsDeleteMode)
        userDefaults.setValue(sortControl.selectedSegmentIndex, forKey: kSettingsSort)
        userDefaults.synchronize()
    }
    
    func loadSettings() {
        let userDefaults = UserDefaults.standard
        deleteAutomaticalySwitcher.isOn = userDefaults.bool(forKey: kSettingsDeleteMode)
        sortControl.selectedSegmentIndex = userDefaults.integer(forKey: kSettingsSort)
    }

}
