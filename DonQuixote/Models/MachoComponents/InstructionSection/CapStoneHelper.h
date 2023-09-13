//
//  CapstoneHelper.h
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CapStoneArchType) {
    CapStoneArchTypeI386,
    CapStoneArchTypeX8664,
    CapStoneArchTypeThumb,
    CapStoneArchTypeARM,
    CapStoneArchTypeARM64
};

@interface CapStoneInstruction : NSObject

@property (nonatomic, strong) NSString *mnemonic;
@property (nonatomic, strong) NSString *operand;
@property (nonatomic, assign) uint64_t startAddrVirtual;
@property (nonatomic, assign) uint64_t startAddrInMacho;
@property (nonatomic, assign) uint16_t size;

@end

@interface CapStoneInstructionBank : NSObject

@property (nonatomic, assign) uint64_t codeStartAddr;
@property (nonatomic, assign) uint64_t instructionSectionOffsetInMacho;
@property (nonatomic, strong) NSError * _Nullable error;

- (NSInteger)numberOfInstructions;
- (CapStoneInstruction * _Nullable)instructionAtIndex:(NSInteger)index;
- (NSInteger)searchIndexForInstructionWith:(uint64_t)targetDataIndex;

@end

@interface CapStoneHelper : NSObject

+ (CapStoneInstructionBank *)capStoneInstructionBankFrom:(NSData *)data arch:(CapStoneArchType)arch codeStartAddress:(uint64_t)codeStartAddress progressBlock:(void (^)(float))progressBlock;

@end

NS_ASSUME_NONNULL_END
