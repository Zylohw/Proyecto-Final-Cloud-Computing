import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/screens/login_screen.dart';
import 'package:leaf_mobile/services/api_services.dart';

class UsersProfileScreen extends StatefulWidget {
  const UsersProfileScreen({super.key});

  @override
  State<UsersProfileScreen> createState() =>
      _UsersProfileScreenState();
}

class _UsersProfileScreenState extends State<UsersProfileScreen> {
  bool cargando = true;
  String? mensajeError;

  List<Map<String, dynamic>> casas = [];

  @override
  void initState() {
    super.initState();
    obtenerCasas();
  }

  Future<void> obtenerCasas() async {
    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final respuesta = await ApiService.instance.get(
        '/api/usuarios/mis-casas',
      );

      final dynamic datos = respuesta is List
          ? respuesta
          : respuesta['casas'];

      if (!mounted) {
        return;
      }

      setState(() {
        casas = datos is List
            ? datos
                .map(
                  (casa) => Map<String, dynamic>.from(casa),
                )
                .toList()
            : [];
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        mensajeError = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> cerrarSesion() async {
    await ApiService.instance.cerrarSesion();

    if (!mounted) {
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
        usuario['nombre']?.toString() ?? 'Usuario';

    final correo =
        usuario['correo']?.toString() ?? 'Correo no disponible';

    final rol =
        usuario['rol']?.toString() ?? 'Comun';

    return RefreshIndicator(
      onRefresh: obtenerCasas,
      color: AppColors.darkGreen,
      child: ListView(
        padding: EdgeInsets.only(
          top: 35,
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
                Icons.person,
                size: 65,
                color: AppColors.darkGreen,
              ),
            ),
          ),

          SizedBox(height: 20),

          Center(
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),

          SizedBox(height: 8),

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
                profileItem(
                  Icons.person_outline,
                  "Nombre",
                  nombre,
                ),

                Divider(),

                profileItem(
                  Icons.mail_outline,
                  "Correo",
                  correo,
                ),

                Divider(),

                profileItem(
                  Icons.badge_outlined,
                  "Rol",
                  rol,
                ),
              ],
            ),
          ),

          SizedBox(height: 25),

          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.alternativeBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mis viviendas",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                  ),
                ),

                SizedBox(height: 15),

                if (cargando)
                  Center(
                    child: CircularProgressIndicator(
                      color: AppColors.darkGreen,
                    ),
                  ),

                if (!cargando && mensajeError != null)
                  Column(
                    children: [
                      Text(
                        mensajeError!,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: obtenerCasas,
                        child: Text("Reintentar"),
                      ),
                    ],
                  ),

                if (!cargando &&
                    mensajeError == null &&
                    casas.isEmpty)
                  Text(
                    "No tiene viviendas asociadas.",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryText,
                    ),
                  ),

                if (!cargando &&
                    mensajeError == null)
                  ...casas.map(
                    (casa) => viviendaItem(casa),
                  ),
              ],
            ),
          ),

          SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: cerrarSesion,
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
      ),
    );
  }
}

Widget profileItem(
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
          size: 28,
          color: AppColors.meidumBlue,
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

Widget viviendaItem(
  Map<String, dynamic> casa,
) {
  final sector =
      casa['sector']?.toString() ?? '';

  final numero =
      casa['numero']?.toString() ?? '';

  return Padding(
    padding: EdgeInsets.only(top: 12),
    child: Row(
      children: [
        Icon(
          Icons.home_outlined,
          color: AppColors.darkGreen,
        ),

        SizedBox(width: 12),

        Expanded(
          child: Text(
            "$sector - Casa $numero",
            style: TextStyle(
              fontSize: 17,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ],
    ),
  );
}