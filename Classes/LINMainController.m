// TableView delegate
// TabView delegate
// MainWindow delegate

/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINMainController.h"
#import "LINPreferences.h"
#import "LINSecureToolCommunication.h"
#import "LINVariousPerformer.h"
#import "LINProgramArgumentsTransformer.h"
#import "LINPlistsController.h"
#import "LINToolbar.h"
#import "LINViewMenuController.h"
#import "LINBoolTransformer.h"
#import "LINBoolColourTransformer.h"
#import "LINEditPlistController.h"
#import "LINCalendarTransformer.h"
#import "LINPathsTransformer.h"
#import "LINSocketsTransformer.h"
#import "LINEnvironmentVariablesTransformer.h"
#import "LINResourceLimitsTransformer.h"
#import "LINActionMenuController.h"
#import "LINFileMenuController.h"
#import "LINAssistant.h"
#import "LINFontTransformer.h"

#import <SystemConfiguration/SCNetwork.h>

NSString *LINMovedRowsType = @"LINMovedRowsType";

#define THISVERSION 1.21

@implementation LINMainController

static id sharedInstance = nil;

+ (LINMainController *)sharedInstance
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
		
		SInt32 systemVersion;
		if (Gestalt(gestaltSystemVersion, &systemVersion) == noErr) {
			if (systemVersion < 0x1042) {
				[NSApp activateIgnoringOtherApps:YES];
				NSAlert *alert = [[[NSAlert alloc] init] autorelease];
				[alert setMessageText:NSLocalizedString(@"You need Mac OS X Tiger 10.4.2 or later to run this version of Lingon", @"You need Mac OS X Tiger 10.4.2 or later to run this version of Lingon in Check-system-version")];
				[alert setInformativeText:@""];
				[alert addButtonWithTitle:OKBUTTON];
				[alert runModal];
				
				[NSApp terminate:nil];
			} else if (systemVersion >= 0x1050) {
				[NSApp activateIgnoringOtherApps:YES];
				NSAlert *alert = [[[NSAlert alloc] init] autorelease];
				[alert setMessageText:NSLocalizedString(@"This version of Lingon does not function properly on Mac OS X 10.5 Leopard. Please download a later version from the web site.", @"This version of Lingon does not function properly on Mac OS X 10.5 Leopard. Please download a later version from the web site.")];
				[alert setInformativeText:@""];
				[alert addButtonWithTitle:OKBUTTON];
				[alert addButtonWithTitle:NSLocalizedString(@"Go To Web Site", @"Go To Web Site")];
				int answer = [alert runModal];
				if (answer == NSAlertSecondButtonReturn) {
					[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lingon.sourceforge.net/"]];
				}
				
				[NSApp terminate:nil];
			}
		}
		
		[[LINPreferences sharedInstance] setDefaults];
		
		defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
		columnWidths = [[NSMutableDictionary alloc] init];
		
		shouldUpdateTab = YES;
    }
    return sharedInstance;
}


+ (void)initialize 
{  
    NSValueTransformer *programArgumentsTransformer = [[LINProgramArgumentsTransformer alloc] init];
    [NSValueTransformer setValueTransformer:programArgumentsTransformer forName:@"ProgramArgumentsTransformer"];
	[programArgumentsTransformer release];
	
	NSValueTransformer *boolTransformer = [[LINBoolTransformer alloc] init];
    [NSValueTransformer setValueTransformer:boolTransformer forName:@"BoolTransformer"];
	[boolTransformer release];
	
	NSValueTransformer *boolColourTransformer = [[LINBoolColourTransformer alloc] init];
    [NSValueTransformer setValueTransformer:boolColourTransformer forName:@"BoolColourTransformer"];
	[boolColourTransformer release];
	
	NSValueTransformer *calendarTransformer = [[LINCalendarTransformer alloc] init];
    [NSValueTransformer setValueTransformer:calendarTransformer forName:@"CalendarTransformer"];
	[calendarTransformer release];
	
	NSValueTransformer *pathsTransformer = [[LINPathsTransformer alloc] init];
    [NSValueTransformer setValueTransformer:pathsTransformer forName:@"PathsTransformer"];
	[pathsTransformer release];
	
	NSValueTransformer *socketsTransformer = [[LINSocketsTransformer alloc] init];
    [NSValueTransformer setValueTransformer:socketsTransformer forName:@"SocketsTransformer"];
	[socketsTransformer release];
	
	NSValueTransformer *environmentVariablesTransformer = [[LINEnvironmentVariablesTransformer alloc] init];
    [NSValueTransformer setValueTransformer:environmentVariablesTransformer forName:@"EnvironmentVariablesTransformer"];
	[environmentVariablesTransformer release];
	
	NSValueTransformer *resourceLimitsTransformer = [[LINResourceLimitsTransformer alloc] init];
    [NSValueTransformer setValueTransformer:resourceLimitsTransformer forName:@"ResourceLimitsTransformer"];
	[resourceLimitsTransformer release];
	
	NSValueTransformer *fontTransformer = [[LINFontTransformer alloc] init];
    [NSValueTransformer setValueTransformer:fontTransformer forName:@"FontTransformer"];
	[fontTransformer release];
}


-(void)awakeFromNib
{
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"ToolbarIdentifier"] autorelease];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    [toolbar setDelegate:[LINToolbar sharedInstance]];
	[toolbar setShowsBaselineSeparator:NO];
    [mainWindow setToolbar:toolbar];
	
	if ([defaults valueForKey:@"TableColumns"]) {
		NSEnumerator *enumerator = [[mainTableView tableColumns] objectEnumerator];
		id item;
		while (item = [enumerator nextObject]) {
			[mainTableView removeTableColumn:item];
		}
		
		enumerator = [[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:@"TableColumns"]] objectEnumerator];
		while (item = [enumerator nextObject]) {
			[[LINVariousPerformer sharedInstance] insertTableColumn:item];
		}
	}
	
	[[LINVariousPerformer sharedInstance] updateContentsForTab:[mainTabView tabViewItemAtIndex:0] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
	
	if ([defaults valueForKey:@"RemovedTableColumnWidths"]) {
		[self setColumnWidths:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:@"RemovedTableColumnWidths"]]];
	}
	
	[mainTableView setTarget:self];
	[mainTableView setDoubleAction:@selector(edit)];
	[mainTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, LINMovedRowsType, nil]];
	[mainTableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationDelete) forLocal:NO];
	
	if ([defaults valueForKey:@"SortDescriptors"]) {
		[mainTableView setSortDescriptors:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:@"SortDescriptors"]]];
	}
	
	[[[LINEditPlistController sharedInstance] programArgumentsTableView] registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, LINMovedRowsType, nil]];
	[[[LINEditPlistController sharedInstance] programArgumentsTableView] setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationDelete) forLocal:NO];
	
	[[[LINEditPlistController sharedInstance] environmentVariablesTableView] registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, LINMovedRowsType, nil]];
	[[[LINEditPlistController sharedInstance] environmentVariablesTableView] setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationDelete) forLocal:NO];
	
	[[[LINEditPlistController sharedInstance] queueDirectoriesTableView] registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, LINMovedRowsType, NSFilenamesPboardType, nil]];
	[[[LINEditPlistController sharedInstance] queueDirectoriesTableView] setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationDelete) forLocal:NO];
	
	[[[LINEditPlistController sharedInstance] watchPathsTableView] registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, LINMovedRowsType, NSFilenamesPboardType, nil]];
	[[[LINEditPlistController sharedInstance] watchPathsTableView] setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationDelete) forLocal:NO];
	
	[[[LINEditPlistController sharedInstance] socketsTableView] registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, LINMovedRowsType, nil]];
	[[[LINEditPlistController sharedInstance] socketsTableView] setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationDelete) forLocal:NO];
	
	[[[LINEditPlistController sharedInstance] bonjourTableView] registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, LINMovedRowsType, nil]];
	[[[LINEditPlistController sharedInstance] bonjourTableView] setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationDelete) forLocal:NO];
	
	if ([defaults valueForKey:@"CheckForUpdatesAtStartup"] && [[defaults valueForKey:@"CheckForUpdatesAtStartup"] boolValue]) {
		checkForUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:3
																target:self
															  selector:@selector(checkForUpdate)
															  userInfo:nil
															   repeats:NO] retain];
	}
	
	[mainTabView registerForDraggedTypes:[NSArray arrayWithObject:LINMovedRowsType]];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[defaults setValue:[NSArchiver archivedDataWithRootObject:[mainTableView sortDescriptors]] forKey:@"SortDescriptors"];
	[defaults setValue:[NSArchiver archivedDataWithRootObject:[mainTableView tableColumns]] forKey:@"TableColumns"];
	[defaults setValue:[NSArchiver archivedDataWithRootObject:columnWidths] forKey:@"RemovedTableColumnWidths"];
	
	[[LINSecureToolCommunication sharedInstance] deauthorise];
}


-(void)refreshTableView
{
	[[[LINPlistsController sharedInstance] arrayController] rearrangeObjects];
	[mainTableView reloadData];
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[defaults valueForKey:@"TableFontSize"] intValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
}


- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if ([[tabViewItem identifier] isEqual:@"5"] && [[defaults valueForKey:@"WarnMe"] boolValue]) { 
		[self alertWithMessage:NSLocalizedString(@"You are STRONGLY recommended not to change the Apple-supplied configuration files unless you know what you are doing", @"You are STRONGLY recommended not to change the Apple-supplied configuration files unless you know what you are doing in warn about changing System Daemons") informativeText:NSLocalizedString(@"You can possibly leave your system inoperable if certain changes are made. Although I have tested as much as I can, absolutely no guarantees can be given about changes to these. If you want to turn on e.g. SSH use Services under Sharing in System Preferences instead. (This warning can be turned off in Preferences.)", @"You can possibly leave your system inoperable if certain changes are made. Although I have tested as much as I can, absolutely no guarantees can be given about changes to these. If you want to turn on e.g. SSH use Services under Sharing in System Preferences instead. (This warning can be turned off in Preferences.) in warn about changing System Daemons") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
	}
	[self updateSelectedTab];
}


-(NSTabView *)mainTabView
{
	return mainTabView;
}


-(NSTableView *)mainTableView
{
	return mainTableView;
}


-(int)alertWithMessage:(NSString *)message informativeText:(NSString *)informativeText defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternateButton otherButton:(NSString *)otherButton
{	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:message];
	[alert setInformativeText:informativeText];
	if (defaultButton) {
		[alert addButtonWithTitle:defaultButton];
	}
	if (alternateButton) {
		[alert addButtonWithTitle:alternateButton];
	}
	if (otherButton) {
		[alert addButtonWithTitle:otherButton];
	}
	
	return [alert runModal];
	// NSAlertFirstButtonReturn
	// NSAlertSecondButtonReturn
	// NSAlertThirdButtonReturn
}


-(void)edit
{
	[[LINActionMenuController sharedInstance] editAction:nil];
}


- (NSMutableDictionary *)columnWidths
{
    return columnWidths; 
}


- (void)setColumnWidths:(NSMutableDictionary *)newColumnWidths
{
    [newColumnWidths retain];
    [columnWidths release];
    columnWidths = newColumnWidths;
}


-(BOOL)needSecureTool
{
	NSString *identifier = [[[self mainTabView] selectedTabViewItem] identifier];
	if ([identifier isEqual:@"1"]) {
		return NO;
	} else {
		return YES;
	}
}


-(void)updateSelectedTab
{
	if (!shouldUpdateTab) { // this is just to avoid having to log in/check loaded twice when importing a plist or creating one from the assistant
		shouldUpdateTab = YES;
		return;
	}
	
	NSArray *loadedArray = [[LINVariousPerformer sharedInstance] getLoadedArray];
	
	[[LINVariousPerformer sharedInstance] updateContentsForTab:[mainTabView selectedTabViewItem] loadedArray:loadedArray];
}


-(NSString *)currentFolderPath
{
	NSString *identifier = [[mainTabView selectedTabViewItem] identifier];
	NSString *path;
	if ([identifier isEqual:@"2"]) {
		path = USERSAGENTS;
	} else if ([identifier isEqual:@"3"]) {
		path = USERSDAEMONS;
	} else if ([identifier isEqual:@"4"]) {
		path = SYSTEMAGENTS;
	} else if ([identifier isEqual:@"5"]) {
		path = SYSTEMDAEMONS;
	} else {
		path = MYAGENTS;
	}
	
	return path;
}


-(int)currentFolderPathNumber
{
	NSString *identifier = [[mainTabView selectedTabViewItem] identifier];
	int number;
	if ([identifier isEqual:@"2"]) {
		number = LINUsersAgentsFolder;
	} else if ([identifier isEqual:@"3"]) {
		number = LINUsersDaemonsFolder;
	} else if ([identifier isEqual:@"4"]) {
		number = LINSystemAgentsFolder;
	} else if ([identifier isEqual:@"5"]) {
		number = LINSystemDaemonsFolder;
	} else {
		number = LINMyAgentsFolder;
	}
	
	return number;
}


- (NSWindow *)mainWindow {
    return mainWindow; 
}


- (BOOL)shouldUpdateTab
{
    return shouldUpdateTab;
}


- (void)setShouldUpdateTab:(BOOL)flag
{
    shouldUpdateTab = flag;
}


-(void)checkForUpdate
{	
	if (checkForUpdateTimer) {
		[checkForUpdateTimer invalidate];
		[checkForUpdateTimer release];
		checkForUpdateTimer = nil;
	}
	
	[NSThread detachNewThreadSelector:@selector(checkForUpdateInSeparateThread) toTarget:self withObject:nil];
}


- (void)checkForUpdateInSeparateThread
{
	NSAutoreleasePool *checkUpdatePool = [[NSAutoreleasePool alloc] init];
	SCNetworkConnectionFlags status; 
	BOOL success = SCNetworkCheckReachabilityByName("lingon.sourceforge.net", &status); 
	BOOL connected = success && (status & kSCNetworkFlagsReachable) && !(status & kSCNetworkFlagsConnectionRequired); 
	if (connected) {
		NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://lingon.sourceforge.net/checkForUpdate.plist"]];
		if (dictionary) {
			float thisVersion = THISVERSION;
			float latestVersion = [[dictionary valueForKey:@"latestVersion"] floatValue];
			if (latestVersion > thisVersion) {
				[self performSelectorOnMainThread:@selector(updateInterfaceOnMainThreadAfterCheckForUpdateFoundNewUpdate:) withObject:dictionary waitUntilDone:YES];
			} else {
				[self performSelectorOnMainThread:@selector(updateInterfaceOnMainThreadAfterCheckForUpdateFoundNewUpdate:) withObject:nil waitUntilDone:YES];
			}
		}
	}
	[checkUpdatePool release];
}


- (void)updateInterfaceOnMainThreadAfterCheckForUpdateFoundNewUpdate:(id)sender
{
	if (sender != nil && [sender isKindOfClass:[NSDictionary class]]) {
		int answer = [self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"A newer version (%@) is available. Do you want to download it?", @"A newer version (%@) is available. Do you want to download it? in checkForUpdate"), [sender valueForKey:@"latestVersionString"]] informativeText:@"" defaultButton:NSLocalizedString(@"Download", @"Download-button in checkForUpdate") alternateButton:NSLocalizedString(@"Cancel", @"Cancel-button in checkForUpdate") otherButton:nil];
		if (answer == NSAlertFirstButtonReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender valueForKey:@"url"]]];
		}
	} else {
		if ([[[LINPreferences sharedInstance] preferencesWindow] isVisible] == YES) {
			[[[LINPreferences sharedInstance] noUpdateAvailableTextField] setHidden:NO];
			hideNoUpdateAvailableTextFieldTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(hideNoUpdateAvailableTextField) userInfo:nil repeats:NO] retain];
		}
	}
	
}


-(void)hideNoUpdateAvailableTextField
{
	if (hideNoUpdateAvailableTextFieldTimer) {
		[hideNoUpdateAvailableTextFieldTimer invalidate];
		[hideNoUpdateAvailableTextFieldTimer release];
		hideNoUpdateAvailableTextFieldTimer = nil;
	}
	
	[[[LINPreferences sharedInstance] noUpdateAvailableTextField] setHidden:YES];
}


- (BOOL)tableView:(NSTableView *)theTableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard*)pasteboard
{
	NSArray *typesArray;
	if ([theTableView isEqual:mainTableView]) {
		typesArray = [NSArray arrayWithObjects:NSFilenamesPboardType, LINMovedRowsType, nil];
	} else {
		typesArray = [NSArray arrayWithObjects:NSStringPboardType, LINMovedRowsType, nil];
	}
	
	[pasteboard declareTypes:typesArray owner:self];
    [pasteboard setPropertyList:[NSArray arrayWithObjects:[NSNumber numberWithInt:[self currentFolderPathNumber]], [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"], [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"loaded"], rows, nil] forType:LINMovedRowsType];
	
	if ([theTableView isEqual:mainTableView]) {
		NSString *path = [[self currentFolderPath] stringByAppendingPathComponent:[[[[[LINPlistsController sharedInstance] arrayController] arrangedObjects] objectAtIndex:[[rows objectAtIndex:0] intValue]] valueForKey:@"filename"]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			[pasteboard setPropertyList:[NSArray arrayWithObject:path] forType:NSFilenamesPboardType];
		}
	} else {
		NSArrayController *arrayController = [self arrayControllerForTableView:theTableView];
		if (arrayController == nil) return NO;
		
		NSMutableString *pasteboardString = [NSMutableString string];    
		NSEnumerator *enumerator = [rows objectEnumerator];
		NSNumber *idx;
		int index = 1;
		int count = [rows count];
		while (idx = [enumerator nextObject]) {
			if ([theTableView isEqual:[[LINEditPlistController sharedInstance] programArgumentsTableView]]) {
				[pasteboardString appendString:[[[arrayController arrangedObjects] objectAtIndex:[idx intValue]] valueForKey:@"argument"]];
			} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] environmentVariablesTableView]]) {
				[pasteboardString appendString:[[[arrayController arrangedObjects] objectAtIndex:[idx intValue]] valueForKey:@"key"]];
				[pasteboardString appendString:@":"];
				[pasteboardString appendString:[[[arrayController arrangedObjects] objectAtIndex:[idx intValue]] valueForKey:@"value"]];
			} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] queueDirectoriesTableView]] || [theTableView isEqual:[[LINEditPlistController sharedInstance] watchPathsTableView]]) {
				[pasteboardString appendString:[[[arrayController arrangedObjects] objectAtIndex:[idx intValue]] valueForKey:@"path"]];
			} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] socketsTableView]]) {
				[pasteboardString appendString:[[[arrayController arrangedObjects] objectAtIndex:[idx intValue]] valueForKey:@"socket"]];
			} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] bonjourTableView]]) {
				[pasteboardString appendString:[[[arrayController arrangedObjects] objectAtIndex:[idx intValue]] valueForKey:@"name"]];
			}
			
			if (index < count) {
				[pasteboardString appendString:@" "];
			}
			index++;
		}
		[pasteboard setString:pasteboardString forType:NSStringPboardType];
	}
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView *)theTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	NSDragOperation dragOperation;
    
    if ([info draggingSource] == theTableView) {
		dragOperation =  NSDragOperationMove;
    } else {
		dragOperation = NSDragOperationCopy;
	}
	
    [theTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOperation;
}


- (BOOL)tableView:(NSTableView *)theTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	if (row < 0) {
		row = 0;
	}
    
	NSArrayController *arrayController = [self arrayControllerForTableView:theTableView];
	if (arrayController == nil) return NO;
	[arrayController commitEditing];
	
    if ([info draggingSource] == theTableView) {
		
		NSArray *pasteboardData = [[info draggingPasteboard] propertyListForType:LINMovedRowsType];
		if ([[pasteboardData objectAtIndex:0] intValue] == [self currentFolderPathNumber]) { // If we haven't changed tab through drag and drop
		
			NSArray *rows = [pasteboardData objectAtIndex:3];
			NSIndexSet *indexSet = [self indexSetFromRows:rows];
			[self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row arrayController:arrayController];
			
			int rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
			NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
			indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
			[arrayController setSelectionIndexes:indexSet];
			
		} else { // We have changed tab through drag and drop
			
			NSString *filename = [pasteboardData objectAtIndex:1];
			if ([[pasteboardData objectAtIndex:2] boolValue] != NO) {
				[self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%@ is loaded", @"%@is loaded in dropOnTab"), filename]  informativeText:NSLocalizedString(@"You must unload it to be able to move it", @"You must unload it to be able to move it in dropOnTab") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
				[mainTabView selectTabViewItemAtIndex:([[pasteboardData objectAtIndex:0] intValue] - 1)];
				return NO;
			}
			
			NSString *path = [[self currentFolderPath] stringByAppendingPathComponent:filename];
			int answer = [self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Are you sure that you want to move %@ here", @"Are you sure that you want to move %@ here in dropOnTab"), path]  informativeText:NSLocalizedString(@"There is no undo available", @"There is no undo available in dropOnTab") defaultButton:NSLocalizedString(@"Cancel", @"Cancel-button in dropOnTab") alternateButton:NSLocalizedString(@"Move", @"Move-button in dropOnTab") otherButton:nil];
			if (answer != NSAlertSecondButtonReturn) {
				[mainTabView selectTabViewItemAtIndex:([[pasteboardData objectAtIndex:0] intValue] - 1)];
				return NO;
			}
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
				[self alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The file %@ already exists", @"The file %@ already exists in moveToAction"), path]  informativeText:NSLocalizedString(@"You need to change the filename before you can proceed. You can do this from the File-menu.", @"You need to change the filename before you can proceed. You can do this from the File-menu. in dropOnTab") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
				[mainTabView selectTabViewItemAtIndex:([[pasteboardData objectAtIndex:0] intValue] - 1)];
				return NO;
			}
			
			NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionMove], filename, [NSNumber numberWithInt:[[pasteboardData objectAtIndex:0] intValue]], [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], nil];
			NSArray *keys = [NSArray arrayWithObjects:@"task", @"filename", @"oldFolder", @"toFolder", nil];
			[[LINActionMenuController sharedInstance] prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"move" errorPath:filename];
			
		}
		return YES;
    }
	
	NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (filesToImport && [theTableView isEqual:mainTableView]) {
		[[LINFileMenuController sharedInstance] importAllTheseFiles:filesToImport];
		return YES;
    } else if (filesToImport && [theTableView isEqual:[[LINEditPlistController sharedInstance] queueDirectoriesTableView]] || [theTableView isEqual:[[LINEditPlistController sharedInstance] watchPathsTableView]]) {
		NSEnumerator *enumerator = [filesToImport objectEnumerator];
		id item;
		NSMutableDictionary *path;
		while (item = [enumerator nextObject]) {
			path = [[NSMutableDictionary alloc] init];
			[path setValue:item forKey:@"path"];
			[arrayController insertObject:path atArrangedObjectIndex:row];
			[path release];
		}
		return YES;
	}

	NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
	if (textToImport && ![theTableView isEqual:mainTableView]) {
		
		if ([theTableView isEqual:[[LINEditPlistController sharedInstance] programArgumentsTableView]]) {
			NSArray *splitArray = [[LINAssistant sharedInstance] divideCommandIntoArray:textToImport];
			NSEnumerator *enumerator = [splitArray reverseObjectEnumerator];
			id item;
			while (item = [enumerator nextObject]) {
				NSMutableDictionary *line = [[NSMutableDictionary alloc] init];
				[line setValue:item forKey:@"argument"];
				[arrayController insertObject:line atArrangedObjectIndex:row];
				[line release];
			}			
			
		} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] environmentVariablesTableView]]) {
			NSArray *splitArray = [textToImport componentsSeparatedByString:@":"]; 
			NSMutableDictionary *variable = [[NSMutableDictionary alloc] init];
			[variable setValue:[splitArray objectAtIndex:0] forKey:@"key"];
			if ([splitArray count] > 1) {
				[variable setValue:[splitArray objectAtIndex:1] forKey:@"value"];
			}
			[arrayController insertObject:variable atArrangedObjectIndex:row];
			[variable release];
			
		} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] queueDirectoriesTableView]] || [theTableView isEqual:[[LINEditPlistController sharedInstance] watchPathsTableView]]) {
			NSMutableDictionary *path = [[NSMutableDictionary alloc] init];
			[path setValue:textToImport forKey:@"path"];
			[arrayController insertObject:path atArrangedObjectIndex:row];
			[path release];
			
		} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] socketsTableView]]) {
			NSMutableDictionary *socket = [[NSMutableDictionary alloc] init];
			NSMutableDictionary *socketValues = [[NSMutableDictionary alloc] init];
			[socketValues setValue:textToImport forKey:@"socket"];
			[socket setValue:socketValues forKey:@"socketValues"];
			[socketValues release];
			[arrayController insertObject:socket atArrangedObjectIndex:row];
			[socket release];
			
		} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] bonjourTableView]]) {
			NSMutableDictionary *name = [[NSMutableDictionary alloc] init];
			[name setValue:textToImport forKey:@"name"];
			[arrayController insertObject:name atArrangedObjectIndex:row];
			[name release];
		}
		
		return YES;
    }
	

    return NO;
}


-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet toIndex:(unsigned int)insertIndex arrayController:(NSArrayController *)arrayController
{
    NSArray	*objects = [arrayController arrangedObjects];
	int	index = [indexSet lastIndex];
	
    int	aboveInsertIndexCount = 0;
    id object;
    int removeIndex;
	
    while (NSNotFound != index) {
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		} else {
			removeIndex = index;
			insertIndex -= 1;
		}
		object = [objects objectAtIndex:removeIndex];
		[arrayController removeObjectAtArrangedObjectIndex:removeIndex];
		[arrayController insertObject:object atArrangedObjectIndex:insertIndex];
		
		index = [indexSet indexLessThanIndex:index];
    }
}


- (NSIndexSet *)indexSetFromRows:(NSArray *)rows
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *rowEnumerator = [rows objectEnumerator];
    NSNumber *idx;
    while (idx = [rowEnumerator nextObject]) {
		[indexSet addIndex:[idx intValue]];
    }
    return indexSet;
}


- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet
{
    unsigned currentIndex = [indexSet firstIndex];
    int i = 0;
    while (currentIndex != NSNotFound) {
		if (currentIndex < row) {
			i++;
		}
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
	
    return i;
}


-(NSArrayController *)arrayControllerForTableView:(NSTableView *)theTableView
{
	NSArrayController *arrayController = nil;
	if ([theTableView isEqual:mainTableView]) {
		arrayController = [[LINPlistsController sharedInstance] arrayController];
	} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] programArgumentsTableView]]) {
		arrayController = [[LINEditPlistController sharedInstance] programArgumentsArrayController];
	} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] environmentVariablesTableView]]) {
		arrayController = [[LINEditPlistController sharedInstance] environmentVariablesArrayController];
	} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] queueDirectoriesTableView]]) {
		arrayController = [[LINEditPlistController sharedInstance] queueDirectoriesArrayController];
	} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] watchPathsTableView]]) {
		arrayController = [[LINEditPlistController sharedInstance] watchPathsArrayController];
	} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] socketsTableView]]) {
		arrayController = [[LINEditPlistController sharedInstance] socketsArrayController];
	} else if ([theTableView isEqual:[[LINEditPlistController sharedInstance] bonjourTableView]]) {
		arrayController = [[LINEditPlistController sharedInstance] bonjourArrayController];
	}
	
	return arrayController;
}


- (void)windowDidResize:(NSNotification *)aNotification
{
	[[[LINSecureToolCommunication sharedInstance] authorisationView] display]; // one needs to update this as otherwise the grey background sometimes covers it after a resize
}


-(void)changeFont:(id)sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *panelFont = [fontManager convertFont:[fontManager selectedFont]];
	[defaults setValue:[NSArchiver archivedDataWithRootObject:panelFont] forKey:@"TextFont"];
}

@end
