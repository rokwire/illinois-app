//
//  CommonCrypto+UIUCUtils.m
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

#import "CommonCrypto+UIUCUtils.h"

NSData * uiuc_aes_operation(NSData * dataIn, CCOperation operation,   // kCC Encrypt, Decrypt
                 CCMode mode,         // kCCMode ECB, CBC, CFB, CTR, OFB, RC4, CFB8
                CCAlgorithm algorithm,  // CCAlgorithm AES DES, 3DES, CAST, RC4, RC2, Blowfish
                CCPadding padding,      // cc NoPadding, PKCS7Padding
                size_t keyLength,       // kCCKeySizeAES 128, 192, 256
                NSData * iv,            // CBC, CFB, CFB8, OFB, CTR
                NSData * key,
                NSError ** error)
{
    if (key.length != keyLength) {
        NSLog(@"CCCryptorArgument key.length: %lu != keyLength: %zu", (unsigned long)key.length, keyLength);
        if (error) {
            *error = [NSError errorWithDomain:@"kArgumentError key length" code:key.length userInfo:nil];
        }
        return nil;
    }

    size_t dataOutMoved = 0;
    size_t dataOutMovedTotal = 0;
    CCCryptorStatus ccStatus = 0;
    CCCryptorRef cryptor = NULL;

    ccStatus = CCCryptorCreateWithMode(operation, mode, algorithm,
                                       padding,
                                       iv.bytes, key.bytes,
                                       keyLength,
                                       NULL, 0, 0, // tweak XTS mode, numRounds
                                       kCCModeOptionCTR_BE, // CCModeOptions
                                       &cryptor);

    if (cryptor == 0 || ccStatus != kCCSuccess) {
        NSLog(@"CCCryptorCreate status: %d", ccStatus);
        if (error) {
            *error = [NSError errorWithDomain:@"kCreateError" code:ccStatus userInfo:nil];
        }
        CCCryptorRelease(cryptor);
        return nil;
    }

    size_t dataOutLength = CCCryptorGetOutputLength(cryptor, dataIn.length, true);
    NSMutableData *dataOut = [NSMutableData dataWithLength:dataOutLength];
    char *dataOutPointer = (char *)dataOut.mutableBytes;

    ccStatus = CCCryptorUpdate(cryptor,
                               dataIn.bytes, dataIn.length,
                               dataOutPointer, dataOutLength,
                               &dataOutMoved);
    dataOutMovedTotal += dataOutMoved;

    if (ccStatus != kCCSuccess) {
        NSLog(@"CCCryptorUpdate status: %d", ccStatus);
        if (error) {
            *error = [NSError errorWithDomain:@"kUpdateError" code:ccStatus userInfo:nil];
        }
        CCCryptorRelease(cryptor);
        return nil;
    }

    ccStatus = CCCryptorFinal(cryptor,
                              dataOutPointer + dataOutMoved, dataOutLength - dataOutMoved,
                              &dataOutMoved);
    if (ccStatus != kCCSuccess) {
        NSLog(@"CCCryptorFinal status: %d", ccStatus);
        if (error) {
            *error = [NSError errorWithDomain:@"kFinalError" code:ccStatus userInfo:nil];
        }
        CCCryptorRelease(cryptor);
        return nil;
    }

    CCCryptorRelease(cryptor);

    dataOutMovedTotal += dataOutMoved;
    dataOut.length = dataOutMovedTotal;

    return dataOut;
}
