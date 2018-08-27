library network_progress;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:network_progress/progress_dialog.dart';

typedef ActionBuilder<T> = Future<T> Function();

/// Performs an action returning a future, optionally showing a progress dialog
/// while the future is executing. If the future returns an error, a dialog is
/// shown offering the option to retry the action, or to cancel. If the future
/// completes, the value is passed to a handler.
/// May also optionally supply callbacks to be notified before and after the
/// future completes, allowing for custom progress indicators to be updated
void showRetryOnError<T>({@required BuildContext context,
  @required ActionBuilder<T> builder,
  @required Function(T) handler,
  String loadingMessage = "Loading",
  String failedTitle = "Request Failed",
  String failedMessage = "Check your network connection and try again",
  String cancelAction = "Cancel",
  String okAction = "Ok",
  bool showProgress = true,
  VoidCallback before,
  VoidCallback after,
}) async {
  ProgressDialog pd = ProgressDialog();
  bool doRetry = false;
  do {
    try {
      if (showProgress) {
        pd.show(context, loadingMessage);
      }

      if (before != null) {
        before();
      }

      T result = await builder();
      await pd.hide(context);
      if (after != null) {
        after();
      }
      doRetry = false;
      handler(result);
    } catch (e) {
      if (after != null) {
        after();
      }
      await pd.hide(context);
      doRetry = await showDialog(
          context: context,
          builder: (innerContext) =>
              AlertDialog(
                title: Text(failedTitle),
                content: Text(failedMessage),
                actions: <Widget>[
                  FlatButton(
                    child: Text(cancelAction.toUpperCase()),
                    onPressed: () => Navigator.of(innerContext).pop(false),
                  ),
                  FlatButton(
                    child: Text(okAction.toUpperCase()),
                    onPressed: () => Navigator.of(innerContext).pop(true),
                  )
                ],
              )
      );
    }
  } while (doRetry);
}