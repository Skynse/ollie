/// Sentinel used by `copyWith` methods that need to distinguish
/// "argument omitted" (keep the current value) from "explicitly null"
/// (clear the value).
///
/// Example:
/// ```dart
/// card.copyWith(dueDate: null) // clears the due date
/// card.copyWith(title: 'x')    // keeps the existing due date
/// ```
class UnsetValue {
  const UnsetValue();
}

const UnsetValue unset = UnsetValue();
