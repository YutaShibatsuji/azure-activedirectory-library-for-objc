// Copyright © Microsoft Open Technologies, Inc.
//
// All Rights Reserved
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A
// PARTICULAR PURPOSE, MERCHANTABILITY OR NON-INFRINGEMENT.
//
// See the Apache License, Version 2.0 for the specific language
// governing permissions and limitations under the License.

#import <Foundation/Foundation.h>
#import "ADClientMetrics.h"
#import "ADHelpers.h"

@implementation ADClientMetrics

//header keys
const NSString* HeaderLastError = @"x-client-last-error";
const NSString* HeaderLastRequest = @"x-client-last-request";
const NSString* HeaderLastResponseTime = @"x-client-last-response-time";
const NSString* HeaderLastEndpoint = @"x-client-last-endpoint";

//values
@synthesize endpoint = _endpoint;
@synthesize responseTime = _responseTime;
@synthesize correlationId = _correlationId;
@synthesize startTime = _startTime;
@synthesize errorToReport = _errorToReport;
@synthesize isPending = _isPending;

+ (ADClientMetrics*) getInstance {
    /* Below is a standard objective C singleton pattern*/
    static ADClientMetrics* instance = nil;
    static dispatch_once_t onceToken = 0;
    @synchronized(self)
    {
        dispatch_once(&onceToken, ^{
            instance = [[ADClientMetrics alloc] init];
        });
    }
#if !__has_feature(objc_arc)
    if ( [instance retainCount] > 1 )
    {
        DebugLog( @"ADClientMetrics retainCount = %lu", (unsigned long)[instance retainCount] );
    }
    NSAssert( [instance retainCount] >= 1, @"Bad retain count on shared instance" );
#endif
    return instance;
}


#if !__has_feature(objc_arc)
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return UINT_MAX; //denotes an object that cannot be released
}
- (oneway void)release {
    // never release
}
- (id)autorelease {
    return self;
}
#endif





- (id)init {
    return self;
}

-(void) dealloc {
    SAFE_ARC_RELEASE(_endpoint);
    SAFE_ARC_RELEASE(_responseTime);
    SAFE_ARC_RELEASE(_correlationId);
    SAFE_ARC_RELEASE(_errorToReport);
    SAFE_ARC_RELEASE(_startTime);
//    SAFE_ARC_RELEASE(self);
    SAFE_ARC_SUPER_DEALLOC();
}

- (void) beginClientMetricsRecordForEndpoint: (NSString*) endPoint
                               correlationId: (NSString*) correlationId
                                requestHeader: (NSMutableDictionary*) requestHeader
{
    @synchronized(self)
    {
        if([ADHelpers isADFSInstance:endPoint]){
            return;
        }
        if(_isPending){
        [requestHeader setObject:_errorToReport forKey:HeaderLastError];
        [requestHeader setObject:_responseTime forKey:HeaderLastResponseTime];
        [requestHeader setObject:[ADHelpers getEndpointName:_endpoint] forKey:HeaderLastEndpoint];
        [requestHeader setObject:_correlationId forKey:HeaderLastRequest];
            _isPending = NO;
        }
        _endpoint = endPoint;
        _responseTime = @"";
        _correlationId = correlationId;
        _startTime = [NSDate new];
        _errorToReport = @"";
        SAFE_ARC_RETAIN(_endpoint);
        SAFE_ARC_RETAIN(_correlationId);
        SAFE_ARC_RETAIN(_errorToReport);
        SAFE_ARC_RETAIN(_startTime);
//        SAFE_ARC_RETAIN(self);
    }
}


-(void) endClientMetricsRecord: (NSString*) error{
    
    @synchronized(self)
    {
        if([ADHelpers isADFSInstance:_endpoint]){
            return;
        }
        if([NSString adIsStringNilOrBlank:error]){
                _errorToReport = @"";
        }else{
            _errorToReport = error;
        }
        _responseTime = [NSString stringWithFormat:@"%f", [_startTime timeIntervalSinceNow] * -1000.0];
        SAFE_ARC_RETAIN(_responseTime);
        _isPending = YES;
    }
}



@end