import 'package:flutter/material.dart';
import '../state/locale_controller.dart';

/// Globe menu to switch app language. Reflects the active locale and persists
/// the choice via [LocaleController].
class LanguageButton extends StatelessWidget {
  final Color? color;
  const LanguageButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final current = LocaleController.instance.locale.value.languageCode;
    return PopupMenuButton<String>(
      tooltip: 'Language',
      icon: Icon(Icons.language, color: color),
      onSelected: (code) => LocaleController.instance.set(code),
      itemBuilder: (context) => LocaleController.names.entries
          .map((e) => CheckedPopupMenuItem<String>(
                value: e.key,
                checked: e.key == current,
                child: Text(e.value),
              ))
          .toList(),
    );
  }
}
