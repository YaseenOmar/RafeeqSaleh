import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafeeq_saleh/styling/app_color.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function()? onClickLeadingIcon;
  final Function()? onClickActionIcon;
  final Icon leadingIcon;
  final Icon actionIcon;

  const MyAppBar({
    super.key,
    this.onClickActionIcon,
    this.onClickLeadingIcon,
    this.leadingIcon = const Icon(Icons.menu),
    this.actionIcon = const Icon(Icons.person_4_sharp),
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.appBarColor,
      centerTitle: true,
      leading: InkWell(
        onTap: onClickLeadingIcon,
        child: Icon(leadingIcon.icon, color: AppColor.appBarIconColor),
      ),
      actions: [
        InkWell(
          onTap: onClickActionIcon,
          child: Icon(actionIcon.icon, color: AppColor.appBarIconColor),
        ),
        SizedBox(width: 24.w),
      ],
      title: Text(
        'الرفيق الصالح',
        style: TextStyle(
          fontSize: 18.sp,
          color: AppColor.goldColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(68.0);
}
