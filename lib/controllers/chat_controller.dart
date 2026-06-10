import 'dart:async';
import 'package:get/get.dart';
import 'package:llamadart/llamadart.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/llm_service.dart';
import '../services/chat_storage_service.dart';
import '../services/wakelock_service.dart';

class ChatController extends GetxController {
  final LlmService _llm = Get.find<LlmService>();
  final ChatStorageService _storage = Get.find<ChatStorageService>();
  final WakelockService _wakelock = Get.find<WakelockService>();

  final chats = <ChatModel>[].obs;
  final activeChatId = RxnString();
  final isGenerating = false.obs;
  final streamedResponse = ''.obs;
  final temperature = 0.7.obs;
  final systemPrompt = ''.obs;
  final contextSizeSetting = 2048.obs;
  final contextUsage = 0.0.obs;

  StreamSubscription<String>? _genSub;

  static const _maxResponseTokens = 512;

  @override
  void onInit() {
    super.onInit();
    _loadChats();
    temperature.value = _storage.defaultTemperature;
    systemPrompt.value = _storage.globalSystemPrompt;
    contextSizeSetting.value = _storage.contextSize;
  }

  void _loadChats() {
    chats.value = _storage.getAllChats();
  }

  ChatModel? get activeChat {
    if (activeChatId.value == null) return null;
    try {
      return chats.firstWhere((c) => c.id == activeChatId.value);
    } catch (_) {
      return null;
    }
  }

  /// Create a new chat and switch to it.
  void newChat() {
    final chat = ChatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      systemPrompt: systemPrompt.value,
    );
    chats.insert(0, chat);
    _storage.saveChat(chat);
    activeChatId.value = chat.id;
  }

  /// Switch to an existing chat.
  void switchChat(String id) {
    activeChatId.value = id;
    final chat = activeChat;
    if (chat != null) {
      systemPrompt.value = chat.systemPrompt;
    }
  }

  /// Delete a chat.
  void deleteChat(String id) {
    chats.removeWhere((c) => c.id == id);
    _storage.deleteChat(id);
    if (activeChatId.value == id) {
      activeChatId.value = chats.isNotEmpty ? chats.first.id : null;
    }
  }

  List<LlamaChatMessage> _buildLlamaMessages(
    List<MessageModel> messages,
    String prompt,
  ) {
    final result = <LlamaChatMessage>[];

    if (prompt.isNotEmpty) {
      result.add(
        LlamaChatMessage.fromText(role: LlamaChatRole.system, text: prompt),
      );
    }

    for (final msg in messages.where((m) => !m.isSystem)) {
      final role = switch (msg.role) {
        MessageRole.user => LlamaChatRole.user,
        MessageRole.assistant => LlamaChatRole.assistant,
        MessageRole.system => LlamaChatRole.system,
      };
      if (msg.content.isEmpty) continue;
      result.add(LlamaChatMessage.fromText(role: role, text: msg.content));
    }

    return result;
  }

  /// Send a user message and stream AI response.
  Future<void> sendMessage(String text, {String? modelFilename}) async {
    if (text.trim().isEmpty) return;
    if (!_llm.isLoaded.value) {
      Get.snackbar(
        'No Model Loaded',
        'Load a model from the Models tab before chatting.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final chat = activeChat;
    if (chat == null) return;

    // Add user message
    final userMsg = MessageModel(role: MessageRole.user, content: text.trim());
    chat.messages.add(userMsg);
    chat.autoTitle();
    chat.updatedAt = DateTime.now();

    // Track which model this chat started with (informational only).
    if (chat.modelId.isEmpty && modelFilename != null) {
      chat.modelId = modelFilename;
    }

    _storage.saveChat(chat);
    chats.refresh();

    final effectivePrompt = chat.systemPrompt.isNotEmpty
        ? chat.systemPrompt
        : systemPrompt.value;

    // Build and trim history to fit the context window.
    final historyWithoutLatest = chat.messages
        .where((m) => !m.isSystem && m != userMsg)
        .toList();
    var llamaMessages = _buildLlamaMessages(historyWithoutLatest, effectivePrompt);
    llamaMessages = await _llm.trimMessagesForContext(
      messages: llamaMessages,
      reservedForResponse: _maxResponseTokens,
    );
    llamaMessages.add(
      LlamaChatMessage.fromText(role: LlamaChatRole.user, text: userMsg.content),
    );

    final usedTokens = await _estimateMessageTokens(llamaMessages);
    contextUsage.value = usedTokens / _llm.loadedContextSize.value;

    // Start generation
    isGenerating.value = true;
    streamedResponse.value = '';

    await _wakelock.enableForGeneration(
      modelName: _llm.loadedModelFilename.isNotEmpty
          ? _llm.loadedModelFilename
          : 'AI model',
    );

    final aiMsg = MessageModel(role: MessageRole.assistant, content: '');
    chat.messages.add(aiMsg);
    chats.refresh();

    final params = GenerationParams(
      temp: temperature.value,
      maxTokens: _maxResponseTokens,
      penalty: 1.0,
      topP: 0.95,
      minP: 0.05,
    );

    try {
      final stream = _llm.generateChatCompletion(
        messages: llamaMessages,
        params: params,
      );

      await for (final token in stream) {
        streamedResponse.value += token;
        aiMsg.content = streamedResponse.value;
        chats.refresh();
      }
    } catch (e) {
      if (aiMsg.content.isEmpty) {
        final err = e.toString().toLowerCase();
        if (err.contains('context') || err.contains('token')) {
          aiMsg.content =
              '⚠ Context window full. Start a new chat or reduce the system prompt in Settings.';
        } else {
          aiMsg.content = '⚠ Error: ${e.toString()}';
        }
      }
    } finally {
      aiMsg.content = aiMsg.content.trim();
      isGenerating.value = false;
      streamedResponse.value = '';
      chat.updatedAt = DateTime.now();
      _storage.saveChat(chat);
      chats.refresh();

      if (_llm.isLoaded.value) {
        await _wakelock.finishGeneration(
          modelName: _llm.loadedModelFilename.isNotEmpty
              ? _llm.loadedModelFilename
              : 'AI model',
        );
      }
    }
  }

  Future<int> _estimateMessageTokens(List<LlamaChatMessage> messages) async {
    var total = 0;
    for (final msg in messages) {
      final tokens = await _llm.countTokens(msg.content);
      total += tokens > 0 ? tokens : (msg.content.length / 4).ceil();
    }
    return total;
  }

  /// Stop current generation.
  void stopGeneration() {
    _llm.stopGeneration();
    isGenerating.value = false;
  }

  /// Update the system prompt for the active chat.
  void updateSystemPrompt(String prompt) {
    systemPrompt.value = prompt;
    final chat = activeChat;
    if (chat != null) {
      chat.systemPrompt = prompt;
      _storage.saveChat(chat);
    }
  }

  /// Set and persist the global system prompt.
  void setGlobalSystemPrompt(String prompt) {
    systemPrompt.value = prompt;
    _storage.globalSystemPrompt = prompt;
  }

  /// Clear global system prompt.
  void clearGlobalSystemPrompt() {
    systemPrompt.value = '';
    _storage.globalSystemPrompt = '';
  }

  void updateTemperature(double temp) {
    temperature.value = temp;
    _storage.defaultTemperature = temp;
  }

  void updateContextSize(int size) {
    contextSizeSetting.value = size;
    _storage.contextSize = size;
  }

  @override
  void onClose() {
    _genSub?.cancel();
    super.onClose();
  }
}