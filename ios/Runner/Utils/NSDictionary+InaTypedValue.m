//
//  NSDictionary+InaTypedValue.m
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

#import "NSDictionary+InaTypedValue.h"

@implementation NSDictionary(InaTypedValue)

- (int)inaIntForKey:(id)key {
	return [self inaIntForKey:(id)key defaults:0];
}

- (int)inaIntForKey:(id)key defaults:(int)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(intValue)] ? [value intValue] : defaultValue;
}

- (long)inaLongForKey:(id)key {
	return [self inaLongForKey:(id)key defaults:0L];
}

- (long)inaLongForKey:(id)key defaults:(long)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(longValue)] ? [value longValue] : defaultValue;
}

- (int64_t)inaInt64ForKey:(id)key {
	return [self inaInt64ForKey:key defaults:0LL];
}

- (int64_t)inaInt64ForKey:(id)key defaults:(int64_t)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : defaultValue;
}

- (NSInteger)inaIntegerForKey:(id)key {
	return [self inaIntegerForKey:key defaults:0LL];
}

- (NSInteger)inaIntegerForKey:(id)key defaults:(NSInteger)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : defaultValue;
}

- (bool)inaBoolForKey:(id)key {
	return [self inaBoolForKey:key  defaults:NO];
}

- (bool)inaBoolForKey:(id)key  defaults:(bool)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}


- (float)inaFloatForKey:(id)key {
	return [self inaFloatForKey:key defaults:0.0f];
}

- (float)inaFloatForKey:(id)key defaults:(float)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : defaultValue;
}


- (double)inaDoubleForKey:(id)key {
	return [self inaDoubleForKey:key  defaults:0.0];
}

- (double)inaDoubleForKey:(id)key defaults:(double)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : defaultValue;
}

- (NSString*)inaStringForKey:(id)key {
	return [self inaStringForKey:key defaults:nil];
}

- (NSString*)inaStringForKey:(id)key  defaults:(NSString*)defaultValue {
	id value = [self objectForKey:key];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSString class]])
		return ((NSString*)value);
	else if([value respondsToSelector:@selector(stringValue)])
		return [value stringValue];
	else
		return defaultValue;
}

- (NSNumber*)inaNumberForKey:(id)key {
	return [self inaNumberForKey:key defaults:nil];
}

- (NSNumber*)inaNumberForKey:(id)key defaults:(NSNumber*)defaultValue {
	id value = [self objectForKey:key];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSNumber class]])
		return ((NSNumber*)value);
	else
		return defaultValue;
}


- (NSArray*)inaArrayForKey:(id)key {
	return [self inaArrayForKey:key defaults:nil];
}

- (NSArray*)inaArrayForKey:(id)key defaults:(NSArray*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSArray class]] ? value : defaultValue;
}

- (NSDictionary*)inaDictForKey:(id)key {
	return [self inaDictForKey:key defaults:nil];
}

- (NSDictionary*)inaDictForKey:(id)key defaults:(NSDictionary*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSDictionary class]] ? value : defaultValue;
}

- (NSValue*)inaValueForKey:(id)key {
	return [self inaValueForKey:key defaults:nil];
}

- (NSValue*)inaValueForKey:(id)key defaults:(NSValue*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSValue class]] ? value : defaultValue;
}

- (NSData*)inaDataForKey:(id)key {
	return [self inaDataForKey:key defaults:nil];
}

- (NSData*)inaDataForKey:(id)key defaults:(NSData*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSData class]] ? value : defaultValue;
}

- (SEL)inaSelectorForKey:(id)key {
	return [self inaSelectorForKey:key defaults:NULL];
}

- (SEL)inaSelectorForKey:(id)key defaults:(SEL)defaultValue {
	id value = [self objectForKey:key];
	if ([value isKindOfClass:[NSValue class]]) {
		return ((NSValue*)value).pointerValue;
	}
	else if ([value isKindOfClass:[NSString class]]) {
		SEL selector = NSSelectorFromString(value);
		return (selector != nil) ? selector : defaultValue;
	}
	return defaultValue;
}

- (id)inaObjectForKey:(id)key class:(Class)class {
	return [self inaObjectForKey:key class:class defaults:nil];
}

- (id)inaObjectForKey:(id)key class:(Class)class defaults:(id)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:class] ? value : defaultValue;
}

@end


