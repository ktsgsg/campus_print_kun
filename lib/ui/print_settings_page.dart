import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../features/webprint/webprint.dart';

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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('印刷設定'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _resetToDefaults,
          child: const Text('規定値に戻す'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _apply,
          child: const Text('適用'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('プリント設定'),
              footer: const Text('queue_id や color_mode_type などは固定値です。'),
              children: [
                _buildSegmentedRow(
                  title: '用紙サイズ',
                  key: 'paper_type',
                  options: const {'06': 'A4', '05': 'A3'},
                ),
                _buildSegmentedRow(
                  title: '両面印刷',
                  key: 'duplex_type',
                  options: const {'1': 'なし', '2': 'あり'},
                ),
                _buildSegmentedRow(
                  title: '印刷向き',
                  key: 'print_orientation',
                  options: const {'1': '長辺', '2': '短辺'},
                ),
                _buildSegmentedRow(
                  title: 'ページ順',
                  key: 'page_sort',
                  options: const {'1': '横', '2': '縦'},
                ),
                _buildNumberRow(
                  title: '部数',
                  key: 'copies',
                  controller: _copiesController,
                ),
                _buildSegmentedRow(
                  title: '割付',
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
