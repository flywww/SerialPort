//
//  MainViewController.swift
//  SerialPortApp
//
//  Created by 林盈志 on 07/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

import Cocoa

let kAccelPlotIdentifier:String = "kAccelPlotIdentifier"
let kAccelTPlotIdentifier:String = "kAccelTPlotIdentifier"
let kAccelXPlotIdentifier:String = "kAccelXPlotIdentifier"
let kAccelYPlotIdentifier:String = "kAccelYPlotIdentifier"
let kAccelZPlotIdentifier:String = "kAccelZPlotIdentifier"


class MainViewController: NSViewController,ORSSerialPortDelegate,serielPortDataParserDelegate,CPTPlotDelegate,CPTPlotDataSource{

    //Graph plot variables
    
    var accelDataArray:Array<accelDataPacket> = []
    var accelTDataArray:[Float] = []
    var accelXDataArray:[Int16] = []
    var accelYDataArray:[Int16] = []
    var accelZDataArray:[Int16] = []
    let plotDataSize = 1000
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
    @IBOutlet weak var serialPortInfoLable: NSTextField!{
        didSet{
            serialPortInfoLable.font = NSFont.init(name: "Helvetica Neue", size: 10)
        }
    }
    
    @IBOutlet weak var spPanelContainerView: NSView!
    @IBOutlet weak var spPlotContainerView: NSView!
    @IBOutlet weak var spFuncTabView: NSTabView!
    
   
    var accelGraphHostView:CPTGraphHostingView!
    var accelGraph:CPTGraph!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.spPanelContainerView.wantsLayer = true
        
        self.accelGraphHostView = self.createHostingView(frame: self.spPlotContainerView.bounds)
        self.accelGraphHostView.wantsLayer = true
        self.accelGraphHostView.translatesAutoresizingMaskIntoConstraints = false
        
        self.spPlotContainerView.addSubview(accelGraphHostView)

        self.accelGraphHostView.topAnchor.constraint(equalTo: self.spPlotContainerView.topAnchor).isActive = true
        self.accelGraphHostView.bottomAnchor.constraint(equalTo: self.spPlotContainerView.bottomAnchor).isActive = true
        self.accelGraphHostView.leadingAnchor.constraint(equalTo: self.spPlotContainerView.leadingAnchor).isActive = true
        self.accelGraphHostView.trailingAnchor.constraint(equalTo: self.spPlotContainerView.trailingAnchor).isActive = true
    
        self.accelGraph = self.createLinGraph(identifier: kAccelPlotIdentifier,
                                              hostView: self.accelGraphHostView,
                                              start: 0,
                                              length: self.accelDataArray.count)
        
        self.view.layoutSubtreeIfNeeded()
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
            self.serialPortConfig()
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
        
        let hostViewBounds:CGRect = hostView.frame
        let graph:CPTGraph = CPTXYGraph.init(frame:hostViewBounds)
        hostView.hostedGraph = graph
        
        graph.plotAreaFrame?.paddingTop    = 10
        graph.plotAreaFrame?.paddingRight  = 10
        graph.plotAreaFrame?.paddingBottom = 10
        graph.plotAreaFrame?.paddingLeft   = 10
        graph.plotAreaFrame?.masksToBorder = false
        graph.paddingTop = 10
        graph.paddingLeft = 10
        graph.paddingBottom = 30
        graph.paddingRight = 10
        
        //Grid line styles
        let majorGridLineStyle:CPTMutableLineStyle = CPTMutableLineStyle.init()
        majorGridLineStyle.lineWidth = 0.75;
        majorGridLineStyle.lineColor = CPTColor.init(genericGray: CGFloat(0.2)).withAlphaComponent(0.75)
        let minorGridLineStyle:CPTMutableLineStyle = CPTMutableLineStyle.init()
        minorGridLineStyle.lineWidth = 0.25;
        minorGridLineStyle.lineColor = CPTColor.init(genericGray: CGFloat(0.2)).withAlphaComponent(0.4)
        
        // Axes
        // X axis
        let axisSet:CPTXYAxisSet   = graph.axisSet as! CPTXYAxisSet
        let x:CPTXYAxis            = axisSet.xAxis!
        x.labelingPolicy        = CPTAxisLabelingPolicy.fixedInterval
        x.orthogonalPosition    = 0.0
        x.majorGridLineStyle    = majorGridLineStyle
        x.minorGridLineStyle    = minorGridLineStyle
        x.majorIntervalLength   = (2 * 100) as NSNumber
        x.minorTicksPerInterval = 4
        x.labelOffset           = 0
        x.titleOffset           = 0
        
        // Y axis
        let y:CPTXYAxis          = axisSet.yAxis!
        y.labelingPolicy        = CPTAxisLabelingPolicy.fixedInterval
        y.orthogonalPosition    = 0.0
        y.majorGridLineStyle    = majorGridLineStyle
        y.minorGridLineStyle    = minorGridLineStyle
        y.minorTicksPerInterval = 5
        y.majorIntervalLength   = (6553) as NSNumber//unit
        y.labelOffset           = 1//15.0 * CPTFloat(0.25);
        y.title                 = identifier
        y.titleOffset           = 20.0 * CGFloat(2)
        y.axisConstraints       = CPTConstraints.constraint(withLowerOffset: 0.0)
        
        
        // Rotate the labels by 45 degrees, just to show it can be done.
        x.labelRotation = CGFloat(M_PI_4)
        y.tickDirection = CPTSign.positive
        y.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0)
        let formatter:NumberFormatter =  NumberFormatter.init()
        formatter.maximumSignificantDigits = 2
        y.labelFormatter = formatter
        
        // Create the plot for Accel T
        let dataTSourceLinePlot:CPTScatterPlot = CPTScatterPlot.init()
        dataTSourceLinePlot.identifier     = kAccelTPlotIdentifier as (NSCoding & NSCopying & NSObjectProtocol)?
        dataTSourceLinePlot.cachePrecision = CPTPlotCachePrecision.double
        
        let lineTStyle:CPTMutableLineStyle = dataTSourceLinePlot.dataLineStyle?.mutableCopy() as! CPTMutableLineStyle
        lineTStyle.lineWidth              = 1.0
        lineTStyle.lineColor              = CPTColor.purple()
        dataTSourceLinePlot.dataLineStyle = lineTStyle
        
        dataTSourceLinePlot.dataSource = self
        graph.add(dataTSourceLinePlot)
        
        // Create the plot for Accel X
        let dataXSourceLinePlot:CPTScatterPlot = CPTScatterPlot.init()
        dataXSourceLinePlot.identifier     = kAccelXPlotIdentifier as (NSCoding & NSCopying & NSObjectProtocol)?
        dataXSourceLinePlot.cachePrecision = CPTPlotCachePrecision.double
        
        let lineXStyle:CPTMutableLineStyle = dataXSourceLinePlot.dataLineStyle?.mutableCopy() as! CPTMutableLineStyle
        lineXStyle.lineWidth              = 1.0
        lineXStyle.lineColor              = CPTColor.red()
        dataXSourceLinePlot.dataLineStyle = lineXStyle
        
        dataXSourceLinePlot.dataSource = self
        graph.add(dataXSourceLinePlot)
        
        // Create the plot for Accel Y
        let dataYSourceLinePlot:CPTScatterPlot = CPTScatterPlot.init()
        dataYSourceLinePlot.identifier     = kAccelYPlotIdentifier as (NSCoding & NSCopying & NSObjectProtocol)?
        dataYSourceLinePlot.cachePrecision = CPTPlotCachePrecision.double
        
        let lineYStyle:CPTMutableLineStyle = dataYSourceLinePlot.dataLineStyle?.mutableCopy() as! CPTMutableLineStyle
        lineYStyle.lineWidth              = 1.0
        lineYStyle.lineColor              = CPTColor.blue()
        dataYSourceLinePlot.dataLineStyle = lineYStyle
        
        dataYSourceLinePlot.dataSource = self
        graph.add(dataYSourceLinePlot)

        
        // Create the plot for Accel Z
        let dataZSourceLinePlot:CPTScatterPlot = CPTScatterPlot.init()
        dataZSourceLinePlot.identifier     = kAccelZPlotIdentifier as (NSCoding & NSCopying & NSObjectProtocol)?
        dataZSourceLinePlot.cachePrecision = CPTPlotCachePrecision.double
        
        let lineZStyle:CPTMutableLineStyle = dataZSourceLinePlot.dataLineStyle?.mutableCopy() as! CPTMutableLineStyle
        lineZStyle.lineWidth              = 1.0
        lineZStyle.lineColor              = CPTColor.green()
        dataZSourceLinePlot.dataLineStyle = lineZStyle
        
        dataZSourceLinePlot.dataSource = self
        graph.add(dataZSourceLinePlot)
        
        // Plot space
        let plotSpace:CPTXYPlotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsMomentumX = true
        plotSpace.allowsUserInteraction  = true
        
        plotSpace.xRange = CPTPlotRange.init(location: 0, length: NSNumber.init(value: plotDataSize))
        plotSpace.yRange = CPTPlotRange.init(location: NSNumber.init(value: -65535/2), length: 65535)
     
        return graph
    }
    
    //MARK: - Graph plot delegate
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        
        if (plot.identifier?.isEqual(kAccelTPlotIdentifier))! {
            return UInt(self.accelTDataArray.count)
        }else if (plot.identifier?.isEqual(kAccelXPlotIdentifier))! {
            return UInt(self.accelXDataArray.count)
        }else if (plot.identifier?.isEqual(kAccelYPlotIdentifier))! {
            return UInt(self.accelYDataArray.count)
        }else if (plot.identifier?.isEqual(kAccelZPlotIdentifier))! {
            return UInt(self.accelZDataArray.count)
        }else{
            return 0
        }
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        
        let _index:NSNumber = NSNumber.init(value: idx)
        
        switch plot.identifier as! String {
        case kAccelTPlotIdentifier:
            switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
            case .X:
                return _index
            case .Y:
                return self.accelTDataArray[_index.intValue]
            }
        case kAccelXPlotIdentifier:
            switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
            case .X:
                return _index
            case .Y:
                return self.accelXDataArray[_index.intValue]
            }
        case kAccelYPlotIdentifier:
            switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
            case .X:
                return _index
            case .Y:
                return self.accelYDataArray[_index.intValue]
            }
        case kAccelZPlotIdentifier:
            switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
            case .X:
                return _index
            case .Y:
                return self.accelZDataArray[_index.intValue]
            }
        default:
            return 0
        }
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
    func didGetAccelDataPacket(dataPacket: accelDataPacket) {
        
        self.accelDataArray.append(dataPacket)
        self.accelTDataArray.append(dataPacket.ACCEL_TEMP)
        self.accelXDataArray.append(dataPacket.ACCEL_X)
        self.accelYDataArray.append(dataPacket.ACCEL_Y)
        self.accelZDataArray.append(dataPacket.ACCEL_Z)
        let updateSize = 50
        
        if self.accelDataArray.count == self.plotDataSize {
            
            let theGraph:CPTGraph = self.accelGraph
            var thePlot:CPTPlot   = theGraph.plot(withIdentifier: kAccelTPlotIdentifier as NSCopying?)!
            thePlot.insertData(at: 0, numberOfRecords: UInt(self.accelXDataArray.count))
            
            thePlot = theGraph.plot(withIdentifier: kAccelXPlotIdentifier as NSCopying?)!
            thePlot.insertData(at: 0, numberOfRecords: UInt(self.accelXDataArray.count))
            
            thePlot = theGraph.plot(withIdentifier: kAccelYPlotIdentifier as NSCopying?)!
            thePlot.insertData(at: 0, numberOfRecords: UInt(self.accelYDataArray.count))
            
            thePlot = theGraph.plot(withIdentifier: kAccelZPlotIdentifier as NSCopying?)!
            thePlot.insertData(at: 0, numberOfRecords: UInt(self.accelZDataArray.count))
            
            self.accelDataArray.removeSubrange(1...updateSize)
            self.accelTDataArray.removeSubrange(1...updateSize)
            self.accelXDataArray.removeSubrange(1...updateSize)
            self.accelYDataArray.removeSubrange(1...updateSize)
            self.accelZDataArray.removeSubrange(1...updateSize)
        }
        
        let t = dataPacket.ACCEL_TEMP
        let x = dataPacket.ACCEL_X
        let y = dataPacket.ACCEL_Y
        let z = dataPacket.ACCEL_Z
        let s = dataPacket.ACCEL_STABLE
        self.serialPortInfoLable.stringValue = String(format: "Time:%@, \nT:%0.1f, \nX:%d, \nY:%d, \nZ:%d, \nS:%d\n",Date() as CVarArg,t,x,y,z,s.rawValue)

    }
}

