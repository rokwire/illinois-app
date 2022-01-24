//
//  Security+RokwireUtils.m
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

#import "Security+RokwireUtils.h"

id rokwireSecStorageData(NSString *account, NSString *generic, id valueToWrite) {
	NSMutableDictionary *spec = [NSMutableDictionary dictionaryWithDictionary:@{
		(id)kSecClass:       (id)kSecClassGenericPassword,
		(id)kSecAttrAccount: account,
//	(id)kSecAttrGeneric: generic,
		(id)kSecAttrService: NSBundle.mainBundle.bundleIdentifier,
	}];
	
	if (generic != nil) {
		[spec setObject:generic forKey:(id)kSecAttrGeneric];
	}
	
	NSMutableDictionary *searchRequest = [NSMutableDictionary dictionaryWithDictionary:spec];
	[searchRequest setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[searchRequest setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	[searchRequest setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];

	CFDictionaryRef response = NULL;
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)searchRequest, (CFTypeRef*)&response);
	NSData *existingData = nil;

	if (status == errSecInteractionNotAllowed) {
		// Could not access data. Error: errSecInteractionNotAllowed
		return nil;
	}
	else if (status == errSecSuccess) {
		NSDictionary *attribs = CFBridgingRelease(response);
		NSData *data = [attribs objectForKey:(id)kSecValueData];
		NSString *security = [attribs objectForKey:(id)kSecAttrAccessible];

		// If not always accessible then update it to be so
		if (![security isEqualToString:(id)kSecAttrAccessibleAlways]) {
			NSDictionary *update = @{
				(id)kSecAttrAccessible:(id)kSecAttrAccessibleAlways,
				(id)kSecValueData:data ?: [[NSData alloc] init],
			};

			SecItemUpdate((CFDictionaryRef)spec, (CFDictionaryRef)update);
		}

		existingData = data;
	}
	
	if (valueToWrite == nil) { // getter
		return existingData;
	}
	else if ([valueToWrite isKindOfClass:[NSData class]]) { // setter
		
		if (status == errSecSuccess) {
			// update existing entry
			NSDictionary *update = @{
				(id)kSecAttrAccessible:(id)kSecAttrAccessibleAlways,
				(id)kSecValueData:valueToWrite
			};
			status = SecItemUpdate((CFDictionaryRef)spec, (CFDictionaryRef)update);
		}
		else {
			// create new entry
			NSMutableDictionary *createRequest = [NSMutableDictionary dictionaryWithDictionary:spec];
			[createRequest setObject:valueToWrite forKey:(id)kSecValueData];
			[createRequest setObject:(id)kSecAttrAccessibleAlways forKey:(id)kSecAttrAccessible];
			status = SecItemAdd((CFDictionaryRef)createRequest, NULL);
		}
		
		return (status == errSecSuccess) ? @(YES) : @(NO);
	}
	else { // delete existing entry
		if (status == errSecSuccess) {
			status = SecItemDelete((CFDictionaryRef)spec);
			return (status == errSecSuccess) ? @(YES) : @(NO);
		}
		else {
			// nothing to do
			return nil;
		}
	}
}
