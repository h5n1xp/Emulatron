//
//  EMULibBase.h
//  Emulatron
//
//  Created by Matt Parsons on 16/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "m68k.h"
#include "endianMacros.h"



#define INSTANCE_ADDRESS 2040   //the number of bytes below the libBase where the instance address can be found.

@interface EMULibBase : NSObject

@property (nonatomic, weak) NSMutableString* debugOutput;

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


-(uint32_t)writeString:(char*)string toAddress:(uint32_t)address;
-(void)callFunction:(NSInteger)lvo;


-(void)open;
-(void)close;
-(void)expunge;
-(void)reserved;
-(void)unimplemented:(NSInteger)lvo;

@end
