#import "TrackingServices.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@interface TrackingServices()
@property (nonatomic) NSMutableSet<FlutterResult> *trackingFlutterResults;
@end

@implementation TrackingServices

+ (instancetype)sharedInstance {
    static TrackingServices *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
	
    return _sharedInstance;
}

- (void)handleMethodCallWithName:(NSString*)name parameters:(id)parameters result:(FlutterResult)result {
	if ([name isEqualToString:@"queryAuthorizationStatus"]) {
		[self queryAuthorizationStatusWithFlutterResult:result];
	}
	else if ([name isEqualToString:@"requestAuthorization"]) {
		[self requestAuthorizationWithFlutterResult:result];
	}
	else {
		result(nil);
	}
}

- (void)queryAuthorizationStatusWithFlutterResult:(FlutterResult)result {
	if (@available(iOS 14, *)) {
		result([self.class authorizationStatusFromTrackingManagerAuthorizationStatus:[ATTrackingManager trackingAuthorizationStatus]]);
	} else {
		result(@"allowed");
	}
}

+ (NSString*)authorizationStatusFromTrackingManagerAuthorizationStatus:(NSUInteger)authorizationStatus {
	if (@available(iOS 14, *)) {
		switch (authorizationStatus) {
			case ATTrackingManagerAuthorizationStatusNotDetermined:       return @"not_determined";
			case ATTrackingManagerAuthorizationStatusRestricted:          return @"restricted";
			case ATTrackingManagerAuthorizationStatusDenied:              return @"denied";
			case ATTrackingManagerAuthorizationStatusAuthorized:          return @"allowed";
		}
	}
	return nil;
}

- (void)requestAuthorizationWithFlutterResult:(FlutterResult)result {
	if (@available(iOS 14, *)) {
		ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
		if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
			if (_trackingFlutterResults != nil) {
				[_trackingFlutterResults addObject:result];
			}
			else {
				__weak typeof(self) weakSelf = self;
				_trackingFlutterResults = [[NSMutableSet alloc] initWithObjects:result, nil];
				[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
					NSSet<FlutterResult> *flutterResults = weakSelf.trackingFlutterResults;
					weakSelf.trackingFlutterResults = nil;
					
					for(FlutterResult flutterResult in flutterResults) {
						flutterResult([self.class authorizationStatusFromTrackingManagerAuthorizationStatus:status]);
					}
				}];
			}
		}
		else {
			result([self.class authorizationStatusFromTrackingManagerAuthorizationStatus:status]);
		}
	} else {
		result(@"allowed");
	}
}

@end
