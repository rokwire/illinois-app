#import "RokwirePlugin.h"
#import "LocationServices.h"

#import <SafariServices/SafariServices.h>

#import "Security+RokwireUtils.h"
#import "NSDictionary+RokwireTypedValue.h"

@implementation RokwirePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"edu.illinois.rokwire/plugin"
            binaryMessenger:[registrar messenger]];
  RokwirePlugin* instance = [[RokwirePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

  NSString *firstMethodComponent = call.method, *nextMethodComponents = nil;
  NSRange range = [call.method rangeOfString:@"."];
  if ((range.location != NSNotFound) && (0 < range.length)) {
    firstMethodComponent = [call.method substringWithRange:NSMakeRange(0, range.location)];
    nextMethodComponents = [call.method substringWithRange:NSMakeRange(range.location + range.length, call.method.length - range.location - range.length)];
  }
  
  NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;

  if ([firstMethodComponent isEqualToString:@"getPlatformVersion"]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }
  else if ([firstMethodComponent isEqualToString:@"getDeviceId"]) {
    result([self deviceUuidWithParameters:parameters]);
  }
  else if ([firstMethodComponent isEqualToString:@"getEncryptionKey"]) {
    result([self encryptionKeyWithParameters:parameters]);
  }
  else if ([firstMethodComponent isEqualToString:@"dismissSafariVC"]) {
  	[self dismissSafariViewControllerWithParameters:parameters result:result];
  }
  else if ([firstMethodComponent isEqualToString:@"locationServices"]) {
    [LocationServices.sharedInstance handleMethodCallWithName:nextMethodComponents parameters:call.arguments result:result];
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark Device UUID

- (NSString*)deviceUuidWithParameters:(NSDictionary*)parameters {
  NSUUID *result = nil;
  NSString* identifier = [parameters rokwireStringForKey:@"identifier"];
  NSString* generic = [parameters rokwireStringForKey:@"identifier2"];
  if (identifier != nil) {
    NSData *data = rokwireSecStorageData(identifier, generic, nil);
    if ([data isKindOfClass:[NSData class]] && (data.length == sizeof(uuid_t))) {
      result = [[NSUUID alloc] initWithUUIDBytes:data.bytes];
    }
    else {
      uuid_t uuidData;
      int rndStatus = SecRandomCopyBytes(kSecRandomDefault, sizeof(uuidData), uuidData);
      if (rndStatus == errSecSuccess) {
        NSNumber *storageResult = rokwireSecStorageData(identifier, generic, [NSData dataWithBytes:uuidData length:sizeof(uuidData)]);
        if ([storageResult isKindOfClass:[NSNumber class]] && [storageResult boolValue]) {
          result = [[NSUUID alloc] initWithUUIDBytes:uuidData];
        }
      }
    }
  }
	return result.UUIDString;
}

#pragma mark Encryption Key

- (NSString*)encryptionKeyWithParameters:(NSDictionary*)parameters {
	
	NSString *identifier = [parameters rokwireStringForKey:@"identifier"];
	if (identifier == nil) {
		return nil;
	}
	
	NSInteger keySize = [parameters rokwireIntegerForKey:@"size"];
	if (keySize <= 0) {
		return nil;
	}

	NSData *data = rokwireSecStorageData(identifier, nil, nil);
	if ([data isKindOfClass:[NSData class]] && (data.length == keySize)) {
		return [data base64EncodedStringWithOptions:0];
	}
	else {
		UInt8 key[keySize];
		int rndStatus = SecRandomCopyBytes(kSecRandomDefault, sizeof(key), key);
		if (rndStatus == errSecSuccess) {
			data = [NSData dataWithBytes:key length:sizeof(key)];
			NSNumber *result = rokwireSecStorageData(identifier, nil, data);
			if ([result isKindOfClass:[NSNumber class]] && [result boolValue]) {
				return [data base64EncodedStringWithOptions:0];
			}
		}
	}
	return nil;
}

#pragma mark SFSafariViewController

- (void)dismissSafariViewControllerWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	UIViewController *presentedController = UIApplication.sharedApplication.keyWindow.rootViewController.presentedViewController;
	if ([presentedController isKindOfClass:[SFSafariViewController class]]) {
		[presentedController dismissViewControllerAnimated:YES completion:^{
			result(@(YES));
		}];
	}
	else {
		result(@(NO));
	}
}

@end
