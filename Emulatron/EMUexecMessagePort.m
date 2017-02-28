//
//  EMUexecMessagePort.m
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecMessagePort.h"

@implementation EMUexecMessagePort


-(unsigned char)mp_Flags{
    _mp_Flags = READ_BYTE(_memory,self.address+14);
    return _mp_Flags;
}
-(void)setMp_Flags:(unsigned char)value{
    _mp_Flags=value;
    WRITE_BYTE(_memory,self.address+14,value);
}

-(unsigned char)mp_SigBit{
    _mp_SigBit = READ_BYTE(_memory,self.address+15);
    return _mp_SigBit;
}
-(void)setMp_SigBit:(unsigned char)value{
    _mp_SigBit=value;
    WRITE_BYTE(_memory, self.address+15, value);
}

-(uint32_t)mp_SigTask{
    _mp_SigTask = READ_LONG(_memory,self.address+16);
    return _mp_SigTask;
}
-(void)setMp_SigTask:(uint32_t)value{
    _mp_SigTask=value;
    WRITE_LONG(_memory, self.address+16, value);
}

-(uint32_t)mp_MsgListPtr{
    _mp_MsgListPtr = self.address+20;
    return _mp_MsgListPtr;
}


@end
