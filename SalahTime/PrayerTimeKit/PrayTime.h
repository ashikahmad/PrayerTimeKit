//--------------------- Copyright Block ----------------------
/* 

PrayTime.h: Prayer Times Calculator (ver 1.2)
Copyright (C) 2007-2010 PrayTimes.org

Objective C Code By: Hussain Ali Khan
Original JS Code By: Hamid Zarrabi-Zadeh

License: GNU LGPL v3.0

TERMS OF USE:
	Permission is granted to use this code, with or 
	without modification, in any website or application 
	provided that credit is given to the original work 
	with a link back to PrayTimes.org.

This program is distributed in the hope that it will 
be useful, but WITHOUT ANY WARRANTY. 

PLEASE DO NOT REMOVE THIS COPYRIGHT BLOCK.

*/

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PTKCalculationMethod) {
    PTKCalculationMethodJafari, // Ithna Ashari
    PTKCalculationMethodKarachi, // University of Islamic Sciences, Karachi
    PTKCalculationMethodISNA, // Islamic Society of North America (ISNA)
    PTKCalculationMethodMWL, // Muslim World League (MWL)
    PTKCalculationMethodMakkah, // Umm al-Qura, Makkah
    PTKCalculationMethodEgypt, // Egyptian General Authority of Survey
    PTKCalculationMethodTehran, // Institute of Geophysics, University of Tehran
    PTKCalculationMethodCustom // Custom Setting
};

typedef NS_ENUM(NSInteger, PTKJuristicMethod) {
    PTKJuristicMethodShafii, // Shafii (standard)
    PTKJuristicMethodHanafi // Hanafi
};

typedef NS_ENUM(NSInteger, PTKHigherLatitudes) {
    PTKHigherLatitudesNone, // No adjustment
    PTKHigherLatitudesMidNight, // middle of night
    PTKHigherLatitudesOneSeventh, // 1/7th of night
    PTKHigherLatitudesAngleBased // angle/60th of night
};

typedef NS_ENUM (NSInteger, PTKTimeFormat) {
    PTKTimeFormatTime24, // 24-hour format
    PTKTimeFormatTime12WithSuffix, // 12-hour format with suffix
    PTKTimeFormatTime12NoSuffix, // 12-hour format with no suffix
    PTKTimeFormatFloat // floating point number
};

@interface PrayTime : NSObject {
	
//	NSMutableArray *timeNames;
	
//	NSString *InvalidTime;
	
	
	
//	NSInteger numIterations;
	
	
	
//	NSMutableDictionary *methodParams;
	
	
//	NSMutableArray *prayerTimesCurrent;
//	NSMutableArray *offsets;
}

// Time Names
@property (readonly) NSArray *timeNames;
// The string used for invalid times
@property (readonly) NSString *InvalidTime;

//--------------------- Technical Settings --------------------
// number of iterations needed to compute times
@property (assign) NSInteger numIterations;

//------------------- Calc Method Parameters --------------------
/*  this.methodParams[methodNum] = new Array(fa, ms, mv, is, iv);
 
 fa : fajr angle
 ms : maghrib selector (0 = angle; 1 = minutes after sunset)
 mv : maghrib parameter value (in angle or minutes)
 is : isha selector (0 = angle; 1 = minutes after maghrib)
 iv : isha parameter value (in angle or minutes)
 */
@property (strong, readonly) NSMutableDictionary *methodParams;

@property (strong, nonatomic) NSMutableArray *prayerTimesCurrent;
@property (strong, nonatomic) NSMutableArray *offsets;

@property (assign, nonatomic) PTKCalculationMethod calcMethod;
@property (assign, nonatomic) PTKJuristicMethod    asrJuristic;
@property (assign, nonatomic) double               dhuhrMinutes;
@property (assign, nonatomic) PTKHigherLatitudes   adjustHighLats;
@property (assign, nonatomic) PTKTimeFormat        timeFormat;
@property (assign, nonatomic) double lat;
@property (assign, nonatomic) double lng;
@property (assign, nonatomic) double timeZone;

//---------------------- Trigonometric Functions -----------------------
-(double) radiansToDegrees:(double)alpha;
-(double) DegreesToRadians:(double)alpha;
-(double) fixangle: (double)a;
-(double) fixhour: (double)a;
-(double) dsin: (double) d;
-(double) dcos: (double) d;
-(double) dtan: (double) d;
-(double) darcsin: (double) x;
-(double) darccos: (double) x;
-(double) darctan: (double) x;
-(double) darccot: (double) x;
-(double) darctan2: (double)y andX: (double) x;

//---------------------- Time-Zone Functions -----------------------
-(double)getTimeZone;
-(double)getBaseTimeZone;
-(double)detectDaylightSaving;

//---------------------- Julian Date Functions -----------------------
-(double) julianDate: (int)year andMonth:(int)month andDay:(int)day;
-(double)calcJD: (int)year andMonth:(int)month andDay:(int)day;

//---------------------- Calculation Functions -----------------------
-(NSMutableArray*)sunPosition: (double) jd;
-(double)equationOfTime: (double)jd;
-(double)sunDeclination: (double)jd;
-(double)computeMidDay: (double) t;
-(double)computeTime: (double)G andTime: (double)t;
-(double)computeAsr: (double)step andTime:(double)t;

//---------------------- Misc Functions -----------------------
-(double)timeDiff:(double)time1 andTime2:(double) time2;

//-------------------- Interface Functions --------------------
-(NSMutableArray*)getDatePrayerTimes:(int)year andMonth:(int)month andDay:(int)day andLatitude:(double)latitude andLongitude:(double)longitude andtimeZone:(double)tZone;
-(NSMutableArray*)getPrayerTimes: (NSDateComponents*)date andLatitude:(double)latitude andLongitude:(double)longitude andtimeZone:(double)tZone;
//-(void)setCalcMethod: (int)methodID;
//-(void)setAsrMethod: (int)methodID;
-(void)setCustomParams: (NSArray*)params;
-(void)setFajrAngle:(double)angle;
-(void)setMaghribAngle:(double)angle;
-(void)setIshaAngle:(double)angle;
//-(void)setDhuhrMinutes:(double)minutes;
-(void)setMaghribMinutes:(double)minutes;
-(void)setIshaMinutes:(double)minutes;
//-(void)setHighLatsMethod:(int)methodID;
//-(void)setTimeFormat: (int)tFormat;
-(NSString*)floatToTime24:(double)time;
-(NSString*)floatToTime12:(double)time andnoSuffix:(BOOL)noSuffix;
-(NSString*)floatToTime12NS:(double)time;

//---------------------- Compute Prayer Times -----------------------
-(NSMutableArray*)computeTimes:(NSMutableArray*)times;
-(NSMutableArray*)computeDayTimes;
-(NSMutableArray*)adjustTimes:(NSMutableArray*)times;
-(NSMutableArray*)adjustTimesFormat:(NSMutableArray*)times;
-(NSMutableArray*)adjustHighLatTimes:(NSMutableArray*)times;
-(double)nightPortion:(double)angle;
-(NSMutableArray*)dayPortion:(NSMutableArray*)times;
-(void)tune:(NSMutableDictionary*)offsets;
-(NSMutableArray*)tuneTimes:(NSMutableArray*)times;

@end
