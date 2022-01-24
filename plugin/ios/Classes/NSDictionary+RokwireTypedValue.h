//
//  NSDictionary+RokwireTypedValue.h
//  InaUtils
//
//  Created by Mihail Varbanov on 2/12/19.
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

@interface NSDictionary(RokwireTypedValue)

	- (int)rokwireIntForKey:(id)key;
	- (int)rokwireIntForKey:(id)key defaults:(int)defaultValue;

	- (long)rokwireLongForKey:(id)key;
	- (long)rokwireLongForKey:(id)key defaults:(long)defaultValue;

	- (NSInteger)rokwireIntegerForKey:(id)key;
	- (NSInteger)rokwireIntegerForKey:(id)key defaults:(NSInteger)defaultValue;

	- (int64_t)rokwireInt64ForKey:(id)key;
	- (int64_t)rokwireInt64ForKey:(id)key defaults:(int64_t)defaultValue;

	- (bool)rokwireBoolForKey:(id)key;
	- (bool)rokwireBoolForKey:(id)key defaults:(bool)defaultValue;
	
	- (float)rokwireFloatForKey:(id)key;
	- (float)rokwireFloatForKey:(id)key defaults:(float)defaultValue;
	
	- (double)rokwireDoubleForKey:(id)key;
	- (double)rokwireDoubleForKey:(id)key defaults:(double)defaultValue;
	
	- (NSString*)rokwireStringForKey:(id)key;
	- (NSString*)rokwireStringForKey:(id)key defaults:(NSString*)defaultValue;

	- (NSNumber*)rokwireNumberForKey:(id)key;
	- (NSNumber*)rokwireNumberForKey:(id)key defaults:(NSNumber*)defaultValue;

	- (NSDictionary*)rokwireDictForKey:(id)key;
	- (NSDictionary*)rokwireDictForKey:(id)key defaults:(NSDictionary*)defaultValue;

	- (NSArray*)rokwireArrayForKey:(id)key;
	- (NSArray*)rokwireArrayForKey:(id)key defaults:(NSArray*)defaultValue;

	- (NSValue*)rokwireValueForKey:(id)key;
	- (NSValue*)rokwireValueForKey:(id)key defaults:(NSValue*)defaultValue;

	- (NSData*)rokwireDataForKey:(id)key;
	- (NSData*)rokwireDataForKey:(id)key defaults:(NSData*)defaultValue;

	- (SEL)rokwireSelectorForKey:(id)key;
	- (SEL)rokwireSelectorForKey:(id)key defaults:(SEL)defaultValue;

	- (id)rokwireObjectForKey:(id)key class:(Class)class;
	- (id)rokwireObjectForKey:(id)key class:(Class)class defaults:(id)defaultValue;
@end
