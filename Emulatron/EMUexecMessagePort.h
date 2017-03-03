//
//  EMUexecMessagePort.h
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecNode.h"

@interface EMUexecMessagePort : EMUexecNode{
    
    unsigned char _mp_Flags;
    unsigned char _mp_SigBit;
    uint32_t      _mp_SigTask;
    uint32_t      _mp_MsgListPtr;
    
}


-(unsigned char)mp_Flags;
-(void)setMp_Flags:(unsigned char)value;

-(unsigned char)mp_SigBit;
-(void)setMp_SigBit:(unsigned char)value;

-(uint32_t)mp_SigTask;
-(void)setMp_SigTask:(uint32_t)value;

-(uint32_t)mp_MsgListPtr;

@end
