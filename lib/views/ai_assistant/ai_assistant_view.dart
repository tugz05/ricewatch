import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../components/widgets/shimmer_loading.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/ai_assistant_controller.dart';
import '../../models/chat_message_model.dart';
import '../../components/navigation/app_bottom_nav_bar.dart';
import '../../components/app_bar/history_app_bar_button.dart';
import '../../services/text_to_speech_service.dart';

/// Intent used so Enter triggers send in the chat input.
class _SendChatIntent extends Intent {
  const _SendChatIntent();
}

/// Stable key for a message so we only run typewriter once (no re-animate on return to page).
String _messageTypewriterKey(ChatMessageModel msg) =>
    '${msg.createdAt.millisecondsSinceEpoch}_${msg.content.length}';

/// AI Assistant chat screen: rice farming only, Cebuano/Bisaya, formatted responses.
class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  AiAssistantController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.read<AiAssistantController>();
    if (_controller != ctrl) {
      _controller?.removeListener(_onControllerUpdate);
      _controller = ctrl;
      ctrl.addListener(_onControllerUpdate);
    }
  }

  void _onControllerUpdate() {
    if (_controller != null) _scrollToBottom();
  }

  @override
  void dispose() {
    TextToSpeechService().stop();
    if (_controller != null && _controller!.messages.isNotEmpty) {
      final last = _controller!.messages.last;
      if (last.role == 'assistant') {
        _controller!.markTypewriterCompleted(_messageTypewriterKey(last));
      }
    }
    _controller?.removeListener(_onControllerUpdate);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, c),
            Expanded(child: _buildBody(context, c)),
            _buildInput(context, c),
            const AppBottomNavBarWrapper(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorSet c) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: c.header,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.accentLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco, color: c.textPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rice Farming Assistant',
                  style: TextStyle(
                    color: c.textOnDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pangutana bahin sa humay — tubag sa Binisaya',
                  style: TextStyle(
                    color: c.textOnDark.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const HistoryAppBarButton(),
          Consumer<AiAssistantController>(
            builder: (context, ctrl, _) {
              if (ctrl.messages.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _showClearConfirm(context),
                icon: Icon(Icons.delete_outline, color: c.textOnDark),
                tooltip: 'Clear chat',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    final c = context.colors;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Clear chat?', style: TextStyle(color: c.textPrimary)),
        content: Text(
          'Tangtangon ang tanang mensahe sa kini nga chat?',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: c.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              context.read<AiAssistantController>().clearChat();
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onPrimary,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppColorSet c) {
    return Consumer<AiAssistantController>(
      builder: (context, ctrl, _) {
        if (ctrl.messages.isEmpty && !ctrl.loading && ctrl.error == null) {
          return _buildEmptyState(context, ctrl, c);
        }
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: 16,
          ),
          itemCount: ctrl.messages.length + (ctrl.loading ? 1 : 0) + (ctrl.error != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < ctrl.messages.length) {
              final msg = ctrl.messages[index];
              final isLastAssistant = !ctrl.loading &&
                  index == ctrl.messages.length - 1 &&
                  msg.role == 'assistant';
              if (isLastAssistant) {
                // Typewriter only for fresh responses; DB-loaded messages show immediately.
                if (!msg.isFreshResponse) {
                  return _MessageBubble(message: msg, c: c);
                }
                final messageKey = _messageTypewriterKey(msg);
                if (ctrl.typewriterCompletedKey == messageKey) {
                  return _MessageBubble(message: msg, c: c);
                }
                return _TypewriterMessageBubble(
                  fullContent: msg.content,
                  messageKey: messageKey,
                  onComplete: () => ctrl.markTypewriterCompleted(messageKey),
                  c: c,
                );
              }
              return _MessageBubble(message: msg, c: c);
            }
            if (ctrl.loading && index == ctrl.messages.length) {
              return _LoadingBubble(c: c);
            }
            if (ctrl.error != null && index == ctrl.messages.length + (ctrl.loading ? 1 : 0)) {
              return _ErrorBubble(message: ctrl.error!, c: c);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AiAssistantController ctrl, AppColorSet c) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context) + 24,
        vertical: 48,
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.agriculture,
            size: 64,
            color: c.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Pangutana bahin sa rice farming',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pangutana bisan unsa nga may kalabotan sa humay, irigasyon, peste, ani, o best practices. Tubag sa Binisaya.',
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (!ctrl.hasApiKey) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.accentLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: c.textPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I-set ang OpenAI API key (dart-define o config) aron magamit ang assistant.',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, AppColorSet c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        12,
        Responsive.horizontalPadding(context),
        12,
      ),
      decoration: BoxDecoration(
        color: c.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<AiAssistantController>(
        builder: (context, ctrl, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Shortcuts(
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.enter): _SendChatIntent(),
                  },
                  child: Actions(
                    actions: {
                      _SendChatIntent: CallbackAction<_SendChatIntent>(
                        onInvoke: (_) {
                          if (!HardwareKeyboard.instance.isShiftPressed) {
                            _send(context);
                          }
                          return null;
                        },
                      ),
                    },
                    child: TextField(
                      controller: _inputController,
                      maxLines: 3,
                      minLines: 1,
                      enabled: !ctrl.loading && ctrl.hasApiKey,
                      style: TextStyle(color: c.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Pangutana bahin sa rice farming...',
                        hintStyle: TextStyle(
                          color: c.textMuted,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: c.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: c.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: c.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: c.accent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _send(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: c.accent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: ctrl.loading || !ctrl.hasApiKey
                      ? null
                      : () => _send(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.send_rounded, color: c.onPrimary, size: 24),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _send(BuildContext context) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    context.read<AiAssistantController>().sendMessage(text);
    _scrollToBottom();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.c});

  final ChatMessageModel message;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: c.accentLight.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco, size: 16, color: c.textPrimary),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? c.accent.withValues(alpha: 0.9)
                    : c.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: c.textPrimary,
                            ),
                            listIndent: 24.0,
                            strong: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                            blockquote: TextStyle(
                              fontSize: 14,
                              color: c.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: c.accent,
                                  width: 4,
                                ),
                              ),
                            ),
                            a: TextStyle(
                              color: c.accent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(
                              Icons.volume_up_rounded,
                              size: 20,
                              color: c.accent.withValues(alpha: 0.9),
                            ),
                            onPressed: () => TextToSpeechService().speak(message.content),
                            tooltip: 'Paminaw (Text to speech)',
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Assistant bubble that reveals text with a typewriter effect (only runs once per message).
class _TypewriterMessageBubble extends StatefulWidget {
  const _TypewriterMessageBubble({
    required this.fullContent,
    required this.messageKey,
    required this.onComplete,
    required this.c,
  });

  final String fullContent;
  final String messageKey;
  final VoidCallback onComplete;
  final AppColorSet c;

  @override
  State<_TypewriterMessageBubble> createState() => _TypewriterMessageBubbleState();
}

class _TypewriterMessageBubbleState extends State<_TypewriterMessageBubble> {
  int _visibleLength = 0;
  bool _completedNotified = false;
  static const int _charsPerTick = 2;
  static const Duration _tickDuration = Duration(milliseconds: 35);

  @override
  void initState() {
    super.initState();
    if (widget.fullContent.isEmpty) {
      widget.onComplete();
      return;
    }
    Future.doWhile(() async {
      await Future.delayed(_tickDuration);
      if (!mounted) return false;
      setState(() {
        _visibleLength = (_visibleLength + _charsPerTick).clamp(0, widget.fullContent.length);
      });
      if (_visibleLength >= widget.fullContent.length && !_completedNotified) {
        _completedNotified = true;
        widget.onComplete();
      }
      return _visibleLength < widget.fullContent.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final content = widget.fullContent.isEmpty
        ? ''
        : widget.fullContent.substring(0, _visibleLength);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.accentLight.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, size: 16, color: c.textPrimary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MarkdownBody(
                    data: content.isEmpty ? ' ' : content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: c.textPrimary,
                      ),
                      listIndent: 24.0,
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                      blockquote: TextStyle(
                        fontSize: 14,
                        color: c.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: c.accent,
                            width: 4,
                          ),
                        ),
                      ),
                      a: TextStyle(
                        color: c.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (widget.fullContent.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: 20,
                          color: c.accent.withValues(alpha: 0.9),
                        ),
                        onPressed: () => TextToSpeechService().speak(widget.fullContent),
                        tooltip: 'Paminaw (Text to speech)',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton matching assistant message bubble: avatar + bubble with text lines.
class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble({required this.c});
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.accentLight.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, size: 16, color: c.textPrimary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ShimmerLoading(
                baseColor: c.primaryContainer.withValues(alpha: 0.6),
                highlightColor: c.textPrimary.withValues(alpha: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShimmerLine(width: 220, c: c),
                    const SizedBox(height: 8),
                    _ShimmerLine(width: 180, c: c),
                    const SizedBox(height: 8),
                    _ShimmerLine(width: 140, c: c),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.width, required this.c});

  final double width;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: c.primaryContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message, required this.c});

  final String message;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 20, color: c.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: c.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
