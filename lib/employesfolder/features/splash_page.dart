import 'dart:async';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constante/assets.dart';
import '../../constante/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;


  @override
  void initState() {
    super.initState();


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );


    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );


    _scaleAnimation = Tween<double>(
      begin: .85,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );


    _controller.forward();


    _checkAuthentication();
  }



  Future<void> _checkAuthentication() async {

  await Future.delayed(
    const Duration(seconds: 2),
  );


  final logged = await AuthService.isLoggedIn();


  if (!mounted) return;


  if (logged) {

    context.goNamed(
      'dashboard',
    );

  } else {

    context.goNamed(
      'login',
    );

  }

}



  @override
  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      body: Center(

        child: FadeTransition(

          opacity: _fadeAnimation,

          child: ScaleTransition(

            scale: _scaleAnimation,

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Image.asset(

                  AppAssets.logoSplash,

                  width: 130,

                ),


                const SizedBox(height:24),


                const Text(

                  "ATTENDANCE",

                  style: TextStyle(

                    fontSize:30,

                    fontWeight:FontWeight.bold,

                    letterSpacing:2,

                  ),

                ),


                const SizedBox(height:12),


                const Text(

                  "Gestion intelligente des présences",

                  style: TextStyle(

                    color:AppColors.textSecondary,

                    fontSize:15,

                  ),

                ),


                const SizedBox(height:50),


                const SizedBox(

                  width:35,

                  height:35,

                  child:CircularProgressIndicator(

                    strokeWidth:3,

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }
}