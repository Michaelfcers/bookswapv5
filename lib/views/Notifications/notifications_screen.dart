import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';
import 'trade_proposal_dialog.dart';
import '../../services/user_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  List<Map<String, dynamic>> notifications = [];
  late RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupRealtimeListener();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('read', ascending: true)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
      });

      debugPrint('Notificaciones obtenidas: $notifications');
    } catch (e) {
      debugPrint('Error al obtener notificaciones: $e');
    }
  }

  void _setupRealtimeListener() {
    _realtimeChannel = _supabase.channel('public:notifications');

    _realtimeChannel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: 'user_id=eq.${_supabase.auth.currentUser!.id}',
      ),
      (payload, [ref]) {
        final newNotification = payload['new'] as Map<String, dynamic>;
        if (!mounted) return;

        setState(() {
          notifications.insert(0, newNotification);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nueva notificación: ${newNotification['content']}'),
          ),
        );
      },
    );

    _realtimeChannel.subscribe();
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);

      if (!mounted) return;

      setState(() {
        final index =
            notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          notifications[index]['read'] = true;
        }
      });

      debugPrint('Notificación marcada como leída: $notificationId');
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
    }
  }

  Future<void> _openTradeProposalDialog(Map<String, dynamic> notification) async {
    debugPrint('Intentando abrir el diálogo para la notificación: $notification');

    if (notification['barter_id'] == null) {
      debugPrint('El barter_id es nulo o no válido.');
      _showErrorDialog(context, 'No se pudo cargar los detalles del trueque.');
      return;
    }

    try {
      final tradeDetails = await _userService.fetchTradeDetails(notification['id']);
      debugPrint('Detalles obtenidos: $tradeDetails');

      if (!mounted) return;

      final books = List<Map<String, dynamic>>.from(tradeDetails['books']);
      final barterStatus = tradeDetails['barter']['status'];

      showDialog(
        context: context,
        builder: (context) => TradeProposalDialog(
          proposerNickname: tradeDetails['proposer']['nickname'],
          proposerName: tradeDetails['proposer']['name'],
          barterId: tradeDetails['barter']['id'],
          books: books,
          status: barterStatus,
        ),
      );
    } catch (e) {
      debugPrint('Error al abrir el diálogo: $e');
      _showErrorDialog(context, 'No se pudo abrir la propuesta.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'trade_request':
        return Icons.mail;
      case 'trade_accepted':
        return Icons.thumb_up;
      case 'trade_rejected':
        return Icons.thumb_down;
      default:
        return Icons.notifications;
    }
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'trade_request':
        return 'Nueva solicitud de trueque';
      case 'trade_accepted':
        return 'Tu trueque ha sido aceptado';
      case 'trade_rejected':
        return 'Tu trueque ha sido rechazado';
      default:
        return 'Notificación';
    }
  }

  @override
  void dispose() {
    _supabase.removeChannel(_realtimeChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Notificaciones",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                "No tienes notificaciones",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationCard(
                  icon: _getIconForType(notification['type']),
                  title: _getTitleForType(notification['type']),
                  subtitle: notification['content'] ?? '',
                  isRead: notification['read'],
                  onTap: () {
                    debugPrint('Notificación seleccionada: $notification');
                    if (!notification['read']) {
                      _markAsRead(notification['id']);
                    }
                    if (notification['type'] == 'trade_request') {
                      _openTradeProposalDialog(notification);
                    }
                  },
                );
              },
            ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isRead;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Si la notificación está leída, usamos line-through y un color más apagado.
    final titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: isRead ? Colors.black54 : Colors.black,
      decoration: isRead ? TextDecoration.lineThrough : null,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isRead ? AppColors.divider : AppColors.primary,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isRead ? AppColors.textSecondary : AppColors.iconSelected,
          size: 30,
        ),
        title: Text(title, style: titleStyle),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
