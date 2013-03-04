//
//  MyViewController.m
//  GoogleMapsCalloutViewDemo
//
//  Created by Ryan Maxwell on 15/01/13.
//  Copyright (c) 2013 Ryan Maxwell. All rights reserved.
//
//  Modified by Jackie Lee on 3/3/13.
//  Launch Hackathon
//

#import "MyViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "SMCalloutView/SMCalloutView.h"

static const CGFloat CalloutYOffset = 50.0f;

/* SF */
static const CLLocationDegrees DefaultLatitude = 37.76643;
static const CLLocationDegrees DefaultLongitude = -122.393822;
static const CGFloat DefaultZoom = 17.5f;

@interface MyViewController () <GMSMapViewDelegate>

@property (nonatomic, strong) NSMutableData *responseData; //json sample data
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) SMCalloutView *calloutView;
@property (strong, nonatomic) UIView *emptyCalloutView;

//FB
@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;

- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error;

@end


@implementation MyViewController

@synthesize labelFirstName = _labelFirstName;
@synthesize loggedInUser = _loggedInUser;
@synthesize profilePic = _profilePic;

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    
    NSString * loc = [NSString stringWithFormat:@"lon:%.6f, lat:%.6f",newLocation.coordinate.longitude, newLocation.coordinate.latitude];
    NSLog(loc);
    
    [self.mapView animateToLocation:newLocation.coordinate];
    
    [locationManager stopUpdatingLocation]; // only update once
    
    // Create a reference to a Firebase location
    Firebase * f1 = [[Firebase alloc] initWithUrl:@"https://vikrum.firebaseio.com/"];
    
    // Write data to Firebase
    /*
    if (sync_data!=NULL) {
        [f1 set:[NSString stringWithFormat:@"%@-%@",sync_data,@"ipadx"]];
    }else{
        [f1 set:[NSString stringWithFormat:@"%@",@"0-"]];
    }*/
    
    [f1 set:[NSString stringWithFormat:@"{location:{%@},uid:%@}",loc,self.profilePic.profileID]];
    
    // Read data and react to changes
    [f1 on:FEventTypeValue doCallback:^(FDataSnapshot *snap) {
        //NSLog(@"%@ %@", [snap val], [snap name]);
        NSLog(@"Received data: %@", [snap val]);
        sync_data = [snap val];
    }];
    
    GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
    options.position = newLocation.coordinate;
    options.title = @"Me";
    //options.icon = [UIImage imageNamed:@"me_pin"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",self.profilePic.profileID]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *img = [[UIImage alloc] initWithData:data];
    //CGSize size = img.size;
    options.icon = img;
    //options.userData = marker;
    
    options.infoWindowAnchor = CGPointMake(0.5, 0.25);
    options.groundAnchor = CGPointMake(0.5, 1.0);
    
    [self.mapView addMarkerWithOptions:options];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse");
    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError");
    //NSLog([NSString stringWithFormat:@"Connection failed: %@", [error description]]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //NSLog(@"connectionDidFinishLoading");
    NSLog(@"Succeeded! Received %d bytes of data",[self.responseData length]);
    
    // convert to JSON
    NSError *myError = nil;
    NSDictionary *res = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&myError];
    
    markers = res;
    
    /*
    for(id key in res[@"checkins"]) {
        //id value = [res objectForKey:key];
        NSString *keyAsString = (NSString *)key;
        NSLog(@"key: %@", keyAsString);
    }*/
    
    /*
    // show all values
    for(id key in res) {
        
        id value = [res objectForKey:key];
        
        NSString *keyAsString = (NSString *)key;
        NSString *valueAsString = (NSString *)value;
        
        NSLog(@"key: %@", keyAsString);
        NSLog(@"value: %@", valueAsString);
    }
    
    
    // extract specific value...
    NSArray *results = [res objectForKey:@"results"];
    
    for (NSDictionary *result in results) {
        NSString *icon = [result objectForKey:@"icon"];
        NSLog(@"icon: %@", icon);
    }
    */
    
    [self addMarkersToMap];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    //swich_img = FALSE;
    
    // load json
    self.responseData = [NSMutableData data];
    //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://raw.github.com/chawei/treasure_map/master/web/js/sample.json"]];
    //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://steampunk.firebaseio.com/users.json"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://dl.dropbox.com/u/14359170/map-users.json"]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    self.calloutView = [[SMCalloutView alloc] init];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [button addTarget:self
               action:@selector(calloutAccessoryButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];
    self.calloutView.rightAccessoryView = button;
    
	GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:DefaultLatitude
                                                                    longitude:DefaultLongitude
                                                                         zoom:DefaultZoom];
    
    //NSLog(@"%.0f,%.0f",self.view.bounds.size.width,self.view.bounds.size.height);
    //CGRectMake(0.0f, 100.0f, 648.0f, 1024.0f)
    self.mapView = [GMSMapView mapWithFrame:CGRectMake(0.0f, 50.0f, 748.0f, 974.0f) camera:cameraPosition];
    self.mapView.delegate = self;
    
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];
    
    self.emptyCalloutView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // update location
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];

    [self.mapView animateToViewingAngle:30];
    
    [self.view addSubview:backgroundFadeView];
    
    //[self addMarkersToMap];
    
    // fb
    
    // Create Login View so that the app will be granted "status_update" permission.
    FBLoginView *loginview = [[FBLoginView alloc] init];
    
    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
    loginview.delegate = self;
    [self.view addSubview:vintageBGView];
    [self.view addSubview:loginview];
    [self.view addSubview:_profilePic];
    [self.view addSubview:_labelFirstName];
    [self.view addSubview:profileFrameView];
    
    [loginview sizeToFit];
    
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [self.mapView removeFromSuperview];
    self.mapView = nil;
    
    self.emptyCalloutView = nil;
    
    self.labelFirstName = nil;
    self.loggedInUser = nil;
    self.profilePic = nil;
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    // here we use helper properties of FBGraphUser to dot-through to first_name and
    // id properties of the json response from the server; alternatively we could use
    // NSDictionary methods such as objectForKey to get values from the my json object
    self.labelFirstName.text = [NSString stringWithFormat:@"%@", user.first_name];
    // setting the profileID property of the FBProfilePictureView instance
    // causes the control to fetch and display the profile picture for the user
    self.profilePic.profileID = user.id;
    self.loggedInUser = user;
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    
    self.profilePic.profileID = nil;
    self.labelFirstName.text = nil;
    self.loggedInUser = nil;
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // see https://developers.facebook.com/docs/reference/api/errors/ for general guidance on error handling for Facebook API
    // our policy here is to let the login view handle errors, but to log the results
    NSLog(@"FBLoginView encountered an error=%@", error);
}

// UIAlertView helper for post buttons
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error {
    
    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertTitle = @"Error";
        if (error.fberrorShouldNotifyUser ||
            error.fberrorCategory == FBErrorCategoryPermissions ||
            error.fberrorCategory == FBErrorCategoryAuthenticationReopenSession) {
            alertMsg = error.fberrorUserMessage;
        } else {
            alertMsg = @"Operation failed due to a connection problem, retry later.";
        }
    } else {
        NSDictionary *resultDict = (NSDictionary *)result;
        alertMsg = [NSString stringWithFormat:@"Successfully posted '%@'.\nPost ID: %@",
                    message, [resultDict valueForKey:@"id"]];
        alertTitle = @"Success";
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:alertMsg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}


- (void)viewWillAppear:(BOOL)animated {
    [self.mapView startRendering];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.mapView stopRendering];
}

- (void)addMarkersToMap {
    
    /*
    NSArray *markers = @[
        @{
            @"title": @"San Francisco",
            @"info": @"City",
            @"latitude": @37.76643,
            @"longitude": @-122.393822
        },
        @{
            @"title": @"Home",
            @"info": @"Home sweet home",
            @"latitude": @37.395864,
            @"longitude": @-121.944482
        },
        @{
            @"title": @"The Louvre",
            @"info": @"The principal museum and art gallery of France, in Paris.",
            @"latitude": @48.8609,
            @"longitude": @2.3363
        },
        @{
            @"title": @"Arc de Triomphe",
            @"info": @"A ceremonial arch standing at the top of the Champs Élysées in Paris.",
            @"latitude": @48.8738,
            @"longitude": @2.2950
        },
        @{
            @"title": @"Notre Dame",
            @"info": @"A Gothic cathedral in Paris, dedicated to the Virgin Mary, built between 1163 and 1250.",
            @"latitude": @48.8530,
            @"longitude": @2.3498
        }
    ];
    */
    
    
    UIImage * pinImage;
    NSString * uname;
    
    //pinImage = [UIImage imageNamed:@"profile_marker"];
    for (id key in markers){
        
        id user = [markers objectForKey:key];
        
        //NSLog([user[@"fb_info"] description]);
        /*
        if ([user[@"fb_info"][@"id"] isEqualToString:@"507483763"])
        {
            pinImage = [UIImage imageNamed:@"profile_marker"];
            
        }else{
            pinImage = [UIImage imageNamed:@"profile_marker2"];
        }
         */
        
        uname = user[@"fb_info"][@"name"];
        
        
        pinImage = [UIImage imageNamed:[NSString stringWithFormat:@"chest%d",(arc4random()%3)+1]];
        
        /*
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",user[@"fb_info"][@"id"]]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        pinImage = [[UIImage alloc] initWithData:data];
        */
        
        for (NSDictionary *marker in user[@"checkins"]) {
            
            if ([marker objectForKey:@"message"]){
                GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
                
                options.position = CLLocationCoordinate2DMake([marker[@"coordinates"][@"latitude"] doubleValue], [marker[@"coordinates"][@"longitude"] doubleValue]);
                
                //options.title = marker[@"place"][@"name"];
                options.title = marker[@"message"];
                
                options.icon = pinImage;
                NSMutableDictionary * dict_tmp = [[NSMutableDictionary alloc]init];
                [dict_tmp setObject:user[@"fb_info"][@"id"] forKey:@"uid"];
                
                [dict_tmp setObject:uname forKey:@"uname"];
                [dict_tmp setObject:marker[@"place"][@"name"] forKey:@"title"];
                //[dict_tmp setObject:marker[@"message"] forKey:@"title"];
                options.userData = dict_tmp;
                
                options.infoWindowAnchor = CGPointMake(0.5, 0.25);
                options.groundAnchor = CGPointMake(0.5, 1.0);
                
                [self.mapView addMarkerWithOptions:options];
            }
        }
         
        
    }
    
    
    /*
    UIImage * pinImage;
    NSString * uname;
    
    pinImage = [UIImage imageNamed:@"profile_marker"];
    for (NSDictionary * user in markers[@"checkins"]){
        
        
        if ([user[@"id"] isEqualToString:@"507483763"])
        {
            pinImage = [UIImage imageNamed:@"profile_marker"];
            uname = @"Jackie";
        }else{
            pinImage = [UIImage imageNamed:@"profile_marker2"];
            uname = @"David";
        }
        
        pinImage = [UIImage imageNamed:[NSString stringWithFormat:@"chest%d",(arc4random()%3)+1]];
        
        for (NSDictionary *marker in user[@"data"]) {
            GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
            
            options.position = CLLocationCoordinate2DMake([marker[@"coordinates"][@"latitude"] doubleValue], [marker[@"coordinates"][@"longitude"] doubleValue]);
            
            options.title = marker[@"place"][@"name"];
            
            options.icon = pinImage;
            NSMutableDictionary * dict_tmp = [[NSMutableDictionary alloc]init];
            [dict_tmp setObject:user[@"id"] forKey:@"uid"];
            
            [dict_tmp setObject:uname forKey:@"uname"];
            [dict_tmp setObject:marker[@"place"][@"name"] forKey:@"title"];
            options.userData = dict_tmp;
            
            options.infoWindowAnchor = CGPointMake(0.5, 0.25);
            options.groundAnchor = CGPointMake(0.5, 1.0);
            
            [self.mapView addMarkerWithOptions:options];
        }
    
    }
     */
    
    /*
    for (NSDictionary *marker in markers) {
        GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
        
        options.position = CLLocationCoordinate2DMake([marker[@"latitude"] doubleValue], [marker[@"longitude"] doubleValue]);
        options.title = marker[@"title"];
        options.icon = pinImage;
        options.userData = marker;
        
        options.infoWindowAnchor = CGPointMake(0.5, 0.25);
        options.groundAnchor = CGPointMake(0.5, 1.0);
        
        [self.mapView addMarkerWithOptions:options];
    }*/
}


- (void)calloutAccessoryButtonTapped:(id)sender {
    if (self.mapView.selectedMarker) {
        
        id<GMSMarker> marker = self.mapView.selectedMarker;
        NSDictionary *userData = marker.userData;
        
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:userData[@"title"]
                                                            message:[NSString stringWithFormat:@"%@ was here.",userData[@"uname"]]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        
        [alertView show];
         
        
        /*
        [[UIApplication sharedApplication] canOpenURL:
        [NSURL URLWithString:@"comgooglemaps://?center=40.765819,-73.975866&zoom=14&views=traffic"]];
         */
    }
}

#pragma mark - GMSMapViewDelegate

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(id<GMSMarker>)marker {
    CLLocationCoordinate2D anchor = marker.position;
    
    CGPoint point = [mapView.projection pointForCoordinate:anchor];
    
    self.calloutView.title = marker.title;
    
    self.calloutView.calloutOffset = CGPointMake(0, -CalloutYOffset);
    
    self.calloutView.hidden = NO;
    
    CGRect calloutRect = CGRectZero;
    calloutRect.origin = point;
    calloutRect.size = CGSizeZero;
    
    [self.calloutView presentCalloutFromRect:calloutRect
                                      inView:mapView
                           constrainedToView:mapView
                    permittedArrowDirections:SMCalloutArrowDirectionDown
                                    animated:YES];
    
    return self.emptyCalloutView;
}

- (void)mapView:(GMSMapView *)pMapView didChangeCameraPosition:(GMSCameraPosition *)position {
    /* move callout with map drag */
    if (pMapView.selectedMarker != nil && !self.calloutView.hidden) {
        CLLocationCoordinate2D anchor = [pMapView.selectedMarker position];
        
        CGPoint arrowPt = self.calloutView.backgroundView.arrowPoint;
        
        CGPoint pt = [pMapView.projection pointForCoordinate:anchor];
        pt.x -= arrowPt.x;
        pt.y -= arrowPt.y + CalloutYOffset;
        
        self.calloutView.frame = (CGRect) {.origin = pt, .size = self.calloutView.frame.size };
    } else {
        self.calloutView.hidden = YES;
    }
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    self.calloutView.hidden = YES;
}

@end
