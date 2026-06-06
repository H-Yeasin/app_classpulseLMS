import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/parent_role/LearningTipsScreen/models/learning_tip.dart';

class LearningTipsService {
  LearningTipsService._();
  static final LearningTipsService instance = LearningTipsService._();

  final ApiClient _api = ApiClient();
  List<LearningTip>? _cache;

  Future<List<LearningTip>> fetch({bool force = false}) async {
    if (_cache != null && !force) return _cache!;

    final response = await _api.get(ApiConstants.learningTipsByParent);
    final data = response.data;
    final rawTips = (data is Map && data['data'] is Map)
        ? (data['data']['tips'] as List? ?? const [])
        : const [];

    final tips = rawTips
        .map((json) => LearningTip.fromJson(json as Map<String, dynamic>))
        .toList();

    _cache = tips;
    return tips;
  }

  void invalidate() {
    _cache = null;
  }
}
