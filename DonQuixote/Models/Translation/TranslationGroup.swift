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
    
    var dataRangeInMacho: HexFiendDataRange {
        HexFiendDataRange(lowerBound: UInt64(dataStartIndex), length: UInt64(bytesCount))
    }
    
    init(dataStartIndex: Int) {
        self.dataStartIndex = dataStartIndex
    }
    
    func skip(size: Int) {
        guard size > 0 else { fatalError() } 
        self.bytesCount += size
    }
    
    func addTranslation(definition: String?,
                        humanReadable: String,
                        translationType: TranslationType,
                        extraDefinition: String? = nil,
                        extraHumanReadable: String? = nil,
                        error: String? = nil) {
        let nextTranslation = Translation(dataIndexInMacho: dataStartIndex + bytesCount,
                                          definition: definition,
                                          humanReadable: humanReadable,
                                          translationType: translationType,
                                          extraDefinition: extraDefinition,
                                          extraHumanReadable: extraHumanReadable,
                                          error: error)
        self.addTranslation(translation: nextTranslation)
    }
    
    func addTranslation(translation: Translation) {
        self.bytesCount += translation.metaInfo.bytesCount
        self.translations.append(translation)
    }
    
}
