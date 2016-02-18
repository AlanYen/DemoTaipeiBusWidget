//
//  ALBusStopManager.h
//  DemoTaipeiBusWidget
//
//  Created by AlanYen on 2016/2/18.
//  Copyright © 2016年 17Life. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALStopInfo.h"

typedef void (^ALBusStopGetDataWillStartBlock)();
typedef void (^ALBusStopGetDataStartBlock)();
typedef void (^ALBusStopGetDataFinishBlock)();
typedef void (^ALBusStopGetDataFailBlock)();

@interface ALBusStopManager : NSObject

@property (copy, nonatomic) ALBusStopGetDataWillStartBlock getDataWillStartBlock;
@property (copy, nonatomic) ALBusStopGetDataStartBlock getDataStartBlock;
@property (copy, nonatomic) ALBusStopGetDataFinishBlock getDataFinishBlock;
@property (copy, nonatomic) ALBusStopGetDataFailBlock getDataFailBlock;

@property (strong, nonatomic) NSString *goStopName;
@property (strong, nonatomic) NSString *backStopName;
@property (strong, nonatomic) NSArray *busIds;
@property (strong, nonatomic) NSMutableArray *stops;

+ (instancetype)sharedManager;
- (void)getData;

@end
