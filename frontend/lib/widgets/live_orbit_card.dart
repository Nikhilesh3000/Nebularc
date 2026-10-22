import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'listen_together_button.dart';

class LiveOrbitCard extends StatelessWidget {
  final String username;
  final String songTitle;
  final String songArtist;
  final String songCoverUrl;
  final VoidCallback? onListenTap;

  const LiveOrbitCard({
    super.key,
    required this.username,
    required this.songTitle,
    required this.songArtist,
    required this.songCoverUrl,
    this.onListenTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: avatar + "X is listening to..."
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$username is listening to...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: subtleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Middle: cover + title + artist
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  songCoverUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    color: isDark ? Colors.black26 : Colors.black12,
                    child: const Icon(Icons.music_note, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      songTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      songArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: subtleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Bottom: Listen Together button
          Align(
            alignment: Alignment.centerLeft,
            child: ListenTogetherButton(
              onPressed: onListenTap,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}