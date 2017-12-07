//
//  MKDirectionsTests.m
//  MKDirectionsTests

//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>



//
// All distance in meters, speed is set in km/hours and
// converted into meters/sec for calculations
//
// Calculated deviations and another parameters are given in meters
//

#define MIN_DISTANCE	0.04		// sensitivity of the algorithm
#define TIME_INTERVAL	10			// simulated time step in seconds

@interface MKDirectionsTests : XCTestCase {
	CLLocation *route1;		// route segment points
	CLLocation *route2;
	CLLocation *route3;
	
	NSMutableArray *arrayStep;
	
	CLLocation *user1;		// user movement points
	CLLocation *user2;
	CLLocation *user3;
	CLLocation *user21;
	
	CLLocation *currentLocation;		// current user loction
	
	double speed;			// user speed
	
	double simulatedTime;
	
	BOOL onTheRoute;
}




@end

@implementation MKDirectionsTests

- (void)setUp
{
    [super setUp];
	
	//
	// Set up two segments - (r12) and (r23)
	//
	route1 = [[CLLocation alloc] initWithLatitude:55.236 longitude:36.577];
	route2 = [[CLLocation alloc] initWithLatitude:55.236 longitude:36.599];
	route3 = [[CLLocation alloc] initWithLatitude:55.2377 longitude:36.5467];
	
	//
	// Set up user's route
	//
	
	//User segment 1 - moves along the road (segment r12 )
	// but with the slight displacement
	user1 = [[CLLocation alloc] initWithLatitude:55.23458 longitude:36.5469];
	
	user2 = [[CLLocation alloc] initWithLatitude:55.23456 longitude:36.5469];
	user21 = [[CLLocation alloc] initWithLatitude:55.23458 longitude:36.5467];
	
	// and next we are going to the side
	user3 = [[CLLocation alloc] initWithLatitude:55.236 longitude:36.545];

	speed = 50.0;		// km/h
	
	//
	// Set up route segments
	//
	arrayStep = [NSMutableArray new];
	
	CLLocationCoordinate2D r_1 = [route1 coordinate];
	CLLocationCoordinate2D r_2 = [route2 coordinate];
	CLLocationCoordinate2D r_3 = [route3 coordinate];
	
	CLLocationCoordinate2D *route12	= malloc(2 * sizeof(CLLocationCoordinate2D));
	route12[0] = r_1;
	route12[1] = r_2;
	CLLocationCoordinate2D *route23	= malloc(2 * sizeof(CLLocationCoordinate2D));
	route23[0] = r_2;
	route23[1] = r_3;
	
	MKPolyline *r12 = [MKPolyline polylineWithCoordinates:route12 count:2];
	MKPolyline *r23 = [MKPolyline polylineWithCoordinates:route23 count:2];
	
	[arrayStep addObject:r12];
	[arrayStep addObject:r23];
	
	
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testDeviationRoute1
{
	onTheRoute = YES;
	// place user into initial point
	currentLocation = user1;
	while (onTheRoute) {
		[self calculateDeviation];
		[self updatePosition:1];
	}
	//XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testDeviationRoute2
{
	onTheRoute = YES;
	// place user into initial point
	currentLocation = user2;
	while (onTheRoute) {
		[self calculateDeviation];
		[self updatePosition:2];
	}
	//XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}


- (void) calculateDeviation
{
	NSLog(@"CurrentLocation: (%.6f, %.6f)",
		  currentLocation.coordinate.latitude,
		  currentLocation.coordinate.longitude);
	BOOL distanceChecked = [self checkDistanceFromRoute];
	
	NSLog(@"Distance checked - %@", (distanceChecked ? @"YES" : @"NO"));
}

- (void) updatePosition:(NSInteger) routeNum
{
	// Distance travelld for the time step in kilometers
	double travelDistance = speed / 3.6 * TIME_INTERVAL;
	
	// bearing
	double bearing = [self getHeadingForDirectionFromCoordinate:(routeNum == 1 ? user1.coordinate : user2.coordinate) toCoordinate:(routeNum == 1 ? user2.coordinate : user3.coordinate)];
	
	// update currentLocation
	CLLocationCoordinate2D newCoord = [self coordinateFromCoord:currentLocation.coordinate atDistanceKm:travelDistance atBearingDegrees:bearing];
	
	if (routeNum == 1) {
		if (newCoord.latitude < user2.coordinate.latitude ) {
			onTheRoute = NO;
			return;
		} else {
			if (newCoord.latitude > user3.coordinate.latitude &&
				newCoord.longitude < user3.coordinate.longitude) {
				onTheRoute = NO;
				return;
			}
		}
	}
	currentLocation = [[CLLocation alloc] initWithLatitude:newCoord.latitude longitude:newCoord.longitude];
}

#pragma mark - Utility methods

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * 180.0 / M_PI)

// return bearing in degrees
- (float)getHeadingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc
{
	float fLat = degreesToRadians(fromLoc.latitude);
	float fLng = degreesToRadians(fromLoc.longitude);
	float tLat = degreesToRadians(toLoc.latitude);
	float tLng = degreesToRadians(toLoc.longitude);
	
	float degree = radiansToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)));
	
	if (degree >= 0) {
		return degree;
	} else {
		return 360+degree;
	}
}

- (CLLocationCoordinate2D)coordinateFromCoord:
(CLLocationCoordinate2D)fromCoord
								 atDistanceKm:(double)distanceKm
        atBearingDegrees:(double)bearingDegrees
{
	double distanceRadians = distanceKm / 6371.0;
	//6,371 = Earth's radius in km
	double bearingRadians = degreesToRadians(bearingDegrees);
	double fromLatRadians = degreesToRadians(fromCoord.latitude);
	double fromLonRadians = degreesToRadians(fromCoord.longitude);
	
	double toLatRadians = asin( sin(fromLatRadians) * cos(distanceRadians)
							   + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians) );
	
	double toLonRadians = fromLonRadians + atan2(sin(bearingRadians)
												 * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians)
												 - sin(fromLatRadians) * sin(toLatRadians));
	
	// adjust toLonRadians to be in the range -180 to +180...
	toLonRadians = fmod((toLonRadians + 3*M_PI), (2*M_PI)) - M_PI;
	
	CLLocationCoordinate2D result;
	result.latitude = radiansToDegrees(toLatRadians);
	result.longitude = radiansToDegrees(toLonRadians);
	return result;
}

#pragma mark - Methods from View Controller are copied below -

- (BOOL)checkDistanceFromRoute
{
	//Get Coordinates of points in MKPolyline
	NSUInteger pointCount = arrayStep.count;
	
	CLLocationCoordinate2D *routeCoordinates = malloc(pointCount+1 * sizeof(CLLocationCoordinate2D));
	
	for (int i = 0 ; i < arrayStep.count ; i ++) {
#warning  MKRouteStep cannot be generated programmatically in user App!!!
		MKPolyline *step = arrayStep[i];
		NSInteger pCount = step.pointCount;	// get aount of points in segment
		CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * pCount);
		[step getCoordinates:coords range:NSMakeRange(0, pCount)];
		routeCoordinates[i] = coords[0];
		if (pointCount > 0 && i == arrayStep.count - 1) {
			// add last point from the last segment
			routeCoordinates[i+1] = coords[pointCount - 1];
		}
		
		if (coords) free(coords);
	}
	
	//Determine Minimum Distance and GuidancePoints from
	// Initial value should be set to the VERY BIG value to calculate
	// minimum
	double MinDistanceFromGuidanceInKM = 10000.0;
	CLLocationCoordinate2D prevPoint            = CLLocationCoordinate2DMake(0, 0);
	CLLocationCoordinate2D pointWithMinDistance = CLLocationCoordinate2DMake(0, 0);
	CLLocationCoordinate2D nextPoint            = CLLocationCoordinate2DMake(0, 0);
	
#warning  use currentLocation instead of MapView data
	
	int find = 0;
	for (int c=0; c < pointCount; c++) {
		double newDistanceInKM = [self distanceBetweentwoPoints:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude Old:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
		
		if (newDistanceInKM < MinDistanceFromGuidanceInKM) {
			
			find = c;
			
			MinDistanceFromGuidanceInKM = newDistanceInKM;
			
			prevPoint = routeCoordinates[MAX(c-1,0)];
			pointWithMinDistance = routeCoordinates[c];
			nextPoint = routeCoordinates[MIN(c+1,pointCount-1)];
		}
	}
	
	double distanceFromClosestRouteSegment = [self distanceOfUser:currentLocation.coordinate fromSegmentStart:prevPoint toSegmentEnd:pointWithMinDistance];
	double distanceFromNextSegment = [self distanceOfUser:currentLocation.coordinate fromSegmentStart:pointWithMinDistance toSegmentEnd:nextPoint];
	
	MinDistanceFromGuidanceInKM = MIN(distanceFromClosestRouteSegment, distanceFromNextSegment);
	
	//	MIN(
	//        [self lineSegmentDistanceFromOrigin:ulv.annotation.coordinate onLineSegmentPointA:prevPoint pointB:pointWithMinDistance],
	//        [self lineSegmentDistanceFromOrigin:ulv.annotation.coordinate onLineSegmentPointA:pointWithMinDistance pointB:nextPoint]);
	
	free(routeCoordinates);
	return (MinDistanceFromGuidanceInKM <= 1.2*MIN_DISTANCE);
}

//
// Returns distance between user locaton and route segment
//

- (double) distanceOfUser:(CLLocationCoordinate2D)userPoint fromSegmentStart:(CLLocationCoordinate2D)startPoint toSegmentEnd:(CLLocationCoordinate2D)endPoint
{
	CLLocation *pointA = [[CLLocation alloc] initWithLatitude:userPoint.latitude longitude:userPoint.longitude];
	CLLocation *pointB = [[CLLocation alloc] initWithLatitude:startPoint.latitude longitude:startPoint.longitude];
	CLLocation *pointC = [[CLLocation alloc] initWithLatitude:endPoint.latitude longitude:endPoint.longitude];
	
	// distance is in meters!
	CLLocationDistance segmentLength = [pointC distanceFromLocation:pointB];
	// if start and end points of this segment are too close, we will
	// just calculate distance between start of segment and current location
	if (segmentLength < MIN_DISTANCE * 1000.0) {
		// don't forget to convert it into kilometers
		return [pointA distanceFromLocation:pointB] / 1000.0;
	}
	
	//
	// Distance is in meters !
	//
	double userFromStartLength = [pointA distanceFromLocation:pointB];
	double userFromEndLength = [pointA distanceFromLocation:pointC];
	
	// convert into kilometers
	return [self distanceForTrinagleA:segmentLength
									B:userFromStartLength
								 andC:userFromEndLength] / 1000.0;
}


//
// A - length of the route segment, B and C - length to the atual user position
// from the start and end of the route segment. Method calculates deviation of
// current user' position from the route segment.
//

- (double) distanceForTrinagleA:(double)aLength B:(double)bLength andC:(double)cLength
{
	// if segment length is lesser than minimal length, suitablr
	// to solve triangle equation, just calculate distance from the start
	// of this segment, which is a bLength
	
	if (aLength < MIN_DISTANCE) {
		return bLength;
	}
	//
	// Calculate deviation as a height from user's position point to the
	// line, which depicts route segment. In fact, we calculate height
	// in the triangle, given by three lengths.
	//
	double p = (aLength + bLength + cLength) * 0.5;
	double tmp = p * (p - aLength) * (p - bLength) * (p - cLength);
	tmp = 2 / aLength * sqrt(tmp);
	
	return tmp;
}


-(double)distanceBetweentwoPoints:(double)Nlat longitude:(double)Nlon Old:(double)Olat longitude:(double)Olon  {
	
	double Math=3.14159265;
	double radlat1 = Math* Nlat/180;
	double radlat2 = Math * Olat/180;
	double theta = Nlon-Olon;
	double radtheta = Math * theta/180;
	double dist = sin(radlat1) * sin(radlat2) + cos(radlat1) * cos(radlat2) * cos(radtheta);
	if (dist>1) {dist=1;} else if (dist<-1) {dist=-1;}
	dist = acos(dist);
	dist = dist * 180/Math;
	dist = dist * 60 * 1.1515;
	return dist * 1.609344;
}


@end
