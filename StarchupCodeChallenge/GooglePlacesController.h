//
//  GooglePlacesController.h
//  StarchupCodeChallenge
//
//  Created by Jonathan Jones on 6/2/16.
//  Copyright © 2016 JJones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol FetchPlacesDelegate <NSObject>

-(void)finishedFetchingLaundromats:(NSArray *)laundryLocations;
-(void)finishedGettingLocationFromCity:(CLLocation *)cityLocation name:(NSString*)cityName;
-(void)errorReverseGeocodingCityName:(NSString *)invalidName;

@end

@interface GooglePlacesController : NSObject

@property id <FetchPlacesDelegate> delegate;

@property NSMutableData *locationData;
@property NSMutableArray *resultsArray;
@property NSString * googlePageToken;

-(void)fetchGooglePlacesInCity:(NSString *)city;
-(void)fetchGooglePlacesFromLocation:(CLLocation *)location;

@end
