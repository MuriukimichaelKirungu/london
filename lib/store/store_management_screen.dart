// File: D:\London\lib\store\store_management_screen.dart
// Regenerated StoreManagementScreen
// Single-product move dialog (destination + per-product quantity) with immediate validation
// Also keeps edit/delete, multi-select + bulk delete (unchanged)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class StoreManagementScreen extends StatefulWidget {
  final bool isAdmin;

  const StoreManagementScreen({super.key, required this.isAdmin});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen>
    with WidgetsBindingObserver {
  String? selectedStore;
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  final Map<String, String> storeKeys = {
    "hotelAccra": "Hotel Accra",
    "silvermine": "Silvermine",
    "ssdSchool": "Ssd School",
    "rooftopLondon": "Rooftop London",
    "seventhLondon": "Seventh London",
  };

  final Map<String, String> allLocations = {
    "branch1": "5th London",
    "branch2": "3rd floor London",
    "branch3": "First floor London",

    "hotelAccra": "Hotel Accra",
    "silvermine": "Silvermine",
    "ssdSchool": "Ssd School",
    "rooftopLondon": "Rooftop London",
    "seventhLondon": "Seventh London",
  };

  CollectionReference<Map<String, dynamic>> _stockRef(String locationId) {
    return FirebaseFirestore.instance
        .collection("branches")
        .doc(locationId)
        .collection("stock");
  }

  /// Multi-select (kept for bulk delete)
  Set<String> selectedProducts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  // -----------------------
  // Add product (unchanged)
  // -----------------------
  Future<void> _addProduct(String storeId) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final buyingCtrl = TextEditingController();
    final sellingCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    final modelCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add Product to ${allLocations[storeId]}"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration:
                  const InputDecoration(labelText: "Product Name")),
              TextField(
                  controller: modelCtrl,
                  decoration:
                  const InputDecoration(labelText: "Model Number")),
              TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: buyingCtrl,
                  decoration:
                  const InputDecoration(labelText: "Buying Price"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: sellingCtrl,
                  decoration:
                  const InputDecoration(labelText: "Selling Price"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: minCtrl,
                  decoration: const InputDecoration(labelText: "Min Price"),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add"),
            onPressed: () async {
              await _stockRef(storeId).add({
                "name": nameCtrl.text,
                "modelNumber": modelCtrl.text,
                "quantity": int.tryParse(qtyCtrl.text) ?? 0,
                "buyingPrice": int.tryParse(buyingCtrl.text) ?? 0,
                "sellingPrice": int.tryParse(sellingCtrl.text) ?? 0,
                "minPrice": int.tryParse(minCtrl.text) ?? 0,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // -----------------------
  // Edit product (unchanged)
  // -----------------------
  void _editProduct(String productId, Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product["name"]);
    final modelCtrl = TextEditingController(text: product["modelNumber"]);
    final qtyCtrl =
    TextEditingController(text: (product["quantity"] ?? 0).toString());
    final buyingCtrl =
    TextEditingController(text: (product["buyingPrice"] ?? 0).toString());
    final sellingCtrl =
    TextEditingController(text: (product["sellingPrice"] ?? 0).toString());
    final minCtrl =
    TextEditingController(text: (product["minPrice"] ?? 0).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration:
                  const InputDecoration(labelText: "Product Name")),
              TextField(
                  controller: modelCtrl,
                  decoration:
                  const InputDecoration(labelText: "Model Number")),
              TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: buyingCtrl,
                  decoration:
                  const InputDecoration(labelText: "Buying Price"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: sellingCtrl,
                  decoration:
                  const InputDecoration(labelText: "Selling Price"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: minCtrl,
                  decoration: const InputDecoration(labelText: "Min Price"),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _stockRef(selectedStore!).doc(productId).update({
                "name": nameCtrl.text,
                "modelNumber": modelCtrl.text,
                "quantity": int.tryParse(qtyCtrl.text) ?? product["quantity"],
                "buyingPrice":
                int.tryParse(buyingCtrl.text) ?? product["buyingPrice"],
                "sellingPrice":
                int.tryParse(sellingCtrl.text) ?? product["sellingPrice"],
                "minPrice":
                int.tryParse(minCtrl.text) ?? product["minPrice"],
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // -----------------------
  // Delete product (unchanged)
  // -----------------------
  void _deleteProduct(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Delete $name?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _stockRef(selectedStore!).doc(id).delete();
      setState(() => selectedProducts.remove(id));
    }
  }

  // -----------------------
  // Bulk delete selected (unchanged)
  // -----------------------
  Future<void> _bulkDeleteSelected() async {
    if (selectedProducts.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Selected Products"),
        content: Text(
            "Are you sure you want to delete ${selectedProducts.length} selected product(s)? This cannot be undone."),
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
      final batch = FirebaseFirestore.instance.batch();
      for (var id in selectedProducts) {
        batch.delete(_stockRef(selectedStore!).doc(id));
      }
      await batch.commit();
      setState(() => selectedProducts.clear());
    }
  }

  // -----------------------------------------
  // BULK MOVE (NEW)
  // -----------------------------------------
  Future<void> _bulkMoveSelected() async {
    if (selectedProducts.length < 2) return;

    String? destination;
    final Map<String, TextEditingController> qtyCtrls = {};
    final Map<String, String?> errors = {};
    final Map<String, Map<String, dynamic>> products = {};

    for (final id in selectedProducts) {
      final doc = await _stockRef(selectedStore!).doc(id).get();
      if (doc.exists) {
        products[id] = doc.data()!;
        qtyCtrls[id] = TextEditingController();
        errors[id] = null;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool canMove() {
            if (destination == null) return false;
            for (final id in products.keys) {
              final available = products[id]!["quantity"] ?? 0;
              final entered = int.tryParse(qtyCtrls[id]!.text) ?? 0;
              if (entered <= 0 || entered > available) return false;
            }
            return true;
          }

          void validate(String id, String value) {
            final available = products[id]!["quantity"] ?? 0;
            final entered = int.tryParse(value) ?? 0;

            if (value.isEmpty) {
              errors[id] = "Required";
            } else if (entered <= 0) {
              errors[id] = "Must be > 0";
            } else if (entered > available) {
              errors[id] = "Max $available";
            } else {
              errors[id] = null;
            }
            setDialogState(() {});
          }

          return AlertDialog(
            title: const Text("Move Selected Products"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: destination,
                    items: allLocations.entries
                        .where((e) => e.key != selectedStore)
                        .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      destination = v;
                      setDialogState(() {});
                    },
                    decoration:
                    const InputDecoration(labelText: "Destination"),
                  ),
                  const SizedBox(height: 12),
                  ...products.entries.map((e) {
                    final id = e.key;
                    final p = e.value;
                    final available = p["quantity"] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: qtyCtrls[id],
                        keyboardType: TextInputType.number,
                        onChanged: (v) => validate(id, v),
                        decoration: InputDecoration(
                          labelText:
                          "${p["name"]} (Available: $available)",
                          errorText: errors[id],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: canMove()
                    ? () async {
                  final batch =
                  FirebaseFirestore.instance.batch();

                  for (final id in products.keys) {
                    final p = products[id]!;
                    final qtyToMove =
                    int.parse(qtyCtrls[id]!.text);
                    final available = p["quantity"] ?? 0;

                    batch.update(
                        _stockRef(selectedStore!).doc(id),
                        {"quantity": available - qtyToMove});

                    final exist = await _stockRef(destination!)
                        .where("name", isEqualTo: p["name"])
                        .where("modelNumber",
                        isEqualTo: p["modelNumber"])
                        .limit(1)
                        .get();

                    if (exist.docs.isNotEmpty) {
                      batch.update(exist.docs.first.reference, {
                        "quantity":
                        (exist.docs.first.data()["quantity"] ??
                            0) +
                            qtyToMove
                      });
                    } else {
                      batch.set(
                        _stockRef(destination!).doc(),
                        {...p, "quantity": qtyToMove},
                      );
                    }
                  }

                  await batch.commit();
                  setState(() => selectedProducts.clear());
                  Navigator.pop(ctx);
                }
                    : null,
                child: const Text("Move"),
              ),
            ],
          );
        },
      ),
    );
  }

  // -----------------------------------------
  // Move a single product (IMPLEMENTED)
  // -----------------------------------------
  Future<void> _moveSingleProduct(
      String productId, Map<String, dynamic> product) async {
    String? destination;
    final qtyCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final available = product["quantity"] ?? 0;

          bool canMove() {
            final q = int.tryParse(qtyCtrl.text) ?? 0;
            return destination != null && q > 0 && q <= available;
          }

          return AlertDialog(
            title: Text("Move ${product["name"]}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: destination,
                  decoration:
                  const InputDecoration(labelText: "Destination"),
                  items: allLocations.entries
                      .where((e) => e.key != selectedStore)
                      .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => destination = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Quantity (Available: $available)",
                    errorText: error,
                  ),
                  onChanged: (v) {
                    final q = int.tryParse(v) ?? 0;
                    if (v.isEmpty) {
                      error = "Required";
                    } else if (q <= 0) {
                      error = "Must be > 0";
                    } else if (q > available) {
                      error = "Max $available";
                    } else {
                      error = null;
                    }
                    setDialogState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: canMove()
                    ? () async {
                  final qty = int.parse(qtyCtrl.text);
                  final batch =
                  FirebaseFirestore.instance.batch();

                  batch.update(
                    _stockRef(selectedStore!).doc(productId),
                    {"quantity": available - qty},
                  );

                  final destRef = _stockRef(destination!);
                  final existing = await destRef
                      .where("name",
                      isEqualTo: product["name"])
                      .where("modelNumber",
                      isEqualTo: product["modelNumber"])
                      .limit(1)
                      .get();

                  if (existing.docs.isNotEmpty) {
                    final d = existing.docs.first;
                    batch.update(d.reference, {
                      "quantity":
                      (d.data()["quantity"] ?? 0) + qty
                    });
                  } else {
                    batch.set(destRef.doc(), {
                      ...product,
                      "quantity": qty,
                    });
                  }

                  await batch.commit();
                  setState(() =>
                      selectedProducts.remove(productId));
                  Navigator.pop(ctx);
                }
                    : null,
                child: const Text("Move"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedStore == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Store Management")),
        body: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: storeKeys.entries.map((e) {
              return ElevatedButton(
                onPressed: () => setState(() => selectedStore = e.key),
                child: Text("Go to ${e.value}"),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Products in ${allLocations[selectedStore]}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => selectedStore = null),
        ),
        actions: [
          if (selectedProducts.length > 1 && widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: "Move selected",
              onPressed: _bulkMoveSelected,
            ),
          if (selectedProducts.isNotEmpty && widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _bulkDeleteSelected,
            ),
          if (widget.isAdmin)
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addProduct(selectedStore!)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search...",
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stockRef(selectedStore!).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var list = snapshot.data!.docs.where((doc) {
                  final d = doc.data();
                  final name =
                  (d["name"] ?? "").toString().toLowerCase();
                  final model =
                  (d["modelNumber"] ?? "").toString().toLowerCase();
                  return name.contains(searchQuery) ||
                      model.contains(searchQuery);
                }).toList();

                if (list.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                return SingleChildScrollView(
                  child: PaginatedDataTable(
                    header: const Text("Inventory"),
                    rowsPerPage: 10,
                    showCheckboxColumn: widget.isAdmin,
                    columns: const [
                      DataColumn(label: Text("Product")),
                      DataColumn(label: Text("Model")),
                      DataColumn(label: Text("Qty")),
                      DataColumn(label: Text("Buying")),
                      DataColumn(label: Text("Selling")),
                      DataColumn(label: Text("Min Price")),
                      DataColumn(label: Text("Actions")),
                    ],
                    source: _StoreTableSource(
                      products: list,
                      isAdmin: widget.isAdmin,
                      selectedProducts: selectedProducts,
                      onSelectionChanged: () => setState(() {}),
                      onEdit: _editProduct,
                      onDelete: _deleteProduct,
                      onMove: _moveSingleProduct,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------
// DataTable source (unchanged)
// -----------------------
class _StoreTableSource extends DataTableSource {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> products;
  final bool isAdmin;
  final Set<String> selectedProducts;
  final VoidCallback onSelectionChanged;
  final Function(String, Map<String, dynamic>) onEdit;
  final Function(String, String) onDelete;
  final Future<void> Function(String, Map<String, dynamic>) onMove;

  _StoreTableSource({
    required this.products,
    required this.isAdmin,
    required this.selectedProducts,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  @override
  DataRow getRow(int index) {
    final doc = products[index];
    final p = doc.data();

    return DataRow.byIndex(
      index: index,
      selected: selectedProducts.contains(doc.id),
      onSelectChanged: isAdmin
          ? (val) {
        if (val == true) {
          selectedProducts.add(doc.id);
        } else {
          selectedProducts.remove(doc.id);
        }
        onSelectionChanged();
      }
          : null,
      cells: [
        DataCell(Text(p["name"] ?? "")),
        DataCell(Text(p["modelNumber"] ?? "-")),
        DataCell(Text("${p["quantity"] ?? 0}")),
        DataCell(Text("Ksh ${p["buyingPrice"] ?? 0}")),
        DataCell(Text("Ksh ${p["sellingPrice"] ?? 0}")),
        DataCell(Text("Ksh ${p["minPrice"] ?? 0}")),
        DataCell(Row(
          children: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.compare_arrows, color: Colors.orange),
                onPressed: () => onMove(doc.id, p),
              ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => onEdit(doc.id, p),
              ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(doc.id, p["name"] ?? ""),
              ),
          ],
        )),
      ],
    );
  }

  @override
  int get rowCount => products.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedProducts.length;
}
