//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class SymbolTable: GroupTranslatedMachoSlice {
    
    let is64Bit: Bool
    let stringTable: StringTable
    let machoSectionHeaders: [SectionHeader]
    
    private var symbolTableEntries: [SymbolTableEntry] = []
    private var symbolTableEntryMap: [UInt64: [Int]] = [:]
    
    init(symbolTableOffset: Int,
         numberOfSymbolTableEntries: Int,
         machoData: Data,
         machoHeader: MachoHeader,
         stringTable: StringTable,
         machoSectionHeaders: [SectionHeader]) {
        
        let entrySize = machoHeader.is64Bit ? 16 : 12
        let symbolTableData = machoData.subSequence(from: symbolTableOffset, count: numberOfSymbolTableEntries * entrySize)
        self.is64Bit = machoHeader.is64Bit
        self.stringTable = stringTable
        self.machoSectionHeaders = machoSectionHeaders
        super.init(symbolTableData, title: "Symbol Table", subTitle: nil)
        
    }
    
    override func initialize() async {
        let modelSize = self.is64Bit ? SymbolTableEntry.modelSizeFor64Bit : SymbolTableEntry.modelSizeFor32Bit
        let numberOfModels = self.dataSize/modelSize
        for index in 0..<numberOfModels {
            let data = self.data.subSequence(from: index * modelSize, count: modelSize)
            let entry = await SymbolTableEntry(with: data, is64Bit: self.is64Bit, stringTable: self.stringTable, machoSectionHeaders: self.machoSectionHeaders)
            self.symbolTableEntries.append(entry)
        }
        
        // quick index
        for (index, symbolEntry) in self.symbolTableEntries.enumerated() {
            
            /* comments from LinkEdit.m in MachoOView code base
            // it is possible to associate more than one symbol to the same address.
            // every new symbol will be appended to the list
            */
            
            if let existedIndexs = self.symbolTableEntryMap[symbolEntry.nValue] {
                self.symbolTableEntryMap[symbolEntry.nValue] = existedIndexs + [index]
            } else {
                self.symbolTableEntryMap[symbolEntry.nValue] = [index]
            }
        }
    }
    
    override func translate(_ progressNotifier: @escaping (Float) -> Void) async -> [TranslationGroup] {
        var translationGroups: [TranslationGroup] = []
        for entry in self.symbolTableEntries {
            translationGroups.append(await entry.translationGroup)
        }
        return translationGroups
    }
    
    func findSymbol(byVirtualAddress virtualAddress: UInt64, callerTag: String) async -> [SymbolTableEntry]? {
        await self.untilInitialized(source: callerTag)
        var symbolTableEntrys: [SymbolTableEntry] = []
        if let symbolTableEntryIndexs = symbolTableEntryMap[virtualAddress] {
            symbolTableEntrys = symbolTableEntryIndexs.map { self.symbolTableEntries[$0] }
        }
        return symbolTableEntrys
    }
    
    func findSymbol(atIndex index: Int, callerTag: String) async -> SymbolTableEntry {
        await self.untilInitialized(source: callerTag)
        guard index < self.symbolTableEntries.count else { fatalError() }
        return self.symbolTableEntries[index]
    }
    
}


