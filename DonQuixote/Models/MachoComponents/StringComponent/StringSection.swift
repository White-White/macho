//
//  StringSection.swift
//  DonQuixote
//
//  Created by white on 2023/6/11.
//

import Foundation

class StringSection: GroupTranslatedMachoSlice {
    
    let encoding: String.Encoding
    let stringContainer: StringContainer
    
    init(encoding: String.Encoding, data: Data, title: String, subTitle: String?) {
        self.encoding = encoding
        self.stringContainer = StringContainer(data: data, encoding: encoding, shouldDemangle: false) // TODO: should disable mangling?
        super.init(data, title: title, subTitle: subTitle)
    }
    
    override func translate(_ progressNotifier: @escaping (Float) -> Void) async -> [TranslationGroup] {
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        for rawString in await self.stringContainer.rawStrings {
            
            if rawString.offset == translationGroup.bytesCount {
                // the offset of next string should equal the translationGroup's current length
                // expected. do nothing
            } else {
                // otherwise, it indicates there is a hole before the string
                translationGroup.skip(size: rawString.offset - translationGroup.bytesCount)
            }
            
            let stringContent = await self.stringContainer.stringContent(for: rawString)
            translationGroup.addTranslation(definition: nil,
                                            humanReadable: stringContent.content ?? "Invalid \(self.encoding) string. Debug me",
                                            translationType: self.encoding == .utf8 ? .utf8String(stringContent.byteCount) : .utf16String(stringContent.byteCount),
                                            extraDefinition: stringContent.demangled != nil ? "Demangled" : nil,
                                            extraHumanReadable: stringContent.demangled)
        }
        return [translationGroup]
    }
    
    func findString(atDataOffset offset: Int) async -> String? {
        if let stringContent = await self.stringContainer.stringContent(withOffset: offset) {
            return stringContent.content ?? "Finded. But fail to decode. Debug me."
        }
        return nil
    }
    
}
