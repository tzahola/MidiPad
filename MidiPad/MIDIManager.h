//
//  MIDIManager.h
//  MidiPad
//
//  Created by Tamás Zahola on 22/11/15.
//  Copyright © 2015 Zahola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern Byte const kMIDINoteC1;
extern Byte const kMIDIMaxVelocity;
extern char const * const MIDINoteNames[];
extern NSUInteger const MIDINotesPerOctave;

CF_INLINE NSString* NSStringFromMIDINote(Byte note) {
    char const* name = MIDINoteNames[note % MIDINotesPerOctave];
    int octaveNumber = (note / MIDINotesPerOctave) - (kMIDINoteC1 / MIDINotesPerOctave) + 1;
    return [NSString stringWithFormat:@"%s%d", name, octaveNumber];
}

@protocol MIDIDestination <NSObject>

@property (nonatomic, strong, readonly) NSString* displayName;

@end

extern NSString* const MIDIManagerSetupChanged;
extern NSString* const MIDIManagerDestinationAdded;
extern NSString* const MIDIManagerDestinationRemoved;

@interface MIDIMessageCollection : NSObject

- (void)addNoteOnMessageWithNote:(Byte)note
                     velocity:(Byte)velocity
                      channel:(Byte)channel
                        delay:(NSTimeInterval)delay;

- (void)addNoteOffMessageWithNote:(Byte)note
                      velocity:(Byte)velocity
                       channel:(Byte)channel
                         delay:(NSTimeInterval)delay;

- (void)addControlChangeMessageWithController:(Byte)controller
                                     value:(Byte)value
                                   channel:(Byte)channel
                                     delay:(NSTimeInterval)delay;

- (void)addChannelPressureMessageWithValue:(Byte)value
                                channel:(Byte)channel
                                  delay:(NSTimeInterval)delay;

- (void)addPitchBendMessageWithValue:(Byte)value
                          channel:(Byte)channel
                            delay:(NSTimeInterval)delay;

@end

@interface MIDIManager : NSObject

@property (nonatomic, strong, readonly) NSArray<id<MIDIDestination>>* midiDestinations;
@property (nonatomic, strong) id<MIDIDestination> selectedDestination;

- (UIViewController*)createBluetoothSetupViewController;

+ (instancetype)defaultManager;

- (void)start;
- (void)stop;

- (void)sendNoteOn:(Byte)note velocity:(Byte)velocity channel:(Byte)channel;
- (void)sendNoteOff:(Byte)note velocity:(Byte)velocity channel:(Byte)channel;
- (void)sendMessages:(MIDIMessageCollection*)messages;

@end
