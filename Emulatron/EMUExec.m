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
    
    
    /*setup Library list header functions predate working list functions
    WRITE_LONG(_emulatorMemory, self.base+378, self.base);  //The Next, which is also the first library is exec.library :)
    WRITE_LONG(_emulatorMemory, self.base+382, 0);          //List headers always have a no tail.
    WRITE_LONG(_emulatorMemory, self.base+386, self.base);  //Same as the first.
    WRITE_BYTE(_emulatorMemory, self.base+390, 9);          //List type is a Library list.
    WRITE_BYTE(_emulatorMemory, self.base+391, 0);          //Makes sure the padding byte is clear... I might need to use that as a flag later
    WRITE_LONG(_emulatorMemory, self.base+4, self.base+378);//The prevNode of the head is always the list header.
    */
    [self addHead:self.base toList:self.base+378];
    
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

-(void)saveContext{
    uint32_t stackPtr = m68k_get_reg(NULL, M68K_REG_A7);
    
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D0));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D1));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D2));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D3));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D4));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D5));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D6));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_D7));
    
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A0));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A1));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A2));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A3));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A4));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A5));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A6));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_A7));
    
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_SR));
    WRITE_LONG(_emulatorMemory,--stackPtr, m68k_get_reg(NULL, M68K_REG_PC));
    
    WRITE_LONG(_emulatorMemory,self.thisTask+54,stackPtr);
}

-(void)restoreContext{
    uint32_t stackPtr = READ_LONG(_emulatorMemory,self.thisTask+54);
    
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_PC));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_SR));
    
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A7));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A6));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A5));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A4));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A3));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A2));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A1));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_A0));

    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D7));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D6));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D5));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D4));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D3));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D2));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D1));
    WRITE_LONG(_emulatorMemory,stackPtr++, m68k_get_reg(NULL, M68K_REG_D0));
}

-(void)callFunction:(NSInteger)lvo{
    
    self.debugOutput.cout = [NSString stringWithFormat:@"Calling %s LVO:%d - ",self.libNameString,(int)lvo];
    
    switch(lvo){
        case   6:[self open];break;
        case  12:[self close];break;
        case  18:[self expunge];break;
        case  24:[self reserved];break;
        case  42:[self schedule];break;
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
        case 282:[self addTask];break;
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
    
    self.debugOutput.cout =@"\n";
    
}

//Obj-C interface  *******************************************************************
-(uint32_t)allocMem:(uint32_t)byteSize with:(uint32_t)requirements{
    self.debugOutput.cout =[NSString stringWithFormat:@"AllocMem: %d bytes, of type: %d... ",byteSize,requirements];
    
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
    
    self.debugOutput.cout =[NSString stringWithFormat:@"Allocated %d bytes at 0x%X. ",byteSize,newBlockAddress];
    
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
    
    self.debugOutput.cout =[NSString stringWithFormat:@"freeMem: %d bytes at %d. ",currentBlock.size,memoryBlock];
    
    [memlist  addObject:currentBlock];  //Swap from busy list to free list.
    [busylist removeObject:currentBlock];

}

-(void)closeLibrary:(uint32_t)libNode{
    
    if(libNode==0){
        return;
    }
    
    [[self instanceAtNode:libNode] close];
    self.debugOutput.cout =[NSString stringWithFormat:@"Close Library: %s",[self instanceAtNode:libNode].libNameString];
}

-(uint32_t)openLibrary:(const char*)libName of:(uint32_t)version{
    
    //Use the proper list functions now we have them... also this function should scan the libs: dir if this returns 0.
    self.debugOutput.cout =[NSString stringWithFormat:@"Open Library: %s (version v%d)",libName,version];
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




-(void)insert:(uint32_t)node behind:(uint32_t)pred inList:(uint32_t)list{
    
    uint32_t firstNode = READ_LONG(_emulatorMemory, list);
    
    //if this is a new list then just add head.
    if(firstNode==0){
        [self addHead:node toList:list];
        return;
    }
    
    uint32_t nextNode = READ_LONG(_emulatorMemory, pred);
    
    if(nextNode==0){
        [self addTail:node toList:list];
        return;
    }
    
    //The pred node cannot be 0 or the list header!
    
    WRITE_LONG(_emulatorMemory, node, nextNode);
    WRITE_LONG(_emulatorMemory, node+4, pred);
    
    WRITE_LONG(_emulatorMemory, pred, node);
    WRITE_LONG(_emulatorMemory, nextNode+4, node);
    
    
    
    return;
}
 

-(void)addHead:(uint32_t)node toList:(uint32_t)list{
    
    uint32_t nextNode = READ_LONG(_emulatorMemory,list); //the old head node
    
    WRITE_LONG(_emulatorMemory, list, node);    //the new head node
    WRITE_LONG(_emulatorMemory, node+4, list);  //the previous node is actually the list header.
    
    if(nextNode==0){
        WRITE_LONG(_emulatorMemory, list+8, node); //since there was no node before, this is also the last node
        return;
    }
    
    WRITE_LONG(_emulatorMemory, node, nextNode);  //add the old head back into the chain.
    WRITE_LONG(_emulatorMemory, nextNode+4, node);//add the new head before the old head.
    
}


-(void)addTail:(uint32_t)node toList:(uint32_t)list{
    
    uint32_t tailNode = READ_LONG(_emulatorMemory,list+8);
    
    if(tailNode==0){
        [self addHead:node toList:list];
        return;
    }
    
    WRITE_LONG(_emulatorMemory, tailNode, node);    //Add this node to the last node.
    WRITE_LONG(_emulatorMemory, node+4, tailNode);  //Set the previous node to the old tail.
    WRITE_LONG(_emulatorMemory, node, 0);           //There is no next node.
    WRITE_LONG(_emulatorMemory, list+8, node);      //Set the list tail to the new node.

    
    return;
}

-(void)remove:(uint32_t)node{
    uint32_t nextNode = READ_LONG(_emulatorMemory, node);
    
    //if this node is the tail
    if(nextNode==0){
        //track back through the list until we find the list header.
        uint32_t prevNode=node;
        uint32_t useNode=node;
        
        while (prevNode !=0) {
            useNode=prevNode;
            prevNode=READ_LONG(_emulatorMemory, prevNode+4);
        }
        //useNode since only the list header can have 0 for a prevNode, the useNode must be the list header.
        
        [self remTail:useNode];
        return;
    }
    
    uint32_t prevNode = READ_LONG(_emulatorMemory, node+4);
    
    WRITE_LONG(_emulatorMemory, prevNode, nextNode);
    WRITE_LONG(_emulatorMemory, nextNode+4, prevNode);
    return;
}


-(void)remHead:(uint32_t)list{
    uint32_t node = READ_LONG(_emulatorMemory, list);
    uint32_t nextNode = READ_LONG(_emulatorMemory, node);
    WRITE_LONG(_emulatorMemory, nextNode+4, list);             //no more prev node
    WRITE_LONG(_emulatorMemory, list, nextNode);          //old next is now list head
}

-(void)remTail:(uint32_t)list{
    uint32_t node = READ_LONG(_emulatorMemory, list+8);
    uint32_t prevNode = READ_LONG(_emulatorMemory, node+4);
    WRITE_LONG(_emulatorMemory, prevNode, 0);               //no more next node
    WRITE_LONG(_emulatorMemory, list+8, prevNode);          //old prev is now list tail
}

-(void)enqueue:(uint32_t)node inList:(uint32_t)list{

    uint32_t nextNode    = READ_LONG(_emulatorMemory, list);
    uint32_t currentNode = nextNode;
    
    if(nextNode==0){
        [self addHead:node toList:list];
        return;
    }
    
    char nodePri =READ_BYTE(_emulatorMemory, node+9);
    
    while(nextNode !=0){
        
        char currentPri = READ_BYTE(_emulatorMemory, nextNode+9);
        
        if(nodePri >= currentPri){
            
            if(currentNode==nextNode){
                [self addHead:node toList:list];
                return;
            }
            
            [self insert:node behind:currentNode inList:list];
            return;
        }
        
        currentNode = nextNode;
        nextNode = READ_LONG(_emulatorMemory, nextNode);
    }
    
    [self addTail:node toList:list];
    return;
}


-(uint32_t)findName:(const char*)name inList:(uint32_t)listPtr{
    //note the parameters are the opposite way around to exec.library
    
    self.debugOutput.cout =[NSString stringWithFormat:@"Find node name: %s in list at 0x%X",name,listPtr];
    
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
    
    if(currentNode==0){
        self.debugOutput.cout =@"... Not found.";
    }else{
        self.debugOutput.cout =@"... Sucess.";
    }
    
    //will return 0 if not found... only in memory libs for now...
    
    return currentNode;
}


-(uint32_t)addTask:(uint32_t)taskStruct initPC:(uint32_t)PC finalPC:(uint32_t)finalPC{
    
    [self enqueue:taskStruct inList:self.base+406]; //Add to the ready list;
    
    //if we are the first task being added to the chain...
    if(self.thisTask==0){
        self.thisTask=taskStruct;
        m68k_set_reg(M68K_REG_PC, PC);
        self.M68KState=M68KSTATE_READY;
        return taskStruct;
    }

    
    [self schedule];
    
    return taskStruct;
}

// 68k Interface *********************************************************************
-(void)forbid{
    self.debugOutput.cout =@"Forbid\n";
}

-(void)permit{
    self.debugOutput.cout =@"Permit\n";
}

-(void)cause{
    self.debugOutput.cout =@"Interupts not enabled yet\n";
}

-(void)schedule{

    char thisPri = READ_BYTE(_emulatorMemory, self.thisTask+9);
    
    uint32_t nextTask = READ_LONG(_emulatorMemory, self.thisTask);
    
    //if we raech the end of the task list... jump back to the top
    if(nextTask==0){
        nextTask=READ_LONG(_emulatorMemory, self.base+406);
        
        //if we are the only task in the ready list don't swap context, just return
        if(nextTask==self.thisTask){
            return;
        }
    }
    
    char nextPri  = READ_BYTE(_emulatorMemory, nextTask+9);
    
    //if the next task is suitable for running... swap context
    if(nextPri >= thisPri){
        [self saveContext];
        self.thisTask = nextTask;
        [self restoreContext];
    }
    
}

-(void)reschedule{
    
    uint32_t currentTask=self.thisTask;
    char     currentPri = READ_BYTE(_emulatorMemory, currentTask+9);
    uint32_t highPriTask = currentPri;
    
    uint32_t nextTask = READ_LONG(_emulatorMemory, self.base+406); //get the top of the ready list;
    
    while(nextTask !=0){
        
        char nextPri = READ_BYTE(_emulatorMemory, nextTask+9);
        
        if(nextPri >= currentPri){
            highPriTask=nextTask;
            break;
        }
        
        nextTask = READ_LONG(_emulatorMemory, nextTask);
    }
    
    return;
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
    uint32_t list = m68k_get_reg(NULL, M68K_REG_A0);
    uint32_t node = m68k_get_reg(NULL, M68K_REG_A1);
    uint32_t pred = m68k_get_reg(NULL, M68K_REG_A2);
    [self insert:node behind:pred inList:list];
    return;
}
-(void)addHead{
    uint32_t list = m68k_get_reg(NULL, M68K_REG_A0);
    uint32_t node = m68k_get_reg(NULL, M68K_REG_A1);
    [self addHead:node toList:list];
    return;
}
-(void)addTail{
    uint32_t list = m68k_get_reg(NULL, M68K_REG_A0);
    uint32_t node = m68k_get_reg(NULL, M68K_REG_A1);
    [self addTail:node toList:list];
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
    uint32_t list = m68k_get_reg(NULL, M68K_REG_A0);
    uint32_t node = m68k_get_reg(NULL, M68K_REG_A1);
    [self enqueue:node inList:list];
    return;
}


-(void)findName{
    uint32_t list = m68k_get_reg(NULL, M68K_REG_A0);
    uint32_t A1 = m68k_get_reg(NULL, M68K_REG_A1);
    const char* name =(const char*) &_emulatorMemory[A1];
    
    uint32_t D0 = [self findName:name inList:list];
    
    m68k_set_reg(M68K_REG_D0, D0);
    
    return;
}

-(void)addTask{
    //282 $fee6 -$011a AddTask(task,initPC,finalPC)(a1/a2/a3)
    uint32_t task = m68k_get_reg(NULL, M68K_REG_A1);
    uint32_t initPC = m68k_get_reg(NULL, M68K_REG_A1);
    uint32_t finalPC = m68k_get_reg(NULL, M68K_REG_A1);
    
   m68k_set_reg(M68K_REG_D0, [self addTask:task initPC:initPC finalPC:finalPC]); //Don't know if D0 is the correct result register
    
}

-(uint32_t)findTask{
    self.debugOutput.cout =@"Find Task: ";
    uint32_t A1 =m68k_get_reg(NULL, M68K_REG_A1);
    
    if(A1==0){
        self.debugOutput.cout =@"This Task :)";
        m68k_set_reg(M68K_REG_D0, self.thisTask);
        return self.thisTask;
    }
    
    unsigned char*    taskName = &_emulatorMemory[A1];

    self.debugOutput.cout =[NSString stringWithFormat:@"Find Task: %s\n",taskName];
    
    //check the ready task list
    uint32_t task = [self findName:taskName inList:self.base+406];
    
    //if nothing, then check the waiting task list
    if(task==0){
        task = [self findName:taskName inList:self.base+420];
    }
    
    m68k_set_reg(M68K_REG_D0, task);
    return task;
}

-(void)setSignal{
    self.debugOutput.cout =@"SetSignal()... not implemented";
}

-(void)getMsg{
    uint32_t A0 = m68k_get_reg(NULL, M68K_REG_A0);
    char* portName = &_emulatorMemory[A0];
    self.debugOutput.cout =@"getMessage()... not implemented";
    return;
}

-(void)replyMsg{
    self.debugOutput.cout =@"replyMessage()... not implemented";
}

-(void)waitPort{
    uint32_t A0 = m68k_get_reg(NULL, M68K_REG_A0);
    char* portName = &_emulatorMemory[A0];
    self.debugOutput.cout =@"waitPort()... not implemented";
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
    
    self.debugOutput.cout =@"SetFunction()... this might work... in future X-D";
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
