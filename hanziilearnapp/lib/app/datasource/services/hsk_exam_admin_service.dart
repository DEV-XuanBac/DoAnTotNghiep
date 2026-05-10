import 'package:hanziilearnapp/app/datasource/repository/hsk_exam_admin_repository.dart';
import 'package:hanziilearnapp/app/datasource/validator/hsk_exam_validator.dart';
import 'package:hanziilearnapp/app/models/parsed_hsk_exam_model.dart';

export 'package:hanziilearnapp/app/models/parsed_hsk_exam_model.dart';

class HskExamAdminService {
  HskExamAdminService({
    IHskExamValidator? validator,
    IHskExamAdminRepository? repository,
  }) : _val = validator ?? HskExamValidator(),
       _repo = repository ?? HskExamAdminRepository();

  final IHskExamValidator _val;
  final IHskExamAdminRepository _repo;

  ParsedHskExam parseValid(String rawJson) {
    return _val.parseValid(rawJson);
  }

  Future<void> upload({
    required ParsedHskExam parsed,
    String? sourceFileName,
  }) async {
    await _repo.upload(parsed: parsed, sourceFileName: sourceFileName);
  }
}
