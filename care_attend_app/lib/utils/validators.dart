/// Password strength check — mirrors the backend `validate_password` rule.
/// Returns an error message if the password is too weak, else null.
String? passwordError(String pw) {
  if (pw.length < 8) {
    return 'Password must be at least 8 characters with an uppercase letter, '
        'a lowercase letter, a number and a symbol';
  }
  if (!RegExp(r'[A-Z]').hasMatch(pw)) {
    return 'Password needs an uppercase letter';
  }
  if (!RegExp(r'[a-z]').hasMatch(pw)) {
    return 'Password needs a lowercase letter';
  }
  if (!RegExp(r'\d').hasMatch(pw)) return 'Password needs a number';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) return 'Password needs a symbol';
  return null;
}

const String passwordHint = '8+ chars · upper, lower, number, symbol';
