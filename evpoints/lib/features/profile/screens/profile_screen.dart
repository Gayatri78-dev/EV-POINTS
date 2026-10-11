import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          final user = profile.user;
          return CustomScrollView(
            slivers: [
              // ── Header SliverAppBar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primaryLight,
                          AppColors.primary
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Avatar with initials
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryDark.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  user?.initials ?? '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Real name from auth
                          Text(
                            user?.name.isNotEmpty == true
                                ? user!.name
                                : 'Guest User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Real email from auth
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (user?.memberSince.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Member since ${user!.memberSince}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Stats Row – real data from UserStatsService
                      _StatsCard(profile: profile),
                      const SizedBox(height: 24),

                      // Vehicle info (if set)
                      if (user?.vehicleType.isNotEmpty == true) ...[
                        _InfoCard(
                          icon: Icons.electric_car_rounded,
                          label: 'Vehicle',
                          value: user!.vehicleType,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Phone (if set)
                      if (user?.phone.isNotEmpty == true) ...[
                        _InfoCard(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: user!.phone,
                          color: AppColors.acBadge,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Account menu
                      _menuCard(context, [
                        _MenuItem(
                          icon: Icons.edit_outlined,
                          label: AppStrings.editProfile,
                          color: AppColors.primary,
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          label: AppStrings.changePassword,
                          color: AppColors.acBadge,
                          onTap: () =>
                              _showChangePasswordDialog(context, profile),
                        ),
                        _MenuItem(
                          icon: Icons.bookmark_outline_rounded,
                          label: AppStrings.savedSpots,
                          color: AppColors.fastChargeBadge,
                          onTap: () =>
                              _showComingSoon(context, 'Saved Spots'),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _menuCard(context, [
                        _MenuItem(
                          icon: Icons.logout_rounded,
                          label: AppStrings.logout,
                          color: AppColors.error,
                          onTap: () => _confirmLogout(context, profile),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      Text(
                        'EV Charge Finder v1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                item.color.withOpacity(0.2),
                                item.color.withOpacity(0.05)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.color, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),
              if (idx < items.length - 1)
                const Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 20,
                  color: AppColors.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, ProfileProvider profile) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Change Password',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pwField(
                  controller: currentCtrl,
                  label: 'Current Password',
                  obscure: obscureCurrent,
                  onToggle: () =>
                      setDialogState(() => obscureCurrent = !obscureCurrent),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _pwField(
                  controller: newCtrl,
                  label: 'New Password',
                  obscure: obscureNew,
                  onToggle: () =>
                      setDialogState(() => obscureNew = !obscureNew),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Min 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                _pwField(
                  controller: confirmCtrl,
                  label: 'Confirm New Password',
                  obscure: obscureConfirm,
                  onToggle: () =>
                      setDialogState(() => obscureConfirm = !obscureConfirm),
                  validator: (v) =>
                      v != newCtrl.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final success = await profile.changePassword(
                    currentCtrl.text, newCtrl.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success
                        ? 'Password changed successfully!'
                        : (profile.errorMessage ?? 'Failed to change password')),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, ProfileProvider profile) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title:
            const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to logout?'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await profile.logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Stats Card ─────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final ProfileProvider profile;
  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: profile.statsLoaded
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  profile.sessionCount.toString(),
                  'Sessions',
                  Icons.ev_station_rounded,
                  AppColors.primary,
                ),
                Container(
                    width: 1, height: 40, color: AppColors.divider),
                _buildStatItem(
                  profile.co2Saved,
                  'CO₂ Saved',
                  Icons.co2_rounded,
                  AppColors.acBadge,
                ),
                Container(
                    width: 1, height: 40, color: AppColors.divider),
                _buildStatItem(
                  profile.totalEnergy,
                  'Energy',
                  Icons.bolt_rounded,
                  AppColors.fastChargeBadge,
                ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Info Card ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Menu item model ────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
