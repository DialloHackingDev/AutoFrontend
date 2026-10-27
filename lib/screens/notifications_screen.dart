import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../core/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllAsRead,
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: provider.isLoading && provider.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.fetchNotifications,
              child: provider.notifications.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Center(child: Text('Aucune notification pour le moment.')),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Vos réservations, paiements et trajets apparaîtront ici.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: provider.notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = provider.notifications[index];
                        final style = _styleFor(notification.type);
                        return ListTile(
                          tileColor: notification.isRead ? null : AppColors.primarySoft,
                          leading: CircleAvatar(
                            backgroundColor: style.color.withValues(alpha: 0.12),
                            child: Icon(style.icon, color: style.color),
                          ),
                          title: Text(
                            notification.titre,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(notification.message),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatDate(notification.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (!notification.isRead)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                          onTap: () => provider.markAsRead(notification.id),
                        );
                      },
                    ),
            ),
    );
  }

  ({IconData icon, Color color}) _styleFor(String type) {
    if (type.startsWith('PAYMENT')) return (icon: Icons.payments, color: AppColors.successDark);
    if (type.startsWith('WITHDRAWAL')) return (icon: Icons.account_balance_wallet, color: AppColors.successDark);
    if (type.startsWith('DISPUTE')) return (icon: Icons.gavel, color: AppColors.warning);
    if (type.contains('CANCELLED') || type == 'DRIVER_UNVERIFIED') {
      return (icon: Icons.cancel, color: AppColors.danger);
    }
    if (type.startsWith('TRIP') || type == 'PASSENGER_BOARDING') {
      return (icon: Icons.directions_car, color: AppColors.primary);
    }
    if (type == 'DRIVER_VERIFIED' || type == 'ACCOUNT_REACTIVATED') {
      return (icon: Icons.verified, color: AppColors.successDark);
    }
    if (type.startsWith('BOOKING') || type.startsWith('RESERVATION')) {
      return (icon: Icons.event_seat, color: AppColors.primary);
    }
    return (icon: Icons.notifications, color: AppColors.primary);
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'À l’instant';
    if (difference.inHours < 1) return 'il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Cloche de l'AppBar avec le nombre de notifications non lues.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    return IconButton(
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications),
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
    );
  }
}
