import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_theme.dart';
import '../core/l10n/app_localizations.dart';
import '../core/utils/sfx_service.dart';

/// Tutorial Screen với phong cách doc-style
class MobilePortraitTutorialScreen extends StatefulWidget {
  const MobilePortraitTutorialScreen({super.key});

  @override
  State<MobilePortraitTutorialScreen> createState() => _MobilePortraitTutorialScreenState();
}

class _MobilePortraitTutorialScreenState extends State<MobilePortraitTutorialScreen> {
  int _currentPage = 0;
  final int _totalPages = 6;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    SfxService().buttonClick();
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    SfxService().buttonClick();
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    SfxService().buttonClick();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          l10n.tutorialTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(theme, l10n),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _buildOverviewPage(theme, l10n),
                _buildPointsPage(theme, l10n),
                _buildLifeSupportPage(theme, l10n),
                _buildRewardingPage(theme, l10n),
                _buildCreativePage(theme, l10n),
                _buildSettingsPage(theme, l10n),
              ],
            ),
          ),
          
          // Navigation controls
          _buildNavigationControls(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(AppTheme theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Page indicator text
          Text(
            l10n.tutorialPageOf(_currentPage + 1, _totalPages),
            style: TextStyle(
              color: theme.text.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Progress bar with animation
          Row(
            children: List.generate(_totalPages, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(
                    right: index < _totalPages - 1 ? 4 : 0,
                  ),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= _currentPage 
                        ? theme.primary 
                        : theme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: index <= _currentPage ? [
                      BoxShadow(
                        color: theme.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPageScaffold({
    required AppTheme theme,
    required String title,
    required String content,
    String? emoji,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with emoji and animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (emoji != null) ...[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content with enhanced styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.secondary.withOpacity(0.15),
                  theme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: theme.text,
                height: 1.7,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPage(AppTheme theme, AppLocalizations l10n) {
    return _buildPageScaffold(
      theme: theme,
      title: l10n.tutorialOverviewTitle,
      content: l10n.tutorialOverviewDesc,
      emoji: '🏠',
    );
  }

  Widget _buildPointsPage(AppTheme theme, AppLocalizations l10n) {
    return _buildPageScaffold(
      theme: theme,
      title: l10n.tutorialPointsTitle,
      content: l10n.tutorialPointsDesc,
      emoji: '💎',
    );
  }

  Widget _buildLifeSupportPage(AppTheme theme, AppLocalizations l10n) {
    return _buildPageScaffold(
      theme: theme,
      title: l10n.tutorialLifestyleSupportTitle,
      content: l10n.tutorialLifestyleSupportDesc,
      emoji: '📋',
    );
  }

  Widget _buildRewardingPage(AppTheme theme, AppLocalizations l10n) {
    return _buildPageScaffold(
      theme: theme,
      title: l10n.tutorialRewardingTitle,
      content: l10n.tutorialRewardingDesc,
      emoji: '🎮',
    );
  }

  Widget _buildCreativePage(AppTheme theme, AppLocalizations l10n) {
    return _buildPageScaffold(
      theme: theme,
      title: l10n.tutorialCreativeTitle,
      content: l10n.tutorialCreativeDesc,
      emoji: '🎨',
    );
  }

  Widget _buildSettingsPage(AppTheme theme, AppLocalizations l10n) {
    return _buildPageScaffold(
      theme: theme,
      title: l10n.tutorialSettingsTitle,
      content: l10n.tutorialSettingsDesc,
      emoji: '⚙️',
    );
  }

  Widget _buildNavigationControls(AppTheme theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: _currentPage > 0 
                  ? Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: theme.secondary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        label: Text(
                          l10n.tutorialPrevious,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondary,
                          foregroundColor: theme.text,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            
            const SizedBox(width: 12),
            
            // Skip button
            Expanded(
              child: Container(
                height: 50,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.border,
                    foregroundColor: theme.text,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    l10n.tutorialSkip,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Next/Got it button
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _currentPage < _totalPages - 1 ? _nextPage : _finish,
                  icon: Icon(
                    _currentPage < _totalPages - 1 
                        ? Icons.arrow_forward_ios 
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    _currentPage < _totalPages - 1 
                        ? l10n.tutorialNext 
                        : l10n.tutorialGotIt,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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