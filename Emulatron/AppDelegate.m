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

@property (weak) IBOutlet NSWindow* window;
@property (weak) IBOutlet EMUConsoleView* debugOutput;
@property (nonatomic,strong) NSOpenPanel* openDlg;

@property (weak) IBOutlet DisassemblerWindow* DisassemblerWindow;
@property (weak) IBOutlet EMUConsoleView* disassemblerOutput;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    self.amiga =[[Emulator alloc]initWithDebug:self.debugOutput];
    
    NSFont* font =[NSFont fontWithName:@"PT Mono" size:11];
    [self.disassemblerOutput  setFont:font];
    self.amiga.disassemblerOutput = self.disassemblerOutput;
    
    
    _openDlg = [NSOpenPanel openPanel];
    [_openDlg setAllowsMultipleSelection:NO];
    [_openDlg setCanChooseDirectories:NO];
    [_openDlg setCanChooseFiles:YES];
    [_openDlg setFloatingPanel:YES];
    [_openDlg setPrompt:@"Load Program"];
    //[_openDlg setAllowedFileTypes:fileTypes]; <--don't need this
    

    //setup debug console


    //[self openDocument:self];
    //NSURL* fileURL = [NSURL URLWithString:@"file:///Users/matt/Library/Mobile%20Documents/com~apple~CloudDocs/Type"];

    
    //NSURL* fileURL =[NSURL URLWithString:@"file:///Users/Shared/uae/540/Work/DELUXEPAINT_IV/Dpaint"];

    
    //NSURL* fileURL =[NSURL URLWithString:@"file:///Users/Shared/uae/540/Workbench/C/List"];
    
    //NSURL* fileURL = [NSURL URLWithString:@"file:///Users/Shared/uae/540/Workbench/System/NoFastMem"];

    
    NSURL* fileURL =[NSURL URLWithString:@"file:///Users/Shared/uae/540/Workbench/Utilities/Clock"];

    
    //NSURL* fileURL =[NSURL URLWithString:@"file:///Users/Shared/uae/540/Work/Sysinfo/SysInfo"];

    uint32_t segList = [self.amiga.dosLibrary loadSeg:fileURL];
    NSString* path = [fileURL absoluteString];
    NSString* name = [path lastPathComponent];
    [self.amiga.dosLibrary createProc:[name UTF8String] priority:0 segList:segList stackSize:4096];
    
   // NSData* data = [NSData dataWithContentsOfURL:fileURL];
   // [self.amiga loadFile:data called:[[fileURL absoluteString] lastPathComponent]];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(IBAction)closeDisassemblerWindow:(id)sender{
    return;
}

-(void)openDocument:(id)sender{
    
    
    [_openDlg beginWithCompletionHandler:
     
     ^(NSInteger result){
         
         if(result == NSFileHandlingPanelOKButton){
             
             NSURL* file = [self.openDlg URL];
             printf("%s",[[file absoluteString] UTF8String]);
             NSData* data  =[NSData dataWithContentsOfURL:file];
                 [self.amiga loadFile:data called:[[file absoluteString] lastPathComponent]];
             
         }
         
     }
         
     ];
}
@end
