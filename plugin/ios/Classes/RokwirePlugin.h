#import <Flutter/Flutter.h>

@interface RokwirePlugin : NSObject<FlutterPlugin>
+ (instancetype)sharedInstance;
- (void)notifyGeoFenceEvent:(NSString*)event arguments:(id)arguments;
@end
