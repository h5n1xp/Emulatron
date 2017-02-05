//
//  EMUExec.m
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUExec.h"

#define MEMF_ANY        0           // Any type of memory will do
#define MEMF_PUBLIC     1
#define MEMF_CHIP       2
#define MEMF_FAST       4
#define MEMF_LOCAL      256         // Memory that does not go away at RESET
#define MEMF_24BITDMA   512         // DMAable memory within 24 bits of address
#define	MEMF_KICK       1024        // Memory that can be used for KickTags
#define MEMF_CLEAR      65536       // AllocMem: NULL out area before return
#define MEMF_LARGEST    131072      // AvailMem: return the largest chunk size
#define MEMF_REVERSE    262144      // AllocMem: allocate from the top down
#define MEMF_TOTAL      524288      // AvailMem: return total size of memory
#define	MEMF_NO_EXPUNGE	2147483648  // AllocMem: Do not cause expunge on failure



@implementation EMUExec

-(void)setupLibNode{
   
    WRITE_LONG(_emulatorMemory, self.base, self.base+20);       // <- Pointer to libnode structure
    WRITE_BYTE(_emulatorMemory, self.base+4, 0);                // flags... wherever they are...
    WRITE_BYTE(_emulatorMemory, self.base+5, 0);                // padding... does nothing
    WRITE_WORD(_emulatorMemory, self.base+6, 1024);             // Neg size, is this suposed to be signed? size of jump table in bytes
    WRITE_WORD(_emulatorMemory, self.base+8, 32+13+25);         // Pos size, size of data area in bytes
    WRITE_LONG(_emulatorMemory, self.base+10, self.base+32+13); // pointer to an ID string
    WRITE_LONG(_emulatorMemory, self.base+14, 0);               // checksum... not used right now
    WRITE_WORD(_emulatorMemory, self.base+18, 1);               // Open count... I'm always going to start exec.library as 1
    
    //Data area starts as libBase + 20.. first thing here is the libnode structure :-)
    WRITE_LONG(_emulatorMemory, self.base+20, 0xF70000);    // <- set the next node to be the dos.library...
    WRITE_LONG(_emulatorMemory, self.base+24, 0);           // <- set the previous node to be 0
    WRITE_LONG(_emulatorMemory, self.base+28, self.base+32);// pointer to the library name string
    
    //Put the strings in the data area, libBase + 32
    uint32_t pointer=self.base+32;
    char* name     = "exec.library";

    for(int i=0;i<13;++i){
        WRITE_BYTE(_emulatorMemory, pointer, name[i]);
        pointer++;
    }
    
    char* IdString = "exec 31.34 (23 Nov 1985)";
    for(int i=0;i<25;++i){
        WRITE_BYTE(_emulatorMemory, pointer, IdString[i]);
        pointer++;
    }
    
    //set up the memory lists
    // All memory exisits in the emualtion ram as a long word size variable followed by the free bytes
    //chipram, starts at 1024, and ends at 2097152. so the free chipram is top address - bottom address;
    //the entry point is 4 bytes into the memory block.
    WRITE_LONG(_emulatorMemory, 1024, 2097152-1024);
    self.freeChipList = [[NSMutableArray alloc] init];
    [self.freeChipList addObject:[NSNumber numberWithInt:1024]];
    
    //Now the fast ram list, hold it 4 bytes above the actual fastram base.
    WRITE_LONG(_emulatorMemory, 2097156, 10485760 - 2097156);
    self.freeFastList = [[NSMutableArray alloc] init];
    [self.freeFastList addObject:[NSNumber numberWithInt:2097156]];
}


-(void)callFunction:(NSInteger)lvo{
    
    switch(lvo){
        case   6:[self open];break;
        case  12:[self close];break;
        case  18:[self expunge];break;
        case  22:[self reserved];break;
        case 180:[self cause];break;
        case 198:[self allocMem];break;
        case 210:[self freeMem];break;
        case 294:[self findTask];break;
        case 306:[self setSignal];break;
        case 414:[self closeLibrary];break;
        case 552:[self openLibrary];break;
        case 684:[self allocVec];break;
        case 690:[self freeVec];break;
        default:[self unimplemented:lvo];break;
    }
    
}



-(void)cause{
    printf("Interupts not enabled yet\n");
}

-(void)allocMem{
    uint32_t byteSize       = m68k_get_reg(NULL, M68K_REG_D0);
    uint32_t requirements   = m68k_get_reg(NULL, M68K_REG_D1);
    printf("AllocMem: %d bytes, of type: %d... ",byteSize,requirements);
    
    byteSize +=8;               // add on 4 bytes to store the size value, and another 4byte so that this always rounds to a multiple of 4.
    byteSize = byteSize >> 2;   // the shifts basiclly round this to a multiple of 4.
    byteSize = byteSize << 2;
    
    NSMutableArray* memlist=nil;
    
    //choose which list we want to use.
    if((requirements & MEMF_CHIP) == MEMF_CHIP){
        memlist = self.freeChipList;
    }else{
        memlist=self.freeFastList;
    }
    
    NSNumber* block=[memlist objectAtIndex:0];
    NSInteger index =0;
    uint32_t goodBlockAddress=0;
    uint32_t goodBlockSize=4294967295;// initilise it with a stupidly large value
    NSInteger goodblockIndex = 0;
    
    
    while(block !=nil){
        
        uint32_t address = (uint32_t) [block integerValue];
        uint32_t size = READ_LONG(_emulatorMemory, address);
        
        //if the freeblock is the correct size... just use it.
        if(size == byteSize){
            goodBlockAddress = address;
            goodBlockSize    = size;
            goodblockIndex   = index;
            break;
        }
        
        //this block is big enough and smaller than the last big enough block... so it becomes the new good block
        if((size > byteSize) && (size<goodBlockSize)){
            goodBlockAddress = address;
            goodBlockSize = size;
            goodblockIndex   = index;
        }
        
        index +=1;
        if(index >= memlist.count){
            block=nil;
        }else{
            block=[memlist objectAtIndex:index];
        }
    };
    
    if(goodBlockAddress==0){
        printf("Not enough free memory\n");
        m68k_set_reg(M68K_REG_D0, 0);
        return;
    }
    
    if(goodBlockSize==byteSize){
        //nothing more to do!
        m68k_set_reg(M68K_REG_D0, goodBlockAddress+4); //the calling program doens't need to know the size pointer before the data block
        [memlist removeObjectAtIndex:goodblockIndex];
    }
    
    
    if(goodBlockSize>byteSize){
        //now we need to split the memory block....
        uint32_t freeblockSize = goodBlockSize-byteSize;
        
        if(freeblockSize < 8){
            //the new free block is going to be smaller than 8 bytes, don't bother
            m68k_set_reg(M68K_REG_D0, goodBlockAddress+4);
            [memlist removeObjectAtIndex:goodblockIndex];
        }
        

        WRITE_LONG(_emulatorMemory, goodBlockAddress, freeblockSize); // the old memory block is now shrunk by the required block size.
        
        uint32_t allocBlockAddress = goodBlockAddress + freeblockSize;
        WRITE_LONG(_emulatorMemory, allocBlockAddress, byteSize);
        m68k_set_reg(M68K_REG_D0, allocBlockAddress+4);
        
        char* mem = &_emulatorMemory[allocBlockAddress];
        printf("Allocated %d bytes at %d\n",byteSize,allocBlockAddress+4);
    }


}

-(void)freeMem{
    uint32_t memoryBlock = m68k_get_reg(NULL, M68K_REG_A1) - 4;
    uint32_t byteSize    = m68k_get_reg(NULL, M68K_REG_D0); //but this is not needed as we keep track of allocations
    
    //just in case something has walked allover our memory tracking system clean it up.
    byteSize +=8;               // add on 4 bytes to store the size value, and another 4byte so that this always rounds to a multiple of 4.
    byteSize = byteSize >> 2;   // the shifts basiclly round this to a multiple of 4.
    byteSize = byteSize << 2;
    
    printf("freeMem: %d bytes at %d\n",byteSize,memoryBlock);
    
    WRITE_LONG(_emulatorMemory, memoryBlock, byteSize);
    

    //if the memory block is under the 2meg limit... it's chip ram.
    if(memoryBlock<2097152){
        [self.freeChipList addObject:[NSNumber numberWithInt:memoryBlock]];
    }else{
        [self.freeFastList addObject:[NSNumber numberWithInt:memoryBlock]];
    }
    
    char* mem = &_emulatorMemory[memoryBlock];
    printf("");
}

-(void)findTask{
    uint32_t              A0 = m68k_get_reg(NULL, M68K_REG_A0);
    unsigned char*    taskName = &_emulatorMemory[m68k_get_reg(NULL, M68K_REG_A0)];

    printf("Find Task: %s\n",taskName);
    return;
}

-(void)setSignal{
    printf("SetSignal... not implemented\n");
}

-(void)closeLibrary{
    uint32_t libNodePtr = m68k_get_reg(NULL,M68K_REG_A1);
    uint32_t libNode =READ_LONG(_emulatorMemory, libNodePtr);
    unsigned char* libNodeName =  &_emulatorMemory[READ_LONG(_emulatorMemory, libNode+8)];
    printf("Close Library: %s\n",libNodeName);
    
    uint32_t opncnt = READ_LONG(_emulatorMemory, libNodePtr+18);
    opncnt -=1;
    WRITE_LONG(_emulatorMemory, libNodePtr+18, opncnt);
    
    return;
}

-(void)openLibrary{

    unsigned char*    libName = &_emulatorMemory[m68k_get_reg(NULL, M68K_REG_A1)]; //adding 2 bytes... not sure why...
    uint32_t version = m68k_get_reg(NULL, M68K_REG_D0);
    printf("Open Library: %s (version v%d)\n",libName,version);
    
    //scan the libnodes for the library
    uint32_t libNodePtr=self.base;
    uint32_t libNode =READ_LONG(_emulatorMemory, libNodePtr);
    
    while(libNodePtr !=0){
       unsigned char* libNodeName =  &_emulatorMemory[READ_LONG(_emulatorMemory, libNode+8)];
        
        if(strcmp(libName, libNodeName)==0){
            //Don't care about version number...
            uint32_t opncnt = READ_LONG(_emulatorMemory, libNodePtr+18);
            opncnt +=1;
            WRITE_LONG(_emulatorMemory, libNodePtr+18, opncnt);
            
            break;
        }
        
        libNodePtr = READ_LONG(_emulatorMemory, libNode);
        libNode = READ_LONG(_emulatorMemory, libNodePtr);
    }
    
    //will return 0 if not found... only in memory libs for now...
    
    m68k_set_reg(M68K_REG_D0, libNodePtr);
    return;
}

-(void)allocVec{
    printf("No Memory functions yet\n");
    m68k_set_reg(M68K_REG_D0, 0x200000);   //some randomly high memory location,,,
}

-(void)freeVec{
    //my allocmem does keep track of memory blocks, so AllocVec isn't needed
    [self allocMem];
}

@end
