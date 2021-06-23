//
//  LeveldbError.swift
//  Swift-LevelDB
//
//  Created by Cherish on 2021/6/23.
//

import Foundation

public enum LevelDBError: Error {
    case unowned
    case openError(message: String)
    case putError(message: String)
    case getError(message: String)
    case deleteErro(message: String)
    case writeError(message: String)
    case otherError
}

