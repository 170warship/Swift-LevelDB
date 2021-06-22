//
//  ViewController.swift
//  Swift-LevelDB
//
//  Created by Cherish on 2021/5/31.
//

import UIKit

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

class Person: NSObject, Codable {
    var name: String = ""
    var age: Int = 1
    
    override init() {}
    
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


struct EncodableDecodableModel {
    let id: Int
    let name: String
}

extension EncodableDecodableModel: Encodable {
    func toData() -> Data {
        let json: [String: Any] = ["id": id, "name": name]

        return try! JSONSerialization
            .data(withJSONObject: json, options: .prettyPrinted)
    }
}

extension EncodableDecodableModel: Decodable {
    init(data: Data) {
        let json = try! JSONSerialization
            .jsonObject(with: data, options: .allowFragments) as! [String: Any]

        id = json["id"] as! Int
        name = json["name"] as! String
    }
}


class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
       operationDB()
       // batchRWOperation()

    }
    
    func operationDB()  {
        
        let ldb = LevelDB.open(db: "share.db")
        
        // String
        ldb.setObject("test", forKey: "String")
        print(ldb.object(forKey: "string") as? String ?? "")
        
        // Dictionary
        ldb.setObject(["key1": "value1", "key2": "value2"], forKey: "dictionray")
        print(ldb.object(forKey: "dictionray") as? [String: String] ?? [])
        
        // Bool
        ldb.setObject(true, forKey: "bool")
        print(ldb.object(forKey: "bool") as? Bool ?? false)
        
        // Array
        ldb.setObject(["1", "2", "3", "4"], forKey: "arrays")
        print(ldb.object(forKey: "arrays") as? [String] ?? [])
        
        // Float
        ldb.setObject(10.5, forKey: "float")
        print(ldb.object(forKey: "float") as? CGFloat ?? 0.0)
        
        // Int
        ldb.setObject(19, forKey: "int")
        print(ldb.object(forKey: "int") as? CGFloat ?? 5)
        
        // class instance
        let jack = Student()
        jack.name = "jack"
        jack.height = 178
        jack.level = 8
        ldb.setObject(jack, forKey: "struct")
        let model = ldb.object(forKey: "struct") as? Student ?? Student()
        print(model.name)
        
        // [class instance]
        let models: [Student] = [jack]
        ldb.setObject(models, forKey: "models")
        let students = ldb.object(forKey: "models") as? [Student]
        guard let m = students?.first else {
            return
        }
        print(m.level)
      
        // Codable
        let p = Person()
        p.name = "rose"
        p.age = 15
        ldb.setCodable(p, forKey: "codable")
        let codablePerson = ldb.getCodable(forKey: "codable", type: Person.self)
        print(codablePerson?.name ?? "", codablePerson?.age ?? 0)
        
        // [Codables]
        let codables: [Person] = [p]
        ldb.setCodable(codables, forKey: "codables")
        let arr: [Person] = ldb.getCodable(forKey: "codables") ?? [Person]()
        print(arr.first?.age ?? 0, arr.first?.name ?? "")
   
        ldb.setCodable(true, forKey: "boolCodable")
        print(ldb.getCodable(forKey: "boolCodable") ?? false)
        
        // update
        print("Before the update, the value of key is String = ",ldb.object(forKey: "String") as? String ?? "")
        ldb.setObject("String", forKey: "String")
       // print("After the update, the value of key is String = ",ldb.value(forKey: "String") as? String ?? "")
        
        // all keys
        print("all keys")
        for (index, item) in ldb.allKeys().enumerated() {
            if item is Data {
                print("index = \(index), key = \(String(data: item as! Data, encoding: .utf8) ?? "")")
            }
        }
        print("1、The number of keys is \(ldb.allKeys().count)")
        // remove
        print("-------------------------------------")
        
        // removeObject
        ldb.removeObject(forKey: "boolCodable")
        for (index, item) in ldb.allKeys().enumerated() {
            if item is Data {
                print("index = \(index), key = \(String(data: item as! Data, encoding: .utf8) ?? "")")
            }
        }
      
        // remove all
        print("2、The number of keys is \(ldb.allKeys().count)")
        ldb.removeAllObjects()
        print("3、The number of keys is \(ldb.allKeys().count)")
        
        //Codable
        let structModel = EncodableDecodableModel.init(id: 89757, name: "kkk")
        ldb.setCodable(structModel, forKey: "ttt")
        ldb.setCodable([structModel], forKey: "ttts")
        let cacheModel = ldb.getCodable(forKey: "ttt", type: EncodableDecodableModel.self)
        let cacheModels = ldb.getCodable(forKey: "ttts") ?? [EncodableDecodableModel]()
        ldb.setCodable(["1","2","3"], forKey: "baseboo")
        let baseboo = ldb.getCodable(forKey: "baseboo") ?? [String]()
        
        print(cacheModel?.name as Any)
        
        var list = [String]()
        list.append("")
        
        // delete db
        if ldb.closed() {
            ldb.close()
        }
    }
    
    func batchRWOperation() {

        let ldb: LevelDB! = LevelDB.databaseInLibrary(withName: "test.db")
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
