/*
 *  ThoMoNetworkStub.m
 *  ThoMoNetworkingFramework
 *
 *  Created by Thorsten Karrer on 2.7.09.
 *  Copyright 2010 media computing group - RWTH Aachen University.
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import "ThoMoNetworkStub.h"
#import "ThoMoNetworkStub_Private.h"

#import <arpa/inet.h>
#import "ThoMoTCPConnection.h"
#import <pthread.h>

NSString *const kThoMoNetworkInfoKeyUserMessage					= @"kThoMoNetworkInfoKeyUserMessage";
NSString *const kThoMoNetworkInfoKeyData						= @"kThoMoNetworkInfoKeyData";
NSString *const kThoMoNetworkInfoKeyRemoteConnectionIdString	= @"kThoMoNetworkInfoKeyRemoteConnectionIdString";
NSString *const kThoMoNetworkInfoKeyLocalNetworkStub			= @"kThoMoNetworkInfoKeyLocalNetworkStub";

NSString *const kThoMoNetworkPrefScopeSpecifierKey				= @"kThoMoNetworkPrefScopeSpecifierKey";

@interface ThoMoNetworkStub ()

-(void)sendDataWithInfoDict:(NSDictionary *)theInfoDict;

@end

// =====================================================================================================================
#pragma mark -
#pragma mark Public Methods
// ---------------------------------------------------------------------------------------------------------------------

@implementation ThoMoNetworkStub

#pragma mark Housekeeping

-(id)initWithProtocolIdentifier:(NSString *)theProtocolIdentifier;
{
	self = [super init];
	if (self != nil) 
	{
		// check if there is a scope specifier present in the user defaults and add it to the protocolId
		NSString *scopeSpecifier = [[NSUserDefaults standardUserDefaults] stringForKey:kThoMoNetworkPrefScopeSpecifierKey];
		if (scopeSpecifier)
		{
			_protocolIdentifier = [scopeSpecifier stringByAppendingFormat:@"-%@", theProtocolIdentifier];
			NSLog(@"Warning: ThoMo Networking Protocol Prefix in effect! If your app cannot connect to its counterpart that may be the reason.");
		}
		else
		{
			_protocolIdentifier = [theProtocolIdentifier copy];
		}

		if ([_protocolIdentifier length] > 14)
		{
			// clean up internally
			[NSException raise:@"ThoMoInvalidArgumentException" 
						format:@"The protocol identifier plus the optional scoping prefix (\"%@\") exceed"
								" Bonjour's maximum allowed length of fourteen characters!", _protocolIdentifier];
		} 
		
		_connections	= [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(id)init;
{
	return [self initWithProtocolIdentifier:[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey]];
}

// since the networkThread retains our object while it executes, this method will be called after the thread is done

// these methods are called on the main thread
#pragma mark Control

-(void)start;
{
	if ([_networkThread isExecuting])
	{
		return;
	}
	
	_networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkThreadEntry) object:nil];
	[_networkThread start];
}

-(void)stop;
{
	[_networkThread cancel];
	_networkThread = nil;
}

-(NSArray *)activeConnections;
{
	@synchronized(_connections)
	{
        return [[_connections allKeys] copy];
	}
}

-(void)send:(id<NSCoding>)theData toConnection:(NSString *)theConnectionIdString;
{
	NSData *sendData = [NSKeyedArchiver archivedDataWithRootObject:theData];
	[self sendByteData:sendData toConnection:theConnectionIdString];
}

-(void)sendByteData:(NSData *)sendData toConnection:(NSString *)theConnectionIdString;
{
    if (_networkThread == nil) {
        NSLog(@"ThoMoNetworking - WARN: Trying to send data without calling start. Starting now...");
        [self start];
    }
    
    if ([sendData length] == 0) {   // nothing to send
        return;
    }
	
    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  sendData, @"DATA",
							  theConnectionIdString, @"ID",
							  nil];
	
	[self performSelector:@selector(sendDataWithInfoDict:) onThread:_networkThread withObject:infoDict waitUntilDone:NO];
}

#pragma mark Send Data Relay

// only call on network thread
-(void)sendDataWithInfoDict:(NSDictionary *)theInfoDict;
{
	NSData *sendData = [theInfoDict objectForKey:@"DATA"];
	NSString *theConnectionIdString = [theInfoDict objectForKey:@"ID"];
	
	ThoMoTCPConnection *connection = nil;
	@synchronized(_connections)
	{
		connection = [_connections objectForKey:theConnectionIdString];
	}
	
    [connection enqueueNextSendObject:sendData];
}


#pragma mark Threading Methods

-(void)networkThreadEntry
{
	@autoreleasepool {
	
		if([self setup])
		{
            @try {
                while (![_networkThread isCancelled])
                {
                    NSDate *inOneSecond = [[NSDate alloc] initWithTimeIntervalSinceNow:1];
                    [[NSRunLoop currentRunLoop]	runMode:NSDefaultRunLoopMode beforeDate:inOneSecond];
                }
            }
            @finally {
                [self teardown];
            }
		}
		
		[self performSelectorOnMainThread:@selector(networkStubDidShutDownRelayMethod) withObject:nil waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark Connection Delegate Methods

/// Delegate method that gets called from ThoMoTCPConnections whenever they did receive data.
/**
 Takes the received data and relays it to a method on the main thread.
 This method is typically overridden in the subclasses of ThoMoNetworkStub and then directly called from there.
 
 \param[in]	theData			reference to the received data
 \param[in]	theConnection	reference to the connection that received the data
 */
-(void)didReceiveData:(NSData *)theData onConnection:(ThoMoTCPConnection *)theConnection;
{
	// look up the connection
	NSString *connectionKey = [self keyForConnection:theConnection];
	
	// package the parameters into an info dict and relay them to the main thread
	NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:	
							  connectionKey,	kThoMoNetworkInfoKeyRemoteConnectionIdString,
							  self,				kThoMoNetworkInfoKeyLocalNetworkStub,
							  theData,          kThoMoNetworkInfoKeyData,
							  nil];
	
	[self performSelectorOnMainThread:@selector(didReceiveDataRelayMethod:) withObject:infoDict waitUntilDone:NO];
}

-(void)streamsDidOpenOnConnection:(ThoMoTCPConnection *)theConnection;
{
	// look up the connection
	NSString *connectionKey = [self keyForConnection:theConnection];
	
	// package the parameters into an info dict and relay them to the main thread
	NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:	
							  self,				kThoMoNetworkInfoKeyLocalNetworkStub,
							  connectionKey,	kThoMoNetworkInfoKeyRemoteConnectionIdString,
							  nil];
	
	[self performSelectorOnMainThread:@selector(connectionEstablishedRelayMethod:) withObject:infoDict waitUntilDone:NO];
}

-(void)streamEndEncountered:(NSStream *)theStream onConnection:(ThoMoTCPConnection *)theConnection;
{
	NSString *connectionKey = [self keyForConnection:theConnection];
	
	[theConnection close];
	
	@synchronized(_connections)
	{
		[_connections removeObjectForKey:connectionKey];
	}
	
	NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:	
							  self,				kThoMoNetworkInfoKeyLocalNetworkStub,
							  connectionKey,	kThoMoNetworkInfoKeyRemoteConnectionIdString,
							  nil];
	
	[self performSelectorOnMainThread:@selector(connectionClosedRelayMethod:) withObject:infoDict waitUntilDone:NO];
}

-(void)streamErrorEncountered:(NSStream *)theStream onConnection:(ThoMoTCPConnection *)theConnection;
{
	NSString *connectionKey = [self keyForConnection:theConnection];
	
	NSError *theError = [theStream streamError];
	
	[theConnection close];
	
	@synchronized(_connections)
	{
		[_connections removeObjectForKey:connectionKey];
	}
	
	NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:	
							  self,				kThoMoNetworkInfoKeyLocalNetworkStub,
							  connectionKey,	kThoMoNetworkInfoKeyRemoteConnectionIdString,	
							  theError,		kThoMoNetworkInfoKeyUserMessage,
							  nil];
	
	[self performSelectorOnMainThread:@selector(connectionLostRelayMethod:) withObject:infoDict waitUntilDone:NO];
}



// =====================================================================================================================
#pragma mark -
#pragma mark Protected Methods
// ---------------------------------------------------------------------------------------------------------------------


-(BOOL)setup
{
	return YES;
}

-(void)teardown
{
	// close all open connections
	@synchronized(_connections)
	{
		for (ThoMoTCPConnection *connection in [_connections allValues]) {
			[connection close];
		}
		
		[_connections removeAllObjects];
	}
}

-(NSString *)keyStringFromAddress:(NSData *)addr;
{
	// get the peer socket address from the NSData object
	// NOTE:	there actually is a struct sockaddr in there, NOT a struct sockaddr_in! 
	//			I heard from beej (<http://www.retran.com/beej/sockaddr_inman.html>) that they share the same 15 first bytes so casting should not be a problem. 
	//			You've been warned, though...
	struct sockaddr_in *peerSocketAddress = (struct sockaddr_in *)[addr bytes];
	
    @synchronized(self) {
        // convert in_addr to ascii (note: returns a pointer to a statically allocated buffer inside inet_ntoa! calling again will overwrite)
        char *humanReadableAddress	= inet_ntoa(peerSocketAddress->sin_addr);
        int peerPort                = ntohs(peerSocketAddress->sin_port);
        NSString *peerKey			= [NSString stringWithFormat:@"%s:%d", humanReadableAddress, peerPort];
        return peerKey;
    }
}

-(NSString *)keyForConnection:(ThoMoTCPConnection *)theConnection;
{
	NSString	*connectionKey;
	NSArray		*keys;
	@synchronized(_connections)
	{
		keys = [_connections allKeysForObject:theConnection];
		NSAssert([keys count] == 1, @"More than one connection record in dict for a single connection.");
		connectionKey = [[keys objectAtIndex:0] copy];
	}
	
	return connectionKey;
}

-(void)openNewConnection:(NSString *)theConnectionKey inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
{
	// create a new ThoMoTCPConnection object and set ourselves as the delegate to forward the incoming data to our own delegate
	ThoMoTCPConnection *newConnection = [[ThoMoTCPConnection alloc] initWithDelegate:self inputStream:istr outputStream:ostr];
	
	// store in our dictionary, open, and release our copy
	@synchronized(_connections)
	{
		// it should never happen that we overwrite a connection
		NSAssert(![_connections valueForKey:theConnectionKey], @"ERROR: Tried to create a connection with an IP and port that we already have a connection for.");
		
		[_connections setValue:newConnection forKey:theConnectionKey];
	}
	[newConnection open];
}

@end
