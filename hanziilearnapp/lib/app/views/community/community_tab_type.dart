import 'package:hanziilearnapp/app/core/constants/community_constants.dart';

enum CommunityTabType { all, interacted, manage }

extension CommunityTabTypeX on CommunityTabType {
  String get label {
    switch (this) {
      case CommunityTabType.all:
        return CommunityConstants.tabAll;
      case CommunityTabType.interacted:
        return CommunityConstants.tabTouched;
      case CommunityTabType.manage:
        return CommunityConstants.tabManage;
    }
  }
}
