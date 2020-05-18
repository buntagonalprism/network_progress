import 'dart:async';

import 'package:building_blocs/building_blocs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:network_progress/src/user_error_dialog.dart';

import 'user_error.dart';

/// State that describes if any network operations are in progress with a descriptive message
class ProgressState extends Equatable {
  final bool loading;
  final String message;
  final UserError userError;
  final ErrorTrace systemError;

  /// The optional [message] parameter will default to displaying 'Loading' (or translated
  /// equivalent) if no value is supplied.
  ProgressState.loading({this.message})
      : loading = true,
        userError = null,
        systemError = null;

  /// No network operations are running
  ProgressState.finished()
      : loading = false,
        message = null,
        userError = null,
        systemError = null;

  /// An error occured which the user can handle. Displays the [UserErrorDialog]
  ProgressState.userError(this.userError)
      : loading = false,
        message = null,
        systemError = null;

  /// An error occured which the user can do nothing about - something we did not
  /// expect, or a network failure etc. Runs the [systemErrorhandler] of [ProgressOverlay]
  ProgressState.systemError(this.systemError)
      : loading = false,
        message = null,
        userError = null;

  bool get hasError => userError != null || systemError != null;

  @override
  List<Object> get props => [loading, message, userError, systemError];
}

typedef SystemErrorHandler = Function(BuildContext context, ErrorTrace error);

/// Show an overlay progress spinner on top of a child widget while network operations are in
/// progress. Can prevent the user from exiting the current screen during loading.
class ProgressOverlay extends StatefulWidget {
  /// Handle any unknown errors emitted on the progress stream. The default handler shows
  /// a generic request failed dialog suggesting to check network conditions and retry.
  /// Implementations should probably log the errors to a crash-logging service like
  /// Sentry or Crashlytics.
  static SystemErrorHandler systemErrorHandler = defaultSystemErrorHandler;

  const ProgressOverlay({
    Key key,
    @required this.progress,
    @required this.child,
    this.canPopWhileLoading = false,
  });

  /// Stream of progress events to observe. When this stream has a [ProgressState.loading()] value
  /// then an overlay will be displayed over the top of [child], preventing any user interaction
  /// with the child widget. A progress spinner will also be displayed as well as a loading message.
  final DataStream<ProgressState> progress;

  /// Child widget that the progress should be overlaid on top of.
  final Widget child;

  /// Whether the user is allowed to exit, or pop back to a previous screen, while an operation is
  /// in progress. Defaults to false to allow in-flight operations to complete
  final bool canPopWhileLoading;

  @override
  _ProgressOverlayState createState() => _ProgressOverlayState();
}

class _ProgressOverlayState extends State<ProgressOverlay> {
  bool loading = false;
  StreamSubscription sub;

  @override
  void initState() {
    super.initState();
    sub = widget.progress.runAndListen((progress) {
      if (progress.loading != loading) {
        setState(() {
          loading = progress.loading;
        });
      }
      if (progress.userError != null) {
        UserErrorDialog.show(context, progress.userError);
      } else if (progress.systemError != null) {
        ProgressOverlay.systemErrorHandler(context, progress.systemError);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: DataStream.builder(
        stream: widget.progress,
        builder: (context, AsyncSnapshot<ProgressState> snapshot) {
          if (snapshot.data?.loading == true) {
            final loadingMessage = snapshot.data.message ?? 'Loading';
            return Stack(
              children: <Widget>[
                widget.child,
                Container(
                  color: Colors.black.withOpacity(0.3),
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircularProgressIndicator(),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 240),
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(loadingMessage),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Stack(
              children: <Widget>[
                widget.child,
              ],
            );
          }
        },
      ),
    );
  }

  Future<bool> onWillPop() {
    if (!widget.canPopWhileLoading && widget.progress.value?.loading == true) {
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  void dispose() {
    super.dispose();
    sub.cancel();
  }
}

void defaultSystemErrorHandler(BuildContext context, ErrorTrace error) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Request Failed'),
        content: Text('Something has gone wrong. Please check your network connection and try again.'),
        actions: [
          FlatButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
