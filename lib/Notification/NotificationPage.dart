import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/Constants.dart';
import 'NotificationModel.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    loadReadStatus();
  }

  Future<void> fetchNotifications() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get token from SharedPreferences - same as your main code
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}notification'),
        headers: {
          'Authorization': 'Bearer $token',  // Token added here
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> notificationList = data['notifications'];

        setState(() {
          notifications = notificationList
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          // Sort by created date - latest first
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          isLoading = false;
        });

        await loadReadStatus();
      } else {
        setState(() {
          errorMessage = 'Failed to load notifications: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Load read status from SharedPreferences
  Future<void> loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var notification in notifications) {
        notification.isRead = prefs.getBool('notification_${notification.id}') ?? false;
      }
    });
  }

  // Save read status to SharedPreferences
  Future<void> saveReadStatus(int notificationId, bool isRead) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_$notificationId', isRead);
  }

  // Mark notification as read
  Future<void> markAsRead(NotificationModel notification) async {
    setState(() {
      notification.isRead = true;
    });
    await saveReadStatus(notification.id, true);
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    for (var notification in notifications) {
      await prefs.setBool('notification_${notification.id}', true);
    }
  }

  // Get notification icon based on type
  IconData getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'inspection':
        return Icons.notifications;
      case 'alert':
        return Icons.notifications;
      case 'reminder':
        return Icons.notifications;
      case 'irrigation':
        return Icons.notifications;
      case 'harvest':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  // Get notification color based on priority
  Color getNotificationColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return const Color(0xFF6B8E23);
    }
  }

  Future<void> updateNotificationStatus(int notificationId, String status, String remark) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Create request body
      Map<String, dynamic> requestBody = {
        'notification_id': notificationId,
        'status': status,
        'remark': remark,
      };

      // Create headers
      Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      String jsonBody = json.encode(requestBody);

      // Print all request details



      print('Headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('  $key: Bearer ${token.substring(0, 10)}...[HIDDEN]');
        } else {
          print('  $key: $value');
        }
      });
      print('');
      print('Request Body (Raw Map):');
      print('  notification_id: $notificationId (${notificationId.runtimeType})');
      print('  status: "$status" (${status.runtimeType})');
      print('  remark: "$remark" (${remark.runtimeType})');

      print('Request Body (JSON String):');
      print('  $jsonBody');
      print('');
      print('Request Body Length: ${jsonBody.length} characters');
      print('==========================================');

      final response = await http.post(
        Uri.parse('${Constanst().base_url}/update-notification'),
        headers: headers,
        body: jsonBody,
      );

      print('Status Code: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('');
      print('Response Body:');
      print('  ${response.body}');
      print('Response Body Length: ${response.body.length} characters');
      print('===========================================');

      if (response.statusCode == 200) {
        // Try to parse response JSON
        try {
          final responseData = json.decode(response.body);
          print('Parsed Response Data: $responseData');
        } catch (e) {
          print('Failed to parse response JSON: $e');
        }

        // Update the local notification status
        setState(() {
          final index = notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            print('Updating local notification status - Index: $index, Old Status: ${notifications[index].status}, New Status: $status');
            notifications[index] = NotificationModel(
              id: notifications[index].id,
              stNo: notifications[index].stNo,
              userId: notifications[index].userId,
              blockName: notifications[index].blockName,
              plotName: notifications[index].plotName,
              priority: notifications[index].priority,
              notificationType: notifications[index].notificationType,
              roll: notifications[index].roll,
              message: notifications[index].message,
              status: status, // Update status
              createdAt: notifications[index].createdAt,
              updatedAt: DateTime.now().toIso8601String(), // Update timestamp
              isRead: notifications[index].isRead,
            );
          } else {
            print('Notification with ID $notificationId not found in local list');
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully!'),

            backgroundColor: Color(0xFF6B8E23),

          ),

        );
        await fetchNotifications();

      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      print('=== UPDATE NOTIFICATION STATUS ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace:');
      print(StackTrace.current);
      print('=======================================');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }












  // Show notification popup with status update
 /* void showNotificationPopup(NotificationModel notification) {
    String selectedStatus = notification.status;
    TextEditingController remarkController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B8E23).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: getNotificationColor(notification.priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              getNotificationIcon(notification.notificationType),
                              color: getNotificationColor(notification.priority),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notification.notificationType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Block: ${notification.blockName}, Plot: ${notification.plotName}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Message
                            Text(
                              'Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),

                            // Details
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Priority',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: getNotificationColor(notification.priority).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          notification.priority,
                                          style: TextStyle(
                                            color: getNotificationColor(notification.priority),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: notification.status == 'Pending'
                                              ? Colors.orange.withOpacity(0.1)
                                              : notification.status == 'Open'
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          notification.status,
                                          style: TextStyle(
                                            color: notification.status == 'Pending'
                                                ? Colors.orange
                                                : notification.status == 'Open'
                                                ? Colors.blue
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Time
                            Text(
                              'Received: ${_formatDateTime(notification.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Status Update Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Update Status:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Radio buttons in vertical layout for better spacing
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Radio<String>(
                                            value: 'Open',
                                            groupValue: selectedStatus,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedStatus = value!;
                                              });
                                            },
                                            activeColor: const Color(0xFF6B8E23),
                                          ),
                                          const Expanded(
                                            child: Text('Open', style: TextStyle(fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Radio<String>(
                                            value: 'Pending',
                                            groupValue: selectedStatus,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedStatus = value!;
                                              });
                                            },
                                            activeColor: const Color(0xFF6B8E23),
                                          ),
                                          const Expanded(
                                            child: Text('Pending', style: TextStyle(fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Radio<String>(
                                            value: 'Resolved',
                                            groupValue: selectedStatus,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedStatus = value!;
                                              });
                                            },
                                            activeColor: const Color(0xFF6B8E23),
                                          ),
                                          const Expanded(
                                            child: Text('Resolved', style: TextStyle(fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Remark text field
                                  TextField(
                                    controller: remarkController,
                                    decoration: InputDecoration(
                                      labelText: 'Remark',
                                      hintText: 'Enter your remark here...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF6B8E23)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    maxLines: 3,
                                    minLines: 2,
                                  ),
                                  const SizedBox(height: 16),

                                  // Submit and Cancel buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: isSubmitting
                                              ? null
                                              : () async {
                                            if (remarkController.text.trim().isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Please enter a remark'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            setDialogState(() {
                                              isSubmitting = true;
                                            });

                                            await updateNotificationStatus(
                                              notification.id,
                                              selectedStatus,
                                              remarkController.text.trim(),
                                            );

                                            setDialogState(() {
                                              isSubmitting = false;
                                            });

                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6B8E23),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: isSubmitting
                                              ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                              : const Text(
                                            'Submit',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }*/

  // Replace the showNotificationPopup method with this updated version

  // Replace the showNotificationPopup method with this updated version

  void showNotificationPopup(NotificationModel notification) {
    String selectedStatus = notification.status;
    TextEditingController remarkController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B8E23).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: getNotificationColor(notification.priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              getNotificationIcon(notification.notificationType),
                              color: getNotificationColor(notification.priority),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notification.notificationType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location info
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Block: ${notification.blockName}, Plot: ${notification.plotName}',
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Message
                            Text(
                              'Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Details in wrapped row
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // Priority
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Priority: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: getNotificationColor(notification.priority).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        notification.priority,
                                        style: TextStyle(
                                          color: getNotificationColor(notification.priority),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Status
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Status: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: notification.status == 'Pending'
                                            ? Colors.orange.withOpacity(0.1)
                                            : notification.status == 'Open'
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        notification.status,
                                        style: TextStyle(
                                          color: notification.status == 'Pending'
                                              ? Colors.orange
                                              : notification.status == 'Open'
                                              ? Colors.blue
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Status Update Section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Update Status:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Horizontal Radio buttons with better overflow handling
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: 'Open',
                                              groupValue: selectedStatus,
                                              onChanged: (value) {
                                                setDialogState(() {
                                                  selectedStatus = value!;
                                                });
                                              },
                                              activeColor: const Color(0xFF6B8E23),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            const Flexible(
                                              child: Text('Open',
                                                style: TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: 'Pending',
                                              groupValue: selectedStatus,
                                              onChanged: (value) {
                                                setDialogState(() {
                                                  selectedStatus = value!;
                                                });
                                              },
                                              activeColor: const Color(0xFF6B8E23),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            const Flexible(
                                              child: Text('Pending',
                                                style: TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: 'Resolved',
                                              groupValue: selectedStatus,
                                              onChanged: (value) {
                                                setDialogState(() {
                                                  selectedStatus = value!;
                                                });
                                              },
                                              activeColor: const Color(0xFF6B8E23),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            const Flexible(
                                              child: Text('Resolved',
                                                style: TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Remark text field
                               /*   TextField(
                                    controller: remarkController,
                                    decoration: InputDecoration(
                                      labelText: 'Remark',
                                      hintText: 'Enter your remark...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Color(0xFF6B8E23)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                    maxLines: 2,
                                    minLines: 2,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),*/

                                  TextField(
                                    controller: remarkController,
                                    decoration: InputDecoration(
                                      labelText: 'Remark',
                                      hintText: 'Enter your remark...',
                                      // Default border (when not focused)
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400, // Gray color for normal state
                                          width: 1.0,
                                        ),
                                      ),
                                      // Focused border (when user clicks/focuses)
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF6B8E23), // Your green color for focus
                                          width: 2.0, // Thicker border on focus
                                        ),
                                      ),
                                      // Error border (optional)
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 1.0,
                                        ),
                                      ),
                                      // Focused error border (optional)
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 2.0,
                                        ),
                                      ),
                                      // Label style
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      // Focused label style
                                      floatingLabelStyle: const TextStyle(
                                        color: Color(0xFF6B8E23),
                                        fontSize: 14,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                    maxLines: 2,
                                    minLines: 2,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),

                                  // Submit and Cancel buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                              side: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: isSubmitting
                                              ? null
                                              : () async {
                                            if (remarkController.text.trim().isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Please enter a remark'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            setDialogState(() {
                                              isSubmitting = true;
                                            });

                                            await updateNotificationStatus(
                                              notification.id,
                                              selectedStatus,
                                              remarkController.text.trim(),
                                            );

                                            setDialogState(() {
                                              isSubmitting = false;
                                            });

                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6B8E23),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          child: isSubmitting
                                              ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                              : const Text(
                                            'Submit',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Format datetime string
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6B8E23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            onPressed: markAllAsRead,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6B8E23),
        ),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B8E23),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : notifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchNotifications,
        color: const Color(0xFF6B8E23),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await markAsRead(notification);
                  showNotificationPopup(notification);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: notification.isRead
                        ? Colors.white
                        : const Color(0xFF6B8E23).withOpacity(0.05),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: getNotificationColor(notification.priority).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          getNotificationIcon(notification.notificationType),
                          color: getNotificationColor(notification.priority),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Notification Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.notificationType,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6B8E23),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Block: ${notification.blockName}, Plot: ${notification.plotName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: getNotificationColor(notification.priority).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    notification.priority,
                                    style: TextStyle(
                                      color: getNotificationColor(notification.priority),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDateTime(notification.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


