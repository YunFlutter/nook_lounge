import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/di/app_providers.dart';

class AppUpdateGuard extends ConsumerWidget {
  const AppUpdateGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateStatus = ref.watch(appUpdateStatusProvider).valueOrNull;
    final remoteVersion = updateStatus?.remoteVersion?.trim();
    final requiresUpdate =
        updateStatus?.requiresUpdate == true &&
        remoteVersion != null &&
        remoteVersion.isNotEmpty;

    if (!requiresUpdate) {
      return child;
    }

    return PopScope(
      canPop: false,
      child: BlockSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ExcludeSemantics(child: child),
            const ModalBarrier(dismissible: false, color: Color(0xB3000000)),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '업데이트가 필요해요',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '현재 사용 중인 버전보다 최신 버전($remoteVersion)이 배포되었어요.\n'
                            '업데이트 전에는 앱을 이용할 수 없어요.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '스토어에서 앱을 업데이트한 뒤 다시 실행해 주세요.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
