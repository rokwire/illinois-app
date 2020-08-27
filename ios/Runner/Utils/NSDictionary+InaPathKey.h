//
//  NSDictionary+InaPathKey.h
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

@interface NSDictionary(InaPathKey)

	- (id)inaObjectForPathKey:(NSString*)key;
	- (id)inaObjectForPathKey:(NSString*)key defaults:(id)defaultValue;

	- (int)inaIntForPathKey:(NSString*)key;
	- (int)inaIntForPathKey:(NSString*)key defaults:(int)defaultValue;

	- (long)inaLongForPathKey:(NSString*)key;
	- (long)inaLongForPathKey:(NSString*)key defaults:(long)defaultValue;

	- (NSInteger)inaIntegerForPathKey:(NSString*)key;
	- (NSInteger)inaIntegerForPathKey:(NSString*)key defaults:(NSInteger)defaultValue;

	- (int64_t)inaInt64ForPathKey:(NSString*)key;
	- (int64_t)inaInt64ForPathKey:(NSString*)key defaults:(int64_t)defaultValue;

	- (bool)inaBoolForPathKey:(NSString*)key;
	- (bool)inaBoolForPathKey:(NSString*)key defaults:(bool)defaultValue;
	
	- (float)inaFloatForPathKey:(NSString*)key;
	- (float)inaFloatForPathKey:(NSString*)key defaults:(float)defaultValue;
	
	- (double)inaDoubleForPathKey:(NSString*)key;
	- (double)inaDoubleForPathKey:(NSString*)key defaults:(double)defaultValue;
	
	- (NSString*)inaStringForPathKey:(NSString*)key;
	- (NSString*)inaStringForPathKey:(NSString*)key defaults:(NSString*)defaultValue;

	- (NSNumber*)inaNumberForPathKey:(NSString*)key;
	- (NSNumber*)inaNumberForPathKey:(NSString*)key defaults:(NSNumber*)defaultValue;

	- (NSDictionary*)inaDictForPathKey:(NSString*)key;
	- (NSDictionary*)inaDictForPathKey:(NSString*)key defaults:(NSDictionary*)defaultValue;

	- (NSArray*)inaArrayForPathKey:(NSString*)key;
	- (NSArray*)inaArrayForPathKey:(NSString*)key defaults:(NSArray*)defaultValue;
@end
