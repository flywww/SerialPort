//
//  DataFormatterViewController.swift
//  SerialPortApp
//
//  Created by 林盈志 on 22/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

import Cocoa

class DataFormatterViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource,NSTextFieldDelegate {
    
    // MARK: - View parameters
    @IBOutlet weak var dataFormaterTableView: NSTableView!{
        didSet{
            dataFormaterTableView.delegate = self
            dataFormaterTableView.dataSource = self
            dataFormaterTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyle.sourceList
            dataFormaterTableView.gridStyleMask = NSTableViewGridLineStyle.dashedHorizontalGridLineMask
            dataFormaterTableView.backgroundColor = NSColor.white
            dataFormaterTableView.usesAlternatingRowBackgroundColors = true
        }
    }
    
    @IBOutlet weak var tableViewToolBar: NSSegmentedControl!{
        didSet{
            tableViewToolBar.target = self
            tableViewToolBar.action = #selector(tableViewToolBarAction)
        }
    }
    
    // MARK: - Other parameters
    var formatterArray:Array<Formatter> = []{
        didSet{
            self.dataFormaterTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // reload array from last setting
        if UserDefaults.standard.object(forKey:"formatterArray") != nil{
            let data:NSData = UserDefaults.standard.object(forKey:"formatterArray") as! NSData
            self.formatterArray = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<Formatter>
        }
    }
    
    @objc fileprivate func setFormate(_ sender:Any){
        
        let dataRow = self.dataFormaterTableView.row(for: sender as! NSView)
        let dataColumn = self.dataFormaterTableView.column(for: sender as! NSView)
        
        switch dataColumn {
        case 0:
            self.formatterArray[dataRow].name = (sender as! NSTextField).stringValue
        case 1:
            self.formatterArray[dataRow].type = (Formatter.formatterType(rawValue: (sender as! NSPopUpButton).indexOfSelectedItem))!
            self.dataFormaterTableView.reloadData()
        case 2:
            self.formatterArray[dataRow].value = Int32.init((sender as! NSTextField).stringValue)!
        case 3:
            self.formatterArray[dataRow].color = (sender as! NSColorWell).color
        default:
            ()
        }
    }
    
    @objc fileprivate func tableViewToolBarAction(_ sender: NSSegmentedControl){
        
        switch sender.selectedSegment {
        case 0:
            let formaterPack:Formatter = Formatter.init()
            self.formatterArray.append(formaterPack)
        case 1:
            if self.formatterArray.count > 0{
                self.formatterArray.remove(at: self.formatterArray.count-1)
            }
        default:
            ()
        }
    }
    
    @IBAction func doneAction(_ sender: Any) {
        
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: self.formatterArray), forKey: "formatterArray")
        UserDefaults.standard.synchronize()
        self.dismissViewController(self)
    }
    
    
    // MARK: - tableView datasource
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 25
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.formatterArray.count
    }
    
    // MARK: - tableView delegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
     
        enum columnIDs {
            static let name = "nameColumnID"
            static let type = "typeColumnID"
            static let value = "valueColumnID"
            static let color = "colorColumnID"
        }
        
        let typeSelector: NSPopUpButton = {
            let formatter = Formatter.init()
            let popUpButton = NSPopUpButton.init()
            popUpButton.removeAllItems()
            popUpButton.addItems(withTitles:formatter.formatterTypeStrArray)
            popUpButton.action = #selector(setFormate)
            popUpButton.target = self
            popUpButton.selectItem(at: self.formatterArray[row].type.rawValue)
            return popUpButton
        }()
        
        let nameTextField: NSTextField = {
            let textField = NSTextField.init()
            textField.isBezeled = false
            textField.alignment = NSTextAlignment.left
            textField.backgroundColor = NSColor.clear
            textField.stringValue = self.formatterArray[row].name
            textField.action = #selector(setFormate)
            textField.target = self
            textField.delegate = self
            return textField
        }()
        
        let valueTextField: NSTextField = {
            let textField = NSTextField.init()
            textField.isBezeled = false
            textField.alignment = NSTextAlignment.left
            textField.backgroundColor = NSColor.clear
            textField.formatter = OnlyIntegerValueFormatter()
            textField.stringValue = String.init(self.formatterArray[row].value)
            textField.action = #selector(setFormate)
            textField.target = self
            textField.delegate = self
            return textField
        }()
        
        let colorPicker: NSColorWell = {
            let colorWell = NSColorWell.init()
            colorWell.action = #selector(setFormate)
            colorWell.target = self
            colorWell.color = self.formatterArray[row].color
            return colorWell
        }()

        if typeSelector.indexOfSelectedItem == Formatter.formatterType.Header.rawValue{
            nameTextField.isEditable = false
            nameTextField.backgroundColor = NSColor.lightGray
            colorPicker.isEnabled = false
            colorPicker.layer?.backgroundColor = NSColor.lightGray.cgColor
        }else{
            nameTextField.isEditable = true
            nameTextField.backgroundColor = NSColor.clear
            colorPicker.isEnabled = true
            colorPicker.layer?.backgroundColor = NSColor.white.cgColor
        }
        
        var tableColumnView:NSView!
        
        switch tableColumn!.identifier {
        case columnIDs.name:
            tableColumnView = nameTextField
        case columnIDs.type:
            tableColumnView = typeSelector
        case columnIDs.value:
            tableColumnView = valueTextField
        case columnIDs.color:
            tableColumnView = colorPicker
        default:
            ()
        }
        return tableColumnView ?? nil
    }
    
    // MARK: - TextField delegate
    override func controlTextDidChange(_ obj: Notification) {
        
        let textField:NSTextField = obj.object as! NSTextField
        setFormate(textField)
    }
}
