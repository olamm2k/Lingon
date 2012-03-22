/* LINAssistant */

/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import <Cocoa/Cocoa.h>

@interface LINAssistant : NSObject
{
    IBOutlet NSWindow *assistantSheet;
    IBOutlet NSMatrix *assitantMatrix;
    IBOutlet NSTextField *choice1JobTextField;
    IBOutlet NSTextField *labelTextField;
    IBOutlet NSPopUpButton *choice2EveryPopUp;
    IBOutlet NSTextField *choice2JobTextField;
    IBOutlet NSTextField *choice2RunEveryTextField;
    IBOutlet NSPopUpButton *choice3DayPopUp;
    IBOutlet NSPopUpButton *choice3HourPopUp;
    IBOutlet NSTextField *choice3JobTextField;
    IBOutlet NSPopUpButton *choice3MinutePopUp;
    IBOutlet NSPopUpButton *choice3MonthPopUp;
    IBOutlet NSPopUpButton *choice3WeekdayPopUp;
    IBOutlet NSTextField *choice4ApplicationScriptTextField;
    IBOutlet NSTextField *choice5FileTextField;
    IBOutlet NSTextField *choice5ApplicationScriptTextField;
    IBOutlet NSTextField *choice6FolderTextField;
    IBOutlet NSTextField *choice6ApplicationScriptTextField;
    IBOutlet NSTextField *stepTextField;
    IBOutlet NSButton *mustRunAsRoot;
    IBOutlet NSButton *nextCreate;
    IBOutlet NSButton *launchOnlyWhenILogIn;
	IBOutlet NSButton *previous;
	IBOutlet NSTabView *assistantTabView;
	
	NSDictionary *defaults;
}

+ (LINAssistant *)sharedInstance;

- (IBAction)cancelAction:(id)sender;
- (IBAction)nextCreateAction:(id)sender;
- (IBAction)pathAction:(id)sender;
- (IBAction)launchOnlyWhenILogInAction:(id)sender;
- (IBAction)previousAction:(id)sender;

-(void)openAssistant;
-(void)closeAssistant;

-(NSArray *)divideCommandIntoArray:(NSString *)command;

-(void)allRequiredFieldsAreNotSet;

-(int)whichFolder;
-(void)setStep:(int)step;
@end
