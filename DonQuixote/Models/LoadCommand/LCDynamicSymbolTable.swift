//
//  LCDynamicSymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/11.
//

import Foundation

class LCDynamicSymbolTable: LoadCommand {
    let ilocalsym: UInt32       /* index to local symbols */
    let nlocalsym: UInt32       /* number of local symbols */
    
    let iextdefsym: UInt32      /* index to externally defined symbols */
    let nextdefsym: UInt32      /* number of externally defined symbols */
    
    let iundefsym: UInt32       /* index to undefined symbols */
    let nundefsym: UInt32       /* number of undefined symbols */
    
    let tocoff: UInt32          /* file offset to table of contents */
    let ntoc: UInt32            /* number of entries in table of contents */
    
    let modtaboff: UInt32       /* file offset to module table */
    let nmodtab: UInt32         /* number of module table entries */
    
    let extrefsymoff: UInt32    /* offset to referenced symbol table */
    let nextrefsyms: UInt32     /* number of referenced symbol table entries */
    
    let indirectsymoff: UInt32  /* file offset to the indirect symbol table */
    let nindirectsyms: UInt32   /* number of indirect symbol table entries */
    
    let extreloff: UInt32       /* offset to external relocation entries */
    let nextrel: UInt32         /* number of external relocation entries */
    
    let locreloff: UInt32       /* offset to local relocation entries */
    let nlocrel: UInt32         /* number of local relocation entries */
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.ilocalsym = dataShifter.shiftUInt32()
        self.nlocalsym = dataShifter.shiftUInt32()
        self.iextdefsym = dataShifter.shiftUInt32()
        self.nextdefsym = dataShifter.shiftUInt32()
        self.iundefsym = dataShifter.shiftUInt32()
        self.nundefsym = dataShifter.shiftUInt32()
        self.tocoff = dataShifter.shiftUInt32()
        self.ntoc = dataShifter.shiftUInt32()
        self.modtaboff = dataShifter.shiftUInt32()
        self.nmodtab = dataShifter.shiftUInt32()
        self.extrefsymoff = dataShifter.shiftUInt32()
        self.nextrefsyms = dataShifter.shiftUInt32()
        self.indirectsymoff = dataShifter.shiftUInt32()
        self.nindirectsyms = dataShifter.shiftUInt32()
        self.extreloff = dataShifter.shiftUInt32()
        self.nextrel = dataShifter.shiftUInt32()
        self.locreloff = dataShifter.shiftUInt32()
        self.nlocrel = dataShifter.shiftUInt32()
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Start Index of Local Symbols ", humanReadable: "\(self.ilocalsym)", translationType: .uint32)
        translationGroup.addTranslation(definition: "Number of Local Symbols ", humanReadable: "\(self.nlocalsym)", translationType: .uint32)
        translationGroup.addTranslation(definition: "Start Index of External Defined Symbols ", humanReadable: "\(self.iextdefsym)", translationType: .uint32)
        translationGroup.addTranslation(definition: "Number of External Defined Symbols ", humanReadable: "\(self.nextdefsym )", translationType: .uint32)
        translationGroup.addTranslation(definition: "Start Index of Undefined Symbols ", humanReadable: "\(self.iundefsym)", translationType: .uint32)
        translationGroup.addTranslation(definition: "Number of Undefined Symbols ", humanReadable: "\(self.nundefsym)", translationType: .uint32)
        translationGroup.addTranslation(definition: "file offset to table of contents ", humanReadable: "\(self.tocoff.hex)", translationType: .uint32)
        translationGroup.addTranslation(definition: "number of entries in table of contents ", humanReadable: "\(self.ntoc)", translationType: .uint32)
        translationGroup.addTranslation(definition: "file offset to module table ", humanReadable: "\(self.modtaboff.hex)", translationType: .uint32)
        translationGroup.addTranslation(definition: "number of module table entries ", humanReadable: "\(self.nmodtab)", translationType: .uint32)
        translationGroup.addTranslation(definition: "offset to referenced symbol table ", humanReadable: "\(self.extrefsymoff.hex)", translationType: .uint32)
        translationGroup.addTranslation(definition: "number of referenced symbol table entries ", humanReadable: "\(self.nextrefsyms)", translationType: .uint32)
        translationGroup.addTranslation(definition: "file offset to the indirect symbol table ", humanReadable: "\(self.indirectsymoff.hex)", translationType: .uint32)
        translationGroup.addTranslation(definition: "number of indirect symbol table entries ", humanReadable: "\(self.nindirectsyms)", translationType: .uint32)
        translationGroup.addTranslation(definition: "offset to external relocation entries ", humanReadable: "\(self.extreloff.hex)", translationType: .uint32)
        translationGroup.addTranslation(definition: "number of external relocation entries ", humanReadable: "\(self.nextrel)", translationType: .uint32)
        translationGroup.addTranslation(definition: "offset to local relocation entries ", humanReadable: "\(self.locreloff.hex)", translationType: .uint32)
        translationGroup.addTranslation(definition: "number of local relocation entries ", humanReadable: "\(self.nlocrel)", translationType: .uint32)
    }
    
    func indirectSymbolTable(machoData: Data, machoHeader: MachoHeader, symbolTable: SymbolTable?) -> IndirectSymbolTable? {
        let indirectSymbolTableStartOffset = Int(self.indirectsymoff)
        let indirectSymbolTableSize = Int(self.nindirectsyms * 4)
        if indirectSymbolTableSize == .zero { return nil }
        let indirectSymbolTableData = machoData.subSequence(from: indirectSymbolTableStartOffset, count: indirectSymbolTableSize)
        return IndirectSymbolTable(indirectSymbolTableData, title: "Indirect Symbol Table", is64Bit: machoHeader.is64Bit, symbolTable: symbolTable)
    }
    
}
