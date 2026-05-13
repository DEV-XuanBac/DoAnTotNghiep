import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

ImageProvider hskExamImageProvider(String imagePath) {
  if (imagePath.startsWith('http')) {
    return NetworkImage(imagePath);
  }
  return AssetImage(imagePath);
}

/// Ảnh minh họa câu hỏi (tap để phóng to).
class HskExamQuestionImageTile extends StatelessWidget {
  const HskExamQuestionImageTile({
    super.key,
    required this.imagePath,
    required this.imageHeight,
    required this.onTap,
  });

  final String imagePath;
  final double imageHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageProvider = hskExamImageProvider(imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    color: context.palette.backgroundWhite,
                    child: Text(
                      'Không tải được ảnh minh họa: $imagePath',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.palette.secondaryText,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Icon(
                    Icons.zoom_out_map_rounded,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showHskExamQuestionImageViewer(
  BuildContext context, {
  required String imagePath,
}) async {
  final imageProvider = hskExamImageProvider(imagePath);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.all(12.w),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Padding(
                        padding: EdgeInsets.all(14.w),
                        child: Text(
                          'Không tải được ảnh minh họa.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8.w,
              top: 8.h,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}
