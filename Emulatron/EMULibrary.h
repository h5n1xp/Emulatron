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

@interface EMULibrary : NSObject

@property (nonatomic) uint32_t base;
@property (nonatomic) NSInteger negSize;    // the size of the LVO table in bytes
@property (nonatomic) NSInteger posSize;    // size of the positive data area.

-(instancetype)initAtAddress:(uint32_t)address;
-(void)buildJumpTableSize:(NSInteger)lvocount;
-(void)callFunction:(NSInteger)lvo;
-(NSInteger)librarySizeInMemory;

-(void)open;
-(void)close;
-(void)expunge;
-(void)reserved;
-(void)unimplemented:(NSInteger)lvo;
@end
