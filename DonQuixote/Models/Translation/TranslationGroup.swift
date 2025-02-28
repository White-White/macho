//
//  TranslationGroup.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation

class TranslationGroup: Identifiable {
    
    let id = UUID()
    
    let offsetInMacho: Int
    
    init(dataStartIndex: Int) {
        self.offsetInMacho = dataStartIndex
    }
    
    private(set) var bytesCount: Int = 0
    private(set) var translations: [Translation] = []
    
    var dataRangeInMacho: Range<UInt64> {
        UInt64(offsetInMacho)..<UInt64(offsetInMacho+bytesCount)
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
        let nextTranslation = Translation(dataIndexInMacho: offsetInMacho + bytesCount,
                                          definition: definition,
                                          humanReadable: humanReadable,
                                          translationType: translationType,
                                          extraDefinition: extraDefinition,
                                          extraHumanReadable: extraHumanReadable,
                                          error: error)

        self.bytesCount += nextTranslation.metaInfo.bytesCount
        self.translations.append(nextTranslation)
    }
    
}

class TranslationGroups: SearchableTranslationContainer, @unchecked Sendable {
    
    let translationGroups: [TranslationGroup]
    
    init(_ translationGroups: [TranslationGroup]) {
        self.translationGroups = translationGroups
    }
    
    func searchForTranslationMetaInfo(at offsetInMacho: UInt64) async -> TranslationSearchResult? {
        
        let group = translationGroups.binarySearch { group in
            if group.dataRangeInMacho.lowerBound > offsetInMacho {
                return .left
            } else if group.dataRangeInMacho.upperBound <= offsetInMacho {
                return .right
            } else {
                return .matched
            }
        }

        let translation = group?.translations.binarySearch(matchCheck: { translation in
            if translation.metaInfo.dataRangeInMacho.lowerBound > offsetInMacho {
                return .left
            } else if translation.metaInfo.dataRangeInMacho.upperBound <= offsetInMacho {
                return .right
            } else {
                return .matched
            }
        })
        
        if let group, let translation {
            return TranslationSearchResult(translationMetaInfo: translation.metaInfo)
        }

        return nil
    }
    
    func firstTranslationMetaInfo() -> TranslationSearchResult? {
        if let firstTranslationMetaInfo = self.translationGroups.first?.translations.first?.metaInfo {
            return TranslationSearchResult(translationMetaInfo: firstTranslationMetaInfo)
        }
        return nil
    }
    
}
