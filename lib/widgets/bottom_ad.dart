// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the current user may see ads. Comes from the backend `showAds`
/// field (site/user based setting). Unknown means no ads.
final ValueNotifier<bool> adsEnabled = ValueNotifier<bool>(false);

Future<void> loadAdsPreference() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  adsEnabled.value = pref.getBool('showAds') ?? false;
}

/// value: showAds from the backend (1/0); null leaves the setting unchanged.
Future<void> setAdsEnabled(dynamic value) async {
  if (value == null) return;
  final bool show = value == 1 || value == true;
  SharedPreferences pref = await SharedPreferences.getInstance();
  pref.setBool('showAds', show);
  adsEnabled.value = show;
}

/// Wraps every route (via MaterialApp.builder) and pins a large ad to the
/// bottom of the screen while ads are enabled.
class AdShell extends StatelessWidget {
  const AdShell({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return ValueListenableBuilder<bool>(
      valueListenable: adsEnabled,
      builder: (context, enabled, _) {
        final bool showAd = enabled && !keyboardOpen;
        return Column(
          children: [
            // Keep the navigator at a stable position in the tree so pages
            // are not rebuilt when the ad appears/disappears.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: showAd,
                child: child,
              ),
            ),
            if (enabled)
              Offstage(offstage: keyboardOpen, child: const BottomAd()),
          ],
        );
      },
    );
  }
}

class BottomAd extends StatefulWidget {
  const BottomAd({Key? key}) : super(key: key);

  @override
  State<BottomAd> createState() => _BottomAdState();
}

class _BottomAdState extends State<BottomAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Google's official test ad units always fill; used in debug builds so we
    // never risk invalid-click activity on the real ad units.
    final adUnitId = kDebugMode
        ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716')
        : (Platform.isAndroid
            ? 'ca-app-pub-3506128953915434/4591588872'
            : 'ca-app-pub-3506128953915434/9991427706');
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('BannerAd loaded ($adUnitId)');
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print(
              'BannerAd failed to load ($adUnitId): code=${error.code} domain=${error.domain} message=${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFEEF1F8),
        border: Border(top: BorderSide(color: Colors.black87, width: 1)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
