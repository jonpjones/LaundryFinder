//
//  ResultsDisplayViewController.m
//  StarchupCodeChallenge
//
//  Created by Jonathan Jones on 6/2/16.
//  Copyright © 2016 JJones. All rights reserved.
//

#import "ResultsDisplayViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "GooglePlacesController.h"
#import "LaundryBusiness.h"

@import Mapbox;

@interface ResultsDisplayViewController () <CLLocationManagerDelegate, FetchPlacesDelegate, MGLMapViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *laundryTableView;
@property (weak, nonatomic) IBOutlet UILabel *laundryCityLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapListSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *currentCityLabel;

@property CLLocationManager *locationManager;
@property CLLocation *userLocation;
@property GooglePlacesController *googleAPIController;
@property MGLMapView *mapView;
@property NSArray *laundryArray;
@property NSString *cityString;
@end

@implementation ResultsDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpMapAndLayout];
    
    self.locationManager = [[CLLocationManager alloc]  init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    
    self.googleAPIController = [[GooglePlacesController alloc] init];
    self.googleAPIController.delegate = self;
}

-(void)setUpMapAndLayout {
    self.mapView = [[MGLMapView alloc] initWithFrame:self.view.frame];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [self.view sendSubviewToBack:self.mapView];
    
    self.laundryTableView.alpha = 0.1;
    self.laundryTableView.hidden = true;
    
    self.currentCityLabel.backgroundColor = [UIColor whiteColor];
    self.currentCityLabel.alpha = 0.6;
    self.currentCityLabel.layer.cornerRadius = 15.0;
    self.currentCityLabel.clipsToBounds = true;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.userLocation = locations.firstObject;
        [self.activityIndicator setHidden:false];
        [self.activityIndicator startAnimating];
        [self.googleAPIController fetchGooglePlacesFromLocation:self.userLocation];
        [self.mapView setCenterCoordinate:self.userLocation.coordinate zoomLevel:11 animated:true];
        [self.mapView setShowsUserLocation:true];
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:self.userLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            self.cityString = placemarks.firstObject.locality;
            if (!self.cityString) {
                self.cityString = @"No City Nearby";
                self.laundryCityLabel.text = self.cityString;
                self.currentCityLabel.text = self.cityString;
            } else {
                self.currentCityLabel.text = self.cityString;
                self.laundryCityLabel.text = [NSString stringWithFormat:@"Laundromats in %@",self.cityString];
            }
        }];
    });
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - MapBox Methods

-(BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id<MGLAnnotation>)annotation {
    return true;
}


-(UIView *)mapView:(MGLMapView *)mapView leftCalloutAccessoryViewForAnnotation:(id<MGLAnnotation>)annotation {
    UIImageView * imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"laundryImage"]];
    imageView.frame = CGRectMake(0, 0, 50, 50);
    return imageView;
}

#pragma mark - Segmented Control

-(void)segmentedControlValueChanged {
    CGFloat mapViewAlpha = self.mapView.alpha;
    CGFloat tableViewAlpha = self.laundryTableView.alpha;
    self.laundryTableView.hidden = !self.laundryTableView.hidden;
    self.mapView.hidden = !self.mapView.hidden;
    
    [UIView animateWithDuration:0.35 animations:^{
        self.mapView.alpha = tableViewAlpha;
        self.laundryTableView.alpha = mapViewAlpha;
    }];
}

- (IBAction)segmentedControlTapped:(UISegmentedControl *)sender {
    [self segmentedControlValueChanged];
}

#pragma mark - Search Button Tapped

- (IBAction)searchButtonTapped:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Change City?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter City";
    }];
    
    UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"Change City" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.cityString = alertController.textFields.firstObject.text;
        
        [self.activityIndicator setHidden:false];
        [self.activityIndicator startAnimating];
        
        [self.googleAPIController fetchGooglePlacesInCity:self.cityString];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okayAction];
    [alertController.view setNeedsLayout];
    
    [self presentViewController:alertController animated:true completion:nil];
}

#pragma mark - Tableview Delegate Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.laundryArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"LaundryCell"];
    
    LaundryBusiness * business = self.laundryArray[indexPath.row];
    cell.textLabel.text = business.name;
    cell.detailTextLabel.text = business.vicinity;
    cell.imageView.image = [UIImage imageNamed:@"laundryImage"];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LaundryBusiness *business = [self.laundryArray objectAtIndex:indexPath.row];
    [self.mapView setCenterCoordinate:business.location.coordinate zoomLevel:13 animated:true];
    [self.mapListSegmentedControl setSelectedSegmentIndex:0];
    [self segmentedControlValueChanged];
}

#pragma mark - GooglePlacesController Delegate Methods

-(void)finishedFetchingLaundromats:(NSArray *)laundryLocations {
    self.laundryArray = laundryLocations;
    [self.laundryTableView reloadData];
    [self.mapView removeAnnotations:[self.mapView annotations]];
    
    [self.activityIndicator setHidden:true];
    [self.activityIndicator stopAnimating];
    
    for (LaundryBusiness *laundry in laundryLocations) {
        MGLPointAnnotation *annotation = [[MGLPointAnnotation alloc] init];
        annotation.coordinate = laundry.location.coordinate;
        annotation.title = laundry.name;
        annotation.subtitle = laundry.vicinity;
        [self.mapView addAnnotation:annotation];
    }
}

-(void)errorReverseGeocodingCityName:(NSString *)invalidName {
    [self.activityIndicator setHidden:true];
    [self.activityIndicator stopAnimating];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No such city!" message:[NSString stringWithFormat:@"%@ is not a valid city name.",invalidName] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okay];
    [alert.view setNeedsLayout];
    [self presentViewController:alert animated:true completion:nil];
}

-(void)finishedGettingLocationFromCity:(CLLocation *)cityLocation name:(NSString *)cityName{
    [self.mapView setCenterCoordinate:cityLocation.coordinate zoomLevel:11 animated:true];
    self.currentCityLabel.text = cityName;
    self.laundryCityLabel.text = [NSString stringWithFormat:@"Laundromats in %@",cityName];
    
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:true];
}

@end
