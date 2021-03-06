import 'package:meta/meta.dart';
import 'package:hive/hive.dart';

import '../src/madob_error.dart';

/// Handles [HiveObject]'s to [Box]-name relations
class HiveBoxRepository {
  bool _isInitialized = false;

  /// Initialization status of [HiveBoxRepository]
  bool get isInitialized => _isInitialized;

  /// **Warning:** [hiveInterface] is only changed for
  /// **unit-test purposes**.
  @visibleForTesting
  HiveInterface hiveInterface = Hive;

  final Map<Type, String> _boxCache = {};

  void _throwIfNotInitialized() {
    if (!isInitialized) {
      throw MadobError('Repository is not initialized');
    }
  }

  void _throwIfNotRegistered<T>() {
    if (!_boxCache.containsKey(T)) {
      throw MadobError('Unknown $T has not been registered');
    }
  }

  /// Initializes [HiveBoxRepository] with a given [path] which is used
  /// as a [Hive] database path.
  /// Also see [Hive.init()]
  void init(String path) {
    assert(path != null && path.isNotEmpty);

    if (isInitialized) {
      throw MadobError('Repository is already initialized');
    }

    if (!isInitialized) {
      hiveInterface.init(path);
      _isInitialized = true;
    }
  }

  /// Register a [HiveObject] to [Box]-name relation, as well as
  /// the required [TypeAdapter] for [Hive]
  void register<K extends HiveObject>(String boxName, TypeAdapter<K> adapter) {
    assert(boxName != null && boxName.isNotEmpty);
    assert(adapter != null);

    _throwIfNotInitialized();

    if (_boxCache.containsKey(K)) {
      throw MadobError('Type $K is already registered');
    }

    if (_boxCache.containsValue(boxName)) {
      throw MadobError('Box $boxName is already registered');
    }

    hiveInterface.registerAdapter(adapter);
    _boxCache.putIfAbsent(K, () => boxName);
  }

  /// Returns the related [Box]-name for [K]
  String getBoxName<K extends HiveObject>() {
    _throwIfNotInitialized();
    _throwIfNotRegistered<K>();

    return _boxCache[K];
  }

  /// Explicitly closes the [Box] for [K]
  Future<void> closeBox<K extends HiveObject>() async {
    _throwIfNotInitialized();
    _throwIfNotRegistered<K>();

    final boxName = getBoxName<K>();

    if (hiveInterface.isBoxOpen(boxName)) {
      await hiveInterface.box<K>(boxName).close();
    }
  }
}
