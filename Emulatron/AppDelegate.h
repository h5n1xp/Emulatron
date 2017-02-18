//
//  AppDelegate.h
//  Emulatron
//
//  Created by Matt Parsons on 02/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Emulator.h"
#import "DisassemblerWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic,strong) Emulator* amiga;


-(IBAction)closeDisassemblerWindow:(id)sender;
    

@end

