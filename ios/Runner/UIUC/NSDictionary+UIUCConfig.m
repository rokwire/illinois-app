//
//  NSDictionary+UIUCConfig
//  UIUCUtils
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

#import "NSDictionary+UIUCConfig.h"
#import "NSDictionary+InaPathKey.h"

@implementation NSDictionary(UIUCConfig)

+ (id)_uiucConfigProcessedValue:(id)value {
	return ([value isKindOfClass:[NSDictionary class]]) ? [value objectForKey:@"ios"] : nil;
}

- (int)uiucConfigIntForPathKey:(NSString*)key {
	return [self uiucConfigIntForPathKey:key defaults:0];
}

- (int)uiucConfigIntForPathKey:(NSString*)key defaults:(int)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if ([value respondsToSelector:@selector(intValue)])
		return [value intValue];
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 respondsToSelector:@selector(intValue)] ? [value1 intValue] : defaultValue;

}

- (long)uiucConfigLongForPathKey:(NSString*)key {
	return [self uiucConfigLongForPathKey:key defaults:0L];
}

- (long)uiucConfigLongForPathKey:(NSString*)key defaults:(long)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if ([value respondsToSelector:@selector(longValue)])
		return [value longValue];
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 respondsToSelector:@selector(longValue)] ? [value1 longValue] : defaultValue;
}

- (int64_t)uiucConfigInt64ForPathKey:(NSString*)key {
	return [self uiucConfigInt64ForPathKey:key defaults:0LL];
}

- (int64_t)uiucConfigInt64ForPathKey:(NSString*)key defaults:(int64_t)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if ([value respondsToSelector:@selector(longLongValue)])
		return [value longLongValue];
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 respondsToSelector:@selector(longLongValue)] ? [value1 longLongValue] : defaultValue;
}

- (NSInteger)uiucConfigIntegerForPathKey:(NSString*)key {
	return [self uiucConfigIntegerForPathKey:key defaults:0LL];
}

- (NSInteger)uiucConfigIntegerForPathKey:(NSString*)key defaults:(NSInteger)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if ([value respondsToSelector:@selector(integerValue)])
		return [value integerValue];
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 respondsToSelector:@selector(integerValue)] ? [value1 integerValue] : defaultValue;
}

- (bool)uiucConfigBoolForPathKey:(NSString*)key {
	return [self uiucConfigBoolForPathKey:key  defaults:NO];
}

- (bool)uiucConfigBoolForPathKey:(NSString*)key  defaults:(bool)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if ([value respondsToSelector:@selector(boolValue)])
		return [value boolValue];
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 respondsToSelector:@selector(boolValue)] ? [value1 boolValue] : defaultValue;
}

- (float)uiucConfigFloatForPathKey:(NSString*)key {
	return [self uiucConfigFloatForPathKey:key defaults:0.0f];
}

- (float)uiucConfigFloatForPathKey:(NSString*)key defaults:(float)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if ([value respondsToSelector:@selector(floatValue)])
		return [value floatValue];
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 respondsToSelector:@selector(floatValue)] ? [value1 floatValue] : defaultValue;
}


- (double)uiucConfigDoubleForPathKey:(NSString*)key {
	return [self uiucConfigDoubleForPathKey:key  defaults:0.0];
}

- (double)uiucConfigDoubleForPathKey:(NSString*)key defaults:(double)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if ([value respondsToSelector:@selector(doubleValue)])
		return [value doubleValue];
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 respondsToSelector:@selector(doubleValue)] ? [value1 doubleValue] : defaultValue;
}

- (NSNumber*)uiucConfigNumberForPathKey:(NSString*)key {
	return [self uiucConfigNumberForPathKey:key defaults:nil];
}

- (NSNumber*)uiucConfigNumberForPathKey:(NSString*)key defaults:(NSNumber*)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if([value isKindOfClass:[NSNumber class]])
		return ((NSNumber*)value);
	id value1 = [self.class _uiucConfigProcessedValue:value];
	return [value1 isKindOfClass:[NSNumber class]] ? value1 : defaultValue;
}

- (NSString*)uiucConfigStringForPathKey:(NSString*)key {
	return [self uiucConfigStringForPathKey:key defaults:nil];
}

- (NSString*)uiucConfigStringForPathKey:(NSString*)key  defaults:(NSString*)defaultValue {
	id value = [self inaObjectForPathKey:key];
	if(value == nil)
		return defaultValue;
	else if([value isKindOfClass:[NSString class]])
		return value;
	else if([value respondsToSelector:@selector(stringValue)])
		return [value stringValue];
	
	id value1 = [self.class _uiucConfigProcessedValue:value];
	if([value1 isKindOfClass:[NSString class]])
		return value1;
	else if([value1 respondsToSelector:@selector(stringValue)])
		return [value1 stringValue];
	else
		return defaultValue;
}

@end


