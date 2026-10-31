import 'dart:async';

/// Interaction categories that require affirmative, action-specific consent.
enum ConsentAction { gentleTouch, kiss, embrace, gaze, whisper }

enum ConsentResponse { yes, notNow, no }

enum ConsentStatus { notAsked, granted, hesitant, refused, blocked, withdrawn }

typedef ConsentPrompt = Future<ConsentResponse?> Function(ConsentAction action);
typedef ConsentWithdrawalHandler = FutureOr<void> Function();

/// Fail-closed, action-specific consent state.
///
/// No action is approved by default. A "yes" only approves the requested
/// category; it never approves other categories. Withdrawal clears all grants.
class ConsentSystem {
  ConsentSystem({
    required ConsentPrompt prompt,
    ConsentWithdrawalHandler? onWithdraw,
    this.responseTimeout = const Duration(seconds: 10),
  })  : _prompt = prompt,
        _onWithdraw = onWithdraw {
    if (responseTimeout <= Duration.zero) {
      throw ArgumentError.value(
        responseTimeout,
        'responseTimeout',
        'Must be greater than zero.',
      );
    }
  }

  final ConsentPrompt _prompt;
  final ConsentWithdrawalHandler? _onWithdraw;
  final Duration responseTimeout;
  final Map<ConsentAction, ConsentStatus> _statuses =
      <ConsentAction, ConsentStatus>{};
  final Set<ConsentAction> _granted = <ConsentAction>{};
  final Set<ConsentAction> _blocked = <ConsentAction>{};
  bool _withdrawn = false;

  /// Requests consent when the action has not already been approved.
  ///
  /// Timeouts, missing responses, and prompt failures are treated as no
  /// permission. A refusal remains in force for that action until reset.
  Future<bool> request(ConsentAction action) async {
    if (_withdrawn) {
      _statuses[action] = ConsentStatus.withdrawn;
      return false;
    }
    if (_blocked.contains(action)) {
      _statuses[action] = ConsentStatus.blocked;
      return false;
    }
    if (_granted.contains(action)) return true;
    if (_statuses[action] == ConsentStatus.refused) return false;

    ConsentResponse? response;
    try {
      response = await _prompt(action).timeout(
        responseTimeout,
        onTimeout: () => null,
      );
    } catch (_) {
      response = null;
    }

    switch (response) {
      case ConsentResponse.yes:
        _granted.add(action);
        _statuses[action] = ConsentStatus.granted;
        return true;
      case ConsentResponse.notNow:
        _statuses[action] = ConsentStatus.hesitant;
        return false;
      case ConsentResponse.no:
        _statuses[action] = ConsentStatus.refused;
        return false;
      case null:
        _statuses[action] = ConsentStatus.hesitant;
        return false;
    }
  }

  /// Withdraws all previously granted actions before notifying the host.
  Future<void> withdraw() async {
    _withdrawn = true;
    _granted.clear();
    for (final action in ConsentAction.values) {
      _statuses[action] = ConsentStatus.withdrawn;
    }
    await _onWithdraw?.call();
  }

  /// Adds an explicit block. Removing it does not grant consent.
  void setBoundary(ConsentAction action) {
    _blocked.add(action);
    _granted.remove(action);
    _statuses[action] = ConsentStatus.blocked;
  }

  void removeBoundary(ConsentAction action) {
    _blocked.remove(action);
    if (_statuses[action] == ConsentStatus.blocked) {
      _statuses[action] = ConsentStatus.notAsked;
    }
  }

  /// Starts a new scene/session with no carried-over consent.
  void resetForNewScene() {
    _withdrawn = false;
    _granted.clear();
    _statuses.clear();
    for (final action in _blocked) {
      _statuses[action] = ConsentStatus.blocked;
    }
  }

  ConsentStatus statusFor(ConsentAction action) {
    if (_withdrawn) return ConsentStatus.withdrawn;
    if (_blocked.contains(action)) return ConsentStatus.blocked;
    return _statuses[action] ?? ConsentStatus.notAsked;
  }

  bool get isWithdrawn => _withdrawn;
  bool isGranted(ConsentAction action) =>
      !_withdrawn && !_blocked.contains(action) && _granted.contains(action);
  Set<ConsentAction> get grantedActions =>
      Set<ConsentAction>.unmodifiable(_granted);
  Set<ConsentAction> get boundaries =>
      Set<ConsentAction>.unmodifiable(_blocked);
}
