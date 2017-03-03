//
//  EMUExec.h
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMULibBase.h"

#define M68KSTATE_STOPPED   00
#define M68KSTATE_THROTTLED 05
#define M68KSTATE_READY     10
#define M68KSTATE_RUNNING   15

@interface EMUExec : EMULibBase{
    uint32_t _elapsed;
    uint32_t _runningTaskCount;
    uint32_t _thisTask;
    char* _runningTask;
}

@property  (nonatomic)       NSInteger       M68KState;

@property (atomic,strong) NSMutableArray* freeFastList;
@property (atomic,strong) NSMutableArray* freeChipList;

@property (atomic,strong) NSMutableArray* busyFastList;
@property (atomic,strong) NSMutableArray* busyChipList;

-(void)addlibrary:(id)library;

-(uint32_t)thisTask;
-(void)setThisTask:(uint32_t)address;

-(char*)runningTask;
-(uint32_t)runningTaskCount;

-(uint32_t)elapsed;
-(void)setElapsed:(uint32_t)value;

-(void)schedule;

-(uint32_t)allocMem:(uint32_t)byteSize with:(uint32_t)requirements;
-(void)freeMem:(uint32_t)memoryBlock;
-(void)closeLibrary:(uint32_t)libNode;
-(uint32_t)openLibrary:(const char*)libName of:(uint32_t)version;

-(void)insert:(uint32_t)node behind:(uint32_t)pred inList:(uint32_t)list;
-(void)addHead:(uint32_t)node toList:(uint32_t)list;
-(void)addTail:(uint32_t)node toList:(uint32_t)list;
-(void)remove:(uint32_t)node;
-(uint32_t)remHead:(uint32_t)list;
-(uint32_t)remTail:(uint32_t)list;
-(void)enqueue:(uint32_t)node inList:(uint32_t)list;


-(uint32_t)addTask:(uint32_t)taskStruct initPC:(uint32_t)PC finalPC:(uint32_t)finalPC;
-(void)remTask:(uint32_t)task;

@end
