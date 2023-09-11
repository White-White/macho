//
//  EncryptionInfo.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

//struct encryption_info_command_64 {
//   uint32_t    cmd;        /* LC_ENCRYPTION_INFO_64 */
//   uint32_t    cmdsize;    /* sizeof(struct encryption_info_command_64) */
//   uint32_t    cryptoff;    /* file offset of encrypted range */
//   uint32_t    cryptsize;    /* file size of encrypted range */
//   uint32_t    cryptid;    /* which enryption system,
//                   0 means not-encrypted yet */
//   uint32_t    pad;        /* padding to make this struct's size a multiple
//                   of 8 bytes */
//};

class LCEncryptionInfo: LoadCommand {
    
    let cryptoOffset: UInt32
    let cryptoSize: UInt32
    let cryptoID: UInt32
    let pad: UInt32?
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.cryptoOffset = dataShifter.shiftUInt32()
        self.cryptoSize = dataShifter.shiftUInt32()
        self.cryptoID = dataShifter.shiftUInt32()
        self.pad = (type == .encryptionInfo64 ? dataShifter.shiftUInt32() : nil)
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Crypto File Offset", humanReadable: self.cryptoOffset.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Crypto File Size", humanReadable: self.cryptoSize.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Crypto ID", humanReadable: "\(self.cryptoID)", translationType: .uint32)
        if let pad = self.pad { translationGroup.addTranslation(definition: "Crypto Pad", humanReadable: "\(pad)", translationType: .uint32) }
    }
    
}
