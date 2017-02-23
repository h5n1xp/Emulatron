//
//  EMULibBase.h
//  Emulatron
//
//  Created by Matt Parsons on 16/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMUConsoleView.h"
#include "m68k.h"
#include "endianMacros.h"
#include "EMUexecNode.h"


#define MEMF_ANY        0           // Any type of memory will do
#define MEMF_PUBLIC     1
#define MEMF_CHIP       2
#define MEMF_FAST       4
#define MEMF_LOCAL      256         // Memory that does not go away at RESET
#define MEMF_24BITDMA   512         // DMAable memory within 24 bits of address
#define	MEMF_KICK       1024        // Memory that can be used for KickTags
#define MEMF_CLEAR      65536       // AllocMem: NULL out area before return
#define MEMF_LARGEST    131072      // AvailMem: return the largest chunk size
#define MEMF_REVERSE    262144      // AllocMem: allocate from the top down
#define MEMF_TOTAL      524288      // AvailMem: return total size of memory
#define	MEMF_NO_EXPUNGE	2147483648  // AllocMem: Do not cause expunge on failure


#define INSTANCE_ADDRESS 2040   //the number of bytes below the libBase where the instance address can be found.

@interface EMULibBase : NSObject

@property (nonatomic, weak) EMUConsoleView* debugOutput;

@property (nonatomic) uint32_t   base;
@property (nonatomic) uint32_t   libData;
//@property (nonatomic, strong) id libSelf;

-(instancetype)initAtAddress:(uint32_t)address;
-(void)buildJumpTableSize:(NSInteger)lvocount;

-(EMULibBase*)instanceAtNode:(uint32)address;

//object Properties
-(uint32_t)libName;
-(void)setLibName:(uint32_t)address;
-(const char*)libNameString;

-(uint32_t)libVersion;
-(void)setLibVersion:(uint32_t)value;

-(uint32_t)libRevision;
-(void)setLibRevision:(uint32_t)value;

-(uint32_t)libID;
-(void)setLibID:(uint32_t)address;
-(const char*)libIDString;

-(uint32_t)libOpenCount;
-(void)setLibOpenCount:(uint32_t)value;


-(uint32_t)writeString:(unsigned char*)string toAddress:(uint32_t)address;
-(void)callFunction:(NSInteger)lvo;


-(void)open;
-(void)close;
-(void)expunge;
-(void)reserved;
-(void)unimplemented:(NSInteger)lvo;

@end
