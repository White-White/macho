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

struct MachoViewSelection {
    
    var selectedMachoSlice: MachoSlice
    var selectedTranslation: Translation?
    var coloredDataRange: Range<UInt64>? = nil
    var selectedDataRange: Range<UInt64>? = nil
    
    func isSelected(_ machoSlice: MachoSlice) -> Bool {
        self.selectedMachoSlice == machoSlice
    }
    
    mutating func select(_ machoSlice: MachoSlice) {
        self.selectedMachoSlice = machoSlice
    }
    
}

// generall we shouldn't init States in init method.
// ref: https://swiftcraft.io/blog/how-to-initialize-state-inside-the-views-init-
struct MachoView: DocumentView {
    
    let macho: Macho
    @State var machoViewSelection: MachoViewSelection
    
    init(_ macho: Macho) {
        self.macho = macho
        self.machoViewSelection = MachoViewSelection(selectedMachoSlice: macho.machoHeader)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            
            HexFiendViewControllerRepresentable(data: macho.machoData, machoViewSelection: $machoViewSelection, clickingHexViewCallBack: self.onClickHexView)
                .border(.separator, width: 1)
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(self.macho.allSlices) { machoSlice in
                            ComponentListCell(machoSlice: machoSlice, isSelected: machoViewSelection.isSelected(machoSlice))
                                .onTapGesture {
                                    self.machoViewSelection.select(machoSlice)
                                }
                        }
                    }
                }
                .border(.separator, width: 1)
                .frame(width: ComponentListCell.widthNeeded(for: self.macho.allSlices))
//                .onChange(of: machoViewState.selectedMachoSlice) { newValue in
//                    withAnimation {
//                        scrollViewProxy.scrollTo(newValue.id)
//                    }
//                }
            }
            
            TranslationView(machoViewSelection: $machoViewSelection)
                
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
    
    
    @State var existingSearchTask: Task<(), Never>?
    func onClickHexView(at dataIndexInMacho: UInt64) {
        
        
        guard let machoSliceFound = (self.macho.allSlices.binarySearch { element in
            if element.data.startIndex > dataIndexInMacho {
                return .searchLeft
            } else if element.data.endIndex <= dataIndexInMacho {
                return .searchRight
            } else {
                return .matched
            }
        }) else { return }
        
        self.machoViewSelection.selectedMachoSlice = machoSliceFound
        
        
        existingSearchTask?.cancel()
        existingSearchTask = nil
        existingSearchTask = Task {
            Task {
                let searchResult = await machoSliceFound.searchForTranslation(with: dataIndexInMacho)
                
                Task { @MainActor in
                    self.machoViewSelection.selectedTranslation = searchResult?.translation
                    self.machoViewSelection.coloredDataRange = searchResult?.translationGroup?.dataRangeInMacho
                    self.machoViewSelection.selectedDataRange = searchResult?.translation?.dataRangeInMacho
                }
                
            }
            
        }
    }
    
}
