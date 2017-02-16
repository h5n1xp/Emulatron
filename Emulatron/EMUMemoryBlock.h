//
//  EMUMemoryBlock.h
//  Emulatron
//
//  Created by Matt Parsons on 07/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMUMemoryBlock : NSObject

@property (nonatomic) uint32_t address;
@property (nonatomic) uint32_t size;
@property (nonatomic) uint32_t attributes;
@property (nonatomic) uint32_t owner;
@property (nonatomic) unsigned char* physicalAddress;

-(instancetype)initWithSize:(uint32_t)size atAddress:(uint32_t)address;

@end
