import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String title;
  final String uploadedBy;
  final String videoUrl;
  final String thumbnailUrl;
  final String cityName;

  Video({
    required this.title,
    required this.uploadedBy,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.cityName,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      title: json['title'],
      uploadedBy: json['uploadedBy'],
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      cityName: json['cityName'],
    );
  }

  factory Video.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Video(
      title: data['title'],
      uploadedBy: data['uploadedBy'],
      videoUrl: data['videoUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      cityName: data['cityName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'uploadedBy': uploadedBy,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'cityName': cityName,
    };
  }
}
