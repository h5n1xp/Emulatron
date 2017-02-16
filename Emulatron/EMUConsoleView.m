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
    
    NSString* newString = [self.string stringByAppendingString:output];

    self.string =newString;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
