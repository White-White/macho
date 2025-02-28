//
//  OperationCode.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/13.
//

import Foundation

enum LEBType {
    case signed
    case unsigned
}

protocol OperationCodeMetadataProtocol: Sendable {
    init(operationCodeValue: UInt8, immediateValue: UInt8)
    func operationReadable() -> String
    func immediateReadable() -> String
    
    var numberOfTrailingLEB: Int { get }
    var trailingLEBType: LEBType { get }
    var hasTrailingCString: Bool { get }
}

struct DyldInfoLEB {
    let byteCount: Int
    let raw: UInt64
    let isSigned: Bool
}

struct OperationCode<CodeMetadata: OperationCodeMetadataProtocol> {
    
    let dataStartIndex: Int
    let codeMetadata: CodeMetadata
    let lebValues: [DyldInfoLEB]
    let cstringData: Data?
    let numberOfTranslations: Int

    var translationGroup: TranslationGroup {
        let translationGroup = TranslationGroup(dataStartIndex: self.dataStartIndex)
        translationGroup.addTranslation(definition: "Operation Code (Upper 4 bits)", humanReadable: codeMetadata.operationReadable(),
                                        translationType: .flags(1),
                                        extraDefinition: "Immediate Value Used As (Lower 4 bits)", extraHumanReadable: codeMetadata.immediateReadable())
        
        for ulebValue in lebValues {
            translationGroup.addTranslation(definition: "LEB Value", humanReadable: ulebValue.isSigned ? "\(Int(bitPattern: UInt(ulebValue.raw)))" : "\(ulebValue.raw)", translationType: .uleb(ulebValue.byteCount))
        }
        
        if let cstringData = cstringData {
            let cstring = cstringData.utf8String ?? "🙅‍♂️ Invalid CString"
            translationGroup.addTranslation(definition: "String", humanReadable: cstring, translationType: .utf8String(cstringData.count))
        }
        return translationGroup
    }
    
    init(dataStartIndex: Int, operationCode: CodeMetadata, lebValues:[DyldInfoLEB], cstringData: Data?) {
        self.dataStartIndex = dataStartIndex
        self.codeMetadata = operationCode
        self.lebValues = lebValues
        self.cstringData = cstringData
        self.numberOfTranslations = 2 + lebValues.count + (cstringData == nil ? 0 : 1)
    }
}
