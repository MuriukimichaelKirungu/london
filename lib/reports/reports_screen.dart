import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// PDF
import 'package:pdf/widgets.dart' as pw;

// MediaStore
import 'package:media_store_plus/media_store_plus.dart';

class ReportsScreen extends StatefulWidget {
  final String branchName;

  const ReportsScreen({super.key, required this.branchName});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? customRange;
  String selectedRange = "This Month";

  final currencyFormatter = NumberFormat("#,##0");

  static const Map<String, String> branchLabels = {
    "branch1": "5th London",
    "branch2": "3rd floor London",
    "branch3": "First floor London",
  };

  String get displayBranch =>
      branchLabels[widget.branchName] ?? widget.branchName;

  // ==============================
  // 🔥 INIT MEDIASTORE (UPDATED)
  // ==============================
  @override
  void initState() {
    super.initState();
    _initMediaStore();
  }

  Future<void> _initMediaStore() async {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = "LondonReports"; // ✅ ADDED
  }

  int asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _isInSelectedRange(DateTime date) {
    final now = DateTime.now();

    if (selectedRange == "All Time") return true;

    if (selectedRange == "Today") {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }

    if (selectedRange == "This Week") {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
    }

    if (selectedRange == "This Month") {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      return date.isAfter(startOfMonth) && date.isBefore(endOfMonth);
    }

    if (selectedRange == "Custom Range" && customRange != null) {
      return date.isAfter(customRange!.start) &&
          date.isBefore(customRange!.end.add(const Duration(days: 1)));
    }

    return true;
  }

  Future<void> _deleteSalesInSelectedRange(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bulk Delete"),
        content: const Text("Delete ALL reports in selected range?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          )
        ],
      ),
    );

    if (confirm != true) return;

    final ref = FirebaseFirestore.instance
        .collection("branches")
        .doc(widget.branchName)
        .collection("sales");

    final snapshot = await ref.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      final sale = doc.data();
      final date = (sale["timestamp"] ?? sale["date"]) is Timestamp
          ? (sale["timestamp"] ?? sale["date"]).toDate()
          : null;

      if (date != null && _isInSelectedRange(date)) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  Future<void> _deleteSale(String saleId) async {
    await FirebaseFirestore.instance
        .collection("branches")
        .doc(widget.branchName)
        .collection("sales")
        .doc(saleId)
        .delete();
  }

  // ==============================
  // 📄 SAVE PDF (UPDATED)
  // ==============================
  Future<void> _savePdfToDownloads(Uint8List pdfBytes) async {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = "LondonReports"; // ✅ ADDED

    try {
      final fileName =
          "report_${DateTime.now().millisecondsSinceEpoch}.pdf";

      final tempDir = Directory.systemTemp;
      final tempFile = File("${tempDir.path}/$fileName");

      await tempFile.writeAsBytes(pdfBytes);

      final result = await MediaStore().saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Saved to Downloads/LondonReports")),
        );
      } else {
        throw "Failed to save file";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  // ==============================
  // 📄 DOWNLOAD REPORT
  // ==============================
  // ONLY CHANGE IS INSIDE _downloadReport METHOD
  Future<void> _downloadReport(List<QueryDocumentSnapshot> salesDocs) async {
    final pdf = pw.Document();

    int grandTotal = 0;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("HEBAIC GENERAL TRADERS LIMITED",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text("REPORT (${displayBranch})"),
          pw.Text("DATE: ${selectedRange}"),
          pw.SizedBox(height: 10),

          // 🔥 SALES LIST
          ...salesDocs.map((doc) {
            final sale = doc.data() as Map<String, dynamic>;

            final date = (sale["timestamp"] ?? sale["date"]) is Timestamp
                ? (sale["timestamp"] ?? sale["date"]).toDate()
                : DateTime.now();

            final products = (sale["products"] as List?) ?? [];

            final total = asInt(sale["grandTotal"]);
            grandTotal += total;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Date: ${DateFormat('dd/MM/yyyy').format(date)}"),
                pw.Text("Customer: ${sale["customer"] ?? "Unknown"}"),
                pw.Text("Employee: ${sale["employee"] ?? "N/A"}"),

                pw.Text("Products:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

                ...products.map((p) => pw.Text(
                  " - ${p["product"]} (${p["quantity"]})",
                )),

                pw.Text("Total: Ksh ${currencyFormatter.format(total)}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

                pw.Divider(),
                pw.SizedBox(height: 5),
              ],
            );
          }).toList(),

          pw.SizedBox(height: 10),

          // 🔥 GRAND TOTAL
          pw.Text(
            "TOTAL SALES: Ksh ${currencyFormatter.format(grandTotal)}",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await _savePdfToDownloads(bytes);
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<String>(
          value: selectedRange,
          items: const [
            DropdownMenuItem(value: "All Time", child: Text("All Time")),
            DropdownMenuItem(value: "Today", child: Text("Today")),
            DropdownMenuItem(value: "This Week", child: Text("This Week")),
            DropdownMenuItem(value: "This Month", child: Text("This Month")),
            DropdownMenuItem(value: "Custom Range", child: Text("Custom Range")),
          ],
          onChanged: (value) async {
            if (value == "Custom Range") {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  selectedRange = "Custom Range";
                  customRange = picked;
                });
              }
            } else {
              setState(() => selectedRange = value!);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports - $displayBranch"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _deleteSalesInSelectedRange(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("branches")
            .doc(widget.branchName)
            .collection("sales")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;
          final salesDocs = allDocs.where((doc) {
            final sale = doc.data() as Map<String, dynamic>;
            final date = (sale["timestamp"] ?? sale["date"]) is Timestamp
                ? (sale["timestamp"] ?? sale["date"]).toDate()
                : DateTime.now();
            return _isInSelectedRange(date);
          }).toList();

          int totalSales = salesDocs.fold<int>(
              0,
                  (prev, doc) =>
              prev + asInt((doc.data() as Map)["grandTotal"]));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFilterBar(context),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadReport(salesDocs),
                    ),
                  ],
                ),
                Card(
                  child: ListTile(
                    title: const Text("Total Sales"),
                    subtitle: Text("Ksh $totalSales"),
                  ),
                ),
                Expanded(
                  child: PaginatedDataTable(
                    header: const Text("Sales Report"),
                    rowsPerPage: 5,
                    columns: const [
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Customer")),
                      DataColumn(label: Text("Employee")),
                      DataColumn(label: Text("Products")),
                      DataColumn(label: Text("Total")),
                      DataColumn(label: Text("Action")),
                    ],
                    source: _ReportsTableSource(
                      salesDocs,
                      asInt,
                      _deleteSale,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==============================
// TABLE SOURCE
// ==============================
class _ReportsTableSource extends DataTableSource {
  final List<QueryDocumentSnapshot> data;
  final int Function(dynamic) asInt;
  final Function(String) onDelete;

  _ReportsTableSource(this.data, this.asInt, this.onDelete);

  @override
  DataRow getRow(int index) {
    if (index >= data.length) return const DataRow(cells: []);

    final doc = data[index];
    final sale = doc.data() as Map<String, dynamic>;

    final date = (sale["timestamp"] ?? sale["date"]) is Timestamp
        ? (sale["timestamp"] ?? sale["date"]).toDate()
        : DateTime.now();

    final customer = sale["customer"] ?? "Unknown";
    final employee = sale["employee"] ?? "N/A";
    final total = asInt(sale["grandTotal"]);

    final products = (sale["products"] as List?) ?? [];

    final productNames = products
        .map((p) => "${p["product"]} (${p["quantity"]})")
        .join(", ");

    return DataRow(cells: [
      DataCell(Text(DateFormat('dd/MM/yyyy').format(date))),
      DataCell(Text(customer)),
      DataCell(Text(employee)),
      DataCell(Text(productNames)),
      DataCell(Text("Ksh $total")),
      DataCell(
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => onDelete(doc.id),
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}