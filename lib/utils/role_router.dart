import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../screens/admin/admin_main_layout.dart';
import '../screens/customer/customer_main_layout.dart';
import '../screens/farmer/farmer_main_layout.dart';
import '../screens/auth/role_selection_screen.dart';

Widget homeForRole(String role) {
  switch (role) {
    case 'Farmer':
      return const FarmerMainLayout();
    case 'Admin':
      return const AdminMainLayout();
    default:
      return const CustomerMainLayout();
  }
}

Future<void> logoutAndGoToRoles(BuildContext context) async {
  await AuthService().signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    (route) => false,
  );
}
