import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/lulify-bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/profile_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Harley',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Premium Member',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Usage Statistics
                _buildSection(
                  title: 'Usage Statistics',
                  child: Column(
                    children: [
                      _buildStatItem(
                        icon: Icons.bedtime,
                        label: 'Total Sleep Time',
                        value: '45h 30m',
                      ),
                      const Divider(color: Colors.white24),
                      _buildStatItem(
                        icon: Icons.music_note,
                        label: 'Music Sessions',
                        value: '12',
                      ),
                      const Divider(color: Colors.white24),
                      _buildStatItem(
                        icon: Icons.star,
                        label: 'Average Sleep Quality',
                        value: '4.5/5',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // App Settings
                _buildSection(
                  title: 'Settings',
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.notifications,
                        label: 'Notifications',
                        onTap: () {
                          // TODO: Implement notification settings
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildSettingItem(
                        icon: Icons.volume_up,
                        label: 'Sound Settings',
                        onTap: () {
                          // TODO: Implement sound settings
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildSettingItem(
                        icon: Icons.palette,
                        label: 'Theme',
                        onTap: () {
                          // TODO: Implement theme settings
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Settings
                _buildSection(
                  title: 'Account',
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.person,
                        label: 'Edit Profile',
                        onTap: () {
                          // TODO: Implement profile editing
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildSettingItem(
                        icon: Icons.lock,
                        label: 'Privacy Settings',
                        onTap: () {
                          // TODO: Implement privacy settings
                        },
                      ),
                      const Divider(color: Colors.white24),
                      _buildSettingItem(
                        icon: Icons.logout,
                        label: 'Sign Out',
                        onTap: () {
                          // TODO: Implement sign out
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
