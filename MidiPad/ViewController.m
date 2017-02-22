//
//  ViewController.m
//  MidiPad
//
//  Created by Tamás Zahola on 21/11/15.
//  Copyright © 2015 Zahola. All rights reserved.
//

#import "ViewController.h"

#import "MIDIManager.h"
#import "PadGrid.h"
#import "PadSettings.h"

static void * PadSettingsContext = &PadSettingsContext;

typedef struct {
    char const * symbol;
    int numberOfNotes;
    int * notes;
} ChordDescription;

static ChordDescription chords[] = {
    { "", 1, (int[]){ 0 } },
    { "M", 3, (int[]){ 0, 4, 7 } },
    { "m", 3, (int[]){ 0, 3, 7 } },
//    { "+", 3, (int[]){ 0, 4, 8 } },
//    { "o", 3, (int[]){ 0, 3, 6 } },
//    { "7", 4, (int[]){ 0, 4, 7, 10 } },
    { "M7", 4, (int[]){ 0, 4, 7, 11 } },
    { "m7", 4, (int[]){ 0, 3, 7, 10 } },
//    { "+7", 4, (int[]){ 0, 4, 8, 10 } },
//    { "o7", 4, (int[]){ 0, 3, 6, 9 } }
    { "M9", 5, (int[]){ 0, 4, 7, 11, 14 } },
    { "9", 5, (int[]){ 0, 4, 7, 10, 14 } },
    { "mM9", 5, (int[]){ 0, 3, 7, 11, 14 } },
    { "M11", 6, (int[]){ 0, 4, 7, 11, 14, 17 } },
};

@interface ViewController () <PadGridDelegate>

@property (nonatomic, weak) IBOutlet PadGrid *padGrid;
@property (nonatomic, strong) PadSettings* padSettings;
@property (nonatomic, assign) PadGridSize padGridSize;

@end

@implementation ViewController

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == PadSettingsContext) {
        [self reloadPadGrid];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (PadGridSize)sizeOfPadGrid:(PadGrid *)padGrid {
    return self.padGridSize;
}

- (void)reloadPadGrid {
    if (self.padSettings.padType == PadTypeMPC) {
        self.padGridSize = PadGridSizeMake(5, 5);
    } else {
        self.padGridSize = PadGridSizeMake(20, sizeof(chords) / sizeof(ChordDescription));
    }
    [self.padGrid reload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addObserver:self forKeyPath:@"padSettings.padType" options:0 context:PadSettingsContext];
    [self addObserver:self forKeyPath:@"padSettings.startNote" options:0 context:PadSettingsContext];
    self.padSettings = [PadSettings sharedSettings];
}

- (NSString *)padGrid:(PadGrid *)padGrid labelForRow:(NSUInteger)row column:(NSUInteger)column {
    if (self.padSettings.padType == PadTypeMPC) {
        return NSStringFromMIDINote([self noteFromRow:row column:column]);
    } else {
        NSString* noteNameForRow = NSStringFromMIDINote(self.padSettings.startNote + row);
        return [NSString stringWithFormat:@"%@\n%s", noteNameForRow, chords[column].symbol];
    }
}

- (Byte)noteFromRow:(NSUInteger)row column:(NSUInteger)column {
    return self.padSettings.startNote + row * self.padGridSize.columns + column;
}

- (void)padGrid:(PadGrid *)padGrid didTouchAtRow:(NSUInteger)row column:(NSUInteger)column {
    if (self.padSettings.padType == PadTypeMPC) {
        [[MIDIManager defaultManager] sendNoteOn:[self noteFromRow:row column:column] velocity:kMIDIMaxVelocity channel:0];
    } else {
        ChordDescription chord = chords[column];
        Byte rootNote = self.padSettings.startNote + row;
        [self sendChordOn:chord rootNote:rootNote];
    }
}

- (void)padGrid:(PadGrid *)padGrid didRetouchAtRow:(NSUInteger)row column:(NSUInteger)column {
    if (self.padSettings.padType == PadTypeMPC) {
        [[MIDIManager defaultManager] sendNoteOff:[self noteFromRow:row column:column] velocity:kMIDIMaxVelocity channel:0];
        [[MIDIManager defaultManager] sendNoteOn:[self noteFromRow:row column:column] velocity:kMIDIMaxVelocity channel:0];
    } else {
        ChordDescription chord = chords[column];
        Byte rootNote = self.padSettings.startNote + row;
        [self sendChordOff:chord rootNote:rootNote];
        [self sendChordOn:chord rootNote:rootNote];
    }
}

- (void)sendChordOn:(ChordDescription)chord rootNote:(Byte)rootNote {
    MIDIMessageCollection* messages = [MIDIMessageCollection new];
    for (int i = 0; i < chord.numberOfNotes; i++) {
        [messages addNoteOnMessageWithNote:rootNote + chord.notes[i] velocity:kMIDIMaxVelocity channel:0 delay:i * 0.056];
    }
    [[MIDIManager defaultManager] sendMessages:messages];
}

- (void)sendChordOff:(ChordDescription)chord rootNote:(Byte)rootNote {
    MIDIMessageCollection* messages = [MIDIMessageCollection new];
    for (int i = 0; i < chord.numberOfNotes; i++) {
        [messages addNoteOffMessageWithNote:rootNote + chord.notes[i] velocity:kMIDIMaxVelocity channel:0 delay:0];
    }
    [[MIDIManager defaultManager] sendMessages:messages];
}

- (void)padGrid:(PadGrid *)padGrid didEndTouchAtRow:(NSUInteger)row column:(NSUInteger)column {
    if (self.padSettings.padType == PadTypeMPC) {
        [[MIDIManager defaultManager] sendNoteOff:[self noteFromRow:row column:column] velocity:kMIDIMaxVelocity channel:0];
    } else {
        ChordDescription chord = chords[column];
        Byte rootNote = self.padSettings.startNote + row;
        [self sendChordOff:chord rootNote:rootNote];
    }
}

@end
