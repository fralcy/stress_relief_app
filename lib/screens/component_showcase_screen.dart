import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_modal.dart';
import '../core/widgets/app_slider.dart';
import '../core/widgets/speech_bubble.dart';
import '../core/widgets/app_scroller.dart';

/// Test screen để showcase tất cả UI components
class ComponentShowcaseScreen extends StatefulWidget {
  const ComponentShowcaseScreen({super.key});

  @override
  State<ComponentShowcaseScreen> createState() => _ComponentShowcaseScreenState();
}

class _ComponentShowcaseScreenState extends State<ComponentShowcaseScreen> {
  bool _buttonToggled = false;
  double _volumeValue = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('UI Components Showcase'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
      body: ScrollableColumn(
        padding: const EdgeInsets.all(24),
        children: [
          // Title
          const Text(
            '🎨 UI Components',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Test tất cả các component với theme pastel',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // ========== BUTTONS ==========
          _buildSection(
            title: '🔘 Buttons',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Icon Only:', style: TextStyle(fontSize: 12, color: AppColors.text)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      icon: Icons.home,
                      onPressed: () => _showToast('Home pressed'),
                    ),
                    AppButton(
                      icon: Icons.favorite,
                      isActive: true,
                      onPressed: () => _showToast('Favorite pressed'),
                    ),
                    AppButton(
                      icon: Icons.settings,
                      isDisabled: true,
                      onPressed: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Text('Icon + Text:', style: TextStyle(fontSize: 12, color: AppColors.text)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      icon: Icons.play_arrow,
                      label: 'Play',
                      onPressed: () => _showToast('Play pressed'),
                    ),
                    AppButton(
                      icon: Icons.check,
                      label: 'Toggle',
                      isActive: _buttonToggled,
                      onPressed: () {
                        setState(() => _buttonToggled = !_buttonToggled);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ========== CARDS ==========
          _buildSection(
            title: '🃏 Cards',
            child: Column(
              children: [
                AppCard(
                  title: 'Static Card',
                  content: const Text(
                    'Đây là card thông thường không thể thu gọn. '
                    'Nội dung luôn hiển thị.',
                    style: TextStyle(color: AppColors.text),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                AppCard(
                  title: 'Expandable Card',
                  isExpandable: true,
                  initiallyExpanded: false,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card này có thể thu gọn/mở rộng!',
                        style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhấn vào header để toggle.\n\n'
                        'Rất hữu ích cho Settings hoặc FAQs.',
                        style: TextStyle(color: AppColors.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ========== SLIDERS ==========
          _buildSection(
            title: '🎚️ Sliders',
            child: Column(
              children: [
                AppSlider(
                  value: _volumeValue,
                  onChanged: (val) => setState(() => _volumeValue = val),
                  label: 'Volume',
                  showValue: true,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ========== SPEECH BUBBLES ==========
          _buildSection(
            title: '💬 Speech Bubbles',
            child: Column(
              children: [
                const SpeechBubble(
                  text: 'Chào bạn! Mình là linh vật mèo của ứng dụng đây~ 😊',
                  tailPosition: BubbleTailPosition.bottom,
                ),
                
                const SizedBox(height: 16),
                
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SpeechBubble(
                    text: 'Bạn có muốn nghỉ ngơi không?',
                    tailPosition: BubbleTailPosition.left,
                    maxWidth: 200,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Align(
                  alignment: Alignment.centerRight,
                  child: SpeechBubble(
                    text: 'Tail bên phải này!',
                    tailPosition: BubbleTailPosition.right,
                    maxWidth: 200,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ========== MODAL ==========
          _buildSection(
            title: '📋 Modal',
            child: Center(
              child: AppButton(
                icon: Icons.open_in_new,
                label: 'Open Modal',
                onPressed: () => _showDemoModal(context),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ========== SCROLLER DEMO ==========
          _buildSection(
            title: '📜 Custom Scroller',
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppScroller(
                alwaysShowScrollbar: true,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Scrollable item ${index + 1}',
                        style: const TextStyle(color: AppColors.text),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
  
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showDemoModal(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Demo Modal',
      maxHeight: 500,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modal Header',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đây là nội dung của modal. Nếu nội dung dài, '
            'người dùng có thể scroll xuống để xem thêm.',
            style: TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 24),
          
          // Demo content
          ...List.generate(10, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Scrollable content item ${index + 1}',
                  style: const TextStyle(color: AppColors.text),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Confirm',
                  isActive: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showToast('Confirmed!');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}