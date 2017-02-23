//
//  EMUexecNode.m
//  Emulatron
//
//  Created by Matt Parsons on 23/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecNode.h"
#include "endianMacros.h"
extern unsigned char* _emulatorMemory;   //Nasty global variable

@implementation EMUexecNode

+(EMUexecNode*)nodeAtAddress:(uint32_t)nodeAddress{
    EMUexecNode* retVal = [[super alloc] init];
    
    retVal.address   = nodeAddress;
    retVal->_next    = READ_LONG(_emulatorMemory, nodeAddress);
    retVal->_prev    = READ_LONG(_emulatorMemory, nodeAddress+4);
    retVal->_type    = READ_BYTE(_emulatorMemory, nodeAddress+8);
    retVal->_priority= READ_BYTE(_emulatorMemory, nodeAddress+9);
    retVal->_name    = READ_LONG(_emulatorMemory, nodeAddress+10);
    retVal->_nodeName = &_emulatorMemory[retVal->_name];
    
    //track back through the list until we find the list header.
    uint32_t prevNode=retVal->_prev;
    uint32_t useNode=retVal->_prev;
        
    while (prevNode !=0) {
        useNode=prevNode;
        prevNode=READ_LONG(_emulatorMemory, prevNode+4);
    }
    //useNode since only the list header can have 0 for a prevNode, the useNode must be the list header.

    retVal->_list = useNode;
        
    return retVal;
}

-(uint32_t)next{
    return READ_LONG(_emulatorMemory,self.address);
}

-(void)setNext:(uint32_t)nextAddress{
    _next = nextAddress;
    WRITE_LONG(_emulatorMemory,self.address,nextAddress);
}

-(uint32_t)prev{
    return READ_LONG(_emulatorMemory,self.address+4);
}

-(void)setPrev:(uint32_t)prevAddress{
    _prev = prevAddress;
    WRITE_LONG(_emulatorMemory,self.address+4,prevAddress);
}

-(unsigned char)type{
    return READ_BYTE(_emulatorMemory,self.address+8);
}

-(void)setType:(unsigned char)type{
    _type = type;
    WRITE_BYTE(_emulatorMemory,self.address+8,type);
}

-(char)priority{
    return READ_BYTE(_emulatorMemory,self.address+9);
}

-(void)setPriority:(char)priority{
    _priority = priority;
    WRITE_BYTE(_emulatorMemory,self.address+9,priority);
}

-(uint32_t)name{
    return READ_LONG(_emulatorMemory,self.address+10);
}

-(void)setName:(uint32_t)nameAddress{
    _name = nameAddress;
    WRITE_LONG(_emulatorMemory,self.address+10,nameAddress);
}

@end
