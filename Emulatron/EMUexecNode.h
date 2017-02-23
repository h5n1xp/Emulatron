//
//  EMUexecNode.h
//  Emulatron
//
//  Created by Matt Parsons on 23/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMUexecNode : NSObject{
    
    uint32_t       _next;
    uint32_t       _prev;
    unsigned char  _type;
    char           _priority;
    uint32_t       _name;
    uint32_t       _list;
    unsigned char* _nodeName;
    
}

@property (nonatomic) uint32_t address;

+(EMUexecNode*)nodeAtAddress:(uint32_t)nodeAddress;

-(uint32_t)next;
-(void)setNext:(uint32_t)nextAddress;
-(uint32_t)prev;
-(void)setPrev:(uint32_t)prevAddress;
-(unsigned char)type;
-(void)setType:(unsigned char)type;
-(char)priority;
-(void)setPriority:(char)priority;
-(uint32_t)name;
-(void)setName:(uint32_t)nameAddress;

@end
