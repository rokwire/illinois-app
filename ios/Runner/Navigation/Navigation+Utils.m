//
//  Navigation+Utils.h
//  Runner
//
//  Created by Mihail Varbanov on 8/19/22.
//  Copyright 2022 Board of Trustees of the University of Illinois.
//

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

#import "Navigation.h"
#import "Navigation+Utils.h"


/////////////////////////////////
// Math Utils

/**
 * The earth's radius, in meters.
 * Mean radius as defined by IUGG.
 */
static double EARTH_RADIUS = 6371009;

/**
 * Restrict x to the range [low, high].
 */
static double clamp(double x, double low, double high) {
	return x < low ? low : (x > high ? high : x);
}

/**
 * Returns the non-negative remainder of x / m.
 * @param x The operand.
 * @param m The modulus.
 */
static double mod(double x, double m) {
	return remainder(remainder(x, m) + m, m);
}

/**
 * Wraps the given value into the inclusive-exclusive interval between min and max.
 * @param n   The value to wrap.
 * @param min The minimum.
 * @param max The maximum.
 */
static double wrap(double n, double min, double max) {
	return (n >= min && n < max) ? n : (mod(n - min, max - min) + min);
}

/**
 * Returns mercator Y corresponding to latitude.
 * See http://en.wikipedia.org/wiki/Mercator_projection .
 */
static double mercator(double lat) {
	return log(tan(lat * 0.5 + M_PI_4));
}

/**
 * Returns latitude from mercator Y.
 */
static double inverseMercator(double y) {
	return 2 * atan(exp(y)) - M_PI_2;
}

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

// Given h==hav(x), returns sin(abs(x)).
static double sinFromHav(double h) {
	return 2 * sqrt(h * (1 - h));
}

// Returns hav(asin(x)).
static double havFromSin(double x) {
	double x2 = x * x;
	return x2 / (1 + sqrt(1 - x2)) * .5;
}

// Returns sin(arcHav(x) + arcHav(y)).
static double sinSumFromHav(double x, double y) {
	double a = sqrt(x * (1 - x));
	double b = sqrt(y * (1 - y));
	return 2 * (a + b - 2 * (a * y + b * x));
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

/**
 * Returns the measure in degrees of the supplied radian angle.
 */
static double toDegrees(double angrad) {
	return angrad * 180.0 / M_PI;
}




/////////////////////////////////
// Polyline Utils

//static double DEFAULT_TOLERANCE = 0.1;  // meters

/**
 * Returns tan(latitude-at-lng3) on the great circle (lat1, lng1) to (lat2, lng2). lng1==0.
 * See http://williams.best.vwh.net/avform.htm .
 */
static double tanLatGC(double lat1, double lat2, double lng2, double lng3) {
	return (tan(lat1) * sin(lng2 - lng3) + tan(lat2) * sin(lng3)) / sin(lng2);
}

/**
 * Returns mercator(latitude-at-lng3) on the Rhumb line (lat1, lng1) to (lat2, lng2). lng1==0.
 */
static double mercatorLatRhumb(double lat1, double lat2, double lng2, double lng3) {
	return (mercator(lat1) * (lng2 - lng3) + mercator(lat2) * lng3) / lng2;
}

/**
 * Computes whether the vertical segment (lat3, lng3) to South Pole intersects the segment
 * (lat1, lng1) to (lat2, lng2).
 * Longitudes are offset by -lng1; the implicit lng1 becomes 0.
 */
static bool intersects(double lat1, double lat2, double lng2,
					   double lat3, double lng3, bool geodesic) {
	// Both ends on the same side of lng3.
	if ((lng3 >= 0 && lng3 >= lng2) || (lng3 < 0 && lng3 < lng2)) {
		return false;
	}
	// Point is South Pole.
	if (lat3 <= -M_PI_2) {
		return false;
	}
	// Any segment end is a pole.
	if (lat1 <= -M_PI_2 || lat2 <= -M_PI_2 || lat1 >= M_PI_2 || lat2 >= M_PI_2) {
		return false;
	}
	if (lng2 <= -M_PI) {
		return false;
	}
	double linearLat = (lat1 * (lng2 - lng3) + lat2 * lng3) / lng2;
	// Northern hemisphere and point under lat-lng line.
	if (lat1 >= 0 && lat2 >= 0 && lat3 < linearLat) {
		return false;
	}
	// Southern hemisphere and point above lat-lng line.
	if (lat1 <= 0 && lat2 <= 0 && lat3 >= linearLat) {
		return true;
	}
	// North Pole.
	if (lat3 >= M_PI_2) {
		return true;
	}
	// Compare lat3 with latitude on the GC/Rhumb segment corresponding to lng3.
	// Compare through a strictly-increasing function (tan() or mercator()) as convenient.
	return geodesic ?
	tan(lat3) >= tanLatGC(lat1, lat2, lng2, lng3) :
	mercator(lat3) >= mercatorLatRhumb(lat1, lat2, lng2, lng3);
}

/**
 * Computes whether the given point lies inside the specified polygon.
 * The polygon is always cosidered closed, regardless of whether the last point equals
 * the first or not.
 * Inside is defined as not containing the South Pole -- the South Pole is always outside.
 * The polygon is formed of great circle segments if geodesic is true, and of rhumb
 * (loxodromic) segments otherwise.
 */

bool navContainsLocation(NavCoord *point, NSArray *polygon, bool geodesic) {
	int size = (int)polygon.count;
	if (size == 0) {
		return false;
	}
	double    lat3 = toRadians(point.latitude);
	double    lng3 = toRadians(point.longitude);
	NavCoord *prev = [polygon objectAtIndex:(size - 1)];
	double    lat1 = toRadians(prev.latitude);
	double    lng1 = toRadians(prev.longitude);
	int nIntersect = 0;
	for (NavCoord *point2 in polygon) {
		double dLng3 = wrap(lng3 - lng1, -M_PI, M_PI);
		// Special case: point equal to vertex is inside.
		if (lat3 == lat1 && dLng3 == 0) {
			return true;
		}
		double lat2 = toRadians(point2.latitude);
		double lng2 = toRadians(point2.longitude);
		// Offset longitudes by -lng1.
		if (intersects(lat1, lat2, wrap(lng2 - lng1, -M_PI, M_PI), lat3, dLng3, geodesic)) {
			++nIntersect;
		}
		lat1 = lat2;
		lng1 = lng2;
	}
	return (nIntersect & 1) != 0;
}

/**
 * Returns sin(initial bearing from (lat1,lng1) to (lat3,lng3) minus initial bearing
 * from (lat1, lng1) to (lat2,lng2)).
 */
static double sinDeltaBearing(double lat1, double lng1, double lat2, double lng2, double lat3, double lng3) {
	double sinLat1 = sin(lat1);
	double cosLat2 = cos(lat2);
	double cosLat3 = cos(lat3);
	double lat31 = lat3 - lat1;
	double lng31 = lng3 - lng1;
	double lat21 = lat2 - lat1;
	double lng21 = lng2 - lng1;
	double a = sin(lng31) * cosLat3;
	double c = sin(lng21) * cosLat2;
	double b = sin(lat31) + 2 * sinLat1 * cosLat3 * hav(lng31);
	double d = sin(lat21) + 2 * sinLat1 * cosLat2 * hav(lng21);
	double denom = (a * a + b * b) * (c * c + d * d);
	return denom <= 0 ? 1 : (a * d - b * c) / sqrt(denom);
}

static bool isOnSegmentGC(double lat1, double lng1, double lat2, double lng2, double lat3, double lng3, double havTolerance) {
	double havDist13 = havDistance(lat1, lat3, lng1 - lng3);
	if (havDist13 <= havTolerance) {
		return true;
	}
	double havDist23 = havDistance(lat2, lat3, lng2 - lng3);
	if (havDist23 <= havTolerance) {
		return true;
	}
	double sinBearing = sinDeltaBearing(lat1, lng1, lat2, lng2, lat3, lng3);
	double sinDist13 = sinFromHav(havDist13);
	double havCrossTrack = havFromSin(sinDist13 * sinBearing);
	if (havCrossTrack > havTolerance) {
		return false;
	}
	double havDist12 = havDistance(lat1, lat2, lng1 - lng2);
	double term = havDist12 + havCrossTrack * (1 - 2 * havDist12);
	if (havDist13 > term || havDist23 > term) {
		return false;
	}
	if (havDist12 < 0.74) {
		return true;
	}
	double cosCrossTrack = 1 - 2 * havCrossTrack;
	double havAlongTrack13 = (havDist13 - havCrossTrack) / cosCrossTrack;
	double havAlongTrack23 = (havDist23 - havCrossTrack) / cosCrossTrack;
	double sinSumAlongTrack = sinSumFromHav(havAlongTrack13, havAlongTrack23);
	return sinSumAlongTrack > 0;  // Compare with half-circle == PI using sign of sin().
}

int navIsLocationOnEdgeOrPath(NavCoord *point, NSArray *poly, bool closed, bool geodesic, double toleranceEarth) {
	int size = (int)poly.count;
	if (size == 0) {
		return -1;
	}
	int       index = 0;
	double    tolerance = toleranceEarth / EARTH_RADIUS;
	double    havTolerance = hav(tolerance);
	double    lat3 = toRadians(point.latitude);
	double    lng3 = toRadians(point.longitude);
	NavCoord *prev = [poly objectAtIndex:(closed ? size - 1 : 0)];
	double    lat1 = toRadians(prev.latitude);
	double    lng1 = toRadians(prev.longitude);
	if (geodesic) {
		for (NavCoord *point2 in poly) {
			double lat2 = toRadians(point2.latitude);
			double lng2 = toRadians(point2.longitude);
			if (isOnSegmentGC(lat1, lng1, lat2, lng2, lat3, lng3, havTolerance)) {
				return index;
			}
			lat1 = lat2;
			lng1 = lng2;
			index++;
		}
	} else {
		// We project the points to mercator space, where the Rhumb segment is a straight line,
		// and compute the geodesic distance between point3 and the closest point on the
		// segment. This method is an approximation, because it uses "closest" in mercator
		// space which is not "closest" on the sphere -- but the error is small because
		// "tolerance" is small.
		double minAcceptable = lat3 - tolerance;
		double maxAcceptable = lat3 + tolerance;
		double y1 = mercator(lat1);
		double y3 = mercator(lat3);
		double xTry[3];
		for (NavCoord *point2 in poly) {
			double lat2 = toRadians(point2.latitude);
			double y2 = mercator(lat2);
			double lng2 = toRadians(point2.longitude);
			if (MAX(lat1, lat2) >= minAcceptable && MIN(lat1, lat2) <= maxAcceptable) {
				// We offset longitudes by -lng1; the implicit x1 is 0.
				double x2 = wrap(lng2 - lng1, -M_PI, M_PI);
				double x3Base = wrap(lng3 - lng1, -M_PI, M_PI);
				xTry[0] = x3Base;
				// Also explore wrapping of x3Base around the world in both directions.
				xTry[1] = x3Base + 2 * M_PI;
				xTry[2] = x3Base - 2 * M_PI;
				for (int xTryIndex = 0; xTryIndex < 3; xTryIndex++) {
					double x3 = xTry[xTryIndex];
					double dy = y2 - y1;
					double len2 = x2 * x2 + dy * dy;
					double t = len2 <= 0 ? 0 : clamp((x3 * x2 + (y3 - y1) * dy) / len2, 0, 1);
					double xClosest = t * x2;
					double yClosest = y1 + t * dy;
					double latClosest = inverseMercator(yClosest);
					double havDist = havDistance(lat3, latClosest, x3 - xClosest);
					if (havDist < havTolerance) {
						return index;
					}
				}
			}
			lat1 = lat2;
			lng1 = lng2;
			y1 = y2;
			index++;
		}
	}
	return -1;
}

/**
 * Computes whether the given point lies on or near the edge of a polygon, within a specified
 * tolerance in meters. The polygon edge is composed of great circle segments if geodesic
 * is true, and of Rhumb segments otherwise. The polygon edge is implicitly closed -- the
 * closing segment between the first point and the last point is included.
 */
bool navIsLocationOnEdge(NavCoord *point, NSArray *polygon, bool geodesic, double tolerance) {
	return navIsLocationOnEdgeOrPath(point, polygon, true, geodesic, tolerance) >= 0;
}

/**
 * Computes whether the given point lies on or near a polyline, within a specified
 * tolerance in meters. The polyline is composed of great circle segments if geodesic
 * is true, and of Rhumb segments otherwise. The polyline is not closed -- the closing
 * segment between the first point and the last point is not included.
 */
bool navIsLocationOnPath(NavCoord *point, NSArray *polyline, bool geodesic, double tolerance) {
	return navIsLocationOnEdgeOrPath(point, polyline, false, geodesic, tolerance) >= 0;
}

int navGetLocationPathIndex(NavCoord *point, NSArray *polyline, bool geodesic, double tolerance) {
	return navIsLocationOnEdgeOrPath(point, polyline, false, geodesic, tolerance);
}

int navGetLocationStepIndex(NavCoord *point, NSArray *steps, double tolerance) {
	for (int stepIndex = 0; stepIndex < steps.count; stepIndex++) {
		NavRouteStep *step = [steps objectAtIndex:stepIndex];
		double stepDistance = navComputeDistanceBetween(step.startLocation.coordinate, point.coordinate);
		if (stepDistance <= tolerance)
			return stepIndex;
	}
	return -1;
}

/////////////////////////////////
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
double navComputeDistanceBetween(CLLocationCoordinate2D from, CLLocationCoordinate2D to) {
	return computeAngleBetween(from, to) * EARTH_RADIUS;
}

/**
 * Returns the heading from one LatLng to another LatLng. Headings are
 * expressed in degrees clockwise from North within the range [-180,180).
 * @return The heading in degrees clockwise from north.
 */

double navComputeHeading(CLLocationCoordinate2D from, CLLocationCoordinate2D to) {
	// http://williams.best.vwh.net/avform.htm#Crs
	double fromLat = toRadians(from.latitude);
	double fromLng = toRadians(from.longitude);
	double toLat = toRadians(to.latitude);
	double toLng = toRadians(to.longitude);
	double dLng = toLng - fromLng;
	double heading = atan2(
						   sin(dLng) * cos(toLat),
						   cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLng));
	return wrap(toDegrees(heading), -180, 180);
}

/**
 * Returns the LatLng resulting from moving a distance from an origin
 * in the specified heading (expressed in degrees clockwise from north).
 * @param from     The LatLng from which to start.
 * @param distance The distance to travel.
 * @param heading  The heading in degrees clockwise from north.
 */
CLLocationCoordinate2D navComputeOffset(CLLocationCoordinate2D from, double distance, double heading) {
	distance /= EARTH_RADIUS;
	heading = toRadians(heading);
	// http://williams.best.vwh.net/avform.htm#LL
	double fromLat = toRadians(from.latitude);
	double fromLng = toRadians(from.longitude);
	double cosDistance = cos(distance);
	double sinDistance = sin(distance);
	double sinFromLat = sin(fromLat);
	double cosFromLat = cos(fromLat);
	double sinLat = cosDistance * sinFromLat + sinDistance * cosFromLat * cos(heading);
	double dLng = atan2(
						sinDistance * cosFromLat * sin(heading),
						cosDistance - sinFromLat * sinLat);
	return CLLocationCoordinate2DMake(toDegrees(asin(sinLat)), toDegrees(fromLng + dLng));
}

/**
 * Returns the location of origin when provided with a LatLng destination,
 * meters travelled and original heading. Headings are expressed in degrees
 * clockwise from North. This function returns null when no solution is
 * available.
 * @param to       The destination LatLng.
 * @param distance The distance travelled, in meters.
 * @param heading  The heading in degrees clockwise from north.
 */
CLLocationCoordinate2D navComputeOffsetOrigin(CLLocationCoordinate2D to, double distance, double heading) {
	heading = toRadians(heading);
	distance /= EARTH_RADIUS;
	// http://lists.maptools.org/pipermail/proj/2008-October/003939.html
	double n1 = cos(distance);
	double n2 = sin(distance) * cos(heading);
	double n3 = sin(distance) * sin(heading);
	double n4 = sin(toRadians(to.latitude));
	// There are two solutions for b. b = n2 * n4 +/- sqrt(), one solution results
	// in the latitude outside the [-90, 90] range. We first try one solution and
	// back off to the other if we are outside that range.
	double n12 = n1 * n1;
	double discriminant = n2 * n2 * n12 + n12 * n12 - n12 * n4 * n4;
	if (discriminant < 0) {
		// No real solution which would make sense in LatLng-space.
		return CLLocationCoordinate2DMake(0,0);
	}
	double b = n2 * n4 + sqrt(discriminant);
	b /= n1 * n1 + n2 * n2;
	double a = (n4 - n2 * b) / n1;
	double fromLatRadians = atan2(a, b);
	if (fromLatRadians < -M_PI_2 || fromLatRadians > M_PI_2) {
		b = n2 * n4 - sqrt(discriminant);
		b /= n1 * n1 + n2 * n2;
		fromLatRadians = atan2(a, b);
	}
	if (fromLatRadians < -M_PI_2 || fromLatRadians > M_PI_2) {
		// No solution which would make sense in LatLng-space.
		return CLLocationCoordinate2DMake(0,0);
	}
	double fromLngRadians = toRadians(to.longitude) -
	atan2(n3, n1 * cos(fromLatRadians) - n2 * sin(fromLatRadians));
	return CLLocationCoordinate2DMake(toDegrees(fromLatRadians), toDegrees(fromLngRadians));
}

/**
 * Returns the LatLng which lies the given fraction of the way between the
 * origin LatLng and the destination LatLng.
 * @param from     The LatLng from which to start.
 * @param to       The LatLng toward which to travel.
 * @param fraction A fraction of the distance to travel.
 * @return The interpolated LatLng.
 */
CLLocationCoordinate2D navInterpolate(CLLocationCoordinate2D from, CLLocationCoordinate2D to, double fraction) {
	// http://en.wikipedia.org/wiki/Slerp
	double fromLat = toRadians(from.latitude);
	double fromLng = toRadians(from.longitude);
	double toLat = toRadians(to.latitude);
	double toLng = toRadians(to.longitude);
	double cosFromLat = cos(fromLat);
	double cosToLat = cos(toLat);
	
	// Computes Spherical interpolation coefficients.
	double angle = computeAngleBetween(from, to);
	double sinAngle = sin(angle);
	if (sinAngle < 1E-6) {
		return from;
	}
	double a = sin((1 - fraction) * angle) / sinAngle;
	double b = sin(fraction * angle) / sinAngle;
	
	// Converts from polar to vector and interpolate.
	double x = a * cosFromLat * cos(fromLng) + b * cosToLat * cos(toLng);
	double y = a * cosFromLat * sin(fromLng) + b * cosToLat * sin(toLng);
	double z = a * sin(fromLat) + b * sin(toLat);
	
	// Converts interpolated vector back to polar.
	double lat = atan2(z, sqrt(x * x + y * y));
	double lng = atan2(y, x);
	return CLLocationCoordinate2DMake(toDegrees(lat), toDegrees(lng));
}

/**
 * Returns the length of the given path, in meters, on Earth.
 */
double navComputeLength(NSArray *path) {
	if (path.count < 2) {
		return 0;
	}
	double length = 0;
	NavCoord *prev = [path objectAtIndex:0];
	double prevLat = toRadians(prev.latitude);
	double prevLng = toRadians(prev.longitude);
	for (NavCoord *point in path) {
		double lat = toRadians(point.latitude);
		double lng = toRadians(point.longitude);
		length += distanceRadians(prevLat, prevLng, lat, lng);
		prevLat = lat;
		prevLng = lng;
	}
	return length * EARTH_RADIUS;
}

/**
 * Returns the signed area of a triangle which has North Pole as a vertex.
 * Formula derived from "Area of a spherical triangle given two edges and the included angle"
 * as per "Spherical Trigonometry" by Todhunter, page 71, section 103, point 2.
 * See http://books.google.com/books?id=3uBHAAAAIAAJ&pg=PA71
 * The arguments named "tan" are tan((pi/2 - latitude)/2).
 */
static double polarTriangleArea(double tan1, double lng1, double tan2, double lng2) {
	double deltaLng = lng1 - lng2;
	double t = tan1 * tan2;
	return 2 * atan2(t * sin(deltaLng), 1 + t * cos(deltaLng));
}

/**
 * Returns the signed area of a closed path on a sphere of given radius.
 * The computed area uses the same units as the radius squared.
 * Used by SphericalUtilTest.
 */
static double computeSignedArea(NSArray *path, double radius) {
	int size = (int)path.count;
	if (size < 3) { return 0; }
	double total = 0;
	NavCoord *prev = [path objectAtIndex:(size - 1)];
	double prevTanLat = tan((M_PI_2 - toRadians(prev.latitude)) / 2);
	double prevLng = toRadians(prev.longitude);
	// For each edge, accumulate the signed area of the triangle formed by the North Pole
	// and that edge ("polar triangle").
	for (NavCoord *point in path) {
		double tanLat = tan((M_PI_2 - toRadians(point.latitude)) / 2);
		double lng = toRadians(point.longitude);
		total += polarTriangleArea(tanLat, lng, prevTanLat, prevLng);
		prevTanLat = tanLat;
		prevLng = lng;
	}
	return total * (radius * radius);
}

/**
 * Returns the signed area of a closed path on Earth. The sign of the area may be used to
 * determine the orientation of the path.
 * "inside" is the surface that does not contain the South Pole.
 * @param path A closed path.
 * @return The loop's area in square meters.
 */
double navComputeSignedArea(NSArray *path) {
	return computeSignedArea(path, EARTH_RADIUS);
}

/**
 * Returns the area of a closed path on Earth.
 * @param path A closed path.
 * @return The path's area in square meters.
 */
double navComputeArea(NSArray *path) {
	return fabs(navComputeSignedArea(path));
}

/////////////////////////////////
// Encoding Utils

NSMutableArray* navCreatePolygonFromEncodedString(NSString *encodedString) {
	const char             *bytes  = [encodedString UTF8String];
	NSUInteger              length = [encodedString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger              idx    = 0;
	int                     lat    = 0;
	int                     lng    = 0;
	int                     byte   = 0;
	int                     res    = 0;
	int                     shift  = 0;
	
	NSMutableArray *list = [NSMutableArray array];
	
	while (idx < length) {
		res   = 1;
		shift = 0;
		do {
			byte   = bytes[idx++] - 63 - 1;
			res   += byte << shift;
			shift += 5;
		}
		while (byte >= 0x1f);
		
		lat += ((res & 1) ? ~(res >> 1) : (res >> 1));
		
		res   = 1;
		shift = 0;
		do {
			byte   = bytes[idx++] - 63 - 1;
			res   += byte << shift;
			shift += 5;
		}
		while (byte >= 0x1f);
		
		lng += ((res & 1) ? ~(res >> 1) : (res >> 1));

		NavCoord *navCoord = [[NavCoord alloc] initWithLatitude:(lat * 1e-5) longitude:(lng * 1e-5)];
		[list addObject:navCoord];
	}
	
	return list;
}

