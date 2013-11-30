//
//  ThoMoServerProxy.h
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-27.
//
//

#import <Foundation/Foundation.h>

@class ThoMoClientStub;

@protocol ThoMoServerProxyDelegate;

@interface ThoMoServerProxy : NSObject

@property (strong, readonly) ThoMoClientStub *client;
@property (strong, readonly) NSString *connectionString;
@property (weak) id<ThoMoServerProxyDelegate> delegate;

- (void)sendData:(NSData *)data;
- (void)sendObject:(id<NSCoding>)object;

@end

@protocol ThoMoServerProxyDelegate <NSObject>

@required
- (void)serverProxy:(ThoMoServerProxy *)serverProxy didReceiveData:(NSData *)data;

@optional
- (void)serverProxyDidDisconnect:(ThoMoServerProxy *)serverProxy;
- (void)serverProxyDidResumeConnection:(ThoMoServerProxy *)serverProxy;

@end