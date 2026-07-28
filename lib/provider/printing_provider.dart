import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

enum PrinterConnectionType { bluetooth, usb }

class PrintingProvider with ChangeNotifier {
  final printerManager = PrinterManager.instance;
  final List<BluetoothPrinter> _bluetoothDevices = [];
  final List<UsbPrinter> _usbDevices = [];
  
  bool _isScanning = false;
  bool _isConnected = false;
  
  BluetoothPrinter? _selectedBluetoothPrinter;
  UsbPrinter? _selectedUsbPrinter;
  PrinterConnectionType _connectionType = PrinterConnectionType.bluetooth;
  PaperSize _paperSize = PaperSize.mm80;
  bool _autoPrint = false;
  
  List<BluetoothPrinter> get bluetoothDevices => _bluetoothDevices;
  List<UsbPrinter> get usbDevices => _usbDevices;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  PrinterConnectionType get connectionType => _connectionType;
  PaperSize get paperSize => _paperSize;
  bool get autoPrint => _autoPrint;
  
  BluetoothPrinter? get selectedBluetoothPrinter => _selectedBluetoothPrinter;
  UsbPrinter? get selectedUsbPrinter => _selectedUsbPrinter;

  PrintingProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final typeIndex = prefs.getInt('printer_type') ?? 0;
    _connectionType = PrinterConnectionType.values[typeIndex];
    
    final paperIndex = prefs.getInt('paper_size') ?? 1; // Default to 80mm
    _paperSize = paperIndex == 0 ? PaperSize.mm58 : PaperSize.mm80;
    
    _autoPrint = prefs.getBool('auto_print') ?? false;
    
    notifyListeners();
  }

  void setAutoPrint(bool value) {
    _autoPrint = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('auto_print', value);
    });
    notifyListeners();
  }

  void setPaperSize(PaperSize size) {
    _paperSize = size;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('paper_size', size == PaperSize.mm58 ? 0 : 1);
    });
    notifyListeners();
  }

  void setConnectionType(PrinterConnectionType type) {
    _connectionType = type;
    _selectedBluetoothPrinter = null;
    _selectedUsbPrinter = null;
    _isConnected = false;
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('printer_type', type.index);
    });
    
    notifyListeners();
  }

  Future<void> scanDevices() async {
    _isScanning = true;
    _bluetoothDevices.clear();
    _usbDevices.clear();
    notifyListeners();

    try {
      if (_connectionType == PrinterConnectionType.bluetooth) {
        printerManager.discovery(type: PrinterType.bluetooth).listen((device) {
          if (!_bluetoothDevices.any((d) => d.address == device.address)) {
            _bluetoothDevices.add(BluetoothPrinter(
              deviceName: device.name,
              address: device.address,
              type: PrinterType.bluetooth,
            ));
            notifyListeners();
          }
        });
      } else {
        printerManager.discovery(type: PrinterType.usb).listen((device) {
          if (!_usbDevices.any((d) => d.vendorId == device.vendorId && d.productId == device.productId)) {
            _usbDevices.add(UsbPrinter(
              deviceName: device.name,
              vendorId: device.vendorId,
              productId: device.productId,
              type: PrinterType.usb,
            ));
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint("Scan error: $e");
    }

    // Stop scanning after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      _isScanning = false;
      notifyListeners();
    });
  }

  Future<bool> connect(dynamic device) async {
    try {
      if (device is BluetoothPrinter) {
        _selectedBluetoothPrinter = device;
        final model = BluetoothPrinterInput(
          name: device.deviceName ?? '',
          address: device.address ?? '',
          isBle: false,
        );
        await printerManager.connect(type: PrinterType.bluetooth, model: model);
      } else if (device is UsbPrinter) {
        _selectedUsbPrinter = device;
        final model = UsbPrinterInput(
          name: device.deviceName ?? '',
          vendorId: device.vendorId,
          productId: device.productId,
        );
        await printerManager.connect(type: PrinterType.usb, model: model);
      }
      
      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    final type = _connectionType == PrinterConnectionType.bluetooth 
        ? PrinterType.bluetooth 
        : PrinterType.usb;
    await printerManager.disconnect(type: type);
    _isConnected = false;
    notifyListeners();
  }

  Future<void> testPrint() async {
    if (!_isConnected) return;

    final profile = await CapabilityProfile.load();
    final generator = Generator(_paperSize, profile);
    List<int> bytes = [];

    bytes += generator.text('NOVA POS TEST PRINT',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.feed(1);
    bytes += generator.text('Connection: ${_connectionType.name.toUpperCase()}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Date: ${DateTime.now().toString().substring(0, 19)}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    final type = _connectionType == PrinterConnectionType.bluetooth 
        ? PrinterType.bluetooth 
        : PrinterType.usb;
        
    await printerManager.send(type: type, bytes: bytes);
  }
}

class BluetoothPrinter {
  final String? deviceName;
  final String? address;
  final PrinterType type;

  BluetoothPrinter({this.deviceName, this.address, required this.type});
}

class UsbPrinter {
  final String? deviceName;
  final String? vendorId;
  final String? productId;
  final PrinterType type;

  UsbPrinter({this.deviceName, this.vendorId, this.productId, required this.type});
  
  String get address => '$vendorId:$productId';
}
