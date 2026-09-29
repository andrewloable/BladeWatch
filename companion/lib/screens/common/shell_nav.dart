import 'package:flutter/widgets.dart';

/// Lets a page send the owner to another place in the shell -- the dashboard's "All trips"
/// (BladeWatch-rdtj.57) -- the same as tapping it in the bar or the drawer.
class ShellNav extends InheritedWidget {
  const ShellNav({super.key, required this.go, required super.child});

  /// Goes to the place with this [Destination.id].
  final void Function(String id) go;

  static ShellNav? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellNav>();

  @override
  bool updateShouldNotify(ShellNav old) => false;
}
