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

@property (weak, nonatomic) IBOutlet UILabel *fajrDetails;
@property (weak, nonatomic) IBOutlet UILabel *sunriseDetails;
@property (weak, nonatomic) IBOutlet UILabel *dhuhrDetails;
@property (weak, nonatomic) IBOutlet UILabel *asrDetails;
@property (weak, nonatomic) IBOutlet UILabel *sunsetDetails;
@property (weak, nonatomic) IBOutlet UILabel *maghribDetails;
@property (weak, nonatomic) IBOutlet UILabel *ishaDetails;

@property (strong, nonatomic) PrayTime *prayTime;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /*
     calcMethod 	= 1
     asrMethod  	= 1
     latitude   	= 23.70
     longitude  	= 90.37
     timezone 	= +6
     */
    self.prayTime = [PrayTime new];
    self.prayTime.calcMethod = PTKCalculationMethodKarachi;
    self.prayTime.asrJuristic = PTKJuristicMethodHanafi;
    self.prayTime.timeFormat = PTKTimeFormatNSDate;
    [self refreshTimes:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - User Acions

- (IBAction)refreshTimes:(id)sender {
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [cal components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:[NSDate date]];
    NSArray *times = [self.prayTime getPrayerTimes:components
                                       andLatitude:23.70
                                      andLongitude:90.37
                                       andtimeZone:6];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"];
    
    NSArray *labels = @[self.fajrDetails, self.sunriseDetails, self.dhuhrDetails, self.asrDetails, self.sunsetDetails, self.maghribDetails, self.ishaDetails];
    for (int i=0; i<labels.count; i++) {
        ((UILabel *)labels[i]).text = [formatter stringFromDate:times[i]];
    }
    NSLog(@"%@", times);
}

#pragma mark - TableView Delegate/DataSource

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSArray *hideArr;
    if(!hideArr) hideArr = @[@1, @4];
    
    if ([hideArr containsObject:@(indexPath.row)]) {
        return 0;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

@end
