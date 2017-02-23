//
//  EMUConsoleView.h
//  Emulatron
//
//  Created by Matt Parsons on 16/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EMUConsoleView : NSTextView 

@property (nonatomic) NSInteger maxChar;

-(void)setCout:(NSString*)output;


@end


