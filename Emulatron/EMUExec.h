//
//  EMUExec.h
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMULibBase.h"

@interface EMUExec : EMULibBase

@property (nonatomic,strong) NSMutableArray* freeFastList;
@property (nonatomic,strong) NSMutableArray* freeChipList;

@property (nonatomic,strong) NSMutableArray* busyFastList;
@property (nonatomic,strong) NSMutableArray* busyChipList;

-(void)addlibrary:(id)library;

-(uint32_t)thisTask;
-(void)setThisTask:(uint32_t)address;


-(uint32_t)allocMem:(uint32_t)byteSize with:(uint32_t)requirements;
-(void)freeMem:(uint32_t)memoryBlock;
-(void)closeLibrary:(uint32_t)libNode;
-(uint32_t)openLibrary:(const char*)libName of:(uint32_t)version;

@end
