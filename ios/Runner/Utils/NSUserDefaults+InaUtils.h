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
- (NSString*)inaStringForKey:(NSString *)defaultName defaults:(NSString*)defaultValue;
- (NSString*)inaNumberForKey:(NSString *)defaultName defaults:(NSNumber*)defaultValue;
- (NSInteger)inaIntegerForKey:(NSString *)defaultName defaults:(NSInteger)defaultValue;
- (bool)inaBoolForKey:(NSString *)defaultName defaults:(bool)defaultValue;
- (double)inaDoubleForKey:(NSString *)defaultName defaults:(double)defaultValue;
@end
