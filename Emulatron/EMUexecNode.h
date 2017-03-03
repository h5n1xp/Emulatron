//
//  EMUexecNode.h
//  Emulatron
//
//  Created by Matt Parsons on 23/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "endianMacros.h"

@interface EMUexecNode : NSObject{
    
    unsigned char* _memory;
    
    uint32_t       _ln_Succ;
    uint32_t       _ln_Pred;
    unsigned char  _ln_Type;
    char           _ln_Priority;
    uint32_t       _ln_Name;
    uint32_t       _list;           // a node should be able it identify which list it blongs to
    unsigned char* _nodeName;       // if it has a name, I want to know
    
}

@property (nonatomic) uint32_t address;

+(instancetype)atAddress:(uint32_t)nodeAddress ofMemory:(unsigned char*)memory;

-(unsigned char*)base;
-(unsigned char*)name;

-(uint32_t)ln_Succ;
-(void)setLn_Succ:(uint32_t)nextAddress;
-(uint32_t)ln_Pred;
-(void)setLn_Pred:(uint32_t)prevAddress;
-(unsigned char)ln_Type;
-(void)setLn_Type:(unsigned char)type;
-(char)ln_Priority;
-(void)setLn_Priority:(char)priority;
-(uint32_t)ln_Name;
-(void)setLn_Name:(uint32_t)nameAddress;

-(uint32_t)listPtr;

@end
