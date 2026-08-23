import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:dio/dio.dart';
import 'package:mpos/dio_client/dio_client.dart';

enum PrinterConnectionType { bluetooth, usb }
enum PrinterRole { receipt, label }

class PrintingProvider with ChangeNotifier {
  final printerManager = PrinterManager.instance;
  final List<BluetoothPrinter> _bluetoothDevices = [];
  final List<UsbPrinter> _usbDevices = [];
  
  bool _isScanning = false;
  
  // Connection state for Receipt Printer
  bool _isReceiptConnected = false;
  dynamic _selectedReceiptPrinter; // Can be BluetoothPrinter or UsbPrinter
  PrinterConnectionType _receiptConnectionType = PrinterConnectionType.bluetooth;
  int _receiptPaperWidthMm = 80;

  // Connection state for Label Printer
  bool _isLabelConnected = false;
  dynamic _selectedLabelPrinter; // Can be BluetoothPrinter or UsbPrinter
  PrinterConnectionType _labelConnectionType = PrinterConnectionType.bluetooth;
  int _labelPaperWidthMm = 58; // Labels are often smaller, defaulting to 58
  
  bool _autoPrint = false;

  Uint8List? _logoBytes;
  Uint8List? get logoBytes => _logoBytes;
  
  List<BluetoothPrinter> get bluetoothDevices => _bluetoothDevices;
  List<UsbPrinter> get usbDevices => _usbDevices;
  bool get isScanning => _isScanning;
  
  bool get autoPrint => _autoPrint;

  // Getters for specific roles
  bool isConnected(PrinterRole role) => role == PrinterRole.receipt ? _isReceiptConnected : _isLabelConnected;
  dynamic selectedPrinter(PrinterRole role) => role == PrinterRole.receipt ? _selectedReceiptPrinter : _selectedLabelPrinter;
  PrinterConnectionType connectionType(PrinterRole role) => role == PrinterRole.receipt ? _receiptConnectionType : _labelConnectionType;
  int paperWidthMm(PrinterRole role) => role == PrinterRole.receipt ? _receiptPaperWidthMm : _labelPaperWidthMm;

  PaperSize paperSize(PrinterRole role) {
    int width = paperWidthMm(role);
    if (width <= 58) return PaperSize.mm58;
    if (width <= 72) return PaperSize.mm72;
    return PaperSize.mm80;
  }

  PrintingProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Receipt Printer settings
    _receiptConnectionType = PrinterConnectionType.values[prefs.getInt('receipt_printer_type') ?? 0];
    _receiptPaperWidthMm = prefs.getInt('receipt_paper_width_mm') ?? 80;
    
    // Load Label Printer settings
    _labelConnectionType = PrinterConnectionType.values[prefs.getInt('label_printer_type') ?? 0];
    _labelPaperWidthMm = prefs.getInt('label_paper_width_mm') ?? 58;

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

  void setPaperWidth(PrinterRole role, int widthMm) {
    if (role == PrinterRole.receipt) {
      _receiptPaperWidthMm = widthMm;
    } else {
      _labelPaperWidthMm = widthMm;
    }
    
    SharedPreferences.getInstance().then((prefs) {
      final key = role == PrinterRole.receipt ? 'receipt_paper_width_mm' : 'label_paper_width_mm';
      prefs.setInt(key, widthMm);
    });
    notifyListeners();
  }

  void setConnectionType(PrinterRole role, PrinterConnectionType type) {
    if (role == PrinterRole.receipt) {
      _receiptConnectionType = type;
      _selectedReceiptPrinter = null;
      _isReceiptConnected = false;
    } else {
      _labelConnectionType = type;
      _selectedLabelPrinter = null;
      _isLabelConnected = false;
    }
    
    SharedPreferences.getInstance().then((prefs) {
      final key = role == PrinterRole.receipt ? 'receipt_printer_type' : 'label_printer_type';
      prefs.setInt(key, type.index);
    });
    
    notifyListeners();
  }

  Future<void> fetchAndCacheLogo(String? url) async {
    if (url == null || url.isEmpty) return;
    if (_logoBytes != null) return;
    try {
      final response = await DioClient.getRawDio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        _logoBytes = Uint8List.fromList(response.data!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching logo: $e');
    }
  }

  Future<void> scanDevices(PrinterRole role) async {
    _isScanning = true;
    _bluetoothDevices.clear();
    _usbDevices.clear();
    notifyListeners();

    try {
      final type = connectionType(role);
      if (type == PrinterConnectionType.bluetooth) {
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

    Future.delayed(const Duration(seconds: 10), () {
      _isScanning = false;
      notifyListeners();
    });
  }

  Future<bool> connect(PrinterRole role, dynamic device) async {
    try {
      final type = connectionType(role);
      if (device is BluetoothPrinter) {
        final model = BluetoothPrinterInput(
          name: device.deviceName ?? '',
          address: device.address ?? '',
          isBle: false,
        );
        await printerManager.connect(type: PrinterType.bluetooth, model: model);
      } else if (device is UsbPrinter) {
        final model = UsbPrinterInput(
          name: device.deviceName ?? '',
          vendorId: device.vendorId,
          productId: device.productId,
        );
        await printerManager.connect(type: PrinterType.usb, model: model);
      }
      
      if (role == PrinterRole.receipt) {
        _selectedReceiptPrinter = device;
        _isReceiptConnected = true;
      } else {
        _selectedLabelPrinter = device;
        _isLabelConnected = true;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      if (role == PrinterRole.receipt) {
        _isReceiptConnected = false;
      } else {
        _isLabelConnected = false;
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect(PrinterRole role) async {
    final type = connectionType(role) == PrinterConnectionType.bluetooth 
        ? PrinterType.bluetooth 
        : PrinterType.usb;
    await printerManager.disconnect(type: type);
    
    if (role == PrinterRole.receipt) {
      _isReceiptConnected = false;
    } else {
      _isLabelConnected = false;
    }
    notifyListeners();
  }

  Future<void> testPrint(PrinterRole role) async {
    if (!isConnected(role)) return;

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize(role), profile);
    List<int> bytes = [];

    bytes += generator.text('NOVA POS TEST PRINT (${role.name.toUpperCase()})',
        styles: PosStyles(
          align: PosAlign.center, 
          bold: true, 
          height: paperWidthMm(role) < 44 ? PosTextSize.size1 : PosTextSize.size2, 
          width: paperWidthMm(role) < 44 ? PosTextSize.size1 : PosTextSize.size2
        ));
    bytes += generator.feed(1);
    bytes += generator.text('Width: ${paperWidthMm(role)}mm', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Connection: ${connectionType(role).name.toUpperCase()}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Date: ${DateTime.now().toString().substring(0, 19)}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    final type = connectionType(role) == PrinterConnectionType.bluetooth 
        ? PrinterType.bluetooth 
        : PrinterType.usb;
        
    await printerManager.send(type: type, bytes: bytes);
  }

  Future<void> printBarcodeLabel({
    required String name,
    required String price,
    required String barcode,
    String? storeName,
  }) async {
    const role = PrinterRole.label;
    if (!isConnected(role)) {
      debugPrint('Label printer not connected');
      return;
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize(role), profile);
    List<int> bytes = [];

    if (storeName != null && storeName.isNotEmpty) {
      bytes += generator.text(storeName,
          styles: const PosStyles(align: PosAlign.center, bold: true));
    }

    bytes += generator.text(name,
        styles: const PosStyles(
            align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));

    bytes += generator.text('Price: $price',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.feed(1);

    try {
      bytes += generator.barcode(Barcode.code128(("{B$barcode").split("")), width: 2, height: 50);
    } catch (e) {
      debugPrint('Error generating barcode: $e');
      bytes += generator.text(barcode, styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    final type = connectionType(role) == PrinterConnectionType.bluetooth
        ? PrinterType.bluetooth
        : PrinterType.usb;

    await printerManager.send(type: type, bytes: bytes);
  }

  // Centalized method to send receipt bytes
  Future<void> sendReceiptBytes(List<int> bytes) async {
    const role = PrinterRole.receipt;
    if (!isConnected(role)) return;
    
    final type = connectionType(role) == PrinterConnectionType.bluetooth
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
