//
//  EMUexecNode.m
//  Emulatron
//
//  Created by Matt Parsons on 23/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecNode.h"

extern unsigned char* _emulatorMemory;   //Nasty global variable

@implementation EMUexecNode

+(instancetype)atAddress:(uint32_t)nodeAddress ofMemory:(unsigned char *)memory{
    EMUexecNode* retVal = [[super alloc] init];
    
    retVal.address       = nodeAddress;
    retVal->_memory      = memory;
    retVal->_ln_Succ     = READ_LONG(memory, nodeAddress);
    retVal->_ln_Pred     = READ_LONG(memory, nodeAddress+4);
    retVal->_ln_Type     = READ_BYTE(memory, nodeAddress+8);
    retVal->_ln_Priority = READ_BYTE(memory, nodeAddress+9);
    retVal->_ln_Name     = READ_LONG(memory, nodeAddress+10);
    retVal->_nodeName    = &_emulatorMemory[retVal->_ln_Name];
    
    //track back through the list until we find the list header.
    uint32_t prevNode=retVal->_ln_Pred;
    uint32_t useNode=retVal->_ln_Pred;
        
    while (prevNode !=0) {
        useNode=prevNode;
        prevNode=READ_LONG(memory, prevNode+4);
    }
    //useNode since only the list header can have 0 for a prevNode, the useNode must be the list header.

    retVal->_list = useNode;
        
    return retVal;
}

-(uint32_t)ln_Succ{
    _ln_Succ =READ_LONG(_memory,_address);
    return _ln_Succ;
}

-(void)setLn_Succ:(uint32_t)nextAddress{
    _ln_Succ = nextAddress;
    WRITE_LONG(_memory,_address,nextAddress);
}

-(uint32_t)ln_Pred{
    _ln_Pred = READ_LONG(_memory,_address+4);
    return _ln_Pred;
}

-(void)setLn_Pred:(uint32_t)prevAddress{
    _ln_Pred = prevAddress;
    WRITE_LONG(_memory,_address+4,prevAddress);
}

-(unsigned char)ln_Type{
    _ln_Type = READ_BYTE(_memory,_address+8);
    return _ln_Type;
}

-(void)setln_Type:(unsigned char)type{
    _ln_Type = type;
    WRITE_BYTE(_memory,_address+8,type);
}

-(char)ln_Priority{
    _ln_Priority =  READ_BYTE(_memory,_address+9);
    return _ln_Priority;
}

-(void)setLn_Priority:(char)priority{
    _ln_Priority = priority;
    WRITE_BYTE(_memory,_address+9,priority);
}

-(uint32_t)ln_Name{
    _ln_Name = READ_LONG(_memory,_address+10);
    return _ln_Name;
}

-(void)setLn_Name:(uint32_t)nameAddress{
    _ln_Name = nameAddress;
    WRITE_LONG(_memory,_address+10,nameAddress);
}

-(uint32_t)listPtr{
    //track back through the list until we find the list header.
    uint32_t prevNode=_ln_Pred;
    uint32_t useNode=_ln_Pred;
    
    while (prevNode !=0) {
        useNode=prevNode;
        prevNode=READ_LONG(_memory, prevNode+4);
    }
    //useNode since only the list header can have 0 for a prevNode, the useNode must be the list header.
    
    _list = useNode;
    return _list;
}

@end
