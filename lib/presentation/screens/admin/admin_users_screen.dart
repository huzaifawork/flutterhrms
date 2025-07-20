import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'all',
    'customer',
    'admin',
    'staff',
    'active',
    'inactive',
  ];

  @override
  void initState() {
    super.initState();
    _userService.initialize();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
      _filterUsers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to dummy data for development
        _users = _createDummyUsers();
        _filteredUsers = _users;
      });
      _filterUsers();
    }
  }

  List<UserModel> _createDummyUsers() {
    return [
      UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        profileImageUrl: null,
      ),
      UserModel(
        id: '2',
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        phoneNumber: '+1234567891',
        role: 'admin',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 30)),
        profileImageUrl: null,
      ),
      UserModel(
        id: '3',
        name: 'Mike Johnson',
        email: 'mike.johnson@example.com',
        phoneNumber: '+1234567892',
        role: 'staff',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
        profileImageUrl: null,
      ),
      UserModel(
        id: '4',
        name: 'Sarah Wilson',
        email: 'sarah.wilson@example.com',
        phoneNumber: '+1234567893',
        role: 'customer',
        isActive: false,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 30)),
        profileImageUrl: null,
      ),
    ];
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = _searchController.text.isEmpty ||
            user.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            user.email
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            user.phoneNumber
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        bool matchesFilter = true;
        if (_selectedFilter == 'active') {
          matchesFilter = user.isActive;
        } else if (_selectedFilter == 'inactive') {
          matchesFilter = !user.isActive;
        } else if (_selectedFilter != 'all') {
          matchesFilter = user.role.toLowerCase() == _selectedFilter;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      final result =
          await _userService.updateUser(user.id, {'isActive': !user.isActive});

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User ${user.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changeUserRole(UserModel user, String newRole) async {
    try {
      final result = await _userService.updateUser(user.id, {'role': newRole});

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role changed to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update user role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated ||
        authProvider.currentUser?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
        ),
        body: const Center(
          child: Text('Access denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            _filterUsers();
                          },
                          selectedColor:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading users...')
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading users',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty ||
                                          _selectedFilter != 'all'
                                      ? 'Try adjusting your search or filter'
                                      : 'No users available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return _buildUserCard(user);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final theme = Theme.of(context);

    Color roleColor;
    IconData roleIcon;

    switch (user.role.toLowerCase()) {
      case 'admin':
        roleColor = Colors.red;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'staff':
        roleColor = Colors.blue;
        roleIcon = Icons.work;
        break;
      case 'customer':
        roleColor = Colors.green;
        roleIcon = Icons.person;
        break;
      default:
        roleColor = Colors.grey;
        roleIcon = Icons.person;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: user.isActive
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              user.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                color:
                                    user.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(roleIcon, size: 16, color: roleColor),
                          const SizedBox(width: 4),
                          Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contact Info
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.email,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  user.phoneNumber,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dates
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Joined: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),

            if (user.lastLoginAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.login,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last login: ${DateFormat('MMM dd, yyyy - hh:mm a').format(user.lastLoginAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],

            // Action Buttons
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _toggleUserStatus(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 32),
                  ),
                  child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                ),
                OutlinedButton(
                  onPressed: () {
                    _showRoleChangeDialog(user);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 32),
                  ),
                  child: const Text('Change Role'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Customer'),
              onTap: () {
                Navigator.of(context).pop();
                _changeUserRole(user, 'customer');
              },
            ),
            ListTile(
              leading: const Icon(Icons.work, color: Colors.blue),
              title: const Text('Staff'),
              onTap: () {
                Navigator.of(context).pop();
                _changeUserRole(user, 'staff');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Admin'),
              onTap: () {
                Navigator.of(context).pop();
                _changeUserRole(user, 'admin');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
