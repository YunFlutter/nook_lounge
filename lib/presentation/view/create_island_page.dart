import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/create_island_draft.dart';
import 'package:nook_lounge_app/presentation/state/create_island_view_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';

class CreateIslandPage extends ConsumerStatefulWidget {
  const CreateIslandPage({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<CreateIslandPage> createState() => _CreateIslandPageState();
}

class _CreateIslandPageState extends ConsumerState<CreateIslandPage> {
  final _formKey = GlobalKey<FormState>();
  final _islandNameController = TextEditingController();
  final _representativeController = TextEditingController();

  String _hemisphere = '북반구';
  String _nativeFruit = '복숭아';

  ProviderSubscription<CreateIslandViewState>? _createSubscription;

  @override
  void initState() {
    super.initState();

    _createSubscription = ref.listenManual<CreateIslandViewState>(
      createIslandViewModelProvider,
      (previous, next) async {
        if (next.errorMessage != null &&
            next.errorMessage != previous?.errorMessage) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));

          ref.read(createIslandViewModelProvider.notifier).clearError();
          return;
        }

        if (next.submitSuccess && previous?.submitSuccess != true) {
          await ref.read(sessionViewModelProvider.notifier).refresh();
          ref.read(createIslandViewModelProvider.notifier).resetSubmitState();
        }
      },
    );
  }

  @override
  void dispose() {
    _createSubscription?.close();
    _islandNameController.dispose();
    _representativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createIslandViewModelProvider);
    final viewModel = ref.read(createIslandViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('여권 만들기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AnimatedFadeSlide(
                child: Text(
                  '나만의 여권을 등록해볼까요?',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              const AnimatedFadeSlide(
                delay: Duration(milliseconds: 30),
                child: Text('당신의 섬 정보를 입력해 주세요.'),
              ),
              const SizedBox(height: 24),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 60),
                child: TextFormField(
                  controller: _islandNameController,
                  decoration: const InputDecoration(labelText: '섬 이름'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '섬 이름을 입력해 주세요.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 90),
                child: TextFormField(
                  controller: _representativeController,
                  decoration: const InputDecoration(labelText: '대표 주민 이름'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '대표 주민 이름을 입력해 주세요.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 18),
              const AnimatedFadeSlide(
                delay: Duration(milliseconds: 120),
                child: Text('반구 선택'),
              ),
              const SizedBox(height: 8),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 140),
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('북반구'),
                      selected: _hemisphere == '북반구',
                      onSelected: (_) => setState(() => _hemisphere = '북반구'),
                    ),
                    ChoiceChip(
                      label: const Text('남반구'),
                      selected: _hemisphere == '남반구',
                      onSelected: (_) => setState(() => _hemisphere = '남반구'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const AnimatedFadeSlide(
                delay: Duration(milliseconds: 170),
                child: Text('특산물'),
              ),
              const SizedBox(height: 8),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 190),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <String>['사과', '체리', '오렌지', '복숭아', '배']
                      .map(
                        (fruit) => ChoiceChip(
                          label: Text(fruit),
                          selected: _nativeFruit == fruit,
                          onSelected: (_) =>
                              setState(() => _nativeFruit = fruit),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 220),
                child: FilledButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          final draft = CreateIslandDraft(
                            islandName: _islandNameController.text.trim(),
                            representativeName: _representativeController.text
                                .trim(),
                            hemisphere: _hemisphere,
                            nativeFruit: _nativeFruit,
                          );

                          await viewModel.createIsland(
                            uid: widget.uid,
                            draft: draft,
                          );
                        },
                  child: Text(state.isSubmitting ? '등록 중...' : '섬 등록하고 시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
