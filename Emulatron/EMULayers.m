//
//  EMULayers.m
//  Emulatron
//
//  Created by Matt Parsons on 08/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMULayers.h"

@implementation EMULayers


-(void)setupLibNode{
    
    self.libVersion  = 37; // for now... i don't actually check it... so doesn't really matter
    self.libRevision = 34; // as above
    
    uint32_t namePtr = self.libData;    //locate the data space
    uint32_t libIDPtr = namePtr + [self writeString:"layers.library" toAddress:namePtr]; //write the name string there and generate the next free address
    self.libName = namePtr; //write the address of the string to the libNode
    
    [self writeString:"layers 37.34 (08 Feb 2017)" toAddress:libIDPtr]; //write the ID string to the data area
    self.libID = libIDPtr;  //write the address of the ID String to the lib structure.
    
}


@end
