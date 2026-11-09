import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class InfoScreenAdmin extends StatefulWidget {
  const InfoScreenAdmin({super.key});

  @override
  State<InfoScreenAdmin> createState() => _InfoScreenAdminState();
}

class _InfoScreenAdminState extends State<InfoScreenAdmin> {
  bool cargando = true;

  String? mensajeError;

  List<Map<String, dynamic>> casas = [];

  @override
  void initState() {
    super.initState();
    obtenerResumen();
  }

  String formatearFecha(DateTime fecha) {
    final anio = fecha.year;
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return "$anio-$mes-$dia";
  }

  Future<void> obtenerResumen() async {
    if (!mounted) {
      return;
    }

    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final ahora = DateTime.now();

      final inicio = DateTime(
        ahora.year,
        ahora.month,
        1,
      );

      final fin = DateTime(
        ahora.year,
        ahora.month + 1,
        0,
      );

      final respuesta = await ApiService.instance.get(
        '/api/admin/lecturas'
        '?fecha_inicio=${formatearFecha(inicio)}'
        '&fecha_fin=${formatearFecha(fin)}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        casas = List<Map<String, dynamic>>.from(
          respuesta['casas'] ?? [],
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

  @override
  Widget build(BuildContext context) {
    final nombre = ApiService.instance.usuario?['nombre'] ?? 'Administrador';

    final pendientes = casas.where(
      (casa) => casa['lectura_realizada'] != true,
    ).toList();

    final completadas = casas.where(
      (casa) =>
          casa['lectura_realizada'] == true &&
          casa['reporte_emitido'] == true,
    ).length;

    final reportesPendientes = casas.where(
      (casa) =>
          casa['lectura_realizada'] == true &&
          casa['reporte_emitido'] != true,
    ).length;

    final porcentaje = casas.isEmpty
        ? 0.0
        : completadas * 100.0 / casas.length;

    return RefreshIndicator(
      onRefresh: obtenerResumen,
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
            "Bienvenido, $nombre",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: 10,
              bottom: 25,
            ),
            child: Text(
              "Resumen de las lecturas del mes actual.",
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

                  SizedBox(height: 15),

                  Text(
                    mensajeError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: obtenerResumen,
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
            consumoInfocardActual(porcentaje),

            penddingHousesComponent(pendientes),

            reportsIssuedComponents(
              completadas,
              casas.length,
              reportesPendientes,
            ),
          ],
        ],
      ),
    );
  }
}

Padding consumoInfocardActual(double data) {
  return Padding(
    padding: EdgeInsets.only(
      bottom: 20,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(35),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 10,
      ),
      child: Column(
        children: [
          Text(
            "Progreso de lecturas",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Viviendas con lectura y reporte emitido",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.secondaryText,
            ),
          ),

          SfRadialGauge(
            enableLoadingAnimation: true,
            animationDuration: 1100,
            axes: [
              RadialAxis(
                axisLineStyle: AxisLineStyle(
                  thickness: 30,
                ),
                showTicks: false,
                axisLabelStyle: GaugeTextStyle(
                  fontSize: 15,
                ),
                maximum: 100,
                minimum: 0,
                pointers: [
                  NeedlePointer(
                    value: data,
                    enableAnimation: true,
                    knobStyle: KnobStyle(
                      color: AppColors.background,
                      knobRadius: 0.06,
                      borderWidth: 0.04,
                      borderColor: Colors.black,
                    ),
                  ),

                  RangePointer(
                    enableAnimation: true,
                    color: lightsIdentifierColor(data),
                    width: 30,
                    value: data,
                  ),
                ],
                annotations: [
                  GaugeAnnotation(
                    widget: Text(
                      "${data.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Padding penddingHousesComponent(
  List<Map<String, dynamic>> pendientes,
) {
  return Padding(
    padding: EdgeInsets.only(top: 10),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Casas pendientes: ${pendientes.length}",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          SizedBox(height: 15),

          if (pendientes.isEmpty)
            Text(
              "No hay lecturas pendientes este mes.",
              style: TextStyle(
                fontSize: 17,
                color: AppColors.secondaryText,
              ),
            ),

          ...pendientes.map((casa) {
            return Padding(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home_outlined,
                    color: AppColors.stateRed,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "${casa['sector']} - Casa ${casa['numero']}",
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}

Padding reportsIssuedComponents(
  int completadas,
  int total,
  int reportesPendientes,
) {
  return Padding(
    padding: EdgeInsets.only(top: 20),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "Lecturas completadas:",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          SizedBox(height: 15),

          Text(
            "$completadas/$total",
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: AppColors.stateGreen,
            ),
          ),

          SizedBox(height: 20),

          Text(
            "Reportes pendientes: $reportesPendientes",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: AppColors.stateYellowOrange,
            ),
          ),
        ],
      ),
    ),
  );
}

Color lightsIdentifierColor(double data) {
  if (data >= 80) {
    return AppColors.stateGreen;
  } else if (data >= 40) {
    return AppColors.stateYellowOrange;
  } else {
    return AppColors.stateRed;
  }
}