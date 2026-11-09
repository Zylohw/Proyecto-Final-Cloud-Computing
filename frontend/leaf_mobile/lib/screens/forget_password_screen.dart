import 'package:flutter/material.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/screens/login_screen.dart';
import 'package:leaf_mobile/widgets/pasword_eye.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});
  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScren();
}

class _ForgetPasswordScren extends State<ForgetPasswordScreen> {
  bool openEye1 = true;
  bool openEye2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [logoRow(), resetPasswordForm(), resetButton()]),
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

  Padding resetPasswordForm() {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 20, right: 30),
      child: Form(
        child: Column(
          children: [
            TextFormField(
              autofocus: true,
              cursorColor: AppColors.meidumBlue,
              decoration: InputDecoration(
                focusColor: AppColors.meidumBlue,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.meidumBlue),
                ),
                labelText: "Contraseña",
                labelStyle: TextStyle(color: AppColors.meidumBlue),
                hintText: "Resetar Contraseña",
                icon: Icon(Icons.key),
                iconColor: AppColors.meidumBlue,
                suffixIconColor: AppColors.meidumBlue,
                suffixIcon: PasswordEye(
                  openEye: openEye1,
                  changeStateEye: () {
                    setState(() {
                      openEye1 = !openEye1;
                    });
                  },
                ),
              ),
            ),
            TextFormField(
              autofocus: true,
              cursorColor: AppColors.meidumBlue,
              decoration: InputDecoration(
                focusColor: AppColors.meidumBlue,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.meidumBlue),
                ),
                labelText: "Repetir Contraseña",
                hintText: "Repetir Contraseña",
                labelStyle: TextStyle(color: AppColors.meidumBlue),
                icon: Icon(Icons.key),
                iconColor: AppColors.meidumBlue,
                suffixIconColor: AppColors.meidumBlue,
                suffixIcon: PasswordEye(
                  openEye: openEye2,
                  changeStateEye: () {
                    setState(() {
                      openEye2 = !openEye2;
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

  Padding resetButton() {
    return Padding(
      padding: EdgeInsetsGeometry.only(top: 10),
      child: FilledButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
        style: FilledButton.styleFrom(backgroundColor: AppColors.meidumBlue),
        child: Text("Resetear contraseña"),
      ),
    );
  }
}
