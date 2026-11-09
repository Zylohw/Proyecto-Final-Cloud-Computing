import 'dart:io';

import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';

import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

class MstaffInputScreen extends StatefulWidget {
  final Map<String, dynamic>? casaInicial;

  const MstaffInputScreen({
    super.key,
    this.casaInicial,
  });

  @override
  State<MstaffInputScreen> createState() =>
      _MstaffInputScreenState();
}

class _MstaffInputScreenState extends State<MstaffInputScreen> {
  final formKey = GlobalKey<FormState>();

  final medidaController = TextEditingController();
  final contenidoController = TextEditingController();

  //final ImagePicker imagePicker = ImagePicker();

  List<Map<String, dynamic>> casas = [];

  int? casaSeleccionada;

  //File? fotoSeleccionada;

  bool cargando = true;
  bool guardando = false;

  String? mensajeError;

  @override
  void initState() {
    super.initState();

    casaSeleccionada = widget.casaInicial == null
        ? null
        : int.tryParse(
            widget.casaInicial!['id'].toString(),
          );

    obtenerCasas();
  }

  @override
  void dispose() {
    medidaController.dispose();
    contenidoController.dispose();
    super.dispose();
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

      if (!mounted) {
        return;
      }

      setState(() {
        casas = datos is List
            ? datos
                .map(
                  (casa) => Map<String, dynamic>.from(casa),
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

  // Future<void> tomarFoto() async {
  //   final XFile? imagen = await imagePicker.pickImage(
  //     source: ImageSource.camera,
  //     imageQuality: 80,
  //   );

  //   if (imagen == null || !mounted) {
  //     return;
  //   }

  //   setState(() {
  //     fotoSeleccionada = File(imagen.path);
  //   });
  // }

  // Future<void> seleccionarGaleria() async {
  //   final XFile? imagen = await imagePicker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 80,
  //   );

  //   if (imagen == null || !mounted) {
  //     return;
  //   }

  //   setState(() {
  //     fotoSeleccionada = File(imagen.path);
  //   });
  // }

  // void mostrarOpcionesFoto() {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return SafeArea(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             ListTile(
  //               leading: Icon(Icons.camera_alt),
  //               title: Text("Tomar fotografía"),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 tomarFoto();
  //               },
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.photo_library),
  //               title: Text("Seleccionar de galería"),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 seleccionarGaleria();
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  void mostrarMensaje(
    String mensaje,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  Future<void> guardarLectura() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (casaSeleccionada == null) {
      mostrarMensaje(
        "Seleccione una vivienda.",
        AppColors.stateRed,
      );

      return;
    }

    // if (fotoSeleccionada == null) {
    //   mostrarMensaje(
    //     "Debe agregar una fotografía del contador.",
    //     AppColors.stateRed,
    //   );

    //   return;
    // }

    final medida = double.tryParse(
      medidaController.text.trim().replaceAll(',', '.'),
    );

    if (medida == null) {
      mostrarMensaje(
        "Ingrese una medición válida.",
        AppColors.stateRed,
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final respuesta = await ApiService.instance.post(
        '/api/mantenimiento/lecturas',
        {
          'casa_id': casaSeleccionada,
          'medida_tomada': medida,
          'contenido': contenidoController.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }

      mostrarMensaje(
        respuesta['mensaje']?.toString() ??
            "Lectura registrada correctamente.",
        AppColors.stateGreen,
      );

      medidaController.clear();
      contenidoController.clear();

      // setState(() {
      //   fotoSeleccionada = null;
      // });

      if (widget.casaInicial != null) {
        Navigator.pop(context, true);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Nueva lectura"),
        backgroundColor: AppColors.background,
      ),
      body: cargando
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.darkGreen,
              ),
            )
          : mensajeError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mensajeError!),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: obtenerCasas,
                        child: Text("Reintentar"),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                   // bloqueFotografia(),

                    SizedBox(height: 30),

                    bloqueFormulario(),

                    SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            guardando ? null : guardarLectura,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: guardando
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Guardar",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // Widget bloqueFotografia() {
  //   return Container(
  //     height: 220,
  //     decoration: BoxDecoration(
  //       color: AppColors.alternativeBackground,
  //       borderRadius: BorderRadius.circular(25),
  //       border: Border.all(
  //         color: AppColors.secondaryText,
  //       ),
  //     ),
  //     child: fotoSeleccionada == null
  //         ? InkWell(
  //             onTap: mostrarOpcionesFoto,
  //             borderRadius: BorderRadius.circular(25),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(
  //                   Icons.add_a_photo_outlined,
  //                   size: 55,
  //                   color: AppColors.darkGreen,
  //                 ),
  //                 SizedBox(height: 15),
  //                 Text(
  //                   "Agregar fotografía",
  //                   style: TextStyle(
  //                     fontSize: 20,
  //                     color: AppColors.primaryText,
  //                   ),
  //                 ),
  //                 SizedBox(height: 8),
  //                 Text(
  //                   "Tome una foto del contador",
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: AppColors.secondaryText,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           )
  //         : Stack(
  //             fit: StackFit.expand,
  //             children: [
  //               ClipRRect(
  //                 borderRadius: BorderRadius.circular(25),
  //                 child: Image.file(
  //                   fotoSeleccionada!,
  //                   fit: BoxFit.cover,
  //                 ),
  //               ),
  //               Positioned(
  //                 right: 10,
  //                 top: 10,
  //                 child: CircleAvatar(
  //                   backgroundColor: Colors.black54,
  //                   child: IconButton(
  //                     onPressed: mostrarOpcionesFoto,
  //                     icon: Icon(
  //                       Icons.edit,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //   );
  // }

  Widget bloqueFormulario() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.alternativeBackground,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.secondaryText,
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Datos de la lectura",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.navyBlue,
              ),
            ),

            SizedBox(height: 20),

            DropdownButtonFormField<int>(
              value: casaSeleccionada,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Vivienda",
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.home_outlined,
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
              onChanged: (valor) {
                setState(() {
                  casaSeleccionada = valor;
                });
              },
              validator: (valor) {
                if (valor == null) {
                  return "Seleccione una vivienda";
                }

                return null;
              },
            ),

            SizedBox(height: 20),

            TextFormField(
              controller: medidaController,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Medición",
                hintText: "Ejemplo: 125.50",
                suffixText: "m³",
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.water_drop_outlined,
                ),
              ),
              validator: (valor) {
                if (valor == null ||
                    valor.trim().isEmpty) {
                  return "Ingrese la medición";
                }

                final medida = double.tryParse(
                  valor.trim().replaceAll(',', '.'),
                );

                if (medida == null) {
                  return "Ingrese una medición válida";
                }

                return null;
              },
            ),

            SizedBox(height: 20),

            TextFormField(
              controller: contenidoController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Observaciones",
                hintText: "Estado del contador",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.description_outlined,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}