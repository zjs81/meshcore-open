import 'dart:math' as math;
import 'dart:typed_data';

import '../../models/message_filter.dart';
import 'message_filter_text.dart';

/// Weights and bias of a trained [NgramSpamClassifier]. Plain data, so
/// training can run in a background isolate and hand the result back.
class SpamModel {
  final Map<int, double> weights;
  final double bias;
  const SpamModel(this.weights, this.bias);
}

/// Inputs for [NgramSpamClassifier.fitInBackground].
typedef SpamTrainingJob = ({
  int epochs,
  double learningRate,
  double lambda,
  int seed,
  List<FilterExample> spam,
  List<FilterExample> ham,
});

/// A sparse, L2-normalised feature vector (hashed bucket ids and values).
class _SparseVector {
  final Int32List indices;
  final Float64List values;
  const _SparseVector(this.indices, this.values);
}

/// Small on-device spam classifier trained from the user's "Spam" and
/// "Not spam" taps.
///
/// Features are hashed character n-grams (3..5, within word boundaries), word
/// unigrams/bigrams and the sender name; the model is a class-balanced,
/// L2-regularised logistic regression trained with seeded SGD. Training and
/// scoring are pure Dart and fully deterministic for the same inputs.
class NgramSpamClassifier {
  NgramSpamClassifier({
    this.epochs = 200,
    this.learningRate = 0.5,
    this.lambda = 1e-4,
    this.seed = 42,
  });

  static const int bucketBits = 18;
  static const int bucketCount = 1 << bucketBits;
  static const int _bucketMask = bucketCount - 1;
  static const int minCharGram = 3;
  static const int maxCharGram = 5;

  final int epochs;
  final double learningRate;
  final double lambda;
  final int seed;

  Map<int, double> _weights = const {};
  double _bias = 0;
  bool _trained = false;

  bool get isTrained => _trained;

  /// Number of non-zero weights in the trained model.
  int get featureCount => _weights.length;

  void reset() {
    _weights = const {};
    _bias = 0;
    _trained = false;
  }

  static final RegExp _wordToken = RegExp(r'[\p{L}\p{N}]+', unicode: true);

  /// Stable 32-bit FNV-1a over the UTF-16 code units of [value].
  ///
  /// The prime multiply is split (0x01000193 = 2^24 + 0x193) so intermediate
  /// values stay below 2^53 and the result is identical on the web.
  static int fnv1a32(String value) {
    var hash = 0x811C9DC5;
    for (var i = 0; i < value.length; i++) {
      hash = (hash ^ value.codeUnitAt(i)) & 0xFFFFFFFF;
      hash = (hash * 0x193 + ((hash & 0xFF) << 24)) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Raw (unhashed) feature strings for a message, exposed for tests.
  static List<String> featureStrings(String sender, String text) {
    final features = <String>[];
    final normalized = MessageFilterText.normalize(text);
    if (normalized.isNotEmpty) {
      for (final word in normalized.split(' ')) {
        if (word.isEmpty) continue;
        final padded = ' $word ';
        if (padded.length <= minCharGram) {
          features.add('c:$padded');
          continue;
        }
        for (var n = minCharGram; n <= maxCharGram; n++) {
          if (padded.length < n) {
            features.add('c:$padded');
            break;
          }
          for (var i = 0; i + n <= padded.length; i++) {
            features.add('c:${padded.substring(i, i + n)}');
          }
        }
      }
      final words = _wordToken
          .allMatches(normalized)
          .map((m) => m.group(0)!)
          .toList(growable: false);
      for (var i = 0; i < words.length; i++) {
        features.add('w:${words[i]}');
        if (i + 1 < words.length) {
          features.add('b:${words[i]} ${words[i + 1]}');
        }
      }
    }
    final normalizedSender = MessageFilterText.normalize(sender);
    if (normalizedSender.isNotEmpty) {
      features.add('s:$normalizedSender');
    }
    return features;
  }

  static _SparseVector _vectorize(String sender, String text) {
    final counts = <int, int>{};
    for (final feature in featureStrings(sender, text)) {
      final bucket = fnv1a32(feature) & _bucketMask;
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    final keys = counts.keys.toList()..sort();
    final indices = Int32List(keys.length);
    final values = Float64List(keys.length);
    var sumSquares = 0.0;
    for (var i = 0; i < keys.length; i++) {
      final value = 1 + math.log(counts[keys[i]]!);
      indices[i] = keys[i];
      values[i] = value;
      sumSquares += value * value;
    }
    if (sumSquares > 0) {
      final norm = math.sqrt(sumSquares);
      for (var i = 0; i < values.length; i++) {
        values[i] /= norm;
      }
    }
    return _SparseVector(indices, values);
  }

  static double _sigmoid(double z) {
    if (z >= 0) {
      return 1 / (1 + math.exp(-z));
    }
    final e = math.exp(z);
    return e / (1 + e);
  }

  /// Trains from scratch. Needs at least one example of each class; otherwise
  /// the classifier is left untrained (and [probability] returns 0).
  void train(List<FilterExample> spam, List<FilterExample> ham) {
    final model = fit(
      spam,
      ham,
      epochs: epochs,
      learningRate: learningRate,
      lambda: lambda,
      seed: seed,
    );
    if (model == null) {
      reset();
    } else {
      use(model);
    }
  }

  /// The job [fitInBackground] runs for this classifier's settings.
  SpamTrainingJob trainingJob(
    List<FilterExample> spam,
    List<FilterExample> ham,
  ) => (
    epochs: epochs,
    learningRate: learningRate,
    lambda: lambda,
    seed: seed,
    spam: spam,
    ham: ham,
  );

  /// Entry point for `compute`: trains on [job] and returns the model, or
  /// null when either class has no usable examples.
  static SpamModel? fitInBackground(SpamTrainingJob job) => fit(
    job.spam,
    job.ham,
    epochs: job.epochs,
    learningRate: job.learningRate,
    lambda: job.lambda,
    seed: job.seed,
  );

  /// Switches to [model] (from [fit] or [fitInBackground]).
  void use(SpamModel model) {
    _weights = model.weights;
    _bias = model.bias;
    _trained = true;
  }

  /// Pure training step: same inputs, same model. Null when either class has
  /// no usable examples.
  static SpamModel? fit(
    List<FilterExample> spam,
    List<FilterExample> ham, {
    required int epochs,
    required double learningRate,
    required double lambda,
    required int seed,
  }) {
    if (spam.isEmpty || ham.isEmpty) return null;

    // Vectorize and remap hashed buckets to a compact local index space.
    final localIndex = <int, int>{};
    final docs = <_SparseVector>[];
    final labels = <double>[];
    void addDoc(FilterExample example, double label) {
      final vector = _vectorize(example.sender, example.text);
      if (vector.indices.isEmpty) return;
      final local = Int32List(vector.indices.length);
      for (var i = 0; i < vector.indices.length; i++) {
        local[i] = localIndex.putIfAbsent(
          vector.indices[i],
          () => localIndex.length,
        );
      }
      docs.add(_SparseVector(local, vector.values));
      labels.add(label);
    }

    for (final example in spam) {
      addDoc(example, 1);
    }
    for (final example in ham) {
      addDoc(example, 0);
    }

    final n = docs.length;
    final nPos = labels.where((y) => y == 1).length;
    final nNeg = n - nPos;
    if (nPos == 0 || nNeg == 0) return null;
    final wPos = n / (2 * nPos);
    final wNeg = n / (2 * nNeg);

    final weights = Float64List(localIndex.length);
    var bias = 0.0;
    final order = List<int>.generate(n, (i) => i);
    final random = math.Random(seed);
    // Per-step decay; lambda is the per-sample L2 strength.
    final decay = 1 - learningRate * lambda;

    for (var epoch = 0; epoch < epochs; epoch++) {
      order.shuffle(random);
      final rate = learningRate / (1 + epoch * 0.02);
      for (final docIndex in order) {
        final doc = docs[docIndex];
        final y = labels[docIndex];
        var z = bias;
        for (var i = 0; i < doc.indices.length; i++) {
          z += weights[doc.indices[i]] * doc.values[i];
        }
        final sampleWeight = y == 1 ? wPos : wNeg;
        final gradient = (_sigmoid(z) - y) * sampleWeight;
        for (var i = 0; i < doc.indices.length; i++) {
          final j = doc.indices[i];
          weights[j] = weights[j] * decay - rate * gradient * doc.values[i];
        }
        bias -= rate * gradient;
      }
    }

    final compact = <int, double>{};
    localIndex.forEach((bucket, local) {
      final weight = weights[local];
      if (weight != 0) compact[bucket] = weight;
    });
    return SpamModel(compact, bias);
  }

  /// Probability (0..1) that the message is spam; 0 when untrained.
  double probability(String sender, String text) {
    if (!_trained) return 0.0;
    final vector = _vectorize(sender, text);
    if (vector.indices.isEmpty) return 0.0;
    var z = _bias;
    for (var i = 0; i < vector.indices.length; i++) {
      final weight = _weights[vector.indices[i]];
      if (weight != null) z += weight * vector.values[i];
    }
    return _sigmoid(z);
  }
}
