//
//  OperationCodeSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/9.
//

import Foundation

class OperationCodeSection<Code: OperationCodeMetadataProtocol>: GroupTranslatedMachoSlice {
    
    private(set) var operationCodes: [OperationCode<Code>] = []
    
    override func initialize() async {
        self.operationCodes = OperationCodeSection.operationCodes(from: self.data)
    }
    
    override func translate(_ progressNotifier: @escaping (Float) -> Void) async -> [TranslationGroup] {
        self.operationCodes.map { $0.translationGroup }
    }
    
    // parsing
    static func operationCodes(from rawData: Data) -> [OperationCode<Code>] {
        
        var operationCodes: [OperationCode<Code>] = []
        var index: Int = 0
        while index < rawData.count {
            let startIndex = index
            
            let byte = rawData[rawData.startIndex+index]; index += 1
            let operationCodeValue = byte & 0xf0 // mask the most significant 4 bits
            let immediateValue = byte & 0x0f // mask the least significant 4 bits
            let operationCode = Code.init(operationCodeValue: operationCodeValue, immediateValue: immediateValue)
            
            // trailing LEBs
            var lebValues: [DyldInfoLEB] = []
            for _ in 0..<operationCode.numberOfTrailingLEB {
                let ulebStartIndex = index
                var delta: Swift.UInt64 = 0
                var shift: Swift.UInt32 = 0
                var more = true
                repeat {
                    let lebByte = rawData[rawData.startIndex+index]; index += 1
                    delta |= ((Swift.UInt64(lebByte) & 0x7f) << shift)
                    shift += 7
                    if lebByte < 0x80 {
                        more = false
                    }
                } while (more)
                
                let isSigned = operationCode.trailingLEBType == .signed
                if (isSigned) {
                    let signExtendMask: Swift.UInt64 = ~0
                    delta |= signExtendMask << shift
                }
                
                lebValues.append(DyldInfoLEB(byteCount:index-ulebStartIndex, raw: delta, isSigned: isSigned))
            }
            
            // trailing string
            var cstringData: Data? = nil
            if operationCode.hasTrailingCString {
                let cstringStartIndex = index
                while (rawData[rawData.startIndex+index] != 0) {
                    index += 1
                }
                index += 1 // the final \0 is a part of the string
                cstringData = rawData[rawData.startIndex+cstringStartIndex..<rawData.startIndex+index]
            }
            
            operationCodes.append(OperationCode<Code>.init(dataStartIndex: startIndex, operationCode: operationCode, lebValues: lebValues, cstringData: cstringData))
        }
        
        return operationCodes
    }
}
