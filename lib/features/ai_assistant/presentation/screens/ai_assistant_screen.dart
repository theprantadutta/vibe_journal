import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/features/auth/domain/models/user_model.dart';
import 'package:vibe_journal/features/premium/presentation/screens/upgrade_screen.dart';

class ChatMessage {
  final String text;
  final bool isFromUser;
  ChatMessage({required this.text, required this.isFromUser});
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  UserModel? _userModel;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isAwaitingResponse = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure BuildContext is ready for any potential
    // async gaps or navigations in the loading logic.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndInitiateChat();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndInitiateChat() async {
    // Standard robust way to get the user model
    if (locator.isRegistered<UserModel>()) {
      _userModel = locator<UserModel>();
    } else {
      // Fallback logic to re-fetch the user model if it's not in the locator
      if (kDebugMode) {
        print(
          "⚠️ UserModel not found in AiAssistantScreen. Attempting re-fetch.",
        );
      }
      final currentUserAuth = FirebaseAuth.instance.currentUser;
      if (currentUserAuth != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserAuth.uid)
            .get();
        if (userDoc.exists) {
          final model = UserModel.fromFirestore(userDoc);
          registerUserSession(model); // Re-register it so other screens have it
          _userModel = model;
        } else {
          // Critical error state: user exists in Auth but not DB. Sign out for safety.
          await FirebaseAuth.instance.signOut();
          clearUserSession();
        }
      }
    }

    // Now that the model is loaded, update the state and add the initial message
    if (mounted && _userModel != null) {
      setState(() {
        if (_userModel!.plan == 'premium' && _messages.isEmpty) {
          _messages.add(
            ChatMessage(
              text:
                  "Hi ${_userModel!.fullName?.split(" ").first ?? ''}! I'm your VibeJournal Assistant. Ask me for a journaling prompt to get started.",
              isFromUser: false,
            ),
          );
        }
      });
    }
  }

  Future<void> _callAiFunction({String? text, required String action}) async {
    if (_isAwaitingResponse) return;

    // Add user message to chat immediately if it exists
    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _messages.insert(0, ChatMessage(text: text, isFromUser: true));
        _textController.clear();
      });
    } else if (action == 'get_feedback') {
      // Don't send empty feedback requests
      return;
    }

    setState(() {
      _isAwaitingResponse = true;
    });
    _scrollToBottom();

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'aiAssistant',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'action': action,
        'text': text,
      });
      final String responseText =
          result.data['responseText'] ?? "Sorry, I couldn't process that.";
      _messages.insert(0, ChatMessage(text: responseText, isFromUser: false));
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print("Cloud Function Error: ${e.code} - ${e.message}");
      }
      _messages.insert(
        0,
        ChatMessage(
          text: "Sorry, an error occurred: ${e.message}",
          isFromUser: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Generic Error: $e");
      }
      _messages.insert(
        0,
        ChatMessage(text: "An unexpected error occurred.", isFromUser: false),
      );
    }

    if (mounted) {
      setState(() {
        _isAwaitingResponse = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Add a small delay to allow the ListView to build the new item
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isPremium = _userModel!.plan == 'premium';
    final theme = Theme.of(context);

    if (!isPremium) return _buildUpgradeScreen(theme);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              reverse: true, // Makes list start from bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatMessageBubble(message: message);
              },
            ),
          ),
          if (_isAwaitingResponse)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
              ),
            ),
          _buildTextInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildTextInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.inputFill)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primary,
              ),
              tooltip: 'Get a prompt',
              onPressed: _isAwaitingResponse
                  ? null
                  : () => _callAiFunction(action: 'get_prompt'),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ask for a prompt or paste a vibe...',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
                onSubmitted: (text) =>
                    _callAiFunction(text: text, action: 'get_feedback'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.secondary),
              onPressed: _isAwaitingResponse
                  ? null
                  : () => _callAiFunction(
                      text: _textController.text,
                      action: 'get_feedback',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeScreen(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textHint,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                "Unlock Your Personal AI Assistant",
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Get personalized journaling prompts and reflective feedback on your entries. Go Premium to access this feature.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                ),
                icon: const Icon(Icons.star_rounded),
                label: const Text("Upgrade to Premium"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: SelectableText(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser ? AppColors.onPrimary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
