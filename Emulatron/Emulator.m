//
//  Emulator.m
//  Emulatron
//
//  Created by Matt Parsons on 02/02/2017.
//  Copyright © 2017 Matt Parsons. All rights reserved.
//

#import "Emulator.h"
#include "m68k.h"
#include "sim.h"
#include "endianMacros.h"

#define ADDRESS_SPACE_SIZE 16777215 // address starts at 0, so is 1 less than 16777216 (2^24)
#define SUPERVISOR_STACK   0xBFCFFC // Top of reserved Autoconfig space... 2meg of ram I'll never use.
#define EXEC_BASE          0xFFF800 // 2Kb below the top of the reserved Kickstart space.
#define DOS_BASE           0xFFE800 // 4k below exec.library
#define GFX_BASE           0xFFD800 // 4k below :-)
#define INTUI_BASE         0xFFC800 // 4k below
#define ICON_BASE          0xFFB800 // 4K below
#define LAYER_BASE         0xFFA800 // 4K below
#define UTIL_BASE          0xFF9800 // 4K below
#define GADTOOL_BASE       0xFF8800 // 4K below
#define DISKFONT_BASE      0xFF7800 // 4k below
#define MATHFFP_BASE       0xEF6800 // 4K below
#define MATHTRANS_BASE     0xEF5800 // 4K below
#define EXPANSION_BASE     0xEF4800 // 4K below

//Load Seg defines... Shouldn't be in this object... should be in EMUDos
#define HUNK_UNIT           0999
#define HUNK_NAME           1000
#define HUNK_CODE           1001    //68K code
#define HUNK_DATA           1002
#define HUNK_BSS            1003
#define HUNK_RELOC32        1004
#define HUNK_RELOC16        1005
#define HUNK_RELOC8         1006
#define HUNK_EXT            1007
#define HUNK_SYMBOL         1008
#define HUNK_DEBUG          1009
#define HUNK_END            1010
#define HUNK_HEADER         1011
#define HUNK_DRELOC32       1015
#define HUNK_DRELOC16       1016
#define HUNK_DRELOC8        1017
#define HUNK_RELOC32SHORT   1020

//Below are some musings as to how the Hunk format could be extended... Though ELF is abviously the way forward.
#define HUNK_SYSTEM         1012    //I propose a "System Hunk" which specifies more deatails about the code, CPU, Endian, ABI etc.
#define HUNK_CODEX86        1021    //x86    code
#define HUNK_CODEX64        1031    //X86-64 code
#define HUNK_RELOC64        1034    //Relcate 64bit
#define HUNK_CODEA32        1041    //ARM32  code
#define HUNK_CODEA64        1051    //ARM64  code

//HORRIBLE GLOBAL VARIABLES... THIS IS THE LINK BETWEEN THE C CODE AND THE OBJ-C code
uint8_t*   _emulatorMemory=NULL;
Emulator*  _emualtorInstance;

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

// Called when the CPU acknowledges an interrupt we don't use  interupts
int cpu_irq_ack(int level)
{
    /*
    switch(level)
    {
        case 0:
        return 0;//nmi_device_ack();
        case 1:
        return 0;// input_device_ack();
        case 2:
        return 0;// output_device_ack();
    }
     */
    return M68K_INT_ACK_SPURIOUS;
}


unsigned int cpu_read_word_dasm(unsigned int address){
    if(address > 16777216)
        printf("Disassembler attempted to read word from address %x", address);
    return READ_WORD(_emulatorMemory, address);
}

unsigned int cpu_read_long_dasm(unsigned int address){
    if(address > 16777216)
        printf("Dasm attempted to read long from address %x", address);
    return READ_LONG(_emulatorMemory, address);
}





/* Disassembler */

void make_hex(char* buff, unsigned int pc, unsigned int length){
    char* ptr = buff;
    
    for(;length>0;length -= 2)
        {
        sprintf(ptr, "%04x", cpu_read_word_dasm(pc));
        pc += 2;
        ptr += 4;
        if(length > 2)
            *ptr++ = ' ';
        }
}

void disassemble_program(){
    unsigned int pc;
    unsigned int instr_size;
    char buff[100];
    char buff2[100];
    
    pc = cpu_read_long_dasm(4);
    
    while(pc <= 0x16e)
        {
        instr_size = m68k_disassemble(buff, pc, M68K_CPU_TYPE_68000);
        make_hex(buff2, pc, instr_size);
        printf("%03x: %-20s: %s\n", pc, buff2, buff);
        pc += instr_size;
        }
    fflush(stdout);
}



void cpu_instr_callback(){
    // The following code will print out instructions as they are executed
    
    
    static char buff[100];
    static char buff2[100];
    static unsigned int pc;
    static unsigned int instr_size;
    
    pc = m68k_get_reg(NULL, M68K_REG_PC);
    instr_size = m68k_disassemble(buff, pc, M68K_CPU_TYPE_68000);
    make_hex(buff2, pc, instr_size);
    _emualtorInstance.disassemblerOutput.cout =[NSString stringWithFormat:@"E %03x: %-20s: %s\n", pc, buff2, buff];
    fflush(stdout);
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

    return self;
}

-(Emulator*)initWithDebug:(EMUConsoleView*)console{
    self = self.init;
    
    self.debugOutput = console;
    [self restartCPU];
    return self;
}



-(void)restartCPU{
    m68k_pulse_reset();
    
    //Set up the Amiga memory map, fill the first few bytes with NOPs, just to let the CPU run a few instructions.
    WRITE_WORD(_emulatorMemory, 0, 0x4E71);
    WRITE_WORD(_emulatorMemory, 2, 0x4E71);

    //Set the Supervisor stack to the top of chipram:
    m68k_set_reg(M68K_REG_SP, SUPERVISOR_STACK);
    WRITE_LONG(_emulatorMemory, SUPERVISOR_STACK, 0); //write address 0, so the very last place the OS will jump to will halt the emulator.
    
    // run a few instructions to clear the pipeline.
    [self execute];
    
    //Setup exec.library
     self.execLibrary = [[EMUExec alloc]initAtAddress:EXEC_BASE];
    [self.execLibrary buildJumpTableSize:170];  //170 LVOs chosen as that makes a nice 1024byte jumptable
     self.execLibrary.debugOutput = self.debugOutput;
     WRITE_LONG(_emulatorMemory, 4, EXEC_BASE); //write execbase to address 0x4
    
    //Setup dos.library
    self.dosLibrary = [[EMUDos alloc]initAtAddress:DOS_BASE];
    [self.dosLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.dosLibrary];
    
    //Setup graphics.library
    self.graphicsLibrary = [[EMUGraphics alloc]initAtAddress:GFX_BASE];
    [self.graphicsLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.graphicsLibrary];
    
    //Setup intuition.library
    self.intuitionLibrary = [[EMUIntuition alloc]initAtAddress:INTUI_BASE];
    [self.intuitionLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.intuitionLibrary];
    
    //Setup icon.library
    self.iconLibrary = [[EMUIcon alloc]initAtAddress:ICON_BASE];
    [self.iconLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.iconLibrary];
    
    //Setup utility.library
    self.utilityLibrary = [[EMUUtility alloc]initAtAddress:UTIL_BASE];
    [self.utilityLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.utilityLibrary];
    
    //Setup layers.library
    self.layersLibrary = [[EMULayers alloc]initAtAddress:LAYER_BASE];
    [self.layersLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.layersLibrary];
    
    //Setup gadtools.library
    self.gadtoolsLibrary = [[EMUGadtools alloc]initAtAddress:GADTOOL_BASE];
    [self.gadtoolsLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.gadtoolsLibrary];
    
    //Setup diskfont.library
    self.diskfontLibrary = [[EMUDiskfont alloc]initAtAddress:DISKFONT_BASE];
    [self.diskfontLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.diskfontLibrary];
    
    //Setup mathffp.library
    self.mathffpLibrary = [[EMUMathffp alloc]initAtAddress:MATHFFP_BASE];
    [self.mathffpLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.mathffpLibrary];
    
    //Setup mathtrans.library
    self.mathtransLibrary = [[EMUMathtrans alloc]initAtAddress:MATHTRANS_BASE];
    [self.mathtransLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.mathtransLibrary];
    
    //Setup expansion.library
    self.expansionLibrary = [[EMUExpansion alloc]initAtAddress:EXPANSION_BASE];
    [self.expansionLibrary buildJumpTableSize:170];
    [self.execLibrary addlibrary:self.expansionLibrary];
    
    //Kick the emulation off!
    _execLibrary.M68KState=M68KSTATE_STOPPED;     //but don't let it run until we have some code loaded
    self.executionTimer = [NSTimer scheduledTimerWithTimeInterval:self.quantum target:self selector:@selector(execute:) userInfo:nil repeats:NO];
    _ticks=0;
    
    
    //Start the system clock!
    [NSTimer scheduledTimerWithTimeInterval:4/50 target:self selector:@selector(fiftyHertzTimer:) userInfo:nil repeats:NO];
    
    WRITE_WORD(_emulatorMemory,0, 0x4E70); //trap execution from address 0...
    WRITE_WORD(_emulatorMemory,2, 0x4E70); //trap execution from address 2...
}


-(void)execute{
    m68k_execute(1);
}

-(void)execute:(NSTimer*)timer{

    if(_execLibrary.M68KState==M68KSTATE_READY){
        _execLibrary.M68KState=M68KSTATE_RUNNING;
        m68k_execute((int)self.instructionsPerQuantum);
        
        if(_execLibrary.M68KState !=M68KSTATE_STOPPED){
            _execLibrary.M68KState = M68KSTATE_READY;
        }
    }else if(_execLibrary.M68KState==M68KSTATE_THROTTLED){
        [NSThread sleepForTimeInterval:2/50];
    }
  
    
    self.executionTimer = [NSTimer scheduledTimerWithTimeInterval:self.quantum target:self selector:@selector(execute:) userInfo:nil repeats:NO];

}


-(void)fiftyHertzTimer:(NSTimer*)timer{
    
    //called once every quantum by the timer
    
    _ticks += 1;
    
    self.execLibrary.elapsed=_ticks;
    
    if(_execLibrary.M68KState == M68KSTATE_RUNNING){
        [_execLibrary schedule];
    }
    
    //if there are no running tasks... then slow the emulator down.
    if(_execLibrary.runningTaskCount<1){
        _execLibrary.M68KState = M68KSTATE_THROTTLED;
    }
    
    self.executionTimer = [NSTimer scheduledTimerWithTimeInterval:4/50 target:self selector:@selector(fiftyHertzTimer:) userInfo:nil repeats:NO];
}

-(void)bounce{
    _execLibrary.M68KState=M68KSTATE_STOPPED; //Pause CPU while we service the function call
    
    //uint32_t a6 = m68k_get_reg(NULL, M68K_REG_A6);    //A^ is supposed to contain the lib address... but i can work it out from the pc + lvo
    uint32_t pc = m68k_get_reg(NULL, M68K_REG_PC);      //this is always one word greater than the current instruction for the jumptable.
    
    //bump the CPU into Supervior mode set the SR flag
   // uint32_t SR = m68k_get_reg(NULL, M68K_REG_SR);
   // m68k_set_reg(M68K_REG_SR, SR | 0x1000);
    
    if(pc<4){
        
        uint32_t currentTask = self.execLibrary.thisTask;
        
        if(currentTask==0){
            m68k_set_reg(M68K_REG_PC, 0);
            return;
        }

        self.debugOutput.cout =[NSString stringWithFormat:@"\nTask: %s Terminated...\n",self.execLibrary.runningTask];
        [self.execLibrary remTask:currentTask];
        _execLibrary.M68KState=M68KSTATE_READY;
        return;
    }
    
    uint16_t lvo =*((uint16_t*) &_emulatorMemory[pc+2]);
    int lib = pc + lvo - 2;

    
    switch(lib){
        case      EXEC_BASE:[self.execLibrary       callFunction:lvo];break;
        case       DOS_BASE:[self.dosLibrary        callFunction:lvo];break;
        case       GFX_BASE:[self.graphicsLibrary   callFunction:lvo];break;
        case     INTUI_BASE:[self.intuitionLibrary  callFunction:lvo];break;
        case      ICON_BASE:[self.iconLibrary       callFunction:lvo];break;
        case      UTIL_BASE:[self.iconLibrary       callFunction:lvo];break;
        case     LAYER_BASE:[self.layersLibrary     callFunction:lvo];break;
        case   GADTOOL_BASE:[self.gadtoolsLibrary   callFunction:lvo];break;
        case  DISKFONT_BASE:[self.diskfontLibrary   callFunction:lvo];break;
        case   MATHFFP_BASE:[self.mathffpLibrary    callFunction:lvo];break;
        case MATHTRANS_BASE:[self.mathtransLibrary  callFunction:lvo];break;
        case EXPANSION_BASE:[self.expansionLibrary  callFunction:lvo];break;
    }
    
    //Put CPU back into User mode;
   // m68k_set_reg(M68K_REG_SR, SR & 0xFFFFEFFF);
    

    _execLibrary.M68KState=M68KSTATE_READY;
}





























// VERY OLD FUNCTION ORIGINALLY USED TO BOOTSTRAP THE EMULATOR
-(void)loadFile:(NSData*)file called:(NSString*)name{
    _execLibrary.M68KState=M68KSTATE_STOPPED;
    
    self.debugOutput.cout =[NSString stringWithFormat:@"\nEmulatron LoadSeg mk1: loading %s\n",[name UTF8String]];
    
    uint8_t* data =(uint8_t*)file.bytes;
    
    if(READ_LONG(data, 0) != HUNK_HEADER){
        self.debugOutput.cout =@"File is not executable\n";
        return;
    }
    
    if(READ_LONG(data, 4) != 0x0){
        self.debugOutput.cout =@"File corrupt\n";
        return;
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
        WRITE_LONG(_emulatorMemory,currentSegment-4,0xDEADC0DE);            //Null out the current segment's next hunk pointer.
        
        totalRamNeeded+=RAMSize;
        
        hunkLoc = hunkLoc + RAMSize + 4; //(put a 4 byte between hunks to keep them apart)
        
        //self.debugOutput.cout =[NSString stringWithFormat:@"0x%X (%d bytes)\n",hunkAddress[i],RAMSize];
        
        
        
    }
    self.debugOutput.cout =[NSString stringWithFormat:@"\ntotal Ram needed:%d\n\n",totalRamNeeded];
    
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
    
    m68k_set_reg(M68K_REG_PC, (uint32_t)hunkAddress[0]);
    
    char* mem =&_emulatorMemory[hunkAddress[7]];
    
    self.debugOutput.cout =@"Emulation started...!\n\n";
    _execLibrary.M68KState=M68KSTATE_READY;
}

@end
