//
//  TranslationGroup.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation

class TranslationGroup: @unchecked Sendable, Identifiable {
    
    let dataStartIndex: Int
    
    private(set) var bytesCount: Int = 0
    private(set) var translations: [Translation] = []
    
    var dataRangeInMacho: Range<UInt64> {
        UInt64(dataStartIndex)..<UInt64(dataStartIndex)+UInt64(bytesCount)
    }
    
    init(dataStartIndex: Int) {
        self.dataStartIndex = dataStartIndex
    }
    
    func addTranslation(definition: String?,
                        humanReadable: String,
                        translationType: TranslationDataType,
                        extraDefinition: String? = nil,
                        extraHumanReadable: String? = nil,
                        error: String? = nil) {
        let nextTranslationStartIndex = UInt64(dataStartIndex + bytesCount)
        let nextTranslationBytesCount = UInt64(translationType.bytesCount)
        let nextTranslationDataRange = nextTranslationStartIndex..<(nextTranslationStartIndex + nextTranslationBytesCount)
        let translation = Translation(dataRangeInMacho: nextTranslationDataRange,
                                      definition: definition,
                                      humanReadable: humanReadable,
                                      translationType: translationType,
                                      extraDefinition: extraDefinition,
                                      extraHumanReadable: extraHumanReadable,
                                      error: error)
        self.addTranslation(translation: translation)
    }
    
    func addTranslation(translation: Translation) {
        self.bytesCount += translation.translationType.bytesCount
        self.translations.append(translation)
    }
    
    func merge(_ translationGroup: TranslationGroup) {
        guard self.dataStartIndex + self.bytesCount == translationGroup.dataStartIndex else { fatalError() }
        translationGroup.translations.forEach { self.addTranslation(translation: $0) }
    }
    
}
