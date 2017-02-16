//
//  EMUExec.m
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUExec.h"
#import "EMUMemoryBlock.h"
#import "EMULibrary.h"

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

    self.libVersion  = 31; // for now... i don't actaully check it... so doesn't really matter
    self.libRevision = 34; // as above
    self.libOpenCount= 1;  // always a minimum of one for this library
    
    uint32_t namePtr = self.libData;    //locate the data space
    uint32_t libIDPtr = namePtr + [self writeString:"exec.library" toAddress:namePtr]; //write the name string there and generate the next free address
    self.libName = namePtr; //write the address of the string to the libNode
    
    [self writeString:"exec 31.34 (23 Nov 1985) <--using old exec 1.2 ID string for now" toAddress:libIDPtr]; //write the ID string to the data area
    self.libID = libIDPtr;  //write the address of the ID String to the lib structure.
    
    //char* _mem = &_emulatorMemory[self.base];
    
    //set up the memory lists
    // All memory is managed outside of the actual 68k...
    //chipram, starts at 1024, and ends at 2097150. so the free chipram is top address - bottom address;
    self.busyChipList = [[NSMutableArray alloc] init];
    self.freeChipList = [[NSMutableArray alloc] init];
    EMUMemoryBlock* freeChipBlock =[[EMUMemoryBlock alloc]initWithSize:(2097150 - 1024) atAddress:1024];
    freeChipBlock.physicalAddress = &_emulatorMemory[1024];
    freeChipBlock.attributes = MEMF_CHIP;
    [self.freeChipList addObject:freeChipBlock];
    
    //fastram starts at 2097152, and ends at 10485758
    self.busyFastList = [[NSMutableArray alloc] init];
    self.freeFastList = [[NSMutableArray alloc] init];
    EMUMemoryBlock* freeFastBlock =[[EMUMemoryBlock alloc]initWithSize:(10485758 - 2097152) atAddress:2097152];
    freeFastBlock.physicalAddress = &_emulatorMemory[2097152];
    freeFastBlock.attributes = MEMF_FAST;
    [self.freeFastList addObject:freeFastBlock];
    
    
    //setup Library list header
    WRITE_LONG(_emulatorMemory, self.base+378, self.base); //The Next, which is also the first library is exec.library :)
    WRITE_LONG(_emulatorMemory, self.base+382, 0);         //List headers always have a no tail.
    WRITE_LONG(_emulatorMemory, self.base+386, self.base); //Same as the first.
    WRITE_BYTE(_emulatorMemory, self.base+390, 9);         //List type is a Library list.
    WRITE_BYTE(_emulatorMemory, self.base+391, 0);         //Makes sure the padding byte is clear... I might need to use that as a flag later
    
    //Set up Supervisor Stack
    uint32_t ssp = [self allocMem:16384 with:MEMF_FAST];    //16kb in the Fastram should be fine.
    WRITE_LONG(_emulatorMemory, self.base+58, ssp);
    ssp +=16380;                                            //Move pointer to top of allocated memory
    WRITE_LONG(_emulatorMemory, self.base+54, ssp);
    m68k_set_reg(M68K_REG_SP, ssp);
    
    
    return;
}

-(void)addlibrary:(id)library{
    
    EMULibrary* newLib = library;
    
    //Use the proper list functions now we have them...
    
    [self addTail:newLib.base toList:self.base+378];
    
    return;
    
    /* Pre List function code... can be deleted
    //Scan the libnodes
    
    uint32_t nextLibNode = self.base;
    uint32_t lastLibnode = 0;
    
    while(nextLibNode !=0){
        lastLibnode = nextLibNode;
        nextLibNode = READ_LONG(_emulatorMemory, nextLibNode);
        
    }
    
    [self instanceAtNode:lastLibnode].nextLib     = newLib.base;
    [self instanceAtNode:newLib.base].previousLib = lastLibnode;

    //char* _execmem = &_emulatorMemory[self.base];
    //char* _dosmem = &_emulatorMemory[newLib.base];

    return;
     */
}

-(uint32_t)thisTask{
    return READ_LONG(_emulatorMemory, self.base+276);
}
-(void)setThisTask:(uint32_t)address{
    WRITE_LONG(_emulatorMemory, self.base+276, address);
}



-(void)callFunction:(NSInteger)lvo{
    
    switch(lvo){
        case   6:[self open];break;
        case  12:[self close];break;
        case  18:[self expunge];break;
        case  24:[self reserved];break;
        case 132:[self forbid];break;
        case 138:[self permit];break;
        case 180:[self cause];break;
        case 198:[self allocMem];break;
        case 210:[self freeMem];break;
        case 216:[self availMem];break;
        case 234:[self insert];break;
        case 240:[self addHead];break;
        case 246:[self addTail];break;
        case 252:[self remove];break;
        case 258:[self remHead];break;
        case 264:[self remTail];break;
        case 270:[self enqueue];break;
        case 276:[self findName];break;
        case 294:[self findTask];break;
        case 306:[self setSignal];break;
        case 372:[self getMsg];break;
        case 378:[self replyMsg];break;
        case 384:[self waitPort];break;
        case 408:[self oldOpenLibrary];break;
        case 414:[self closeLibrary];break;
        case 420:[self setFunction];break;
        case 552:[self openLibrary];break;
        case 684:[self allocVec];break;
        case 690:[self freeVec];break;
        default:[self unimplemented:lvo];break;
    }
    
}

//Obj-C interface  *******************************************************************
-(uint32_t)allocMem:(uint32_t)byteSize with:(uint32_t)requirements{
    printf("AllocMem: %d bytes, of type: %d... ",byteSize,requirements);
    
    byteSize +=4;               // add on 4 bytes so that this always rounds to a multiple of 4.
    byteSize = byteSize >> 2;   // the shifts basiclly round this to a multiple of 4.
    byteSize = byteSize << 2;
    
    NSMutableArray* memlist  = self.freeFastList;
    NSMutableArray* busylist = self.busyFastList;
    
    //choose which list we need to use chip ram...
    if((requirements & MEMF_CHIP) == MEMF_CHIP){
        memlist  = self.freeChipList;
        busylist = self.busyChipList;
    }
    
    EMUMemoryBlock* useBlock     = nil;
    uint32_t useBlockSize        = 4294967295;// initilise it with a stupidly large value
    EMUMemoryBlock* currentBlock = [memlist objectAtIndex:0];
    uint32_t currentBlockSize    = 0;
    NSInteger index              = 0;
    NSInteger memListSize        = memlist.count;
    
    while(currentBlock != nil){
        
        currentBlockSize = currentBlock.size;
        
        if(currentBlockSize == byteSize){

            [busylist addObject:currentBlock];  //Swap from free list to busy list.
            [memlist removeObject:currentBlock];
    
            return currentBlock.address;
        }
        
        if( (currentBlock.size>byteSize) && (currentBlockSize < useBlockSize) ){
            useBlock     = currentBlock;
            useBlockSize = currentBlockSize;
        }
        
        index = index + 1;
        if(index<memListSize){
            currentBlock = [memlist objectAtIndex:index];
        }else{
            currentBlock=nil;
        }
    }
    
    if(useBlock==nil){
        return 0;
    }
    
    useBlock.size   = useBlockSize - byteSize;
    uint32_t newBlockAddress = useBlock.address+(useBlockSize-byteSize);
    
    EMUMemoryBlock* newBlock = [[EMUMemoryBlock alloc] initWithSize:byteSize atAddress:newBlockAddress];
    newBlock.physicalAddress = &_emulatorMemory[newBlockAddress];
    newBlock.attributes = requirements;
    
    [busylist addObject:newBlock];
    
    printf("Allocated %d bytes at %d\n",byteSize,newBlockAddress);
    
    //need to 0 the block? Slow but does the job.
    if((requirements & MEMF_CLEAR) == MEMF_CLEAR){
        unsigned char* newBlockPtr =newBlock.physicalAddress;
        
        for(int i=0;i<byteSize;++i){
            newBlockPtr[i]=0;
        }
    }
    
    return newBlockAddress;
}


-(void)freeMem:(uint32_t)memoryBlock{
    
    NSMutableArray* memlist  = self.freeFastList;
    NSMutableArray* busylist = self.busyFastList;
    
    //choose which list we want to use, if we need to scan the chiplist.
    if(memoryBlock<2097152){
        memlist  = self.freeChipList;
        busylist = self.busyChipList;
    }
    
    //We need to scan the busy list to find the allocated object...
    EMUMemoryBlock* currentBlock=[busylist objectAtIndex:0];
    int index=0;
    
    while(currentBlock.address !=memoryBlock){
        index +=1;
        currentBlock =[busylist objectAtIndex:index];
    }
    
    printf("freeMem: %d bytes at %d\n",currentBlock.size,memoryBlock);
    
    [memlist  addObject:currentBlock];  //Swap from busy list to free list.
    [busylist removeObject:currentBlock];

}

-(void)closeLibrary:(uint32_t)libNode{
    
    if(libNode==0){
        return;
    }
    
    [[self instanceAtNode:libNode] close];
    printf("Close Library: %s\n",[self instanceAtNode:libNode].libNameString);
}

-(uint32_t)openLibrary:(const char*)libName of:(uint32_t)version{
    
    //Use the proper list functions now we have them... also this function should scan the libs: dir if this returns 0.
    printf("Open Library: %s (version v%d)\n",libName,version);
    return [self findName:libName inList:self.base+378];
    
    
    /* Prelist functions code... can be deleted
    //scan the libnodes for the library
    uint32_t nextLibNode = self.base;
    uint32_t currentLibNode = 0;
    
    while(nextLibNode !=0){
        currentLibNode = nextLibNode;
        
        const char* libNodeName=[self instanceAtNode:currentLibNode].libNameString;
        
        if(strcmp(libName, libNodeName)==0){
            [[self instanceAtNode:currentLibNode] open];
            break;
        }
        
        nextLibNode = READ_LONG(_emulatorMemory, nextLibNode);
        
    }
    
    //will return 0 if not found... only in memory libs for now...
    
    return nextLibNode;
     */
}



/*
 Insert(list,node,pred)(a0/a1/a2)
 AddHead(list,node)(a0/a1)
 */

-(void)addTail:(uint32_t)node toList:(uint32_t)list{
    
    uint32_t tailNode = READ_LONG(_emulatorMemory,list+8);
    
    char* name =&_emulatorMemory[READ_LONG(_emulatorMemory, node+10)];
    
    WRITE_LONG(_emulatorMemory, tailNode, node);    //Add this node to the last node.
    WRITE_LONG(_emulatorMemory, node+4, tailNode);  //Set the previous node to the old tail.
    WRITE_LONG(_emulatorMemory, list+8, node);      //Set the list tail to the new node.
    
    return;
}
 /*
 Remove(node)(a1)
 RemHead(list)(a0)
 RemTail(list)(a0)
 Enqueue(list,node)(a0/a1)
 
 */



-(uint32_t)findName:(const char*)name inList:(uint32_t)listPtr{
    //note the parameters are the opposite way around to exec.library
    
    printf("Find name: %s in list %x\n",name,listPtr);
    
    //scan the libnodes for the library
    uint32_t nextNode = READ_LONG(_emulatorMemory,listPtr);
    uint32_t currentNode = nextNode;
    
    while(currentNode !=0){

        
        const char* nodeName=(const char*)&_emulatorMemory[READ_LONG(_emulatorMemory, currentNode+10)];
        
        if(strcmp(name, nodeName)==0){
            break;
        }
        
        currentNode = READ_LONG(_emulatorMemory,currentNode);
        
    }
    
    //will return 0 if not found... only in memory libs for now...
    
    return currentNode;
    
}




// 68k Interface *******************************************************************
-(void)forbid{
    printf("Forbid\n");
}

-(void)permit{
    printf("Permit\n");
}

-(void)cause{
    printf("Interupts not enabled yet\n");
}

-(void)allocMem{
    uint32_t byteSize       = m68k_get_reg(NULL, M68K_REG_D0);
    uint32_t requirements   = m68k_get_reg(NULL, M68K_REG_D1);
    
    m68k_set_reg(M68K_REG_D0,[self allocMem:byteSize with:requirements]);
    
    return;
}

-(void)freeMem{
    uint32_t memoryBlock = m68k_get_reg(NULL, M68K_REG_A1);
    uint32_t byteSize    = m68k_get_reg(NULL, M68K_REG_D0); //This is not needed as we keep track of allocations
    
    [self freeMem:memoryBlock];
 }

-(void)availMem{
    uint32_t D1 = m68k_get_reg(NULL, M68K_REG_D1);
    
    if( (D1 & MEMF_CHIP) == MEMF_CHIP){
        
        m68k_set_reg(M68K_REG_D0, 2097152); //just return all the Chipram... can't be bothered to scan the free list
    }else{
         m68k_set_reg(M68K_REG_D0, 10485758 - 2097152); //just return all the Fastram... can't be bothered to scan the free list
    }
    
    return;
}


-(void)insert{
    //(list,node,pred)(a0/a1/a2)
    return;
}
-(void)addHead{
    //(list,node)(a0/a1)
    return;
}
-(void)addTail{
    //(list,node)(a0/a1)
    uint32_t A0 = m68k_get_reg(NULL, M68K_REG_A0);
    uint32_t A1 = m68k_get_reg(NULL, M68K_REG_A1);
    
    [self addTail:A1 toList:A0];
    
    return;
}
-(void)remove{
    //(node)(a1)
    return;
}
-(void)remHead{
    //(list)(a0)
    return;
}
-(void)remTail{
    //(list)(a0)
    return;
}
-(void)enqueue{
    //(list,node)(a0/a1)
    return;
}


-(void)findName{
    uint32_t A0 = m68k_get_reg(NULL, M68K_REG_A0);
    uint32_t A1 = m68k_get_reg(NULL, M68K_REG_A1);
    const char* name =(const char*) &_emulatorMemory[A1];
    
    uint32_t D0 = [self findName:name inList:A0];
    
    m68k_set_reg(M68K_REG_D0, D0);
    char* mem = &_emulatorMemory[0x9f2c92];
    
    return;
}

-(void)findTask{
    printf("Find Task: ");
    uint32_t A1 =m68k_get_reg(NULL, M68K_REG_A1);
    
    if(A1==0){
        printf("This Task :)\n");
        m68k_set_reg(M68K_REG_D0, self.thisTask);
        return;
    }
    
    unsigned char*    taskName = &_emulatorMemory[A1];

    printf("Find Task: %s\n",taskName);
    return;
}

-(void)setSignal{
    printf("SetSignal... not implemented\n");
}

-(void)getMsg{
    uint32_t A0 = m68k_get_reg(NULL, M68K_REG_A0);
    char* portName = &_emulatorMemory[A0];
    printf("getMessage... not implemented\n");
    return;
}

-(void)replyMsg{
    printf("reply message... not implemented\n");
}

-(void)waitPort{
    uint32_t A0 = m68k_get_reg(NULL, M68K_REG_A0);
    char* portName = &_emulatorMemory[A0];
    printf("waitPort... not implemented\n");
    return;
}

-(void)oldOpenLibrary{
    //uint32 D0 = m68k_get_reg(NULL, M68K_REG_D0;)
    m68k_set_reg(M68K_REG_D0, 0);   // clear the D0 reg
    [self openLibrary];
}

-(void)closeLibrary{
    uint32_t libNode = m68k_get_reg(NULL,M68K_REG_A1);
    
    [self closeLibrary:libNode];

}

-(void)setFunction{
    
    //uint32_t library =m68k_get_reg(NULL, M68K_REG_A1);
    //uint32_t funcOffset =m68k_get_reg(NULL, M68K_REG_A0);
    //uint32_t newFunction =m68k_get_reg(NULL, M68K_REG_A1);
    
    printf("SetFunction\n");
    // this will probably work!
}



-(void)openLibrary{

    const char* libName =(const char*) &_emulatorMemory[m68k_get_reg(NULL, M68K_REG_A1)];
    uint32_t version = m68k_get_reg(NULL, M68K_REG_D0);
    
    m68k_set_reg(M68K_REG_D0,[self openLibrary:libName of:version]);
    
    return;
}

-(void)allocVec{
    //my allocmem does keep track of memory blocks, so AllocVec isn't needed anymore
    [self allocMem];
}

-(void)freeVec{
    [self freeMem];
}

@end
