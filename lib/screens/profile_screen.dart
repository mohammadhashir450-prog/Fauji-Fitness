import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../utils/scaffold_keys.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final user = userProv.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFFC7F000);
    
    // Dynamic text colors to prevent white text on white background in Light mode!
    final textColorMain = isDark ? Colors.white : Colors.black87;
    final textColorSub = isDark ? Colors.white38 : Colors.black54;
    final cardBgColor = isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
    final accentGreen = isDark ? const Color(0xFFC7F000) : const Color(0xFF558B2F);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 14,
              backgroundColor: primaryColor,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF0B0D0A),
                child: Icon(Icons.fitness_center, size: 12, color: Color(0xFFC7F000)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'MY PROFILE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4, color: textColorMain),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
              icon: Icon(Icons.menu_rounded, color: primaryColor),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: user == null
            ? Center(
                child: Text(
                  'No athlete profile loaded.',
                  style: TextStyle(color: textColorSub),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // 🌟 UNIQUE HERO CARD (GLOWING ACCENTS / DYNAMIC GRADIENTS)
                  _buildUniqueHeroCard(user, isDark),
                  const SizedBox(height: 20),
                  
                  // 📊 BIOMETRIC DATA (GRID DISPLAY)
                  Text(
                    'BIOMETRIC DATA',
                    style: TextStyle(color: textColorSub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildInfoTile(Icons.height, 'HEIGHT', user.heightCm == null ? '--' : '${user.heightCm!.toStringAsFixed(0)} CM', accentGreen, cardBgColor, textColorMain, textColorSub),
                      _buildInfoTile(Icons.flag, 'PRIMARY GOAL', user.goal.name.toUpperCase(), accentGreen, cardBgColor, textColorMain, textColorSub),
                      _buildInfoTile(Icons.wc, 'GENDER', user.sex.toUpperCase(), accentGreen, cardBgColor, textColorMain, textColorSub),
                      _buildInfoTile(Icons.badge, 'CATEGORY', (user.memberCategory ?? MemberCategory.male).name.toUpperCase(), accentGreen, cardBgColor, textColorMain, textColorSub),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 💳 MEMBERSHIP LEVEL
                  Text(
                    'MEMBERSHIP DETAILS',
                    style: TextStyle(color: textColorSub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  _buildMembershipDetailCard(user, cardBgColor, accentGreen, textColorMain, textColorSub),
                  const SizedBox(height: 20),

                  // ⚙️ PREFERENCES
                  Text(
                    'PREFERENCES',
                    style: TextStyle(color: textColorSub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  _buildPreferencesCard(userProv, user, cardBgColor, accentGreen, textColorMain, textColorSub),
                  const SizedBox(height: 24),

                  // 🚀 ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () => _openEditBottomSheet(context, user),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.edit_note, size: 22),
                      label: const Text('EDIT PROFILE DETAILS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUniqueHeroCard(UserProfile user, bool isDark) {
    // Dynamic gradient based on Dark/Light theme mode
    final gradColors = isDark 
      ? [const Color(0xFF182310), const Color(0xFF0F150A)]
      : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)];
    
    final borderCol = isDark 
      ? const Color(0xFFC7F000).withOpacity(0.25)
      : const Color(0xFF558B2F).withOpacity(0.3);

    final titleCol = isDark ? Colors.white : Colors.black87;
    final subCol = isDark ? Colors.white38 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC7F000).withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFC7F000).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFFC7F000) : const Color(0xFF558B2F), width: 2),
            ),
            child: Center(
              child: Icon(Icons.person, color: isDark ? const Color(0xFFC7F000) : const Color(0xFF558B2F), size: 40),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFC7F000) : const Color(0xFF558B2F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.membershipType == MembershipType.trainer ? 'ELITE TRAINER' : 'WARRIOR ATHLETE',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.name.toUpperCase(),
                  style: TextStyle(color: titleCol, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined: ${_formatDate(user.registrationDate ?? DateTime.now())}',
                  style: TextStyle(color: subCol, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, Color accent, Color bg, Color mainText, Color subText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mainText.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(color: subText, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: mainText, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipDetailCard(UserProfile user, Color bg, Color accent, Color mainText, Color subText) {
    final fee = user.membershipType == MembershipType.trainer ? '15,000 PKR' : '10,000 PKR';
    final label = user.membershipType == MembershipType.trainer
        ? 'Trainer Monthly Package (incl. personal coach)'
        : 'Basic Gym Access Membership';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mainText.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.credit_card, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.membershipType.name.toUpperCase(),
                  style: TextStyle(color: mainText, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(color: subText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fee,
                style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                '/month',
                style: TextStyle(color: subText, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(UserProvider userProv, UserProfile user, Color bg, Color accent, Color mainText, Color subText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mainText.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode, color: accent, size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DARK MODE', style: TextStyle(color: mainText, fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('Toggle UI theme colors', style: TextStyle(color: subText, fontSize: 11)),
                ],
              ),
            ],
          ),
          Switch(
            value: userProv.darkMode,
            onChanged: (v) => userProv.setDarkMode(v),
            activeColor: accent,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _openEditBottomSheet(BuildContext context, UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditProfileSheet(user: user),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserProfile user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  double? _height;
  late String _sex;
  late MemberCategory _memberCategory;
  late Goal _goal;
  late MembershipType _membershipType;

  @override
  void initState() {
    super.initState();
    _name = widget.user.name;
    _height = widget.user.heightCm;
    _sex = widget.user.sex;
    _memberCategory = widget.user.memberCategory ?? MemberCategory.male;
    _goal = widget.user.goal;
    _membershipType = widget.user.membershipType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Dynamic text colors & container styles inside bottom sheet editor
    final textCol = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFFC7F000);
    final labelStyleCol = isDark ? primaryColor : const Color(0xFF4E7E00);
    final fillCol = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final dropCol = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EDIT WARRIOR BIOMETRICS',
                    style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textCol.withOpacity(0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                style: TextStyle(color: textCol),
                decoration: InputDecoration(
                  labelText: 'FULL NAME',
                  labelStyle: TextStyle(color: labelStyleCol, fontSize: 12, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: fillCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
                onSaved: (v) => _name = v ?? _name,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _height?.toString(),
                style: TextStyle(color: textCol),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'HEIGHT (CM)',
                  labelStyle: TextStyle(color: labelStyleCol, fontSize: 12, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: fillCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSaved: (v) => _height = v == null || v.isEmpty ? null : double.tryParse(v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _sex,
                dropdownColor: dropCol,
                style: TextStyle(color: textCol),
                decoration: InputDecoration(
                  labelText: 'GENDER',
                  labelStyle: TextStyle(color: labelStyleCol, fontSize: 12, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: fillCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _sex = v ?? 'male'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MemberCategory>(
                value: _memberCategory,
                dropdownColor: dropCol,
                style: TextStyle(color: textCol),
                decoration: InputDecoration(
                  labelText: 'MEMBER CATEGORY',
                  labelStyle: TextStyle(color: labelStyleCol, fontSize: 12, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: fillCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: MemberCategory.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _memberCategory = v ?? MemberCategory.male),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Goal>(
                value: _goal,
                dropdownColor: dropCol,
                style: TextStyle(color: textCol),
                decoration: InputDecoration(
                  labelText: 'PRIMARY GOAL',
                  labelStyle: TextStyle(color: labelStyleCol, fontSize: 12, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: fillCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: Goal.values
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _goal = v ?? Goal.maintain),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MembershipType>(
                value: _membershipType,
                dropdownColor: dropCol,
                style: TextStyle(color: textCol),
                decoration: InputDecoration(
                  labelText: 'MEMBERSHIP LEVEL',
                  labelStyle: TextStyle(color: labelStyleCol, fontSize: 12, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: fillCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: MembershipType.basic, child: Text('BASIC ACCESS (10,000 PKR)')),
                  DropdownMenuItem(value: MembershipType.trainer, child: Text('PERSONAL COACH (15,000 PKR)')),
                ],
                onChanged: (v) => setState(() => _membershipType = v ?? MembershipType.basic),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    _formKey.currentState!.save();
                    
                    final userProvider = context.read<UserProvider>();
                    await userProvider.createOrUpdate(
                      name: _name,
                      heightCm: _height,
                      sex: _sex,
                      goal: _goal,
                      membershipType: _membershipType,
                      memberCategory: _memberCategory,
                      darkMode: userProvider.darkMode,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Athlete profile updated successfully!')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE BIO CHANGES', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
