//
//  LINCalendarTransformer.m
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

#import "LINCalendarTransformer.h"

@implementation LINCalendarTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}


+(BOOL)allowsReverseTransformation
{
    return NO;
}


-(id)transformedValue:(id)value
{
	NSMutableString *returnString = [NSMutableString stringWithString:@""];
	if ([value valueForKey:@"Minute"]) {
		[returnString appendFormat:@"M:%@", [[value valueForKey:@"Minute"] stringValue]];
	}
	if ([value valueForKey:@"Hour"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
		[returnString appendFormat:@"H:%@", [[value valueForKey:@"Hour"] stringValue]];
	}
	if ([value valueForKey:@"Day"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
		[returnString appendFormat:@"D:%@", [[value valueForKey:@"Day"] stringValue]];
	}
	if ([value valueForKey:@"Weekday"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
		[returnString appendFormat:@"W:%@", [[value valueForKey:@"Weekday"] stringValue]];
	}
	if ([value valueForKey:@"Month"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
		[returnString appendFormat:@"Month:%@", [[value valueForKey:@"Month"] stringValue]];
	}
	
	return returnString;
}

@end
