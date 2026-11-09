import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  DateTime? fechaLectura;

  int? reporteSeleccionado;

  bool cargando = true;
  bool guardando = false;

  String? mensajeError;

  List<Map<String, dynamic>> reportes = [];

  final TextEditingController indicacionesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    obtenerReportes();
  }

  @override
  void dispose() {
    indicacionesController.dispose();
    super.dispose();
  }

  Future<void> obtenerReportes() async {
    if (!mounted) {
      return;
    }

    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final respuesta = await ApiService.instance.get(
        '/api/admin/reportes',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        reportes = List<Map<String, dynamic>>.from(
          respuesta['reportes'],
        );

        if (!reportes.any(
          (reporte) => reporte['id'] == reporteSeleccionado,
        )) {
          reporteSeleccionado = null;
        }
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

  Future<void> seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: fechaLectura ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: "Seleccione la fecha de lectura",
      cancelText: "Cancelar",
      confirmText: "Aceptar",
    );

    if (fecha != null && mounted) {
      setState(() {
        fechaLectura = fecha;
      });
    }
  }

  String formatearFecha(DateTime fecha) {
    return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  Future<void> guardarProgramacion() async {
    if (guardando) {
      return;
    }

    if (reporteSeleccionado == null) {
      mostrarMensaje(
        "Seleccione una vivienda y su reporte.",
        AppColors.stateRed,
      );

      return;
    }

    if (fechaLectura == null) {
      mostrarMensaje(
        "Seleccione la fecha de lectura.",
        AppColors.stateRed,
      );

      return;
    }

    final hoy = DateUtils.dateOnly(DateTime.now());

    if (fechaLectura!.isBefore(hoy)) {
      mostrarMensaje(
        "La fecha de lectura no puede ser anterior a hoy.",
        AppColors.stateRed,
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final respuesta = await ApiService.instance.post(
        '/api/admin/programaciones',
        {
          'reporte_id': reporteSeleccionado,
          'fecha_lectura': formatearFecha(fechaLectura!),
          'indicaciones': indicacionesController.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        reporteSeleccionado = null;
        fechaLectura = null;
        indicacionesController.clear();
      });

      mostrarMensaje(
        respuesta['mensaje'] ?? 'Lectura programada correctamente',
        AppColors.stateGreen,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      mostrarMensaje(
        error.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        AppColors.stateRed,
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  void mostrarMensaje(String mensaje, Color color) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: obtenerReportes,
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
            "Programación de lecturas",
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
              "Configure las fechas en las que el personal de mantenimiento deberá realizar las lecturas de los contadores.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
              ),
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
                    size: 55,
                    color: AppColors.stateRed,
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
                    onPressed: obtenerReportes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Reintentar"),
                  ),
                ],
              ),
            ),

          if (!cargando && mensajeError == null)
            formProgramacionLecturas(
              context,
              reportes,
              reporteSeleccionado,
              (value) {
                setState(() {
                  reporteSeleccionado = value;
                });
              },
              fechaLectura,
              seleccionarFecha,
              indicacionesController,
              guardarProgramacion,
              guardando,
            ),
        ],
      ),
    );
  }
}

Padding formProgramacionLecturas(
  BuildContext context,
  List<Map<String, dynamic>> reportes,
  int? reporteSeleccionado,
  ValueChanged<int?> seleccionarReporte,
  DateTime? fecha,
  VoidCallback seleccionarFecha,
  TextEditingController indicacionesController,
  VoidCallback guardarProgramacion,
  bool guardando,
) {
  String fechaTexto = fecha == null
      ? "Seleccione una fecha"
      : "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";

  return Padding(
    padding: EdgeInsets.only(top: 20),
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nueva programación",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: 25,
              bottom: 10,
            ),
            child: Text(
              "Vivienda y reporte:",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primaryText,
              ),
            ),
          ),

          if (reportes.isEmpty)
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.meidumBlue,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "No hay reportes disponibles para programar lecturas.",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (reportes.isNotEmpty)
            Container(
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonFormField<int>(
                value: reporteSeleccionado,
                isExpanded: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.home,
                    color: AppColors.meidumBlue,
                  ),
                ),
                hint: Text("Seleccione una vivienda"),
                items: reportes.map((reporte) {
                  return DropdownMenuItem<int>(
                    value: reporte['id'],
                    child: Text(
                      "${reporte['sector']} - Casa ${reporte['numero']} | Reporte ${reporte['id']}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: guardando
                    ? null
                    : seleccionarReporte,
              ),
            ),

          if (reporteSeleccionado != null)
            reporteSeleccionadoInfo(
              reportes,
              reporteSeleccionado,
            ),

          Padding(
            padding: EdgeInsets.only(
              top: 30,
              bottom: 10,
            ),
            child: Text(
              "Fecha de lectura:",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primaryText,
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: AppColors.meidumBlue,
                size: 30,
              ),
              title: Text(
                fechaTexto,
                style: TextStyle(fontSize: 17),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.meidumBlue,
              ),
              onTap: guardando
                  ? null
                  : seleccionarFecha,
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: 30,
              bottom: 10,
            ),
            child: Text(
              "Indicaciones para mantenimiento:",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primaryText,
              ),
            ),
          ),

          TextFormField(
            controller: indicacionesController,
            maxLines: 4,
            enabled: !guardando,
            cursorColor: AppColors.meidumBlue,
            decoration: InputDecoration(
              hintText: "Ingrese indicaciones adicionales",
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: AppColors.meidumBlue,
                  width: 2,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 30),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: guardando || reportes.isEmpty
                    ? null
                    : guardarProgramacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: Colors.white,
                ),
                icon: guardando
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(
                  guardando
                      ? "Guardando..."
                      : "Guardar programación",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Padding reporteSeleccionadoInfo(
  List<Map<String, dynamic>> reportes,
  int reporteSeleccionado,
) {
  final reporte = reportes.firstWhere(
    (reporte) => reporte['id'] == reporteSeleccionado,
  );

  return Padding(
    padding: EdgeInsets.only(top: 15),
    child: Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reporte seleccionado",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              reporte['titulo'] ?? 'Sin título',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primaryText,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Mantenimiento: ${reporte['mantenimiento'] ?? 'No disponible'}",
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primaryText,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Vivienda: ${reporte['sector']} - ${reporte['numero']}",
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}