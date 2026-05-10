import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/services/admin_vocabulary_service.dart';

class VocabularyCreateTab extends StatefulWidget {
  const VocabularyCreateTab({super.key});

  @override
  State<VocabularyCreateTab> createState() => _VocabularyCreateTabState();
}

class _VocabularyCreateTabState extends State<VocabularyCreateTab> {
  final _formKey = GlobalKey<FormState>();
  final AdminVocabularyService _vocabularyService = AdminVocabularyService();
  static const List<String> _hskLevels = ['HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'];

  final _sttController = TextEditingController();
  final _hanziController = TextEditingController();
  final _pinyinController = TextEditingController();
  final _meaningController = TextEditingController();
  final _topicController = TextEditingController();
  final _ttsUrlController = TextEditingController();
  final _exampleHanziController = TextEditingController();
  final _examplePinyinController = TextEditingController();
  final _exampleMeaningController = TextEditingController();

  bool _saving = false;
  bool _loadingStt = false;
  String _selectedHskLevel = _hskLevels.first;

  @override
  void initState() {
    super.initState();
    _loadNextStt();
  }

  @override
  void dispose() {
    _sttController.dispose();
    _hanziController.dispose();
    _pinyinController.dispose();
    _meaningController.dispose();
    _topicController.dispose();
    _ttsUrlController.dispose();
    _exampleHanziController.dispose();
    _examplePinyinController.dispose();
    _exampleMeaningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final leftPanel = SingleChildScrollView(
          padding: EdgeInsets.all(14.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHintCard(),
                SizedBox(height: 10.h),
                _buildHskLevelDropdown(),
                _buildSttField(),
                _buildTextField(_hanziController, 'Hanzi (từ mới)', required: true),
                _buildTextField(_pinyinController, 'Pinyin', required: true),
                _buildTextField(_meaningController, 'Nghĩa', required: true),
                _buildTextField(_topicController, 'Topic'),
                _buildTextField(_ttsUrlController, 'TTS URL'),
                _buildTextField(_exampleHanziController, 'Ví dụ Hán'),
                _buildTextField(_examplePinyinController, 'Ví dụ pinyin'),
                _buildTextField(_exampleMeaningController, 'Ví dụ dịch'),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveVocabulary,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Đang lưu...' : 'Lưu từ vựng vào Firestore'),
                  ),
                ),
              ],
            ),
          ),
        );

        final rightPanel = SingleChildScrollView(
          padding: EdgeInsets.all(14.w),
          child: _buildVocabularyListSection(),
        );

        if (!isWide) return SingleChildScrollView(child: Column(children: [leftPanel, rightPanel]));

        return Row(
          children: [
            Expanded(flex: 11, child: leftPanel),
            VerticalDivider(width: 1.w, thickness: 1.w, color: AppColors.borderDefault.withValues(alpha: 0.4)),
            Expanded(flex: 10, child: rightPanel),
          ],
        );
      },
    );
  }

  Widget _buildHintCard() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(color: AppColors.lightCardBackground, borderRadius: BorderRadius.circular(12.r)),
    child: Text(
      'Schema lưu vào collection "dictionary": stt, level, hskLevel, hanzi, pinyin, meaning, topic, ttsUrl, exampleHanzi, examplePinyin, exampleMeaning, updatedAt.',
      style: TextStyle(fontSize: 12.sp, color: AppColors.primaryText),
    ),
  );

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false}) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.backgroundWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
      validator: required
          ? (value) => (value ?? '').trim().isEmpty ? 'Không được để trống' : null
          : null,
    ),
  );

  Widget _buildHskLevelDropdown() => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: DropdownButtonFormField<String>(
      key: ValueKey(_selectedHskLevel),
      initialValue: _selectedHskLevel,
      decoration: InputDecoration(
        labelText: 'Level',
        filled: true,
        fillColor: AppColors.backgroundWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
      items: _hskLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
      onChanged: _saving
          ? null
          : (value) async {
              if (value == null || value == _selectedHskLevel) return;
              setState(() => _selectedHskLevel = value);
              await _loadNextStt();
            },
    ),
  );

  Widget _buildSttField() => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: TextFormField(
      controller: _sttController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'STT (tự động)',
        filled: true,
        fillColor: AppColors.backgroundWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        suffixIcon: _loadingStt
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      validator: (value) => (value ?? '').trim().isEmpty ? 'Không lấy được STT tự động' : null,
    ),
  );

  Widget _buildVocabularyListSection() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: AppColors.backgroundWhite,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách từ vựng theo cấp độ $_selectedHskLevel',
          style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 14.sp),
        ),
        SizedBox(height: 10.h),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _vocabularyService.watchWordsByLvl(_selectedHskLevel),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Text('Không tải được danh sách từ vựng.', style: TextStyle(color: AppColors.errorText));
            final docs = snapshot.data ?? const <Map<String, dynamic>>[];
            if (docs.isEmpty) return Text('Chưa có từ vựng cho $_selectedHskLevel.', style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic));
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final data = docs[index];
                final stt = (data['stt'] ?? '').toString();
                final hanzi = (data['hanzi'] ?? '').toString();
                final pinyin = (data['pinyin'] ?? '').toString();
                final meaning = (data['meaning'] ?? '').toString();
                return Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: AppColors.backgroundLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10.r)),
                  child: Text(
                    '$stt. $hanzi [$pinyin] - $meaning',
                    style: TextStyle(color: AppColors.primaryText, fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
  );

  Future<void> _loadNextStt() async {
    setState(() => _loadingStt = true);
    try {
      final nextStt = await _vocabularyService.nextStt(_selectedHskLevel);
      if (!mounted) return;
      _sttController.text = nextStt.toString();
    } catch (_) {
      if (!mounted) return;
      _sttController.clear();
    } finally {
      if (mounted) setState(() => _loadingStt = false);
    }
  }

  Future<void> _saveVocabulary() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final hskLevel = _selectedHskLevel;
      final stt = _sttController.text.trim();
      final hanzi = _hanziController.text.trim();
      await _vocabularyService.saveVocab(
        hskLevel: hskLevel,
        stt: stt,
        hanzi: hanzi,
        pinyin: _pinyinController.text.trim(),
        meaning: _meaningController.text.trim(),
        topic: _topicController.text.trim(),
        ttsUrl: _ttsUrlController.text.trim(),
        exampleHanzi: _exampleHanziController.text.trim(),
        examplePinyin: _examplePinyinController.text.trim(),
        exampleMeaning: _exampleMeaningController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu từ "$hanzi" thành công.')));
      _clearForm();
      await _loadNextStt();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu từ vựng thất bại: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _hanziController.clear();
    _pinyinController.clear();
    _meaningController.clear();
    _topicController.clear();
    _ttsUrlController.clear();
    _exampleHanziController.clear();
    _examplePinyinController.clear();
    _exampleMeaningController.clear();
  }
}
