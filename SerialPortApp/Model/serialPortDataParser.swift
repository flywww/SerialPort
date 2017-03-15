//
//  serialPortDataParser.swift
//  SerialPortApp
//
//  Created by 林盈志 on 09/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

import Cocoa

protocol serielPortDataParserDelegate {
    func didGetAccelDataPacket(dataArray:NSArray)
}

class accelDataPacket: NSObject {
    var ACCEL_X:Int16 = 0
    var ACCEL_Y:Int16 = 0
    var ACCEL_Z:Int16 = 0
    var ACCEL_TEMP:Float = 0.0
}


class serialPortDataParser: NSObject {
    var delegate : serielPortDataParserDelegate?
    let dataBuffSize = 88 // (3 header + 8 data) * N
    
    let packetSize = 8
    var packetArray = NSMutableArray()
    
    var dataBuff:NSMutableArray = NSMutableArray()
    var headArray:NSMutableArray = NSMutableArray()

   //parseDataWithSerialPacket
    func parseSerailData(dataArray:NSArray) {
 
        dataBuff.addObjects(from: dataArray as [AnyObject])
        if dataBuff.count > dataBuffSize {
            
            var offset:Int = packetSize
            var tempData_L:UInt16 = 0
            var tempData_H:UInt16 = 0
            var accelDataX_L:UInt16 = 0
            var accelDataX_H:UInt16 = 0
            var accelDataY_L:UInt16 = 0
            var accelDataY_H:UInt16 = 0
            var accelDataZ_L:UInt16 = 0
            var accelDataZ_H:UInt16 = 0
            let packet =  accelDataPacket.init()
            
            for i in 0...(dataBuffSize-1){
                
                
                headArray.add(dataBuff[i])
                if headArray.count == 4 {
                   headArray.removeObject(at: 0)
                }
                
                if (headArray == [0x00,0xff,0x55]) {
                    offset = 0
                    
                }else if(offset < packetSize){
                    
                    switch offset {
                    case 0:
                        tempData_L = UInt16((dataBuff[i] as! NSNumber).int16Value)
                    case 1:
                        tempData_H = UInt16((dataBuff[i] as! NSNumber).int16Value)
                        packet.ACCEL_TEMP = Float(((tempData_L + (tempData_H << 8))as NSNumber).int16Value)
                    case 2:
                        accelDataX_L = UInt16((dataBuff[i] as! NSNumber).int16Value)
                    case 3:
                        accelDataX_H = UInt16((dataBuff[i] as! NSNumber).int16Value)
                        packet.ACCEL_X = ((accelDataX_L + (accelDataX_H << 8)) as NSNumber).int16Value
                    case 4:
                        accelDataY_L = UInt16((dataBuff[i] as! NSNumber).int16Value)
                    case 5:
                        accelDataY_H = UInt16((dataBuff[i] as! NSNumber).int16Value)
                        packet.ACCEL_Y = ((accelDataY_L + (accelDataY_H << 8)) as NSNumber).int16Value
                    case 6:
                        accelDataZ_L = UInt16((dataBuff[i] as! NSNumber).int16Value)
                    case 7:
                        accelDataZ_H = UInt16((dataBuff[i] as! NSNumber).int16Value)
                        packet.ACCEL_Z = ((accelDataZ_L + (accelDataZ_H << 8)) as NSNumber).int16Value
                        //print("T:\(packet.ACCEL_TEMP),X:\(packet.ACCEL_X),Y:\(packet.ACCEL_Y),Z:\(packet.ACCEL_Z)")
                        let accelValues = ACCEL_Values(ACCEL_X:packet.ACCEL_X,ACCEL_Y:packet.ACCEL_Y,ACCEL_Z:packet.ACCEL_Z,ACCEL_TEMP:Int16(packet.ACCEL_TEMP),ACCEL_STATUS:0)
                        
                        get_AccelMotionState(accelValues)
                        
                        packetArray.add(packet)
                        if packetArray.count > 20{
                            delegate?.didGetAccelDataPacket(dataArray: packetArray)
                            packetArray.removeAllObjects()
                        }
                    default:
                        ()
                    }
                    
                    offset += 1
                }
            }
            dataBuff.removeObjects(in: NSMakeRange(0, dataBuffSize))
        }
    }
}

