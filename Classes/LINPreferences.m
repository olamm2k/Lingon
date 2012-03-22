/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINPreferences.h"
#import "LINMainController.h"
#import "LINEditPlistController.h"

@implementation LINPreferences

static id sharedInstance = nil;

+ (LINPreferences *)sharedInstance
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


-(void)setDefaults
{	
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	[dictionary setValue:[NSNumber numberWithInt:0] forKey:@"TableFontSize"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"CheckForUpdatesAtStartup"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"WarnMe"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Monaco" size:11]] forKey:@"TextFont"];
	[dictionary setValue:NSHomeDirectory() forKey:@"LastDirectory"];
	[dictionary setValue:@"/Applications/Smultron.app" forKey:@"ExternalEditor"];
	
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:dictionary];
	[dictionary release];
}


-(IBAction)changeTableFontSizeAction:(id)sender
{
	[defaults setValue:[NSNumber numberWithInt:[sender tag]] forKey:@"TableFontSize"];
	[self refreshAllTableViews];

}


-(IBAction)checkNowAction:(id)sender
{
	[noUpdateAvailableTextField setHidden:YES];
	[[LINMainController sharedInstance] checkForUpdate];	
}


-(void)refreshAllTableViews
{
	[[[LINMainController sharedInstance] mainTableView] reloadData];
	[[[LINEditPlistController sharedInstance] bonjourTableView] reloadData];
	[[[LINEditPlistController sharedInstance] programArgumentsTableView] reloadData];
	[[[LINEditPlistController sharedInstance] queueDirectoriesTableView] reloadData];
	[[[LINEditPlistController sharedInstance] socketsTableView] reloadData];
	[[[LINEditPlistController sharedInstance] watchPathsTableView] reloadData];
}


- (IBAction)showFontPanelAction:(id)sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:@"TextFont"]] isMultiple:NO];
	[fontManager orderFrontFontPanel:nil];
}


- (NSTextField *)noUpdateAvailableTextField {
    return noUpdateAvailableTextField; 
}


-(IBAction)externalEditorPathAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	
	int answer = [openPanel runModalForDirectory:@"/Applications" file:nil types:nil];
	if (answer != NSOKButton) {
		return;
	}
	
	[defaults setValue:[[openPanel filenames] objectAtIndex:0] forKey:@"ExternalEditor"];
}


- (NSWindow *)preferencesWindow
{
    return preferencesWindow; 
}
@end
