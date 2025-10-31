import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';

/// Modal sáng tác nhạc
class MusicModal extends StatefulWidget {
  const MusicModal({super.key});

  @override
  State<MusicModal> createState() => _MusicModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    if (!context.mounted) return;
    
    return AppModal.show(
      context: context,
      title: l10n.music,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const MusicModal(),
    );
  }
}

class _MusicModalState extends State<MusicModal> {
  final TextEditingController _nameController = TextEditingController();
  
  String _songName = 'My Song';
  bool _isEditingName = false;
  
  // Music settings
  static const int _bpm = 120;
  static const int _timeSignature = 4; // 4/4
  static const int _durationSeconds = 8;
  static const int _beatsPerBar = 4;
  
  // Calculate total beats: 8 seconds * 120 BPM / 60 = 16 beats
  static const int _totalBeats = (_durationSeconds * _bpm) ~/ 60;
  
  // Selected instrument and note
  InstrumentType _selectedInstrument = InstrumentType.piano;
  String? _selectedNote;
  
  // Timeline grid: [beat][track] -> note or null
  // 5 tracks for 5 instruments, 16 beats
  final List<List<String?>> _timeline = List.generate(
    _totalBeats,
    (_) => List.filled(5, null),
  );
  
  // Current playback position (0-16)
  int _playbackPosition = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _songName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onEditName() {
    SfxService().buttonClick();
    setState(() {
      _isEditingName = true;
    });
  }

  Future<void> _onSaveName() async {
    SfxService().buttonClick();
    
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _nameController.text = _songName;
      setState(() {
        _isEditingName = false;
      });
      return;
    }
    
    setState(() {
      _songName = newName;
      _isEditingName = false;
    });
  }

  void _onCancelEdit() {
    SfxService().buttonClick();
    _nameController.text = _songName;
    setState(() {
      _isEditingName = false;
    });
  }

  void _onInstrumentSelected(InstrumentType instrument) {
    SfxService().buttonClick();
    setState(() {
      _selectedInstrument = instrument;
    });
  }

  void _onNoteSelected(String note) {
    SfxService().buttonClick();
    setState(() {
      _selectedNote = note;
    });
  }

  void _onTimelineGridTap(int beatIndex) {
    if (_selectedNote == null) return;
    
    SfxService().buttonClick();
    
    final trackIndex = _selectedInstrument.index;
    
    setState(() {
      // Toggle: if same note exists, remove it; otherwise place it
      if (_timeline[beatIndex][trackIndex] == _selectedNote) {
        _timeline[beatIndex][trackIndex] = null;
      } else {
        _timeline[beatIndex][trackIndex] = _selectedNote;
      }
    });
  }

  void _onPlay() {
    SfxService().buttonClick();
    // TODO: Implement playback
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _onPause() {
    SfxService().buttonClick();
    setState(() {
      _isPlaying = false;
    });
  }

  void _onStop() {
    SfxService().buttonClick();
    setState(() {
      _isPlaying = false;
      _playbackPosition = 0;
    });
  }

  void _onSave() {
    SfxService().buttonClick();
    // TODO: Implement save
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========== SONG NAME ==========
          _buildSongNameSection(l10n, theme),
          
          const SizedBox(height: 16),
          
          // ========== TIMELINE ==========
          _buildTimeline(theme),
          
          const SizedBox(height: 16),
          
          // ========== PLAYBACK CONTROLS ==========
          _buildPlaybackControls(l10n),
          
          const SizedBox(height: 24),
          
          // ========== INSTRUMENT SELECTION ==========
          _buildInstrumentSection(l10n, theme),
          
          const SizedBox(height: 16),
          
          // ========== NOTE SELECTION ==========
          _buildNoteSection(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildSongNameSection(AppLocalizations l10n, dynamic theme) {
    return Row(
      children: [
        Text(
          '${l10n.songName}: ',
          style: TextStyle(
            color: theme.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        if (_isEditingName) ...[
          Expanded(
            child: TextField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.primary),
                ),
              ),
              onSubmitted: (_) => _onSaveName(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onSaveName,
            child: const Text('✓', style: TextStyle(fontSize: 20, color: Colors.green)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onCancelEdit,
            child: const Text('✗', style: TextStyle(fontSize: 20, color: Colors.red)),
          ),
        ] else ...[
          Text(
            _songName,
            style: TextStyle(
              color: theme.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onEditName,
            child: const Text('✏️', style: TextStyle(fontSize: 16)),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeline(dynamic theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.border, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: theme.background,
      ),
      child: Column(
        children: [
          // Timeline grid
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Instrument labels column
                  Container(
                    width: 60,
                    color: theme.primary.withOpacity(0.1),
                    child: Column(
                      children: InstrumentType.values.map((instrument) {
                        return Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: theme.border, width: 1),
                            ),
                          ),
                          child: Text(
                            _getInstrumentEmoji(instrument),
                            style: const TextStyle(fontSize: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Timeline beats
                  ...List.generate(_totalBeats, (beatIndex) {
                    return Container(
                      width: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: beatIndex % _beatsPerBar == 0 
                                ? theme.border 
                                : theme.border.withOpacity(0.3),
                            width: beatIndex % _beatsPerBar == 0 ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: List.generate(5, (trackIndex) {
                          final hasNote = _timeline[beatIndex][trackIndex] != null;
                          final isPlaybackPosition = beatIndex == _playbackPosition && _isPlaying;
                          
                          return GestureDetector(
                            onTap: () => _onTimelineGridTap(beatIndex),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPlaybackPosition
                                    ? theme.secondary.withOpacity(0.3)
                                    : hasNote
                                        ? Colors.black
                                        : theme.background,
                                border: Border(
                                  bottom: BorderSide(color: theme.border, width: 1),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // Progress bar
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LinearProgressIndicator(
              value: _isPlaying ? _playbackPosition / _totalBeats : 0,
              backgroundColor: theme.border,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppButton(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: _isPlaying ? _onPause : _onPlay,
          width: 56,
        ),
        const SizedBox(width: 12),
        AppButton(
          icon: Icons.stop,
          onPressed: _onStop,
          width: 56,
        ),
        const SizedBox(width: 12),
        AppButton(
          icon: Icons.save,
          onPressed: _onSave,
          width: 56,
        ),
      ],
    );
  }

  Widget _buildInstrumentSection(AppLocalizations l10n, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectInstrument,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: InstrumentType.values.map((instrument) {
              final isSelected = instrument == _selectedInstrument;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _onInstrumentSelected(instrument),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.secondary : theme.primary,
                      border: Border.all(
                        color: isSelected ? theme.text : theme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getInstrumentEmoji(instrument),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getInstrumentName(instrument, l10n),
                          style: TextStyle(
                            color: theme.background,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(AppLocalizations l10n, dynamic theme) {
    final notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C2'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notes,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: notes.map((note) {
            final isSelected = note == _selectedNote;
            return GestureDetector(
              onTap: () => _onNoteSelected(note),
              child: Container(
                width: 60,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? theme.secondary : theme.primary,
                  border: Border.all(
                    color: isSelected ? theme.text : theme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note,
                  style: TextStyle(
                    color: theme.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (_selectedNote != null)
          Row(
            children: [
              Text(
                '${l10n.selected}: ',
                style: TextStyle(color: theme.text, fontSize: 14),
              ),
              Text(
                '${_getInstrumentEmoji(_selectedInstrument)} • ${l10n.note}: $_selectedNote',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _getInstrumentEmoji(InstrumentType instrument) {
    switch (instrument) {
      case InstrumentType.piano:
        return '🎹';
      case InstrumentType.guitar:
        return '🎸';
      case InstrumentType.synth:
        return '🎛️';
      case InstrumentType.bass:
        return '🎻';
      case InstrumentType.drum:
        return '🥁';
    }
  }

  String _getInstrumentName(InstrumentType instrument, AppLocalizations l10n) {
    switch (instrument) {
      case InstrumentType.piano:
        return l10n.piano;
      case InstrumentType.guitar:
        return l10n.guitar;
      case InstrumentType.synth:
        return l10n.synth;
      case InstrumentType.bass:
        return l10n.bass;
      case InstrumentType.drum:
        return l10n.drum;
    }
  }
}

enum InstrumentType {
  piano,
  guitar,
  synth,
  bass,
  drum,
}