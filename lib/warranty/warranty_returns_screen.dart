// lib/warranty/warranty_returns_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WarrantyReturnsScreen extends StatefulWidget {
  final String branchName;
  final String employeeName;
  final bool isAdmin;

  const WarrantyReturnsScreen({
    super.key,
    required this.branchName,
    required this.employeeName,
    required this.isAdmin,
  });

  @override
  State<WarrantyReturnsScreen> createState() =>
      _WarrantyReturnsScreenState();
}

class _WarrantyReturnsScreenState extends State<WarrantyReturnsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  Offset _fabOffset = const Offset(24, 500);

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('branches')
          .doc(widget.branchName)
          .collection('returns');

  /// ✅ NEW: Branch display mapping
  String _getDisplayName(String key) {
    const labels = {
      "branch1": "5th London",
      "branch2": "3rd floor London",
      "branch3": "First floor London",
    };
    return labels[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ---------- DATE FORMATTER ----------
  String _fmt(dynamic ts) {
    try {
      final DateTime dt = ts is Timestamp
          ? ts.toDate()
          : (ts is DateTime ? ts : DateTime.now());
      return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
    } catch (_) {
      return "-";
    }
  }

  // ---------- ADD / EDIT ----------
  Future<void> _openDialog({
    required bool isCustomer,
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final key = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(
      text: existing != null
          ? existing[isCustomer ? 'customerName' : 'supplierName'] ?? ''
          : '',
    );

    final contactCtrl =
    TextEditingController(text: existing?['contact'] ?? '');
    final productCtrl =
    TextEditingController(text: existing?['productName'] ?? '');
    final modelCtrl = TextEditingController(text: existing?['model'] ?? '');
    final reasonCtrl = TextEditingController(text: existing?['reason'] ?? '');

    String status = existing?['status'] ?? 'pending';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          docId == null
              ? "New ${isCustomer ? "Customer" : "Supplier"} Return"
              : "Edit Return",
        ),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText:
                    isCustomer ? "Customer Name" : "Supplier Name",
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: contactCtrl,
                  decoration: InputDecoration(
                    labelText:
                    isCustomer ? "Customer Contact" : "Supplier Contact",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: productCtrl,
                  decoration: const InputDecoration(
                      labelText: "Product Name",
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                      labelText: "Model", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: "Reason", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  onChanged: (v) => status = v ?? "pending",
                  decoration: const InputDecoration(
                      labelText: "Status", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: "pending", child: Text("Pending")),
                    DropdownMenuItem(
                        value: "resolved", child: Text("Resolved")),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            child: Text(docId == null ? "Add" : "Save"),
            onPressed: () async {
              if (!key.currentState!.validate()) return;

              final payload = {
                "type": isCustomer ? "customer" : "supplier",
                isCustomer ? "customerName" : "supplierName":
                nameCtrl.text.trim(),
                "contact": contactCtrl.text.trim(),
                "productName": productCtrl.text.trim(),
                "model": modelCtrl.text.trim(),
                "reason": reasonCtrl.text.trim(),
                "handledBy": widget.employeeName,
                "branch": widget.branchName,
                "status": status,
                "timestamp": Timestamp.now(),
              };

              if (docId == null) {
                await _ref.add(payload);
              } else {
                await _ref.doc(docId).update(payload);
              }

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ---------- DELETE CONFIRMATION ----------
  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
            "Are you sure you want to delete this return? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    ) ??
        false;
  }

  // ---------- BUILD CARD ----------
  Widget _buildCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final type = d["type"];
    final name =
    type == "customer" ? d["customerName"] : d["supplierName"];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name ?? "-",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: d['status'] == 'resolved'
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d['status']?.toUpperCase() ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: d['status'] == 'resolved'
                          ? Colors.green[900]
                          : Colors.orange[900],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            if ((d["contact"] ?? "").toString().isNotEmpty)
              Text("Contact: ${d["contact"]}"),
            Text("Product: ${d["productName"] ?? "-"}"),
            Text("Model: ${d["model"] ?? "-"}"),
            const SizedBox(height: 6),
            Text("Reason: ${d["reason"] ?? "-"}"),
            const SizedBox(height: 6),
            Text("Handled By: ${d["handledBy"]}"),
            Text("When: ${_fmt(d["timestamp"])}"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: widget.isAdmin
                      ? () => _openDialog(
                    isCustomer: type == "customer",
                    docId: doc.id,
                    existing: d,
                  )
                      : null,
                ),
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: d["status"] == "resolved"
                        ? Colors.orange
                        : Colors.green,
                  ),
                  tooltip: d["status"] == "resolved"
                      ? "Mark as Pending"
                      : "Resolve",
                  onPressed: widget.isAdmin
                      ? () {
                    final newStatus = d["status"] == "resolved"
                        ? "pending"
                        : "resolved";
                    _ref.doc(doc.id).update({
                      "status": newStatus,
                      if (newStatus == "resolved")
                        "resolvedAt": Timestamp.now(),
                      if (newStatus == "resolved")
                        "resolvedBy": widget.employeeName,
                    });
                  }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.isAdmin
                      ? () async {
                    final confirmed = await _confirmDelete();
                    if (confirmed) {
                      await _ref.doc(doc.id).delete();
                    }
                  }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- STREAM LIST ----------
  Widget _buildList(String type) {
    return StreamBuilder(
      stream: _ref
          .where("type", isEqualTo: type)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Text(type == "customer"
                ? "No customer returns."
                : "No supplier returns."),
          );
        }

        final bottomInset = MediaQuery.of(context).padding.bottom;
        final fabSpace = widget.isAdmin ? 88.0 : 24.0;

        return SafeArea(
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: 8,
              bottom: bottomInset + fabSpace,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) => _buildCard(docs[i]),
          ),
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final display = _getDisplayName(widget.branchName);

    return Scaffold(
      appBar: AppBar(
        title: Text("Warranty Returns — $display"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Customer Returns", icon: Icon(Icons.person)),
            Tab(text: "Supplier Returns", icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: [
              _buildList("customer"),
              _buildList("supplier"),
            ],
          ),
          if (widget.isAdmin)
            Positioned(
              left: _fabOffset.dx,
              top: _fabOffset.dy,
              child: LongPressDraggable(
                feedback: _fab(),
                childWhenDragging: _fab(),
                onDragEnd: (d) {
                  final padding = 16.0;
                  final fabWidth = 180.0;
                  final fabHeight = 56.0;

                  final snapX = d.offset.dx < screenSize.width / 2
                      ? padding
                      : screenSize.width - fabWidth - padding;

                  final snapY = d.offset.dy < screenSize.height / 2
                      ? padding
                      : screenSize.height - fabHeight - padding;

                  setState(() {
                    _fabOffset = Offset(snapX, snapY);
                  });
                },
                child: _fab(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fab() {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text("New Return"),
      onPressed: () {
        final isCustomer = _tab.index == 0;
        _openDialog(isCustomer: isCustomer);
      },
    );
  }
}