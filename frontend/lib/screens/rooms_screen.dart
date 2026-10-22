import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import '../widgets/aurora_background.dart';
import 'room_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _roomNameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;
  bool _isPublic = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  void _createRoom() {
    final name = _roomNameController.text.trim();
    if (name.isEmpty) {
      _snack('Please enter a room name');
      return;
    }
    setState(() => _isCreating = true);
    final service = context.read<SocketService>();

    void listener() {
      if (service.currentRoom != null) {
        service.removeListener(listener);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoomScreen()),
          );
        }
      }
    }

    service.addListener(listener);
    service.createRoom(name, isPublic: _isPublic);

    Future.delayed(const Duration(seconds: 5), () {
      service.removeListener(listener);
      if (mounted && service.currentRoom == null) {
        setState(() => _isCreating = false);
        _snack('Backend did not respond');
      }
    });
  }

  void _joinRoom() {
    final code = _roomCodeController.text.trim();
    if (code.length != 6) {
      _snack('Enter a 6-digit room code');
      return;
    }
    setState(() => _isJoining = true);
    final service = context.read<SocketService>();

    void listener() {
      if (service.currentRoom != null) {
        service.removeListener(listener);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoomScreen()),
          );
        }
      }
    }

    service.addListener(listener);
    service.joinRoom(code);

    Future.delayed(const Duration(seconds: 5), () {
      service.removeListener(listener);
      if (mounted && service.currentRoom == null) {
        setState(() => _isJoining = false);
        _snack('Room not found');
      }
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ---------- Header ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: textColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '🌌  Social Rooms',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ---------- Body ----------
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start a shared listening session',
                        style: TextStyle(fontSize: 13, color: subtleColor),
                      ),
                      const SizedBox(height: 32),

                      // ================================================
                      // CREATE ROOM
                      // ================================================
                      _SectionTitle(
                        icon: Icons.add_circle_outline,
                        text: 'Create a Room',
                        color: textColor,
                      ),
                      const SizedBox(height: 14),

                      _InputField(
                        controller: _roomNameController,
                        hint: 'e.g. Friday Night Vibes',
                        isDark: isDark,
                        surface: surface,
                        textColor: textColor,
                        subtleColor: subtleColor,
                      ),
                      const SizedBox(height: 14),

                      // ---------- Public/Private toggle ----------
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPublic
                                  ? Icons.public
                                  : Icons.lock_outline,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPublic ? 'Public Room' : 'Private Room',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    _isPublic
                                        ? 'Anyone can find and join'
                                        : 'Only people with the code',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPublic,
                              onChanged: (v) =>
                                  setState(() => _isPublic = v),
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      _GradientButton(
                        label: 'Create Room',
                        icon: Icons.add,
                        isLoading: _isCreating,
                        onPressed: _createRoom,
                      ),

                      const SizedBox(height: 32),

                      // ---------- Divider ----------
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: subtleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ================================================
                      // JOIN ROOM
                      // ================================================
                      _SectionTitle(
                        icon: Icons.login,
                        text: 'Join a Room',
                        color: textColor,
                      ),
                      const SizedBox(height: 14),

                      _InputField(
                        controller: _roomCodeController,
                        hint: '000000',
                        isDark: isDark,
                        surface: surface,
                        textColor: textColor,
                        subtleColor: subtleColor,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        isCentered: true,
                        isCodeStyle: true,
                      ),
                      const SizedBox(height: 18),

                      _GradientButton(
                        label: 'Join Room',
                        icon: Icons.login,
                        isLoading: _isJoining,
                        onPressed: _joinRoom,
                      ),

                      const SizedBox(height: 40),

                      // ---------- Hint ----------
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tips_and_updates_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Share your room code with friends so they can tune in.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Section Title
// ============================================================================
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Themed Input Field
// ============================================================================
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final Color surface;
  final Color textColor;
  final Color subtleColor;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool isCentered;
  final bool isCodeStyle;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.isDark,
    required this.surface,
    required this.textColor,
    required this.subtleColor,
    this.keyboardType,
    this.maxLength,
    this.isCentered = false,
    this.isCodeStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textAlign: isCentered ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: textColor,
          fontSize: isCodeStyle ? 24 : 15,
          fontWeight: isCodeStyle ? FontWeight.bold : FontWeight.w500,
          letterSpacing: isCodeStyle ? 8 : 0,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: subtleColor,
            fontSize: isCodeStyle ? 24 : 14,
            letterSpacing: isCodeStyle ? 8 : 0,
            fontWeight: isCodeStyle ? FontWeight.bold : FontWeight.w400,
          ),
          counterText: '',
          filled: true,
          fillColor: surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isCodeStyle ? 22 : 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Gradient Button (reusable)
// ============================================================================
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pink.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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