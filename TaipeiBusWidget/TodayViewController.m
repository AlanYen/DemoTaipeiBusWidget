//
//  TodayViewController.m
//  TaipeiBusWidget
//
//  Created by AlanYen on 2016/2/17.
//  Copyright © 2016年 17Life. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "ALBusStopManager.h"

#define kTargetGoStopName @"中正環河路口"//@"中正環河路口"
#define kTargetBackStopName @"忠孝敦化"//@"捷運忠孝敦化站"

@interface TodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *exchangeButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;
@property (strong, nonatomic) NSString *goStopName;
@property (strong, nonatomic) NSString *backStopName;
@property (strong, nonatomic) NSMutableArray *busIds;
@property (strong, nonatomic) NSMutableArray *stops;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setPreferredContentSize:CGSizeMake(self.view.frame.size.width, 74.0)];
    [self setup];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[ALBusStopManager sharedManager] getData];
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

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

#pragma mark - 按鍵事件

- (IBAction)onRefreshButtonPressed:(id)sender {

    NSLog(@"onExchangeButtonPressed");
    [[ALBusStopManager sharedManager] getData];
}

- (IBAction)onExchangeButtonPressed:(id)sender {
    
    NSLog(@"onExchangeButtonPressed");
    NSString *temp = self.goStopName;
    self.goStopName = [self.backStopName copy];
    self.backStopName = [temp copy];
    [[ALBusStopManager sharedManager] setGoStopName:self.goStopName];
    [[ALBusStopManager sharedManager] setBackStopName:self.backStopName];
    [[ALBusStopManager sharedManager] getData];
}

#pragma mark - 設定

- (void)setup {
    
    self.goStopName = kTargetGoStopName;
    self.backStopName = kTargetBackStopName;
    [[ALBusStopManager sharedManager] setGoStopName:self.goStopName];
    [[ALBusStopManager sharedManager] setBackStopName:self.backStopName];
    [[ALBusStopManager sharedManager] setBusIds:@[@"905", @"906", @"909"]];
 
    __weak TodayViewController *weakSelf = self;
    [ALBusStopManager sharedManager].getDataWillStartBlock = ^() {
        
        NSLog(@"getDataWillStartBlock");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 準備開始
            [weakSelf.exchangeButton setAlpha:0.0];
            [weakSelf.exchangeButton setEnabled:NO];
            [weakSelf.refreshButton setAlpha:0.0];
            [weakSelf.refreshButton setEnabled:NO];
            [weakSelf.tableView setAlpha:0.0];
            [weakSelf.indicatorView setHidden:NO];
            [weakSelf.indicatorView startAnimating];
        });
    };
    
    [ALBusStopManager sharedManager].getDataStartBlock = ^() {
        
        NSLog(@"getDataStartBlock");
        // 開始
    };
    
    [ALBusStopManager sharedManager].getDataFinishBlock = ^() {
        
        NSLog(@"getDataFinishBlock");
        // 成功
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            [weakSelf.stops removeAllObjects];
            weakSelf.stops = [[ALBusStopManager sharedManager].stops mutableCopy];
            
            [weakSelf.tableView reloadData];
            
            self.preferredContentSize = self.tableView.contentSize;
            //[weakSelf setPreferredContentSize:CGSizeMake(self.view.frame.size.width, 196.0)];
            
            [weakSelf.indicatorView setHidden:YES];
            [weakSelf.indicatorView stopAnimating];
            
            [weakSelf.tableView setAlpha:1.0];
            
            [weakSelf.refreshButton setAlpha:1.0];
            [weakSelf.refreshButton setEnabled:YES];
            [weakSelf.exchangeButton setAlpha:1.0];
            [weakSelf.exchangeButton setEnabled:YES];
            NSLog(@"(更新成功)顯示資料");
        });
    };

    [ALBusStopManager sharedManager].getDataFailBlock = ^() {
        
        NSLog(@"getDataFailBlock");
        // 失敗
        [weakSelf.indicatorView stopAnimating];
        [weakSelf.indicatorView removeFromSuperview];
        weakSelf.indicatorView = nil;
        
        weakSelf.tableView.alpha = 1.0;
        NSLog(@"(更新失敗)顯示資料");
    };
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.stops.count == 0) {
        return 0;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stops.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 22.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 22.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 22.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
   
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 22.0);
    label.font = [UIFont systemFontOfSize:14.0];
    label.backgroundColor = [UIColor darkGrayColor];
    label.textColor = [UIColor whiteColor];
    label.text = [NSString stringWithFormat:@"%@ 往 %@", self.goStopName, self.backStopName];
    return label;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 44.0);
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:10.0];
    label.textAlignment = NSTextAlignmentCenter;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSString *update = [NSString stringWithFormat:@"資料更新時間 %@", dateString];
    label.text = update;
    
    CALayer *pulseLayer = [CALayer layer];
    pulseLayer.backgroundColor = [[UIColor whiteColor] CGColor];
    pulseLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), (1.0 / [UIScreen mainScreen].scale));
    [label.layer addSublayer:pulseLayer];
    return label;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    
    ALStopInfo *stopInfo = nil;
    stopInfo = [self.stops objectAtIndex:indexPath.row];
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    if (stopInfo) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", stopInfo.busId, stopInfo.status];
        cell.detailTextLabel.text = stopInfo.name;
    }
    else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

@end
