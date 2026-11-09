import 'package:flutter/material.dart';

class UsersTrackingScreen extends StatefulWidget{
  const UsersTrackingScreen({super.key});
  @override
  State<UsersTrackingScreen> createState() => _UsersTrackingScreenState();

}

class _UsersTrackingScreenState extends State<UsersTrackingScreen>{
  @override
  Widget build(BuildContext context){
    return Center(
      child: Text("Proximamente", style:  TextStyle(fontSize: 50),),
    );
  }
}