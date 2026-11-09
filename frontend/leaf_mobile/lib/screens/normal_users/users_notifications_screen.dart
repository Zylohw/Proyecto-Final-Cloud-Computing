import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

class UsersNotificationsScreen extends StatefulWidget {
  const UsersNotificationsScreen({super.key});

  @override
  State<UsersNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState
    extends State<UsersNotificationsScreen> {
  bool cargando = true;
  String? mensajeError;

  List<Map<String, dynamic>> notificaciones = [];

  @override
  void initState() {
    super.initState();
    obtenerNotificaciones();
  }

  Future<void> obtenerNotificaciones() async {
    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final respuesta = await ApiService.instance.get(
        '/api/usuarios/notificaciones',
      );

      final dynamic datos = respuesta is List
          ? respuesta
          : respuesta['notificaciones'];

      if (!mounted) {
        return;
      }

      setState(() {
        notificaciones = datos is List
            ? datos
                .map(
                  (notificacion) =>
                      Map<String, dynamic>.from(notificacion),
                )
                .toList()
            : [];

        notificaciones.sort((a, b) {
          final fechaA = DateTime.tryParse(
            a['fecha']?.toString() ?? '',
          );

          final fechaB = DateTime.tryParse(
            b['fecha']?.toString() ?? '',
          );

          if (fechaA == null && fechaB == null) {
            return 0;
          }

          if (fechaA == null) {
            return 1;
          }

          if (fechaB == null) {
            return -1;
          }

          return fechaB.compareTo(fechaA);
        });
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: obtenerNotificaciones,
      color: AppColors.darkGreen,
      child: ListView(
        padding: EdgeInsets.only(
          top: 30,
          left: 15,
          right: 15,
          bottom: 30,
        ),
        children: [
          Text(
            "Avisos",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Consulte las notificaciones relacionadas con sus reportes.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
            ),
          ),

          SizedBox(height: 25),

          if (cargando)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.darkGreen,
              ),
            ),

          if (!cargando && mensajeError != null)
            Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 55,
                  color: AppColors.stateRed,
                ),

                SizedBox(height: 15),

                Text(
                  mensajeError!,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: obtenerNotificaciones,
                  child: Text("Reintentar"),
                ),
              ],
            ),

          if (!cargando &&
              mensajeError == null &&
              notificaciones.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 50),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 65,
                    color: AppColors.secondaryText,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "No hay avisos disponibles.",
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

          if (!cargando && mensajeError == null)
            ...notificaciones.map(
              (notificacion) =>
                  notifationComponent(notificacion),
            ),
        ],
      ),
    );
  }
}

Padding notifationComponent(
  Map<String, dynamic> notificacion,
) {
  final descripcion =
      notificacion['descripcion']?.toString() ?? '';

  final titulo =
      notificacion['titulo']?.toString() ??
      'Notificación';

  final sector =
      notificacion['sector']?.toString() ?? '';

  final numero =
      notificacion['numero']?.toString() ?? '';

  final fecha = formatearFechaNotificacion(
    notificacion['fecha'],
  );

  return Padding(
    padding: EdgeInsets.only(
      top: 20,
    ),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.lightGreen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),

              Icon(
                Icons.notifications_active,
                color: AppColors.darkGreen,
                size: 30,
              ),
            ],
          ),

          if (sector.isNotEmpty &&
              numero.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.home_outlined,
                    color: AppColors.navyBlue,
                  ),

                  SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      "$sector - Casa $numero",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 15),

          Text(
            descripcion,
            style: TextStyle(
              fontSize: 17,
              color: AppColors.primaryText,
            ),
          ),

          SizedBox(height: 15),

          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 17,
                color: AppColors.secondaryText,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  fecha,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String formatearFechaNotificacion(dynamic fecha) {
  if (fecha == null) {
    return "Fecha no disponible";
  }

  final fechaConvertida = DateTime.tryParse(
    fecha.toString(),
  );

  if (fechaConvertida == null) {
    return "Fecha no disponible";
  }

  final fechaLocal = fechaConvertida.toLocal();

  final dia =
      fechaLocal.day.toString().padLeft(2, '0');

  final mes =
      fechaLocal.month.toString().padLeft(2, '0');

  final anio = fechaLocal.year;

  final hora =
      fechaLocal.hour.toString().padLeft(2, '0');

  final minutos =
      fechaLocal.minute.toString().padLeft(2, '0');

  return "$dia/$mes/$anio - $hora:$minutos";
}