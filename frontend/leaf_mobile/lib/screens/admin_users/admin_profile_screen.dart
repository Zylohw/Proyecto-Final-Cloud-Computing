import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/screens/login_screen.dart';
import 'package:leaf_mobile/services/api_services.dart';

String obtenerMensajeError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool cargando = true;

  String nombre = '';
  String correo = '';

  @override
  void initState() {
    super.initState();
    obtenerPerfil();
  }

  Future<void> obtenerPerfil() async {
    setState(() {
      cargando = true;
    });

    try {
      final data = await ApiService.instance.get(
        '/api/admin/perfil',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        nombre = data['usuario']['nombre'];
        correo = data['usuario']['correo'];
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(obtenerMensajeError(error)),
          backgroundColor: AppColors.stateRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> editarPerfil() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditProfileScreen(
          nombre: nombre,
          correo: correo,
        ),
      ),
    );

    if (resultado == true && mounted) {
      await obtenerPerfil();
    }
  }

  Future<void> crearMantenimiento() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCreateProfileScreen(),
      ),
    );
  }

  Future<void> cerrarSesion() async {
    await ApiService.instance.cerrarSesion();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.darkGreen,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: obtenerPerfil,
      color: AppColors.darkGreen,
      child: ListView(
        children: [
          adminProfileInfo(
            context,
            nombre,
            correo,
            editarPerfil,
            crearMantenimiento,
            cerrarSesion,
          ),
        ],
      ),
    );
  }
}

Padding adminProfileInfo(
  BuildContext context,
  String nombre,
  String correo,
  VoidCallback editarPerfil,
  VoidCallback crearMantenimiento,
  VoidCallback cerrarSesion,
) {
  return Padding(
    padding: EdgeInsetsGeometry.only(
      top: 20,
      left: 15,
      right: 15,
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.alternativeBackground,
      ),
      padding: EdgeInsets.only(
        top: 25,
        bottom: 25,
        left: 15,
        right: 15,
      ),
      child: Column(
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: AppColors.darkGreen,
          ),

          Text(
            "Administrador: $nombre",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),

          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              correo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.secondaryText,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 10, bottom: 20),
            child: Text(
              "Rol: Administrador",
              style: TextStyle(fontSize: 20),
            ),
          ),

          ElevatedButton(
            onPressed: editarPerfil,
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.darkGreen,
              fixedSize: Size(220, 40),
            ),
            child: Text(
              "Editar perfil",
              style: TextStyle(fontSize: 20),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: crearMantenimiento,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                fixedSize: Size(220, 40),
              ),
              child: Text(
                "Crear mantenimiento",
                style: TextStyle(
                  color: AppColors.background,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: cerrarSesion,
              style: ElevatedButton.styleFrom(
                fixedSize: Size(220, 40),
                backgroundColor: AppColors.stateRed,
              ),
              child: Text(
                "Cerrar Sesión",
                style: TextStyle(
                  color: AppColors.background,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AdminEditProfileScreen extends StatefulWidget {
  final String nombre;
  final String correo;

  const AdminEditProfileScreen({
    super.key,
    required this.nombre,
    required this.correo,
  });

  @override
  State<AdminEditProfileScreen> createState() =>
      _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    emailController.text = widget.correo;
    userController.text = widget.nombre;
  }

  @override
  void dispose() {
    emailController.dispose();
    userController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> guardarCambios() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final Map<String, dynamic> datos = {
        'nombre': userController.text.trim(),
        'correo': emailController.text.trim(),
      };

      if (passwordController.text.isNotEmpty) {
        datos['contrasena'] = passwordController.text;
      }

      final respuesta = await ApiService.instance.put(
        '/api/admin/perfil',
        datos,
      );

      final Map<String, dynamic> usuarioActualizado =
          Map<String, dynamic>.from(
            ApiService.instance.usuario ?? {},
          );

      usuarioActualizado['nombre'] =
          respuesta['usuario']['nombre'];

      usuarioActualizado['correo'] =
          respuesta['usuario']['correo'];

      ApiService.instance.usuario = usuarioActualizado;

      await ApiService.instance.storage.write(
        key: 'leaf_usuario',
        value: jsonEncode(usuarioActualizado),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respuesta['mensaje'],
          ),
          backgroundColor: AppColors.stateGreen,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(obtenerMensajeError(error)),
          backgroundColor: AppColors.stateRed,
        ),
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
        title: Text("Editar perfil"),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 70,
          left: 20,
          right: 29,
        ),
        children: [
          Center(
            child: Text(
              "Editar mi usuario:",
              style: TextStyle(fontSize: 31),
            ),
          ),

          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: AppColors.meidumBlue,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.meidumBlue,
                      ),
                    ),
                    labelText: "Email",
                    labelStyle: TextStyle(
                      color: AppColors.meidumBlue,
                    ),
                    hintText: "Ingrese un correo electrónico",
                    icon: Icon(Icons.mail),
                    iconColor: AppColors.meidumBlue,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese un correo electrónico';
                    }

                    if (!value.contains('@')) {
                      return 'Ingrese un correo válido';
                    }

                    return null;
                  },
                ),

                TextFormField(
                  controller: userController,
                  cursorColor: AppColors.meidumBlue,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.meidumBlue,
                      ),
                    ),
                    labelText: "Usuario",
                    labelStyle: TextStyle(
                      color: AppColors.meidumBlue,
                    ),
                    hintText: "Ingrese su nuevo nombre de usuario",
                    icon: Icon(Icons.person),
                    iconColor: AppColors.meidumBlue,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese su nombre';
                    }

                    return null;
                  },
                ),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  cursorColor: AppColors.meidumBlue,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.meidumBlue,
                      ),
                    ),
                    labelText: "Contraseña",
                    labelStyle: TextStyle(
                      color: AppColors.meidumBlue,
                    ),
                    hintText: "Dejar vacío para conservar la actual",
                    icon: Icon(Icons.lock),
                    iconColor: AppColors.meidumBlue,
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }

                    return null;
                  },
                ),

                Padding(
                  padding: EdgeInsetsGeometry.only(top: 30),
                  child: ElevatedButton(
                    onPressed: guardando ? null : guardarCambios,
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(300, 40),
                      backgroundColor: AppColors.darkGreen,
                    ),
                    child: guardando
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : Text(
                            "Guardar Cambios",
                            style: TextStyle(
                              color: AppColors.background,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCreateProfileScreen extends StatefulWidget {
  const AdminCreateProfileScreen({super.key});

  @override
  State<AdminCreateProfileScreen> createState() =>
      _AdminCreateProfileScreenState();
}

class _AdminCreateProfileScreenState
    extends State<AdminCreateProfileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool guardando = false;

  @override
  void dispose() {
    emailController.dispose();
    userController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> crearMantenimiento() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final respuesta = await ApiService.instance.post(
        '/api/admin/mantenimiento',
        {
          'nombre': userController.text.trim(),
          'correo': emailController.text.trim(),
          'contrasena': passwordController.text,
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respuesta['mensaje'],
          ),
          backgroundColor: AppColors.stateGreen,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(obtenerMensajeError(error)),
          backgroundColor: AppColors.stateRed,
        ),
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
        title: Text("Crear usuario Mantenimiento"),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 70,
          left: 20,
          right: 29,
        ),
        children: [
          Center(
            child: Text(
              "Nuevo personal de mantenimiento:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 31),
            ),
          ),

          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: userController,
                  cursorColor: AppColors.meidumBlue,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.meidumBlue,
                      ),
                    ),
                    labelText: "Usuario",
                    labelStyle: TextStyle(
                      color: AppColors.meidumBlue,
                    ),
                    hintText: "Ingrese el nombre del trabajador",
                    icon: Icon(Icons.person),
                    iconColor: AppColors.meidumBlue,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el nombre';
                    }

                    return null;
                  },
                ),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: AppColors.meidumBlue,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.meidumBlue,
                      ),
                    ),
                    labelText: "Email",
                    labelStyle: TextStyle(
                      color: AppColors.meidumBlue,
                    ),
                    hintText: "Ingrese el correo electrónico",
                    icon: Icon(Icons.mail),
                    iconColor: AppColors.meidumBlue,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese un correo electrónico';
                    }

                    if (!value.contains('@')) {
                      return 'Ingrese un correo válido';
                    }

                    return null;
                  },
                ),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  cursorColor: AppColors.meidumBlue,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.meidumBlue,
                      ),
                    ),
                    labelText: "Contraseña",
                    labelStyle: TextStyle(
                      color: AppColors.meidumBlue,
                    ),
                    hintText: "Ingrese una contraseña",
                    icon: Icon(Icons.lock),
                    iconColor: AppColors.meidumBlue,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una contraseña';
                    }

                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }

                    return null;
                  },
                ),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  cursorColor: AppColors.meidumBlue,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.meidumBlue,
                      ),
                    ),
                    labelText: "Confirmar contraseña",
                    labelStyle: TextStyle(
                      color: AppColors.meidumBlue,
                    ),
                    hintText: "Confirme la contraseña",
                    icon: Icon(Icons.lock_outline),
                    iconColor: AppColors.meidumBlue,
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }

                    return null;
                  },
                ),

                Padding(
                  padding: EdgeInsetsGeometry.only(top: 30),
                  child: ElevatedButton(
                    onPressed: guardando ? null : crearMantenimiento,
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(300, 40),
                      backgroundColor: AppColors.darkGreen,
                    ),
                    child: guardando
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : Text(
                            "Crear mantenimiento",
                            style: TextStyle(
                              color: AppColors.background,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}