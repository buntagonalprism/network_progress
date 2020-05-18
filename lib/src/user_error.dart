import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Describes an error that a user can acknowledge or respond to, typically emitted by blocs after an
/// asynchronous operation has completed and feedback is required from the user before proceeding.
/// Example use cases:
/// - Displaying a confirmation dialog and waiting for the user to accept before navigating
/// - Presenting a list of possible options when an error occurs, allowing them to choose how to
///   handle it.
class UserError extends Equatable {
  UserError({
    this.title,
    @required this.message,
    @required this.responses,
    this.responseIsRequired = true,
  }) ;

  /// Title to display for the request. Optional.
  final String title;

  /// A message explaining what the request relates to. Should describe the available responses.
  final String message;

  /// Choices the user can make to response
  final List<ErrorResponse> responses;

  /// Whether the user must input a response to this request - they are not allowed to navigate
  /// away without making a selection.
  final bool responseIsRequired;

  @override
  List<Object> get props => [title, message, responses, responseIsRequired];
}

/// An option that a user can select when presented with an [UserError]
class ErrorResponse extends Equatable {
  ErrorResponse(this.label, this.onSelected);

  /// Label for this response
  final String label;

  /// Callback to be invoked if the response is selected.
  final Function() onSelected;

  @override
  List<Object> get props => [label, onSelected];
}
