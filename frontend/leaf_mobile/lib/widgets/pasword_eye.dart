import 'package:flutter/material.dart';

class PasswordEye extends StatefulWidget {
  final bool openEye;
  final Function() changeStateEye;
  const PasswordEye({super.key,required this.openEye,required this.changeStateEye});
  @override
  State<PasswordEye> createState() => _PasswordEyeState();
}

class _PasswordEyeState extends State<PasswordEye> {
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        widget.changeStateEye();
      },
      icon: getIconState(widget.openEye),
    );
  }

  Icon getIconState(bool openEye) {
    if (openEye == true) {
      return Icon(Icons.visibility);
    }
    return Icon(Icons.visibility_off);
  }
}
