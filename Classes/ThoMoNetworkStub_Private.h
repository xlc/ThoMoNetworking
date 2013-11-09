//
//  ThoMoNetworkStub_Private.h
//  ThoMoNetworking
//
//  Created by Xiliang Chen on 13-11-6.
//
//

#import "ThoMoNetworkStub.h"

@interface ThoMoNetworkStub () <ThoMoTCPConnectionDelegateProtocol, NSNetServiceDelegate>
{
	NSMutableDictionary	*_connections;
	NSThread			*_networkThread;
}

@property (copy, readonly) NSString *protocolIdentifier;

-(NSArray *)activeConnections;

-(void)send:(id<NSCoding>)theData toConnection:(NSString *)theConnectionIdString;
-(void)sendByteData:(NSData *)theData toConnection:(NSString *)theConnectionIdString;

-(BOOL)setup;
-(void)teardown;
-(NSString *)keyStringFromAddress:(NSData *)addr;
/// Returns the key for theConnection from the connections dictionary.
-(NSString *)keyForConnection:(ThoMoTCPConnection *)theConnection;
-(void) openNewConnection:(NSString *)theConnectionKey inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;

@end

// interface category for main thread relay methods
// abstracted methods, they are not implemented in ThoMoNetworkStub, subclasses must implemented them all and not call super
@interface ThoMoNetworkStub (RelayMethods)
-(void)networkStubDidShutDownRelayMethod;
-(void)netServiceProblemRelayMethod:(NSDictionary *)infoDict;
-(void)didReceiveDataRelayMethod:(NSDictionary *)infoDict;
-(void)connectionEstablishedRelayMethod:(NSDictionary *)infoDict;
-(void)connectionLostRelayMethod:(NSDictionary *)infoDict;
-(void)connectionClosedRelayMethod:(NSDictionary *)infoDict;
@end

NSString *const kThoMoNetworkInfoKeyUserMessage;
NSString *const kThoMoNetworkInfoKeyData;
NSString *const kThoMoNetworkInfoKeyRemoteConnectionIdString;
NSString *const kThoMoNetworkInfoKeyLocalNetworkStub;