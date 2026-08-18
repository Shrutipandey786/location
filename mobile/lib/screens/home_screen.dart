import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_data.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'live_camera_screen.dart';
import 'push_to_talk_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final data = provider.dashboardData ?? DashboardData.fallback();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: const [
                Icon(Icons.navigation_rounded, color: AppTheme.primaryIndigo, size: 22),
                SizedBox(width: 8),
                Text("Location Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Refresh Dashboard",
                onPressed: () => provider.fetchDashboard(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchDashboard(),
            color: AppTheme.primaryIndigo,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top User Profile & Status Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryIndigo.withOpacity(0.15),
                                child: const Icon(Icons.person, color: AppTheme.primaryIndigo, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.userName.isNotEmpty ? data.userName : "Active User",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      data.statusMessage.isNotEmpty ? data.statusMessage : "Active & Broadcast Mode On",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      data.isOnline ? Icons.wifi : Icons.wifi_off,
                                      color: data.isOnline ? AppTheme.statusGreen : Colors.grey,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      data.isOnline ? "ONLINE" : "OFFLINE",
                                      style: TextStyle(
                                        color: data.isOnline ? AppTheme.statusGreen : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: AppTheme.primaryIndigo, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    data.formatCoordinates(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryIndigo,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.battery_charging_full_rounded, color: AppTheme.statusGreen, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${data.batteryLevel}%",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Quick Features Section
                  const Text(
                    "Quick Features",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickCircleButton(
                        context,
                        title: "Map Overview",
                        icon: Icons.map_outlined,
                        color: AppTheme.primaryIndigo,
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(2); // Map tab
                          }
                        },
                      ),
                      _buildQuickCircleButton(
                        context,
                        title: "Live Camera",
                        icon: Icons.camera_alt_outlined,
                        color: AppTheme.accentCyan,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LiveCameraScreen()),
                          );
                        },
                      ),
                      _buildQuickCircleButton(
                        context,
                        title: "PTT Radio",
                        icon: Icons.mic_none_outlined,
                        color: AppTheme.primaryViolet,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PushToTalkScreen()),
                          );
                        },
                      ),
                      _buildQuickCircleButton(
                        context,
                        title: "Messages",
                        icon: Icons.chat_bubble_outline,
                        color: AppTheme.statusGreen,
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(1); // Chats tab
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. Recent Activity Stream
                  const Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (data.recentActivities.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "No recent telemetry activity recorded.",
                            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.recentActivities.length,
                      itemBuilder: (context, index) {
                        final activity = data.recentActivities[index];

                        IconData activityIcon = Icons.location_on;
                        Color iconColor = AppTheme.primaryIndigo;

                        if (activity.type == 'STATUS_CHANGE' || activity.type == 'BATTERY_UPDATE') {
                          activityIcon = Icons.battery_charging_full_rounded;
                          iconColor = AppTheme.primaryViolet;
                        } else if (activity.type == 'PTT_VOICE') {
                          activityIcon = Icons.mic;
                          iconColor = AppTheme.primaryViolet;
                        } else if (activity.type == 'CAMERA_TELEMETRY') {
                          activityIcon = Icons.camera_alt;
                          iconColor = AppTheme.accentCyan;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(activityIcon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            activity.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            activity.formattedTime,
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        activity.details,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickCircleButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
