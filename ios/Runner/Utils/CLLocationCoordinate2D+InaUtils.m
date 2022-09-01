//
//  CLLocationCoordinate2D+InaUtils.h
//  InaUtils
//
//  Created by Mihail Varbanov on 7/17/19.
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

#import "CLLocationCoordinate2D+InaUtils.h"

/**
 * The earth's radius, in meters.
 * Mean radius as defined by IUGG.
 */
static double EARTH_RADIUS = 6371009;

/**
 * Returns haversine(angle-in-radians).
 * hav(x) == (1 - cos(x)) / 2 == sin(x / 2)^2.
 */
static double hav(double x) {
	double sinHalf = sin(x * 0.5);
	return sinHalf * sinHalf;
}

/**
 * Computes inverse haversine. Has good numerical stability around 0.
 * arcHav(x) == acos(1 - 2 * x) == 2 * asin(sqrt(x)).
 * The argument must be in [0, 1], and the result is positive.
 */
static double arcHav(double x) {
	return 2 * asin(sqrt(x));
}

/**
 * Returns hav() of distance from (lat1, lng1) to (lat2, lng2) on the unit sphere.
 */
static double havDistance(double lat1, double lat2, double dLng) {
	return hav(lat1 - lat2) + hav(dLng) * cos(lat1) * cos(lat2);
}

/**
 * Returns the measure in radians of the supplied degree angle.
 */
static double toRadians(double angdeg) {
	return angdeg / 180.0 * M_PI;
}

// Spherical Utils

/**
 * Returns distance on the unit sphere; the arguments are in radians.
 */
static double distanceRadians(double lat1, double lng1, double lat2, double lng2) {
	return arcHav(havDistance(lat1, lat2, lng1 - lng2));
}

/**
 * Returns the angle between two LatLngs, in radians. This is the same as the distance
 * on the unit sphere.
 */
static double computeAngleBetween(CLLocationCoordinate2D from, CLLocationCoordinate2D to) {
	return distanceRadians(toRadians(from.latitude), toRadians(from.longitude),
						   toRadians(to.latitude), toRadians(to.longitude));
}

/**
 * Returns the distance between two LatLngs, in meters.
 */
double CLLocationCoordinate2DInaDistance(CLLocationCoordinate2D from, CLLocationCoordinate2D to) {
	return computeAngleBetween(from, to) * EARTH_RADIUS;
}

bool CLLocationCoordinate2DIsEqual(CLLocationCoordinate2D point1, CLLocationCoordinate2D point2) {
	return (point1.latitude == point2.latitude) && (point1.longitude == point2.longitude);
}

bool CLLocationCoordinate2DIsNear(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2, double tolerance) {
	return (fabs(coord1.latitude - coord2.latitude) < tolerance) && (fabs(coord1.longitude - coord2.longitude) < tolerance);
}
