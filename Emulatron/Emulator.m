//
//  Emulator.m
//  Emulatron
//
//  Created by Matt Parsons on 02/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "Emulator.h"
#include "m68k.h"
#include "sim.h"
#include "endianMacros.h"

#define ADDRESS_SPACE_SIZE 16777215 // address starts at 0, so is 1 less than 16777216 (2^24)
#define SUPERVISOR_STACK   0xFFFFF0 // Top of reserved kickstart space.
#define EXEC_BASE          0xF80000 // Half way through the reserved Kickstart space.
#define DOS_BASE           0xF70000 // 64k below exec.library

//Load Seg defines... probably shouldn't be in this object... should be in EMUDos
#define HUNK_UNIT           0999
#define HUNK_NAME           1000
#define HUNK_CODE           1001
#define HUNK_DATA           1002
#define HUNK_BSS            1003
#define HUNK_RELOC32        1004
#define HUNK_RELOC32SHORT   1020
#define HUNK_RELOC16        1005
#define HUNK_RELOC8         1006
#define HUNK_DRELOC32       1015
#define HUNK_DRELOC16       1016
#define HUNK_DRELOC8        1017
#define HUNK_EXT            1007
#define HUNK_SYMBOL         1008
#define HUNK_DEBUG          1009
#define HUNK_END            1010
#define HUNK_HEADER         1011

//HORRIBLE GLOBAL VARIABLES... THIS IS THE LINK BETWEEN THE C CODE AND THE OBJ-C code
uint8_t* _emulatorMemory=NULL;
id       _emualtorInstance;

/* Called when the CPU pulses the RESET line */
void cpu_pulse_reset(void){
    [_emualtorInstance bounce];
}


void doNothing(){
    return;
}

unsigned int cpu_read_byte(unsigned int address){
 
    if(address > ADDRESS_SPACE_SIZE){
        printf("Attempted to read byte from RAM address %08x", address);
        return -1;
    }
    return READ_BYTE(_emulatorMemory, address);
}

unsigned int cpu_read_word(unsigned int address){
    
    if(address > ADDRESS_SPACE_SIZE){
        printf("Attempted to read word from RAM address %08x", address);
        return -1;
    }
    return READ_WORD(_emulatorMemory, address);
}


unsigned int cpu_read_long(unsigned int address) {
    
    /*
    if(address==4){
        printf("Exec.library address loaded\n");
    }
    */
    
    if(address > ADDRESS_SPACE_SIZE){
        printf("Attempted to read long from RAM address %08x", address);
        return -1;
    }
    return READ_LONG(_emulatorMemory, address);
}

void cpu_write_byte(unsigned int address, unsigned int value){

    if(address > ADDRESS_SPACE_SIZE){
        printf("Attempted to write %02x to RAM address %08x", value&0xff, address);
    }
    WRITE_BYTE(_emulatorMemory, address, value);
}

void cpu_write_word(unsigned int address, unsigned int value){

    if(address > ADDRESS_SPACE_SIZE){
        printf("Attempted to write %04x to RAM address %08x", value&0xffff, address);
        return;
    }
    WRITE_WORD(_emulatorMemory, address, value);
}

void cpu_write_long(unsigned int address, unsigned int value){
    
    
    
    if(address > ADDRESS_SPACE_SIZE || address < 8){                            //all writes to address 0x0 and 0x4 MUST FAIL
        printf("Attempted to write %08x to RAM address %08x", value, address);
        return;
    }
    WRITE_LONG(_emulatorMemory, address, value);
}











@implementation Emulator

-(Emulator*)init{
    self = [super init];
    
    self.addressSpace =[[NSMutableData alloc] initWithLength:ADDRESS_SPACE_SIZE];
    _emulatorMemory=self.addressSpace.mutableBytes;
    _emualtorInstance = self;
    
    self.PALClockSpeed=28375000;
    self.instructionsPerQuantum=100;//low number for easy debugging
    self.quantum = 1/50;
    
    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000); //Pretend to be an A500 for now...
    [self restartCPU];
    return self;
}



-(void)loadFile:(NSData*)file toSegListAt:(NSInteger)address{
    running=NO;
    
    printf("\nEmulatron LoadSeg mk1:\n");
    
    uint8_t* data =(uint8_t*)file.bytes;
    
    if(READ_LONG(data, 0) != HUNK_HEADER){
        printf("File is not executable\n");
        return;
    }
    
    if(READ_LONG(data, 4) != 0x0){
        printf("File corrupt\n");
        return;
    }
    
    uint32_t totalHunks = READ_LONG(data,  8);
    uint32_t currentHunk= READ_LONG(data, 12);    //Should be zero for executable files,
    uint32_t lastHunk   = READ_LONG(data, 16);
    uint32_t hunkLoc    = 0;
    uint32_t totalRamNeeded = 0;
    
    uint32 hunkPointer = 20;
    //allocate ram for each hunk
    printf("Hunk Table [%d]\n",totalHunks);
    uint32_t hunkAddress[totalHunks]; //an array which points to the memory address of each memory hunk.
                              //this code currently just loads the hunks in sequentially, since we have so much ram... but really I sould exec.library alloc memory for each one.
    for(int i=0;i<totalHunks;++i){
        
        hunkAddress[i]=(uint32_t)address+hunkLoc;
        uint32_t RAMType = (READ_LONG(data, hunkPointer)   & 0xC0000000) >> 30;
        uint32_t RAMSize = (READ_LONG(data, hunkPointer)*4)& 0x3FFFFFFF;hunkPointer+=4;
        
        totalRamNeeded+=RAMSize;
        
        hunkLoc = hunkLoc + RAMSize + 4; //(put a 4 byte between hunks to keep them apart)
        
        printf("0x%X: hunk %d (%d bytes) in ",hunkAddress[i],i,RAMSize);
        
        switch (RAMType) {
            case 0: printf("fast ram (prefered) or chip ram\n");break;
            case 1: printf("chip ram or fail\n");break;
            case 2: printf("fast ram or fail\n");break;
            case 3: printf("some ram tag I don't know!\n");break;
        }
        
    }
    printf("total Ram needed:%d\n\n",totalRamNeeded);
    
    
    // Hunk header read, now time to load the code and data hunks into RAM.
    while(hunkPointer<file.length){
        uint32_t hunkType   =  READ_LONG(data, hunkPointer) & 0x3FFFFFFF;hunkPointer+=4;//Mask out any memory type flags (everything goes into fast ram for now)
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
                
                printf("hunk:%d %d bytes(hunk_code) loaded at 0x%x\n",currentHunk-1,hunkSize,hunkAddress[currentHunk-1]); //need to subtract from the hunk pointer as I incremented it earlier...
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
                        printf("%d offsets in hunk %d which need a pointer to hunk %d\n",numberOfOffsets,currentHunk-1,(READ_LONG(data, hunkPointer-4)));
                        
                        
                        for(int j=0;j<numberOfOffsets;++j){
                            uint32_t offset = (READ_LONG(data, hunkPointer));hunkPointer+=4;
                            uint32_t currentValueAtOffset = READ_LONG(_emulatorMemory, memPointer+offset);
                            currentValueAtOffset += valueToAdd;
                            WRITE_LONG(_emulatorMemory, memPointer+offset,currentValueAtOffset);
                            //printf("Offset %d: %d\n",offset,currentValueAtOffset);
                        }
                        
                    }while(numberOfOffsets>0);
                    
                    printf("\n");

                
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
                
                printf("hunk:%d %d bytes (hunk_data) loaded at 0x%x\n",currentHunk-1,hunkSize,hunkAddress[currentHunk-1]); //need to subtract from the hunk pointer as I incremented it earlier...
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
                        printf("%d offsets in hunk %d which need a pointer to hunk %d\n",numberOfOffsets,currentHunk-1,(READ_LONG(data, hunkPointer-4)));
                        
                        
                        for(int j=0;j<numberOfOffsets;++j){
                            uint32_t offset = (READ_LONG(data, hunkPointer));hunkPointer+=4;
                            uint32_t currentValueAtOffset = READ_LONG(_emulatorMemory, memPointer+offset);
                            currentValueAtOffset += valueToAdd;
                            WRITE_LONG(_emulatorMemory, memPointer+offset,currentValueAtOffset);
                            //printf("Offset %d: %d\n",offset,currentValueAtOffset);
                        }
                        
                    }while(numberOfOffsets>0);
                    
                    printf("\n");
                }
                
                
                break;
                
            case HUNK_DEBUG:
                //Do nothing with Debug hunks, just skip over them.
                hunkSize = READ_LONG(data, hunkPointer)*4; hunkPointer+=4; // multiply by 4 to get the number of bytes
                hunkPointer+=hunkSize;
                break;
                
            case HUNK_END:
                //ignore end hunks
                break;
                
                
            default:
                printf("Unsupported hunk type %d\n",hunkType);
                break;
        }
        
    }
    


 
    
    
    
    

    /*
    // VERY OLD CODE BELOW!. NOT DELETED YET... BUT WILL BE SOON
    while(hunkPointer<file.length){
        uint32_t RAMType = (READ_LONG(data, hunkPointer)   & 0xC0000000) >> 30;
        uint32_t hunkType = READ_LONG(data, hunkPointer) & 0x3FFFFFFF;hunkPointer+=4;//Mask out any memory type flags (everything goes into fast ram for now)


        
        if(hunkType==HUNK_DEBUG){
            printf("hunk_debug (ignore)\n");
            uint32_t hunkSize = READ_LONG(data, hunkPointer)*4;hunkPointer+=4;
            hunkPointer+=hunkSize;
        }
        
        //if this is a code hunk, then load it into ram
        if(hunkType==HUNK_CODE){
            uint32_t hunkSize = READ_LONG(data, hunkPointer)*4; hunkPointer+=4; // multiply by 4 to get the number of bytes
            uint32_t memPointer = hunkAddress[currentHunk++];//get the address of the current hunk's allocated memory, and advance the current hunk pointer.
            
            //copy data to ram
            for(int j=0;j<hunkSize;++j){
                _emulatorMemory[memPointer+j] =data[hunkPointer+j];
            }
            
            printf("hunk:%d %dbytes(hunk_code) loaded at 0x%x\n",currentHunk-1,hunkSize,hunkAddress[currentHunk-1]); //need to subtract from the hunk pointer as I incremented it earlier...
            hunkPointer+=hunkSize;
        }
        
        
        if(hunkType==HUNK_RELOC32){
            printf("hunk_reloc32");
            int numberOfOffsets;
            
            do{
                //quite neat as this catches the hunk_end symbol and moves quietly on...
                numberOfOffsets =(READ_LONG(data, hunkPointer));hunkPointer+=4;
                int hunkToReloc =(READ_LONG(data, hunkPointer));hunkPointer+=4;
                printf("\n%d offsets in hunk %d:",numberOfOffsets,hunkToReloc);
                
                
                for(int j=0;j<numberOfOffsets;++j){
                    // uint32_t offset = (READ_LONG(data, hunkPointer));hunkPointer+=4;
                    //printf("@%d ",offset);
                }
                
            }while(numberOfOffsets>0);
            
            printf("\n");
        }
        
        //if this is a data hunk, then load it into ram
        if(hunkType ==HUNK_DATA){
            switch (RAMType) {
                case 0: printf("FREE_MEM: ");break;
                case 1: printf("CHIP_MEM: ");break;
                case 2: printf("FAST_MEM: ");break;
                case 3: printf("PANIC:");break;
            }
            uint32_t hunkSize = READ_LONG(data, hunkPointer)*4; hunkPointer+=4; // multiply by 4 to get the number of bytes
            uint32_t memPointer = hunkAddress[currentHunk++];//get the address of the current hunk's allocated memory, and advance the current hunk pointer.
            
            //copy data to ram
            for(int j=0;j<hunkSize;++j){
                _emulatorMemory[memPointer+j] =data[hunkPointer+j];
            }
            
            printf("hunk:%d %dbytes (hunk_data) loaded at 0x%x\n",currentHunk-1,hunkSize,hunkAddress[currentHunk-1]); //need to subtract from the hunk pointer as I incremented it earlier...
            hunkPointer+=hunkSize;
        }
        
        if(hunkType==HUNK_END){
            //move on...
        }
        
        if( (hunkType != HUNK_CODE) && (hunkType != HUNK_RELOC32) && (hunkType != HUNK_DATA) && (hunkType != HUNK_DEBUG) && (hunkType != HUNK_END)){
            //some Hunk I don't care about yet.... so skip over it
            uint32_t hunkSize = READ_LONG(data, hunkPointer)*4;hunkPointer+=4;
            hunkPointer+=hunkSize;
            printf("hunk_ignored (%x)\n",hunkType);
        }
        

    }
*/

    
    
    
    m68k_set_reg(M68K_REG_PC, (uint32_t)address);


    printf("Emulation started...!\n");
    running=YES;
}

-(void)restartCPU{
    	m68k_pulse_reset();
    
    //Set up the Amiga memory map, fill the first few bytes with NOPs, just to let the CPU run a few instructions.
    WRITE_WORD(_emulatorMemory, 0, 0x4E71);
    WRITE_WORD(_emulatorMemory, 2, 0x4E71);
    WRITE_WORD(_emulatorMemory, 4, 0x4E71);
    WRITE_WORD(_emulatorMemory, 6,  65535); // there is the unfeasable lvo value.
    WRITE_WORD(_emulatorMemory, 8, 0x4E71);
    WRITE_WORD(_emulatorMemory,10, 0x4E70); //call lvo 65535... which halts the emulato, this is the last address on the Supervisor stack.
    WRITE_WORD(_emulatorMemory,12, 0x4E71);
    WRITE_WORD(_emulatorMemory,14, 0x4E71);
    WRITE_WORD(_emulatorMemory,16, 0x4E71);
    WRITE_WORD(_emulatorMemory,20, 0x4E71);
    WRITE_WORD(_emulatorMemory,12, 0x4E71);

    //Set the Supervisor stack to the top of chipram:
    m68k_set_reg(M68K_REG_SP, SUPERVISOR_STACK-4);
    WRITE_LONG(_emulatorMemory, SUPERVISOR_STACK, 10); //write address 10, so the very last place the OS will jump to will halt the emulator.
    
    // run a few instructions to clear the pipeline.
    [self execute];
    
    //Setup exec.library
     self.execLibrary = [[EMUExec alloc]initAtAddress:EXEC_BASE];
    [self.execLibrary buildJumpTableSize:170];  //170 LVOs chosen as that makes a nice 1024byte jumptable
     WRITE_LONG(_emulatorMemory, 4, EXEC_BASE); //write execbase to address 0x4
    
    //Setup dos.library
    self.dosLibrary = [[EMUDos alloc]initAtAddress:DOS_BASE];
    [self.dosLibrary buildJumpTableSize:170];

    
    //Kick the emulation off!
    running=NO;     //but don't let it run until we have some code loaded
    self.executionTimer = [NSTimer scheduledTimerWithTimeInterval:self.quantum target:self selector:@selector(execute:) userInfo:nil repeats:YES];

}

-(void)execute{
    m68k_execute(1);
}

-(void)execute:(NSTimer*)timer{
    //called once every second by the timer
    
    if(running==YES){
        m68k_execute((int)self.instructionsPerQuantum);
    }
}

-(void)bounce{
    running=NO; //Pause CPU while we service the function call
    
    uint32_t a6 = m68k_get_reg(NULL, M68K_REG_A6);
    uint32_t pc = m68k_get_reg(NULL, M68K_REG_PC);      //this is always one word greater than the current instruction for the jumptable.
    uint16_t lvo =*((uint16_t*) &_emulatorMemory[pc-6]);
    
    if(lvo==65535){
        printf("Emulation Terminated... no more tasks to run");
    }
    
    switch(a6){
        case EXEC_BASE:[self.execLibrary callFunction:lvo];break;
        case  DOS_BASE:[self.dosLibrary  callFunction:lvo];break;
    }
    
    m68k_set_reg(M68K_REG_PC, pc-4);
    
    running=YES;
}


@end
