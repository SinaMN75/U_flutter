part of "u_admin.dart";

enum UAdminScreenType { mobile, tablet, desktop }

extension UAdminResponsiveContext on BuildContext {
  UAdminScreenType get screenType {
    final double w = MediaQuery.sizeOf(this).width;
    if (w < 720) return UAdminScreenType.mobile;
    if (w < 1100) return UAdminScreenType.tablet;
    return UAdminScreenType.desktop;
  }

  bool get isMobileWidth => screenType == UAdminScreenType.mobile;

  bool get isTabletWidth => screenType == UAdminScreenType.tablet;

  bool get isDesktopWidth => screenType == UAdminScreenType.desktop;

  double get pagePadding => isMobileWidth ? 12 : (isTabletWidth ? 20 : 28);

  double dialogWidth({double max = 420}) {
    final double available = MediaQuery.sizeOf(this).width - 48;
    return available < max ? available : max;
  }

  double dialogHeight({double max = 600}) {
    final double available = MediaQuery.sizeOf(this).height - 96;
    return available < max ? available : max;
  }

  T responsive<T>({required T mobile, required T desktop, T? tablet}) => switch (screenType) {
    UAdminScreenType.mobile => mobile,
    UAdminScreenType.tablet => tablet ?? desktop,
    UAdminScreenType.desktop => desktop,
  };
}

class UAdminResponsiveGrid extends StatelessWidget {
  const UAdminResponsiveGrid({required this.children, super.key, this.minTileWidth = 260, this.spacing = 16, this.runSpacing = 16});

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final int rawColumns = (maxWidth / minTileWidth).floor();
        final int columns = rawColumns.clamp(1, children.length);
        final double tileWidth = columns == 1 ? maxWidth : (maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((Widget child) => SizedBox(width: tileWidth, child: child)).toList(),
        );
      },
    );
  }
}

class UAdminPageBody extends StatelessWidget {
  const UAdminPageBody({required this.child, super.key, this.maxWidth = 1400, this.padded = true});

  final Widget child;
  final double maxWidth;
  final bool padded;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: padded ? child.pSymmetric(horizontal: context.pagePadding) : child,
    ),
  );
}
