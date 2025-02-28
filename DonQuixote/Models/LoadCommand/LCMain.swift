//
//  LCMain.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCMain: LoadCommand, @unchecked Sendable {
    
    let entryOffset: UInt64
    let stackSize: UInt64
    
    init(with type: LoadCommandType, data: Data) {
        self.entryOffset = data.subSequence(from: 8, count: 8).UInt64
        self.stackSize = data.subSequence(from: 16, count: 8).UInt64
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Entry Offset (relative to __TEXT)", humanReadable: entryOffset.hex, translationType: .uint64)
        translationGroup.addTranslation(definition: "Entry Offset (relative to __TEXT)", humanReadable: entryOffset.hex, translationType: .uint64)
    }
    
}
