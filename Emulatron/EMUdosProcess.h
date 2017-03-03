//
//  EMUdosProcess.h
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecTask.h"

@interface EMUdosProcess : EMUexecTask{
    
    uint32_t _pr_MsgPort;
    uint32_t _pr_SegList;
    uint32_t _pr_StackSize;
    uint32_t _pr_StackBase;
}


-(uint32_t)pr_MsgPortPtr;

-(uint32_t)pr_SegList;
-(void)setPr_SegList:(uint32_t)value;

-(uint32_t)pr_StackSize;
-(void)setPr_StackSize:(uint32_t)value;

-(uint32_t)pr_StackBase;
-(void)setPr_StackBase:(uint32_t)value;


@end
