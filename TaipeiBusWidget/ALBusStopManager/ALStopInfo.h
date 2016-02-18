//
//  ALStopInfo.h
//  DemoTaipeiBusWidget
//
//  Created by AlanYen on 2016/2/17.
//  Copyright © 2016年 17Life. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ALStopDirectionType) {
    
    ALStopDirectionTypeGo = 0,
    ALStopDirectionTypeBack = 1,
};

@interface ALStopInfo : NSObject

@property (strong, nonatomic) NSString *busId;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *status;
@property (assign, nonatomic) NSInteger index;
@property (assign, nonatomic) ALStopDirectionType direction;

@end
