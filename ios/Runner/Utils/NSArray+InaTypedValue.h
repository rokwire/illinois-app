//
//  NSArray+InaTypedValue.h
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

@interface NSArray(InaTypedValue)

	- (int)inaIntAtIndex:(NSUInteger)index;
	- (int)inaIntAtIndex:(NSUInteger)index defaults:(int)defaultValue;

	- (long)inaLongAtIndex:(NSUInteger)index;
	- (long)inaLongAtIndex:(NSUInteger)index defaults:(long)defaultValue;

	- (NSInteger)inaIntegerAtIndex:(NSUInteger)index;
	- (NSInteger)inaIntegerAtIndex:(NSUInteger)index defaults:(NSInteger)defaultValue;

	- (int64_t)inaInt64AtIndex:(NSUInteger)index;
	- (int64_t)inaInt64AtIndex:(NSUInteger)index defaults:(int64_t)defaultValue;

	- (bool)inaBoolAtIndex:(NSUInteger)index;
	- (bool)inaBoolAtIndex:(NSUInteger)index defaults:(bool)defaultValue;
	
	- (float)inaFloatAtIndex:(NSUInteger)index;
	- (float)inaFloatAtIndex:(NSUInteger)index defaults:(float)defaultValue;
	
	- (double)inaDoubleAtIndex:(NSUInteger)index;
	- (double)inaDoubleAtIndex:(NSUInteger)index defaults:(double)defaultValue;
	
	- (NSString*)inaStringAtIndex:(NSUInteger)index;
	- (NSString*)inaStringAtIndex:(NSUInteger)index defaults:(NSString*)defaultValue;

	- (NSNumber*)inaNumberAtIndex:(NSUInteger)index;
	- (NSNumber*)inaNumberAtIndex:(NSUInteger)index defaults:(NSNumber*)defaultValue;

	- (NSDictionary*)inaDictAtIndex:(NSUInteger)index;
	- (NSDictionary*)inaDictAtIndex:(NSUInteger)index defaults:(NSDictionary*)defaultValue;

	- (NSArray*)inaArrayAtIndex:(NSUInteger)index;
	- (NSArray*)inaArrayAtIndex:(NSUInteger)index defaults:(NSArray*)defaultValue;

	- (NSValue*)inaValueAtIndex:(NSUInteger)index;
	- (NSValue*)inaValueAtIndex:(NSUInteger)index defaults:(NSValue*)defaultValue;

	- (NSData*)inaDataAtIndex:(NSUInteger)index;
	- (NSData*)inaDataAtIndex:(NSUInteger)index defaults:(NSData*)defaultValue;

	- (SEL)inaSelectorAtIndex:(NSUInteger)index;
	- (SEL)inaSelectorAtIndex:(NSUInteger)index defaults:(SEL)defaultValue;

	- (id)inaObjectAtIndex:(NSUInteger)index;
	- (id)inaObjectAtIndex:(NSUInteger)index class:(Class)class;
	- (id)inaObjectAtIndex:(NSUInteger)index class:(Class)class defaults:(id)defaultValue;
@end
