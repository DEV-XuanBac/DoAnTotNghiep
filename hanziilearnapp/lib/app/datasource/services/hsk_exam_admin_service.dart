import 'package:hanziilearnapp/app/datasource/repository/hsk_exam_admin_repository.dart';
import 'package:hanziilearnapp/app/datasource/validator/hsk_exam_validator.dart';
import 'package:hanziilearnapp/app/models/parsed_hsk_exam_model.dart';

export 'package:hanziilearnapp/app/models/parsed_hsk_exam_model.dart';

class HskExamAdminService {
  HskExamAdminService({
    IHskExamValidator? validator,
    IHskExamAdminRepository? repository,
  }) : _validator = validator ?? HskExamValidator(),
       _repository = repository ?? HskExamAdminRepository();

  final IHskExamValidator _validator;
  final IHskExamAdminRepository _repository;

  ParsedHskExam parseAndValidate(String rawJson) {
    return _validator.parseAndValidate(rawJson);
  }

  Future<void> uploadExam({
    required ParsedHskExam parsed,
    String? sourceFileName,
  }) async {
    await _repository.uploadExam(parsed: parsed, sourceFileName: sourceFileName);
  }
}
