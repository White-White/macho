//
//  Searachable.swift
//  DonQuixote
//
//  Created by white on 2025/1/29.
//

import Foundation

// search
struct TranslationSearchResult {
    let translationMetaInfo: TranslationMetaInfo
}

protocol SearchableTranslationContainer {
    func searchForTranslationMetaInfo(at dataIndexInMacho: UInt64) async -> TranslationSearchResult?
    func firstTranslationMetaInfo() -> TranslationSearchResult?
}
