//
//  AccelAlgoritnm.h
//  SerialPortApp
//
//  Created by 林盈志 on 13/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

#ifndef AccelAlgoritnm_h
#define AccelAlgoritnm_h

#include <stdio.h>

typedef struct
{
    int16_t ACCEL_X;
    int16_t ACCEL_Y;
    int16_t ACCEL_Z;
    int16_t ACCEL_TEMP;
    uint16_t ACCEL_STATUS;
    
}ACCEL_Values;

typedef enum motionState
{
    noMotion = 0,
    unstableMotion = 1,
    stableMotion = 2
    
}ACCEL_MotionState;

ACCEL_MotionState get_AccelMotionState(ACCEL_Values values);


#endif /* AccelAlgoritnm_h */
