import "package:u/utilities.dart";

class UChat extends StatefulWidget {
  const UChat({
    required this.messages,
    required this.outgoingUserId,
    super.key,
    this.composer,
    this.actionButton,
    this.headerBuilder,
    this.footerBuilder,
    this.avatarBuilder,
    this.messageBuilder,
    this.emptyBuilder,
    this.onMessageSent,
    this.loadingIndicator,
    this.errorIndicator,
    this.showLoading = false,
    this.constraints,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor,
  });

  final List<ChatMessage> messages;
  final String outgoingUserId;
  final ChatComposer? composer;
  final ChatActionButton? actionButton;
  final ChatWidgetBuilder? headerBuilder;
  final ChatWidgetBuilder? footerBuilder;
  final ChatWidgetBuilder? avatarBuilder;
  final ChatWidgetBuilder? messageBuilder;
  final WidgetBuilder? emptyBuilder;
  final void Function(String)? onMessageSent;
  final Widget? loadingIndicator;
  final Widget? errorIndicator;
  final bool showLoading;
  final BoxConstraints? constraints;
  final EdgeInsets padding;
  final Color? backgroundColor;

  @override
  State<UChat> createState() => _UChatState();
}

class _UChatState extends State<UChat> {
  final bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) => Container(
    padding: widget.padding,
    constraints: widget.constraints,
    color: widget.backgroundColor,
    child: Stack(
      children: <Widget>[
        if (_hasError && widget.errorIndicator != null)
          widget.errorIndicator!
        else if (_hasError)
          Center(
            child: Text(
              _errorMessage ?? "Chat error occurred",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          )
        else
          SfChat(
            messages: widget.messages,
            outgoingUser: widget.outgoingUserId,
            composer: widget.composer,
            actionButton:
                widget.actionButton ??
                (widget.onMessageSent != null
                    ? ChatActionButton(
                        onPressed: (String message) {
                          try {
                            widget.onMessageSent!(message);
                            setState(() {
                              widget.messages.add(
                                ChatMessage(
                                  text: message,
                                  time: DateTime.now(),
                                  author: ChatAuthor(id: widget.outgoingUserId, name: "You"),
                                ),
                              );
                            });
                          } catch (e) {
                            setState(() {
                              _hasError = true;
                              _errorMessage = "Failed to send message: $e";
                            });
                            if (context.mounted) {
                              UToast.snackBar(message: _errorMessage ?? "Message send failed");
                            }
                          }
                        },
                      )
                    : null),
            messageHeaderBuilder: widget.headerBuilder,
            messageFooterBuilder: widget.footerBuilder,
            messageAvatarBuilder: widget.avatarBuilder,
            messageContentBuilder: widget.messageBuilder,
            placeholderBuilder: widget.emptyBuilder,
          ),
        if (widget.showLoading && _isLoading && !_hasError) widget.loadingIndicator ?? const Center(child: CircularProgressIndicator()),
      ],
    ),
  );
}
