//
//  NSDictionary+RokwireTypedValue.m
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

#import "NSDictionary+RokwireTypedValue.h"

@implementation NSDictionary(RokwireTypedValue)

- (int)rokwireIntForKey:(id)key {
	return [self rokwireIntForKey:(id)key defaults:0];
}

- (int)rokwireIntForKey:(id)key defaults:(int)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(intValue)] ? [value intValue] : defaultValue;
}

- (long)rokwireLongForKey:(id)key {
	return [self rokwireLongForKey:(id)key defaults:0L];
}

- (long)rokwireLongForKey:(id)key defaults:(long)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(longValue)] ? [value longValue] : defaultValue;
}

- (int64_t)rokwireInt64ForKey:(id)key {
	return [self rokwireInt64ForKey:key defaults:0LL];
}

- (int64_t)rokwireInt64ForKey:(id)key defaults:(int64_t)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : defaultValue;
}

- (NSInteger)rokwireIntegerForKey:(id)key {
	return [self rokwireIntegerForKey:key defaults:0LL];
}

- (NSInteger)rokwireIntegerForKey:(id)key defaults:(NSInteger)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : defaultValue;
}

- (bool)rokwireBoolForKey:(id)key {
	return [self rokwireBoolForKey:key  defaults:NO];
}

- (bool)rokwireBoolForKey:(id)key  defaults:(bool)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}


- (float)rokwireFloatForKey:(id)key {
	return [self rokwireFloatForKey:key defaults:0.0f];
}

- (float)rokwireFloatForKey:(id)key defaults:(float)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : defaultValue;
}


- (double)rokwireDoubleForKey:(id)key {
	return [self rokwireDoubleForKey:key  defaults:0.0];
}

- (double)rokwireDoubleForKey:(id)key defaults:(double)defaultValue {
	id value = [self objectForKey:key];
	return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : defaultValue;
}

- (NSString*)rokwireStringForKey:(id)key {
	return [self rokwireStringForKey:key defaults:nil];
}

- (NSString*)rokwireStringForKey:(id)key  defaults:(NSString*)defaultValue {
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

- (NSNumber*)rokwireNumberForKey:(id)key {
	return [self rokwireNumberForKey:key defaults:nil];
}

- (NSNumber*)rokwireNumberForKey:(id)key defaults:(NSNumber*)defaultValue {
	id value = [self objectForKey:key];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSNumber class]])
		return ((NSNumber*)value);
	else
		return defaultValue;
}


- (NSArray*)rokwireArrayForKey:(id)key {
	return [self rokwireArrayForKey:key defaults:nil];
}

- (NSArray*)rokwireArrayForKey:(id)key defaults:(NSArray*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSArray class]] ? value : defaultValue;
}

- (NSDictionary*)rokwireDictForKey:(id)key {
	return [self rokwireDictForKey:key defaults:nil];
}

- (NSDictionary*)rokwireDictForKey:(id)key defaults:(NSDictionary*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSDictionary class]] ? value : defaultValue;
}

- (NSValue*)rokwireValueForKey:(id)key {
	return [self rokwireValueForKey:key defaults:nil];
}

- (NSValue*)rokwireValueForKey:(id)key defaults:(NSValue*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSValue class]] ? value : defaultValue;
}

- (NSData*)rokwireDataForKey:(id)key {
	return [self rokwireDataForKey:key defaults:nil];
}

- (NSData*)rokwireDataForKey:(id)key defaults:(NSData*)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:[NSData class]] ? value : defaultValue;
}

- (SEL)rokwireSelectorForKey:(id)key {
	return [self rokwireSelectorForKey:key defaults:NULL];
}

- (SEL)rokwireSelectorForKey:(id)key defaults:(SEL)defaultValue {
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

- (id)rokwireObjectForKey:(id)key class:(Class)class {
	return [self rokwireObjectForKey:key class:class defaults:nil];
}

- (id)rokwireObjectForKey:(id)key class:(Class)class defaults:(id)defaultValue {
	id value = [self objectForKey:key];
	return [value isKindOfClass:class] ? value : defaultValue;
}

@end


