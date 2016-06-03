//
//  GooglePlacesController.m
//  StarchupCodeChallenge
//
//  Created by Jonathan Jones on 6/2/16.
//  Copyright © 2016 JJones. All rights reserved.
//

#import "GooglePlacesController.h"
#import "LaundryBusiness.h"

#import <CoreLocation/CoreLocation.h>


@implementation GooglePlacesController

//Uses CLGeocoder to convert a city name string into a CLPlacemark to get coordinate information from the city.
-(void)fetchGooglePlacesInCity:(NSString *)city  {
    self.resultsArray = [NSMutableArray new];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:city completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error - %@",error.description);
            [self.delegate errorReverseGeocodingCityName:city];
        } else {
            CLPlacemark *placeMark = placemarks.firstObject;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate finishedGettingLocationFromCity:placeMark.location name:city];
                [self fetchGooglePlacesFromLocation:placeMark.location];
            });
        }
        
    }];
    
}

//Forms url string to use in a get request to the Google Places API
-(void)fetchGooglePlacesFromLocation:(CLLocation *)location {
    self.resultsArray = [NSMutableArray new];
    double latitude = location.coordinate.latitude;
    double longitude = location.coordinate.longitude;
    int radius  = 5000;
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&radius=%d&type=laundry&key=AIzaSyCz9rKIcxWitarLMCS0Lje2EcSe9ev67ys",latitude,longitude,radius];
    [self googleRestAPICall:urlString];
}

//Retrieves data results from the Google Places API
-(void) googleRestAPICall:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    [self performSelectorOnMainThread:@selector(fetchingLocations:) withObject:data waitUntilDone:true];
}

//Since there are only twenty results per 'page' when making a request from the Google Places API, check to see if there is a 'next page token' included in the data from google. If there is, then loop back and make another data request using that token while storing the current page of results in a mutable array. Another quirk of the Google Places API is that there is sometimes a short delay between being assigned a pagetoken and it being accepted by the server - to account for this, if an 'invalid request' response is received from the data request, then the request is performed again with the same token.
-(void)fetchingLocations:(NSData *)data {
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:data
                          options:kNilOptions error:&error];
    
    if (!error) {
        NSArray *pageResults = json[@"results"];
        
        if (json[@"next_page_token"] || [json[@"status"] isEqualToString:@"INVALID_REQUEST"]) {
            if (json[@"next_page_token"]) {
                self.googlePageToken = json[@"next_page_token"];
            }
            [self.resultsArray addObjectsFromArray:pageResults];
            NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=%@&key=AIzaSyCz9rKIcxWitarLMCS0Lje2EcSe9ev67ys",self.googlePageToken];
            [self performSelector:@selector(googleRestAPICall:) withObject:urlString afterDelay:0.5];
        } else {
            [self.resultsArray addObjectsFromArray:pageResults];
            [self locationsFinishedFetching:self.resultsArray];
        }
    } else {
        NSLog(@"Error - %@", error.description);
    }
}

//Locations have finished fetching without error, so now we can go through the mutable array and format the results that we would like to include in the map and tableview.
-(void)locationsFinishedFetching: (NSMutableArray*)results {
    NSArray *laundromats = [[NSArray alloc] init];
    for (NSDictionary* dictionary in results) {
        
        NSDictionary * coordinates = dictionary[@"geometry"][@"location"];
        NSNumber* latitude = coordinates[@"lat"];
        NSNumber* longitude = coordinates[@"lng"];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
        
        LaundryBusiness * laundry = [[LaundryBusiness alloc] init];
        if (dictionary[@"name"]) {
            laundry.name = dictionary[@"name"];
        } else {
            laundry.name = @"No Name";
        }
        if (dictionary[@"vicinity"]) {
            laundry.vicinity = dictionary[@"vicinity"];
        } else {
            laundry.vicinity = @"No Address Information";
        }
        if (dictionary[@"icon"]) {
            laundry.icon = dictionary[@"icon"];
        }
        laundry.location = location;
        
        laundromats = [laundromats arrayByAddingObject:laundry];
    }
    
    [self.delegate finishedFetchingLaundromats:laundromats];
}

@end
