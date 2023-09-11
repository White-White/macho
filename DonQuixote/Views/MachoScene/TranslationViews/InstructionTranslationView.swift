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
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<instructionBank.numberOfInstructions, id: \.self) { index in
                        self.singleInstructionTranslationView(for: index, inBank: instructionBank)
                    }
                }
            }
        }
    }
    
    func singleInstructionTranslationView(for index: Int, inBank bank: InstructionBank) -> some View {
        let translation = bank.translation(at: index)
        return self.singleTranslationView(for: translation).onTapGesture {

        }.id(translation.id)
    }
    
    private func singleTranslationView(for translation: Translation) -> some View {
        let isSelected = false
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(translation.humanReadable)
                    .font(.system(size: 14))
                    .foregroundColor(Color(nsColor: .textColor))
                if let definition = translation.definition {
                    Text(definition)
                        .font(.system(size: 12))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                if let extraExplanation = translation.extraHumanReadable {
                    Text(extraExplanation)
                        .foregroundColor(Color(nsColor: .textColor))
                        .font(.system(size: 13))
                }
                if let extraDescription = translation.extraDefinition {
                    Text(extraDescription)
                        .font(.system(size: 12))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                HStack {
                    Text("\(translation.translationType.description) (\(translation.translationType.bytesCount) bytes)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    if let error = translation.error {
                        Text(error)
                            .font(.system(size: 10))
                            .foregroundColor(Color(nsColor: .white))
                            .background(Color(nsColor: .orange))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            Divider()
        }
        .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
}
