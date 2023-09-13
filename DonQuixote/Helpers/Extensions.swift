//
//  Utils.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation
import SwiftUI

extension Data {
    
    private func cast<T>(to type: T.Type) -> T {
        guard self.count == MemoryLayout<T>.size else { fatalError() }
        return self.withUnsafeBytes { $0.bindMemory(to: type).baseAddress!.pointee }
    }
    
    var UInt8: Swift.UInt8 { if (self.count == 1) { return self.first! } else { fatalError() } }
    var UInt16: Swift.UInt16 { cast(to: Swift.UInt16.self) }
    var UInt32: Swift.UInt32 { cast(to: Swift.UInt32.self) }
    var Int32: Swift.Int32 { cast(to: Swift.Int32.self) }
    var UInt64: Swift.UInt64 { cast(to: Swift.UInt64.self) }
    var utf8String: String? { String(data: self, encoding: .utf8) }
    
    func subSequence(from: Int, maxCount: Int) -> Data {
        if from + maxCount > self.count {
            return self.subSequence(from: from)
        } else {
            return self.subSequence(from: from, count: maxCount)
        }
    }
    
    func subSequence(from: Int) -> Data {
        guard from < self.count else { fatalError() }
        return self[self.startIndex+from..<self.endIndex]
    }
    
    func subSequence(from: Int, count: Int, allowZeroLength: Bool = false) -> Data {
        if !allowZeroLength && count == .zero {
            Log.error("Empty data returned")
            return Data()
        }
        guard from + count <= self.count else { fatalError() }
        return self[self.startIndex+from..<self.startIndex+from+count]
    }
    
}

extension String {
    
    var spaceRemoved: String {
        return self.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\0", with: "")
    }
    
}

extension Int {
    var hex: String { String(format: "0x%0X", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension UInt16 {
    var hex: String { String(format: "0x%0X", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension UInt32 {
    var hex: String { String(format: "0x%0X", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension Int32 {
    var hex: String { String(format: "0x%0X", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension UInt64 {
    var hex: String { String(format: "0x%llX", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension Array {
    
    enum BinaryCompareResult {
        case left
        case matched
        case right
    }
    
    func binarySearch(matchCheck: (_ element: Element) -> BinaryCompareResult) -> Element? {
        return _binarySearch(lower: self.startIndex, upper: self.endIndex - 1, matchCheck: matchCheck)
    }
    
    private func _binarySearch(lower: Index, upper: Index, matchCheck: (_ element: Element) -> BinaryCompareResult) -> Element? {
        // false, search left
        // true search right
        guard lower <= upper else { return nil }
        let mid = (lower + upper) / 2
        let element = self[mid]
        switch matchCheck(self[mid]) {
        case .left:
            return _binarySearch(lower: lower, upper: mid - 1, matchCheck: matchCheck)
        case .right:
            return _binarySearch(lower: mid + 1, upper: upper, matchCheck: matchCheck)
        case .matched:
            return element
        }
    }
    
}
