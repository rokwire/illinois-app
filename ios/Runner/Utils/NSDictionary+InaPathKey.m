//
//  NSDictionary+InaPathKey.m
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

#import "NSDictionary+InaPathKey.h"

@implementation NSDictionary(InaPathKey)

- (id)inaObjectForPathKey:(NSString*)key {
	id entry = nil;
	NSString *field = nil;
	NSDictionary *source = self;
	NSRange scope = NSMakeRange(0, key.length), lookup;
	
	while (0 < (lookup = [key rangeOfString:@"." options:0 range:scope]).length) {
		field = [key substringWithRange:NSMakeRange(scope.location, lookup.location - scope.location)];
		entry = [source objectForKey:field];
		if ([entry isKindOfClass:[NSDictionary class]] || [entry isKindOfClass:[NSArray class]]) {
			source = entry;
			scope.location = lookup.location + lookup.length;
			scope.length = key.length - scope.location;
		}
		else {
			break;
		}
	}
	
	if (0 < scope.length) {
		field = (0 < scope.location) ? [key substringWithRange:scope] : key;
		return [source objectForKey:field];
	}
	else {
		return nil;
	}
}

- (id)inaObjectForPathKey:(NSString*)key defaults:(id)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return (value != nil) ? value : defaultValue;
}

- (int)inaIntForPathKey:(NSString*)key {
	return [self inaIntForPathKey:key defaults:0];
}

- (int)inaIntForPathKey:(NSString*)key defaults:(int)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value respondsToSelector:@selector(intValue)] ? [value intValue] : defaultValue;
}

- (long)inaLongForPathKey:(NSString*)key {
	return [self inaLongForPathKey:key defaults:0L];
}

- (long)inaLongForPathKey:(NSString*)key defaults:(long)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value respondsToSelector:@selector(longValue)] ? [value longValue] : defaultValue;
}

- (int64_t)inaInt64ForPathKey:(NSString*)key {
	return [self inaInt64ForPathKey:key defaults:0LL];
}

- (int64_t)inaInt64ForPathKey:(NSString*)key defaults:(int64_t)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : defaultValue;
}

- (NSInteger)inaIntegerForPathKey:(NSString*)key {
	return [self inaIntegerForPathKey:key defaults:0LL];
}

- (NSInteger)inaIntegerForPathKey:(NSString*)key defaults:(NSInteger)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : defaultValue;
}

- (bool)inaBoolForPathKey:(NSString*)key {
	return [self inaBoolForPathKey:key  defaults:NO];
}

- (bool)inaBoolForPathKey:(NSString*)key  defaults:(bool)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}


- (float)inaFloatForPathKey:(NSString*)key {
	return [self inaFloatForPathKey:key defaults:0.0f];
}

- (float)inaFloatForPathKey:(NSString*)key defaults:(float)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : defaultValue;
}


- (double)inaDoubleForPathKey:(NSString*)key {
	return [self inaDoubleForPathKey:key  defaults:0.0];
}

- (double)inaDoubleForPathKey:(NSString*)key defaults:(double)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : defaultValue;
}

- (NSString*)inaStringForPathKey:(NSString*)key {
	return [self inaStringForPathKey:key defaults:nil];
}

- (NSString*)inaStringForPathKey:(NSString*)key  defaults:(NSString*)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSString class]])
		return ((NSString*)value);
	else if([value respondsToSelector:@selector(stringValue)])
		return [value stringValue];
	else
		return defaultValue;
}

- (NSNumber*)inaNumberForPathKey:(NSString*)key {
	return [self inaNumberForPathKey:key defaults:nil];
}

- (NSNumber*)inaNumberForPathKey:(NSString*)key defaults:(NSNumber*)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSNumber class]])
		return ((NSNumber*)value);
	else
		return defaultValue;
}


- (NSArray*)inaArrayForPathKey:(NSString*)key {
	return [self inaArrayForPathKey:key defaults:nil];
}

- (NSArray*)inaArrayForPathKey:(NSString*)key defaults:(NSArray*)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value isKindOfClass:[NSArray class]] ? value : defaultValue;
}

- (NSDictionary*)inaDictForPathKey:(NSString*)key {
	return [self inaDictForPathKey:key defaults:nil];
}

- (NSDictionary*)inaDictForPathKey:(NSString*)key defaults:(NSDictionary*)defaultValue {
	id value = [self inaObjectForPathKey:key];
	return [value isKindOfClass:[NSDictionary class]] ? value : defaultValue;
}

@end


