/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/


#import "LINHelpMenuController.h"
#import "LINVariousPerformer.h"
#import "LINMainController.h"

@implementation LINHelpMenuController


- (IBAction)openManPageAction:(id)sender
{
	NSString *path = [[LINVariousPerformer sharedInstance] genererateTempPath];
	
	if ([sender tag] == 1) {
		system([[NSString stringWithFormat:@"/usr/bin/man launchd.plist | col -b > %@", path] UTF8String]);
		[manPageLaunchdPlistTextView setString:[self getManStringAtPath:path]];
		[manPageLaunchdPlistWindow makeKeyAndOrderFront:nil];
	} else if ([sender tag] == 2) {
		system([[NSString stringWithFormat:@"/usr/bin/man launchctl | col -b > %@", path] UTF8String]);
		[manPageLaunchCtlTextView setString:[self getManStringAtPath:path]];
		[manPageLaunchCtlWindow makeKeyAndOrderFront:nil];
	} else if ([sender tag] == 3) {
		system([[NSString stringWithFormat:@"/usr/bin/man launchd | col -b > %@", path] UTF8String]);
		[manPageLaunchdTextView setString:[self getManStringAtPath:path]];
		[manPageLaunchdWindow makeKeyAndOrderFront:nil];
	}
}


-(NSString *)getManStringAtPath:(NSString *)path
{
	NSString *manString;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		manString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	} else {
		manString = NSLocalizedString(@"The man page cannot be displayed because of an error. Please try again!", @"The man page cannot be displayed because of an error. Please try again! in openManPageAction"); 
	}

	return manString;
}

@end
