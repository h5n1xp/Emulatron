//
//  EMUDos.m
//  Emulatron
//
//  Created by Matt Parsons on 04/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUDos.h"
#import "EMUdosProcess.h"

@implementation EMUDos


-(void)setupLibNode{
    
    self.libVersion  = 37; // for now... i don't actaully check it... so doesn't really matter
    self.libRevision = 34; // as above
    self.libOpenCount= 1;  // always a minimum of one for this library, as we alwasy need to access the drives.
    
    uint32_t namePtr = self.libData;    //locate the data space
    uint32_t libIDPtr = namePtr + [self writeString:"dos.library" toAddress:namePtr]; //write the name string there and generate the next free address
    self.libName = namePtr; //write the address of the string to the libNode
    
    [self writeString:"dos 37.34 (04 Feb 2017)" toAddress:libIDPtr]; //write the ID string to the data area
    self.libID = libIDPtr;  //write the address of the ID String to the lib structure.
    
}


-(void)callFunction:(NSInteger)lvo{
    
    self.execLibrary.debugOutput.cout = [NSString stringWithFormat:@"%s calling %s LVO:%d - ",self.execLibrary.runningTask,self.libNameString,(int)lvo];
    
    switch(lvo){
        case   6:[self open];break;
        case  12:[self close];break;
        case  18:[self expunge];break;
        case  24:[self reserved];break;
        case  30:[self Open];break;     // <--- note that this is the DOS function open with a capital O
        case  42:[self read];break;
        case  84:[self lock];break;
        case  90:[self unLock];break;
        case 126:[self currentDir];break;
        case 132:[self ioError];break;
        case 138:[self createProc];break;
        case 150:[self loadSeg];break;
        case 474:[self printFault];break;
        case 606:[self systemTagList];break;
        case 642:[self setIoErr];break;
        case 798:[self readArgs];break;
        case 858:[self freeArgs];break;
        default:[self unimplemented:lvo];break;
    }
    
    self.execLibrary.debugOutput.cout =@"\n";
}
//Obj-C interface  *******************************************************************


-(uint32_t)currentDir:(uint32_t)lock{
    
    //ignore lock...
    
    //ok... nasty hack time, jam the currentDir string into a bit of memory I know isn't currently used... DOS NEEDS A PROPER REWRITE!!!
    
    const char* st = [self.currentPath UTF8String];
    
    [self writeString:st toAddress:0xA00000];
    
    
    return 0xA00000;
}

-(uint32_t)createProc:(unsigned char*)name priority:(char)pri segList:(uint32_t)segList stackSize:(uint32_t)stackSize{
    
    //Convoltued way to get the process name into the emulator memory
    uint32_t nameLen =(uint32_t)strlen(name);
    uint32_t strPtr =[self.execLibrary allocMem:nameLen with:MEMF_FAST];
    [self writeString:name toAddress:strPtr];
    
    //Allocate Memory for Process control block and Stack
    self.execLibrary.debugOutput.cout =@"\nNeed 228 bytes for Process Control Block\n";
    uint32_t taskStructure = [self.execLibrary allocMem:228 with:4];
    self.execLibrary.debugOutput.cout =[NSString stringWithFormat:@"\nNeed %d bytes for process stack\n",stackSize];
    uint32_t taskStackLower     = [self.execLibrary allocMem:stackSize with:4]; //add on a safety buffer of 4k above the stack
    
    WRITE_LONG(_emulatorMemory, taskStructure+10, strPtr);   //set the task name
    
    //set the top 8 bytes of the stack to 0, so any unexpected rts will point PC to 0 and be captured by the bounce function.
    WRITE_LONG(_emulatorMemory, taskStackLower+stackSize-4, 0x0);
    WRITE_LONG(_emulatorMemory, taskStackLower+stackSize-8, 0x0);
    stackSize -=4;
    
    //Use a Process structure
    EMUdosProcess* proc = [EMUdosProcess atAddress:taskStructure ofMemory:_emulatorMemory];
    
    proc.ln_Priority  = pri;
    proc.ln_Name      = strPtr;
    proc.tc_SPReg     = taskStackLower+stackSize;
    proc.tc_SPLower   = taskStackLower;
    proc.tc_SPUpper   = taskStackLower+stackSize;
    proc.pr_SegList   = segList;
    proc.pr_StackSize = stackSize;
    proc.pr_StackBase = taskStackLower+stackSize;
    
    /* Predates my proper process strucutre
    //build a task structure for exec
    WRITE_BYTE(_emulatorMemory, taskStructure+9, pri);
    WRITE_LONG(_emulatorMemory, taskStructure+10, strPtr);
    WRITE_LONG(_emulatorMemory, taskStructure+54, taskStackLower+stackSize);
    WRITE_LONG(_emulatorMemory, taskStructure+58, taskStackLower);
    WRITE_LONG(_emulatorMemory, taskStructure+62, taskStackLower+stackSize);
    
    //build a process structure for dos.
    WRITE_LONG(_emulatorMemory, taskStructure+128, segList);
    WRITE_LONG(_emulatorMemory, taskStructure+132, stackSize);
    WRITE_LONG(_emulatorMemory, taskStructure+144, taskStackLower+stackSize);
    */
    
    [self.execLibrary addTask:taskStructure initPC:segList+4 finalPC:0];
    
    //return taskStructure+92;
    return proc.pr_MsgPortPtr;
}

-(uint32_t)loadSeg:(NSURL*)path{
    
    NSString* pathString = [path absoluteString];
    self.currentPath =[pathString stringByDeletingLastPathComponent];
    NSString* name =[path lastPathComponent];
    NSData* file = [NSData dataWithContentsOfURL:path];
    
    
    self.execLibrary.debugOutput.cout =[NSString stringWithFormat:@"\nEmulatron LoadSeg mk1: loading %s\n",[name UTF8String]];
    
    uint8_t* data =(uint8_t*)file.bytes;
    
    if(READ_LONG(data, 0) != HUNK_HEADER){
        self.debugOutput.cout =@"File is not executable\n";
        return 0;
    }
    
    if(READ_LONG(data, 4) != 0x0){
        self.debugOutput.cout =@"File corrupt\n";
        return 0;
    }
    
    uint32_t totalHunks = READ_LONG(data,  8);
    uint32_t currentHunk= READ_LONG(data, 12);    //Should be zero for executable files,
    //uint32_t lastHunk   = READ_LONG(data, 16);
    uint32_t hunkLoc    = 0;
    uint32_t totalRamNeeded = 0;
    
    uint32 hunkPointer = 20;
    //allocate ram for each hunk
    self.debugOutput.cout =[NSString stringWithFormat:@"Hunk Table [%d]\n",totalHunks];
    uint32_t hunkAddress[totalHunks]; //an array which points to the memory address of each memory hunk.
    
    for(int i=0;i<totalHunks;++i){
        
        uint32_t RAMType = (READ_LONG(data, hunkPointer)   & 0xC0000000) >> 30;
        uint32_t RAMTag = 0;
        switch (RAMType) {
            case 0:  self.debugOutput.cout =[NSString stringWithFormat:@"\nHunk %d: fast ram (prefered) or chip ram using ",i];RAMTag=4;break;
            case 1:  self.debugOutput.cout =[NSString stringWithFormat:@"\nHunk %d: chip ram or fail using ",i];RAMTag=2;break;
            case 2:  self.debugOutput.cout =[NSString stringWithFormat:@"\nHunk %d: fast ram or fail using ",i];RAMTag=4;break;
            case 3:  self.debugOutput.cout =[NSString stringWithFormat:@"\nHunk %d: some ram tag I don't know! using ",i];break;
        }
        uint32_t RAMSize = (READ_LONG(data, hunkPointer)*4)& 0x3FFFFFFF;hunkPointer+=4;
        RAMSize +=4; //add 4 bytes to hold the address of the next segment
        
        hunkAddress[i]=[self.execLibrary allocMem:RAMSize with:RAMTag]+4;  //The memory allocated is 4bytes too big, so the address we need is 4bytes into the memory allocation.
        
        uint32_t currentSegment =hunkAddress[i];
        if(i !=0){
            uint32_t previousSegment = hunkAddress[i-1];
            WRITE_LONG(_emulatorMemory,previousSegment-4,currentSegment-4); //Write the next Hunk address to the top of the previous hunk... to create a seglist.
        }
        WRITE_LONG(_emulatorMemory,currentSegment-4,0x0);            //Null out the current segment's next hunk pointer.
        
        totalRamNeeded+=RAMSize;
        
        hunkLoc = hunkLoc + RAMSize + 4; //(put a 4 byte between hunks to keep them apart)
        
        //self.debugOutput.cout =[NSString stringWithFormat:@"0x%X (%d bytes)\n",hunkAddress[i],RAMSize];
        
        
        
    }
    self.debugOutput.cout =[NSString stringWithFormat:@"\ntotal Ram needed:%d\n\n",totalRamNeeded];
    
    // Hunk header read, now time to load the code and data hunks into RAM.
    while(hunkPointer<file.length){
        uint32_t hunkType   =  READ_LONG(data, hunkPointer) & 0x3FFFFFFF;hunkPointer+=4;//Mask out any memory type flags (the ram and required type have all be pre allocated);
        uint32_t hunkSize   = 0;
        uint32_t memPointer = 0;
        
        switch(hunkType){
                
            case HUNK_CODE:
                hunkSize   = READ_LONG(data, hunkPointer)*4; hunkPointer+=4; // multiply by 4 to get the number of bytes
                memPointer = hunkAddress[currentHunk++];//get the address of the current hunk's allocated memory, and advance the current hunk pointer.
                
                //copy data to ram
                for(int j=0;j<hunkSize;++j){
                    _emulatorMemory[memPointer+j] =data[hunkPointer+j];
                }
                
                self.debugOutput.cout =[NSString stringWithFormat:@"hunk:%d %d bytes(hunk_code) loaded at 0x%X\n",currentHunk-1,hunkSize,hunkAddress[currentHunk-1]]; //need to subtract from the hunk pointer as I incremented it earlier...
                hunkPointer+=hunkSize;
                
                //Check if this code hunk has a reloc32 block;
                hunkType = READ_LONG(data, hunkPointer);
                
                if(hunkType==HUNK_RELOC32){
                    hunkPointer+=4;
                    uint32_t numberOfOffsets=0;
                    
                    do{
                        //quite neat as this catches the hunk_end symbol and moves quietly on...
                        numberOfOffsets      = (READ_LONG(data, hunkPointer));hunkPointer+=4;
                        uint32_t valueToAdd  = hunkAddress[READ_LONG(data, hunkPointer)];hunkPointer+=4;
                        if(numberOfOffsets>0){
                            self.debugOutput.cout =[NSString stringWithFormat:@"%d offsets in hunk %d which need a pointer to hunk %d\n",numberOfOffsets,currentHunk-1,(READ_LONG(data, hunkPointer-4))];
                        }
                        
                        for(int j=0;j<numberOfOffsets;++j){
                            uint32_t offset = (READ_LONG(data, hunkPointer));hunkPointer+=4;
                            uint32_t currentValueAtOffset = READ_LONG(_emulatorMemory, memPointer+offset);
                            currentValueAtOffset += valueToAdd;
                            WRITE_LONG(_emulatorMemory, memPointer+offset,currentValueAtOffset);
                            //printf("Offset %d: %d\n",offset,currentValueAtOffset);
                        }
                        
                    }while(numberOfOffsets>0);
                    
                    self.debugOutput.cout =@"\n";
                    
                    
                }
                
                printf("");
                break;
                
            case HUNK_DATA:
                hunkSize = READ_LONG(data, hunkPointer)*4; hunkPointer+=4; // multiply by 4 to get the number of bytes
                memPointer = hunkAddress[currentHunk++];//get the address of the current hunk's allocated memory, and advance the current hunk pointer.
                
                //copy data to ram
                for(int j=0;j<hunkSize;++j){
                    _emulatorMemory[memPointer+j] =data[hunkPointer+j];
                }
                
                self.debugOutput.cout =[NSString stringWithFormat:@"hunk:%d %d bytes (hunk_data) loaded at 0x%X\n",currentHunk-1,hunkSize,hunkAddress[currentHunk-1]]; //need to subtract from the hunk pointer as I incremented it earlier...
                hunkPointer+=hunkSize;
                
                //Check if this data hunk has a reloc32 block;
                hunkType = READ_LONG(data, hunkPointer);
                
                if(hunkType==HUNK_RELOC32){
                    hunkPointer+=4;
                    uint32_t numberOfOffsets=0;
                    
                    do{
                        //quite neat as this catches the hunk_end symbol and moves quietly on...
                        numberOfOffsets      = (READ_LONG(data, hunkPointer));hunkPointer+=4;
                        uint32_t valueToAdd  = hunkAddress[READ_LONG(data, hunkPointer)];hunkPointer+=4;
                        if(numberOfOffsets>0){
                            self.debugOutput.cout =[NSString stringWithFormat:@"%d offsets in hunk %d which need a pointer to hunk %d\n",numberOfOffsets,currentHunk-1,(READ_LONG(data, hunkPointer-4))];
                        }
                        
                        for(int j=0;j<numberOfOffsets;++j){
                            uint32_t offset = (READ_LONG(data, hunkPointer));hunkPointer+=4;
                            uint32_t currentValueAtOffset = READ_LONG(_emulatorMemory, memPointer+offset);
                            currentValueAtOffset += valueToAdd;
                            WRITE_LONG(_emulatorMemory, memPointer+offset,currentValueAtOffset);
                            //printf("Offset %d: %d\n",offset,currentValueAtOffset);
                        }
                        
                    }while(numberOfOffsets>0);
                    
                    self.debugOutput.cout =@"\n";
                }
                
                
                break;
                
            case HUNK_DEBUG:
                //Do nothing with Debug hunks, just skip over them.
                hunkSize = READ_LONG(data, hunkPointer)*4; hunkPointer+=4; // multiply by 4 to get the number of bytes
                hunkPointer+=hunkSize;
                break;
                
            case HUNK_BSS:
                hunkSize = READ_LONG(data, hunkPointer)*4; hunkPointer+=4; // multiply by 4 to get the number of bytes
                currentHunk++;
                self.debugOutput.cout =[NSString stringWithFormat:@"hunk:%d %d bytes (hunk_bss)\n",currentHunk-1,hunkSize];
                break;
                
            case HUNK_END:
                //ignore end hunks
                break;
                
                
            default:
                self.debugOutput.cout =[NSString stringWithFormat:@"Unsupported hunk type %d\n",hunkType];
                break;
        }
        
    }
    
    
    return hunkAddress[0]-4; // top of the seglist is 4bytes below the data.
}

// 68k Interface *********************************************************************

-(void)Open{
    uint32_t D1 = m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t D2 = m68k_get_reg(NULL, M68K_REG_D2);
    
    unsigned char* name =&_emulatorMemory[D1];
    
    return;
}

-(void)read{
    
}

-(void)lock{
    self.execLibrary.debugOutput.cout =@"lock() not implemented";
}

-(void)unLock{
    self.execLibrary.debugOutput.cout =@"unLock() not implemented";
}

-(void)currentDir{
    uint32_t D1 =m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t pathPtr = [self currentDir:D1];
    
    
    
    self.execLibrary.debugOutput.cout =@"currentDir() just returns the last path used";
}

-(void)ioError{
    self.execLibrary.debugOutput.cout =@"ioError() not implemented";
    m68k_set_reg(M68K_REG_D0, 0);    // return 0, since I have no idea what has failed :-)
}

-(void)createProc{
//    138 $ff76 -$008a CreateProc(name,pri,segList,stackSize)(d1/d2/d3/d4)
    uint32_t D1 = m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t D2 = m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t D3 = m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t D4 = m68k_get_reg(NULL, M68K_REG_D1);
    
    unsigned char* name = &_emulatorMemory[D1];
    
    uint32_t ret = [self createProc:name priority:D2 segList:D3 stackSize:D4];
    
    m68k_set_reg(M68K_REG_D0, ret);
}

-(void)loadSeg{
    //150 $ff6a -$0096 LoadSeg(name)(d1)
    uint32_t D0 = m68k_get_reg(NULL, M68K_REG_D0);
    
    
    char* name = &_emulatorMemory[D0];
    
    printf("%s",name);
    return;
}

-(void)printFault{
    uint32_t code   = m68k_get_reg(NULL, M68K_REG_D0);
    uint32_t headerPtr = m68k_get_reg(NULL, M68K_REG_D1);
    
    unsigned char* header = &_emulatorMemory[headerPtr];
    
    self.execLibrary.debugOutput.cout = [NSString stringWithFormat:@"AmigaDOS: errorcode - %d, text:%s\n",code,header];
    return;
}

-(void)systemTagList{
    self.execLibrary.debugOutput.cout =@"systemTagList() not implemented";
}

-(void)setIoErr{
    self.execLibrary.debugOutput.cout =@"setIOError() not implemented";
}

-(void)readArgs{
    
    uint32_t templatePtr  = m68k_get_reg(NULL, M68K_REG_D1);
    uint32_t arrayPtr     = m68k_get_reg(NULL, M68K_REG_D2);
    uint32_t argsPtr      = m68k_get_reg(NULL, M68K_REG_D3);
    
    char* array = &_emulatorMemory[arrayPtr];
    unsigned char* template = &_emulatorMemory[templatePtr];
    
    self.execLibrary.debugOutput.cout = [NSString stringWithFormat:@"ReadArgs withTemplate: %s",template];
    
    //Don't know how to service this so put 0 for failure
    m68k_set_reg(M68K_REG_D0, 0);
    return;
}

-(void)freeArgs{
    self.execLibrary.debugOutput.cout =@"freeArgs() not implemented";
}

@end
