import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/screens/login_screen.dart';
import 'package:leaf_mobile/services/api_services.dart';

class MstaffProfileScreen extends StatelessWidget {
  const MstaffProfileScreen({super.key});

  Future<void> cerrarSesion(BuildContext context) async {
    await ApiService.instance.cerrarSesion();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ApiService.instance.usuario ?? {};

    final nombre =
        usuario['nombre']?.toString() ?? 'Mantenimiento';

    final correo =
        usuario['correo']?.toString() ?? 'Correo no disponible';

    final rol =
        usuario['rol']?.toString() ?? 'Mantenimiento';

    return ListView(
      padding: EdgeInsets.only(
        top: 40,
        left: 20,
        right: 20,
        bottom: 30,
      ),
      children: [
        Center(
          child: CircleAvatar(
            radius: 55,
            backgroundColor: AppColors.lightBlue,
            child: Icon(
              Icons.engineering,
              size: 60,
              color: AppColors.darkGreen,
            ),
          ),
        ),

        SizedBox(height: 25),

        Center(
          child: Text(
            nombre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),

        SizedBox(height: 10),

        Center(
          child: Text(
            correo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
            ),
          ),
        ),

        SizedBox(height: 30),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.alternativeBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              perfilItem(
                Icons.person,
                "Nombre",
                nombre,
              ),

              Divider(),

              perfilItem(
                Icons.mail_outline,
                "Correo",
                correo,
              ),

              Divider(),

              perfilItem(
                Icons.badge_outlined,
                "Rol",
                rol,
              ),
            ],
          ),
        ),

        SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => cerrarSesion(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stateRed,
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.logout),
            label: Text(
              "Cerrar sesión",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget perfilItem(
  IconData icono,
  String titulo,
  String valor,
) {
  return Padding(
    padding: EdgeInsets.symmetric(
      vertical: 12,
    ),
    child: Row(
      children: [
        Icon(
          icono,
          color: AppColors.meidumBlue,
          size: 28,
        ),

        SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),

              SizedBox(height: 5),

              Text(
                valor,
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}