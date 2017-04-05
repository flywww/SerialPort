//
//  serialPortDataParser.swift
//  SerialPortApp
//
//  Created by 林盈志 on 09/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

import Cocoa

// MARK: - Formatter classes

class Formatter: NSObject, NSCoding {
    
    let formatterTypeStrArray:[String] = ["UInt8","UInt16","UInt24","UInt32","Int8","Int16","Int24","Int32","Header"]
   enum formatterType:Int {
        case Uint8 = 0
        case Uint16 = 1
        case Uint24 = 2
        case Uint32 = 3
        case Int8 = 4
        case Int16 = 5
        case Int24 = 6
        case Int32 = 7
        case Header = 8
    }
    
    var size:Int = 8
    var name:String = ""
    var type:formatterType = formatterType.Int8{
        didSet{
                switch self.type {
                case .Uint8: self.size = 8
                case .Uint16: self.size = 16
                case .Uint24: self.size = 24
                case .Uint32: self.size = 32
                case .Int8: self.size = 8
                case .Int16: self.size = 16
                case .Int24: self.size = 24
                case .Int32: self.size = 32
                case .Header: self.size = 8
            }
        }
    }
    var value:Int32 = 0
    var color:NSColor = NSColor.init(rgb:0xff5566)

    override init(){
        self.name = ""
        self.type = formatterType.Int8
        self.value = 0
        self.color = NSColor.init(rgb:0xff5566)
        self.size = 8
    }
    
    required init(coder aDecoder: NSCoder) {

        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.type = formatterType(rawValue: aDecoder.decodeInteger(forKey: "type") as Int)!
        self.value = Int32(aDecoder.decodeInteger(forKey: "value"))
        self.color = aDecoder.decodeObject(forKey: "color") as! NSColor
        self.size = aDecoder.decodeInteger(forKey: "size") 
    }
    
    func encode(with coder: NSCoder) {
        
        coder.encode(self.name, forKey: "name")
        coder.encode(self.type.rawValue, forKey: "type")
        coder.encode(self.value, forKey: "value")
        coder.encode(self.color, forKey: "color")
        coder.encode(self.size, forKey: "size")
    }
}

// MARK: - Data parser classes

class SPPack: NSObject {
    var dataArray:Array<Int64> = []
    var colorCodeArray:Array<NSColor> = []
    var formaterPack:Formatter = FormaterPack.init()
}

protocol SPDataParserDelegate {
    func didGetDataPacket(packet:SPPack)
}

class SPDataParser: NSObject {
    var delegate : SPDataParserDelegate?
    var formatterArray:Array<Formatter> = []
    
    var dataBuff:Array<UInt8> = []
    let dataBuffSize = 100
    
    var header:Array<UInt8> = []
    
    var bytePerPack = 0
    
    init(formatterArray:Array<Formatter>){
        
        var bitPerPack = 0
        for formatter in formatterArray{
            if formatter.type == Formatter.formatterType.Header{
                self.header.append(UInt8(formatter.value))
            }else{
                bitPerPack += formatter.size
                self.bytePerPack = bitPerPack/8
            }
        }
        self.formatterArray = formatterArray
    }
    
    func parseSerialData(dataArray:Array<UInt8>){
        
        self.dataBuff.append(contentsOf: dataArray)
        
        if self.dataBuff.count > self.dataBuffSize{
            
            var headerBuff:Array<UInt8> = []
            var unsolvedDataBuffSize = self.dataBuff.count
            
            for ( buffIdx ,data ) in dataBuff.enumerated(){
                if( unsolvedDataBuffSize >= (self.bytePerPack) ){
                    if( headerBuff == header ){

                        for ( _ ,formatter) in self.formatterArray.enumerated(){
                            
                            var dataOutPut:Int64 = 0
                            var dataOutPutTemp:UInt64 = 0
                            var solvingDataBuff = dataBuff[buffIdx..<(buffIdx + self.bytePerPack)]
                            let solvedPack:SPPack = SPPack.init()
                            
                            for byteIdx in 0..<(formatter.size/8){
                                dataOutPutTemp = dataOutPutTemp << 8 + UInt64(solvingDataBuff[byteIdx])
                            }
                            
                            switch formatter.type {
                            case .Uint8,.Uint16,.Uint24,.Uint32:
                                dataOutPut = Int64(dataOutPutTemp)
                            case .Int8:
                                dataOutPutTemp = (dataOutPutTemp > 0x0000007f) ? (dataOutPutTemp|0xffffffffffffff00) : (dataOutPutTemp)
                                dataOutPut = Int64(bitPattern:dataOutPutTemp)
                            case .Int16:
                                dataOutPutTemp = (dataOutPutTemp > 0x00007fff) ? (dataOutPutTemp|0xffffffffffff0000) : (dataOutPutTemp)
                                dataOutPut = Int64(bitPattern:dataOutPutTemp)
                            case .Int24:
                                dataOutPutTemp = (dataOutPutTemp > 0x007fffff) ? (dataOutPutTemp|0xffffffffff000000) : (dataOutPutTemp)
                                dataOutPut = Int64(bitPattern:dataOutPutTemp)
                            case .Int32:
                                dataOutPutTemp = (dataOutPutTemp > 0x7fffffff) ? (dataOutPutTemp|0xffffffff00000000) : (dataOutPutTemp)
                                dataOutPut = Int64(bitPattern:dataOutPutTemp)
                            default:
                                ()
                            }
                            solvedPack.dataArray.append(dataOutPut)
                            solvedPack.colorCodeArray.append(formatter.color)
                            solvedPack.formaterPack = formatter
                            delegate?.didGetDataPacket(packet: solvedPack)
                        }
                    }
                    headerBuff.append(data)
                    if (headerBuff.count > header.count){headerBuff.remove(at: 0)}
                    unsolvedDataBuffSize -= 1
                    
                }else{
                
                    self.dataBuff.removeSubrange(0..<unsolvedDataBuffSize)
                }
            }
        }
    }
}

