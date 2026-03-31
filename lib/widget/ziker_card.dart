import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafeeq_saleh/model/ziker.dart';
import 'package:rafeeq_saleh/styling/app_color.dart';

class ZikerCard extends StatelessWidget {
  final Ziker ziker;

  const ZikerCard({super.key, required this.ziker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColor.secondaryColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ziker.ziker,
                    style: TextStyle(color: AppColor.goldColor, fontSize: 16.sp),
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ziker.description,
                    style: TextStyle(color: AppColor.whiteColor, fontSize: 12.sp),
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w,),
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: AppColor.appBarColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Text(
                  ziker.numOfCount.toString(),
                  style: TextStyle(color: AppColor.goldColor,
                  fontSize: 24.sp),

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
