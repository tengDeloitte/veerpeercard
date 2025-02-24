import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veerpeercard/services/chat_service.dart';


final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});