import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rafeeq_saleh/data/azkar_lists.dart';
import 'package:rafeeq_saleh/screen/azkar_screen.dart';
import 'package:rafeeq_saleh/screen/subha_screen.dart';
import 'package:rafeeq_saleh/screen/ziker_screen.dart';
import 'screen/home_screen.dart';

void main() async{
  runApp(const MyApp());
  await initializeDateFormatting('ar');

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final AzkarLists azkarLists = AzkarLists();
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
          "/azkar_screen":(context) => const AzkarScreen(),
          "/ziker_screen":(context) => const ZikerScreen(azkar: [], title: '',),

        },
      ),
    );
  }
}