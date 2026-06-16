import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import 'registration_screen.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithEmail(email, password);
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      if (errorStr.contains('API key') || errorStr.contains('firebase_auth/unknown')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase API Key invalid. Switching to Local Warrior Mode...')),
        );
        _proceedLocalMode();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithGoogle();
      
      if (result != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      if (errorStr.contains('API key') || errorStr.contains('firebase_auth/unknown')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase API Key invalid. Switching to Local Warrior Mode...')),
        );
        _proceedLocalMode();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login failed: ${e.toString()}')),
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
    final fg = theme.colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    final sub = theme.colorScheme.brightness == Brightness.dark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
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
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFC7F000), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7F000).withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fitness_center, color: Color(0xFFC7F000), size: 60),
                ),
                const SizedBox(height: 32),
                const Text(
                  'FORGE AHEAD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ELITE PERFORMANCE PROTOCOL',
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                // Email Field
                _buildInputField(
                  label: 'IDENTITY',
                  hint: 'Email Address',
                  controller: _emailController,
                  icon: Icons.mail_outline,
                  subColor: sub,
                  surfaceColor: surface,
                  fgColor: fg,
                ),
                const SizedBox(height: 16),
                // Password Field
                _buildInputField(
                  label: 'SECURITY',
                  hint: 'Password',
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  subColor: sub,
                  surfaceColor: surface,
                  fgColor: fg,
                  isPassword: true,
                  obscure: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 24),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC7F000),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
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
                              Icon(Icons.bolt, size: 20),
                              SizedBox(width: 8),
                              Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),
                const SizedBox(height: 24),
                // Google Auth Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white10, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white.withValues(alpha: 0.02),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.language, color: Color(0xFFC7F000), size: 20),
                        SizedBox(width: 12),
                        Text(
                          'GOOGLE AUTHENTICATION',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Local Warrior Mode Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC7F000), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: const Color(0xFFC7F000).withValues(alpha: 0.05),
                    ),
                    onPressed: _isLoading ? null : _proceedLocalMode,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.offline_bolt, color: Color(0xFFC7F000), size: 20),
                        SizedBox(width: 12),
                        Text(
                          'LOCAL WARRIOR MODE (OFFLINE)',
                          style: TextStyle(
                            color: Color(0xFFC7F000),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Registration Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New recruit? ',
                      style: TextStyle(color: sub, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                      ),
                      child: const Text(
                        'REGISTER NOW',
                        style: TextStyle(
                          color: Color(0xFFC7F000),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color subColor,
    required Color surfaceColor,
    required Color fgColor,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              label,
              style: TextStyle(
                color: subColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: controller,
              style: TextStyle(color: fgColor),
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: subColor),
                prefixIcon: Icon(icon, color: const Color(0xFFC7F000)),
                suffixIcon: isPassword
                    ? GestureDetector(
                        onTap: onToggleObscure,
                        child: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFFC7F000),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
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



  void _proceedLocalMode() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final localUser = await const StorageService().loadUser();
      if (localUser != null) {
        await userProvider.load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully in Local Mode!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No local profile found. Please register first.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
