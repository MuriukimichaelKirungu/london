import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ReceiptsPreviewScreen extends StatefulWidget {
  final String branch;
  final String employee;
  final String clientName;
  final DateTime date;

  // item = {"product": String, "quantity": int, "unitPrice": int, "discount": int, "total": int}
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
  State<ReceiptsPreviewScreen> createState() => _ReceiptsPreviewScreenState();
}

class _ReceiptsPreviewScreenState extends State<ReceiptsPreviewScreen> {
  bool _customerPrinted = false;

  int get grandTotal =>
      widget.items.fold(0, (sum, item) => sum + (item["total"] as int));

  String get formattedDate =>
      DateFormat("dd/MM/yyyy hh:mm a").format(widget.date.toLocal());

  /// 🔹 Build PDF receipt (item name line, qty & price below)
  pw.Widget _buildReceipt(String copyType) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  "HEBAIC GENERAL TRADERS LIMITED",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "CONTACTS: 0706565994",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "LOCATION: TAVETA ROAD LONDON BEAUTY FIRST FLOOR F8",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "DEALS: TVS, RADIOS, AMPLIFIERS, SPEAKERS,\n"
                      "FRIDGES & FREEZERS, SOLAR BATTERIES,\n"
                      "ALL ELECTRONICS & ACCESSORIES",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 6),
          pw.Text(
            "---- $copyType COPY ----",
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            "BRANCH: ${widget.branch.toUpperCase()}",
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "CASHIER: ${widget.employee.toUpperCase()}",
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "CUSTOMER: ${widget.clientName.toUpperCase()}",
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "DATE: $formattedDate",
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),

          ...widget.items.map((item) {
            final product =
            (item["product"] ?? "").toString().toUpperCase();
            final qty = item["quantity"] ?? 0;
            final unitPrice = item["unitPrice"] ?? 0;
            final totalPrice = unitPrice * qty; // ✅ Multiply by quantity

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  product,
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "QTY: $qty    KSH $totalPrice", // ✅ show total for line item
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
              ],
            );
          }).toList(),

          pw.Divider(),
          pw.Text(
            "GRAND TOTAL: KSH $grandTotal",
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              "THANK YOU FOR SHOPPING WITH US!",
              style: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 AppBar print button handler (customer → business)
  Future<void> _handlePrint() async {
    final copyType = _customerPrinted ? "Business" : "Customer";

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4,
        ),
        build: (_) => _buildReceipt(copyType),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );

    if (!_customerPrinted) {
      setState(() => _customerPrinted = true);
    }
  }

  /// 🔹 Build text preview
  String _buildPreview(String copyType) {
    final buffer = StringBuffer();
    buffer.writeln("HEBAIC GENERAL TRADERS LIMITED");
    buffer.writeln("CONTACTS: 0706565994");
    buffer.writeln("LOCATION: TAVETA ROAD LONDON BEAUTY FIRST FLOOR f8");
    buffer.writeln("---- $copyType COPY ----");
    buffer.writeln("BRANCH: ${widget.branch.toUpperCase()}");
    buffer.writeln("CASHIER: ${widget.employee.toUpperCase()}");
    buffer.writeln("CUSTOMER: ${widget.clientName.toUpperCase()}");
    buffer.writeln("DATE: $formattedDate");
    buffer.writeln("--------------------------------");

    for (var item in widget.items) {
      final product =
      (item["product"] ?? "").toString().toUpperCase();
      final qty = item["quantity"] ?? 0;
      final unitPrice = item["unitPrice"] ?? 0;
      final totalPrice = unitPrice * qty; // ✅ Multiply by quantity

      buffer.writeln(product);
      buffer.writeln("QTY: $qty    KSH $totalPrice\n"); // ✅ show total for line item
    }

    buffer.writeln("--------------------------------");
    buffer.writeln("GRAND TOTAL: KSH $grandTotal");
    buffer.writeln("VAT 16% INCLUDED");
    buffer.writeln("THANK YOU FOR SHOPPING WITH US!");
    buffer.writeln("");
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final previewText = _buildPreview("Customer") +
        "-------- CUT HERE --------\n" +
        _buildPreview("Business");

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600 && screenWidth <= 900;
        final isDesktop = screenWidth > 900;

        final horizontalPadding = isDesktop
            ? 48.0
            : isTablet
            ? 32.0
            : 16.0;

        final fontSize = isDesktop
            ? 16.0
            : isTablet
            ? 15.0
            : 14.0;

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
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: SingleChildScrollView(
              child: Text(
                previewText,
                style: TextStyle(
                  fontFamily: "monospace",
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
