//
//  LINPathsTransformer.m
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

#import "LINPathsTransformer.h"

@implementation LINPathsTransformer

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
	NSArray *paths = [value valueForKey:@"path"];
	int count = [paths count];
	if (!count) return @"";
	int index;
	if (count == 1) {
		NSString *returnString = [NSString stringWithString:[paths objectAtIndex:0]];
		return returnString;
	} else {
		NSMutableString *returnString = [NSMutableString stringWithFormat:@"1:%@", [paths objectAtIndex:0]];
		for (index = 1; index < count; index++) {
			[returnString appendFormat:@" %d:%@", index + 1, [paths objectAtIndex:index]];
		}
		return returnString;
	}
}

@end
