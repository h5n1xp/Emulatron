//
//  EMULibrary.m
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMULibrary.h"

@implementation EMULibrary

-(instancetype)initAtAddress:(uint32_t)address{
    self = [super init];
    self.base = address;
    return self;
}

-(void)buildJumpTableSize:(NSInteger)lvocount{
    
    uint32_t offset =self.base;
    
    WRITE_WORD(    _emulatorMemory, self.base  , 0xDEAD);
    WRITE_WORD(    _emulatorMemory, self.base-2, 0xDE0D);
    WRITE_WORD(    _emulatorMemory, self.base-4, 0xDE1D);
    
    for(NSInteger i=1;i<lvocount;++i){
        offset = offset - 6;
        WRITE_WORD(    _emulatorMemory, offset  , 0x4E70);   //CALL Function
        WRITE_WORD(    _emulatorMemory, offset-2, 0x4E75);   //RTS return from function call
        *((uint16_t*) &_emulatorMemory[ offset-4]) = i*6;      //Load the thrid word with LVO value;
        //printf("address:%X value:%d\n",offset,(int)i*6);
    }
    
    [self setupLibNode];
}

-(void)setupLibNode{
    
}

-(NSInteger)totalLibraryVectorOffsets{
    return 1024;                        //change this value to reflect the actual number of LVOs in the library.
}

-(void)callFunction:(NSInteger)lvo{
    
    switch(lvo){
        case  6:[self open];break;
        case 12:[self close];break;
        case 18:[self expunge];break;
        case 22:[self reserved];break;
        default:[self unimplemented:lvo];break;
    }
    
}

-(void)open{
    uint32_t openCount = READ_LONG(_emulatorMemory, self.base+4);
    openCount = openCount + 1;
    WRITE_LONG(_emulatorMemory, self.base, openCount);
}

-(void)close{
    
}

-(void)expunge{
    
}

-(void)reserved{
    
    printf("Lib Address:%X reserved function called!\n",m68k_get_reg(NULL, M68K_REG_A6));
    
}

-(void)unimplemented:(NSUInteger)lvo{
    printf("Lib Address:%X unimplmented function at LVO %d called!\n",m68k_get_reg(NULL, M68K_REG_A6),(int)lvo);
    printf("");
}

@end
