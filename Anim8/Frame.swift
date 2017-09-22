//
//  Frame.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 11/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class Frame: NSObject, NSCoding {
    
    var uuid: String = NSUUID().uuidString
    var name: String = ""
    var image: UIImage?
    var timeCreated: Date = Date()
    var madeBy: String = ""

    
    init(name: String, image: UIImage, madeBy: String) {
        super.init()
        self.name = name
        self.image = image
        self.madeBy = madeBy
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uuid, forKey: "uuid")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(image, forKey: "image")
        aCoder.encode(timeCreated, forKey: "timeCreated")
        aCoder.encode(madeBy, forKey: "madeBy")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        
        if let archivedTimeCreated = aDecoder.decodeObject(forKey: "timeCreated") as? Date {
            timeCreated = archivedTimeCreated
        }
        
        if let archivedUuid = aDecoder.decodeObject(forKey: "uuid") as? String {
            uuid = archivedUuid
        }
        
        if let archivedName = aDecoder.decodeObject(forKey: "name") as? String {
            name = archivedName
        }
        
        if let archivedImage = aDecoder.decodeObject(forKey: "image") as? UIImage {
            image = archivedImage
        }
        
        if let archivedMadeBy = aDecoder.decodeObject(forKey: "madeBy") as? String {
            madeBy = archivedMadeBy
        }
        
    }
    
}
