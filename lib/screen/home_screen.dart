import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafeeq_saleh/styling/app_color.dart';
import 'package:rafeeq_saleh/widget/home_cart.dart';
import 'package:rafeeq_saleh/widget/my_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      appBar: MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0x5f122a3a),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColor.appBarColor, // border green
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          '24 - رمضان - 1445',
                          style: TextStyle(
                            color: AppColor.whiteColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '16 -  مارس - 2026',
                          style: TextStyle(
                            color: AppColor.whiteColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 42.w,
                      height: 42.h,
                      decoration: BoxDecoration(
                        color: AppColor.secondaryColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppColor.goldColor,
                        size: 28.r,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              height: 148.h,
              decoration: BoxDecoration(
                color: Color(0x5f122a3a),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColor.appBarColor, // border green
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -1,
                    left: -5,
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.only(
                        bottomLeft: Radius.circular(24.r),
                      ),
                      child: Image.asset(
                        'assets/images/mosque.png',
                        color: Color(0x30dae2fd),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 16.w,
                    top: 24.h,
                    child: Column(
                      children: [
                        Text(
                          'الصلاة القادمة',
                          style: TextStyle(
                            color: AppColor.whiteColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'المغرب',
                          style: TextStyle(
                            color: AppColor.whiteColor,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: AppColor.greenColor,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'متبقي 00:45:22',
                              style: TextStyle(
                                color: AppColor.greenColor,
                                fontSize: 18.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 24.h,
                    left: 24.w,
                    child: Text(
                      '6:12 PM',
                      style: TextStyle(
                        color: AppColor.goldColor,
                        fontSize: 32.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                HomeCart(
                  imagePath: 'assets/images/quran.png',
                  title: "قراءة القران ",
                  details: "متابعة الورد اليومي ",
                ),
                SizedBox(width: 16.w),
                HomeCart(
                  imagePath: 'assets/images/sound.png',
                  title: "تلاوات صوتية ",
                  details: "بأصوات مشاهير القراء ",
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                HomeCart(
                  imagePath: 'assets/images/azkar.png',
                  title: "الأذكار اليومية ",
                  details: "حصن المسلم ",
                ),
                SizedBox(width: 16.w),
                HomeCart(
                  imagePath: 'assets/images/tasbih.png',
                  title: "المسبحة الالكترونية",
                  details: "بأصوات مشاهير القراء ",
                  onClick: () {
                    Navigator.pushNamed(context, '/subha_screen');
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
