import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DeliveryScreen extends StatefulWidget {
  final String branchName;
  final bool isAdmin;
  final String employeeName;

  const DeliveryScreen({
    super.key,
    required this.branchName,
    required this.isAdmin,
    required this.employeeName,
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> cart = [];
  bool isSearching = false;

  final Map<String, String> branches = {
    "branch1": "5th London",
    "branch2": "3rd floor London",
    "branch3": "First floor London",
    "hotelAccra": "Hotel Accra",
    "silvermine": "Silvermine",
    "ssdSchool": "Ssd School",
    "rooftopLondon": "Rooftop London",
    "seventhLondon": "Seventh London",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  String formatTime(Timestamp? ts) {
    if (ts == null) return "-";
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  /// 🔍 SEARCH PRODUCTS
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isSearching = true);

    List<Map<String, dynamic>> results = [];

    try {
      final futures = branches.keys.map((branch) async {
        final snapshot = await FirebaseFirestore.instance
            .collection("branches")
            .doc(branch)
            .collection("stock")
            .get();

        for (var doc in snapshot.docs) {
          final data = doc.data();

          if ((data["name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              (data["modelNumber"] ?? "")
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase())) {
            results.add({
              ...data,
              "branch": branch,
              "branchName": branches[branch],
              "id": doc.id,
              "availableQty": data["quantity"] ?? 0, // ✅ ADDED
            });
          }
        }
      });

      await Future.wait(futures);

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      setState(() => isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  /// ➕ ADD TO CART
  Future<void> addToCart(Map item) async {
    final qtyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item["name"]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Available: ${item["availableQty"]}"), // ✅ ADDED
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;

              setState(() {
                cart.add({
                  "product": item["name"],
                  "modelNumber": item["modelNumber"],
                  "productId": item["id"],
                  "quantity": qty,
                  "unitPrice": item["sellingPrice"] ?? 0,
                  "total": (item["sellingPrice"] ?? 0) * qty,
                  "branch": item["branch"],
                  "branchName": item["branchName"],
                });
              });

              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  /// 🚚 CREATE DELIVERY
  Future<void> createDelivery() async {
    if (cart.isEmpty) return;

    final customerController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Customer Name"),
        content: TextField(controller: customerController),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final customer = customerController.text.trim();
              if (customer.isEmpty) return;

              try {
                await FirebaseFirestore.instance
                    .collection("deliveries")
                    .add({
                  "products": cart,
                  "customer": customer,
                  "status": "pending",
                  "createdAt": FieldValue.serverTimestamp(),
                  "createdByName": widget.employeeName,
                });

                setState(() => cart.clear());
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Delivery created")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Error: $e")),
                );
              }
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  /// ✅ APPROVE DELIVERY
  Future<void> approveDelivery(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final List products = data["products"] ?? [];

    try {
      for (var item in products) {
        final stockDoc = await FirebaseFirestore.instance
            .collection("branches")
            .doc(item["branch"])
            .collection("stock")
            .doc(item["productId"])
            .get();

        if (!stockDoc.exists) continue;

        final currentQty = stockDoc["quantity"] ?? 0;

        if (currentQty < item["quantity"]) continue;

        await stockDoc.reference.update({
          "quantity": currentQty - item["quantity"],
        });

        await FirebaseFirestore.instance
            .collection("branches")
            .doc(item["branch"])
            .collection("sales")
            .add({
          "products": [item],
          "grandTotal": item["total"],
          "timestamp": FieldValue.serverTimestamp(),
        });
      }

      await doc.reference.update({
        "status": "approved",
        "approvedAt": FieldValue.serverTimestamp(),
        "approvedByName": widget.employeeName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Delivery approved")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  /// 🗑 DELETE DELIVERY
  Future<void> deleteDelivery(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Delivery"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"))
        ],
      ),
    );

    if (confirm == true) {
      await doc.reference.delete();
    }
  }

  Stream<QuerySnapshot> deliveryStream(String status) {
    return FirebaseFirestore.instance
        .collection("deliveries")
        .where("status", isEqualTo: status)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deliveries"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Create"),
            Tab(text: "Pending"),
            Tab(text: "Approved"),
          ],
        ),
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: createDelivery,
        label: Text("Deliver (${cart.length})"),
      )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          /// CREATE
          Column(
            children: [
              TextField(
                decoration:
                const InputDecoration(hintText: "Search product..."),
                onChanged: searchProducts,
              ),
              Expanded(
                child: isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  children: searchResults.map((item) {
                    return ListTile(
                      title: Text(item["name"]),
                      subtitle: Text(item["branchName"]),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => addToCart(item),
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),

          /// PENDING
          StreamBuilder(
            stream: deliveryStream("pending"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final products = data["products"] ?? [];

                  return Card(
                    child: ExpansionTile(
                      title: Text(data["customer"] ?? ""),
                      children: [
                        ...products.map<Widget>((item) {
                          return ListTile(
                            title: Text(item["product"]),
                          );
                        }).toList(),
                        Row(
                          children: [
                            if (widget.isAdmin)
                              ElevatedButton(
                                onPressed: () => approveDelivery(doc),
                                child: const Text("Approve"),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteDelivery(doc),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          /// APPROVED
          StreamBuilder(
            stream: deliveryStream("approved"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(data["customer"] ?? ""),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deleteDelivery(doc),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}