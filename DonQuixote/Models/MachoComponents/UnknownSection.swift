//
//  UnknownSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/4.
//

import Foundation

class UnknownSection: GroupTranslatedMachoSlice {
    
    override func translate(_ progressNotifier: @escaping (Float) -> Void) async -> [TranslationGroup] {
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        translationGroup.addTranslation(definition: "Unknow",
                                        humanReadable: "Mocha doesn's know how to parse this section yet.",
                                        translationType: .rawData(0))
        return [translationGroup]
    }
    
}
