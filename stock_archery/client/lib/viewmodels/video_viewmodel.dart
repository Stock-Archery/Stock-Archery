import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_model.dart';

final videoProvider = Provider<List<VideoModel>>((ref) {
  return [
    // SOB Videos
    VideoModel(
      title: "Stock Option Buying strategy Part 1",
      videoId: "BKoWmDwlfnQ",
      thumbnail: "https://img.youtube.com/vi/BKoWmDwlfnQ/0.jpg",
      description:
          "Learn the fundamentals of option buying with real market examples.",
      category: "SOB",
    ),
    VideoModel(
      title: "Stock Option Buying strategy Part 2",
      videoId: "MnopZVm7baM",
      thumbnail: "https://img.youtube.com/vi/MnopZVm7baM/0.jpg",
      description:
          "Build advanced strategies for trading stock options in volatile markets.",
      category: "SOB",
    ),
    VideoModel(
      title: "Stock Option Buying strategy Part 3",
      videoId: "bDLYO5D7RoE",
      thumbnail: "https://img.youtube.com/vi/bDLYO5D7RoE/0.jpg",
      description:
          "Master risk management, strike selection, and execution timing.",
      category: "SOB",
    ),
    VideoModel(
      title: "Intro of Free Classes",
      videoId: "seMb193jGCc",
      thumbnail: "https://img.youtube.com/vi/seMb193jGCc/0.jpg",
      description:
          "Learn the fundamentals of option buying with real market examples.",
      category: "Free Classes",
    ),
    VideoModel(
      title: "Anatomy of Candlestick",
      videoId: "o5J12_E9xaE",
      thumbnail: "https://img.youtube.com/vi/o5J12_E9xaE/0.jpg",
      description:
          "Learn the fundamentals of candlestick anatomy and understand how to read candlestick patterns.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Risk Management",
      videoId: "10eEQhpC1Ko",
      thumbnail: "https://img.youtube.com/vi/10eEQhpC1Ko/0.jpg",
      description:
          "Learn the fundamentals of risk management and how to manage risk while trading.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Stock Selection",
      videoId: "-_EKDOEd8GM",
      thumbnail: "https://img.youtube.com/vi/-_EKDOEd8GM/0.jpg",
      description:
          "Learn the fundamentals of stock selection and how to identify suitable stocks for trading.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Demand and Supply",
      videoId: "xSlFZTAD3S8",
      thumbnail: "https://img.youtube.com/vi/xSlFZTAD3S8/0.jpg",
      description:
          "Understand demand and supply and how they influence price movement in the market.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Trap Psychology",
      videoId: "pjQqJ35oY6I",
      thumbnail: "https://img.youtube.com/vi/pjQqJ35oY6I/0.jpg",
      description:
          "Understand trading trap psychology and how market participants can get caught in common traps.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Intraday Setup",
      videoId: "GTWnB5PuQrI",
      thumbnail: "https://img.youtube.com/vi/GTWnB5PuQrI/0.jpg",
      description:
          "Learn the fundamentals of intraday setups and how to identify trading opportunities.",
      category: "Free Classes",
    ),
  ];
});
