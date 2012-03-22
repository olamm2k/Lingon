/* LINMainController */

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

#ifdef DEBUG_STYLE_BUILD
	#define LogBool(bool) NSLog(@"The value of "#bool" is %@", bool ? @"YES" : @"NO")
	#define LogInt(number) NSLog(@"The value of "#number" is %d", number)
	#define LogFloat(number) NSLog(@"The value of "#number" is %f", number)
	#define Log(obj) NSLog(@"The value of "#obj" is %@", obj)
	#define LogChar(characters) NSLog(@#characters)
	#define START NSDate *then = [NSDate date]
	#define TIME NSLog(@"Time elapsed: %f seconds", [then timeIntervalSinceNow] * -1)
#endif

#define MYAGENTS [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"LaunchAgents"]
#define USERSAGENTS @"/Library/LaunchAgents"
#define USERSDAEMONS @"/Library/LaunchDaemons"
#define SYSTEMAGENTS @"/System/Library/LaunchAgents"
#define SYSTEMDAEMONS @"/System/Library/LaunchDaemons"

#define MYAGENTSSTRING NSLocalizedString(@"My Agents", @"My Agents tab view label")
#define USERSAGENTSSTRING NSLocalizedString(@"Users Agents", @"Users Agents tab view label")
#define USERSDAEMONSSTRING NSLocalizedString(@"Users Daemons", @"Users Daemons tab view label")
#define SYSTEMAGENTSSTRING NSLocalizedString(@"System Agents", @"System Agents tab view label")
#define SYSTEMDAEMONSSTRING NSLocalizedString(@"System Daemons", @"System Daemons tab view label")

#define OKBUTTON NSLocalizedString(@"OK", @"OK-button")

enum {
    LINAuthActionGetLoadedLaunchd = 1,
	LINAuthActionLoad,
	LINAuthActionUnload,
	LINAuthActionReload,
	LINAuthActionStart,
	LINAuthActionStop,
	LINAuthActionSave,
	LINAuthActionMove,
	LINAuthActionDelete,
	LINAuthActionChangeName
};

enum {
    LINMyAgentsFolder = 1,
	LINUsersAgentsFolder,
	LINUsersDaemonsFolder,
	LINSystemAgentsFolder,
	LINSystemDaemonsFolder,
};

@interface LINMainController : NSObject
{
    IBOutlet NSTabView *mainTabView;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSTableView *mainTableView;
	
	NSDictionary *defaults;
	NSMutableDictionary *columnWidths;

	BOOL shouldUpdateTab;
	
	NSTimer *checkForUpdateTimer;
	NSTimer *hideNoUpdateAvailableTextFieldTimer;
}

+ (LINMainController *)sharedInstance;

-(void)refreshTableView;
-(NSTabView *)mainTabView;
-(NSTableView *)mainTableView;

-(int)alertWithMessage:(NSString *)message informativeText:(NSString *)informativeText defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternateButton otherButton:(NSString *)otherButton;
-(void)edit;

- (NSMutableDictionary *)columnWidths;
- (void)setColumnWidths:(NSMutableDictionary *)newColumnWidths;

-(BOOL)needSecureTool;
-(void)updateSelectedTab;

-(NSString *)currentFolderPath;
-(int)currentFolderPathNumber;

- (NSWindow *)mainWindow;

- (BOOL)shouldUpdateTab;
- (void)setShouldUpdateTab:(BOOL)flag;

-(void)checkForUpdate;


- (BOOL)tableView:(NSTableView *)theTableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard*)pasteboard;
- (NSDragOperation)tableView:(NSTableView *)theTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation;
- (BOOL)tableView:(NSTableView *)theTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation;


-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet toIndex:(unsigned int)insertIndex arrayController:(NSArrayController *)arrayController;
-(NSIndexSet *)indexSetFromRows:(NSArray *)rows;
-(int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet;
-(NSArrayController *)arrayControllerForTableView:(NSTableView *)theTableView;
@end
