//
//  GroupTranslationView.swift
//  DonQuixote
//
//  Created by white on 2023/6/13.
//

import Foundation
import SwiftUI

struct GroupTranslationView: View {
    
    let translationGroups: [TranslationGroup]
    @Binding var machoViewState: MachoViewState
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(translationGroups) { translationGroup in
                        ForEach(translationGroup.translations) { translation in
                            self.singleTranslationView(for: translation)
                                .onTapGesture {
                                    machoViewState.update(coloredDataRange: translationGroup.dataRangeInMacho)
                                    machoViewState.update(selectedDataRange: translation.metaInfo.dataRangeInMacho)
                                    machoViewState.selectedTranslationMetaInfo = translation.metaInfo
                                }
                        }
                    }
                }
            }
            .onChange(of: machoViewState.selectedTranslationMetaInfo) { newValue in
                scrollViewProxy.scrollTo(newValue.id)
            }
        }
    }
    
    private func singleTranslationView(for translation: Translation) -> some View {
        let isSelected = machoViewState.selectedTranslationMetaInfo == translation.metaInfo
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
                    Text("\(translation.metaInfo.type.description) (\(translation.metaInfo.bytesCount) bytes)")
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
