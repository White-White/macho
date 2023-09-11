//
//  LCOneString.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCMonoString: LoadCommand {
    
    let stringOffset: UInt32
    let stringLength: Int
    let string: String
    
    init(with type: LoadCommandType, data: Data) {
        self.stringOffset = data.subSequence(from: 8, count: 4).UInt32
        self.stringLength = data.count - Int(self.stringOffset)
        self.string = data.subSequence(from: Int(self.stringOffset)).utf8String ?? Log.warning("Failed to parse \(type.name). Debug me.")
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "String Offset", humanReadable: self.stringOffset.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Content", humanReadable: string, translationType: .utf8String(self.stringLength))
    }
    
}
