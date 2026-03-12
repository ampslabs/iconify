import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_sdk/iconify_sdk.dart';

void main() {
  runApp(
    IconifyApp(
      config: const IconifyConfig(mode: IconifyMode.auto),
      child: const IconifyAtlasApp(),
    ),
  );
}

class IconifyAtlasApp extends StatelessWidget {
  const IconifyAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iconify Atlas',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MainNavigationScreen(),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF020617), // Deepest Slate
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF38BDF8),
        brightness: Brightness.dark,
        primary: const Color(0xFF38BDF8),
        secondary: const Color(0xFF818CF8),
        surface: const Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 1000;

        return Scaffold(
          appBar: isSmallScreen
              ? AppBar(
                  backgroundColor: const Color(0xFF0F172A),
                  title: Text(
                    'ATLAS',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  elevation: 0,
                )
              : null,
          drawer: isSmallScreen ? Drawer(child: _buildSidebarContents()) : null,
          body: Row(
            children: [
              if (!isSmallScreen) _buildSidebar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: 400.ms,
                  switchInCurve: Curves.easeOutCubic,
                  child: _buildCurrentPage(isSmallScreen),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: _buildSidebarContents(),
    );
  }

  Widget _buildSidebarContents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SidebarHeader(),
        const SizedBox(height: 32),
        _SidebarItem(
          icon: 'lucide:layout-grid',
          label: 'Explorer',
          isActive: _activeTabIndex == 0,
          onTap: () {
            setState(() => _activeTabIndex = 0);
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
        ),
        _SidebarItem(
          icon: 'tabler:flask',
          label: 'Design System Lab',
          isActive: _activeTabIndex == 1,
          onTap: () {
            setState(() => _activeTabIndex = 1);
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
        ),
        _SidebarItem(
          icon: 'heroicons:cog-6-tooth',
          label: 'Diagnostics',
          isActive: _activeTabIndex == 2,
          onTap: () {
            setState(() => _activeTabIndex = 2);
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
        ),
        const Spacer(),
        const _SidebarFooter(),
      ],
    );
  }

  Widget _buildCurrentPage(bool isSmallScreen) {
    switch (_activeTabIndex) {
      case 0:
        return IconExplorerPage(
          key: const ValueKey('explorer'),
          isSmallScreen: isSmallScreen,
        );
      case 1:
        return DesignSystemLabPage(
          key: const ValueKey('lab'),
          isSmallScreen: isSmallScreen,
        );
      case 2:
        return const DiagnosticsPage(key: ValueKey('diag'));
      default:
        return const SizedBox.shrink();
    }
  }
}

// --- EXPLORER PAGE ---

class IconExplorerPage extends StatefulWidget {
  const IconExplorerPage({super.key, required this.isSmallScreen});
  final bool isSmallScreen;

  @override
  State<IconExplorerPage> createState() => _IconExplorerPageState();
}

class _IconExplorerPageState extends State<IconExplorerPage>
    with SingleTickerProviderStateMixin {
  final List<String> _icons = [
    'mdi:bag-personal-tag-outline',
    'mdi:account',
    'mdi:cog',
    'mdi:magnify',
    'lucide:rocket',
    'lucide:zap',
    'lucide:shield',
    'lucide:atom',
    'tabler:wand',
    'tabler:dna',
    'tabler:cpu',
    'tabler:world',
    'heroicons:sparkles',
    'heroicons:fire',
    'heroicons:bolt',
    'heroicons:command-line',
  ];

  String? _selectedIcon;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = const Color(0xFF38BDF8);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Icon Atlas',
          subtitle: 'Exploring 150,000+ possibilities across 200+ collections.',
          isSmallScreen: widget.isSmallScreen,
        ),
        const SizedBox(height: 48),
        Expanded(
          child: widget.isSmallScreen
              ? Column(
                  children: [
                    if (_selectedIcon != null) ...[
                      SizedBox(
                        height: 500,
                        child: _IconDetailPanel(
                          name: _selectedIcon!,
                          color: currentColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    Expanded(child: _buildGrid(currentColor, 2)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildGrid(currentColor, 4)),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 2,
                      child: _selectedIcon != null
                          ? _IconDetailPanel(
                              name: _selectedIcon!,
                              color: currentColor,
                            )
                          : const _EmptyDetailPanel(),
                    ),
                  ],
                ),
        ),
      ],
    );

    return Stack(
      children: [
        // Ambient background glow
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: MediaQuery.of(context).size.width * 0.5 - 200,
              child: Opacity(
                opacity: 0.4 + (_pulseController.value * 0.2),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        currentColor.withAlpha(150),
                        currentColor.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.all(widget.isSmallScreen ? 24.0 : 48.0),
          child: content,
        ),
      ],
    );
  }

  Widget _buildGrid(Color currentColor, int crossAxisCount) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _icons.length,
      itemBuilder: (context, i) => _IconCard(
        name: _icons[i],
        isSelected: _selectedIcon == _icons[i],
        color: currentColor,
        onTap: () => setState(() => _selectedIcon = _icons[i]),
      ),
    );
  }
}

// --- DESIGN SYSTEM LAB PAGE ---

class DesignSystemLabPage extends StatelessWidget {
  const DesignSystemLabPage({super.key, required this.isSmallScreen});
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 24.0 : 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'Design System Lab',
            subtitle:
                'Validating icon utility within production-grade components.',
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 48),
          _LabSection(
            title: 'Glassmorphic Navigation',
            child: _GlassNavbar(isSmallScreen: isSmallScreen),
          ),
          const SizedBox(height: 32),
          _LabSection(
            title: 'System Status Board',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                const _StatusChip(
                  label: 'Operational',
                  icon: 'lucide:check',
                  color: Colors.green,
                ),
                const _StatusChip(
                  label: 'Warning',
                  icon: 'lucide:warning',
                  color: Colors.amber,
                ),
                const _StatusChip(
                  label: 'System Failure',
                  icon: 'lucide:error',
                  color: Colors.redAccent,
                ),
                const _StatusChip(
                  label: 'Deploying',
                  icon: 'lucide:refresh',
                  color: Colors.blueAccent,
                  isSpinning: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _LabSection(
            title: 'Interactive Buttons',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                const _ModernButton(
                  label: 'Primary Action',
                  icon: 'lucide:arrow-right',
                  isPrimary: true,
                ),
                const _ModernButton(label: 'Secondary', icon: 'lucide:copy'),
                const _ModernButton(
                  label: 'Delete',
                  icon: 'lucide:trash',
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- DIAGNOSTICS PAGE ---

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 1000;
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'Adaptive Rendering',
            subtitle: 'Monitoring the bridge between Vector and Raster paths.',
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(10)),
            ),
            child: Column(
              children: [
                const _DiagRow(
                  label: 'Renderer Backend',
                  value: 'Impeller (Metal)',
                  icon: 'lucide:cpu',
                  color: Colors.orangeAccent,
                ),
                const Divider(height: 48, color: Colors.white10),
                const _DiagRow(
                  label: 'SVG Direct Path',
                  value: 'Active (No color filter)',
                  icon: 'lucide:check',
                  color: Colors.greenAccent,
                ),
                const Divider(height: 48, color: Colors.white10),
                const _DiagRow(
                  label: 'Rasterized Fallback',
                  value: 'Ready (Color override detected)',
                  icon: 'lucide:layers',
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS (Sidebar) ---

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconifyIcon('lucide:box', color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            'ATLAS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withAlpha(10) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconifyIcon(
                icon,
                size: 20,
                color: isActive ? const Color(0xFF38BDF8) : Colors.white54,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HELPER WIDGETS (Components) ---

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.isSmallScreen,
  });
  final String title;
  final String subtitle;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isSmallScreen ? 32 : 48,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 18,
            color: Colors.white54,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
      ],
    );
  }
}

class _IconCard extends StatelessWidget {
  const _IconCard({
    required this.name,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String name;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(30) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? color : Colors.white.withAlpha(10),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: IconifyIcon(
                name,
                size: 32,
                color: isSelected ? color : Colors.white,
              ),
            ),
          ),
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
  }
}

class _IconDetailPanel extends StatelessWidget {
  const _IconDetailPanel({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SPECIFICATION',
              style: TextStyle(
                letterSpacing: 2,
                color: Colors.white30,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(child: IconifyIcon(name, size: 64, color: color)),
            ),
            const SizedBox(height: 32),
            _DetailRow(label: 'Identifier', value: name),
            _DetailRow(label: 'Collection', value: name.split(':').first),
            const _DetailRow(label: 'License', value: 'MIT / Open Source'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: IconifyIcon('lucide:copy', size: 18, color: Colors.black),
                label: const Text(
                  'COPY IDENTIFIER',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetailPanel extends StatelessWidget {
  const _EmptyDetailPanel();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(100),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withAlpha(5),
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Text(
          'Select an icon to view details',
          style: TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.firaCode(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- LAB COMPONENTS ---

class _LabSection extends StatelessWidget {
  const _LabSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            letterSpacing: 1.5,
            color: Colors.white30,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _GlassNavbar extends StatelessWidget {
  const _GlassNavbar({required this.isSmallScreen});
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            border: Border.all(color: Colors.white.withAlpha(20)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconifyIcon(
                'lucide:home',
                size: 20,
                color: const Color(0xFF38BDF8),
              ),
              SizedBox(width: isSmallScreen ? 16 : 32),
              const IconifyIcon.name(
                IconifyName('lucide', 'search'),
                size: 20,
                color: Colors.white54,
              ),
              SizedBox(width: isSmallScreen ? 16 : 32),
              const IconifyIcon.name(
                IconifyName('lucide', 'bell'),
                size: 20,
                color: Colors.white54,
              ),
              SizedBox(width: isSmallScreen ? 16 : 32),
              const IconifyIcon.name(
                IconifyName('lucide', 'user'),
                size: 20,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    this.isSpinning = false,
  });
  final String label;
  final String icon;
  final Color color;
  final bool isSpinning;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = IconifyIcon(icon, size: 16, color: color);
    if (isSpinning) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 2.seconds);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  const _ModernButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.color,
  });
  final String label;
  final String icon;
  final bool isPrimary;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            color ??
            (isPrimary ? const Color(0xFF38BDF8) : const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary ? Colors.transparent : Colors.white.withAlpha(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          IconifyIcon(
            icon,
            size: 16,
            color: isPrimary ? Colors.black : Colors.white,
          ),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  const _DiagRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconifyIcon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CORE VERSION',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v0.2.0-alpha',
            style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
