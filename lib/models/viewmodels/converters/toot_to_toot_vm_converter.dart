import 'package:intl/intl.dart';
import 'package:toot_ui/models/api/v1/mastodonstatus.dart';
import 'package:toot_ui/models/api/v1/entieties/entity.dart';
import 'package:toot_ui/models/api/v1/entieties/media_entity.dart';
import 'package:toot_ui/models/viewmodels/toot_vm.dart';

class TootToTootVMConverter {
  static const String _PHOTO_TYPE = "photo";
  static const String _VIDEO_TYPE = "video";
  static const String _GIF_TYPE = "animated_gif";
  static const String _TWITTER_URL = "https://twitter.com/";
  static const String _UNKNOWN_SCREEN_NAME = "twitter_unknown";

  final MastodonStatus toot;

  const TootToTootVMConverter(this.toot);

  TootVM convert(DateFormat? createdDateDisplayFormat) {
    return TootVM(
      createdAt: _createdAt(toot, createdDateDisplayFormat),
      allEntities: _allEntities(_originalTootOrRetoot(toot)),
      hasPhoto: _hasPhoto(_originalTootOrRetoot(toot)),
      hasGif: _hasGif(_originalTootOrRetoot(toot)),
      tootLink: _tootLink(toot)!,
      userLink: _userLink(toot)!,
      text: _text(_originalTootOrRetoot(toot)),
      textRunes: _runes(_originalTootOrRetoot(toot)),
      profileUrl: _profileURL(toot),
      allPhotos: _allPhotos(_originalTootOrRetoot(toot)),
      userName: _userName(toot),
      userScreenName: _userScreenName(toot),
      userVerified: _userVerified(toot),
      favouriteCount: _favouriteCount(toot),
      repliesCount: _repliesCount(toot),
      startDisplayText: _startDisplayText(_originalTootOrRetoot(toot)),
      endDisplayText: _endDisplayText(_originalTootOrRetoot(toot)),
      favourited: _favourited(toot),
    );
  }

  static MastodonStatus _originalTootOrRetoot(toot) {
    return toot.retootedStatus != null ? toot.retootedStatus : toot;
  }

  static String _createdAt(MastodonStatus toot, DateFormat? displayFormat) {
    DateFormat twitterFormat =
        new DateFormat("yyyy-MM-ddTHH:mm:ss", 'en_US');
    final dateTime = twitterFormat.parseUTC(toot.createdAt).toLocal();
    return (displayFormat ?? new DateFormat("HH:mm • MM.dd.yyyy", 'en_US'))
        .format(dateTime);
  }

  static bool _isPhotoType(MediaEntity mediaEntity) {
    return _PHOTO_TYPE == mediaEntity.type;
  }

  static bool _isVideoType(MediaEntity mediaEntity) {
    return _VIDEO_TYPE == mediaEntity.type || _GIF_TYPE == mediaEntity.type;
  }

  static bool _isGifType(MediaEntity mediaEntity) {
    return _GIF_TYPE == mediaEntity.type;
  }

  static bool _hasSupportedVideo(MastodonStatus toot) {
    final MediaEntity? entity = _videoEntity(toot);
    return entity != null;
  }

  static MediaEntity? _videoEntity(MastodonStatus toot) {
    try {
      return _allMediaEntities(toot).firstWhere(
        (MediaEntity mediaEntity) => _isVideoType(mediaEntity),
      );
    } catch (e) {
      return null;
    }
  }

  static List<MediaEntity> _allMediaEntities(MastodonStatus toot) {
    return [];
  }

  static List<Entity> _allEntities(MastodonStatus toot) {
    final List<Entity> allEntities = [
    ];
    allEntities.sort((a, b) => a.start.compareTo(b.start));
    return allEntities;
  }

  static MediaEntity? _photoEntity(MastodonStatus toot) {
    final List<MediaEntity> mediaEntityList = _allMediaEntities(toot);
    for (int i = mediaEntityList.length - 1; i >= 0; i--) {
      final MediaEntity entity = mediaEntityList[i];
      if (_isPhotoType(entity)) {
        return entity;
      }
    }
    return null;
  }

  static MediaEntity? _gifEntity(MastodonStatus toot) {
    final List<MediaEntity> mediaEntityList = _allMediaEntities(toot);
    for (int i = mediaEntityList.length - 1; i >= 0; i--) {
      final MediaEntity entity = mediaEntityList[i];
      if (_isGifType(entity)) {
        return entity;
      }
    }
    return null;
  }

  static bool _hasPhoto(MastodonStatus toot) {
    return _photoEntity(toot) != null;
  }

  static bool _hasGif(MastodonStatus toot) {
    return _gifEntity(toot) != null;
  }

  static String? _tootLink(MastodonStatus toot) {
    if (toot.id == "") {
      return null;
    }
    if (toot.account.displayName.isEmpty) {
      return "$_TWITTER_URL$_UNKNOWN_SCREEN_NAME/status/${toot.id}";
    } else {
      return "$_TWITTER_URL${toot.account.displayName}/status/${toot.id}";
    }
  }

  static String? _userLink(MastodonStatus toot) {
    if (toot.id == "") {
      return null;
    }
    if (toot.account.displayName.isEmpty) {
      return "$_TWITTER_URL$_UNKNOWN_SCREEN_NAME";
    } else {
      return "$_TWITTER_URL${toot.account.displayName}";
    }
  }

  static String _text(MastodonStatus toot) {
    return toot.content;
  }

  static Runes _runes(MastodonStatus toot) {
    return toot.content.runes;
  }

  static String? _profileURL(MastodonStatus toot) {
    return toot.account.avatarUrl;
  }

  static List<String> _allPhotos(MastodonStatus toot) {
    return toot.mediaUrls ?? [];
  }

  static String _userName(MastodonStatus toot) {
    return toot.account.username;
  }

  static String _userScreenName(MastodonStatus toot) {
    return toot.account.displayName;
  }

  static TootVM? _quotedToot(
      MastodonStatus? toot, DateFormat? createdDateDisplayFormat) {
    if (toot != null) {
      return TootVM.fromApiModel(toot, createdDateDisplayFormat);
    } else {
      return null;
    }
  }

  static TootVM? _retootedToot(
      MastodonStatus? toot, DateFormat? createdDateDisplayFormat) {
    if (toot != null) {
      return TootVM.fromApiModel(toot, createdDateDisplayFormat);
    } else {
      return null;
    }
  }

  static bool _userVerified(MastodonStatus toot) {
    return toot.account.verified;
  }

  static String? _videoPlaceholderUrl(MastodonStatus toot) {
    return _videoEntity(toot)?.mediaUrlHttps;
  }

  static Map<String, String> _videoUrls(MastodonStatus toot) {
    final List<Variant>? listOfVideoVariants = _videoEntity(toot)
        ?.videoInfo
        ?.variants
        .where((variant) => variant.contentType == 'video/mp4')
        .toList();
    listOfVideoVariants?.sort(
        (variantA, variantB) => variantA.bitrate.compareTo(variantB.bitrate));
    if (listOfVideoVariants != null && listOfVideoVariants.isNotEmpty) {
      return Map.fromIterable(listOfVideoVariants,
          key: (dynamic variant) =>
              (variant as Variant).bitrate.toString() + ' kbps',
          value: (dynamic variant) => (variant as Variant).url);
    } else {
      return {};
    }
  }

  static double? _videoAspectRatio(MastodonStatus toot) {
    VideoInfo? videoInfo = _videoEntity(toot)?.videoInfo;
    if (videoInfo != null) {
      return videoInfo.aspectRatio[0] / videoInfo.aspectRatio[1];
    } else {
      return null;
    }
  }

  static int? _favouriteCount(MastodonStatus toot) {
    return toot.favouritesCount;
  }

  static int? _repliesCount(MastodonStatus toot) {
    return toot.repliesCount;
  }

  static int _startDisplayText(MastodonStatus toot) {
    return 0;
  }

  static int _endDisplayText(MastodonStatus toot) {
    return _runes(toot).length;
  }

  static bool _favourited(MastodonStatus toot) {
    return toot.favourited != null ? toot.favourited! : false;
  }
}
