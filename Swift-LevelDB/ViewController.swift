//
//  ViewController.swift
//  Swift-LevelDB
//
//  Created by Cherish on 2021/5/31.
//

import UIKit

class Student: NSObject,NSCoding ,NSSecureCoding{

    static var supportsSecureCoding: Bool = true
    var name: String = ""
    var height: Float = 175.5
    var level: Int = 5
    override init(){
        
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.height, forKey: "height")
        coder.encode(self.level, forKey: "level")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        self.name = (coder.decodeObject(forKey: "name") as? String)!
        self.height = coder.decodeFloat(forKey: "height")
        self.level = coder.decodeInteger(forKey: "level")
    }
}
class ViewController: UIViewController{

    var db: LevelDB?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.db = LevelDB.databaseInLibrary(withName: "share.db")
      
        //1.set Int
        self.db?.setObject(10, forKey: "int")
        
        //2 set float
        self.db?.setObject(10.23, forKey: "float")
        
        // 3. set string
        self.db?.setObject("cherish", forKey: "name")
        
        // 4. set array
        self.db?.setObject(["1","2","3","4"], forKey: "array")
        
        // 5. set dictionary
        self.db?.setObject(["name":"cherish","height":1765.5], forKey: "map")
        
        // 6. set Bool
        self.db?.setObject(true, forKey: "flag")
        
        // 7. set struct
        
        
        // 8.set model
        let jack = Student()
        jack.name = "jack"
        jack.height = 178
        jack.level = 8
        self.db?.setObject(jack, forKey: "jackModel")
        
        // 9. model Array
        let rose = Student()
        rose.name = "rose"
        rose.height = 189
        rose.level = 88
        let models = [jack,rose]
        self.db?.setObject(models, forKey: "models")
        
        print("############################")
        print(self.db?.object(forKey: "int") as! Int)
        print("############################")
        
        print()
        
        
        print("############################")
        print(self.db?.object(forKey: "float") as! CGFloat)
        print("############################")
        
        print()
        
        print("############################")
        print(self.db?.object(forKey: "name") as! String)
        print("############################")
        
        print()
        
        print("############################")
        print(self.db?.object(forKey: "array") as! [String])
        print("############################")
        
        print()
        
        print("############################")
        print(self.db?.object(forKey: "map") as! [String:Any])
        print("############################")
        
        print()
        
        print("############################")
        let stu = self.db?.object(forKey: "jackModel")
        guard (stu as? Student) != nil else {
            return
        }
        print(jack.name)
        print("############################")
        
        print()
        
        print(self.db?.allKeys() ?? [])
        self.db?.removeObjects(forKeys: ["haha","name"])
        print(self.db?.allKeys() ?? [])
        
        let arr:[Student] = (self.db?.object(forKey: "models") as? [Student])!
        let Jack = arr.first
        print(Jack!.name)
        
        print(self.db?.object(forKey: "flag") as? Bool ?? false)
 
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.db?.deleteDatabaseFromDisk()
    }


}

