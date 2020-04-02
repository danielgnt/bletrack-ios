//
//  BL_Broadcast.swift
//  BLETrack
//
//  Created by Daniel Günther on 29.03.20.
//  Copyright © 2020 Daniel Günther. All rights reserved.
//  Prototpe of https://arxiv.org/abs/2004.00517
//

import UIKit
import CoreLocation
import CoreBluetooth

// Service UUID which all devices look for and which all device broadcast themselves
let S_UUID = CBUUID(string: "7823C5DE-BFC9-4BC6-8E60-2280A22FED01")
// Unique User id, different on every device
let WR_UUID = CBUUID(string: "AF3F34F4-CCBA-4C36-BB13-C53509085C8B")
let WR_PROPERTIES: CBCharacteristicProperties = .write
let WR_PERMISSIONS: CBAttributePermissions = .writeable
let bl_broadcast = BL_Broadcast()
var listViewData = ListViewData()
// List of users already seen to not spam the list, ofcourse this should not be used in an actual implementation 
var alreadySeen = [CBUUID]()

// Log status to console
func status(of: String, value: String){
    print(of + ": " + value)
}

struct CInfo : Hashable{
    var uuid : String!
    var time : String!
    
    init(uuid: String, time: String) {
        self.uuid = uuid
        self.time = time
    }
}

class ListViewData: ObservableObject {
    @Published var items = [CInfo]()
    func setItems(items: [CInfo]){
        self.items = items
    }
}


class BL_Broadcast: UIViewController, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var peripheralStorage = [UUID: CBPeripheral]()
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
            case .poweredOn:
                status(of: "BluetoothPeripheral", value: "ready")
                // Launch of peripheralManager was successful, start advertising
                startAdvertising()
            case .poweredOff:
                status(of: "BluetoothPeripheral", value: "turned off")
            case .resetting:
                status(of: "BluetoothPeripheral", value: "resetting")
            case .unauthorized:
                status(of: "BluetoothPeripheral", value: "unauthorized")
            case .unsupported:
                status(of: "BluetoothPeripheral", value: "not supported")
            default:
                status(of: "BluetoothPeripheral", value: "unknown")
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Launch successful
            status(of: "CentralBluetooth", value: "online")
            // start peripheralManager for Advertisment, peripheralManagerDidUpdateState with state = .poweredOn is called if successful
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            // start scanning for other devices without registering duplicates since when the application goes into background mode this will happen nevertheless 
            centralManager.scanForPeripherals(withServices: [S_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            // Possibly the permission was denied, state would then be .unauthorized
            status(of: "CentralBluetooth", value: "not ready")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Store reference of discovered peripheral and connect (if reference isn't kept, connect would be unsuccessful)
        peripheralStorage[peripheral.identifier] = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Connect successful, discover services
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Services discovered search for our service and discover characteristics
        for service in peripheral.services! {
            if(service.uuid == S_UUID){
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if(service.uuid == S_UUID){
            // Our service characteristics have been found. Read the userid and add it to the list
            let user_uuid = (service.characteristics![0] as CBCharacteristic).uuid
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = Date()
            let dateString = dateFormatter.string(from: date)
            listViewData.items.append(CInfo(uuid: user_uuid.uuidString, time: dateString))
            alreadySeen.append(user_uuid)
        }
        // Remove reference to the device since we are done
        peripheralStorage.removeValue(forKey: peripheral.identifier)
    }

    func startAdvertising(){
        // Setup service and advertise it to other devices
        let serialService = CBMutableService(type: S_UUID, primary: true)
        let writeCharacteristics = CBMutableCharacteristic(type: WR_UUID,
                                         properties: WR_PROPERTIES, value: nil,
                                         permissions: WR_PERMISSIONS)
        serialService.characteristics = [writeCharacteristics]
        peripheralManager.add(serialService)
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey:[S_UUID]
        ])
    }
    
    func stopAll(){
        // Very basic stop function, that just removes reference to all objects therefor iOS cleansup
        if(peripheralManager != nil && peripheralManager.isAdvertising){
            peripheralManager.stopAdvertising();
        }
        peripheralManager = nil
        centralManager = nil
        alreadySeen = [CBUUID]()
    }
    
    // Init function
    func dewIt(){
        //Initializes bluetooth, after launch is complete and successful iOS calls centralManagerDidUpdateStat with state = .poweredOn
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    

}
