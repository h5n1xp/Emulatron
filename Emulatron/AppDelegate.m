//
//  AppDelegate.m
//  Emulatron
//
//  Created by Matt Parsons on 02/02/2017.
//  Copyright © 2017 Matt Parsons. All rights reserved.
//

#import "AppDelegate.h"
#import "EMUConsoleView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet EMUConsoleView *debugOutput;
@property (nonatomic,strong) NSOpenPanel* openDlg;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    self.amiga =[[Emulator alloc]init];
    [self.amiga execute];
    
    _openDlg = [NSOpenPanel openPanel];
    [_openDlg setAllowsMultipleSelection:NO];
    [_openDlg setCanChooseDirectories:NO];
    [_openDlg setCanChooseFiles:YES];
    [_openDlg setFloatingPanel:YES];
    [_openDlg setPrompt:@"Load Program"];
    //[_openDlg setAllowedFileTypes:fileTypes]; <--don't need this
    

    //setup debug console
    self.amiga.debugOutput = self.debugOutput;

    //[self openDocument:self];
    
    //NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/matt/Library/Mobile%20Documents/com~apple~CloudDocs/Type"]];
    //[self.amiga loadFile:data toSegListAt:32];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/Shared/uae/540/Work/DELUXEPAINT_IV/Dpaint"]];
    [self.amiga loadFile:data toSegListAt:16];
    
    //NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/Shared/uae/540/Workbench/C/List"]];
    //[self.amiga loadFile:data toSegListAt:0x400];
    
    //NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/Shared/uae/540/Workbench/System/NoFastMem"]];
    //[self.amiga loadFile:data toSegListAt:0x400];
    
    // NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/Shared/uae/540/Workbench/Utilities/Clock"]];
    //[self.amiga loadFile:data toSegListAt:0x400];
    
    //NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/Shared/uae/540/Work/Sysinfo/SysInfo"]];
    //[self.amiga loadFile:data toSegListAt:0x400];
    
    //
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void)openDocument:(id)sender{
    
    
    [_openDlg beginWithCompletionHandler:
     
     ^(NSInteger result){
         
         if(result == NSFileHandlingPanelOKButton){
             
             NSURL* file = [self.openDlg URL];
             printf("%s",[[file absoluteString] UTF8String]);
             NSData* data  =[NSData dataWithContentsOfURL:file];
             [self.amiga loadFile:data toSegListAt:1024];          // <-- bottom of chipram is the first executable address on an amiga...
             
         }
         
     }
         
     ];
}
@end
