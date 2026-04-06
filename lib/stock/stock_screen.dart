import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../receipts/receipts_preview.dart';

class StockScreen extends StatefulWidget {
  final String branchName;
  final bool isAdmin;
  final String employeeName;

  const StockScreen({
    super.key,
    required this.branchName,
    required this.isAdmin,
    required this.employeeName,
  });

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with WidgetsBindingObserver {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  final Set<String> selectedProducts = {};
  List<QueryDocumentSnapshot> allProducts = [];
  final GlobalKey<PaginatedDataTableState> tableKey =
  GlobalKey<PaginatedDataTableState>();

  final Map<String, String> branchLabels = {
    // Shops
    "branch1": "5th London",
    "branch2": "3rd floor London",
    "branch3": "First floor London",

    // additional shops
    "hotelAccra": "Hotel Accra",
    "silvermine": "Silvermine",
    "ssdSchool": "Ssd School",
    "rooftopLondon": "Rooftop London",
    "seventhLondon": "Seventh London",
  };

  String get displayBranch =>
      branchLabels[widget.branchName] ?? widget.branchName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
        tableKey.currentState?.pageTo(0);
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
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  void _showLowStockSnackbar(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("⚠️ '$productName' is low on stock!"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addProduct() {
    final nameCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final buyingCtrl = TextEditingController();
    final sellingCtrl = TextEditingController();
    final minCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Product"),
        content: SingleChildScrollView(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Product Name")),
              TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: "Model Number")),
              TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: buyingCtrl,
                  decoration: const InputDecoration(labelText: "Buying Price"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: sellingCtrl,
                  decoration: const InputDecoration(labelText: "Selling Price"),
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
              await FirebaseFirestore.instance
                  .collection("branches")
                  .doc(widget.branchName)
                  .collection("stock")
                  .add({
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

  void _editProduct(String productId, Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product["name"]);
    final modelCtrl = TextEditingController(text: product["modelNumber"]);
    final qtyCtrl = TextEditingController(text: product["quantity"].toString());
    final buyingCtrl =
    TextEditingController(text: product["buyingPrice"].toString());
    final sellingCtrl =
    TextEditingController(text: product["sellingPrice"].toString());
    final minCtrl = TextEditingController(text: product["minPrice"].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Product"),
        content: SingleChildScrollView(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Product Name")),
              TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: "Model Number")),
              TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: buyingCtrl,
                  decoration: const InputDecoration(labelText: "Buying Price"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: sellingCtrl,
                  decoration: const InputDecoration(labelText: "Selling Price"),
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
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("branches")
                  .doc(widget.branchName)
                  .collection("stock")
                  .doc(productId)
                  .update({
                "name": nameCtrl.text,
                "modelNumber": modelCtrl.text,
                "quantity":
                int.tryParse(qtyCtrl.text) ?? product["quantity"],
                "buyingPrice":
                int.tryParse(buyingCtrl.text) ?? product["buyingPrice"],
                "sellingPrice":
                int.tryParse(sellingCtrl.text) ?? product["sellingPrice"],
                "minPrice":
                int.tryParse(minCtrl.text) ?? product["minPrice"],
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete $productName?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection("branches")
          .doc(widget.branchName)
          .collection("stock")
          .doc(productId)
          .delete();
    }
  }

  void _sellProducts(Map<String, dynamic>? singleProduct, [String? singleId]) {
    final custCtrl = TextEditingController();

    if (singleProduct != null && singleId != null) {
      // SINGLE SELL
      final qtyCtrl = TextEditingController();
      final agreedPriceCtrl = TextEditingController();
      double total = 0;
      double discount = 0;

      bool isValid() {
        final qty = int.tryParse(qtyCtrl.text) ?? 0;
        final agreedPrice = double.tryParse(agreedPriceCtrl.text) ?? 0;
        final minPrice = (singleProduct["minPrice"] ?? 0).toDouble();
        return custCtrl.text.trim().isNotEmpty &&
            qty > 0 &&
            qty <= (singleProduct["quantity"] ?? 0) &&
            agreedPrice >= minPrice;
      }

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: Text("Sell ${singleProduct["name"]}"),
            content: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selling Price: Ksh ${singleProduct["sellingPrice"] ?? 0}",
                      style: const TextStyle(color: Colors.green)),
                  Text("Min Price: Ksh ${singleProduct["minPrice"] ?? 0}",
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: custCtrl,
                    decoration:
                    const InputDecoration(labelText: "Customer Name"),
                    onChanged: (_) => setStateDialog(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          decoration:
                          const InputDecoration(labelText: "Quantity"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            final qty = int.tryParse(qtyCtrl.text) ?? 0;
                            final price =
                                double.tryParse(agreedPriceCtrl.text) ?? 0;
                            final sellPrice =
                            (singleProduct["sellingPrice"] ?? 0).toDouble();
                            setStateDialog(() {
                              discount = (sellPrice - price) * qty;
                              total = price * qty;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: agreedPriceCtrl,
                          decoration:
                          const InputDecoration(labelText: "Agreed Price"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            final qty = int.tryParse(qtyCtrl.text) ?? 0;
                            final price =
                                double.tryParse(agreedPriceCtrl.text) ?? 0;
                            final sellPrice =
                            (singleProduct["sellingPrice"] ?? 0).toDouble();
                            setStateDialog(() {
                              discount = (sellPrice - price) * qty;
                              total = price * qty;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Discount: Ksh ${discount.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.orange)),
                  Text("Total: Ksh ${total.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              ElevatedButton.icon(
                icon: const Icon(Icons.sell),
                label: const Text("Confirm"),
                onPressed: isValid()
                    ? () async {
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  final agreedPrice =
                      double.tryParse(agreedPriceCtrl.text) ?? 0;
                  final discountTotal =
                      (singleProduct["sellingPrice"] - agreedPrice) * qty;
                  final totalVal = agreedPrice * qty;

                  final updatedQty =
                      (singleProduct["quantity"] ?? 0) - qty;

                  await FirebaseFirestore.instance
                      .collection("branches")
                      .doc(widget.branchName)
                      .collection("stock")
                      .doc(singleId)
                      .update({"quantity": updatedQty});

                  if (updatedQty <= 1) {
                    _showLowStockSnackbar(singleProduct["name"]);
                  }

                  final item = {
                    "product": singleProduct["name"],
                    "quantity": qty,
                    "unitPrice": agreedPrice,
                    "discount": discountTotal,
                    "total": totalVal.toInt(),
                  };

                  final saleData = {
                    "customer": custCtrl.text,
                    "employee": widget.employeeName,
                    "branch": widget.branchName,
                    "products": [item],
                    "grandTotal": totalVal,
                    "timestamp": Timestamp.now(),
                  };

                  await FirebaseFirestore.instance
                      .collection("branches")
                      .doc(widget.branchName)
                      .collection("sales")
                      .add(saleData);

                  Navigator.pop(ctx);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptsPreviewScreen(
                        branch: displayBranch,
                        employee: widget.employeeName,
                        clientName: custCtrl.text.trim(),
                        date: DateTime.now(),
                        items: [item],
                      ),
                    ),
                  );

                  setState(() => selectedProducts.clear());
                }
                    : null,
              ),
            ],
          ),
        ),
      );
    } else {
      _multiSellDialog(custCtrl);
    }
  }

  void _multiSellDialog(TextEditingController custCtrl) {
    List<QueryDocumentSnapshot> items =
    allProducts.where((p) => selectedProducts.contains(p.id)).toList();
    final Map<String, TextEditingController> qtyCtrls = {};
    final Map<String, TextEditingController> agreedCtrls = {};
    final Map<String, double> discounts = {};
    double grandTotal = 0;

    for (var doc in items) {
      qtyCtrls[doc.id] = TextEditingController();
      agreedCtrls[doc.id] = TextEditingController();
      discounts[doc.id] = 0;
    }

    bool isValid() {
      if (custCtrl.text.trim().isEmpty) return false;
      if (items.isEmpty) return false;
      for (var doc in items) {
        final data = doc.data() as Map<String, dynamic>;
        final q = int.tryParse(qtyCtrls[doc.id]!.text) ?? 0;
        final agreed = double.tryParse(agreedCtrls[doc.id]!.text) ?? 0;
        final minPrice = (data["minPrice"] ?? 0).toDouble();
        if (q > 0) {
          if (q > (data["quantity"] ?? 0)) return false;
          if (agreed < minPrice) return false;
        }
      }
      return true;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Multi-Sell"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: custCtrl,
                  decoration:
                  const InputDecoration(labelText: "Customer Name"),
                  onChanged: (_) => setStateDialog(() {}),
                ),
                const Divider(),
                ...items.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Column(
                    key: ValueKey(doc.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                                  "${data["name"]} (${data["modelNumber"]})",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                          IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () {
                                selectedProducts.remove(doc.id);
                                items.remove(doc);
                                setStateDialog(() {
                                  // Recalculate grand total
                                  grandTotal = 0;
                                  for (var d in items) {
                                    final q =
                                        int.tryParse(qtyCtrls[d.id]!.text) ?? 0;
                                    final a = double.tryParse(
                                        agreedCtrls[d.id]!.text) ??
                                        0;
                                    grandTotal += q * a;
                                  }
                                });
                                setState(() {}); // also update table
                              })
                        ],
                      ),
                      Text("Selling Price: Ksh ${data["sellingPrice"] ?? 0}",
                          style: const TextStyle(color: Colors.green)),
                      Text("Min Price: Ksh ${data["minPrice"] ?? 0}",
                          style: const TextStyle(color: Colors.red)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyCtrls[doc.id],
                              decoration:
                              const InputDecoration(labelText: "Qty"),
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                final q =
                                    int.tryParse(qtyCtrls[doc.id]!.text) ?? 0;
                                final a = double.tryParse(
                                    agreedCtrls[doc.id]!.text) ??
                                    0;
                                final sellPrice =
                                (data["sellingPrice"] ?? 0).toDouble();
                                setStateDialog(() {
                                  discounts[doc.id] = (sellPrice - a) * q;
                                  grandTotal = 0;
                                  for (var d in items) {
                                    final q2 =
                                        int.tryParse(qtyCtrls[d.id]!.text) ?? 0;
                                    final a2 = double.tryParse(
                                        agreedCtrls[d.id]!.text) ??
                                        0;
                                    grandTotal += q2 * a2;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: agreedCtrls[doc.id],
                              decoration: const InputDecoration(
                                  labelText: "Agreed Price"),
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                final q =
                                    int.tryParse(qtyCtrls[doc.id]!.text) ?? 0;
                                final a = double.tryParse(
                                    agreedCtrls[doc.id]!.text) ??
                                    0;
                                final sellPrice =
                                (data["sellingPrice"] ?? 0).toDouble();
                                setStateDialog(() {
                                  discounts[doc.id] = (sellPrice - a) * q;
                                  grandTotal = 0;
                                  for (var d in items) {
                                    final q2 =
                                        int.tryParse(qtyCtrls[d.id]!.text) ?? 0;
                                    final a2 = double.tryParse(
                                        agreedCtrls[d.id]!.text) ??
                                        0;
                                    grandTotal += q2 * a2;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      Text("Discount: Ksh ${discounts[doc.id]!.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.orange)),
                      const Divider(),
                    ],
                  );
                }),
                Text("Grand Total: Ksh ${grandTotal.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton.icon(
              icon: const Icon(Icons.sell),
              label: const Text("Confirm Sell"),
              onPressed: isValid() && items.isNotEmpty
                  ? () async {
                final receiptItems = <Map<String, dynamic>>[];
                for (var doc in items) {
                  final data = doc.data() as Map<String, dynamic>;
                  final q =
                      int.tryParse(qtyCtrls[doc.id]!.text) ?? 0;
                  final agreed =
                      double.tryParse(agreedCtrls[doc.id]!.text) ?? 0;
                  if (q <= 0) continue;

                  final updatedQty = (data["quantity"] ?? 0) - q;

                  await FirebaseFirestore.instance
                      .collection("branches")
                      .doc(widget.branchName)
                      .collection("stock")
                      .doc(doc.id)
                      .update({"quantity": updatedQty});

                  if (updatedQty <= 1) {
                    _showLowStockSnackbar(data["name"]);
                  }

                  final total = agreed * q;
                  final discount =
                      ((data["sellingPrice"] ?? 0) - agreed) * q;

                  receiptItems.add({
                    "product": data["name"],
                    "quantity": q,
                    "unitPrice": agreed,
                    "discount": discount,
                    "total": total.toInt(),
                  });
                }

                final saleData = {
                  "customer": custCtrl.text,
                  "employee": widget.employeeName,
                  "branch": widget.branchName,
                  "products": receiptItems,
                  "grandTotal": grandTotal,
                  "timestamp": Timestamp.now(),
                };

                await FirebaseFirestore.instance
                    .collection("branches")
                    .doc(widget.branchName)
                    .collection("sales")
                    .add(saleData);

                Navigator.pop(ctx);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptsPreviewScreen(
                      branch: displayBranch,
                      employee: widget.employeeName,
                      clientName: custCtrl.text.trim(),
                      date: DateTime.now(),
                      items: receiptItems,
                    ),
                  ),
                );

                setState(() => selectedProducts.clear());
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _moveProducts() async {
    final items =
    allProducts.where((p) => selectedProducts.contains(p.id)).toList();
    if (items.isEmpty) return;

    final Map<String, TextEditingController> qtyCtrls = {};
    for (var doc in items) {
      qtyCtrls[doc.id] = TextEditingController();
    }

    String? selectedBranch;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Move Products"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedBranch,
                  decoration:
                  const InputDecoration(labelText: "Destination Branch"),
                  items: branchLabels.entries
                      .where((e) => e.key != widget.branchName)
                      .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
                      .toList(),
                  onChanged: (val) {
                    setStateDialog(() => selectedBranch = val);
                  },
                ),
                const Divider(),
                ...items.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "${data["name"]} (${data["modelNumber"]}) - Stock: ${data["quantity"]}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextField(
                        controller: qtyCtrls[doc.id],
                        decoration:
                        const InputDecoration(labelText: "Qty to move"),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton.icon(
              icon: const Icon(Icons.compare_arrows),
              label: const Text("Confirm Move"),
              onPressed: selectedBranch == null
                  ? null
                  : () async {
                for (var doc in items) {
                  final data = doc.data() as Map<String, dynamic>;
                  final moveQty =
                      int.tryParse(qtyCtrls[doc.id]!.text) ?? 0;

                  if (moveQty <= 0 ||
                      moveQty > (data["quantity"] ?? 0)) continue;

                  /// 🔻 REMOVE FROM SOURCE
                  await FirebaseFirestore.instance
                      .collection("branches")
                      .doc(widget.branchName)
                      .collection("stock")
                      .doc(doc.id)
                      .update({
                    "quantity": (data["quantity"] ?? 0) - moveQty
                  });

                  /// 🔺 ADD TO DESTINATION
                  final destStock = FirebaseFirestore.instance
                      .collection("branches")
                      .doc(selectedBranch)
                      .collection("stock");

                  final existing = await destStock
                      .where("name", isEqualTo: data["name"])
                      .where("modelNumber",
                      isEqualTo: data["modelNumber"])
                      .limit(1)
                      .get();

                  if (existing.docs.isNotEmpty) {
                    final destDoc = existing.docs.first;
                    final destData = destDoc.data();
                    await destDoc.reference.update({
                      "quantity":
                      (destData["quantity"] ?? 0) + moveQty,
                    });
                  } else {
                    await destStock.add({
                      "name": data["name"],
                      "modelNumber": data["modelNumber"],
                      "quantity": moveQty,
                      "buyingPrice": data["buyingPrice"],
                      "sellingPrice": data["sellingPrice"],
                      "minPrice": data["minPrice"],
                    });
                  }

                  /// 🔥 GLOBAL MOVEMENT RECORD (FIXED)
                  await FirebaseFirestore.instance
                      .collection("movements")
                      .add({
                    "product": data["name"],
                    "modelNumber": data["modelNumber"],
                    "productId": doc.id,
                    "quantityMoved": moveQty,
                    "fromBranch": widget.branchName,
                    "toBranch": selectedBranch,
                    "movedByName": widget.employeeName,
                    "movedByRole":
                    widget.isAdmin ? "admin" : "employee",
                    "createdAt": FieldValue.serverTimestamp(),
                  });
                }

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("✅ Products moved successfully")),
                );

                setState(() => selectedProducts.clear());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stock - $displayBranch"),
        actions: [
          if (widget.isAdmin)
            IconButton(onPressed: _addProduct, icon: const Icon(Icons.add)),
          if (selectedProducts.isNotEmpty)
            IconButton(
                onPressed: _moveProducts, icon: const Icon(Icons.compare_arrows)),
          if (selectedProducts.length == 1)
            IconButton(
              onPressed: () {
                final doc =
                allProducts.firstWhere((p) => selectedProducts.contains(p.id));
                final data = doc.data() as Map<String, dynamic>;
                _sellProducts(data, doc.id);
              },
              icon: const Icon(Icons.sell),
            ),
          if (selectedProducts.length > 1)
            IconButton(
                onPressed: () => _sellProducts(null),
                icon: const Icon(Icons.shopping_cart_checkout)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("branches")
                  .doc(widget.branchName)
                  .collection("stock")
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());

                allProducts = snap.data!.docs;

                final filtered = allProducts.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data["name"] ?? "").toString().toLowerCase();
                  final model =
                  (data["modelNumber"] ?? "").toString().toLowerCase();
                  return name.contains(searchQuery) || model.contains(searchQuery);
                }).toList();

                return SingleChildScrollView(
                  child: PaginatedDataTable(
                    key: tableKey,
                    header: const Text("Stock List"),
                    rowsPerPage: 8,
                    columns: const [
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Model")),
                      DataColumn(label: Text("Qty")),
                      DataColumn(label: Text("Buy Price")),
                      DataColumn(label: Text("Sell Price")),
                      DataColumn(label: Text("Min Price")),
                      DataColumn(label: Text("Actions")),
                    ],
                    source: _StockDataSource(
                        filtered,
                        selectedProducts,
                        _editProduct,
                        _confirmDelete,
                        _sellProducts,
                        widget.isAdmin,
                            () => setState(() {})),
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

class _StockDataSource extends DataTableSource {
  final List<QueryDocumentSnapshot> products;
  final Set<String> selectedProducts;
  final Function(String, Map<String, dynamic>) onEdit;
  final Function(String, String) onDelete;
  final Function(Map<String, dynamic>, String) onSell;
  final bool isAdmin;
  final VoidCallback refresh;

  _StockDataSource(
      this.products,
      this.selectedProducts,
      this.onEdit,
      this.onDelete,
      this.onSell,
      this.isAdmin,
      this.refresh,
      );

  @override
  DataRow? getRow(int index) {
    if (index >= products.length) return null;

    final doc = products[index];
    final data = doc.data() as Map<String, dynamic>;
    final selected = selectedProducts.contains(doc.id);
    final qty = data["quantity"] ?? 0;

    return DataRow.byIndex(
      index: index,
      selected: selected,

      /// 🔴 LOW STOCK HIGHLIGHT
      color: qty <= 1
          ? MaterialStateProperty.all(Colors.red.shade100)
          : null,

      /// ✅ SELECT ROW
      onSelectChanged: (val) {
        if (val == true) {
          selectedProducts.add(doc.id);
        } else {
          selectedProducts.remove(doc.id);
        }
        refresh();
      },

      cells: [
        DataCell(Text(data["name"] ?? "")),
        DataCell(Text(data["modelNumber"] ?? "")),
        DataCell(Text("$qty")),
        DataCell(Text("${data["buyingPrice"] ?? 0}")),
        DataCell(Text("${data["sellingPrice"] ?? 0}")),
        DataCell(Text("${data["minPrice"] ?? 0}")),

        /// 🔥 ACTIONS (CLEANED)
        DataCell(
          Row(
            children: [
              /// 💰 SELL (ALL USERS)
              IconButton(
                icon: const Icon(Icons.sell, color: Colors.green),
                onPressed: () => onSell(data, doc.id),
              ),

              /// ✏️ EDIT (ADMIN ONLY)
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(doc.id, data),
                ),

              /// 🗑 DELETE (ADMIN ONLY)
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      onDelete(doc.id, data["name"] ?? ""),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => products.length;

  @override
  int get selectedRowCount => selectedProducts.length;
}