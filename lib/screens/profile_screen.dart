import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  double? _height;
  Goal _goal = Goal.maintain;
  String _sex = 'male';
  MembershipType _membershipType = MembershipType.basic;
  MemberCategory _memberCategory = MemberCategory.male;
  bool _darkMode = true;
  bool _agreeTerms = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<UserProvider>().user;
    if (u != null) {
      _name = u.name;
      _height = u.heightCm;
      _goal = u.goal;
      _sex = u.sex;
      _membershipType = u.membershipType;
      _memberCategory = u.memberCategory ?? MemberCategory.male;
      _darkMode = u.darkMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final user = userProv.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.colorScheme.surface;
    final textMain = isDark ? Colors.white : Colors.black87;
    final textSub = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFC7F000),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF0B0D0A),
                child: Icon(Icons.fitness_center, size: 12, color: Color(0xFFC7F000)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('FAUJI FITNESS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFFC7F000))),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            _ProfileHeroCard(user: user, goal: _goal, sex: _sex),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ProfileMetricCard(
                    icon: Icons.monitor_weight_outlined,
                    title: 'HEIGHT',
                    value: _height == null ? '--' : '${_height!.toStringAsFixed(0)} CM',
                    accent: const Color(0xFFC7F000),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileMetricCard(
                    icon: Icons.flag_outlined,
                    title: 'GOAL',
                    value: _goal.name.toUpperCase(),
                    accent: const Color(0xFFC7F000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProfileMetricCard(
                    icon: Icons.person_outline,
                    title: 'MEMBER TYPE',
                    value: _membershipType.name.toUpperCase(),
                    accent: _membershipType == MembershipType.trainer ? Colors.orange : const Color(0xFFC7F000),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileMetricCard(
                    icon: Icons.badge_outlined,
                    title: 'CATEGORY',
                    value: _memberCategory.name.toUpperCase(),
                    accent: const Color(0xFFC7F000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle('MEMBERSHIP PRICING'),
            const SizedBox(height: 12),
            _MembershipCard(
              title: 'BASIC MEMBERSHIP',
              price: '10,000 PKR',
              description: 'Monthly access to gym',
              isSelected: _membershipType == MembershipType.basic,
              onTap: () => setState(() => _membershipType = MembershipType.basic),
            ),
            const SizedBox(height: 10),
            _MembershipCard(
              title: 'TRAINER MEMBERSHIP',
              price: '15,000 PKR',
              description: 'Monthly with personal trainer',
              isSelected: _membershipType == MembershipType.trainer,
              onTap: () => setState(() => _membershipType = MembershipType.trainer),
            ),
            const SizedBox(height: 18),
            _SectionTitle('PROFILE SETTINGS'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _name,
                      style: TextStyle(color: textMain),
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
                      onSaved: (v) => _name = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _height?.toString(),
                      style: TextStyle(color: textMain),
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _height = v == null || v.isEmpty ? null : double.tryParse(v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _sex = v ?? 'male'),
                      decoration: const InputDecoration(labelText: 'Sex'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MemberCategory>(
                      initialValue: _memberCategory,
                      items: MemberCategory.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _memberCategory = v ?? MemberCategory.male),
                      decoration: const InputDecoration(labelText: 'Member Category'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Goal>(
                      initialValue: _goal,
                      items: Goal.values.map((g) => DropdownMenuItem(value: g, child: Text(g.name.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _goal = v ?? Goal.maintain),
                      decoration: const InputDecoration(labelText: 'Primary Goal'),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Switch(
                            value: _darkMode,
                            onChanged: (v) {
                              setState(() => _darkMode = v);
                              userProv.setDarkMode(v);
                            },
                            activeThumbColor: const Color(0xFFC7F000),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dark Mode', style: TextStyle(color: textMain, fontWeight: FontWeight.w700)),
                                Text('Black background when ON, white background when OFF', style: TextStyle(color: textSub, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTermsDialog(context),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('I agree to Terms & Conditions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  Text('Tap to view', style: TextStyle(color: Color(0xFFC7F000), fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: Color(0xFFC7F000)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _membershipType == MembershipType.trainer ? 'Trainer fee: 15,000 PKR' : 'Basic fee: 10,000 PKR',
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _agreeTerms ? const Color(0xFFC7F000) : Colors.grey,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _agreeTerms
                            ? () async {
                                if (!_formKey.currentState!.validate()) return;
                                _formKey.currentState!.save();
                                final userProvider = context.read<UserProvider>();
                                await userProvider.createOrUpdate(
                                  name: _name!,
                                  heightCm: _height,
                                  sex: _sex,
                                  goal: _goal,
                                  membershipType: _membershipType,
                                  memberCategory: _memberCategory,
                                  darkMode: _darkMode,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully')));
                              }
                            : null,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('SAVE PROFILE'),
                      ),
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

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171816),
        title: const Text('Terms & Conditions', style: TextStyle(color: Color(0xFFC7F000))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TermsSection(title: 'MEMBERSHIP FEES', content: '''
• Basic Membership: 10,000 PKR per month
• Trainer Membership: 15,000 PKR per month
• Payment due on the 1st of each month
• Late payment subject to 10% penalty'''),
              _TermsSection(title: 'MEMBER CATEGORIES', content: '''
• Members can select Male or Female category
• This helps personalize workout recommendations
• Personal trainers assigned based on category
• Privacy and comfort guaranteed'''),
              _TermsSection(title: 'GYM RULES', content: '''
• Maintain proper hygiene and cleanliness
• Follow equipment usage guidelines
• Respect other members' space
• Report any equipment damage immediately'''),
              _TermsSection(title: 'CANCELLATION', content: '''
• 30 days notice required for cancellation
• No refund for remaining balance
• Account will be deactivated upon cancellation
• Membership can be renewed anytime'''),
              _TermsSection(title: 'TRAINER SERVICES', content: '''
• Personal trainer assigned for trainer membership
• Trainer provides customized workout plans
• Nutritional guidance included
• Monthly progress assessment'''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFFC7F000))),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFFC7F000), fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 6),
        Text(content, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _MembershipCard({
    required this.title,
    required this.price,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFC7F000) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFC7F000) : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.black : Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(price, style: const TextStyle(color: Color(0xFFC7F000), fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final dynamic user;
  final Goal goal;
  final String sex;

  const _ProfileHeroCard({required this.user, required this.goal, required this.sex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFC7F000).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC7F000).withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.person, color: Color(0xFFC7F000), size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CURRENT PROFILE', style: TextStyle(color: Colors.white60, letterSpacing: 1.1, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? 'ATHLETE',
                  style: const TextStyle(color: Color(0xFFC7F000), fontSize: 26, fontWeight: FontWeight.w900, height: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sex: ${sex.toUpperCase()}   •   Goal: ${goal.name.toUpperCase()}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  const _ProfileMetricCard({required this.icon, required this.title, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900));
  }
}
