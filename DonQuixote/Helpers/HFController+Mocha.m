//
//  HFController+Mocha.m
//  mocha (macOS)
//
//  Created by white on 2022/9/21.
//

#import "HFController+Mocha.h"
#import <objc/runtime.h>
#import <HexFiend/HexFiend.h>

@implementation HFController (Mocha)

- (void)scrollHexViewToIndex:(NSUInteger)dataIndex bytesPerLine:(NSUInteger)bytesPerLine {
    long double targetLineIndex = dataIndex / bytesPerLine;
    HFFPRange visableLineRange = [self displayedLineRange];
    if (visableLineRange.location <= targetLineIndex && targetLineIndex <= (visableLineRange.location + visableLineRange.length)) {
        return;
    }
    long double delta = targetLineIndex - (visableLineRange.location + visableLineRange.length / 2);
    [self scrollByLines: delta];
}

- (HexFiendViewController *)viewController {
    return objc_getAssociatedObject(self, @selector(viewController));
}

- (void)setController:(HexFiendViewController *)viewController {
    objc_setAssociatedObject(self, @selector(viewController), viewController, OBJC_ASSOCIATION_ASSIGN);
}

@end
