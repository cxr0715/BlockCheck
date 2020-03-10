//
//  ViewController.m
//  BlockCheck
//
//  Created by YYInc on 2020/3/10.
//  Copyright © 2020 caoxuerui. All rights reserved.
//

#import "ViewController.h"
#import "BNLeakCheckerWithBlockVariable.h"
typedef void (^BlockTest)(void);
@interface ViewController ()
@property (nonatomic, copy) BlockTest strongBlock;
@property (nonatomic, copy) BlockTest blockBlock;
@property (nonatomic, copy) BlockTest weakBlock;
@property (nonatomic, copy) NSString *strongString;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // strong Block
    self.strongBlock = ^() {
        NSLog(@"string:%@",self.strongString);
    };
    NSSet *set = [BNLeakCheckerWithBlockVariable getBlockStrongLayout_new:(void *)(self.strongBlock)];
    NSLog(@"strong set:%@",set);
    if ([set containsObject:self]) {
        NSLog(@"self has strong ivar retain cycle:%@",self);
    }
    
    // __block Block
    __block NSString *str = @"aaa";
    self.blockBlock = ^{
        str = @"bbb";
        NSLog(@"string:%@",str);
    };
    NSSet *set1 = [BNLeakCheckerWithBlockVariable getBlockStrongLayout_new:(void *)self.blockBlock];
    NSLog(@"__blcok set:%@",set1);
    if ([set1 containsObject:self]) {
        NSLog(@"self has __block ivar return cycle:%@",self);
    }
    
    // weak Block
    __weak typeof(self) weakSelf = self;
    self.weakBlock = ^{
        NSLog(@"string:%@",weakSelf.strongString);
    };
    NSSet *set2 = [BNLeakCheckerWithBlockVariable getBlockStrongLayout_new:(void *)self.weakBlock];
    NSLog(@"weak set:%@",set2);
    if ([set2 containsObject:self]) {
        NSLog(@"self has weak ivar return cycle:%@",self);
    }
}


@end
