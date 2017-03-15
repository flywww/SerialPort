//
//  ViewController.swift
//  SerialPortApp
//
//  Created by 林盈志 on 07/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

import Cocoa

let kAccelPlotIdentifier:String = "kAccelPlotIdentifier"


class ViewController: NSViewController,ORSSerialPortDelegate,serielPortDataParserDelegate,CPTPlotDelegate{
//CPTPlotDataSource
    //Graph plot variables
    
    var accelDataArray:Array<accelDataPacket> = []
    
    //Serial port variables
    let serialPortManager = ORSSerialPortManager.shared()
    var serialPort: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            serialPort?.delegate = self
        }
    }
    
    lazy var SPDataParser:serialPortDataParser! = {
        self.SPDataParser = serialPortDataParser.init()
        self.SPDataParser.delegate = self
        return self.SPDataParser
        }()

    @IBOutlet weak var serialPortSelector: NSPopUpButton!{
        didSet{
            var serialPortNames:[String] = []
            for port in self.serialPortManager.availablePorts {
                serialPortNames.append(port.name)
                //serialPortNames.insert(port.name, at: 0)
            }
            serialPortSelector.removeAllItems()
            serialPortSelector.addItems(withTitles:serialPortNames)
            serialPortSelector.action = #selector(serialPortConfig)
            serialPortSelector.target = self
            serialPortSelector.selectItem(at: 0)
        }
    }
    @IBOutlet weak var bautRateSelector: NSPopUpButton!{
        didSet{
            let bautRate:[String] = ["0","50","75","110","134","150","200","300","600","1200","1800","2400","4800","9600","19200","38400","7200","14400","28800","57600","76800","115200","230400"]
            bautRateSelector.removeAllItems()
            bautRateSelector.addItems(withTitles:bautRate)
            bautRateSelector.action = #selector(serialPortConfig)
            bautRateSelector.target = self
            bautRateSelector.selectItem(at: bautRate.index(of: "115200")!)
        }
    }
    @IBOutlet weak var stopBitSelector: NSPopUpButton!{
        didSet{
            let stopBit:[String] = ["1","2"]
            stopBitSelector.removeAllItems()
            stopBitSelector.addItems(withTitles: stopBit)
            stopBitSelector.action = #selector(serialPortConfig)
            stopBitSelector.target = self
            stopBitSelector.selectItem(at: stopBit.index(of:"1")!)
        }
    }
    @IBOutlet weak var paritySelector: NSPopUpButton!{
        didSet{
            let parity:[String] = ["Non","Odd","Even"]
            paritySelector.removeAllItems()
            paritySelector.addItems(withTitles: parity)
            paritySelector.action = #selector(serialPortConfig)
            paritySelector.target = self
            paritySelector.selectItem(at: parity.index(of: "Non")!)
        }
    }
    @IBOutlet weak var characterSizeSelector: NSPopUpButton!{
        didSet{
            let cs:[String] = ["5","6","7","8"]
            characterSizeSelector.removeAllItems()
            characterSizeSelector.addItems(withTitles: cs)
            characterSizeSelector.action = #selector(serialPortConfig)
            characterSizeSelector.target = self
            characterSizeSelector.selectItem(at: cs.index(of: "8")!)
        }
    }
    @IBOutlet weak var RTSCTSBtn: NSButton!{
        didSet{
            RTSCTSBtn.setButtonType(NSButtonType.switch)
            RTSCTSBtn.title = "ON"
            RTSCTSBtn.target = self
            RTSCTSBtn.action = #selector(serialPortConfig)
        }
    }
    @IBOutlet weak var DTRSRFBtn: NSButton!{
        didSet{
            DTRSRFBtn.setButtonType(NSButtonType.switch)
            DTRSRFBtn.title = "ON"
            DTRSRFBtn.target = self
            DTRSRFBtn.action = #selector(serialPortConfig)
        }
    }
    @IBOutlet weak var serialPortOpenBtn: NSButton!{
        didSet{
            serialPortOpenBtn.target = self
            serialPortOpenBtn.action = #selector(serialPortBtnAction)
        }
    }
    @IBOutlet weak var serialPortInfoLable: NSTextField!
    
    
    @IBOutlet weak var testView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let accelGraphHostView:CPTGraphHostingView = CPTGraphHostingView.init()
        //let accelGraphHostView:NSView = NSView.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        accelGraphHostView.wantsLayer = true
        accelGraphHostView.layer?.backgroundColor = NSColor.blue.cgColor
        
        accelGraphHostView.translatesAutoresizingMaskIntoConstraints = false
        
        self.testView.wantsLayer = true
        self.testView.layer?.backgroundColor = NSColor.red.cgColor
        
        self.view.addSubview(accelGraphHostView)
    
        
        accelGraphHostView.leadingAnchor.constraint(equalTo: self.testView.leadingAnchor, constant:-5).isActive = true
        accelGraphHostView.topAnchor.constraint(equalTo: self.testView.topAnchor,constant:-5).isActive = true
        accelGraphHostView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        accelGraphHostView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        
        
        
        super.updateViewConstraints()
        
        //NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint, heightConstaint, wigthConstaint])

        
        
//        let accelGraph:CPTGraph = self.createLinGraph(identifier: kAccelPlotIdentifier,
//                                                      hostView: accelGraphHostView,
//                                                      start: 0,
//                                                      length: 200)
        //accelGraph.delegate = self
        
        
        
        
        
//      self.ecgArray = [[NSMutableArray alloc]init];  
//        self.ecgHostView = [self createHostingViewWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 350)];
//        [self.ecgHostView.heightAnchor constraintEqualToConstant:350].active = true;
//        [self.ecgHostView.widthAnchor constraintEqualToConstant:self.view.frame.size.width].active = true;
//        self.ecgGraph = [self createLineGraphWithIdentifier:kECGIndentifier onHostingView:self.ecgHostView withStart:-0.5 withUnit:1];
        
        
        
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    //MARK: - Interface compoments action
    
    func serialPortBtnAction() {
        if self.serialPortOpenBtn.title == "OPEN" {
            self.serialPortOpenBtn.title = "CLOSE"
            serialPortConfig()
            self.serialPort?.open()
            self.bautRateSelector.isEnabled = false
            self.serialPortSelector.isEnabled = false
            self.stopBitSelector.isEnabled = false
            self.paritySelector.isEnabled = false
            self.characterSizeSelector.isEnabled = false
            self.RTSCTSBtn.isEnabled = false
            self.DTRSRFBtn.isEnabled = false
            
        }else if serialPortOpenBtn.title == "CLOSE"{
            self.serialPortOpenBtn.title = "OPEN"
            self.serialPort?.close()
            self.serialPort?.open()
            self.bautRateSelector.isEnabled = true
            self.serialPortSelector.isEnabled = true
            self.stopBitSelector.isEnabled = true
            self.paritySelector.isEnabled = true
            self.characterSizeSelector.isEnabled = true
            self.RTSCTSBtn.isEnabled = true
            self.DTRSRFBtn.isEnabled = true
        }
    }

    //MARK: - Graph plot functions
    
    func createHostingView(frame:CGRect) -> CPTGraphHostingView {
        let hostView:CPTGraphHostingView = CPTGraphHostingView.init(frame: frame)
        return hostView
    }
    
    func createLinGraph(identifier:String,hostView:CPTGraphHostingView,start:Float,length:NSInteger) -> CPTGraph {
        let graph:CPTGraph = CPTGraph.init(frame: hostView.frame)
        hostView.hostedGraph = graph
        return graph
    }
    
    //MARK: - Graph plot delegate
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return 4
    }
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> NSNumber! {
        return 1
    }
    
    
    //MARK: - Serial port configuration
    
   func serialPortConfig() {
    
        self.serialPort?.close()
        self.serialPort = self.serialPortManager.availablePorts[self.serialPortSelector.indexOfSelectedItem]
        self.serialPort?.baudRate = NSNumber(value:Int(self.bautRateSelector.titleOfSelectedItem!)!)
        self.serialPort?.numberOfStopBits = UInt(self.stopBitSelector.titleOfSelectedItem!)!
        switch self.paritySelector.titleOfSelectedItem! {
            case "Non":
                self.serialPort?.parity = ORSSerialPortParity.none
            case "Odd":
                self.serialPort?.parity = ORSSerialPortParity.odd
            case "Even":
                self.serialPort?.parity = ORSSerialPortParity.even
            default:
                ()
        }
        switch self.characterSizeSelector.titleOfSelectedItem! {
            case "5":
                self.serialPort?.characterSize = ORSSerialPortCharSize.size5
            case "6":
                self.serialPort?.characterSize = ORSSerialPortCharSize.size6
            case "7":
                self.serialPort?.characterSize = ORSSerialPortCharSize.size7
            case "8":
                self.serialPort?.characterSize = ORSSerialPortCharSize.size8
            default:
                ()
        }
        self.serialPort?.usesRTSCTSFlowControl = Bool(self.RTSCTSBtn.state as NSNumber)
        self.serialPort?.usesDTRDSRFlowControl = Bool(self.DTRSRFBtn.state as NSNumber)
    }

    // MARK: - ORSSerialPort delegate
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        if let string = NSString(data: data, encoding: String.Encoding.ascii.rawValue) {
            //print("\nReceived: \"\(string)\" \(data)", terminator: "\n")
        }
        
        let uint8Ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        uint8Ptr.initialize(from: data)
        let buffArray:NSMutableArray = NSMutableArray()
        
        for i in 0...(data.count - 1){
            let val = uint8Ptr[i]
            buffArray.add(val)
        }
        self.SPDataParser.parseSerailData(dataArray:buffArray )
        buffArray.removeAllObjects()
    }
    
    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        self.serialPort = nil
        //self.openCloseButton.title = "Open"
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        //print("SerialPort \(serialPort) encountered an error: \(error)")
    }
    
    // MARK: - serial port parser delegate
    func didGetAccelDataPacket(dataArray: NSArray) {
        //print("receive dataArray:\(dataArray)")
        
        accelDataArray = accelDataArray + (dataArray as! Array<accelDataPacket>)
        
        
        
        
        
        let t = (dataArray[0] as! accelDataPacket).ACCEL_TEMP
        let x = (dataArray[0] as! accelDataPacket).ACCEL_X
        let y = (dataArray[0] as! accelDataPacket).ACCEL_Y
        let z = (dataArray[0] as! accelDataPacket).ACCEL_Z
        self.serialPortInfoLable.stringValue = String(format: "T:%0.1f, X:%d, Y:%d, Z:%d\n",t,x,y,z)
    }
    

}

