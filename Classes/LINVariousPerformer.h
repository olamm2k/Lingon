/* LINVariousPerformer */

/*
Lingon version 1.2.1, 2007-07-16
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://lingon.sourceforge.net

Copyright 2005-2007 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import <Cocoa/Cocoa.h>

typedef enum _LINAfterSaveAction {
    LINAfterSaveNothing = 0,
	LINAfterSaveLoad,
	LINAfterSaveReload
} LINAfterSaveAction;

@interface LINVariousPerformer : NSObject
{
	NSDictionary *defaults;
	
}

+ (LINVariousPerformer *)sharedInstance;

-(void)updateContentsForTab:(NSTabViewItem *)tabViewItem loadedArray:(NSArray *)loadedArray;
-(void)insertPlistIntoContext:(NSDictionary *)plist filename:(NSString *)filename loadedArray:(NSArray *)loadedArray;
-(NSMutableDictionary *)convertDictionary:(NSDictionary *)originalDictionary;
-(void)setBonjourForItem:(NSString *)item inArray:(NSMutableArray *)sockets inPlist:(NSDictionary *)thePlist socketDictionary:(NSDictionary *)socketDictionary fromInnerArray:(BOOL)fromInnerArray;

-(void)updateCountsInTabViewItemLabels;
-(int)folderCountForPath:(NSString *)path;
-(void)updateLabelForIndex:(int)index count:(int)count label:(NSString *)label;

-(void)insertTableColumn:(NSTableColumn *)tableColumn;
-(void)configureTableColumn:(NSTableColumn *)tableColumn;

-(NSDictionary *)convertPartsOfDictionaryBeforePlist:(NSDictionary *)dictionary;

-(NSString *)performTask:(NSString *)launchPath arguments:(NSArray *)arguments;
-(NSArray *)getLoadedArray;
-(NSString *)genererateTempPath;

-(BOOL)performSaveOfDictionary:(NSDictionary *)dictionary toFolder:(int)folder filename:(NSString *)filename action:(LINAfterSaveAction)action;
-(void)cannotSavePath:(NSString *)path;

-(void)selectLabel:(NSString *)label;
@end
