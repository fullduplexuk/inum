import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inum/presentation/design_system/colors.dart';

const Map<String, List<String>> _emojiCategories = {
  'Recent': [],
  'Smileys': ['\u{1F600}', '\u{1F603}', '\u{1F604}', '\u{1F601}', '\u{1F606}',
    '\u{1F605}', '\u{1F602}', '\u{1F923}', '\u{1F60A}', '\u{1F607}',
    '\u{1F642}', '\u{1F643}', '\u{1F609}', '\u{1F60C}', '\u{1F60D}',
    '\u{1F970}', '\u{1F618}', '\u{1F617}', '\u{1F619}', '\u{1F61A}',
    '\u{1F60B}', '\u{1F61B}', '\u{1F61C}', '\u{1F92A}', '\u{1F61D}',
    '\u{1F911}', '\u{1F917}', '\u{1F92D}', '\u{1F92B}', '\u{1F914}'],
  'People': ['\u{1F44B}', '\u{1F91A}', '\u{270B}', '\u{1F596}', '\u{1F44C}',
    '\u{270C}', '\u{1F91E}', '\u{1F44D}', '\u{1F44E}', '\u{1F44F}',
    '\u{1F64C}', '\u{1F450}', '\u{1F932}', '\u{1F91D}', '\u{1F64F}'],
  'Nature': ['\u{1F436}', '\u{1F431}', '\u{1F42D}', '\u{1F439}', '\u{1F430}',
    '\u{1F98A}', '\u{1F43B}', '\u{1F43C}', '\u{1F428}', '\u{1F42F}'],
  'Food': ['\u{1F34E}', '\u{1F34F}', '\u{1F350}', '\u{1F34A}', '\u{1F34B}',
    '\u{1F34C}', '\u{1F349}', '\u{1F347}', '\u{1F353}', '\u{1F348}'],
  'Activities': ['\u{26BD}', '\u{1F3C0}', '\u{1F3C8}', '\u{26BE}', '\u{1F94E}'],
  'Travel': ['\u{1F697}', '\u{1F695}', '\u{1F68C}', '\u{1F693}', '\u{1F680}'],
  'Symbols': ['\u{2764}', '\u{1F9E1}', '\u{1F49B}', '\u{1F49A}', '\u{1F499}',
    '\u{1F49C}', '\u{1F494}', '\u{2B50}', '\u{1F525}', '\u{1F4A5}'],
};

const String _tenorApiKey = 'AIzaSyAyimkuYQYF_FXVALexPuGQctUWRURdCYQ';

class StickerPicker extends StatefulWidget {
  final void Function(String emoji) onEmojiSelected;
  final void Function(String stickerUrl)? onStickerSelected;
  final VoidCallback? onClose;
  const StickerPicker({super.key, required this.onEmojiSelected, this.onStickerSelected, this.onClose});
  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Smileys';
  final List<String> _recentEmojis = [];

  // GIF state
  final _gifSearchController = TextEditingController();
  List<Map<String, dynamic>> _gifs = [];
  bool _isLoadingGifs = false;
  Timer? _gifSearchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _gifs.isEmpty && !_isLoadingGifs) {
        _loadTrendingGifs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _gifSearchController.dispose();
    _gifSearchDebounce?.cancel();
    super.dispose();
  }

  List<String> _getFilteredEmojis() {
    if (_searchQuery.isEmpty) {
      if (_selectedCategory == 'Recent') return _recentEmojis;
      return _emojiCategories[_selectedCategory] ?? [];
    }
    final all = <String>[];
    for (final emojis in _emojiCategories.values) all.addAll(emojis);
    return all;
  }

  void _selectEmoji(String emoji) {
    widget.onEmojiSelected(emoji);
    setState(() { _recentEmojis.remove(emoji); _recentEmojis.insert(0, emoji); if (_recentEmojis.length > 30) _recentEmojis.removeLast(); });
  }

  Future<void> _loadTrendingGifs() async {
    setState(() => _isLoadingGifs = true);
    try {
      final uri = Uri.parse('https://tenor.googleapis.com/v2/featured?key=$_tenorApiKey&limit=20');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _gifs = results.map((r) => r as Map<String, dynamic>).toList();
            _isLoadingGifs = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingGifs = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGifs = false);
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingGifs();
      return;
    }
    setState(() => _isLoadingGifs = true);
    try {
      final uri = Uri.parse('https://tenor.googleapis.com/v2/search?q=${Uri.encodeComponent(query)}&key=$_tenorApiKey&limit=20');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _gifs = results.map((r) => r as Map<String, dynamic>).toList();
            _isLoadingGifs = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingGifs = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGifs = false);
    }
  }

  String? _getGifUrl(Map<String, dynamic> gif) {
    try {
      final mediaFormats = gif['media_formats'] as Map<String, dynamic>?;
      if (mediaFormats == null) return null;
      final tinygif = mediaFormats['tinygif'] as Map<String, dynamic>?;
      return tinygif?['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? _getGifFullUrl(Map<String, dynamic> gif) {
    try {
      final mediaFormats = gif['media_formats'] as Map<String, dynamic>?;
      if (mediaFormats == null) return null;
      final fullGif = mediaFormats['gif'] as Map<String, dynamic>?;
      return fullGif?['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), offset: const Offset(0, -2), blurRadius: 8)],
      ),
      child: Column(children: [
        TabBar(controller: _tabController, labelColor: inumPrimary, unselectedLabelColor: customGreyColor500,
          indicatorColor: inumPrimary, tabs: const [Tab(text: 'Emoji'), Tab(text: 'Stickers'), Tab(text: 'GIFs')]),
        Expanded(child: TabBarView(controller: _tabController, children: [_buildEmojiTab(), _buildStickersTab(), _buildGifsTab()])),
      ]),
    );
  }

  Widget _buildEmojiTab() {
    final categories = _emojiCategories.keys.toList();
    final emojis = _getFilteredEmojis();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: TextField(
          controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(hintText: 'Search emojis...', prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18),
              onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)), isDense: true),
        ),
      ),
      if (_searchQuery.isEmpty) SizedBox(height: 32, child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index]; final sel = cat == _selectedCategory;
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: ChoiceChip(
            label: Text(cat, style: const TextStyle(fontSize: 11)), selected: sel,
            onSelected: (_) => setState(() => _selectedCategory = cat),
            selectedColor: inumPrimary.withAlpha(30),
            labelStyle: TextStyle(color: sel ? inumPrimary : customGreyColor600, fontSize: 11),
            visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4)));
        })),
      const SizedBox(height: 4),
      Expanded(child: emojis.isEmpty
        ? Center(child: Text(_selectedCategory == 'Recent' ? 'No recent emojis' : 'No emojis found', style: const TextStyle(color: customGreyColor500)))
        : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, childAspectRatio: 1),
            itemCount: emojis.length,
            itemBuilder: (context, index) => GestureDetector(onTap: () => _selectEmoji(emojis[index]),
              child: Center(child: Text(emojis[index], style: const TextStyle(fontSize: 24)))))),
    ]);
  }

  Widget _buildStickersTab() {
    final packs = [
      ['\u{1F600}','\u{1F60D}','\u{1F622}','\u{1F621}','\u{1F60E}','\u{1F914}','\u{1F973}','\u{1F92F}','\u{1F47B}','\u{1F916}','\u{1F47D}','\u{1F4A9}'],
      ['\u{1F436}','\u{1F431}','\u{1F43C}','\u{1F98A}','\u{1F981}','\u{1F427}','\u{1F985}','\u{1F41F}','\u{1F40D}','\u{1F422}','\u{1F41D}','\u{1F98B}'],
    ];
    return ListView(padding: const EdgeInsets.all(12), children: [
      const Text('Emoji Faces', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 8), _stickerGrid(packs[0]),
      const SizedBox(height: 16),
      const Text('Animals', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 8), _stickerGrid(packs[1]),
    ]);
  }

  Widget _stickerGrid(List<String> stickers) {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: stickers.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => widget.onStickerSelected?.call(stickers[index]),
        child: Container(decoration: BoxDecoration(color: customGreyColor200, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(stickers[index], style: const TextStyle(fontSize: 40))))));
  }

  Widget _buildGifsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: _gifSearchController,
            onChanged: (v) {
              _gifSearchDebounce?.cancel();
              _gifSearchDebounce = Timer(const Duration(milliseconds: 400), () => _searchGifs(v));
            },
            decoration: InputDecoration(
              hintText: 'Search GIFs...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _gifSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _gifSearchController.clear();
                        _loadTrendingGifs();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: _isLoadingGifs
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _gifs.isEmpty
                  ? const Center(child: Text('No GIFs found', style: TextStyle(color: customGreyColor500)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _gifs.length,
                      itemBuilder: (context, index) {
                        final gif = _gifs[index];
                        final thumbUrl = _getGifUrl(gif);
                        final fullUrl = _getGifFullUrl(gif);
                        if (thumbUrl == null) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () {
                            final url = fullUrl ?? thumbUrl;
                            widget.onStickerSelected?.call(url);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              thumbUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: customGreyColor200,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: customGreyColor200,
                                child: const Center(child: Icon(Icons.broken_image, color: customGreyColor400)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('Powered by Tenor', style: TextStyle(fontSize: 10, color: customGreyColor500)),
        ),
      ],
    );
  }
}
