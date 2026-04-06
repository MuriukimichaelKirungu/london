// lib/deposits/deposits_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DepositsScreen extends StatefulWidget {
  final String branchName;
  final bool isAdmin;
  final String employeeName;

  const DepositsScreen({
    super.key,
    required this.branchName,
    required this.isAdmin,
    required this.employeeName,
  });

  @override
  State<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends State<DepositsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _initialPayment = TextEditingController();
  final TextEditingController _paymentMethod = TextEditingController();

  @override
  void dispose() {
    _customerName.dispose();
    _phone.dispose();
    _description.dispose();
    _amount.dispose();
    _initialPayment.dispose();
    _paymentMethod.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _depositRef =>
      _firestore
          .collection("branches")
          .doc(widget.branchName)
          .collection("deposits");

  num _parseNum(String? v) {
    if (v == null || v.trim().isEmpty) return 0;
    return num.tryParse(v) ?? 0;
  }

  // ============================================================
  // CREATE DEPOSIT
  // ============================================================
  Future<void> _createDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseNum(_amount.text).toDouble();
    final initial = _parseNum(_initialPayment.text).toDouble();
    final balance = (amount - initial).clamp(0, double.infinity);

    final docRef = await _depositRef.add({
      "customerName": _customerName.text.trim(),
      "phone": _phone.text.trim(),
      "description": _description.text.trim(),
      "amount": amount,
      "initialPayment": initial,
      "balance": balance,
      "paymentMethod": _paymentMethod.text.trim(),
      "createdBy": widget.employeeName,
      "timestamp": FieldValue.serverTimestamp(),
    });

    if (initial > 0) {
      await docRef.collection("payments").add({
        "amount": initial,
        "timestamp": FieldValue.serverTimestamp(),
        "handledBy": widget.employeeName,
      });
    }

    _customerName.clear();
    _phone.clear();
    _description.clear();
    _amount.clear();
    _initialPayment.clear();
    _paymentMethod.clear();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deposit created")),
    );
  }

  // ============================================================
  // ADD PAYMENT
  // ============================================================
  Future<void> _addPayment(String id, Map<String, dynamic> data) async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Payment"),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Amount"),
            validator: (v) {
              final amt = _parseNum(v);
              if (amt <= 0) return "Enter amount";
              if (amt > (data["balance"] ?? 0)) return "Exceeds balance";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;

              final amt = _parseNum(controller.text).toDouble();
              final docRef = _depositRef.doc(id);

              await docRef.collection("payments").add({
                "amount": amt,
                "timestamp": FieldValue.serverTimestamp(),
                "handledBy": widget.employeeName,
              });

              final newInitial = (data["initialPayment"] ?? 0) + amt;
              final newBalance =
              (data["amount"] - newInitial).clamp(0, double.infinity);

              await docRef.update({
                "initialPayment": newInitial,
                "balance": newBalance,
                "timestamp": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment added")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE RECORD
  // ============================================================
  Future<void> _deleteRecord(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Deposit"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              child: const Text("Delete"),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm != true) return;

    final doc = _depositRef.doc(id);
    final paySnap = await doc.collection("payments").get();

    for (final p in paySnap.docs) {
      await p.reference.delete();
    }

    await doc.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Record deleted")),
    );
  }

  // ============================================================
  // VIEW PAYMENTS
  // ============================================================
  Future<void> _viewPayments(String id) async {
    final query = _depositRef
        .doc(id)
        .collection("payments")
        .orderBy("timestamp", descending: true);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Payments"),
        content: SizedBox(
          width: 400,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()));
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Text("No payments");

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: docs.map((p) {
                  final data = p.data();
                  final ts = (data["timestamp"] as Timestamp?)?.toDate();
                  return ListTile(
                    title: Text("Ksh ${data["amount"]}"),
                    subtitle: ts != null ? Text(ts.toString()) : null,
                    trailing: Text(data["handledBy"] ?? ""),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text("Deposits – ${widget.branchName.toUpperCase()}"),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (_) => _buildFormSheet(),
        ),
        label: const Text("New"),
        icon: const Icon(Icons.add),
      )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
        _depositRef.orderBy("timestamp", descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No deposits yet"));
          }

          if (isDesktop) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Customer")),
                  DataColumn(label: Text("Phone")),
                  DataColumn(label: Text("Description")),
                  DataColumn(label: Text("Amount")),
                  DataColumn(label: Text("Initial Deposit")),
                  DataColumn(label: Text("Total Paid")),
                  DataColumn(label: Text("Balance")),
                  DataColumn(label: Text("Payment Method")), // <-- before Actions
                  DataColumn(label: Text("Actions")),
                ],
                rows: docs.map((d) {
                  final data = d.data();
                  return DataRow(cells: [
                    DataCell(Text(data["customerName"] ?? "-")),
                    DataCell(Text(data["phone"] ?? "-")),
                    DataCell(Text(data["description"] ?? "-")),
                    DataCell(Text("Ksh ${data["amount"]}")),
                    DataCell(
                      StreamBuilder<QuerySnapshot>(
                        stream: d.reference
                            .collection("payments")
                            .orderBy("timestamp")
                            .limit(1)
                            .snapshots(),
                        builder: (_, s) {
                          final v = s.hasData && s.data!.docs.isNotEmpty
                              ? s.data!.docs.first["amount"]
                              : 0;
                          return Text("Ksh $v");
                        },
                      ),
                    ),
                    DataCell(
                      StreamBuilder<QuerySnapshot>(
                        stream:
                        d.reference.collection("payments").snapshots(),
                        builder: (_, s) {
                          final total = s.hasData
                              ? s.data!.docs.fold<num>(
                              0, (p, e) => p + (e["amount"] ?? 0))
                              : 0;
                          return Text("Ksh $total");
                        },
                      ),
                    ),
                    DataCell(
                      StreamBuilder<QuerySnapshot>(
                        stream:
                        d.reference.collection("payments").snapshots(),
                        builder: (_, s) {
                          final paid = s.hasData
                              ? s.data!.docs.fold<num>(
                              0, (p, e) => p + (e["amount"] ?? 0))
                              : 0;
                          final bal =
                          (data["amount"] - paid).clamp(0, double.infinity);
                          return Text("Ksh $bal");
                        },
                      ),
                    ),
                    DataCell(Text(data["paymentMethod"] ?? "-")), // <-- before Actions
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: () => _viewPayments(d.id),
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.payment),
                            onPressed: () => _addPayment(d.id, data),
                          ),
                        if (widget.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () => _deleteRecord(d.id),
                          ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            );
          }

          // =============================
          // MOBILE VIEW
          // =============================
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(data["customerName"] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Phone: ${data["phone"] ?? "-"}"),
                      Text(data["description"] ?? ""),
                      Text("Amount: Ksh ${data["amount"]}"),
                      Text("Payment Method: ${data["paymentMethod"] ?? "-"}"), // mobile
                      StreamBuilder<QuerySnapshot>(
                        stream:
                        d.reference.collection("payments").snapshots(),
                        builder: (_, s) {
                          final paid = s.hasData
                              ? s.data!.docs.fold<num>(
                              0, (p, e) => p + (e["amount"] ?? 0))
                              : 0;
                          final bal =
                          (data["amount"] - paid).clamp(0, double.infinity);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Paid: Ksh $paid"),
                              Text("Balance: Ksh $bal"),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == "payments") _viewPayments(d.id);
                      if (v == "pay") _addPayment(d.id, data);
                      if (v == "delete") _deleteRecord(d.id);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: "payments",
                        child: Text("View Payments"),
                      ),
                      if (widget.isAdmin)
                        const PopupMenuItem(
                          value: "pay",
                          child: Text("Add Payment"),
                        ),
                      if (widget.isAdmin)
                        const PopupMenuItem(
                          value: "delete",
                          child: Text("Delete"),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFormSheet() {
    return Padding(
      padding:
      MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("New Deposit",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerName,
                decoration:
                const InputDecoration(labelText: "Customer Name"),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                decoration:
                const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: "Amount (Ksh)"),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _initialPayment,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: "Initial Payment"),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _paymentMethod,
                decoration:
                const InputDecoration(labelText: "Payment Method"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createDeposit,
                child: const Text("Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
