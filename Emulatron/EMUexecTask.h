//
//  EMUexecTask.h
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecNode.h"

@interface EMUexecTask : EMUexecNode{
    
    unsigned char _tc_Flags;
    unsigned char _tc_State;
    char          _tc_IDNestCnt;   /* intr disabled nesting */
    char          _tc_TDNestCnt;   /* task disabled nesting */
    uint32_t      _tc_SigAlloc;    /* sigs allocated */
    uint32_t      _tc_SigWait;     /* sigs we are waiting for */
    uint32_t      _tc_SigRecvd;    /* sigs we have received */
    uint32_t      _tc_SigExcept;   /* sigs we will take excepts for */
    uint16_t      _tc_TrapAlloc;   /* traps allocated */
    uint16_t      _tc_TrapAble;    /* traps enabled */
    uint32_t      _tc_ExceptData;  /* points to except data */
    uint32_t      _tc_ExceptCode;  /* points to except code */
    uint32_t      _tc_TrapData;    /* points to trap code */
    uint32_t      _tc_TrapCode;    /* points to trap data */
    uint32_t      _tc_SPReg;       /* stack pointer */
    uint32_t      _tc_SPLower;     /* stack lower bound */
    uint32_t      _tc_SPUpper;     /* stack upper bound + 2*/
    uint32_t      _tc_Switch;      /* task losing CPU */
    uint32_t      _tc_Launch;      /* task getting CPU */
    uint32_t      _tc_MemEntryPtr; /* allocated memory List header pointer */
    uint32_t      _tc_UserData;    /* per task data */
    
}


-(unsigned char)tc_Flags;
-(void)setTc_Flags:(unsigned char)value;

-(unsigned char)tc_State;
-(void)setTc_State:(unsigned char)value;

-(char)tc_IDNestCnt;        // intr disabled nesting
-(void)setTc_IDNestCnt:(char)value;

-(char)tc_TDNestCnt;        // task disabled nesting
-(void)setTc_TDNestCnt:(unsigned char)value;

-(uint32_t)tc_SigAlloc;    // sigs allocated
-(void)setTc_SigAlloc:(uint32_t)value;

-(uint32_t)tc_SigWait;     // sigs we are waiting for
-(void)setTc_SigWait:(uint32_t)value;

-(uint32_t)tc_SigRecvd;    // sigs we have received
-(void)setTc_SigRecvd:(uint32_t)value;

-(uint32_t)tc_SigExcept;   // sigs we will take excepts for
-(void)setTc_SigExcept:(uint32_t)value;

-(uint16_t)tc_TrapAlloc;   // traps allocated
-(void)setTc_TrapAlloc:(uint16_t)value;

-(uint16_t)tc_TrapAble;    // traps enabled
-(void)setTc_TrapAble:(uint16_t)value;

-(uint32_t)tc_ExceptData;  // points to except data
-(void)setTc_ExceptData:(uint32_t)value;

-(uint32_t)tc_ExceptCode;  // points to except code
-(void)setTc_ExceptCode:(uint32_t)value;

-(uint32_t)tc_TrapData;    // points to trap code
-(void)setTc_TrapData:(uint32_t)value;

-(uint32_t)tc_TrapCode;    // points to trap data
-(void)setTc_TrapCode:(uint32_t)value;

-(uint32_t)tc_SPReg;       // stack pointer
-(void)setTc_SPReg:(uint32_t)value;

-(uint32_t)tc_SPLower;     // stack lower bound
-(void)setTc_SPLower:(uint32_t)value;

-(uint32_t)tc_SPUpper;     // stack upper bound + 2
-(void)setTc_SPUpper:(uint32_t)value;

-(uint32_t)tc_Switch;       // task losing CPU
-(void)setTc_Switch:(uint32_t)value;

-(uint32_t)tc_Launch;       // task getting CPU
-(void)setTc_Launch:(uint32_t)value;

-(uint32_t)tc_MemEntryPtr;// allocated memory List


-(uint32_t)tc_UserData;    // per task data
-(void)setTc_UserData:(uint32_t)value;

@end
