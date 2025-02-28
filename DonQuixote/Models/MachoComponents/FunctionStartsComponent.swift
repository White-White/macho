//
//  FunctionStartsComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/25.
//

import Foundation

struct FunctionStart {
    let startOffset: Int
    let byteLength: Int
    let address: Swift.UInt64
}

// a great description for function start section data format
// https://stackoverflow.com/questions/9602438/mach-o-file-lc-function-starts-load-command

class FunctionStartsSection: MachoPortion, @unchecked Sendable {
    
    let symbolTable: SymbolTable?
    let textSegmentVirtualAddress: Swift.UInt64
    
    init(_ data: Data, title: String, textSegmentVirtualAddress: UInt64, symbolTable: SymbolTable?) {
        self.symbolTable = symbolTable
        self.textSegmentVirtualAddress = textSegmentVirtualAddress
        super.init(data, title: title, subTitle: nil)
    }
    
    override func initialize() async -> AsyncInitializeResult {
        // ref: https://opensource.apple.com/source/ld64/ld64-127.2/src/other/dyldinfo.cpp in function printFunctionStartsInfo
        // The code below decode (unsigned) LEB128 data into integers
        var functionStarts: [FunctionStart] = []
        var address: UInt64 = 0
        var index = 0
        while index < data.count {
            var delta: Swift.UInt64 = 0
            var shift: Swift.UInt32 = 0
            var more = true
            
            let startIndex = index
            repeat {
                let byte = data[data.startIndex+index]; index += 1
                delta |= ((Swift.UInt64(byte) & 0x7f) << shift)
                shift += 7
                if byte < 0x80 {
                    address += delta
                    functionStarts.append(FunctionStart(startOffset: startIndex, byteLength: index - startIndex, address: address))
                    more = false
                }
            } while (more)
        }
        return functionStarts
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let initializeResult = initializeResult as! [FunctionStart]
        
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        for functionStart in initializeResult {
            var symbolName: String = ""
            let functionVirtualAddress = functionStart.address + textSegmentVirtualAddress
            
            try? await self.symbolTable?.findSymbol(byVirtualAddress: functionVirtualAddress, callerTag: self.title)?.forEach({ symbolTableEntry in
                guard symbolTableEntry.symbolType == .section else { return }
                symbolName += symbolTableEntry.symbolName
            })
            
            translationGroup.addTranslation(definition: "Vitual Address",
                                            humanReadable: (functionStart.address + textSegmentVirtualAddress).hex,
                                            translationType: .uleb128(functionStart.byteLength),
                                            extraDefinition: "Referred Symbol Name",
                                            extraHumanReadable: symbolName)
            
        }
        return TranslationGroups([translationGroup])
    }
    
}
