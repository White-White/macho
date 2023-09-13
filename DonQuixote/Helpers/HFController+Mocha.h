//
//  HFController+Mocha.h
//  mocha (macOS)
//
//  Created by white on 2022/9/21.
//

#import <HexFiend/HexFiend.h>

@class HexFiendViewController;

NS_ASSUME_NONNULL_BEGIN

@interface HFController (Mocha)

- (void)scrollHexViewToIndex:(NSUInteger)dataIndex bytesPerLine:(NSUInteger)bytesPerLine;

- (HexFiendViewController * _Nullable)viewController;

- (void)setController:(HexFiendViewController * _Nonnull)viewController;

@end

NS_ASSUME_NONNULL_END
