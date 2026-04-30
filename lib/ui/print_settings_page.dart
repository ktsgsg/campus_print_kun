import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../features/webprint/webprint.dart';
import '../l10n/app_localizations.dart';

class PrintSettingsPage extends StatefulWidget {
  const PrintSettingsPage({super.key, required this.format});

  final PrintFormat format;

  @override
  State<PrintSettingsPage> createState() => _PrintSettingsPageState();
}

class _PrintSettingsPageState extends State<PrintSettingsPage> {
  late Map<String, String> _values;
  late TextEditingController _copiesController;

  @override
  void initState() {
    super.initState();
    _values = Map<String, String>.from(widget.format.toMap());
    final numberUp = int.tryParse(_values['number_up'] ?? '') ?? 1;
    if (numberUp < 1 || numberUp > 4) {
      _values['number_up'] = '1';
    }
    _copiesController = TextEditingController(
      text: _values['copies'] ?? PrintFormat.defaults['copies'],
    );
  }

  @override
  void dispose() {
    _copiesController.dispose();
    super.dispose();
  }

  void _setValue(String key, String value) {
    setState(() => _values[key] = value);
  }

  void _resetToDefaults() {
    setState(() {
      _values = Map<String, String>.from(PrintFormat.defaults);
      _copiesController.text = _values['copies'] ?? '1';
    });
  }

  void _normalizeNumeric(String key, TextEditingController controller) {
    final raw = controller.text.trim();
    final parsed = int.tryParse(raw) ?? 1;
    final safe = parsed < 1 ? 1 : parsed;
    controller.text = safe.toString();
    _values[key] = controller.text;
  }

  void _apply() {
    _normalizeNumeric('copies', _copiesController);
    Navigator.of(context).pop(PrintFormat(_values));
  }

  Widget _buildSegmentedRow({
    required String title,
    required String key,
    required Map<String, String> options,
  }) {
    return CupertinoFormRow(
      prefix: Text(title),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _values[key] ?? PrintFormat.defaults[key],
        children: {
          for (final entry in options.entries) entry.key: Text(entry.value),
        },
        onValueChanged: (value) {
          if (value != null) _setValue(key, value);
        },
      ),
    );
  }

  Widget _buildNumberRow({
    required String title,
    required String key,
    required TextEditingController controller,
  }) {
    return CupertinoFormRow(
      prefix: Text(title),
      child: SizedBox(
        width: 120,
        child: CupertinoTextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isEmpty) return;
            _setValue(key, value);
          },
          onEditingComplete: () {
            _normalizeNumeric(key, controller);
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.printSettingsTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _resetToDefaults,
          child: Text(l10n.resetDefaults),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _apply,
          child: Text(l10n.apply),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: Text(l10n.settingsSectionHeader),
              footer: Text(l10n.settingsSectionFooter),
              children: [
                _buildSegmentedRow(
                  title: l10n.paperSize,
                  key: 'paper_type',
                  options: const {'06': 'A4', '05': 'A3'},
                ),
                _buildSegmentedRow(
                  title: l10n.duplexPrinting,
                  key: 'duplex_type',
                  options: {'1': l10n.duplexNo, '2': l10n.duplexYes},
                ),
                _buildSegmentedRow(
                  title: l10n.printOrientation,
                  key: 'print_orientation',
                  options: {'1': l10n.longEdge, '2': l10n.shortEdge},
                ),
                _buildSegmentedRow(
                  title: l10n.pageSort,
                  key: 'page_sort',
                  options: {'1': l10n.horizontalLayout, '2': l10n.verticalLayout},
                ),
                _buildNumberRow(
                  title: l10n.copies,
                  key: 'copies',
                  controller: _copiesController,
                ),
                _buildSegmentedRow(
                  title: l10n.numberUp,
                  key: 'number_up',
                  options: const {'1': '1', '2': '2', '3': '3', '4': '4'},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
