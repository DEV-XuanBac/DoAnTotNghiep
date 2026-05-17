import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/services/admin_post_service.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';
import 'package:hanziilearnapp/app/views/community/community_utils.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_avatar.dart';

enum _PostSearchMode { none, byUser, byContent }

class PostManagementTab extends StatefulWidget {
  const PostManagementTab({super.key});

  @override
  State<PostManagementTab> createState() => _PostManagementTabState();
}

class _PostManagementTabState extends State<PostManagementTab> {
  final AdminPostService _postService = AdminPostService();
  final _usernameController = TextEditingController();
  final _contentQueryController = TextEditingController();
  final _announcementController = TextEditingController();

  _PostSearchMode _searchMode = _PostSearchMode.none;
  String? _selectedUserId;
  String? _selectedUsername;
  List<CommunityPostModel> _contentSearchResults = const [];
  bool _searchingContent = false;
  bool _deletingPostId = false;
  String? _deletingId;
  bool _savingAnnouncement = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAnnouncement();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _contentQueryController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAnnouncement() async {
    final snapshot = await _postService.watchAnnouncement().first;
    if (!mounted || snapshot == null || !snapshot.isVisible) {
      return;
    }
    _announcementController.text = snapshot.content;
  }

  Future<void> _searchByUsername() async {
    final query = _usernameController.text.trim();
    if (query.isEmpty) {
      _showMessage('Vui lòng nhập tên người dùng.');
      return;
    }

    setState(() {
      _searchMode = _PostSearchMode.none;
      _selectedUserId = null;
      _selectedUsername = null;
      _contentSearchResults = const [];
    });

    try {
      final users = await _postService.findUsersByUsername(query);
      if (!mounted) return;
      if (users.isEmpty) {
        _showMessage('Không tìm thấy người dùng phù hợp.');
        return;
      }
      if (users.length == 1) {
        setState(() {
          _searchMode = _PostSearchMode.byUser;
          _selectedUserId = users.first.userId;
          _selectedUsername = users.first.username;
        });
        return;
      }

      final picked = await showDialog<({String userId, String username})>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn người dùng'),
          content: SizedBox(
            width: 420,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.username),
                  subtitle: Text(user.userId),
                  onTap: () => Navigator.pop(context, user),
                );
              },
            ),
          ),
        ),
      );
      if (!mounted || picked == null) return;
      setState(() {
        _searchMode = _PostSearchMode.byUser;
        _selectedUserId = picked.userId;
        _selectedUsername = picked.username;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('Lỗi tìm kiếm: $error');
    }
  }

  Future<void> _searchByContent() async {
    final query = _contentQueryController.text.trim();
    if (query.isEmpty) {
      _showMessage('Vui lòng nhập nội dung cần lọc.');
      return;
    }

    setState(() {
      _searchMode = _PostSearchMode.none;
      _selectedUserId = null;
      _selectedUsername = null;
      _searchingContent = true;
      _contentSearchResults = const [];
    });

    try {
      final posts = await _postService.searchPostsByContent(query);
      if (!mounted) return;
      setState(() {
        _searchMode = _PostSearchMode.byContent;
        _contentSearchResults = posts;
        _searchingContent = false;
      });
      if (posts.isEmpty) {
        _showMessage('Không có bài đăng nào chứa câu đã nhập.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _searchingContent = false);
      _showMessage('Lỗi lọc bài đăng: $error');
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài đăng'),
        content: const Text('Bạn có chắc muốn xóa bài đăng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingPostId = true;
      _deletingId = postId;
    });
    try {
      await _postService.deletePost(postId);
      if (!mounted) return;
      if (_searchMode == _PostSearchMode.byContent) {
        setState(() {
          _contentSearchResults =
              _contentSearchResults.where((post) => post.postId != postId).toList();
        });
      }
      _showMessage('Đã xóa bài đăng.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Không xóa được bài đăng: $error');
    } finally {
      if (mounted) {
        setState(() {
          _deletingPostId = false;
          _deletingId = null;
        });
      }
    }
  }

  Future<void> _saveAnnouncement() async {
    final content = _announcementController.text.trim();
    if (content.isEmpty) {
      _showMessage('Vui lòng nhập nội dung thông báo.');
      return;
    }

    setState(() => _savingAnnouncement = true);
    try {
      await _postService.saveAnnouncement(content);
      if (!mounted) return;
      _showMessage('Đã đăng thông báo lên trang cộng đồng.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Không lưu được thông báo: $error');
    } finally {
      if (mounted) {
        setState(() => _savingAnnouncement = false);
      }
    }
  }

  Future<void> _clearAnnouncement() async {
    setState(() => _savingAnnouncement = true);
    try {
      await _postService.clearAnnouncement();
      if (!mounted) return;
      _announcementController.clear();
      _showMessage('Đã gỡ thông báo khỏi trang cộng đồng.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Không gỡ được thông báo: $error');
    } finally {
      if (mounted) {
        setState(() => _savingAnnouncement = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              _buildUsernameSearchSection(),
              SizedBox(height: 14.h),
              _buildContentSearchSection(),
              SizedBox(height: 14.h),
              _buildAnnouncementSection(),
            ],
          ),
        );

        final rightPanel = Padding(
          padding: EdgeInsets.all(14.w),
          child: _buildResultsSection(),
        );

        if (!isWide) {
          return SingleChildScrollView(
            child: Column(children: [leftPanel, rightPanel]),
          );
        }

        return Row(
          children: [
            Expanded(flex: 11, child: leftPanel),
            VerticalDivider(
              width: 1.w,
              thickness: 1.w,
              color: context.palette.borderDefault.withValues(alpha: 0.4),
            ),
            Expanded(flex: 10, child: rightPanel),
          ],
        );
      },
    );
  }

  Widget _buildHintCard() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: context.palette.lightCardBackground,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Text(
      'Tìm bài đăng theo tên người dùng (usename_vie) hoặc lọc theo cụm từ trong nội dung. '
      'Thông báo cộng đồng lưu tại Firestore doc community_config/announcement và luôn hiển thị đầu trang Cộng đồng.',
      style: TextStyle(fontSize: 12.sp, color: context.palette.primaryText),
    ),
  );

  Widget _buildUsernameSearchSection() => _sectionCard(
    title: 'Tìm theo tên người dùng',
    child: Column(
      children: [
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Tên người dùng',
            hintText: 'Nhập usename_vie...',
            filled: true,
            fillColor: context.palette.backgroundWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
          onSubmitted: (_) => _searchByUsername(),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _searchByUsername,
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('Tìm bài đăng của người dùng'),
          ),
        ),
      ],
    ),
  );

  Widget _buildContentSearchSection() => _sectionCard(
    title: 'Lọc theo nội dung bài đăng',
    child: Column(
      children: [
        TextField(
          controller: _contentQueryController,
          decoration: InputDecoration(
            labelText: 'Cụm từ trong bài đăng',
            hintText: 'Nhập câu hoặc từ khóa...',
            filled: true,
            fillColor: context.palette.backgroundWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
          onSubmitted: (_) => _searchByContent(),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _searchingContent ? null : _searchByContent,
            icon: const Icon(Icons.manage_search_rounded),
            label: Text(_searchingContent ? 'Đang lọc...' : 'Lọc toàn bộ bài đăng'),
          ),
        ),
      ],
    ),
  );

  Widget _buildAnnouncementSection() => _sectionCard(
    title: 'Thông báo trang cộng đồng',
    child: Column(
      children: [
        TextField(
          controller: _announcementController,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'Nội dung thông báo',
            hintText: 'Thông báo sẽ luôn hiện ở đầu trang Cộng đồng...',
            filled: true,
            fillColor: context.palette.backgroundWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _savingAnnouncement ? null : _saveAnnouncement,
                icon: const Icon(Icons.campaign_rounded),
                label: Text(_savingAnnouncement ? 'Đang lưu...' : 'Đăng thông báo'),
              ),
            ),
            SizedBox(width: 8.w),
            OutlinedButton(
              onPressed: _savingAnnouncement ? null : _clearAnnouncement,
              child: const Text('Gỡ thông báo'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _sectionCard({required String title, required Widget child}) => Container(
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
        Text(
          title,
          style: TextStyle(
            color: context.palette.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 10.h),
        child,
      ],
    ),
  );

  Widget _buildResultsSection() {
    if (_searchMode == _PostSearchMode.byUser && _selectedUserId != null) {
      return _buildUserPostsResult();
    }
    if (_searchMode == _PostSearchMode.byContent) {
      return _buildContentPostsResult();
    }

    return Center(
      child: Text(
        'Kết quả tìm kiếm sẽ hiển thị tại đây.',
        style: TextStyle(
          color: context.palette.secondaryText,
          fontSize: 14.sp,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUserPostsResult() {
    final username = _selectedUsername ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bài đăng của: $username',
          style: TextStyle(
            color: context.palette.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 10.h),
        Expanded(
          child: StreamBuilder<List<CommunityPostModel>>(
            stream: _postService.watchPostsByUserId(_selectedUserId!),
            builder: (context, snapshot) => _buildPostsList(snapshot),
          ),
        ),
      ],
    );
  }

  Widget _buildContentPostsResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả lọc nội dung (${_contentSearchResults.length})',
          style: TextStyle(
            color: context.palette.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 10.h),
        Expanded(
          child: _contentSearchResults.isEmpty
              ? Center(
                  child: Text(
                    'Không có bài đăng phù hợp.',
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 13.sp,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _contentSearchResults.length,
                  itemBuilder: (context, index) =>
                      _buildPostTile(_contentSearchResults[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPostsList(AsyncSnapshot<List<CommunityPostModel>> snapshot) {
    if (snapshot.hasError) {
      return Center(child: Text('Lỗi tải bài đăng: ${snapshot.error}'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final posts = snapshot.data ?? const <CommunityPostModel>[];
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'Người dùng này chưa có bài đăng.',
          style: TextStyle(color: context.palette.secondaryText, fontSize: 13.sp),
        ),
      );
    }
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostTile(posts[index]),
    );
  }

  Widget _buildPostTile(CommunityPostModel post) {
    final isDeleting = _deletingPostId && _deletingId == post.postId;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.palette.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.palette.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommunityAvatar(avatar: post.userAvatar, size: 32),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName.trim().isEmpty ? 'Người dùng' : post.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    Text(
                      formatCommunityTimeAgo(post.createdAt),
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: isDeleting ? null : () => _deletePost(post.postId),
                child: Text(
                  isDeleting ? 'Đang xóa...' : 'Xóa',
                  style: TextStyle(color: context.palette.errorText),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(post.content, style: TextStyle(fontSize: 13.sp)),
          SizedBox(height: 4.h),
          Text(
            'ID: ${post.postId}',
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}
