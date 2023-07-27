//
//  NSUserDefaults+InaTypedValue.h
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

@interface NSUserDefaults(InaUtils)
- (NSString*)inaStringForKey:(NSString *)defaultName;
- (NSString*)inaStringForKey:(NSString *)defaultName defaults:(NSString*)defaultValue;
- (void)inaSetString:(NSString *)value forKey:(NSString *)defaultName;

- (NSString*)inaNumberForKey:(NSString *)defaultName;
- (NSString*)inaNumberForKey:(NSString *)defaultName defaults:(NSNumber*)defaultValue;
- (void)inaSetNumber:(NSNumber*)value forKey:(NSString *)defaultName;

- (NSInteger)inaIntegerForKey:(NSString *)defaultName;
- (NSInteger)inaIntegerForKey:(NSString *)defaultName defaults:(NSInteger)defaultValue;
- (void)inaSetInteger:(NSInteger)value forKey:(NSString *)defaultName;

- (bool)inaBoolForKey:(NSString *)defaultName;
- (bool)inaBoolForKey:(NSString *)defaultName defaults:(bool)defaultValue;
- (void)inaSetBool:(bool)value forKey:(NSString *)defaultName;

- (double)inaDoubleForKey:(NSString *)defaultName;
- (double)inaDoubleForKey:(NSString *)defaultName defaults:(double)defaultValue;
- (void)inaSetDouble:(double)value forKey:(NSString *)defaultName;

- (float)inaFloatForKey:(NSString *)defaultName;
- (float)inaFloatForKey:(NSString *)defaultName defaults:(float)defaultValue;
- (void)inaSetFloat:(float)value forKey:(NSString *)defaultName;

@end
