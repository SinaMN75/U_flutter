import "package:u/utilities.dart";

import "pages/components/charts_navigation_page.dart";
import "pages/components/documents_page.dart";
import "pages/components/inputs_page.dart";
import "pages/components/layout_page.dart";
import "pages/components/media_components_page.dart";
import "pages/components/video_ar_process_page.dart";
import "pages/showcases/ar_page.dart";
import "pages/showcases/audio_notes_page.dart";
import "pages/showcases/camera_page.dart";
import "pages/showcases/camera_studio_page.dart";
import "pages/showcases/document_reader_page.dart";
import "pages/showcases/downloads/downloads_page.dart";
import "pages/showcases/maps/maps_page.dart";
import "pages/showcases/media_player_page.dart";
import "pages/showcases/scanner_studio_page.dart";
import "pages/showcases/video_notes_page.dart";
import "pages/utils/app_page.dart";
import "pages/utils/backend_web_page.dart";
import "pages/utils/crypto_data_page.dart";
import "pages/utils/extensions_page.dart";
import "pages/utils/files_page.dart";
import "pages/utils/geo_page.dart";
import "pages/utils/launch_share_page.dart";
import "pages/utils/location_notification_page.dart";
import "pages/utils/media_camera_page.dart";
import "pages/utils/persian_dates_state_page.dart";
import "pages/utils/storage_page.dart";
import "pages/utils/ui_helpers_page.dart";

/// One row of the catalog: a page and the API names it demonstrates (used by search).
class GalleryEntry {
  const GalleryEntry(this.title, this.subtitle, this.icon, this.builder);

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;
}

/// The catalog, by section. Every public utility, extension and widget of the plugin has a runnable example in one of these pages.
final Map<String, List<GalleryEntry>> kSections = <String, List<GalleryEntry>>{
  "Utilities": <GalleryEntry>[
    GalleryEntry("App & device", "UApp, UAppState, U, UDevice info, theme, locale, keepScreenOn", Icons.phone_android, () => const AppPage()),
    GalleryEntry("UI helpers", "UNavigator, UToast, ULoading, UValidators, UDebouncer, UThrottler, URetry", Icons.handyman, () => const UiHelpersPage()),
    GalleryEntry("Storage & network", "ULocalStorage, UNetwork", Icons.storage, () => const StoragePage()),
    GalleryEntry("Files & downloads", "UFile, UDownloads", Icons.folder_open, () => const FilesPage()),
    GalleryEntry("Launch, share, guard", "ULaunch, UShare, UScreenGuard", Icons.share, () => const LaunchSharePage()),
    GalleryEntry("Location & notifications", "ULocation, UNotification", Icons.location_on, () => const LocationNotificationPage()),
    GalleryEntry("Geo & maps", "UGeo, UMaps: distances, shapes, codes, GPX/KML/GeoJSON, search, routing, offline", Icons.public, () => const GeoPage()),
    GalleryEntry("Media & camera", "UMedia, UAudio, USound, UCamera, UArExperiences", Icons.perm_media, () => const MediaCameraPage()),
    GalleryEntry("Crypto & data", "UEncryption, UUUID, UOtp, UConvert, UClipboard, UTimezone", Icons.lock, () => const CryptoDataPage()),
    GalleryEntry("Persian, dates, state", "UPersianTools, UPhoneNumberUtils, UJalali, UGregorian, URx", Icons.calendar_month, () => const PersianDatesStatePage()),
    GalleryEntry("Backend & web", "UHttpClient, UAuth, UCrashlytics, UUpdateDialog, UWeb, UIso", Icons.cloud_sync, () => const BackendWebPage()),
    GalleryEntry("Extensions", "String, num, Duration, DateTime, Iterable, Map, BuildContext, Widget", Icons.extension, () => const ExtensionsPage()),
  ],
  "Components": <GalleryEntry>[
    GalleryEntry("Layout & basics", "Boxes, text, buttons, badges, progress, skeleton, async builders", Icons.dashboard, () => const LayoutComponentsPage()),
    GalleryEntry("Inputs & forms", "Text fields, pickers, selectors, OTP, keyboards, signature, card", Icons.edit_note, () => const InputsComponentsPage()),
    GalleryEntry("Charts & navigation", "Charts, gauges, pagination, side menu, tab bar, carousel", Icons.insights, () => const ChartsNavigationPage()),
    GalleryEntry("Media widgets", "Images, viewers, cropper, barcodes, scanner, notes, lyrics, web, map", Icons.image, () => const MediaComponentsPage()),
    GalleryEntry("Documents", "PDF viewer & editor, EPUB, rich text editor", Icons.description, () => const DocumentsComponentsPage()),
    GalleryEntry("Video, AR, process", "Video building blocks, AR widgets, KYC process, download helpers", Icons.view_in_ar, () => const VideoArProcessPage()),
  ],
  "Showcases": <GalleryEntry>[
    GalleryEntry("Document reader", "PDF & EPUB, highlights, notes", Icons.menu_book_rounded, () => const DocumentReaderPage()),
    GalleryEntry("Video course", "Timestamp notes, resume, PiP", Icons.ondemand_video_rounded, () => const VideoNotesPage()),
    GalleryEntry("Audio lecture", "Voice player with notes", Icons.headphones_rounded, () => const AudioNotesPage()),
    GalleryEntry("Media player", "Native audio & video engine", Icons.play_circle_fill, () => const MediaPlayerPage()),
    GalleryEntry("Camera & scanning", "Native camera + Dart barcode engine", Icons.photo_camera, () => const CameraPage()),
    GalleryEntry("Camera studio", "Full camera UI", Icons.camera, () => const CameraStudioPage()),
    GalleryEntry("Scanner studio", "Barcode scanner UI", Icons.qr_code_scanner, () => const ScannerStudioPage()),
    GalleryEntry("AR & 3D", "Place, measure, geo cards, 3D viewer", Icons.threed_rotation, () => const ArPage()),
    GalleryEntry("Downloads", "Segmented, encrypted, resumable", Icons.download_for_offline, () => const DownloadsPage()),
    GalleryEntry("Maps", "UMap: vector styles, clusters, drawing, heatmaps, routing, navigation, offline", Icons.map, () => const MapsPage()),
  ],
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = "";

  bool _matches(GalleryEntry e) => _query.isBlank || "${e.title} ${e.subtitle}".toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: const UTextTitleLarge("u plugin gallery", fontWeight: FontWeight.w700), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          USearchField(hint: "Search a class or feature (e.g. UJalali, toast, pdf)", debounce: Duration.zero, onSearch: (String q) => setState(() => _query = q)),
          for (final MapEntry<String, List<GalleryEntry>> section in kSections.entries)
            if (section.value.any(_matches)) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: UTextTitleMedium(section.key, color: scheme.primary),
              ),
              UCard(
                child: Column(
                  children: section.value
                      .where(_matches)
                      .map(
                        (GalleryEntry e) => ListTile(
                          leading: UContainer(
                            color: scheme.primaryContainer,
                            radius: 10,
                            padding: const EdgeInsets.all(8),
                            child: Icon(e.icon, color: scheme.onPrimaryContainer, size: 20),
                          ),
                          title: UTextTitleSmall(e.title),
                          subtitle: UTextBodySmall(e.subtitle, maxLines: 2),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => UNavigator.push<void>(e.builder()),
                        ),
                      )
                      .toList()
                      .withDividers(),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
