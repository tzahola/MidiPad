//
//  MIDIManager.m
//  MidiPad
//
//  Created by Tamás Zahola on 22/11/15.
//  Copyright © 2015 Zahola. All rights reserved.
//

#import "MIDIManager.h"

#import <CoreMIDI/CoreMIDI.h>
#import <CoreAudioKit/CoreAudioKit.h>

extern "C" {
    #include <mach/mach_time.h>
}

#include <vector>

#define CAST(type, name, value) type name = (type)(value)

Byte const kMIDINoteC1 = 36;
Byte const kMIDIMaxVelocity = 127;

NSString* const MIDIManagerSetupChanged = @"MIDIManagerSetupChanged";
NSString* const MIDIManagerDestinationAdded = @"MIDIManagerDestinationAdded";
NSString* const MIDIManagerDestinationRemoved = @"MIDIManagerDestinationRemoved";

char const * const MIDINoteNames[] = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" };
NSUInteger const MIDINotesPerOctave = 12;

static inline NSString* NSStringFromMIDIObjectType(MIDIObjectType type) {
    switch (type) {
        case kMIDIObjectType_Other: return @"Other";
        case kMIDIObjectType_Device: return @"Device";
        case kMIDIObjectType_Entity: return @"Entity";
        case kMIDIObjectType_Source: return @"Source";
        case kMIDIObjectType_Destination: return @"Destination";
        case kMIDIObjectType_ExternalDevice: return @"ExternalDevice";
        case kMIDIObjectType_ExternalEntity: return @"ExternalEntity";
        case kMIDIObjectType_ExternalSource: return @"ExternalSource";
        case kMIDIObjectType_ExternalDestination: return @"ExternalDestination";
        default: NSCAssert(NO, @"Uknown MIDIObjectType: %lld", (long long int)type);
    }
}

enum {
    kMIDINoteOffNibble = 0x8,
    kMIDINoteOnNibble = 0x9,
    kMIDIAftertouchNibble = 0xA,
    kMIDIControlChangeNibble = 0xB,
    kMIDIProgramChangeNibble = 0xC,
    kMIDIChannelPressureNibble = 0xD,
    kMIDIPitchBendChangeNibble = 0xE,
    kMIDISystemNibble = 0xF
};

static inline Byte ByteFromNibbles(Byte leftMostNibble, Byte rightMostNibble) {
    NSCParameterAssert(leftMostNibble <= 0xF);
    NSCParameterAssert(rightMostNibble <= 0xF);
    return (leftMostNibble << 4) | rightMostNibble;
}

namespace midi {
    struct message {
        std::vector<Byte> bytes;
        NSTimeInterval delay;
    };
}

@implementation MIDIMessageCollection {
    @public std::vector<midi::message> _messages;
}

- (void)addNoteOnMessageWithNote:(Byte)note
                        velocity:(Byte)velocity
                         channel:(Byte)channel
                           delay:(NSTimeInterval)delay {
    NSParameterAssert((note & 0b01111111) == note);
    NSParameterAssert((velocity & 0b01111111) == velocity);
    NSParameterAssert((channel & 0b00001111) == channel);
    
    midi::message message = {
        .bytes = {
            ByteFromNibbles(kMIDINoteOnNibble, channel),
            note,
            velocity
        },
        .delay = delay
    };
    _messages.push_back(message);
}

- (void)addNoteOffMessageWithNote:(Byte)note
                         velocity:(Byte)velocity
                          channel:(Byte)channel
                            delay:(NSTimeInterval)delay {
    NSParameterAssert((note & 0b01111111) == note);
    NSParameterAssert((velocity & 0b01111111) == velocity);
    NSParameterAssert((channel & 0b00001111) == channel);
    
    midi::message message = {
        .bytes = {
            ByteFromNibbles(kMIDINoteOffNibble, channel),
            note,
            velocity
        },
        .delay = delay
    };
    _messages.push_back(message);
}

- (void)addControlChangeMessageWithController:(Byte)controller
                                        value:(Byte)value
                                      channel:(Byte)channel
                                        delay:(NSTimeInterval)delay {
    
}

- (void)addChannelPressureMessageWithValue:(Byte)value
                                   channel:(Byte)channel
                                     delay:(NSTimeInterval)delay {
    
}

- (void)addPitchBendMessageWithValue:(Byte)value
                             channel:(Byte)channel
                               delay:(NSTimeInterval)delay {
    
}

@end

static MIDITimeStamp MIDITimestampFromTimeInterval(NSTimeInterval timeInterval) {
    static double factor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mach_timebase_info_data_t timebase;
        mach_timebase_info(&timebase);
        factor = (timebase.denom / (double)timebase.numer) * 1.0e9;
    });
    return (MIDITimeStamp)(timeInterval * factor);
}

static inline OSStatus SendMIDIData(MIDIPortRef port, MIDIEndpointRef endpoint, MIDIMessageCollection* messages) {
    Byte buffer[65536];
    MIDIPacketList* packetList = (MIDIPacketList*)buffer;
    MIDIPacket* packet = MIDIPacketListInit(packetList);
    for (midi::message message : messages->_messages) {
        MIDITimeStamp timestamp = mach_absolute_time() + MIDITimestampFromTimeInterval(message.delay);
        packet = MIDIPacketListAdd(packetList, sizeof(buffer), packet, timestamp, message.bytes.size(), &message.bytes[0]);
    }
    return MIDISend(port, endpoint, packetList);
}

static void MIDIManagerNotifyProc(const MIDINotification *message, void * __nullable refCon);

@interface MIDIDestinationImpl : NSObject<MIDIDestination>

@property (nonatomic, assign, readonly) MIDIUniqueID uniqueID;

@end

@implementation MIDIDestinationImpl
@dynamic displayName;

- (instancetype)initWithUniqueID:(MIDIUniqueID)uniqueID {
    self = [super init];
    if (self) {
        _uniqueID = uniqueID;
    }
    return self;
}

- (MIDIEndpointRef)destination {
    MIDIEndpointRef destination;
    MIDIObjectType type;
    OSStatus status = MIDIObjectFindByUniqueID(_uniqueID, &destination, &type);
    NSAssert(status == noErr && (type & kMIDIObjectType_Destination), @"");
    return destination;
}

- (NSString *)displayName {
    CFStringRef destinationName;
    OSStatus status = MIDIObjectGetStringProperty(self.destination, kMIDIPropertyDisplayName, &destinationName);
    NSAssert(status == noErr, @"Failed to get display name");
    return (__bridge NSString*)CFAutorelease(destinationName);
}

@end

@interface MIDIManager ()

@property (nonatomic, strong) NSMutableDictionary* midiDestinationsByUniqueID;
@property (nonatomic, assign) MIDIUniqueID selectedDestinationUniqueID;

@end

@implementation MIDIManager {
    MIDIClientRef _midiClient;
    MIDIPortRef _midiOutputPort;
    MIDIEndpointRef _midiDestination;
}
@dynamic
midiDestinations,
selectedDestination;

+ (instancetype)defaultManager {
    static MIDIManager* defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [MIDIManager new];
    });
    return defaultManager;
}

- (void)dealloc {
    [self stop];
}

- (void)start {
    OSStatus status = MIDIClientCreate(CFSTR("MIDI Client"), MIDIManagerNotifyProc, (__bridge void*)self, &_midiClient);
    NSAssert(status == noErr, @"Failed to create MIDI client");
    
    status = MIDIOutputPortCreate(_midiClient, CFSTR("MIDI Output Port"), &_midiOutputPort);
    NSAssert(status == noErr, @"Failed to create MIDI output port");
    
    [self reloadMIDIDestinations];
}

- (void)reloadMIDIDestinations {
    self.midiDestinationsByUniqueID = [NSMutableDictionary new];
    
    int numberOfDestinations = (int)MIDIGetNumberOfDestinations();
    for (int i = 0; i < numberOfDestinations; i++) {
        MIDIEndpointRef destination = MIDIGetDestination(i);
        MIDIUniqueID uniqueID;
        OSStatus status = MIDIObjectGetIntegerProperty(destination, kMIDIPropertyUniqueID, &uniqueID);
        NSAssert(status == noErr, @"Failed to get uniqueID");
        self.midiDestinationsByUniqueID[@(uniqueID)] = [[MIDIDestinationImpl alloc] initWithUniqueID:uniqueID];
    }
}

- (void)stop {
    self.midiDestinationsByUniqueID = nil;
    MIDIPortDispose(_midiOutputPort);
    MIDIClientDispose(_midiClient);
}

- (UIViewController *)createBluetoothSetupViewController {
    return [[CABTMIDILocalPeripheralViewController alloc] init];
}

- (NSArray<id<MIDIDestination>> *)midiDestinations {
    return self.midiDestinationsByUniqueID.allValues;
}

- (void)setSelectedDestination:(id<MIDIDestination>)selectedDestination {
    self.selectedDestinationUniqueID = ((MIDIDestinationImpl*)selectedDestination).uniqueID;
    MIDIObjectType type;
    OSStatus status = MIDIObjectFindByUniqueID(self.selectedDestinationUniqueID, &_midiDestination, &type);
    NSAssert(status == noErr, @"Failed to find MIDI destination!");
    NSAssert(type & kMIDIObjectType_Destination, @"The given object is not a MIDI destination!");
}

- (id<MIDIDestination>)selectedDestination {
    return self.midiDestinationsByUniqueID[@(self.selectedDestinationUniqueID)];
}

- (void)sendNoteOn:(Byte)note velocity:(Byte)velocity channel:(Byte)channel {
    MIDIMessageCollection* messages = [MIDIMessageCollection new];
    [messages addNoteOnMessageWithNote:note velocity:velocity channel:channel delay:0];
    [self sendMessages:messages];
}

- (void)sendNoteOff:(Byte)note velocity:(Byte)velocity channel:(Byte)channel {
    MIDIMessageCollection* messages = [MIDIMessageCollection new];
    [messages addNoteOffMessageWithNote:note velocity:velocity channel:channel delay:0];
    [self sendMessages:messages];
}

- (void)sendMessages:(MIDIMessageCollection *)messages {
    OSStatus status = SendMIDIData(_midiOutputPort, _midiDestination, messages);
    NSAssert(status == noErr, @"Failed to send MIDI data, status: %d", (int)status);
}

@end

static void MIDIManagerNotifyProc(const MIDINotification *message, void * __nullable refCon) {
    MIDIManager* self = (__bridge MIDIManager*)refCon;
    
    switch (message->messageID) {
        case kMIDIMsgSetupChanged:
            NSLog(@"MIDI Setup changed");
            [self reloadMIDIDestinations];
            [[NSNotificationCenter defaultCenter] postNotificationName:MIDIManagerSetupChanged object:self];
            break;
        case kMIDIMsgObjectAdded: {
            CAST(MIDIObjectAddRemoveNotification const *, addNotification, message);
            if (addNotification->childType & kMIDIObjectType_Destination) {
                [self reloadMIDIDestinations];
                [[NSNotificationCenter defaultCenter] postNotificationName:MIDIManagerDestinationAdded object:self];
            }
        } break;
        case kMIDIMsgObjectRemoved: {
            CAST(MIDIObjectAddRemoveNotification const *, removeNotification, message);
            if (removeNotification->childType & kMIDIObjectType_Destination) {
                [self reloadMIDIDestinations];
                [[NSNotificationCenter defaultCenter] postNotificationName:MIDIManagerDestinationRemoved object:self];
            }
        } break;
        case kMIDIMsgPropertyChanged: {
            CAST(MIDIObjectPropertyChangeNotification const *, propertyChangedNotification, message);
            NSLog(@"MIDI Property changed: %@", (__bridge NSString*)propertyChangedNotification->propertyName);
        } break;
        case kMIDIMsgThruConnectionsChanged:
            NSLog(@"MIDI Thru connections changed");
            break;
        case kMIDIMsgSerialPortOwnerChanged:
            NSLog(@"MIDI Serial port owner changed");
            break;
        case kMIDIMsgIOError:
            NSLog(@"MIDI IO Error");
            break;
    }
}
