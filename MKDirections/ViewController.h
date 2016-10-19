//
//  ViewController.h
//  MKDirections
//
//  Created by Amol Mavuduru.
//  Copyright (c) Amols. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
//@property (weak, nonatomic) IBOutlet UILabel *destinationLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *transportLabel;
@property (weak, nonatomic) IBOutlet UILabel *estCostOfGasLabel;
@property (weak, nonatomic) IBOutlet UITextView *steps;

@property (strong, nonatomic) NSString *allSteps;

@property (nonatomic, retain) CLLocationManager *locationManager;
-(IBAction)alternateTransportation: (id)sender;
-(IBAction)getTraffic: (id)sender;
-(IBAction)getBikeTrails: (id)sender;

@end
