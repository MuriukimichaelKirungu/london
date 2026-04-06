// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_screen.dart';
import '../reports/reports_screen.dart';
import '../stock/stock_screen.dart';
import '../branch/branch_selection_screen.dart';

import '../warranty/warranty_returns_screen.dart';
import '../deposits/deposits_screen.dart';
import '../damages/damages_screen.dart';
import '../stocklookup/stock_lookup_screen.dart';
import '../delivery/delivery_screen.dart';
import '../movements/movements_screen.dart'; // ✅ NEW IMPORT

class DashboardScreen extends StatefulWidget {
  final String branchName;
  final bool isAdmin;
  final String employeeName;

  const DashboardScreen({
    super.key,
    required this.branchName,
    required this.isAdmin,
    required this.employeeName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? selectedIndex;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _navigateBack(BuildContext context) {
    if (widget.isAdmin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BranchSelectionScreen(
            isAdmin: true,
            employeeName: widget.employeeName,
          ),
        ),
            (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  String _getDisplayBranch(String key) {
    const branchLabels = {
      "branch1": "5th London",
      "branch2": "3rd floor London",
      "branch3": "First floor London",
      "hotelAccra": "Hotel Accra",
      "silvermine": "Silvermine",
      "ssdSchool": "Ssd School",
      "rooftopLondon": "Rooftop London",
      "seventhLondon": "Seventh London",
    };
    return branchLabels[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final displayBranch = _getDisplayBranch(widget.branchName);

    final List<Map<String, dynamic>> menu = [];

    // 🔹 STOCK (ALL USERS)
    menu.add({
      "title": "Stock",
      "icon": Icons.inventory_2,
      "gradient": [Colors.blue.shade400, Colors.blue.shade700],
      "screen": StockScreen(
        branchName: widget.branchName,
        isAdmin: widget.isAdmin,
        employeeName: widget.employeeName,
      ),
    });

    // 🔹 STOCK LOOKUP (ALL USERS)
    menu.add({
      "title": "Stock Lookup",
      "icon": Icons.search,
      "gradient": [Colors.teal.shade400, Colors.teal.shade700],
      "screen": const StockLookupScreen(),
    });

    // 🔥 DELIVERIES (ALL USERS)
    menu.add({
      "title": "Deliveries",
      "icon": Icons.local_shipping,
      "gradient": [Colors.indigo.shade400, Colors.indigo.shade700],
      "screen": DeliveryScreen(
        branchName: widget.branchName,
        isAdmin: widget.isAdmin,
        employeeName: widget.employeeName,
      ),
    });

    // 🔥 NEW: MOVEMENTS (ALL USERS)
    menu.add({
      "title": "Movements",
      "icon": Icons.swap_horiz,
      "gradient": [Colors.brown.shade400, Colors.brown.shade700],
      "screen": const MovementScreen(),
    });

    if (widget.isAdmin) {
      menu.add({
        "title": "Warranty Returns",
        "icon": Icons.assignment_return,
        "gradient": [Colors.orange.shade400, Colors.orange.shade700],
        "screen": WarrantyReturnsScreen(
          branchName: widget.branchName,
          isAdmin: widget.isAdmin,
          employeeName: widget.employeeName,
        ),
      });

      menu.add({
        "title": "Deposits",
        "icon": Icons.payments,
        "gradient": [Colors.green.shade400, Colors.green.shade700],
        "screen": DepositsScreen(
          branchName: widget.branchName,
          isAdmin: widget.isAdmin,
          employeeName: widget.employeeName,
        ),
      });

      menu.add({
        "title": "Damages",
        "icon": Icons.report_problem,
        "gradient": [Colors.red.shade400, Colors.red.shade700],
        "screen": DamagesScreen(
          branchName: widget.branchName,
          isAdmin: widget.isAdmin,
          employeeName: widget.employeeName,
        ),
      });

      menu.add({
        "title": "Reports",
        "icon": Icons.bar_chart,
        "gradient": [Colors.purple.shade400, Colors.purple.shade700],
        "screen": ReportsScreen(branchName: widget.branchName),
      });
    }

    return WillPopScope(
      onWillPop: () async {
        _navigateBack(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dashboard - $displayBranch"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth > 1000;
            final bool isTablet = constraints.maxWidth > 700;
            final int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
            final double horizontalPadding =
            isDesktop ? constraints.maxWidth * 0.15.clamp(0, 400) : 16;

            return SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop)
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.grey.shade50,
                      elevation: 4,
                      minExtendedWidth: 180,
                      destinations: menu
                          .map(
                            (item) => NavigationRailDestination(
                          icon: Icon(item["icon"],
                              color: item["gradient"][1]),
                          label: Text(item["title"]),
                        ),
                      )
                          .toList(),
                      onDestinationSelected: (index) {
                        setState(() => selectedIndex = index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => menu[index]["screen"],
                          ),
                        );
                      },
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.blue,
                                      child: Icon(Icons.person,
                                          size: 36, color: Colors.white),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Welcome, ${widget.employeeName}",
                                            style: TextStyle(
                                              fontSize:
                                              isDesktop ? 22 : 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            widget.isAdmin
                                                ? "Administrator"
                                                : "Employee",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          Text(
                                            "Branch: $displayBranch",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            GridView.builder(
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio:
                                isDesktop ? 1.2 : 1,
                              ),
                              itemCount: menu.length,
                              itemBuilder: (context, index) {
                                final isSelected =
                                    selectedIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() =>
                                    selectedIndex = index);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        menu[index]["screen"],
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: menu[index]["gradient"],
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: menu[index]["gradient"][1]
                                              .withOpacity(
                                              isSelected ? 0.5 : 0.3),
                                          blurRadius:
                                          isSelected ? 14 : 10,
                                          offset: const Offset(2, 6),
                                        ),
                                      ],
                                      border: isSelected
                                          ? Border.all(
                                          color: Colors.white,
                                          width: 3)
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(menu[index]["icon"],
                                            size:
                                            isDesktop ? 64 : 42,
                                            color: Colors.white),
                                        const SizedBox(height: 14),
                                        Text(
                                          menu[index]["title"],
                                          style: TextStyle(
                                            fontSize:
                                            isDesktop ? 22 : 16,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}