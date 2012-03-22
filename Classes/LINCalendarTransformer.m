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
  if ([value valueForKey:@"Month"]) {
		[returnString appendFormat:@"Month:%02d", [[value valueForKey:@"Month"] intValue]];
	}
	if ([value valueForKey:@"Day"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
		[returnString appendFormat:@"D:%02d", [[value valueForKey:@"Day"] intValue]];
	}
  if ([value valueForKey:@"Weekday"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
		[returnString appendFormat:@"W:%02d", [[value valueForKey:@"Weekday"] intValue]];
	}
	if ([value valueForKey:@"Hour"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
		[returnString appendFormat:@"H:%02d", [[value valueForKey:@"Hour"] intValue]];
	}
	if ([value valueForKey:@"Minute"]) {
		if ([returnString length] > 0) {
			[returnString appendString:@" "];
		}
    [returnString appendFormat:@"M:%02d", [[value valueForKey:@"Minute"] intValue]];
	}
	
	return returnString;
}

+ (NSString *)sortableStringFromCalendarDictionary:(NSDictionary *)dictionary {
  NSArray *sortableKeys = [NSArray arrayWithObjects:
                           @"Month",
                           @"Day",
                           @"Weekday",
                           @"Hour",
                           @"Minute",
                           nil];

  NSMutableString *returnString = [NSMutableString stringWithString:@""];
  for(NSString *key in sortableKeys) {
    if([dictionary valueForKey:key]) {
      [returnString appendFormat:@"%02d", [[dictionary valueForKey:key] intValue]];
    } else {
      [returnString appendString:@"00"];
    }
  }
	
	return returnString;
}

@end
