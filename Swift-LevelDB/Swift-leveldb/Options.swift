//
//  Options.swift
//  Swift-LevelDB
//
//  Created by Cherish on 2021/6/23.
//

import Foundation

public enum CompressionType: Int {
    case none = 0
    case snappy
}

/// MARK :  option protocol
public protocol Option {
    func set(options: OpaquePointer)

    static var standard: [Self] { get }
}

public protocol Options: class {
    associatedtype OptionType: Option

    init(options: [OptionType])

    var pointer: OpaquePointer { get }
}


/// MARK:   Leveldb_option_t
public enum LevelDBOption: Option, Equatable {
    case createIfMissing
    case errorIfExists
    case paranoidChecks
    case writeBufferSize(Int)
    case maxOpenFiles(Int)
    case blockSize(Int)
    case blockRestartInterval(Int)
    case compression(CompressionType)

    public func set(options: OpaquePointer) {
        switch self {
        case .createIfMissing:
            // If true, the database will be created if it is missing. Default: false
            leveldb_options_set_create_if_missing(options, 1)
        case .errorIfExists:
            // If true, an error is raised if the database already exists.  Default: false
            leveldb_options_set_error_if_exists(options, 1)
        case .paranoidChecks:
            // If true, the implementation will do aggressive checking of the data it is processing and will stop early if it detects any errors. This may have unforeseen ramifications. Default: false
            leveldb_options_set_paranoid_checks(options, 1)
        case .writeBufferSize(let size):
            //// Amount of data to build up in memory before converting to a sorted on-disk file. Default: 4MB
            leveldb_options_set_write_buffer_size(options, Int(size))
        case .maxOpenFiles(let files):
            //// Number of open files that can be used by the DB. Default: 1000
            leveldb_options_set_max_open_files(options, Int32(files))
        case .blockSize(let size):
            // Approximate size of user data packed per block. Default: 4K
            leveldb_options_set_block_size(options, Int(size))
        case .blockRestartInterval(let interval):
            // Number of keys between restart points for delta encoding of keys.This parameter can be changed dynamically.  Most clients should leave this parameter alone.
            leveldb_options_set_block_restart_interval(options, Int32(interval))
        case .compression(let type):
            // Compress blocks using the specified compression algorithm. Default: kSnappyCompression
            leveldb_options_set_compression(options, Int32(type.rawValue))
        }
    }

    public static var standard: [LevelDBOption] {
        return [
            .createIfMissing,
            .writeBufferSize(4 << 20),
            .maxOpenFiles(1000),
            .blockSize(1024 * 4),
            .blockRestartInterval(16),
            .compression(.snappy),
        ]
    }
}

public final class LevelDBOptions: Options {
    public let pointer: OpaquePointer

    public init(options: [LevelDBOption]) {
        self.pointer = leveldb_options_create()
        options.forEach { $0.set(options: pointer) }
    }

    deinit {
        leveldb_options_destroy(pointer)
    }
}


/// MARK:   Leveldb_readoptions_t
public enum ReadOption: Option {
    case verifyChecksums
    case fillCache
    // case snapshot(Snapshot)
    public func set(options: OpaquePointer) {
        switch self {
        case .verifyChecksums:
            // If true, all data read from underlying storage will be verified against corresponding checksums. Default: false
            leveldb_readoptions_set_verify_checksums(options, 1)
        case .fillCache:
            // Should the data read for this iteration be cached in memory. Default: true
            leveldb_readoptions_set_fill_cache(options, 1)
//        case .snapshot(let snapshot):
//            leveldb_readoptions_set_snapshot(options, snapshot.pointer)
//            break
        }
    }

    public static var standard: [ReadOption] {
        return [
            .fillCache,
        ]
    }
}

public final class ReadOptions: Options {
    public let pointer: OpaquePointer

    public init(options: [ReadOption]) {
        self.pointer = leveldb_readoptions_create()
        options.forEach { $0.set(options: pointer) }
    }

    deinit {
        leveldb_readoptions_destroy(pointer)
    }
}


/// MARK:   leveldb_writeoptions_t
public enum WriteOption: Option {
    case sync

    public func set(options: OpaquePointer) {
        switch self {
        case .sync:
            // If true, the write will be flushed from the operating system buffer cache (by calling WritableFile::Sync()) before the write is considered complete.  If this flag is true, writes will be slower.  Default: false
            leveldb_writeoptions_set_sync(options, 1)
        }
    }

    public static var standard: [WriteOption] {
        return []
    }
}

public final class WriteOptions: Options {
    public let pointer: OpaquePointer

    public init(options: [WriteOption]) {
        self.pointer = leveldb_writeoptions_create()
        options.forEach { $0.set(options: pointer) }
    }

    deinit {
        leveldb_writeoptions_destroy(pointer)
    }
}
