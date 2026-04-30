import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neopay_ai/theme/app_theme.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final TextEditingController _keyCtl = TextEditingController();
  String _provider = 'openai';
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _keyCtl.text = prefs.getString('ai_api_key') ?? '';
    _provider = prefs.getString('ai_provider') ?? 'openai';
    _enabled = prefs.getBool('ai_enabled') ?? true;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', _keyCtl.text.trim());
    await prefs.setString('ai_provider', _provider);
    await prefs.setBool('ai_enabled', _enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('AI settings saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: _enabled,
                    title: const Text('Enable AI features'),
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provider',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _provider,
                    items: const [
                      DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                      DropdownMenuItem(
                        value: 'anthropic',
                        child: Text('Anthropic (experimental)'),
                      ),
                      DropdownMenuItem(
                        value: 'gemini',
                        child: Text('Gemini (experimental)'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _provider = v ?? 'openai'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'API Key',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyCtl,
                    decoration: const InputDecoration(
                      hintText: 'Paste your API key here',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notes: For safety, do not commit your API keys. This app stores the key locally on-device using SharedPreferences.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
