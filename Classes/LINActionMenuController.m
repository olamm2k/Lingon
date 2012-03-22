/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINActionMenuController.h"
#import "LINMainController.h"
#import "LINPlistsController.h"
#import "LINVariousPerformer.h"
#import "LINSecureToolCommunication.h"
#import "LINEditPlistController.h"
#import "LINAssistant.h"

#import <Carbon/Carbon.h>

@implementation LINActionMenuController

static id sharedInstance = nil;

+ (LINActionMenuController *)sharedInstance
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


- (IBAction)loadAction:(id)sender
{	
	BOOL optionKeyDown = ((GetCurrentKeyModifiers() & (optionKey | rightOptionKey)) != 0) ? YES : NO;
	NSString *path = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"]];
	NSString *convertedPath = [NSString stringWithUTF8String:[path UTF8String]];
	
	if (![[LINMainController sharedInstance] needSecureTool]) {
		if (optionKeyDown) {
			if (![self checkIfCanBeLoaded]) {
				return;
			}
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load", convertedPath, nil]];
		} else {
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load", @"-w", convertedPath, nil]];
		}
		[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
		
	} else {
		if (![self checkIfCanBeLoaded]) {
			return;
		}
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionLoad], [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"], [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], [NSNumber numberWithBool:optionKeyDown], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"filename", @"folder", @"optionKeyDown", nil];
		[self prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"load" errorPath:path];
	}
}


- (IBAction)unloadAction:(id)sender
{
	BOOL optionKeyDown = ((GetCurrentKeyModifiers() & (optionKey | rightOptionKey)) != 0) ? YES : NO;
	NSString *path = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"]];
	NSString *convertedPath = [NSString stringWithUTF8String:[path UTF8String]];
	
	if (![[LINMainController sharedInstance] needSecureTool]) {
		if (optionKeyDown) {
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"unload", convertedPath, nil]];
		} else {
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"unload", @"-w", convertedPath, nil]];
		}
		[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
		
	} else {
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionUnload], [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"], [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], [NSNumber numberWithBool:optionKeyDown], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"filename", @"folder", @"optionKeyDown", nil];
		[self prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"unload" errorPath:path];
	}
}


- (IBAction)reloadAction:(id)sender
{
	BOOL optionKeyDown = ((GetCurrentKeyModifiers() & (optionKey | rightOptionKey)) != 0) ? YES : NO;
	NSString *path = [[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"]];
	NSString *convertedPath = [NSString stringWithUTF8String:[path UTF8String]];
	
	if (![[LINMainController sharedInstance] needSecureTool]) {
		if (optionKeyDown) {
			if (![self checkIfCanBeLoaded]) {
				return;
			}
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"unload", convertedPath, nil]];
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load", convertedPath, nil]];
		} else {
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"unload", @"-w", convertedPath, nil]];
			[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load", @"-w", convertedPath, nil]];
		}
		
		[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
		
	} else {
		if (![self checkIfCanBeLoaded]) {
			return;
		}
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionReload], [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"filename"], [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], [NSNumber numberWithBool:optionKeyDown], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"filename", @"folder", @"optionKeyDown", nil];
		[self prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"reload" errorPath:path];
	}
}


- (IBAction)startAction:(id)sender
{
	if (![[LINMainController sharedInstance] needSecureTool]) {
		[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"start", [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Label"], nil]];
		[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
		
	} else {
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionStart], [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Label"], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"label", nil];
		[self prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"start" errorPath:[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Label"]];
	}
}


- (IBAction)stopAction:(id)sender
{
	if (![[LINMainController sharedInstance] needSecureTool]) {
		[[LINVariousPerformer sharedInstance] performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"stop", [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Label"], nil]];
		[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[LINVariousPerformer sharedInstance] getLoadedArray]];
		
	} else {
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionStop], [[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Label"], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"label", nil];
		[self prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"stop" errorPath:[[[[LINPlistsController sharedInstance] arrayController] selection] valueForKey:@"Label"]];
	}
}


-(BOOL)checkIfCanBeLoaded
{
	BOOL optionKeyDown = ((GetCurrentKeyModifiers() & (optionKey | rightOptionKey)) != 0) ? YES : NO;

	if (optionKeyDown) {
		id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
		if ([selection valueForKey:@"Disabled"] && [[selection valueForKey:@"Disabled"] boolValue]) {
			[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"You cannot load %@ because it is disabled and you need to release the Option key if you want to override this setting", @"You cannot load %@ because it is disabled and you need to release the Option key if you want to override this setting in release the Option key if you want to load a disabled item"), [selection valueForKey:@"Label"]] informativeText:@"" defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
			return NO;
		}
	}
	
	return YES;
}


- (IBAction)editAction:(id)sender
{
	[self insertDefaultDictionariesIntoSelection];

	id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
	[[LINEditPlistController sharedInstance] setOldLabel:[selection valueForKey:@"Label"]];	
		
	[[LINEditPlistController sharedInstance] setTitleForSaveAndLoadReloadButton];
	if ([[LINEditPlistController sharedInstance] isExpertTabViewSelected]) {
		[[LINEditPlistController sharedInstance] updateExpertTextView];
		if ([[[[LINEditPlistController sharedInstance] expertTextView] superview] isKindOfClass:[NSClipView class]]) {
			[(NSClipView *)[[[LINEditPlistController sharedInstance] expertTextView] superview] scrollToPoint:NSMakePoint(0, 0)];
		}
	}
	[NSApp beginSheet:[[LINEditPlistController sharedInstance] editPlistSheet] modalForWindow:[[LINMainController sharedInstance] mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([[[LINMainController sharedInstance] mainWindow] attachedSheet]) {
		return NO;
	}
	
	BOOL enableMenuItem = YES;
	BOOL aPlistIsSelected = [[[[LINPlistsController sharedInstance] arrayController] selectedObjects] count];
	if (!aPlistIsSelected) return NO;
	
	id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
	if ([anItem tag] == 2 || [anItem tag] == 22) { // Load, Load But Don't Enable
	if ([selection valueForKey:@"loaded"] && [[selection valueForKey:@"loaded"] boolValue]) {
			enableMenuItem = NO;
		}
	} else if ([anItem tag] == 3 || [anItem tag] == 33 || [anItem tag] == 4 || [anItem tag] == 44 || [anItem tag] == 5 || [anItem tag] == 6) { // Unload, Unload But Don't Disable, Reload, Reload But Don't Enable, Start, Stop
		if ([selection valueForKey:@"loaded"] && ![[selection valueForKey:@"loaded"] boolValue]) {
			enableMenuItem = NO;
		}
	} else if ([anItem tag] == ([[[LINMainController sharedInstance] mainTabView] indexOfTabViewItem:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem]] + 11)) { // The selected tab
			enableMenuItem = NO;
	}
	
	return enableMenuItem;
}


- (IBAction)moveToAction:(id)sender
{
	id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
	if ([selection valueForKey:@"loaded"] && [[selection valueForKey:@"loaded"] boolValue] != NO) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%@ is loaded", @"%@is loaded in moveToAction"), [selection valueForKey:@"Label"]]  informativeText:NSLocalizedString(@"You must unload it to be able to move it", @"You must unload it to be able to move it in moveToAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return;
	}
	
	int toFolder;
	NSString *toFolderString;
	NSString *toFolderPath;
	if ([sender tag] == 12) {
		toFolder = LINUsersAgentsFolder;
		toFolderPath = USERSAGENTS;
		toFolderString = USERSAGENTSSTRING;
	} else if ([sender tag] == 13) {
		toFolder = LINUsersDaemonsFolder;
		toFolderPath = USERSDAEMONS;
		toFolderString = USERSDAEMONSSTRING;
	} else if ([sender tag] == 14) {
		toFolder = LINSystemAgentsFolder;
		toFolderPath = USERSAGENTS;
		toFolderString = SYSTEMAGENTSSTRING;
	} else if ([sender tag] == 15) {
		toFolder = LINSystemDaemonsFolder;
		toFolderPath = SYSTEMDAEMONS;
		toFolderString = SYSTEMDAEMONSSTRING;
	} else {
		toFolder = LINMyAgentsFolder;
		toFolderPath = MYAGENTS;
		toFolderString = MYAGENTSSTRING;
	}
	
	int answer = [[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Are you sure that you want to move %@ to %@", @"Are you sure that you want to move %@ to %@ in moveToAction"), [selection valueForKey:@"Label"], toFolderString]  informativeText:NSLocalizedString(@"There is no undo available", @"There is no undo available in deleteAction") defaultButton:NSLocalizedString(@"Cancel", @"Cancel-button in moveToAction") alternateButton:NSLocalizedString(@"Move", @"Move-button in moveToAction") otherButton:nil];
	if (answer != NSAlertSecondButtonReturn) {
		return;
	}
	
	NSString *newPath = [toFolderPath stringByAppendingPathComponent:[selection valueForKey:@"filename"]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The file %@ already exists in %@", @"The file %@ already exists in %@ in moveToAction"), [selection valueForKey:@"filename"], toFolderString]  informativeText:NSLocalizedString(@"You need to change the filename before you can proceed. You can do this from the File-menu.", @"You need to change the filename before you can proceed. You can do this from the File-menu. in moveToAction") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return;
	}
	
	NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionMove], [selection valueForKey:@"filename"], [NSNumber numberWithInt:[[LINMainController sharedInstance] currentFolderPathNumber]], [NSNumber numberWithInt:toFolder], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"task", @"filename", @"oldFolder", @"toFolder", nil];
	[self prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"move" errorPath:[[[LINMainController sharedInstance] currentFolderPath] stringByAppendingPathComponent:[selection valueForKey:@"filename"]]];
	
	[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:(toFolder - 1)];
}


-(void)prepareAndRunAuthenticatedCommand:(NSArray *)objects keys:(NSArray *)keys errorString:(NSString *)errorString errorPath:(NSString *)path
{
	NSDictionary *commandDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	NSDictionary *returnDictionary = [[LINSecureToolCommunication sharedInstance] performCommandAuthenticated:commandDictionary];
	if (![[LINSecureToolCommunication sharedInstance] hasAuthenticated:returnDictionary]) {
		return;
	}
	if ([[LINSecureToolCommunication sharedInstance] hasError:returnDictionary]) {
		[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"An unknown error occurred when trying to %@ %@", @"An unknown error occurred when trying to %@ %@ in prepareAndRunCommand"), errorString, path]  informativeText:NSLocalizedString(@"Please try again", @"Please try again in prepareAndRunCommand") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
	}
	[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[[returnDictionary valueForKey:@"loaded"] componentsSeparatedByString:@"\n"]];
}


-(void)insertDefaultDictionariesIntoSelection
{
	id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
	if (![selection valueForKey:@"StartCalendarInterval"]) {
		NSMutableDictionary *startCalendarInterval = [[NSMutableDictionary alloc] init];
		[selection setValue:startCalendarInterval forKey:@"StartCalendarInterval"];
		[startCalendarInterval release];
	}
	
	if (![selection valueForKey:@"SoftResourceLimits"]) {
		NSMutableDictionary *softResourceLimits = [[NSMutableDictionary alloc] init];
		[selection setValue:softResourceLimits forKey:@"SoftResourceLimits"];
		[softResourceLimits release];
	}
	
	if (![selection valueForKey:@"HardResourceLimits"]) {
		NSMutableDictionary *hardResourceLimits = [[NSMutableDictionary alloc] init];
		[selection setValue:hardResourceLimits forKey:@"HardResourceLimits"];
		[hardResourceLimits release];
	}
}
@end
