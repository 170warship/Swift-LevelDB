        //
//  LevelDB.swift
//  SwiftLevelDB
//
//  Created by Cherish on 2021/5/28.
//

import UIKit

struct LevelDBOptions {
}

class LevelDB: NSObject {
    
    var db: OpaquePointer?
    var readOptions: OpaquePointer?
    var writeSync = false
    
    fileprivate var dbPath: String?
    fileprivate var dbName: String?

    open class func databaseInLibrary(withName name: String) -> LevelDB {
        let opts = LevelDBOptions()
        return LevelDB.databaseInLibrary(withName: name, andOptions: opts)
    }
    
    open class func databaseInLibrary(withName name: String, andOptions options: LevelDBOptions) -> LevelDB {
        let path = LevelDB.getLibraryPath() + "/" + name
        return LevelDB.init(path: path, name: name, andOptions: options)!
    }

    public init?(path: String?, andName name: String?) {
        let opts = LevelDBOptions()
        let _ = LevelDB.init(path: path, name: name, andOptions: opts)
    }
    
    public init?(path: String?, name: String?, andOptions opts: LevelDBOptions) {
        super.init()
        dbPath = path ?? ""
        dbName = name ?? ""
        self.readOptions = leveldb_options_create()
        leveldb_options_set_create_if_missing(self.readOptions, 1)
        var error: UnsafeMutablePointer<Int8>? = nil
        let dbPointer = path!.utf8CString.withUnsafeBufferPointer {
            return leveldb_open(self.readOptions, $0.baseAddress!, &error)
        }
        self.db = dbPointer
    }

    public func deleteDatabaseFromDisk() {
        leveldb_close(self.db)
        try? FileManager.default.removeItem(atPath: self.dbPath!)
        self.db = nil
    }
    
    public func close() {
        leveldb_close(self.db)
    }
    
    public func path() -> String {
        return dbPath ?? ""
    }
    
    public func name() -> String {
        return dbName ?? ""
    }
    
    public var safe: Bool{
        get {
            return writeSync
        }
        set {
            self.writeSync = newValue
        }
    }
    
    private class func getLibraryPath() -> String {
        let paths: [String] = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }
    
    open class func makeOptions() -> LevelDBOptions {
        return LevelDBOptions()
    }
    
     // MARK: Set
    public func setObject(_ object: Any?, forKey key: Slice) {
        //写入选项
        let writeOptions = leveldb_writeoptions_create()
        leveldb_writeoptions_set_sync(writeOptions,self.safe == true ? 1 : 0)
        var error: UnsafeMutablePointer<Int8>? = nil
        key.slice { (keyBytes, keyCount) in
            if let value = object {
                guard let data: Data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true) else {
                    return
                }
                data.withUnsafeBytes {
                    leveldb_put(self.db, writeOptions, keyBytes, keyCount,$0, data.count, &error)
                }
            }
        }
    }
    
    public func setValue(_ value: Any!, forKey key: Slice) {
        setObject(value, forKey: key)
    }
    
    public func setCodable<T>(_ value: T?, forKey key: Slice) where T: Codable {
        if value == nil {
            removeObject(forKey: key)
            return
        }
        
        let data = try? JSONEncoder().encode(value!)
        assert(data != nil, "JSONEncoder faild!")
        setObject(data, forKey: key)
    }

    // MARK: Get

    public func value(forKey key: Slice) -> Any! {
        return object(forKey: key)
    }
    
    public func object(forKey key: Slice) -> Any! {
        var error: UnsafeMutablePointer<Int8>? = nil
        var value: UnsafeMutablePointer<Int8>? = nil
        var valueLength = 0
        let readOptions = leveldb_readoptions_create()
        key.slice { (bytes, len)  in
            value = leveldb_get(self.db, readOptions, bytes, len, &valueLength, &error)
        }
        // check fetch value lenght
        guard valueLength > 0 else {
            return nil
        }
        guard let object = try? NSKeyedUnarchiver.unarchiveObject(with: Data(bytes: value!, count: valueLength)) else {
            return nil
        }
        return object
    }
    
    public func getCodable<T>(forKey: Slice) -> T? where T: Codable {
        guard let data = object(forKey: forKey) as? Data else { return nil }
        let value = try? JSONDecoder().decode(T.self, from: data)
        return value
    }
    
    public func getCodable<T>(forKey: Slice, type: T.Type) -> T? where T: Codable {
        let value: T? = getCodable(forKey: forKey)
        return value
    }
    
    public func allKeys() -> [Slice] {
        let readOptions = leveldb_readoptions_create()
        let iterator = leveldb_create_iterator(self.db,readOptions)
        leveldb_iter_seek_to_first(iterator)
        var keys = [Slice]()
        while leveldb_iter_valid(iterator) == 1 {
            var len = 0
            let result: UnsafePointer<Int8> = leveldb_iter_key(iterator,&len)
            let data = Data(bytes: result, count: len)
            let key = String(data: data, encoding: .utf8)
            keys.append(key!)
            leveldb_iter_next(iterator)
        }
         return keys
    }
    
    // MARK: Delete

    public func removeObject(forKey key: Slice) {
        var error: UnsafeMutablePointer<Int8>? = nil
        let readOptions = leveldb_readoptions_create()
        key.slice { (bytes, len)  in
            leveldb_delete(self.db, readOptions, bytes, len, &error)
        }
    }
    
    public func removeObjects(forKeys keyArray: [Slice]) {
        for (_,key) in keyArray.enumerated() {
            if objectExists(forKey: key) {
                removeObject(forKey: key)
            }
        }
    }
    
    public func objectExists(forKey:Slice) -> Bool {
        return object(forKey: forKey) != nil
    }
    
    public func removeAllObjects() {
        let keys = allKeys()
        if keys.count > 0 {
            for (_,item) in keys.enumerated() {
                if objectExists(forKey: item) {
                    removeObject(forKey:item)
                }
            }
        }
    }
}
