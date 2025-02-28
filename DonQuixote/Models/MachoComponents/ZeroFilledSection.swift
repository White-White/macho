//
//  ZeroFilledSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/4.
//

import Foundation

class ZeroFilledSection: MachoPortion, @unchecked Sendable {
    
    let runtimeSize: Int
    
    init(runtimeSize: Int, title: String) {
        self.runtimeSize = runtimeSize
        super.init(Data(), /* dummy data */ title: title, subTitle: nil)
    }
    
    override func initialize() async -> AsyncInitializeResult {
        return Void()
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        translationGroup.addTranslation(definition: "Zero Filled Section",
                                        humanReadable: "This section has no data in the macho file.\nIts in memory size is \(runtimeSize.hex)",
                                        translationType: .rawData(0))
        return TranslationGroups([translationGroup])
    }
    
}
