//
//  ViewController.m
//  SalahTime
//
//  Created by Ashik Ahmad on 12/19/14.
//  Copyright (c) 2014 WNeeds. All rights reserved.
//

#import "ViewController.h"
#import "PrayTime.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    PrayTime *pt = [PrayTime new];
    /*
     calcMethod 	= 1
     asrMethod  	= 1
     latitude   	= 23.70
     longitude  	= 90.37
     timezone 	= +6
     */
    [pt setCalcMethod:PTKCalculationMethodKarachi];
    [pt setAsrJuristic:PTKJuristicMethodHanafi];
    NSArray *times = [pt getDatePrayerTimes:2014
                                   andMonth:12
                                     andDay:19
                                andLatitude:23.70
                               andLongitude:90.37
                                andtimeZone:6];
    NSLog(@"%@", times);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
