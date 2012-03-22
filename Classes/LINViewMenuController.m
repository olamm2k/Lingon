/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINViewMenuController.h"
#import "LINMainController.h"
#import "LINVariousPerformer.h"
#import "LINEditPlistController.h"

@implementation LINViewMenuController

static id sharedInstance = nil;

+ (LINViewMenuController *)sharedInstance
{ 
	if (sharedInstance == nil) { 
		sharedInstance = [[self alloc] init];
	} 
	return sharedInstance; 
} 


- (id)init 
{
    if (sharedInstance) {
        [self dealloc];
    } else {
        sharedInstance = [super init];
    }
    return sharedInstance;
}


-(void)awakeFromNib
{
	[columnsMenu setDelegate:self];	
}


- (IBAction)refreshAction:(id)sender
{
	[[LINMainController sharedInstance] updateSelectedTab];
	[[LINMainController sharedInstance] refreshTableView];
}


- (IBAction)columnAction:(id)sender
{	
	NSString *column = [sender title];
	NSEnumerator *enumerator = [[[[LINMainController sharedInstance] mainTableView] tableColumns] objectEnumerator];
	id item;
	BOOL foundColumn = NO;
	while (item = [enumerator nextObject]) {
		if ([[[item headerCell] title] isEqual:column]) {
			foundColumn = YES;
			break;
		}
	}
	
	if (foundColumn) {
		[[[LINMainController sharedInstance] columnWidths] setValue:[NSNumber numberWithFloat:[item width]] forKey:column];
		[[[LINMainController sharedInstance] mainTableView] removeTableColumn:item];
	} else {
		NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
		NSTableHeaderCell *cell = [[NSTableHeaderCell alloc] init];
		[cell setTitle:column];
		[tableColumn setHeaderCell:cell];
		[tableColumn setIdentifier:@""];
		[[LINVariousPerformer sharedInstance] insertTableColumn:tableColumn];
		[cell release];
		if ([[[LINMainController sharedInstance] columnWidths] valueForKey:column]) {
			[tableColumn setWidth:[[[[LINMainController sharedInstance] columnWidths] valueForKey:column] floatValue]];
		} else {
			[tableColumn sizeToFit];
		}
		if ([tableColumn width] < 50) {
			[tableColumn setWidth:50];
		}
		
		[tableColumn release];
	}
	
	[[LINMainController sharedInstance] refreshTableView];
}


- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSMutableSet *titleSet = [[NSMutableSet alloc] init];
	NSEnumerator *enumerator = [[[[LINMainController sharedInstance] mainTableView] tableColumns] objectEnumerator];
	id item;
	while (item = [enumerator nextObject]) {
		[titleSet addObject:[[item headerCell] title]];
	}
	
	enumerator = [[columnsMenu itemArray] objectEnumerator];
	while (item = [enumerator nextObject]) {
		if ([titleSet containsObject:[item title]]) {
			[item setState:NSOnState];
		} else {
			[item setState:NSOffState];
		}
	}
	
	[titleSet release];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([[[[LINMainController sharedInstance] mainWindow] attachedSheet] isEqual:[[LINEditPlistController sharedInstance] editPlistSheet]]) {
		if ([anItem tag] == 0 || [anItem tag] == 1 || ([anItem tag] > 10 && [anItem tag] < 20)) { // Columns, Refresh, Agents/Daemons
			return NO;
		} else if ([anItem tag] == ([[[LINEditPlistController sharedInstance] editTabView] indexOfTabViewItem:[[[LINEditPlistController sharedInstance] editTabView] selectedTabViewItem]] + 21)) { // The selected tab
			return NO;
		}
	} else {
		if ([anItem tag] > 20 && [anItem tag] < 30) {
			return NO;
		} else if ([anItem tag] == ([[[LINMainController sharedInstance] mainTabView] indexOfTabViewItem:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem]] + 11)) { // The selected tab
			return NO;
		}
	}
	
	return YES;
}


- (IBAction)selectNextTabAction:(id)sender
{
	int index;
	if ([[[[LINMainController sharedInstance] mainWindow] attachedSheet] isEqual:[[LINEditPlistController sharedInstance] editPlistSheet]]) {
		index = [[[LINEditPlistController sharedInstance] editTabView] indexOfTabViewItem:[[[LINEditPlistController sharedInstance] editTabView] selectedTabViewItem]];
		if (index == 5) {
			[[[LINEditPlistController sharedInstance] editTabView] selectFirstTabViewItem:nil];
		} else {
			[[[LINEditPlistController sharedInstance] editTabView] selectNextTabViewItem:nil];
		}
	} else {
		index = [[[LINMainController sharedInstance] mainTabView] indexOfTabViewItem:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem]];
		if (index == 4) {
			[[[LINMainController sharedInstance] mainTabView] selectFirstTabViewItem:nil];
		} else {
			[[[LINMainController sharedInstance] mainTabView] selectNextTabViewItem:nil];
		}
	}
}


- (IBAction)selectPreviousTabAction:(id)sender
{
	int index;
	if ([[[[LINMainController sharedInstance] mainWindow] attachedSheet] isEqual:[[LINEditPlistController sharedInstance] editPlistSheet]]) {
		index = [[[LINEditPlistController sharedInstance] editTabView] indexOfTabViewItem:[[[LINEditPlistController sharedInstance] editTabView] selectedTabViewItem]];
		if (index == 0) {
			[[[LINEditPlistController sharedInstance] editTabView] selectLastTabViewItem:nil];
		} else {
			[[[LINEditPlistController sharedInstance] editTabView] selectPreviousTabViewItem:nil];
		}
	} else {
		index = [[[LINMainController sharedInstance] mainTabView] indexOfTabViewItem:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem]];
		if (index == 0) {
			[[[LINMainController sharedInstance] mainTabView] selectLastTabViewItem:nil];
		} else {
			[[[LINMainController sharedInstance] mainTabView] selectPreviousTabViewItem:nil];
		}
	}
}


- (IBAction)agentsDaemonsTabAction:(id)sender
{
	[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:([sender tag] - 11)];	
}


- (IBAction)editTabAction:(id)sender
{
	[[[LINEditPlistController sharedInstance] editTabView] selectTabViewItemAtIndex:([sender tag] - 21)];
}


- (IBAction)folderInFinderAction:(id)sender
{
	NSString *path;
	if ([sender tag] == 32) {
		path = USERSAGENTS;
	} else if ([sender tag] == 33) {
		path = USERSDAEMONS;
	} else if ([sender tag] == 34) {
		path = SYSTEMAGENTS;
	} else if ([sender tag] == 35) {
		path = SYSTEMDAEMONS;
	} else {
		path = MYAGENTS;
	}
	
	[[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Finder"];
}


@end
