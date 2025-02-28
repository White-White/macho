//
//  InstructionTranslationView.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation
import SwiftUI

struct InstructionTranslationView: View {
    
    let instructionBank: InstructionBank
    
    @EnvironmentObject var machoViewState: MachoViewState
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<instructionBank.numberOfInstructions, id: \.self) { index in
                        self.singleInstructionTranslationView(for: index, inBank: instructionBank)
                    }
                }
            }
            .onChange(of: machoViewState.selectedTranslationMetaInfo) { newValue in
                // TODO: performance issue when there are too many instructions
                if instructionBank.numberOfInstructions < 1024 * 1024 {
                    scrollViewProxy.scrollTo(newValue.id)
                }
            }
        }
    }
    
    func singleInstructionTranslationView(for index: Int, inBank bank: InstructionBank) -> some View {
        let instructionTranslation = bank.instructionTranslation(at: index)!
        return self.singleInstructionTranslationView(for: instructionTranslation).onTapGesture {
//            self.machoViewState.update(selectedDataRange: instructionTranslation.metaInfo.dataRangeInMacho)
            machoViewState.selectedTranslationMetaInfo = instructionTranslation.metaInfo
        }
    }
    
    private func singleInstructionTranslationView(for instructionTranslation: InstructionTranslation) -> some View {
        let isSelected = machoViewState.selectedTranslationMetaInfo == instructionTranslation.metaInfo
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(instructionTranslation.instruction)
                    .font(.system(size: 14))
                    .foregroundColor(Color(nsColor: .textColor))
                HStack {
                    Text("\(instructionTranslation.metaInfo.type.description) (\(instructionTranslation.metaInfo.bytesCount) bytes)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            Divider()
        }
        .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
        .id(instructionTranslation.id)
    }
    
}
