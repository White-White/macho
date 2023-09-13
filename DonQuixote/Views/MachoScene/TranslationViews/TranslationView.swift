//
//  TranslationView.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation
import SwiftUI

struct AsyncView<Translated: Sendable, Content: View>: View {
    
    @ObservedObject var translatedSlice: MachoTranslatedSlice<Translated>
    let contentBuilder: (_ item: Translated) -> Content
    
    init(translatedSlice: MachoTranslatedSlice<Translated>, @ViewBuilder contentBuilder: @escaping (_ item: Translated) -> Content) {
        self.translatedSlice = translatedSlice
        self.contentBuilder = contentBuilder
    }
    
    var body: some View {
        VStack {
            switch translatedSlice.loadingStatus {
            case .created:
                Text("\(translatedSlice.readableTag) is loading...")
            case .initializing(let progress):
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        ProgressView()
                        Text(String(format: "Initializing... (%.2f %%)", progress * 100))
                    }
                }
            case .translating(let progress):
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        ProgressView()
                        Text(String(format: "Translating... (%.2f %%)", progress * 100))
                    }
                }
            case .translated(let translated):
                self.contentBuilder(translated)
            }
        }
        .frame(width: 600)
    }
    
}

struct TranslationView: View {
    
    @Binding var machoViewState: MachoViewState
    
    var body: some View {
        if let groupTranslatedSlice = machoViewState.selectedMachoSlice as? GroupTranslatedMachoSlice {
            AsyncView(translatedSlice: groupTranslatedSlice) { transtionGroups in
                GroupTranslationView(translationGroups: transtionGroups, machoViewState: $machoViewState)
            }
        } else if let instructionTranslatedSlice = machoViewState.selectedMachoSlice as? InstructionSection {
            AsyncView(translatedSlice: instructionTranslatedSlice) { instructionBank in
                InstructionTranslationView(instructionBank: instructionBank, machoViewState: $machoViewState)
            }
        }
    }
    
}
