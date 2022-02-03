#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface TrackingServices : NSObject

+ (instancetype)sharedInstance;

- (void)handleMethodCallWithName:(NSString*)name parameters:(id)parameters result:(FlutterResult)result;

@end
