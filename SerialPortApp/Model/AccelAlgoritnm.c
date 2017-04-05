//
//  AccelAlgoritnm.c
//  SerialPortApp
//
//  Created by 林盈志 on 13/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

#include "AccelAlgoritnm.h"
#include "math.h"

static int16_t accelSqrtAvgArray[100];
static int16_t accelStableTHArray[100];

int16_t accelStableTH = 300;

int16_t getMovingAvgValue(int16_t, int16_t);
int16_t* accelArrayRefresh(int16_t []);
int16_t get_maxValue(int16_t [],int16_t);
int16_t get_minValue(int16_t [],int16_t);

ACCEL_MotionState get_AccelMotionState(ACCEL_Values accelValues){
   
    static int16_t accelSqrtAvgArray[100];
    static int16_t motionCount = 0;
    int16_t accelStableTH = 300;
    int32_t accelSqrtAvg;
    //int16_t accelMoveAvg;
    
    
    static ACCEL_MotionState motionState = unstableMotion;
    
    int16_t x = accelValues.ACCEL_X;
    int16_t y = accelValues.ACCEL_Y;
    int16_t z = accelValues.ACCEL_Z;
    
    accelSqrtAvg = (int32_t)sqrt(pow(x, 2)+pow(y, 2)+pow(z, 2));
    //accelMoveAvg = (int16_t)getMovingAvgValue(accelSqrtAvg, 100);
    
    for (int i=0; i<(sizeof(accelSqrtAvgArray)/2); i++) {
        accelSqrtAvgArray[i] = (i == sizeof(accelSqrtAvgArray)/2-1)?accelSqrtAvg:accelSqrtAvgArray[i+1];
    }
    
    int16_t accelSqrtRange = get_maxValue(accelSqrtAvgArray,100) - get_minValue(accelSqrtAvgArray,100);
    if(accelSqrtRange > accelStableTH){
            motionCount = 0;
            motionState = unstableMotion;
    }else{
        motionCount++;
        if(motionCount > 200){
            motionCount = 0;
            motionState = noMotion;
        }
    }
    return motionState;
}

int16_t getMovingAvgValue(int16_t data, int16_t avgPoints){
    
    static long long avg = 0;
    avg = (data + avg*(avgPoints -1));
    avg = avg /avgPoints;
    return avg;
}

int16_t get_maxValue(int16_t array[],int16_t size){
    int16_t maxValue = array[0];
    for(int16_t i = 1; i < size; i++){
        if(array[i] > maxValue){
            maxValue = array[i];
        }
    }
    return maxValue;
}

int16_t get_minValue(int16_t array[],int16_t size){
    
    int16_t minValue = array[0];
    for(int16_t i = 1; i < size; i++){
        if(array[i] < minValue){
            minValue = array[i];
        }
    }
    return minValue;
}
