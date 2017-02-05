//
//  EMUExec.h
//  Emulatron
//
//  Created by Matt Parsons on 03/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMULibrary.h"

@interface EMUExec : EMULibrary

@property (nonatomic,strong) NSMutableArray* freeFastList;
@property (nonatomic,strong) NSMutableArray* freeChipList;


-(NSInteger)addlibrary:(id)library;
@end
