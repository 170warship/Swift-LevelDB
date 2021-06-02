//
//  Slice.swift
//  Swift-LevelDB
//
//  Created by Cherish on 2021/5/31.
//

import UIKit

public protocol Slice{
    func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType
    func data() -> Data
}

extension Data: Slice {
    public func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType {
        return self.withUnsafeBytes {
            pointer($0, self.count)
        }
    }

    public func data() -> Data {
        return self
    }
}

extension String: Slice {
    public func slice<ResultType>(pointer: (UnsafePointer<Int8>, Int) -> ResultType) -> ResultType {
        return self.utf8CString.withUnsafeBufferPointer {
            pointer($0.baseAddress!, Int(strlen($0.baseAddress!)))
        }
    }

    public func data() -> Data {
        return self.utf8CString.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
    }
}
