//
//  GroupTranslatedSlice.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation

class GroupTranslatedMachoSlice: MachoTranslatedSlice<[TranslationGroup]> {
    
    override func searchForTranslation(with targetDataIndex: UInt64) async -> TranslationSearchResult? {
        
        guard let translationGroups = await self.untilTranslated(source: "Translation search") else { return nil }
        
        let findedGroup = translationGroups.binarySearch { group in
            if group.dataStartIndex > targetDataIndex {
                return .searchLeft
            } else if group.dataRangeInMacho.endIndex <= targetDataIndex {
                return .searchRight
            } else {
                return .matched
            }
        }

        let findedTranslation = findedGroup?.translations.binarySearch(matchCheck: { translation in
            if translation.dataRangeInMacho.startIndex > targetDataIndex {
                return .searchLeft
            } else if translation.dataRangeInMacho.endIndex <= targetDataIndex {
                return .searchRight
            } else {
                return .matched
            }
        })

        return TranslationSearchResult(translationGroup: findedGroup, translation: findedTranslation)
        
    }
    
}
