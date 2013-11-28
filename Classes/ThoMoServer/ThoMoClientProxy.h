//
//  ThoMoClientProxy.h
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-28.
//
//

#import <Foundation/Foundation.h>

@class ThoMoServerStub;

@interface ThoMoClientProxy : NSObject

@property (strong, readonly) ThoMoServerStub *server;
@property (strong, readonly) NSString *connectionString;

- (void)sendData:(NSData *)data;
- (void)sendObject:(id<NSCoding>)object;

@end
