import 'package:client/Features/Video_lectures/Model/video_model.dart';
import 'package:client/Features/Video_lectures/video_player_screen.dart';
import 'package:flutter/material.dart';

class VideoListScreen extends StatelessWidget {
  VideoListScreen({super.key});

 final List<VideoModel> videos = [
  VideoModel(
    title: "Stock Option Buying strategy Part 1",
    videoId: "BKoWmDwlfnQ",
    thumbnail: "https://img.youtube.com/vi/BKoWmDwlfnQ/0.jpg",
  ),
  VideoModel(
    title: "Stock Option Buying strategy Part 2",
    videoId: "MnopZVm7baM",
    thumbnail: "https://img.youtube.com/vi/MnopZVm7baM/0.jpg",
  ),
  VideoModel(
    title: "Stock Option Buying strategy Part 3",
    videoId: "bDLYO5D7RoE",
    thumbnail: "https://img.youtube.com/vi/bDLYO5D7RoE/0.jpg",
  ),


];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Lectures"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    videoId: video.videoId,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎥 Thumbnail with play button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          video.thumbnail,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),

                  // 📄 Title & subtitle
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Tap to watch",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}