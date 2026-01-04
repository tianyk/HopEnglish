import 'package:equatable/equatable.dart';
import 'package:hopenglish/src/utils.dart';

/// 单词数据模型
class Word extends Equatable {
  /// 唯一标识
  final String id;

  /// 名称（英文）
  final String name;

  /// 图标（emoji），与 image 二选一
  final String? emoji;

  /// 图片路径，与 emoji 二选一，优先使用
  final String? image;

  /// 音频路径
  final String audio;

  const Word({
    required this.id,
    required this.name,
    this.emoji,
    this.image,
    required this.audio,
  }) : assert(emoji != null || image != null, 'emoji 和 image 至少需要一个');

  /// 是否有图片
  bool get hasImage => image != null && image!.isNotEmpty;

  /// 图片是否为网络地址
  bool get isImageNetwork => image != null && isNetworkUrl(image!);

  /// 音频是否为网络地址
  bool get isAudioNetwork => isNetworkUrl(audio);

  /// 获取图片完整路径（自动判断本地/网络）
  String get imagePath {
    if (image == null) return '';
    return isNetworkUrl(image!) ? image! : 'assets/images/words/$image';
  }

  /// 获取音频完整路径（自动判断本地/网络）
  String get audioPath {
    return isNetworkUrl(audio) ? audio : 'assets/audio/words/$audio';
  }

  /// 从 JSON 创建实例
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      image: json['image'] as String?,
      audio: json['audio'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (emoji != null) 'emoji': emoji,
      if (image != null) 'image': image,
      'audio': audio,
    };
  }

  @override
  List<Object?> get props => [id, name, emoji, image, audio];

  @override
  String toString() {
    return 'Word(id: $id, name: $name)';
  }
}
