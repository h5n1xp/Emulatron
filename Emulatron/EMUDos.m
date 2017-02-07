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
    
    self.libVersion  = 33; // for now... i don't actaully check it... so doesn't really matter
    self.libRevision = 34; // as above
    self.libOpenCount= 1;  // always a minimum of one for this library, as we alwasy need to access the drives.
    
    uint32_t namePtr = self.libData;    //locate the data space
    uint32_t libIDPtr = namePtr + [self writeString:"dos.library" toAddress:namePtr]; //write the name string there and generate the next free address
    self.libName = namePtr; //write the address of the string to the libNode
    
    [self writeString:"dos 31.34 (04 Feb 2017)" toAddress:libIDPtr]; //write the ID string to the data area
    self.libID = libIDPtr;  //write the address of the ID String to the lib structure.
    
}


-(void)callFunction:(NSInteger)lvo{
    
    printf("Calling function: %d from dos.library\n",(int)lvo);
    
    switch(lvo){
        case   6:[self open];break;
        case  12:[self close];break;
        case  18:[self expunge];break;
        case  24:[self reserved];break;
        case  84:[self lock];break;
        case  90:[self unLock];break;
        case 126:[self currentDir];break;
        case 132:[self ioError];break;
        case 474:[self printFault];break;
        case 606:[self systemTagList];break;
        case 642:[self setIoErr];break;
        case 798:[self readArgs];break;
        case 858:[self freeArgs];break;
        default:[self unimplemented:lvo];break;
    }
    
}

-(void)lock{
    
}

-(void)unLock{
    
}

-(void)currentDir{
    
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

-(void)systemTagList{
    
}

-(void)setIoErr{
    
}

-(void)readArgs{
    
    uint32_t templatePtr  = m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t arrayPtr     = m68k_get_reg(NULL, M68K_REG_D2);
    uint32_t argsPtr      = m68k_get_reg(NULL, M68K_REG_D3);
    
    char* array = &_emulatorMemory[arrayPtr];
    unsigned char* template = &_emulatorMemory[templatePtr];
    
    printf("%s",template);
    
    //Don't know how to service this so put 0 for failure
    m68k_set_reg(M68K_REG_D0, 0);
    return;
}

-(void)freeArgs{
    
}
@end
