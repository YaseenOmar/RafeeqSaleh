import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafeeq_saleh/model/ziker.dart';
import 'package:rafeeq_saleh/styling/app_color.dart';
import 'package:rafeeq_saleh/widget/ziker_card.dart';

class ZikerScreen extends StatefulWidget {
  final List<Ziker> azkar;
  final String title;

  const ZikerScreen({super.key, required this.azkar, required this.title});

  @override
  State<ZikerScreen> createState() => _ZikerScreenState();
}

class _ZikerScreenState extends State<ZikerScreen> {
  late List<Ziker> currentAzkar;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    currentAzkar = List.from(widget.azkar);
  }

  void _decrementCounter(int index) {
    final ziker = currentAzkar[index];

    if (ziker.numOfCount > 1) {
      setState(() {
        currentAzkar[index] = Ziker(
          ziker: ziker.ziker,
          description: ziker.description,
          numOfCount: ziker.numOfCount - 1,
        );
      });
    } else {
      final removedZiker = currentAzkar.removeAt(index);
      _listKey.currentState!.removeItem(
        index,
            (context, animation) => _buildItem(removedZiker, animation),
        duration: const Duration(milliseconds: 300),

      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
    }
  }

  Widget _buildItem(Ziker ziker, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: ZikerCard(ziker: ziker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appBarColor,
        centerTitle: true,
        title: Text(widget.title, style: TextStyle(color: AppColor.whiteColor)),
      ),
      backgroundColor: AppColor.primaryColor,
      body: currentAzkar.isNotEmpty? AnimatedList(
        key: _listKey,
        padding: const EdgeInsets.all(8.0),
        initialItemCount: currentAzkar.length,
        itemBuilder: (context, index, animation) {
          return InkWell(
            onTap: () => _decrementCounter(index),
            child: _buildItem(currentAzkar[index], animation),
          );
        },
      ): Center(
        child: Column(
          children: [
            Image.asset('assets/images/done.png'),
            Text('تم الانتهاء من ${widget.title}', style: TextStyle(
              color: AppColor.whiteColor,
              fontSize: 24.sp
            ),),
          ],
        ),
      ),
    );
  }
}