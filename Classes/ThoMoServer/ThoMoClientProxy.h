//
//  ThoMoClientProxy.h
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-28.
//
//

#import <Foundation/Foundation.h>

@class ThoMoServerStub;

@protocol ThoMoClientProxyDelegate;

@interface ThoMoClientProxy : NSObject

@property (strong, readonly) ThoMoServerStub *server;
@property (strong, readonly) NSString *connectionString;
@property (weak) id<ThoMoClientProxyDelegate> delegate;

- (void)sendData:(NSData *)data;
- (void)sendObject:(id<NSCoding>)object;

@end

@protocol ThoMoClientProxyDelegate <NSObject>

@required
- (void)clientProxy:(ThoMoClientProxy *)clientProxy didReceiveData:(NSData *)data;

@optional
- (void)clientProxyDidDisconnect:(ThoMoClientProxy *)clientProxy;
- (void)clientProxyDidResumeConnection:(ThoMoClientProxy *)clientProxy;

@end