// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Keeps BladeWatch vehicle monitoring active in the background. This service does not read or interact with screen content.';

  @override
  String get action_cancel => 'Cancel';

  @override
  String get action_clear_plain => 'Clear';

  @override
  String get action_select_all => 'Select all';

  @override
  String get action_select_all_short => 'All';

  @override
  String get action_delete => 'Delete';

  @override
  String get action_done => 'DONE';

  @override
  String get action_remind_me_later => 'REMIND ME LATER';

  @override
  String get action_retry => 'Retry';

  @override
  String get action_run => 'Run';

  @override
  String get action_clear_output => 'Clear Output';

  @override
  String get cd_camera => 'Camera';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR Code';

  @override
  String get cd_show_hide_token => 'Show/Hide Token';

  @override
  String get cd_copy_token => 'Copy Token';

  @override
  String get cd_copy_url => 'Copy URL';

  @override
  String get cd_clear_logs => 'Clear logs';

  @override
  String get cd_expand_collapse => 'Expand/Collapse';

  @override
  String get cd_recording_status => 'Recording status';

  @override
  String get cd_trip_tracking_status => 'Trip tracking status';

  @override
  String get cd_video_thumbnail => 'Video thumbnail';

  @override
  String get cd_play => 'Play';

  @override
  String get cd_back => 'Back';

  @override
  String get cd_play_pause => 'Play/Pause';

  @override
  String get cd_player_prev => 'Previous recording';

  @override
  String get cd_player_next => 'Next recording';

  @override
  String get cd_player_maximize => 'Maximize player';

  @override
  String get cd_player_minimize => 'Exit fullscreen';

  @override
  String get cd_delete => 'Delete';

  @override
  String get cd_decrease => 'Decrease';

  @override
  String get cd_increase => 'Increase';

  @override
  String get cd_expand => 'Expand';

  @override
  String get cd_configure => 'Configure';

  @override
  String get cd_download_log => 'Download log';

  @override
  String get cd_reset => 'Reset';

  @override
  String get cd_battery => 'Battery';

  @override
  String get cd_step_completed => 'Step completed';

  @override
  String get cd_permission_granted => 'Permission granted';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'PROCESSES';

  @override
  String get logs_panel_title => 'Logs';

  @override
  String get url_connecting => 'Connecting…';

  @override
  String get camera_selection_title => 'Camera Selection';

  @override
  String get camera_selection_subtitle => 'Select panoramic camera source';

  @override
  String get camera_current_auto => 'Current: Auto';

  @override
  String get camera_option_auto => 'Auto (detect on startup)';

  @override
  String get camera_option_0 => 'Camera 0 — Atto trims';

  @override
  String get camera_option_1 => 'Camera 1 — Seal (default)';

  @override
  String get camera_option_2 => 'Camera 2';

  @override
  String get camera_option_3 => 'Camera 3';

  @override
  String get camera_option_4 => 'Camera 4';

  @override
  String get camera_option_5 => 'Camera 5';

  @override
  String get camera_selection_hint =>
      'Auto picks the right camera for your trim on every boot. Camera 1 = BYD Seal, Camera 0 = Atto trims. Restart the camera service after changing camera ID for the setting to take effect.';

  @override
  String get dashboard_scan_to_connect => 'Scan to Connect';

  @override
  String get dashboard_qr_waiting => 'Waiting for tunnel…';

  @override
  String get dashboard_daemons_running_default => '0/5 Running';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'Access Code';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Regenerate Token';

  @override
  String get dashboard_set_password => 'Set Password';

  @override
  String get cd_set_password => 'Set custom password';

  @override
  String get dialog_set_password_title => 'Set Custom Password';

  @override
  String get dialog_set_password_message =>
      'Enter a new access password. This replaces the auto-generated token.';

  @override
  String get dialog_set_password_hint => 'New password (min 12 characters)';

  @override
  String get toast_password_set => 'Password updated';

  @override
  String get toast_password_too_short =>
      'Password must be at least 12 characters';

  @override
  String get toast_password_save_failed =>
      'Failed to save password — service not ready';

  @override
  String get setup_guide_title => 'Getting Started';

  @override
  String get setup_guide_subtitle =>
      'Three quick steps to get the best experience:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Pick Your Language';

  @override
  String get setup_language_body =>
      'Defaults to your head unit\'s language. Tap to choose a different one for the BladeWatch app and the web tunnel.';

  @override
  String get setup_language_button => 'Choose Language';

  @override
  String get setup_autostart_title => 'Disable Auto-Start Restriction';

  @override
  String get setup_autostart_body =>
      'Tap below to open BYD Auto-Start, then uncheck BOTH BladeWatch and BladeWatch Service. Without this, recording does not start when you switch the car on — you have to open the app every time. BYD wipes this on every install, so redo it after updates.';

  @override
  String get setup_autostart_button => 'Open BYD Auto-Start';

  @override
  String get setup_overlay_title => 'Allow Display Over Other Apps';

  @override
  String get setup_overlay_body =>
      'Enable this to show a floating status indicator for recording and trip tracking on top of other apps.';

  @override
  String get setup_overlay_button => 'Open Overlay Settings';

  @override
  String get cd_close => 'Close';

  @override
  String get language_picker_title => 'Language';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '$arg1 languages available';
  }

  @override
  String get language_picker_subtitle_pending => 'Choose a language';

  @override
  String get language_auto_title => 'Auto';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Follow system · $arg1';
  }

  @override
  String get language_not_saved =>
      'Language applied, but it could not be saved — it will reset when the app restarts.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Auto';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Enter command…';

  @override
  String get adb_preset_commands_header => 'Preset commands';

  @override
  String get adb_output_header => 'Output';

  @override
  String get adb_output_ready => '\$ Ready for commands…';

  @override
  String get adb_console_hero_title => 'ADB Console';

  @override
  String get adb_console_hero_subtitle => 'Run shell commands on the device';

  @override
  String get adb_console_unavailable_title => 'ADB is not connected';

  @override
  String get adb_console_unavailable_body =>
      'On this vehicle, the standard \"USB debugging\" toggle in Developer Options is not enough by itself — the head unit\'s own wireless ADB (network debugging) setting also needs to be on, and a system update can reset it. Re-enable wireless ADB on the head unit, or connect via USB.';

  @override
  String get adb_console_auth_pending_title => 'Waiting for approval';

  @override
  String get adb_console_auth_pending_body =>
      'Check the head unit\'s screen for an \"Allow USB debugging?\" prompt and accept it, then retry.';

  @override
  String get performance_connecting => 'Connecting to performance monitor…';

  @override
  String get performance_hero_title => 'System Performance';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'System Usage';

  @override
  String get performance_cpu_app_usage => 'App Usage';

  @override
  String get performance_frequency_label => 'Frequency';

  @override
  String get performance_temperature_label => 'Temperature';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Memory';

  @override
  String get performance_usage_label => 'Usage';

  @override
  String get performance_memory_total => 'Total';

  @override
  String get performance_memory_used => 'Used';

  @override
  String get performance_memory_app => 'App';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'App Process';

  @override
  String get performance_threads_label => 'Threads';

  @override
  String get performance_gc_cycles_label => 'GC Cycles';

  @override
  String get performance_open_fds_label => 'Open FDs';

  @override
  String get performance_refreshing_footer => 'Refreshing every 3 seconds';

  @override
  String get webview_loading => 'Loading…';

  @override
  String get reset_title => 'Reset Data';

  @override
  String get reset_subtitle => 'Wipe accumulated data by category';

  @override
  String get reset_warning =>
      'This cannot be undone. Recordings, trips, and battery history will be permanently deleted.';

  @override
  String get reset_cat_trips => 'Trips';

  @override
  String get reset_cat_trips_desc =>
      'Trip history, routes, weekly/monthly rollups';

  @override
  String get reset_cat_soc_history => 'SoC & 12V history';

  @override
  String get reset_cat_soc_history_desc =>
      'SoC samples, charging sessions, voltage logs';

  @override
  String get reset_cat_recordings => 'Recordings (videos)';

  @override
  String get reset_cat_recordings_desc => 'All MP4s in the recordings folder';

  @override
  String get reset_cat_sentry_events => 'Surveillance events';

  @override
  String get reset_cat_sentry_events_desc =>
      'Surveillance event clips and JSON sidecars';

  @override
  String get reset_cat_proximity => 'Proximity recordings';

  @override
  String get reset_cat_proximity_desc => 'Radar-triggered event MP4s';

  @override
  String get reset_cat_trip_files => 'Trip telemetry files';

  @override
  String get reset_cat_trip_files_desc => 'Per-trip JSON telemetry on disk';

  @override
  String get recording_lib_chip_any => 'Any';

  @override
  String get recording_lib_chip_person => 'Person';

  @override
  String get recording_lib_chip_vehicle => 'Vehicle';

  @override
  String get recording_lib_chip_bike => 'Bike';

  @override
  String get recording_lib_chip_animal => 'Animal';

  @override
  String get recording_lib_chip_alert => 'Alert';

  @override
  String get recording_lib_chip_critical => 'Critical';

  @override
  String get recording_lib_selected_count_zero => '0 selected';

  @override
  String get recording_lib_no_recordings => 'No recordings';

  @override
  String get recording_lib_filter_button => 'Filter';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filter · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Filter recordings';

  @override
  String get recording_lib_filter_apply => 'Apply';

  @override
  String get recording_lib_filter_reset => 'Reset';

  @override
  String get recording_lib_filter_section_what => 'What';

  @override
  String get recording_lib_filter_section_severity => 'Severity';

  @override
  String get recording_lib_filter_section_type => 'Type';

  @override
  String get recording_lib_chip_type_normal => 'Normal';

  @override
  String get recording_lib_chip_type_proximity => 'Proximity';

  @override
  String get recording_lib_date_today => 'Today';

  @override
  String get recording_lib_date_yesterday => 'Yesterday';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clips',
      one: '$arg1 clip',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Pick a date';

  @override
  String get recording_lib_date_all_days => 'All days';

  @override
  String get cd_clear_date_filter => 'Show all days';

  @override
  String get recording_lib_section_morning => 'Morning';

  @override
  String get recording_lib_section_afternoon => 'Afternoon';

  @override
  String get recording_lib_section_evening => 'Evening';

  @override
  String get recording_lib_section_night => 'Night';

  @override
  String get cd_previous_day => 'Previous day';

  @override
  String get cd_next_day => 'Next day';

  @override
  String get cd_open_filters => 'Open filters';

  @override
  String get cd_clear_filter => 'Clear filter';

  @override
  String get player_title_recording => 'Recording';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Camera Daemon';

  @override
  String get daemon_name_surveillance => 'Surveillance Daemon';

  @override
  String get daemon_name_acc => 'ACC Surveillance';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'Background services';

  @override
  String get daemons_count_pending => 'Loading services…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 of $arg2 running';
  }

  @override
  String get battery_health_title => 'Battery Health';

  @override
  String get battery_health_unavailable => 'Not available';

  @override
  String get battery_health_unavailable_desc =>
      'Battery health estimation is not available.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% on $arg2';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 recordings deleted',
      one: '$arg1 recording deleted',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Delete $arg1 Recordings',
      one: 'Delete $arg1 Recording',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'This will permanently delete $arg1 recordings. This cannot be undone.',
      one:
          'This will permanently delete $arg1 recording. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'App is up to date (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Storage permission required for recordings';

  @override
  String get toast_url_copied_short => 'URL copied!';

  @override
  String get toast_camera_set_to_auto => 'Camera set to Auto';

  @override
  String get toast_failed_to_save_short => 'Failed to save';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Failed: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Camera $arg1 set — next ACC cycle';
  }

  @override
  String get toast_clearing_camera_config => 'Clearing camera config…';

  @override
  String get toast_restarting_camera_daemon => 'Restarting camera service…';

  @override
  String get toast_camera_daemon_restarting =>
      'Camera service restarting with full probe';

  @override
  String get toast_camera_restart_failed =>
      'Config cleared but service restart failed. Please restart manually.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Failed: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'Select at least one category';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Reset failed: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 traffic monitor…';
  }

  @override
  String get dialog_close => 'Close';

  @override
  String get dialog_reset => 'Reset';

  @override
  String get dialog_delete => 'Delete';

  @override
  String get dialog_save => 'Save';

  @override
  String get dialog_enable => 'Enable';

  @override
  String get dialog_disable => 'Disable';

  @override
  String get dialog_keep_enabled => 'Keep Enabled';

  @override
  String get dialog_keep_disabled => 'Keep Disabled';

  @override
  String get dialog_regenerate => 'Regenerate';

  @override
  String get dialog_reset_selected => 'Reset Selected';

  @override
  String get dialog_reset_following_title => 'Reset the following?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'This cannot be undone.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Reset complete';

  @override
  String get dialog_traffic_cannot_check_title => 'Cannot Check Status';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB is not connected, and the app could not reconnect automatically.\n\nOn this vehicle, the standard \"USB debugging\" toggle in Developer Options is not enough by itself — the head unit\'s own wireless ADB (network debugging) setting also needs to be on, and a system update can reset it. Re-enable wireless ADB on the head unit, or connect via USB.\n\nThe status will update automatically once connected.';

  @override
  String get dialog_traffic_disable_title => 'Disable BYD Traffic Monitor?';

  @override
  String get dialog_traffic_disable_message =>
      'The BYD Traffic Monitor (com.byd.trafficmonitor) is a built-in system app that continuously monitors road traffic conditions in the background.\n\nWhy disable it?\n\n• Consumes mobile data (even when parked)\n• Uses CPU and battery in the background\n• Not needed if you use a separate navigation app\n• Can interfere with the dashcam\'s network usage\n\nThis is safe to disable — it only affects the built-in traffic overlay on the map. Your navigation, Bluetooth, and all other car functions remain unaffected.\n\nA hard reboot is required after disabling (hold center console button 5 seconds).';

  @override
  String get dialog_traffic_enable_title => 'Re-enable BYD Traffic Monitor?';

  @override
  String get dialog_traffic_enable_message =>
      'The BYD Traffic Monitor is currently disabled.\n\nRe-enabling it will restore the built-in traffic overlay on the navigation map. Note that it will run in the background and consume mobile data.\n\nA hard reboot is required after enabling (hold center console button 5 seconds).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Traffic Monitor $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'The change has been applied.\n\nPlease perform a hard reboot now:\nPress and hold the central console button for 5 seconds.';

  @override
  String get traffic_monitor_loading => 'Traffic Monitor: Checking…';

  @override
  String get traffic_monitor_tap_to_check => 'Traffic Monitor (tap to check)';

  @override
  String get reset_label_trips => 'Trips';

  @override
  String get reset_label_soc_history => 'SoC + 12V history';

  @override
  String get reset_label_recordings => 'Recordings';

  @override
  String get reset_label_sentry_events => 'Surveillance events';

  @override
  String get reset_label_proximity => 'Proximity recordings';

  @override
  String get reset_label_trip_files => 'Trip telemetry files';

  @override
  String get toast_access_code_copied => 'Access code copied';

  @override
  String get dialog_regenerate_token_title => 'Regenerate Token';

  @override
  String get dialog_regenerate_token_message =>
      'This will invalidate the current token. All active sessions will be logged out. Continue?';

  @override
  String get toast_token_regenerated_logged_out =>
      'New token generated. All sessions logged out.';

  @override
  String get toast_token_regenerated_restart =>
      'Token regenerated. Services may need restart to apply.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token regenerated. Could not notify background service.';

  @override
  String get toast_token_regenerated => 'Token regenerated';

  @override
  String get dashboard_no_tunnel => 'No tunnel running';

  @override
  String get dashboard_starting_tor => 'Starting Tor tunnel…';

  @override
  String get dashboard_waiting_url => 'Waiting for tunnel URL…';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 Running';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'Access Code';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'No configuration needed for $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'Token cannot be empty';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Fetching $arg1 log…';
  }

  @override
  String get toast_log_empty_or_missing => 'Log file is empty or not found';

  @override
  String get toast_log_empty => 'Log file is empty';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Failed to save log: $arg1';
  }

  @override
  String get toast_log_not_found => 'Log file not found or unreadable';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1 Log - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Share $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 Log ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Source: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'Exported: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'NOTE: Log truncated to last 10000 lines (total: $arg1 lines)',
      one: 'NOTE: Log truncated to last 10000 lines (total: $arg1 line)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Cannot play video: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Delete Recording';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'Delete $arg1?\nThis cannot be undone.';
  }

  @override
  String get toast_recording_deleted => 'Recording deleted';

  @override
  String get toast_recording_delete_failed => 'Failed to delete recording';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 deleted, $arg2 failed';
  }

  @override
  String get play_with_chooser => 'Play with';

  @override
  String setup_version_banner(Object arg1) {
    return 'Updated to v$arg1 — re-confirm autostart, BYD wipes it on every install';
  }

  @override
  String get setup_overlay_already_granted => 'Already Granted';

  @override
  String camera_current_manual(Object arg1) {
    return 'Current: Camera $arg1 (Manual)';
  }

  @override
  String get camera_current_auto_label => 'Current: Auto';

  @override
  String get soh_estimation_active => 'Estimation active';

  @override
  String get soh_oem_readout =>
      'Vehicle SOH readout — waiting for calculated estimate';

  @override
  String get soh_nominal_baseline =>
      'Nominal baseline — waiting for trusted SOH data';

  @override
  String get soh_no_estimate_yet => 'No estimate yet — waiting for data';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 selected';
  }

  @override
  String get video_player_playback_error => 'Playback error';

  @override
  String get video_player_no_events => 'No events';

  @override
  String get daemon_configuration_required => 'Configuration required';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Video Player';

  @override
  String get status_overlay_notif_title => 'BladeWatch Status';

  @override
  String get status_overlay_notif_text => 'Status overlay active';

  @override
  String get rail_dashboard => 'Dashboard';

  @override
  String get rail_live => 'Live';

  @override
  String get rail_recordings => 'Recordings';

  @override
  String get rail_vehicle => 'Vehicle';

  @override
  String get rail_trips => 'Trips';

  @override
  String get rail_location => 'Location';

  @override
  String get rail_diagnostics => 'Diagnostics';

  @override
  String get rail_settings => 'Settings';

  @override
  String get settings_section_appearance => 'Appearance';

  @override
  String get settings_section_recording => 'Recording';

  @override
  String get settings_section_surveillance => 'Surveillance';

  @override
  String get settings_section_daemons => 'Services';

  @override
  String get settings_section_privacy => 'Privacy & data';

  @override
  String get settings_section_trips => 'Trips';

  @override
  String get settings_section_trips_subtitle =>
      'Cost rates, distance unit and where trips are stored';

  @override
  String get settings_section_overlay => 'Status overlay';

  @override
  String get settings_overlay_subtitle =>
      'Choose which segments of the floating status pill stay visible.';

  @override
  String get settings_overlay_camera_title => 'Camera indicator';

  @override
  String get settings_overlay_camera_subtitle =>
      'Show the REC / PROX badge while recording is active.';

  @override
  String get settings_overlay_trip_title => 'Trip indicator';

  @override
  String get settings_overlay_trip_subtitle =>
      'Show the TRIP badge while trip detection is running.';

  @override
  String get settings_section_about => 'About';

  @override
  String get settings_subrail_overline => 'SETTINGS';

  @override
  String get cd_settings_subrail => 'Settings sub-rail';

  @override
  String get settings_privacy_title => 'Privacy & data';

  @override
  String get settings_privacy_body =>
      'Reset clears recordings index, cached credentials, service state, and on-device preferences. The action cannot be undone.';

  @override
  String get settings_about_title => 'About BladeWatch';

  @override
  String get settings_about_version_label => 'Version';

  @override
  String get settings_about_package_label => 'Build';

  @override
  String get settings_about_support_section => 'Powered by people like you';

  @override
  String get settings_about_support_share_title => 'Tell a fellow owner';

  @override
  String get settings_about_support_share_value =>
      'Every shared link helps another BYD owner discover BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Check out BladeWatch — open-source surveillance & dashcam for BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'Share BladeWatch';

  @override
  String get settings_about_open_link_failed => 'Couldn\'t open link.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'No browser found. URL copied: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => 'Fuel the next release';

  @override
  String get settings_about_support_kofi_value =>
      'A coffee on Ko-fi keeps the late-night commits coming.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'License';

  @override
  String get settings_about_license_value =>
      'MIT — open source. Tap to view full text.';

  @override
  String get settings_about_source_title => 'Source code';

  @override
  String get settings_about_source_value =>
      'github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_license_url =>
      'https://github.com/yash-srivastava/BladeWatch-release/blob/main/LICENSE';

  @override
  String get settings_about_source_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_star_title => 'Star us on GitHub';

  @override
  String get settings_about_star_value => 'Takes a second. Means a lot.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Thanks';

  @override
  String get settings_about_thanks_subtitle =>
      'Built with the help of contributors and supporters.';

  @override
  String get settings_about_contributors_title => 'Contributors';

  @override
  String get settings_about_supporters_title => 'Supporters';

  @override
  String get settings_about_thanks_empty =>
      'List populates as people pitch in.';

  @override
  String get settings_theme_label => 'Theme';

  @override
  String get settings_theme_auto => 'Auto (follow system)';

  @override
  String get settings_theme_light => 'Light';

  @override
  String get settings_theme_dark => 'Dark';

  @override
  String get settings_language_label => 'Language';

  @override
  String get settings_drive_side_label => 'Navigation Side';

  @override
  String get settings_drive_side_subtitle =>
      'Choose which side of the screen the navigation menu appears on.';

  @override
  String get settings_drive_side_left => 'Left';

  @override
  String get settings_drive_side_left_hint => 'LHD · default';

  @override
  String get settings_drive_side_right => 'Right';

  @override
  String get settings_drive_side_right_hint => 'RHD vehicles';

  @override
  String get settings_drive_side_auto => 'Auto';

  @override
  String get settings_drive_side_auto_hint => 'Detect from vehicle';

  @override
  String get settings_drive_side_caption_left => 'Navigation on left';

  @override
  String get settings_drive_side_caption_right => 'Navigation on right';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Auto — vehicle reports left-hand drive';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Auto — vehicle reports right-hand drive';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Auto — vehicle unavailable, using left';

  @override
  String get recordings_title => 'Recordings';

  @override
  String get recordings_segment_dashcam => 'Dashcam';

  @override
  String get recordings_segment_surveillance => 'Surveillance';

  @override
  String get recordings_action_settings => 'Settings';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 today · $arg2 total · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashcam · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Surveillance · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Select a recording';

  @override
  String get recordings_preview_placeholder_body =>
      'Tap any item on the left to play it.';

  @override
  String get diagnostics_section_adb_console => 'ADB Console';

  @override
  String get diagnostics_section_traffic => 'Traffic monitor';

  @override
  String get diagnostics_section_camera_probe => 'Camera probe';

  @override
  String get diagnostics_section_battery => 'Battery health';

  @override
  String get diagnostics_section_performance => 'Performance';

  @override
  String get diagnostics_hero_title => 'System diagnostics';

  @override
  String get diagnostics_hero_subtitle =>
      'Live health, logs, and probes for the device.';

  @override
  String get diagnostics_health_clear => 'All clear';

  @override
  String get diagnostics_health_section => 'Health';

  @override
  String get diagnostics_health_network => 'Network';

  @override
  String get diagnostics_health_storage => 'Storage';

  @override
  String get diagnostics_health_camera => 'Camera';

  @override
  String get diagnostics_health_battery => 'Battery';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Online';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Tunnel · $arg1';
  }

  @override
  String diagnostics_network_data_usage_line(Object arg1) {
    return '$arg1 this month';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Online';

  @override
  String get diagnostics_tunnel_state_offline => 'Offline';

  @override
  String get diagnostics_tunnel_state_connecting => 'Connecting';

  @override
  String get diagnostics_network_mobile => 'Mobile';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Offline';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clips · $arg2 used',
      one: '$arg1 clip · $arg2 used',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 free';
  }

  @override
  String get diagnostics_logs_card_title => 'Live event log';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Streaming output from running services.';

  @override
  String get diagnostics_tools_section => 'Tools';

  @override
  String get diagnostics_traffic_subtitle => 'Watch live network throughput.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Inspect connected camera streams.';

  @override
  String get diagnostics_adb_subtitle => 'Open the on-device terminal.';

  @override
  String get diagnostics_battery_subtitle => 'Inspect cell SOH and pack stats.';

  @override
  String get diagnostics_settings_subtitle =>
      'App preferences, theme, and language.';

  @override
  String get settings_action_reset_data => 'Reset data…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'On watch';

  @override
  String get dashboard_subtitle_all_systems => 'All systems online';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 of $arg2 services online';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Remote access offline';

  @override
  String get dashboard_metric_recordings => 'Today\'s recordings';

  @override
  String get dashboard_metric_storage => 'Storage used';

  @override
  String get dashboard_metric_tunnel => 'Remote access';

  @override
  String get dashboard_metric_services => 'Background services';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Vehicle';

  @override
  String get dashboard_chip_recording_active => 'Recording';

  @override
  String get dashboard_chip_recording_idle => 'Idle';

  @override
  String get dashboard_vehicle_tap_to_set => 'Tap to set';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Set battery capacity';

  @override
  String get vehicle_dialog_model_label => 'Model';

  @override
  String get vehicle_dialog_save => 'Save';

  @override
  String get settings_recording_tab_status => 'Status';

  @override
  String get settings_recording_tab_capture => 'Capture';

  @override
  String get settings_recording_tab_quality => 'Quality';

  @override
  String get settings_recording_tab_storage => 'Storage';

  @override
  String get settings_recording_status_title => 'Recording Status';

  @override
  String get settings_recording_status_current_state => 'Current State';

  @override
  String get settings_recording_status_today_count => 'Recordings Today';

  @override
  String get settings_recording_mode_title => 'Recording Mode (ACC ON)';

  @override
  String get settings_recording_mode_description =>
      'Choose when dashcam recording should occur while driving.';

  @override
  String get settings_recording_mode_none_label => 'None (Default)';

  @override
  String get settings_recording_mode_none_desc =>
      'No recording — surveillance still works';

  @override
  String get settings_recording_mode_continuous_label => 'Continuous';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Record all the time while driving';

  @override
  String get settings_recording_mode_drive_label => 'Drive Mode';

  @override
  String get settings_recording_mode_drive_desc =>
      'Record only when vehicle is moving';

  @override
  String get settings_recording_mode_proximity_label => 'Proximity Guard';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Record when motion is detected';

  @override
  String get settings_recording_limit_title => 'Recording Limit';

  @override
  String get settings_recording_limit_description =>
      'Maximum length per file. Recordings split into new files at this interval.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_priority_title => 'Recording Priority';

  @override
  String get settings_recording_priority_description =>
      'How recording handles a sudden loss of power.';

  @override
  String get settings_recording_priority_performance_label => 'Performance';

  @override
  String get settings_recording_priority_performance_desc =>
      'Uses less CPU. If power is cut abruptly, the current recording segment (up to your Recording Limit) may be lost.';

  @override
  String get settings_recording_priority_reliability_label => 'Reliability';

  @override
  String get settings_recording_priority_reliability_desc =>
      'Uses a bit more CPU to save more often. If power is cut abruptly, at most about a minute may be lost.';

  @override
  String get settings_recording_overlay_fields_title => 'Overlay Fields';

  @override
  String get settings_recording_overlay_fields_description =>
      'Choose what appears in the burned-in overlay on continuous recordings.';

  @override
  String get settings_recording_overlay_field_speed => 'Speed';

  @override
  String get settings_recording_overlay_field_gear => 'Gear';

  @override
  String get settings_recording_overlay_field_turn_signal_left =>
      'Left turn signal';

  @override
  String get settings_recording_overlay_field_turn_signal_right =>
      'Right turn signal';

  @override
  String get settings_recording_overlay_field_brake_pedal => 'Brake pedal';

  @override
  String get settings_recording_overlay_field_accel_pedal =>
      'Accelerator pedal';

  @override
  String get settings_recording_overlay_field_seatbelt_driver =>
      'Driver seatbelt';

  @override
  String get settings_recording_overlay_field_seatbelt_passenger =>
      'Passenger seatbelt';

  @override
  String get settings_recording_overlay_field_timestamp => 'Date and time';

  @override
  String get settings_recording_quality_title => 'Recording Quality';

  @override
  String get settings_recording_storage_title => 'Recording Storage';

  @override
  String get settings_recording_storage_confirm_title => 'Delete recordings?';

  @override
  String settings_recording_storage_confirm_message(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'This will delete $arg1 recordings ($arg2).',
      one: 'This will delete $arg1 recording ($arg2).',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_confirm_unknown_title =>
      'Impact unknown';

  @override
  String get settings_recording_storage_confirm_unknown_message =>
      'Could not determine what this change would delete. Lowering the limit may remove existing recordings.';

  @override
  String get settings_recording_storage_location_label => 'Storage Location';

  @override
  String get settings_recording_storage_internal => 'Internal';

  @override
  String get settings_recording_storage_sd_card => 'SD Card';

  @override
  String get settings_recording_storage_sd_card_na => 'SD Card (N/A)';

  @override
  String get settings_recording_storage_sd_mount_failed_title =>
      'SD card did not mount';

  @override
  String get settings_recording_storage_limit_label =>
      'Storage Limit — auto-deletes oldest when reached';

  @override
  String get settings_recording_storage_usage_label => 'Storage Usage';

  @override
  String get settings_recording_storage_files_label => 'Files';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 used / $arg2 limit';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 recordings',
      one: '$arg1 recording',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Path';

  @override
  String get settings_recording_storage_sd_free_label => 'SD Card Free';

  @override
  String get settings_recording_storage_internal_free_label => 'Internal Free';

  @override
  String get settings_recording_format_title => 'Format External Drive';

  @override
  String get settings_recording_format_warning =>
      'Permanently erases ALL data on the SD card or USB drive.';

  @override
  String get settings_recording_format_confirm =>
      'Tap again — ALL data will be ERASED';

  @override
  String get settings_recording_format_running => 'Formatting… please wait';

  @override
  String get settings_recording_format_button => 'Format SD Card / USB';

  @override
  String get settings_recording_format_no_drive => 'No removable drive found';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Formatted successfully. New path: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Database Catalog';

  @override
  String get settings_recording_sync_description =>
      'Reconcile the recordings index with files on disk.';

  @override
  String get settings_recording_sync_running => 'Syncing…';

  @override
  String get settings_recording_sync_button => 'Sync Database';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Synced: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => 'Sync already in progress';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Sync failed: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Apply Changes';

  @override
  String get settings_recording_dismiss => 'Dismiss';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Starting/stopping $arg1 isn’t supported yet';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 used · $arg2 free';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Storage —';

  @override
  String get dashboard_tunnel_offline => 'Offline';

  @override
  String get dashboard_tunnel_online => 'Online';

  @override
  String get dashboard_tunnel_connecting => 'Connecting…';

  @override
  String get dashboard_trips_this_week => 'This Week';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 trips',
      one: '$arg1 trip',
    );
    return '$_temp0';
  }

  @override
  String dashboard_trips_distance_km(Object arg1) {
    return '$arg1 km';
  }

  @override
  String dashboard_trips_distance_mi(Object arg1) {
    return '$arg1 mi';
  }

  @override
  String dashboard_trips_duration(Object arg1) {
    return '$arg1';
  }

  @override
  String get dashboard_trips_label_trips => 'Trips';

  @override
  String get dashboard_trips_label_distance => 'Distance';

  @override
  String get dashboard_trips_label_time => 'Drive Time';

  @override
  String get dashboard_trips_no_data => 'No trips recorded this week';

  @override
  String get dashboard_trips_unavailable => 'Start driving to see stats';

  @override
  String get dashboard_trips_loading => 'Loading…';

  @override
  String get dashboard_trips_view_all => 'View all trips';

  @override
  String get dashboard_action_live => 'Live';

  @override
  String get dashboard_action_live_subtitle => 'Open camera view';

  @override
  String get dashboard_action_recordings => 'Recordings';

  @override
  String get dashboard_action_settings => 'Settings';

  @override
  String get dashboard_action_settings_subtitle => 'Preferences and about';

  @override
  String get settings_hero_title => 'Settings';

  @override
  String get settings_hero_overline => 'BLADEWATCH';

  @override
  String get settings_hero_subtitle =>
      'Tune appearance, recording, surveillance, and on-device data.';

  @override
  String get settings_overline_preferences => 'PREFERENCES';

  @override
  String get settings_overline_about_data => 'DATA';

  @override
  String get settings_quick_theme_label => 'Theme';

  @override
  String get settings_quick_language_label => 'Language';

  @override
  String get settings_section_recording_subtitle =>
      'Pre/post buffers, codec, storage limits.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Schedule, motion sensitivity, object detection.';

  @override
  String get settings_section_daemons_subtitle =>
      'Tor tunnel and background services.';

  @override
  String get settings_about_row_title => 'About BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Version, license, support development.';

  @override
  String get settings_reset_row_subtitle =>
      'Clear recordings, events, or all caches.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Theme, language, and visual preferences.';

  @override
  String get settings_theme_active_auto_caption =>
      'Auto follows your system theme.';

  @override
  String get settings_theme_active_light_caption => 'Light theme is always on.';

  @override
  String get settings_theme_active_dark_caption => 'Dark theme is always on.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 of $arg2 languages available';
  }

  @override
  String get settings_language_card_title => 'Display language';

  @override
  String get settings_privacy_stance_title => 'On-device by default';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch runs entirely on the head unit. No telemetry leaves your car except via the tunnels and integrations you explicitly configure.';

  @override
  String get settings_privacy_overline_storage => 'LOCAL STORAGE';

  @override
  String get settings_privacy_overline_reset => 'DATA RESET';

  @override
  String get settings_privacy_storage_clips_label => 'Clips on disk';

  @override
  String get settings_privacy_storage_size_label => 'Total size';

  @override
  String get settings_privacy_storage_unavailable => 'Unavailable';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clips',
      one: '$arg1 clip',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Choose categories: recordings, events, service configs, cached telemetry…';

  @override
  String get settings_developer_overline => 'DEVELOPER';

  @override
  String get settings_developer_timing_logs_title => 'Service timing logs';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Log elapsed-time markers during service startup. Disable in normal use to keep logcat clean.';

  @override
  String get settings_developer_debug_logs_title => 'Developer debug logs';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Log all Activity and Fragment lifecycle events and startup steps to /storage/emulated/0/BladeWatch/data/debug_app.log. Crashes are always captured. Off by default.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Camera $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Camera $arg1 (manual)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Probing…';

  @override
  String get diagnostics_camera_value_offline => 'Offline';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Pending data';

  @override
  String diagnostics_battery_value_charge(Object arg1) {
    return '$arg1%';
  }

  @override
  String dashboard_recordings_value_live(Object arg1) {
    return '● $arg1';
  }

  @override
  String dashboard_insight_storage_milestone(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clips · $arg2 recorded',
      one: '$arg1 clip · $arg2 recorded',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Trunk';

  @override
  String get vehicle_tab_climate => 'Climate';

  @override
  String get vehicle_tab_seats => 'Seats';

  @override
  String get vehicle_tab_windows => 'Windows';

  @override
  String get vehicle_tab_lights => 'Lights';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Charging';

  @override
  String get vehicle_locked => 'Locked';

  @override
  String get vehicle_unlocked => 'Unlocked';

  @override
  String get vehicle_range_label => 'Range';

  @override
  String get vehicle_data_unavailable => 'Vehicle data unavailable.';

  @override
  String get vehicle_action_failed =>
      'Action failed. Check vehicle connection.';

  @override
  String get vehicle_open_trunk => 'Open Trunk';

  @override
  String get vehicle_close_trunk => 'Close Trunk';

  @override
  String get vehicle_trunk_info_open =>
      'Opening the trunk will unlock the car first.';

  @override
  String get vehicle_ac_on => 'AC On';

  @override
  String get vehicle_ac_off => 'AC Off';

  @override
  String get vehicle_max_cooling_on => 'Max Cooling: ON';

  @override
  String get vehicle_max_cooling_off => 'Max Cooling: OFF';

  @override
  String get vehicle_screen_on => 'Screen: ON';

  @override
  String get vehicle_screen_off => 'Screen: OFF';

  @override
  String get vehicle_media_volume_label => 'Media Volume';

  @override
  String get vehicle_media_mute => 'Mute';

  @override
  String get vehicle_media_muted => 'Muted';

  @override
  String get vehicle_front_defrost => 'Front Defrost';

  @override
  String get vehicle_rear_defrost => 'Rear Defrost';

  @override
  String get vehicle_temp_label => 'Temperature';

  @override
  String get vehicle_fan_speed_label => 'Fan Speed';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Level $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return 'Inside: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => 'Driver';

  @override
  String get vehicle_seat_passenger => 'Passenger';

  @override
  String get vehicle_seat_no_controls =>
      'No seat controls available for this vehicle.';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return 'Heat $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return 'Cool $arg1';
  }

  @override
  String get vehicle_heat_off => '(Off)';

  @override
  String get vehicle_heat_low => '(Low)';

  @override
  String get vehicle_heat_high => '(High)';

  @override
  String get vehicle_seat_pos_1 => 'Pos 1';

  @override
  String get vehicle_seat_pos_2 => 'Pos 2';

  @override
  String get vehicle_all_windows => 'All Windows';

  @override
  String get vehicle_window_awake_note => 'Works only while the car is awake.';

  @override
  String get vehicle_window_front_left => 'Front Left';

  @override
  String get vehicle_window_front_right => 'Front Right';

  @override
  String get vehicle_window_rear_left => 'Rear Left';

  @override
  String get vehicle_window_rear_right => 'Rear Right';

  @override
  String get vehicle_window_close => 'Close';

  @override
  String get vehicle_window_close_vent => 'Close Vent';

  @override
  String get vehicle_window_vent_12 => 'Vent 12%';

  @override
  String get vehicle_window_open_all => 'Open All';

  @override
  String get vehicle_sunroof => 'Sunroof';

  @override
  String get vehicle_sunshade => 'Sunshade';

  @override
  String get vehicle_btn_drl_title => 'Daytime running lights';

  @override
  String get vehicle_btn_slw_title => 'Speed limit warning';

  @override
  String get vehicle_control_section_charge_cap => 'Charge limit';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Charge cap is not supported by this vehicle.';

  @override
  String get vehicle_charge_limit_label => 'Charge Limit';

  @override
  String get vehicle_enable_charge_limit => 'Enable Charge Limit';

  @override
  String get vehicle_charge_limit_range => 'Minimum 50%, maximum 100%';

  @override
  String get vehicle_tyre_no_signal => 'NO SIGNAL';

  @override
  String get vehicle_tyre_slow_leak => 'SLOW LEAK';

  @override
  String get vehicle_tyre_fast_leak => 'FAST LEAK';

  @override
  String get vehicle_tyre_low => 'LOW';

  @override
  String get vehicle_tyre_high => 'HIGH';

  @override
  String get vehicle_tyre_ok => 'OK';

  @override
  String get vehicle_tyre_check_pressure => 'Check pressure';

  @override
  String get vehicle_toggle_on => 'ON';

  @override
  String get vehicle_toggle_off => 'OFF';

  @override
  String get vehicle_err_climate_control => 'Climate control failed.';

  @override
  String get vehicle_err_max_cooling => 'Max cooling failed.';

  @override
  String get vehicle_err_drl_control => 'DRL control failed.';

  @override
  String get vehicle_err_slw_control => 'ADAS control failed.';

  @override
  String get vehicle_err_charge_limit_toggle => 'Charge limit toggle failed.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Decrease $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Increase $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Connecting…';

  @override
  String get vehicle_appearance_model_title => 'Select Model';

  @override
  String get vehicle_appearance_custom_color => 'Custom color';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Charge: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Range: $arg1 km';
  }

  @override
  String vehicle_status_fuel_fmt(Object arg1) {
    return 'Fuel: $arg1%';
  }

  @override
  String vehicle_status_fuel_range_fmt(Object arg1) {
    return 'Fuel range: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Charge: —';

  @override
  String get vehicle_status_range_unknown => 'Range: —';

  @override
  String get startup_subtitle => 'Getting your dashcam ready';

  @override
  String get startup_header_preparing => 'Getting things ready…';

  @override
  String get startup_header_starting => 'Starting up…';

  @override
  String get startup_header_verifying => 'Almost ready…';

  @override
  String get startup_header_ready => 'Everything\'s ready';

  @override
  String get startup_daemon_camera => 'Camera';

  @override
  String get startup_daemon_camera_desc => 'Live view & recording';

  @override
  String get startup_daemon_sentry => 'Sentry Mode';

  @override
  String get startup_daemon_sentry_desc => 'Motion detection & alerts';

  @override
  String get startup_daemon_parking => 'Parking Guard';

  @override
  String get startup_daemon_parking_desc => 'Keeps watch while parked';

  @override
  String get startup_status_waiting => 'Waiting';

  @override
  String get startup_status_starting => 'Starting';

  @override
  String get startup_status_ready => 'Ready';

  @override
  String get startup_status_failed => 'Failed';

  @override
  String get startup_continue_anyway => 'Continue anyway';

  @override
  String get startup_continue => 'Continue →';

  @override
  String get live_retry => 'Retry';

  @override
  String get live_connecting => 'Connecting to camera…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Error: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Camera unavailable\n$arg1';
  }

  @override
  String get live_direction_all => 'All';

  @override
  String get live_direction_front => 'Front';

  @override
  String get live_direction_right => 'Right';

  @override
  String get live_direction_rear => 'Rear';

  @override
  String get live_direction_left => 'Left';

  @override
  String get trip_no_route_data => 'No route data for this trip';

  @override
  String get trips_tab_trips => 'Trips';

  @override
  String get trips_tab_stats => 'Stats';

  @override
  String get trips_tab_storage => 'Storage';

  @override
  String get trips_filter_7_days => '7 Days';

  @override
  String get trips_filter_14_days => '14 Days';

  @override
  String get trips_filter_30_days => '30 Days';

  @override
  String trips_load_error(Object message) {
    return 'Error: $message';
  }

  @override
  String get trips_empty_state => 'No trips recorded yet';

  @override
  String get trips_period_summary_title => 'Period Summary';

  @override
  String get trips_stat_trips => 'Trips';

  @override
  String get trips_stat_hours => 'Hours';

  @override
  String get trips_stat_efficiency => 'Efficiency';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Score: $score';
  }

  @override
  String get trips_driver_score_title => 'Driver Score';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Overall: $score / 100';
  }

  @override
  String get trips_range_title => 'Personalized Range';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD estimate: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'Fuel range: $km';
  }

  @override
  String get trips_range_no_data => 'Not enough data yet';

  @override
  String get trips_dna_title => 'Driving DNA';

  @override
  String get trips_dna_anticipation => 'Anticipation';

  @override
  String get trips_dna_smoothness => 'Smoothness';

  @override
  String get trips_dna_speed_discipline => 'Speed Discipline';

  @override
  String get trips_dna_efficiency => 'Efficiency';

  @override
  String get trips_dna_consistency => 'Consistency';

  @override
  String get trips_storage_title => 'Trip Storage';

  @override
  String get trips_storage_analytics_label => 'Trip Analytics';

  @override
  String get trips_storage_rate_label => 'Electricity Rate';

  @override
  String get trips_storage_fuel_price_label => 'Fuel Price (per litre)';

  @override
  String get trips_storage_tank_capacity_label => 'Fuel Tank Capacity (litres)';

  @override
  String get trips_storage_distance_unit_label => 'Distance Unit';

  @override
  String get trips_storage_location_label => 'Storage Location';

  @override
  String get trips_storage_internal => 'Internal';

  @override
  String get trips_storage_sd_card => 'SD Card';

  @override
  String get trips_storage_sd_card_unavailable => 'SD Card (N/A)';

  @override
  String get trips_storage_apply => 'Apply Changes';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit used / $limit MB limit · $count trips';
  }

  @override
  String get trips_sync_title => 'Database Catalog';

  @override
  String get trips_sync_description =>
      'Reconcile the trips index with telemetry files on disk.';

  @override
  String get trips_sync_button => 'Sync Database';

  @override
  String get trips_sync_running => 'Syncing…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Synced successfully: +$added -$removed ($total total)';
  }

  @override
  String get trips_sync_failed_generic => 'Sync failed';

  @override
  String get trips_detail_summary_title => 'Trip Summary';

  @override
  String get trips_detail_distance => 'Distance';

  @override
  String get trips_detail_duration => 'Duration';

  @override
  String get trips_detail_energy => 'Energy';

  @override
  String get trips_detail_avg_speed => 'Avg Speed';

  @override
  String get trips_detail_max_speed => 'Max Speed';

  @override
  String get trips_detail_soc => 'SoC';

  @override
  String get trips_detail_cost => 'Cost';

  @override
  String get trips_detail_ext_temp => 'Ext Temp';

  @override
  String get trips_detail_fuel_used => 'Fuel Used';

  @override
  String get trips_detail_fuel_cost => 'Fuel Cost';

  @override
  String get trips_detail_electric_cost => 'Electric Cost';

  @override
  String get trips_detail_elev_gain => 'Elev Gain';

  @override
  String get trips_detail_scores_title => 'Driving Scores';

  @override
  String get trips_detail_unavailable => 'Trip details unavailable';

  @override
  String get trips_detail_loading => 'Loading trip…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count GPS points recorded';
  }

  @override
  String get rec_severity_critical => 'CRITICAL';

  @override
  String get rec_severity_alert => 'ALERT';

  @override
  String get location_loading_title => 'Loading map';

  @override
  String get location_permission_missing_title =>
      'Location permission required';

  @override
  String get location_permission_denied_title => 'Permission denied';

  @override
  String get location_provider_disabled_title => 'GPS disabled';

  @override
  String get location_waiting_for_fix_title => 'Waiting for GPS fix';

  @override
  String get location_car_location_title => 'Car location';

  @override
  String get location_stale_title => 'Location stale';

  @override
  String get location_tile_failure_title => 'Map unavailable';

  @override
  String get location_tile_failure_subtitle => 'Network unavailable';

  @override
  String get location_error_title => 'Location error';

  @override
  String get location_action_grant => 'Grant';

  @override
  String get location_action_retry => 'Retry';

  @override
  String get location_mode_auto => 'Auto';

  @override
  String get location_mode_light => 'Light';

  @override
  String get location_mode_dark => 'Dark';

  @override
  String get cd_recenter_on_car => 'Recenter on car';

  @override
  String get recording_lib_no_recordings_normal => 'No normal recordings';

  @override
  String get recording_lib_no_recordings_sentry => 'No sentry events';

  @override
  String get recording_lib_no_recordings_proximity => 'No proximity events';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'person';

  @override
  String get video_player_legend_car => 'car';

  @override
  String get video_player_legend_bike => 'bike';

  @override
  String get video_player_legend_motion => 'motion';

  @override
  String get recording_lib_proximity_very_close => 'very close';

  @override
  String get recording_lib_proximity_close => 'close';

  @override
  String get recording_lib_proximity_mid => 'mid';

  @override
  String get recording_lib_proximity_far => 'far';

  @override
  String get surveillance_tab_general => 'General';

  @override
  String get surveillance_tab_detection => 'Detection';

  @override
  String get surveillance_tab_recording => 'Recording';

  @override
  String get surveillance_tab_storage => 'Storage';

  @override
  String get surveillance_tab_advanced => 'Advanced';

  @override
  String get surveillance_general_title => 'Surveillance Mode';

  @override
  String get surveillance_general_enable => 'Enable Surveillance';

  @override
  String get surveillance_general_status => 'Status';

  @override
  String get surveillance_general_status_running => 'Running';

  @override
  String get surveillance_general_status_idle => 'Idle';

  @override
  String get surveillance_general_events_today => 'Events Today';

  @override
  String get surveillance_safe_locations_title => 'Safe Locations';

  @override
  String get surveillance_safe_locations_subtitle =>
      'Camera won\'t start when parked here';

  @override
  String get surveillance_safe_locations_enable => 'Disable at Safe Locations';

  @override
  String get surveillance_safe_locations_empty => 'No safe locations added yet';

  @override
  String get surveillance_safe_locations_add_current =>
      'Add Current Location as Safe Zone';

  @override
  String get surveillance_safe_locations_no_gps => 'GPS location not available';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Detection Settings';

  @override
  String get surveillance_detection_preset_label => 'Environment Preset';

  @override
  String get surveillance_preset_outdoor => 'Outdoor';

  @override
  String get surveillance_preset_garage => 'Garage';

  @override
  String get surveillance_preset_street => 'Street';

  @override
  String get surveillance_preset_custom => 'Custom';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Sensitivity (1=strict, 5=sensitive): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Detect Objects';

  @override
  String get surveillance_detection_object_person => 'Person';

  @override
  String get surveillance_detection_object_car => 'Car';

  @override
  String get surveillance_detection_object_bike => 'Bike';

  @override
  String get surveillance_recording_title => 'Event Recording';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Pre-record (seconds before event): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Post-record (seconds after event): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Surveillance Storage';

  @override
  String get surveillance_storage_location_label => 'Storage Location';

  @override
  String get surveillance_storage_internal => 'Internal';

  @override
  String get surveillance_storage_sd_card => 'SD Card';

  @override
  String get surveillance_storage_sd_card_na => 'SD Card (N/A)';

  @override
  String get surveillance_storage_limit_label =>
      'Storage Limit — auto-deletes oldest when reached';

  @override
  String get surveillance_storage_usage_label => 'Storage Usage';

  @override
  String get surveillance_storage_files_label => 'Files';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 used / $arg2 limit';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 events',
      one: '$arg1 event',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'Path';

  @override
  String get surveillance_format_title => 'Format External Drive';

  @override
  String get surveillance_format_warning =>
      'Permanently erases ALL data on the SD card or USB drive.';

  @override
  String get surveillance_format_button => 'Format SD Card / USB';

  @override
  String get surveillance_format_confirm =>
      'Tap again — ALL data will be ERASED';

  @override
  String get surveillance_format_running => 'Formatting… please wait';

  @override
  String get surveillance_dismiss => 'Dismiss';

  @override
  String get surveillance_sync_title => 'Database Catalog';

  @override
  String get surveillance_sync_description =>
      'Reconcile the surveillance index with files on disk.';

  @override
  String get surveillance_sync_button => 'Sync Database';

  @override
  String get surveillance_sync_running => 'Syncing…';

  @override
  String get surveillance_advanced_camera_title => 'Camera Selection';

  @override
  String get surveillance_advanced_camera_front => 'Front';

  @override
  String get surveillance_advanced_camera_right => 'Right';

  @override
  String get surveillance_advanced_camera_rear => 'Rear';

  @override
  String get surveillance_advanced_camera_left => 'Left';

  @override
  String get surveillance_advanced_ai_title => 'AI & Deterrent';

  @override
  String get surveillance_advanced_ai_detection => 'AI Detection';

  @override
  String get surveillance_advanced_night_mode => 'Night Mode';

  @override
  String get surveillance_advanced_deterrent_label => 'Deterrent Action';

  @override
  String get surveillance_deterrent_silent => 'Silent';

  @override
  String get surveillance_deterrent_horn => 'Horn';

  @override
  String get surveillance_deterrent_flash => 'Flash';

  @override
  String get surveillance_apply_button => 'Apply Changes';

  @override
  String get surveillance_apply_failed => 'Save failed';

  @override
  String get dashboard_tor_bootstrapping => 'Connecting to Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'How to open this address';

  @override
  String get dashboard_tor_help_title => 'Opening this address';

  @override
  String get dashboard_tor_help_android =>
      'Android: install Tor Browser from Google Play or F-Droid, open it and paste the address.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone and iPad: install Onion Browser from the App Store, open it and paste the address. Tor Browser itself is not available on iOS.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS and Linux: download Tor Browser from torproject.org, open it and paste the address.';

  @override
  String get dashboard_tor_help_password_note =>
      'You will still need the password after the page loads.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'Scan for the Tor Browser download page';

  @override
  String get dashboard_tor_help_close => 'Got it';

  @override
  String get surveillance_general_battery_warning =>
      'Sentry mode uses extra 12V battery power while armed.';

  @override
  String get surveillance_general_camera_contention_warning =>
      'Another app is using the camera right now.';

  @override
  String get pairing_title => 'Pair a device';

  @override
  String get pairing_scan_hint =>
      'Scan with the BladeWatch app on your phone or computer. The code works once.';

  @override
  String pairing_expires_in(String time) {
    return 'Expires in $time';
  }

  @override
  String get pairing_expired => 'This code has expired.';

  @override
  String get pairing_new_code => 'New code';

  @override
  String get pairing_remote_note =>
      'Pairing turns on remote access for this car.';

  @override
  String get pairing_lan_title => 'Direct connection on this Wi-Fi';

  @override
  String get pairing_lan_body =>
      'A paired device on the same Wi-Fi as the car connects to it directly and encrypted, without going through the internet. Off unless you turn it on.';

  @override
  String get pairing_devices_title => 'Paired devices';

  @override
  String get pairing_devices_empty => 'No devices paired yet.';

  @override
  String get pairing_remove => 'Remove';

  @override
  String pairing_remove_confirm_title(String name) {
    return 'Remove $name?';
  }

  @override
  String get pairing_remove_confirm_body =>
      'It loses access right away. Your other devices keep working.';

  @override
  String get pairing_error => 'The camera service did not respond. Try again.';

  @override
  String get daemon_name_pear => 'Remote access (Pear)';

  @override
  String get pear_status_reachable => 'Reachable from anywhere';

  @override
  String get pear_status_unreachable =>
      'Not reachable: no connection to the Pear network';

  @override
  String get pear_status_unknown => 'Reachability unknown';

  @override
  String pear_devices_connected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices connected',
      one: '$count device connected',
      zero: 'No devices connected',
    );
    return '$_temp0';
  }

  @override
  String pear_last_connection(String time) {
    return 'Last connection: $time';
  }

  @override
  String get pear_tile_off => 'Off';
}
