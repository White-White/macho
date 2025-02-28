//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

struct SymbolTableEntryContainer {
    let symbolTableEntries: [SymbolTableEntry]
    let symbolTableEntryMap: [UInt64: [Int]]
}

class SymbolTable: MachoPortion, @unchecked Sendable {
    
    let is64Bit: Bool
    let stringTable: StringTable
    let machoSectionHeaders: [SectionHeader]
    
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
    
    override func initialize() async -> AsyncInitializeResult {

        var symbolTableEntries: [SymbolTableEntry] = []
        var symbolTableEntryMap: [UInt64: [Int]] = [:]
        
        let modelSize = self.is64Bit ? SymbolTableEntry.modelSizeFor64Bit : SymbolTableEntry.modelSizeFor32Bit
        let numberOfModels = self.dataSize/modelSize
        for index in 0..<numberOfModels {
            let data = self.data.subSequence(from: index * modelSize, count: modelSize)
            let entry = await SymbolTableEntry(with: data, is64Bit: self.is64Bit, stringTable: self.stringTable, machoSectionHeaders: self.machoSectionHeaders)
            symbolTableEntries.append(entry)
        }
        
        // quick index
        for (index, symbolEntry) in symbolTableEntries.enumerated() {
            
            /* comments from LinkEdit.m in MachoOView code base
            // it is possible to associate more than one symbol to the same address.
            // every new symbol will be appended to the list
            */
            
            if let existedIndexs = symbolTableEntryMap[symbolEntry.nValue] {
                symbolTableEntryMap[symbolEntry.nValue] = existedIndexs + [index]
            } else {
                symbolTableEntryMap[symbolEntry.nValue] = [index]
            }
        }
        
        return SymbolTableEntryContainer(symbolTableEntries: symbolTableEntries, symbolTableEntryMap: symbolTableEntryMap)
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let initializeResult = initializeResult as! SymbolTableEntryContainer
        var translationGroups: [TranslationGroup] = []
        for entry in initializeResult.symbolTableEntries {
            translationGroups.append(await entry.translationGroup)
        }
        return TranslationGroups(translationGroups)
    }
    
    func findSymbol(byVirtualAddress virtualAddress: UInt64, callerTag: String) async throws -> [SymbolTableEntry]? {
        let symbolTableEntryContainer = try await self.symbolTableEntryContainer(callerTag: callerTag)
        
        var symbolTableEntrys: [SymbolTableEntry] = []
        if let symbolTableEntryIndexs = symbolTableEntryContainer.symbolTableEntryMap[virtualAddress] {
            symbolTableEntrys = symbolTableEntryIndexs.map { symbolTableEntryContainer.symbolTableEntries[$0] }
        }
        return symbolTableEntrys
    }
    
    func findSymbol(atIndex index: Int, callerTag: String) async throws -> SymbolTableEntry {
        let symbolTableEntryContainer = try await self.symbolTableEntryContainer(callerTag: callerTag)
        
        guard index < symbolTableEntryContainer.symbolTableEntries.count else { fatalError() }
        return symbolTableEntryContainer.symbolTableEntries[index]
    }
    
    func symbolTableEntryContainer(callerTag: String) async throws -> SymbolTableEntryContainer {
        (try await self.storage.initializeResult(calleeTag: callerTag)) as! SymbolTableEntryContainer
    }
    
}


