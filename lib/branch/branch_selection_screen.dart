import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/dashboard_screen.dart';
import '../employeemanagement/employee_management.dart';
import '../auth/login_screen.dart';

class BranchSelectionScreen extends StatelessWidget {
  final bool isAdmin;
  final String employeeName;

  const BranchSelectionScreen({
    super.key,
    required this.isAdmin,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    // 🔑 ALL LOCATIONS NOW = SHOPS
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

    final List<String> branchKeys = branchLabels.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Branch"),
        actions: [
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isTablet = width >= 600 && width < 1024;
          final bool isDesktop = width >= 1024;

          final double padding = isDesktop
              ? 48
              : isTablet
              ? 32
              : 16;
          final double fontSize = isDesktop
              ? 22
              : isTablet
              ? 20
              : 18;
          final double cardPadding = isDesktop
              ? 40
              : isTablet
              ? 28
              : 20;
          final double iconSize = isDesktop
              ? 60
              : isTablet
              ? 50
              : 40;
          final double titleSize = isDesktop
              ? 20
              : isTablet
              ? 18
              : 16;

          final bool useGrid = width >= 700;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin
                      ? "Welcome $employeeName 👑, select a shop or manage system:"
                      : "Welcome $employeeName 👤, select your shop:",
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: useGrid
                      ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop
                          ? 3
                          : isTablet
                          ? 2
                          : 1,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: isDesktop
                          ? 1.4
                          : isTablet
                          ? 1.2
                          : 1,
                    ),
                    itemCount: branchKeys.length + (isAdmin ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isAdmin && index == branchKeys.length) {
                        return _buildEmployeeManagementCard(
                          context,
                          iconSize,
                          titleSize,
                          cardPadding,
                        );
                      }

                      final branchKey = branchKeys[index];
                      return _buildBranchCard(
                        context,
                        branchKey,
                        branchLabels[branchKey]!,
                        iconSize,
                        titleSize,
                        cardPadding,
                      );
                    },
                  )
                      : ListView.builder(
                    itemCount: branchKeys.length + (isAdmin ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isAdmin && index == branchKeys.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildEmployeeManagementCard(
                            context,
                            iconSize,
                            titleSize,
                            cardPadding,
                          ),
                        );
                      }

                      final branchKey = branchKeys[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _buildBranchCard(
                          context,
                          branchKey,
                          branchLabels[branchKey]!,
                          iconSize,
                          titleSize,
                          cardPadding,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchCard(
      BuildContext context,
      String branchKey,
      String displayName,
      double iconSize,
      double titleSize,
      double padding) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              branchName: branchKey,
              isAdmin: isAdmin,
              employeeName: employeeName,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, size: iconSize, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeManagementCard(
      BuildContext context, double iconSize, double titleSize, double padding) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EmployeeManagementScreen(),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.green.shade50,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: iconSize, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                "Employee Management",
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}