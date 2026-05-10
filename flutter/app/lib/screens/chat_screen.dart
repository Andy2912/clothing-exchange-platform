import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app/session.dart';

class ChatScreen extends StatefulWidget {
  final int match_Id;

  const ChatScreen({super.key, required this.match_Id});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List messages = [];
  final TextEditingController controller = TextEditingController();
  Map<String, dynamic>? trade;
  bool isLoadingTrade = true;
  String? selectedShippingMethod;
  final String apiBaseUrl = 'http://10.0.2.2:8000';
  final List<String> shippingOptions = ['shipping', 'meetup', 'drop-off'];

  // GET messages
  Future<void> fetchMessages() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/messages/${widget.match_Id}'),
    );

    if (response.statusCode != 200) {
      print('Failed to load messages: ${response.statusCode}');
      return;
    }

    final data = jsonDecode(response.body);

    setState(() {
      messages = data;
    });
  }

  // POST message
  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final response = await http.post(
      Uri.parse('$apiBaseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "match_id": widget.match_Id,
        "sender_user_id": AppSession.userId,
        "content": text,
      }),
    );

    if (response.statusCode != 200) {
      _handleHttpError(response);
      return;
    }

    controller.clear();
    fetchMessages();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleHttpError(http.Response response) {
    final errorText = 'Error ${response.statusCode}: ${response.body}';
    print(errorText);
    _showError(errorText);
  }

  bool get isProposer => trade?['proposer_user_id'] == AppSession.userId;

  // Fetch trade for match
  Future<void> fetchTrade() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/trades/match/${widget.match_Id}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        trade = data;
        isLoadingTrade = false;
      });
    } else {
      setState(() {
        trade = null;
        isLoadingTrade = false;
      });
    }
  }

  // Propose deal with shipping method
  Future<void> proposeDeal({String? shippingMethod}) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/trades'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "match_id": widget.match_Id,
          "proposer_user_id": AppSession.userId,
          if (shippingMethod != null) "meeting_method": shippingMethod,
        }),
      );

      if (response.statusCode != 200) {
        _handleHttpError(response);
        return;
      }

      setState(() {
        selectedShippingMethod = null;
      });
      fetchTrade();
    } catch (e) {
      _showError('Error proposing deal: $e');
      print('Exception in proposeDeal: $e');
    }
  }

  // Show shipping method selection dialog
  Future<void> showShippingDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Shipping Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: shippingOptions
                .map(
                  (method) => ListTile(
                    title: Text(method),
                    onTap: () {
                      Navigator.pop(context, method);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ).then((selectedMethod) {
      if (selectedMethod != null) {
        proposeDeal(shippingMethod: selectedMethod);
      }
    });
  }

  // Cancel deal
  Future<void> cancelDeal() async {
    try {
      if (trade == null) {
        return;
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/trades/${trade!['trade_id']}/decline'),
      );

      if (response.statusCode != 200) {
        _handleHttpError(response);
        return;
      }

      fetchTrade();
    } catch (e) {
      _showError('Error cancelling deal: $e');
      print('Exception in cancelDeal: $e');
    }
  }

  // Accept deal
  Future<void> acceptDeal() async {
    try {
      if (trade == null) {
        return;
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/trades/${trade!['trade_id']}/accept'),
      );

      if (response.statusCode != 200) {
        _handleHttpError(response);
        return;
      }

      fetchTrade();
    } catch (e) {
      _showError('Error accepting deal: $e');
      print('Exception in acceptDeal: $e');
    }
  }

  // Update shipping method
  Future<void> updateShippingMethod() async {
    try {
      if (trade == null || selectedShippingMethod == null) {
        return;
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/trades/${trade!['trade_id']}/shipping'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'meeting_method': selectedShippingMethod}),
      );

      if (response.statusCode != 200) {
        _handleHttpError(response);
        return;
      }

      fetchTrade();
    } catch (e) {
      _showError('Error updating shipping: $e');
      print('Exception in updateShippingMethod: $e');
    }
  }

  // Mark item received
  Future<void> markReceived() async {
    try {
      if (trade == null) {
        return;
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/trades/${trade!['trade_id']}/received'),
      );

      if (response.statusCode != 200) {
        _handleHttpError(response);
        return;
      }

      fetchTrade();
    } catch (e) {
      _showError('Error marking received: $e');
      print('Exception in markReceived: $e');
    }
  }

  // Decline deal
  Future<void> declineDeal() async {
    try {
      if (trade == null) {
        return;
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/trades/${trade!['trade_id']}/decline'),
      );

      if (response.statusCode != 200) {
        _handleHttpError(response);
        return;
      }

      fetchTrade();
    } catch (e) {
      _showError('Error declining deal: $e');
      print('Exception in declineDeal: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMessages();
    fetchTrade();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine =
                          message['sender_user_id'] == AppSession.userId;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(messages[index]['content']),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                if (!isLoadingTrade)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (trade == null)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: showShippingDialog,
                            child: const Text("Propose Deal"),
                          )
                        else if (trade!['status'] == 'pending')
                          if (isProposer)
                            Row(
                              children: [
                                const Text(
                                  "Deal proposed, waiting for response",
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: cancelDeal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: acceptDeal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text("Accept Deal"),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: declineDeal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text("Decline"),
                                ),
                              ],
                            )
                        else if (trade!['status'] == 'agreed')
                          trade!['meeting_method'] == null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    DropdownButton<String>(
                                      value: selectedShippingMethod,
                                      dropdownColor: Colors.purple,
                                      iconEnabledColor: Colors.white,
                                      underline: Container(
                                        height: 2,
                                        color: Colors.purple,
                                      ),
                                      hint: const Text(
                                        'Choose shipping method',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      items: shippingOptions
                                          .map(
                                            (method) => DropdownMenuItem(
                                              value: method,
                                              child: Text(
                                                method,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedShippingMethod = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: updateShippingMethod,
                                      child: const Text('Set Shipping'),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Text(
                                      'Shipping via ${trade!['meeting_method']}',
                                    ),
                                    const SizedBox(height: 6),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: markReceived,
                                      child: const Text('I received it'),
                                    ),
                                  ],
                                )
                        else if (trade!['status'] == 'shipping')
                          Column(
                            children: [
                              if (trade!['meeting_method'] != null)
                                Text(
                                  'Shipping method: ${trade!['meeting_method']}',
                                ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: markReceived,
                                child: const Text('I received it'),
                              ),
                            ],
                          )
                        else if (trade!['status'] == 'completed')
                          const Text("Item received and added to history")
                        else if (trade!['status'] == 'cancelled')
                          if (isProposer)
                            Row(
                              children: [
                                const Text("Deal cancelled"),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                  ),
                                  onPressed: showShippingDialog,
                                  child: const Text("Propose Again"),
                                ),
                              ],
                            )
                          else
                            const Text("You cancelled the deal")
                        else
                          const Text("Unknown trade status"),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await sendMessage();
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
