//
//  LevelDB.swift
//  SwiftLevelDB
//
//  Created by Cherish on 2021/5/28.
//

import UIKit

public protocol Slice {
    func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType
    func data() -> Data
}

extension Data: Slice {
    public func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType {
        return withUnsafeBytes {
            pointer($0, self.count)
        }
    }

    public func data() -> Data {
        return self
    }
}

extension String: Slice {
    public func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType {
        return utf8CString.withUnsafeBufferPointer {
            pointer($0.baseAddress!, Int(strlen($0.baseAddress!)))
        }
    }

    public func data() -> Data {
        return utf8CString.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
    }
}

struct LevelDBOptions {
    var createIfMissing = true
    var createIntermediateDirectories = true
    var errorIfExists = false
    var paranoidCheck = false
    var compression = false
    var filterPolicy: Int = 0
    var cacheSize: size_t = 0
}

class LevelDB: NSObject {
    fileprivate var db: OpaquePointer? = nil
    fileprivate var writeSync = false
    fileprivate var isUseCache = false
    fileprivate var readOptions: OpaquePointer? = nil
    fileprivate var writeOptions: OpaquePointer? = nil
    fileprivate var dbPath: String? = ""
    fileprivate var dbName: String? = ""

    public class func databaseInLibrary(withName name: String) -> LevelDB! {
        let opts = LevelDBOptions()
        return LevelDB.databaseInLibrary(withName: name, andOptions: opts)
    }
    
    public class func databaseInLibrary(withName name: String, andOptions options: LevelDBOptions) -> LevelDB! {
        let path = LevelDB.getLibraryPath() + "/" + name
        return LevelDB(path: path, name: name, andOptions: options)!
    }

    public init?(path: String?, andName name: String?) {
        let opts = LevelDBOptions()
        _ = LevelDB(path: path, name: name, andOptions: opts)
    }
    
    public init?(path: String?, name: String?, andOptions opts: LevelDBOptions) {
        super.init()
        
        guard let dbPath = path else {
            return
        }
        
        guard let dbName = name else {
            return
        }
        
        readOptions = leveldb_readoptions_create()
        leveldb_readoptions_set_fill_cache(readOptions, 1) // Should the data read for this iteration be cached in memory. Default: true
        leveldb_readoptions_set_verify_checksums(readOptions, 0) //  If true, all data read from underlying storage will be verified against corresponding checksums. Default: false
        
        writeOptions = leveldb_writeoptions_create()
        leveldb_writeoptions_set_sync(writeOptions, 0) // If true, the write will be flushed from the operating system buffer cache (by calling WritableFile::Sync()) before the write is considered complete.  If this flag is true, writes will be slower.  Default: false
  
        let options = leveldb_options_create()
        leveldb_options_set_create_if_missing(options, 1) // If true, the database will be created if it is missing. Default: false
        leveldb_options_set_error_if_exists(options, 0) // If true, an error is raised if the database already exists.  Default: false
        leveldb_options_set_paranoid_checks(options, 0) // If true, the implementation will do aggressive checking of the data it is processing and will stop early if it detects any errors. This may have unforeseen ramifications. Default: false
        leveldb_options_set_write_buffer_size(options, 4 << 20) // Amount of data to build up in memory before converting to a sorted on-disk file. Default: 4MB
        leveldb_options_set_max_open_files(options, 1000) // Number of open files that can be used by the DB. Default: 1000
        leveldb_options_set_compression(options, Int32(leveldb_snappy_compression)) // Compress blocks using the specified compression algorithm. Default: kSnappyCompression

        var error: UnsafeMutablePointer<Int8>?
        let dbPointer = dbPath.utf8CString.withUnsafeBufferPointer {
            leveldb_open(options, $0.baseAddress!, &error)
        }
        self.dbPath = dbPath
        self.dbName = dbName
        self.db = dbPointer
    }

    public func deleteDatabaseFromDisk() {
        close()
        guard let path = dbPath else {
            return
        }
        try? FileManager.default.removeItem(atPath: path)
    }
    
    public func close() {
        leveldb_close(db) // delete db
        db = nil
    }
    
    public func closed() -> Bool {
        return db == nil
    }
        
    public func path() -> String {
        return dbPath ?? ""
    }
    
    public func name() -> String {
        return dbName ?? ""
    }
    
    public var safe: Bool {
        get {
            writeSync
        }
        set {
            writeSync = newValue
            leveldb_writeoptions_set_sync(writeOptions, newValue ? 1 : 0)
        }
    }
    
    public var useCache: Bool {
        get {
            isUseCache
        }
        set {
            isUseCache = newValue
            leveldb_readoptions_set_fill_cache(readOptions, newValue ? 1 : 0)
        }
    }
    
    private class func getLibraryPath() -> String {
        let paths: [String] = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }
    
    public class func makeOptions() -> LevelDBOptions {
        return LevelDBOptions(createIfMissing: true, createIntermediateDirectories: true, errorIfExists: false, paranoidCheck: false, compression: false, filterPolicy: 0, cacheSize: 0)
    }
    
    // MARK: Set

    public func setObject(_ object: Any?, forKey key: Slice) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        assert(key is String || key is Data, "key must be String type or Data type")
        assert(object != nil, "Stored value cannot be empty")
        
        var error: UnsafeMutablePointer<Int8>?
        key.slice { keyBytes, keyCount in
            if let value = object {
                guard let data: Data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true) else {
                    return
                }
                data.withUnsafeBytes {
                    leveldb_put(self.db, self.writeOptions, keyBytes, keyCount, $0, data.count, &error)
                }
            }
        }
    }
    
    override open func setValue(_ value: Any!, forKey key: String) {
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

    override open func value(forKey key: String) -> Any? {
        return object(forKey: key)
    }
    
    public func object(forKey key: Slice) -> Any! {
        var error: UnsafeMutablePointer<Int8>?
        var value: UnsafeMutablePointer<Int8>?
        var valueLength = 0
        key.slice { bytes, len in
            value = leveldb_get(self.db, self.readOptions, bytes, len, &valueLength, &error)
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
        let iterator = leveldb_create_iterator(db, readOptions)
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
    
    // MARK: Delete

    public func removeObject(forKey key: Slice) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        assert(key is String || key is Data, "key must be String type or Data type")
        
        var error: UnsafeMutablePointer<Int8>?
        key.slice { bytes, len in
            leveldb_delete(self.db, self.writeOptions, bytes, len, &error)
        }
    }
    
    public func removeObjects(forKeys keyArray: [Slice]) {
        for (_, key) in keyArray.enumerated() {
            if objectExists(forKey: key) {
                removeObject(forKey: key)
            }
        }
    }
    
    public func objectExists(forKey: Slice) -> Bool {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        assert(forKey is String || forKey is Data, "key must be String type or Data type")
        
        return object(forKey: forKey) != nil
    }
    
    public func removeAllObjects() {
        let keys = allKeys()
        if keys.count > 0 {
            for (_, item) in keys.enumerated() {
                if objectExists(forKey: item) {
                    removeObject(forKey: item)
                }
            }
        }
    }
        
    deinit {
       close()
    }
}
