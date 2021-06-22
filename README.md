## Introduction

An Swift database library built over [Google's LevelDB](http://code.google.com/p/leveldb), a fast embedded key-value store written by Google.

## Installation

By far, the easiest way to integrate this library in your project is by using [CocoaPods][1].

1. Have [Cocoapods][1] installed, if you don't already
2. In your Podfile, add the line 

        pod 'Swift-LevelDB'  //Unrealized

3. Run `pod install`
4. Make something awesome.

## How to use

#### Open database

```Swift
 let ldb = LevelDB.open(db: "share.db")
```

#### Close database

```Swift
 ldb.close()
```

##### Delete  database

```Swift
  ldb.deleteDatabaseFromDisk()
```

##### Cache data

###### Data structure

```Swift
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
```

######  Cached data structure

```Swift

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

 // Implement Codable protocol object
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
 
```
Remarks: The key type supports String and Data types

##### Delete data

```Swift
 ldb.delte("Int")
```


##### Keys

```Swift
 let keys: [Slice] = ldb.keys()
```


### License

Distributed under the [MIT license](LICENSE)

[1]: http://cocoapods.org
[2]: http://leveldb.googlecode.com/svn/trunk/doc/index.html



