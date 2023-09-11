//
//  Log.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class Log {
    
    private init() {}
    
    @discardableResult
    static func warning(_ string: String) -> String {
        return printAndReturn("⚠️ " + string)
    }
    
    @discardableResult
    static func error(_ string: String) -> String {
        return printAndReturn("❌ " + string)
    }
    
    private static func printAndReturn(_ s: String) -> String {
        print(s); return s
    }
    
}
