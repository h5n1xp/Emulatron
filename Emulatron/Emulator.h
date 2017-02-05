//
//  Emulator.h
//  Emulatron
//
//  Created by Matt Parsons on 02/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMUExec.h"
#import "EMUDos.h"

@interface Emulator : NSObject{
    
    BOOL running;
    
};

@property (nonatomic,strong) NSTimer*       executionTimer;
@property (nonatomic,strong) NSMutableData* addressSpace;
@property (nonatomic)        NSInteger      instructionsPerQuantum;
@property (nonatomic)        float          quantum;                //fractional seconds... 0.02 = 50th of a second
@property (nonatomic)        NSInteger      PALClockSpeed;

@property (nonatomic,strong) EMUExec*   execLibrary;
@property (nonatomic,strong) EMUDos* dosLibrary;

-(void)loadFile:(NSData*)file toSegListAt:(NSInteger)address;
-(void)restartCPU;
-(void)execute;
-(void)execute:(NSTimer*)timer;
-(void)bounce;

@end
