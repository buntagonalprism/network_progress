import 'dart:async';

import 'package:flutter/material.dart';

class _DialogRoute<T> extends PopupRoute<T> {
  _DialogRoute({
    @required this.progress,
    @required this.theme,
    bool barrierDismissible: true,
    this.barrierLabel,
    @required this.child,
    RouteSettings settings,
  })  : assert(barrierDismissible != null),
        _barrierDismissible = barrierDismissible,
        super(settings: settings);

  final Widget child;
  final ThemeData theme;
  final ProgressDialog progress;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  Color get barrierColor => Colors.black54;

  @override
  final String barrierLabel;

  @override
  bool didPop(T result) {
    progress.isShowing = false;
    return super.didPop(result);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return new SafeArea(
      child: new Builder(builder: (BuildContext context) {
        final Widget annotatedChild = new Semantics(
          child: child,
          scopesRoute: true,
          explicitChildNodes: true,
        );
        return theme != null
            ? new Theme(data: theme, child: annotatedChild)
            : annotatedChild;
      }),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return new FadeTransition(
        opacity: new CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child);
  }
}

/// Displays a dialog above the current contents of the app.
///
/// This function takes a `builder` which typically builds a [Dialog] widget.
/// Content below the dialog is dimmed with a [ModalBarrier]. This widget does
/// not share a context with the location that `showDialog` is originally
/// called from. Use a [StatefulBuilder] or a custom [StatefulWidget] if the
/// dialog needs to update dynamically.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the dialog. It is only used when the method is called. Its corresponding
/// widget can be safely removed from the tree before the dialog is closed.
///
/// The `child` argument is deprecated, and should be replaced with `builder`.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the dialog was closed.
///
/// The dialog route created by this method is pushed to the root navigator.
/// If the application has multiple [Navigator] objects, it may be necessary to
/// call `Navigator.of(context, rootNavigator: true).pop(result)` to close the
/// dialog rather just 'Navigator.pop(context, result)`.
///
/// See also:
///  * [AlertDialog], for dialogs that have a row of buttons below a body.
///  * [SimpleDialog], which handles the scrolling of the contents and does
///    not show buttons below its body.
///  * [Dialog], on which [SimpleDialog] and [AlertDialog] are based.
///  * <https://material.google.com/components/dialogs.html>
PopupRoute<T> getDialogRoute<T>({
  @required ProgressDialog progress,
  @required
      BuildContext context,
  bool barrierDismissible: true,
  @Deprecated(
      'Instead of using the "child" argument, return the child from a closure '
      'provided to the "builder" argument. This will ensure that the BuildContext '
      'is appropriate for widgets built in the dialog.')
      Widget child,
  WidgetBuilder builder,
}) {
  assert(child == null || builder == null);
  return new _DialogRoute<T>(
    progress: progress,
    child: child ?? new Builder(builder: builder),
    theme: Theme.of(context, shadowThemeOnly: true),
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  );
}



class ProgressDialog {
  PopupRoute dialogRoute;
  bool isShowing = false;
  void show(BuildContext context, String message) {
    if (dialogRoute == null || !isShowing) {
      dialogRoute = getDialogRoute(
        barrierDismissible: false,
        progress: this,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: <Widget>[
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(message ?? ''),
                  )
                ],
              ),
            );
          });

      // Error could occur if observeProgress was called during initState, where
      // context was not yet ready
      try {
        Navigator.of(context).push(dialogRoute);
        isShowing = true;
      } catch (e) {
        dialogRoute = null;
        isShowing = false;
      }
    }
  }

  /// Await this call to be certain that the dialog is hidden before pushing
  /// other routes
  Future hide(BuildContext context) async {
    if (dialogRoute != null && isShowing) {
      Navigator.pop(context);
      await dialogRoute.popped;
      dialogRoute = null;
      isShowing = false;
    }
    if (isShowing) {
      dialogRoute = null;
      isShowing= false;
    }
  }
  

}
