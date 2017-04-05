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


class MainViewController: NSViewController,FormatterDelegate,ORSSerialPortDelegate,SPDataParserDelegate,CPTPlotDelegate,CPTPlotDataSource{

    //Graph plot variables
    let plotDataLength = 500
    
    //Serial port variables
    let serialPortManager = ORSSerialPortManager.shared()
    var serialPort: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            serialPort?.delegate = self
        }
    }
    
    //Data
    var spDataParser:SPDataParser?{
        didSet{
            oldValue?.delegate = nil
            spDataParser?.delegate = self
        }
    }
    var dataPack:SPPack = SPPack.init()
    var dataArray:Array<Array<Int64>> = [[]]
    var formatterArray:Array<Formatter> = []{
        didSet{
            self.dataArray = []
            for _ in 0..<formatterArray.count {
                self.dataArray.append([])
            }
            createPlotView()
            
        }
    }
    
    
    @IBOutlet weak var serialPortSelector: NSPopUpButton!{
        didSet{
            var serialPortNames:[String] = []
            for port in self.serialPortManager.availablePorts {
                serialPortNames.append(port.name)
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
    
   
    var graphHostView:CPTGraphHostingView!
    var graph:CPTGraph!

    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.object(forKey:"formatterArray") != nil{
            let data:NSData = UserDefaults.standard.object(forKey:"formatterArray") as! NSData
            self.formatterArray = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<Formatter>
            createPlotView()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.setFrame(NSRect(x:0,y:0,width:1000,height:1000), display: true)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == "FormatterVCSeque"){
            let formatterViewController:FormatterViewController = segue.destinationController as! FormatterViewController
            formatterViewController.formatterArray = self.formatterArray
            formatterViewController.delegate = self
        }
    }
    
    func createPlotView(){
        self.spPanelContainerView.wantsLayer = true
        
        if (self.graphHostView != nil){
            self.graphHostView.removeFromSuperview()
        }
        
        self.graphHostView = self.createHostingView(frame: self.spPlotContainerView.bounds)
        self.graphHostView.wantsLayer = true
        self.graphHostView.translatesAutoresizingMaskIntoConstraints = false
        
        self.spPlotContainerView.addSubview(self.graphHostView)
        
        self.graphHostView.topAnchor.constraint(equalTo: self.spPlotContainerView.topAnchor).isActive = true
        self.graphHostView.bottomAnchor.constraint(equalTo: self.spPlotContainerView.bottomAnchor).isActive = true
        self.graphHostView.leadingAnchor.constraint(equalTo: self.spPlotContainerView.leadingAnchor).isActive = true
        self.graphHostView.trailingAnchor.constraint(equalTo: self.spPlotContainerView.trailingAnchor).isActive = true
        
        self.graph = self.createLinGraph(   hostView: self.graphHostView,
                                            start: 0,
                                            length: plotDataLength)
        
        self.view.layoutSubtreeIfNeeded()
    }
    
    
    func formatterArrayUpdate(formatterArray: Array<Formatter>) {
        self.formatterArray = formatterArray
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
    
    func createLinGraph(hostView:CPTGraphHostingView,start:Float,length:NSInteger) -> CPTGraph {
        
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

        

        
        for idx in 0..<self.formatterArray.count{
            
            if (self.formatterArray[idx].type != Formatter.formatterType.Header) && (self.formatterArray[idx].type != Formatter.formatterType.Trailer) {

                let dataSourceLinePlot:CPTScatterPlot = CPTScatterPlot.init()
                let lineStyle:CPTMutableLineStyle = dataSourceLinePlot.dataLineStyle?.mutableCopy() as! CPTMutableLineStyle
                
                dataSourceLinePlot.identifier     =  String(idx) as (NSCoding & NSCopying & NSObjectProtocol)?
                dataSourceLinePlot.cachePrecision = CPTPlotCachePrecision.double
                
                let lineColor:CGColor            = self.formatterArray[idx].color.cgColor
                lineStyle.lineWidth              = 1.0
                lineStyle.lineColor              = CPTColor.init(cgColor: lineColor)
                dataSourceLinePlot.dataLineStyle = lineStyle
                
                dataSourceLinePlot.dataSource = self
                graph.add(dataSourceLinePlot)
            }
        }
        
        // Plot space
        let plotSpace:CPTXYPlotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsMomentumX = true
        plotSpace.allowsUserInteraction  = true
        
        plotSpace.xRange = CPTPlotRange.init(location: 0, length: NSNumber.init(value: plotDataLength))
        plotSpace.yRange = CPTPlotRange.init(location: NSNumber.init(value: -65535/2), length: 65535)
     
        return graph
    }
    
    //MARK: - Graph plot delegate
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        
        let idx = Int(plot.identifier as! String)
        return UInt(self.dataArray[idx!].count)
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        
        let _index:NSNumber = NSNumber.init(value: idx)
        let idx = Int(plot.identifier as! String)
        
        switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
        case .X:
             return _index
        case .Y:
            return (self.dataArray[idx!])[_index.intValue]
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
        self.spDataParser = SPDataParser.init(formatterArray: self.formatterArray)
        
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        self.spDataParser = nil
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        let uint8Ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        uint8Ptr.initialize(from: data)
        var byteArray:Array<UInt8> = []
        
        for i in 0...(data.count - 1){
            byteArray.append(uint8Ptr[i])
        }
        self.spDataParser?.parseSerialData(byteArray: byteArray)
        
        byteArray.removeAll()
    }
    
    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        self.serialPort = nil
        //self.openCloseButton.title = "Open"
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        //print("SerialPort \(serialPort) encountered an error: \(error)")
    }
    
    // MARK: - serial port parser delegate
    func didGetDataPacket(packetArray:Array<SPPack>) {

        //print(packetArray.count)
    
        
        for packet in packetArray{
            
            for idx in 0..<packet.dataArray.count{
                self.dataArray[idx].append(packet.dataArray[idx])
            }
            
            if (self.dataArray.last?.count)! > plotDataLength{
                
                let theGraph:CPTGraph = self.graph
                var thePlot:CPTPlot?
                
                //Plot
                for idx in 0..<self.formatterArray.count{
                    
                    if (self.formatterArray[idx].type != Formatter.formatterType.Header) && (self.formatterArray[idx].type != Formatter.formatterType.Trailer) {
                        
//                        thePlot = theGraph.plot(withIdentifier: String(idx) as (NSCoding & NSCopying & NSObjectProtocol)?)!
//                        thePlot?.insertData(at: 0, numberOfRecords: UInt(self.dataArray[idx].count))
                        
                        self.dataArray[idx].remove(at: 0)
                    }
                }
            }
        }
     }
}

