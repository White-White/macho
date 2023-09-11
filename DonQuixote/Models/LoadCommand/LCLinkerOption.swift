//
//  LinkerOption.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCLinkerOption: LoadCommand {
    
    let numberOfOptions: UInt32
    let optionDataLength: Int
    let options: [String]
    
    init(with type: LoadCommandType, data: Data) {
        self.numberOfOptions = data.subSequence(from: 8, count: 4).UInt32
        self.optionDataLength = data.count - 12
        self.options = LCLinkerOption.options(from: data.subSequence(from: 12))
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Number of options", humanReadable: "\(self.numberOfOptions)", translationType: .uint32)
        translationGroup.addTranslation(definition: "Options(s)", humanReadable: self.options.joined(separator: " "), translationType: .utf8String(self.optionDataLength))
    }
    
    static func options(from data: Data) -> [String] {
        return data.split(separator: 0x00).map {
            if let optionString = String(data: $0, encoding: .utf8) {
                return optionString
            } else {
                return Log.warning("Unexpected, found unknown linker option. Breakpoint to debug")
            }
        }
    }
}
