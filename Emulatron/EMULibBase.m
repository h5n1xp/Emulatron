//
//  EMULibBase.m
//  Emulatron
//
//  Created by Matt Parsons on 16/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMULibBase.h"

@implementation EMULibBase

-(instancetype)initAtAddress:(uint32_t)address{
    self = [super init];
    self.base = address;
    return self;
}

-(void)buildJumpTableSize:(NSInteger)lvocount{
    
    uint32_t offset =self.base;

    for(NSInteger i=1;i<lvocount;++i){
        offset = offset - 6;
        WRITE_WORD(    _emulatorMemory, offset  , 0x4E70);   // CALL Function
        WRITE_WORD(    _emulatorMemory, offset+2, 0x4E75);   // RTS return from function call
        *((uint16_t*) &_emulatorMemory[ offset+4]) = i*6;    // Load the third word with LVO value - note little endian value;
        //printf("address:%X value:%d\n",offset,(int)i*6);
    }
    
    [self setupLibPos];
    [self getExec];     //does nothing for the libBase, but is important for EMULibrary
}

-(void)setupLibPos{
    
    //hide a 64bit pointer to this object at self.base - 2040; the very last LVO is actually this object
    //This links the 68k and obj-C interfaces.
    NSInteger* ObjLink =(NSInteger*)&_emulatorMemory[self.base-INSTANCE_ADDRESS];
    *ObjLink =(NSInteger)(__bridge void *)self;
    
    
    //first thing here is the libnode structure :-)
    WRITE_LONG(_emulatorMemory, self.base,   0);                    // <- set the next node to be 0
    WRITE_LONG(_emulatorMemory, self.base+4, 0);                    // <- set the previous node to be 0
    WRITE_WORD(_emulatorMemory, self.base+8, 9);                    // Node type - Library nodes are type 9
    WRITE_BYTE(_emulatorMemory, self.base+9, 0);                    // Node priority
    WRITE_LONG(_emulatorMemory, self.base+10, 0);                   // pointer to the library name string
    
    WRITE_BYTE(_emulatorMemory, self.base+14, 0);                   // flags... wherever they are...
    WRITE_BYTE(_emulatorMemory, self.base+15, 1);                   // was padding... but now if this is set to 1 the we know this library has an Obj-C interface.
    WRITE_WORD(_emulatorMemory, self.base+16, INSTANCE_ADDRESS+8);  // Neg size, size of jump table in bytes - default 2kb (with a pointer hiding down there)
    WRITE_WORD(_emulatorMemory, self.base+18, 2048);                // Pos size, size of data area in bytes  - default 2kb
    WRITE_WORD(_emulatorMemory, self.base+20, 0);                   // Lib version
    WRITE_WORD(_emulatorMemory, self.base+22, 0);                   // Lib revision
    WRITE_LONG(_emulatorMemory, self.base+24, 0);                   // pointer to an ID string
    WRITE_LONG(_emulatorMemory, self.base+28, 0xDEADDEAD);          // checksum... not used right now
    WRITE_WORD(_emulatorMemory, self.base+32, 0);                   // Open count... I'm always start at 0
    
    self.libData = self.base+34; //libData starts after the size of the normal lib structure.
    
    [self setupLibNode];
}

-(void)getExec{
    
}

-(void)setupLibNode{
    //Stub to be completed by the library writer
}

-(EMULibBase*)instanceAtNode:(uint32)address{
    
    if(READ_BYTE(_emulatorMemory, self.base+15)==0){
        return nil;                                     //if flag is 0, then this library has no Obj-C interface.
    }
    
    NSInteger* ObjLinkValue =(NSInteger*)&_emulatorMemory[address-INSTANCE_ADDRESS];
    void* objLink = (void*)*ObjLinkValue;
    return (__bridge id)objLink;
}

/* These functions predate the proper list handeling functions
 -(uint32_t)node{
 return self.base;
 }
 
 -(uint32_t)nextLib{
 return READ_LONG(_emulatorMemory, self.base);
 }
 -(void)setNextLib:(uint32_t)address{
 WRITE_LONG(_emulatorMemory, self.base, address);
 }
 
 -(uint32_t)previousLib{
 return READ_LONG(_emulatorMemory, self.base+4);
 }
 -(void)setPreviousLib:(uint32_t)address{
 WRITE_LONG(_emulatorMemory, self.base+4, address);
 }
 */


-(uint32_t)libName{
    return READ_LONG(_emulatorMemory, self.base+10);
}
-(void)setLibName:(uint32_t)address{
    WRITE_LONG(_emulatorMemory, self.base+10, address);
}
-(const char*)libNameString{
    return (const char*)&_emulatorMemory[READ_LONG(_emulatorMemory,self.base+10)];
}

-(uint32_t)libVersion{
    return READ_WORD(_emulatorMemory, self.base+20);
}
-(void)setLibVersion:(uint32_t)value{
    WRITE_WORD(_emulatorMemory, self.base+20, value);
}

-(uint32_t)libRevision{
    return READ_WORD(_emulatorMemory, self.base+22);
}
-(void)setLibRevision:(uint32_t)value{
    WRITE_WORD(_emulatorMemory, self.base+22, value);
}

-(uint32_t)libID{
    return self.base+24;
}
-(void)setLibID:(uint32_t)address{
    WRITE_LONG(_emulatorMemory, self.base+24,address);
}
-(const char*)libIDString{
    return (const char*)&_emulatorMemory[READ_LONG(_emulatorMemory,self.base+24)];
}

-(uint32_t)libOpenCount{
    return READ_WORD(_emulatorMemory, self.base+32);
}
-(void)setLibOpenCount:(uint32_t)value{
    WRITE_WORD(_emulatorMemory, self.base+32, value);
}

-(uint32_t)writeString:(char*)string toAddress:(uint32_t)address{
    
    uint32_t len = (uint32_t)strlen(string)+1;
    
    for(int i=0;i<len;++i){
        WRITE_BYTE(_emulatorMemory, address+i, string[i]);
    }
    
    return len;
}


-(void)callFunction:(NSInteger)lvo{
    
    switch(lvo){
        case  6:[self open];break;
        case 12:[self close];break;
        case 18:[self expunge];break;
        case 24:[self reserved];break;
        default:[self unimplemented:lvo];break;
    }
    
}

-(void)open{
    uint32_t openCount = READ_WORD(_emulatorMemory, self.base+32);
    openCount += 1;
    WRITE_WORD(_emulatorMemory, self.base+32, openCount);
}

-(void)close{
    uint32_t openCount = READ_WORD(_emulatorMemory, self.base+32);
    openCount += 1;
    WRITE_WORD(_emulatorMemory, self.base+32, openCount);
}

-(void)expunge{
    //Don't expunge... even the 4gig maximum that the emulation can support is a tiny amount of RAM
}

-(void)reserved{
    
    self.debugOutput.cout =[NSString stringWithFormat:@"Lib Address:%X reserved function called!\n",m68k_get_reg(NULL, M68K_REG_A6)];
    
}

-(void)unimplemented:(NSInteger)lvo{
    self.debugOutput.cout =[NSString stringWithFormat:@"%s unimplmented function at LVO %d called!\n",self.libNameString,(int)lvo];
}

@end
