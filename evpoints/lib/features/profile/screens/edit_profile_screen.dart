import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _vehicleCtrl;

  static const List<String> _vehicleOptions = [
    '',
    'Tata Nexon EV',
    'Tata Tiago EV',
    'MG ZS EV',
    'Hyundai Kona EV',
    'Kia EV6',
    'BYD Atto 3',
    'Ola S1 Pro',
    'Ather 450X',
    'TVS iQube',
    'Hero Vida V1',
    'Other',
  ];

  String _selectedVehicle = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _vehicleCtrl =
        TextEditingController(text: user?.vehicleType ?? '');
    _selectedVehicle = user?.vehicleType ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = context.read<ProfileProvider>();
    final success = await profile.updateProfile(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      vehicleType: _selectedVehicle,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profile.errorMessage ?? AppStrings.genericError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text(
          AppStrings.editProfile,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Avatar
            Consumer<ProfileProvider>(
              builder: (_, profile, __) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        profile.user?.initials ?? '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Update your profile details below.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full name
                    CustomTextField(
                      label: AppStrings.fullName,
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: Validators.fullName,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomTextField(
                      label: AppStrings.email,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),

                    // Phone (optional)
                    CustomTextField(
                      label: 'Phone Number (optional)',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (_) => null, // optional
                    ),
                    const SizedBox(height: 16),

                    // Vehicle type dropdown
                    const Text(
                      'EV Vehicle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _vehicleOptions.contains(_selectedVehicle) ? _selectedVehicle : '',
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.electric_car_rounded,
                          color: AppColors.primary,
                        ),
                        hintText: 'Select your EV',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                      ),
                      items: _vehicleOptions.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            v.isEmpty ? 'Not specified' : v,
                            style: TextStyle(
                              color: v.isEmpty
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                              fontWeight: v.isEmpty
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedVehicle = v ?? ''),
                    ),

                    const SizedBox(height: 32),
                    Consumer<ProfileProvider>(
                      builder: (_, profile, __) => CustomButton(
                        label: AppStrings.save,
                        onPressed: _save,
                        isLoading: profile.isLoading,
                        icon: Icons.save_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: AppStrings.cancel,
                      onPressed: () => context.pop(),
                      isOutlined: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
