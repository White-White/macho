//
//  UnknownSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/4.
//

import Foundation

class UnknownSection: MachoPortion, @unchecked Sendable {
    
    override func initialize() async -> AsyncInitializeResult {
        return Void()
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        translationGroup.addTranslation(definition: "Unknow",
                                        humanReadable: "Mocha doesn's know how to parse this section yet.",
                                        translationType: .rawData(0))
        return TranslationGroups([translationGroup])
    }
    
}
