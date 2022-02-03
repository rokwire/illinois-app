#import "LocationServices.h"
#import <CoreLocation/CoreLocation.h>

@interface LocationServices()<CLLocationManagerDelegate>
@property (nonatomic) CLLocationManager *clLocationManager;
@property (nonatomic) NSMutableSet<FlutterResult> *locationFlutterResults;
@end

@implementation LocationServices

+ (instancetype)sharedInstance {
    static LocationServices *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
	
    return _sharedInstance;
}

- (void)handleMethodCallWithName:(NSString*)name parameters:(id)parameters result:(FlutterResult)result {
	if ([name isEqualToString:@"queryStatus"]) {
		[self queryLocationServicesStatusWithFlutterResult:result];
	}
	else if ([name isEqualToString:@"requestPermision"]) {
		[self requestLocationServicesPermisionWithFlutterResult:result];
	}
	else {
		result(nil);
	}
}

- (void)queryLocationServicesStatusWithFlutterResult:(FlutterResult)result {
	NSString *status = [CLLocationManager locationServicesEnabled] ?
		[self.class locationServicesPermisionFromAuthorizationStatus:[CLLocationManager authorizationStatus]] :
		@"disabled";
	result(status);
}

+ (NSString*)locationServicesPermisionFromAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus {
	switch (authorizationStatus) {
		case kCLAuthorizationStatusNotDetermined:       return @"not_determined";
		case kCLAuthorizationStatusRestricted:          return @"denied";
		case kCLAuthorizationStatusDenied:              return @"denied";
		case kCLAuthorizationStatusAuthorizedAlways:    return @"allowed";
		case kCLAuthorizationStatusAuthorizedWhenInUse: return @"allowed";
	}
	return nil;
}

- (void)requestLocationServicesPermisionWithFlutterResult:(FlutterResult)result {
	if ([CLLocationManager locationServicesEnabled]) {
		CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
		if (status == kCLAuthorizationStatusNotDetermined) {
			if (_locationFlutterResults == nil) {
				_locationFlutterResults = [[NSMutableSet alloc] init];
			}
			[_locationFlutterResults addObject:result];

			if (_clLocationManager == nil) {
				_clLocationManager = [[CLLocationManager alloc] init];
				_clLocationManager.delegate = self;
				[_clLocationManager requestWhenInUseAuthorization];
			}
		}
		else {
			result([self.class locationServicesPermisionFromAuthorizationStatus:status]);
		}
	}
	else {
		result([self.class locationServicesPermisionFromAuthorizationStatus:kCLAuthorizationStatusRestricted]);
	}
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {

	if (status != kCLAuthorizationStatusNotDetermined) {
		_clLocationManager.delegate = nil;
		_clLocationManager = nil;

		NSSet<FlutterResult> *flutterResults = _locationFlutterResults;
		_locationFlutterResults = nil;

		for(FlutterResult flutterResult in flutterResults) {
			flutterResult([self.class locationServicesPermisionFromAuthorizationStatus:status]);
		}
	}
}

@end
