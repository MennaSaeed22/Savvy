import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../globals.dart';
import '../../widgets/header_clipper.dart';
import '../../providers/app_provider.dart';

// Message class definition
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Widget? customWidget;
  final bool isTransactionCard;
  
  Message({
    required this.text, 
    required this.isUser, 
    required this.timestamp,
    this.customWidget,
    this.isTransactionCard = false,
  });
}

// Chat Notifier for managing messages
class ChatNotifier extends StateNotifier<List<Message>> {
  ChatNotifier() : super([
    Message(
      text: "💡 Tip: You can switch between getting insights from Savvy or managing your transactions using the toggle above.",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  void addMessage(Message message) {
    state = [...state, message];
  }

  void clearMessages() {
    state = [
      Message(
        text: "💡 Tip: You can switch between getting insights from Savvy or managing your transactions using the toggle above.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

// Provider declaration
final chatProvider = StateNotifierProvider<ChatNotifier, List<Message>>((ref) {
  return ChatNotifier();
});

class ChatbotScreen extends ConsumerStatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isBotTyping = false;
  bool _showScrollButton = false;
  String _mode = "Ask Savvy";
  bool _userHasScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final atBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 100;
      if (!atBottom) _userHasScrolled = true;
      setState(() => _showScrollButton = _userHasScrolled && !atBottom);
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isBotTyping) return;
    
    final message = Message(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    // Add message using the provider
    ref.read(chatProvider.notifier).addMessage(message);
    
    setState(() {
      _isBotTyping = true;
    });
    _controller.clear();
    _scrollToBottom();
    _handleBotResponse(text);
    _focusNode.requestFocus();
  }

  Future<void> _handleBotResponse(String userMessage) async {
    final currentMode = _mode;
    String botText;
    try {
      final userResponse = await Supabase.instance.client.auth.getUser();
      final userId = userResponse.user?.id;
      if (userId == null) {
        throw Exception("User ID not found");
      }
      if (currentMode == "Ask Savvy") {
        botText = await fetchInsightResponse(userId, userMessage);
      } else {
        botText = await fetchTransactionResponse(userId, userMessage);
      }
    } catch (e) {
      botText = "Error: Unable to fetch response. Please try again later.";
    }
    
    final botMessage = Message(
      text: botText, 
      isUser: false, 
      timestamp: DateTime.now()
    );
    
    // Add bot message using the provider
    ref.read(chatProvider.notifier).addMessage(botMessage);
    
    setState(() {
      _isBotTyping = false;
    });
    if (!_userHasScrolled) _scrollToBottom();
  }

  // First API call to get insights
  Future<String> fetchInsightResponse(String userId, String userMessage) async {
    final response = await http.post(
      Uri.parse('$baseURL/api/v1/chat/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'message': userMessage}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['response'];
    } else {
      throw Exception('Insight API Error: ${response.statusCode}');
    }
  }

  // Updated method to fetch category using your TransactionNotifier
  Future<Map<String, dynamic>?> fetchCategoryFromProvider(String categoryId) async {
    try {
      ref.read(transactionProvider.notifier);
      
      // Use Supabase directly to fetch category info (same pattern as your TransactionNotifier)
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('categories')
          .select('category_id, category_name')
          .eq('category_id', categoryId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching category from provider: $e');
      return null;
    }
  }

  // Get icon based on category name
  IconData getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Food':
        return Icons.restaurant;
      case 'Fashion':
        return Icons.checkroom;
      case 'Health':
        return Icons.health_and_safety;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Lifestyle':
        return Icons.emoji_people;
      case 'Education':
        return Icons.school;
      case 'Salary':
        return Icons.business_center;
      case 'Freelance':
        return Icons.computer;
      case 'Investments':
        return Icons.trending_up;
      case 'Bonus':
        return Icons.star;
      case 'Refunds':
        return Icons.request_quote;
      default:
        return Icons.category;
    }
  }

  // Create transaction card widget
  Widget createTransactionCard(Map<String, dynamic> transaction) {
    final category = transaction['categories']?['category_name'] ?? 'Uncategorized';
    final isIncome = transaction['transaction_type']?.toLowerCase() == 'income';
    final amount = transaction['amount'];
    final description = transaction['description'] ?? '';
    final date = DateFormat('MMMM d, yyyy h:mm a')
        .format(DateTime.parse(transaction['created_at']));
    final typeText = isIncome ? "Income" : "Expense";
    final categoryIcon = getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIncome ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon,
                  color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeText,
                      style: TextStyle(
                        fontSize: 14,
                        color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${amount.toStringAsFixed(2)} EGP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String> fetchTransactionResponse(String userId, String userMessage) async {
    final response = await http.post(
      Uri.parse('$baseURL/api/v1/transactions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'input_text': userMessage,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Fetch category information using your provider pattern
      if (data['category_id'] != null) {
        final categoryInfo = await fetchCategoryFromProvider(data['category_id']);
        if (categoryInfo != null) {
          data['categories'] = categoryInfo;
        } else {
          // Fallback for unknown category
          data['categories'] = {
            'category_id': data['category_id'],
            'category_name': 'Unknown'
          };
        }
      } else {
        data['categories'] = null;
      }
      
      // Add transaction card message using provider
      final transactionCard = Message(
        text: '', 
        isUser: false, 
        timestamp: DateTime.now(),
        customWidget: createTransactionCard(data),
        isTransactionCard: true,
      );
      
      ref.read(chatProvider.notifier).addMessage(transactionCard);
      
      // Refresh the transaction provider to get the latest data
      await ref.read(transactionProvider.notifier).fetchTransactions();
      
      // Return feedback message
      return data['feedback'] ?? 'Transaction recorded successfully!';
    } else {
      throw Exception('Transaction API Error: ${response.statusCode}');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        _userHasScrolled = false;
        if (_showScrollButton) {
          setState(() => _showScrollButton = false);
        }
      }
    });
  }

  Widget _buildMessage(Message message) {
    // If it's a transaction card, return the custom widget
    if (message.isTransactionCard && message.customWidget != null) {
      return message.customWidget!;
    }
    
    // Regular message bubble
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? softBlue : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageWithDate(int index, List<Message> messages) {
    final message = messages[index];
    bool showDate = false;
    if (message.isUser &&
        !messages.sublist(0, index).any((m) => m.isUser)) {
      showDate = true;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDate)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Center(
              child: Text(
                _formatDate(message.timestamp),
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        _buildMessage(message),
        // Only show timestamp for regular messages, not transaction cards
        if (!message.isTransactionCard)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment:
                  message.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return "Today";
    } else {
      return DateFormat.yMMMMd().format(dateTime);
    }
  }

  // Optional: Add method to clear chat
  void _clearChat() {
    ref.read(chatProvider.notifier).clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the chat messages from the provider
    final messages = ref.watch(chatProvider);
    
    return Scaffold(
      backgroundColor: OffWhite,
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  ClipPath(
                    clipper: AppBarClipper(),
                    child: Container(
                      height: 150,
                      color: primaryColor,
                      alignment: Alignment.center,
                      child: ToggleButtons(
                        borderRadius: BorderRadius.circular(20),
                        selectedColor: primaryColor,
                        color: Colors.white70,
                        fillColor: Colors.white,
                        selectedBorderColor: Colors.white,
                        borderColor: Colors.white70,
                        splashColor: Colors.transparent,
                        constraints: BoxConstraints.expand(
                          width: (MediaQuery.of(context).size.width - 80) / 2.3,
                          height: 40,
                        ),
                        isSelected: [
                          _mode == "Ask Savvy",
                          _mode == "Transactions"
                        ],
                        onPressed: _isBotTyping
                            ? null
                            : (index) {
                                setState(() {
                                  _mode =
                                      index == 0 ? "Ask Savvy" : "Transactions";
                                });
                              },
                        children: const [
                          Text('Ask Savvy',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Transactions',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 5,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: OffWhite, size: 25),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  // Optional: Add clear chat button
                  Positioned(
                    top: 50,
                    right: 5,
                    child: IconButton(
                      icon: const Icon(Icons.clear_all,
                          color: OffWhite, size: 25),
                      onPressed: _clearChat,
                      tooltip: 'Clear Chat',
                    ),
                  ),
                ],
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length, // Use messages from provider
                    itemBuilder: (context, index) =>
                        _buildMessageWithDate(index, messages), // Pass messages
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: _sendMessage,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          maxLines: 3,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send_rounded),
                        color: primaryColor,
                        onPressed: _isBotTyping
                            ? null
                            : () => _sendMessage(_controller.text),
                        iconSize: 20,
                        padding: EdgeInsets.only(right: 8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showScrollButton && !_isBotTyping)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: _scrollToBottom,
                backgroundColor: primaryColor,
                child: Icon(Icons.arrow_downward, color: OffWhite, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}