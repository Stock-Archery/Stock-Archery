import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_model.dart';

final videoProvider = Provider<List<VideoModel>>((ref) {
  return [
    // SOB Videos
    VideoModel(
      title: "Stock Option Buying strategy Part 1",
      videoId: "BKoWmDwlfnQ",
      thumbnail: "https://img.youtube.com/vi/BKoWmDwlfnQ/0.jpg",
      description: "What option buying is and how it works, explained simply.",
      category: "SOB",
    ),
    VideoModel(
      title: "Stock Option Buying strategy Part 2",
      videoId: "MnopZVm7baM",
      thumbnail: "https://img.youtube.com/vi/MnopZVm7baM/0.jpg",
      description:
          " How to tell when a stock is really breaking out, and which way it's likely to go.",
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
      title: "Stock Option Buying strategy Part -4",
      videoId: "gqaNgndQavA",
      thumbnail: "https://img.youtube.com/vi/gqaNgndQavA/0.jpg",
      description:
          " A simple, step-by-step method for buying options at the right time.",
      category: "SOB",
    ),
    VideoModel(
      title: "Intro of Free Classes",
      videoId: "seMb193jGCc",
      thumbnail: "https://img.youtube.com/vi/seMb193jGCc/0.jpg",
      description:
          " Overview of the free trading course, what it covers, and what to expect.",
      category: "Free Classes",
    ),
    VideoModel(
      title: "Anatomy of Candlestick",
      videoId: "o5J12_E9xaE",
      thumbnail: "https://img.youtube.com/vi/o5J12_E9xaE/0.jpg",
      description:
          " Basics of candlestick structure and how to read price action from them.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Risk Management",
      videoId: "10eEQhpC1Ko",
      thumbnail: "https://img.youtube.com/vi/10eEQhpC1Ko/0.jpg",
      description: "How to protect capital and control losses while trading.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Stock Selection",
      videoId: "-_EKDOEd8GM",
      thumbnail: "https://img.youtube.com/vi/-_EKDOEd8GM/0.jpg",
      description:
          "Criteria and process for picking the right stocks to trade.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Demand and Supply",
      videoId: "xSlFZTAD3S8",
      thumbnail: "https://img.youtube.com/vi/xSlFZTAD3S8/0.jpg",
      description:
          "Understanding market zones where buying/selling pressure shifts price.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Trap Psychology",
      videoId: "pjQqJ35oY6I",
      thumbnail: "https://img.youtube.com/vi/pjQqJ35oY6I/0.jpg",
      description:
          "Recognizing false breakouts/breakdowns and the psychology behind market traps.",
      category: "Free Classes",
    ),

    VideoModel(
      title: "Intraday Setup",
      videoId: "GTWnB5PuQrI",
      thumbnail: "https://img.youtube.com/vi/GTWnB5PuQrI/0.jpg",
      description:
          "Practical setup and strategy for executing intraday trades.",
      category: "Free Classes",
    ),
  ];
});
