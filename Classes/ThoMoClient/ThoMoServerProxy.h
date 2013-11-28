//
//  ThoMoServerProxy.h
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-27.
//
//

#import <Foundation/Foundation.h>

@class ThoMoClientStub;

@interface ThoMoServerProxy : NSObject

@property (strong, readonly) ThoMoClientStub *client;
@property (strong, readonly) NSString *connectionString;

- (void)sendData:(NSData *)data;
- (void)sendObject:(id<NSCoding>)object;

@end
