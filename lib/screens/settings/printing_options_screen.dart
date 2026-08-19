import 'package:mpos/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mpos/provider/printing_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PrintingOptionsScreen extends StatefulWidget {
  const PrintingOptionsScreen({super.key});

  @override
  State<PrintingOptionsScreen> createState() => _PrintingOptionsScreenState();
}

class _PrintingOptionsScreenState extends State<PrintingOptionsScreen> {
  PrinterRole _activeRole = PrinterRole.receipt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final provider = context.read<PrintingProvider>();
    if (provider.connectionType(_activeRole) == PrinterConnectionType.bluetooth) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      
      if (statuses.values.any((status) => status.isDenied)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('bluetooth_permission_required'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final printingProvider = context.watch<PrintingProvider>();
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('printing_options'), style: const TextStyle(fontWeight: FontWeight.w800)),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _activeRole = index == 0 ? PrinterRole.receipt : PrinterRole.label;
              });
            },
            tabs: const [
              Tab(text: 'Receipt Printer'),
              Tab(text: 'Label Printer'),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRoleHeader(printingProvider, theme),
            const SizedBox(height: 12),
            _buildConnectionSection(printingProvider, theme),
            const SizedBox(height: 12),
            _buildPaperSizeSection(printingProvider, theme),
            const SizedBox(height: 12),
            if (_activeRole == PrinterRole.receipt) ...[
              _buildAutoPrintSection(printingProvider, theme),
              const SizedBox(height: 20),
            ],
            _buildDeviceListSection(printingProvider, theme),
            const SizedBox(height: 20),
            _buildTestingSection(printingProvider, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleHeader(PrintingProvider provider, ThemeData theme) {
    final isConnected = provider.isConnected(_activeRole);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withOpacity(0.1) : theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isConnected ? Colors.green : theme.colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.error_outline,
            color: isConnected ? Colors.green : theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeRole == PrinterRole.receipt ? 'Receipt Printer Setup' : 'Label Printer Setup',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isConnected ? 'Connected and ready' : 'Not connected',
                  style: TextStyle(fontSize: 12, color: isConnected ? Colors.green[700] : theme.colorScheme.error),
                ),
              ],
            ),
          ),
          if (isConnected)
            TextButton(
              onPressed: () => provider.disconnect(_activeRole),
              child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeSection(PrintingProvider provider, ThemeData theme) {
    final sizes = [30, 44, 57, 58, 70, 72, 80];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('paper_size'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes.map((width) {
                final isSelected = provider.paperWidthMm(_activeRole) == width;
                return ChoiceChip(
                  label: Text('${width}mm'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) provider.setPaperWidth(_activeRole, width);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection(PrintingProvider provider, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('connection_type'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(context.tr('bluetooth'))),
                    selected: provider.connectionType(_activeRole) == PrinterConnectionType.bluetooth,
                    onSelected: (selected) {
                      if (selected) provider.setConnectionType(_activeRole, PrinterConnectionType.bluetooth);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(context.tr('usb'))),
                    selected: provider.connectionType(_activeRole) == PrinterConnectionType.usb,
                    onSelected: (selected) {
                      if (selected) provider.setConnectionType(_activeRole, PrinterConnectionType.usb);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoPrintSection(PrintingProvider provider, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: SwitchListTile(
        title: Text(context.tr('automatic_printing'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        subtitle: Text(context.tr('auto_print_subtitle')),
        value: provider.autoPrint,
        onChanged: (value) => provider.setAutoPrint(value),
      ),
    );
  }

  Widget _buildDeviceListSection(PrintingProvider provider, ThemeData theme) {
    final devices = provider.connectionType(_activeRole) == PrinterConnectionType.bluetooth
        ? provider.bluetoothDevices
        : provider.usbDevices;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('available_devices'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                if (provider.isScanning)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => provider.scanDevices(_activeRole),
                  ),
              ],
            ),
          ),
          if (devices.isEmpty)
             Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  context.tr('no_devices_found'),
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = devices[index];
                final String name = (device is BluetoothPrinter ? device.deviceName : (device as UsbPrinter).deviceName) ?? 'Unknown Device';
                final String address = (device is BluetoothPrinter ? device.address : (device as UsbPrinter).address) ?? '';
                
                final selectedDevice = provider.selectedPrinter(_activeRole);
                final isSelected = selectedDevice != null && 
                    ((device is BluetoothPrinter && selectedDevice is BluetoothPrinter && selectedDevice.address == device.address) ||
                     (device is UsbPrinter && selectedDevice is UsbPrinter && selectedDevice.address == device.address));

                return ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(address),
                  trailing: isSelected && provider.isConnected(_activeRole)
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => provider.connect(_activeRole, device),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTestingSection(PrintingProvider provider, ThemeData theme) {
    final isConnected = provider.isConnected(_activeRole);
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: isConnected ? () => provider.testPrint(_activeRole) : null,
          icon: const Icon(Icons.print),
          label: Text('Print Test (${_activeRole == PrinterRole.receipt ? 'Receipt' : 'Label'})'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (!isConnected)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr('connect_printer_first'),
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
