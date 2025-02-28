//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

class MachoViewState: ObservableObject, @unchecked Sendable {
    
    let macho: Macho
    
    private var taskForFetchingFirstTranslation: Task<(), Never>?
    
    func cancelTaskForFetchingFirstTranslation() {
        self.taskForFetchingFirstTranslation?.cancel()
    }
    
    @Published
    var selectedMachoPortion: MachoPortion {
        didSet {
            self.cancelTaskForFetchingFirstTranslation()
            taskForFetchingFirstTranslation = Task {
                guard let firstMachoPortionTranslation =
                        try? await selectedMachoPortion.storage.translateResult(calleeTag: "didSet macho portion").firstTranslationMetaInfo() else {
                    return
                }
                if !Task.isCancelled {
                    Task { @MainActor in
                        self.selectedTranslationMetaInfo = firstMachoPortionTranslation.translationMetaInfo
                    }
                } else {
                    Log.info("task for searching first translaiton in \(selectedMachoPortion.title) is cancelled.")
                }
            }
        }
    }
    
    @Published
    var selectedTranslationMetaInfo: TranslationMetaInfo {
        didSet {
            self.questionToDeepSeek = selectedTranslationMetaInfo.generateQuestion()
        }
    }
    
    var selectedDataRange: Range<UInt64> {
        selectedTranslationMetaInfo.dataRangeInMacho
    }
    
    @Published
    var questionToDeepSeek: String
    
    init(macho: Macho) {
        self.macho = macho
        let machoHeader = macho.machoHeader
        let firstTranslation = machoHeader.translationGroup.translations.first!
        self.selectedMachoPortion = machoHeader
        self.selectedTranslationMetaInfo = firstTranslation.metaInfo
        self.questionToDeepSeek = firstTranslation.metaInfo.generateQuestion()
    }
    
}

// generall we shouldn't init States in init method.
// ref: https://swiftcraft.io/blog/how-to-initialize-state-inside-the-views-init-
struct MachoView: DocumentView {
    
    let machoViewState: MachoViewState
    
    init(_ macho: Macho) {
        self.machoViewState = MachoViewState(macho: macho)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            
            HexFiendViewControllerRepresentable()
                .onClickHexView({ dataIndex in
                    Task {
                        await self.onClickHexView(at: dataIndex)
                    }
                })
            
            MachoPortionListView()
            
            VStack(spacing: 4) {
                TranslationView(machoPortionStorage: self.machoViewState.selectedMachoPortion.storage)
                DeepSeekView()
            }
            .frame(minWidth: 400)
                
        }
        .environmentObject(self.machoViewState)
    }
    
    @MainActor
    func onClickHexView(at dataIndexInMacho: UInt64) async {
        
        let machoPortion = self.machoViewState.macho.allPortions.binarySearch { element in
            if element.data.startIndex > dataIndexInMacho {
                return .left
            } else if element.data.endIndex <= dataIndexInMacho {
                return .right
            } else {
                return .matched
            }
        }
        
        guard let machoPortion else {
            Log.error("didn't find any macho portion")
            return
        }
        
        switch machoPortion.storage.loadingStatus {
        case .translated(_, let translationResult):
            Task { @MainActor in
                if let searchResult = await translationResult.searchForTranslationMetaInfo(at: dataIndexInMacho) {
                    self.machoViewState.selectedMachoPortion = machoPortion
                    self.machoViewState.cancelTaskForFetchingFirstTranslation()
                    self.machoViewState.selectedTranslationMetaInfo = searchResult.translationMetaInfo
                }
            }
        default:
            return
        }
        
    }
    
}
