import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class UsersMenuScreen extends StatefulWidget {
  final String userName;

  const UsersMenuScreen({
    super.key,
    required this.userName,
  });

  @override
  State<UsersMenuScreen> createState() =>
      _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UsersMenuScreen> {
  bool cargando = true;
  bool cargandoHistorial = false;

  String? mensajeError;

  List<Map<String, dynamic>> casas = [];
  List<Map<String, dynamic>> historial = [];

  int? casaSeleccionada;

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

        await obtenerHistorial();
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

  Future<void> obtenerHistorial() async {
    if (casaSeleccionada == null) {
      return;
    }

    setState(() {
      cargandoHistorial = true;
    });

    try {
      final respuesta = await ApiService.instance.get(
        '/api/usuarios/casas/$casaSeleccionada/historial?meses=6',
      );

      final dynamic datos = respuesta is List
          ? respuesta
          : respuesta['historial'];

      if (!mounted) {
        return;
      }

      setState(() {
        historial = datos is List
            ? datos
                .map(
                  (dato) => Map<String, dynamic>.from(dato),
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
          cargandoHistorial = false;
        });
      }
    }
  }

  double obtenerConsumo(Map<String, dynamic> dato) {
    final posiblesValores = [
      dato['consumo'],
      dato['consumo_mensual'],
      dato['diferencia'],
    ];

    for (final valor in posiblesValores) {
      if (valor != null) {
        final convertido = double.tryParse(
          valor.toString(),
        );

        if (convertido != null) {
          return convertido;
        }
      }
    }

    return 0;
  }

  double consumoActual() {
    if (historial.isEmpty) {
      return 0;
    }

    return obtenerConsumo(
      historial.last,
    );
  }

  Map<String, dynamic>? obtenerCasaSeleccionada() {
    if (casaSeleccionada == null) {
      return null;
    }

    for (final casa in casas) {
      final id = int.tryParse(
        casa['id'].toString(),
      );

      if (id == casaSeleccionada) {
        return casa;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final casaActual = obtenerCasaSeleccionada();
    final consumo = consumoActual();

    return RefreshIndicator(
      onRefresh: obtenerCasas,
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
            "Bienvenido ${widget.userName}",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
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
                    fontSize: 18,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),

          if (!cargando &&
              mensajeError == null &&
              casas.isNotEmpty) ...[
            selectorCasa(),

            if (casaActual != null)
              informacionCasa(casaActual),

            if (cargandoHistorial)
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.darkGreen,
                  ),
                ),
              ),

            if (!cargandoHistorial) ...[
              radialChart(consumo),

              if (historial.isNotEmpty)
                tablaHistorial(historial)
              else
                sinHistorial(),
            ],
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
            historial = [];
          });

          await obtenerHistorial();
        },
      ),
    );
  }
}

Padding informacionCasa(
  Map<String, dynamic> casa,
) {
  return Padding(
    padding: EdgeInsets.only(
      top: 20,
      bottom: 20,
    ),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home,
            size: 40,
            color: AppColors.darkGreen,
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${casa['sector']} - Casa ${casa['numero']}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Vivienda asociada",
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.secondaryText,
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

Padding radialChart(double data) {
  final double maximo =
      data > 30 ? data + 10 : 30;

  return Padding(
    padding: EdgeInsets.only(
      bottom: 20,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(50),
      ),
      padding: EdgeInsets.only(
        left: 30,
        right: 20,
        top: 10,
      ),
      child: Column(
        children: [
          Text(
            "Consumo actual",
            style: TextStyle(
              fontSize: 20,
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
                  fontSize: 17,
                ),
                maximum: maximo,
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
                      "${data.toStringAsFixed(2)} m³",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
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

Padding tablaHistorial(
  List<Map<String, dynamic>> historial,
) {
  return Padding(
    padding: EdgeInsets.only(
      bottom: 20,
    ),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Historial de consumo",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    "Mes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Lectura",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Consumo m³",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Observaciones",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: historial.map((dato) {
                final mes =
                    dato['mes']?.toString() ?? '-';

                final lectura =
                    dato['medida_tomada']?.toString() ?? '-';

                final consumo =
                    dato['consumo']?.toString() ??
                    dato['consumo_mensual']?.toString() ??
                    dato['diferencia']?.toString() ??
                    '-';

                final observaciones =
                    dato['contenido']?.toString() ?? '-';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        formatearMes(mes),
                      ),
                    ),
                    DataCell(
                      Text(lectura),
                    ),
                    DataCell(
                      Text(consumo),
                    ),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          observaciones,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

String formatearMes(String valor) {
  final fecha = DateTime.tryParse(valor);

  if (fecha == null) {
    return valor;
  }

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

  return meses[fecha.month];
}

Padding sinHistorial() {
  return Padding(
    padding: EdgeInsets.only(
      bottom: 20,
    ),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 50,
            color: AppColors.secondaryText,
          ),

          SizedBox(height: 15),

          Text(
            "No hay historial de consumo disponible.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    ),
  );
}

Color lightsIdentifierColor(double data) {
  if (data <= 10.9) {
    return AppColors.stateGreen;
  } else if (data <= 29.9) {
    return AppColors.stateYellowOrange;
  } else {
    return AppColors.stateRed;
  }
}