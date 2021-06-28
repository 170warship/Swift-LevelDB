//
//  LevelDB.swift
//  SwiftLevelDB
//
//  Created by Cherish on 2021/5/28.
//

import UIKit

final class LevelDB {
    fileprivate var db: OpaquePointer?
    fileprivate var writeSync = false
    fileprivate var isUseCache = false
    fileprivate var dbPath = ""
    fileprivate var dbName = ""

    /// Create and open a database
    ///
    /// It is recommended to use this method to initialize a database
    ///
    /// The following example calls this method
    ///
    ///      let ldb = LevelDB.open(db: "xxx.db")
    ///
    ///
    /// - Parameters:
    ///   - path: Sandbox path where the database is stored. Default: ~/Library .
    ///   - db: database name, It is recommended to use a string ending in .db .
    /// - Returns: Return an instance of LevelDB.
    public class func open(path: String = getLibraryPath(), db: String) -> LevelDB {
        return LevelDB(path: path, name: db)
    }
    
    /// Create and open a database
    ///
    /// Convenient initialization method to initialize a database instance
    ///
    /// The following example calls this method
    ///
    ///      let ldb = LevelDB(name: "xxx.db")
    ///
    ///      let ldb = LevelDB(path: "xxxx", name: "xxx.db")
    ///
    ///      //let options = [.createIfMissing]
    ///      let  options = FileOption.standard
    ///      let ldb = LevelDB(path: "xxxx", name: "xxx.db", options: options)
    ///
    ///
    /// - Parameters:
    ///   - path: Sandbox path where the database is stored. Default: ~/Library .
    ///   - name: database name, It is recommended to use a string ending in .db .
    ///   - options: Database configuration parameters, see FileOption for details, where ".createIfMissing" is necessary, default: FileOption.standard.
    /// - Returns: Return an instance of LevelDB.
    public convenience init(path: String = getLibraryPath(), name: String, options: [LevelDBOption] = LevelDBOption.standard) {
        self.init()
        assert(name.count != 0, "The database name cannot be empty")
        assert(options.contains(.createIfMissing), "options must contain .createIfMissing , Otherwise the database creation fails")
        
        let dbPath = path + "/" + name
        let levelOption = LevelDBOptions(options: options)
        var error: UnsafeMutablePointer<Int8>?
        
        let dbPointer = dbPath.utf8CString.withUnsafeBufferPointer {
            leveldb_open(levelOption.pointer, $0.baseAddress!, &error)
        }
        
        self.db = dbPointer
        self.dbPath = dbPath
        self.dbName = name
    }
    
    /// Cache data to the database
    ///
    /// Just convert the data to be cached into Data type, the user can encapsulate and call it
    ///
    /// The following example calls this method
    ///
    ///      let intValue: Int = 10
    ///      let cacheData = try? JSONEncoder().encode(intValue)
    ///      ldb.put("Codable", value: cacheData)
    ///
    ///      //class Person: NSObject,NSCoding
    ///      let p = Person()
    ///      let data = NSKeyedArchiver.archivedData(withRootObject: object as Any)
    ///      ldb.put("NSCoding",value: data)
    ///
    ///
    /// - Parameters:
    ///   - key: The key corresponding to the cached data, supports two types: String and Data
    ///   - value: The cached data must be of type Data
    ///   - options: Optional parameter, default WriteOption.standard
    public func put(_ key: Slice, value: Data?, options: [WriteOption] = WriteOption.standard) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        
        var error: UnsafeMutablePointer<Int8>?
        let writeOptions = ReadOptions(options: ReadOption.standard)
        key.slice { keyBytes, keyCount in
            if let value = value {
                value.withUnsafeBytes {
                    leveldb_put(self.db, writeOptions.pointer, keyBytes, keyCount, $0.baseAddress!.assumingMemoryBound(to: Int8.self), value.count, &error)
                }
            } else {
                leveldb_put(self.db, writeOptions.pointer, keyBytes, keyCount, nil, 0, &error)
            }
        }
    }
    
    
    /// Get cached data from the database according to the key
    ///
    /// Just convert the data to be cached into Data type, the user can encapsulate and call it
    ///
    /// The following example calls this method
    ///
    ///      if let getData = ldb.get("Codable") {
    ///        let getIntValue = try? JSONDecoder().decode(Int.self, from: getData)
    ///        print(getIntValue ?? 0)
    ///      }
    ///
    ///      if let getData = ldb.get("NSCoding") {
    ///        let getCodingValue = NSKeyedUnarchiver.unarchiveObject(with: data)
    ///        print(getIntValue ?? Person())
    ///      }
    ///
    ///
    /// - Parameters:
    ///   - key: The key corresponding to the cached data, supports two types: String and Data
    ///   - options: Optional parameter, default WriteOption.standard
    public func get(_ key: Slice, options: [ReadOption] = ReadOption.standard) -> Data? {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        
        var valueLength = 0
        var error: UnsafeMutablePointer<Int8>?
        var value: UnsafeMutablePointer<Int8>?

        let options = ReadOptions(options: options)
        key.slice { bytes, len in
            value = leveldb_get(self.db, options.pointer, bytes, len, &valueLength, &error)
        }
        
        // check fetch value lenght
        guard valueLength > 0 else {
            return nil
        }
        let target = Data(bytes: value!, count: valueLength)
        free(value)
        return  target
        
    }
 
    
    /// Get the collection of keys corresponding to all data in the database
    public func keys() -> [Slice] {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        let readOptions = ReadOptions(options: ReadOption.standard)
        
        let iterator = leveldb_create_iterator(db, readOptions.pointer)
        leveldb_iter_seek_to_first(iterator)
        var keys = [Slice]()
        while leveldb_iter_valid(iterator) == 1 {
            var len = 0
            let result: UnsafePointer<Int8> = leveldb_iter_key(iterator, &len)
            let data = Data(bytes: result, count: len)
            keys.append(data)
            leveldb_iter_next(iterator)
        }
        return keys
    }
    
   
    /// Delete some data according to the key
    ///
    ///
    /// The following example calls this method
    ///
    ///     ldb.delete("Codable")
    ///
    ///
    /// - Parameters:
    ///   - key: The key corresponding to the cached data, supports two types: String and Data
    ///   - options: Optional parameter, default WriteOption.standard
    public func delete(_ key: Slice, options: [WriteOption] = WriteOption.standard) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        
        var error: UnsafeMutablePointer<Int8>?
        let writeOptions = WriteOptions(options: options)
        key.slice { bytes, len in
            leveldb_delete(self.db, writeOptions.pointer, bytes, len, &error)
        }
    }
    
    /// Close the database
    public func close() {
        leveldb_close(db)
        db = nil
    }
    
    deinit {
        close()
    }
}

// MARK: Compatible with Objective-Leveldb

extension LevelDB {

    private class func getLibraryPath() -> String {
        let paths: [String] = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }
    
    public var safe: Bool {
        get {
            writeSync
        }
        set {
            writeSync = newValue
            leveldb_writeoptions_set_sync(leveldb_writeoptions_create(), newValue ? 1 : 0)
        }
    }
    
    public var useCache: Bool {
        get {
            isUseCache
        }
        set {
            isUseCache = newValue
            leveldb_readoptions_set_fill_cache(leveldb_readoptions_create(), newValue ? 1 : 0)
        }
    }
    
    public func path() -> String {
        return dbPath
    }
    
    public func name() -> String {
        return dbName
    }
    
    public func setObject(_ object: Any?, forKey key: Slice) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        assert(key is String || key is Data, "key must be String type or Data type")
        assert(object != nil, "Stored value cannot be empty")
        assert(object is NSCoding, "value must implemented NSCoding protocol!")
    
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: object as Any)
        put(key, value: data)
    }
    
    public func setValue(_ value: Any?, forKey key: Slice) {
        setObject(value, forKey: key)
    }
    
    public func value(forKey key: String) -> Any? {
        return object(forKey: key)
    }
    
    public func object(forKey key: Slice) -> Any? {
        guard let data = get(key) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }
    
    public func allKeys() -> [Slice] {
        return keys()
    }
    
    public func removeObject(forKey key: Slice) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        
        delete(key)
    }
    
    public func removeObjects(forKeys keyArray: [Slice]) {
        for (_, key) in keyArray.enumerated() {
            removeObject(forKey: key)
        }
    }
        
    public func removeAllObjects() {
        let keys = allKeys()
        if keys.count > 0 {
            for (_, item) in keys.enumerated() {
                removeObject(forKey: item)
            }
        }
    }
    
    public func deleteDatabaseFromDisk() {
        if self.db != nil {
            close()
            try? FileManager.default.removeItem(atPath: self.dbPath)
        }
    }
    
    public func objectExists(forKey: Slice) -> Bool {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        
        return get(forKey) != nil
    }
    
    public func closed() -> Bool {
        return db == nil
    }
}

// MARK: Cache and get objects that implement the Codable protocol

extension LevelDB {
    public func setCodable<T>(_ value: T?, forKey key: Slice) where T: Codable {
        let data = try? JSONEncoder().encode(value!)
        assert(data != nil, "JSONEncoder faild!")
        put(key, value: data)
    }
    
    public func getCodable<T>(forKey: Slice) -> T? where T: Codable {
        guard let data = get(forKey) else { return nil }
        let value = try? JSONDecoder().decode(T.self, from: data)
        return value
    }
    
    public func getCodable<T>(forKey: Slice, type: T.Type) -> T? where T: Codable {
        let value: T? = getCodable(forKey: forKey)
        return value
    }
}
