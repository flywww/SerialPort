//
//  SerialPortDataParser.swift
//  SerialPortApp
//
//  Created by 林盈志 on 09/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

import Cocoa

// MARK: - Formatter classes

class Formatter: NSObject, NSCoding {
    
    let formatterTypeStrArray:[String] = ["UInt8","UInt16","UInt24","UInt64","Int8","Int16","Int24","Int64","Header","Trailer"]
   enum formatterType:Int {
        case Uint8 = 0
        case Uint16 = 1
        case Uint24 = 2
        case Uint32 = 3
        case Int8 = 4
        case Int16 = 5
        case Int24 = 6
        case Int64 = 7
        case Header = 8
        case Trailer = 9
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
                case .Int64: self.size = 32
                case .Header: self.size = 8
                case .Trailer: self.size = 8
            }
        }
    }
    var value:Int64 = 0
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
        self.value = Int64(aDecoder.decodeInteger(forKey: "value"))
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
    var formatterArray:Array<Formatter> = []
}

protocol SPDataParserDelegate {
    //func didGetDataPacket(packet:SPPack)
    func didGetDataPacket(packetArray:Array<SPPack>)
    //func failToSolveDataPacket(aFailSolvingByteArray:Array<UInt8>,aFailRate:Float)
}

class SPDataParser: NSObject {
    var delegate : SPDataParserDelegate?
    var formatterArray:Array<Formatter> = []
    
    var byteBuff:Array<UInt8> = []
    let byteBuffSize = 500
    
    var header:Array<UInt8> = []
    var trailer:Array<UInt8> = []
    
    var bytePerPack = 0
    
    var solvedPackArray:Array<SPPack> = []
    
    init(formatterArray:Array<Formatter>){
        
        super.init()
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkSolvedPack), userInfo: nil, repeats: true);
        
        var bitPerPack = 0
        for formatter in formatterArray{
            if formatter.type == Formatter.formatterType.Header{
                self.header.append(UInt8(formatter.value))
            }else if(formatter.type == Formatter.formatterType.Trailer){
                self.trailer.append(UInt8(formatter.value))
            }
            
            bitPerPack += formatter.size
            self.bytePerPack = bitPerPack/8
            
        }
        self.formatterArray = formatterArray
        
    }
    
//    func parseSerialData(byteArray:Array<UInt8>){
//        
//        self.byteBuff.append(contentsOf: byteArray)
//        var unsolvedByteBuffSize = self.byteBuff.count
//        
//        var solvingByteBuff:Array<UInt8> = []
//        var solvingHeaderBuff:Array<UInt8> = []
//        var solvingTrailerBuff:Array<UInt8> = []
//        
//        
//        if self.byteBuff.count > byteBuffSize{
//            
//            var solvedByte = 0
//            
//            for buffIdx in 0..<self.byteBuff.count{
//                
//                if( unsolvedByteBuffSize > self.bytePerPack ){
//                    
//                    solvingByteBuff =  Array.init(self.byteBuff[ buffIdx..<(buffIdx + self.bytePerPack) ])
//                    solvingHeaderBuff = Array.init(solvingByteBuff[ 0..<self.header.count ])
//                    solvingTrailerBuff = Array.init(solvingByteBuff[ (solvingByteBuff.count - self.trailer.count)..<solvingByteBuff.count] )
//                    
//                    // TODO: - check fail rate
//                    
//                    if (solvingHeaderBuff == self.header) && (solvingTrailerBuff == self.trailer) {
//                        
//                        let solvedPack:SPPack = SPPack.init()
//                        
//                        for formatter in self.formatterArray{
//                            
//                            var solvingByteArray:Array<UInt8> = Array.init(solvingByteBuff[0..<(formatter.size/8)])
//                            solvingByteBuff.removeSubrange(0..<(formatter.size/8))
//                            
//                            var dataOutPut:UInt64 = 0
//                            for arrayIdx in 0..<solvingByteArray.count{
//                                let byteShift:UInt64 = 256 * UInt64(arrayIdx)
//                                dataOutPut = dataOutPut + UInt64(solvingByteArray[arrayIdx]) * (byteShift == 0 ? UInt64(1) : byteShift)
//                                solvedByte += 1
//                            }
//                            
//                            //BUG SHOOTING CODE
//                            if(solveUIntToIntData(with: formatter, and: dataOutPut) > 20000){
//                                
//                                print(solveUIntToIntData(with: formatter, and: dataOutPut))
//                            }
//                            
//                            solvedPack.dataArray.append(solveUIntToIntData(with: formatter, and: dataOutPut))
//                            solvedPack.formatterArray.append(formatter)
//                        }
//                        self.solvedPackArray.append(solvedPack)
//                    }
//                unsolvedByteBuffSize -= 1
//                }
//            }
//            print("total byte:\(self.byteBuff.count),unsolved byte \(unsolvedByteBuffSize),solvedByte \(solvedByte),byte lose \(self.byteBuff.count - (unsolvedByteBuffSize + solvedByte)),")
//            self.byteBuff.removeSubrange(0..<(self.byteBuff.count - unsolvedByteBuffSize))
//        }
//    }

    func parseSerialData(byteArray:Array<UInt8>){
        
        self.byteBuff.append(contentsOf: byteArray)
        
        var unsolvedByteBuffSize = self.byteBuff.count
        var solvingByteBuff:Array<UInt8> = []
        
        if self.byteBuff.count > byteBuffSize{
            
            var solvedByte = 0
            
            for buffIdx in 0..<self.byteBuff.count{
                
                if( unsolvedByteBuffSize > self.bytePerPack ){
                    
                    var headerChecker:Bool = false
                    var trailerChecker:Bool = false
                    
                    solvingByteBuff.append(self.byteBuff[buffIdx])
                    if solvingByteBuff.count > self.bytePerPack{
                        solvingByteBuff.remove(at: 0)
                    }
                    
                    if solvingByteBuff.count == self.bytePerPack{
                        headerChecker = true
                        trailerChecker = true
                        var trailerCount = 0
                        
                        for idx in 0..<solvingByteBuff.count{
                            
                            if(idx < self.header.count){
                                if solvingByteBuff[idx] != self.header[idx] { headerChecker = false }
                            }else if(idx >= solvingByteBuff.count - self.trailer.count ){
                                if solvingByteBuff[idx] != self.trailer[trailerCount] { trailerChecker = false }
                                trailerCount += 1
                            }
                        }
                    }
                    // TODO: - check fail rate
                    
                    if (headerChecker) && (trailerChecker) {
                        
                        let solvedPack:SPPack = SPPack.init()
                        
                        for formatter in self.formatterArray{
                            
                            var solvingByteArray:Array<UInt8> = Array.init(solvingByteBuff[0..<(formatter.size/8)])
                            solvingByteBuff.removeSubrange(0..<(formatter.size/8))
                            
                            var dataOutPut:UInt64 = 0
                            for arrayIdx in 0..<solvingByteArray.count{
                                let byteShift:UInt64 = 256 * UInt64(arrayIdx)
                                dataOutPut = dataOutPut + UInt64(solvingByteArray[arrayIdx]) * (byteShift == 0 ? UInt64(1) : byteShift)
                                solvedByte += 1
                            }
                            
                            solvedPack.dataArray.append(solveUIntToIntData(with: formatter, and: dataOutPut))
                            solvedPack.formatterArray.append(formatter)
                        }
                        self.solvedPackArray.append(solvedPack)
                    }
                    unsolvedByteBuffSize -= 1
                }
            }
            print("total byte:\(self.byteBuff.count),unsolved byte \(unsolvedByteBuffSize),solvedByte \(solvedByte),byte lose \(self.byteBuff.count - (unsolvedByteBuffSize + solvedByte)),")
            self.byteBuff.removeSubrange(0..<(self.byteBuff.count - unsolvedByteBuffSize))
        }
    }
    
    
    func  checkSolvedPack(){
        DispatchQueue.main.async {
                self.delegate?.didGetDataPacket(packetArray: self.solvedPackArray)
                self.solvedPackArray = []
        }
    }
    func solveUIntToIntData(with formatter:Formatter, and data:UInt64) -> Int64{
        
        var dataOutPut:Int64 = 0
        var modifiedData:UInt64 = 0
        
        switch formatter.type {
        case .Uint8,.Uint16,.Uint24,.Uint32,.Header,.Trailer:
            dataOutPut = Int64(data)
        case .Int8:
            modifiedData = (data > 0x0000007f) ? (data|0xffffffffffffff00) : (data)
            dataOutPut = Int64(bitPattern:modifiedData)
        case .Int16:
            modifiedData = (data > 0x00007fff) ? (data|0xffffffffffff0000) : (data)
            dataOutPut = Int64(bitPattern:modifiedData)
        case .Int24:
            modifiedData = (data > 0x007fffff) ? (data|0xffffffffff000000) : (data)
            dataOutPut = Int64(bitPattern:modifiedData)
        case .Int64:
            modifiedData = (data > 0x7fffffff) ? (data|0xffffffff00000000) : (data)
            dataOutPut = Int64(bitPattern:modifiedData)
        }

        return dataOutPut
    }

}


