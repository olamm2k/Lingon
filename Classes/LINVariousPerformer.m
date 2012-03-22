/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LINVariousPerformer.h"
#import "LINMainController.h"
#import "LINPlistsController.h"
#import "LINSecureToolCommunication.h"
#import "LINActionMenuController.h"

@implementation LINVariousPerformer

static id sharedInstance = nil;

+ (LINVariousPerformer *)sharedInstance
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


-(void)updateContentsForTab:(NSTabViewItem *)tabViewItem loadedArray:(NSArray *)loadedArray
{
	NSString *path;
	NSString *identifier = [tabViewItem identifier];
	if ([identifier isEqual:@"1"]) {
		path = MYAGENTS;
	} else if ([identifier isEqual:@"2"]) {
		path = USERSAGENTS;
	} else if ([identifier isEqual:@"3"]) {
		path = USERSDAEMONS;
	} else if ([identifier isEqual:@"4"]) {
		path = SYSTEMAGENTS;
	} else if ([identifier isEqual:@"5"]) {
		path = SYSTEMDAEMONS;
	}
	
	[[[LINPlistsController sharedInstance] plistsArray] removeAllObjects];

	NSDictionary *dictionary;
	NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
	id item;
	while (item = [enumerator nextObject]) {
		if ([item isEqualToString:@".DS_Store"]) continue;
		dictionary = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:item]];
		if (dictionary) {
			@try {
				[self insertPlistIntoContext:dictionary filename:item loadedArray:loadedArray];
			}
			@catch (NSException * e) {
			}
			@finally {
				[dictionary release];
			}
		}
		
	}
	
	[self updateCountsInTabViewItemLabels];
  
	[[[LINPlistsController sharedInstance] arrayController] rearrangeObjects];
}


-(void)insertPlistIntoContext:(NSDictionary *)plist filename:(NSString *)filename loadedArray:(NSArray *)loadedArray
{
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:[self convertDictionary:plist]];
	
	NSString *label = [plist valueForKey:@"Label"];
	if (loadedArray == nil) {
		[dictionary setValue:[[NSBundle mainBundle] pathForResource:@"LINUnknownState" ofType:@"pdf"] forKey:@"loadedImagePath"];
	} else if ([loadedArray containsObject:label]) {
		[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"loaded"];
		[dictionary setValue:[[NSBundle mainBundle] pathForResource:@"LINLoaded" ofType:@"pdf"] forKey:@"loadedImagePath"];
	} else {
		[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"loaded"];
		[dictionary setValue:[[NSBundle mainBundle] pathForResource:@"LINNotLoaded" ofType:@"pdf"] forKey:@"loadedImagePath"];
	}
			   
	[dictionary setValue:filename forKey:@"filename"];
	
	[[[LINPlistsController sharedInstance] plistsArray] addObject:dictionary];
	[dictionary release];
}


-(NSMutableDictionary *)convertDictionary:(NSDictionary *)originalDictionary
{
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:originalDictionary];
	NSEnumerator *enumerator;
	id item;
	
	NSMutableArray *programArguments = [[NSMutableArray alloc] init];
	enumerator = [[originalDictionary valueForKey:@"ProgramArguments"] objectEnumerator];
	while (item = [enumerator nextObject]) {
		[programArguments addObject:[NSMutableDictionary dictionaryWithObject:item forKey:@"argument"]];
	}
	[dictionary setValue:programArguments forKey:@"ProgramArguments"];
	[programArguments release];
	
	
	NSMutableArray *environmentVariables = [[NSMutableArray alloc] init];
	enumerator = [[originalDictionary valueForKey:@"EnvironmentVariables"] keyEnumerator];
	while (item = [enumerator nextObject]) {
		NSMutableDictionary *environmentVariable = [[NSMutableDictionary alloc] init];
		[environmentVariable setValue:item forKey:@"key"];
		[environmentVariable setValue:[[originalDictionary valueForKey:@"EnvironmentVariables"] valueForKey:item] forKey:@"value"];
		[environmentVariables addObject:environmentVariable];
		[environmentVariable release];
	}
	[dictionary setValue:environmentVariables forKey:@"EnvironmentVariables"];
	[environmentVariables release];
	
	NSMutableArray *watchPaths = [[NSMutableArray alloc] init];
	enumerator = [[originalDictionary valueForKey:@"WatchPaths"] objectEnumerator];
	while (item = [enumerator nextObject]) {
		[watchPaths addObject:[NSMutableDictionary dictionaryWithObject:item forKey:@"path"]];
	}
	[dictionary setValue:watchPaths forKey:@"WatchPaths"];
	[watchPaths release];
	
	NSMutableArray *queueDirectories = [[NSMutableArray alloc] init];
	enumerator = [[originalDictionary valueForKey:@"QueueDirectories"] objectEnumerator];
	while (item = [enumerator nextObject]) {
		[queueDirectories addObject:[NSMutableDictionary dictionaryWithObject:item forKey:@"path"]];
	}
	[dictionary setValue:queueDirectories forKey:@"QueueDirectories"];
	[queueDirectories release];
	
	NSMutableArray *sockets = [[NSMutableArray alloc] init];
	enumerator = [[originalDictionary valueForKey:@"Sockets"] keyEnumerator];
	while (item = [enumerator nextObject]) {
		if ([[[originalDictionary valueForKey:@"Sockets"] valueForKey:item] isKindOfClass:[NSArray class]]) { // to check if it's a dictionary of arrays of dictionaries
			int count = [[[originalDictionary valueForKey:@"Sockets"] valueForKey:item] count]; 
			int index;
			for (index = 0; index < count; index++) {
				[self setBonjourForItem:item inArray:sockets inPlist:originalDictionary socketDictionary:[[[originalDictionary valueForKey:@"Sockets"] valueForKey:item] objectAtIndex:index] fromInnerArray:YES];
			}
		} else {
			[self setBonjourForItem:item inArray:sockets inPlist:originalDictionary socketDictionary:[[originalDictionary valueForKey:@"Sockets"] valueForKey:item] fromInnerArray:NO];
		}
		
	}
	[dictionary setValue:sockets forKey:@"Sockets"];
	[sockets release];
	
	if ([dictionary valueForKey:@"inetdCompatibility"]) {
		if ([[dictionary valueForKey:@"inetdCompatibility"] valueForKey:@"Wait"]) {
			if ([[[dictionary valueForKey:@"inetdCompatibility"] valueForKey:@"Wait"] boolValue]) {
				[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"inetdCompatibilityWait"];
			}
		}
		[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"inetdCompatibility"];
	}
	
	return [dictionary autorelease];
}


-(void)setBonjourForItem:(NSString *)item inArray:(NSMutableArray *)sockets inPlist:(NSDictionary *)thePlist socketDictionary:(NSDictionary *)socketDictionary fromInnerArray:(BOOL)fromInnerArray
{
	if (![socketDictionary isKindOfClass:[NSDictionary class]]) {
		return;
	}
	
	NSMutableDictionary *socket = [[NSMutableDictionary alloc] init];
	[socket setValue:item forKey:@"socket"];
	NSMutableDictionary *socketValues = [[NSMutableDictionary alloc] initWithDictionary:socketDictionary];
	
	if ([socketValues valueForKey:@"Bonjour"]) {
		if ([[socketValues valueForKey:@"Bonjour"] isKindOfClass:[NSNumber class]]) {
			if ([[socketValues valueForKey:@"Bonjour"] boolValue]) {
				[socketValues setValue:[NSNumber numberWithBool:YES] forKey:@"bonjourIsSet"];
			}
		} else if ([[socketValues valueForKey:@"Bonjour"] isKindOfClass:[NSString class]]) { 
			[socketValues setValue:[NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObject:[socketValues valueForKey:@"Bonjour"] forKey:@"name"]] forKey:@"bonjourValues"];
			[socketValues setValue:[NSNumber numberWithBool:YES] forKey:@"bonjourIsSet"];
		} else if ([[socketValues valueForKey:@"Bonjour"] isKindOfClass:[NSArray class]]) {
			NSEnumerator *socketValuesEnumerator = [[socketValues valueForKey:@"Bonjour"] objectEnumerator];
			id socketValuesItem;
			NSMutableArray *socketValuesArray = [[NSMutableArray alloc] init];
			while (socketValuesItem = [socketValuesEnumerator nextObject]) {
				[socketValuesArray addObject:[NSMutableDictionary dictionaryWithObject:socketValuesItem forKey:@"name"]];
			}
			[socketValues setValue:socketValuesArray forKey:@"bonjourValues"];
			[socketValuesArray release];
			[socketValues setValue:[NSNumber numberWithBool:YES] forKey:@"bonjourIsSet"];
		}
	}
	
	[socketValues removeObjectForKey:@"Bonjour"];
	
	[socket setValue:[NSNumber numberWithBool:fromInnerArray] forKey:@"fromInnerArray"];
	[socket setValue:socketValues forKey:@"socketValues"];
	[socketValues release];
	[sockets addObject:socket];
	[socket release];
}


-(void)updateCountsInTabViewItemLabels
{
	[self updateLabelForIndex:0 count:[self folderCountForPath:MYAGENTS] label:MYAGENTSSTRING];
	[self updateLabelForIndex:1 count:[self folderCountForPath:USERSAGENTS] label:USERSAGENTSSTRING];
	[self updateLabelForIndex:2 count:[self folderCountForPath:USERSDAEMONS] label:USERSDAEMONSSTRING];
	[self updateLabelForIndex:3 count:[self folderCountForPath:SYSTEMAGENTS] label:SYSTEMAGENTSSTRING];
	[self updateLabelForIndex:4 count:[self folderCountForPath:SYSTEMDAEMONS] label:SYSTEMDAEMONSSTRING];
}


-(int)folderCountForPath:(NSString *)path
{
	int count = 0;
	NSArray *folderContents = [[NSFileManager defaultManager] directoryContentsAtPath:path];
	if ([folderContents containsObject:@".DS_Store"]) {
		count = [folderContents count] - 1;
	} else {
		count = [folderContents count];
	}

	return count;
}


-(void)updateLabelForIndex:(int)index count:(int)count label:(NSString *)label
{
	NSTabView *tabView = [[LINMainController sharedInstance] mainTabView];
	if (count) {
		[[tabView tabViewItemAtIndex:index] setLabel:[NSString stringWithFormat:@"%@ (%d)", label, count]];
	} else {
		[[tabView tabViewItemAtIndex:index] setLabel:label];
	}
}


-(void)insertTableColumn:(NSTableColumn *)tableColumn
{
	[[[LINMainController sharedInstance] mainTableView] addTableColumn:tableColumn];
	[self configureTableColumn:tableColumn];
}


-(void)configureTableColumn:(NSTableColumn *)tableColumn
{
	NSString *title = [[tableColumn headerCell] title];
	[tableColumn setIdentifier:title];
	[tableColumn setEditable:NO];
	
	NSArrayController *arrayController = [[LINPlistsController sharedInstance] arrayController];
	
	if ([title isEqual:@"Loaded"]) {
		NSImageCell *imageCell = [[NSImageCell alloc] init];
		[tableColumn setDataCell:imageCell];
		[imageCell release];
		[tableColumn bind:@"valuePath" toObject:arrayController withKeyPath:@"arrangedObjects.loadedImagePath" options:nil];
		
	
	} else if ([title isEqual:@"Filename"]) {
		[tableColumn bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.filename" options:nil];
		
	} else if ([title isEqual:@"Label"] || [title isEqual:@"UserName"] || [title isEqual:@"GroupName"] || [title isEqual:@"Program"] || [title isEqual:@"RootDirectory"] || [title isEqual:@"WorkingDirectory"] || [title isEqual:@"ServiceDescription"] || [title isEqual:@"Umask"] || [title isEqual:@"TimeOut"] || [title isEqual:@"StartInterval"] || [title isEqual:@"StandardOutPath"] || [title isEqual:@"StandardErrorPath"] || [title isEqual:@"Nice"]) {
		[tableColumn bind:@"value" toObject:arrayController withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", title] options:nil];
	
	} else if ([title isEqual:@"Disabled"] || [title isEqual:@"OnDemand"] || [title isEqual:@"RunAtLoad"] || [title isEqual:@"ServiceIPC"] || [title isEqual:@"InitGroups"] || [title isEqual:@"Debug"] || [title isEqual:@"LowPriorityIO"] || [title isEqual:@"inetdCompatibility"]) {
		[tableColumn bind:@"value" toObject:arrayController withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", title] options:[NSDictionary dictionaryWithObject:@"BoolTransformer" forKey:@"NSValueTransformerName"]];
		[tableColumn bind:@"textColor" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", title] options:[NSDictionary dictionaryWithObject:@"BoolColourTransformer" forKey:@"NSValueTransformerName"]];
	
	} else if ([title isEqual:@"ProgramArguments"]) {
		[tableColumn bind:@"value" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:@"arrangedObjects.ProgramArguments" options:[NSDictionary dictionaryWithObject:@"ProgramArgumentsTransformer" forKey:@"NSValueTransformerName"]];
		
	} else if ([title isEqual:@"StartCalendarInterval"]) {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"StartCalendarInterval" ascending:NO selector:@selector(calSort:)];
    [tableColumn setSortDescriptorPrototype:sortDescriptor];
    [sortDescriptor release];
    
		[tableColumn bind:@"value"
             toObject:[[LINPlistsController sharedInstance] arrayController]
          withKeyPath:@"arrangedObjects.StartCalendarInterval"
              options:[NSDictionary dictionaryWithObject:@"CalendarTransformer" forKey:@"NSValueTransformerName"]];
	} else if ([title isEqual:@"SoftResourceLimits"]) {
		[tableColumn bind:@"value" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:@"arrangedObjects.SoftResourceLimits" options:[NSDictionary dictionaryWithObject:@"ResourceLimitsTransformer" forKey:@"NSValueTransformerName"]];
		
	} else if ([title isEqual:@"HardResourceLimits"]) {
		[tableColumn bind:@"value" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:@"arrangedObjects.HardResourceLimits" options:[NSDictionary dictionaryWithObject:@"ResourceLimitsTransformer" forKey:@"NSValueTransformerName"]];
		
	} else if ([title isEqual:@"Sockets"]) {
		[tableColumn bind:@"value" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:@"arrangedObjects.Sockets" options:[NSDictionary dictionaryWithObject:@"SocketsTransformer" forKey:@"NSValueTransformerName"]];

	} else if ([title isEqual:@"EnvironmentVariables"]) {
		[tableColumn bind:@"value" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:@"arrangedObjects.EnvironmentVariables" options:[NSDictionary dictionaryWithObject:@"EnvironmentVariablesTransformer" forKey:@"NSValueTransformerName"]];
		
	} else if ([title isEqual:@"WatchPaths"]) {
		[tableColumn bind:@"value" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:@"arrangedObjects.WatchPaths" options:[NSDictionary dictionaryWithObject:@"PathsTransformer" forKey:@"NSValueTransformerName"]];
	
	} else if ([title isEqual:@"QueueDirectories"]) {
		[tableColumn bind:@"value" toObject:[[LINPlistsController sharedInstance] arrayController] withKeyPath:@"arrangedObjects.QueueDirectories" options:[NSDictionary dictionaryWithObject:@"PathsTransformer" forKey:@"NSValueTransformerName"]];
	}
}


-(NSDictionary *)convertPartsOfDictionaryBeforePlist:(NSDictionary *)dictionary
{
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
	
	[returnDictionary removeObjectForKey:@"loaded"];
	[returnDictionary removeObjectForKey:@"loadedImagePath"];
	[returnDictionary removeObjectForKey:@"filename"];
	
	if ([returnDictionary valueForKey:@"StartCalendarInterval"]) {
		if (![[returnDictionary valueForKey:@"StartCalendarInterval"] count]) {
			[returnDictionary removeObjectForKey:@"StartCalendarInterval"];
		}
	}
	
	if ([returnDictionary valueForKey:@"SoftResourceLimits"]) {
		if (![[returnDictionary valueForKey:@"SoftResourceLimits"] count]) {
			[returnDictionary removeObjectForKey:@"SoftResourceLimits"];
		}
	}
	
	if ([returnDictionary valueForKey:@"HardResourceLimits"]) {
		if (![[returnDictionary valueForKey:@"HardResourceLimits"] count]) {
			[returnDictionary removeObjectForKey:@"HardResourceLimits"];
		}
	}
	
	NSEnumerator *enumerator;
	id item;
	
	if ([dictionary valueForKey:@"ProgramArguments"]) {
		NSMutableArray *programArguments = [[NSMutableArray alloc] init];
		enumerator = [[dictionary valueForKey:@"ProgramArguments"] objectEnumerator];
		while (item = [enumerator nextObject]) {
			if ([[item valueForKey:@"argument"] isKindOfClass:[NSString class]]) {
				[programArguments addObject:[item valueForKey:@"argument"]];
			}
		}
		if ([programArguments count] != 0) {
			[returnDictionary setValue:programArguments forKey:@"ProgramArguments"];
		} else {
			[returnDictionary removeObjectForKey:@"ProgramArguments"];
		}
		[programArguments release];
	}
	
	if ([dictionary valueForKey:@"EnvironmentVariables"]) {
		NSMutableDictionary *environmentVariables = [[NSMutableDictionary alloc] init];
		enumerator = [[dictionary valueForKey:@"EnvironmentVariables"] objectEnumerator];
		while (item = [enumerator nextObject]) {
			if ([[item valueForKey:@"value"] isKindOfClass:[NSString class]]) {
				[environmentVariables setValue:[item valueForKey:@"value"] forKey:[item valueForKey:@"key"]];
			}
		}
		if ([environmentVariables count] != 0) {
			[returnDictionary setValue:environmentVariables forKey:@"EnvironmentVariables"];
		} else {
			[returnDictionary removeObjectForKey:@"EnvironmentVariables"];
		}
		[environmentVariables release];
	}
	
	if ([dictionary valueForKey:@"WatchPaths"]) {
		NSMutableArray *watchPaths = [[NSMutableArray alloc] init];
		enumerator = [[dictionary valueForKey:@"WatchPaths"] objectEnumerator];
		while (item = [enumerator nextObject]) {
			if ([[item valueForKey:@"path"] isKindOfClass:[NSString class]]) {
				[watchPaths addObject:[item valueForKey:@"path"]];
			}
		}
		if ([watchPaths count] != 0) {
			[returnDictionary setValue:watchPaths forKey:@"WatchPaths"];
		} else {
			[returnDictionary removeObjectForKey:@"WatchPaths"];
		}
		[watchPaths release];
	}
	
	if ([dictionary valueForKey:@"QueueDirectories"]) {
		NSMutableArray *queueDirectories = [[NSMutableArray alloc] init];
		enumerator = [[dictionary valueForKey:@"QueueDirectories"] objectEnumerator];
		while (item = [enumerator nextObject]) {
			if ([[item valueForKey:@"path"] isKindOfClass:[NSString class]]) {
				[queueDirectories addObject:[item valueForKey:@"path"]];
			}
		}
		if ([queueDirectories count] != 0) {
			[returnDictionary setValue:queueDirectories forKey:@"QueueDirectories"];
		} else {
			[returnDictionary removeObjectForKey:@"QueueDirectories"];
		}
		[queueDirectories release];
	}
	
	if ([dictionary valueForKey:@"Sockets"]) {
		NSMutableDictionary *sockets = [[NSMutableDictionary alloc] init];
		NSMutableArray *socketsInInnerArray = [[NSMutableArray alloc] init];
		NSString *socketsInInnerArrayKey;
		enumerator = [[dictionary valueForKey:@"Sockets"] objectEnumerator];
		NSMutableDictionary *socket; 
		NSMutableArray *bonjourValues;
		NSEnumerator *bonjourValuesEnumerator;
		id socketValue;
		while (item = [enumerator nextObject]) {
			socket = [[NSMutableDictionary alloc] initWithDictionary:[item valueForKey:@"socketValues"]];
			if ([socket valueForKey:@"bonjourIsSet"]) {
				if (![[socket valueForKey:@"bonjourIsSet"] boolValue]) {
					[socket setValue:[NSNumber numberWithBool:NO] forKey:@"Bonjour"];
				} else if (![socket valueForKey:@"bonjourValues"]) {
					[socket setValue:[NSNumber numberWithBool:YES] forKey:@"Bonjour"];
				} else if ([[socket valueForKey:@"bonjourValues"] count] == 1) {
					[socket setValue:[[[socket valueForKey:@"bonjourValues"] objectAtIndex:0] valueForKey:@"name"] forKey:@"Bonjour"];
				} else {
					bonjourValues = [[NSMutableArray alloc] init];
					bonjourValuesEnumerator = [[socket valueForKey:@"bonjourValues"] objectEnumerator];
					while (socketValue = [bonjourValuesEnumerator nextObject]) {
						if ([[socketValue valueForKey:@"name"] isKindOfClass:[NSString class]]) {
							[bonjourValues addObject:[socketValue valueForKey:@"name"]];
						}
					}
					[socket setValue:bonjourValues forKey:@"Bonjour"];
					[bonjourValues release];
				}			
			}

			[socket removeObjectForKey:@"bonjourValues"];
			[socket removeObjectForKey:@"bonjourIsSet"];
			if ([item valueForKey:@"fromInnerArray"] && [[item valueForKey:@"fromInnerArray"] boolValue]) {
				[socket removeObjectForKey:@"fromInnerArray"];
				socketsInInnerArrayKey = [item valueForKey:@"socket"];
				[socketsInInnerArray addObject:socket];
				
			} else {
				if ([[item valueForKey:@"socket"] isKindOfClass:[NSString class]]) {
					[sockets setValue:socket forKey:[item valueForKey:@"socket"]];
				}
			}
			[socket release];
		}
		
		if ([socketsInInnerArray count] > 0) {
			[sockets setValue:socketsInInnerArray forKey:socketsInInnerArrayKey];			
		}
		[socketsInInnerArray release];
		
		if ([sockets count] != 0) {
			[returnDictionary setValue:sockets forKey:@"Sockets"];
		} else {
			[returnDictionary removeObjectForKey:@"Sockets"];
		}
		[sockets release];
	}
	
	
	if ([dictionary valueForKey:@"inetdCompatibility"] && [[dictionary valueForKey:@"inetdCompatibility"] boolValue]) {
		NSMutableDictionary *inetdCompatibility = [[NSMutableDictionary alloc] init];
		if ([[dictionary valueForKey:@"inetdCompatibilityWait"] boolValue]) {
			[inetdCompatibility setValue:[NSNumber numberWithBool:YES] forKey:@"Wait"];
		} else {
			[inetdCompatibility setValue:[NSNumber numberWithBool:NO] forKey:@"Wait"];
		}
		[returnDictionary setValue:inetdCompatibility forKey:@"inetdCompatibility"];
		[inetdCompatibility release];
	} else if ([[dictionary valueForKey:@"inetdCompatibility"] boolValue] == NO) {
		[returnDictionary removeObjectForKey:@"inetdCompatibility"];
	}
	[returnDictionary removeObjectForKey:@"inetdCompatibilityWait"];
	
	
	// to make sure that they are saved as integer and nothing else
	if ([returnDictionary valueForKey:@"StartCalendarInterval"]) {
		enumerator = [[[returnDictionary valueForKey:@"StartCalendarInterval"] allKeys] objectEnumerator];
		while (item = [enumerator nextObject]) {
			[[returnDictionary valueForKey:@"StartCalendarInterval"] setValue:[NSNumber numberWithInt:[[[returnDictionary valueForKey:@"StartCalendarInterval"] valueForKey:item] intValue]] forKey:item];
		}
	}
	
	if ([returnDictionary valueForKey:@"SoftResourceLimits"]) {
		enumerator = [[[returnDictionary valueForKey:@"SoftResourceLimits"] allKeys] objectEnumerator];
		while (item = [enumerator nextObject]) {
			[[returnDictionary valueForKey:@"SoftResourceLimits"] setValue:[NSNumber numberWithInt:[[[returnDictionary valueForKey:@"SoftResourceLimits"] valueForKey:item] intValue]] forKey:item];
		}
	}
	
	if ([returnDictionary valueForKey:@"HardResourceLimits"]) {
		enumerator = [[[returnDictionary valueForKey:@"HardResourceLimits"] allKeys] objectEnumerator];
		while (item = [enumerator nextObject]) {
			[[returnDictionary valueForKey:@"HardResourceLimits"] setValue:[NSNumber numberWithInt:[[[returnDictionary valueForKey:@"HardResourceLimits"] valueForKey:item] intValue]] forKey:item];
		}
	}
	
	if ([returnDictionary valueForKey:@"Umask"]) {
		[returnDictionary setValue:[NSNumber numberWithInt:[[returnDictionary valueForKey:@"Umask"] intValue]] forKey:@"Umask"];
	}
	
	if ([returnDictionary valueForKey:@"TimeOut"]) {
		[returnDictionary setValue:[NSNumber numberWithInt:[[returnDictionary valueForKey:@"TimeOut"] intValue]] forKey:@"TimeOut"];
	}
	
	if ([returnDictionary valueForKey:@"StartInterval"]) {
		[returnDictionary setValue:[NSNumber numberWithInt:[[returnDictionary valueForKey:@"StartInterval"] intValue]] forKey:@"StartInterval"];
	}
	
	if ([returnDictionary valueForKey:@"Nice"]) {
		[returnDictionary setValue:[NSNumber numberWithInt:[[returnDictionary valueForKey:@"Nice"] intValue]] forKey:@"Nice"];
	}
	
	return returnDictionary;
}


-(NSString *)performTask:(NSString *)launchPath arguments:(NSArray *)arguments
{
	NSTask *task = [[NSTask alloc] init];
	NSPipe *errorPipe = [[NSPipe alloc] init];
	
	[task setLaunchPath:launchPath];
	[task setArguments:arguments];
	[task setStandardError:errorPipe];
	
	[task launch];
	
	[task waitUntilExit];

	NSString *returnString;
	NSData *data;

	int status = [task terminationStatus];

	if (status == 0) {
		returnString = @"";
	} else {
		data = [[errorPipe fileHandleForReading] readDataToEndOfFile];
		NSString *errorString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		returnString = [[[NSString alloc] initWithFormat:@"LingonError: %@", errorString] autorelease];
		[errorString release];
	}
	
	[errorPipe release];
	[task release];
	
	return returnString;
}


-(NSArray *)getLoadedArray
{
	NSString *loadedString;
	if (![[LINMainController sharedInstance] needSecureTool]) {
		// Use this roundabout way instead of loadedString = [self performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObject:@"list"]] because if one runs performTask with launchctl list and it doesn't return anything, readDataToEndOfFile can lock everything for half a minute, so this is a way of working around it; it has been reported to Apple
		
		NSString *path = [self genererateTempPath];
		system([[NSString stringWithFormat:@"/bin/launchctl list > %@", path] UTF8String]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			loadedString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		} else {
			loadedString = @"";
		}
		
	} else {
		NSDictionary *returnDictionary = [[LINSecureToolCommunication sharedInstance] performCommandAuthenticated:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:LINAuthActionGetLoadedLaunchd] forKey:@"task"]];
		
		if ([[LINSecureToolCommunication sharedInstance] hasError:returnDictionary]) {
			return nil;
		}
		
		loadedString = [returnDictionary valueForKey:@"returnString"];
	}
	
	NSArray *returnArray = [loadedString componentsSeparatedByString:@"\n"];
	
	return returnArray;
}


-(NSString *)genererateTempPath
{
	int sequenceNumber = 0;
	NSString *tempPath;
	do {
		sequenceNumber++;
		tempPath = [NSString stringWithFormat:@"%d-%d-%d.%@", [[NSProcessInfo processInfo] processIdentifier], (int)[NSDate timeIntervalSinceReferenceDate], sequenceNumber, @"Lingon"];
		tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempPath];
	} while ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]);

	return tempPath;
}


-(BOOL)performSaveOfDictionary:(NSDictionary *)dictionary toFolder:(int)folder filename:(NSString *)filename action:(LINAfterSaveAction)action
{	
	if (![[LINMainController sharedInstance] needSecureTool]) {
		if (![[NSFileManager defaultManager] fileExistsAtPath:MYAGENTS]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:MYAGENTS attributes:nil];
		}
		
		if (![dictionary writeToFile:[MYAGENTS stringByAppendingPathComponent:filename] atomically:YES]) {
			[self cannotSavePath:[MYAGENTS stringByAppendingPathComponent:filename]];
		}
		if (action == LINAfterSaveLoad) {
			NSString *convertedPath = [NSString stringWithUTF8String:[[MYAGENTS stringByAppendingPathComponent:filename] UTF8String]];
			[self performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load", @"-w", convertedPath, nil]];
		} else if (action == LINAfterSaveReload) {
			NSString *convertedPath = [NSString stringWithUTF8String:[[MYAGENTS stringByAppendingPathComponent:filename] UTF8String]];
			[self performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"unload", @"-w", convertedPath, nil]];
			[self performTask:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load", @"-w", convertedPath, nil]];
		}
		
		[[LINVariousPerformer sharedInstance] updateContentsForTab:[[[LINMainController sharedInstance] mainTabView] selectedTabViewItem] loadedArray:[self getLoadedArray]];
		
	} else {
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:LINAuthActionSave], dictionary, [NSNumber numberWithInt:folder], filename, [NSNumber numberWithInt:action], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"task", @"dictionary", @"folder", @"filename", @"action", nil];
		[[LINActionMenuController sharedInstance] prepareAndRunAuthenticatedCommand:objects keys:keys errorString:@"save" errorPath:[dictionary valueForKey:@"Label"]];
	}
	
	return YES;
}


-(void)cannotSavePath:(NSString *)path
{
	[[LINMainController sharedInstance] alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"An unknown error occurred when saving %@", @"An unknown error occurred when saving %@ in cannotSavePath"), path] informativeText:@"" defaultButton:NSLocalizedString(@"Bummer", @"Bummer-button in cannotSavePath") alternateButton:nil otherButton:nil];
}


-(void)selectLabel:(NSString *)label
{
	int index;
	NSArray *arrangedObjects = [[[LINPlistsController sharedInstance] arrayController] arrangedObjects];
	int count = [arrangedObjects count];
	for (index = 0; index < count; index++) {
		if ([[[arrangedObjects objectAtIndex:index] valueForKey:@"Label"] isEqual:label]) {
			[[[LINPlistsController sharedInstance] arrayController] setSelectionIndex:index];
			break;
		}
	}
}

@end
