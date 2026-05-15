import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D0A),
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
            const Text('FORGE AHEAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4)),
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
            _HeroBanner(onJoin: () {}),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(
                  child: _CommunityMetricCard(
                    icon: Icons.groups_rounded,
                    title: 'CLUBS',
                    value: '128',
                    subtitle: 'ACTIVE GROUPS',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _CommunityMetricCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'CHALLENGES',
                    value: '24',
                    subtitle: 'LIVE EVENTS',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('TRENDING COMMUNITY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _CommunityCard(
              title: 'Morning Run Squad',
              members: '12.4K members',
              note: 'Daily cardio and pace goals',
              color: const Color(0xFF171816),
              accent: const Color(0xFFC7F000),
            ),
            const SizedBox(height: 10),
            _CommunityCard(
              title: 'Power Lifting League',
              members: '8.7K members',
              note: 'Strength, PRs, and technique',
              color: const Color(0xFF171816),
              accent: const Color(0xFFC7F000),
            ),
            const SizedBox(height: 10),
            _CommunityCard(
              title: 'Nutrition & Recovery',
              members: '19.2K members',
              note: 'Meal plans, supplements, rest',
              color: const Color(0xFF171816),
              accent: const Color(0xFFC7F000),
            ),
            const SizedBox(height: 18),
            const Text('COMMUNITY FEED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _FeedPost(
              user: 'Alex M.',
              time: '10 min ago',
              title: 'Finished a 5K in 19:42',
              body: 'New personal best today. The neon running plan is working great!',
            ),
            const SizedBox(height: 10),
            _FeedPost(
              user: 'Sara K.',
              time: '42 min ago',
              title: 'Leg day completed',
              body: 'Added +10 lbs to squat. Recovery stats are looking strong.',
            ),
            const SizedBox(height: 10),
            _FeedPost(
              user: 'Mark T.',
              time: '1 hr ago',
              title: 'Meal prep week finished',
              body: 'High protein meals logged and calories on target.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onJoin;
  const _HeroBanner({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=900&q=80'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.08), Colors.black.withValues(alpha: 0.82)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFC7F000), borderRadius: BorderRadius.circular(6)),
                  child: const Text('COMMUNITY SPOTLIGHT', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'TRAIN TOGETHER\nGROW FASTER',
                  style: TextStyle(color: Colors.white, fontSize: 30, height: 0.95, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join group workouts, post progress, and stay motivated with athletes in your network.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 170,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC7F000),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onJoin,
                    child: const Text('JOIN NOW'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _CommunityMetricCard({required this.icon, required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171816),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFFC7F000)),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String title;
  final String members;
  final String note;
  final Color color;
  final Color accent;

  const _CommunityCard({required this.title, required this.members, required this.note, required this.color, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.groups_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(members, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(note, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }
}

class _FeedPost extends StatelessWidget {
  final String user;
  final String time;
  final String title;
  final String body;

  const _FeedPost({required this.user, required this.time, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF171816), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Color(0xFFC7F000), child: Icon(Icons.person, size: 18, color: Colors.black)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Colors.white70, height: 1.35)),
        ],
      ),
    );
  }
}
