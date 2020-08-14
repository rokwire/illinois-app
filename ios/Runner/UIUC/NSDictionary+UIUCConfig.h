//
//  NSDictionary+UIUCConfig.h
//  UIUCUtils
//
//  Created by Mihail Varbanov on 5/9/19.
//  Copyright 2020 Board of Trustees of the University of Illinois.
    
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//    http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

@interface NSDictionary(UIUCConfig)

	- (int)uiucConfigIntForPathKey:(NSString*)key;
	- (int)uiucConfigIntForPathKey:(NSString*)key defaults:(int)defaultValue;

	- (long)uiucConfigLongForPathKey:(NSString*)key;
	- (long)uiucConfigLongForPathKey:(NSString*)key defaults:(long)defaultValue;

	- (NSInteger)uiucConfigIntegerForPathKey:(NSString*)key;
	- (NSInteger)uiucConfigIntegerForPathKey:(NSString*)key defaults:(NSInteger)defaultValue;

	- (int64_t)uiucConfigInt64ForPathKey:(NSString*)key;
	- (int64_t)uiucConfigInt64ForPathKey:(NSString*)key defaults:(int64_t)defaultValue;

	- (bool)uiucConfigBoolForPathKey:(NSString*)key;
	- (bool)uiucConfigBoolForPathKey:(NSString*)key defaults:(bool)defaultValue;
	
	- (float)uiucConfigFloatForPathKey:(NSString*)key;
	- (float)uiucConfigFloatForPathKey:(NSString*)key defaults:(float)defaultValue;
	
	- (double)uiucConfigDoubleForPathKey:(NSString*)key;
	- (double)uiucConfigDoubleForPathKey:(NSString*)key defaults:(double)defaultValue;
	
	- (NSNumber*)uiucConfigNumberForPathKey:(NSString*)key;
	- (NSNumber*)uiucConfigNumberForPathKey:(NSString*)key defaults:(NSNumber*)defaultValue;

	- (NSString*)uiucConfigStringForPathKey:(NSString*)key;
	- (NSString*)uiucConfigStringForPathKey:(NSString*)key defaults:(NSString*)defaultValue;
@end
