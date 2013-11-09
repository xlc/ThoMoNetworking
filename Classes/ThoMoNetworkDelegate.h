//
//  ThoMoNetworkDelegate.h
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-8.
//
//

#import <Foundation/Foundation.h>

@class ThoMoNetworkStub;

@protocol ThoMoNetworkDelegate <NSObject>

@optional
/// Connection notification (optional)
- (void)network:(ThoMoNetworkStub *)theClient didConnectToServer:(NSString *)aServerIdString;


/// Disconnection notification (optional)
- (void)client:(ThoMoNetworkStub *)theClient didDisconnectFromServer:(NSString *)aServerIdString error:(NSError *)error;


/// Bonjour problem notification (optional)
- (void)client:(ThoMoNetworkStub *)theClient encounteredNetServiceError:(NSError *)error;


/// Client shutdown notification (optional)
- (void)clientDidShutDown:(ThoMoNetworkStub *)theClient;


@required

@end
