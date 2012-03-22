//
//  LINSecureToolCommunication.m
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

#import "LINSecureToolCommunication.h"
#import "LINMainController.h"

#import <Security/Authorization.h>

#include "MoreUNIX.h"
#include "MoreSecurity.h"
#include "MoreCFQ.h"

@implementation LINSecureToolCommunication

static id sharedInstance = nil;

+ (LINSecureToolCommunication *)sharedInstance
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
	[authorisationView setString:"org.lingon.Lingon.authorised.action"];
	[authorisationView setAutoupdate:YES interval:60];
	[authorisationView updateStatus:nil];
	[authorisationView setDelegate:self];
}


-(void)deauthorise
{
	[authorisationView deauthorize:nil];
}


-(NSDictionary *)performCommandAuthenticated:(NSDictionary *)commandDictionary
{	
	OSStatus err;
	CFURLRef tool = NULL;
	CFDictionaryRef response = NULL;
	
	err = EXXXToOSStatus(MoreUNIXIgnoreSIGPIPE());
	

	if ([authorisationView authorizationState] != SFAuthorizationViewUnlockedState) {
		[authorisationView authorize:nil];
	}
	
	if (err == noErr) {
		err = MoreSecCopyHelperToolURLAndCheckBundled(CFBundleGetBundleWithIdentifier(CFSTR("org.lingon.Lingon")), 
													  CFSTR("LingonToolTemplate"), 
													  kApplicationSupportFolderType, 
													  CFSTR("Lingon"), 
													  CFSTR("LingonTool"), 
													  &tool);
		
		if (err == kMoreSecFolderInappropriateErr) {
			err = MoreSecCopyHelperToolURLAndCheckBundled(CFBundleGetBundleWithIdentifier(CFSTR("org.lingon.Lingon")), 
														  CFSTR("LingonToolTemplate"), 
														  kTemporaryFolderType, 
														  CFSTR("Lingon"), 
														  CFSTR("LingonTool"), 
														  &tool);
			
			if (err == kMoreSecFolderInappropriateErr) {
				[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"Your home directory is on a volume that does not support privileged helper tools", @"Indicate that your home directory is on a volume that does not support privileged helper tools in Try-to-set-up-authentication-sheet") informativeText:@"" defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
				return nil;			
			}			
		}
	}
	
	if (![[commandDictionary valueForKey:@"task"] isKindOfClass:[NSNumber class]]) {
		return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
	}
	unsigned int task = [[commandDictionary valueForKey:@"task"] intValue];
	if (task == LINAuthActionGetLoadedLaunchd) {
		if ([[commandDictionary allKeys] count] != 1) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
	} else if (task == LINAuthActionLoad || task == LINAuthActionUnload || task == LINAuthActionReload) {
		if ([[commandDictionary allKeys] count] != 4) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]] || ![[commandDictionary valueForKey:@"optionKeyDown"] isKindOfClass:[NSNumber class]]) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
	} else if (task == LINAuthActionStart || task == LINAuthActionStop) {
		if ([[commandDictionary allKeys] count] != 2) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"label"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"label"] length] > 1024) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
	} else if (task == LINAuthActionSave) {
		if ([[commandDictionary allKeys] count] != 5) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]] || ![[commandDictionary valueForKey:@"action"] isKindOfClass:[NSNumber class]]) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"dictionary"] isKindOfClass:[NSDictionary class]]) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
	} else if (task == LINAuthActionMove) {
		if ([[commandDictionary allKeys] count] != 4) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"oldFolder"] isKindOfClass:[NSNumber class]] || ![[commandDictionary valueForKey:@"toFolder"] isKindOfClass:[NSNumber class]]) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
	} else if (task == LINAuthActionDelete) {
		if ([[commandDictionary allKeys] count] != 3) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]]) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
	} else if (task == LINAuthActionChangeName) {
		if ([[commandDictionary allKeys] count] != 4) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]]) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"oldName"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"oldName"] length] > 1024) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		if (![[commandDictionary valueForKey:@"newName"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"newName"] length] > 1024) {
			return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
	} else {
		return [NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
	}
	
	if (err == noErr) {	
		err = MoreSecExecuteRequestInHelperTool(tool, [[authorisationView authorization] authorizationRef] , (CFDictionaryRef)commandDictionary, &response);
	}
	
	NSDictionary *returnDictionary = [NSDictionary dictionaryWithDictionary:(NSDictionary *)response];

	CFQRelease(tool);
	CFQRelease(response);
	
	return returnDictionary;
}


-(BOOL)hasAuthenticated:(NSDictionary *)returnDictionary
{
	if ([[returnDictionary valueForKey:@"com.apple.dts.MoreIsBetter.MoreSec.ErrorNumber"] intValue] == -60005 || [[returnDictionary valueForKey:@"com.apple.dts.MoreIsBetter.MoreSec.ErrorNumber"] intValue] == -60006) {
		[[LINMainController sharedInstance] alertWithMessage:NSLocalizedString(@"You failed to authenticate so you cannot perform the action", @"You failed to authenticate so you cannot perform the action in hasAuthenticated") informativeText:@"" defaultButton:OKBUTTON alternateButton:nil otherButton:nil];
		return NO;
	} else {
		return YES;
	}
}


-(BOOL)hasError:(NSDictionary *)returnDictionary
{
	if ([[returnDictionary valueForKey:@"returnString"] length] < 12) {
		return NO;
	}
	
	if ([[returnDictionary valueForKey:@"returnString"] rangeOfString:@"LingonError:" options:NSLiteralSearch range:NSMakeRange(0, 12)].location == NSNotFound) {
		return NO;
	} else {
		return YES;
	}
}


- (SFAuthorizationView *)authorisationView
{
    return authorisationView; 
}
@end
