import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GameOverPanel extends StatelessWidget {
  const GameOverPanel({
    super.key,
    required this.score,
    required this.best,
    required this.isNewBest,
    required this.onRestart,
    required this.onMenu,
  });

  final int score;
  final int best;
  final bool isNewBest;
  final VoidCallback onRestart;
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
            'Game Over',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4037),
            ),
          ),
          SizedBox(height: 16.h),
          _row('Score', '$score'),
          SizedBox(height: 6.h),
          _row('Best', '$best'),
          if (isNewBest) ...[
            SizedBox(height: 10.h),
            Text(
              'New Best!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ],
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: onRestart,
              child: Text('Restart', style: TextStyle(fontSize: 18.sp)),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: onMenu,
            child: Text('Menu', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    final style = TextStyle(
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF5D4037),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
