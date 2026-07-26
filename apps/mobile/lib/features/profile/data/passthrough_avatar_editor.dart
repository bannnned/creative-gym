import 'package:creative_gym_mobile/features/profile/domain/avatar_editor.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:flutter/widgets.dart';

class PassthroughAvatarEditor implements AvatarEditor {
  const PassthroughAvatarEditor();

  @override
  Future<SelectedPhoto?> edit(BuildContext context, SelectedPhoto photo) async {
    return photo;
  }
}
