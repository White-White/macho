//
//  DeepSeekView.swift
//  DonQuixote
//
//  Created by white on 2025/1/23.
//

import SwiftUI
import Combine

struct DeepSeekView: View {
    
    @EnvironmentObject var machoViewState: MachoViewState
    
    @ObservedObject var deepSeek = DeepSeek.shared
    @ObservedObject var streamDataHandler: StreamDataHandler = StreamDataHandler()
    
    @State var inputAPIKey: String = ""
    @State var errorAlertShowing: Bool = false
    @State var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            self.renderAPIKeyView()
            self.renderAskingView()
        }
        .frame(maxHeight: 300)
        .padding([.bottom, .trailing], 4)
    }
    
    func renderAPIKeyView() -> some View {
        
        let confirmButtonTitle: String
        let confirmButtonDisabled: Bool
        let textFieldDisabled: Bool
        
        switch deepSeek.status {
        case .pending:
            confirmButtonTitle = "Confirm"
            confirmButtonDisabled = false
            textFieldDisabled = false
        case .verifying:
            confirmButtonTitle = "Confirm"
            confirmButtonDisabled = true
            textFieldDisabled = true
        case .ready:
            confirmButtonTitle = "Reset"
            confirmButtonDisabled = false
            textFieldDisabled = true
        }
        
        return HStack(spacing: 4) {
            
            Image("deepseek")
                .resizable()
                .frame(width: 44, height: 44)
                .padding(12)
            
            VStack(alignment: .leading, spacing: 4) {
                
                TextField("Please input your API key for DeepSeek", text: $inputAPIKey)
                    .disabled(textFieldDisabled)
                    .frame(maxWidth: 400)
                
                HStack {
                    Button(confirmButtonTitle) {
                        switch deepSeek.status {
                        case .pending:
                            Task {
                                let verifyResult = await deepSeek.verify(apiKey: inputAPIKey)
                                switch verifyResult {
                                case .success:
                                    return
                                case .failure(let failure):
                                    self.errorMessage = failure.localizedDescription
                                    self.errorAlertShowing = true
                                }
                            }
                        case .verifying:
                            return
                        case .ready:
                            deepSeek.reset()
                        }
                    }
                    .disabled(confirmButtonDisabled)
                    .alert(errorMessage, isPresented: $errorAlertShowing) {
                        Button("OK", role: .cancel) { }
                    }
                }
            }
            
            Spacer()
        }
    }
    
    func renderAskingView() -> some View {
        
        let askButtonDisable: Bool
        switch deepSeek.status {
        case .pending:
            askButtonDisable = true
        case .verifying:
            askButtonDisable = true
        case .ready:
            askButtonDisable = false
        }

        return VStack(spacing: 4) {
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(self.streamDataHandler.deekSeekAnswerLines.indices, id: \.self) { lineIndex in
                        let lineContent = self.streamDataHandler.deekSeekAnswerLines[lineIndex]
                        HStack(spacing: 0) {
                            MarkDownText(lineContent)
                            Spacer()
                        }
                    }
                    HStack(spacing: 0) {
                        MarkDownText(self.streamDataHandler.deekSeekAnswerCache)
                        Spacer()
                    }
                }
                .padding([.leading, .trailing], 12)
            }
            
            HStack(spacing: 4) {
                TextField("Input your question to DeepSeek", text: $machoViewState.questionToDeepSeek)
                Button("Ask") {
                    Task {
                        self.deepSeek.streamDeepSeek(question: machoViewState.questionToDeepSeek, streamDataHandler: self.streamDataHandler)
                    }
                }
                .disabled(askButtonDisable)
            }
            
        }
    }
    
}

struct MarkDownText: View {
    
    let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        if let markdown = try? AttributedString(markdown: content) {
            Text(markdown)
        } else {
            Text(content)
        }
    }
    
}
