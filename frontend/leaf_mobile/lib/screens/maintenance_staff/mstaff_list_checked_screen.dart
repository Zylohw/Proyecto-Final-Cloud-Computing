import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';
import 'package:leaf_mobile/screens/maintenance_staff/mstaff_input_screen.dart';

class MstaffListCheckedScreen extends StatefulWidget {
  const MstaffListCheckedScreen({super.key});

  @override
  State<MstaffListCheckedScreen> createState() =>
      _MstaffListCheckedScreenState();
}

class _MstaffListCheckedScreenState
    extends State<MstaffListCheckedScreen> {
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
        '/api/mantenimiento/casas',
      );

      final dynamic datos = respuesta is List
          ? respuesta
          : respuesta['casas'];

      if (!mounted) return;

      setState(() {
        casas = datos is List
            ? datos
                .map((casa) => Map<String, dynamic>.from(casa))
                .toList()
            : [];
      });
    } catch (error) {
      if (!mounted) return;

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

  Future<void> abrirRegistro(Map<String, dynamic> casa) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MstaffInputScreen(
          casaInicial: casa,
        ),
      ),
    );

    if (resultado == true && mounted) {
      await obtenerCasas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: obtenerCasas,
      color: AppColors.darkGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 30, 15, 30),
        children: [
          const Text(
            "Lecturas de viviendas",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Seleccione una vivienda para registrar la medición de su contador.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 25),

          if (cargando)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.darkGreen,
              ),
            ),

          if (!cargando && mensajeError != null) ...[
            const Icon(
              Icons.error_outline,
              color: AppColors.stateRed,
              size: 55,
            ),

            const SizedBox(height: 15),

            Text(
              mensajeError!,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: obtenerCasas,
              child: const Text("Reintentar"),
            ),
          ],

          if (!cargando && mensajeError == null) ...[
            Text(
              "Viviendas disponibles: ${casas.length}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.navyBlue,
              ),
            ),

            const SizedBox(height: 15),

            if (casas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 35),
                child: Center(
                  child: Text(
                    "No hay viviendas disponibles.",
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),

            ...casas.map(
              (casa) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.alternativeBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: const Icon(
                      Icons.home_outlined,
                      size: 35,
                      color: AppColors.darkGreen,
                    ),
                    title: Text(
                      "${casa['sector']} - Casa ${casa['numero']}",
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue,
                      ),
                    ),
                    subtitle: Text(
                      "Vivienda ${casa['id']}",
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.meidumBlue,
                    ),
                    onTap: () => abrirRegistro(casa),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}