/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINAssistant.h"
#import "LINMainController.h"
#import "LINVariousPerformer.h"
#import "LINPlistsController.h"

@implementation LINAssistant

static id sharedInstance = nil;

+ (LINAssistant *)sharedInstance
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


-(void)awakeFromNib
{	
	int index;
	NSMenuItem *item;
	for (index = 0; index < 60; index++) {
		item = [[NSMenuItem alloc] init];
		NSNumber *number = [[NSNumber alloc] initWithInt:index];
		[item setTitle:[number stringValue]];
		[number release];
		[item setTag:index + 1];
		[[choice3MinutePopUp menu] addItem:item];
		[item release];
	}
	
	for (index = 0; index < 24; index++) {
		item = [[NSMenuItem alloc] init];
		NSNumber *number = [[NSNumber alloc] initWithInt:index];
		[item setTitle:[number stringValue]];
		[number release];
		[item setTag:index + 1];
		[[choice3HourPopUp menu] addItem:item];
		[item release];
	}
	
	for (index = 1; index < 32; index++) {
		item = [[NSMenuItem alloc] init];
		NSNumber *number = [[NSNumber alloc] initWithInt:index];
		[item setTitle:[number stringValue]];
		[number release];
		[item setTag:index];
		[[choice3DayPopUp menu] addItem:item];
		[item release];
	}
}


-(void)openAssistant
{
	[labelTextField setStringValue:@""];
	[assitantMatrix selectCellAtRow:0 column:0];
	[choice1JobTextField setStringValue:@""];
	[choice2EveryPopUp selectItemAtIndex:0];
	[choice2JobTextField setStringValue:@""];
	[choice2RunEveryTextField setStringValue:@""];
	[choice3DayPopUp selectItemAtIndex:0];
	[choice3HourPopUp selectItemAtIndex:0];
	[choice3JobTextField setStringValue:@""];
	[choice3MinutePopUp selectItemAtIndex:0];
	[choice3MonthPopUp selectItemAtIndex:0];
	[choice3WeekdayPopUp selectItemAtIndex:0];
	[choice4ApplicationScriptTextField setStringValue:@""];
	[choice5FileTextField setStringValue:@""];
	[choice5ApplicationScriptTextField setStringValue:@""];
	[choice6FolderTextField setStringValue:@""];
	[choice6ApplicationScriptTextField setStringValue:@""];
	[launchOnlyWhenILogIn setState:NSOnState];
	[mustRunAsRoot setState:NSOffState];
	[mustRunAsRoot setEnabled:NO];
	
	[self setStep:1];
	[assistantTabView selectTabViewItemAtIndex:0];
	[previous setEnabled:NO];
	[nextCreate setTitle:NSLocalizedString(@"Next", @"Next-button in Assistant")];
	
	[NSApp beginSheet:assistantSheet modalForWindow:[[LINMainController sharedInstance] mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
}


-(void)closeAssistant
{
	[NSApp endSheet:assistantSheet];
	[assistantSheet close];
}


- (IBAction)cancelAction:(id)sender
{
	[self closeAssistant];
}


- (IBAction)nextCreateAction:(id)sender
{
	if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"0"]) { // Step 1

		[assistantTabView selectTabViewItemAtIndex:1];
		[nextCreate setTitle:NSLocalizedString(@"Next", @"Next-button in Assistant")];
		[previous setEnabled:YES];
		[self setStep:2];
		[assistantSheet makeFirstResponder:labelTextField];

	} else if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"100"]) { // Step 2
		
		if ([[labelTextField stringValue] isEqual:@""]) {
			[self allRequiredFieldsAreNotSet];
			return;
		}
		
		int selectedAssistant = [assitantMatrix selectedRow] + 2;
		[assistantTabView selectTabViewItemAtIndex:selectedAssistant];
		[nextCreate setTitle:NSLocalizedString(@"Create", @"Create-button in Assistant")];
		
		if (selectedAssistant == 2) {
			[assistantSheet makeFirstResponder:choice1JobTextField];
		} else if (selectedAssistant == 3) {
			[assistantSheet makeFirstResponder:choice2JobTextField];
		} else if (selectedAssistant == 4) {
			[assistantSheet makeFirstResponder:choice3JobTextField];
		} else if (selectedAssistant == 5) {
			[assistantSheet makeFirstResponder:choice4ApplicationScriptTextField];
		} else if (selectedAssistant == 6) {
			[assistantSheet makeFirstResponder:choice5ApplicationScriptTextField];
		} else if (selectedAssistant == 7) {
			[assistantSheet makeFirstResponder:choice6ApplicationScriptTextField];
		}
		
		[previous setEnabled:YES];
		[self setStep:3];
		
	} else { // Step 3
		if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"1"]) { // Run at startup
			if ([[choice1JobTextField stringValue] isEqual:@""]) {
				[self allRequiredFieldsAreNotSet];
				return;
			}
			
			NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
			[dictionary setValue:[labelTextField stringValue] forKey:@"Label"];
			[dictionary setValue:[self divideCommandIntoArray:[choice1JobTextField stringValue]] forKey:@"ProgramArguments"];
			[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
			
			int whichFolder = [self whichFolder];
			[[LINMainController sharedInstance] setShouldUpdateTab:NO];
			[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:whichFolder - 1];
			[[LINMainController sharedInstance] setShouldUpdateTab:YES];
			if ([[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:whichFolder filename:[[labelTextField stringValue] stringByAppendingPathExtension:@"plist"] action:LINAfterSaveLoad] == NO) {
				return;
			}
			[[LINVariousPerformer sharedInstance] selectLabel:[labelTextField stringValue]];
			
			
			
			
		} else if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"2"]) { // Run periodically
			if ([[choice2JobTextField stringValue] isEqual:@""] || [[choice2RunEveryTextField stringValue] isEqual:@""]) {
				[self allRequiredFieldsAreNotSet];
				return;
			}
			
			NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
			[dictionary setValue:[labelTextField stringValue] forKey:@"Label"];
			[dictionary setValue:[self divideCommandIntoArray:[choice2JobTextField stringValue]] forKey:@"ProgramArguments"];
			[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"RunAtLoad"];
			int seconds = [choice2RunEveryTextField intValue];
			if ([choice2EveryPopUp selectedTag] == 1) {
				seconds = seconds * 60;
			} else if ([choice2EveryPopUp selectedTag] == 2) {
				seconds = seconds * 60 * 60;
			}
			[dictionary setValue:[NSNumber numberWithInt:seconds] forKey:@"StartInterval"];
			
			int whichFolder = [self whichFolder];
			[[LINMainController sharedInstance] setShouldUpdateTab:NO];
			[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:whichFolder - 1];
			[[LINMainController sharedInstance] setShouldUpdateTab:YES];
			if ([[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:whichFolder filename:[[labelTextField stringValue] stringByAppendingPathExtension:@"plist"] action:LINAfterSaveLoad] == NO) {
				return;
			}
			[[LINVariousPerformer sharedInstance] selectLabel:[labelTextField stringValue]];
			
			
			
			
		} else if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"3"]) { // Run at specific time
			int areAllTimePopUpsSet = [choice3MinutePopUp selectedTag] + [choice3HourPopUp selectedTag] + [choice3DayPopUp selectedTag] + [choice3WeekdayPopUp selectedTag] + [choice3MonthPopUp selectedTag];
			if ([[choice3JobTextField stringValue] isEqual:@""] || areAllTimePopUpsSet == 0) {
				[self allRequiredFieldsAreNotSet];
				return;
			}			
			
			NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
			[dictionary setValue:[labelTextField stringValue] forKey:@"Label"];
			[dictionary setValue:[self divideCommandIntoArray:[choice3JobTextField stringValue]] forKey:@"ProgramArguments"];
			NSMutableDictionary *calendarDictionary = [[NSMutableDictionary alloc] init];
			if ([choice3MinutePopUp selectedTag] != 0) {
				[calendarDictionary setValue:[NSNumber numberWithInt:([choice3MinutePopUp selectedTag] - 1)] forKey:@"Minute"];
			}
			if ([choice3HourPopUp selectedTag] != 0) {
				[calendarDictionary setValue:[NSNumber numberWithInt:([choice3HourPopUp selectedTag] - 1)] forKey:@"Hour"];
			}
			if ([choice3DayPopUp selectedTag] != 0) {
				[calendarDictionary setValue:[NSNumber numberWithInt:([choice3DayPopUp selectedTag] - 1)] forKey:@"Day"];
			}
			if ([choice3WeekdayPopUp selectedTag] != 0) {
				[calendarDictionary setValue:[NSNumber numberWithInt:([choice3WeekdayPopUp selectedTag] - 1)] forKey:@"Weekday"];
			}
			if ([choice3MonthPopUp selectedTag] != 0) {
				[calendarDictionary setValue:[NSNumber numberWithInt:[choice3MonthPopUp selectedTag]] forKey:@"Month"];
			}
			[dictionary setValue:calendarDictionary forKey:@"StartCalendarInterval"];
			[calendarDictionary release];
			
			int whichFolder = [self whichFolder];
			[[LINMainController sharedInstance] setShouldUpdateTab:NO];
			[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:whichFolder - 1];
			[[LINMainController sharedInstance] setShouldUpdateTab:YES];
			if ([[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:whichFolder filename:[[labelTextField stringValue] stringByAppendingPathExtension:@"plist"] action:LINAfterSaveLoad] == NO) {
				return;
			}
			[[LINVariousPerformer sharedInstance] selectLabel:[labelTextField stringValue]];
			
			
			
			
		} else if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"4"]) { // Kepp app running
			if ([[choice4ApplicationScriptTextField stringValue] isEqual:@""]) {
				[self allRequiredFieldsAreNotSet];
				return;
			}
			
			NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
			[dictionary setValue:[labelTextField stringValue] forKey:@"Label"];
			[dictionary setValue:[NSArray arrayWithObject:[choice4ApplicationScriptTextField stringValue]] forKey:@"ProgramArguments"];
			[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"OnDemand"];
			
			int whichFolder = [self whichFolder];
			[[LINMainController sharedInstance] setShouldUpdateTab:NO];
			[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:whichFolder - 1];
			[[LINMainController sharedInstance] setShouldUpdateTab:YES];
			if ([[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:whichFolder filename:[[labelTextField stringValue] stringByAppendingPathExtension:@"plist"] action:LINAfterSaveLoad] == NO) {
				return;
			}
			[[LINVariousPerformer sharedInstance] selectLabel:[labelTextField stringValue]];
			
			
			
			
		} else if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"5"]) { // Watch file
			if ([[choice5ApplicationScriptTextField stringValue] isEqual:@""] || [[choice5FileTextField stringValue] isEqual:@""]) {
				[self allRequiredFieldsAreNotSet];
				return;
			}
			
			NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
			[dictionary setValue:[labelTextField stringValue] forKey:@"Label"];
			[dictionary setValue:[NSArray arrayWithObject:[choice5ApplicationScriptTextField stringValue]] forKey:@"ProgramArguments"];
			[dictionary setValue:[NSArray arrayWithObject:[choice5FileTextField stringValue]] forKey:@"WatchPaths"];
			
			int whichFolder = [self whichFolder];
			[[LINMainController sharedInstance] setShouldUpdateTab:NO];
			[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:whichFolder - 1];
			[[LINMainController sharedInstance] setShouldUpdateTab:YES];
			if ([[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:whichFolder filename:[[labelTextField stringValue] stringByAppendingPathExtension:@"plist"] action:LINAfterSaveLoad] == NO) {
				return;
			}
			[[LINVariousPerformer sharedInstance] selectLabel:[labelTextField stringValue]];
			
			
			
			
		} else if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"6"]) { // Watch folder
			if ([[choice6ApplicationScriptTextField stringValue] isEqual:@""] || [[choice6FolderTextField stringValue] isEqual:@""]) {
				[self allRequiredFieldsAreNotSet];
				return;
			}
			
			NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
			[dictionary setValue:[labelTextField stringValue] forKey:@"Label"];
			[dictionary setValue:[NSArray arrayWithObject:[choice6ApplicationScriptTextField stringValue]] forKey:@"ProgramArguments"];
			[dictionary setValue:[NSArray arrayWithObject:[choice6FolderTextField stringValue]] forKey:@"QueueDirectories"];
			
			int whichFolder = [self whichFolder];
			[[LINMainController sharedInstance] setShouldUpdateTab:NO];
			[[[LINMainController sharedInstance] mainTabView] selectTabViewItemAtIndex:whichFolder - 1];
			[[LINMainController sharedInstance] setShouldUpdateTab:YES];
			if ([[LINVariousPerformer sharedInstance] performSaveOfDictionary:dictionary toFolder:whichFolder filename:[[labelTextField stringValue] stringByAppendingPathExtension:@"plist"] action:LINAfterSaveLoad] == NO) {
				return;
			}
			[[LINVariousPerformer sharedInstance] selectLabel:[labelTextField stringValue]];
			
		}
	
		[self closeAssistant];
	}		
}


- (IBAction)pathAction:(id)sender
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
	
	int answer = [openPanel runModalForDirectory:[defaults valueForKey:@"LastDirectory"] file:nil types:nil];
	
	if (answer != NSOKButton) return;
	
	NSString *path = [[openPanel filenames] objectAtIndex:0];
	[defaults setValue:[path stringByDeletingLastPathComponent] forKey:@"LastDirectory"];
	
	if (tag == 1) { 
		[choice4ApplicationScriptTextField setStringValue:path];
	} else if (tag == 2) { 
		[choice5ApplicationScriptTextField setStringValue:path];
	} else if (tag == 3) { 
		[choice5FileTextField setStringValue:path];
	} else if (tag == 4) {
		[choice6ApplicationScriptTextField setStringValue:path];
	} else if (tag == 5) {
		[choice6FolderTextField setStringValue:path];
	}
}


- (IBAction)launchOnlyWhenILogInAction:(id)sender
{
	if ([launchOnlyWhenILogIn state] == NSOnState) {
		[mustRunAsRoot setEnabled:NO];
	} else {
		[mustRunAsRoot setEnabled:YES];
	}
}


- (NSArray *)divideCommandIntoArray:(NSString *)command
{
	if ([command rangeOfString:@"\""].location == NSNotFound && [command rangeOfString:@"'"].location == NSNotFound) {
		return [command componentsSeparatedByString:@" "];
	} else {
		NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
		NSScanner *scanner = [NSScanner scannerWithString:command];
		int location = 0;
		int commandLength = [command length];
		int beginning;
		int savedBeginning = -1;
		NSString *characterToScanFor;
		
		while (location < commandLength) {
			if (savedBeginning == -1) {
				beginning = location;
			} else {
				beginning = savedBeginning;
				savedBeginning = -1;
			}
			if ([command characterAtIndex:location] == '"') {
				characterToScanFor = @"\"";
				beginning++;
				location++;
			} else if ([command characterAtIndex:location] == '\'') {
				characterToScanFor = @"'";
				beginning++;
				location++;
			} else {
				characterToScanFor = @" ";
			}

			[scanner setScanLocation:location];
			if ([scanner scanUpToString:characterToScanFor intoString:nil]) {
				if (![characterToScanFor isEqual:@" "] && [command characterAtIndex:([scanner scanLocation] - 1)] == '\\') {
					location = [scanner scanLocation];
					savedBeginning = beginning - 1;
					continue;
				}
				location = [scanner scanLocation];
			} else {
				location = commandLength - 1;
			}

			[returnArray addObject:[command substringWithRange:NSMakeRange(beginning, location - beginning)]];
			location++;
		}
		return (NSArray *)returnArray;
	}
}


-(void)allRequiredFieldsAreNotSet
{
	[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"All required fields are not set", @"All required fields are not set in allRequiredFieldsAreNotSet") informativeText:NSLocalizedString(@"Please make sure that all required fields are set", @"Please make sure that all required fields are set in allRequiredFieldsAreNotSet") defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
}


-(int)whichFolder
{
	int whichFolder;
	if ([launchOnlyWhenILogIn state] == NSOffState && [mustRunAsRoot state] == NSOffState) {
		whichFolder = LINUsersAgentsFolder;
	} else if ([launchOnlyWhenILogIn state] == NSOffState && [mustRunAsRoot state] == NSOnState) {
		whichFolder = LINUsersDaemonsFolder;
	} else {
		whichFolder = LINMyAgentsFolder; 
	}
	
	return whichFolder;
}

- (IBAction)previousAction:(id)sender
{
	if ([[[assistantTabView selectedTabViewItem] identifier] isEqual:@"100"]) { // Step 2
		
		[previous setEnabled:NO];
		[assistantTabView selectTabViewItemAtIndex:0];
		[self setStep:1];
		
	} else if (![[[assistantTabView selectedTabViewItem] identifier] isEqual:@"0"]) { // All the others
		
		[nextCreate setTitle:NSLocalizedString(@"Next", @"Next-button in Assistant")];
		[assistantTabView selectTabViewItemAtIndex:1];
		[self setStep:2];
	}
}

-(void)setStep:(int)step
{
	[stepTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Step %d of 3", @"Step %d of 3 in setStep"), step]];
}
@end
