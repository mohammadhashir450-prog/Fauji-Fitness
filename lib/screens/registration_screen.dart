import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _heightController = TextEditingController();

  String _selectedSex = 'male';
  MemberCategory _selectedCategory = MemberCategory.male;
  Goal _selectedGoal = Goal.maintain;
  MembershipType _selectedMembership = MembershipType.basic;
  bool _obscurePassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final userProvider = context.read<UserProvider>();

      // 1. Firebase Auth Registration
      final result = await authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (result != null) {
        // 2. Update Local/Global Provider State
        await userProvider.createOrUpdate(
          name: _nameController.text.trim(),
          sex: _selectedSex,
          heightCm: double.tryParse(_heightController.text),
          goal: _selectedGoal,
          membershipType: _selectedMembership,
          memberCategory: _selectedCategory,
          darkMode: true,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Welcome Warrior.')),
        );

        // 3. Navigate to Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      if (errorStr.contains('API key') || errorStr.contains('firebase_auth/unknown')) {
        _showApiKeyErrorDialog(context, errorStr);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    final sub = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFC7F000)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'REGISTER WARRIOR',
          style: TextStyle(
            color: Color(0xFFC7F000),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, color: Color(0xFFC7F000)),
            onPressed: () => _promptFirebaseApiKey(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildLabel('FULL NAME', sub),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context: context,
                    controller: _nameController,
                    hintText: 'Your Name',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('EMAIL ADDRESS', sub),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context: context,
                    controller: _emailController,
                    hintText: 'your@email.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('PASSWORD', sub),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    context: context,
                    controller: _passwordController,
                    hintText: 'Create password',
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('HEIGHT (CM)', sub),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context: context,
                    controller: _heightController,
                    hintText: '180',
                    icon: Icons.straighten,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter height' : null,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('SEX', sub),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    context: context,
                    value: _selectedSex,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _selectedSex = v ?? 'male'),
                    icon: Icons.wc_outlined,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('MEMBER CATEGORY', sub),
                  const SizedBox(height: 8),
                  _buildDropdown<MemberCategory>(
                    context: context,
                    value: _selectedCategory,
                    items: MemberCategory.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? MemberCategory.male),
                    icon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('FITNESS GOAL', sub),
                  const SizedBox(height: 8),
                  _buildDropdown<Goal>(
                    context: context,
                    value: _selectedGoal,
                    items: Goal.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGoal = v ?? Goal.maintain),
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('SELECT MEMBERSHIP', sub),
                  const SizedBox(height: 12),
                  _buildMembershipCard(
                    context: context,
                    title: 'BASIC',
                    price: '10,000 PKR',
                    isSelected: _selectedMembership == MembershipType.basic,
                    onTap: () => setState(() => _selectedMembership = MembershipType.basic),
                  ),
                  const SizedBox(height: 10),
                  _buildMembershipCard(
                    context: context,
                    title: 'TRAINER',
                    price: '15,000 PKR',
                    isSelected: _selectedMembership == MembershipType.trainer,
                    onTap: () => setState(() => _selectedMembership = MembershipType.trainer),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreeTerms,
                          onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                          activeColor: const Color(0xFFC7F000),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'I agree to Terms & Conditions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Terms & Conditions')),
                                ),
                                child: const Text(
                                  'Tap to view',
                                  style: TextStyle(
                                    color: Color(0xFFC7F000),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _agreeTerms ? const Color(0xFFC7F000) : Colors.grey,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _agreeTerms && !_isLoading ? _handleRegistration : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _agreeTerms ? const Color(0xFFC7F000) : Colors.grey,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: _agreeTerms
                            ? const Color(0xFFC7F000).withValues(alpha: 0.05)
                            : Colors.transparent,
                      ),
                      onPressed: _agreeTerms && !_isLoading ? _proceedLocalMode : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7F000)),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.offline_bolt,
                                  color: _agreeTerms ? const Color(0xFFC7F000) : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'REGISTER IN LOCAL MODE (OFFLINE)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _agreeTerms ? const Color(0xFFC7F000) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already registered? ',
                          style: TextStyle(color: sub, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              color: Color(0xFFC7F000),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFFC7F000), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFC7F000), size: 20),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFC7F000),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFC7F000), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
        style: const TextStyle(color: Colors.white),
        dropdownColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildMembershipCard({
    required BuildContext context,
    required String title,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC7F000) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFFC7F000),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC7F000) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.black : Colors.white54,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _promptFirebaseApiKey(BuildContext context) {
    final tempController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key, color: Color(0xFFC7F000)),
                const SizedBox(width: 10),
                const Text(
                  'Configure Firebase API Key',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'A valid Firebase API Key is required to register or login. Paste your key below to initialize Firebase services.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tempController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Paste API Key (AIzaSy...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final key = tempController.text.trim();
                if (key.isNotEmpty) {
                  final authService = context.read<AuthService>();
                  await authService.saveApiKeyAndReinit(key);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Firebase API Key saved and initialized!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC7F000),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save & Initialize', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121826),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'Invalid API Key Config',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The default Firebase API key is mock or invalid. You can enter a valid Firebase API key or bypass this error using Local Mode.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _promptFirebaseApiKey(context);
              },
              child: const Text('Configure Key', style: TextStyle(color: Color(0xFFC7F000), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _proceedLocalMode();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC7F000),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Local Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _proceedLocalMode() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();

      await userProvider.createOrUpdate(
        name: _nameController.text.trim(),
        sex: _selectedSex,
        heightCm: double.tryParse(_heightController.text),
        goal: _selectedGoal,
        membershipType: _selectedMembership,
        memberCategory: _selectedCategory,
        darkMode: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful in Local Mode! Welcome Warrior.')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
