import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Panel shown over a dimmed game while paused: Resume or go back to the menu.
class PausePanel extends StatelessWidget {
  const PausePanel({
    super.key,
    required this.onResume,
    required this.onMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.w,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF8D6E63), width: 3),
        boxShadow: const [
          BoxShadow(blurRadius: 12, color: Colors.black38, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Paused',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4037),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: onResume,
              child: Text('Resume', style: TextStyle(fontSize: 18.sp)),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: onMenu,
            child: Text('Quit to menu', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }
}
