import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_model.dart';

final videoProvider = Provider<List<VideoModel>>((ref) {
  return [
    VideoModel(
      title: "Stock Option Buying strategy Part 1",
      videoId: "BKoWmDwlfnQ",
      thumbnail: "https://img.youtube.com/vi/BKoWmDwlfnQ/0.jpg",
      description:
          "Learn the fundamentals of option buying with real market examples.",
    ),
    VideoModel(
      title: "Stock Option Buying strategy Part 2",
      videoId: "MnopZVm7baM",
      thumbnail: "https://img.youtube.com/vi/MnopZVm7baM/0.jpg",
      description:
          "Build advanced strategies for trading stock options in volatile markets.",
    ),
    VideoModel(
      title: "Stock Option Buying strategy Part 3",
      videoId: "bDLYO5D7RoE",
      thumbnail: "https://img.youtube.com/vi/bDLYO5D7RoE/0.jpg",
      description:
          "Master risk management, strike selection, and execution timing.",
    ),
  ];
});
