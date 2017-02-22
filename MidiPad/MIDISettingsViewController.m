//
//  MIDISettingsViewController.m
//  MidiPad
//
//  Created by Tamás Zahola on 22/11/15.
//  Copyright © 2015 Zahola. All rights reserved.
//

#import "MIDISettingsViewController.h"

#import "MIDIManager.h"

@interface MIDISettingsViewController ()

@property (nonatomic, strong) NSArray<id<MIDIDestination>>* midiDestinations;
@property (nonatomic, strong) id<MIDIDestination> selectedDestination;

@end

@implementation MIDISettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter
        defaultCenter]
        addObserver:self
        selector:@selector(midiDestinationsChanged:)
        name:MIDIManagerSetupChanged
        object:nil];
    [[NSNotificationCenter
        defaultCenter]
        addObserver:self
        selector:@selector(midiDestinationsChanged:)
        name:MIDIManagerDestinationAdded
        object:nil];
    [[NSNotificationCenter
        defaultCenter]
        addObserver:self
        selector:@selector(midiDestinationsChanged:)
        name:MIDIManagerDestinationRemoved
        object:nil];
    [self reload];
}

- (void)midiDestinationsChanged:(NSNotification*)notification {
    [self reload];
}

- (void)reload {
    self.midiDestinations = [MIDIManager defaultManager].midiDestinations;
    self.selectedDestination = [MIDIManager defaultManager].selectedDestination;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 1;
        case 1: return self.midiDestinations.count;
        default:
            NSAssert(NO, @"Unhandled section: %d", (int)section);
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: return [tableView dequeueReusableCellWithIdentifier:@"BluetoothSetupCell"];
        case 1: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MIDIDestinationCell"];
            cell.textLabel.text = self.midiDestinations[indexPath.row].displayName;
            cell.accessoryType = self.midiDestinations[indexPath.row] == self.selectedDestination ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            return cell;
        }
        default:
            NSAssert(NO, @"Unhandled section: %d", (int)indexPath.row);
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            [self.navigationController
                pushViewController:[[MIDIManager defaultManager] createBluetoothSetupViewController]
                animated:YES];
        } break;
        case 1: {
            [MIDIManager defaultManager].selectedDestination = self.midiDestinations[indexPath.row];
            [self reload];
        } break;
        default: NSAssert(NO, @"Unhandled section: %d", (int)indexPath.row);
    }
}

- (IBAction)doneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
