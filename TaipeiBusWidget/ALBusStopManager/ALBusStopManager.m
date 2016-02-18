//
//  ALBusStopManager.m
//  DemoTaipeiBusWidget
//
//  Created by AlanYen on 2016/2/18.
//  Copyright © 2016年 17Life. All rights reserved.
//

#import "ALBusStopManager.h"
#import "TFHpple.h"

@interface ALBusStopManager ()

@property (strong, nonatomic) dispatch_group_t group;

@end

@implementation ALBusStopManager

+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken;
    static ALBusStopManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[ALBusStopManager alloc] init];
        manager.group = dispatch_group_create();
    });
    return manager;
}

- (void)getData {
    
    NSURLSession *session = [NSURLSession sharedSession];
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks,
                                             NSArray *uploadTasks,
                                             NSArray *downloadTasks) {
        
        if (self.getDataWillStartBlock) {
            self.getDataWillStartBlock();
        }
        
        for (NSURLSessionTask *task in dataTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in uploadTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in downloadTasks) {
            [task cancel];
        }
        
        if (self.getDataStartBlock) {
            self.getDataStartBlock();
        }
        
        [self.stops removeAllObjects];
        self.stops = [NSMutableArray new];
        
        for (NSString *budId in self.busIds) {
            [self downloadData:budId];
        }
        
        dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
            
            NSLog(@"dispatch_group_notify");
            if (self.getDataFinishBlock) {
                self.getDataFinishBlock();
            }
        });
    }];
}

- (void)downloadData:(NSString *)busId {
    
    dispatch_group_enter(self.group);
    
    // NSURLSessionDataTask
    NSString *urlString = [NSString stringWithFormat:@"http://pda.5284.com.tw/MQS/businfo2.jsp?routeId=%@", busId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         if (!error) {
             //NSString *html = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
             //NSLog(@"Response data = %@", html);
             [self parseHTML:data busId:busId];
         }
         
         dispatch_group_leave(self.group);
     }];
    
    // resume
    [dataTask resume];
}

- (void)parseHTML:(NSData *)data busId:(NSString *)busId {
    
    TFHpple *parser = [[TFHpple alloc] initWithHTMLData:data];
    [self parseGoStops:parser busId:busId];
}

- (void)parseGoStops:(TFHpple *)parser busId:(NSString *)busId {
    
    NSMutableArray *tempStops = [NSMutableArray new];
    
    NSArray *stops =
    [self parseStopElement:parser
                     busId:busId
                goStopName:self.goStopName
              backStopName:self.backStopName
                XPathQuery:@"//tr[@class='ttego1']"
                 baseIndex:0
                 direction:ALStopDirectionTypeGo];
    [tempStops addObjectsFromArray:stops];
    
    stops =
    [self parseStopElement:parser
                     busId:busId
                goStopName:self.goStopName
              backStopName:self.backStopName
                XPathQuery:@"//tr[@class='ttego2']"
                 baseIndex:1
                 direction:ALStopDirectionTypeGo];
    [tempStops addObjectsFromArray:stops];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
    [tempStops sortUsingDescriptors:@[sort]];
    
    ALStopInfo *stopInfo = [tempStops firstObject];
    if ([stopInfo.name rangeOfString:self.goStopName].location != NSNotFound) {
        NSLog(@"目標是去程資料");
        for (ALStopInfo *info in tempStops) {
            if ([info.name rangeOfString:self.goStopName].location != NSNotFound) {
                [self.stops addObject:info];
            }
        }
    }
    else {
        NSLog(@"目標是回程資料");
        [self parseBackStops:parser busId:busId];
    }
}

- (void)parseBackStops:(TFHpple *)parser busId:(NSString *)busId {
    
    NSArray *stops =
    [self parseStopElement:parser
                     busId:busId
                goStopName:self.goStopName
              backStopName:@"xxx"//self.backStopName
                XPathQuery:@"//tr[@class='tteback1']"
                 baseIndex:0
                 direction:ALStopDirectionTypeBack];
    [self.stops addObjectsFromArray:stops];
    
    stops =
    [self parseStopElement:parser
                     busId:busId
                goStopName:self.goStopName
              backStopName:@"xxx"//self.backStopName
                XPathQuery:@"//tr[@class='tteback2']"
                 baseIndex:1
                 direction:ALStopDirectionTypeBack];
    [self.stops addObjectsFromArray:stops];
}

- (NSMutableArray *)parseStopElement:(TFHpple *)parser
                               busId:(NSString *)busId
                          goStopName:(NSString *)goStopName
                        backStopName:(NSString *)backStopName
                          XPathQuery:(NSString *)path
                           baseIndex:(NSInteger)baseIndex
                           direction:(ALStopDirectionType)directionType {
    
    NSMutableArray *stops = [NSMutableArray new];
    NSArray *elements = [parser searchWithXPathQuery:path];
    for (NSInteger i = 0; i < elements.count; i++) {
        TFHppleElement *element = [elements objectAtIndex:i];
        NSArray *tds = [element childrenWithTagName:@"td"];
        if (tds.count == 2) {
            TFHppleElement *a = [[tds firstObject] firstChildWithTagName:@"a"];
            if (a) {
                if ([[a text] rangeOfString:goStopName].location != NSNotFound ||
                    [[a text] rangeOfString:backStopName].location != NSNotFound) {
                    NSLog(@"%@: %@ (%@)", busId, [a text], [[tds lastObject] text]);
                    ALStopInfo *stopInfo = [[ALStopInfo alloc] init];
                    stopInfo.busId = busId;
                    stopInfo.name = [a text];
                    stopInfo.status = [[tds lastObject] text];
                    stopInfo.direction = directionType;
                    stopInfo.index = baseIndex + (i * 2);
                    [stops addObject:stopInfo];
                }
            }
        }
    }
    return stops;
}

@end
