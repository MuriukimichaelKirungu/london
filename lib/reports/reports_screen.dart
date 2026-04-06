import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  final String branchName;

  const ReportsScreen({super.key, required this.branchName});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? customRange;
  String selectedRange = "This Month";

  static const Map<String, String> branchLabels = {
    "branch1": "5th London",
    "branch2": "3rd floor London",
    "branch3": "First floor London",
  };

  String get displayBranch =>
      branchLabels[widget.branchName] ?? widget.branchName;

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
    final rangeLabel =
    selectedRange == "Custom Range" && customRange != null
        ? "${DateFormat('dd/MM/yyyy').format(customRange!.start)} - ${DateFormat('dd/MM/yyyy').format(customRange!.end)}"
        : selectedRange;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Sales"),
        content: Text(
          "This will permanently delete ALL sales in:\n\n$rangeLabel\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
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
    int deletedCount = 0;

    for (final doc in snapshot.docs) {
      final sale = doc.data();
      final date = (sale["timestamp"] ?? sale["date"]) is Timestamp
          ? (sale["timestamp"] ?? sale["date"]).toDate()
          : null;

      if (date != null && _isInSelectedRange(date)) {
        batch.delete(doc.reference);
        deletedCount++;
      }
    }

    if (deletedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ℹ️ No sales found for selected range")),
      );
      return;
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🗑️ Deleted $deletedCount sales")),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, List<QueryDocumentSnapshot> salesDocs) async {
    final e = excel.Excel.createExcel();
    final sheet = e['Sales Report'];

    sheet.appendRow([
      excel.TextCellValue("Date"),
      excel.TextCellValue("Customer"),
      excel.TextCellValue("Employee"),
      excel.TextCellValue("Product"),
      excel.TextCellValue("Quantity"),
      excel.TextCellValue("Unit Price"),
      excel.TextCellValue("Discount"),
      excel.TextCellValue("Total"),
      excel.TextCellValue("Grand Total (Sale)"),
    ]);

    for (var doc in salesDocs) {
      final sale = doc.data() as Map<String, dynamic>;
      final date = (sale["timestamp"] ?? sale["date"]) is Timestamp
          ? (sale["timestamp"] ?? sale["date"]).toDate()
          : DateTime.now();
      if (!_isInSelectedRange(date)) continue;

      final customer = sale["customer"] ?? "Unknown";
      final employee = sale["employee"] ?? "N/A";
      final grandTotal = asInt(sale["grandTotal"]);
      final products = (sale["products"] as List?) ?? [];

      for (var item in products) {
        sheet.appendRow([
          excel.TextCellValue(DateFormat('dd/MM/yyyy').format(date)),
          excel.TextCellValue(customer),
          excel.TextCellValue(employee),
          excel.TextCellValue(item["product"] ?? "Unknown"),
          excel.IntCellValue(asInt(item["quantity"])),
          excel.IntCellValue(asInt(item["unitPrice"])),
          excel.IntCellValue(asInt(item["discount"])),
          excel.IntCellValue(asInt(item["total"])),
          excel.IntCellValue(grandTotal),
        ]);
      }
    }

    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}";
    final safeBranchName = displayBranch.replaceAll(" ", "_");
    final dir = await getApplicationDocumentsDirectory();
    final file =
    File("${dir.path}/${safeBranchName}_report_$formattedDate.xlsx");

    await file.writeAsBytes(e.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Excel exported: ${file.path}")),
    );
  }

  Future<void> _deleteSale(
      BuildContext context, String saleId, String customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Sale"),
        content:
        Text("Are you sure you want to delete the sale for $customer?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection("branches")
          .doc(widget.branchName)
          .collection("sales")
          .doc(saleId)
          .delete();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("🗑️ Sale deleted")));
    }
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
        Text(
          selectedRange == "Custom Range" && customRange != null
              ? "${DateFormat('dd/MM/yyyy').format(customRange!.start)} - ${DateFormat('dd/MM/yyyy').format(customRange!.end)}"
              : selectedRange,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
            tooltip: "Delete sales in selected range",
            onPressed: () => _deleteSalesInSelectedRange(context),
          ),
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
              prev +
                  asInt(
                      (doc.data() as Map<String, dynamic>)["grandTotal"]));

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isTablet = screenWidth > 600 && screenWidth <= 900;
              final isDesktop = screenWidth > 900;
              final padding = isDesktop
                  ? 48.0
                  : isTablet
                  ? 32.0
                  : 16.0;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterBar(context),
                    const SizedBox(height: 12),
                    Text(
                      "Reports Overview (${displayBranch})",
                      style: TextStyle(
                        fontSize: isDesktop ? 28 : isTablet ? 22 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue.shade50,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.analytics,
                                color: Colors.blue.shade700,
                                size: isDesktop ? 48 : 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Total Sales",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text("Ksh $totalSales",
                                      style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          color: Colors.blue.shade800)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download),
                              tooltip: "Export to Excel",
                              onPressed: () =>
                                  _exportToExcel(context, salesDocs),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: salesDocs.length,
                        itemBuilder: (context, index) {
                          final doc = salesDocs[index];
                          final sale =
                          doc.data() as Map<String, dynamic>;
                          final date =
                          (sale["timestamp"] ?? sale["date"])
                          is Timestamp
                              ? (sale["timestamp"] ?? sale["date"])
                              .toDate()
                              : DateTime.now();
                          final customer =
                              sale["customer"] ?? "Unknown";
                          final employee =
                              sale["employee"] ?? "N/A";
                          final grandTotal =
                          asInt(sale["grandTotal"]);
                          final products =
                              (sale["products"] as List?)
                                  ?.cast<Map>() ??
                                  [];

                          return Card(
                            elevation: 2,
                            margin:
                            const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                            child: ExpansionTile(
                              leading: Icon(Icons.receipt_long,
                                  color: Colors.blue.shade600),
                              title: Text(
                                  "Customer: $customer — Total: Ksh $grandTotal",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                "Date: ${DateFormat('dd/MM/yyyy').format(date)} | Employee: $employee",
                                style: const TextStyle(
                                    color: Colors.black54),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                tooltip: "Delete Sale",
                                onPressed: () => _deleteSale(
                                    context, doc.id, customer),
                              ),
                              children: products.map((item) {
                                final qty =
                                asInt(item["quantity"]);
                                final price =
                                asInt(item["unitPrice"]);
                                final total =
                                asInt(item["total"]);
                                final discount =
                                asInt(item["discount"]);
                                return ListTile(
                                  title: Text(
                                      item["product"] ?? "Unknown"),
                                  subtitle: Text(
                                      "$qty × Ksh $price - Discount: Ksh $discount = Total: Ksh $total"),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}