//
//  ViewController.m
//  CT4AFNetworkingDemo
//
//  Created by 陈世翰 on 16/12/19.
//  Copyright © 2016年 Coder Chan. All rights reserved.
//

#import "ViewController.h"
#import "NetWorkManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *docRootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *savePath = [docRootPath stringByAppendingPathComponent:@"ddd"];
    NSString *downL =@"http://static.tangguoyuan.net//static/4a/d8/79/e7/4bd8bdf9ba9d4d7aabb74006f4aa2932.mp4";
    NSLog(@"%@",downL);
   NSURLSessionDataTask *task = [NetWorkManager continuedDownLoadFileWithSavaPath:savePath withUrlString:downL withSuccessBlock:^(NSDictionary *object) {
        NSLog(@"%@",object);
    } withFailureBlock:^(NSString *desc) {
        NSLog(@"%@",desc);
    } withDownLoadProgress:^(float progress, float readMB, float expectedMB) {
        NSLog(@"%f",progress);
    }];
    [task resume];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
