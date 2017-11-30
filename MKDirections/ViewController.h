//
//  ViewController.h
//  MKDirections
//

//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *destinationLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *transportLabel;
@property (weak, nonatomic) IBOutlet UITextView *steps;

@property (strong, nonatomic) NSString *allSteps;

@end
