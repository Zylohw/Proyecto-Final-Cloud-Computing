import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

class AdminReadingsScreen extends StatefulWidget {
  const AdminReadingsScreen({super.key});

  @override
  State<AdminReadingsScreen> createState() => _AdminReadingsScreenState();
}

class _AdminReadingsScreenState extends State<AdminReadingsScreen> {
  bool cargando = true;

  String? mensajeError;

  List<Map<String, dynamic>> casas = [];

  Map<String, dynamic> resumen = {};

  late DateTime fechaInicio;
  late DateTime fechaFin;

  @override
  void initState() {
    super.initState();

    final fechaActual = DateTime.now();

    fechaInicio = DateTime(
      fechaActual.year,
      fechaActual.month,
      1,
    );

    fechaFin = DateTime(
      fechaActual.year,
      fechaActual.month + 1,
      0,
    );

    obtenerLecturas();
  }

  String formatearFecha(DateTime fecha) {
    return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  String fechaVisual(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
  }

  Future<void> obtenerLecturas() async {
    if (!mounted) {
      return;
    }

    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final String inicio = formatearFecha(fechaInicio);
      final String fin = formatearFecha(fechaFin);

      final respuesta = await ApiService.instance.get(
        '/api/admin/lecturas?fecha_inicio=$inicio&fecha_fin=$fin',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        casas = List<Map<String, dynamic>>.from(
          respuesta['casas'],
        );

        resumen = Map<String, dynamic>.from(
          respuesta['resumen'],
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

  Future<void> seleccionarPeriodo() async {
    final DateTimeRange? periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: fechaInicio,
        end: fechaFin,
      ),
      helpText: "Seleccione el período de lecturas",
      cancelText: "Cancelar",
      confirmText: "Aceptar",
      saveText: "Aceptar",
    );

    if (periodo == null || !mounted) {
      return;
    }

    setState(() {
      fechaInicio = periodo.start;
      fechaFin = periodo.end;
    });

    await obtenerLecturas();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: obtenerLecturas,
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
            "Supervisión de lecturas",
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
              "Consulte el estado de las lecturas y reportes de las viviendas.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
              ),
            ),
          ),

          selectorPeriodo(
            fechaVisual(fechaInicio),
            fechaVisual(fechaFin),
            seleccionarPeriodo,
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
                    onPressed: obtenerLecturas,
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
            resumenLecturas(resumen),

            Padding(
              padding: EdgeInsets.only(
                top: 30,
                bottom: 10,
              ),
              child: Text(
                "Estado de las viviendas",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue,
                ),
              ),
            ),

            if (casas.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    "No hay viviendas registradas.",
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),

            ...casas.map((casa) {
              return houseItem(
                "${casa['sector']} - ${casa['numero']}",
                casa['lectura_realizada'] == true,
                casa['reporte_emitido'] == true,
              );
            }),
          ],
        ],
      ),
    );
  }
}

Padding selectorPeriodo(
  String fechaInicio,
  String fechaFin,
  VoidCallback seleccionarPeriodo,
) {
  return Padding(
    padding: EdgeInsets.only(
      top: 10,
      bottom: 20,
    ),
    child: Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Período de consulta",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: 15,
              bottom: 15,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: AppColors.meidumBlue,
                  size: 30,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    "$fechaInicio - $fechaFin",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: seleccionarPeriodo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
              ),
              icon: Icon(Icons.date_range),
              label: Text(
                "Seleccionar período",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Column resumenLecturas(
  Map<String, dynamic> resumen,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Resumen general",
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: AppColors.navyBlue,
        ),
      ),

      resumenItem(
        "Total de viviendas",
        resumen['total_casas'] ?? 0,
        Icons.home,
        AppColors.meidumBlue,
      ),

      resumenItem(
        "Completadas",
        resumen['completadas'] ?? 0,
        Icons.check_circle,
        AppColors.stateGreen,
      ),

      resumenItem(
        "Lecturas pendientes",
        resumen['pendientes'] ?? 0,
        Icons.pending_actions,
        AppColors.stateRed,
      ),

      resumenItem(
        "Reportes pendientes",
        resumen['reportes_pendientes'] ?? 0,
        Icons.description,
        AppColors.stateYellowOrange,
      ),
    ],
  );
}

Padding resumenItem(
  String titulo,
  int cantidad,
  IconData icono,
  Color color,
) {
  return Padding(
    padding: EdgeInsets.only(top: 12),
    child: Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: color,
            size: 35,
          ),

          SizedBox(width: 15),

          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.primaryText,
              ),
            ),
          ),

          Text(
            cantidad.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

Padding houseItem(
  String name,
  bool readingChecked,
  bool reportChecked,
) {
  Color stateColor = AppColors.stateRed;
  String stateText = "Pendiente";

  if (readingChecked && reportChecked) {
    stateColor = AppColors.stateGreen;
    stateText = "Completado";
  } else if (readingChecked) {
    stateColor = AppColors.stateYellowOrange;
    stateText = "Reporte pendiente";
  }

  return Padding(
    padding: EdgeInsets.only(
      top: 15,
      left: 7,
      right: 7,
    ),
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                  ),
                ),
              ),

              SizedBox(width: 8),

              Flexible(
                child: Container(
                  padding: EdgeInsets.only(
                    top: 7,
                    bottom: 7,
                    left: 12,
                    right: 12,
                  ),
                  decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    stateText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Icon(
                  readingChecked
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: readingChecked
                      ? AppColors.stateGreen
                      : AppColors.stateRed,
                ),

                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    readingChecked
                        ? "Lectura realizada"
                        : "Lectura pendiente",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 15),
            child: Row(
              children: [
                Icon(
                  reportChecked
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: reportChecked
                      ? AppColors.stateGreen
                      : AppColors.stateRed,
                ),

                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    reportChecked
                        ? "Reporte emitido"
                        : "Reporte pendiente",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
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