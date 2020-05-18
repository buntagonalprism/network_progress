import 'package:flutter/material.dart';
import 'package:network_progress/src/user_error.dart';

/// Dialog for capturing a response from a user.
class UserErrorDialog extends StatelessWidget {
  static show(BuildContext context, UserError request) {
    showDialog(
      context: context,
      builder: (ctx) => UserErrorDialog._(request: request),
      barrierDismissible: !request.responseIsRequired,
    );
  }

  final UserError request;

  const UserErrorDialog._({Key key, this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: allowPop,
      child: AlertDialog(
        title: request.title != null ? Text(request.title) : null,
        content: Text(request.message),
        actions: request.responses.map((response) {
          return FlatButton(
            child: Text(response.label.toUpperCase()),
            onPressed: () {
              Navigator.of(context).pop();
              response.onSelected();
            },
          );
        }).toList(),
      ),
    );
  }

  Future<bool> allowPop() {
    return Future.value(!request.responseIsRequired);
  }
}
