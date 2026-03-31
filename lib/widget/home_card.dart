import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafeeq_saleh/styling/app_color.dart';

class HomeCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String details;
  final Function()? onClick;

  const HomeCard({
    super.key,
    this.onClick,
    required this.imagePath,
    required this.title,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      child: Container(
        width: 160.w,
        height: 176.h,
        decoration: BoxDecoration(
          color: AppColor.secondaryColor,
          borderRadius: BorderRadiusGeometry.circular(12.r),
          border: Border.all(
            color: AppColor.appBarColor, // border green
            width: 2.w,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(imagePath),
              SizedBox(height: 12.h),
              Text(
                title,
                style: TextStyle(color: AppColor.whiteColor, fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Text(
                details,
                style: TextStyle(color: AppColor.whiteColor, fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
