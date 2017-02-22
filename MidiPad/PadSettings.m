//
//  PadSettings.m
//  MidiPad
//
//  Created by Tamás Zahola on 15/03/16.
//  Copyright © 2016 Zahola. All rights reserved.
//

#import "PadSettings.h"

#import "MIDIManager.h"

@implementation PadSettings

+ (instancetype)sharedSettings {
    static PadSettings* sharedSettings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSettings = [PadSettings new];
        sharedSettings.padType = PadTypeChords;
        sharedSettings.startNote = kMIDINoteC1 + 12 * 2;
    });
    return sharedSettings;
}

@end
