//
//  AppDelegate.m
//  Emulatron
//
//  Created by Matt Parsons on 02/02/2017.
//  Copyright © 2017 Matt Parsons. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
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
    [_openDlg setPrompt:@"Load ADF"];
    //[_openDlg setAllowedFileTypes:fileTypes]; <--don't need this
    
    //[self openDocument:self];

    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/matt/Library/Mobile%20Documents/com~apple~CloudDocs/Type"]];
    [self.amiga loadFile:data toSegListAt:32];
    
    //NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/Shared/uae/540/Work/DELUXEPAINT_IV/Dpaint"]];
    //[self.amiga loadFile:data toSegListAt:16];
    
    //NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"file:///Users/Shared/uae/540/Workbench/C/List"]];
    //[self.amiga loadFile:data toSegListAt:0x400];
    
    //file:///Users/Shared/uae/540/Workbench/System/NoFastMem
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
             [self.amiga loadFile:data toSegListAt:8];          //<--8 is the first executable address on an amiga... but is in the exception table
             
         }
         
     }
         
     ];
}
@end
