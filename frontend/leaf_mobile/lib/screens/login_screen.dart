import 'package:flutter/material.dart';

import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/services/api_services.dart';

import 'package:leaf_mobile/screens/admin_users/admin_screen_router.dart';
import 'package:leaf_mobile/screens/forget_password_screen.dart';
import 'package:leaf_mobile/screens/maintenance_staff/mstaff_screen_router.dart';
import 'package:leaf_mobile/screens/normal_users/user_screen_router.dart';
import 'package:leaf_mobile/screens/register_screen.dart';

import 'package:leaf_mobile/widgets/pasword_eye.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool eyeopen = true;

  bool cargando = false;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController contrasenaController =
      TextEditingController();

  @override
  void dispose() {
    correoController.dispose();

    contrasenaController.dispose();

    super.dispose();
  }

  Future<void> iniciarSesion() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      await ApiService.instance.iniciarSesion(
        correoController.text.trim(),
        contrasenaController.text,
      );

      if (!mounted) {
        return;
      }

      final String rol =
          ApiService.instance.usuario?['rol'] ?? '';

      Widget pantalla;

      switch (rol) {
        case 'Administrador':
          pantalla = const AdminScreenRouter();
          break;

        case 'Mantenimiento':
          pantalla = const MstaffScreenRouter();
          break;

        case 'Comun':
          pantalla = const UserScreenRouter();
          break;

        default:
          await ApiService.instance.cerrarSesion();

          throw Exception(
            'El usuario no tiene un rol válido',
          );
      }

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => pantalla,
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      String mensaje = error.toString();

      if (mensaje.startsWith('Exception: ')) {
        mensaje = mensaje.replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          children: [
            logoRow(),
            formInputs(),
            specialButtons(),
          ],
        ),
      ),
    );
  }

  Widget logoRow() {
    return Center(
      child: Image.asset(
        'assets/images/LogoV3.png',
        width: 290,
        height: 290,
      ),
    );
  }

  Padding formInputs() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 30,
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              cursorColor: AppColors.meidumBlue,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.meidumBlue,
                  ),
                ),
                icon: Icon(
                  Icons.person,
                  color: AppColors.meidumBlue,
                ),
                labelText: "Email",
                hintText: "user123@gmail.com",
                labelStyle: TextStyle(
                  color: AppColors.meidumBlue,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese su correo electrónico';
                }

                if (!value.contains('@')) {
                  return 'Ingrese un correo válido';
                }

                return null;
              },
            ),

            TextFormField(
              controller: contrasenaController,
              cursorColor: AppColors.meidumBlue,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.meidumBlue,
                  ),
                ),
                icon: Icon(
                  Icons.key,
                  color: AppColors.meidumBlue,
                ),
                labelText: "Contraseña",
                labelStyle: TextStyle(
                  color: AppColors.meidumBlue,
                ),
                suffixIcon: PasswordEye(
                  openEye: eyeopen,
                  changeStateEye: () {
                    setState(() {
                      eyeopen = !eyeopen;
                    });
                  },
                ),
                suffixIconColor: AppColors.meidumBlue,
              ),
              obscureText: eyeopen,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese su contraseña';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Padding specialButtons() {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FilledButton(
            onPressed: cargando ? null : iniciarSesion,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.meidumBlue,
            ),
            child: cargando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : Text("Iniciar Sesión"),
          ),

          TextButton(
            onPressed: cargando
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ForgetPasswordScreen(),
                      ),
                    );
                  },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.meidumBlue,
            ),
            child: Text(
              "¿Olvidaste tu contraseña?",
            ),
          ),

          TextButton(
            onPressed: cargando
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const RegisterScreen(),
                      ),
                    );
                  },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.meidumBlue,
            ),
            child: Text("Registrarse"),
          ),
        ],
      ),
    );
  }
}