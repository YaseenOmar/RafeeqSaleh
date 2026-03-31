import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafeeq_saleh/screen/ziker_screen.dart';
import 'package:rafeeq_saleh/styling/app_color.dart';
import 'package:rafeeq_saleh/widget/home_card.dart';

import '../data/azkar_lists.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColor.appBarColor,
        centerTitle: true,
        title: Text(
          'حصن المسلم ',
          style: TextStyle(color: AppColor.whiteColor),
        ),
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
        child: Column(
          children: [
            Row(
              children: [
                HomeCard(
                  imagePath: 'assets/images/azkar.png',
                  title: "أذكار الصباح  ",
                  details: "حصن المسلم ",
                  onClick: () {
                    final azkarLists = AzkarLists();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZikerScreen(
                          azkar: azkarLists.morningAzkar,
                          title: "أذكار الصباح",

                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 16.w),
                HomeCard(
                  imagePath: 'assets/images/azkar.png',
                  title: "أذكار المساء ",
                  details: "عداد التسبيح الالكتروني  ",
                  onClick: () {
                    final azkarLists = AzkarLists();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZikerScreen(
                          azkar: azkarLists.eveningAzkar,
                          title: "أذكار المساء",

                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 16.h,),
            Row(
              children: [
                HomeCard(
                  imagePath: 'assets/images/azkar.png',
                  title: "أذكار النوم  ",
                  details: "حصن المسلم ",
                  onClick: () {
                    final azkarLists = AzkarLists();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZikerScreen(
                          azkar: azkarLists.sleepAzkar,
                          title: "أذكار النوم",

                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 16.w),
                HomeCard(
                  imagePath: 'assets/images/azkar.png',
                  title: "أذكار بعد الصلاة ",
                  details: "عداد التسبيح الالكتروني  ",
                  onClick: () {
                    final azkarLists = AzkarLists();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZikerScreen(
                          azkar: azkarLists.afterPrayerAzkar,
                          title: "أذكار بعد الصلاة",

                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
