//
//  Slice.swift
//  Swift-LevelDB
//
//  Created by Cherish on 2021/6/23.
//

import Foundation

public protocol Slice {
    func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType
    func data() -> Data
}

extension Data: Slice {
    public func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType {
        return withUnsafeBytes {
            pointer($0.baseAddress!.assumingMemoryBound(to: Int8.self), self.count)
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
