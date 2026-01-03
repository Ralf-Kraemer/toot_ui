import 'package:intl/intl.dart';
import 'package:toot_ui/models/api/v1/entieties/entity.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'package:toot_ui/models/viewmodels/converters/toot_to_toot_vm_converter.dart';

class TootVM {
  final String? createdAt;
  final List<Entity> allEntities;
  final bool hasPhoto;
  final bool hasGif;
  final String tootLink;
  final String userLink;
  final String text;
  final Runes textRunes;
  final String? profileUrl;
  final List<String> allPhotos;
  final String userName;
  final String userScreenName;
  final TootVM? quotedToot;
  final TootVM? retootedToot;
  final bool userVerified;
  final int? favouriteCount;
  final int? repliesCount;
  final int? startDisplayText;
  final int? endDisplayText;
  final bool favourited;

  const TootVM({
    required this.createdAt,
    required this.allEntities,
    required this.hasPhoto,
    required this.hasGif,
    required this.tootLink,
    required this.userLink,
    required this.text,
    required this.textRunes,
    required this.profileUrl,
    required this.allPhotos,
    required this.userName,
    required this.userScreenName,
    this.quotedToot,
    this.retootedToot,
    required this.userVerified,
    this.favouriteCount,
    this.repliesCount,
    this.startDisplayText,
    this.endDisplayText,
    required this.favourited,
  });

  factory TootVM.fromApiModel(
          MastodonStatus toot, DateFormat? createdDateDisplayFormat) =>
      TootToTootVMConverter(toot).convert(createdDateDisplayFormat);

}

extension ExtendedText on TootVM {
  TootVM getDisplayToot() {
    if (this.retootedToot != null) {
      return retootedToot!;
    } else {
      return this;
    }
  }
}
