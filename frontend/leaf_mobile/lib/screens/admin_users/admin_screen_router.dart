import 'package:flutter/material.dart';
import 'package:leaf_mobile/screens/admin_users/admin_reading_screen.dart';
import 'package:leaf_mobile/screens/admin_users/info_screen_admin.dart';
import 'package:leaf_mobile/screens/admin_users/admin_screen_settings.dart';
import 'package:leaf_mobile/screens/admin_users/admin_notification_screen.dart';
import 'package:leaf_mobile/screens/admin_users/admin_profile_screen.dart';
import 'package:leaf_mobile/core/app_colors.dart';

class AdminScreenRouter extends StatefulWidget {
  const AdminScreenRouter({super.key});
  @override
  State<AdminScreenRouter> createState() => _AdminScreenRouterState();
}

class _AdminScreenRouterState extends State<AdminScreenRouter> {
  int indexNav = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: indexNav,
        children: [
          /**
           * Contiene las siguientes vistas
           * Menu 
           * Supervision de rutas
           * Ajustes: esta vista permite configurar fechas en las que hay que que leer, controlar los usuarios de mantenimiento y general
           * Avisos/Notificaciones
           * Perfil
           * 
           */
          InfoScreenAdmin(),
          AdminReadingsScreen(),
          AdminSettingsScreen(),
          AdminNotificationsScreen(),
          AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indexNav,
        indicatorColor: AppColors.lightBlue,
        backgroundColor: AppColors.background,
        onDestinationSelected: (int index) {
          setState(() {
            indexNav = index;
          });
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.menu), label: "Menu"),
          NavigationDestination(icon: Icon(Icons.book), label: "Lecturas"),
          NavigationDestination(icon: Icon(Icons.build), label: "Ajustes"),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: "Avisos",
          ),
          NavigationDestination(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
