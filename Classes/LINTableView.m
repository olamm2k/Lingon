//
//  LINTableView.m
//  Lingon
//
/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINTableView.h"
#import "LINFileMenuController.h"
#import "LINMainController.h"
#import "LINEditPlistController.h"

@implementation LINTableView

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	[super draggedImage:anImage endedAt:aPoint operation:operation];
	
	if (operation == NSDragOperationDelete) {
		if ([[[[LINMainController sharedInstance] mainWindow] attachedSheet] isEqual:[[LINEditPlistController sharedInstance] editPlistSheet]]) {
			NSArrayController *arrayController = [[LINMainController sharedInstance] arrayControllerForTableView:[self self]];
			[arrayController removeObjectsAtArrangedObjectIndexes:[arrayController selectionIndexes]];
		} else {
			[[LINFileMenuController sharedInstance] deleteAction:nil];
		}
	}
}

- (void)keyDown:(NSEvent *)event
{
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    int keyCode = [event keyCode];
	
	// get flags and strip the lower 16 (device dependant) bits
	unsigned int flags = ([event modifierFlags] & 0x00FF);

	if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
		if ([self selectedRow] == -1) {
			NSBeep();
		} else {
			if ([[[[LINMainController sharedInstance] mainWindow] attachedSheet] isEqual:[[LINEditPlistController sharedInstance] editPlistSheet]]) {
				NSArrayController *arrayController = [[LINMainController sharedInstance] arrayControllerForTableView:[self self]];
				[arrayController removeObjectsAtArrangedObjectIndexes:[arrayController selectionIndexes]];
			} else {
				[[LINFileMenuController sharedInstance] deleteAction:nil];
			}
		}
	} else {
		[super keyDown:event];
	}
}
@end
