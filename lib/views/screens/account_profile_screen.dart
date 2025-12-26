import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../widgets/pro_status_widget.dart';

class AccountProfileScreen extends StatelessWidget {
  const AccountProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    final authService = context.read<AuthService>();
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: <Widget>[
            _buildHeader(context, user),
            const SizedBox(height: 30),
            const ProStatusWidget(),
            const SizedBox(height: 20),
            _buildAccountActions(context, authService, user),
            const SizedBox(height: 30),
            _buildSignOutButton(context, authService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : '?',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          user.displayName,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          user.email,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAccountActions(
      BuildContext context, AuthService authService, UserModel user) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: Column(
        children: [
          ListTile(
            leading:
                Icon(Icons.lock_outline, color: theme.colorScheme.secondary),
            title: Text('Change Password', style: theme.textTheme.titleMedium),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              authService.sendPasswordResetEmail(user.email);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset email sent.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    // Removed conflicting menu items to avoid navigation conflicts
    // Keeping only essential account management features
    return const SizedBox.shrink();
  }

  Widget _buildSignOutButton(BuildContext context, AuthService authService) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        onPressed: () {
          authService.signOut();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red, width: 0.5),
          ),
        ),
      ),
    );
  }
}
