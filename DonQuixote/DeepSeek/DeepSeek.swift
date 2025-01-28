//
//  DeepSeek.swift
//  DonQuixote
//
//  Created by white on 2025/1/23.
//

import Foundation
import Combine

enum DeepSeekStatus {
    case pending
    case verifying(String)
    case ready(String)
}

struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

struct DeepSeekRequestBody: Encodable {
    
    let model: String = "deepseek-chat"
    let stream: Bool
    let messages: [DeepSeekMessage]
    
    init(question: String, stream: Bool) {
        self.stream = stream
        self.messages = [
            DeepSeekMessage(role: "system", content: "You are an expert in computer science."),
            DeepSeekMessage(role: "user", content: question)
        ]
    }
    
}

struct DeepSeekResponseBody: Decodable {
    
    struct Choice: Decodable {
        let index: Int
        let message: DeepSeekMessage
    }
    let choices: [Choice]
    
    func readable() -> String {
        return self.choices.reduce("") { partialResult, choice in
            return partialResult + "\n" + choice.message.content
        }
    }
    
}

struct DeepSeekStreamResponseBody: Decodable {
    
    struct Delta: Decodable {
        let content: String
    }
    
    struct StreamChoice: Decodable {
        let delta: Delta
    }
    
    let choices: [StreamChoice]
    
    func deltaContent() -> String {
        return self.choices.reduce("") { partialResult, choice in
            return partialResult + choice.delta.content
        }
    }
    
}

enum DeepSeekError: LocalizedError {
    
    case ApiKeyNotSet
    case MalFormat
    case FailAuth
    case InsuffcientBalance
    case WrongParam
    case HitLimit
    case ServerError
    case ServerBusy
    case Unknown(Int)
    
    init(code: Int) {
        switch code {
        case 400:
            self = .MalFormat
        case 401:
            self = .FailAuth
        case 402:
            self = .InsuffcientBalance
        case 422:
            self = .WrongParam
        case 429:
            self = .HitLimit
        case 500:
            self = .ServerError
        case 503:
            self = .ServerBusy
        default:
            self = .Unknown(code)
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .ApiKeyNotSet:
            return "Api key is not set"
        case .MalFormat:
            return "Request in wrong format"
        case .FailAuth:
            return "Failed to auth with DeepSeek"
        case .InsuffcientBalance:
            return "You dont have sufficient balance"
        case .WrongParam:
            return "Wrong parameters"
        case .HitLimit:
            return "You've hit the rate limit for DeepSeek request"
        case .ServerError:
            return "DeepSeek server error"
        case .ServerBusy:
            return "DeepSeek server busy"
        case .Unknown(let code):
            return "Unknown DeepSeep error. code: \(code)"
        }
    }
    
}



@MainActor
class DeepSeek: ObservableObject {
    static let shared = DeepSeek()
    
    @Published
    var status: DeepSeekStatus = .pending
    
    func reset() {
        self.status = .pending
    }
    
    func verify(apiKey: String) async -> Result<Void, Error> {
        self.status = .verifying(apiKey)
        let verifyResult = await self.deepSeek(question: "Hi")
        switch verifyResult {
        case .success(_):
            self.status = .ready(apiKey)
            return .success(Void())
        case .failure(let error):
            self.status = .pending
            return .failure(error)
        }
    }
    
    func deepSeek(question: String) async -> Result<DeepSeekResponseBody, Error> {
        switch self.status {
        case .pending:
            return .failure(DeepSeekError.ApiKeyNotSet)
        case .verifying(let apiKey):
            fallthrough
        case .ready(let apiKey):
            do {
                let dsResponse = try await self.deepSeek(question: question, apiKey: apiKey)
                return .success(dsResponse)
            } catch let e {
                return .failure(e)
            }
        }
    }
    
    private func deepSeek(question: String, apiKey: String) async throws -> DeepSeekResponseBody {
        var dsRequest = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
        dsRequest.httpMethod = "POST"
        dsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        dsRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        dsRequest.httpBody = try JSONEncoder().encode(DeepSeekRequestBody(question: question, stream: false))
        let (data, response) = try await URLSession.shared.data(for: dsRequest)
        let statusCode = (response as! HTTPURLResponse).statusCode
        if (statusCode != 200) {
            let deepSeekError = DeepSeekError(code: statusCode)
            throw deepSeekError
        }
        return try JSONDecoder().decode(DeepSeekResponseBody.self, from: data)
    }
    
    func streamDeepSeek(question: String, streamDataHandler: StreamDataHandler) {
        switch self.status {
        case .pending:
            fatalError()
        case .verifying:
            fatalError()
        case .ready(let apiKey):
            var dsRequest = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
            dsRequest.httpMethod = "POST"
            dsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            dsRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            dsRequest.httpBody = try! JSONEncoder().encode(DeepSeekRequestBody(question: self.buildTheQuestion(originalQuestion: question), stream: true))
            let dataTask = URLSession.shared.dataTask(with: dsRequest)
            dataTask.delegate = streamDataHandler
            dataTask.resume()
        }
    }
    
    func buildTheQuestion(originalQuestion: String) -> String {
        return String([originalQuestion].joined(separator: " "))
    }
    
}


class StreamDataHandler: NSObject, URLSessionDelegate, URLSessionDataDelegate, ObservableObject, @unchecked Sendable {
    
    @Published
    var deekSeekAnswerLines: [String] = []
    
    @Published
    var deekSeekAnswerCache: String = ""
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        do {
            let lines = data.utf8String?.components(separatedBy: "\n")
            let dataLines = lines?.filter { $0.starts(with: "data: ") }
            
            guard let dataLines else {
                // handle error
                fatalError()
            }
            
            for dataLine in dataLines {
                let jsonDataLine = dataLine[String.Index.init(utf16Offset: 6, in: dataLine)...]
                
                if jsonDataLine == "[DONE]" {
                    return
                }
                
                guard let deltaData = jsonDataLine.data(using: .utf8) else {
                    // handle error
                    fatalError()
                }
                
                let newContent = (try JSONDecoder().decode(DeepSeekStreamResponseBody.self, from: deltaData)).deltaContent()
                self.handle(newContent: newContent)
            }
            
        } catch let e {
            print(e)
        }
    }
    
    func handle(newContent: String) {
        
        if !newContent.contains("\n") {
            DispatchQueue.main.async {
                self.deekSeekAnswerCache += newContent
            }
            return
        }
        
        var cache: String = ""
        for char in newContent {
            if char == "\n" {
                let currentCache = cache
                cache = ""
                DispatchQueue.main.async {
                    let newLine = self.deekSeekAnswerCache + currentCache
                    self.deekSeekAnswerCache = ""
                    self.deekSeekAnswerLines.append(newLine)
                }
            } else {
                cache.append(char)
            }
        }
        
        if !cache.isEmpty {
            DispatchQueue.main.async {
                self.deekSeekAnswerCache += cache
            }
        }
        
    }
    
}
