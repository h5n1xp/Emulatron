//
//  EMULibrary.h
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "m68k.h"
#include "endianMacros.h"

#define INSTANCE_ADDRESS 2040

@interface EMULibrary : NSObject

@property (nonatomic) uint32_t   base;
@property (nonatomic) uint32_t   libData;
@property (nonatomic, strong) id libSelf;

-(instancetype)initAtAddress:(uint32_t)address;
-(void)buildJumpTableSize:(NSInteger)lvocount;

-(EMULibrary*)instanceAtNode:(uint32)address;
-(uint32_t)node;

-(uint32_t)nextLib;
-(void)setNextLib:(uint32_t)address;

-(uint32_t)previousLib;
-(void)setPreviousLib:(uint32_t)address;

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

-(uint32_t)writeString:(char*)string toAddress:(uint32_t)address;

-(void)callFunction:(NSInteger)lvo;

-(void)open;
-(void)close;
-(void)expunge;
-(void)reserved;
-(void)unimplemented:(NSInteger)lvo;
@end
