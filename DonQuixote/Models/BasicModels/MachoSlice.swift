//
//  MachoSlice.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation
import SwiftUI

enum LoadingStatus<TranslationResult: Sendable> {
    case created
    case initializing(Float)
    case translating(Float)
    case translated(TranslationResult)
}

class MachoSlice: Identifiable, Equatable, Hashable, @unchecked Sendable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: MachoSlice, rhs: MachoSlice) -> Bool {
        lhs.id == rhs.id
    }
    
    let id = UUID()
    let data: Data
    var dataSize: Int { data.count }
    var offsetInMacho: Int { data.startIndex }
    
    let title: String
    let subTitle: String?
    var readableTag: String { title + ", " + (subTitle ?? "") }
    
    init(_ data: Data, title: String, subTitle: String?) {
        self.data = data
        self.title = title
        self.subTitle = subTitle
    }
    
    func initialize() async {
        
    }
    
    struct TranslationSearchResult {
        let translationGroup: TranslationGroup?
        let translation: Translation?
    }
    
    func searchForTranslation(with targetDataIndex: UInt64) async -> TranslationSearchResult? {
        fatalError()
    }
    
}

class MachoTranslatedSlice<TranslationResult: Sendable>: MachoSlice, ObservableObject {
    
    @MainActor @Published
    private(set) var loadingStatus: LoadingStatus<TranslationResult> = .created
    
    override init(_ data: Data, title: String, subTitle: String?) {
        super.init(data, title: title, subTitle: subTitle)
        self.load()
    }
    
    func translate() async -> TranslationResult {
        fatalError()
    }
    
}

extension MachoTranslatedSlice {
    
    func load() {
        Task {
            guard case .success(true) = await (Task { @MainActor in
                if case .created = self.loadingStatus {
                    self.loadingStatus = .initializing(.zero)
                    return true
                } else {
                    return false
                }
            }).result else { return }
            
            let tick = TickTock()
            await self.initialize()
            tick.tock("Init " + self.readableTag, threshHold: 5)
            tick.reset()
            
            Task { @MainActor in
                self.loadingStatus = .translating(.zero)
            }
            
            let translationResult = await self.translate()
            tick.tock("Translate " + self.readableTag, threshHold: 10)
            
            Task { @MainActor in
                self.loadingStatus = .translated(translationResult)
            }
        }
    }
    
    func untilInitialized(source: String) async {
        
        @MainActor
        func ready() async -> Bool {
            switch self.loadingStatus {
            case .created:
                return false
            case .initializing:
                return false
            case .translating:
                return true
            case .translated:
                return true
            }
        }
        
        while await !ready() {
            print("\(source) is waiting for \(self.readableTag) to init.")
            do {
                try await Task.sleep(for: Duration.milliseconds(50))
                try Task.checkCancellation()
            } catch {
                print("\(source) cancelled waiting.")
                return
            }
            await Task.yield()
        }
        
    }
    
    func untilTranslated(source: String) async -> TranslationResult? {
        
        @MainActor
        func fetchTranslationResult() async -> TranslationResult? {
            switch self.loadingStatus {
            case .created:
                fallthrough
            case .initializing:
                fallthrough
            case .translating:
                return nil
            case .translated(let result):
                return result
            }
        }
        
        var result = await fetchTranslationResult()
        
        while result == nil {
            print("\(source) is waiting for \(self.readableTag) to translate.")
            do {
                try await Task.sleep(for: Duration.milliseconds(50))
                try Task.checkCancellation()
            } catch {
                print("\(source) cancelled waiting.")
                return nil
            }
            await Task.yield()
            result = await fetchTranslationResult()
        }
        
        return result!
        
    }
    
}
