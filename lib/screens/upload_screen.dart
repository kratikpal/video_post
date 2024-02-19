import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/video_model.dart';

class UploadScreen extends StatefulWidget {
  final String uid;
  const UploadScreen({super.key, required this.uid});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  VideoPlayerController? _videoController;
  final _titleController = TextEditingController();
  late bool _isUploading;
  String? _videoUrl;
  String? _thumbnailUrl;
  String? _username;
  String _title = '';

  Future<void> _getUser() async {
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    if (userData.exists) {
      setState(() {
        _username = userData['username'] ?? '';
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    XFile? videoFile;
    try {
      videoFile = await picker.pickVideo(source: ImageSource.camera);
      if (videoFile == null) return;
      _videoUrl = videoFile.path;
      _initVideoPlayer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Failed to pick video: $e',
        ),
      ));
    }
  }

  Future<void> _initVideoPlayer() async {
    _videoController = VideoPlayerController.file(File(_videoUrl!))
      ..initialize().then((value) => setState(() {
            _videoController?.play();
          }));
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.play();
  }

  Future<void> _uploadVideo() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _isUploading = true;
        _title = _titleController.text;
      });
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Upload Thumbnail
      final Uint8List? thumbnailBytes = await _generateThumbnail();
      if (thumbnailBytes != null) {
        final thumbnailRef =
            storage.ref().child("thumbnails/${DateTime.now()}");
        final thumbnailUploadTask = thumbnailRef.putData(thumbnailBytes);
        await thumbnailUploadTask.whenComplete(() async {
          _thumbnailUrl = await thumbnailRef.getDownloadURL();
        });
      }

      // Retrieve user's location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String cityName = placemarks[0].locality ?? '';

      // Upload Video
      final videoRef = storage.ref().child("videos/${DateTime.now()}");
      final videoUploadTask = videoRef.putFile(File(_videoUrl!));
      await videoUploadTask.whenComplete(() async {
        final String downloadUrl = await videoRef.getDownloadURL();

        final videoDetails = Video(
          title: _title,
          uploadedBy: _username ?? '',
          videoUrl: downloadUrl,
          thumbnailUrl: _thumbnailUrl ?? '',
          cityName: cityName,
        );
        await FirebaseFirestore.instance
            .collection('videos')
            .add(videoDetails.toJson());
        Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Permission denied'),
      ));
    }
  }

  Future<Uint8List?> _generateThumbnail() async {
    final thumbnailBytes = await VideoThumbnail.thumbnailData(
      video: _videoUrl!,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 200,
      quality: 50,
    );
    return thumbnailBytes;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getUser();
    _isUploading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_videoUrl == null)
              ElevatedButton(
                onPressed: _pickVideo,
                child: const Text('Pick Video'),
              ),
            _videoPlayerPreview(),
          ],
        ),
      ),
    );
  }

  Widget _videoPlayerPreview() {
    if (_videoController != null) {
      return Column(
        children: [
          SizedBox(
            height: 300,
            width: 300,
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isUploading && _titleController.text.isNotEmpty
                ? null
                : _uploadVideo,
            child: _isUploading
                ? const CircularProgressIndicator()
                : const Text('Upload Video'),
          )
        ],
      );
    }
    return const Text("Video not picked");
  }
}
