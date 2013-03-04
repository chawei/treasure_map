//
//  MyViewController.h
//  GoogleMapsCalloutViewDemo
//
//  Created by Ryan Maxwell on 15/01/13.
//  Copyright (c) 2013 Ryan Maxwell. All rights reserved.
//
//  Modified by Jackie Lee on 3/3/13.
//  Launch Hackathon
//
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Firebase/Firebase.h>

@interface MyViewController : UIViewController<CLLocationManagerDelegate,FBLoginViewDelegate>{
    CLLocationManager *locationManager;
    IBOutlet UIImageView * backgroundFadeView;
    NSString * sync_data;
    NSDictionary * profile_me;
    NSDictionary * markers;
    NSDictionary * markers_other;
    bool swich_img;
    //float lat,lon;
}

@end
