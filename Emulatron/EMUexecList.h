//
//  EMUexecList.h
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "endianMacros.h"

@interface EMUexecList : NSObject{
    
    unsigned char* _memory;
    
    uint32_t       _lh_Head;
    uint32_t       _lh_Tail;
    uint32_t       _lh_TailPred;
    unsigned char  _lh_Type;
}

@property (nonatomic) uint32_t address;

+(instancetype)atAddress:(uint32_t)nodeAddress ofMemory:(unsigned char*)memory;

//The list header and the nodes overlap, so I need these two properties:
-(uint32_t)ln_Succ;
-(void)setLn_Succ:(uint32_t)nextAddress;
-(uint32_t)ln_Pred;


-(uint32_t)lh_Head;
-(void)setLh_Head:(uint32_t)value;
-(uint32_t)lh_Tail;
-(void)setLh_Tail:(uint32_t)value;
-(uint32_t)lh_TailPred;
-(void)setLh_TailPred:(uint32_t)value;
-(unsigned char)lh_Type;
-(void)setLh_Type:(unsigned char)value;

@end
