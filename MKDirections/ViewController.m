//
//  ViewController.m
//  MKDirections
//
//  Created by Amol Mavuduru.
//  Copyright (c) Amols. All rights reserved.
//

#import "ViewController.h"
#import "MapPin.h"
#include <math.h>

@interface ViewController ()

@end

@implementation ViewController

@synthesize locationManager;

@synthesize mapView;

CLPlacemark *thePlacemark;
MKRoute *routeDetails;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.mapView.delegate = self;
    
    self.mapView.showsBuildings = YES;
    MKCoordinateRegion Richardson = { {0.0, 0.0}, {0.0}};
    Richardson.center.latitude = 32.94833;                       //Coordinates of Richardson, Texas
    Richardson.center.longitude = -96.72985;
    Richardson.span.longitudeDelta = 0.15f;               //The longitude span of the map.
    Richardson.span.latitudeDelta = 0.15f;                //The latitude span of the map.
    [self.mapView setRegion:Richardson animated:YES];
    
    
    locationManager = [[CLLocationManager alloc]init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if([locationManager respondsToSelector: @selector(requestWhenInUseAuthorization)])
    {
        [locationManager requestWhenInUseAuthorization];
    }
    
    
    
    [locationManager startUpdatingLocation];
    
    self.mapView.showsUserLocation = YES;
}

- (IBAction)routeButtonPressedCar:(UIBarButtonItem *)sender {
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
           // self.destinationLabel.text = [placemark.addressDictionary objectForKey:@"Street"];
            self.distanceLabel.text = [NSString stringWithFormat:@"%0.1f Miles", routeDetails.distance/1609.344];
            self.estCostOfGasLabel.text = [NSString stringWithFormat:@"$%0.2f ", ((1.95*routeDetails.distance/1609.344)/39.0)];
            self.transportLabel.text = [NSString stringWithFormat:@"%s" , "Car"];
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

- (IBAction)alternateTransportation:(id)sender
{
    NSString *urlString = @"http://maps.apple.com/maps?daddr=32.94833,-96.72985";
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:urlString] ];
    
}



- (IBAction)clearRoute:(UIBarButtonItem *)sender {
   // self.destinationLabel.text = nil;
    self.distanceLabel.text = nil;
    self.transportLabel.text = nil;
    self.steps.text = nil;
    self.estCostOfGasLabel.text = nil;
    [self.mapView removeOverlay:routeDetails.polyline];
    
}

- (IBAction)addressSearch:(UITextField *) sender {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:sender.text completionHandler:^(NSArray *placemarks, NSError *error)
    {
        
        NSLog(@"String: %@", sender.text);
        NSLog(@"Sender: %@", sender);
        
        if (error) {
            NSLog(@"%@", error);
        } else {
            thePlacemark = [placemarks lastObject];
            //float spanX = 1.00725;
           // float spanY = 1.00725;
            float spanX = fabs(thePlacemark.location.coordinate.longitude - mapView.userLocation.coordinate.longitude) + 0.1;
            float spanY = fabs(thePlacemark.location.coordinate.latitude - mapView.userLocation.coordinate.latitude) + 0.1;
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

-(IBAction)getTraffic: (id)sender;
{
    MapPin *Coit = [[MapPin alloc] init];
    Coit.title = @"Coit Rd";
    Coit.subtitle = @"Very high volume traffic!";
    MKCoordinateRegion coit = { {0.0, 0.0}, 0.0};
    coit.center.latitude = 33.08842;
    coit.center.longitude = -96.77113;
    Coit.coordinate = coit.center;
    [self.mapView addAnnotation: Coit];
    
    MapPin *ECampbell = [[MapPin alloc] init];
    ECampbell.title = @"E Campbell Rd";
    ECampbell.subtitle = @"High volume traffic!";
    MKCoordinateRegion ecampbell = { {0.0, 0.0}, 0.0};
    ecampbell.center.latitude = 32.997486;
    ecampbell.center.longitude = -96.699753;
    ECampbell.coordinate = ecampbell.center;
    [self.mapView addAnnotation: ECampbell];
    
    MapPin *Arapaho = [[MapPin alloc] init];
    Arapaho.title = @"Arapaho Rd";
    Arapaho.subtitle = @"High volume traffic!";
    MKCoordinateRegion arapaho = {{0.0, 0.0}, 0.0};
    arapaho.center.latitude = 32.960596;
    arapaho.center.longitude = -96.811069;
    Arapaho.coordinate = arapaho.center;
    [self.mapView addAnnotation: Arapaho];
    
    MapPin *ERenner = [[MapPin alloc] init];
    ERenner.title = @"E Renner Rd";
    ERenner.subtitle = @"Moderate volume traffic";
    MKCoordinateRegion erenner = {{0.0, 0.0}, 0.0};
    erenner.center.latitude = 32.997082;
    erenner.center.longitude = -96.658198;
    ERenner.coordinate = erenner.center;
    [self.mapView addAnnotation: ERenner];
    
    MapPin *WRenner = [[MapPin alloc] init];
    WRenner.title = @"W Renner Rd";
    WRenner.subtitle = @"Moderate volume traffic";
    MKCoordinateRegion wrenner = {{0.0, 0.0}, 0.0};
    wrenner.center.latitude = 32.997584;
    wrenner.center.longitude = -96.725962;
    WRenner.coordinate = wrenner.center;
    [self.mapView addAnnotation: WRenner];
    
    MapPin *WCampbell = [[MapPin alloc] init];
    WCampbell.title = @"W Campbell Rd";
    WCampbell.subtitle = @"Moderate volume traffic";
    MKCoordinateRegion wcampbell = {{0.0, 0.0}, 0.0};
    wcampbell.center.latitude = 32.997082;
    wcampbell.center.longitude = -96.658198;
    WCampbell.coordinate = wcampbell.center;
    [self.mapView addAnnotation: WCampbell];
    
    MapPin *CusterPkwy = [[MapPin alloc] init];
    CusterPkwy.title = @"Custer Parkway";
    CusterPkwy.subtitle = @"Low volume traffic";
    MKCoordinateRegion custerpkwy = {{0.0, 0.0}, 0.0};
    custerpkwy.center.latitude = 32.988324;
    custerpkwy.center.longitude = -96.728035;
    CusterPkwy.coordinate = custerpkwy.center;
    [self.mapView addAnnotation: CusterPkwy];

    MapPin *NCollinsBlvd = [[MapPin alloc] init];
    NCollinsBlvd.title = @"N Collins Blvd";
    NCollinsBlvd.subtitle = @"Low volume traffic";
    MKCoordinateRegion ncollinsblvd = {{0.0, 0.0}, 0.0};
    ncollinsblvd.center.latitude = 32.982068;
    ncollinsblvd.center.longitude = -96.717052;
    NCollinsBlvd.coordinate = ncollinsblvd.center;
    [self.mapView addAnnotation: NCollinsBlvd];
    
    MapPin *EBuckinghamRd = [[MapPin alloc] init];
    EBuckinghamRd.title = @"E Buckingham Rd";
    EBuckinghamRd.subtitle = @"High volume traffic";
    MKCoordinateRegion ebuckingham = {{0.0, 0.0}, 0.0};
    ebuckingham.center.latitude = 32.934815;
    ebuckingham.center.longitude = -96.730008;
    EBuckinghamRd.coordinate = ebuckingham.center;
    [self.mapView addAnnotation: EBuckinghamRd];
    
    MapPin *NPlanoRd = [[MapPin alloc] init];
    NPlanoRd.title = @"N Plano Rd";
    NPlanoRd.subtitle = @"Moderate volume traffic";
    MKCoordinateRegion nplanord = {{0.0, 0.0}, 0.0};
    nplanord.center.latitude = 32.958140;
    nplanord.center.longitude = -96.699950;
    NPlanoRd.coordinate = nplanord.center;
    [self.mapView addAnnotation: NPlanoRd];
    
    MapPin *CentennBlvd = [[MapPin alloc] init];
    CentennBlvd.title = @"Centennial Blvd";
    CentennBlvd.subtitle = @"Very high volume traffic!";
    MKCoordinateRegion centennblvd = {{0.0, 0.0}, 0.0};
    centennblvd.center.latitude = 32.938231;
    centennblvd.center.longitude = -96.720758;
    CentennBlvd.coordinate = centennblvd.center;
    [self.mapView addAnnotation: CentennBlvd];
    
}

-(IBAction)getBikeTrails: (id)sender;
{
    CLLocationCoordinate2D rennerTrail;
    rennerTrail.latitude = 32.997305;
    rennerTrail.longitude = -96.725848;
    MapPin *RennerTrail = [[MapPin alloc] init];
    RennerTrail.title = @"Renner Trail";
    RennerTrail.subtitle = @"Bike trail";
    RennerTrail.coordinate = rennerTrail;
    [self.mapView addAnnotation: RennerTrail];
    
    CLLocationCoordinate2D cottonwoodTrail;
    cottonwoodTrail.latitude = 32.9196471;
    cottonwoodTrail.longitude = -96.7649725;
    MapPin *CottonWoodTrail = [[MapPin alloc] init];
    CottonWoodTrail.title = @"CottonWood Trail";
    CottonWoodTrail.subtitle = @"Bike trail";
    CottonWoodTrail.coordinate = cottonwoodTrail;
    [self.mapView addAnnotation: CottonWoodTrail];
    
    CLLocationCoordinate2D univTrail;
    univTrail.latitude = 32.984531;
    univTrail.longitude = -96.748754;
    MapPin *UnivTrail = [[MapPin alloc] init];
    UnivTrail.title = @"University Trail";
    UnivTrail.subtitle = @"Bike trail";
    UnivTrail.coordinate = univTrail;
    [self.mapView addAnnotation: UnivTrail];
    
    CLLocationCoordinate2D cottonbelt;
    cottonbelt.latitude = 32.893384;
    cottonbelt.longitude = -97.167971;
    MapPin *CottonBeltTrail = [[MapPin alloc] init];
    CottonBeltTrail.title = @"Cotton Belt Trail";
    CottonBeltTrail.subtitle = @"Bike trail";
    CottonBeltTrail.coordinate = cottonbelt;
    [self.mapView addAnnotation: CottonBeltTrail];
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate function

-(void) locationManager: (CLLocationManager *) manager didUpdateLocations: (NSArray<CLLocation *> *)locations
{
    CLLocation *location = [locations lastObject];
    
    NSLog(@"Lat: %f, Lon: %f", location.coordinate.latitude, location.coordinate.longitude);
}



@end
