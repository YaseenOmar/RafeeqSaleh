import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rafeeq_saleh/styling/app_color.dart';

class SubhaScreen extends StatefulWidget {
  const SubhaScreen({super.key});

  @override
  State<SubhaScreen> createState() => _SubhaScreenState();
}

class _SubhaScreenState extends State<SubhaScreen> {
  int count = 0;
  int goal = 100;
  int totalTsbeeh = 1254;

  int get currentZikrIndex {
    return count ~/ 33;
  }

  String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  void _increment() {
    setState(() {
      if (count < goal) count++;
      totalTsbeeh++;
    });
  }

  void _reset() {
    setState(() {
      count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtly blended top-left pattern
            Positioned(
              top: 20,
              left: 20,
              child: SvgPicture.asset('assets/icons/icon2.svg', height: 80),
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                // Top Logo
                Center(
                  child: SvgPicture.asset('assets/icons/icon.svg', height: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'سبحة',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'اذكر الله ليطمئن قلبك',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xff94A3B8), // gray-ish text
                  ),
                ),

                const Spacer(flex: 2),

                // Main Circular Counter with Reset button positioned
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    children: [
                      // The main circle
                      Align(
                        alignment: Alignment.center,
                        child: InkWell(
                          onTap: _increment,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.primaryColor, // inner dark green
                              border: Border.all(
                                color: Color(0x30dae2fd), // border green
                                width: 5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0x30dae2fd,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  toArabicNumbers(count.toString()),
                                  style: const TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffD4AF37),
                                    height: 1.1,
                                  ),
                                ),
                                const Text(
                                  'العد الحالي',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white, // gold text
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Reset Button
                      Positioned(
                        bottom: 20,
                        left: 10, // Adjust this based on circle constraints
                        child: GestureDetector(
                          onTap: _reset,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.primaryColor,
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/icon3.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            toArabicNumbers('$count/$goal'),
                            style: const TextStyle(
                              color: Color(0xff94A3B8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'الهدف: ${toArabicNumbers(goal.toString())}',
                            style: const TextStyle(
                              color: Color(0xff94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: goal > 0 ? count / goal : 0,
                          backgroundColor: const Color(0xff1E293B),
                          // darker grey
                          minHeight: 8,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xffD4AF37), // gold progress
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Zikr Buttons Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildZikrButton('سبحان الله', 0),
                          const SizedBox(width: 12),
                          _buildZikrButton('الحمد لله', 1),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildZikrButton('الله أكبر', 2),
                          const SizedBox(width: 12),
                          _buildZikrButton('لا اله الا الله ', 3),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZikrButton(String text, int index) {
    bool isActive = currentZikrIndex == index;
    bool isDone = currentZikrIndex > index;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xffD4AF37) // الذكر الحالي
              : isDone
              ? const Color(0xff06513E) // الذكر اللي خلص
              : AppColor.primaryColor, // الذكر اللي لسا ما وصلناه
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff1E293B)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
