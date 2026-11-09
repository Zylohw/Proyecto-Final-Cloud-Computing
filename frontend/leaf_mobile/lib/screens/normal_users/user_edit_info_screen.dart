import 'package:flutter/material.dart';
import 'package:leaf_mobile/screens/login_screen.dart';
import 'package:leaf_mobile/screens/normal_users/user_screen_router.dart';
import 'package:leaf_mobile/core/app_colors.dart';
import 'package:leaf_mobile/screens/normal_users/users_menu_screen.dart';
import 'package:leaf_mobile/screens/normal_users/users_profile_screen.dart';
import 'package:leaf_mobile/widgets/pasword_eye.dart';

class UserEditInfoScreen extends StatefulWidget {
  const UserEditInfoScreen({super.key});
  @override
  State<UserEditInfoScreen> createState() => _UserEditoInfoScreenState();
}

class _UserEditoInfoScreenState extends State<UserEditInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: myFormEditor(context)));
  }
}

ListView myFormEditor(BuildContext context) {
  return ListView(
    padding: EdgeInsets.only(top: 140, left: 20, right: 29),
    children: [
      Center(
        child: Text("Editar mi usuario: ", style: TextStyle(fontSize: 31)),
      ),
      Form(
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
                iconColor: AppColors.meidumBlue,
              ),
            ),
            TextFormField(
              autofocus: true,
              cursorColor: AppColors.meidumBlue,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.meidumBlue),
                ),
                labelText: "Usuario",
                labelStyle: TextStyle(color: AppColors.meidumBlue),
                hintText: "Ingrese su nuevo nombre de usuario",
                icon: Icon(Icons.person),
                iconColor: AppColors.meidumBlue,
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(top: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)=>LoginScreen())
                  );
                },
                style: ElevatedButton.styleFrom(fixedSize: Size(300, 30)),
                child: Text(
                  "Guardar Cambios",
                  style: TextStyle(color: AppColors.navyBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
