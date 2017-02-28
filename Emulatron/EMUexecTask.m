//
//  EMUexecTask.m
//  Emulatron
//
//  Created by Matt Parsons on 24/02/2017.
//  Copyright © 2017 Matt Pasons. All rights reserved.
//

#import "EMUexecTask.h"

@implementation EMUexecTask


-(unsigned char)tc_Flags{
    _tc_Flags  = READ_BYTE(_memory,self.address+14);
    return _tc_Flags;
}
-(void)setTc_Flags:(unsigned char)value{
    _tc_Flags  = value;
    WRITE_BYTE(_memory,self.address+14,value);
}

-(unsigned char)tc_State{
    _tc_State = READ_BYTE(_memory,self.address+15);
    return _tc_State;
}
-(void)setTc_State:(unsigned char)value{
     _tc_State = value;
    WRITE_BYTE(_memory,self.address+15,value);
}

-(char)tc_IDNestCnt{
    _tc_IDNestCnt = READ_BYTE(_memory,self.address+16);
    return _tc_IDNestCnt;
}
-(void)setTc_IDNestCnt:(char)value{
    _tc_IDNestCnt = value;
    WRITE_BYTE(_memory,self.address+16,value);
}

-(char)tc_TDNestCnt{
    _tc_TDNestCnt = READ_BYTE(_memory,self.address+17);
    return _tc_TDNestCnt;
}
-(void)setTc_TDNestCnt:(unsigned char)value{
    _tc_TDNestCnt = value;
    WRITE_BYTE(_memory,self.address+17,value);
}

-(uint32_t)tc_SigAlloc{
    _tc_SigAlloc = READ_LONG(_memory,self.address+18);
    return _tc_SigAlloc;
}
-(void)setTc_SigAlloc:(uint32_t)value{
    _tc_SigAlloc = value;
    WRITE_LONG(_memory,self.address+18,value);
}

-(uint32_t)tc_SigWait{
    _tc_SigWait = READ_LONG(_memory,self.address+22);
    return _tc_SigWait;
}
-(void)setTc_SigWait:(uint32_t)value{
    _tc_SigWait = value;
    WRITE_LONG(_memory,self.address+22,value);
}

-(uint32_t)tc_SigRecvd{
    _tc_SigRecvd = READ_LONG(_memory,self.address+26);
    return _tc_SigRecvd;
}
-(void)setTc_SigRecvd:(uint32_t)value{
    _tc_SigRecvd = value;
    WRITE_LONG(_memory,self.address+26,value);
}

-(uint32_t)tc_SigExcept{
    _tc_SigExcept = READ_LONG(_memory,self.address+30);
    return _tc_SigExcept;
}
-(void)setTc_SigExcept:(uint32_t)value{
    _tc_SigExcept = value;
    WRITE_LONG(_memory,self.address+30,value);
}

-(uint16_t)tc_TrapAlloc{
    _tc_TrapAlloc = READ_WORD(_memory,self.address+34);
    return _tc_TrapAlloc;
}
-(void)setTc_TrapAlloc:(uint16_t)value{
    _tc_TrapAlloc = value;
    WRITE_WORD(_memory,self.address+34,value);
}

-(uint16_t)tc_TrapAble{
    _tc_TrapAble = READ_WORD(_memory,self.address+36);
    return _tc_TrapAble;
}
-(void)setTc_TrapAble:(uint16_t)value{
    _tc_TrapAble = value;
    WRITE_WORD(_memory,self.address+36,value);
}

-(uint32_t)tc_ExceptData{
    _tc_ExceptData = READ_LONG(_memory,self.address+38);
    return _tc_ExceptData;
}
-(void)setTc_ExceptData:(uint32_t)value{
    _tc_ExceptData = value;
    WRITE_LONG(_memory,self.address+38,value);
}

-(uint32_t)tc_ExceptCode{
    _tc_ExceptCode = READ_LONG(_memory,self.address+42);
    return _tc_ExceptCode;
}
-(void)setTc_ExceptCode:(uint32_t)value{
    _tc_ExceptCode = value;
    WRITE_LONG(_memory,self.address+42,value);
}

-(uint32_t)tc_TrapData{
    _tc_TrapData = READ_LONG(_memory,self.address+46);
    return _tc_TrapData;
}
-(void)setTc_TrapData:(uint32_t)value{
    _tc_TrapData = value;
    WRITE_LONG(_memory,self.address+46,value);
}

-(uint32_t)tc_TrapCode{
    _tc_TrapCode = READ_LONG(_memory,self.address+50);
    return _tc_TrapCode;
}
-(void)setTc_TrapCode:(uint32_t)value{
    _tc_TrapCode = value;
    WRITE_LONG(_memory,self.address+50,value);
}

-(uint32_t)tc_SPReg{
    _tc_SPReg = READ_LONG(_memory,self.address+54);
    return _tc_SPReg;
}
-(void)setTc_SPReg:(uint32_t)value{
    _tc_SPReg = value;
    WRITE_LONG(_memory,self.address+54,value);
}

-(uint32_t)tc_SPLower{
    _tc_SPLower = READ_LONG(_memory,self.address+58);
    return _tc_SPLower;
}
-(void)setTc_SPLower:(uint32_t)value{
    _tc_SPLower = value;
    WRITE_LONG(_memory,self.address+58,value);
}

-(uint32_t)tc_SPUpper{
    _tc_SPUpper = READ_LONG(_memory,self.address+62);
    return _tc_SPUpper;
}
-(void)setTc_SPUpper:(uint32_t)value{
    _tc_SPUpper = value;
    WRITE_LONG(_memory,self.address+62,value);
}

-(uint32_t)tc_Switch{
    _tc_Switch = READ_LONG(_memory,self.address+66);
    return _tc_Switch;
}
-(void)setTc_Switch:(uint32_t)value{
    _tc_Switch = value;
    WRITE_LONG(_memory,self.address+66,value);
}

-(uint32_t)tc_Launch{
    _tc_Launch = READ_LONG(_memory,self.address+70);
    return _tc_Launch;
}
-(void)setTc_Launch:(uint32_t)value{
    _tc_Launch = value;
    WRITE_LONG(_memory,self.address+70,value);
}

-(uint32_t)tc_MemEntryPtr{
    _tc_MemEntryPtr = self.address+74;
    return _tc_MemEntryPtr;
}

-(uint32_t)tc_UserData{
    _tc_UserData = READ_LONG(_memory,self.address+88);
    return _tc_UserData;
}
-(void)setTc_UserData:(uint32_t)value{
    _tc_UserData = value;
    WRITE_LONG(_memory,self.address+88,value);
}


@end
