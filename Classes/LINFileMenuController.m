/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINFileMenuController.h"
#import "LINMainController.h"
#import "LINPlistsController.h"
#import "LINVariousPerformer.h"
#import "LINActionMenuController.h"
#import "LINAssistant.h"
#import "LINSecureToolCommunication.h"

@implementation LINFileMenuController

static id sharedInstance = nil;

+ (LINFileMenuController *)sharedInstance
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
    }
    return sharedInstance;
}


- (IBAction)assistantAction:(id)sender
{
	[[LINAssistant sharedInstance] openAssistant];
}


- (IBAction)exportAction:(id)sender
{
	NSDictionary *dictionary = [[LINVariousPerformer sharedInstance] convertPartsOfDictionaryBeforePlist:[[[[LINPlistsController sharedInstance] arrayController] selectedObjects] objectAtIndex:0]];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	int answer = [savePanel runModalForDirectory:[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] file:[[dictionary valueForKey:@"Label"] stringByAppendingPathExtension:@"plist"]];
	if (answer != NSFileHandlingPanelOKButton) return;
		
	NSString *path = [savePanel filename];
	
	if (![dictionary writeToFile:path atomically:YES]) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Could not save the file to %@", @"Could not save the file to %@ in exportAction"), path] informativeText:@"" defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
	}
}


- (IBAction)importAction:(id)sender
{
	[[LINMainController sharedInstance] setShouldUpdateTab:NO];
	int selectedTab = [[[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] identifier] intValue];
	[whichFolderMatrix selectCellAtRow:(selectedTab - 1) column:0];
	[createImport setTitle:[NSString stringWithFormat:NSLocalizedString(@"Choose%C", @"Choose%C-button in importAction"), 0x2026]];
	[createImport setTag:1];
	[NSApp beginSheet:whichFolderSheet modalForWindow:[[LINMainController sharedInstance] mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (IBAction)newAction:(id)sender
{
	int selectedTab = [[[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] identifier] intValue];
	[whichFolderMatrix selectCellAtRow:(selectedTab - 1) column:0];
	[createImport setTitle:NSLocalizedString(@"Create", @"Create-button in newAction")];
	[createImport setTag:0];
	[NSApp beginSheet:whichFolderSheet modalForWindow:[[LINMainController sharedInstance] mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([[[LINMainController sharedInstance] mainWindow] attachedSheet]) {
		return NO;
	}
	
	BOOL enableMenuItem = YES;
	if ([anItem tag] == 4 || [anItem tag] == 5 || [anItem tag] == 6 || [anItem tag] == 7) { // Export, Delete, Change Filename, Open In External Editor
		if ([[[[LINPlistsController sharedInstance] arrayController] selectedObjects] count] == 0) {
			enableMenuItem = NO;
		}
	} 
	
	return enableMenuItem;
}


- (IBAction)createImportAction:(id)sender
{
	[self closeWhichFolder];
	
	int tag = [sender tag];
	if (tag == 0) { // New
		[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:[whichFolderMatrix selectedRow]];
		NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];		
		
		[[[LINPlistsController sharedInstance] arrayController] addObject:dictionary];
		[dictionary release];
		[[[LINPlistsController sharedInstance] arrayController] rearrangeObjects];
		[[LINActionMenuController sharedInstance] editAction:nil];
		
	} else if (tag == 1) { // Import
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setResolvesAliases:YES];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setCanChooseDirectories:NO];
		[openPanel setCanChooseFiles:YES];
	
		int answer = [openPanel runModalForDirectory:[defaults valueForKey:@"LastDirectory"] file:nil types:nil];
		if (answer != NSOKButton) {
			[[LINMainController sharedInstance] setShouldUpdateTab:YES];
			return;
		}
		
		[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:[whichFolderMatrix selectedRow]];
		NSString *path = [[openPanel filenames] objectAtIndex:0];
		[defaults setValue:[path stringByDeletingLastPathComponent] forKey:@"LastDirectory"];
		
		[self performImportForPath:path];
	}
	
}


-(void)performImportForPath:(NSString *)path
{
	NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
	if (!dictionary) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%@ is not a valid plist file", @"%@ is not a valid plist file in performImportForPath"), path] informativeText:NSLocalizedString(@"You need to choose another file", @"You need to choose another file in performImportForPath") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return;
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[path lastPathComponent]]]) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The file %@ already exists", @"The file %@ already exists in performImportForPath"), [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[path lastPathComponent]]]  informativeText:NSLocalizedString(@"Please change the name of the file that you are importing", @"Please change the name of the file that you are importing in performImportForPath") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return;
	}
	
	[[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:[[LINMainController sharedInstance] currentFolderPathNumber] filename:[path lastPathComponent] action:LINAfterSaveLoad];
	
	if ([dictionary valueForKey:@"Label"]) {
		[[LINVariousPerformer sharedInstance] selectLabel:[dictionary valueForKey:@"Label"]];
	}
	[dictionary release];
	
}


- (IBAction)whichFolderCancelAction:(id)sender
{
	[[LINMainController sharedInstance] setShouldUpdateTab:YES];
	[self closeWhichFolder];
}


-(void)closeWhichFolder
{
	[NSApp endSheet:whichFolderSheet];
	[whichFolderSheet close];
}


- (NSWindow *)whichFolderSheet
{
    return whichFolderSheet; 
}


-(void)importAllTheseFiles:(NSArray *)filesToImport
{
	NSEnumerator *enumerator = [filesToImport objectEnumerator];
	id item;
	while (item = [enumerator nextObject]) {
		[self performImportForPath:item];
	}
}


- (IBAction)deleteAction:(id)sender
{
	id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
	if ([selection valueForKey:@"loaded"] && [[selection valueForKey:@"loaded"] boolValue] != NO) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%@ is loaded", @"%@is loaded in deleteAction"), [selection valueForKey:@"Label"]]  informativeText:NSLocalizedString(@"You must unload it to be able to delete it", @"You must unload it to be able to delete it in deleteAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return;
	}

	int answer = [[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Are you sure that you want to delete %@", @"Are you sure that you want to delete %@ in deleteAction"), [selection valueForKey:@"Label"]]  informativeText:NSLocalizedString(@"There is no undo available", @"There is no undo available in deleteAction") defaultButton:NSLocalizedString(@"Cancel", @"Cancel-button in deleteAction") alternateButton:NSLocalizedString(@"Delete", @"Delete-button in deleteAction") otherButton:nil];
	if (answer != NSAlertSecondButtonReturn) {
		return;
	}

	
	NSString *path = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[selection valueForKey:@"filename"]];
	
	if (![[LINMainController sharedInstance] needSecureTool]) {
		if ([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) { 
			[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
		} else {
			[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"An unknown error occurred when deleting the file %@", @"An unknown error occurred when deleting the file %@ in deleteAction"), path]  informativeText:NSLocalizedString(@"Please try again", @"Please try again in deleteAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		}
	} else {
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionDelete], [selection valueForKey:@"filename"], [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"filename", @"folder", nil];
		[[LINActionMenuController sharedInstance] prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"delete" errorPath:path];
	}
}


- (IBAction)changeFilenameAction:(id)sender
{
	[changeFilenameFolderTextField setStringValue:[[LINMainController sharedInstance] currentFolderPath]];
	NSString *oldName = [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"];
	[changeFilenameOldNameTextField setStringValue:oldName];
	[changeFilenameNewNameTextField setStringValue:oldName];
	
	[NSApp beginSheet:changeFilenameSheet modalForWindow:[[LINMainController sharedInstance] mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	[changeFilenameNewNameTextField selectText:nil];
}


- (IBAction)changeFilenameCancelAction:(id)sender
{
	[self closeChangeFilename];
}


- (IBAction)performChangeFilenameAction:(id)sender
{
	NSString *newName = [changeFilenameNewNameTextField stringValue];
	if ([newName isEqual:@""]) {
		[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"You must supply a new name", @"You must supply a new name in performChangeFilenameAction") informativeText:NSLocalizedString(@"Please write the new name that you want to give the file", @"Please write the new name that you want to give the file in performChangeFilenameAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return;
	}
	
	NSString *newPath = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:newName];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:newPath]) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The file %@ already exists", @"The file %@ already exists in performChangeFilenameAction"), newPath]  informativeText:NSLocalizedString(@"Please try another name", @"Please try another name in performChangeFilenameAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return;
	}
	
	NSString *oldName = [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"];
	NSString *oldPath = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:oldName];
	
	if (![[LINMainController sharedInstance] needSecureTool]) {
		if ([fileManager movePath:oldPath toPath:newPath handler:nil]) { 
			[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
		} else {
			[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"An unknown error occurred when changing the name to %@", @"An unknown error occurred when changing the name to %@ in performChangeFilenameAction"), newPath]  informativeText:NSLocalizedString(@"Please try again", @"Please try again in performChangeFilenameAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		}
	} else {
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionChangeName], oldName, newName, [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"oldName", @"newName", @"folder", nil];
		[[LINActionMenuController sharedInstance] prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"change the name" errorPath:oldPath];
	}
	
	[self closeChangeFilename];
}


-(void)closeChangeFilename
{
	[NSApp endSheet:changeFilenameSheet];
	[changeFilenameSheet close];
}


-(IBAction)openInExternalEditorAction:(id)sender
{
	id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
	NSString *path = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[selection valueForKey:@"filename"]];
	[[NSWorkspace sharedWorkspace] openFile:path withApplication:[defaults valueForKey:@"ExternalEditor"]]; 
}


- (NSWindow *)changeFilenameSheet
{
	return changeFilenameSheet;
}
@end
