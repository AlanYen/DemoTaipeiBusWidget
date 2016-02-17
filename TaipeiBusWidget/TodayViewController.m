//
//  TodayViewController.m
//  TaipeiBusWidget
//
//  Created by AlanYen on 2016/2/17.
//  Copyright © 2016年 17Life. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "TFHpple.h"
#import "StopInfo.h"

#define kTargetGoStopName @"中正環河路口"//@"中正環河路口"
#define kTargetBackStopName @"忠孝敦化"//@"捷運忠孝敦化站"

@interface TodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;
@property (strong, nonatomic) NSMutableArray *goStops;
@property (strong, nonatomic) NSMutableArray *backStops;
@property (assign, nonatomic) NSInteger taskCounter;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    
    [self setPreferredContentSize:CGSizeMake(self.view.frame.size.width, 74.0)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");

    NSLog(@"重新取得資料");
    [self startGetHTML];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    NSLog(@"widgetPerformUpdateWithCompletionHandler");
    [self.tableView reloadData];
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    completionHandler(NCUpdateResultNewData);
}

- (void)startGetHTML {
    
    [self.goStops removeAllObjects];
    self.goStops = [NSMutableArray new];
    [self.backStops removeAllObjects];
    self.backStops = [NSMutableArray new];
    [self.tableView reloadData];
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.indicatorView startAnimating];
    self.indicatorView.center = self.view.center;
    [self.view addSubview:self.indicatorView];
    
    self.tableView.alpha = 0.0;
    
    NSURLSession *session = [NSURLSession sharedSession];
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks,
                                             NSArray *uploadTasks,
                                             NSArray *downloadTasks) {
        for (NSURLSessionTask *task in dataTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in uploadTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in downloadTasks) {
            [task cancel];
        }
        
        self.taskCounter = 3;
        [self downloadData:@"905"];
        [self downloadData:@"906"];
        [self downloadData:@"909"];

    }];
}

- (void)downloadData:(NSString *)busId {
    
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
         self.taskCounter--;
         NSLog(@"self.taskCounter = %zd", self.taskCounter);
         if (self.taskCounter == 0) {
             
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [self.tableView reloadData];
             //self.preferredContentSize = self.tableView.contentSize;
             [self setPreferredContentSize:CGSizeMake(self.view.frame.size.width, 196.0)];
             
                 [self.indicatorView stopAnimating];
                 [self.indicatorView removeFromSuperview];
                 self.indicatorView = nil;
                 
                 self.tableView.alpha = 1.0;
                 NSLog(@"顯示資料");
             });
         }
     }];
    
    // resume
    [dataTask resume];
}

- (void)parseHTML:(NSData *)data busId:(NSString *)busId {
    
    TFHpple *parser = [[TFHpple alloc] initWithHTMLData:data];
    [self parseGoStops:parser busId:busId];
    [self parseBackStops:parser busId:busId];
}

- (void)parseGoStops:(TFHpple *)parser busId:(NSString *)busId  {
    
    NSArray *elements = [parser searchWithXPathQuery:@"//tr[@class='ttego1']"];
    for (TFHppleElement *element in elements) {
        NSArray *tds = [element childrenWithTagName:@"td"];
        if (tds.count == 2) {
            TFHppleElement *a = [[tds firstObject] firstChildWithTagName:@"a"];
            if (a) {
                if ([[a text] rangeOfString:kTargetGoStopName].location != NSNotFound) {
                    NSLog(@"%@: %@ (%@)", busId, [a text], [[tds lastObject] text]);
                    StopInfo *stopInfo = [[StopInfo alloc] init];
                    stopInfo.busId = busId;
                    stopInfo.name = [a text];
                    stopInfo.status = [[tds lastObject] text];
                    [self.goStops addObject:stopInfo];
                }
            }
        }
    }
    
    elements = [parser searchWithXPathQuery:@"//tr[@class='ttego2']"];
    for (TFHppleElement *element in elements) {
        NSArray *tds = [element childrenWithTagName:@"td"];
        if (tds.count == 2) {
            TFHppleElement *a = [[tds firstObject] firstChildWithTagName:@"a"];
            if (a) {
                if ([[a text] rangeOfString:kTargetGoStopName].location != NSNotFound) {
                    NSLog(@"%@: %@ (%@)", busId, [a text], [[tds lastObject] text]);
                    StopInfo *stopInfo = [[StopInfo alloc] init];
                    stopInfo.busId = busId;
                    stopInfo.name = [a text];
                    stopInfo.status = [[tds lastObject] text];
                    [self.goStops addObject:stopInfo];
                }
            }
        }
    }
}

- (void)parseBackStops:(TFHpple *)parser busId:(NSString *)busId  {
    
    NSArray *elements = [parser searchWithXPathQuery:@"//tr[@class='tteback1']"];
    for (TFHppleElement *element in elements) {
        NSArray *tds = [element childrenWithTagName:@"td"];
        if (tds.count == 2) {
            TFHppleElement *a = [[tds firstObject] firstChildWithTagName:@"a"];
            if (a) {
                if ([[a text] rangeOfString:kTargetBackStopName].location != NSNotFound) {
                    NSLog(@"%@: %@ (%@)", busId, [a text], [[tds lastObject] text]);
                    StopInfo *stopInfo = [[StopInfo alloc] init];
                    stopInfo.busId = busId;
                    stopInfo.name = [a text];
                    stopInfo.status = [[tds lastObject] text];
                    [self.backStops addObject:stopInfo];
                }
            }
        }
    }
    
    elements = [parser searchWithXPathQuery:@"//tr[@class='tteback2']"];
    for (TFHppleElement *element in elements) {
        NSArray *tds = [element childrenWithTagName:@"td"];
        if (tds.count == 2) {
            TFHppleElement *a = [[tds firstObject] firstChildWithTagName:@"a"];
            if (a) {
                if ([[a text] rangeOfString:kTargetBackStopName].location != NSNotFound) {
                    NSLog(@"%@: %@ (%@)", busId, [a text], [[tds lastObject] text]);
                    StopInfo *stopInfo = [[StopInfo alloc] init];
                    stopInfo.busId = busId;
                    stopInfo.name = [a text];
                    stopInfo.status = [[tds lastObject] text];
                    [self.backStops addObject:stopInfo];
                }
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.goStops.count == 0 ||
        self.backStops.count == 0) {
        NSLog(@"numberOfSectionsInTableView = 0");
        return 0;
    }
    NSLog(@"numberOfSectionsInTableView = 2");
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        NSLog(@"numberOfRowsInSection = %zd", self.goStops.count);
        return self.goStops.count;
    }
    else if (section == 1) {
        NSLog(@"numberOfRowsInSection = %zd", self.backStops.count);
        return self.backStops.count;
    }
    NSLog(@"numberOfRowsInSection = 0");
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 22.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 22.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return 22.0;
    }
    return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
   
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 22.0);
    label.font = [UIFont systemFontOfSize:14.0];
    label.backgroundColor = [UIColor darkGrayColor];
    label.textColor = [UIColor whiteColor];
    if (section == 0) {
        label.text = kTargetGoStopName;
    }
    else if (section == 1) {
        label.text = kTargetBackStopName;
    }
NSLog(@"viewForHeaderInSection");
    return label;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    if (section == 1) {
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 44.0);
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:10.0];
        label.textAlignment = NSTextAlignmentCenter;
        if (section == 1) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
            NSString *dateString = [formatter stringFromDate:[NSDate date]];
            NSString *update = [NSString stringWithFormat:@"資料更新時間 %@", dateString];
            label.text = update;
        }
        
        CALayer *pulseLayer = [CALayer layer];
        pulseLayer.backgroundColor = [[UIColor whiteColor] CGColor];
        pulseLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), (1.0 / [UIScreen mainScreen].scale));
        [label.layer addSublayer:pulseLayer];
        return label;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    
    StopInfo *stopInfo = nil;
    if (indexPath.section == 0) {
        stopInfo = [self.goStops objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1) {
        stopInfo = [self.backStops objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    if (stopInfo) {
        cell.textLabel.text = stopInfo.busId;
        cell.detailTextLabel.text = stopInfo.status;
    }
    else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    
    NSLog(@"cell %@", stopInfo.status);

    return cell;
}

@end
