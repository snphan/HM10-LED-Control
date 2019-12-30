//
//  ViewController.swift
//  BLE LED Control
//
//  Created by Steven Phan on 2019-07-26.
//  Copyright © 2019 Steven Phan. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    // MARK: VARIABLES

    @IBOutlet weak var intensitySlider: UISlider!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    var centralManager: CBCentralManager!
    let serviceUUID = CBUUID(string: "FFE0")
    let characteristicUUID = CBUUID(string: "FFE1")
    var bluetoothDevice: CBPeripheral?
    var bluetoothCharacteristic: CBCharacteristic?
    var sliderPreviousValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        DispatchQueue.main.async {
            self.connectButton.isEnabled = false
            self.disconnectButton.isEnabled = false
            self.peripheralName.text = "..."
            self.statusLabel.text = "..."
            self.onOffSwitch.isOn = false
            self.onOffSwitch.isEnabled = false
            self.searchButton.isEnabled = true
            self.intensitySlider.isContinuous = true
            self.intensitySlider.isEnabled = false
            self.intensitySlider.value = 0
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
            
        case .unknown:
            print("Bluetooth status is UNKNOWN")
            statusLabel.text = "Bluetooth status is UNKNOWN"
        case .resetting:
            print("Bluetooth status is RESETTING")
            statusLabel.text = "Bluetooth status is RESETTING"
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
            statusLabel.text = "Bluetooth status is UNSUPPORTED"
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
            statusLabel.text = "Bluetooth status is UNAUTHORIZED"
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            statusLabel.text = "Bluetooth status is POWERED OFF"
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            statusLabel.text = "Bluetooth is POWERED ON, Press Search"
            }
    }
    
    // MARK: CentralManager methods
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Found: "
            self.peripheralName.text = peripheral.name!
            self.connectButton.isEnabled = true
        }
        decodePeripheralState(peripheralState: peripheral.state)
        // STEP 4.2: MUST store a reference to the peripheral in
        // class instance variable
        bluetoothDevice = peripheral
        // STEP 4.3: since HeartRateMonitorViewController
        // adopts the CBPeripheralDelegate protocol,
        // the peripheralHeartRateMonitor must set its
        // delegate property to HeartRateMonitorViewController
        // (self)
        bluetoothDevice?.delegate = self
        
        // STEP 5: stop scanning to preserve battery life;
        // re-scan if disconnected
        centralManager?.stopScan()
        
    } // END func centralManager(... didDiscover peripheral
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        bluetoothDevice?.discoverServices([serviceUUID])
        DispatchQueue.main.async {
            self.statusLabel.text = "Connected!"
            self.disconnectButton.isEnabled = true
            self.connectButton.isEnabled = false
            self.onOffSwitch.isEnabled = true
            self.onOffSwitch.isOn = false
            self.searchButton.isEnabled = false
            self.intensitySlider.isEnabled = false
            self.intensitySlider.value = 0
        }
        decodePeripheralState(peripheralState: bluetoothDevice!.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        DispatchQueue.main.async {
            self.statusLabel.text = "Disconnected!"
            self.peripheralName.text = "..."
            self.onOffSwitch.isOn = false
            
        }
        decodePeripheralState(peripheralState: bluetoothDevice!.state)
    }

    // MARK: IBActions
    
    @IBAction func switchButton(_ sender: Any) {
        if onOffSwitch.isOn {
            // Send "N" to the HM10 and turn on the LED
            turnOnLed(device: bluetoothDevice, deviceCharacteristic: bluetoothCharacteristic)
            DispatchQueue.main.async {
                self.intensitySlider.isEnabled = true
            }
        }
        else {
            // Send "F" to the HM10 and turn off the LED
            turnOffLed(device: bluetoothDevice, deviceCharacteristic: bluetoothCharacteristic)
            DispatchQueue.main.async {
                self.intensitySlider.isEnabled = true
                self.intensitySlider.value = 0
            }
        }
    }
    
    @IBAction func searchForDevice(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Searching..."
        }
        centralManager?.scanForPeripherals(withServices: [serviceUUID])
    }
    
    
    @IBAction func connectToDevice(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Connecting..."
        }
        centralManager?.connect(bluetoothDevice!)
    }
    
    @IBAction func disconnectFromDevice(_ sender: UIButton) {
 
        DispatchQueue.main.async {
            self.turnOffLed(device: self.bluetoothDevice, deviceCharacteristic: self.bluetoothCharacteristic)
            self.disconnectButton.isEnabled = false
            self.onOffSwitch.isEnabled = false
            self.intensitySlider.isEnabled = false
            self.intensitySlider.value = 0
            self.statusLabel.text = "Disconnecting..."
        }
        // For some reason this was running parallel with the above line so, delay it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.centralManager?.cancelPeripheralConnection(self.bluetoothDevice!)
            self.searchButton.isEnabled = true
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let sliderValue = Int(sender.value)
        let delta = abs(sliderValue - sliderPreviousValue)
        if (delta > 5) {
            let sliderString = String(sliderValue)
            changeSliderIntensity(device: bluetoothDevice, deviceCharacteristic: bluetoothCharacteristic, value: sliderString)
            sliderPreviousValue = sliderValue
        }
        // Make a case where the slider goes to zero or close to zero, set to zero
        if (sliderValue <= 1 && delta > 1) {
            let sliderString = String(0)
            changeSliderIntensity(device: bluetoothDevice, deviceCharacteristic: bluetoothCharacteristic, value: sliderString)
            sliderPreviousValue = 0
        }
        
    }
    
    // MARK: User Defined Functions
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        
        switch peripheralState {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
        }
        
    }
    
    func turnOffLed(device: CBPeripheral?, deviceCharacteristic: CBCharacteristic?) {
        // Turn off the LED by sending F.
        let someString = "F000"
        let data = someString.data(using: .utf8)
        device?.writeValue(data!, for: deviceCharacteristic!, type: .withoutResponse)
        print("wrote \(someString)")
    }
    
    func turnOnLed(device: CBPeripheral?, deviceCharacteristic: CBCharacteristic?) {
        // Turn on the led by sending N.
        let someString = "N000"
        let data = someString.data(using: .utf8)
        device?.writeValue(data!, for: deviceCharacteristic!, type: .withoutResponse)
        print("wrote \(someString)")
    }
    
    func changeSliderIntensity(device: CBPeripheral?, deviceCharacteristic: CBCharacteristic?, value: String) {
        let someString = intensityStringFormat(value: value)
        let data = someString.data(using: .utf8)
        device?.writeValue(data!, for: deviceCharacteristic!, type: .withoutResponse)
        print("wrote \(someString)")
        
    }
    
    func intensityStringFormat(value: String) -> String {
        let numberSize = value.count
        var outputString: String
        switch numberSize {
        case 1:
            outputString = "N00\(value)"
        case 2:
            outputString = "N0\(value)"
        case 3:
            outputString = "N\(value)"
        default:
            return "error"
        }
        return outputString
    }
}


extension ViewController {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
            }
            if characteristic.properties.contains(.write) {
                print("\(characteristic.uuid): properties contains .write")
            }
            bluetoothCharacteristic = characteristic
            turnOffLed(device: bluetoothDevice, deviceCharacteristic: bluetoothCharacteristic)
        }
    }
}
