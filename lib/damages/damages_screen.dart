// lib/screens/damages/damages_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DamagesScreen extends StatefulWidget {
  final String employeeName;
  final bool isAdmin;
  final String branchName;

  const DamagesScreen({
    super.key,
    required this.employeeName,
    required this.isAdmin,
    required this.branchName,
  });

  @override
  State<DamagesScreen> createState() => _DamagesScreenState();
}

class _DamagesScreenState extends State<DamagesScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _employeeCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _initialPaymentCtrl = TextEditingController();

  String _paymentMethod = "Salary Cut";
  bool _loading = false;

  /// ✅ NEW: London display mapping
  String _getDisplayName(String key) {
    const labels = {
      "branch1": "5th London",
      "branch2": "3rd floor London",
      "branch3": "First floor London",
    };
    return labels[key] ?? key;
  }

  CollectionReference<Map<String, dynamic>> get _damageRef =>
      FirebaseFirestore.instance
          .collection("branches")
          .doc(widget.branchName)
          .collection("damages");

  @override
  void dispose() {
    _employeeCtrl.dispose();
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _initialPaymentCtrl.dispose();
    super.dispose();
  }

  String _fmt(Timestamp ts) {
    return DateFormat("dd/MM/yyyy hh:mm a").format(ts.toDate());
  }

  Future<void> _addDamage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final employee = _employeeCtrl.text.trim();
    final desc = _descriptionCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final initial = double.tryParse(_initialPaymentCtrl.text.trim()) ?? 0;

    final balance = (amount - initial).clamp(0.0, double.infinity);

    final payload = {
      "employee": employee,
      "description": desc,
      "amount": amount,
      "initialPayment": initial,
      "balance": balance,
      "paymentMethod": _paymentMethod,
      "createdBy": widget.employeeName,
      "branch": widget.branchName, // ✅ added
      "timestamp": Timestamp.now(),
    };

    try {
      final doc = await _damageRef.add(payload);

      if (balance <= 0) {
        await doc.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Paid fully — record closed.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Damage recorded.")),
        );
      }

      _employeeCtrl.clear();
      _descriptionCtrl.clear();
      _amountCtrl.clear();
      _initialPaymentCtrl.clear();
      _paymentMethod = "Salary Cut";

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addPayment({
    required String docId,
    required double balance,
    required String employee,
  }) async {
    final TextEditingController payCtrl = TextEditingController();
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Payment"),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Employee: $employee"),
              const SizedBox(height: 8),
              Text("Current Balance: Ksh ${balance.toStringAsFixed(2)}"),
              const SizedBox(height: 12),
              TextFormField(
                controller: payCtrl,
                decoration: const InputDecoration(
                  labelText: "Payment",
                  prefixText: "Ksh ",
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final x = double.tryParse(v ?? "");
                  if (x == null || x <= 0) return "Enter valid amount";
                  if (x > balance) return "Cannot exceed balance";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                    payCtrl.text = balance.toStringAsFixed(0),
                    child: const Text("Pay Full"),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                    payCtrl.text = (balance / 2).toStringAsFixed(0),
                    child: const Text("Half"),
                  ),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            child: const Text("Apply"),
            onPressed: () async {
              if (!key.currentState!.validate()) return;

              final amount = double.parse(payCtrl.text);
              Navigator.pop(ctx);

              final newBal =
              (balance - amount).clamp(0.0, double.infinity);

              try {
                if (newBal <= 0) {
                  await _damageRef.doc(docId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Payment done — record cleared."),
                    ),
                  );
                } else {
                  await _damageRef.doc(docId).update({
                    "balance": newBal,
                    "lastPayment": amount,
                    "lastPaymentAt": Timestamp.now(),
                    "lastPaymentBy": widget.employeeName,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Paid Ksh ${amount.toStringAsFixed(0)} — balance Ksh ${newBal.toStringAsFixed(0)}",
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id, String employee) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record"),
        content: Text("Delete damage for $employee?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          )
        ],
      ),
    );

    if (ok == true) {
      await _damageRef.doc(id).delete();
    }
  }

  Widget _buildDamageList(double maxWidth) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _damageRef.orderBy("timestamp", descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No damages recorded"));
        }

        final wide = maxWidth > 900;

        if (wide) {
          return Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Employee")),
                  DataColumn(label: Text("Description")),
                  DataColumn(label: Text("Amount")),
                  DataColumn(label: Text("Balance")),
                  DataColumn(label: Text("Method")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: docs.map((d) {
                  final data = d.data();
                  return DataRow(
                    cells: [
                      DataCell(Text(_fmt(data['timestamp']))),
                      DataCell(Text(data['employee'])),
                      DataCell(SizedBox(
                          width: 200,
                          child: Text(data['description'],
                              overflow: TextOverflow.ellipsis))),
                      DataCell(Text("Ksh ${data['amount']}")),
                      DataCell(Text("Ksh ${data['balance']}")),
                      DataCell(Text(data['paymentMethod'])),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_money,
                                color: Colors.green),
                            onPressed: () => _addPayment(
                              docId: d.id,
                              balance: data['balance'],
                              employee: data['employee'],
                            ),
                          ),
                          IconButton(
                            icon:
                            const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _delete(d.id, data['employee']),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data();
            return Card(
              child: ListTile(
                title: Text("${data['employee']} — Ksh ${data['balance']}"),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description']),
                      Text("Amount: Ksh ${data['amount']}"),
                      Text("Method: ${data['paymentMethod']}"),
                      Text("Date: ${_fmt(data['timestamp'])}"),
                    ]),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_money,
                          color: Colors.green),
                      onPressed: () => _addPayment(
                        docId: d.id,
                        balance: data['balance'],
                        employee: data['employee'],
                      ),
                    ),
                    IconButton(
                      icon:
                      const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _delete(d.id, data['employee']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildForm(double width) {
    final wide = width > 700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Record Damage",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeCtrl,
                decoration: const InputDecoration(
                    labelText: "Employee Name",
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Enter employee" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        prefixText: "Ksh ",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final x = double.tryParse(v ?? "");
                        if (x == null || x <= 0) return "Invalid";
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 8),
                  Expanded(
                    child: TextFormField(
                      controller: _initialPaymentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Initial Payment",
                        prefixText: "Ksh ",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: const [
                  DropdownMenuItem(
                      value: "Salary Cut", child: Text("Salary Cut")),
                  DropdownMenuItem(value: "Cash", child: Text("Cash")),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
                decoration: const InputDecoration(
                    labelText: "Payment Method",
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add),
                  label: const Text("Save"),
                  onPressed: _loading ? null : _addDamage,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = _getDisplayName(widget.branchName);

    if (!widget.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text("Damages — $display")),
        body: const Center(child: Text("Admin only")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Damages — $display")),
      body: LayoutBuilder(
        builder: (ctx, box) {
          final wide = box.maxWidth > 900;

          if (!wide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildForm(box.maxWidth),
                  const SizedBox(height: 16),
                  _buildDamageList(box.maxWidth),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildForm(box.maxWidth * 0.4)),
                const SizedBox(width: 20),
                Expanded(child: _buildDamageList(box.maxWidth * 0.6)),
              ],
            ),
          );
        },
      ),
    );
  }
}