//
//  TranslationView.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation
import SwiftUI

struct TranslationView: View {
    
    @EnvironmentObject var machoViewState: MachoViewState
    
    @ObservedObject var machoPortionStorage: MachoPortionStorage
    
    var body: some View {
        VStack {
            switch machoViewState.selectedMachoPortion.storage.loadingStatus {
            case .created:
                Text("\(machoViewState.selectedMachoPortion.title) is loading...")
            case .initializing:
                //TODO:
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        ProgressView()
                        Text(String(format: "Initializing... (%.2f %%)", 0.5 * 100))
                    }
                }
            case .translating:
                //TODO:
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        ProgressView()
                        Text(String(format: "Initializing... (%.2f %%)", 0.5 * 100))
                    }
                }
            case .translated(_, let t):
                if let t = t as? TranslationGroups {
                    GroupTranslationView(translationGroups: t)
                } else if let t = t as? InstructionBank {
                    InstructionTranslationView(instructionBank: t)
                }
            }
        }
        .background(.white)
    }
    
}
