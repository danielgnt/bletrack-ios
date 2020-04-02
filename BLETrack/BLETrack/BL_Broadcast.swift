//
//  BL_Broadcast.swift
//  BLETrack
//
//  Created by Daniel Günther on 29.03.20.
//  Copyright © 2020 Daniel Günther. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

let S_UUID = CBUUID(string: "7823C5DE-BFC9-4BC6-8E60-2280A22FED01")
let WR_UUID = CBUUID(string: "AF3F34F4-CCBA-4C36-BB13-C53509085C8B")
let WR_PROPERTIES: CBCharacteristicProperties = .write
let WR_PERMISSIONS: CBAttributePermissions = .writeable
let bl_broadcast = BL_Broadcast()
var statusDict = ["BluetoothPeripheral": "unknown", "CentralBluetooth": "unknown"]
var listViewData = ListViewData()
var alreadySeen = [CBUUID]()

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
            status(of: "CentralBluetooth", value: "online")
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            centralManager.scanForPeripherals(withServices: [S_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            status(of: "CentralBluetooth", value: "not ready")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //let dateFormatter : DateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        ///let date = Date()
        //let dateString = dateFormatter.string(from: date)
        //listViewData.items.append(CInfo(uuid: "U/" + peripheral.identifier.uuidString, time: dateString))
        peripheralStorage[peripheral.identifier] = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if(service.uuid == S_UUID){
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if(service.uuid == S_UUID){
            let user_uuid = (service.characteristics![0] as CBCharacteristic).uuid
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = Date()
            let dateString = dateFormatter.string(from: date)
            listViewData.items.append(CInfo(uuid: user_uuid.uuidString, time: dateString))
            alreadySeen.append(user_uuid)
        }
        peripheralStorage.removeValue(forKey: peripheral.identifier)
    }

    func startAdvertising(){
        let serialService = CBMutableService(type: S_UUID, primary: true)
        let writeCharacteristics = CBMutableCharacteristic(type: WR_UUID,
                                         properties: WR_PROPERTIES, value: nil,
                                         permissions: WR_PERMISSIONS)
        serialService.characteristics = [writeCharacteristics]
        peripheralManager.add(serialService)
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey:[S_UUID],
            CBAdvertisementDataLocalNameKey: WR_UUID.uuidString
        ])
    }
    
    func stopAll(){
        if(peripheralManager != nil && peripheralManager.isAdvertising){
            peripheralManager.stopAdvertising();
        }
        peripheralManager = nil
        centralManager = nil
        alreadySeen = [CBUUID]()
    }
    
    func dewIt(){
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    

}
