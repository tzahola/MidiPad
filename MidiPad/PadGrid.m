//
//  PadGrid.m
//  MidiPad
//
//  Created by Tamás Zahola on 15/03/16.
//  Copyright © 2016 Zahola. All rights reserved.
//

#import "PadGrid.h"

@interface Pad : UIView

@property (nonatomic, assign) NSUInteger row;
@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, assign) NSUInteger currentTouchCount;
@property (nonatomic, strong) UILabel* label;

@end

@implementation Pad

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.multipleTouchEnabled = YES;
    self.label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.numberOfLines = 0;
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor whiteColor];
    self.label.font = [UIFont systemFontOfSize:9];
    [self addSubview:self.label];
    [self refresh];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = self.bounds;
}

- (void)refresh {
    if (self.currentTouchCount == 0) {
        self.backgroundColor = [UIColor darkGrayColor];
    } else {
        self.backgroundColor = [UIColor lightGrayColor];
    }
}

@end

@interface PadGrid ()

@property (nonatomic, strong) NSMutableArray<Pad*>* pads;

@end

@implementation PadGrid {
    PadGridSize _size;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.pads = [NSMutableArray new];
    [self reload];
}

- (void)reload {
    _size = [self.delegate sizeOfPadGrid:self];
    [self.pads makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.pads removeAllObjects];
    
    for (int row = 0; row < _size.rows; row++) {
        for (int column = 0; column < _size.columns; column++) {
            Pad* pad = [[Pad alloc] initWithFrame:CGRectZero];
            pad.row = row;
            pad.column = column;
            pad.label.text = [self.delegate padGrid:self labelForRow:row column:column];
            [self addSubview:pad];
            [self.pads addObject:pad];
        }
    }
}

- (Pad*)padAtRow:(NSUInteger)row column:(NSUInteger)column {
    return self.pads[row * _size.columns + column];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat spacing = 1.0 / [UIScreen mainScreen].nativeScale;
    CGSize padSize = {
        (self.bounds.size.width - (_size.columns - 1) * spacing) / _size.columns,
        (self.bounds.size.height - (_size.rows - 1) * spacing) / _size.rows
    };
    for (int row = 0; row < _size.rows; row++) {
        for (int column = 0; column < _size.columns; column++) {
            Pad* pad = [self padAtRow:row column:column];
            pad.frame = CGRectMake(self.bounds.origin.x + column * (spacing + padSize.width),
                                   self.bounds.origin.y + row * (spacing + padSize.height),
                                   padSize.width,
                                   padSize.height);
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self refreshTouchesWithEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self refreshTouchesWithEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self refreshTouchesWithEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self refreshTouchesWithEvent:event];
}

- (void)refreshTouchesWithEvent:(UIEvent*)event {
    NSUInteger* touchesForPads = alloca(sizeof(NSInteger) * self.pads.count);
    for (int i = 0; i < self.pads.count; i++) {
        touchesForPads[i] = 0;
    }
    
    for (UITouch* touch in event.allTouches) {
        CGPoint location = [touch locationInView:self];
        if (CGRectContainsPoint(self.bounds, location) && (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary)) {
            NSUInteger column = floor((location.x - self.bounds.origin.x) / self.bounds.size.width * _size.columns);
            NSUInteger row = floor((location.y - self.bounds.origin.y) / self.bounds.size.height * _size.rows);
            touchesForPads[row * _size.columns + column]++;
        }
    }
    
    for (int i = 0; i < self.pads.count; i++) {
        Pad* pad = self.pads[i];
        
        NSUInteger newTouches = touchesForPads[i];
        NSUInteger currentTouches = pad.currentTouchCount;
        
        if (currentTouches != newTouches) {
            pad.currentTouchCount = newTouches;
            [pad refresh];
            if (currentTouches == 0) {
                [self.delegate padGrid:self didTouchAtRow:pad.row column:pad.column];
            } else if (newTouches == 0) {
                [self.delegate padGrid:self didEndTouchAtRow:pad.row column:pad.column];
            } else if (newTouches > currentTouches) {
                [self.delegate padGrid:self didRetouchAtRow:pad.row column:pad.column];
            }
        }
    }
}

@end
