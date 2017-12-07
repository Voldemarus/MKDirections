//
//  ViewController.m
//  MKDirections
//

//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#define MIN_DISTANCE        .004
@interface ViewController () {
    NSMutableArray          *arrayStep;
    
}

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

CLPlacemark *thePlacemark;
MKRoute *routeDetails;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
        arrayStep = [NSMutableArray array];
    self.mapView.delegate = self;
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    [self.locationManager requestWhenInUseAuthorization];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if ([self checkDistanceFromRoute] == NO) {
        [self clearRoute];
        [self routeButtonPressed:nil];
        return;
    }
}


- (IBAction)routeButtonPressed:(UIBarButtonItem *)sender {
    MKDirectionsRequest *directionsRequest = [[MKDirectionsRequest alloc] init];
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:thePlacemark];
    
    [directionsRequest setSource:[MKMapItem mapItemForCurrentLocation]];
    
    [directionsRequest setDestination:[[MKMapItem alloc] initWithPlacemark:placemark]];
    directionsRequest.transportType = MKDirectionsTransportTypeAutomobile;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error %@", error.description);
        } else {
        
            routeDetails = response.routes.lastObject;
            [self.mapView addOverlay:routeDetails.polyline];
            self.destinationLabel.text = [placemark.addressDictionary objectForKey:@"Street"];
            self.distanceLabel.text = [NSString stringWithFormat:@"%0.1f Miles", routeDetails.distance/1609.344];
            self.transportLabel.text = [NSString stringWithFormat:@"%lu" ,(unsigned long)routeDetails.transportType];
            self.allSteps = @"";
            for (int i = 0; i < routeDetails.steps.count; i++) {
                MKRouteStep *step = [routeDetails.steps objectAtIndex:i];
                NSString *newStep = step.instructions;
                self.allSteps = [self.allSteps stringByAppendingString:newStep];
                self.allSteps = [self.allSteps stringByAppendingString:@"\n\n"];
                self.steps.text = self.allSteps;
            }
        }
    }];
}


- (void)clearRoute {

    [arrayStep removeAllObjects];
    self.destinationLabel.text = nil;
    self.distanceLabel.text = nil;
    self.transportLabel.text = nil;
    self.steps.text = nil;
    
    //   [speechSync stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.mapView removeOverlays: self.mapView.overlays];
    
}




- (IBAction)addressSearch:(UITextField *)sender {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:sender.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            thePlacemark = [placemarks lastObject];
            float spanX = 1.00725;
            float spanY = 1.00725;
            MKCoordinateRegion region;
            region.center.latitude = thePlacemark.location.coordinate.latitude;
            region.center.longitude = thePlacemark.location.coordinate.longitude;
            region.span = MKCoordinateSpanMake(spanX, spanY);
            [self.mapView setRegion:region animated:YES];
            [self addAnnotation:thePlacemark];
        }
    }];
}

- (void)addAnnotation:(CLPlacemark *)placemark {
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude);
    point.title = [placemark.addressDictionary objectForKey:@"Street"];
    point.subtitle = [placemark.addressDictionary objectForKey:@"City"];
    [self.mapView addAnnotation:point];
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer  * routeLineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:routeDetails.polyline];
    routeLineRenderer.strokeColor = [UIColor redColor];
    routeLineRenderer.lineWidth = 5;
    return routeLineRenderer;
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        // Try to dequeue an existing pin view first.
        MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        if (!pinView)
        {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
            pinView.canShowCallout = YES;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

- (BOOL)checkDistanceFromRoute
{
    //Get Coordinates of points in MKPolyline
    NSUInteger pointCount = arrayStep.count;
    
    CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0 ; i < arrayStep.count ; i ++) {
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
	
//        MKRouteStep *step = arrayStep[i];
//        routeCoordinates[i] = step.polyline.coordinate;
    }
    
    //Determine Minimum Distance and GuidancePoints from
 
    double MinDistanceFromGuidanceInKM = 10000.0;
    CLLocationCoordinate2D prevPoint            = CLLocationCoordinate2DMake(0, 0);
    CLLocationCoordinate2D pointWithMinDistance = CLLocationCoordinate2DMake(0, 0);
    CLLocationCoordinate2D nextPoint            = CLLocationCoordinate2DMake(0, 0);
    
    MKAnnotationView *ulv = [self.mapView viewForAnnotation:self.mapView.userLocation];
    
    int find = 0;
    for (int c=0; c < pointCount; c++) {
        double newDistanceInKM = [self distanceBetweentwoPoints:ulv.annotation.coordinate.latitude longitude:ulv.annotation.coordinate.longitude Old:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
        
        if (newDistanceInKM < MinDistanceFromGuidanceInKM) {
            
            find = c;
            
            MinDistanceFromGuidanceInKM = newDistanceInKM;
            
            prevPoint = routeCoordinates[MAX(c-1,0)];
            pointWithMinDistance = routeCoordinates[c];
            nextPoint = routeCoordinates[MIN(c+1,pointCount-1)];
        }
    }
    free(routeCoordinates);
	
	double distanceFromClosestRouteSegment = [self distanceOfUser:ulv.annotation.coordinate fromSegmentStart:prevPoint toSegmentEnd:pointWithMinDistance];
	double distanceFromNextSegment = [self distanceOfUser:ulv.annotation.coordinate fromSegmentStart:pointWithMinDistance toSegmentEnd:nextPoint];
	
	MinDistanceFromGuidanceInKM = MIN(distanceFromClosestRouteSegment, distanceFromNextSegment);
	
//	MIN(
//        [self lineSegmentDistanceFromOrigin:ulv.annotation.coordinate onLineSegmentPointA:prevPoint pointB:pointWithMinDistance],
//        [self lineSegmentDistanceFromOrigin:ulv.annotation.coordinate onLineSegmentPointA:pointWithMinDistance pointB:nextPoint]);
	
    if (MinDistanceFromGuidanceInKM > 1.2*MIN_DISTANCE) {
     
        return NO;
    }
    
    else {
        return YES;
    }
     
}

//
// Returns distance between user locaton and route segment
//

- (double) distanceOfUser:(CLLocationCoordinate2D)userPoint fromSegmentStart:(CLLocationCoordinate2D)startPoint toSegmentEnd:(CLLocationCoordinate2D)endPoint
{
	CLLocation *pointA = [[CLLocation alloc] initWithLatitude:userPoint.latitude longitude:userPoint.longitude];
	CLLocation *pointB = [[CLLocation alloc] initWithLatitude:startPoint.latitude longitude:startPoint.longitude];
	CLLocation *pointC = [[CLLocation alloc] initWithLatitude:endPoint.latitude longitude:endPoint.longitude];
	
	CLLocationDistance segmentLength = [pointC distanceFromLocation:pointB];
	if (segmentLength < MIN_DISTANCE * 1000.0) {
		// don't forget to convert it into kilometers
		return [pointA distanceFromLocation:pointB] / 1000.0;
	}
	
	double userFromStartLength = [pointA distanceFromLocation:pointB];
	double userFromEndLength = [pointA distanceFromLocation:pointC];
	
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

/*
- (CGFloat)lineSegmentDistanceFromOrigin:(CLLocationCoordinate2D)origin onLineSegmentPointA:(CLLocationCoordinate2D)pointA pointB:(CLLocationCoordinate2D)pointB {
    
    CGPoint dAP = CGPointMake(origin.longitude - pointA.longitude, origin.latitude - pointA.latitude);
    CGPoint dAB = CGPointMake(pointB.longitude - pointA.longitude, pointB.latitude - pointA.latitude);
    CGFloat dot = dAP.x * dAB.x + dAP.y * dAB.y;
    CGFloat squareLength = dAB.x * dAB.x + dAB.y * dAB.y;
    
    CGFloat param = dot / MAX(squareLength,.001);
    
    CGPoint nearestPoint;
    if (param < 0 || (pointA.longitude == pointB.longitude && pointA.latitude == pointB.latitude)) {
        nearestPoint.x = pointA.longitude;
        nearestPoint.y = pointA.latitude;
    } else if (param > 1) {
        nearestPoint.x = pointB.longitude;
        nearestPoint.y = pointB.latitude;
    } else {
        nearestPoint.x = pointA.longitude + param * dAB.x;
        nearestPoint.y = pointA.latitude + param * dAB.y;
    }
    
    CGFloat dx = origin.longitude - nearestPoint.x;
    CGFloat dy = origin.latitude - nearestPoint.y;
    
    return sqrtf(dx * dx + dy * dy);
    
}
 */

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
