//
//  EMUConsoleView.m
//  Emulatron
//
//  Created by Matt Parsons on 16/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUConsoleView.h"

@implementation EMUConsoleView

-(void)setCout:(NSString*)output{

    NSString* newString;
    
    if(self.string.length>4096){
        NSString* temp = [self.string substringFromIndex:512];
        newString = [temp stringByAppendingString:output];
    }else{
        newString = [self.string stringByAppendingString:output];
    }
    
    self.string =newString;
}

-(void)delete:(id)sender{
    return;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
