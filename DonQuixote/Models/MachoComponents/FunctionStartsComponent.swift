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

class FunctionStartsSection: MachoBaseElement {
    
    let symbolTable: SymbolTable?
    let textSegmentVirtualAddress: Swift.UInt64
    let functionStarts: [FunctionStart]
    
    init(_ data: Data, title: String, textSegmentVirtualAddress: UInt64, symbolTable: SymbolTable?) {
        self.symbolTable = symbolTable
        self.textSegmentVirtualAddress = textSegmentVirtualAddress
        
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
        self.functionStarts = functionStarts
        super.init(data, title: title, subTitle: nil)
    }
    
    override func loadTranslations() async {
        let translations = await withTaskGroup(of: Translation.self, body: { taskGroup in
            for functionStart in functionStarts {
                taskGroup.addTask {
                    await self.translation(for: functionStart)
                }
            }
            return await taskGroup.reduce(into: [Translation]()) { partialResult, translation in
                partialResult.append(translation)
            }
        })
        await self.save(translations: translations)
    }
    
    private func translation(for functionStart: FunctionStart) async -> Translation {
        var symbolName: String = ""
        let functionVirtualAddress = functionStart.address + textSegmentVirtualAddress
        
        await self.symbolTable?.findSymbol(byVirtualAddress: functionVirtualAddress, callerTag: self.title)?.forEach({ symbolTableEntry in
            guard symbolTableEntry.symbolType == .section else { return }
            symbolName += symbolTableEntry.symbolName
        })
        
        let translation = Translation(definition: "Vitual Address",
                                      humanReadable: (functionStart.address + textSegmentVirtualAddress).hex,
                                      translationType: .uleb128(functionStart.byteLength),
                                      extraDefinition: "Referred Symbol Name",
                                      extraHumanReadable: symbolName)
        return translation
    }
    
}
