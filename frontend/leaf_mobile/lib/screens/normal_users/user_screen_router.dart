import 'package:flutter/material.dart';

import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

import 'package:leaf_mobile/screens/normal_users/users_menu_screen.dart';
import 'package:leaf_mobile/screens/normal_users/users_notifications_screen.dart';
import 'package:leaf_mobile/screens/normal_users/users_profile_screen.dart';
import 'package:leaf_mobile/screens/normal_users/users_reports_screen.dart';
import 'package:leaf_mobile/screens/normal_users/users_tracking_screen.dart';

class UserScreenRouter extends StatefulWidget {
  const UserScreenRouter({super.key});

  @override
  State<UserScreenRouter> createState() =>
      _UserScreenRouterState();
}

class _UserScreenRouterState
    extends State<UserScreenRouter> {
  int indexNavBottom = 0;

  @override
  Widget build(BuildContext context) {
    final String nombreUsuario =
        ApiService.instance.usuario?['nombre'] ?? 'Usuario';

    return Scaffold(
      body: IndexedStack(
        index: indexNavBottom,
        children: [
          UsersMenuScreen(
            userName: nombreUsuario,
          ),
          UsersReportsScreen(),
          UsersTrackingScreen(),
          UsersNotificationsScreen(),
          UsersProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            indexNavBottom = index;
          });
        },
        selectedIndex: indexNavBottom,
        indicatorColor: AppColors.lightBlue,
        backgroundColor: AppColors.alternativeBackground,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Menú",
          ),
          NavigationDestination(
            icon: Icon(Icons.file_open),
            label: "Reportes",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: "Tracing",
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: "Avisos",
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}