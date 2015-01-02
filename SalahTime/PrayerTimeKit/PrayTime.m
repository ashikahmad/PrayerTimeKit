//--------------------- Copyright Block ----------------------
/* 

PrayTime.m: Prayer Times Calculator (ver 1.2)
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


#import "PrayTime.h"

NSString * const PTKInvalidTimeString = @"-----";


@interface PrayTime ()

@property (strong, nonatomic) NSCalendar *gregorianCalendar;

@end

@implementation PrayTime {
    int calcYear;
    int calcMonth;
    int calcDay;
    double JDate;
    
}

-(instancetype) init {
	self = [super init];
	
	if(self){
        // Set default settings
        self.calcMethod     = PTKCalculationMethodJafari;
        self.asrJuristic    = PTKJuristicMethodShafii;
        self.dhuhrMinutes   = 0;
        self.adjustHighLats = PTKHigherLatitudesMidNight;
        self.timeFormat     = PTKTimeFormatTime24;
        
        self.gregorianCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
		
		// Time Names
        _timeNames = @[@"Fajr", @"Sunrise", @"Dhuhr", @"Asr", @"Sunset", @"Maghrib", @"Isha"];
		
		//--------------------- Technical Settings --------------------
		
		_numIterations = 1;		// number of iterations needed to compute times
		
		//------------------- Calc Method Parameters --------------------
		
		//Tuning offsets
        _offsets = [@[
                      @0, //fajr
                      @0, //sunrise
                      @0, //dhuhr
                      @0, //asr
                      @0, //sunset
                      @0, //maghrib
                      @0, //isha
                      ] mutableCopy];
		
		/*
         self.methodParams[methodNum] = @[fa, ms, mv, is, iv];
		 fa : fajr angle
		 ms : maghrib selector (0 = angle; 1 = minutes after sunset)
		 mv : maghrib parameter value (in angle or minutes)
		 is : isha selector (0 = angle; 1 = minutes after maghrib)
		 iv : isha parameter value (in angle or minutes)
		 */
        _methodParams = [@{
                           @(PTKCalculationMethodJafari)  : @[@16  , @0, @4  , @0, @14  ],
                           @(PTKCalculationMethodKarachi) : @[@18  , @1, @0  , @0, @18  ],
                           @(PTKCalculationMethodISNA)    : @[@15  , @1, @0  , @0, @15  ],
                           @(PTKCalculationMethodMWL)     : @[@18  , @1, @0  , @0, @17  ],
                           @(PTKCalculationMethodMakkah)  : @[@18.5, @1, @0  , @1, @90  ],
                           @(PTKCalculationMethodEgypt)   : @[@19.5, @1, @0  , @0, @17.5],
                           @(PTKCalculationMethodTehran)  : @[@17.7, @0, @4.5, @0, @14  ],
                           @(PTKCalculationMethodCustom)  : @[@18  , @1, @0  , @0, @17  ]
                           } mutableCopy];
	}
	return self;
}


//------------------------------------------------------
#pragma mark - Time-Zone Functions
//------------------------------------------------------

// compute local time-zone for a specific date
-(double)getTimeZone {
	NSTimeZone *timeZone = [NSTimeZone localTimeZone];
	double hoursDiff = [timeZone secondsFromGMT]/3600.0f;
	return hoursDiff;
}

// compute base time-zone of the system
-(double)getBaseTimeZone {
	
	NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
	double hoursDiff = [timeZone secondsFromGMT]/3600.0f;
	return hoursDiff;
	
}

// detect daylight saving in a given date
-(double)detectDaylightSaving {
	NSTimeZone *timeZone = [NSTimeZone localTimeZone];
	double hoursDiff = [timeZone daylightSavingTimeOffsetForDate:[NSDate date]];
	return hoursDiff;
}

//------------------------------------------------------
#pragma mark - Julian Date Functions
//------------------------------------------------------

// calculate julian date from a calendar date
-(double) julianDate: (int)year andMonth:(int)month andDay:(int)day {
	
	if (month <= 2) 
	{
		year -= 1;
		month += 12;
	}
	double A = floor(year/100.0);
	double B = 2 - A + floor(A/4.0);
	
	double JD = floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + B - 1524.5;
		
	return JD;
}


// convert a calendar date to julian date (second method)
-(double)calcJD: (int)year andMonth:(int)month andDay:(int)day {
	double J1970 = 2440588;
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setWeekday:day]; // Monday
	//[components setWeekdayOrdinal:1]; // The first day in the month
	[components setMonth:month]; // May
	[components setYear:year];
	NSDate *date1 = [self.gregorianCalendar dateFromComponents:components];
	
	double ms = [date1 timeIntervalSince1970];// # of milliseconds since midnight Jan 1, 1970
	double days = floor(ms/ (1000.0 * 60.0 * 60.0 * 24.0)); 
	return J1970 + days - 0.5;
}

//------------------------------------------------------
#pragma mark - Calculation Functions
//------------------------------------------------------


// References:
// http://www.ummah.net/astronomy/saltime  
// http://aa.usno.navy.mil/faq/docs/SunApprox.html


// compute declination angle of sun and equation of time
-(NSMutableArray*)sunPosition: (double) jd {
	
	double D = jd - 2451545;
	double g = [self fixangle: (357.529 + 0.98560028 * D)];
	double q = [self fixangle: (280.459 + 0.98564736 * D)];
	double L = [self fixangle: (q + (1.915 * [self dsin: g]) + (0.020 * [self dsin:(2 * g)]))];
	
	//double R = 1.00014 - 0.01671 * [self dcos:g] - 0.00014 * [self dcos: (2*g)];
	double e = 23.439 - (0.00000036 * D);
	double d = [self darcsin: ([self dsin: e] * [self dsin: L])];
	double RA = ([self darctan2: ([self dcos: e] * [self dsin: L]) andX: [self dcos:L]])/ 15.0;
	RA = [self fixhour:RA];
	
	double EqT = q/15.0 - RA;
	
	NSMutableArray *sPosition = [[NSMutableArray alloc] init];
	[sPosition addObject:@(d)];
	[sPosition addObject:@(EqT)];
	
	return sPosition;
}

// compute equation of time
-(double)equationOfTime: (double)jd {
	double eq = [[self sunPosition:jd][1] doubleValue];
	return eq;
}

// compute declination angle of sun
-(double)sunDeclination: (double)jd {
	double d = [[self sunPosition:jd][0] doubleValue];
	return d;
}

// compute mid-day (Dhuhr, Zawal) time
-(double)computeMidDay: (double) t {
	double T = [self equationOfTime:(JDate+ t)];
	double Z = [self fixhour: (12 - T)];
	return Z;
}

// compute time for a given angle G
-(double)computeTime: (double)G andTime: (double)t {
	
	double D = [self sunDeclination:(JDate+ t)];
	double Z = [self computeMidDay: t];
	double V = ([self darccos: (-[self dsin:G] - ([self dsin:D] * [self dsin:self.latitude]))/ ([self dcos:D] * [self dcos:self.latitude])]) / 15.0f;

	return Z+ (G>90 ? -V : V);
}

// compute the time of Asr
// Shafii: step=1, Hanafi: step=2
-(double)computeAsr: (double)step andTime:(double)t {
	double D = [self sunDeclination:(JDate+ t)];
	double G = -[self darccot : (step + [self dtan:ABS(self.latitude-D)])];
	return [self computeTime:G andTime:t];
}

//------------------------------------------------------
#pragma mark - Misc Functions
//------------------------------------------------------

// compute the difference between two times 
-(double)timeDiff:(double)time1 andTime2:(double) time2 {
	return [self fixhour: (time2- time1)];
}

//------------------------------------------------------
#pragma mark - Interface (Public) Functions
//------------------------------------------------------

// return prayer times for a given date
-(NSMutableArray*)getDatePrayerTimes:(int)year andMonth:(int)month andDay:(int)day andLatitude:(double)latitude andLongitude:(double)longitude andtimeZone:(double)tZone {
    self.latitude  = latitude;
    self.longitude = longitude;
	
    calcYear  = year;
    calcMonth = month;
    calcDay   = day;
    
	//timeZone = this.effectiveTimeZone(year, month, day, timeZone); 
	//timeZone = [self getTimeZone];
	self.timeZone = tZone;
	JDate = [self julianDate:year andMonth:month andDay:day];
	
	double lonDiff = longitude/(15.0 * 24.0);
	JDate = JDate - lonDiff;
	return [self computeDayTimes];
}

// return prayer times for a given date
-(NSMutableArray*)getPrayerTimes: (NSDateComponents*)date andLatitude:(double)latitude andLongitude:(double)longitude andtimeZone:(double)tZone {
	
    int year  = (int)[date year];
    int month = (int)[date month];
    int day   = (int)[date day];
	return [self getDatePrayerTimes:year andMonth:month andDay:day andLatitude:latitude andLongitude:longitude andtimeZone:tZone];
}

// set custom values for calculation parameters
-(void)setCustomParams: (NSArray*)params {
	int i;
	NSNumber *j;
	NSMutableArray *cust = [(NSArray *) self.methodParams[@(PTKCalculationMethodCustom)] mutableCopy];
	NSArray *cal = (NSArray *) self.methodParams[@((int)self.calcMethod)];
	for (i=0; i<5; i++)
	{
		j = (NSNumber *)params[i];
		if ([j isEqualToNumber: @(-1)])
			cust[i] = cal[i] ;
		else
			cust[i] = j;
	}
    self.methodParams[@(PTKCalculationMethodCustom)] = [cust copy];
	self.calcMethod = PTKCalculationMethodCustom;
}

// set the angle for calculating Fajr
-(void)setFajrAngle:(double)angle {
	NSArray *params = @[@(angle), @(-1.0), @(-1.0), @(-1.0), @(-1.0)];
	[self setCustomParams:params];
}

// set the angle for calculating Maghrib
-(void)setMaghribAngle:(double)angle {
	NSArray *params = @[@(-1.0), @(0.0), @(angle), @(-1.0), @(-1.0)];
	[self setCustomParams:params];
}

// set the angle for calculating Isha
-(void)setIshaAngle:(double)angle {
	NSArray *params = @[@(-1.0), @(-1.0), @(-1.0), @(0.0), @(angle)];
	[self setCustomParams:params];
}

// set the minutes after Sunset for calculating Maghrib
-(void)setMaghribMinutes:(double)minutes {
    NSArray *params = @[@(-1.0), @(1.0), @(minutes), @(-1.0), @(-1.0)];
	[self setCustomParams:params];
}

// set the minutes after Maghrib for calculating Isha
-(void)setIshaMinutes:(double)minutes {
    NSArray *params = @[@(-1.0), @(-1.0), @(-1.0), @(1.0), @(minutes)];
	[self setCustomParams:params];
}

// convert double hours to 24h format
-(NSString*)floatToTime24:(double)time {
	
	NSString *result = nil;
	
	if (isnan(time))
		return PTKInvalidTimeString;
	
	time = [self fixhour:(time + 0.5/ 60.0)];  // add 0.5 minutes to round
	int hours = floor(time); 
	double minutes = floor((time - hours) * 60.0);
	
	if((hours >=0 && hours<=9) && (minutes >=0 && minutes <=9)){
		result = [NSString stringWithFormat:@"0%d:0%.0f",hours, minutes];
	}
	else if((hours >=0 && hours<=9)){
		result = [NSString stringWithFormat:@"0%d:%.0f",hours, minutes];
	}
	else if((minutes >=0 && minutes <=9)){
		result = [NSString stringWithFormat:@"%d:0%.0f",hours, minutes];
	}
	else{
		result = [NSString stringWithFormat:@"%d:%.0f",hours, minutes];
	}
	return result;
}

// convert double hours to 12h format
-(NSString*)floatToTime12:(double)time andnoSuffix:(BOOL)noSuffix {
	
	if (isnan(time))
		return PTKInvalidTimeString;
	
	time =[self fixhour:(time+ 0.5/ 60)];  // add 0.5 minutes to round
	double hours = floor(time); 
	double minutes = floor((time- hours)* 60);
	NSString *suffix, *result=nil;
	if(hours >= 12) {
		suffix = @"pm";
	}
	else{
		suffix = @"am";
	}
	//hours = ((((hours+ 12) -1) % (12))+ 1);
	hours = (hours + 12) - 1;
	int hrs = (int)hours % 12;
	hrs += 1;
	if(noSuffix == NO){
		if((hrs >=0 && hrs<=9) && (minutes >=0 && minutes <=9)){
			result = [NSString stringWithFormat:@"0%d:0%.0f %@",hrs, minutes, suffix];
		}
		else if((hrs >=0 && hrs<=9)){
			result = [NSString stringWithFormat:@"0%d:%.0f %@",hrs, minutes, suffix];
		}
		else if((minutes >=0 && minutes <=9)){
			result = [NSString stringWithFormat:@"%d:0%.0f %@",hrs, minutes, suffix];
		}
		else{
			result = [NSString stringWithFormat:@"%d:%.0f %@",hrs, minutes, suffix];
		}
		
	}
	else{
		if((hrs >=0 && hrs<=9) && (minutes >=0 && minutes <=9)){
			result = [NSString stringWithFormat:@"0%d:0%.0f",hrs, minutes];
		}
		else if((hrs >=0 && hrs<=9)){
			result = [NSString stringWithFormat:@"0%d:%.0f",hrs, minutes];
		}
		else if((minutes >=0 && minutes <=9)){
			result = [NSString stringWithFormat:@"%d:0%.0f",hrs, minutes];
		}
		else{
			result = [NSString stringWithFormat:@"%d:%.0f",hrs, minutes];
		}
	}
	return result;
	
}

// convert double hours to 12h format with no suffix
-(NSString*)floatToTime12NS:(double)time {
	return [self floatToTime12:time andnoSuffix:YES];
}

-(NSDate *) floatToNSDate:(double)time {
    if (isnan(time)) return nil;
    
    time = [self fixhour:(time + 0.5/ 60.0)];  // add 0.5 minutes to round
    int hours = floor(time);
    double minutes = floor((time - hours) * 60.0);
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = calcYear;
    components.month = calcMonth;
    components.day = calcDay;
    components.hour = hours;
    components.minute = minutes;
    return [self.gregorianCalendar dateFromComponents:components];
}

//------------------------------------------------------
#pragma mark - Compute Prayer Times
//------------------------------------------------------

// compute prayer times at given julian date
-(NSMutableArray*)computeTimes:(NSMutableArray*)times {
	
	NSMutableArray *t = [self dayPortion:times];
	
	id obj = self.methodParams[@((int)self.calcMethod)];
	double idk = [obj[0] doubleValue];
	double Fajr    = [self computeTime:(180 - idk) andTime: [t[0] doubleValue]];
	double Sunrise = [self computeTime:(180 - 0.833) andTime: [t[1] doubleValue]];
	double Dhuhr   = [self computeMidDay: [t[2] doubleValue]];
	double Asr     = [self computeAsr:(1 + self.asrJuristic) andTime: [t[3] doubleValue]];
	double Sunset  = [self computeTime:0.833 andTime: [t[4] doubleValue]];
	double Maghrib = [self computeTime:[self.methodParams[@((int)self.calcMethod)][2] doubleValue] andTime: [t[5] doubleValue]];
	double Isha    = [self computeTime:[self.methodParams[@((int)self.calcMethod)][4] doubleValue] andTime: [t[6] doubleValue]];
	
    NSMutableArray *Ctimes = [@[@(Fajr),
                                @(Sunrise),
                                @(Dhuhr),
                                @(Asr),
                                @(Sunset),
                                @(Maghrib),
                                @(Isha)] mutableCopy];
    
	//Tune times here
	//Ctimes = [self tuneTimes:Ctimes];
	
	return Ctimes;
}

// compute prayer times at given julian date
-(NSMutableArray*)computeDayTimes {
    static NSArray *defaultTimes;
    if(!defaultTimes) defaultTimes = @[@5.0, @6.0, @12.0, @13.0, @18.0, @18.0, @18.0];
    
	//int i = 0;
	NSMutableArray *t1, *t2, *t3;
    //default times
	NSMutableArray *times = [defaultTimes mutableCopy];
    
	for (int i=1; i<= self.numIterations; i++)
		t1 = [self computeTimes:times];
	
	t2 = [self adjustTimes:t1];
	
	t2 = [self tuneTimes:t2];
	
	//Set prayerTimesCurrent here!!
	self.prayerTimesCurrent = [[NSMutableArray alloc] initWithArray:t2];
	
	t3 = [self adjustTimesFormat:t2];
	
	return t3;
}

//Tune timings for adjustments
//Set time offsets
-(void)tune:(NSMutableDictionary*)offsetTimes{

	(self.offsets)[0] = offsetTimes[@"fajr"];
	(self.offsets)[1] = offsetTimes[@"sunrise"];
	(self.offsets)[2] = offsetTimes[@"dhuhr"];
	(self.offsets)[3] = offsetTimes[@"asr"];
	(self.offsets)[4] = offsetTimes[@"sunset"];
	(self.offsets)[5] = offsetTimes[@"maghrib"];
	(self.offsets)[6] = offsetTimes[@"isha"];
}

-(NSMutableArray*)tuneTimes:(NSMutableArray*)times{
	double off, time;
	for(int i=0; i<[times count]; i++){
		//if(i==5)
		//NSLog(@"Normal: %d - %@", i, [times objectAtIndex:i]);
		off = [(self.offsets)[i] doubleValue]/60.0;
		time = [times[i] doubleValue] + off;
		times[i] = @(time);
		//if(i==5)
		//NSLog(@"Modified: %d - %@", i, [times objectAtIndex:i]);
	}
	
	return times;
}

// range reduce hours to 0..23
-(double) fixhour: (double) a {
    a = a - 24.0 * floor(a / 24.0);
    a = a < 0 ? (a + 24) : a;
    return a;
}

// adjust times in a prayer time array
-(NSMutableArray*)adjustTimes:(NSMutableArray*)times {
	
	int i = 0;
	NSMutableArray *a; //test variable
	double time = 0, Dtime, Dtime1, Dtime2;
	
	for (i=0; i<7; i++) {
		time = ([times[i] doubleValue]) + (self.timeZone- self.longitude/ 15.0);
		
		times[i] = @(time);
		
	}
	
	Dtime = [times[2] doubleValue] + (self.dhuhrMinutes/ 60.0); //Dhuhr
		
	times[2] = @(Dtime);
	
	a = self.methodParams[@((int)self.calcMethod)];
	double val = [a[1] doubleValue];
	
	if (val == 1) { // Maghrib
		Dtime1 = [times[4] doubleValue]+ ([self.methodParams[@((int)self.calcMethod)][2] doubleValue]/60.0);
		times[5] = @(Dtime1);
	}
	
	if ([self.methodParams[@((int)self.calcMethod)][3] doubleValue]== 1) { // Isha
		Dtime2 = [times[5] doubleValue] + ([self.methodParams[@((int)self.calcMethod)][4] doubleValue]/60.0);
		times[6] = @(Dtime2);
	}
	
	if (self.adjustHighLats != PTKHigherLatitudesNone){
		times = [self adjustHighLatTimes:times];
	}
	return times;
}


// convert times array to given time format
-(NSMutableArray*)adjustTimesFormat:(NSMutableArray*)times {
	int i = 0;
	
	if (self.timeFormat == PTKTimeFormatFloat){
		return times;
	}
	for (i=0; i<7; i++) {
		if (self.timeFormat == PTKTimeFormatTime12WithSuffix){
			times[i] = [self floatToTime12:[times[i] doubleValue] andnoSuffix:NO];
		}
		else if (self.timeFormat == PTKTimeFormatTime12NoSuffix){
			times[i] = [self floatToTime12:[times[i] doubleValue] andnoSuffix:YES];
		}
		else if (self.timeFormat == PTKTimeFormatTime24){
			times[i] = [self floatToTime24:[times[i] doubleValue]];
        } else {
            // floatToNSDate can return nil, if time is invalid
            times[i] = [self floatToNSDate:[times[i] doubleValue]] ?: [NSNull null];
        }
	}
	return times;
}


// adjust Fajr, Isha and Maghrib for locations in higher latitudes
-(NSMutableArray*)adjustHighLatTimes:(NSMutableArray*)times {
	
	double time0 = [times[0] doubleValue];
	double time1 = [times[1] doubleValue];
	//double time2 = [[times objectAtIndex:2] doubleValue];
	//double time3 = [[times objectAtIndex:3] doubleValue];
	double time4 = [times[4] doubleValue];
	double time5 = [times[5] doubleValue];
	double time6 = [times[6] doubleValue];
	
	double nightTime = [self timeDiff:time4 andTime2:time1]; // sunset to sunrise
	
	// Adjust Fajr
	double obj0 =[self.methodParams[@((int)self.calcMethod)][0] doubleValue];
	double obj1 =[self.methodParams[@((int)self.calcMethod)][1] doubleValue];
	double obj2 =[self.methodParams[@((int)self.calcMethod)][2] doubleValue];
	double obj3 =[self.methodParams[@((int)self.calcMethod)][3] doubleValue];
	double obj4 =[self.methodParams[@((int)self.calcMethod)][4] doubleValue];
	
	double FajrDiff = [self nightPortion:obj0] * nightTime;
	
	if ((isnan(time0)) || ([self timeDiff:time0 andTime2:time1] > FajrDiff)) 
		times[0] = @(time1 - FajrDiff);
	
	// Adjust Isha
	double IshaAngle = (obj3 == 0) ? obj4: 18;
	double IshaDiff = [self nightPortion: IshaAngle] * nightTime;
	if (isnan(time6) ||[self timeDiff:time4 andTime2:time6] > IshaDiff) 
		times[6] = @(time4 + IshaDiff);
	
	
	// Adjust Maghrib
	double MaghribAngle = (obj1 == 0) ? obj2 : 4;
	double MaghribDiff = [self nightPortion: MaghribAngle] * nightTime;
	if (isnan(time5) || [self timeDiff:time4 andTime2:time5] > MaghribDiff) 
		times[5] = @(time4 + MaghribDiff);
	
	return times;
}


// the night portion used for adjusting times in higher latitudes
-(double)nightPortion:(double)angle {
	double calc = 0;
	
	if (self.adjustHighLats == PTKHigherLatitudesAngleBased)
		calc = (angle)/60.0f;
	else if (self.adjustHighLats == PTKHigherLatitudesMidNight)
		calc = 0.5f;
	else if (self.adjustHighLats == PTKHigherLatitudesOneSeventh)
		calc = 0.14286f;
	
	return calc;
}


// convert hours to day portions 
-(NSMutableArray*)dayPortion:(NSMutableArray*)times {
	int i = 0;
	double time = 0;
	for (i=0; i<7; i++){
		time = [times[i] doubleValue];
		time = time/24.0;
		
		times[i] = @(time);
		
	}
	return times;
}

//------------------------------------------------------
#pragma mark - Trigonometric Functions
//------------------------------------------------------

// range reduce angle in degrees.
-(double) fixangle: (double) a {
    a = a - (360 * (floor(a / 360.0)));
    a = a < 0 ? (a + 360) : a;
    return a;
}

// radian to degree
-(double) radiansToDegrees:(double)alpha {
    return ((alpha*180.0)/M_PI);
}

//deree to radian
-(double) DegreesToRadians:(double)alpha {
    
    return ((alpha*M_PI)/180.0);
}

// degree sin
-(double)dsin: (double) d {
    return (sin([self DegreesToRadians:d]));
}

// degree cos
-(double)dcos: (double) d {
    return (cos([self DegreesToRadians:d]));
}

// degree tan
-(double)dtan: (double) d {
    return (tan([self DegreesToRadians:d]));
}

// degree arcsin
-(double)darcsin: (double) x {
    double val = asin(x);
    return [self radiansToDegrees: val];
}

// degree arccos
-(double)darccos: (double) x {
    double val = acos(x);
    return [self radiansToDegrees: val];
}

// degree arctan
-(double)darctan: (double) x {
    double val = atan(x);
    return [self radiansToDegrees: val];
}

// degree arctan2
-(double)darctan2: (double)y andX: (double) x {
    double val = atan2(y, x);
    return [self radiansToDegrees: val];
}

// degree arccot
-(double)darccot: (double) x {
    double val = atan2(1.0, x);
    return [self radiansToDegrees: val];
}

@end