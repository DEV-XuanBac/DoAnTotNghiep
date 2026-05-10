import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/models/conversation_model.dart';
import 'package:hanziilearnapp/app/models/pronunciation_result.dart';
import 'package:hanziilearnapp/app/providers/post_provider.dart';
import 'package:hanziilearnapp/app/views/conversation/widgets/conversation_message_bubble.dart';
import 'package:provider/provider.dart';

class ConversationMessagesList extends StatelessWidget {
  const ConversationMessagesList({
    super.key,
    required this.chat,
    required this.step,
    required this.pron,
    required this.scroll,
    required this.onPlay,
  });

  final ConversationDialogue chat;
  final int step;
  final Map<int, PronunciationResult> pron;
  final ScrollController scroll;
  final ValueChanged<String> onPlay;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: context.read<PostProvider>().watchCurrentUserProfile(),
      builder: (context, snap) {
        final avatar = (snap.data?['avatar'] ?? '').trim();
        return ListView.builder(
          controller: scroll,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          itemCount: step + 1,
          itemBuilder: (_, i) {
            final msg = chat.messages[i];
            return ConversationMessageBubble(
              msg: msg,
              active: i == step,
              pron: pron[i],
              avatar: avatar,
              onPlay: onPlay,
            );
          },
        );
      },
    );
  }
}
