//
//  MachoSlice.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation
import SwiftUI

typealias AsyncInitializeResult = Sendable
typealias AsyncTranslationResult = Sendable & SearchableTranslationContainer

enum MachoPortionAsyncLoadingStatus {
    case created
    case initializing
    case translating(AsyncInitializeResult)
    case translated(AsyncInitializeResult, AsyncTranslationResult)
}

actor MachoPortionStorage: ObservableObject {
    
    @MainActor @Published
    var loadingStatus: MachoPortionAsyncLoadingStatus = .created
    
    let title: String
    
    init(title: String) {
        self.title = title
    }
    
    func startLoading(machoPortion: MachoPortion) async {
        // forbiding re-enter
        guard case .created = await self.loadingStatus else { fatalError() }
        // start loading
        Task { @MainActor in
            self.loadingStatus = .initializing
        }
        let initializeResult = await machoPortion.initialize()
        Task { @MainActor in
            self.loadingStatus = .translating(initializeResult)
        }
        let translateResult = await machoPortion.translate(initializeResult: initializeResult)
        Task { @MainActor in
            self.loadingStatus = .translated(initializeResult, translateResult)
        }
    }
    
    func initializeResult(calleeTag: String) async throws -> AsyncInitializeResult {
        switch await self.loadingStatus {
        case .created:
            fallthrough
        case .initializing:
            print("\(calleeTag) is waiting for macho portion to init.")
            try await Task.sleep(for: Duration.milliseconds(100))
            return try await self.initializeResult(calleeTag: calleeTag)
        case .translating(let asyncInitializeResult):
            return asyncInitializeResult
        case .translated(let asyncInitializeResult, _):
            return asyncInitializeResult
        }
    }
    
    func translateResult(calleeTag: String) async throws -> AsyncTranslationResult {
        switch await self.loadingStatus {
        case .created:
            fallthrough
        case .initializing:
            fallthrough
        case .translating:
            print("\(calleeTag) is waiting for macho portion to translate.")
            try await Task.sleep(for: Duration.milliseconds(100))
            return try await self.translateResult(calleeTag: calleeTag)
        case .translated(_, let asyncTranslationResult):
            return asyncTranslationResult
        }
    }
    
}

class MachoPortion: Identifiable, Hashable, @unchecked Sendable {
    
    static func == (lhs: MachoPortion, rhs: MachoPortion) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    let id = UUID()
    let data: Data
    var dataSize: Int { data.count }
    var offsetInMacho: Int { data.startIndex }
    
    let title: String
    let subTitle: String?
    var readableTag: String { title + ", " + (subTitle ?? "") }
    
    let storage: MachoPortionStorage
    
    init(_ data: Data, title: String, subTitle: String?) {
        self.storage = MachoPortionStorage(title: title)
        self.data = data
        self.title = title
        self.subTitle = subTitle
        
        // kick start async loading
        Task {
            await self.storage.startLoading(machoPortion: self)
        }
    }
    
    func initialize() async -> AsyncInitializeResult {
        fatalError()
    }
    
    func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        fatalError()
    }
    
}
