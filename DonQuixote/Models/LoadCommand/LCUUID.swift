//
//  LCUUID.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCUUID: LoadCommand, @unchecked Sendable {
    
    let uuid: UUID
    
    init(with type: LoadCommandType, data: Data) {
        self.uuid = LCUUID.uuid(from: [UInt8](data.subSequence(from: 8, count: 16)))
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "UUID", humanReadable: self.uuid.uuidString, translationType: .rawData(16))
    }
    
    static func uuid(from uuidData: [UInt8]) -> UUID {
        return UUID(uuid: (uuidData[0], uuidData[1], uuidData[2], uuidData[3], uuidData[4], uuidData[5], uuidData[6], uuidData[7],
                           uuidData[8], uuidData[9], uuidData[10], uuidData[11], uuidData[12], uuidData[13], uuidData[14], uuidData[15]))
    }
    
}
