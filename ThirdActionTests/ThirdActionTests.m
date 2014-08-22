//
//  ThirdActionTests.m
//  ThirdActionTests
//
//  Created by wac on 14-8-13.
//  Copyright (c) 2014年 com.myxgou.third. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ThirdActionTests : XCTestCase

@end

@implementation ThirdActionTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
}

- (void)testExample
{
    
    NSString *s = nil;
    NSLog(@"l:%lu",(unsigned long)s.length);
    XCTAssertTrue(s.length==0, @"xxx");
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
