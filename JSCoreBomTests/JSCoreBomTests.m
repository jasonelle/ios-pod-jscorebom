#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "JSCoreBom.h"
#import "AGWaitForAsyncTestHelper.h"
#import "OHHTTPStubs.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface JSCoreBomTests : XCTestCase

@end

@implementation JSCoreBomTests
{
    JSContext* context;
}

-(void)testSetTimeout
{
    [context evaluateScript:@"var flag=false; setTimeout(function(){ flag=true },1000)"];
    XCTAssertFalse([[context evaluateScript:@"flag"] toBool],@"Flag should be true by default");
    [self sleepWithoutBlocking:2000];
    XCTAssertTrue([[context evaluateScript:@"flag"] toBool],@"Flag has to be set to true");
}

-(void)testXmlHTTPRequest
{
    NSString* expectedText = @"Hello World";
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[expectedText dataUsingEncoding:NSUTF8StringEncoding] statusCode:200 headers:nil];
    }];
    
    NSString* js = @"var data, error, req = new XMLHttpRequest();                \
                     req.onload  = function () { data = this.responseText };     \
                     req.onerror = function (er) { error = er };                 \
                     req.open('GET', 'http://example.com', true);                \
                     req.send()";
    [context evaluateScript:js];
    XCTAssertNil(context.exception,@"There should be no exception: %@",context.exception);
    [self sleepWithoutBlocking:1000];
    XCTAssertNil([[context evaluateScript:@"error"] toObject],@"There should be no error");
    XCTAssertEqualObjects(expectedText, [[context evaluateScript:@"data"] toString],@"There should be right return string");
}

-(void)testXmlHTTPRequestNoNetwork
{
    [self disableNetwork];
    
    NSString* js = @"var flag = false, error, req = new XMLHttpRequest();        \
                     req.onload  = function () { flag = true };                  \
                     req.onerror = function (er) { error = er };                 \
                     req.open('GET', 'http://example.com', true);                \
                     req.send()";
    [context evaluateScript:js];
    XCTAssertNil(context.exception,@"There should be no exception: %@",context.exception);
    [self sleepWithoutBlocking:1000];
    XCTAssertFalse([[context evaluateScript:@"flag"] toBool],@"XmlHTTPRequest should not succeed if there is no network");
    XCTAssertNotNil([context evaluateScript:@"error"],@"There should be an error about connection");
}

-(void)setUp
{
    context = [[JSContext alloc] init];
    [[JSCoreBom shared] extend:context];
    [OHHTTPStubs removeAllStubs];
}

-(void)sleepWithoutBlocking:(float)ms
{
    __block BOOL isDone = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ms * USEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        isDone = YES;
    });
    WAIT_WHILE(!isDone, 30);
}

-(void)disableNetwork
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]];
    }];
}

@end
