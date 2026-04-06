import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key});

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  String selectedFilter = "All";
  String selectedShop = "All";

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

  String formatTime(Timestamp? ts) {
    if (ts == null) return "-";
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  bool isToday(Timestamp? ts) {
    if (ts == null) return false;
    final now = DateTime.now();
    final date = ts.toDate();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  /// 🗑 DELETE FUNCTION
  Future<void> deleteMovement(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Movement"),
        content: const Text("Are you sure you want to delete this movement?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await doc.reference.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Movement deleted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Movements"),
      ),
      body: Column(
        children: [
          /// 🔽 FILTER BAR
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                /// Date Filter
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedFilter,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All Time")),
                      DropdownMenuItem(value: "Today", child: Text("Today")),
                    ],
                    onChanged: (val) {
                      setState(() => selectedFilter = val!);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                /// Shop Filter
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedShop,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: "All", child: Text("All Shops")),
                      ...branchLabels.entries.map(
                            (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                    ],
                    onChanged: (val) {
                      setState(() => selectedShop = val!);
                    },
                  ),
                ),
              ],
            ),
          ),

          /// 🔽 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("movements")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  /// Date filter
                  if (selectedFilter == "Today" &&
                      !isToday(data["createdAt"])) {
                    return false;
                  }

                  /// Shop filter
                  if (selectedShop != "All" &&
                      data["fromBranch"] != selectedShop &&
                      data["toBranch"] != selectedShop) {
                    return false;
                  }

                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No movements found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.swap_horiz,
                            color: Colors.blue),
                        title: Text(
                          data["product"] ?? "Unknown",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "From: ${branchLabels[data["fromBranch"]] ?? data["fromBranch"]}\n"
                              "To: ${branchLabels[data["toBranch"]] ?? data["toBranch"]}\n"
                              "Qty: ${data["quantityMoved"]}\n"
                              "By: ${data["movedByName"]} (${data["movedByRole"]})\n"
                              "Time: ${formatTime(data["createdAt"])}",
                        ),

                        /// 🔥 DELETE BUTTON
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteMovement(doc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}