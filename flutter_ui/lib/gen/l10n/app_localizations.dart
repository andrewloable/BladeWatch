import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nb'),
    Locale('nl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'BladeWatch'**
  String get app_name;

  /// No description provided for @accessibility_service_description.
  ///
  /// In en, this message translates to:
  /// **'Keeps BladeWatch vehicle monitoring active in the background. This service does not read or interact with screen content.'**
  String get accessibility_service_description;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_clear_plain.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get action_clear_plain;

  /// No description provided for @action_select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get action_select_all;

  /// No description provided for @action_select_all_short.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get action_select_all_short;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @action_done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get action_done;

  /// No description provided for @action_remind_me_later.
  ///
  /// In en, this message translates to:
  /// **'REMIND ME LATER'**
  String get action_remind_me_later;

  /// No description provided for @action_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get action_retry;

  /// No description provided for @action_run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get action_run;

  /// No description provided for @action_clear_output.
  ///
  /// In en, this message translates to:
  /// **'Clear Output'**
  String get action_clear_output;

  /// No description provided for @cd_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cd_camera;

  /// No description provided for @cd_qr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get cd_qr;

  /// No description provided for @cd_qr_code.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get cd_qr_code;

  /// No description provided for @cd_show_hide_token.
  ///
  /// In en, this message translates to:
  /// **'Show/Hide Token'**
  String get cd_show_hide_token;

  /// No description provided for @cd_copy_token.
  ///
  /// In en, this message translates to:
  /// **'Copy Token'**
  String get cd_copy_token;

  /// No description provided for @cd_copy_url.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get cd_copy_url;

  /// No description provided for @cd_clear_logs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get cd_clear_logs;

  /// No description provided for @cd_expand_collapse.
  ///
  /// In en, this message translates to:
  /// **'Expand/Collapse'**
  String get cd_expand_collapse;

  /// No description provided for @cd_recording_status.
  ///
  /// In en, this message translates to:
  /// **'Recording status'**
  String get cd_recording_status;

  /// No description provided for @cd_trip_tracking_status.
  ///
  /// In en, this message translates to:
  /// **'Trip tracking status'**
  String get cd_trip_tracking_status;

  /// No description provided for @cd_video_thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Video thumbnail'**
  String get cd_video_thumbnail;

  /// No description provided for @cd_play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get cd_play;

  /// No description provided for @cd_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cd_back;

  /// No description provided for @cd_play_pause.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause'**
  String get cd_play_pause;

  /// No description provided for @cd_player_prev.
  ///
  /// In en, this message translates to:
  /// **'Previous recording'**
  String get cd_player_prev;

  /// No description provided for @cd_player_next.
  ///
  /// In en, this message translates to:
  /// **'Next recording'**
  String get cd_player_next;

  /// No description provided for @cd_player_maximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize player'**
  String get cd_player_maximize;

  /// No description provided for @cd_player_minimize.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get cd_player_minimize;

  /// No description provided for @cd_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cd_delete;

  /// No description provided for @cd_expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get cd_expand;

  /// No description provided for @cd_configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get cd_configure;

  /// No description provided for @cd_download_log.
  ///
  /// In en, this message translates to:
  /// **'Download log'**
  String get cd_download_log;

  /// No description provided for @cd_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get cd_reset;

  /// No description provided for @cd_battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get cd_battery;

  /// No description provided for @cd_step_completed.
  ///
  /// In en, this message translates to:
  /// **'Step completed'**
  String get cd_step_completed;

  /// No description provided for @cd_permission_granted.
  ///
  /// In en, this message translates to:
  /// **'Permission granted'**
  String get cd_permission_granted;

  /// No description provided for @overlay_rec_inactive_label.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get overlay_rec_inactive_label;

  /// No description provided for @overlay_trip_inactive_label.
  ///
  /// In en, this message translates to:
  /// **'TRIP'**
  String get overlay_trip_inactive_label;

  /// No description provided for @log_entry_default_timestamp.
  ///
  /// In en, this message translates to:
  /// **'12:34:56'**
  String get log_entry_default_timestamp;

  /// No description provided for @log_entry_default_tag.
  ///
  /// In en, this message translates to:
  /// **'[TAG]'**
  String get log_entry_default_tag;

  /// No description provided for @log_entry_default_message.
  ///
  /// In en, this message translates to:
  /// **'Log message here'**
  String get log_entry_default_message;

  /// No description provided for @daemon_card_default_name.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get daemon_card_default_name;

  /// No description provided for @daemon_card_default_status.
  ///
  /// In en, this message translates to:
  /// **'Status message'**
  String get daemon_card_default_status;

  /// No description provided for @daemon_card_subprocesses.
  ///
  /// In en, this message translates to:
  /// **'PROCESSES'**
  String get daemon_card_subprocesses;

  /// No description provided for @logs_panel_title.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs_panel_title;

  /// No description provided for @url_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get url_connecting;

  /// No description provided for @camera_selection_title.
  ///
  /// In en, this message translates to:
  /// **'Camera Selection'**
  String get camera_selection_title;

  /// No description provided for @camera_selection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select panoramic camera source'**
  String get camera_selection_subtitle;

  /// No description provided for @camera_current_auto.
  ///
  /// In en, this message translates to:
  /// **'Current: Auto'**
  String get camera_current_auto;

  /// No description provided for @camera_option_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto (detect on startup)'**
  String get camera_option_auto;

  /// No description provided for @camera_option_0.
  ///
  /// In en, this message translates to:
  /// **'Camera 0 — Atto trims'**
  String get camera_option_0;

  /// No description provided for @camera_option_1.
  ///
  /// In en, this message translates to:
  /// **'Camera 1 — Seal (default)'**
  String get camera_option_1;

  /// No description provided for @camera_option_2.
  ///
  /// In en, this message translates to:
  /// **'Camera 2'**
  String get camera_option_2;

  /// No description provided for @camera_option_3.
  ///
  /// In en, this message translates to:
  /// **'Camera 3'**
  String get camera_option_3;

  /// No description provided for @camera_option_4.
  ///
  /// In en, this message translates to:
  /// **'Camera 4'**
  String get camera_option_4;

  /// No description provided for @camera_option_5.
  ///
  /// In en, this message translates to:
  /// **'Camera 5'**
  String get camera_option_5;

  /// No description provided for @camera_selection_hint.
  ///
  /// In en, this message translates to:
  /// **'Auto picks the right camera for your trim on every boot. Camera 1 = BYD Seal, Camera 0 = Atto trims. Restart the camera service after changing camera ID for the setting to take effect.'**
  String get camera_selection_hint;

  /// No description provided for @dashboard_scan_to_connect.
  ///
  /// In en, this message translates to:
  /// **'Scan to Connect'**
  String get dashboard_scan_to_connect;

  /// No description provided for @dashboard_qr_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for tunnel…'**
  String get dashboard_qr_waiting;

  /// No description provided for @dashboard_daemons_running_default.
  ///
  /// In en, this message translates to:
  /// **'0/5 Running'**
  String get dashboard_daemons_running_default;

  /// No description provided for @dashboard_device_id_loading.
  ///
  /// In en, this message translates to:
  /// **'…'**
  String get dashboard_device_id_loading;

  /// No description provided for @dashboard_access_code.
  ///
  /// In en, this message translates to:
  /// **'Access Code'**
  String get dashboard_access_code;

  /// No description provided for @dashboard_token_masked.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get dashboard_token_masked;

  /// No description provided for @dashboard_regenerate_token.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Token'**
  String get dashboard_regenerate_token;

  /// No description provided for @dashboard_set_password.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get dashboard_set_password;

  /// No description provided for @cd_set_password.
  ///
  /// In en, this message translates to:
  /// **'Set custom password'**
  String get cd_set_password;

  /// No description provided for @dialog_set_password_title.
  ///
  /// In en, this message translates to:
  /// **'Set Custom Password'**
  String get dialog_set_password_title;

  /// No description provided for @dialog_set_password_message.
  ///
  /// In en, this message translates to:
  /// **'Enter a new access password. This replaces the auto-generated token.'**
  String get dialog_set_password_message;

  /// No description provided for @dialog_set_password_hint.
  ///
  /// In en, this message translates to:
  /// **'New password (min 12 characters)'**
  String get dialog_set_password_hint;

  /// No description provided for @toast_password_set.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get toast_password_set;

  /// No description provided for @toast_password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 12 characters'**
  String get toast_password_too_short;

  /// No description provided for @toast_password_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save password — service not ready'**
  String get toast_password_save_failed;

  /// No description provided for @setup_guide_title.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get setup_guide_title;

  /// No description provided for @setup_guide_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Three quick steps to get the best experience:'**
  String get setup_guide_subtitle;

  /// No description provided for @setup_step_one_label.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get setup_step_one_label;

  /// No description provided for @setup_step_two_label.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get setup_step_two_label;

  /// No description provided for @setup_step_three_label.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get setup_step_three_label;

  /// No description provided for @setup_language_title.
  ///
  /// In en, this message translates to:
  /// **'Pick Your Language'**
  String get setup_language_title;

  /// No description provided for @setup_language_body.
  ///
  /// In en, this message translates to:
  /// **'Defaults to your head unit\'s language. Tap to choose a different one for the BladeWatch app and the web tunnel.'**
  String get setup_language_body;

  /// No description provided for @setup_language_button.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get setup_language_button;

  /// No description provided for @setup_autostart_title.
  ///
  /// In en, this message translates to:
  /// **'Disable Auto-Start Restriction'**
  String get setup_autostart_title;

  /// No description provided for @setup_autostart_body.
  ///
  /// In en, this message translates to:
  /// **'Tap below to open BYD Auto-Start. Find BladeWatch in the list and uncheck the box. BYD wipes this on every install — you\'ll redo it after updates.'**
  String get setup_autostart_body;

  /// No description provided for @setup_autostart_button.
  ///
  /// In en, this message translates to:
  /// **'Open BYD Auto-Start'**
  String get setup_autostart_button;

  /// No description provided for @setup_overlay_title.
  ///
  /// In en, this message translates to:
  /// **'Allow Display Over Other Apps'**
  String get setup_overlay_title;

  /// No description provided for @setup_overlay_body.
  ///
  /// In en, this message translates to:
  /// **'Enable this to show a floating status indicator for recording and trip tracking on top of other apps.'**
  String get setup_overlay_body;

  /// No description provided for @setup_overlay_button.
  ///
  /// In en, this message translates to:
  /// **'Open Overlay Settings'**
  String get setup_overlay_button;

  /// No description provided for @cd_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cd_close;

  /// No description provided for @language_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_picker_title;

  /// No description provided for @language_picker_subtitle_fmt.
  ///
  /// In en, this message translates to:
  /// **'{arg1} languages available'**
  String language_picker_subtitle_fmt(Object arg1);

  /// No description provided for @language_picker_subtitle_pending.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get language_picker_subtitle_pending;

  /// No description provided for @language_auto_title.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get language_auto_title;

  /// No description provided for @language_auto_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system · {arg1}'**
  String language_auto_subtitle(Object arg1);

  /// No description provided for @language_not_saved.
  ///
  /// In en, this message translates to:
  /// **'Language applied, but it could not be saved — it will reset when the app restarts.'**
  String get language_not_saved;

  /// No description provided for @language_label_auto_fmt.
  ///
  /// In en, this message translates to:
  /// **'{arg1} · Auto'**
  String language_label_auto_fmt(Object arg1);

  /// No description provided for @adb_prompt.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get adb_prompt;

  /// No description provided for @adb_command_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter command…'**
  String get adb_command_hint;

  /// No description provided for @adb_preset_commands_header.
  ///
  /// In en, this message translates to:
  /// **'Preset commands'**
  String get adb_preset_commands_header;

  /// No description provided for @adb_output_header.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get adb_output_header;

  /// No description provided for @adb_output_ready.
  ///
  /// In en, this message translates to:
  /// **'\$ Ready for commands…'**
  String get adb_output_ready;

  /// No description provided for @adb_console_hero_title.
  ///
  /// In en, this message translates to:
  /// **'ADB Console'**
  String get adb_console_hero_title;

  /// No description provided for @adb_console_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Run shell commands on the device'**
  String get adb_console_hero_subtitle;

  /// No description provided for @adb_console_unavailable_title.
  ///
  /// In en, this message translates to:
  /// **'ADB is not connected'**
  String get adb_console_unavailable_title;

  /// No description provided for @adb_console_unavailable_body.
  ///
  /// In en, this message translates to:
  /// **'On this vehicle, the standard \"USB debugging\" toggle in Developer Options is not enough by itself — the head unit\'s own wireless ADB (network debugging) setting also needs to be on, and a system update can reset it. Re-enable wireless ADB on the head unit, or connect via USB.'**
  String get adb_console_unavailable_body;

  /// No description provided for @adb_console_auth_pending_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get adb_console_auth_pending_title;

  /// No description provided for @adb_console_auth_pending_body.
  ///
  /// In en, this message translates to:
  /// **'Check the head unit\'s screen for an \"Allow USB debugging?\" prompt and accept it, then retry.'**
  String get adb_console_auth_pending_body;

  /// No description provided for @performance_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to performance monitor…'**
  String get performance_connecting;

  /// No description provided for @performance_hero_title.
  ///
  /// In en, this message translates to:
  /// **'System Performance'**
  String get performance_hero_title;

  /// No description provided for @performance_cpu_title.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get performance_cpu_title;

  /// No description provided for @performance_cpu_system_usage.
  ///
  /// In en, this message translates to:
  /// **'System Usage'**
  String get performance_cpu_system_usage;

  /// No description provided for @performance_cpu_app_usage.
  ///
  /// In en, this message translates to:
  /// **'App Usage'**
  String get performance_cpu_app_usage;

  /// No description provided for @performance_frequency_label.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get performance_frequency_label;

  /// No description provided for @performance_temperature_label.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get performance_temperature_label;

  /// No description provided for @performance_temperature_na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get performance_temperature_na;

  /// No description provided for @performance_memory_title.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get performance_memory_title;

  /// No description provided for @performance_usage_label.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get performance_usage_label;

  /// No description provided for @performance_memory_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get performance_memory_total;

  /// No description provided for @performance_memory_used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get performance_memory_used;

  /// No description provided for @performance_memory_app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get performance_memory_app;

  /// No description provided for @performance_gpu_title.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get performance_gpu_title;

  /// No description provided for @performance_app_process_title.
  ///
  /// In en, this message translates to:
  /// **'App Process'**
  String get performance_app_process_title;

  /// No description provided for @performance_threads_label.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get performance_threads_label;

  /// No description provided for @performance_gc_cycles_label.
  ///
  /// In en, this message translates to:
  /// **'GC Cycles'**
  String get performance_gc_cycles_label;

  /// No description provided for @performance_open_fds_label.
  ///
  /// In en, this message translates to:
  /// **'Open FDs'**
  String get performance_open_fds_label;

  /// No description provided for @performance_refreshing_footer.
  ///
  /// In en, this message translates to:
  /// **'Refreshing every 3 seconds'**
  String get performance_refreshing_footer;

  /// No description provided for @webview_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get webview_loading;

  /// No description provided for @webview_camera_daemon_not_running.
  ///
  /// In en, this message translates to:
  /// **'Camera Not Running'**
  String get webview_camera_daemon_not_running;

  /// No description provided for @webview_start_camera_daemon.
  ///
  /// In en, this message translates to:
  /// **'Start the Camera service from the Services screen to access this page.'**
  String get webview_start_camera_daemon;

  /// No description provided for @zrok_enable_token_hint.
  ///
  /// In en, this message translates to:
  /// **'Enable Token'**
  String get zrok_enable_token_hint;

  /// No description provided for @zrok_token_storage_note.
  ///
  /// In en, this message translates to:
  /// **'Token is stored securely and shared between the app and background services.'**
  String get zrok_token_storage_note;

  /// No description provided for @zrok_reset_environment.
  ///
  /// In en, this message translates to:
  /// **'Reset Zrok Environment'**
  String get zrok_reset_environment;

  /// No description provided for @zrok_reset_environment_desc.
  ///
  /// In en, this message translates to:
  /// **'Removes environment and token. You will need to re-enable with your token (uses a device slot).'**
  String get zrok_reset_environment_desc;

  /// No description provided for @reset_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Data'**
  String get reset_title;

  /// No description provided for @reset_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe accumulated data by category'**
  String get reset_subtitle;

  /// No description provided for @reset_warning.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Recordings, trips, and battery history will be permanently deleted.'**
  String get reset_warning;

  /// No description provided for @reset_cat_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get reset_cat_trips;

  /// No description provided for @reset_cat_trips_desc.
  ///
  /// In en, this message translates to:
  /// **'Trip history, routes, weekly/monthly rollups'**
  String get reset_cat_trips_desc;

  /// No description provided for @reset_cat_soc_history.
  ///
  /// In en, this message translates to:
  /// **'SoC & 12V history'**
  String get reset_cat_soc_history;

  /// No description provided for @reset_cat_soc_history_desc.
  ///
  /// In en, this message translates to:
  /// **'SoC samples, charging sessions, voltage logs'**
  String get reset_cat_soc_history_desc;

  /// No description provided for @reset_cat_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings (videos)'**
  String get reset_cat_recordings;

  /// No description provided for @reset_cat_recordings_desc.
  ///
  /// In en, this message translates to:
  /// **'All MP4s in the recordings folder'**
  String get reset_cat_recordings_desc;

  /// No description provided for @reset_cat_sentry_events.
  ///
  /// In en, this message translates to:
  /// **'Surveillance events'**
  String get reset_cat_sentry_events;

  /// No description provided for @reset_cat_sentry_events_desc.
  ///
  /// In en, this message translates to:
  /// **'Surveillance event clips and JSON sidecars'**
  String get reset_cat_sentry_events_desc;

  /// No description provided for @reset_cat_proximity.
  ///
  /// In en, this message translates to:
  /// **'Proximity recordings'**
  String get reset_cat_proximity;

  /// No description provided for @reset_cat_proximity_desc.
  ///
  /// In en, this message translates to:
  /// **'Radar-triggered event MP4s'**
  String get reset_cat_proximity_desc;

  /// No description provided for @reset_cat_trip_files.
  ///
  /// In en, this message translates to:
  /// **'Trip telemetry files'**
  String get reset_cat_trip_files;

  /// No description provided for @reset_cat_trip_files_desc.
  ///
  /// In en, this message translates to:
  /// **'Per-trip JSON telemetry on disk'**
  String get reset_cat_trip_files_desc;

  /// No description provided for @recording_lib_chip_any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get recording_lib_chip_any;

  /// No description provided for @recording_lib_chip_person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get recording_lib_chip_person;

  /// No description provided for @recording_lib_chip_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get recording_lib_chip_vehicle;

  /// No description provided for @recording_lib_chip_bike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get recording_lib_chip_bike;

  /// No description provided for @recording_lib_chip_animal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get recording_lib_chip_animal;

  /// No description provided for @recording_lib_chip_alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get recording_lib_chip_alert;

  /// No description provided for @recording_lib_chip_critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get recording_lib_chip_critical;

  /// No description provided for @recording_lib_selected_count_zero.
  ///
  /// In en, this message translates to:
  /// **'0 selected'**
  String get recording_lib_selected_count_zero;

  /// No description provided for @recording_lib_no_recordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings'**
  String get recording_lib_no_recordings;

  /// No description provided for @recording_lib_filter_button.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get recording_lib_filter_button;

  /// No description provided for @recording_lib_filter_button_active.
  ///
  /// In en, this message translates to:
  /// **'Filter · {arg1}'**
  String recording_lib_filter_button_active(Object arg1);

  /// No description provided for @recording_lib_filter_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Filter recordings'**
  String get recording_lib_filter_sheet_title;

  /// No description provided for @recording_lib_filter_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get recording_lib_filter_apply;

  /// No description provided for @recording_lib_filter_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get recording_lib_filter_reset;

  /// No description provided for @recording_lib_filter_section_what.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get recording_lib_filter_section_what;

  /// No description provided for @recording_lib_filter_section_severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get recording_lib_filter_section_severity;

  /// No description provided for @recording_lib_filter_section_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get recording_lib_filter_section_type;

  /// No description provided for @recording_lib_chip_type_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get recording_lib_chip_type_normal;

  /// No description provided for @recording_lib_chip_type_proximity.
  ///
  /// In en, this message translates to:
  /// **'Proximity'**
  String get recording_lib_chip_type_proximity;

  /// No description provided for @recording_lib_date_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get recording_lib_date_today;

  /// No description provided for @recording_lib_date_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get recording_lib_date_yesterday;

  /// No description provided for @recording_lib_clip_count.
  ///
  /// In en, this message translates to:
  /// **'{arg1} clips'**
  String recording_lib_clip_count(Object arg1);

  /// No description provided for @recording_lib_clip_count_one.
  ///
  /// In en, this message translates to:
  /// **'{arg1} clip'**
  String recording_lib_clip_count_one(Object arg1);

  /// No description provided for @recording_lib_pick_date.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get recording_lib_pick_date;

  /// No description provided for @recording_lib_date_all_days.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get recording_lib_date_all_days;

  /// No description provided for @cd_clear_date_filter.
  ///
  /// In en, this message translates to:
  /// **'Show all days'**
  String get cd_clear_date_filter;

  /// No description provided for @recording_lib_section_morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get recording_lib_section_morning;

  /// No description provided for @recording_lib_section_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get recording_lib_section_afternoon;

  /// No description provided for @recording_lib_section_evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get recording_lib_section_evening;

  /// No description provided for @recording_lib_section_night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get recording_lib_section_night;

  /// No description provided for @cd_previous_day.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get cd_previous_day;

  /// No description provided for @cd_next_day.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get cd_next_day;

  /// No description provided for @cd_open_filters.
  ///
  /// In en, this message translates to:
  /// **'Open filters'**
  String get cd_open_filters;

  /// No description provided for @cd_clear_filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get cd_clear_filter;

  /// No description provided for @player_title_recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get player_title_recording;

  /// No description provided for @player_time_zero.
  ///
  /// In en, this message translates to:
  /// **'0:00'**
  String get player_time_zero;

  /// No description provided for @player_time_separator.
  ///
  /// In en, this message translates to:
  /// **' / '**
  String get player_time_separator;

  /// No description provided for @daemon_name_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera Daemon'**
  String get daemon_name_camera;

  /// No description provided for @daemon_name_surveillance.
  ///
  /// In en, this message translates to:
  /// **'Surveillance Daemon'**
  String get daemon_name_surveillance;

  /// No description provided for @daemon_name_acc.
  ///
  /// In en, this message translates to:
  /// **'ACC Surveillance'**
  String get daemon_name_acc;

  /// No description provided for @daemon_name_zrok.
  ///
  /// In en, this message translates to:
  /// **'Zrok Tunnel'**
  String get daemon_name_zrok;

  /// No description provided for @daemons_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Background services'**
  String get daemons_hero_title;

  /// No description provided for @daemons_count_pending.
  ///
  /// In en, this message translates to:
  /// **'Loading services…'**
  String get daemons_count_pending;

  /// No description provided for @daemons_count_fmt.
  ///
  /// In en, this message translates to:
  /// **'{arg1} of {arg2} running'**
  String daemons_count_fmt(Object arg1, Object arg2);

  /// No description provided for @battery_health_title.
  ///
  /// In en, this message translates to:
  /// **'Battery Health'**
  String get battery_health_title;

  /// No description provided for @battery_health_subtitle.
  ///
  /// In en, this message translates to:
  /// **'State of Health'**
  String get battery_health_subtitle;

  /// No description provided for @battery_health_dashes.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get battery_health_dashes;

  /// No description provided for @battery_health_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data…'**
  String get battery_health_waiting;

  /// No description provided for @battery_health_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get battery_health_source;

  /// No description provided for @battery_health_method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get battery_health_method;

  /// No description provided for @battery_health_capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get battery_health_capacity;

  /// No description provided for @battery_health_samples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get battery_health_samples;

  /// No description provided for @battery_health_last_updated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get battery_health_last_updated;

  /// No description provided for @battery_health_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get battery_health_unavailable;

  /// No description provided for @battery_health_unavailable_desc.
  ///
  /// In en, this message translates to:
  /// **'Battery health estimation is not available.'**
  String get battery_health_unavailable_desc;

  /// No description provided for @battery_health_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset SOH Estimation'**
  String get battery_health_reset;

  /// No description provided for @battery_health_reset_desc.
  ///
  /// In en, this message translates to:
  /// **'Clears all data and re-estimates from scratch. Use if battery was replaced or reading seems incorrect.'**
  String get battery_health_reset_desc;

  /// No description provided for @soh_dialog_model_label.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get soh_dialog_model_label;

  /// No description provided for @soh_dialog_pack_capacity_label.
  ///
  /// In en, this message translates to:
  /// **'Pack capacity'**
  String get soh_dialog_pack_capacity_label;

  /// No description provided for @soh_dialog_estimated_capacity_label.
  ///
  /// In en, this message translates to:
  /// **'Effective capacity'**
  String get soh_dialog_estimated_capacity_label;

  /// No description provided for @soh_dialog_calibration_anchor_label.
  ///
  /// In en, this message translates to:
  /// **'Last calibrated'**
  String get soh_dialog_calibration_anchor_label;

  /// No description provided for @soh_dialog_source_user.
  ///
  /// In en, this message translates to:
  /// **'user-set'**
  String get soh_dialog_source_user;

  /// No description provided for @soh_dialog_source_auto.
  ///
  /// In en, this message translates to:
  /// **'auto-detected'**
  String get soh_dialog_source_auto;

  /// No description provided for @soh_dialog_model_not_selected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get soh_dialog_model_not_selected;

  /// No description provided for @soh_dialog_capacity_not_detected.
  ///
  /// In en, this message translates to:
  /// **'Not detected'**
  String get soh_dialog_capacity_not_detected;

  /// No description provided for @soh_dialog_calibration_format.
  ///
  /// In en, this message translates to:
  /// **'{arg1}% on {arg2}'**
  String soh_dialog_calibration_format(Object arg1, Object arg2);

  /// No description provided for @dialog_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialog_ok;

  /// No description provided for @recordings_deleted_count.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{{arg1} recording deleted} other{{arg1} recordings deleted}}'**
  String recordings_deleted_count(num arg1);

  /// No description provided for @delete_recordings_title.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{Delete {arg1} Recording} other{Delete {arg1} Recordings}}'**
  String delete_recordings_title(num arg1);

  /// No description provided for @delete_recordings_message.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{This will permanently delete {arg1} recording. This cannot be undone.} other{This will permanently delete {arg1} recordings. This cannot be undone.}}'**
  String delete_recordings_message(num arg1);

  /// No description provided for @toast_app_up_to_date.
  ///
  /// In en, this message translates to:
  /// **'App is up to date (v{arg1})'**
  String toast_app_up_to_date(Object arg1);

  /// No description provided for @toast_storage_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required for recordings'**
  String get toast_storage_permission_required;

  /// No description provided for @toast_url_copied_short.
  ///
  /// In en, this message translates to:
  /// **'URL copied!'**
  String get toast_url_copied_short;

  /// No description provided for @toast_camera_set_to_auto.
  ///
  /// In en, this message translates to:
  /// **'Camera set to Auto'**
  String get toast_camera_set_to_auto;

  /// No description provided for @toast_failed_to_save_short.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get toast_failed_to_save_short;

  /// No description provided for @toast_failed_with_message.
  ///
  /// In en, this message translates to:
  /// **'Failed: {arg1}'**
  String toast_failed_with_message(Object arg1);

  /// No description provided for @toast_camera_id_set.
  ///
  /// In en, this message translates to:
  /// **'Camera {arg1} set — next ACC cycle'**
  String toast_camera_id_set(Object arg1);

  /// No description provided for @toast_clearing_camera_config.
  ///
  /// In en, this message translates to:
  /// **'Clearing camera config…'**
  String get toast_clearing_camera_config;

  /// No description provided for @toast_restarting_camera_daemon.
  ///
  /// In en, this message translates to:
  /// **'Restarting camera service…'**
  String get toast_restarting_camera_daemon;

  /// No description provided for @toast_camera_daemon_restarting.
  ///
  /// In en, this message translates to:
  /// **'Camera service restarting with full probe'**
  String get toast_camera_daemon_restarting;

  /// No description provided for @toast_camera_restart_failed.
  ///
  /// In en, this message translates to:
  /// **'Config cleared but service restart failed. Please restart manually.'**
  String get toast_camera_restart_failed;

  /// No description provided for @toast_failed_with_message_x.
  ///
  /// In en, this message translates to:
  /// **'Failed: {arg1}'**
  String toast_failed_with_message_x(Object arg1);

  /// No description provided for @toast_soh_reset_success.
  ///
  /// In en, this message translates to:
  /// **'SOH estimation reset — will recalculate from next data'**
  String get toast_soh_reset_success;

  /// No description provided for @toast_soh_reset_failed_no_daemon.
  ///
  /// In en, this message translates to:
  /// **'Reset failed — service not responding and file not writable'**
  String get toast_soh_reset_failed_no_daemon;

  /// No description provided for @toast_soh_reset_failed_with_message.
  ///
  /// In en, this message translates to:
  /// **'Reset failed: {arg1}'**
  String toast_soh_reset_failed_with_message(Object arg1);

  /// No description provided for @toast_select_at_least_one_category.
  ///
  /// In en, this message translates to:
  /// **'Select at least one category'**
  String get toast_select_at_least_one_category;

  /// No description provided for @toast_reset_failed_with_error.
  ///
  /// In en, this message translates to:
  /// **'Reset failed: {arg1}'**
  String toast_reset_failed_with_error(Object arg1);

  /// No description provided for @toast_traffic_monitor_changing.
  ///
  /// In en, this message translates to:
  /// **'{arg1} traffic monitor…'**
  String toast_traffic_monitor_changing(Object arg1);

  /// No description provided for @dialog_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialog_close;

  /// No description provided for @dialog_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get dialog_reset;

  /// No description provided for @dialog_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialog_delete;

  /// No description provided for @dialog_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialog_save;

  /// No description provided for @dialog_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get dialog_enable;

  /// No description provided for @dialog_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get dialog_disable;

  /// No description provided for @dialog_keep_enabled.
  ///
  /// In en, this message translates to:
  /// **'Keep Enabled'**
  String get dialog_keep_enabled;

  /// No description provided for @dialog_keep_disabled.
  ///
  /// In en, this message translates to:
  /// **'Keep Disabled'**
  String get dialog_keep_disabled;

  /// No description provided for @dialog_regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get dialog_regenerate;

  /// No description provided for @dialog_reset_selected.
  ///
  /// In en, this message translates to:
  /// **'Reset Selected'**
  String get dialog_reset_selected;

  /// No description provided for @dialog_reset_following_title.
  ///
  /// In en, this message translates to:
  /// **'Reset the following?'**
  String get dialog_reset_following_title;

  /// No description provided for @dialog_reset_following_message.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.\n\n{arg1}'**
  String dialog_reset_following_message(Object arg1);

  /// No description provided for @dialog_reset_complete_title.
  ///
  /// In en, this message translates to:
  /// **'Reset complete'**
  String get dialog_reset_complete_title;

  /// No description provided for @dialog_traffic_cannot_check_title.
  ///
  /// In en, this message translates to:
  /// **'Cannot Check Status'**
  String get dialog_traffic_cannot_check_title;

  /// No description provided for @dialog_traffic_cannot_check_message.
  ///
  /// In en, this message translates to:
  /// **'ADB is not connected, and the app could not reconnect automatically.\n\nOn this vehicle, the standard \"USB debugging\" toggle in Developer Options is not enough by itself — the head unit\'s own wireless ADB (network debugging) setting also needs to be on, and a system update can reset it. Re-enable wireless ADB on the head unit, or connect via USB.\n\nThe status will update automatically once connected.'**
  String get dialog_traffic_cannot_check_message;

  /// No description provided for @dialog_traffic_disable_title.
  ///
  /// In en, this message translates to:
  /// **'Disable BYD Traffic Monitor?'**
  String get dialog_traffic_disable_title;

  /// No description provided for @dialog_traffic_disable_message.
  ///
  /// In en, this message translates to:
  /// **'The BYD Traffic Monitor (com.byd.trafficmonitor) is a built-in system app that continuously monitors road traffic conditions in the background.\n\nWhy disable it?\n\n• Consumes mobile data (even when parked)\n• Uses CPU and battery in the background\n• Not needed if you use a separate navigation app\n• Can interfere with the dashcam\'s network usage\n\nThis is safe to disable — it only affects the built-in traffic overlay on the map. Your navigation, Bluetooth, and all other car functions remain unaffected.\n\nA hard reboot is required after disabling (hold center console button 5 seconds).'**
  String get dialog_traffic_disable_message;

  /// No description provided for @dialog_traffic_enable_title.
  ///
  /// In en, this message translates to:
  /// **'Re-enable BYD Traffic Monitor?'**
  String get dialog_traffic_enable_title;

  /// No description provided for @dialog_traffic_enable_message.
  ///
  /// In en, this message translates to:
  /// **'The BYD Traffic Monitor is currently disabled.\n\nRe-enabling it will restore the built-in traffic overlay on the navigation map. Note that it will run in the background and consume mobile data.\n\nA hard reboot is required after enabling (hold center console button 5 seconds).'**
  String get dialog_traffic_enable_message;

  /// No description provided for @dialog_traffic_status_title.
  ///
  /// In en, this message translates to:
  /// **'Traffic Monitor {arg1}'**
  String dialog_traffic_status_title(Object arg1);

  /// No description provided for @dialog_traffic_reboot_message.
  ///
  /// In en, this message translates to:
  /// **'The change has been applied.\n\nPlease perform a hard reboot now:\nPress and hold the central console button for 5 seconds.'**
  String get dialog_traffic_reboot_message;

  /// No description provided for @traffic_monitor_loading.
  ///
  /// In en, this message translates to:
  /// **'Traffic Monitor: Checking…'**
  String get traffic_monitor_loading;

  /// No description provided for @traffic_monitor_tap_to_check.
  ///
  /// In en, this message translates to:
  /// **'Traffic Monitor (tap to check)'**
  String get traffic_monitor_tap_to_check;

  /// No description provided for @reset_label_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get reset_label_trips;

  /// No description provided for @reset_label_soc_history.
  ///
  /// In en, this message translates to:
  /// **'SoC + 12V history'**
  String get reset_label_soc_history;

  /// No description provided for @reset_label_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get reset_label_recordings;

  /// No description provided for @reset_label_sentry_events.
  ///
  /// In en, this message translates to:
  /// **'Surveillance events'**
  String get reset_label_sentry_events;

  /// No description provided for @reset_label_proximity.
  ///
  /// In en, this message translates to:
  /// **'Proximity recordings'**
  String get reset_label_proximity;

  /// No description provided for @reset_label_trip_files.
  ///
  /// In en, this message translates to:
  /// **'Trip telemetry files'**
  String get reset_label_trip_files;

  /// No description provided for @toast_access_code_copied.
  ///
  /// In en, this message translates to:
  /// **'Access code copied'**
  String get toast_access_code_copied;

  /// No description provided for @dialog_regenerate_token_title.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Token'**
  String get dialog_regenerate_token_title;

  /// No description provided for @dialog_regenerate_token_message.
  ///
  /// In en, this message translates to:
  /// **'This will invalidate the current token. All active sessions will be logged out. Continue?'**
  String get dialog_regenerate_token_message;

  /// No description provided for @toast_token_regenerated_logged_out.
  ///
  /// In en, this message translates to:
  /// **'New token generated. All sessions logged out.'**
  String get toast_token_regenerated_logged_out;

  /// No description provided for @toast_token_regenerated_restart.
  ///
  /// In en, this message translates to:
  /// **'Token regenerated. Services may need restart to apply.'**
  String get toast_token_regenerated_restart;

  /// No description provided for @toast_token_regenerated_no_notify.
  ///
  /// In en, this message translates to:
  /// **'Token regenerated. Could not notify background service.'**
  String get toast_token_regenerated_no_notify;

  /// No description provided for @toast_token_regenerated.
  ///
  /// In en, this message translates to:
  /// **'Token regenerated'**
  String get toast_token_regenerated;

  /// No description provided for @dashboard_no_tunnel.
  ///
  /// In en, this message translates to:
  /// **'No tunnel running'**
  String get dashboard_no_tunnel;

  /// No description provided for @dashboard_starting_zrok.
  ///
  /// In en, this message translates to:
  /// **'Starting Zrok tunnel…'**
  String get dashboard_starting_zrok;

  /// No description provided for @dashboard_waiting_url.
  ///
  /// In en, this message translates to:
  /// **'Waiting for tunnel URL…'**
  String get dashboard_waiting_url;

  /// No description provided for @dashboard_daemons_running.
  ///
  /// In en, this message translates to:
  /// **'{arg1}/{arg2} Running'**
  String dashboard_daemons_running(Object arg1, Object arg2);

  /// No description provided for @tunnel_label_zrok.
  ///
  /// In en, this message translates to:
  /// **'Zrok'**
  String get tunnel_label_zrok;

  /// No description provided for @clip_label_access_code.
  ///
  /// In en, this message translates to:
  /// **'Access Code'**
  String get clip_label_access_code;

  /// No description provided for @clip_label_url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get clip_label_url;

  /// No description provided for @toast_no_config_needed.
  ///
  /// In en, this message translates to:
  /// **'No configuration needed for {arg1}'**
  String toast_no_config_needed(Object arg1);

  /// No description provided for @dialog_zrok_token_title.
  ///
  /// In en, this message translates to:
  /// **'Zrok Tunnel Token'**
  String get dialog_zrok_token_title;

  /// No description provided for @dialog_zrok_token_message.
  ///
  /// In en, this message translates to:
  /// **'Enter your Zrok enable token.\nGet one at: zrok.io'**
  String get dialog_zrok_token_message;

  /// No description provided for @toast_token_cannot_be_empty.
  ///
  /// In en, this message translates to:
  /// **'Token cannot be empty'**
  String get toast_token_cannot_be_empty;

  /// No description provided for @dialog_zrok_reset_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Zrok Environment'**
  String get dialog_zrok_reset_title;

  /// No description provided for @dialog_zrok_reset_message.
  ///
  /// In en, this message translates to:
  /// **'This will:\n• Stop the zrok tunnel if running\n• Remove the zrok environment from this device\n• Delete the saved token\n\nYou will need to re-enter your token and re-enable. This uses one of your 5 device slots on zrok.io.\n\nAre you sure?'**
  String get dialog_zrok_reset_message;

  /// No description provided for @toast_resetting_zrok.
  ///
  /// In en, this message translates to:
  /// **'Resetting zrok environment…'**
  String get toast_resetting_zrok;

  /// No description provided for @toast_zrok_reset_success.
  ///
  /// In en, this message translates to:
  /// **'Zrok environment reset. Enter a new token to set up again.'**
  String get toast_zrok_reset_success;

  /// No description provided for @toast_zrok_reset_partial.
  ///
  /// In en, this message translates to:
  /// **'Environment reset (token file may need manual cleanup)'**
  String get toast_zrok_reset_partial;

  /// No description provided for @toast_zrok_reset_warnings.
  ///
  /// In en, this message translates to:
  /// **'Environment reset (with warnings: {arg1})'**
  String toast_zrok_reset_warnings(Object arg1);

  /// No description provided for @zrok_no_token_configured.
  ///
  /// In en, this message translates to:
  /// **'No token configured. Tap to set up.'**
  String get zrok_no_token_configured;

  /// No description provided for @toast_zrok_token_saved.
  ///
  /// In en, this message translates to:
  /// **'Token saved'**
  String get toast_zrok_token_saved;

  /// No description provided for @toast_zrok_token_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save token'**
  String get toast_zrok_token_save_failed;

  /// No description provided for @toast_zrok_token_deleted.
  ///
  /// In en, this message translates to:
  /// **'Token deleted'**
  String get toast_zrok_token_deleted;

  /// No description provided for @toast_zrok_token_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete token'**
  String get toast_zrok_token_delete_failed;

  /// No description provided for @toast_fetching_log.
  ///
  /// In en, this message translates to:
  /// **'Fetching {arg1} log…'**
  String toast_fetching_log(Object arg1);

  /// No description provided for @toast_log_empty_or_missing.
  ///
  /// In en, this message translates to:
  /// **'Log file is empty or not found'**
  String get toast_log_empty_or_missing;

  /// No description provided for @toast_log_empty.
  ///
  /// In en, this message translates to:
  /// **'Log file is empty'**
  String get toast_log_empty;

  /// No description provided for @toast_log_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save log: {arg1}'**
  String toast_log_save_failed(Object arg1);

  /// No description provided for @toast_log_not_found.
  ///
  /// In en, this message translates to:
  /// **'Log file not found or unreadable'**
  String get toast_log_not_found;

  /// No description provided for @log_share_title.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Log - {arg2}'**
  String log_share_title(Object arg1, Object arg2);

  /// No description provided for @log_share_chooser.
  ///
  /// In en, this message translates to:
  /// **'Share {arg1} Log'**
  String log_share_chooser(Object arg1);

  /// No description provided for @log_header_title.
  ///
  /// In en, this message translates to:
  /// **'=== {arg1} Log ==='**
  String log_header_title(Object arg1);

  /// No description provided for @log_header_source.
  ///
  /// In en, this message translates to:
  /// **'Source: {arg1}'**
  String log_header_source(Object arg1);

  /// No description provided for @log_header_exported.
  ///
  /// In en, this message translates to:
  /// **'Exported: {arg1}'**
  String log_header_exported(Object arg1);

  /// No description provided for @log_header_truncated.
  ///
  /// In en, this message translates to:
  /// **'NOTE: Log truncated to last 10000 lines (total: {arg1} lines)'**
  String log_header_truncated(Object arg1);

  /// No description provided for @toast_cannot_play_video.
  ///
  /// In en, this message translates to:
  /// **'Cannot play video: {arg1}'**
  String toast_cannot_play_video(Object arg1);

  /// No description provided for @dialog_delete_recording_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Recording'**
  String get dialog_delete_recording_title;

  /// No description provided for @dialog_delete_recording_message.
  ///
  /// In en, this message translates to:
  /// **'Delete {arg1}?\nThis cannot be undone.'**
  String dialog_delete_recording_message(Object arg1);

  /// No description provided for @toast_recording_deleted.
  ///
  /// In en, this message translates to:
  /// **'Recording deleted'**
  String get toast_recording_deleted;

  /// No description provided for @toast_recording_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete recording'**
  String get toast_recording_delete_failed;

  /// No description provided for @toast_batch_delete_partial.
  ///
  /// In en, this message translates to:
  /// **'{arg1} deleted, {arg2} failed'**
  String toast_batch_delete_partial(Object arg1, Object arg2);

  /// No description provided for @play_with_chooser.
  ///
  /// In en, this message translates to:
  /// **'Play with'**
  String get play_with_chooser;

  /// No description provided for @setup_version_banner.
  ///
  /// In en, this message translates to:
  /// **'Updated to v{arg1} — re-confirm autostart, BYD wipes it on every install'**
  String setup_version_banner(Object arg1);

  /// No description provided for @setup_overlay_already_granted.
  ///
  /// In en, this message translates to:
  /// **'Already Granted'**
  String get setup_overlay_already_granted;

  /// No description provided for @camera_current_manual.
  ///
  /// In en, this message translates to:
  /// **'Current: Camera {arg1} (Manual)'**
  String camera_current_manual(Object arg1);

  /// No description provided for @camera_current_auto_label.
  ///
  /// In en, this message translates to:
  /// **'Current: Auto'**
  String get camera_current_auto_label;

  /// No description provided for @soh_estimation_active.
  ///
  /// In en, this message translates to:
  /// **'Estimation active'**
  String get soh_estimation_active;

  /// No description provided for @soh_oem_readout.
  ///
  /// In en, this message translates to:
  /// **'Vehicle SOH readout — waiting for calculated estimate'**
  String get soh_oem_readout;

  /// No description provided for @soh_nominal_baseline.
  ///
  /// In en, this message translates to:
  /// **'Nominal baseline — waiting for trusted SOH data'**
  String get soh_nominal_baseline;

  /// No description provided for @soh_no_estimate_yet.
  ///
  /// In en, this message translates to:
  /// **'No estimate yet — waiting for data'**
  String get soh_no_estimate_yet;

  /// No description provided for @recording_lib_selected_count.
  ///
  /// In en, this message translates to:
  /// **'{arg1} selected'**
  String recording_lib_selected_count(Object arg1);

  /// No description provided for @video_player_playback_error.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get video_player_playback_error;

  /// No description provided for @video_player_no_events.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get video_player_no_events;

  /// No description provided for @daemon_configuration_required.
  ///
  /// In en, this message translates to:
  /// **'Configuration required'**
  String get daemon_configuration_required;

  /// No description provided for @daemon_configuration_message.
  ///
  /// In en, this message translates to:
  /// **'{arg1}'**
  String daemon_configuration_message(Object arg1);

  /// No description provided for @nav_page_video_player.
  ///
  /// In en, this message translates to:
  /// **'Video Player'**
  String get nav_page_video_player;

  /// No description provided for @status_overlay_notif_title.
  ///
  /// In en, this message translates to:
  /// **'BladeWatch Status'**
  String get status_overlay_notif_title;

  /// No description provided for @status_overlay_notif_text.
  ///
  /// In en, this message translates to:
  /// **'Status overlay active'**
  String get status_overlay_notif_text;

  /// No description provided for @rail_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get rail_dashboard;

  /// No description provided for @rail_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get rail_live;

  /// No description provided for @rail_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get rail_recordings;

  /// No description provided for @rail_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get rail_vehicle;

  /// No description provided for @rail_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get rail_trips;

  /// No description provided for @rail_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get rail_location;

  /// No description provided for @rail_diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get rail_diagnostics;

  /// No description provided for @rail_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get rail_settings;

  /// No description provided for @settings_section_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_section_appearance;

  /// No description provided for @settings_section_recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get settings_section_recording;

  /// No description provided for @settings_section_surveillance.
  ///
  /// In en, this message translates to:
  /// **'Surveillance'**
  String get settings_section_surveillance;

  /// No description provided for @settings_section_daemons.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get settings_section_daemons;

  /// No description provided for @settings_section_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settings_section_privacy;

  /// No description provided for @settings_section_overlay.
  ///
  /// In en, this message translates to:
  /// **'Status overlay'**
  String get settings_section_overlay;

  /// No description provided for @settings_overlay_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which segments of the floating status pill stay visible.'**
  String get settings_overlay_subtitle;

  /// No description provided for @settings_overlay_camera_title.
  ///
  /// In en, this message translates to:
  /// **'Camera indicator'**
  String get settings_overlay_camera_title;

  /// No description provided for @settings_overlay_camera_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the REC / PROX badge while recording is active.'**
  String get settings_overlay_camera_subtitle;

  /// No description provided for @settings_overlay_trip_title.
  ///
  /// In en, this message translates to:
  /// **'Trip indicator'**
  String get settings_overlay_trip_title;

  /// No description provided for @settings_overlay_trip_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the TRIP badge while trip detection is running.'**
  String get settings_overlay_trip_subtitle;

  /// No description provided for @settings_section_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_section_about;

  /// No description provided for @settings_subrail_overline.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings_subrail_overline;

  /// No description provided for @cd_settings_subrail.
  ///
  /// In en, this message translates to:
  /// **'Settings sub-rail'**
  String get cd_settings_subrail;

  /// No description provided for @settings_privacy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settings_privacy_title;

  /// No description provided for @settings_privacy_body.
  ///
  /// In en, this message translates to:
  /// **'Reset clears recordings index, cached credentials, service state, and on-device preferences. The action cannot be undone.'**
  String get settings_privacy_body;

  /// No description provided for @settings_about_title.
  ///
  /// In en, this message translates to:
  /// **'About BladeWatch'**
  String get settings_about_title;

  /// No description provided for @settings_about_version_label.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_about_version_label;

  /// No description provided for @settings_about_package_label.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get settings_about_package_label;

  /// No description provided for @settings_about_support_section.
  ///
  /// In en, this message translates to:
  /// **'Powered by people like you'**
  String get settings_about_support_section;

  /// No description provided for @settings_about_support_share_title.
  ///
  /// In en, this message translates to:
  /// **'Tell a fellow owner'**
  String get settings_about_support_share_title;

  /// No description provided for @settings_about_support_share_value.
  ///
  /// In en, this message translates to:
  /// **'Every shared link helps another BYD owner discover BladeWatch.'**
  String get settings_about_support_share_value;

  /// No description provided for @settings_about_support_share_message.
  ///
  /// In en, this message translates to:
  /// **'Check out BladeWatch — open-source surveillance & dashcam for BYD: https://bladewatch-5lc.pages.dev/'**
  String get settings_about_support_share_message;

  /// No description provided for @settings_about_support_share_chooser.
  ///
  /// In en, this message translates to:
  /// **'Share BladeWatch'**
  String get settings_about_support_share_chooser;

  /// No description provided for @settings_about_open_link_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open link.'**
  String get settings_about_open_link_failed;

  /// No description provided for @settings_about_open_link_copied.
  ///
  /// In en, this message translates to:
  /// **'No browser found. URL copied: {arg1}'**
  String settings_about_open_link_copied(Object arg1);

  /// No description provided for @settings_about_support_kofi_title.
  ///
  /// In en, this message translates to:
  /// **'Fuel the next release'**
  String get settings_about_support_kofi_title;

  /// No description provided for @settings_about_support_kofi_value.
  ///
  /// In en, this message translates to:
  /// **'A coffee on Ko-fi keeps the late-night commits coming.'**
  String get settings_about_support_kofi_value;

  /// No description provided for @settings_about_support_kofi_url.
  ///
  /// In en, this message translates to:
  /// **'https://ko-fi.com/E1E71XALHX'**
  String get settings_about_support_kofi_url;

  /// No description provided for @settings_about_license_title.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settings_about_license_title;

  /// No description provided for @settings_about_license_value.
  ///
  /// In en, this message translates to:
  /// **'MIT — open source. Tap to view full text.'**
  String get settings_about_license_value;

  /// No description provided for @settings_about_source_title.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settings_about_source_title;

  /// No description provided for @settings_about_source_value.
  ///
  /// In en, this message translates to:
  /// **'github.com/yash-srivastava/BladeWatch-release'**
  String get settings_about_source_value;

  /// No description provided for @settings_about_license_url.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/yash-srivastava/BladeWatch-release/blob/main/LICENSE'**
  String get settings_about_license_url;

  /// No description provided for @settings_about_source_url.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/yash-srivastava/BladeWatch-release'**
  String get settings_about_source_url;

  /// No description provided for @settings_about_star_title.
  ///
  /// In en, this message translates to:
  /// **'Star us on GitHub'**
  String get settings_about_star_title;

  /// No description provided for @settings_about_star_value.
  ///
  /// In en, this message translates to:
  /// **'Takes a second. Means a lot.'**
  String get settings_about_star_value;

  /// No description provided for @settings_about_star_url.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/yash-srivastava/BladeWatch-release'**
  String get settings_about_star_url;

  /// No description provided for @settings_about_thanks_title.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get settings_about_thanks_title;

  /// No description provided for @settings_about_thanks_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Built with the help of contributors and supporters.'**
  String get settings_about_thanks_subtitle;

  /// No description provided for @settings_about_contributors_title.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get settings_about_contributors_title;

  /// No description provided for @settings_about_supporters_title.
  ///
  /// In en, this message translates to:
  /// **'Supporters'**
  String get settings_about_supporters_title;

  /// No description provided for @settings_about_thanks_empty.
  ///
  /// In en, this message translates to:
  /// **'List populates as people pitch in.'**
  String get settings_about_thanks_empty;

  /// No description provided for @settings_theme_label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme_label;

  /// No description provided for @settings_theme_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto (follow system)'**
  String get settings_theme_auto;

  /// No description provided for @settings_theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_theme_light;

  /// No description provided for @settings_theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_theme_dark;

  /// No description provided for @settings_language_label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language_label;

  /// No description provided for @settings_drive_side_label.
  ///
  /// In en, this message translates to:
  /// **'Navigation Side'**
  String get settings_drive_side_label;

  /// No description provided for @settings_drive_side_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which side of the screen the navigation menu appears on.'**
  String get settings_drive_side_subtitle;

  /// No description provided for @settings_drive_side_left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get settings_drive_side_left;

  /// No description provided for @settings_drive_side_left_hint.
  ///
  /// In en, this message translates to:
  /// **'LHD · default'**
  String get settings_drive_side_left_hint;

  /// No description provided for @settings_drive_side_right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get settings_drive_side_right;

  /// No description provided for @settings_drive_side_right_hint.
  ///
  /// In en, this message translates to:
  /// **'RHD vehicles'**
  String get settings_drive_side_right_hint;

  /// No description provided for @settings_drive_side_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settings_drive_side_auto;

  /// No description provided for @settings_drive_side_auto_hint.
  ///
  /// In en, this message translates to:
  /// **'Detect from vehicle'**
  String get settings_drive_side_auto_hint;

  /// No description provided for @settings_drive_side_caption_left.
  ///
  /// In en, this message translates to:
  /// **'Navigation on left'**
  String get settings_drive_side_caption_left;

  /// No description provided for @settings_drive_side_caption_right.
  ///
  /// In en, this message translates to:
  /// **'Navigation on right'**
  String get settings_drive_side_caption_right;

  /// No description provided for @settings_drive_side_caption_auto_left.
  ///
  /// In en, this message translates to:
  /// **'Auto — vehicle reports left-hand drive'**
  String get settings_drive_side_caption_auto_left;

  /// No description provided for @settings_drive_side_caption_auto_right.
  ///
  /// In en, this message translates to:
  /// **'Auto — vehicle reports right-hand drive'**
  String get settings_drive_side_caption_auto_right;

  /// No description provided for @settings_drive_side_caption_auto_unknown.
  ///
  /// In en, this message translates to:
  /// **'Auto — vehicle unavailable, using left'**
  String get settings_drive_side_caption_auto_unknown;

  /// No description provided for @recordings_title.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get recordings_title;

  /// No description provided for @recordings_segment_dashcam.
  ///
  /// In en, this message translates to:
  /// **'Dashcam'**
  String get recordings_segment_dashcam;

  /// No description provided for @recordings_segment_surveillance.
  ///
  /// In en, this message translates to:
  /// **'Surveillance'**
  String get recordings_segment_surveillance;

  /// No description provided for @recordings_action_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get recordings_action_settings;

  /// No description provided for @recordings_summary_format.
  ///
  /// In en, this message translates to:
  /// **'{arg1} today · {arg2} total · {arg3}'**
  String recordings_summary_format(Object arg1, Object arg2, Object arg3);

  /// No description provided for @recordings_segment_dashcam_count.
  ///
  /// In en, this message translates to:
  /// **'Dashcam · {arg1}'**
  String recordings_segment_dashcam_count(Object arg1);

  /// No description provided for @recordings_segment_surveillance_count.
  ///
  /// In en, this message translates to:
  /// **'Surveillance · {arg1}'**
  String recordings_segment_surveillance_count(Object arg1);

  /// No description provided for @recordings_summary_pending.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get recordings_summary_pending;

  /// No description provided for @recordings_preview_placeholder_title.
  ///
  /// In en, this message translates to:
  /// **'Select a recording'**
  String get recordings_preview_placeholder_title;

  /// No description provided for @recordings_preview_placeholder_body.
  ///
  /// In en, this message translates to:
  /// **'Tap any item on the left to play it.'**
  String get recordings_preview_placeholder_body;

  /// No description provided for @diagnostics_section_adb_console.
  ///
  /// In en, this message translates to:
  /// **'ADB Console'**
  String get diagnostics_section_adb_console;

  /// No description provided for @diagnostics_section_traffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic monitor'**
  String get diagnostics_section_traffic;

  /// No description provided for @diagnostics_section_camera_probe.
  ///
  /// In en, this message translates to:
  /// **'Camera probe'**
  String get diagnostics_section_camera_probe;

  /// No description provided for @diagnostics_section_battery.
  ///
  /// In en, this message translates to:
  /// **'Battery health'**
  String get diagnostics_section_battery;

  /// No description provided for @diagnostics_section_performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get diagnostics_section_performance;

  /// No description provided for @diagnostics_hero_title.
  ///
  /// In en, this message translates to:
  /// **'System diagnostics'**
  String get diagnostics_hero_title;

  /// No description provided for @diagnostics_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Live health, logs, and probes for the device.'**
  String get diagnostics_hero_subtitle;

  /// No description provided for @diagnostics_health_clear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get diagnostics_health_clear;

  /// No description provided for @diagnostics_health_section.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get diagnostics_health_section;

  /// No description provided for @diagnostics_health_network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get diagnostics_health_network;

  /// No description provided for @diagnostics_health_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get diagnostics_health_storage;

  /// No description provided for @diagnostics_health_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get diagnostics_health_camera;

  /// No description provided for @diagnostics_health_battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get diagnostics_health_battery;

  /// No description provided for @diagnostics_metric_pending.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get diagnostics_metric_pending;

  /// No description provided for @diagnostics_metric_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get diagnostics_metric_online;

  /// No description provided for @diagnostics_network_tunnel_label.
  ///
  /// In en, this message translates to:
  /// **'Tunnel · {arg1}'**
  String diagnostics_network_tunnel_label(Object arg1);

  /// No description provided for @diagnostics_tunnel_state_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get diagnostics_tunnel_state_online;

  /// No description provided for @diagnostics_tunnel_state_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get diagnostics_tunnel_state_offline;

  /// No description provided for @diagnostics_tunnel_state_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get diagnostics_tunnel_state_connecting;

  /// No description provided for @diagnostics_network_mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get diagnostics_network_mobile;

  /// No description provided for @diagnostics_network_ethernet.
  ///
  /// In en, this message translates to:
  /// **'Ethernet'**
  String get diagnostics_network_ethernet;

  /// No description provided for @diagnostics_network_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get diagnostics_network_offline;

  /// No description provided for @diagnostics_storage_used_line.
  ///
  /// In en, this message translates to:
  /// **'{arg1} clips · {arg2} used'**
  String diagnostics_storage_used_line(Object arg1, Object arg2);

  /// No description provided for @diagnostics_storage_free_line.
  ///
  /// In en, this message translates to:
  /// **'{arg1} free'**
  String diagnostics_storage_free_line(Object arg1);

  /// No description provided for @diagnostics_logs_card_title.
  ///
  /// In en, this message translates to:
  /// **'Live event log'**
  String get diagnostics_logs_card_title;

  /// No description provided for @diagnostics_logs_card_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Streaming output from running services.'**
  String get diagnostics_logs_card_subtitle;

  /// No description provided for @diagnostics_tools_section.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get diagnostics_tools_section;

  /// No description provided for @diagnostics_traffic_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch live network throughput.'**
  String get diagnostics_traffic_subtitle;

  /// No description provided for @diagnostics_camera_probe_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect connected camera streams.'**
  String get diagnostics_camera_probe_subtitle;

  /// No description provided for @diagnostics_adb_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the on-device terminal.'**
  String get diagnostics_adb_subtitle;

  /// No description provided for @diagnostics_battery_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect cell SOH and pack stats.'**
  String get diagnostics_battery_subtitle;

  /// No description provided for @diagnostics_settings_subtitle.
  ///
  /// In en, this message translates to:
  /// **'App preferences, theme, and language.'**
  String get diagnostics_settings_subtitle;

  /// No description provided for @settings_action_reset_data.
  ///
  /// In en, this message translates to:
  /// **'Reset data…'**
  String get settings_action_reset_data;

  /// No description provided for @cd_brand_logo.
  ///
  /// In en, this message translates to:
  /// **'BladeWatch'**
  String get cd_brand_logo;

  /// No description provided for @dashboard_hero_headline.
  ///
  /// In en, this message translates to:
  /// **'On watch'**
  String get dashboard_hero_headline;

  /// No description provided for @dashboard_subtitle_all_systems.
  ///
  /// In en, this message translates to:
  /// **'All systems online'**
  String get dashboard_subtitle_all_systems;

  /// No description provided for @dashboard_subtitle_some_offline.
  ///
  /// In en, this message translates to:
  /// **'{arg1} of {arg2} services online'**
  String dashboard_subtitle_some_offline(Object arg1, Object arg2);

  /// No description provided for @dashboard_subtitle_no_tunnel.
  ///
  /// In en, this message translates to:
  /// **'Remote access offline'**
  String get dashboard_subtitle_no_tunnel;

  /// No description provided for @dashboard_metric_recordings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s recordings'**
  String get dashboard_metric_recordings;

  /// No description provided for @dashboard_metric_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get dashboard_metric_storage;

  /// No description provided for @dashboard_metric_tunnel.
  ///
  /// In en, this message translates to:
  /// **'Remote access'**
  String get dashboard_metric_tunnel;

  /// No description provided for @dashboard_metric_services.
  ///
  /// In en, this message translates to:
  /// **'Background services'**
  String get dashboard_metric_services;

  /// No description provided for @dashboard_metric_value_pending.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get dashboard_metric_value_pending;

  /// No description provided for @dashboard_metric_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get dashboard_metric_vehicle;

  /// No description provided for @dashboard_chip_recording_active.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get dashboard_chip_recording_active;

  /// No description provided for @dashboard_chip_recording_idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get dashboard_chip_recording_idle;

  /// No description provided for @dashboard_vehicle_tap_to_set.
  ///
  /// In en, this message translates to:
  /// **'Tap to set'**
  String get dashboard_vehicle_tap_to_set;

  /// No description provided for @dashboard_vehicle_summary.
  ///
  /// In en, this message translates to:
  /// **'{arg1} kWh · {arg2}'**
  String dashboard_vehicle_summary(Object arg1, Object arg2);

  /// No description provided for @vehicle_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Set battery capacity'**
  String get vehicle_dialog_title;

  /// No description provided for @vehicle_dialog_capacity_label.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get vehicle_dialog_capacity_label;

  /// No description provided for @vehicle_dialog_capacity_suffix.
  ///
  /// In en, this message translates to:
  /// **'kWh'**
  String get vehicle_dialog_capacity_suffix;

  /// No description provided for @vehicle_dialog_capacity_helper.
  ///
  /// In en, this message translates to:
  /// **'8 to 120 kWh. Leave to use the model default.'**
  String get vehicle_dialog_capacity_helper;

  /// No description provided for @vehicle_dialog_model_label.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicle_dialog_model_label;

  /// No description provided for @vehicle_dialog_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get vehicle_dialog_save;

  /// No description provided for @vehicle_dialog_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset to auto-detect'**
  String get vehicle_dialog_reset;

  /// No description provided for @vehicle_dialog_invalid_capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity must be 8 - 120 kWh'**
  String get vehicle_dialog_invalid_capacity;

  /// No description provided for @vehicle_dialog_summary_capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity: {arg1}'**
  String vehicle_dialog_summary_capacity(Object arg1);

  /// No description provided for @vehicle_dialog_summary_soh.
  ///
  /// In en, this message translates to:
  /// **'SOH: {arg1}'**
  String vehicle_dialog_summary_soh(Object arg1);

  /// No description provided for @vehicle_dialog_soh_source_live.
  ///
  /// In en, this message translates to:
  /// **'{arg1}% (live)'**
  String vehicle_dialog_soh_source_live(Object arg1);

  /// No description provided for @vehicle_dialog_soh_source_calibration.
  ///
  /// In en, this message translates to:
  /// **'{arg1}% (from last charge)'**
  String vehicle_dialog_soh_source_calibration(Object arg1);

  /// No description provided for @vehicle_dialog_soh_source_oem.
  ///
  /// In en, this message translates to:
  /// **'{arg1}% (vehicle)'**
  String vehicle_dialog_soh_source_oem(Object arg1);

  /// No description provided for @vehicle_dialog_soh_source_nominal.
  ///
  /// In en, this message translates to:
  /// **'{arg1}% (nominal)'**
  String vehicle_dialog_soh_source_nominal(Object arg1);

  /// No description provided for @settings_recording_tab_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settings_recording_tab_status;

  /// No description provided for @settings_recording_tab_capture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get settings_recording_tab_capture;

  /// No description provided for @settings_recording_tab_quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get settings_recording_tab_quality;

  /// No description provided for @settings_recording_tab_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settings_recording_tab_storage;

  /// No description provided for @settings_recording_status_title.
  ///
  /// In en, this message translates to:
  /// **'Recording Status'**
  String get settings_recording_status_title;

  /// No description provided for @settings_recording_status_current_state.
  ///
  /// In en, this message translates to:
  /// **'Current State'**
  String get settings_recording_status_current_state;

  /// No description provided for @settings_recording_status_today_count.
  ///
  /// In en, this message translates to:
  /// **'Recordings Today'**
  String get settings_recording_status_today_count;

  /// No description provided for @settings_recording_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Recording Mode (ACC ON)'**
  String get settings_recording_mode_title;

  /// No description provided for @settings_recording_mode_description.
  ///
  /// In en, this message translates to:
  /// **'Choose when dashcam recording should occur while driving.'**
  String get settings_recording_mode_description;

  /// No description provided for @settings_recording_mode_none_label.
  ///
  /// In en, this message translates to:
  /// **'None (Default)'**
  String get settings_recording_mode_none_label;

  /// No description provided for @settings_recording_mode_none_desc.
  ///
  /// In en, this message translates to:
  /// **'No recording — surveillance still works'**
  String get settings_recording_mode_none_desc;

  /// No description provided for @settings_recording_mode_continuous_label.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get settings_recording_mode_continuous_label;

  /// No description provided for @settings_recording_mode_continuous_desc.
  ///
  /// In en, this message translates to:
  /// **'Record all the time while driving'**
  String get settings_recording_mode_continuous_desc;

  /// No description provided for @settings_recording_mode_drive_label.
  ///
  /// In en, this message translates to:
  /// **'Drive Mode'**
  String get settings_recording_mode_drive_label;

  /// No description provided for @settings_recording_mode_drive_desc.
  ///
  /// In en, this message translates to:
  /// **'Record only when vehicle is moving'**
  String get settings_recording_mode_drive_desc;

  /// No description provided for @settings_recording_mode_proximity_label.
  ///
  /// In en, this message translates to:
  /// **'Proximity Guard'**
  String get settings_recording_mode_proximity_label;

  /// No description provided for @settings_recording_mode_proximity_desc.
  ///
  /// In en, this message translates to:
  /// **'Record when motion is detected'**
  String get settings_recording_mode_proximity_desc;

  /// No description provided for @settings_recording_limit_title.
  ///
  /// In en, this message translates to:
  /// **'Recording Limit'**
  String get settings_recording_limit_title;

  /// No description provided for @settings_recording_limit_description.
  ///
  /// In en, this message translates to:
  /// **'Maximum length per file. Recordings split into new files at this interval.'**
  String get settings_recording_limit_description;

  /// No description provided for @settings_recording_limit_minutes.
  ///
  /// In en, this message translates to:
  /// **'{arg1} min'**
  String settings_recording_limit_minutes(Object arg1);

  /// No description provided for @settings_recording_quality_title.
  ///
  /// In en, this message translates to:
  /// **'Recording Quality'**
  String get settings_recording_quality_title;

  /// No description provided for @settings_recording_storage_title.
  ///
  /// In en, this message translates to:
  /// **'Recording Storage'**
  String get settings_recording_storage_title;

  /// No description provided for @settings_recording_storage_location_label.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get settings_recording_storage_location_label;

  /// No description provided for @settings_recording_storage_internal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get settings_recording_storage_internal;

  /// No description provided for @settings_recording_storage_sd_card.
  ///
  /// In en, this message translates to:
  /// **'SD Card'**
  String get settings_recording_storage_sd_card;

  /// No description provided for @settings_recording_storage_sd_card_na.
  ///
  /// In en, this message translates to:
  /// **'SD Card (N/A)'**
  String get settings_recording_storage_sd_card_na;

  /// No description provided for @settings_recording_storage_limit_label.
  ///
  /// In en, this message translates to:
  /// **'Storage Limit — auto-deletes oldest when reached'**
  String get settings_recording_storage_limit_label;

  /// No description provided for @settings_recording_storage_usage_label.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get settings_recording_storage_usage_label;

  /// No description provided for @settings_recording_storage_files_label.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get settings_recording_storage_files_label;

  /// No description provided for @settings_recording_storage_usage.
  ///
  /// In en, this message translates to:
  /// **'{arg1} used / {arg2} limit'**
  String settings_recording_storage_usage(Object arg1, Object arg2);

  /// No description provided for @settings_recording_storage_files.
  ///
  /// In en, this message translates to:
  /// **'{arg1} recordings'**
  String settings_recording_storage_files(Object arg1);

  /// No description provided for @settings_recording_storage_path_label.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get settings_recording_storage_path_label;

  /// No description provided for @settings_recording_storage_sd_free_label.
  ///
  /// In en, this message translates to:
  /// **'SD Card Free'**
  String get settings_recording_storage_sd_free_label;

  /// No description provided for @settings_recording_storage_internal_free_label.
  ///
  /// In en, this message translates to:
  /// **'Internal Free'**
  String get settings_recording_storage_internal_free_label;

  /// No description provided for @settings_recording_format_title.
  ///
  /// In en, this message translates to:
  /// **'Format External Drive'**
  String get settings_recording_format_title;

  /// No description provided for @settings_recording_format_warning.
  ///
  /// In en, this message translates to:
  /// **'Permanently erases ALL data on the SD card or USB drive.'**
  String get settings_recording_format_warning;

  /// No description provided for @settings_recording_format_confirm.
  ///
  /// In en, this message translates to:
  /// **'Tap again — ALL data will be ERASED'**
  String get settings_recording_format_confirm;

  /// No description provided for @settings_recording_format_running.
  ///
  /// In en, this message translates to:
  /// **'Formatting… please wait'**
  String get settings_recording_format_running;

  /// No description provided for @settings_recording_format_button.
  ///
  /// In en, this message translates to:
  /// **'Format SD Card / USB'**
  String get settings_recording_format_button;

  /// No description provided for @settings_recording_format_no_drive.
  ///
  /// In en, this message translates to:
  /// **'No removable drive found'**
  String get settings_recording_format_no_drive;

  /// No description provided for @settings_recording_format_success.
  ///
  /// In en, this message translates to:
  /// **'Formatted successfully. New path: {arg1}'**
  String settings_recording_format_success(Object arg1);

  /// No description provided for @settings_recording_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Database Catalog'**
  String get settings_recording_sync_title;

  /// No description provided for @settings_recording_sync_description.
  ///
  /// In en, this message translates to:
  /// **'Reconcile the recordings index with files on disk.'**
  String get settings_recording_sync_description;

  /// No description provided for @settings_recording_sync_running.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get settings_recording_sync_running;

  /// No description provided for @settings_recording_sync_button.
  ///
  /// In en, this message translates to:
  /// **'Sync Database'**
  String get settings_recording_sync_button;

  /// No description provided for @settings_recording_sync_success.
  ///
  /// In en, this message translates to:
  /// **'Synced: +{arg1} -{arg2}'**
  String settings_recording_sync_success(Object arg1, Object arg2);

  /// No description provided for @settings_recording_sync_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Sync already in progress'**
  String get settings_recording_sync_in_progress;

  /// No description provided for @settings_recording_sync_failed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {arg1}'**
  String settings_recording_sync_failed(Object arg1);

  /// No description provided for @settings_recording_apply_button.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get settings_recording_apply_button;

  /// No description provided for @settings_recording_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get settings_recording_dismiss;

  /// No description provided for @settings_daemons_toggle_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Starting/stopping {arg1} isn’t supported yet'**
  String settings_daemons_toggle_unsupported(Object arg1);

  /// No description provided for @settings_daemons_zrok_configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get settings_daemons_zrok_configure;

  /// No description provided for @settings_daemons_zrok_reset_button.
  ///
  /// In en, this message translates to:
  /// **'Reset Environment'**
  String get settings_daemons_zrok_reset_button;

  /// No description provided for @vehicle_dialog_summary_effective.
  ///
  /// In en, this message translates to:
  /// **'Effective: {arg1} kWh'**
  String vehicle_dialog_summary_effective(Object arg1);

  /// No description provided for @vehicle_dialog_summary_model.
  ///
  /// In en, this message translates to:
  /// **'Model: {arg1}'**
  String vehicle_dialog_summary_model(Object arg1);

  /// No description provided for @vehicle_dialog_summary_calibration.
  ///
  /// In en, this message translates to:
  /// **'Last calibrated: {arg1}% on {arg2}'**
  String vehicle_dialog_summary_calibration(Object arg1, Object arg2);

  /// No description provided for @vehicle_dialog_soh_unavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get vehicle_dialog_soh_unavailable;

  /// No description provided for @dashboard_metric_storage_chip.
  ///
  /// In en, this message translates to:
  /// **'{arg1} used · {arg2} free'**
  String dashboard_metric_storage_chip(Object arg1, Object arg2);

  /// No description provided for @dashboard_metric_storage_chip_pending.
  ///
  /// In en, this message translates to:
  /// **'Storage —'**
  String get dashboard_metric_storage_chip_pending;

  /// No description provided for @dashboard_tunnel_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get dashboard_tunnel_offline;

  /// No description provided for @dashboard_tunnel_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get dashboard_tunnel_online;

  /// No description provided for @dashboard_tunnel_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get dashboard_tunnel_connecting;

  /// No description provided for @dashboard_trips_this_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get dashboard_trips_this_week;

  /// No description provided for @dashboard_trips_count.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{{arg1} trip} other{{arg1} trips}}'**
  String dashboard_trips_count(num arg1);

  /// No description provided for @dashboard_trips_distance_km.
  ///
  /// In en, this message translates to:
  /// **'{arg1} km'**
  String dashboard_trips_distance_km(Object arg1);

  /// No description provided for @dashboard_trips_distance_mi.
  ///
  /// In en, this message translates to:
  /// **'{arg1} mi'**
  String dashboard_trips_distance_mi(Object arg1);

  /// No description provided for @dashboard_trips_duration.
  ///
  /// In en, this message translates to:
  /// **'{arg1}'**
  String dashboard_trips_duration(Object arg1);

  /// No description provided for @dashboard_trips_label_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get dashboard_trips_label_trips;

  /// No description provided for @dashboard_trips_label_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get dashboard_trips_label_distance;

  /// No description provided for @dashboard_trips_label_time.
  ///
  /// In en, this message translates to:
  /// **'Drive Time'**
  String get dashboard_trips_label_time;

  /// No description provided for @dashboard_trips_no_data.
  ///
  /// In en, this message translates to:
  /// **'No trips recorded this week'**
  String get dashboard_trips_no_data;

  /// No description provided for @dashboard_trips_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Start driving to see stats'**
  String get dashboard_trips_unavailable;

  /// No description provided for @dashboard_trips_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get dashboard_trips_loading;

  /// No description provided for @dashboard_trips_view_all.
  ///
  /// In en, this message translates to:
  /// **'View all trips'**
  String get dashboard_trips_view_all;

  /// No description provided for @dashboard_action_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get dashboard_action_live;

  /// No description provided for @dashboard_action_live_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Open camera view'**
  String get dashboard_action_live_subtitle;

  /// No description provided for @dashboard_action_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get dashboard_action_recordings;

  /// No description provided for @dashboard_action_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboard_action_settings;

  /// No description provided for @dashboard_action_settings_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences and about'**
  String get dashboard_action_settings_subtitle;

  /// No description provided for @settings_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_hero_title;

  /// No description provided for @settings_hero_overline.
  ///
  /// In en, this message translates to:
  /// **'BLADEWATCH'**
  String get settings_hero_overline;

  /// No description provided for @settings_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune appearance, recording, surveillance, and on-device data.'**
  String get settings_hero_subtitle;

  /// No description provided for @settings_overline_preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get settings_overline_preferences;

  /// No description provided for @settings_overline_about_data.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get settings_overline_about_data;

  /// No description provided for @settings_quick_theme_label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_quick_theme_label;

  /// No description provided for @settings_quick_language_label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_quick_language_label;

  /// No description provided for @settings_section_recording_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pre/post buffers, codec, storage limits.'**
  String get settings_section_recording_subtitle;

  /// No description provided for @settings_section_surveillance_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule, motion sensitivity, object detection.'**
  String get settings_section_surveillance_subtitle;

  /// No description provided for @settings_section_daemons_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Zrok tunnel and background services.'**
  String get settings_section_daemons_subtitle;

  /// No description provided for @settings_about_row_title.
  ///
  /// In en, this message translates to:
  /// **'About BladeWatch'**
  String get settings_about_row_title;

  /// No description provided for @settings_about_row_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, license, support development.'**
  String get settings_about_row_subtitle;

  /// No description provided for @settings_reset_row_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear recordings, events, or all caches.'**
  String get settings_reset_row_subtitle;

  /// No description provided for @settings_footer_format.
  ///
  /// In en, this message translates to:
  /// **'BladeWatch {arg1} · {arg2}'**
  String settings_footer_format(Object arg1, Object arg2);

  /// No description provided for @settings_appearance_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, and visual preferences.'**
  String get settings_appearance_subtitle;

  /// No description provided for @settings_theme_active_auto_caption.
  ///
  /// In en, this message translates to:
  /// **'Auto follows your system theme.'**
  String get settings_theme_active_auto_caption;

  /// No description provided for @settings_theme_active_light_caption.
  ///
  /// In en, this message translates to:
  /// **'Light theme is always on.'**
  String get settings_theme_active_light_caption;

  /// No description provided for @settings_theme_active_dark_caption.
  ///
  /// In en, this message translates to:
  /// **'Dark theme is always on.'**
  String get settings_theme_active_dark_caption;

  /// No description provided for @settings_language_count_format.
  ///
  /// In en, this message translates to:
  /// **'{arg1} of {arg2} languages available'**
  String settings_language_count_format(Object arg1, Object arg2);

  /// No description provided for @settings_language_card_title.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get settings_language_card_title;

  /// No description provided for @settings_privacy_stance_title.
  ///
  /// In en, this message translates to:
  /// **'On-device by default'**
  String get settings_privacy_stance_title;

  /// No description provided for @settings_privacy_stance_body.
  ///
  /// In en, this message translates to:
  /// **'BladeWatch runs entirely on the head unit. No telemetry leaves your car except via the tunnels and integrations you explicitly configure.'**
  String get settings_privacy_stance_body;

  /// No description provided for @settings_privacy_overline_storage.
  ///
  /// In en, this message translates to:
  /// **'LOCAL STORAGE'**
  String get settings_privacy_overline_storage;

  /// No description provided for @settings_privacy_overline_reset.
  ///
  /// In en, this message translates to:
  /// **'DATA RESET'**
  String get settings_privacy_overline_reset;

  /// No description provided for @settings_privacy_storage_clips_label.
  ///
  /// In en, this message translates to:
  /// **'Clips on disk'**
  String get settings_privacy_storage_clips_label;

  /// No description provided for @settings_privacy_storage_size_label.
  ///
  /// In en, this message translates to:
  /// **'Total size'**
  String get settings_privacy_storage_size_label;

  /// No description provided for @settings_privacy_storage_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get settings_privacy_storage_unavailable;

  /// No description provided for @settings_privacy_storage_count_format.
  ///
  /// In en, this message translates to:
  /// **'{arg1} clip'**
  String settings_privacy_storage_count_format(Object arg1);

  /// No description provided for @settings_privacy_storage_count_format_plural.
  ///
  /// In en, this message translates to:
  /// **'{arg1} clips'**
  String settings_privacy_storage_count_format_plural(Object arg1);

  /// No description provided for @settings_privacy_reset_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose categories: recordings, events, service configs, cached telemetry…'**
  String get settings_privacy_reset_subtitle;

  /// No description provided for @settings_developer_overline.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get settings_developer_overline;

  /// No description provided for @settings_developer_timing_logs_title.
  ///
  /// In en, this message translates to:
  /// **'Service timing logs'**
  String get settings_developer_timing_logs_title;

  /// No description provided for @settings_developer_timing_logs_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Log elapsed-time markers during service startup. Disable in normal use to keep logcat clean.'**
  String get settings_developer_timing_logs_subtitle;

  /// No description provided for @settings_developer_debug_logs_title.
  ///
  /// In en, this message translates to:
  /// **'Developer debug logs'**
  String get settings_developer_debug_logs_title;

  /// No description provided for @settings_developer_debug_logs_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Log all Activity and Fragment lifecycle events and startup steps to /storage/emulated/0/BladeWatch/data/debug_app.log. Crashes are always captured. Off by default.'**
  String get settings_developer_debug_logs_subtitle;

  /// No description provided for @diagnostics_camera_value_camera_n.
  ///
  /// In en, this message translates to:
  /// **'Camera {arg1}'**
  String diagnostics_camera_value_camera_n(Object arg1);

  /// No description provided for @diagnostics_camera_value_camera_n_manual.
  ///
  /// In en, this message translates to:
  /// **'Camera {arg1} (manual)'**
  String diagnostics_camera_value_camera_n_manual(Object arg1);

  /// No description provided for @diagnostics_camera_value_probing.
  ///
  /// In en, this message translates to:
  /// **'Probing…'**
  String get diagnostics_camera_value_probing;

  /// No description provided for @diagnostics_camera_value_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get diagnostics_camera_value_offline;

  /// No description provided for @diagnostics_battery_value_soh.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String diagnostics_battery_value_soh(Object arg1);

  /// No description provided for @diagnostics_battery_value_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending data'**
  String get diagnostics_battery_value_pending;

  /// No description provided for @diagnostics_battery_value_charge.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String diagnostics_battery_value_charge(Object arg1);

  /// No description provided for @dashboard_recordings_value_live.
  ///
  /// In en, this message translates to:
  /// **'● {arg1}'**
  String dashboard_recordings_value_live(Object arg1);

  /// No description provided for @dashboard_insight_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome — BladeWatch is now your second pair of eyes.'**
  String get dashboard_insight_welcome;

  /// No description provided for @dashboard_insight_parked_charged_kwh.
  ///
  /// In en, this message translates to:
  /// **'Picked up {arg1} (≈{arg2}) while parked'**
  String dashboard_insight_parked_charged_kwh(Object arg1, Object arg2);

  /// No description provided for @dashboard_insight_parked_charged.
  ///
  /// In en, this message translates to:
  /// **'Picked up {arg1} while parked'**
  String dashboard_insight_parked_charged(Object arg1);

  /// No description provided for @dashboard_insight_parked_drained_kwh.
  ///
  /// In en, this message translates to:
  /// **'Used {arg1} (≈{arg2}) since you parked'**
  String dashboard_insight_parked_drained_kwh(Object arg1, Object arg2);

  /// No description provided for @dashboard_insight_parked_drained.
  ///
  /// In en, this message translates to:
  /// **'Used {arg1} since you parked'**
  String dashboard_insight_parked_drained(Object arg1);

  /// No description provided for @dashboard_insight_last_alert.
  ///
  /// In en, this message translates to:
  /// **'Last surveillance alert: {arg1}'**
  String dashboard_insight_last_alert(Object arg1);

  /// No description provided for @dashboard_insight_last_charge.
  ///
  /// In en, this message translates to:
  /// **'Last charge: +{arg1} in {arg2}'**
  String dashboard_insight_last_charge(Object arg1, Object arg2);

  /// No description provided for @dashboard_insight_storage_milestone.
  ///
  /// In en, this message translates to:
  /// **'{arg1} clips · {arg2} recorded'**
  String dashboard_insight_storage_milestone(Object arg1, Object arg2);

  /// No description provided for @dashboard_insight_kwh_format.
  ///
  /// In en, this message translates to:
  /// **'{arg1} kWh'**
  String dashboard_insight_kwh_format(Object arg1);

  /// No description provided for @dashboard_insight_percent_format.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String dashboard_insight_percent_format(Object arg1);

  /// No description provided for @dashboard_insight_hours_minutes.
  ///
  /// In en, this message translates to:
  /// **'{arg1} hr {arg2} min'**
  String dashboard_insight_hours_minutes(Object arg1, Object arg2);

  /// No description provided for @dashboard_insight_today_clips.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{{arg1} clip recorded today} other{{arg1} clips recorded today}}'**
  String dashboard_insight_today_clips(num arg1);

  /// No description provided for @dashboard_insight_uptime_days_hours.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{BladeWatch online for {arg1} day, {arg2} hr} other{BladeWatch online for {arg1} days, {arg2} hr}}'**
  String dashboard_insight_uptime_days_hours(num arg1, Object arg2);

  /// No description provided for @dashboard_insight_uptime_hours.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{BladeWatch online for {arg1} hour} other{BladeWatch online for {arg1} hours}}'**
  String dashboard_insight_uptime_hours(num arg1);

  /// No description provided for @dashboard_insight_minutes.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{{arg1} min} other{{arg1} min}}'**
  String dashboard_insight_minutes(num arg1);

  /// No description provided for @dashboard_insight_hours.
  ///
  /// In en, this message translates to:
  /// **'{arg1, plural, one{{arg1} hr} other{{arg1} hr}}'**
  String dashboard_insight_hours(num arg1);

  /// No description provided for @vehicle_tab_trunk.
  ///
  /// In en, this message translates to:
  /// **'Trunk'**
  String get vehicle_tab_trunk;

  /// No description provided for @vehicle_tab_climate.
  ///
  /// In en, this message translates to:
  /// **'Climate'**
  String get vehicle_tab_climate;

  /// No description provided for @vehicle_tab_seats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get vehicle_tab_seats;

  /// No description provided for @vehicle_tab_windows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get vehicle_tab_windows;

  /// No description provided for @vehicle_tab_lights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get vehicle_tab_lights;

  /// No description provided for @vehicle_tab_adas.
  ///
  /// In en, this message translates to:
  /// **'ADAS'**
  String get vehicle_tab_adas;

  /// No description provided for @vehicle_control_charging_tab.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get vehicle_control_charging_tab;

  /// No description provided for @vehicle_locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get vehicle_locked;

  /// No description provided for @vehicle_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get vehicle_unlocked;

  /// No description provided for @vehicle_range_label.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get vehicle_range_label;

  /// No description provided for @vehicle_data_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Vehicle data unavailable.'**
  String get vehicle_data_unavailable;

  /// No description provided for @vehicle_action_failed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Check vehicle connection.'**
  String get vehicle_action_failed;

  /// No description provided for @vehicle_open_trunk.
  ///
  /// In en, this message translates to:
  /// **'Open Trunk'**
  String get vehicle_open_trunk;

  /// No description provided for @vehicle_close_trunk.
  ///
  /// In en, this message translates to:
  /// **'Close Trunk'**
  String get vehicle_close_trunk;

  /// No description provided for @vehicle_trunk_info_open.
  ///
  /// In en, this message translates to:
  /// **'Opening the trunk will unlock the car first.'**
  String get vehicle_trunk_info_open;

  /// No description provided for @vehicle_ac_on.
  ///
  /// In en, this message translates to:
  /// **'AC On'**
  String get vehicle_ac_on;

  /// No description provided for @vehicle_ac_off.
  ///
  /// In en, this message translates to:
  /// **'AC Off'**
  String get vehicle_ac_off;

  /// No description provided for @vehicle_max_cooling_on.
  ///
  /// In en, this message translates to:
  /// **'Max Cooling: ON'**
  String get vehicle_max_cooling_on;

  /// No description provided for @vehicle_max_cooling_off.
  ///
  /// In en, this message translates to:
  /// **'Max Cooling: OFF'**
  String get vehicle_max_cooling_off;

  /// No description provided for @vehicle_temp_label.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get vehicle_temp_label;

  /// No description provided for @vehicle_fan_speed_label.
  ///
  /// In en, this message translates to:
  /// **'Fan Speed'**
  String get vehicle_fan_speed_label;

  /// No description provided for @vehicle_fan_level.
  ///
  /// In en, this message translates to:
  /// **'Level {arg1}'**
  String vehicle_fan_level(Object arg1);

  /// No description provided for @vehicle_inside_temp_fmt.
  ///
  /// In en, this message translates to:
  /// **'Inside: {arg1}°C'**
  String vehicle_inside_temp_fmt(Object arg1);

  /// No description provided for @vehicle_seat_driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get vehicle_seat_driver;

  /// No description provided for @vehicle_seat_passenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get vehicle_seat_passenger;

  /// No description provided for @vehicle_seat_no_controls.
  ///
  /// In en, this message translates to:
  /// **'No seat controls available for this vehicle.'**
  String get vehicle_seat_no_controls;

  /// No description provided for @vehicle_seat_heat_label.
  ///
  /// In en, this message translates to:
  /// **'Heat {arg1}'**
  String vehicle_seat_heat_label(Object arg1);

  /// No description provided for @vehicle_seat_cool_label.
  ///
  /// In en, this message translates to:
  /// **'Cool {arg1}'**
  String vehicle_seat_cool_label(Object arg1);

  /// No description provided for @vehicle_heat_off.
  ///
  /// In en, this message translates to:
  /// **'(Off)'**
  String get vehicle_heat_off;

  /// No description provided for @vehicle_heat_low.
  ///
  /// In en, this message translates to:
  /// **'(Low)'**
  String get vehicle_heat_low;

  /// No description provided for @vehicle_heat_high.
  ///
  /// In en, this message translates to:
  /// **'(High)'**
  String get vehicle_heat_high;

  /// No description provided for @vehicle_seat_pos_1.
  ///
  /// In en, this message translates to:
  /// **'Pos 1'**
  String get vehicle_seat_pos_1;

  /// No description provided for @vehicle_seat_pos_2.
  ///
  /// In en, this message translates to:
  /// **'Pos 2'**
  String get vehicle_seat_pos_2;

  /// No description provided for @vehicle_all_windows.
  ///
  /// In en, this message translates to:
  /// **'All Windows'**
  String get vehicle_all_windows;

  /// No description provided for @vehicle_window_front_left.
  ///
  /// In en, this message translates to:
  /// **'Front Left'**
  String get vehicle_window_front_left;

  /// No description provided for @vehicle_window_front_right.
  ///
  /// In en, this message translates to:
  /// **'Front Right'**
  String get vehicle_window_front_right;

  /// No description provided for @vehicle_window_rear_left.
  ///
  /// In en, this message translates to:
  /// **'Rear Left'**
  String get vehicle_window_rear_left;

  /// No description provided for @vehicle_window_rear_right.
  ///
  /// In en, this message translates to:
  /// **'Rear Right'**
  String get vehicle_window_rear_right;

  /// No description provided for @vehicle_window_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get vehicle_window_close;

  /// No description provided for @vehicle_window_close_vent.
  ///
  /// In en, this message translates to:
  /// **'Close Vent'**
  String get vehicle_window_close_vent;

  /// No description provided for @vehicle_window_vent_12.
  ///
  /// In en, this message translates to:
  /// **'Vent 12%'**
  String get vehicle_window_vent_12;

  /// No description provided for @vehicle_window_open_all.
  ///
  /// In en, this message translates to:
  /// **'Open All'**
  String get vehicle_window_open_all;

  /// No description provided for @vehicle_sunroof.
  ///
  /// In en, this message translates to:
  /// **'Sunroof'**
  String get vehicle_sunroof;

  /// No description provided for @vehicle_sunshade.
  ///
  /// In en, this message translates to:
  /// **'Sunshade'**
  String get vehicle_sunshade;

  /// No description provided for @vehicle_btn_drl_title.
  ///
  /// In en, this message translates to:
  /// **'Daytime running lights'**
  String get vehicle_btn_drl_title;

  /// No description provided for @vehicle_btn_slw_title.
  ///
  /// In en, this message translates to:
  /// **'Speed limit warning'**
  String get vehicle_btn_slw_title;

  /// No description provided for @vehicle_control_section_charge_cap.
  ///
  /// In en, this message translates to:
  /// **'Charge limit'**
  String get vehicle_control_section_charge_cap;

  /// No description provided for @vehicle_charge_cap_not_supported.
  ///
  /// In en, this message translates to:
  /// **'Charge cap is not supported by this vehicle.'**
  String get vehicle_charge_cap_not_supported;

  /// No description provided for @vehicle_charge_limit_label.
  ///
  /// In en, this message translates to:
  /// **'Charge Limit'**
  String get vehicle_charge_limit_label;

  /// No description provided for @vehicle_enable_charge_limit.
  ///
  /// In en, this message translates to:
  /// **'Enable Charge Limit'**
  String get vehicle_enable_charge_limit;

  /// No description provided for @vehicle_charge_limit_range.
  ///
  /// In en, this message translates to:
  /// **'Minimum 50%, maximum 100%'**
  String get vehicle_charge_limit_range;

  /// No description provided for @vehicle_tyre_no_signal.
  ///
  /// In en, this message translates to:
  /// **'NO SIGNAL'**
  String get vehicle_tyre_no_signal;

  /// No description provided for @vehicle_tyre_slow_leak.
  ///
  /// In en, this message translates to:
  /// **'SLOW LEAK'**
  String get vehicle_tyre_slow_leak;

  /// No description provided for @vehicle_tyre_fast_leak.
  ///
  /// In en, this message translates to:
  /// **'FAST LEAK'**
  String get vehicle_tyre_fast_leak;

  /// No description provided for @vehicle_tyre_low.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get vehicle_tyre_low;

  /// No description provided for @vehicle_tyre_high.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get vehicle_tyre_high;

  /// No description provided for @vehicle_tyre_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get vehicle_tyre_ok;

  /// No description provided for @vehicle_tyre_check_pressure.
  ///
  /// In en, this message translates to:
  /// **'Check pressure'**
  String get vehicle_tyre_check_pressure;

  /// No description provided for @vehicle_toggle_on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get vehicle_toggle_on;

  /// No description provided for @vehicle_toggle_off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get vehicle_toggle_off;

  /// No description provided for @vehicle_err_climate_control.
  ///
  /// In en, this message translates to:
  /// **'Climate control failed.'**
  String get vehicle_err_climate_control;

  /// No description provided for @vehicle_err_max_cooling.
  ///
  /// In en, this message translates to:
  /// **'Max cooling failed.'**
  String get vehicle_err_max_cooling;

  /// No description provided for @vehicle_err_drl_control.
  ///
  /// In en, this message translates to:
  /// **'DRL control failed.'**
  String get vehicle_err_drl_control;

  /// No description provided for @vehicle_err_slw_control.
  ///
  /// In en, this message translates to:
  /// **'ADAS control failed.'**
  String get vehicle_err_slw_control;

  /// No description provided for @vehicle_err_charge_limit_toggle.
  ///
  /// In en, this message translates to:
  /// **'Charge limit toggle failed.'**
  String get vehicle_err_charge_limit_toggle;

  /// No description provided for @vehicle_a11y_decrease_fmt.
  ///
  /// In en, this message translates to:
  /// **'Decrease {arg1}'**
  String vehicle_a11y_decrease_fmt(Object arg1);

  /// No description provided for @vehicle_a11y_increase_fmt.
  ///
  /// In en, this message translates to:
  /// **'Increase {arg1}'**
  String vehicle_a11y_increase_fmt(Object arg1);

  /// No description provided for @vehicle_stale_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get vehicle_stale_connecting;

  /// No description provided for @vehicle_appearance_model_title.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get vehicle_appearance_model_title;

  /// No description provided for @vehicle_appearance_custom_color.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get vehicle_appearance_custom_color;

  /// No description provided for @vehicle_status_charge_fmt.
  ///
  /// In en, this message translates to:
  /// **'Charge: {arg1}%'**
  String vehicle_status_charge_fmt(Object arg1);

  /// No description provided for @vehicle_status_range_fmt.
  ///
  /// In en, this message translates to:
  /// **'Range: {arg1} km'**
  String vehicle_status_range_fmt(Object arg1);

  /// No description provided for @vehicle_status_charge_unknown.
  ///
  /// In en, this message translates to:
  /// **'Charge: —'**
  String get vehicle_status_charge_unknown;

  /// No description provided for @vehicle_status_range_unknown.
  ///
  /// In en, this message translates to:
  /// **'Range: —'**
  String get vehicle_status_range_unknown;

  /// No description provided for @startup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Getting your dashcam ready'**
  String get startup_subtitle;

  /// No description provided for @startup_header_preparing.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready…'**
  String get startup_header_preparing;

  /// No description provided for @startup_header_starting.
  ///
  /// In en, this message translates to:
  /// **'Starting up…'**
  String get startup_header_starting;

  /// No description provided for @startup_header_verifying.
  ///
  /// In en, this message translates to:
  /// **'Almost ready…'**
  String get startup_header_verifying;

  /// No description provided for @startup_header_ready.
  ///
  /// In en, this message translates to:
  /// **'Everything\'s ready'**
  String get startup_header_ready;

  /// No description provided for @startup_daemon_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get startup_daemon_camera;

  /// No description provided for @startup_daemon_camera_desc.
  ///
  /// In en, this message translates to:
  /// **'Live view & recording'**
  String get startup_daemon_camera_desc;

  /// No description provided for @startup_daemon_sentry.
  ///
  /// In en, this message translates to:
  /// **'Sentry Mode'**
  String get startup_daemon_sentry;

  /// No description provided for @startup_daemon_sentry_desc.
  ///
  /// In en, this message translates to:
  /// **'Motion detection & alerts'**
  String get startup_daemon_sentry_desc;

  /// No description provided for @startup_daemon_parking.
  ///
  /// In en, this message translates to:
  /// **'Parking Guard'**
  String get startup_daemon_parking;

  /// No description provided for @startup_daemon_parking_desc.
  ///
  /// In en, this message translates to:
  /// **'Keeps watch while parked'**
  String get startup_daemon_parking_desc;

  /// No description provided for @startup_status_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get startup_status_waiting;

  /// No description provided for @startup_status_starting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get startup_status_starting;

  /// No description provided for @startup_status_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get startup_status_ready;

  /// No description provided for @startup_status_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get startup_status_failed;

  /// No description provided for @startup_continue_anyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get startup_continue_anyway;

  /// No description provided for @startup_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get startup_continue;

  /// No description provided for @live_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get live_retry;

  /// No description provided for @live_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to camera…'**
  String get live_connecting;

  /// No description provided for @live_error_fmt.
  ///
  /// In en, this message translates to:
  /// **'Error: {arg1}'**
  String live_error_fmt(Object arg1);

  /// No description provided for @live_camera_unavailable_fmt.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable\n{arg1}'**
  String live_camera_unavailable_fmt(Object arg1);

  /// No description provided for @live_direction_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get live_direction_all;

  /// No description provided for @live_direction_front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get live_direction_front;

  /// No description provided for @live_direction_right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get live_direction_right;

  /// No description provided for @live_direction_rear.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get live_direction_rear;

  /// No description provided for @live_direction_left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get live_direction_left;

  /// No description provided for @trip_no_route_data.
  ///
  /// In en, this message translates to:
  /// **'No route data for this trip'**
  String get trip_no_route_data;

  /// No description provided for @trips_tab_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips_tab_trips;

  /// No description provided for @trips_tab_stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get trips_tab_stats;

  /// No description provided for @trips_tab_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get trips_tab_storage;

  /// No description provided for @trips_filter_7_days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get trips_filter_7_days;

  /// No description provided for @trips_filter_14_days.
  ///
  /// In en, this message translates to:
  /// **'14 Days'**
  String get trips_filter_14_days;

  /// No description provided for @trips_filter_30_days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get trips_filter_30_days;

  /// No description provided for @trips_load_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String trips_load_error(Object message);

  /// No description provided for @trips_empty_state.
  ///
  /// In en, this message translates to:
  /// **'No trips recorded yet'**
  String get trips_empty_state;

  /// No description provided for @trips_period_summary_title.
  ///
  /// In en, this message translates to:
  /// **'Period Summary'**
  String get trips_period_summary_title;

  /// No description provided for @trips_stat_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips_stat_trips;

  /// No description provided for @trips_stat_hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get trips_stat_hours;

  /// No description provided for @trips_stat_efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get trips_stat_efficiency;

  /// No description provided for @trips_stat_kwh.
  ///
  /// In en, this message translates to:
  /// **'kWh'**
  String get trips_stat_kwh;

  /// No description provided for @trips_stat_kwh_per_100km.
  ///
  /// In en, this message translates to:
  /// **'kWh/100km'**
  String get trips_stat_kwh_per_100km;

  /// No description provided for @trips_score_label.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String trips_score_label(Object score);

  /// No description provided for @trips_driver_score_title.
  ///
  /// In en, this message translates to:
  /// **'Driver Score'**
  String get trips_driver_score_title;

  /// No description provided for @trips_driver_score_overall.
  ///
  /// In en, this message translates to:
  /// **'Overall: {score} / 100'**
  String trips_driver_score_overall(Object score);

  /// No description provided for @trips_range_title.
  ///
  /// In en, this message translates to:
  /// **'Personalized Range'**
  String get trips_range_title;

  /// No description provided for @trips_range_byd_estimate.
  ///
  /// In en, this message translates to:
  /// **'BYD estimate: {km} km'**
  String trips_range_byd_estimate(Object km);

  /// No description provided for @trips_range_no_data.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get trips_range_no_data;

  /// No description provided for @trips_dna_title.
  ///
  /// In en, this message translates to:
  /// **'Driving DNA'**
  String get trips_dna_title;

  /// No description provided for @trips_dna_anticipation.
  ///
  /// In en, this message translates to:
  /// **'Anticipation'**
  String get trips_dna_anticipation;

  /// No description provided for @trips_dna_smoothness.
  ///
  /// In en, this message translates to:
  /// **'Smoothness'**
  String get trips_dna_smoothness;

  /// No description provided for @trips_dna_speed_discipline.
  ///
  /// In en, this message translates to:
  /// **'Speed Discipline'**
  String get trips_dna_speed_discipline;

  /// No description provided for @trips_dna_efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get trips_dna_efficiency;

  /// No description provided for @trips_dna_consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get trips_dna_consistency;

  /// No description provided for @trips_storage_title.
  ///
  /// In en, this message translates to:
  /// **'Trip Storage'**
  String get trips_storage_title;

  /// No description provided for @trips_storage_analytics_label.
  ///
  /// In en, this message translates to:
  /// **'Trip Analytics'**
  String get trips_storage_analytics_label;

  /// No description provided for @trips_storage_rate_label.
  ///
  /// In en, this message translates to:
  /// **'Electricity Rate'**
  String get trips_storage_rate_label;

  /// No description provided for @trips_storage_distance_unit_label.
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get trips_storage_distance_unit_label;

  /// No description provided for @trips_storage_location_label.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get trips_storage_location_label;

  /// No description provided for @trips_storage_internal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get trips_storage_internal;

  /// No description provided for @trips_storage_sd_card.
  ///
  /// In en, this message translates to:
  /// **'SD Card'**
  String get trips_storage_sd_card;

  /// No description provided for @trips_storage_sd_card_unavailable.
  ///
  /// In en, this message translates to:
  /// **'SD Card (N/A)'**
  String get trips_storage_sd_card_unavailable;

  /// No description provided for @trips_storage_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get trips_storage_apply;

  /// No description provided for @trips_storage_usage_line.
  ///
  /// In en, this message translates to:
  /// **'{used} {unit} used / {limit} MB limit · {count} trips'**
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  );

  /// No description provided for @trips_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Database Catalog'**
  String get trips_sync_title;

  /// No description provided for @trips_sync_description.
  ///
  /// In en, this message translates to:
  /// **'Reconcile the trips index with telemetry files on disk.'**
  String get trips_sync_description;

  /// No description provided for @trips_sync_button.
  ///
  /// In en, this message translates to:
  /// **'Sync Database'**
  String get trips_sync_button;

  /// No description provided for @trips_sync_running.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get trips_sync_running;

  /// No description provided for @trips_sync_success.
  ///
  /// In en, this message translates to:
  /// **'Synced successfully: +{added} -{removed} ({total} total)'**
  String trips_sync_success(Object added, Object removed, Object total);

  /// No description provided for @trips_sync_failed_generic.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get trips_sync_failed_generic;

  /// No description provided for @trips_detail_summary_title.
  ///
  /// In en, this message translates to:
  /// **'Trip Summary'**
  String get trips_detail_summary_title;

  /// No description provided for @trips_detail_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get trips_detail_distance;

  /// No description provided for @trips_detail_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trips_detail_duration;

  /// No description provided for @trips_detail_energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get trips_detail_energy;

  /// No description provided for @trips_detail_avg_speed.
  ///
  /// In en, this message translates to:
  /// **'Avg Speed'**
  String get trips_detail_avg_speed;

  /// No description provided for @trips_detail_max_speed.
  ///
  /// In en, this message translates to:
  /// **'Max Speed'**
  String get trips_detail_max_speed;

  /// No description provided for @trips_detail_soc.
  ///
  /// In en, this message translates to:
  /// **'SoC'**
  String get trips_detail_soc;

  /// No description provided for @trips_detail_cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get trips_detail_cost;

  /// No description provided for @trips_detail_ext_temp.
  ///
  /// In en, this message translates to:
  /// **'Ext Temp'**
  String get trips_detail_ext_temp;

  /// No description provided for @trips_detail_elev_gain.
  ///
  /// In en, this message translates to:
  /// **'Elev Gain'**
  String get trips_detail_elev_gain;

  /// No description provided for @trips_detail_scores_title.
  ///
  /// In en, this message translates to:
  /// **'Driving Scores'**
  String get trips_detail_scores_title;

  /// No description provided for @trips_detail_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Trip details unavailable'**
  String get trips_detail_unavailable;

  /// No description provided for @trips_detail_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading trip…'**
  String get trips_detail_loading;

  /// No description provided for @trips_detail_route_points.
  ///
  /// In en, this message translates to:
  /// **'{count} GPS points recorded'**
  String trips_detail_route_points(Object count);

  /// No description provided for @rec_severity_critical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get rec_severity_critical;

  /// No description provided for @rec_severity_alert.
  ///
  /// In en, this message translates to:
  /// **'ALERT'**
  String get rec_severity_alert;

  /// No description provided for @location_loading_title.
  ///
  /// In en, this message translates to:
  /// **'Loading map'**
  String get location_loading_title;

  /// No description provided for @location_permission_missing_title.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get location_permission_missing_title;

  /// No description provided for @location_permission_denied_title.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get location_permission_denied_title;

  /// No description provided for @location_provider_disabled_title.
  ///
  /// In en, this message translates to:
  /// **'GPS disabled'**
  String get location_provider_disabled_title;

  /// No description provided for @location_waiting_for_fix_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS fix'**
  String get location_waiting_for_fix_title;

  /// No description provided for @location_car_location_title.
  ///
  /// In en, this message translates to:
  /// **'Car location'**
  String get location_car_location_title;

  /// No description provided for @location_stale_title.
  ///
  /// In en, this message translates to:
  /// **'Location stale'**
  String get location_stale_title;

  /// No description provided for @location_tile_failure_title.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable'**
  String get location_tile_failure_title;

  /// No description provided for @location_tile_failure_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable'**
  String get location_tile_failure_subtitle;

  /// No description provided for @location_error_title.
  ///
  /// In en, this message translates to:
  /// **'Location error'**
  String get location_error_title;

  /// No description provided for @location_action_grant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get location_action_grant;

  /// No description provided for @location_action_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get location_action_retry;

  /// No description provided for @location_mode_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get location_mode_auto;

  /// No description provided for @location_mode_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get location_mode_light;

  /// No description provided for @location_mode_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get location_mode_dark;

  /// No description provided for @cd_recenter_on_car.
  ///
  /// In en, this message translates to:
  /// **'Recenter on car'**
  String get cd_recenter_on_car;

  /// No description provided for @recording_lib_no_recordings_normal.
  ///
  /// In en, this message translates to:
  /// **'No normal recordings'**
  String get recording_lib_no_recordings_normal;

  /// No description provided for @recording_lib_no_recordings_sentry.
  ///
  /// In en, this message translates to:
  /// **'No sentry events'**
  String get recording_lib_no_recordings_sentry;

  /// No description provided for @recording_lib_no_recordings_proximity.
  ///
  /// In en, this message translates to:
  /// **'No proximity events'**
  String get recording_lib_no_recordings_proximity;

  /// No description provided for @recording_lib_camera_badge.
  ///
  /// In en, this message translates to:
  /// **'C{arg1}'**
  String recording_lib_camera_badge(Object arg1);

  /// No description provided for @video_player_legend_person.
  ///
  /// In en, this message translates to:
  /// **'person'**
  String get video_player_legend_person;

  /// No description provided for @video_player_legend_car.
  ///
  /// In en, this message translates to:
  /// **'car'**
  String get video_player_legend_car;

  /// No description provided for @video_player_legend_bike.
  ///
  /// In en, this message translates to:
  /// **'bike'**
  String get video_player_legend_bike;

  /// No description provided for @video_player_legend_motion.
  ///
  /// In en, this message translates to:
  /// **'motion'**
  String get video_player_legend_motion;

  /// No description provided for @recording_lib_proximity_very_close.
  ///
  /// In en, this message translates to:
  /// **'very close'**
  String get recording_lib_proximity_very_close;

  /// No description provided for @recording_lib_proximity_close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get recording_lib_proximity_close;

  /// No description provided for @recording_lib_proximity_mid.
  ///
  /// In en, this message translates to:
  /// **'mid'**
  String get recording_lib_proximity_mid;

  /// No description provided for @recording_lib_proximity_far.
  ///
  /// In en, this message translates to:
  /// **'far'**
  String get recording_lib_proximity_far;

  /// No description provided for @surveillance_tab_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get surveillance_tab_general;

  /// No description provided for @surveillance_tab_detection.
  ///
  /// In en, this message translates to:
  /// **'Detection'**
  String get surveillance_tab_detection;

  /// No description provided for @surveillance_tab_recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get surveillance_tab_recording;

  /// No description provided for @surveillance_tab_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get surveillance_tab_storage;

  /// No description provided for @surveillance_tab_advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get surveillance_tab_advanced;

  /// No description provided for @surveillance_general_title.
  ///
  /// In en, this message translates to:
  /// **'Surveillance Mode'**
  String get surveillance_general_title;

  /// No description provided for @surveillance_general_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable Surveillance'**
  String get surveillance_general_enable;

  /// No description provided for @surveillance_general_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get surveillance_general_status;

  /// No description provided for @surveillance_general_status_running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get surveillance_general_status_running;

  /// No description provided for @surveillance_general_status_idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get surveillance_general_status_idle;

  /// No description provided for @surveillance_general_events_today.
  ///
  /// In en, this message translates to:
  /// **'Events Today'**
  String get surveillance_general_events_today;

  /// No description provided for @surveillance_safe_locations_title.
  ///
  /// In en, this message translates to:
  /// **'Safe Locations'**
  String get surveillance_safe_locations_title;

  /// No description provided for @surveillance_safe_locations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Camera won\'t start when parked here'**
  String get surveillance_safe_locations_subtitle;

  /// No description provided for @surveillance_safe_locations_enable.
  ///
  /// In en, this message translates to:
  /// **'Disable at Safe Locations'**
  String get surveillance_safe_locations_enable;

  /// No description provided for @surveillance_safe_locations_empty.
  ///
  /// In en, this message translates to:
  /// **'No safe locations added yet'**
  String get surveillance_safe_locations_empty;

  /// No description provided for @surveillance_safe_locations_add_current.
  ///
  /// In en, this message translates to:
  /// **'Add Current Location as Safe Zone'**
  String get surveillance_safe_locations_add_current;

  /// No description provided for @surveillance_safe_locations_no_gps.
  ///
  /// In en, this message translates to:
  /// **'GPS location not available'**
  String get surveillance_safe_locations_no_gps;

  /// No description provided for @surveillance_safe_locations_zone_label.
  ///
  /// In en, this message translates to:
  /// **'{arg1}  ({arg2}m)'**
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2);

  /// No description provided for @surveillance_detection_title.
  ///
  /// In en, this message translates to:
  /// **'Detection Settings'**
  String get surveillance_detection_title;

  /// No description provided for @surveillance_detection_preset_label.
  ///
  /// In en, this message translates to:
  /// **'Environment Preset'**
  String get surveillance_detection_preset_label;

  /// No description provided for @surveillance_preset_outdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get surveillance_preset_outdoor;

  /// No description provided for @surveillance_preset_garage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get surveillance_preset_garage;

  /// No description provided for @surveillance_preset_street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get surveillance_preset_street;

  /// No description provided for @surveillance_preset_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get surveillance_preset_custom;

  /// No description provided for @surveillance_detection_sensitivity_label.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity (1=strict, 5=sensitive): {arg1}'**
  String surveillance_detection_sensitivity_label(Object arg1);

  /// No description provided for @surveillance_detection_objects_label.
  ///
  /// In en, this message translates to:
  /// **'Detect Objects'**
  String get surveillance_detection_objects_label;

  /// No description provided for @surveillance_detection_object_person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get surveillance_detection_object_person;

  /// No description provided for @surveillance_detection_object_car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get surveillance_detection_object_car;

  /// No description provided for @surveillance_detection_object_bike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get surveillance_detection_object_bike;

  /// No description provided for @surveillance_recording_title.
  ///
  /// In en, this message translates to:
  /// **'Event Recording'**
  String get surveillance_recording_title;

  /// No description provided for @surveillance_recording_pre_label.
  ///
  /// In en, this message translates to:
  /// **'Pre-record (seconds before event): {arg1}'**
  String surveillance_recording_pre_label(Object arg1);

  /// No description provided for @surveillance_recording_post_label.
  ///
  /// In en, this message translates to:
  /// **'Post-record (seconds after event): {arg1}'**
  String surveillance_recording_post_label(Object arg1);

  /// No description provided for @surveillance_seconds_value.
  ///
  /// In en, this message translates to:
  /// **'{arg1}s'**
  String surveillance_seconds_value(Object arg1);

  /// No description provided for @surveillance_storage_title.
  ///
  /// In en, this message translates to:
  /// **'Surveillance Storage'**
  String get surveillance_storage_title;

  /// No description provided for @surveillance_storage_location_label.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get surveillance_storage_location_label;

  /// No description provided for @surveillance_storage_internal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get surveillance_storage_internal;

  /// No description provided for @surveillance_storage_sd_card.
  ///
  /// In en, this message translates to:
  /// **'SD Card'**
  String get surveillance_storage_sd_card;

  /// No description provided for @surveillance_storage_sd_card_na.
  ///
  /// In en, this message translates to:
  /// **'SD Card (N/A)'**
  String get surveillance_storage_sd_card_na;

  /// No description provided for @surveillance_storage_limit_label.
  ///
  /// In en, this message translates to:
  /// **'Storage Limit — auto-deletes oldest when reached'**
  String get surveillance_storage_limit_label;

  /// No description provided for @surveillance_storage_usage_label.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get surveillance_storage_usage_label;

  /// No description provided for @surveillance_storage_files_label.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get surveillance_storage_files_label;

  /// No description provided for @surveillance_storage_usage.
  ///
  /// In en, this message translates to:
  /// **'{arg1} used / {arg2} limit'**
  String surveillance_storage_usage(Object arg1, Object arg2);

  /// No description provided for @surveillance_storage_files.
  ///
  /// In en, this message translates to:
  /// **'{arg1} events'**
  String surveillance_storage_files(Object arg1);

  /// No description provided for @surveillance_storage_path_label.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get surveillance_storage_path_label;

  /// No description provided for @surveillance_format_title.
  ///
  /// In en, this message translates to:
  /// **'Format External Drive'**
  String get surveillance_format_title;

  /// No description provided for @surveillance_format_warning.
  ///
  /// In en, this message translates to:
  /// **'Permanently erases ALL data on the SD card or USB drive.'**
  String get surveillance_format_warning;

  /// No description provided for @surveillance_format_button.
  ///
  /// In en, this message translates to:
  /// **'Format SD Card / USB'**
  String get surveillance_format_button;

  /// No description provided for @surveillance_format_confirm.
  ///
  /// In en, this message translates to:
  /// **'Tap again — ALL data will be ERASED'**
  String get surveillance_format_confirm;

  /// No description provided for @surveillance_format_running.
  ///
  /// In en, this message translates to:
  /// **'Formatting… please wait'**
  String get surveillance_format_running;

  /// No description provided for @surveillance_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get surveillance_dismiss;

  /// No description provided for @surveillance_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Database Catalog'**
  String get surveillance_sync_title;

  /// No description provided for @surveillance_sync_description.
  ///
  /// In en, this message translates to:
  /// **'Reconcile the surveillance index with files on disk.'**
  String get surveillance_sync_description;

  /// No description provided for @surveillance_sync_button.
  ///
  /// In en, this message translates to:
  /// **'Sync Database'**
  String get surveillance_sync_button;

  /// No description provided for @surveillance_sync_running.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get surveillance_sync_running;

  /// No description provided for @surveillance_advanced_camera_title.
  ///
  /// In en, this message translates to:
  /// **'Camera Selection'**
  String get surveillance_advanced_camera_title;

  /// No description provided for @surveillance_advanced_camera_front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get surveillance_advanced_camera_front;

  /// No description provided for @surveillance_advanced_camera_right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get surveillance_advanced_camera_right;

  /// No description provided for @surveillance_advanced_camera_rear.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get surveillance_advanced_camera_rear;

  /// No description provided for @surveillance_advanced_camera_left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get surveillance_advanced_camera_left;

  /// No description provided for @surveillance_advanced_ai_title.
  ///
  /// In en, this message translates to:
  /// **'AI & Deterrent'**
  String get surveillance_advanced_ai_title;

  /// No description provided for @surveillance_advanced_ai_detection.
  ///
  /// In en, this message translates to:
  /// **'AI Detection'**
  String get surveillance_advanced_ai_detection;

  /// No description provided for @surveillance_advanced_night_mode.
  ///
  /// In en, this message translates to:
  /// **'Night Mode'**
  String get surveillance_advanced_night_mode;

  /// No description provided for @surveillance_advanced_deterrent_label.
  ///
  /// In en, this message translates to:
  /// **'Deterrent Action'**
  String get surveillance_advanced_deterrent_label;

  /// No description provided for @surveillance_deterrent_silent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get surveillance_deterrent_silent;

  /// No description provided for @surveillance_deterrent_horn.
  ///
  /// In en, this message translates to:
  /// **'Horn'**
  String get surveillance_deterrent_horn;

  /// No description provided for @surveillance_deterrent_flash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get surveillance_deterrent_flash;

  /// No description provided for @surveillance_apply_button.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get surveillance_apply_button;

  /// No description provided for @surveillance_apply_failed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get surveillance_apply_failed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'nb',
    'nl',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nb':
      return AppLocalizationsNb();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
