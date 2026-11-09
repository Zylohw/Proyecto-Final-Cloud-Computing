import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

class MstaffHomeScreen extends StatefulWidget {
  const MstaffHomeScreen({super.key});

  @override
  State<MstaffHomeScreen> createState() => _MstaffHomeScreenState();
}

class _MstaffHomeScreenState extends State<MstaffHomeScreen> {
  bool cargando = true;
  String? mensajeError;

  List<Map<String, dynamic>> casas = [];
  List<Map<String, dynamic>> reportes = [];

  @override
  void initState() {
    super.initState();
    obtenerDatos();
  }

  Future<void> obtenerDatos() async {
    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final respuestaCasas = await ApiService.instance.get(
        '/api/mantenimiento/casas',
      );

      final respuestaReportes = await ApiService.instance.get(
        '/api/mantenimiento/reportes',
      );

      final dynamic datosCasas = respuestaCasas is List
          ? respuestaCasas
          : respuestaCasas['casas'];

      final dynamic datosReportes = respuestaReportes is List
          ? respuestaReportes
          : respuestaReportes['reportes'];

      if (!mounted) {
        return;
      }

      setState(() {
        casas = datosCasas is List
            ? datosCasas
                .map(
                  (casa) => Map<String, dynamic>.from(casa),
                )
                .toList()
            : [];

        reportes = datosReportes is List
            ? datosReportes
                .map(
                  (reporte) => Map<String, dynamic>.from(reporte),
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

  @override
  Widget build(BuildContext context) {
    final nombre =
        ApiService.instance.usuario?['nombre'] ?? 'Mantenimiento';

    final reportesEmitidos = reportes.where((reporte) {
      final pdf = reporte['pdf']?.toString();
      return pdf != null && pdf.trim().isNotEmpty;
    }).length;

    final reportesPendientes = reportes.where((reporte) {
      final pdf = reporte['pdf']?.toString();
      return pdf == null || pdf.trim().isEmpty;
    }).length;

    return RefreshIndicator(
      onRefresh: obtenerDatos,
      color: AppColors.darkGreen,
      child: ListView(
        padding: EdgeInsets.only(
          top: 25,
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

          SizedBox(height: 10),

          Text(
            "Resumen de mantenimiento",
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
                  onPressed: obtenerDatos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Reintentar"),
                ),
              ],
            ),

          if (!cargando && mensajeError == null) ...[
            casasDisponibles(casas),
            resumenReportes(
              reportesEmitidos,
              reportesPendientes,
              reportes.length,
            ),
          ],
        ],
      ),
    );
  }
}

Padding casasDisponibles(
  List<Map<String, dynamic>> casas,
) {
  return Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.alternativeBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Casas disponibles para análisis",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          SizedBox(height: 15),

          Text(
            "Total: ${casas.length}",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          SizedBox(height: 15),

          if (casas.isEmpty)
            Text(
              "No hay viviendas disponibles.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
              ),
            ),

          ...casas.take(5).map(
            (casa) => Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.home_outlined,
                    color: AppColors.meidumBlue,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "${casa['sector']} - Casa ${casa['numero']}",
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (casas.length > 5)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                "Y ${casas.length - 5} viviendas más...",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Padding resumenReportes(
  int emitidos,
  int pendientes,
  int total,
) {
  return Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.alternativeBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reportes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              datoReporte(
                "Total",
                total,
                AppColors.meidumBlue,
              ),
              datoReporte(
                "Emitidos",
                emitidos,
                AppColors.stateGreen,
              ),
              datoReporte(
                "Pendientes",
                pendientes,
                AppColors.stateYellowOrange,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget datoReporte(
  String titulo,
  int cantidad,
  Color color,
) {
  return Column(
    children: [
      Text(
        cantidad.toString(),
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),

      SizedBox(height: 5),

      Text(
        titulo,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.primaryText,
        ),
      ),
    ],
  );
}