enum CommunityTabType { all, interacted, manage }

extension CommunityTabTypeX on CommunityTabType {
  String get label {
    switch (this) {
      case CommunityTabType.all:
        return 'Tất cả';
      case CommunityTabType.interacted:
        return 'Đã tương tác';
      case CommunityTabType.manage:
        return 'Quản lý';
    }
  }
}
