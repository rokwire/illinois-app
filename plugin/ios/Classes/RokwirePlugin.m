#import "RokwirePlugin.h"
#import "LocationServices.h"

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
  
  NSArray<NSString*> *methodComponents = [call.method componentsSeparatedByString:@"."];
  NSString *firstMethodComponent = methodComponents.firstObject, *nextMethodComponents = nil;
  
  if (1 < methodComponents.count) {
    NSMutableArray<NSString*>* methodComponents1 = [NSMutableArray arrayWithArray:methodComponents];
    [methodComponents1 removeObjectAtIndex:0];
    nextMethodComponents = [methodComponents1 componentsJoinedByString:@"."];
  }
  
  if ([firstMethodComponent isEqualToString:@"getPlatformVersion"]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }
  else if ([firstMethodComponent isEqualToString:@"locationServices"]) {
    [LocationServices.sharedInstance handleMethodCallWithName:nextMethodComponents parameters:call.arguments result:result];
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

@end
