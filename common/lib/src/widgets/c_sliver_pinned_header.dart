import 'package:flutter/material.dart';

class CSliverPinnedHeader extends StatelessWidget {
  const CSliverPinnedHeader({required this.preferredSize, required this.child, super.key});

  final Widget child;
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      delegate: _SliverPinnedHeaderDelegate(
        child: PreferredSize(preferredSize: preferredSize, child: child),
      ),
      pinned: true,
    );
  }
}

class _SliverPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SliverPinnedHeaderDelegate({required this.child});

  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _SliverPinnedHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
