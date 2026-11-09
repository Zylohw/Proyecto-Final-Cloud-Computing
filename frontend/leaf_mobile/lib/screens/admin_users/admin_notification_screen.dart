import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  bool cargando = true;
  bool mostrarTodas = false;

  String? mensajeError;

  int? notificacionProcesando;

  List<Map<String, dynamic>> notificaciones = [];

  @override
  void initState() {
    super.initState();
    obtenerNotificaciones();
  }

  Future<void> obtenerNotificaciones() async {
    if (!mounted) {
      return;
    }

    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final respuesta = await ApiService.instance.get(
        '/api/admin/notificaciones',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        notificaciones = List<Map<String, dynamic>>.from(
          respuesta['notificaciones'],
        );
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

  Future<void> cambiarEstadoNotificacion(
    int id,
    bool estado,
  ) async {
    setState(() {
      notificacionProcesando = id;
    });

    try {
      final respuesta = await ApiService.instance.patch(
        '/api/admin/notificaciones/$id/estado',
        {
          'estado': estado,
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        final index = notificaciones.indexWhere(
          (notificacion) => notificacion['id'] == id,
        );

        if (index != -1) {
          notificaciones[index]['estado'] = estado;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje']),
          backgroundColor: AppColors.stateGreen,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: AppColors.stateRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          notificacionProcesando = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avisosFiltrados = notificaciones.where(
      (notificacion) {
        return mostrarTodas ||
            notificacion['estado'] == true;
      },
    ).toList();

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

          Padding(
            padding: EdgeInsets.only(
              top: 10,
              bottom: 20,
            ),
            child: Text(
              "Consulte y administre las notificaciones de Leaf.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.only(
              left: 15,
              right: 10,
              top: 5,
              bottom: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.alternativeBackground,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mostrarTodas
                        ? "Todas las notificaciones"
                        : "Notificaciones activas",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),

                Switch(
                  value: mostrarTodas,
                  activeThumbColor: AppColors.darkGreen,
                  onChanged: (value) {
                    setState(() {
                      mostrarTodas = value;
                    });
                  },
                ),
              ],
            ),
          ),

          if (cargando)
            Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkGreen,
                ),
              ),
            ),

          if (!cargando && mensajeError != null)
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.stateRed,
                    size: 55,
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                      bottom: 20,
                    ),
                    child: Text(
                      mensajeError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: obtenerNotificaciones,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Reintentar"),
                  ),
                ],
              ),
            ),

          if (!cargando && mensajeError == null) ...[
            Padding(
              padding: EdgeInsets.only(top: 25),
              child: Text(
                "Notificaciones: ${avisosFiltrados.length}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue,
                ),
              ),
            ),

            if (avisosFiltrados.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.secondaryText,
                      size: 60,
                    ),

                    Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Text(
                        "No hay notificaciones disponibles.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ...avisosFiltrados.map((notificacion) {
              return adminNotificationComponent(
                notificacion,
                () {
                  if (notificacionProcesando != null) {
                    return;
                  }

                  cambiarEstadoNotificacion(
                    notificacion['id'],
                    notificacion['estado'] != true,
                  );
                },
                notificacionProcesando ==
                    notificacion['id'],
              );
            }),
          ],
        ],
      ),
    );
  }
}

Padding adminNotificationComponent(
  Map<String, dynamic> notificacion,
  VoidCallback cambiarEstado,
  bool procesando,
) {
  final bool activa = notificacion['estado'] == true;

  final String descripcion =
      notificacion['descripcion'] ?? '';

  final String sector =
      notificacion['sector'] ?? '';

  final String numero =
      notificacion['numero'] ?? '';

  final String titulo =
      notificacion['titulo'] ?? 'Notificación';

  final String fecha = formatearFechaNotificacion(
    notificacion['fecha'],
  );

  return Padding(
    padding: EdgeInsets.only(
      top: 20,
      left: 7,
      right: 7,
    ),
    child: Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: activa
            ? AppColors.lightGreen
            : AppColors.alternativeBackground,
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
                activa
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: activa
                    ? AppColors.darkGreen
                    : AppColors.secondaryText,
                size: 28,
              ),
            ],
          ),

          if (sector.isNotEmpty && numero.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "$sector - Vivienda $numero",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue,
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.only(top: 15),
            child: Text(
              descripcion,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.primaryText,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 15),
            child: Row(
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
          ),

          Padding(
            padding: EdgeInsets.only(top: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activa ? "Activa" : "Desactivada",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: activa
                        ? AppColors.darkGreen
                        : AppColors.stateRed,
                  ),
                ),

                procesando
                    ? SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.meidumBlue,
                        ),
                      )
                    : IconButton(
                        onPressed: cambiarEstado,
                        tooltip: activa
                            ? "Desactivar aviso"
                            : "Activar aviso",
                        icon: Icon(
                          activa
                              ? Icons.delete_outline
                              : Icons.restore,
                          color: activa
                              ? AppColors.stateRed
                              : AppColors.darkGreen,
                          size: 32,
                        ),
                      ),
              ],
            ),
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

  final DateTime? fechaConvertida = DateTime.tryParse(
    fecha.toString(),
  );

  if (fechaConvertida == null) {
    return "Fecha no disponible";
  }

  final fechaLocal = fechaConvertida.toLocal();

  final String dia =
      fechaLocal.day.toString().padLeft(2, '0');

  final String mes =
      fechaLocal.month.toString().padLeft(2, '0');

  final String anio =
      fechaLocal.year.toString();

  final String hora =
      fechaLocal.hour.toString().padLeft(2, '0');

  final String minutos =
      fechaLocal.minute.toString().padLeft(2, '0');

  return "$dia/$mes/$anio - $hora:$minutos";
}