//
//  EMUMemoryBlock.m
//  Emulatron
//
//  Created by Matt Parsons on 07/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUMemoryBlock.h"

@implementation EMUMemoryBlock

-(instancetype)initWithSize:(uint32_t)size atAddress:(uint32_t)address{
    self = [super init];
    
    self.size   = size;
    self.address = address;
    return self;
}

@end
