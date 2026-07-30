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
  
  // Custom Paper Width in mm
  int _paperWidthMm = 80;
  
  bool _autoPrint = false;
  
  List<BluetoothPrinter> get bluetoothDevices => _bluetoothDevices;
  List<UsbPrinter> get usbDevices => _usbDevices;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  PrinterConnectionType get connectionType => _connectionType;
  
  // Expose both raw width and the PaperSize object for the generator
  int get paperWidthMm => _paperWidthMm;
  PaperSize get paperSize {
    if (_paperWidthMm <= 58) return PaperSize.mm58;
    if (_paperWidthMm <= 72) return PaperSize.mm72;
    return PaperSize.mm80;
  }
  
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
    
    _paperWidthMm = prefs.getInt('paper_width_mm') ?? 80;
    
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

  void setPaperWidth(int widthMm) {
    _paperWidthMm = widthMm;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('paper_width_mm', widthMm);
    });
    notifyListeners();
  }

  // Deprecated - kept for compatibility if needed elsewhere
  void setPaperSize(PaperSize size) {
    if (size == PaperSize.mm58) setPaperWidth(58);
    if (size == PaperSize.mm72) setPaperWidth(72);
    if (size == PaperSize.mm80) setPaperWidth(80);
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
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    bytes += generator.text('NOVA POS TEST PRINT',
        styles:  PosStyles(
          align: PosAlign.center, 
          bold: true, 
          height: _paperWidthMm < 44 ? PosTextSize.size1 : PosTextSize.size2, 
          width: _paperWidthMm < 44 ? PosTextSize.size1 : PosTextSize.size2
        ));
    bytes += generator.feed(1);
    bytes += generator.text('Width: ${_paperWidthMm}mm', styles: const PosStyles(align: PosAlign.center));
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
