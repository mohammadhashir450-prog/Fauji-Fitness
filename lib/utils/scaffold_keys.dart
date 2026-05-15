import 'package:flutter/material.dart';

/// Global scaffold key for the AppShell scaffold so child screens can open the
/// drawer without circular imports.
final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();
