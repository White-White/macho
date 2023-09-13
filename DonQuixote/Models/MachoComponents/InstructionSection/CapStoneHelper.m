//
//  CapstoneHelper.m
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

#import "CapStoneHelper.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // ignoring all warnings from capstore
#import "capstone/capstone.h"
#pragma clang diagnostic pop

@implementation CapStoneInstruction
    
@end

@interface CapStoneInstructionBank ()

@property (nonatomic, strong) NSMutableData *instructionStringBank;
@property (nonatomic, strong) NSMutableData *instructionOffsetInStringBank;
@property (nonatomic, strong) NSMutableData *instructionOpStrSizes;
@property (nonatomic, strong) NSMutableData *instructionMnemonicSizes;
@property (nonatomic, strong) NSMutableData *instructionStartAddresses;
@property (nonatomic, strong) NSMutableData *instructionSizes;
@property (nonatomic, assign) NSInteger numberOfInstructions;

@end

@implementation CapStoneInstructionBank

- (instancetype)init {
    self = [super init];
    _instructionStringBank = [NSMutableData data];
    _instructionOffsetInStringBank = [NSMutableData data];
    _instructionOpStrSizes = [NSMutableData data];
    _instructionMnemonicSizes = [NSMutableData data];
    _instructionStartAddresses = [NSMutableData data];
    _instructionSizes = [NSMutableData data];
    _numberOfInstructions = 0;
    return self;
}

- (void)appendInstruction:(const cs_insn *)insn codeStartAddr:(uint64_t)codeStartAddr {
    
    NSUInteger offsetInStringBank = _instructionStringBank.length;
    [_instructionOffsetInStringBank appendBytes:&offsetInStringBank length:sizeof(NSUInteger)];
    
    NSUInteger mnemonicSize = strlen(insn->mnemonic);
    [_instructionMnemonicSizes appendBytes:&mnemonicSize length:sizeof(NSUInteger)];
    [_instructionStringBank appendBytes:insn->mnemonic length:mnemonicSize];
    
    NSUInteger opStrSize = strlen(insn->op_str);
    [_instructionOpStrSizes appendBytes:&opStrSize length:sizeof(NSUInteger)];
    [_instructionStringBank appendBytes:insn->op_str length:opStrSize];
    
    [_instructionStartAddresses appendBytes:&codeStartAddr length:sizeof(uint64_t)];
    
    [_instructionSizes appendBytes:&insn->size length:sizeof(uint16_t)];
    
    _numberOfInstructions ++;
}

- (NSInteger)numberOfInstructions {
    return _numberOfInstructions;
}

- (CapStoneInstruction *)instructionAtIndex:(NSInteger)index {
    
    if (_numberOfInstructions <= index) {
        return nil;
    }
    
    CapStoneInstruction *instruction = [[CapStoneInstruction alloc] init];
    
    NSUInteger offsetInStringBank = [self getOffsetInStringBankForInstructionIndex:index];
    NSUInteger mnemonicSize = [self getMnemonicSizeForInstructionIndex:index];
    NSUInteger operandSize = [self getOperandSizeForInstructionIndex:index];
    
    instruction.mnemonic = [[NSString alloc] initWithBytes:_instructionStringBank.bytes + offsetInStringBank
                                                    length:mnemonicSize
                                                  encoding:NSUTF8StringEncoding];
    
    instruction.operand = [[NSString alloc] initWithBytes:_instructionStringBank.bytes + offsetInStringBank + mnemonicSize
                                                    length:operandSize
                                                  encoding:NSUTF8StringEncoding];
    
    instruction.size = [self getInstructionSizeForInstructionIndex:index];
    
    instruction.startAddrVirtual = [self getInstructionStartAddressForInstructionIndex:index];
    
    instruction.startAddrInMacho = instruction.startAddrVirtual - self.codeStartAddr + self.instructionSectionOffsetInMacho;
    
    return instruction;
}

- (NSUInteger)getOffsetInStringBankForInstructionIndex:(NSInteger)instructionIndex {
    return [self getNSUIntegerValueFromData:_instructionOffsetInStringBank forIndex:instructionIndex];
}

- (NSUInteger)getMnemonicSizeForInstructionIndex:(NSInteger)instructionIndex {
    return [self getNSUIntegerValueFromData:_instructionMnemonicSizes forIndex:instructionIndex];
}

- (NSUInteger)getOperandSizeForInstructionIndex:(NSInteger)instructionIndex {
    return [self getNSUIntegerValueFromData:_instructionOpStrSizes forIndex:instructionIndex];
}

- (uint16_t)getInstructionSizeForInstructionIndex:(NSInteger)instructionIndex {
    const void *bytes = _instructionSizes.bytes;
    const void *startPointer = bytes + sizeof(uint16_t) * instructionIndex;
    uint16_t value = *((uint16_t *)startPointer);
    return value;
}

- (uint64_t)getInstructionStartAddressForInstructionIndex:(NSInteger)instructionIndex {
    const void *bytes = _instructionStartAddresses.bytes;
    const void *startPointer = bytes + sizeof(uint64_t) * instructionIndex;
    uint64_t value = *((uint64_t *)startPointer);
    return value;
}

- (NSUInteger)getNSUIntegerValueFromData:(NSData *)data forIndex:(NSInteger)index {
    const void *bytes = data.bytes;
    const void *startPointer = bytes + sizeof(NSUInteger) * index;
    NSUInteger value = *((NSUInteger *)startPointer);
    return value;
}

- (NSInteger)searchIndexForInstructionWith:(uint64_t)targetDataIndex {
    NSInteger low = 0;
    NSInteger mid;
    NSInteger high = self.numberOfInstructions - 1;
    while (low <= high) {
        mid = (low + high) / 2;
        uint64_t startAddrVirtual = [self getInstructionStartAddressForInstructionIndex:mid];
        uint64_t startAddrInMacho = startAddrVirtual - self.codeStartAddr + self.instructionSectionOffsetInMacho;
        if (targetDataIndex < startAddrInMacho) {
            high = mid - 1;
        } else if (targetDataIndex >= (startAddrInMacho + (uint64_t)[self getInstructionSizeForInstructionIndex: mid])) {
            low = mid + 1;
        } else {
            return mid;
        }
    }
    return -1;
}

@end

@implementation CapStoneHelper

+ (CapStoneInstructionBank *)capStoneInstructionBankFrom:(NSData *)data arch:(CapStoneArchType)arch codeStartAddress:(uint64_t)codeStartAddress progressBlock:(void (^)(float))progressBlock {
    
    CapStoneInstructionBank *instructionBank = [[CapStoneInstructionBank alloc] init];
    
    csh cs_handle;
    cs_err cserr;
    /* open capstone */
    cs_arch target_arch;
    cs_mode target_mode;
    
    switch (arch) {
        case CapStoneArchTypeI386:
            target_arch = CS_ARCH_X86;
            target_mode = CS_MODE_32;
            break;
        case CapStoneArchTypeX8664:
            target_arch = CS_ARCH_X86;
            target_mode = CS_MODE_64;
            break;
        case CapStoneArchTypeThumb:
            target_arch = CS_ARCH_ARM;
            target_mode = CS_MODE_ARM;
            break;
        case CapStoneArchTypeARM:
            target_arch = CS_ARCH_ARM;
            target_mode = CS_MODE_ARM;
            break;
        case CapStoneArchTypeARM64:
            target_arch = CS_ARCH_ARM64;
            target_mode = CS_MODE_ARM;
            break;
    }
    
    if ( (cserr = cs_open(target_arch, target_mode, &cs_handle)) != CS_ERR_OK ) {
        instructionBank.error = [NSError errorWithDomain:@"Capstore" code:cserr userInfo:nil];
        return instructionBank;
    }
    
    switch (arch) {
        case CapStoneArchTypeThumb:
            cs_option(cs_handle, CS_OPT_MODE, CS_MODE_THUMB);
            break;
        case CapStoneArchTypeARM:
            // fallthrough
        case CapStoneArchTypeARM64:
            cs_option(cs_handle, CS_OPT_MODE, CS_MODE_ARM);
            break;
        default:
            break;
    }
    
    /* enable detail - we need fields available in detail field */
    cs_option(cs_handle, CS_OPT_DETAIL, CS_OPT_ON);
    cs_option(cs_handle, CS_OPT_SKIPDATA, CS_OPT_ON);
    
    
    struct cs_insn *insn = cs_malloc(cs_handle);
    
    uint64_t startOffset = 0;
    size_t initial_code_size = (size_t)[data length];
    float progress = 0;
    
    uint64_t codeAddress = codeStartAddress; // value will be updated in iteration
    uint8_t *code = (uint8_t *)[data bytes]; // value will be updated in iteration
    size_t code_size = (size_t)[data length]; // value will be updated in iteration
    
    while(cs_disasm_iter(cs_handle, (const uint8_t **)&code, &code_size, &codeAddress, insn)) {
        [instructionBank appendInstruction:insn codeStartAddr:codeAddress - insn->size];
        startOffset += insn->size;
        float newProgress = (float)startOffset / (float)initial_code_size;
        if (newProgress - progress > 0.01) {
            progressBlock(newProgress);
            progress = newProgress;
        }
    }
    cs_free(insn, 1);
    
    cs_err err_handle = cs_errno(cs_handle);
    if (err_handle != CS_ERR_OK) {
        instructionBank.error = [NSError errorWithDomain:@"Capstone" code:cserr userInfo:nil];
    }
    cs_close(&cs_handle);
    
    return instructionBank;
    
}

@end
