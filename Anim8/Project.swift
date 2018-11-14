//
//  Project.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 05/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class Project: NSObject, NSCoding {
    
    // STATIC DEFAULTS
    static let CHOICES_FEATURE_ALGORITHMS    = getFeatureAlgorithmOptions()
    static let CHOICES_DESCRIPTOR_ALGORITHMS = getDescriptorAlgorithmOptions()
    static let CHOICES_VISUALISATIONS        = getVisualisationOptions()
    static let CHOICES_PLAYBACK_INTERVAL     = getPlaybackIntervals()
    
    var uuid: String = NSUUID().uuidString
    var name: String = ""
    var desc: String = ""
    
    var feedback: String
    var algFeatures: String
    var algDescriptor: String
    var playbackFrameRate: Double
    var compareFrameWithFirst: Bool
    
    var keypoints: Bool = false     // Show keypoints overlayt
    var keypointsAdv: Bool = false  // Show advanced keypints
    var hideFrame1: Bool = false
    var orbLimit: Double
    
    var frames : [Frame] = []
    
    var timeCreated = NSDate()
    var timeUpdated = NSDate()
    
    var actionLog : [String] = []
    
    var devMode = false
    
    
    //
    // Static Methods
    //
    
    // Get the default value form the bundlew
    static func getDefaultValueFromBundleAsString(forKey: String) -> String {
        if let prefData = getSettingsPlistData(forKey: forKey)  {
            print (prefData)
            return prefData["DefaultValue"] as? String ?? "None"
        }
        return "None"
    }
    
    // Get the default value from the userData object
    static func getDefaultSelect(forKey: String) -> String {
        let defaultValue = Project.getDefaultValueFromBundleAsString(forKey: forKey)
        UserDefaults.standard.register(defaults: [forKey: defaultValue])
        let userDefaults = UserDefaults.standard
        return userDefaults.value(forKey: forKey) as? String ?? defaultValue
    }
    
    // Get the default value from the userData object
    static func getDefaultDouble(forKey: String) -> Double {
        let userDefaults = UserDefaults.standard
        UserDefaults.standard.register(defaults: [forKey: getPlaybackIntervals()[0] ])
        return userDefaults.double(forKey: forKey)
    }
    
    // Get the default value from the userData object
    static func getDefaultBool(forKey: String) -> Bool {
        let userDefaults = UserDefaults.standard
        UserDefaults.standard.register(defaults: [forKey:false])
        return userDefaults.bool(forKey: forKey)
    }
    
    // Read the setting bundle plist
    private static func getSettingsPlistData(forKey: String) -> AnyObject? {
        //get the path of the plist file
        guard let plistPath = Bundle.main.path(forResource: "Root", ofType: "plist", inDirectory: "Settings.bundle") else { return nil }
        //load the plist as data in memory
        guard let plistData = FileManager.default.contents(atPath: plistPath) else { return nil }
        //use the format of a property list (xml)
        var format = PropertyListSerialization.PropertyListFormat.xml
        //convert the plist data to a Swift Dictionary
        guard let  plistDict = try! PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &format) as? [String : AnyObject] else { return nil }
        // Return
        for dict in plistDict["PreferenceSpecifiers"] as! [AnyObject] {
            if let key = dict["Key"], key != nil {
                if key as! String == forKey {
                    return dict
                }
            }
        }
        return nil
    }
    
   
    
    static func getFeatureAlgorithmOptions() -> [String] {
        if let prefData = getSettingsPlistData(forKey: "defaultAlgFeatures")  {
            //print(prefData["Values"])
            return prefData["Values"] as! [String]
        }
        return[String]()
    }
    
    static func getDescriptorAlgorithmOptions() -> [String] {
        if let prefData = getSettingsPlistData(forKey: "defaultAlgDescriptors")  {
            //print(prefData["Values"])
            return prefData["Values"] as! [String]
        }
        return [String]()
    }
    
    static func getVisualisationOptions() -> [String] {
        if let prefData = getSettingsPlistData(forKey: "defaultVisualisation")  {
            //print(prefData["Values"])
            return prefData["Values"] as! [String]
        }
        return [String]()
    }
    
    static func getPlaybackIntervals() -> [Double] {
        if let prefData = getSettingsPlistData(forKey: "defaultPlaybackInterval")  {
            //print(prefData["Values"])
            return prefData["Values"] as! [Double]
        }
        return [Double]()
    }
    
    
    //
    // Initialisation
    //
    
  
    init(name: String) {
        self.name = name
        self.timeCreated = NSDate()
        self.timeUpdated = NSDate()
        
        self.feedback = Project.getDefaultSelect(forKey: "defaultVisualisation")
        self.algFeatures = Project.getDefaultSelect(forKey: "defaultAlgFeatures")
        self.algDescriptor = Project.getDefaultSelect(forKey: "defaultAlgDescriptors")
        self.playbackFrameRate = Project.getDefaultDouble(forKey: "defaultPlaybackInterval")
        self.compareFrameWithFirst = Project.getDefaultBool(forKey: "defaultTranformToFirstFrame")
        
        self.keypointsAdv = Project.getDefaultBool(forKey: "defaultKeypointsAdv")
        self.hideFrame1 = Project.getDefaultBool(forKey: "defaultHideFirstFrame")
        self.keypoints = Project.getDefaultBool(forKey: "defaultAlwaysKeypoints")
        self.devMode = Project.getDefaultBool(forKey: "defaultDebugMessages")
        self.orbLimit = Project.getDefaultDouble(forKey: "defaultORBLimit")
   
        print("---> Creating a new project")
        print("feedback: ", self.feedback)
        print("algFeatures:", self.algFeatures)
        print("algDescriptor:", self.algDescriptor)
        print("playbackFrameRate:", self.playbackFrameRate)
        print("compareFrameWithFirst:", self.compareFrameWithFirst)
        print("hideFrame1:", self.hideFrame1)
        print("defaultORBLimit:", self.orbLimit)
        super.init()
    }
    
    init(frames: [Frame], name: String, desc:String, uuid: String, feedback: String, algFeatures: String, playbackFrameRate: Double, timeCreated: NSDate, timeEdited: NSDate, actionLog: [String], keypoints: Bool, keypointsAdv: Bool, compareFrameWithFirst: Bool, devMode: Bool, algDescriptor: String, hideFrame1: Bool, orbLimit: Double) {
        
        print("---> Loading an existing project")
        
        self.frames = frames
        self.name = name
        self.desc = desc
        self.uuid = uuid
        self.feedback = feedback
        self.algFeatures = algFeatures
        self.keypoints = keypoints
        self.keypointsAdv = keypointsAdv
        self.timeCreated = timeCreated
        self.timeUpdated = timeEdited
        self.actionLog = actionLog
        self.compareFrameWithFirst = compareFrameWithFirst
        self.devMode = devMode
        self.algDescriptor = algDescriptor
        self.playbackFrameRate = playbackFrameRate
        self.hideFrame1 = hideFrame1
        self.orbLimit = orbLimit
        super.init()
    }
    
    //
    // Save
    //
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uuid, forKey: "uuid")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(desc, forKey: "desc")
        aCoder.encode(feedback, forKey: "feedback")
        aCoder.encode(algFeatures, forKey: "algotithm")
        aCoder.encode(frames, forKey: "frames")
        aCoder.encode(playbackFrameRate, forKey: "playbackFrameRate")
        aCoder.encode(timeCreated, forKey: "timeCreated")
        aCoder.encode(timeUpdated, forKey: "timeUpdated")
        aCoder.encode(actionLog, forKey: "actionLog")
        aCoder.encode(keypoints, forKey: "keypoints")
        aCoder.encode(keypointsAdv, forKey: "keypointsAdv")
        aCoder.encode(compareFrameWithFirst, forKey: "compareFrameWithFirst")
        aCoder.encode(devMode, forKey: "devMode")
        aCoder.encode(algDescriptor, forKey: "algDescriptor")
        aCoder.encode(hideFrame1, forKey: "hideFrame1")
        aCoder.encode(orbLimit, forKey: "orbLimit")
//        print ("saving name...", name)
//        print ("saving keypoints...", keypoints)
//        print ("saving kp adv...", keypointsAdv)
    }
    
    //
    // Helper functions
    //
    
    func getThumb() -> UIImage {
        if frames.count > 0 {
            return frames.first!.image!
        } else {
            return UIImage(named: "defaultThumb.png")!
        }
    }
    
    func getMostRecentFrame() -> Frame? {
        if frames.count > 0 {
            return frames.last
        } else {
            return nil
        }
    }
    
    //
    // Load
    //
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        let archivedFrames = aDecoder.decodeObject(forKey: "frames") as? [Frame] ?? []
        let archivedUuid = aDecoder.decodeObject(forKey: "uuid") as? String
        
        let archivedName = aDecoder.decodeObject(forKey: "name") as? String ?? "No Name"
        let archivedDesc = aDecoder.decodeObject(forKey: "desc") as? String ?? ""
        
        let archivedFeedback = aDecoder.decodeObject(forKey: "feedback") as? String ?? Project.getDefaultSelect(forKey: "defaultVisualisation")
        let archivedAlgotithm = aDecoder.decodeObject(forKey: "algotithm") as? String ?? Project.getDefaultSelect(forKey: "defaultAlgFeqtures")
        let archivedAlgDescriptor = aDecoder.decodeObject(forKey: "algDescriptor") as? String ?? Project.getDefaultSelect(forKey: "defaultAlgDescriptor")
        
        let archivedCompareFrameWithFirst = aDecoder.decodeObject(forKey: "compareFrameWithFirst") as? Bool ?? aDecoder.decodeBool(forKey: "compareFrameWithFirst")
        
        let archivedKeypoints = aDecoder.decodeObject(forKey: "keypoints") as? Bool ?? aDecoder.decodeBool(forKey: "keypoints")
        let archivedKeypointsAdv = aDecoder.decodeObject(forKey: "keypointsAdv") as? Bool ?? aDecoder.decodeBool(forKey: "keypointsAdv")

        let archivedPlaybackFrameRate = aDecoder.decodeObject(forKey: "playbackFrameRate") as? Double ?? Project.getDefaultDouble(forKey: "defaultPlaybackInterval")
        
        let archivedTimeCreated = aDecoder.decodeObject(forKey: "timeCreated") as? NSDate ?? NSDate()
        let archivedTimeEdited = aDecoder.decodeObject(forKey: "timeEdited") as? NSDate ?? NSDate()
        
        let archivedActionLog = aDecoder.decodeObject(forKey: "actionLog") as? [String] ?? []
        
        let archivedDevMode = aDecoder.decodeObject(forKey: "devMode") as? Bool ?? aDecoder.decodeBool(forKey: "devMode")
        
        let archivedHideFrame1 = aDecoder.decodeObject(forKey: "hideFrame1") as? Bool ?? aDecoder.decodeBool(forKey: "hideFrame1")
        
        let archivedORBLimit = aDecoder.decodeObject(forKey: "orbLimit") as? Double ?? Project.getDefaultDouble(forKey: "defaultORBLimit")

        
        self.init(
            frames: archivedFrames,
            name: archivedName,
            desc: archivedDesc,
            uuid: archivedUuid!,
            feedback: archivedFeedback,
            algFeatures: archivedAlgotithm,
            playbackFrameRate: archivedPlaybackFrameRate,
            timeCreated: archivedTimeCreated,
            timeEdited: archivedTimeEdited,
            actionLog: archivedActionLog,
            keypoints: archivedKeypoints,
            keypointsAdv: archivedKeypointsAdv,
            compareFrameWithFirst: archivedCompareFrameWithFirst,
            devMode: archivedDevMode,
            algDescriptor: archivedAlgDescriptor,
            hideFrame1: archivedHideFrame1,
            orbLimit: archivedORBLimit
        )
    }
    
}
