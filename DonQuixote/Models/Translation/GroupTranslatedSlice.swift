//
//  GroupTranslatedSlice.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation

class GroupTranslatedMachoSlice: MachoTranslatedSlice<[TranslationGroup]> {
    
    override func searchForTranslationMetaInfo(at dataIndexInMacho: UInt64) async -> MachoSlice.SearchResult? {
        guard let translationGroups = await self.untilTranslated(source: "Translation search") else { return nil }
        
        let group = translationGroups.binarySearch { group in
            if group.dataRangeInMacho.lowerBound > dataIndexInMacho {
                return .left
            } else if group.dataRangeInMacho.upperBound <= dataIndexInMacho {
                return .right
            } else {
                return .matched
            }
        }

        let translation = group?.translations.binarySearch(matchCheck: { translation in
            if translation.metaInfo.dataRangeInMacho.lowerBound > dataIndexInMacho {
                return .left
            } else if translation.metaInfo.dataRangeInMacho.upperBound <= dataIndexInMacho {
                return .right
            } else {
                return .matched
            }
        })
        
        if let group, let translation {
            return SearchResult(enclosedDataRange: group.dataRangeInMacho, translationMetaInfo: translation.metaInfo)
        }

        return nil
    }
    
    override func searchForFirstTranslationMetaInfo() -> MachoSlice.SearchResult? {
        if case .translated(let translationGroups) = self.loadingStatus,
           let firstGroup = translationGroups.first,
           let firstTranslation = firstGroup.translations.first {
            return SearchResult(enclosedDataRange: firstGroup.dataRangeInMacho, translationMetaInfo: firstTranslation.metaInfo)
        }
        return nil
    }
    
}
