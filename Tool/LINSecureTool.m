// LINSecureTool.m

/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/


#import <unistd.h>

#import "MoreUNIX.h"
#import "MoreSecurity.h"
#import "MoreCFQ.h"

#import <Foundation/NSFileManager.h>
#import <Foundation/NSData.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSPathUtilities.h>

#define MYAGENTS (CFStringRef)[[(NSString *)homeDirectory stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"LaunchAgents"]
#define USERSAGENTS CFSTR("/Library/LaunchAgents")
#define USERSDAEMONS CFSTR("/Library/LaunchDaemons")
#define SYSTEMAGENTS CFSTR("/System/Library/LaunchAgents")
#define SYSTEMDAEMONS CFSTR("/System/Library/LaunchDaemons")

enum {
    LINAuthActionGetLoadedLaunchd = 1,
	LINAuthActionLoad,
	LINAuthActionUnload,
	LINAuthActionReload,
	LINAuthActionStart,
	LINAuthActionStop,
	LINAuthActionSave,
	LINAuthActionMove,
	LINAuthActionDelete,
	LINAuthActionChangeName
};


enum {
    LINMyAgentsFolder = 1,
	LINUsersAgentsFolder,
	LINUsersDaemonsFolder,
	LINSystemAgentsFolder,
	LINSystemDaemonsFolder,
};


typedef enum _LINAfterSaveAction {
    LINAfterSaveNothing = 0,
	LINAfterSaveLoad,
	LINAfterSaveReload
} LINAfterSaveAction;

CFStringRef homeDirectory;

static CFStringRef PerformTask(CFStringRef launchPath, CFArrayRef arguments)
{
	NSTask *task = [[NSTask alloc] init];
	NSPipe *pipe = [[NSPipe alloc] init];
	
	[task setLaunchPath:(NSString *)launchPath];
	[task setArguments:(NSArray *)arguments];
	[task setStandardOutput:pipe];
	
	[task launch];
	
	[task waitUntilExit];
	
	NSString *returnString;
	NSData *data;
	
	int status = [task terminationStatus];
	
	if (status == 0) {
		data = [[pipe fileHandleForReading] readDataToEndOfFile];
		returnString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	} else {
		returnString = @"LingonError:";
	}

	[pipe release];
	[task release];
	
	return (CFStringRef)returnString;
}


static CFStringRef GetLoaded()
{
	NSArray *arguments = [[NSArray alloc] initWithObjects: @"list", nil];	
	CFStringRef returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
	[arguments release];
	return returnString;
}


static CFStringRef FolderPath(int folder)
{
	if (folder == LINUsersAgentsFolder) {
		return USERSAGENTS;
	} else if (folder == LINUsersDaemonsFolder) {
		return USERSDAEMONS;
	} else if (folder == LINSystemAgentsFolder) {
		return SYSTEMAGENTS;
	} else if (folder == LINSystemDaemonsFolder) {
		return SYSTEMDAEMONS;
	} else {
		return MYAGENTS;
	}
}


static CFDictionaryRef PerformCommandAuthenticated(CFDictionaryRef commandDictionary)
{
	unsigned int task = [[(NSDictionary *)commandDictionary valueForKey:@"task"] intValue];
	
	if (task == LINAuthActionGetLoadedLaunchd) {  
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObject:(NSString *)GetLoaded() forKey:@"returnString"];
		return (CFDictionaryRef)returnDictionary;
		
	} else if (task == LINAuthActionLoad) {
		
		NSString *path = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"folder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"filename"]];
		NSString *convertedPath = [NSString stringWithUTF8String:[path UTF8String]];
		NSArray *arguments;
		if ([[(NSDictionary *)commandDictionary valueForKey:@"optionKeyDown"] boolValue]) {
			arguments = [[NSArray alloc] initWithObjects: @"load", convertedPath, nil];
		} else {
			arguments = [[NSArray alloc] initWithObjects: @"load", @"-w", convertedPath, nil];
		}
		CFStringRef returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
		[arguments release];
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
		
	} else if (task == LINAuthActionUnload) {
		
		NSString *path = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"folder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"filename"]];
		NSString *convertedPath = [NSString stringWithUTF8String:[path UTF8String]];
		NSArray *arguments;
		if ([[(NSDictionary *)commandDictionary valueForKey:@"optionKeyDown"] boolValue]) {
			arguments = [[NSArray alloc] initWithObjects: @"unload", convertedPath, nil];
		} else {
			arguments = [[NSArray alloc] initWithObjects: @"unload", @"-w", convertedPath, nil];
		}
		CFStringRef returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
		[arguments release];
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
		
	} else if (task == LINAuthActionReload) {
		
		NSString *path = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"folder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"filename"]];
		NSString *convertedPath = [NSString stringWithUTF8String:[path UTF8String]];
		NSArray *arguments;
		if ([[(NSDictionary *)commandDictionary valueForKey:@"optionKeyDown"] boolValue]) {
			arguments = [[NSArray alloc] initWithObjects: @"unload", convertedPath, nil];
		} else {
			arguments = [[NSArray alloc] initWithObjects: @"unload", @"-w", convertedPath, nil];
		}
		CFStringRef returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
		[arguments release];
		
		if ([(NSString *)returnString rangeOfString:@"LingonError:"].location == NSNotFound) {
			if ([[(NSDictionary *)commandDictionary valueForKey:@"optionKeyDown"] boolValue]) {
				arguments = [[NSArray alloc] initWithObjects: @"load", convertedPath, nil];
			} else {
				arguments = [[NSArray alloc] initWithObjects: @"load", @"-w", convertedPath, nil];
			}
			returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
			[arguments release];
		}
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;		
		
		
	} else if (task == LINAuthActionStart) {
		NSString *label = [(NSDictionary *)commandDictionary valueForKey:@"label"];
		NSArray *arguments = [[NSArray alloc] initWithObjects: @"start", label, nil];	
		CFStringRef returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
		[arguments release];
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
		
	} else if (task == LINAuthActionStop) {
		NSString *label = [(NSDictionary *)commandDictionary valueForKey:@"label"];
		NSArray *arguments = [[NSArray alloc] initWithObjects: @"stop", label, nil];	
		CFStringRef returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
		[arguments release];
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
		
	} else if (task == LINAuthActionSave) {
		
		NSString *path = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"folder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"filename"]];
		
		if (![[(NSDictionary *)commandDictionary valueForKey:@"dictionary"] writeToFile:path atomically:YES]) {
			return (CFDictionaryRef)[NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
		}
		
		[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:420] forKey:@"NSFilePosixPermissions"] atPath:path];
		
		CFStringRef returnString;
		int action = [[(NSDictionary *)commandDictionary valueForKey:@"action"] intValue];
		
		if (action == LINAfterSaveLoad) {
			NSArray *arguments = [[NSArray alloc] initWithObjects: @"load", @"-w", path, nil];
			returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
			[arguments release];
			
		} else if (action == LINAfterSaveReload) { 
			NSArray *arguments = [[NSArray alloc] initWithObjects: @"unload", @"-w", path, nil];
			returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
			[arguments release];
			if ([(NSString *)returnString rangeOfString:@"LingonError:"].location == NSNotFound) {
				arguments = [[NSArray alloc] initWithObjects: @"load", @"-w", path, nil];
				returnString = PerformTask(CFSTR("/bin/launchctl"), (CFArrayRef)arguments);
				[arguments release];
			}
	
		} else {
			returnString = CFSTR("");
		}			
			
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
		
	} else if (task == LINAuthActionMove) {
		
		NSString *oldPath = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"oldFolder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"filename"]];
		NSString *newPath = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"toFolder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"filename"]];
		
		CFStringRef returnString = CFSTR("");
		if (![[NSFileManager defaultManager] movePath:oldPath toPath:newPath handler:nil]) {
			returnString = CFSTR("LingonError:");
		}
		
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
		
	} else if (task == LINAuthActionDelete) {
		
		NSString *path = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"folder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"filename"]];
		
		CFStringRef returnString = CFSTR("");
		if (![[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
			returnString = CFSTR("LingonError:");
		}
		
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
		
	} else if (task == LINAuthActionChangeName) {
		
		NSString *oldPath = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"folder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"oldName"]];
		NSString *newPath = [(NSString *)FolderPath([[(NSDictionary *)commandDictionary valueForKey:@"folder"] intValue]) stringByAppendingPathComponent:[(NSDictionary *)commandDictionary valueForKey:@"newName"]];
		
		CFStringRef returnString = CFSTR("");
		if (![[NSFileManager defaultManager] movePath:oldPath toPath:newPath handler:nil]) {
			returnString = CFSTR("LingonError:");
		}
		
		NSArray *objects = [[NSArray alloc] initWithObjects:(NSString *)returnString, (NSString *)GetLoaded(), nil];
		NSArray *keys = [[NSArray alloc] initWithObjects:@"returnString", @"loaded", nil];
		NSDictionary *returnDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[objects release];
		[keys release];
		return (CFDictionaryRef)returnDictionary;
		
	} else {
		return (CFDictionaryRef)[NSDictionary dictionaryWithObject:@"LingonError:" forKey:@"returnString"];
	}
	
	return nil;
}


static OSStatus PerformCommand(AuthorizationRef auth, CFDictionaryRef request, CFDictionaryRef *result)
{
	NSDictionary *commandDictionary = (NSDictionary *)request;
	if (![[commandDictionary valueForKey:@"task"] isKindOfClass:[NSNumber class]]) {
		return 1000;
	}
	unsigned int task = [[commandDictionary valueForKey:@"task"] intValue];
	if (task == LINAuthActionGetLoadedLaunchd) {
		if ([[commandDictionary allKeys] count] != 1) {
			return 1000;
		}
		
	} else if (task == LINAuthActionLoad || task == LINAuthActionUnload || task == LINAuthActionReload) {
		if ([[commandDictionary allKeys] count] != 4) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]] || ![[commandDictionary valueForKey:@"optionKeyDown"] isKindOfClass:[NSNumber class]]) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return 1000;
		}
		
	} else if (task == LINAuthActionStart || task == LINAuthActionStop) {
		if ([[commandDictionary allKeys] count] != 2) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"label"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"label"] length] > 1024) {
			return 1000;
		}
		
	} else if (task == LINAuthActionSave) {
		if ([[commandDictionary allKeys] count] != 5) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]] || ![[commandDictionary valueForKey:@"action"] isKindOfClass:[NSNumber class]]) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"dictionary"] isKindOfClass:[NSDictionary class]]) {
			return 1000;
		}
		
	} else if (task == LINAuthActionMove) {
		if ([[commandDictionary allKeys] count] != 4) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"oldFolder"] isKindOfClass:[NSNumber class]] || ![[commandDictionary valueForKey:@"toFolder"] isKindOfClass:[NSNumber class]]) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return 1000;
		}
		
	} else if (task == LINAuthActionDelete) {
		if ([[commandDictionary allKeys] count] != 3) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]]) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"filename"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"filename"] length] > 1024) {
			return 1000;
		}
		
	} else if (task == LINAuthActionChangeName) {
		if ([[commandDictionary allKeys] count] != 4) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"folder"] isKindOfClass:[NSNumber class]]) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"oldName"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"oldName"] length] > 1024) {
			return 1000;
		}
		if (![[commandDictionary valueForKey:@"newName"] isKindOfClass:[NSString class]] || [[commandDictionary valueForKey:@"newName"] length] > 1024) {
			return 1000;
		}
		
	} else {
		return 1000;
	}
	
	OSStatus err = noErr;
	
	static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	static const char *kRightName = "org.lingon.Lingon.authorised.action";
	AuthorizationItem right = {kRightName, 0, NULL, 0};
	AuthorizationRights rights = {1, &right};
	err = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
	
	if (err == noErr) {
		homeDirectory = (CFStringRef)NSHomeDirectory(); // one needs to set it here before the user id changes below
		(void)MoreSecSetPrivilegedEUID();
		int savedUID = getuid();
		setuid(0); // set the uid to root for launchctl to act like it's root (setting the euid is not enough) otherwise e.g. it just returns the user's list; resets the uid below

		CFDictionaryRef returnDictionary = PerformCommandAuthenticated(request);
	
		setuid(savedUID);
		(void)MoreSecPermanentlySetNonPrivilegedEUID();
		if (err == noErr) {
			*result = returnDictionary;
			err = CFQError(*result);
		}
	}
	
	return err;
}


int main(int argc, const char *argv[])
{	
	NSAutoreleasePool *pool;
	pool = [[NSAutoreleasePool alloc] init];
	// The tool crashes if the pool is released, but it doesn't really matter much as the tool should only be running for a short while anyway
	
	int err;
	int result;
	AuthorizationRef auth;
	
	
	// It's vital that we get any auth ref passed to us from 
	// AuthorizationExecuteWithPrivileges before we call 
	// MoreSecDestroyInheritedEnvironment, because AEWP passes its 
	// auth ref to us via the environment.
	//
	// auth may come back as NULL, and that's just fine.  It signals 
	// that we're not being executed by AuthorizationExecuteWithPrivileges.
	
	auth = MoreSecHelperToolCopyAuthRef();
	
	// Because we're normally running as a setuid root program, it's 
	// important that we not trust any information coming to us from 
	// our potentially malicious parent process.  
	// MoreSecDestroyInheritedEnvironment eliminates all sources of 
	// such information, so we can't depend on it ever if we try.
	
	err = MoreSecDestroyInheritedEnvironment(kMoreSecKeepStandardFilesMask, argv);
	
	// Mask SIGPIPE, otherwise stuff won't work properly.
	
	if (err == 0) {
		err = MoreUNIXIgnoreSIGPIPE();
	}
	
	// Call the MoreSecurity helper routine.
	
	if (err == 0) {
		err = MoreSecHelperToolMain(STDIN_FILENO, STDOUT_FILENO, auth, PerformCommand, argc, argv);
	}
	
	// Map the error code to a tool result.
	
	result = MoreSecErrorToHelperToolResult(err);
	
	return result;
}
