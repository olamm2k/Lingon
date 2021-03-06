//
//  LINDictionaryCategory.m
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
#import "LINDictionaryCategory.h"


@implementation NSDictionary (LINDictionaryCategory)

- (NSComparisonResult)compare:(NSDictionary *)dictionary
{
  return [[self description] compare:[dictionary description]];
}

- (NSComparisonResult)calSort:(NSDictionary *)dictionary {
  NSString *string1 = [LINCalendarTransformer sortableStringFromCalendarDictionary:self];
  NSString *string2 = [LINCalendarTransformer sortableStringFromCalendarDictionary:dictionary];

#ifdef MS_DEBUG
  NSLog(@"s1: %@, s2: %@, %d", string1, string2, [string1 compare:string2]);
#endif
  
  return [string1 compare:string2];
}

@end
