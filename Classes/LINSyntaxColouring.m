// This code is, with some alterations, from one of my other programs, Smultron http://smultron.sourceforge.net

// expertTextView delegate

//
//  LINSyntaxColouring.m
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


#import "LINSyntaxColouring.h"
#import "LINEditPlistController.h"

@implementation LINSyntaxColouring

static id sharedInstance = nil;

+ (LINSyntaxColouring *)sharedInstance
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
	textView = [[LINEditPlistController sharedInstance] expertTextView];
	layoutManager = [textView layoutManager];
	completeString = [textView string];
	
	commandsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.97 alpha:1.0], NSForegroundColorAttributeName, nil];
	stringsColour = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor colorWithCalibratedRed:0.95 green:0.0 blue:0.0 alpha:1.0], NSForegroundColorAttributeName, nil];	
}


-(void)textDidChange:(NSNotification *)notification
{
	[self recolourCompleteDocument];
}


-(void)recolourCompleteDocument
{
	scanner = [[NSScanner alloc] initWithString:completeString];
	[scanner setCharactersToBeSkipped:nil];
	
	int completeStringLength = [completeString length];
	int beginning;
	int endOfLine;
	int commandLocation;
	int skipEndCommand;
	int index;
	
	unichar commandCharacterTest;
	
	BOOL beginningIsOnACommand;
	BOOL thereHasBeenACommandEarlierOnTheLine;
	BOOL foundMatch;
	
	NSRange rangeOfLine;
	
	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0, [completeString length])];
	
	NS_DURING // if there are any exceptions raised by this section just pass through and stop colouring instead of throwing an exception and refuse to load the textview 
		
	//commands
	int searchSyntaxLength = 1;
	NSString *beginCommand = @"<";
	NSString *endCommand = @">";
	unichar beginCommandCharacter = '<';
	unichar endCommandCharacter = '>';
	while (![scanner isAtEnd]) {
		[scanner scanUpToString:beginCommand intoString:nil];
		beginning = [scanner scanLocation];
		endOfLine = NSMaxRange([completeString lineRangeForRange:NSMakeRange(beginning, 0)]);
		if (![scanner scanUpToString:endCommand intoString:nil] || [scanner scanLocation] >= endOfLine) {
			[scanner setScanLocation:endOfLine];
			continue; // don't colour it if it hasn't got a closing tag
		} else {
			// to avoid problems with strings like <yada <%=yada%> yada> we need to balance the number of begin- and end-tags
			// if ever there's a beginCommand or endCommand with more than one character then do a check first
			commandLocation = beginning + 1;
			skipEndCommand = 0;
			
			while (commandLocation < endOfLine) {
				commandCharacterTest = [completeString characterAtIndex:commandLocation];
				if (commandCharacterTest == endCommandCharacter) {
					if (!skipEndCommand) 
						break;
					else
						skipEndCommand--;
				}
				if (commandCharacterTest == beginCommandCharacter) skipEndCommand++;
				commandLocation++;
			}
			if (commandLocation < endOfLine)
				[scanner setScanLocation:commandLocation + searchSyntaxLength];
			else
				[scanner setScanLocation:endOfLine];
		}
		[layoutManager addTemporaryAttributes:commandsColour forCharacterRange:NSMakeRange(beginning, [scanner scanLocation] - beginning)];	 
	}

	//second string
	[scanner setScanLocation:0];
	endOfLine = completeStringLength;
	while (![scanner isAtEnd]) {
		beginningIsOnACommand = NO;
		thereHasBeenACommandEarlierOnTheLine = NO;
		foundMatch = NO;
		[scanner scanUpToString:@"'" intoString:nil];
		beginning = [scanner scanLocation];
		if (beginning >= completeStringLength) break;
		if ([completeString characterAtIndex:beginning - 1] == '\\') {
			[scanner setScanLocation:beginning + 1];
			continue; // to avoid e.g. \'
		}
		
		rangeOfLine = [completeString lineRangeForRange:NSMakeRange(beginning, 0)];

		if ([[layoutManager temporaryAttributesAtCharacterIndex:0 effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
			beginningIsOnACommand = YES;
		} else {
			commandLocation = [completeString rangeOfString:beginCommand options:NSLiteralSearch range:rangeOfLine].location;
			if (commandLocation != NSNotFound && commandLocation < beginning)
				thereHasBeenACommandEarlierOnTheLine = YES;
		}

		endOfLine = NSMaxRange(rangeOfLine);
		index = beginning + 1;				
		while (index < endOfLine) {
			if ([completeString characterAtIndex:index] == '\'') {
				if ([completeString characterAtIndex:index - 1] == '\\') {
					index++;
					continue;
				} else {
					index++;
					foundMatch = YES;
					break;
				}
			}
			index++;
		}
		
		if (!thereHasBeenACommandEarlierOnTheLine) {
			if (beginningIsOnACommand || foundMatch) {
				[scanner setScanLocation:index];
				[layoutManager addTemporaryAttributes:stringsColour forCharacterRange:NSMakeRange(beginning, index - beginning)];
			} else {
				[scanner setScanLocation:beginning + 1];
			}
		} else { 
			[scanner setScanLocation:beginning + 1];
		}
	}


	//first string
	[scanner setScanLocation:0];
	endOfLine = completeStringLength;
	while (![scanner isAtEnd]) {
		beginningIsOnACommand = NO;
		thereHasBeenACommandEarlierOnTheLine = NO;
		foundMatch = NO;
		[scanner scanUpToString:@"\"" intoString:nil];
		beginning = [scanner scanLocation];
		if (beginning >= completeStringLength) break;
		if ([completeString characterAtIndex:beginning - 1] == '\\') {
			[scanner setScanLocation:beginning + 1];
			continue; // to avoid e.g. \"
		}
		if ([[layoutManager temporaryAttributesAtCharacterIndex:beginning effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
			[scanner setScanLocation:beginning + 1];
			continue; // if the first string is within a second string disregard it
		}
		
		rangeOfLine = [completeString lineRangeForRange:NSMakeRange(beginning, 0)];
		if ([[layoutManager temporaryAttributesAtCharacterIndex:beginning effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
			beginningIsOnACommand = YES;
		} else {
			commandLocation = [completeString rangeOfString:beginCommand options:NSLiteralSearch range:rangeOfLine].location;
			if (commandLocation != NSNotFound && commandLocation < beginning) {
				if (![[layoutManager temporaryAttributesAtCharacterIndex:commandLocation effectiveRange:NULL] isEqualToDictionary:stringsColour]) { // if the command isn't within a string
					thereHasBeenACommandEarlierOnTheLine = YES;
				}
			}
		}

		endOfLine = NSMaxRange([completeString lineRangeForRange:NSMakeRange(beginning, 0)]);
		index = beginning + 1;
		while (index < endOfLine) {
			if ([completeString characterAtIndex:index] == '"') {
				if ([completeString characterAtIndex:index - 1] == '\\') {
					index++;
					continue;
				} else {
					index++;
					foundMatch = YES;
					break;
				}
			}
			index++;
		}
		
		if (!thereHasBeenACommandEarlierOnTheLine) {
			if (beginningIsOnACommand || foundMatch) {
				[scanner setScanLocation:index];
				[layoutManager addTemporaryAttributes:stringsColour forCharacterRange:NSMakeRange(beginning, index - beginning)];
			} else {
				[scanner setScanLocation:beginning + 1];
			}
		} else { 
			[scanner setScanLocation:beginning + 1];
		}
	}

	NS_HANDLER // if there are any exceptions raised, just continue and leave it uncoloured
	NS_ENDHANDLER	
	[scanner release];

}

@end
