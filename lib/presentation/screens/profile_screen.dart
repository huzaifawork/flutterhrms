import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              authProvider.userName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              authProvider.userName ?? 'User',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 32),
          _buildSettingsCard(
            title: 'Account Settings',
            subtitle: 'Update your profile information',
            icon: Icons.person,
            onTap: () => _showSnackBar('Account settings tapped'),
          ),
          _buildSettingsCard(
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            icon: Icons.notifications,
            onTap: () => _showSnackBar('Notifications tapped'),
          ),
          _buildSettingsCard(
            title: 'Privacy',
            subtitle: 'Manage your privacy settings',
            icon: Icons.lock,
            onTap: () => _showSnackBar('Privacy settings tapped'),
          ),
          _buildSettingsCard(
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            icon: Icons.help,
            onTap: () => _showSnackBar('Help & Support tapped'),
          ),
          _buildSettingsCard(
            title: 'About',
            subtitle: 'App information and version',
            icon: Icons.info,
            onTap: () => _showSnackBar('About tapped'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Show a dialog to test backend connection
  void _showBackendConnectionDialog() {
    final TextEditingController urlController = TextEditingController(text: APIService.baseUrl);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current API URL:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              APIService.baseUrl,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection status:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<bool>(
              future: APIService.instance.checkApiAvailability(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Testing connection...'),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.data == true) {
                  return const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Connected to backend',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  );
                } else {
                  return const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Cannot connect to backend',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Troubleshooting:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Ensure your backend server is running\n'
              '• Check network connectivity\n'
              '• Verify the correct URL is being used\n'
              '• If using web, check for CORS issues',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () async {
              // Force refresh data in the app
              Navigator.of(ctx).pop();
              _showSnackBar('Refreshing data from server...');
              
              // Force the app to refresh data
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            child: const Text('REFRESH APP'),
          ),
        ],
      ),
    );
  }
} 