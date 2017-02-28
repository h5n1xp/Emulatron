//
//  EMUdosProcess.m
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUdosProcess.h"

@implementation EMUdosProcess


-(uint32_t)pr_MsgPortPtr{
    _pr_MsgPort = self.address+92;
    return _pr_MsgPort;
}

-(uint32_t)pr_SegList{
    _pr_SegList = READ_LONG(_memory,self.address+128);
    return _pr_SegList;
}
-(void)setPr_SegList:(uint32_t)value{
    _pr_SegList = value;
    WRITE_LONG(_memory,self.address+128,value);
}

-(uint32_t)pr_StackSize{
    _pr_StackSize = READ_LONG(_memory,self.address+132);
    return _pr_StackSize;
}
-(void)setPr_StackSize:(uint32_t)value{
    _pr_StackSize = value;
    WRITE_LONG(_memory,self.address+132,value);
}

-(uint32_t)pr_StackBase{
    _pr_StackBase = READ_LONG(_memory,self.address+132);
    return _pr_StackBase;
}
-(void)setPr_StackBase:(uint32_t)value{
    _pr_StackBase = value;
    WRITE_LONG(_memory,self.address+132,value);
}


@end
