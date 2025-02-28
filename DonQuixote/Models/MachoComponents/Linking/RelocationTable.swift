//
//  RelocationTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/13.
//

import Foundation

struct RelocationInfo {
    let numberOfEntries: Int
    let sectionName: String
}

class RelocationTable: MachoPortion, @unchecked Sendable {
    
    let relocationInfos: [RelocationInfo]
    
    init(data: Data, relocationInfos: [RelocationInfo]) {
        self.relocationInfos = relocationInfos
        super.init(data, title: "Relocation Table", subTitle: nil)
    }
    
    override func initialize() async -> AsyncInitializeResult {
        var relocationEntries: [RelocationEntry] = []
        var dataShifter = DataShifter(self.data)
        for relocationInfo in relocationInfos {
            for _ in 0..<relocationInfo.numberOfEntries {
                let entryData = dataShifter.shift(.rawNumber(RelocationEntry.entrySize))
                let entry = RelocationEntry(with: entryData, sectionName: relocationInfo.sectionName)
                relocationEntries.append(entry)
            }
        }
        return relocationEntries
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let initializeResult = initializeResult as! [RelocationEntry]
        return TranslationGroups(initializeResult.map { $0.translationGroup })
    }
    
}
