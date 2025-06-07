import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const GeldiGeldiApp());
}

class GeldiGeldiApp extends StatelessWidget {
  const GeldiGeldiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeldiGeldi',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Colors.tealAccent, 
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

const List<String> cities = ["Ankara", "Konya", "İzmir", "Bursa", "Antalya"];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? secilenSehir = cities[0];
  final TextEditingController durakController = TextEditingController();
  bool isLoading = false;
  String? sonuc; 
  List<Map<String, dynamic>> otobusListesi = []; 
  bool _showResult = false;
  String? sonDurakIsmi; 
  Map<String, Map<String, int>> durakKullanimSayilari = {}; 
  late AnimationController _starController;
  Map<String, Set<String>> favoriDuraklar = {}; 
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initPreferences(); 
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavorites(); 
    _loadUsageStats(); 
  }

  Future<void> _loadFavorites() async {
    final favData = _prefs.getString('favoriDuraklar');
    if (favData != null) {
      try {
         final decodedData = json.decode(favData) as Map<String, dynamic>;
        setState(() {
          favoriDuraklar = decodedData.map(
            (k, v) => MapEntry(k, Set<String>.from(v as List)),
          );
        });
      } catch (e) {
        print("Favoriler yüklenirken hata: $e");
        favoriDuraklar = {}; 
      }
    }
  }

  Future<void> _loadUsageStats() async {
    final usageData = _prefs.getString('durakKullanimSayilari');
    if (usageData != null) {
       try {
        final decodedData = json.decode(usageData) as Map<String, dynamic>;
        setState(() {
          durakKullanimSayilari = decodedData.map(
            (k, v) => MapEntry(k, Map<String, int>.from(v as Map)),
          );
        });
      } catch (e) {
        print("Kullanım istatistikleri yüklenirken hata: $e");
        durakKullanimSayilari = {}; 
      }
    }
  }

  Future<void> _saveFavorites() async { 
    try {
      await _prefs.setString(
        'favoriDuraklar',
        json.encode(
          favoriDuraklar.map((k, v) => MapEntry(k, v.toList())),
        ),
      );
    } catch (e) {
      print("Favoriler kaydedilirken hata: $e");
    }
  }

  Future<void> _saveUsageStats() async { 
     try {
        await _prefs.setString(
        'durakKullanimSayilari',
        json.encode(durakKullanimSayilari),
      );
    } catch (e) {
      print("Kullanım istatistikleri kaydedilirken hata: $e");
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    durakController.dispose();
    super.dispose();
  }

  List<String> getPopularStops() { // En çok kullanılan durakları buradan alıyoruz
    if (secilenSehir == null) return [];
    final usage = durakKullanimSayilari[secilenSehir!] ?? {};
    final sorted = usage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  List<String> getFavoriDuraklar() { // Favori durakları buradan alıyoruz
    if (secilenSehir == null) return [];
    return favoriDuraklar[secilenSehir!]?.toList() ?? [];
  }

  Future<void> otobusBilgisiGetir({String? durakNo}) async {
    final durakId = durakNo ?? durakController.text;
    if (secilenSehir == null || durakId.isEmpty) {
      setState(() {
        sonuc = "Lütfen şehir ve durak bilgisi giriniz";
        otobusListesi = [{'hat': 'Uyarı', 'detay': sonuc}];
        _showResult = true;
        sonDurakIsmi = null;
      });
      return;
    }

    
    if (secilenSehir != null) {
      final String durakIdForStats = durakId.split(" - ").first; 
      durakKullanimSayilari.putIfAbsent(secilenSehir!, () => {});
      durakKullanimSayilari[secilenSehir!]!.update(
        durakIdForStats, 
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      await _saveUsageStats();
    }

    setState(() {
      isLoading = true;
      _showResult = false;
      sonDurakIsmi = null;
      otobusListesi = []; 
    });

    try {
      final response = await http
          .post(
            Uri.parse("http://localhost:5000/bus_info"), 
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'sehir': secilenSehir, 'durak_id': durakId.split(" - ").first}), 
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      String? extractedDurakAdi;

      if (data['durak_adi'] != null) {
        extractedDurakAdi = data['durak_adi'];
      } else if (data['result'] is List &&
          data['result'].isNotEmpty &&
          data['result'][0]['durak_adi'] != null) {
        extractedDurakAdi = data['result'][0]['durak_adi'];
      }
      
      setState(() {
        
        final String currentDurakId = durakId.split(" - ").first;
        sonDurakIsmi = extractedDurakAdi != null ? "$currentDurakId - $extractedDurakAdi" : currentDurakId;


        if (data['result'] is List) {
          otobusListesi = List<Map<String, dynamic>>.from(data['result']);
          if (otobusListesi.isEmpty){
             sonuc = "Bu duraktan geçecek otobüs bulunamadı."; 
          } else {
            sonuc = json.encode(data['result']); 
          }
        } else if (data['result'] is String) {
          otobusListesi = [{'hat': 'Bilgi', 'detay': data['result']}];
           sonuc = data['result'];
        } else if (data['message'] != null) { 
           otobusListesi = [{'hat': 'Bilgi', 'detay': data['message']}];
           sonuc = data['message'];
        }
         else {
          otobusListesi = [{'hat': 'Hata', 'detay': "Beklenmedik veri formatı."}];
          sonuc = "Beklenmedik veri formatı.";
        }
        _showResult = true;
      });

      _starController.forward(from: 0);
    } catch (e) {
      setState(() {
        sonuc = "Hata: ${e.toString()}\nDurak numarası geçersiz olabilir veya sunucuya ulaşılamıyor.";
        otobusListesi = [{'hat': 'Hata', 'detay': sonuc}];
        _showResult = true;
        sonDurakIsmi = durakId.split(" - ").first; 
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

 void toggleFavori(String durakKimligi) { 
    if (secilenSehir == null) return;

    final String durakIdOnly = durakKimligi.split(" - ").first; 

    setState(() {
      favoriDuraklar.putIfAbsent(secilenSehir!, () => <String>{});
      if (favoriDuraklar[secilenSehir!]!.contains(durakIdOnly)) {
        favoriDuraklar[secilenSehir!]!.remove(durakIdOnly);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Durak favorilerden çıkarıldı!")),
        );
      } else {
        favoriDuraklar[secilenSehir!]!.add(durakIdOnly);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Durak favorilere eklendi!")),
        );
      }
      _saveFavorites();
    });
  }

  void _yakindakiDuraklarSayfasinaGit() {
    if (secilenSehir == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YakindakiDuraklarPage(sehir: secilenSehir!),
      ),
    ).then((gelenDurakNo) { 
        if (gelenDurakNo != null && gelenDurakNo is String && gelenDurakNo.isNotEmpty) {
            durakController.text = gelenDurakNo; 
            otobusBilgisiGetir(durakNo: gelenDurakNo); 
        }
    });
  }

  Widget _buildResultCard() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!_showResult) return const SizedBox.shrink(); 
    
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: colors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sonDurakIsmi ?? "Durak Bilgisi", 
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (sonDurakIsmi != null && secilenSehir != null)
                      IconButton(
                        icon: Icon(
                          (favoriDuraklar[secilenSehir!]?.contains(
                                  sonDurakIsmi!.split(" - ").first) ?? 
                              false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: colors.primary,
                        ),
                        onPressed: () {
                          toggleFavori(sonDurakIsmi!); 
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (otobusListesi.isNotEmpty)
                  ...otobusListesi.map((otobus) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    otobus['hat']?.toString() ?? '???',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (otobus['varis_suresi'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      otobus['varis_suresi'].toString(),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold, 
                                        fontStyle: FontStyle.italic, 
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (otobus['son_durak'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Son durak: ",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      TextSpan(
                                        text: otobus['son_durak'].toString(),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,   
                                          fontStyle: FontStyle.italic,  
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (otobus['detay'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  otobus['detay'].toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold, 
                                    fontStyle: FontStyle.italic, 
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                else if (isLoading == false) 
                  Center( 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        sonuc ?? "Bu duraktan geçecek otobüs bulunamadı veya bilgi alınamadı.",
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularStopChip(String stopId, int index, ThemeData theme) { 
    final colors = theme.colorScheme;
    final isFavorite = (secilenSehir != null && favoriDuraklar[secilenSehir!]?.contains(stopId) == true);
    
    String displayText = stopId; 
    

    return FadeInDown(
      delay: Duration(milliseconds: index * 100),
      child: GestureDetector(
        onTap: () => otobusBilgisiGetir(durakNo: stopId), 
        onLongPress: () => toggleFavori(stopId), 
        child: Chip(
          avatar: CircleAvatar(
            backgroundColor: isFavorite 
                ? colors.secondaryContainer.withOpacity(0.7)
                : colors.primaryContainer.withOpacity(0.7),
            child: Text(
              "${index + 1}",
              style: TextStyle(
                color: isFavorite 
                    ? colors.onSecondaryContainer
                    : colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          label: Text(
            displayText, 
            style: TextStyle(
              fontWeight: isFavorite ? FontWeight.bold : FontWeight.normal,
              color: isFavorite ? colors.secondary : colors.onSurface,
            ),
          ),
          backgroundColor: colors.surface.withOpacity(0.9),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(
            color: isFavorite ? colors.secondary : colors.outline.withOpacity(0.5),
            width: isFavorite ? 1.5 : 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final popularStops = getPopularStops(); 
    final favoriler = getFavoriDuraklar();   
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colors.surface, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: FadeInDown(
          duration: const Duration(milliseconds: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bus_filled,
                color: colors.primary, 
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                "GeldiGeldi",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: colors.primary, 
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colors.primary),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "GeldiGeldi",
                applicationVersion: "1.0.2", 
                applicationLegalese: "© 2024-2025 Ulaşım Asistanı",
              );
            },
          ),
        ],
      ),
      body: Container( 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer.withOpacity(0.6),
              colors.surface.withOpacity(0.3),
              colors.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 1.0]
          )
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding( 
                padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 40, 16, 16), 
                child: Column(
                  children: [
                    FadeInLeft(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                           boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: secilenSehir,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down_circle_outlined, color: colors.primary),
                            items: cities.map((city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                secilenSehir = val;
                                _showResult = false; 
                                otobusListesi = [];
                                sonuc = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: colors.surface.withOpacity(0.95),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: durakController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Durak Numarası",
                                  labelStyle: TextStyle(color: colors.primary),
                                  prefixIcon: Icon(Icons.confirmation_number_outlined, color: colors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colors.outline)
                                  ),
                                   focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colors.primary, width: 2)
                                  ),
                                ),
                                onSubmitted: isLoading ? null : (_) => otobusBilgisiGetir(),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: isLoading ? null : () => otobusBilgisiGetir(),
                                  icon: isLoading 
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: colors.onPrimary))
                                    : const Icon(Icons.search_rounded),
                                  label: Text(isLoading ? "Yükleniyor..." : "Otobüs Bilgisi Getir"),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: colors.primary,
                                    foregroundColor: colors.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (popularStops.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FadeInLeft(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                    child: Text(
                      "Popüler Duraklar ($secilenSehir)",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60, 
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: popularStops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final stopId = popularStops[index];
                      return _buildPopularStopChip(stopId, index, theme);
                    },
                  ),
                ),
              ),
            ],
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: FadeInUp(
                  child: OutlinedButton.icon( 
                    onPressed: _yakindakiDuraklarSayfasinaGit,
                    icon: Icon(Icons.location_searching_rounded, color: colors.secondary),
                    label: Text("Yakındaki Durakları Göster", style: TextStyle(color: colors.secondary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.secondary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                       shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            if (_showResult) 
              SliverToBoxAdapter(
                child: _buildResultCard(),
              ),
            
            if (favoriler.isNotEmpty) ...[
               SliverToBoxAdapter(
                child: FadeInLeft(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          "Favori Duraklarım ($secilenSehir)",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                             color: colors.onSurfaceVariant
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${favoriler.length} adet",
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final favId = favoriler[index]; 
                      String favDisplayText = favId; 
                    
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 50),
                        child: Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                           shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colors.outline.withOpacity(0.3))
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.favorite,
                              color: colors.primary,
                            ),
                            title: Text(favDisplayText, style: TextStyle(fontWeight: FontWeight.w500)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.8)),
                              iconSize: 22,
                              onPressed: () => toggleFavori(favId), 
                            ),
                            onTap: () => otobusBilgisiGetir(durakNo: favId), 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: favoriler.length,
                  ),
                ),
              ),
            ] else if (secilenSehir != null) ... [ 
                SliverToBoxAdapter(
                child: FadeIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.sentiment_dissatisfied_outlined, size: 40, color: colors.onSurfaceVariant.withOpacity(0.6)),
                          const SizedBox(height: 8),
                          Text(
                            "Henüz $secilenSehir için favori durağınız yok.",
                             style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                             textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
            SliverToBoxAdapter(child: SizedBox(height: 30)) 
          ],
        ),
      ),
    );
  }
}

class YakindakiDuraklarPage extends StatefulWidget {
  final String sehir;

  const YakindakiDuraklarPage({super.key, required this.sehir});

  @override
  State<YakindakiDuraklarPage> createState() => _YakindakiDuraklarPageState();
}

class _YakindakiDuraklarPageState extends State<YakindakiDuraklarPage> {
  String _sonucMetni = "Yükleniyor...";
  bool _loading = true;
  List<Map<String, dynamic>> _yakindakiDuraklarListesi = [];

  final Map<String, Map<String, double>> sehirMerkezleri = {
    "Ankara": {"lat": 39.9334, "lng": 32.8597},
    "İzmir": {"lat": 38.4192, "lng": 27.1287},
    "Antalya": {"lat": 36.8969, "lng": 30.6954},
    "Konya": {"lat": 37.8715, "lng": 32.4845},
    "Bursa": {"lat": 40.1826, "lng": 29.0628},
  };

  @override
  void initState() {
    super.initState();
    _getYakindakiDuraklariGetir();
  }

  Future<void> _getYakindakiDuraklariGetir() async {
    setState(() {
      _loading = true;
      _yakindakiDuraklarListesi = [];
    });
    final sehir = widget.sehir;
    final center = sehirMerkezleri[sehir];

    if (center == null) {
      setState(() {
        _sonucMetni = "Geçersiz şehir merkezi bilgisi.";
        _loading = false;
      });
      return;
    }

    final random = Random();
    final lat = center["lat"]! + (random.nextDouble() - 0.5) * 0.05; 
    final lng = center["lng"]! + (random.nextDouble() - 0.5) * 0.05; 

    try {
      final response = await http
          .post(
            Uri.parse("http://localhost:5000/nearby_stops"), 
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "sehir": sehir,
              "latitude": lat,
              "longitude": lng,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] is List) {
            setState(() {
              _yakindakiDuraklarListesi = List<Map<String, dynamic>>.from(data['result']);
              if (_yakindakiDuraklarListesi.isEmpty) {
                _sonucMetni = "Yakınınızda durak bulunamadı.";
              }
              _loading = false;
            });
        } else if (data['message'] != null) {
           setState(() {
            _sonucMetni = data['message'];
            _loading = false;
          });
        }
         else {
           setState(() {
            _sonucMetni = "Duraklar alınamadı veya format hatalı.";
            _loading = false;
          });
        }
      } else {
        setState(() {
          _sonucMetni = "API hatası: ${response.statusCode}. Sunucuyla iletişim kurulamadı.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sonucMetni = "Hata oluştu: ${e.toString()}. İnternet bağlantınızı kontrol edin.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.sehir} - Yakındaki Duraklar"),
        backgroundColor: colors.primaryContainer,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _yakindakiDuraklarListesi.isNotEmpty 
            ? ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _yakindakiDuraklarListesi.length,
                itemBuilder: (context, index) {
                  final durak = _yakindakiDuraklarListesi[index];
                  String durakAdi = durak['durak_adi'] ?? 'Bilinmeyen Durak';
                  String durakNo = durak['durak_no']?.toString() ?? '';
                  String mesafe = durak['mesafe']?.toString() ?? '';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primary,
                        child: Text(durakNo.isNotEmpty ? durakNo : "?", style: TextStyle(color: colors.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(durakAdi, style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: mesafe.isNotEmpty ? Text("Mesafe: $mesafe") : null,
                      trailing: Icon(Icons.directions_bus_outlined, color: colors.secondary),
                      onTap: () {
                        if (durakNo.isNotEmpty) {
                           Navigator.pop(context, durakNo); 
                        } else {
                           Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              )
            : Center( 
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.location_off_outlined, size: 50, color: colors.onSurfaceVariant.withOpacity(0.7)),
                       const SizedBox(height: 16),
                       Text(
                        _sonucMetni, 
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Tekrar Dene"),
                        onPressed: _getYakindakiDuraklariGetir,
                        style: FilledButton.styleFrom(backgroundColor: colors.secondary, foregroundColor: colors.onSecondary),
                      )
                    ],
                  ),
                ),
              ),
    );
  }
}

















