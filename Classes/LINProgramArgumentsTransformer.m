//
//  LINProgramArgumentsTransformer.m
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

#import "LINProgramArgumentsTransformer.h"


@implementation LINProgramArgumentsTransformer

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
	NSArray *programArguments = [value valueForKey:@"argument"];
	int count = [programArguments count];
	if (!count || ![[programArguments objectAtIndex:0] isKindOfClass:[NSString class]]) return @"";
	
	NSMutableString *returnString = [NSMutableString stringWithString:[programArguments objectAtIndex:0]];
	int index;
	for (index = 1; index < count; index++) {
		[returnString appendFormat:@" %@", [programArguments objectAtIndex:index]];
	}
	
	return returnString;
}
@end
