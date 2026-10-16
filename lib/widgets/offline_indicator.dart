import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../app/fitgenie_theme.dart';
import '../services/connectivity_service.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityService(),
      builder: (context, child) {
        final isOnline = ConnectivityService().isOnline;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOnline ? 0 : 32,
          width: double.infinity,
          color: FitGenieTheme.hot,
          child: isOnline
              ? const SizedBox.shrink()
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppStrings.get('offline_banner'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Banner style indicator
class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityService(),
      builder: (context, _) {
        final isOnline = ConnectivityService().isOnline;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isOnline ? 0 : 40,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FitGenieTheme.hot,
                    FitGenieTheme.hot.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: isOnline
                  ? const SizedBox.shrink()
                  : SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppStrings.get('offline_mode'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(AppStrings.get('offline_sync_hint'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
