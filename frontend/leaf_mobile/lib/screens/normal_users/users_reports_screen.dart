import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';
import 'package:month_year_picker/month_year_picker.dart';

class UsersReportsScreen extends StatefulWidget {
  const UsersReportsScreen({super.key});

  @override
  State<UsersReportsScreen> createState() =>
      _UserReportsScreenState();
}

class _UserReportsScreenState
    extends State<UsersReportsScreen> {
  bool cargando = true;
  bool cargandoReportes = false;

  String? mensajeError;

  List<Map<String, dynamic>> casas = [];
  List<Map<String, dynamic>> reportes = [];

  int? casaSeleccionada;
  DateTime? mesSeleccionado;

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

      casas = datos is List
          ? datos
              .map(
                (casa) => Map<String, dynamic>.from(casa),
              )
              .toList()
          : [];

      if (casas.isNotEmpty) {
        casaSeleccionada = int.tryParse(
          casas.first['id'].toString(),
        );

        await obtenerReportes();
      }

      if (!mounted) {
        return;
      }

      setState(() {});
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

  Future<void> obtenerReportes() async {
    if (casaSeleccionada == null) {
      return;
    }

    setState(() {
      cargandoReportes = true;
    });

    try {
      final respuesta = await ApiService.instance.get(
        '/api/usuarios/casas/$casaSeleccionada/reportes',
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
          cargandoReportes = false;
        });
      }
    }
  }

  Future<void> seleccionarMes() async {
    final ahora = DateTime.now();

    final fecha = await showMonthYearPicker(
      context: context,
      initialDate: mesSeleccionado ?? ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null || !mounted) {
      return;
    }

    setState(() {
      mesSeleccionado = fecha;
    });
  }

  void limpiarFiltro() {
    setState(() {
      mesSeleccionado = null;
    });
  }

  List<Map<String, dynamic>> reportesFiltrados() {
    if (mesSeleccionado == null) {
      return reportes;
    }

    return reportes.where((reporte) {
      final fecha = DateTime.tryParse(
        reporte['fecha']?.toString() ?? '',
      );

      if (fecha == null) {
        return false;
      }

      return fecha.month == mesSeleccionado!.month &&
          fecha.year == mesSeleccionado!.year;
    }).toList();
  }

  Future<void> marcarRecibido(
    int reporteId,
  ) async {
    if (casaSeleccionada == null) {
      return;
    }

    try {
      final respuesta = await ApiService.instance.patch(
        '/api/usuarios/casas/$casaSeleccionada/reportes/$reporteId/recibido',
        {
          'recibido': true,
        },
      );

      if (!mounted) {
        return;
      }

      final index = reportes.indexWhere(
        (reporte) =>
            int.tryParse(reporte['id'].toString()) ==
            reporteId,
      );

      if (index != -1) {
        setState(() {
          reportes[index]['recibido'] = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respuesta['mensaje']?.toString() ??
                'Reporte marcado como recibido.',
          ),
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
    }
  }

  void descargarReporte(
    Map<String, dynamic> reporte,
  ) {
    final pdf = reporte['pdf']?.toString();

    if (pdf == null || pdf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "El PDF todavía no ha sido emitido.",
          ),
          backgroundColor: AppColors.stateYellowOrange,
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "La descarga del PDF será conectada al servicio binario.",
        ),
        backgroundColor: AppColors.meidumBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = reportesFiltrados();

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
            "Mis reportes",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Consulte los reportes de lectura de sus viviendas.",
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
                  onPressed: obtenerCasas,
                  child: Text("Reintentar"),
                ),
              ],
            ),

          if (!cargando &&
              mensajeError == null &&
              casas.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(
                child: Text(
                  "No tiene viviendas asociadas.",
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),

          if (!cargando &&
              mensajeError == null &&
              casas.isNotEmpty) ...[
            selectorCasa(),

            SizedBox(height: 20),

            filtroMes(),

            if (cargandoReportes)
              Padding(
                padding: EdgeInsets.only(top: 50),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.darkGreen,
                  ),
                ),
              ),

            if (!cargandoReportes &&
                filtrados.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 60,
                      color: AppColors.secondaryText,
                    ),

                    SizedBox(height: 15),

                    Text(
                      "No hay reportes disponibles.",
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

            if (!cargandoReportes)
              ...filtrados.map(
                (reporte) => myReport(
                  reporte,
                  descargarReporte,
                  marcarRecibido,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget selectorCasa() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<int>(
        value: casaSeleccionada,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.home_outlined,
            color: AppColors.meidumBlue,
          ),
        ),
        items: casas.map((casa) {
          return DropdownMenuItem<int>(
            value: int.tryParse(
              casa['id'].toString(),
            ),
            child: Text(
              "${casa['sector']} - Casa ${casa['numero']}",
            ),
          );
        }).toList(),
        onChanged: (valor) async {
          if (valor == null) {
            return;
          }

          setState(() {
            casaSeleccionada = valor;
            reportes = [];
          });

          await obtenerReportes();
        },
      ),
    );
  }

  Widget filtroMes() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            color: AppColors.navyBlue,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              mesSeleccionado == null
                  ? "Todos los meses"
                  : formatearMesCompleto(
                      mesSeleccionado!,
                    ),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
          ),

          IconButton(
            onPressed: seleccionarMes,
            icon: Icon(
              Icons.filter_alt,
            ),
          ),

          if (mesSeleccionado != null)
            IconButton(
              onPressed: limpiarFiltro,
              icon: Icon(
                Icons.close,
              ),
            ),
        ],
      ),
    );
  }
}

Padding myReport(
  Map<String, dynamic> reporte,
  void Function(Map<String, dynamic>) descargar,
  void Function(int) marcarRecibido,
) {
  final id = int.tryParse(
    reporte['id']?.toString() ?? '',
  );

  final titulo =
      reporte['titulo']?.toString() ??
      "Reporte ${reporte['id']}";

  final fecha = DateTime.tryParse(
    reporte['fecha']?.toString() ?? '',
  );

  final pdf = reporte['pdf']?.toString();

  final bool disponible =
      pdf != null && pdf.isNotEmpty;

  final bool recibido =
      reporte['recibido'] == true;

  return Padding(
    padding: EdgeInsets.only(top: 15),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.lightBlue,
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
                    color: Colors.black,
                  ),
                ),
              ),

              IconButton(
                onPressed: disponible
                    ? () => descargar(reporte)
                    : null,
                icon: Icon(
                  Icons.picture_as_pdf,
                  size: 38,
                  color: disponible
                      ? AppColors.stateRed
                      : AppColors.secondaryText,
                ),
              ),
            ],
          ),

          if (fecha != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                formatearFecha(fecha),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.secondaryText,
                ),
              ),
            ),

          SizedBox(height: 15),

          Row(
            children: [
              Icon(
                recibido
                    ? Icons.check_circle
                    : Icons.pending_outlined,
                color: recibido
                    ? AppColors.stateGreen
                    : AppColors.stateYellowOrange,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  recibido
                      ? "Reporte recibido"
                      : "Pendiente de confirmar",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),

              if (!recibido && id != null)
                TextButton(
                  onPressed: () {
                    marcarRecibido(id);
                  },
                  child: Text(
                    "Marcar recibido",
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

String formatearMesCompleto(DateTime fecha) {
  const meses = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return "${meses[fecha.month]} ${fecha.year}";
}

String formatearFecha(DateTime fecha) {
  final dia =
      fecha.day.toString().padLeft(2, '0');

  final mes =
      fecha.month.toString().padLeft(2, '0');

  return "$dia/$mes/${fecha.year}";
}