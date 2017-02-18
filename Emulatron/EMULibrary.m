//
//  EMULibrary.m
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMULibrary.h"


@implementation EMULibrary

-(void)getExec{
    uint32_t addr = READ_LONG(_emulatorMemory, 4);
    self.execLibrary = (EMUExec*)[self instanceAtNode:addr];
    self.debugOutput = self.execLibrary.debugOutput;
    return;
}

-(void)callFunction:(NSInteger)lvo{
    
    self.execLibrary.debugOutput.cout = [NSString stringWithFormat:@"Calling %s LVO:%d - ",self.libNameString,(int)lvo];
    
    switch(lvo){
        case  6:[self open];break;
        case 12:[self close];break;
        case 18:[self expunge];break;
        case 24:[self reserved];break;
        default:[self unimplemented:lvo];break;
    }
    
    self.execLibrary.debugOutput.cout = @"\n";
}

-(void)reserved{
    
    self.execLibrary.debugOutput.cout =@"reserved function called!";
    
}

-(void)unimplemented:(NSInteger)lvo{
    self.execLibrary.debugOutput.cout =@"unimplmented";
}

@end
