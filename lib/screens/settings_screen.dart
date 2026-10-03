import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/player_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final downloads = ref.watch(downloadsProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Profil kartı
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF282828), Color(0xFF181818)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF1DB954),
                  child: Icon(Icons.person, size: 36, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Samet Kasal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sametify Premium (Sınırsız)',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF1DB954).withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _buildSectionHeader('SES VE OYNATMA KALİTESİ'),
          ListTile(
            title: const Text('Ses Kalitesi'),
            subtitle: Text(
              settings.audioQuality,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              _showQualityPicker(context, ref, settings.audioQuality);
            },
          ),
          SwitchListTile(
            title: const Text('Sadece Çevrimdışı Mod'),
            subtitle: Text(
              'Yalnızca indirilen şarkıları oynatır',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            value: settings.offlineModeOnly,
            activeThumbColor: const Color(0xFF1DB954),
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleOfflineMode(val);
            },
          ),
          SwitchListTile(
            title: const Text('Otomatik Oynatma'),
            subtitle: Text(
              'Parça bittiğinde benzer müzikleri çalmaya devam et',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            value: settings.autoPlay,
            activeThumbColor: const Color(0xFF1DB954),
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleAutoPlay(val);
            },
          ),
          SwitchListTile(
            title: const Text('Ses Seviyesini Dengele'),
            subtitle: Text(
              'Tüm parçalar için eşit ses düzeyi',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            value: settings.normalizeAudio,
            activeThumbColor: const Color(0xFF1DB954),
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleNormalizeAudio(val);
            },
          ),

          _buildSectionHeader('DEPOLAMA VE VERİ'),
          ListTile(
            title: const Text('İndirilen Şarkılar'),
            subtitle: Text(
              '${downloads.length} şarkı cihazda kayıtlı',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            trailing: const Icon(Icons.download_done, color: Color(0xFF1DB954)),
          ),
          ListTile(
            title: const Text('Önbelleği Temizle'),
            subtitle: Text(
              '${settings.cacheSizeMb.toStringAsFixed(1)} MB yerel önbellek',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            trailing: TextButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).clearCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Önbellek başarıyla temizlendi')),
                );
              },
              child: const Text('Temizle', style: TextStyle(color: Color(0xFF1DB954))),
            ),
          ),
          ListTile(
            title: const Text('Çalma Geçmişini Sıfırla'),
            subtitle: Text(
              '${history.length} dinleme kaydı',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            trailing: TextButton(
              onPressed: () {
                ref.read(historyProvider.notifier).clearHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dinleme geçmişi sıfırlandı')),
                );
              },
              child: const Text('Sıfırla', style: TextStyle(color: Colors.redAccent)),
            ),
          ),

          _buildSectionHeader('UYGULAMA HAKKINDA'),
          const ListTile(
            title: Text('Sürüm'),
            subtitle: Text('Sametify 1.1.0 Stable (Arch/CachyOS Build)',
                style: TextStyle(color: Colors.white54)),
          ),
          const ListTile(
            title: Text('Geliştirici'),
            subtitle: Text('Samet Kasal (@abdulsamet-kasal)',
                style: TextStyle(color: Colors.white54)),
          ),
          const ListTile(
            title: Text('Lisans'),
            subtitle: Text('MIT License - Açık Kaynak Müzik Ekosistemi',
                style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1DB954),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showQualityPicker(BuildContext context, WidgetRef ref, String current) {
    final options = ['Düşük (96kbps)', 'Normal (160kbps)', 'Yüksek (320kbps)', 'Kayıpsız FLAC'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Akış & İndirme Kalitesi Seç',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...options.map((opt) {
                final isSelected = opt == current;
                return ListTile(
                  title: Text(opt,
                      style: TextStyle(
                          color: isSelected ? const Color(0xFF1DB954) : Colors.white)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF1DB954))
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setAudioQuality(opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
