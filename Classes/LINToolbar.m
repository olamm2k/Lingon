//
//  LINToolbar.m
//  Lingon

/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINToolbar.h"
#import "LINActionMenuController.h"
#import "LINMainController.h"
#import "LINFileMenuController.h"
#import "LINViewMenuController.h"
#import "LINSecureToolCommunication.h"
#import "LINPlistsController.h"


@implementation LINToolbar

static id sharedInstance = nil;

+ (LINToolbar *)sharedInstance
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


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:@"LoadToolbarItem",
		@"UnloadToolbarItem",
		@"ReloadToolbarItem"
		@"EditToolbarItem",
		@"RefrehToolbarItem",
		@"AssistantToolbarItem",
		@"NewToolbarItem",
		@"StartToolbarItem",
		@"StopToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		nil];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar  
{      
	return [NSArray arrayWithObjects:@"NewToolbarItem",
		@"AssistantToolbarItem",
		NSToolbarSeparatorItemIdentifier,
		@"EditToolbarItem",
		NSToolbarSeparatorItemIdentifier,
		@"LoadToolbarItem",
		@"UnloadToolbarItem",
		@"ReloadToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"RefreshToolbarItem",
		nil];  
} 

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    if ([itemIdentifier isEqual:@"LoadToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Load", @"Load toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Load", @"Load toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Load the selected agent/daemon. Hold Option if you do not want to set Disable to false.", @"Load the selected agent/daemon. Hold Option if you do not want to set Disable to false Tool Tip")];
		NSImage *loadImage = [NSImage imageNamed:@"LINLoadIcon.pdf"];
		[[[loadImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:loadImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(load:)];
		
	} else if ([itemIdentifier isEqual:@"UnloadToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Unload", @"Unload toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Unload", @"Unload toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Unload the selected agent/daemon. Hold Option if you do not want to set Disable to true.", @"Unload the selected agent/daemon. Hold Option if you do not want to set Disable to true.")];
		NSImage *unloadImage = [NSImage imageNamed:@"LINUnloadIcon.pdf"];
		[[[unloadImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:unloadImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(unload:)];
		
	} else if ([itemIdentifier isEqual:@"ReloadToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Reload", @"Reload toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Reload", @"Reload toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Reload the selected agent/daemon. Hold Option if you do not want to set Disable to false", @"Reload the selected agent/daemon. Hold Option if you do not want to set Disable to false Tool Tip")];
		NSImage *reloadImage = [NSImage imageNamed:@"LINReloadIcon.pdf"];
		[[[reloadImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:reloadImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(reload:)];
		
	} else if ([itemIdentifier isEqual:@"EditToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Edit", @"Edit toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Edit", @"Edit toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Edit the selected agent/daemon", @"Edit the selected agent/daemon Tool Tip")];
		NSImage *editImage = [NSImage imageNamed:@"LINEditIcon.pdf"];
		[[[editImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:editImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(edit:)];
		
	} else if ([itemIdentifier isEqual:@"RefreshToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Refresh", @"Refresh toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Refresh", @"Refresh toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Refresh the selected agent/daemon", @"Refresh the selected agent/daemon Tool Tip")];
		NSImage *refreshImage = [NSImage imageNamed:@"LINRefreshIcon.pdf"];
		[[[refreshImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:refreshImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(refresh:)];
		
	} else if ([itemIdentifier isEqual:@"AssistantToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Assistant", @"Assistant toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Assistant", @"Assistant toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Creates a new agent/daemon with an assistant", @"Creates a new agent/daemon with an assistant Tool Tip")];
		NSImage *assistantImage = [NSImage imageNamed:@"LINAssistantIcon.pdf"];
		[[[assistantImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:assistantImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(assistant:)];
		
	} else if ([itemIdentifier isEqual:@"NewToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"New", @"New toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"New", @"New toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Creates a new agent/daemon", @"Creates a new agent/daemon Tool Tip")];
		NSImage *newImage = [NSImage imageNamed:@"LINNewIcon.pdf"];
		[[[newImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:newImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(new:)];
		
	} else if ([itemIdentifier isEqual:@"StartToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Start", @"Start toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Start", @"Start toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Starts the selected launchd item", @"Starts the selected launchd item Tool Tip")];
		NSImage *startImage = [NSImage imageNamed:@"LINStartIcon.pdf"];
		[[[startImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:startImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(start:)];
		
	} else if ([itemIdentifier isEqual:@"StopToolbarItem"]) {
        [toolbarItem setLabel:NSLocalizedString(@"Stop", @"Stop toolbar item Label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Stop", @"Stop toolbar item Palette Label")];
        [toolbarItem setToolTip:NSLocalizedString(@"Stops the selected launchd item", @"Stops the selected launchd item Tool Tip")];
		NSImage *stopImage = [NSImage imageNamed:@"LINStopIcon.pdf"];
		[[[stopImage representations] objectAtIndex:0] setAlpha:YES];
		[toolbarItem setImage:stopImage];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(stop:)];
		
	} else {
		toolbarItem = nil;
	}
	
	return toolbarItem;
}


-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem 
{
	BOOL enable = YES;
	BOOL aPlistIsSelected = [[[[LINPlistsController sharedInstance] arrayController] selectedObjects] count];
	id selection = [[[LINPlistsController sharedInstance] arrayController] selection];
	NSString *identifier = [toolbarItem itemIdentifier];
	if (!aPlistIsSelected && ([identifier isEqual:@"EditToolbarItem"] || [identifier isEqual:@"LoadToolbarItem"] || [identifier isEqual:@"UnloadToolbarItem"] || [identifier isEqual:@"ReloadToolbarItem"] || [identifier isEqual:@"StartToolbarItem"] || [identifier isEqual:@"StopToolbarItem"])) return NO;
	
	if ([identifier isEqual:@"LoadToolbarItem"]) {
		if ([selection valueForKey:@"loaded"] && [[selection valueForKey:@"loaded"] boolValue]) {
			enable = NO;
		}
	} else if ([identifier isEqual:@"UnloadToolbarItem"] || [identifier isEqual:@"ReloadToolbarItem"] || [identifier isEqual:@"StartToolbarItem"] || [identifier isEqual:@"StopToolbarItem"]) {
		if ([selection valueForKey:@"loaded"] && ![[selection valueForKey:@"loaded"] boolValue]) {
			enable = NO;
		}
	}
	
	return enable;
}


-(void)load:(id)sender
{
	[[LINActionMenuController sharedInstance] loadAction:nil];
}


-(void)unload:(id)sender
{
	[[LINActionMenuController sharedInstance] unloadAction:nil];
}


-(void)reload:(id)sender
{
	[[LINActionMenuController sharedInstance] reloadAction:nil];
}


-(void)edit:(id)sender
{
	[[LINActionMenuController sharedInstance] editAction:nil];
}


-(void)start:(id)sender
{
	[[LINActionMenuController sharedInstance] startAction:nil];
}


-(void)stop:(id)sender
{
	[[LINActionMenuController sharedInstance] stopAction:nil];
}


-(void)refresh:(id)sender
{
	[[LINViewMenuController sharedInstance] refreshAction:nil];
}


-(void)assistant:(id)sender
{
	[[LINFileMenuController sharedInstance] assistantAction:nil];
}


-(void)new:(id)sender
{
	[[LINFileMenuController sharedInstance] newAction:nil];
}



@end
