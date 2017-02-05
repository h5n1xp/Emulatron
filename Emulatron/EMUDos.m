//
//  EMUDos.m
//  Emulatron
//
//  Created by Matt Parsons on 04/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUDos.h"

@implementation EMUDos


-(void)setupLibNode{
    
    WRITE_LONG(_emulatorMemory, self.base, self.base+20);       // <- Pointer to libnode structure
    WRITE_BYTE(_emulatorMemory, self.base+4, 0);                // flags... wherever they are...
    WRITE_BYTE(_emulatorMemory, self.base+5, 0);                // padding... does nothing
    WRITE_WORD(_emulatorMemory, self.base+6, 1024);             // Neg size, is this suposed to be signed? size of jump table in bytes
    WRITE_WORD(_emulatorMemory, self.base+8, 32+12+24);         // Pos size, size of data area in bytes
    WRITE_LONG(_emulatorMemory, self.base+10, self.base+32+12); // pointer to an ID string
    WRITE_LONG(_emulatorMemory, self.base+14, 0);               // checksum... not used right now
    WRITE_WORD(_emulatorMemory, self.base+18, 0);               // Open count... I'm always going to start at 0 :)
    
    //Data area starts as libBase + 20.. first thing here is the libnode structure :-)
    WRITE_LONG(_emulatorMemory, self.base+20, 0);               // <- set the next node to 0
    WRITE_LONG(_emulatorMemory, self.base+24, 0x5FFFFC);        // <- set the previous node to be the exec.library
    WRITE_LONG(_emulatorMemory, self.base+28, self.base+32);    // pointer to the library name string
    
    //Put the strings in the data area, libBase + 32
    uint32_t pointer=self.base+32;
    char* name     = "dos.library";
    
    for(int i=0;i<12;++i){
        WRITE_BYTE(_emulatorMemory, pointer, name[i]);
        pointer++;
    }
    
    char* IdString = "dos 31.34 (04 Feb 2017)";
    for(int i=0;i<24;++i){
        WRITE_BYTE(_emulatorMemory, pointer, IdString[i]);
        pointer++;
    }
}


-(void)callFunction:(NSInteger)lvo{
    
    printf("Calling function: %d from dos.library\n",(int)lvo);
    
    switch(lvo){
        case   6:[self open];break;
        case  12:[self close];break;
        case  18:[self expunge];break;
        case  22:[self reserved];break;
        case 132:[self ioError];break;
        case 474:[self printFault];break;
        case 642:[self setIoErr];break;
        case 798:[self readArgs];break;
        case 858:[self freeArgs];break;
        default:[self unimplemented:lvo];break;
    }
    
}

-(void)ioError{
    m68k_set_reg(M68K_REG_D0, 0);    // return 0, since I have no idea what has failed :-)
}

-(void)printFault{
    uint32_t code   = m68k_get_reg(NULL, M68K_REG_D0);
    uint32_t headerPtr = m68k_get_reg(NULL, M68K_REG_D1);
    
    unsigned char* header = &_emulatorMemory[headerPtr];
    
    printf("AmigaDOS: errorcode - %d, text:%s\n",code,header);
    return;
}

-(void)setIoErr{
    
}

-(void)readArgs{
    
    uint32_t template = m68k_get_reg(NULL, M68K_REG_D0);
    uint32_t array = m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t args = m68k_get_reg(NULL, M68K_REG_D2);
    
    //Don't know how to service this so put 0 for failure
    m68k_set_reg(M68K_REG_D0, 0);
    return;
}

-(void)freeArgs{
    
}
@end
