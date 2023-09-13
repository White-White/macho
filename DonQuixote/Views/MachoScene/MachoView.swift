//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

//@MainActor
//class MachoViewState: ObservableObject {
//
//    @Published var selectedMachoSlice: MachoSlice
//
//
//
//
//    init(_ macho: Macho) {
//        self.selectedMachoSlice = macho.machoHeader
//        self.selectFirstTranslationWhenPossible()
//    }
//
//    func onClick(machoSlice: MachoSlice) {
//        self.selectedMachoSlice = machoSlice
//        self.selectFirstTranslationWhenPossible()
//    }
//
//    func selectFirstTranslationWhenPossible() {
//        Task {
//            await self.selectedMachoSlice.translationStore.suspendUntilLoaded(callerTag: "Auto select")
//            if let firstGroup = self.selectedMachoSlice.translationStore.translationGroups.first {
//                Task { @MainActor in
//                    self.updateHexViewColoredDataRange(with: firstGroup.dataRangeInMacho)
//                    self.updateHexViewSelectedDataRange(with: firstGroup.translations.first?.rangeInMacho)
//                    self.selectedTranslation = firstGroup.translations.first
//                }
//            }
//        }
//    }
//
//}

struct MachoViewState {
    
    var selectedMachoSlice: MachoSlice
    var selectedTranslationMetaInfo: TranslationMetaInfo
    private(set) var coloredDataRange: HexFiendDataRange
    private(set) var selectedDataRange: HexFiendDataRange
    
    init(selectedMachoSlice: MachoSlice, selectedTranslationMetaInfo: TranslationMetaInfo, coloredDataRange: HexFiendDataRange, selectedDataRange: HexFiendDataRange) {
        self.selectedMachoSlice = selectedMachoSlice
        self.selectedTranslationMetaInfo = selectedTranslationMetaInfo
        self.coloredDataRange = coloredDataRange
        self.selectedDataRange = selectedDataRange
    }
    
    mutating func update(coloredDataRange: HexFiendDataRange) {
        if self.coloredDataRange != coloredDataRange {
            self.coloredDataRange = coloredDataRange
        }
    }
    
    mutating func update(selectedDataRange: HexFiendDataRange) {
        if self.selectedDataRange != selectedDataRange {
            self.selectedDataRange = selectedDataRange
        }
    }
    
}

// generall we shouldn't init States in init method.
// ref: https://swiftcraft.io/blog/how-to-initialize-state-inside-the-views-init-
struct MachoView: DocumentView {
    
    let macho: Macho
    @State var machoViewState: MachoViewState
    
    init(_ macho: Macho) {
        self.macho = macho
        let machoHeader = macho.machoHeader
        let firstTranslation = machoHeader.translationGroup.translations.first!
        self.machoViewState = MachoViewState(selectedMachoSlice: machoHeader,
                                             selectedTranslationMetaInfo: firstTranslation.metaInfo,
                                             coloredDataRange: machoHeader.translationGroup.dataRangeInMacho,
                                             selectedDataRange: firstTranslation.metaInfo.dataRangeInMacho)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            
            HexFiendViewControllerRepresentable(data: macho.machoData, machoViewState: $machoViewState)
                .onClickHexView({ dataIndex in
                    Task {
                        await self.onClickHexView(at: dataIndex)
                    }
                })
                .border(.separator, width: 1)
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(self.macho.allSlices) { machoSlice in
                            ComponentListCell(machoSlice: machoSlice, isSelected: machoViewState.selectedMachoSlice == machoSlice)
                                .onTapGesture {
                                    self.machoViewState.selectedMachoSlice = machoSlice
                                    if let searchResult = machoSlice.searchForFirstTranslationMetaInfo() {
                                        self.machoViewState.selectedTranslationMetaInfo = searchResult.translationMetaInfo
                                        self.machoViewState.update(coloredDataRange: searchResult.enclosedDataRange)
                                        self.machoViewState.update(selectedDataRange: searchResult.translationMetaInfo.dataRangeInMacho)
                                    } else {
                                        self.machoViewState.update(coloredDataRange: machoSlice.dataRangeInMacho)
                                    }
                                }
                        }
                    }
                }
                .border(.separator, width: 1)
                .frame(width: ComponentListCell.widthNeeded(for: self.macho.allSlices))
                .onChange(of: machoViewState.selectedMachoSlice) { newValue in
                    withAnimation {
                        scrollViewProxy.scrollTo(newValue.id)
                    }
                }
            }
            
            TranslationView(machoViewState: $machoViewState)
                
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        
//        .onReceive(NotificationCenter.default.publisher(for: HexFiendViewController.MouseDownNoti, object: machoViewState.hexFiendViewController)) { output in
//            if let charIndex = output.userInfo?[HexFiendViewController.MouseDownNotiCharIndexKey] as? UInt64 {
//                Task {
//                    await machoViewState.onClickHexView(at: charIndex)
//                }
//            }
//        }
    }
    
    @MainActor
    func onClickHexView(at dataIndexInMacho: UInt64) async {
        
        let machoSlice = self.macho.allSlices.binarySearch { element in
            if element.data.startIndex > dataIndexInMacho {
                return .left
            } else if element.data.endIndex <= dataIndexInMacho {
                return .right
            } else {
                return .matched
            }
        }
        
        if let machoSlice, let searchResult = await machoSlice.searchForTranslationMetaInfo(at: dataIndexInMacho) {
            self.machoViewState.selectedMachoSlice = machoSlice
            self.machoViewState.selectedTranslationMetaInfo = searchResult.translationMetaInfo
            self.machoViewState.update(coloredDataRange: searchResult.enclosedDataRange)
            self.machoViewState.update(selectedDataRange: searchResult.translationMetaInfo.dataRangeInMacho)
        }
        
    }
    
}
