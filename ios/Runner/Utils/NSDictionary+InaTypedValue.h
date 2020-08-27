//
//  NSDictionary+InaTypedValue.h
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

@interface NSDictionary(InaTypedValue)

	- (int)inaIntForKey:(id)key;
	- (int)inaIntForKey:(id)key defaults:(int)defaultValue;

	- (long)inaLongForKey:(id)key;
	- (long)inaLongForKey:(id)key defaults:(long)defaultValue;

	- (NSInteger)inaIntegerForKey:(id)key;
	- (NSInteger)inaIntegerForKey:(id)key defaults:(NSInteger)defaultValue;

	- (int64_t)inaInt64ForKey:(id)key;
	- (int64_t)inaInt64ForKey:(id)key defaults:(int64_t)defaultValue;

	- (bool)inaBoolForKey:(id)key;
	- (bool)inaBoolForKey:(id)key defaults:(bool)defaultValue;
	
	- (float)inaFloatForKey:(id)key;
	- (float)inaFloatForKey:(id)key defaults:(float)defaultValue;
	
	- (double)inaDoubleForKey:(id)key;
	- (double)inaDoubleForKey:(id)key defaults:(double)defaultValue;
	
	- (NSString*)inaStringForKey:(id)key;
	- (NSString*)inaStringForKey:(id)key defaults:(NSString*)defaultValue;

	- (NSNumber*)inaNumberForKey:(id)key;
	- (NSNumber*)inaNumberForKey:(id)key defaults:(NSNumber*)defaultValue;

	- (NSDictionary*)inaDictForKey:(id)key;
	- (NSDictionary*)inaDictForKey:(id)key defaults:(NSDictionary*)defaultValue;

	- (NSArray*)inaArrayForKey:(id)key;
	- (NSArray*)inaArrayForKey:(id)key defaults:(NSArray*)defaultValue;

	- (NSValue*)inaValueForKey:(id)key;
	- (NSValue*)inaValueForKey:(id)key defaults:(NSValue*)defaultValue;

	- (NSData*)inaDataForKey:(id)key;
	- (NSData*)inaDataForKey:(id)key defaults:(NSData*)defaultValue;

	- (SEL)inaSelectorForKey:(id)key;
	- (SEL)inaSelectorForKey:(id)key defaults:(SEL)defaultValue;

	- (id)inaObjectForKey:(id)key class:(Class)class;
	- (id)inaObjectForKey:(id)key class:(Class)class defaults:(id)defaultValue;
@end
