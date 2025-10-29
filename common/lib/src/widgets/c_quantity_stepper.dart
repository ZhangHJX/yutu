import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CQuantityStepper extends StatelessWidget {
  const CQuantityStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24.w,
      decoration: BoxDecoration(
        border: Border.all(color: '#FFD1D1D1'.color, width: hairline),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        children: [
          CButton(
            icon: Image.asset('assets/images/shop_cart/ic_minus.png'),
            width: 20.w,
            height: double.infinity,
            border: Border(right: borderSide),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: CText(
              '88',
              style: text333333(fontSize: 13.w),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          CButton(
            icon: Image.asset('assets/images/shop_cart/ic_add.png'),
            width: 20.w,
            height: double.infinity,
            border: Border(left: borderSide),
          ),
        ],
      ),
    );
  }
}
