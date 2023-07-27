//
//  NSUserDefaults+InaTypedValue.m
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

#import "NSUserDefaults+InaUtils.h"

@implementation NSUserDefaults(InaUtils)

- (NSString*)inaStringForKey:(NSString *)defaultName {
	return [self inaStringForKey:defaultName defaults:nil];
}

- (NSString*)inaStringForKey:(NSString *)defaultName defaults:(NSString*)defaultValue {
	NSString *value = [self stringForKey:defaultName];
	return (value != nil) ? value : defaultValue;
}

- (void)inaSetString:(NSString *)value forKey:(NSString *)defaultName {
	[self setObject:value forKey:defaultName];
}

- (NSNumber*)inaNumberForKey:(NSString *)defaultName {
	return [self inaNumberForKey:defaultName defaults:nil];
}

- (NSNumber*)inaNumberForKey:(NSString *)defaultName defaults:(NSNumber*)defaultValue {
	NSNumber *value = [self objectForKey:defaultName];
	return [value isKindOfClass:[NSNumber class]] ? value : defaultValue;
}

- (void)inaSetNumber:(NSNumber*)value forKey:(NSString *)defaultName {
	[self setObject:value forKey:defaultName];
}

- (NSInteger)inaIntegerForKey:(NSString *)defaultName {
	return [self inaNumberForKey:defaultName defaults:0];
}

- (NSInteger)inaIntegerForKey:(NSString *)defaultName defaults:(NSInteger)defaultValue {
	id value = [self objectForKey:defaultName];
	return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : defaultValue;
}

- (void)inaSetInteger:(NSInteger)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithInteger:value] forKey:defaultName];
}

- (bool)inaBoolForKey:(NSString *)defaultName {
	return [self inaBoolForKey:defaultName defaults:false];
}

- (bool)inaBoolForKey:(NSString *)defaultName defaults:(bool)defaultValue {
	id value = [self objectForKey:defaultName];
	return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

- (void)inaSetBool:(bool)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithBool:value] forKey:defaultName];
}

- (double)inaDoubleForKey:(NSString *)defaultName {
	return [self inaDoubleForKey:defaultName defaults:0.0];
}

- (double)inaDoubleForKey:(NSString *)defaultName defaults:(double)defaultValue {
	id value = [self objectForKey:defaultName];
	return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : defaultValue;
}

- (void)inaSetDouble:(double)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithDouble:value] forKey:defaultName];
}

- (float)inaFloatForKey:(NSString *)defaultName {
	return [self inaFloatForKey:defaultName defaults:0.0f];
}

- (float)inaFloatForKey:(NSString *)defaultName defaults:(float)defaultValue {
	id value = [self objectForKey:defaultName];
	return [value respondsToSelector:@selector(floatValue)] ? [value doubleValue] : defaultValue;
}

- (void)inaSetFloat:(float)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithFloat:value] forKey:defaultName];
}


@end
