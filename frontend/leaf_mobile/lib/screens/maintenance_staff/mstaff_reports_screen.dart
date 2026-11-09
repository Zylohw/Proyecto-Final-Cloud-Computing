import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

class MstaffReportsScreen extends StatefulWidget {
  const MstaffReportsScreen({super.key});

  @override
  State<MstaffReportsScreen> createState() =>
      _MstaffReportsScreenState();
}

class _MstaffReportsScreenState extends State<MstaffReportsScreen> {
  bool cargando = true;
  String? mensajeError;

  int? reporteProcesando;

  List<Map<String, dynamic>> reportes = [];

  @override
  void initState() {
    super.initState();
    obtenerReportes();
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
        '/api/mantenimiento/reportes',
      );

      final dynamic datos = respuesta is List
          ? respuesta
          : respuesta['reportes'];

      if (!mounted) {
        return;
      }

      setState(() {
        reportes = datos is List
            ? datos
                .map(
                  (reporte) => Map<String, dynamic>.from(
                    reporte,
                  ),
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

  Future<void> emitirReporte(int id) async {
    if (reporteProcesando != null) {
      return;
    }

    setState(() {
      reporteProcesando = id;
    });

    try {
      final respuesta = await ApiService.instance.post(
        '/api/mantenimiento/reportes/$id/emitir',
        {},
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respuesta['mensaje']?.toString() ??
                'Reporte emitido correctamente.',
          ),
          backgroundColor: AppColors.stateGreen,
        ),
      );

      await obtenerReportes();
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
          reporteProcesando = null;
        });
      }
    }
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
            "Reportes",
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
              "Consulte las lecturas registradas y emita sus reportes.",
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

          if (!cargando && mensajeError == null) ...[
            Text(
              "Reportes registrados: ${reportes.length}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.navyBlue,
              ),
            ),

            if (reportes.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 65,
                      color: AppColors.secondaryText,
                    ),

                    SizedBox(height: 15),

                    Text(
                      "Todavía no hay reportes registrados.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

            ...reportes.map(
              (reporte) => reporteComponent(
                reporte,
                reporteProcesando ==
                    convertirId(reporte['id']),
                () {
                  final id = convertirId(reporte['id']);

                  if (id != null) {
                    emitirReporte(id);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Padding reporteComponent(
  Map<String, dynamic> reporte,
  bool procesando,
  VoidCallback emitir,
) {
  final id = reporte['id']?.toString() ?? '';

  final titulo = reporte['titulo']?.toString() ??
      'Reporte $id';

  final sector = reporte['sector']?.toString() ?? '';

  final numero = reporte['numero']?.toString() ?? '';

  final medida =
      reporte['medida_tomada']?.toString() ?? '';

  final contenido =
      reporte['contenido']?.toString() ?? '';

  final fecha = formatearFechaReporte(
    reporte['fecha'],
  );

  final pdf = reporte['pdf']?.toString();

  final bool emitido =
      pdf != null && pdf.trim().isNotEmpty;

  return Padding(
    padding: EdgeInsets.only(top: 20),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: emitido
                      ? AppColors.stateGreen
                      : AppColors.stateYellowOrange,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  emitido ? "Emitido" : "Pendiente",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (sector.isNotEmpty ||
              numero.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 15),
              child: Row(
                children: [
                  Icon(
                    Icons.home_outlined,
                    color: AppColors.meidumBlue,
                  ),

                  SizedBox(width: 10),

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
            ),

          if (medida.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 15),
              child: Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    color: AppColors.meidumBlue,
                  ),

                  SizedBox(width: 10),

                  Text(
                    "Medición: $medida m³",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
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
                  Icons.calendar_today,
                  size: 19,
                  color: AppColors.secondaryText,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    fecha,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (contenido.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                contenido,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryText,
                ),
              ),
            ),

          SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed:
                  emitido || procesando ? null : emitir,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
              ),
              icon: procesando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      emitido
                          ? Icons.check_circle
                          : Icons.picture_as_pdf,
                    ),
              label: Text(
                procesando
                    ? "Generando..."
                    : emitido
                        ? "PDF emitido"
                        : "Emitir PDF",
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

int? convertirId(dynamic id) {
  if (id is int) {
    return id;
  }

  return int.tryParse(
    id?.toString() ?? '',
  );
}

String formatearFechaReporte(dynamic fecha) {
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