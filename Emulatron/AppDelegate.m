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
@property (weak) IBOutlet NSSlider* instructionsPerQuantumSlider;
@property (weak) IBOutlet NSTextField* ipqLable;

@property (weak) IBOutlet NSButton* oneSecond;
@property (weak) IBOutlet NSButton* halfSecond;
@property (weak) IBOutlet NSButton* quaterSecond;
@property (weak) IBOutlet NSButton* eighthSecond;

@end

@implementation AppDelegate

-(IBAction)adjustIPQ:(id)sender{
    NSSlider* ipq = sender;
    NSString* message =@"Instructions per quantum: ";
    NSInteger value  = ipq.integerValue;
    
    self.ipqLable.stringValue =[message stringByAppendingFormat:@"%d",value];
    self.amiga.instructionsPerQuantum=value;
    
}

-(IBAction)adjustQuantum:(id)sender{
    
    float value=0.0;
    
    if(sender==_oneSecond)   {value=1.0;  }
    if(sender==_halfSecond)  {value=0.5;  }
    if(sender==_quaterSecond){value=0.25; }
    if(sender==_eighthSecond){value=0.125;}
    
    self.amiga.quantum = value;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    self.debugOutput.maxChar=65536;
    self.amiga =[[Emulator alloc]initWithDebug:self.debugOutput];
    
    self.disassemblerOutput.maxChar=4096;
    NSFont* font =[NSFont fontWithName:@"PT Mono" size:11];
    [self.disassemblerOutput  setFont:font];
    self.amiga.disassemblerOutput = self.disassemblerOutput;
    
    //set up GUI
    NSString* message =@"Instructions per quantum: ";
    self.ipqLable.stringValue =[message stringByAppendingFormat:@"%d",100];
    self.instructionsPerQuantumSlider.integerValue = self.amiga.instructionsPerQuantum;
    
    //Set up open file dialog
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
    
    //Allocate a nice lump of memory to keep Dpaint away from clock
    [self.amiga.execLibrary allocMem:1045504 with:4];
    
    fileURL =[NSURL URLWithString:@"file:///Users/Shared/uae/540/Work/DELUXEPAINT_IV/Dpaint"];
    segList = [self.amiga.dosLibrary loadSeg:fileURL];
    path = [fileURL absoluteString];
    name = [path lastPathComponent];
    [self.amiga.dosLibrary createProc:[name UTF8String] priority:-1 segList:segList stackSize:4096];
    
    
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
             
             NSURL* fileURL = [self.openDlg URL];
             uint32_t segList = [self.amiga.dosLibrary loadSeg:fileURL];
             NSString* path = [fileURL absoluteString];
             NSString* name = [path lastPathComponent];
             [self.amiga.dosLibrary createProc:[name UTF8String] priority:0 segList:segList stackSize:4096];

             
         }
         
     }
         
     ];
}
@end
