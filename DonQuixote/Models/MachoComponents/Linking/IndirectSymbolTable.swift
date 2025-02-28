//
//  IndirectSymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class IndirectSymbolTable: MachoPortion, @unchecked Sendable {
    
    let is64Bit: Bool
    let symbolTable: SymbolTable?
    
    init(_ data: Data, title: String, is64Bit: Bool, symbolTable: SymbolTable?) {
        self.is64Bit = is64Bit
        self.symbolTable = symbolTable
        super.init(data, title: title, subTitle: nil)
    }
    
    override func initialize() async -> AsyncInitializeResult {
        var indirectSymbolTableEntries: [IndirectSymbolTableEntry] = []
        let modelSize = self.is64Bit ? IndirectSymbolTableEntry.modelSizeFor64Bit : IndirectSymbolTableEntry.modelSizeFor32Bit
        let numberOfModels = self.dataSize/modelSize
        for index in 0..<numberOfModels {
            let data = self.data.subSequence(from: index * modelSize, count: modelSize)
            let entry = IndirectSymbolTableEntry(with: data, is64Bit: self.is64Bit, symbolTable: self.symbolTable)
            indirectSymbolTableEntries.append(entry)
        }
        return indirectSymbolTableEntries
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let initializeResult = initializeResult as! [IndirectSymbolTableEntry]
        var translationGroups: [TranslationGroup] = []
        for entry in initializeResult {
            translationGroups.append(await entry.translationGroup)
        }
        return TranslationGroups(translationGroups)
    }
    
    func findIndirectSymbol(atIndex index: Int) async throws -> IndirectSymbolTableEntry {
        let initializeResult = try await self.storage.initializeResult(calleeTag: "Find Symbol")
        let indirectSymbolTableEntries = initializeResult as! [IndirectSymbolTableEntry]
        guard index < indirectSymbolTableEntries.count else { fatalError() }
        return indirectSymbolTableEntries[index]
    }
    
}
