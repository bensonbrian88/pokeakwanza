import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoadingUser = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ref.listen(authProvider, (prev, next) {
      final prevToken = prev?.token;
      final nextToken = next.token;
      if (prevToken == null && nextToken != null) {
        setState(() {
          _errorMessage = null;
        });
        _loadUserProfile();
      }
      if (prevToken != null && nextToken == null) {
        setState(() {
          _errorMessage = null;
          _isLoadingUser = false;
        });
      }
    });
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authNotifier = ref.read(authProvider.notifier);

    if (ref.read(authProvider).token == null) {
      setState(() {
        _isLoadingUser = false;
      });
      return;
    }

    // Fetch user from backend
    setState(() {
      _isLoadingUser = true;
      _errorMessage = null;
    });

    try {
      await authNotifier.fetchUser();
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthenticated = authState.token != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('is_guest');
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
                }
              },
              tooltip: 'Logout',
            ),
        ],
      ),
      body: _isLoadingUser
          ? _buildLoadingState()
          : (user == null && (!isAuthenticated || _errorMessage != null))
              ? _buildLoginRequiredState()
              : _buildProfileContent(context, user),
    );
  }

  /// Loading indicator while fetching user
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading profile...'),
        ],
      ),
    );
  }

  /// Show login button when not authenticated
  Widget _buildLoginRequiredState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Login Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Please log in to view your profile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Login Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile content when authenticated and user data loaded
  Widget _buildProfileContent(
    BuildContext context,
    Map<String, dynamic>? user,
  ) {
    final userName = user?['name'] ?? 'Profile User';
    final userEmail = user?['email'] ?? 'No email';
    final userPhone = user?['phone'] ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // User Header Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.transparent,
                        backgroundImage: user != null && user['avatar'] != null
                            ? NetworkImage(user['avatar']) as ImageProvider
                            : null,
                        child: user == null || user['avatar'] == null
                            ? Icon(
                                Icons.person,
                                size: 40,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userEmail,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              userPhone,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loadUserProfile,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Refresh Profile',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Menu Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 12),
                _ProfileOptionTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  onTap: () => Navigator.pushNamed(context, '/orders'),
                ),
                const SizedBox(height: 8),
                _ProfileOptionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Shipping Address',
                  onTap: () =>
                      Navigator.pushNamed(context, '/shipping_addresses'),
                ),
                const SizedBox(height: 8),
                _ProfileOptionTile(
                  icon: Icons.payment_outlined,
                  title: 'Payment Methods',
                  onTap: () => Navigator.pushNamed(context, '/payment_methods'),
                ),
                const SizedBox(height: 8),
                _ProfileOptionTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                const SizedBox(height: 8),
                _ProfileOptionTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () => Navigator.pushNamed(context, '/help_center'),
                ),
                const SizedBox(height: 8),
                _ProfileOptionTile(
                  icon: Icons.chat_outlined,
                  title: 'Chat',
                  onTap: () => Navigator.pushNamed(context, '/chats'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
