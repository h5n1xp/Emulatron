//
//  EMUexecList.m
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecList.h"

@implementation EMUexecList


+(instancetype)atAddress:(uint32_t)address ofMemory:(unsigned char *)memory{
    EMUexecList* retVal = [[super alloc] init];
    
    retVal.address   = address;
    retVal->_memory      = memory;
    retVal->_lh_Head     = READ_LONG(memory, address);
    retVal->_lh_Tail     = READ_LONG(memory, address+4);
    retVal->_lh_TailPred = READ_LONG(memory, address+8);
    retVal->_lh_Type     = READ_BYTE(memory, address+12);
    
    return retVal;
}


-(uint32_t)ln_Succ{
    return self.lh_Head;
}

-(void)setLn_Succ:(uint32_t)nextAddress{
    self.lh_Head = nextAddress;
}

-(uint32_t)ln_Pred{
    return self.lh_Tail;
}


-(uint32_t)lh_Head{
    _lh_Head = READ_LONG(_memory,self.address);
    return _lh_Head;
}
-(void)setLh_Head:(uint32_t)value{
    _lh_Head = value;
    WRITE_LONG(_memory,self.address,value);
}

-(uint32_t)lh_Tail{
    _lh_Tail= READ_LONG(_memory,self.address+4);
    return _lh_Tail;
}
-(void)setLh_Tail:(uint32_t)value{
    _lh_Tail= value;
    WRITE_LONG(_memory,self.address,value+4);
}

-(uint32_t)lh_TailPred{
    _lh_TailPred= READ_LONG(_memory,self.address+8);
    return _lh_TailPred;
}
-(void)setLh_TailPred:(uint32_t)value{
    _lh_TailPred= value;
    WRITE_LONG(_memory,self.address,value+8);
}

-(unsigned char)lh_Type{
    _lh_Type= READ_BYTE(_memory,self.address+12);
    return _lh_Type;
}
-(void)setLh_Type:(unsigned char)value{
    _lh_Type= value;
    WRITE_BYTE(_memory,self.address,value+12);
}


@end
