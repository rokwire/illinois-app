//
//  NSArray+InaTypedValue.m
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

#import "NSArray+InaTypedValue.h"

@implementation NSArray(InaTypedValue)

- (int)inaIntAtIndex:(NSUInteger)index {
	return [self inaIntAtIndex:index defaults:0];
}

- (int)inaIntAtIndex:(NSUInteger)index defaults:(int)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value respondsToSelector:@selector(intValue)] ? [value intValue] : defaultValue;
}

- (long)inaLongAtIndex:(NSUInteger)index {
	return [self inaLongAtIndex:index defaults:0L];
}

- (long)inaLongAtIndex:(NSUInteger)index defaults:(long)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value respondsToSelector:@selector(longValue)] ? [value longValue] : defaultValue;
}

- (int64_t)inaInt64AtIndex:(NSUInteger)index {
	return [self inaInt64AtIndex:index defaults:0LL];
}

- (int64_t)inaInt64AtIndex:(NSUInteger)index defaults:(int64_t)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : defaultValue;
}

- (NSInteger)inaIntegerAtIndex:(NSUInteger)index {
	return [self inaIntegerAtIndex:index defaults:0LL];
}

- (NSInteger)inaIntegerAtIndex:(NSUInteger)index defaults:(NSInteger)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : defaultValue;
}

- (bool)inaBoolAtIndex:(NSUInteger)index {
	return [self inaBoolAtIndex:index  defaults:NO];
}

- (bool)inaBoolAtIndex:(NSUInteger)index defaults:(bool)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}


- (float)inaFloatAtIndex:(NSUInteger)index {
	return [self inaFloatAtIndex:index defaults:0.0f];
}

- (float)inaFloatAtIndex:(NSUInteger)index defaults:(float)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : defaultValue;
}


- (double)inaDoubleAtIndex:(NSUInteger)index {
	return [self inaDoubleAtIndex:index  defaults:0.0];
}

- (double)inaDoubleAtIndex:(NSUInteger)index defaults:(double)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : defaultValue;
}

- (NSString*)inaStringAtIndex:(NSUInteger)index {
	return [self inaStringAtIndex:index defaults:nil];
}

- (NSString*)inaStringAtIndex:(NSUInteger)index  defaults:(NSString*)defaultValue {
	id value = [self inaObjectAtIndex:index];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSString class]])
		return ((NSString*)value);
	else if([value respondsToSelector:@selector(stringValue)])
		return [value stringValue];
	else
		return defaultValue;
}

- (NSNumber*)inaNumberAtIndex:(NSUInteger)index {
	return [self inaNumberAtIndex:index defaults:nil];
}

- (NSNumber*)inaNumberAtIndex:(NSUInteger)index defaults:(NSNumber*)defaultValue {
	id value = [self inaObjectAtIndex:index];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSNumber class]])
		return ((NSNumber*)value);
	else
		return defaultValue;
}


- (NSArray*)inaArrayAtIndex:(NSUInteger)index {
	return [self inaArrayAtIndex:index defaults:nil];
}

- (NSArray*)inaArrayAtIndex:(NSUInteger)index defaults:(NSArray*)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value isKindOfClass:[NSArray class]] ? value : defaultValue;
}

- (NSDictionary*)inaDictAtIndex:(NSUInteger)index {
	return [self inaDictAtIndex:index defaults:nil];
}

- (NSDictionary*)inaDictAtIndex:(NSUInteger)index defaults:(NSDictionary*)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value isKindOfClass:[NSDictionary class]] ? value : defaultValue;
}

- (NSValue*)inaValueAtIndex:(NSUInteger)index {
	return [self inaValueAtIndex:index defaults:nil];
}

- (NSValue*)inaValueAtIndex:(NSUInteger)index defaults:(NSValue*)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value isKindOfClass:[NSValue class]] ? value : defaultValue;
}

- (NSData*)inaDataAtIndex:(NSUInteger)index {
	return [self inaDataAtIndex:index defaults:nil];
}

- (NSData*)inaDataAtIndex:(NSUInteger)index defaults:(NSData*)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value isKindOfClass:[NSData class]] ? value : defaultValue;
}

- (SEL)inaSelectorAtIndex:(NSUInteger)index {
	return [self inaSelectorAtIndex:index defaults:NULL];
}

- (SEL)inaSelectorAtIndex:(NSUInteger)index defaults:(SEL)defaultValue {
	id value = [self inaObjectAtIndex:index];
	if ([value isKindOfClass:[NSValue class]]) {
		return ((NSValue*)value).pointerValue;
	}
	else if ([value isKindOfClass:[NSString class]]) {
		SEL selector = NSSelectorFromString(value);
		return (selector != nil) ? selector : defaultValue;
	}
	return defaultValue;
}

- (id)inaObjectAtIndex:(NSUInteger)index {
	return ((0 <= index) && (index < self.count)) ? [self objectAtIndex:index] : nil;
}

- (id)inaObjectAtIndex:(NSUInteger)index class:(Class)class {
	return [self inaObjectAtIndex:index class:class defaults:nil];
}

- (id)inaObjectAtIndex:(NSUInteger)index class:(Class)class defaults:(id)defaultValue {
	id value = [self inaObjectAtIndex:index];
	return [value isKindOfClass:class] ? value : defaultValue;
}

@end


