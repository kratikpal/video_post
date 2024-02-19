import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/video_model.dart';
import '../widgets/video_card.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _usernameController = TextEditingController();

  String? _uid;
  String _username = '';
  List<Video> _videos = [];

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid;
    _fetchVideos();
    _checkUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    if (_uid != null) {
      final userData =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (userData.exists) {
        setState(() {
          _username = userData['username'] ?? '';
        });
      }
    }
  }

  Future<void> _fetchVideos() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('videos').get();

    setState(() {
      _videos = querySnapshot.docs
          .map((doc) => Video.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVideos,
          )
        ],
        title: Text("Welcome $_username"),
      ),
      body: Center(
        child: _username.isNotEmpty ? buildVideoList() : buildUsernameInput(),
      ),
      floatingActionButton: _username.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UploadScreen(uid: _uid!);
                }));
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget buildLogoutButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Welcome back! $_username'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            FirebaseAuth.instance.signOut();
          },
          child: const Text("Logout"),
        ),
      ],
    );
  }

  Widget buildVideoList() {
    if (_videos.isEmpty) {
      return const Center(
        child: Text('No videos available.'),
      );
    }
    return ListView.builder(
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return VideoCard(video: video);
      },
    );
  }

  Widget buildUsernameInput() {
    return Card(
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Welcome, Please enter your username",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_uid != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .set({
                    'uid': _uid,
                    'username': _usernameController.text,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Username saved successfully!'),
                  ));
                  setState(() {
                    _username = _usernameController.text;
                  });
                }
              },
              child: const Text('Save Username'),
            )
          ],
        ),
      ),
    );
  }
}
