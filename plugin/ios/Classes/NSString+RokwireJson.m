//
//  NSString+RokwireJson.m
//  RokwireUtils
//
//  Created by Mihail Varbanov on 5/9/19.
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

#import "NSString+RokwireJson.h"

@implementation NSString(RokwireJson)

- (id)rokwireObjectFromJsonString {
	NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
	return (jsonData != nil) ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL] : nil;
}

- (NSDictionary*)rokwireDictFromJsonString {
	NSDictionary* dict = [self rokwireObjectFromJsonString];
	return [dict isKindOfClass:[NSDictionary class]] ? dict : nil;
}

- (NSArray*)rokwireArrayFromJsonString {
	NSArray* array = [self rokwireObjectFromJsonString];
	return [array isKindOfClass:[NSArray class]] ? array : nil;
}

@end

@implementation NSObject(RokwireJson)

- (NSString*)rokwireJsonString {
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:NULL];
	return (jsonData != nil) ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
}

@end

