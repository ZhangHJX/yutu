import 'package:common/common.dart';
import 'package:flutter/material.dart';

enum CStepStatus { todo, active, done, error }

class CStepItem {
  CStepItem({required this.title, required this.status});
  final String title;
  final CStepStatus status;
}

class CStepProgress extends StatelessWidget {
  const CStepProgress({required this.steps, this.margin, super.key});

  final List<CStepItem> steps;
  final double? margin;

  String imgPath(CStepItem step) => switch (step.status) {
    .done => 'assets/images/common/ic_circle_s.png',
    .active => 'assets/images/order/ic_in_progress.png',
    .todo => 'assets/images/order/ic_not_reach.png',
    .error => 'assets/images/common/ic_circle_e.png',
  };

  TextStyle textStyle(CStepItem step) {
    final isSpecial = [CStepStatus.active, CStepStatus.error].contains(step.status);
    return .new(
      fontSize: 13.w,
      height: 19 / 13,
      color: isSpecial ? cff333333 : cff545454,
      fontWeight: isSpecial ? .w500 : .normal,
      fontFamily: 'NotoSansSC',
    );
  }

  Widget _buildStep(CStepItem step) {
    return Stack(
      clipBehavior: .none,
      alignment: .center,
      children: [
        Image.asset(imgPath(step), width: 18.w, height: 18.w),
        Positioned(
          top: 27.w,
          child: Text(step.title, style: textStyle(step)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: .symmetric(horizontal: margin ?? 24.w),
      alignment: .topCenter,
      height: 46.w,
      child: Row(
        spacing: 3.w,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStep(steps[i]),
            if (i != steps.length - 1)
              Expanded(
                child: Container(
                  height: 2.w,
                  decoration: BoxDecoration(
                    borderRadius: .circular(2.w),
                    color: steps[i].status == .done ? Colors.orange : '#FFD1D1D1'.color,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
