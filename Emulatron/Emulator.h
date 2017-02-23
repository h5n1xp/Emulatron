//
//  Emulator.h
//  Emulatron
//
//  Created by Matt Parsons on 02/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMUConsoleView.h"

#import "EMUExec.h"
#import "EMUDos.h"
#import "EMUGraphics.h"
#import "EMUIntuition.h"
#import "EMUIcon.h"
#import "EMULayers.h"
#import "EMUGadtools.h"
#import "EMUDiskfont.h"
#import "EMUMathffp.h"
#import "EMUMathtrans.h"
#import "EMUExpansion.h"
#import "EMUUtility.h"




@interface Emulator : NSObject{
    uint32_t _ticks;            //the number of OS Quantums which have occured since starting.
}

@property (nonatomic,weak) EMUConsoleView* debugOutput;
@property (nonatomic,weak) EMUConsoleView *disassemblerOutput;

@property (nonatomic,strong) NSTimer*       executionTimer;
@property (nonatomic,strong) NSMutableData* addressSpace;
@property (nonatomic)        NSInteger      instructionsPerQuantum;
@property (nonatomic)        float          quantum;                //fractional seconds... 0.02 = 50th of a second
@property (nonatomic)        NSInteger      PALClockSpeed;

@property (nonatomic,strong) EMUExec*       execLibrary;
@property (nonatomic,strong) EMUDos*        dosLibrary;
@property (nonatomic,strong) EMUGraphics*   graphicsLibrary;
@property (nonatomic,strong) EMUIntuition*  intuitionLibrary;
@property (nonatomic,strong) EMUIcon*       iconLibrary;
@property (nonatomic,strong) EMULayers*     layersLibrary;
@property (nonatomic,strong) EMUUtility*    utilityLibrary;
@property (nonatomic,strong) EMUGadtools*   gadtoolsLibrary;
@property (nonatomic,strong) EMUDiskfont*   diskfontLibrary;
@property (nonatomic,strong) EMUMathffp*    mathffpLibrary;
@property (nonatomic,strong) EMUMathtrans*  mathtransLibrary;
@property (nonatomic,strong) EMUExpansion*  expansionLibrary;

-(Emulator*)initWithDebug:(EMUConsoleView*)console;
-(void)loadFile:(NSData*)file called:(NSString*)name;
-(void)restartCPU;
-(void)execute;
-(void)execute:(NSTimer*)timer;
-(void)bounce;

@end
