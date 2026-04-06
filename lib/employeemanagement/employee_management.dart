import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart'; // Make sure to import your login screen

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? selectedBranch;
  String selectedRole = "employee"; // default role
  bool _obscurePassword = true; // 👁️ Added for password visibility toggle

  /// 🔥 TEMP store admin credentials
  String? adminEmail;
  String? adminPassword;

  /// 🔹 Firestore branch → Human readable labels
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

  /// ✅ Add employee/admin
  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRole == "employee" && selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Select a shop for employees.")),
      );
      return;
    }

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final email = "$username@london.com";

    try {
      final UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCred.user!.uid;

      await FirebaseFirestore.instance.collection("employees").doc(uid).set({
        "username": username,
        "email": email,
        "role": selectedRole,
        "branch": selectedRole == "employee" ? selectedBranch : null,
        "createdAt": FieldValue.serverTimestamp(),
        "createdAtLocal": DateTime.now(),
      });

      /// 🔥 IMPORTANT: LOG BACK ADMIN
      await FirebaseAuth.instance.signOut();

      if (adminEmail != null && adminPassword != null) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail!,
          password: adminPassword!,
        );
      }

      usernameController.clear();
      passwordController.clear();
      setState(() {
        selectedBranch = null;
        selectedRole = "employee";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ User created successfully")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.message}")),
      );
    }
  }

  /// ✅ Edit employee/admin
  Future<void> _editEmployee(
      String uid, String currentRole, String? currentBranch) async {
    String newRole = currentRole;
    String? newBranch = currentBranch;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Employee"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: newRole,
                    decoration: const InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                    ),
                    items: ["employee", "admin"]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) =>
                        setStateDialog(() => newRole = val ?? "employee"),
                  ),
                  const SizedBox(height: 12),
                  if (newRole == "employee")
                    DropdownButtonFormField<String>(
                      value: newBranch,
                      decoration: const InputDecoration(
                        labelText: "Assign Shop",
                        border: OutlineInputBorder(),
                      ),
                      items: branchLabels.entries
                          .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => newBranch = val),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Save"),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection("employees")
                      .doc(uid)
                      .update({
                    "role": newRole,
                    "branch": newRole == "employee" ? newBranch : null,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Employee updated")),
                  );
                },
              ),
            ],
          );
        });
      },
    );
  }

  ///  Delete employee/admin with confirmation
  Future<void> _deleteEmployee(
      String uid, String username, String role) async {
    if (role == "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ You cannot delete another admin account.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete user \"$username\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            label: const Text("Delete"),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection("employees").doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🗑️ $username deleted.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error deleting user: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final isTablet = screenWidth > 600 && screenWidth <= 900;
      final isDesktop = screenWidth > 900;

      final horizontalPadding = isDesktop
          ? 48.0
          : isTablet
          ? 32.0
          : 16.0;
      final titleFont = isDesktop
          ? 20.0
          : isTablet
          ? 18.0
          : 16.0;

      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Employee Management"),
          actions: [
            // ✅ Logout button
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Logout",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Confirm Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 16),
            child: Column(
              children: [
                // ✅ Add employee/admin form
                Form(
                  key: _formKey,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Add New User",
                              style: TextStyle(
                                  fontSize: titleFont,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: "Username",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? "Enter username"
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? "Enter password"
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            decoration: const InputDecoration(
                              labelText: "Role",
                              border: OutlineInputBorder(),
                            ),
                            items: ["employee", "admin"]
                                .map((r) => DropdownMenuItem(
                                value: r, child: Text(r)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedRole = val ?? "employee"),
                          ),
                          const SizedBox(height: 12),
                          if (selectedRole == "employee")
                            DropdownButtonFormField<String>(
                              value: selectedBranch,
                              decoration: const InputDecoration(
                                labelText: "Assign Shop",
                                border: OutlineInputBorder(),
                              ),
                              items: branchLabels.entries
                                  .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedBranch = val),
                              validator: (value) =>
                              selectedRole == "employee" && value == null
                                  ? "Select a shop"
                                  : null,
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.person_add),
                              label: const Text("Add User"),
                              onPressed: _addEmployee,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Users list
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("employees")
                      .orderBy("createdAt", descending: true)
                      .snapshots(includeMetadataChanges: true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No users found"));
                    }

                    final employees = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final emp =
                        employees[index].data() as Map<String, dynamic>;
                        final uid = employees[index].id;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading:
                            const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(emp["username"] ?? "Unknown",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              "Role: ${emp["role"]} "
                                  "${emp["role"] == "employee" ? "| Shop: ${branchLabels[emp["branch"]] ?? emp["branch"]}" : ""}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  tooltip: "Edit",
                                  onPressed: () => _editEmployee(
                                    uid,
                                    emp["role"],
                                    emp["branch"],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: "Delete",
                                  onPressed: () => _deleteEmployee(
                                    uid,
                                    emp["username"] ?? "",
                                    emp["role"] ?? "employee",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
