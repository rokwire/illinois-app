//
//  CommonCrypto+UIUCUtils.h
//  UIUCUtils
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

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

NSData * uiuc_aes_operation(NSData * dataIn,
	CCOperation operation,  // kCC Encrypt, Decrypt
	CCMode mode,            // kCCMode ECB, CBC, CFB, CTR, OFB, RC4, CFB8
	CCAlgorithm algorithm,  // CCAlgorithm AES DES, 3DES, CAST, RC4, RC2, Blowfish
	CCPadding padding,      // cc NoPadding, PKCS7Padding
	size_t keyLength,       // kCCKeySizeAES 128, 192, 256
	NSData * iv,            // CBC, CFB, CFB8, OFB, CTR
	NSData * key,
	NSError ** error);
