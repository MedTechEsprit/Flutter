import 'package:diab_care/core/services/walkthrough_service.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RoleWalkthroughDialog extends StatefulWidget {
  final String roleTitle;
  final List<WalkthroughStepData> steps;
  final VoidCallback onCompleted;

  const RoleWalkthroughDialog({
    super.key,
    required this.roleTitle,
    required this.steps,
    required this.onCompleted,
  });

  @override
  State<RoleWalkthroughDialog> createState() => _RoleWalkthroughDialogState();
}

class _RoleWalkthroughDialogState extends State<RoleWalkthroughDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == widget.steps.length - 1;

  Future<void> _next() async {
    if (_isLastPage) {
      widget.onCompleted();
      Navigator.of(context).pop();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Guide ${widget.roleTitle}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onCompleted();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Passer'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Premiere connexion detectee: voici vos fonctionnalites cles.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.steps.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final step = widget.steps[index];
                    return Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF4FBF8), Color(0xFFE7F6EF)],
                        ),
                        border: Border.all(
                          color: AppColors.softGreen.withOpacity(0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.softGreen.withOpacity(0.6),
                              ),
                            ),
                            child: Text(
                              step.tabLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.softGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: AppColors.textSecondary.withOpacity(0.95),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Etape ${index + 1}/${widget.steps.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: index == _currentPage ? 26 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: index == _currentPage
                          ? AppColors.softGreen
                          : AppColors.softGreen.withOpacity(0.25),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_isLastPage ? 'Terminer' : 'Suivant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
