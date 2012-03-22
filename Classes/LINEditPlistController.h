/* LINEditPlistController */

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

@interface LINEditPlistController : NSObject
{
    IBOutlet NSTextView *expertTextView;
	IBOutlet NSTabView *editTabView;
	IBOutlet NSButton *saveAndLoadReload;
	IBOutlet NSTableView *bonjourTableView;
	IBOutlet NSTableView *programArgumentsTableView;
	IBOutlet NSTableView *queueDirectoriesTableView;
	IBOutlet NSTableView *socketsTableView;
	IBOutlet NSTableView *watchPathsTableView;
	IBOutlet NSTableView *environmentVariablesTableView;
	
	IBOutlet NSTextField *rootDirectoryTextField;
	IBOutlet NSTextField *workingDirectoryTextField;
	IBOutlet NSTextField *standardOutPathTextField;
	IBOutlet NSTextField *standardErrorPathTextField;
	
	IBOutlet NSArrayController *programArgumentsArrayController;
	IBOutlet NSArrayController *environmentVariablesArrayController;
	IBOutlet NSArrayController *watchPathsArrayController;
	IBOutlet NSArrayController *queueDirectoriesArrayController;
	IBOutlet NSArrayController *socketsArrayController;
	IBOutlet NSArrayController *bonjourArrayController;
	
	IBOutlet NSWindow *editPlistSheet;
	
	BOOL isInExpertTabView;
	
	NSDictionary *defaults;
	NSString *oldLabel;
}

+ (LINEditPlistController *)sharedInstance;

- (IBAction)cancelAction:(id)sender;
-(void)closeEditSheet;
- (IBAction)justSaveAction:(id)sender;
- (IBAction)saveAndLoadReloadAction:(id)sender;
- (IBAction)validateAction:(id)sender;

- (NSTableView *)bonjourTableView;
- (NSTableView *)programArgumentsTableView;
- (NSTableView *)queueDirectoriesTableView;
- (NSTableView *)socketsTableView;
- (NSTableView *)watchPathsTableView;
- (NSTableView *)environmentVariablesTableView;

-(IBAction)setPathAction:(id)sender;

-(void)setTitleForSaveAndLoadReloadButton;

-(BOOL)checkThatRequiredFieldsAreSet;

-(NSString *)plistStringFromDictionary:(NSDictionary *)dictionary;
-(BOOL)validateStringAsPlist:(NSString *)string;

- (NSTextView *)expertTextView;
-(void)updateExpertTextView;
-(BOOL)isExpertTabViewSelected;
-(BOOL)updateSelectionFromExpertTextView;

-(IBAction)insertAction:(id)sender;

- (NSWindow *)editPlistSheet;

- (NSArrayController *)programArgumentsArrayController;
- (NSArrayController *)environmentVariablesArrayController;
- (NSArrayController *)watchPathsArrayController;
- (NSArrayController *)queueDirectoriesArrayController;
- (NSArrayController *)socketsArrayController;
- (NSArrayController *)bonjourArrayController;

- (NSTabView *)editTabView;

- (NSString *)oldLabel;
- (void)setOldLabel:(NSString *)newOldLabel;
@end
