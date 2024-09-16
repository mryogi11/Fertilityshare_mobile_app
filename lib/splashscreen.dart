import 'dart:async';

import 'package:fertilityshare/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class splashscreen extends StatefulWidget {
  @override
  State<splashscreen> createState() => _splashscreenState();
}

class _splashscreenState extends State<splashscreen> {

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 4), (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> Homepage()));

    });
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  body: Center(
   // color: Colors.white,
    child: Image.asset("assets/images/fertilityshare.png")
  ),

   );
  }
}