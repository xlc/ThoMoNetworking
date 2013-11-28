//
//  ThoMoServerProxy.m
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-27.
//
//

#import "ThoMoServerProxy_Private.h"

#import "ThoMoClientStub.h"

@implementation ThoMoServerProxy

- (id)initWithClient:(ThoMoClientStub *)client andConnectionString:(NSString *)connectionString
{
    self = [super init];
    if (self) {
        _client = client;
        _connectionString = connectionString;
    }
    return self;
}

- (void)sendData:(NSData *)data
{
    [_client sendBytes:data toServer:_connectionString];
}

- (void)sendObject:(id<NSCoding>)object
{
    [_client send:object toServer:_connectionString];
}

@end
