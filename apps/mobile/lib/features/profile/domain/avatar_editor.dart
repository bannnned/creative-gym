import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:flutter/widgets.dart';

abstract interface class AvatarEditor {
  Future<SelectedPhoto?> edit(BuildContext context, SelectedPhoto photo);
}
