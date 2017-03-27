//
//  LMTimeLineLocationListVC.m
//  LMMapLocationList
//
//  Created by limin on 17/3/27.
//  Copyright © 2017年 君安信（北京）科技有限公司. All rights reserved.
//

#import "LMTimeLineLocationListVC.h"
#import "UIView+SDAutoLayout.h"
//地图定位
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>

#define kBaiduMapMaxHeight 300
#define kCurrentLocationBtnWH 50
#define kPading 10
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
@interface LMTimeLineLocationListVC ()<BMKMapViewDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,UITableViewDataSource,UITableViewDelegate>
{
    BOOL isFirstLocation;
}

@property(nonatomic,strong)BMKMapView* mapView;
@property(nonatomic,strong)BMKLocationService* locService;
@property(nonatomic,strong)BMKGeoCodeSearch* geocodesearch;

@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)NSMutableArray *dataSource;

@property(nonatomic,assign)CLLocationCoordinate2D currentCoordinate;
@property(nonatomic,assign)NSInteger currentSelectLocationIndex;
@property(nonatomic,strong)UIImageView *centerCallOutImageView;
@property(nonatomic,strong)UIButton *currentLocationBtn;


@end

@implementation LMTimeLineLocationListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self configUI];
    [self startLocation];
}
-(void)configUI
{
    [self.view addSubview:self.mapView];
    self.mapView.sd_layout
    .leftSpaceToView(self.view,0)
    .rightSpaceToView(self.view,0)
    .topSpaceToView(self.view,0)
    .heightIs(kBaiduMapMaxHeight);
    
    
    [self.view addSubview:self.centerCallOutImageView];
    [self.view bringSubviewToFront:self.centerCallOutImageView];
    self.centerCallOutImageView.sd_layout
    .topSpaceToView(self.view,(kBaiduMapMaxHeight-30)*0.5)
    .leftSpaceToView(self.view,(kScreenWidth-30)*0.5)
    .widthIs(30)
    .heightIs(30);
    
    
    [self.mapView layoutIfNeeded];
    
    [self.view addSubview:self.tableView];
    self.tableView.sd_layout
    .topSpaceToView(self.mapView,0)
    .leftSpaceToView(self.view,0)
    .rightSpaceToView(self.view,0)
    .bottomSpaceToView(self.view,0);
    
    self.currentLocationBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.currentLocationBtn setImage:[UIImage imageNamed:@"location_back_icon"] forState:UIControlStateNormal];
    [self.currentLocationBtn setImage:[UIImage imageNamed:@"location_blue_icon"] forState:UIControlStateSelected];
    [self.currentLocationBtn addTarget:self action:@selector(startLocation) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.currentLocationBtn];
    [self.view bringSubviewToFront:self.currentLocationBtn];
    self.currentLocationBtn.sd_layout
    .widthIs(kCurrentLocationBtnWH)
    .heightIs(kCurrentLocationBtnWH)
    .topSpaceToView(self.view,kBaiduMapMaxHeight-10-kCurrentLocationBtnWH)
    .leftSpaceToView(self.view,10);
    
    
}

-(void)startLocation
{
    isFirstLocation=YES;//首次定位
    self.currentSelectLocationIndex=0;
    self.currentLocationBtn.selected=YES;
    [self.locService startUserLocationService];
    self.mapView.showsUserLocation = NO;//先关闭显示的定位图层
    self.mapView.userTrackingMode = BMKUserTrackingModeFollow;//设置定位的状态
    self.mapView.showsUserLocation = YES;//显示定位图层
}

-(void)startGeocodesearchWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeocodeSearchOption.reverseGeoPoint = coordinate;
    BOOL flag = [_geocodesearch reverseGeoCode:reverseGeocodeSearchOption];
    if(flag)
    {
        NSLog(@"反geo检索发送成功");
    }
    else
    {
        NSLog(@"反geo检索发送失败");
    }
}

-(void)setCurrentCoordinate:(CLLocationCoordinate2D)currentCoordinate
{
    _currentCoordinate=currentCoordinate;
    [self startGeocodesearchWithCoordinate:currentCoordinate];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.mapView viewWillAppear];
    self.mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
    self.locService.delegate = self;
    self.geocodesearch.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.mapView viewWillDisappear];
    self.mapView.delegate = nil; // 不用时，置nil
    self.locService.delegate = nil;
    self.geocodesearch.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (_mapView)
    {
        _mapView = nil;
    }
    if (_geocodesearch)
    {
        _geocodesearch = nil;
    }
    if (_locService)
    {
        _locService=nil;
    }
}

#pragma mark - BMKMapViewDelegate

/**
 *在地图View将要启动定位时，会调用此函数
 *@param mapView 地图View
 */
- (void)willStartLocatingUser
{
    NSLog(@"start locate");
}

/**
 *用户方向更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    [self.mapView updateLocationData:userLocation];
    //    NSLog(@"heading is %@",userLocation.heading);
}

/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    isFirstLocation=NO;
    self.currentLocationBtn.selected=NO;
    [self.mapView  updateLocationData:userLocation];
    self.currentCoordinate=userLocation.location.coordinate;
    
    if (self.currentCoordinate.latitude!=0)
    {
        [self.locService stopUserLocationService];
    }
}

/**
 *在地图View停止定位后，会调用此函数
 *@param mapView 地图View
 */
- (void)didStopLocatingUser
{
    NSLog(@"stop locate");
}

/**
 *定位失败后，会调用此函数
 *@param mapView 地图View
 *@param error 错误号，参考CLError.h中定义的错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"location error");
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"无法定位" message:@"请在iPhone的\"设置-隐私-定位服务\"中允许灵佛使用定位服务。" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    [alertVC addAction:action];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)mapView:(BMKMapView *)mapView onClickedMapBlank:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"map view: click blank");
}
- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (!isFirstLocation)
    {
        CLLocationCoordinate2D tt =[mapView convertPoint:self.centerCallOutImageView.center toCoordinateFromView:self.centerCallOutImageView];
        self.currentCoordinate=tt;
    }
    
}
#pragma mark - BMKGeoCodeSearchDelegate

/**
 *返回地址信息搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结BMKGeoCodeSearch果
 *@param error 错误号，@see BMKSearchErrorCode
 */
- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    NSLog(@"返回地址信息搜索结果,失败-------------");
}

/**
 *返回反地理编码搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结果
 *@param error 错误号，@see BMKSearchErrorCode
 */

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR)
    {
        [self.dataSource removeAllObjects];
        [self.dataSource addObjectsFromArray:result.poiList];
        
        if (isFirstLocation)
        {
            //把当前定位信息自定义组装 放进数组首位
            BMKPoiInfo *first =[[BMKPoiInfo alloc]init];
            first.address=result.address;
            first.name=@"[当前位置]";
            first.pt=result.location;
            first.city=result.addressDetail.city;
            [self.dataSource insertObject:first atIndex:0];
        }
        
        [self.tableView reloadData];
        
    }
}

#pragma mark - TableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellid = @"cellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellid];
        
    }
    BMKPoiInfo *model=[self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text=model.name;
    cell.detailTextLabel.text=model.address;
    cell.detailTextLabel.textColor=[UIColor grayColor];
    
    if (self.currentSelectLocationIndex==indexPath.row)
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType=UITableViewCellAccessoryNone;
    
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BMKPoiInfo *model=[self.dataSource objectAtIndex:indexPath.row];
    BMKMapStatus *mapStatus =[self.mapView getMapStatus];
    mapStatus.targetGeoPt=model.pt;
    [self.mapView setMapStatus:mapStatus withAnimation:YES];
    self.currentSelectLocationIndex=indexPath.row;
    [self.tableView reloadData];
}

#pragma mark - InitMethod

-(BMKMapView*)mapView
{
    if (_mapView==nil)
    {
        _mapView =[BMKMapView new];
        _mapView.zoomEnabled=NO;
        _mapView.zoomEnabledWithTap=NO;
        _mapView.zoomLevel=17;
    }
    return _mapView;
}

-(BMKLocationService*)locService
{
    if (_locService==nil)
    {
        _locService = [[BMKLocationService alloc]init];
    }
    return _locService;
}
-(BMKGeoCodeSearch*)geocodesearch
{
    if (_geocodesearch==nil)
    {
        _geocodesearch=[[BMKGeoCodeSearch alloc]init];
    }
    return _geocodesearch;
}

-(UITableView*)tableView
{
    if (_tableView==nil)
    {
        _tableView=[UITableView new];
        _tableView.delegate=self;
        _tableView.dataSource=self;
        
    }
    return _tableView;
}

-(UIImageView*)centerCallOutImageView
{
    if (_centerCallOutImageView==nil)
    {
        _centerCallOutImageView=[UIImageView new];
        [_centerCallOutImageView setImage:[UIImage imageNamed:@"location_green_icon"]];
    }
    return _centerCallOutImageView;
}
-(NSMutableArray*)dataSource
{
    if (_dataSource==nil) {
        _dataSource=[[NSMutableArray alloc]init];
    }
    
    return _dataSource;
}


@end
