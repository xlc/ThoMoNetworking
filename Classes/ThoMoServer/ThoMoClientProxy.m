//
//  ThoMoClientProxy.m
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-28.
//
//

#import "ThoMoClientProxy_Private.h"

#import "ThoMoServerStub.h"

@implementation ThoMoClientProxy

- (id)initWithServer:(ThoMoServerStub *)server andConnectionString:(NSString *)connectionString
{
    self = [super init];
    if (self) {
        _server = server;
        _connectionString = connectionString;
    }
    return self;
}

- (void)sendData:(NSData *)data
{
    [_server sendBytes:data toClient:_connectionString];
}

- (void)sendObject:(id<NSCoding>)object
{
    [_server send:object toClient:_connectionString];
}

@end
