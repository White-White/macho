//
//  Translation.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/18.
//

import Foundation

enum TranslationDataType {
    
    case uint8
    case uint16
    case uint32
    case uint64
    case int8
    case int16
    case int32
    case int64
    case versionString32Bit //4
    case versionString64Bit //4
    
    case numberEnum8Bit
    case numberEnum16Bit
    case numberEnum32Bit
    
    case utf8String(Int)
    case utf16String(Int)
    case rawData(Int)
    case uleb(Int)
    case uleb128(Int)
    case flags(Int)
    case code(Int)
    
    var description: String {
        switch self {
        case .uint8:
            return "Unsigned Int-8"
        case .uint16:
            return "Unsigned Int-16"
        case .uint32:
            return "Unsigned Int-32"
        case .uint64:
            return "Unsigned Int-64"
        case .int8:
            return "Signed Int-8"
        case .int16:
            return "Signed Int-16"
        case .int32:
            return "Signed Int-32"
        case .int64:
            return "Signed Int-64"
        case .versionString32Bit, .versionString64Bit:
            return "Semantic Version"
        case .numberEnum8Bit, .numberEnum16Bit, .numberEnum32Bit:
            return "Number Enum"
        case .utf8String:
            return "String-UTF8"
        case .utf16String:
            return "String-UTF16"
        case .rawData:
            return "Raw Data"
        case .uleb:
            return "ULEB"
        case .uleb128:
            return "ULEB-128"
        case .flags:
            return "Bit Flags"
        case .code:
            return "Machine Code"
        }
    }
    
    var bytesCount: Int {
        switch self {
        case .uint8, .int8, .numberEnum8Bit:
            return Straddle.byte.raw
        case .uint16, .int16, .numberEnum16Bit:
            return Straddle.word.raw
        case .uint32, .int32, .versionString32Bit, .numberEnum32Bit:
            return Straddle.doubleWords.raw
        case .uint64, .int64, .versionString64Bit:
            return Straddle.quadWords.raw
        case .utf8String(let count):
            return count
        case .utf16String(let count):
            return count
        case .rawData(let count):
            return count
        case .uleb(let count):
            return count
        case .uleb128(let count):
            return count
        case .flags(let count):
            return count
        case .code(let count):
            return count
        }
    }
    
}

struct Translation: Equatable, Identifiable {
    
    static func == (lhs: Translation, rhs: Translation) -> Bool {
        lhs.rangeInMacho == rhs.rangeInMacho
    }
    
    var rangeInMacho: Range<UInt64>?
    var id: UInt64 { rangeInMacho!.startIndex }
    
    let definition: String?
    let humanReadable: String
    let translationType: TranslationDataType
    var bytesCount: Int { translationType.bytesCount }
    
    let extraDefinition: String?
    let extraHumanReadable: String?
    let error: String?
    
    init(definition: String?,
         humanReadable: String,
         translationType: TranslationDataType,
         extraDefinition: String? = nil,
         extraHumanReadable: String? = nil,
         error: String? = nil) {
        
        self.definition = definition
        self.humanReadable = humanReadable
        self.translationType = translationType
        self.extraDefinition = extraDefinition
        self.extraHumanReadable = extraHumanReadable
        self.error = error
        
    }
    
    mutating func updateRange(with rangeInMacho: Range<UInt64>) {
        self.rangeInMacho = rangeInMacho
    }
    
}

struct TranslationGroup: Identifiable {
    
    let translations: [Translation]
    
    var dataRangeInMacho: Range<UInt64>? {
        if let start = translations.first?.rangeInMacho?.startIndex,
           let end = translations.last?.rangeInMacho?.endIndex {
            return start..<end
        }
        return nil
    }
    
    var id: UInt64 { dataRangeInMacho!.startIndex }
    
}
