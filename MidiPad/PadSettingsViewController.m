//
//  PadSettingsViewController.m
//  MidiPad
//
//  Created by Tamás Zahola on 15/03/16.
//  Copyright © 2016 Zahola. All rights reserved.
//

#import "PadSettingsViewController.h"

#import "PadSettings.h"
#import "MIDIManager.h"

static inline PadType PadTypeFromSegmentIndex(NSInteger segment) {
    switch (segment) {
        case 0: return PadTypeMPC;
        case 1: return PadTypeChords;
        default:
            NSCAssert(NO, @"Unknown segment: %d", (int)segment);
            return 0;
    }
}

static inline NSInteger SegmentIndexFromPadType(PadType padType) {
    switch (padType) {
        case PadTypeMPC: return 0;
        case PadTypeChords: return 1;
        default:
            NSCAssert(NO, @"Unknown pad type: %d", (int)padType);
            return 0;
    }
}

@interface PadSettingsViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) PadSettings* padSettings;
@property (nonatomic, weak) IBOutlet UISegmentedControl *padLayoutSegmentedControl;
@property (nonatomic, weak) IBOutlet UIPickerView *startNotePicker;

@end

@implementation PadSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.padSettings = [PadSettings sharedSettings];
    
    self.padLayoutSegmentedControl.selectedSegmentIndex = SegmentIndexFromPadType(self.padSettings.padType);
    
    NSUInteger startNote = self.padSettings.startNote % MIDINotesPerOctave;
    [self.startNotePicker selectRow:startNote inComponent:0 animated:NO];
    
    NSUInteger startNoteOctave = self.padSettings.startNote / MIDINotesPerOctave;
    [self.startNotePicker selectRow:startNoteOctave inComponent:1 animated:NO];
}

- (IBAction)padLayoutSegmentedControlChanged:(UISegmentedControl*)padLayoutSegmentedControl {
    self.padSettings.padType = PadTypeFromSegmentIndex(padLayoutSegmentedControl.selectedSegmentIndex);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (component) {
        case 0: return 12;
        case 1: return 10;
        default:
            NSAssert(NO, @"Unknown component: %d", (int)component);
            return 0;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSUInteger note = [pickerView selectedRowInComponent:0];
    NSUInteger octave = [pickerView selectedRowInComponent:1];
    self.padSettings.startNote = note + octave * MIDINotesPerOctave;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (component) {
        case 0: return @(MIDINoteNames[row]);
        case 1: return [NSString stringWithFormat:@"%d", (int)row - 2];
            
        default:
            NSAssert(NO, @"Unknown component: %d", (int)component);
            return nil;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return pickerView.bounds.size.height / 3;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return pickerView.bounds.size.width / 2;
}

- (IBAction)doneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
