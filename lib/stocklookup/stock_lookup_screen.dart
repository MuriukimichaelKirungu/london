import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockLookupScreen extends StatefulWidget {
  const StockLookupScreen({super.key});

  @override
  State<StockLookupScreen> createState() => _StockLookupScreenState();
}

class _StockLookupScreenState extends State<StockLookupScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> results = [];
  bool isLoading = false;

  /// 🔥 ALL SHOPS
  final Map<String, String> branchLabels = {
    "branch1": "5th London",
    "branch2": "3rd floor London",
    "branch3": "First floor London",
    "hotelAccra": "Hotel Accra",
    "silvermine": "Silvermine",
    "ssdSchool": "Ssd School",
    "rooftopLondon": "Rooftop London",
    "seventhLondon": "Seventh London",
  };

  /// ⚡ OPTIMIZED SEARCH (PARALLEL FETCH)
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => isLoading = true);

    try {
      final lowerQuery = query.toLowerCase();

      /// 🔥 FETCH ALL BRANCHES IN PARALLEL
      final futures = branchLabels.keys.map((branch) {
        return FirebaseFirestore.instance
            .collection("branches")
            .doc(branch)
            .collection("stock")
            .get()
            .then((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            return {
              "branch": branchLabels[branch],
              "name": data["name"] ?? "",
              "model": data["modelNumber"] ?? "",
              "quantity": data["quantity"] ?? 0,
            };
          }).toList();
        });
      }).toList();

      final allResults = await Future.wait(futures);

      /// 🔍 FLATTEN + FILTER
      final filtered = allResults
          .expand((list) => list)
          .where((item) {
        final name = item["name"].toString().toLowerCase();
        final model = item["model"].toString().toLowerCase();

        return name.contains(lowerQuery) ||
            model.contains(lowerQuery);
      }).toList();

      setState(() => results = filtered);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  /// 🧾 GROUP RESULTS
  Map<String, List<Map<String, dynamic>>> groupResults() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in results) {
      final key = "${item["name"]}_${item["model"]}";

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupResults();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Lookup"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔍 SEARCH
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search product or model...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: searchProducts,
            ),

            const SizedBox(height: 16),

            /// LOADING
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )

            /// EMPTY
            else if (grouped.isEmpty)
              const Expanded(
                child: Center(child: Text("No results found")),
              )

            /// RESULTS (UPDATED TO PAGINATED TABLE)
            else
              Expanded(
                child: SingleChildScrollView(
                  child: PaginatedDataTable(
                    header: const Text("Stock Results"),
                    rowsPerPage: 5,
                    columns: const [
                      DataColumn(label: Text("Product")),
                      DataColumn(label: Text("Model")),
                      DataColumn(label: Text("Branch")),
                      DataColumn(label: Text("Quantity")),
                    ],
                    source: _StockTableSource(results),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockTableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;

  _StockTableSource(this.data);

  @override
  DataRow getRow(int index) {
    if (index >= data.length) return const DataRow(cells: []);

    final item = data[index];

    return DataRow(cells: [
      DataCell(Text(item["name"] ?? "")),
      DataCell(Text(item["model"] ?? "")),
      DataCell(Text(item["branch"] ?? "")),
      DataCell(Text(item["quantity"].toString())),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}