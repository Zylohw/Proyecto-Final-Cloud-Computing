import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/screens/login_screen.dart';
import 'package:leaf_mobile/widgets/pasword_eye.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreen();
}

class _RegisterScreen extends State<RegisterScreen> {
  bool eyeOpen = true;
  bool eyeOpen2 = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [logoRow(), registerForm(), registerButton()]),
    );
  }

  // logo Row
  Row logoRow() {
    return Row(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.only(top: 0.4, left: 60),
          child: Image.asset(
            'assets/images/LogoV3.png',
            width: 290,
            height: 290,
          ),
        ),
      ],
    );
  }

  Padding registerForm() {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 20, right: 30),
      child: Form(
        child: Column(
          children: [
            TextFormField(
              autofocus: true,
              cursorColor: AppColors.meidumBlue,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.meidumBlue),
                ),
                labelText: "Email",
                labelStyle: TextStyle(color: AppColors.meidumBlue),
                hintText: "Ingrese un correo electronico",
                icon: Icon(Icons.mail),
                iconColor: AppColors.meidumBlue
              ),
            ),
            TextFormField(
              autofocus: true,
              cursorColor: AppColors.meidumBlue,
              obscureText: eyeOpen,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.meidumBlue),
                ),
                labelText: "Contraseña",
                labelStyle: TextStyle(color: AppColors.meidumBlue),
                hintText: "Contraseña minimo 8 caracteres",
                icon: Icon(Icons.key),
                iconColor: AppColors.meidumBlue,
                suffixIconColor: AppColors.meidumBlue,
                suffixIcon: PasswordEye(
                  openEye: eyeOpen,
                  changeStateEye: () {
                    setState(() {
                      eyeOpen = !eyeOpen;
                    });
                  },
                ),
              ),
            ),
            TextFormField(
              autocorrect: true,
              cursorColor: AppColors.meidumBlue,
              obscureText: eyeOpen2,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.meidumBlue),
                ),
                labelText: "Repetir Contraseña",
                labelStyle: TextStyle(color: AppColors.meidumBlue),
                hintText: "Repita la contraseña por favor",
                icon: Icon(Icons.key),
                iconColor: AppColors.meidumBlue,
                suffixIconColor: AppColors.meidumBlue,
                suffixIcon: PasswordEye(
                  openEye: eyeOpen2,
                  changeStateEye: () {
                    setState(() {
                      eyeOpen2 = !eyeOpen2;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding registerButton() {
    return Padding(
      padding: EdgeInsetsGeometry.only(top: 16),
      child: FilledButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
        style: FilledButton.styleFrom(backgroundColor: AppColors.meidumBlue),
        child: Text("Registrar"),
      ),
    );
  }
}
