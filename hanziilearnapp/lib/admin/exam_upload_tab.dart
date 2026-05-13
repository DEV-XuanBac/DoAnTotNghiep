import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/services/admin_exam_service.dart';
import 'package:hanziilearnapp/app/datasource/services/hsk_exam_admin_service.dart';

class ExamUploadTab extends StatefulWidget {
  const ExamUploadTab({super.key});

  @override
  State<ExamUploadTab> createState() => _ExamUploadTabState();
}

class _ExamUploadTabState extends State<ExamUploadTab> {
  static const List<String> _hskLevels = ['HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'];
  final TextEditingController _jsonController = TextEditingController();
  final HskExamAdminService _adminService = HskExamAdminService();
  final AdminExamService _examService = AdminExamService();

  bool _isBusy = false;
  String? _pickedFileName;
  ParsedHskExam? _validatedExam;
  String _examListLevel = _hskLevels.first;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final leftPanel = SingleChildScrollView(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHintCard(),
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _pickJsonFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Chọn file JSON'),
              ),
              if (_pickedFileName != null) ...[
                SizedBox(height: 8.h),
                Text(
                  'File đã chọn: $_pickedFileName',
                  style: TextStyle(fontSize: 12.sp, color: context.palette.secondaryText),
                ),
              ],
              SizedBox(height: 12.h),
              TextField(
                controller: _jsonController,
                minLines: 12,
                maxLines: 24,
                readOnly: true,
                style: TextStyle(fontSize: 12.sp),
                decoration: InputDecoration(
                  hintText: 'Nội dung JSON từ file sẽ hiển thị tại đây...',
                  filled: true,
                  fillColor: context.palette.backgroundWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _validateOnly,
                      icon: const Icon(Icons.rule),
                      label: const Text('Kiểm tra cấu trúc'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _uploadExam,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(_isBusy ? 'Đang xử lý...' : 'Upload Firestore'),
                    ),
                  ),
                ],
              ),
              if (_validatedExam != null) ...[
                SizedBox(height: 14.h),
                _buildExamPreview(_validatedExam!),
              ],
            ],
          ),
        );

        final rightPanel = SingleChildScrollView(
          padding: EdgeInsets.all(14.w),
          child: _buildExamListSection(),
        );

        if (!isWide) return SingleChildScrollView(child: Column(children: [leftPanel, rightPanel]));

        return Row(
          children: [
            Expanded(flex: 11, child: leftPanel),
            VerticalDivider(width: 1.w, thickness: 1.w, color: context.palette.borderDefault.withValues(alpha: 0.4)),
            Expanded(flex: 10, child: rightPanel),
          ],
        );
      },
    );
  }

  Widget _buildHintCard() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(color: context.palette.lightCardBackground, borderRadius: BorderRadius.circular(12.r)),
    child: Text(
      'Mẫu đề thi: schema_version, exam_code, level, title, total_questions, time_limit_minutes, audio_listening, sections[]. '
      'HSK1–3: chỉ true_false / single_choice. Từ HSK4 trở lên có thể thêm sort_sentences (đáp án C-A-B), sort_word, write_sentence (hai loại sau dùng options rỗng [ ]).',
      style: TextStyle(fontSize: 12.sp, color: context.palette.primaryText, fontWeight: FontWeight.w500),
    ),
  );

  Widget _buildExamPreview(ParsedHskExam exam) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: context.palette.backgroundWhite,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: context.palette.borderDefault.withValues(alpha: 0.7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đề hợp lệ: ${exam.examCode}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: context.palette.primaryText)),
        SizedBox(height: 6.h),
        Text('Level: ${exam.level} | Sections: ${exam.sectionCount} | Câu hỏi: ${exam.totalQuestions}', style: TextStyle(fontSize: 12.sp, color: context.palette.secondaryText)),
        SizedBox(height: 4.h),
        Text(exam.title, style: TextStyle(fontSize: 13.sp, color: context.palette.primaryText)),
      ],
    ),
  );

  Widget _buildExamListSection() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: context.palette.backgroundWhite,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: context.palette.borderDefault.withValues(alpha: 0.7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Danh sách đề thi theo cấp độ', style: TextStyle(color: context.palette.primaryText, fontWeight: FontWeight.w700, fontSize: 14.sp)),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          key: ValueKey(_examListLevel),
          initialValue: _examListLevel,
          decoration: InputDecoration(labelText: 'Cấp độ HSK', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r))),
          items: _hskLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _examListLevel = value);
          },
        ),
        SizedBox(height: 10.h),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _examService.watchExamsByLvl(_examListLevel),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Text('Không tải được danh sách đề thi.', style: TextStyle(color: context.palette.errorText));
            final docs = snapshot.data ?? const <Map<String, dynamic>>[];
            if (docs.isEmpty) return Text('Chưa có đề thi cho $_examListLevel.', style: TextStyle(color: context.palette.secondaryText, fontStyle: FontStyle.italic));
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final data = docs[index];
                final examCode = (data['examCode'] ?? '').toString();
                final title = (data['title'] ?? '').toString();
                final totalQuestions = (data['totalQuestions'] ?? 0).toString();
                return Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: context.palette.backgroundLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10.r)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$examCode - $title', style: TextStyle(color: context.palette.primaryText, fontWeight: FontWeight.w700, fontSize: 13.sp)),
                    SizedBox(height: 4.h),
                    Text('Số câu: $totalQuestions', style: TextStyle(color: context.palette.secondaryText, fontSize: 12.sp)),
                  ]),
                );
              },
            );
          },
        ),
      ],
    ),
  );

  Future<void> _pickJsonFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['json'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    String? content;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      content = utf8.decode(file.bytes!, allowMalformed: true);
    } else if (file.readStream != null) {
      final bytesBuilder = BytesBuilder();
      await for (final chunk in file.readStream!) {
        bytesBuilder.add(chunk);
      }
      final mergedBytes = bytesBuilder.takeBytes();
      if (mergedBytes.isNotEmpty) content = utf8.decode(mergedBytes, allowMalformed: true);
    }
    if (!mounted || content == null || content.trim().isEmpty) return _showSnackBar('Không đọc được nội dung JSON.');
    setState(() {
      _jsonController.text = content!;
      _pickedFileName = file.name;
      _validatedExam = null;
    });
  }

  Future<void> _validateOnly() async {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) return _showSnackBar('Bạn cần chọn file JSON trước khi kiểm tra.');
    try {
      final parsed = _adminService.parseValid(raw);
      if (!mounted) return;
      setState(() => _validatedExam = parsed);
      _showSnackBar('JSON hợp lệ theo cấu trúc đề thi HSK.');
    } catch (error) {
      _showSnackBar('JSON không hợp lệ: $error');
    }
  }

  Future<void> _uploadExam() async {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) return _showSnackBar('Bạn cần chọn file JSON trước khi upload.');
    setState(() => _isBusy = true);
    try {
      final parsed = _adminService.parseValid(raw);
      await _adminService.upload(parsed: parsed, sourceFileName: _pickedFileName);
      if (!mounted) return;
      setState(() => _validatedExam = parsed);
      _showSnackBar('Upload thành công đề ${parsed.examCode} (${parsed.level}).');
    } catch (error) {
      _showSnackBar('Upload thất bại: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
