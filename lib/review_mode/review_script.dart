import '../connector/meshcore_protocol.dart';

/// A contact in the simulated radio's contact table.
class ReviewContact {
  final String name;
  final String publicKeyHex;
  final int type;

  /// One-byte path hashes, as hex. Empty means a direct (zero hop) path.
  final String pathHex;
  final double latitude;
  final double longitude;
  final int lastAdvertAgoSecs;

  const ReviewContact({
    required this.name,
    required this.publicKeyHex,
    required this.type,
    required this.pathHex,
    required this.latitude,
    required this.longitude,
    required this.lastAdvertAgoSecs,
  });

  int get hopCount => pathHex.length ~/ 2;
}

/// A channel slot configured on the simulated radio.
class ReviewChannel {
  final int index;
  final String name;
  final String pskHex;

  const ReviewChannel({
    required this.index,
    required this.name,
    required this.pskHex,
  });
}

/// A direct message from a script contact.
class ReviewDirectLine {
  final int contactIndex;
  final String text;
  final int agoSecs;

  const ReviewDirectLine({
    required this.contactIndex,
    required this.text,
    this.agoSecs = 0,
  });
}

/// A channel message from a script member.
class ReviewChannelLine {
  final int channelIndex;
  final String sender;
  final String text;
  final int agoSecs;

  const ReviewChannelLine({
    required this.channelIndex,
    required this.sender,
    required this.text,
    this.agoSecs = 0,
  });
}

/// The fake world the simulated radio lives in.
class ReviewScript {
  ReviewScript._();

  static const String selfName = 'Review Radio';
  static const int selfLatitudeE6 = 45515232;
  static const int selfLongitudeE6 = -122678385;
  static const int frequencyHz = 910525000;
  static const int bandwidthHz = 62500;
  static const int spreadingFactor = 7;
  static const int codingRate = 5;
  static const int txPowerDbm = 20;
  static const int maxTxPowerDbm = 22;

  static const int firmwareVerCode = 14;
  static const int maxContacts = 100;
  static const int maxChannels = 8;

  static const List<ReviewContact> contacts = [
    ReviewContact(
      name: 'Maya',
      publicKeyHex:
          'a95db5b0ac159e4384ff55ef91c94a98dc563d66a88e7b027fcd5190c0f5bed5',
      type: advTypeChat,
      pathHex: 'a1',
      latitude: 45.5231,
      longitude: -122.6765,
      lastAdvertAgoSecs: 600,
    ),
    ReviewContact(
      name: 'Jordan',
      publicKeyHex:
          '136c67657614311f32238751044a0a3c0294f2a521e573afa8e496992d3786ba',
      type: advTypeChat,
      pathHex: 'a1c4',
      latitude: 45.5089,
      longitude: -122.6912,
      lastAdvertAgoSecs: 1800,
    ),
    ReviewContact(
      name: 'Sam',
      publicKeyHex:
          'e96e02d8e47f2a7c03be5117b3ed175c52aa30fb22028cf9c96f261563577605',
      type: advTypeChat,
      pathHex: '',
      latitude: 45.5176,
      longitude: -122.6701,
      lastAdvertAgoSecs: 240,
    ),
    ReviewContact(
      name: 'Ranger Pat',
      publicKeyHex:
          'dbc4a04327176e6577b4da46df04564150053960eba5d89587dad1f76a818d80',
      type: advTypeChat,
      pathHex: 'a1c47f',
      latitude: 45.5402,
      longitude: -122.7120,
      lastAdvertAgoSecs: 3600,
    ),
    ReviewContact(
      name: 'Hilltop Repeater',
      publicKeyHex:
          '409e364456fa93642cd24878f532fffe31e3aae5944d04239a7d023e66ebdbe3',
      type: advTypeRepeater,
      pathHex: '',
      latitude: 45.5298,
      longitude: -122.7064,
      lastAdvertAgoSecs: 120,
    ),
    ReviewContact(
      name: 'Trailhead Room',
      publicKeyHex:
          '08d33503ee27d4c13055d0cefec5e730be4ef2e41cd6cfce434936ec1e7c9d4b',
      type: advTypeRoom,
      pathHex: 'a1',
      latitude: 45.5350,
      longitude: -122.6650,
      lastAdvertAgoSecs: 900,
    ),
  ];

  static const List<ReviewChannel> channels = [
    ReviewChannel(
      index: 0,
      name: 'Public',
      pskHex: '8b3387e9c5cdea6ac9e5edbaa115cd72',
    ),
    ReviewChannel(
      index: 1,
      name: 'Hiking Group',
      pskHex: 'dd488fa58a29956b6271b573e1a33ac5',
    ),
    ReviewChannel(
      index: 2,
      name: 'Local Net',
      pskHex: '8bca9c2e3ef52ebcd61d30ec6c724a25',
    ),
  ];

  /// Senders that may speak in each channel, by channel index.
  static const Map<int, List<String>> channelMembers = {
    0: ['Maya', 'Sam'],
    1: ['Jordan', 'Sam'],
    2: ['Ranger Pat', 'Maya'],
  };

  static const List<ReviewDirectLine> seedDirectMessages = [
    ReviewDirectLine(
      contactIndex: 0,
      text: 'Hey! Are you heading up to the ridge this weekend?',
      agoSecs: 7200,
    ),
    ReviewDirectLine(
      contactIndex: 0,
      text: 'The repeater on the hill is showing a great signal today.',
      agoSecs: 6900,
    ),
    ReviewDirectLine(
      contactIndex: 1,
      text: 'Signal check from the trailhead. Reading you loud and clear.',
      agoSecs: 3300,
    ),
  ];

  static const List<ReviewChannelLine> seedChannelMessages = [
    ReviewChannelLine(
      channelIndex: 0,
      sender: 'Maya',
      text: 'Good morning mesh! Anyone on the air?',
      agoSecs: 5400,
    ),
    ReviewChannelLine(
      channelIndex: 1,
      sender: 'Jordan',
      text: 'Planning to leave the trailhead at 8 on Saturday.',
      agoSecs: 4800,
    ),
    ReviewChannelLine(
      channelIndex: 1,
      sender: 'Sam',
      text: 'I will bring the spare battery pack.',
      agoSecs: 4500,
    ),
    ReviewChannelLine(
      channelIndex: 2,
      sender: 'Ranger Pat',
      text: 'Weekly net check-in starts at 7 pm. Please report your signal.',
      agoSecs: 2400,
    ),
  ];

  /// Scheduled incoming direct messages, cycled in order.
  static const List<ReviewDirectLine> incomingDirectPool = [
    ReviewDirectLine(
      contactIndex: 0,
      text: 'Just got a message through the hilltop repeater. Nice!',
    ),
    ReviewDirectLine(
      contactIndex: 1,
      text: 'Battery is at 80 percent. Plenty for the whole hike.',
    ),
    ReviewDirectLine(
      contactIndex: 2,
      text: 'Can you hear me from the creek crossing?',
    ),
    ReviewDirectLine(
      contactIndex: 3,
      text: 'Trail conditions are good. A little muddy near the bridge.',
    ),
    ReviewDirectLine(
      contactIndex: 0,
      text: 'Testing a new antenna today. How is my signal?',
    ),
    ReviewDirectLine(
      contactIndex: 2,
      text: 'Heading back down now. See you at the trailhead.',
    ),
  ];

  /// Scheduled incoming channel messages, cycled in order.
  static const List<ReviewChannelLine> incomingChannelPool = [
    ReviewChannelLine(
      channelIndex: 0,
      sender: 'Sam',
      text: 'Radio check, one two three. Anyone copy?',
    ),
    ReviewChannelLine(
      channelIndex: 1,
      sender: 'Jordan',
      text: 'We reached the lookout. The view is great!',
    ),
    ReviewChannelLine(
      channelIndex: 2,
      sender: 'Ranger Pat',
      text: 'Reminder: the net is open to everyone. Say hello.',
    ),
    ReviewChannelLine(
      channelIndex: 0,
      sender: 'Maya',
      text: 'Clear skies and a strong signal across town today.',
    ),
    ReviewChannelLine(
      channelIndex: 1,
      sender: 'Sam',
      text: 'Anyone need water? I am refilling at the next stop.',
    ),
    ReviewChannelLine(
      channelIndex: 2,
      sender: 'Maya',
      text: 'Checking in from the east side. Copy you five by five.',
    ),
  ];

  /// Auto-replies to a direct message the app sends.
  static const List<String> directReplies = [
    'Got it, thanks!',
    'Sounds good to me.',
    'Message received loud and clear.',
    'Thanks for the update. Talk soon!',
  ];

  /// Auto-replies to a channel message the app sends.
  static const List<String> channelReplies = [
    'Copy that!',
    'Welcome to the mesh!',
    'Heard you loud and clear.',
    'Thanks for checking in.',
  ];
}
