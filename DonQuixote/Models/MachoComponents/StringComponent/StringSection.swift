//
//  StringSection.swift
//  DonQuixote
//
//  Created by white on 2023/6/11.
//

import Foundation

class StringSection: MachoPortion, @unchecked Sendable {
    
    let encoding: String.Encoding
    
    init(encoding: String.Encoding, data: Data, title: String, subTitle: String?) {
        self.encoding = encoding
        super.init(data, title: title, subTitle: subTitle)
    }
    
    override func initialize() async -> AsyncInitializeResult {
        return StringContainer(data: data, encoding: encoding, shouldDemangle: false) // TODO: should disable mangling?
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let initializeResult = initializeResult as! StringContainer
        
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        for rawString in initializeResult.rawStrings {
            
            if rawString.offset == translationGroup.bytesCount {
                // the offset of next string should equal the translationGroup's current length
                // expected. do nothing
            } else {
                // otherwise, it indicates there is a hole before the string
                translationGroup.skip(size: rawString.offset - translationGroup.bytesCount)
            }
            
            let stringContent = initializeResult.stringContent(for: rawString)
            translationGroup.addTranslation(definition: nil,
                                            humanReadable: stringContent.content ?? "Invalid \(self.encoding) string. Debug me",
                                            translationType: self.encoding == .utf8 ? .utf8String(stringContent.byteCount) : .utf16String(stringContent.byteCount),
                                            extraDefinition: stringContent.demangled != nil ? "Demangled" : nil,
                                            extraHumanReadable: stringContent.demangled)
        }
        return TranslationGroups([translationGroup])
    }
    
    func findString(atDataOffset offset: Int) async throws -> String? {
        let stringContainer = (try await self.storage.initializeResult(calleeTag: "Finding string - ")) as! StringContainer
        if let stringContent = stringContainer.stringContent(withOffset: offset) {
            return stringContent.content ?? "Finded. But fail to decode. Debug me."
        }
        return nil
    }
    
}
