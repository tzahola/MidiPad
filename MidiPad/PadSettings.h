//
//  PadSettings.h
//  MidiPad
//
//  Created by Tamás Zahola on 15/03/16.
//  Copyright © 2016 Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PadType) {
    PadTypeMPC,
    PadTypeChords
};

@interface PadSettings : NSObject

@property (nonatomic, assign) PadType padType;
@property (nonatomic, assign) Byte startNote;

+ (instancetype)sharedSettings;

@end
