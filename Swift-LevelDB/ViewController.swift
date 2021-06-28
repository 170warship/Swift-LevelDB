//
//  ViewController.swift
//  Swift-LevelDB
//
//  Created by Cherish on 2021/5/31.
//

import UIKit

struct EncodableDecodableModel: Codable {
    let id: Int
    let name: String
}

class Person: NSObject, Codable {
    var name: String = ""
    var age: Int = 1
 
    override init() {
        super.init()
    }
    enum CodingKeys: String, CodingKey {
        case name
        case age
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.age = try container.decode(Int.self, forKey: .age)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.age, forKey: .age)
    }
}

class Student: NSObject, NSCoding, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    var name: String = ""
    var height: Float = 175.5
    var level: Int = 5
    override init() {}
    
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


class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //readMeTest()
        test()
    }
    
    func readMeTest() {
        let ldb = LevelDB.open(db: "test.db")
        
        // Int
        ldb.setCodable(10, forKey: "Int")
        print(ldb.getCodable(forKey: "Int") ?? 0)
        
        // Double
        ldb.setCodable(3.1415, forKey: "Double")
        print(ldb.getCodable(forKey: "Double") ?? 0.0)
        
        // Bool
        ldb.setCodable(true, forKey: "Bool")
        print(ldb.getCodable(forKey: "Bool") ?? false)
        
        // Array
        ldb.setCodable(["1","2","3"], forKey: "Array")
        print(ldb.getCodable(forKey: "Array") ?? [String]())
        
        // Dictionary
        ldb.setCodable(["id":"89757","name":"json"], forKey: "Dictionary")
        print(ldb.getCodable(forKey: "Dictionary") ?? ["":""])
       
        //  Implement Codable protocol object
        let codable = EncodableDecodableModel.init(id: 233, name: "codable")
        ldb.setCodable(codable, forKey: "codable")
        let cacheCodable = ldb.getCodable(forKey: "codable",type: EncodableDecodableModel.self)
        print(cacheCodable?.name ?? "",cacheCodable?.id ?? 0)
        
        let classCodable = Person()
        classCodable.name = "rose"
        classCodable.age = 15
        ldb.setCodable(classCodable, forKey: "classCodable")
        let cacheClassCodable = ldb.getCodable(forKey: "classCodable", type: Person.self)
        print(cacheClassCodable?.name ?? "",cacheClassCodable?.age ?? 0)
        
        // [Codable]
        ldb.setCodable([classCodable], forKey: "classCodables")
        let cacheCodables = ldb.getCodable(forKey: "classCodables") ?? [Person]()
        let cachePerson = cacheCodables.first
        print(cachePerson?.age ?? 0 ,cachePerson?.name ?? "")
        
        // Implement NSCoding protocol object
        let nscodingObject = Student()
        nscodingObject.name = "jack"
        nscodingObject.height = 175
        nscodingObject.level = 8
        ldb.setObject(nscodingObject, forKey: "nscodingObject")
        let cacheNsCodingObject = ldb.object(forKey: "struct") as? Student ?? Student()
        print(cacheNsCodingObject.name,cacheNsCodingObject.level,cacheNsCodingObject.height)
    }
    
    func test() {
        let ldb = LevelDB.open(db: "test.db")
        
       let data  =  String("876567898765467898765456789876567898765456789765,876567898765467898765456789876567898765456789765,876567898765467898765456789876567898765456789765,876567898765467898765456789876567898765456789765,876567898765467898765456789876567898765456789765,876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765876567898765467898765456789876567898765456789765").data()
       // let cacheData = try? JSONEncoder().encode(intValue)
        ldb.put("Int", value: data)

        
        let timer = Timer.init(timeInterval: 0.01, repeats: true) { _ in
            if let getData = ldb.get("Int") {
               //let getIntValue = try? JSONDecoder().decode(Int.self, from: getData)
               print(getData)
            }
        }
        RunLoop.current.add(timer, forMode: .common)

//
//        // remove objects
//        print(ldb.keys())
//        ldb.removeObjects(forKeys: ["Int"])
//        print(ldb.keys())
    }
    
    func batchRWOperation() {

        let ldb: LevelDB! = LevelDB.open(db: "test.db")
        let count = 100000
        //ldb.safe = false
        let writeStartTime = CFAbsoluteTimeGetCurrent()
        for index in 0...count {
            ldb.setObject(index, forKey: "\(index)")
        }
        let writeEndTime = CFAbsoluteTimeGetCurrent()
        debugPrint("执行时长：%f 秒", (writeEndTime - writeStartTime))
        
        
        let readStartTime = CFAbsoluteTimeGetCurrent()
        for index in 0...count {
           let _ =  ldb.object(forKey: "\(index)")
        }
        let readEndTime = CFAbsoluteTimeGetCurrent()
        debugPrint("执行时长：%f 秒", (readEndTime - readStartTime))
        

        
    }
    
}
