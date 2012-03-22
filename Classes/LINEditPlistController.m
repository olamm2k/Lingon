/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINEditPlistController.h"
#import "LINMainController.h"
#import "LINViewMenuController.h"
#import "LINPlistsController.h"
#import "LINVariousPerformer.h"
#import "LINSyntaxColouring.h"
#import "LINActionMenuController.h"

@implementation LINEditPlistController

static id sharedInstance = nil;

+ (LINEditPlistController *)sharedInstance
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
		defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
		[self setOldLabel:@""];
    }
    return sharedInstance;
}


-(void)awakeFromNib
{
	isInExpertTabView = NO;
}


- (IBAction)cancelAction:(id)sender
{
	[self closeEditSheet];
	[[LINViewMenuController sharedInstance] refreshAction:nil];
}


-(void)closeEditSheet
{
	[NSApp endSheet:editPlistSheet];
	[editPlistSheet close];
	[[editPlistSheet undoManager] removeAllActions];
}


- (IBAction)justSaveAction:(id)sender
{
	if ([self isExpertTabViewSelected] && ![self updateSelectionFromExpertTextView]) {
		return;
	}
	
	[[[LINPlistsController sharedInstance] arrayController] commitEditing];
	
	if (![self checkThatRequiredFieldsAreSet]) {
		return;
	}
	
	BOOL newPlist = NO;
	
	NSMutableDictionary *selectedDictionary = [[[[LINPlistsController sharedInstance] arrayController] selectedObjects] objectAtIndex:0];
	if (![selectedDictionary valueForKey:@"filename"] || [[selectedDictionary valueForKey:@"filename"] isEqual:@""]) {
		[selectedDictionary setValue:[[selectedDictionary valueForKey:@"Label"] stringByAppendingPathExtension:@"plist"] forKey:@"filename"];
		newPlist = YES;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:[[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[selectedDictionary valueForKey:@"filename"]]]) {
			[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The file %@ already exists", @"The file %@ already exists in justSaveAction"), [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[selectedDictionary valueForKey:@"filename"]]]  informativeText:NSLocalizedString(@"Please choose another label", @"Please choose another label in justSaveAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
			[selectedDictionary removeObjectForKey:@"filename"];
			return;
		}
	}

	NSString *filename = [selectedDictionary valueForKey:@"filename"];
	
	NSDictionary *dictionary = [[LINVariousPerformer sharedInstance] convertPartsOfDictionaryBeforePlist:selectedDictionary];
	
	[[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:[[LINMainController sharedInstance] currentFolderPathNumber] filename:filename action:LINAfterSaveNothing];
	
	[self closeEditSheet];
	
	if (newPlist) {
		[[LINVariousPerformer sharedInstance] selectLabel:[dictionary valueForKey:@"Label"]];
	}
}


- (IBAction)saveAndLoadReloadAction:(id)sender
{
	if ([self isExpertTabViewSelected] && ![self updateSelectionFromExpertTextView]) {
		return;
	}
	
	[[[LINPlistsController sharedInstance] arrayController] commitEditing];
	
	if (![self checkThatRequiredFieldsAreSet]) {
		return;
	}
	
	BOOL newPlist = NO;
	
	NSMutableDictionary *selectedDictionary = [[[[LINPlistsController sharedInstance] arrayController] selectedObjects] objectAtIndex:0];
	if (![selectedDictionary valueForKey:@"filename"] || [[selectedDictionary valueForKey:@"filename"] isEqual:@""]) {
		[selectedDictionary setValue:[[selectedDictionary valueForKey:@"Label"] stringByAppendingPathExtension:@"plist"] forKey:@"filename"];
		newPlist = YES;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:[[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[selectedDictionary valueForKey:@"filename"]]]) {
			[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The file %@ already exists", @"The file %@ already exists in saveAndLoadReloadAction"), [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[selectedDictionary valueForKey:@"filename"]]]  informativeText:NSLocalizedString(@"Please choose another label", @"Please choose another label in saveAndLoadReloadAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
			[selectedDictionary removeObjectForKey:@"filename"];
			return;
		}
	}

	NSString *filename = [selectedDictionary valueForKey:@"filename"];
	
	NSDictionary *dictionary = [[LINVariousPerformer sharedInstance] convertPartsOfDictionaryBeforePlist:selectedDictionary];

	int action;
	if ([[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"loaded"] && [[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"loaded"] boolValue]) {
		action = LINAfterSaveReload;
	} else {
		action = LINAfterSaveLoad;
	}
	
	if (![[self oldLabel] isEqual:[dictionary valueForKey:@"Label"]] && !newPlist) { // If the label has changed we should unload the old label and then load instead of reloading the dictionary with the new label
		
		NSString *path = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:filename];
		
		if (![[LINMainController sharedInstance] needSecureTool]) {
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"unload", @"-w", [NSString stringWithUTF8String:[path UTF8String]], nil]];			
		} else {
			NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionUnload], filename, [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], [NSNumber numberWithBool:NO], nil];
			NSArray *keys = [NSArray arrayWithObjects:@"task", @"filename", @"folder", @"optionKeyDown", nil];
			[[LINActionMenuController sharedInstance] prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"unload" errorPath:path];
		}
		
		action = LINAfterSaveLoad;
	}
	
	
	[[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:[[LINMainController sharedInstance] currentFolderPathNumber] filename:filename action:action];
	
	[self closeEditSheet];
	
	if (newPlist) {
		[[LINVariousPerformer sharedInstance] selectLabel:[dictionary valueForKey:@"Label"]];
	}
}


- (NSTableView *)bonjourTableView
{
    return bonjourTableView; 
}


- (NSTableView *)programArgumentsTableView
{
    return programArgumentsTableView; 
}


- (NSTableView *)queueDirectoriesTableView
{
    return queueDirectoriesTableView; 
}


- (NSTableView *)socketsTableView
{
    return socketsTableView; 
}


- (NSTableView *)watchPathsTableView
{
    return watchPathsTableView; 
}


- (NSTableView *)environmentVariablesTableView
{
    return environmentVariablesTableView; 
}


-(IBAction)setPathAction:(id)sender
{
	int tag = [sender tag];
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	
	@try { // Unpublished calls...
		if ([openPanel respondsToSelector:@selector(_navView)]) {
			id navView = [openPanel performSelector:@selector(_navView)];
			if ([navView respondsToSelector:@selector(setShowsHiddenFiles:)]) {
				[openPanel performSelector:@selector(setShowsHiddenFiles:) withObject:[NSNumber numberWithBool:YES]];
			}
		}
	} @catch (NSException * e) {
	} @finally {
	}
	
	NSString *directory;
	
	if (tag == 1) { // WatchPaths
		directory = [[watchPathsArrayController selection] valueForKey:@"path"];
	} else if (tag == 2) { // QueueDirectories
		directory = [[queueDirectoriesArrayController selection] valueForKey:@"path"];
	} else if (tag == 3) { // RootDirectory
		directory = [rootDirectoryTextField stringValue];
	} else if (tag == 4) { // WorkingDirectory
		directory = [workingDirectoryTextField stringValue];
	} else if (tag == 5) { // StandardOutPath
		directory = [standardOutPathTextField stringValue];
	} else if (tag == 6) { // StandardErrorPath
		directory = [standardErrorPathTextField stringValue];
	}
	
	if (!directory || [directory isEqual:@""]) {
		directory = [defaults valueForKey:@"LastDirectory"];
	}
		
	int answer = [openPanel runModalForDirectory:directory file:nil types:nil];
	
	if (answer != NSOKButton) return;
	
	NSString *path = [[openPanel filenames] objectAtIndex:0];
	[defaults setValue:[path stringByDeletingLastPathComponent] forKey:@"LastDirectory"];
	
	if (tag == 1) { // WatchPaths
		[[watchPathsArrayController selection] setValue:path forKey:@"path"];
		[watchPathsArrayController rearrangeObjects];
		[watchPathsTableView reloadData];
	} else if (tag == 2) { // QueueDirectories
		[[queueDirectoriesArrayController selection] setValue:path forKey:@"path"];	
		[queueDirectoriesArrayController rearrangeObjects];
		[queueDirectoriesTableView reloadData];
	} else if (tag == 3) { // RootDirectory
		[rootDirectoryTextField setStringValue:path];
	} else if (tag == 4) { // WorkingDirectory
		[workingDirectoryTextField setStringValue:path];
	} else if (tag == 5) { // StandardOutPath
		[standardOutPathTextField setStringValue:path];
	} else if (tag == 6) { // StandardErrorPath
		[standardErrorPathTextField setStringValue:path];
	} 
}


-(void)setTitleForSaveAndLoadReloadButton
{
	if ([[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"loaded"] && [[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"loaded"] boolValue]) {
		[saveAndLoadReload setTitle:NSLocalizedString(@"Save & Reload", @"Save & Reload-button in edit-sheet")];
	} else {
		[saveAndLoadReload setTitle:NSLocalizedString(@"Save & Load", @"Save & Load-button in edit-sheet")];
	}
}


-(BOOL)checkThatRequiredFieldsAreSet
{
	if (![[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Label"] || (![[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Program"] && [[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"ProgramArguments"] count] == 0)) {
		[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"Not all required fields are set", @"Not all required fields are set in Plist edit") informativeText:NSLocalizedString(@"You need to make sure that at least Label and either ProgramArguments or Program are set", @"You need to make sure that at least Label and either ProgramArguments or Program are set in Plist edit") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return NO;
	} else {
		return YES;
	}	
}


-(NSString *)plistStringFromDictionary:(NSDictionary *)dictionary
{
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:dictionary format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
	NSString *returnString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	
	return [returnString autorelease];
}


- (IBAction)validateAction:(id)sender
{
	if ([self validateStringAsPlist:[expertTextView string]]) {
		[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"It looks all right!", @"It looks all right in Validate plist in Expert textView") informativeText:NSLocalizedString(@"But please note that this only means that it validates as a plist and not necessarily that all correct elements are set for it to work as a launchd, but I trust that you are an expert:-)", @"But please note that this only means that it validates as a plist and not necessarily that all correct elements are set for it to work as a launchd, but I trust that you are an expert:-) Validate plist in Expert textView") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
	} else {
		[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"It does NOT validate", @"It does NOT validate in Validate plist in Expert textView") informativeText:@"" defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
	}
	
}


-(BOOL)validateStringAsPlist:(NSString *)string
{
	BOOL validates = YES;
	NS_DURING
		[string propertyList];
	NS_HANDLER
		if ([[localException name] isEqualToString:NSParseErrorException]) {
			validates = NO;
		} else {
			[localException raise];
		}
	NS_ENDHANDLER
		
	return validates;
}


- (NSTextView *)expertTextView
{
    return expertTextView; 
}


- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	BOOL shouldSelect = YES;
	NSString *identifier = [tabViewItem identifier];
	if ([identifier isEqual:@"6"]) {
		[self updateExpertTextView];
		isInExpertTabView = YES;
	} else {
		if (isInExpertTabView) {
			if (![self updateSelectionFromExpertTextView]) {
				shouldSelect = NO;
			}
		}
		if (shouldSelect) {
			isInExpertTabView = NO;
			[[editPlistSheet undoManager] removeAllActions];
		}
	}
	
	return shouldSelect;
}


-(void)updateExpertTextView
{
	[[[LINPlistsController sharedInstance] arrayController] commitEditing];
	
	NSDictionary *dictionary = [[LINVariousPerformer sharedInstance] convertPartsOfDictionaryBeforePlist:[[[[LINPlistsController sharedInstance] arrayController] selectedObjects] objectAtIndex:0]];
	
	NSString *plist = [self plistStringFromDictionary:dictionary];
	if (!plist) {
		[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"Could not generate the plist", @"Could not generate the plist in Put plist in Expert textView") informativeText:@"" defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
	} else {
		[expertTextView setString:plist];
		[[LINSyntaxColouring sharedInstance] recolourCompleteDocument];
	}
}


-(BOOL)isExpertTabViewSelected
{
	if ([[[editTabView selectedTabViewItem] identifier] isEqual:@"6"]) {
		return YES;
	} else {
		return NO;
	}
}


-(BOOL)updateSelectionFromExpertTextView
{
	if (![self validateStringAsPlist:[expertTextView string]]) {
		[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"It does NOT validate as a plist", @"It does NOT validate as a plist in Validate plist in Expert textView") informativeText:NSLocalizedString(@"You cannot do anything else until it validates", @"You cannot do anything else until it validates in Validate plist in Expert textView") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return NO;
	}
	
	NSData *plistData = [[expertTextView string] dataUsingEncoding:NSUTF8StringEncoding];
	NSPropertyListFormat format;
	id plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:nil];
	
	// First remove all the keys from the selected dictionary that can be set by the user (but keep the filename, loaded etc.) and then insert the new values from the expert textView. Otherwise if you remove a whole key in the textView it will still remain in the dictionary when you switch to another tab or save it.
	NSDictionary *dictionary = [[NSDictionary alloc] initWithDictionary:[[LINVariousPerformer sharedInstance] convertDictionary:(NSDictionary *)plist]];
	
	NSMutableDictionary *selectedDictionary = [[[[LINPlistsController sharedInstance] arrayController] selectedObjects] objectAtIndex:0];
	NSEnumerator *enumerator = [[selectedDictionary allKeys] objectEnumerator];
	id item;
	while (item = [enumerator nextObject]) {
		if (![item isEqual:@"filename"] && ![item isEqual:@"loaded"] && ![item isEqual:@"loadedImagePath"]) {
			[selectedDictionary removeObjectForKey:item];

		}
	}
	
	enumerator = [dictionary keyEnumerator];
	while (item = [enumerator nextObject]) {
		[selectedDictionary setValue:[dictionary valueForKey:item] forKey:item];
	}
	
	[[LINActionMenuController sharedInstance] insertDefaultDictionariesIntoSelection];
	
	[dictionary release];
	
	return YES;
}


-(IBAction)insertAction:(id)sender
{
	int tag = [sender tag];
	int index;
	id object;

	if (tag == 1) {
		[programArgumentsArrayController commitEditing];
		index = [programArgumentsTableView selectedRow] + 1;
		object = [programArgumentsArrayController newObject];
		[programArgumentsArrayController insertObject:object atArrangedObjectIndex:index];
		[editPlistSheet makeFirstResponder:programArgumentsTableView];
		[programArgumentsTableView editColumn:0 row:index withEvent:nil select:NO];
		[object release];
	} else if (tag == 2) {
		[environmentVariablesArrayController commitEditing];
		index = [environmentVariablesTableView selectedRow] + 1;
		object = [environmentVariablesArrayController newObject];
		[environmentVariablesArrayController insertObject:object atArrangedObjectIndex:index];
		[editPlistSheet makeFirstResponder:environmentVariablesTableView];
		[environmentVariablesTableView editColumn:0 row:index withEvent:nil select:NO];
		[object release];
	} else if (tag == 3) {
		[watchPathsArrayController commitEditing];
		index = [watchPathsTableView selectedRow] + 1;
		object = [watchPathsArrayController newObject];
		[watchPathsArrayController insertObject:object atArrangedObjectIndex:index];
		[editPlistSheet makeFirstResponder:watchPathsTableView];
		[watchPathsTableView editColumn:0 row:index withEvent:nil select:NO];
		[object release];
	} else if (tag == 4) {
		[queueDirectoriesArrayController commitEditing];
		index = [queueDirectoriesTableView selectedRow] + 1;
		object = [queueDirectoriesArrayController newObject];
		[queueDirectoriesArrayController insertObject:object atArrangedObjectIndex:index];
		[editPlistSheet makeFirstResponder:queueDirectoriesTableView];
		[queueDirectoriesTableView editColumn:0 row:index withEvent:nil select:NO];
		[object release];
	} else if (tag == 5) {
		// One needs to do it like this otherwise there is no dictionary to put the settings for every socket into
		NSMutableDictionary *socket = [[NSMutableDictionary alloc] init];
		NSMutableDictionary *socketValues = [[NSMutableDictionary alloc] init];
		[socket setValue:socketValues forKey:@"socketValues"];
		[socketValues release];

		[socketsArrayController commitEditing];
		index = [socketsTableView selectedRow] + 1;
		[socketsArrayController insertObject:socket atArrangedObjectIndex:index];
		[editPlistSheet makeFirstResponder:socketsTableView];
		[socketsTableView editColumn:0 row:index withEvent:nil select:NO];
		[socket release];
	} else if (tag == 6) {
		[bonjourArrayController commitEditing];
		index = [bonjourTableView selectedRow] + 1;
		object = [bonjourArrayController newObject];
		[bonjourArrayController insertObject:object atArrangedObjectIndex:index];
		[editPlistSheet makeFirstResponder:bonjourTableView];
		[bonjourTableView editColumn:0 row:index withEvent:nil select:NO];
		[object release];
	} 

}


- (NSWindow *)editPlistSheet
{
    return editPlistSheet; 
}


- (NSArrayController *)programArgumentsArrayController
{
    return programArgumentsArrayController; 
}


- (NSArrayController *)environmentVariablesArrayController
{
    return environmentVariablesArrayController; 
}


- (NSArrayController *)watchPathsArrayController
{
    return watchPathsArrayController; 
}


- (NSArrayController *)queueDirectoriesArrayController
{
    return queueDirectoriesArrayController; 
}


- (NSArrayController *)socketsArrayController
{
    return socketsArrayController; 
}


- (NSArrayController *)bonjourArrayController
{
    return bonjourArrayController; 
}


- (NSTabView *)editTabView
{
    return editTabView; 
}


- (NSString *)oldLabel
{
    return oldLabel; 
}

- (void)setOldLabel:(NSString *)newOldLabel
{
    [newOldLabel retain];
    [oldLabel release];
    oldLabel = newOldLabel;
}
@end
