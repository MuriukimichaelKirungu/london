import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptsPreviewScreen extends StatefulWidget {
  final String branch;
  final String employee;
  final String clientName;
  final DateTime date;
  final List<Map<String, dynamic>> items;

  const ReceiptsPreviewScreen({
    super.key,
    required this.branch,
    required this.employee,
    required this.clientName,
    required this.date,
    required this.items,
  });

  @override
  State<ReceiptsPreviewScreen> createState() =>
      _ReceiptsPreviewScreenState();
}

class _ReceiptsPreviewScreenState extends State<ReceiptsPreviewScreen> {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  bool _customerPrinted = false;
  BluetoothDevice? selectedDevice;

  int get grandTotal =>
      widget.items.fold(0, (sum, item) => sum + (item["total"] as int));

  String get formattedDate =>
      DateFormat("dd/MM/yyyy hh:mm a").format(widget.date.toLocal());

  final currencyFormatter = NumberFormat("#,##0");

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString("printer_address");

    if (savedAddress == null) return;

    List<BluetoothDevice> devices =
    await printer.getBondedDevices();

    for (var device in devices) {
      if (device.address == savedAddress) {
        selectedDevice = device;
        try {
          await printer.connect(device);
        } catch (_) {}
        setState(() {});
        break;
      }
    }
  }

  Future<void> _savePrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("printer_address", device.address!);
  }

  Future<void> selectPrinter() async {
    List<BluetoothDevice> devices =
    await printer.getBondedDevices();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: devices.map((device) {
            return ListTile(
              title: Text(device.name ?? "Unknown"),
              subtitle: Text(device.address ?? ""),
              onTap: () async {
                Navigator.pop(context);
                await printer.connect(device);
                await _savePrinter(device);
                setState(() => selectedDevice = device);
              },
            );
          }).toList(),
        );
      },
    );
  }

  // ==============================
  // 🔥 BLUETOOTH PRINT
  // ==============================
  Future<void> printViaBluetooth() async {
    bool? isConnected = await printer.isConnected;

    if (isConnected != true) {
      if (selectedDevice != null) {
        await printer.connect(selectedDevice!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please connect printer first")),
        );
        return;
      }
    }

    final copyType = _customerPrinted ? "BUSINESS" : "CUSTOMER";

    double totalVatAll = 0;
    double totalExVatAll = 0;

    printer.printNewLine();
    printer.printCustom("HEBAIC GENERAL TRADERS LIMITED", 3, 1);
    printer.printCustom("CONTACTS: 0706565994", 1, 1);
    printer.printCustom(
        "LOCATION: TAVETA ROAD LONDON BEAUTY FIRST FLOOR F8", 1, 1);

    printer.printNewLine();
    printer.printCustom("---- $copyType COPY ----", 2, 0);
    printer.printCustom("BRANCH: ${widget.branch}", 1, 0);
    printer.printCustom("CASHIER: ${widget.employee}", 1, 0);
    printer.printCustom("CUSTOMER: ${widget.clientName}", 1, 0);
    printer.printCustom("DATE: $formattedDate", 1, 0);

    printer.printNewLine();

    for (var item in widget.items) {
      final product =
      (item["product"] ?? "").toString().toUpperCase();

      final qty = item["quantity"] ?? 0;
      final sellingPrice = item["unitPrice"] ?? 0;

      final total = sellingPrice * qty;
      final exVat = (sellingPrice / 1.16) * qty;
      final vat = total - exVat;

      totalVatAll += vat;
      totalExVatAll += exVat;

      printer.printCustom(product, 1, 0);
      printer.printCustom("QTY: $qty", 1, 0);
      printer.printCustom(
          "UNIT PRICE (EX VAT): ${currencyFormatter.format(exVat)}", 1, 0);
      printer.printCustom(
          "VAT (16%): ${currencyFormatter.format(vat)}", 1, 0);
      printer.printCustom(
          "TOTAL (INC VAT): ${currencyFormatter.format(total)}", 1, 0);

      printer.printNewLine();
    }

    printer.printCustom(
        "TOTAL EX VAT: ${currencyFormatter.format(totalExVatAll)}", 1, 0);
    printer.printCustom(
        "TOTAL VAT: ${currencyFormatter.format(totalVatAll)}", 1, 0);

    printer.printNewLine();
    printer.printCustom(
        "GRAND TOTAL: KSH ${currencyFormatter.format(grandTotal)}",
        2,
        0);

    printer.printNewLine();
    printer.printCustom("THANK YOU FOR SHOPPING WITH US!", 1, 1);
    printer.printNewLine();
    printer.paperCut();

    if (!_customerPrinted) {
      setState(() => _customerPrinted = true);
    }
  }

  // ==============================
  // 📄 PDF PRINT
  // ==============================
  Future<void> printViaPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4,
        ),
        build: (_) => pw.Text("Use Android for Bluetooth printing"),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }

  Future<void> _handlePrint() async {
    if (Platform.isAndroid) {
      await printViaBluetooth();
    } else {
      await printViaPdf();
    }
  }

  // ==============================
  // 🖥 PREVIEW
  // ==============================
  String _buildPreview(String copyType) {
    final buffer = StringBuffer();

    double totalVatAll = 0;
    double totalExVatAll = 0;

    buffer.writeln("HEBAIC GENERAL TRADERS LIMITED");
    buffer.writeln("CONTACTS: 0706565994");
    buffer.writeln("LOCATION: TAVETA ROAD LONDON BEAUTY FIRST FLOOR F8");
    buffer.writeln("---- $copyType COPY ----");
    buffer.writeln("BRANCH: ${widget.branch}");
    buffer.writeln("CASHIER: ${widget.employee}");
    buffer.writeln("CUSTOMER: ${widget.clientName}");
    buffer.writeln("DATE: $formattedDate");
    buffer.writeln("--------------------------------");

    for (var item in widget.items) {
      final product =
      (item["product"] ?? "").toString().toUpperCase();

      final qty = item["quantity"] ?? 0;
      final sellingPrice = item["unitPrice"] ?? 0;

      final total = sellingPrice * qty;
      final exVat = (sellingPrice / 1.16) * qty;
      final vat = total - exVat;

      totalVatAll += vat;
      totalExVatAll += exVat;

      buffer.writeln(product);
      buffer.writeln("QTY: $qty");
      buffer.writeln(
          "UNIT PRICE (EX VAT): ${currencyFormatter.format(exVat)}");
      buffer.writeln("VAT (16%): ${currencyFormatter.format(vat)}");
      buffer.writeln(
          "TOTAL (INC VAT): ${currencyFormatter.format(total)}\n");
    }

    buffer.writeln("--------------------------------");
    buffer.writeln(
        "TOTAL EX VAT: ${currencyFormatter.format(totalExVatAll)}");
    buffer.writeln(
        "TOTAL VAT: ${currencyFormatter.format(totalVatAll)}");
    buffer.writeln(
        "GRAND TOTAL: KSH ${currencyFormatter.format(grandTotal)}");
    buffer.writeln("THANK YOU FOR SHOPPING WITH US!");

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final previewText = _buildPreview("Customer") +
        "-------- CUT HERE --------\n" +
        _buildPreview("Business");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _handlePrint,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: selectPrinter,
              icon: const Icon(Icons.bluetooth),
              label: Text(
                selectedDevice == null
                    ? "Connect Printer"
                    : "Connected: ${selectedDevice!.name}",
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  previewText,
                  style: const TextStyle(
                    fontFamily: "monospace",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}