import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafeeq_saleh/screen/subha_screen.dart';
import 'screen/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),

        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        theme: ThemeData(
          fontFamily: 'NotoSerif'
        ),
        initialRoute: '/home_screen',
        routes: {
          "/home_screen":(context) => const HomeScreen(),
          "/subha_screen":(context) => const SubhaScreen(),

        },
      ),
    );
  }
}