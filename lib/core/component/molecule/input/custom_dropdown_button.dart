// ignore_for_file: require_trailing_commas, prefer_asserts_with_message

import 'dart:math' as math;

import 'package:cloudloop_mobile/core/preferences/colors.dart';
import 'package:flutter/material.dart';

const Duration _kDropdownMenuDuration = Duration(milliseconds: 300);
const double _kMenuItemHeight = 48;
const double _kDenseButtonHeight = 24;
const EdgeInsets _kMenuItemPadding = EdgeInsets.symmetric(horizontal: 16);
const EdgeInsetsGeometry _kAlignedButtonPadding =
    EdgeInsetsDirectional.only(start: 16, end: 4);
const EdgeInsets _kUnalignedButtonPadding = EdgeInsets.zero;
const EdgeInsets _kAlignedMenuMargin = EdgeInsets.zero;
const EdgeInsetsGeometry _kUnalignedMenuMargin =
    EdgeInsetsDirectional.only(start: 16, end: 24);

class _DropdownMenuPainter extends CustomPainter {
  _DropdownMenuPainter({
    required this.color,
    required this.elevation,
    required this.selectedIndex,
    required this.resize,
  })  : _painter = BoxDecoration(
          // If you add an image here, you must provide a real
          // of onChanged callback here.
          color: color,
          borderRadius: BorderRadius.circular(2),
          boxShadow: kElevationToShadow[elevation],
        ).createBoxPainter(),
        super(repaint: resize);

  final Color color;
  final int elevation;
  final int selectedIndex;
  final Animation<double> resize;

  final BoxPainter _painter;

  @override
  void paint(Canvas canvas, Size size) {
    final selectedItemOffset =
        selectedIndex * _kMenuItemHeight + kMaterialListPadding.top;
    final top = Tween<double>(
      begin: selectedItemOffset.clamp(0.0, size.height - _kMenuItemHeight),
      end: 0,
    );

    final bottom = Tween<double>(
      begin: (top.begin ?? 0 + _kMenuItemHeight)
          .clamp(_kMenuItemHeight, size.height),
      end: size.height,
    );

    final rect = Rect.fromLTRB(
      0,
      top.evaluate(resize),
      size.width,
      bottom.evaluate(resize),
    );

    _painter.paint(
      canvas,
      rect.topLeft,
      ImageConfiguration(size: rect.size),
    );
  }

  @override
  bool shouldRepaint(_DropdownMenuPainter oldPainter) {
    return oldPainter.color != color ||
        oldPainter.elevation != elevation ||
        oldPainter.selectedIndex != selectedIndex ||
        oldPainter.resize != resize;
  }
}

// Do not use the platform-specific default scroll configuration.
// Dropdown menus should never overscroll or display an overscroll indicator.
class _DropdownScrollBehavior extends ScrollBehavior {
  const _DropdownScrollBehavior();

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      Theme.of(context).platform;

  @override
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

class _DropdownMenu<T> extends StatefulWidget {
  const _DropdownMenu({
    Key? key,
    required this.padding,
    required this.route,
  }) : super(key: key);

  final _DropdownRoute<T> route;
  final EdgeInsets padding;

  @override
  _DropdownMenuState<T> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<_DropdownMenu<T>> {
  late CurvedAnimation _fadeOpacity;
  late CurvedAnimation _resize;

  @override
  void initState() {
    super.initState();
    // We need to hold these animations as state because of their curve
    // direction. When the route's animation reverses, if we were to recreate
    // the CurvedAnimation objects in build, we'd lose
    // CurvedAnimation._curveDirection.
    _fadeOpacity = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0, 0.25),
      reverseCurve: const Interval(0.75, 1),
    );
    _resize = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Threshold(0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final route = widget.route;
    final unit = 0.5 / (route.items.length + 1.5);
    final children = <Widget>[];
    for (var itemIndex = 0; itemIndex < route.items.length; ++itemIndex) {
      CurvedAnimation opacity;
      if (itemIndex == route.selectedIndex) {
        opacity = CurvedAnimation(
          parent: route.animation!,
          curve: const Threshold(0),
        );
      } else {
        final start = (0.5 + (itemIndex + 1) * unit).clamp(0.0, 1.0);
        final end = (start + 1.5 * unit).clamp(0.0, 1.0);
        opacity = CurvedAnimation(
          parent: route.animation!,
          curve: Interval(start, end),
        );
      }
      children.add(
        FadeTransition(
          opacity: opacity,
          child: InkWell(
            onTap: () => Navigator.pop(
              context,
              // ignore: null_check_on_nullable_type_parameter
              _DropdownRouteResult<T>(route.items[itemIndex].value!),
            ),
            child: Container(
              padding: widget.padding,
              child: route.items[itemIndex],
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeOpacity,
      child: CustomPaint(
        painter: _DropdownMenuPainter(
          color: Theme.of(context).canvasColor,
          elevation: route.elevation,
          selectedIndex: route.selectedIndex,
          resize: _resize,
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: localizations.popupMenuLabel,
          child: Material(
            type: MaterialType.transparency,
            textStyle: route.style,
            child: ScrollConfiguration(
              behavior: const _DropdownScrollBehavior(),
              child: Scrollbar(
                child: ListView(
                  controller: widget.route.scrollController,
                  padding: kMaterialListPadding,
                  itemExtent: _kMenuItemHeight,
                  shrinkWrap: true,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuRouteLayout<T> extends SingleChildLayoutDelegate {
  _DropdownMenuRouteLayout({
    required this.buttonRect,
    required this.menuTop,
    required this.menuHeight,
    required this.textDirection,
  });

  final Rect buttonRect;
  final double menuTop;
  final double menuHeight;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The maximum height of a simple menu should be one or more rows less than
    // the view height. This ensures a tappable area outside of the simple menu
    // with which to dismiss the menu.
    //   -- https://material.google.com/components/menus.html#menus-simple-menus
    final double maxHeight =
        math.max(0, constraints.maxHeight - 2 * _kMenuItemHeight);
    // The width of a menu should be at most the view width. This ensures that
    // the menu does not extend past the left and right edges of the screen.
    final double width = math.min(constraints.maxWidth, buttonRect.width);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    assert(() {
      final container = Offset.zero & size;
      if (container.intersect(buttonRect) == buttonRect) {
        // If the button was entirely on-screen, then verify
        // that the menu is also on-screen.
        // If the button was a bit off-screen, then, oh well.
        assert(menuTop >= 0.0);
        assert(menuTop + menuHeight <= size.height);
      }
      return true;
    }());
    double left;
    switch (textDirection) {
      case TextDirection.rtl:
        left = buttonRect.right.clamp(0.0, size.width) - childSize.width;
        break;
      case TextDirection.ltr:
        left = buttonRect.left.clamp(0.0, size.width - childSize.width);
        break;
    }
    return Offset(left, menuTop);
  }

  @override
  bool shouldRelayout(_DropdownMenuRouteLayout<T> oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        menuTop != oldDelegate.menuTop ||
        menuHeight != oldDelegate.menuHeight ||
        textDirection != oldDelegate.textDirection;
  }
}

class _DropdownRouteResult<T> {
  const _DropdownRouteResult(this.result);

  final T result;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(dynamic other) {
    if (other is! _DropdownRouteResult<T>) {
      return false;
    }
    final typedOther = other;
    return result == typedOther.result;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => result.hashCode;
}

class _DropdownRoute<T> extends PopupRoute<_DropdownRouteResult<T>> {
  _DropdownRoute({
    required this.items,
    required this.padding,
    required this.buttonRect,
    required this.selectedIndex,
    required this.theme,
    required this.style,
    required this.barrierLabel,
    this.elevation = 8,
  });

  final List<DropdownMenuItem<T>> items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final int selectedIndex;
  final int elevation;
  final ThemeData theme;
  final TextStyle style;

  ScrollController? scrollController;

  @override
  Duration get transitionDuration => _kDropdownMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    assert(debugCheckHasDirectionality(context));
    final screenHeight = MediaQuery.of(context).size.height;
    final maxMenuHeight = screenHeight - 2.0 * _kMenuItemHeight;
    final preferredMenuHeight =
        (items.length * _kMenuItemHeight) + kMaterialListPadding.vertical;
    final double menuHeight = math.min(maxMenuHeight, preferredMenuHeight);

    final buttonTop = buttonRect.top;
    final selectedItemOffset =
        selectedIndex * _kMenuItemHeight + kMaterialListPadding.top;
    var menuTop = (buttonTop - selectedItemOffset) -
        (_kMenuItemHeight - buttonRect.height) / 2.0;
    const topPreferredLimit = _kMenuItemHeight;
    if (menuTop < topPreferredLimit) {
      menuTop = math.min(buttonTop, topPreferredLimit);
    }
    var bottom = menuTop + menuHeight;
    final bottomPreferredLimit = screenHeight - _kMenuItemHeight;
    if (bottom > bottomPreferredLimit) {
      bottom = math.max(buttonTop + _kMenuItemHeight, bottomPreferredLimit);
      menuTop = bottom - menuHeight;
    }

    if (scrollController == null) {
      var scrollOffset = 0.0;
      if (preferredMenuHeight > maxMenuHeight) {
        scrollOffset = selectedItemOffset - (buttonTop - menuTop);
      }
      scrollController = ScrollController(initialScrollOffset: scrollOffset);
    }

    final textDirection = Directionality.of(context);
    Widget menu = _DropdownMenu<T>(
      route: this,
      padding: padding.resolve(textDirection),
    );

    menu = Theme(data: theme, child: menu);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _DropdownMenuRouteLayout<T>(
              buttonRect: buttonRect,
              menuTop: menuTop,
              menuHeight: menuHeight,
              textDirection: textDirection,
            ),
            child: menu,
          );
        },
      ),
    );
  }

  void _dismiss() {
    navigator?.removeRoute(this);
  }
}

class CustomDropdownButton<T> extends StatefulWidget {
  /// Creates a dropdown button.
  ///
  /// The [elevation] and [iconSize] arguments must not be null (they both have
  /// defaults, so do not need to be specified).
  const CustomDropdownButton({
    Key? key,
    required this.items,
    this.hint,
    this.onChanged,
    this.style,
    this.elevation = 8,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.underline,
    this.value,
    this.dropdownColor,
  }) : super(key: key);

  /// The list of possible items to select among.
  final List<DropdownMenuItem<T>> items;

  /// The currently selected item, or null if no item has been selected. If
  /// value is null then the menu is popped up as if the first item was
  /// selected.
  final T? value;

  /// Displayed if [value] is null.
  final Widget? hint;

  /// Custom underline Widget, allowing you to change the default
  final Widget? underline;

  /// Called when the user selects an item.
  final ValueChanged<T>? onChanged;

  /// The z-coordinate at which to place the menu when open.
  ///
  ///
  /// Defaults to 8, the appropriate elevation for dropdown buttons.
  final int elevation;

  /// The text style to use for text in the dropdown button and the dropdown
  /// menu that appears when you tap the button.
  ///

  /// [ThemeData.textTheme] of the current [Theme].
  final TextStyle? style;

  /// The widget to use for the drop-down button's icon.
  ///
  /// Defaults to an [Icon] with the [Icons.arrow_drop_down] glyph.
  final Widget? icon;

  final Color? dropdownColor;

  /// The color of any [Icon] descendant of [icon] if this button is disabled,
  /// i.e. if [onChanged] is null.
  ///
  /// Defaults to [MaterialColor.shade400] of [Colors.grey] when the theme's
  /// [ThemeData.brightness] is [Brightness.light] and to
  /// [Colors.white10] when it is [Brightness.dark]
  final Color? iconDisabledColor;

  /// The color of any [Icon] descendant of [icon] if this button is enabled,
  /// i.e. if [onChanged] is defined.
  ///
  /// Defaults to [MaterialColor.shade700] of [Colors.grey] when the theme's
  /// [ThemeData.brightness] is [Brightness.light] and to
  /// [Colors.white70] when it is [Brightness.dark]
  final Color? iconEnabledColor;

  /// The size to use for the drop-down button's down arrow icon button.
  ///
  /// Defaults to 24.0.
  final double iconSize;

  /// Reduce the button's height.
  ///
  /// By default this button's height is the same as its menu items' heights.
  /// If isDense is true, the button's height is reduced by about half. This
  /// can be useful when the button is embedded in a container that adds
  /// its own decorations, like [InputDecorator].
  final bool isDense;

  @override
  _DropdownButtonState<T> createState() => _DropdownButtonState<T>();
}

class _DropdownButtonState<T> extends State<CustomDropdownButton<T>>
    with WidgetsBindingObserver {
  int? _selectedIndex;
  _DropdownRoute<T>? _dropdownRoute;

  @override
  void initState() {
    super.initState();

    _updateSelectedIndex();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDropdownRoute();
    super.dispose();
  }

  // Typically called because the device's orientation has changed.
  // Defined by WidgetsBindingObserver
  @override
  void didChangeMetrics() {
    _removeDropdownRoute();
  }

  void _removeDropdownRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
  }

  @override
  void didUpdateWidget(CustomDropdownButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    _selectedIndex = 0;
    for (var itemIndex = 0; itemIndex < widget.items.length; itemIndex++) {
      if (widget.items[itemIndex].value == widget.value) {
        _selectedIndex = itemIndex;
        return;
      }
    }
  }

  TextStyle get _textStyle =>
      widget.style ?? Theme.of(context).textTheme.subtitle1!;

  void _handleTap() {
    final itemBox = context.findRenderObject()! as RenderBox;
    final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;
    final textDirection = Directionality.of(context);
    final menuMargin = ButtonTheme.of(context).alignedDropdown
        ? _kAlignedMenuMargin
        : _kUnalignedMenuMargin;

    assert(_dropdownRoute == null);
    _dropdownRoute = _DropdownRoute<T>(
      items: widget.items,
      buttonRect: menuMargin.resolve(textDirection).inflateRect(itemRect),
      padding: _kMenuItemPadding.resolve(textDirection),
      selectedIndex: -1,
      elevation: widget.elevation,
      theme: Theme.of(context),
      style: _textStyle,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );

    Navigator.push(context, _dropdownRoute!)
        .then<void>((_DropdownRouteResult<T>? newValue) {
      _dropdownRoute = null;
      if (!mounted || newValue == null) {
        return;
      }
      if (widget.onChanged != null) {
        // ignore: prefer_null_aware_method_calls
        widget.onChanged!(newValue.result);
      }
    });
  }

  double get _denseButtonHeight {
    return math.max(
      _textStyle.fontSize!,
      math.max(widget.iconSize, _kDenseButtonHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    // The width of the button and the menu are defined by the widest
    // item and the width of the hint.
    final items = List<Widget>.from(widget.items);
    int? hintIndex;
    if (widget.hint != null) {
      hintIndex = items.length;
      items.add(
        DefaultTextStyle(
          style: _textStyle.copyWith(
            color: Theme.of(context).hintColor,
          ),
          child: IgnorePointer(
            ignoringSemantics: false,
            child: widget.hint,
          ),
        ),
      );
    }

    final padding = ButtonTheme.of(context).alignedDropdown
        ? _kAlignedButtonPadding
        : _kUnalignedButtonPadding;

    Widget result = DefaultTextStyle(
      style: _textStyle,
      child: Container(
        padding: padding.resolve(Directionality.of(context)),
        height: widget.isDense ? _denseButtonHeight : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // If value is null (then _selectedIndex is null) then we display
            // the hint or nothing at all.
            Expanded(
              child: IndexedStack(
                index: hintIndex ?? _selectedIndex,
                alignment: AlignmentDirectional.centerStart,
                children: items,
              ),
            ),
            IconTheme(
              data: IconThemeData(
                color: AppColors.primarySolidColor,
                size: widget.iconSize,
              ),
              child: widget.icon ?? const Icon(Icons.expand_more),
            ),
          ],
        ),
      ),
    );

    if (!DropdownButtonHideUnderline.at(context)) {
      final bottom = widget.isDense ? 0.0 : 8.0;
      result = Stack(
        children: <Widget>[
          result,
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            child: widget.underline ??
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFBDBDBD), width: 0),
                    ),
                  ),
                ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: result,
      ),
    );
  }
}
