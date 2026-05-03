import 'package:flutter/material.dart';

import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../widgets/app_vector_icons.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.appState,
    required this.onGoToAccount,
  });

  final AppState appState;
  final VoidCallback onGoToAccount;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appState.loadNotifications(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appState.account == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          const SectionTitle(title: 'Notifications'),
          MessageCard(
            title: 'Sign in to see notifications',
            message:
                'Order updates, offers, and support messages will appear here once you sign in.',
            action: TextButton(
              onPressed: widget.onGoToAccount,
              child: const Text('Go to account'),
            ),
          ),
        ],
      );
    }

    final payload = widget.appState.notifications;
    return RefreshIndicator(
      onRefresh: () => widget.appState.loadNotifications(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          SectionTitle(
            title: 'Notifications',
            trailing: payload.unreadCount > 0
                ? TextButton(
                    onPressed: widget.appState.notificationsLoading
                        ? null
                        : () => widget.appState.markNotificationsRead(),
                    child: const Text('Mark all read'),
                  )
                : null,
          ),
          if (widget.appState.notificationsLoading && payload.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (payload.items.isEmpty)
            const MessageCard(
              title: 'No notifications yet',
              message:
                  'You are all caught up. Order updates and app messages will appear here.',
            )
          else
            for (final notification in payload.items)
              _NotificationTile(
                notification: notification,
                onMarkRead: notification.isRead
                    ? null
                    : () => widget.appState.markNotificationsRead(
                          notificationIds: <int>[notification.id],
                        ),
              ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
  });

  final AppNotification notification;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: notification.isRead
            ? null
            : theme.colorScheme.primaryContainer.withOpacity(0.45),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: AppVectorIcon(
              notification.type == 'order' ? 'cart' : 'bell',
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            notification.title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              notification.body,
              style: const TextStyle(height: 1.35),
            ),
          ),
          trailing: onMarkRead == null
              ? null
              : IconButton(
                  tooltip: 'Mark read',
                  onPressed: onMarkRead,
                  icon: const AppVectorIcon('check', size: 20),
                ),
        ),
      ),
    );
  }
}
