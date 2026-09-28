import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Section ──────────────────────────────────────────────
                _HeroSection(
                  topPadding: media.padding.top,
                  pulse: _pulse,
                ),

                // ── Body Content ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'WHY DELIVERSYNC',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4F46E5),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Smart Logistics,\nSimplified.',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage, track, and optimize your delivery operations seamlessly.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Feature Cards ─────────────────────────────────────
                      const _FeatureCard(
                        icon: Icons.my_location_rounded,
                        title: 'Live Tracking',
                        description: 'Track your deliveries in real time.',
                        gradient: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      ),
                      const SizedBox(height: 10),
                      const _FeatureCard(
                        icon: Icons.bolt_rounded,
                        title: 'Smart Assignment',
                        description:
                            'Automatically assign deliveries efficiently.',
                        gradient: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                      ),
                      const SizedBox(height: 10),
                      const _FeatureCard(
                        icon: Icons.notifications_active_rounded,
                        title: 'Instant Updates',
                        description:
                            'Stay informed about important delivery updates.',
                        gradient: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                      ),

                      const SizedBox(height: 28),

                      // ── Get Started Button ────────────────────────────────
                      _GradientButton(
                        label: 'Get Started',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                      ),

                      const SizedBox(height: 12),

                      // ── Login Outlined Button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(
                                color: Color(0xFFC7D2FE), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Bottom Link ───────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                              children: [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Create Account',
                                  style: TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
}

// ── Hero Section ───────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final double topPadding;
  final Animation<double> pulse;

  const _HeroSection({required this.topPadding, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF312E81), // Deep Indigo
            Color(0xFF4F46E5), // Primary Purple
            Color(0xFF6366F1), // Light Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          const Positioned(
            top: -30,
            right: -30,
            child: _DecorativeBlob(size: 180, opacity: 0.08),
          ),
          const Positioned(
            bottom: -20,
            left: -40,
            child: _DecorativeBlob(size: 150, opacity: 0.06),
          ),
          const Positioned(
            top: 60,
            left: -20,
            child: _DecorativeBlob(size: 100, opacity: 0.05),
          ),

          // Content
          Padding(
            padding: EdgeInsets.only(
              top: topPadding + 28,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/DeliverSync logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_shipping_rounded,
                        color: Color(0xFF4F46E5),
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // App name
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                    children: [
                      TextSpan(
                        text: 'Deliver',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Sync',
                        style: TextStyle(color: Color(0xFF67E8F9)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Tagline
                const Text(
                  'Delivering trust, every mile.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE0E7FF),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 28),

                // Logistics Visual Card
                _LogisticsVisualCard(pulse: pulse),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Decorative Blob ────────────────────────────────────────────────────────────
class _DecorativeBlob extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorativeBlob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Logistics Visual Card ──────────────────────────────────────────────────────
class _LogisticsVisualCard extends StatelessWidget {
  final Animation<double> pulse;
  const _LogisticsVisualCard({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Status row
          Row(
            children: [
              // Pulsing status dot
              ScaleTransition(
                scale: pulse,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x6034D399),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE FLEET MONITORING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFA7F3D0),
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '24 Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Delivery flow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const _FlowItem(
                icon: Icons.inventory_2_outlined,
                label: 'Pickup',
                color: Color(0xFFFBBF24),
              ),
              _FlowArrow(),
              const _FlowItem(
                icon: Icons.local_shipping_rounded,
                label: 'In Transit',
                color: Color(0xFF67E8F9),
              ),
              _FlowArrow(),
              const _FlowItem(
                icon: Icons.location_on_rounded,
                label: 'Delivered',
                color: Color(0xFF34D399),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FlowItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0E7FF),
          ),
        ),
      ],
    );
  }
}

class _FlowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Container(
          width: 5,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: i == 1 ? 0.7 : 0.35),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ── Feature Card ───────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gradient icon container
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: gradient[0].withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: gradient[0],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient Button ────────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x404F46E5),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
