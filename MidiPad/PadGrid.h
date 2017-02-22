//
//  PadGrid.h
//  MidiPad
//
//  Created by Tamás Zahola on 15/03/16.
//  Copyright © 2016 Zahola. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PadGrid;

typedef struct {
    NSUInteger rows;
    NSUInteger columns;
} PadGridSize;

@protocol PadGridDelegate <NSObject>

- (NSString*)padGrid:(PadGrid*)padGrid labelForRow:(NSUInteger)row column:(NSUInteger)column;
- (void)padGrid:(PadGrid*)padGrid didTouchAtRow:(NSUInteger)row column:(NSUInteger)column;
- (void)padGrid:(PadGrid*)padGrid didRetouchAtRow:(NSUInteger)row column:(NSUInteger)column;
- (void)padGrid:(PadGrid*)padGrid didEndTouchAtRow:(NSUInteger)row column:(NSUInteger)column;
- (PadGridSize)sizeOfPadGrid:(PadGrid*)padGrid;

@end

static inline PadGridSize PadGridSizeMake(NSUInteger rows, NSUInteger columns) {
    PadGridSize result = { .rows = rows, .columns = columns };
    return result;
}

@interface PadGrid : UIView

@property (nonatomic, weak) id<PadGridDelegate> delegate;

- (void)reload;

@end
