// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Übertragung von Fahrzeugüberwachung im Hintergrund aktiviert. Dieser Dienst liest und interagiert nicht mit Bildschirminhalten.';

  @override
  String get action_cancel => 'Abbrechen';

  @override
  String get action_clear_plain => 'Leeren';

  @override
  String get action_select_all => 'Wählen Sie alle aus';

  @override
  String get action_select_all_short => 'Alle';

  @override
  String get action_delete => 'Löschen';

  @override
  String get action_done => 'FERTIG';

  @override
  String get action_remind_me_later => 'SPÄTER ERINNERN';

  @override
  String get action_retry => 'Erneut versuchen';

  @override
  String get action_run => 'Ausführen';

  @override
  String get action_clear_output => 'Ausgabe löschen';

  @override
  String get cd_camera => 'Kamera';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR-Code';

  @override
  String get cd_clear_logs => 'Protokoll löschen';

  @override
  String get cd_expand_collapse => 'Aus-/Einklappen';

  @override
  String get cd_recording_status => 'Aufzeichnungsstatus';

  @override
  String get cd_trip_tracking_status => 'Status der Reiseverfolgung';

  @override
  String get cd_video_thumbnail => 'Video-Miniaturansicht';

  @override
  String get cd_play => 'Abspielen';

  @override
  String get cd_back => 'Zurück';

  @override
  String get cd_play_pause => 'Wiedergabe/Pause';

  @override
  String get cd_player_prev => 'Vorherige Aufnahme';

  @override
  String get cd_player_next => 'Nächste Aufnahme';

  @override
  String get cd_player_maximize => 'Player maximieren';

  @override
  String get cd_player_minimize => 'Vollbild beenden';

  @override
  String get cd_delete => 'Löschen';

  @override
  String get cd_decrease => 'Verringern';

  @override
  String get cd_increase => 'Erhöhen';

  @override
  String get cd_expand => 'Ausklappen';

  @override
  String get cd_configure => 'Konfigurieren';

  @override
  String get cd_download_log => 'Download-Log';

  @override
  String get cd_reset => 'Zurücksetzen';

  @override
  String get cd_battery => 'Batterie';

  @override
  String get cd_step_completed => 'Schritt abgeschlossen';

  @override
  String get cd_permission_granted => 'Berechtigung erteilt';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'PROZESSE';

  @override
  String get logs_panel_title => 'Schlagzeilen';

  @override
  String get url_connecting => 'Verbindung wird hergestellt…';

  @override
  String get camera_selection_title => 'Auswahl der Kamera';

  @override
  String get camera_selection_subtitle =>
      'Wählen Sie die Panorama-Kameraquelle aus';

  @override
  String get camera_current_auto => 'Derzeit: Auto';

  @override
  String get camera_option_auto => 'Automatisiert (aufgerufene Erkennung)';

  @override
  String get camera_option_0 => 'Kamera 0 — Atto Ausstattung';

  @override
  String get camera_option_1 => 'Kamera 1 — Seal (Standard)';

  @override
  String get camera_option_2 => 'Kamera 2';

  @override
  String get camera_option_3 => 'Kamera 3';

  @override
  String get camera_option_4 => 'Kamera 4';

  @override
  String get camera_option_5 => 'Kamera 5';

  @override
  String get camera_selection_hint =>
      'Auto wählt bei jedem Start die passende Kamera für Ihre Ausstattung. Kamera 1 = BYD Seal, Kamera 0 = Atto-Ausstattungen. Starten Sie den Kameradienst nach einer Änderung der Kamera-ID neu, damit die Einstellung wirksam wird.';

  @override
  String get dashboard_qr_waiting => 'Warten auf den Tunnel …';

  @override
  String get dashboard_daemons_running_default => '0/5 aktiv';

  @override
  String get dashboard_regenerate_token => 'Token neu generieren';

  @override
  String get cd_set_password => 'Eigenes Passwort festlegen';

  @override
  String get toast_password_save_failed =>
      'Passwort konnte nicht gespeichert werden — Dienst nicht bereit';

  @override
  String get setup_guide_title => 'Der Anfang';

  @override
  String get setup_guide_subtitle =>
      'Drei schnelle Schritte zur besten Erfahrung:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Wählen Sie Ihre Sprache aus';

  @override
  String get setup_language_body =>
      'Standardmäßig die Sprache Ihrer Haupteinheit. Tippen Sie, um eine andere für die BladeWatch-App und den Web-Tunnel zu wählen.';

  @override
  String get setup_language_button => 'Wählen Sie die Sprache aus';

  @override
  String get setup_autostart_title =>
      'Deaktivieren Sie die Autostart-Beschränkung';

  @override
  String get setup_autostart_body =>
      'Tippen Sie unten, um BYD Auto-Start zu öffnen, und entfernen Sie die Haken bei BladeWatch UND BladeWatch-Dienst. Ohne dies startet die Aufnahme beim Einschalten des Fahrzeugs nicht — Sie müssen die App jedes Mal öffnen. BYD setzt dies bei jeder Installation zurück.';

  @override
  String get setup_autostart_button => 'Öffnen Sie BYD Auto-Start';

  @override
  String get setup_overlay_title => 'Erlauben Sie die Anzeige über andere Apps';

  @override
  String get setup_overlay_body =>
      'Aktivieren Sie dies, um einen schwimmenden Statusindikator für Aufzeichnung und Reiseverfolgung auf anderen Apps anzuzeigen.';

  @override
  String get setup_overlay_button =>
      'Öffnen Sie die Überlagerungseinstellungen';

  @override
  String get cd_close => 'Schließen';

  @override
  String get language_picker_title => 'Sprache';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '$arg1 verfügbare Sprachen';
  }

  @override
  String get language_picker_subtitle_pending => 'Wählen Sie eine Sprache';

  @override
  String get language_auto_title => 'Automatisiert';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Folgsystem · $arg1';
  }

  @override
  String get language_not_saved =>
      'Sprache übernommen, aber nicht gespeichert — sie wird beim Neustart zurückgesetzt.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Automatisch';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Geben Sie den Befehl ein...';

  @override
  String get adb_preset_commands_header => 'Vordefinierte Befehle';

  @override
  String get adb_output_header => 'Ausgabe';

  @override
  String get adb_output_ready => '\$ Bereit für Befehle...';

  @override
  String get adb_console_hero_title => 'ADB-Konsole';

  @override
  String get adb_console_hero_subtitle =>
      'Führen Sie Shell-Befehle auf dem Gerät aus';

  @override
  String get adb_console_unavailable_title => 'ADB ist nicht verbunden';

  @override
  String get adb_console_unavailable_body =>
      'Bei diesem Fahrzeug reicht der normale „USB-Debugging“-Schalter in den Entwickleroptionen allein nicht aus — die kabellose ADB-Funktion (Netzwerk-Debugging) des Head-Units muss ebenfalls aktiviert sein, und ein Systemupdate kann sie zurücksetzen. Aktivieren Sie kabelloses ADB am Head-Unit erneut oder verbinden Sie sich per USB.';

  @override
  String get adb_console_auth_pending_title => 'Warten auf Bestätigung';

  @override
  String get adb_console_auth_pending_body =>
      'Prüfen Sie den Bildschirm des Head-Units auf die Meldung „USB-Debugging zulassen?“ und bestätigen Sie sie, dann erneut versuchen.';

  @override
  String get performance_connecting => 'Verbindung zum Leistungsmonitor…';

  @override
  String get performance_hero_title => 'Systemleistung';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'System-Auslastung';

  @override
  String get performance_cpu_app_usage => 'App-Auslastung';

  @override
  String get performance_frequency_label => 'Frequenz';

  @override
  String get performance_temperature_label => 'Temperatur';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Speicher';

  @override
  String get performance_usage_label => 'Auslastung';

  @override
  String get performance_memory_total => 'Gesamt';

  @override
  String get performance_memory_used => 'Belegt';

  @override
  String get performance_memory_app => 'App';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'App-Prozess';

  @override
  String get performance_threads_label => 'Threads';

  @override
  String get performance_gc_cycles_label => 'GC-Zyklen';

  @override
  String get performance_open_fds_label => 'Offene FDs';

  @override
  String get performance_refreshing_footer => 'Aktualisierung alle 3 Sekunden';

  @override
  String get webview_loading => 'Lade...';

  @override
  String get reset_title => 'Daten zurücksetzen';

  @override
  String get reset_subtitle =>
      'Löschen der angesammelten Daten nach Kategorien';

  @override
  String get reset_warning =>
      'Dies kann nicht rückgängig gemacht werden. Aufnahmen, Fahrten und Batterieverlauf werden dauerhaft gelöscht.';

  @override
  String get reset_cat_trips => 'Fahrten';

  @override
  String get reset_cat_trips_desc =>
      'Fahrgeschichte, Routen, wöchentliche/monatliche Aufnahmen';

  @override
  String get reset_cat_soc_history => 'SoC & 12V-Geschichte';

  @override
  String get reset_cat_soc_history_desc =>
      'SoC-Proben, Ladevorgänge, Spannungsprotokolle';

  @override
  String get reset_cat_recordings => 'Aufnahmen (Videos)';

  @override
  String get reset_cat_recordings_desc =>
      'Alle MP4-Dateien im Ordner der Aufnahmen';

  @override
  String get reset_cat_sentry_events => 'Überwachungsereignisse';

  @override
  String get reset_cat_sentry_events_desc =>
      'Clips von Überwachungsereignissen und zugehörige JSON-Dateien';

  @override
  String get reset_cat_proximity => 'Nähere Aufzeichnungen';

  @override
  String get reset_cat_proximity_desc => 'Radar-ausgelöste MP4-Ereignisse';

  @override
  String get reset_cat_trip_files => 'Fahrt-Telemetrie-Dateien';

  @override
  String get reset_cat_trip_files_desc =>
      'Fernmessung per Reise JSON auf Festplatte';

  @override
  String get recording_lib_chip_any => 'Alle';

  @override
  String get recording_lib_chip_person => 'Person';

  @override
  String get recording_lib_chip_vehicle => 'Fahrzeug';

  @override
  String get recording_lib_chip_bike => 'Fahrrad';

  @override
  String get recording_lib_chip_animal => 'Tiere';

  @override
  String get recording_lib_chip_alert => 'Warnung';

  @override
  String get recording_lib_chip_critical => 'Kritisch';

  @override
  String get recording_lib_selected_count_zero => '0 ausgewählt';

  @override
  String get recording_lib_no_recordings => 'Keine Aufnahmen';

  @override
  String get recording_lib_filter_button => 'Filter';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filter · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Aufnahmen filtern';

  @override
  String get recording_lib_filter_apply => 'Anwenden';

  @override
  String get recording_lib_filter_reset => 'Zurücksetzen';

  @override
  String get recording_lib_filter_section_what => 'Was';

  @override
  String get recording_lib_filter_section_severity => 'Schweregrad';

  @override
  String get recording_lib_filter_section_type => 'Art';

  @override
  String get recording_lib_chip_type_normal => 'Normal';

  @override
  String get recording_lib_chip_type_proximity => 'Nähe';

  @override
  String get recording_lib_date_today => 'Heute';

  @override
  String get recording_lib_date_yesterday => 'Gestern';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 Clips',
      one: '$arg1 Clip',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Datum wählen';

  @override
  String get recording_lib_date_all_days => 'Alle Tage';

  @override
  String get cd_clear_date_filter => 'Alle Tage anzeigen';

  @override
  String get recording_lib_section_morning => 'Vormittag';

  @override
  String get recording_lib_section_afternoon => 'Nachmittag';

  @override
  String get recording_lib_section_evening => 'Abend';

  @override
  String get recording_lib_section_night => 'Nacht';

  @override
  String get cd_previous_day => 'Vorheriger Tag';

  @override
  String get cd_next_day => 'Nächster Tag';

  @override
  String get cd_open_filters => 'Filter öffnen';

  @override
  String get cd_clear_filter => 'Filter löschen';

  @override
  String get player_title_recording => 'Aufzeichnung';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Kamera-Dienst';

  @override
  String get daemon_name_surveillance => 'Überwachungsdienst';

  @override
  String get daemon_name_acc => 'ACC-Überwachung';

  @override
  String get daemons_hero_title => 'Hintergrunddienste';

  @override
  String get daemons_count_pending => 'Dienste werden geladen…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 von $arg2 laufen';
  }

  @override
  String get battery_health_title => 'Batteriengesundheit';

  @override
  String get battery_health_unavailable => 'Nicht verfügbar';

  @override
  String get battery_health_unavailable_desc =>
      'Die Schätzung des Batteriezustands ist nicht verfügbar.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% auf $arg2';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Löschte Aufnahmen von $arg1',
      one: 'Aufzeichnung $arg1 gelöscht',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Löschen Sie $arg1 Aufnahmen',
      one: 'Löschen Sie die Aufzeichnung $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'Dies löscht $arg1 Aufnahmen dauerhaft. Dies kann nicht rückgängig gemacht werden.',
      one:
          'Dies löscht $arg1 Aufnahme dauerhaft. Dies kann nicht rückgängig gemacht werden.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'Die App ist aktuell (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Speicherberechtigung für Aufnahmen erforderlich';

  @override
  String get toast_url_copied_short => 'URL kopiert!';

  @override
  String get toast_camera_set_to_auto => 'Kamera auf Auto eingestellt';

  @override
  String get toast_failed_to_save_short => 'Nicht gerettet';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Versagt: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Kamera $arg1 eingestellt — nächster ACC-Zyklus';
  }

  @override
  String get toast_clearing_camera_config =>
      'Kamerakonfiguration wird gelöscht…';

  @override
  String get toast_restarting_camera_daemon =>
      'Kameradienst wird neu gestartet...';

  @override
  String get toast_camera_daemon_restarting =>
      'Kameradienst wird mit vollständiger Erkennung neu gestartet';

  @override
  String get toast_camera_restart_failed =>
      'Konfiguration gelöscht, aber Neustart des Dienstes fehlgeschlagen. Bitte manuell neu starten.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Versagt: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'Wählen Sie mindestens eine Kategorie aus';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Zurücksetzungsfehler: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 Verkehrsmonitor...';
  }

  @override
  String get dialog_close => 'Schließen';

  @override
  String get dialog_reset => 'Zurücksetzen';

  @override
  String get dialog_delete => 'Löschen';

  @override
  String get dialog_save => 'Speichern';

  @override
  String get dialog_enable => 'Aktivieren';

  @override
  String get dialog_disable => 'Deaktivieren';

  @override
  String get dialog_keep_enabled => 'Aktiviert lassen';

  @override
  String get dialog_keep_disabled => 'Deaktiviert lassen';

  @override
  String get dialog_regenerate => 'Neu generieren';

  @override
  String get dialog_reset_selected => 'Ausgewählte zurücksetzen';

  @override
  String get dialog_reset_following_title => 'Folgendes zurücksetzen?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Dies kann nicht rückgängig gemacht werden.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Zurücksetzen abgeschlossen';

  @override
  String get dialog_traffic_cannot_check_title => 'Status nicht überprüfen';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB ist nicht verbunden, und die App konnte die Verbindung nicht automatisch wiederherstellen.\n\nAuf diesem Fahrzeug reicht der übliche Schalter \"USB-Debugging\" in den Entwickleroptionen allein nicht aus – die eigene WLAN-ADB-Einstellung (Netzwerk-Debugging) des Infotainmentsystems muss ebenfalls aktiviert sein, und ein System-Update kann sie zurücksetzen. Aktivieren Sie WLAN-ADB am Infotainmentsystem erneut, oder verbinden Sie sich per USB.\n\nDer Status wird automatisch aktualisiert, sobald die Verbindung besteht.';

  @override
  String get dialog_traffic_disable_title =>
      'BYD Verkehrsüberwachung deaktivieren?';

  @override
  String get dialog_traffic_disable_message =>
      'Der BYD Traffic Monitor (com.byd.trafficmonitor) ist eine integrierte System-App, die im Hintergrund fortlaufend die Verkehrslage überwacht.\n\nWarum deaktivieren?\n\n• Verbraucht mobile Daten (auch im geparkten Zustand)\n• Belegt CPU und Akku im Hintergrund\n• Nicht nötig, wenn Sie eine separate Navigations-App nutzen\n• Kann die Netzwerknutzung der Dashcam stören\n\nDas Deaktivieren ist unbedenklich — es betrifft nur die eingebaute Verkehrsanzeige auf der Karte. Navigation, Bluetooth und alle übrigen Fahrzeugfunktionen bleiben unberührt.\n\nNach dem Deaktivieren ist ein harter Neustart nötig (Taste der Mittelkonsole 5 Sekunden halten).';

  @override
  String get dialog_traffic_enable_title =>
      'BYD Verkehrsmonitor wieder aktivieren?';

  @override
  String get dialog_traffic_enable_message =>
      'Der BYD-Verkehrsmonitor ist derzeit deaktiviert.\n\nWenn er erneut aktiviert wird, wird die eingebaute Verkehrsüberlagerung auf der Navigationskarte wiederhergestellt. Beachten Sie, dass er im Hintergrund ausgeführt und mobile Daten verbraucht.\n\nNach aktiviert wird ein harter Neustart erforderlich (Halt die Zentrum-Konsole-Schaltfläche 5 Sekunden).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Verkehrsüberwachung $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'Die Änderung wurde angewendet. Bitte führen Sie jetzt einen harten Neustart aus: Drücken Sie und halten Sie den Knopf der zentralen Konsole für 5 Sekunden fest.';

  @override
  String get traffic_monitor_loading => 'Verkehrsüberwachung: Überprüfung...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Verkehrsüberwachung (Taste zum Überprüfen)';

  @override
  String get reset_label_trips => 'Fahrten';

  @override
  String get reset_label_soc_history => 'SoC + 12V-Geschichte';

  @override
  String get reset_label_recordings => 'Aufnahmen';

  @override
  String get reset_label_sentry_events => 'Überwachungsereignisse';

  @override
  String get reset_label_proximity => 'Nähere Aufzeichnungen';

  @override
  String get reset_label_trip_files => 'Fahrt-Telemetrie-Dateien';

  @override
  String get dialog_regenerate_token_title => 'Token neu generieren';

  @override
  String get dialog_regenerate_token_message =>
      'Damit wird das aktuelle Token ungültig. Alle aktiven Sitzungen werden abgemeldet. Fortfahren?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Neues Token generiert. Alle Sitzungen abgemeldet.';

  @override
  String get toast_token_regenerated_restart =>
      'Token erneuert. Dienste müssen möglicherweise neu gestartet werden.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token erneuert. Hintergrunddienst konnte nicht benachrichtigt werden.';

  @override
  String get toast_token_regenerated => 'Wiederhergestellte Token';

  @override
  String get dashboard_waiting_url => 'Warten auf die Tunnel-URL …';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 aktiv';
  }

  @override
  String get clip_label_access_code => 'Zugriffscode';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'Keine Konfiguration für $arg1 erforderlich';
  }

  @override
  String get toast_token_cannot_be_empty => 'Das Token kann nicht leer sein';

  @override
  String toast_fetching_log(Object arg1) {
    return '$arg1-Log wird abgerufen …';
  }

  @override
  String get toast_log_empty_or_missing =>
      'Protokolldatei ist leer oder nicht gefunden';

  @override
  String get toast_log_empty => 'Die Protokolldatei ist leer';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Nicht gespeichert: $arg1';
  }

  @override
  String get toast_log_not_found =>
      'Protokolldatei nicht gefunden oder nicht lesbar';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1 Protokoll – $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Teilen Sie $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 Protokoll ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Quelle: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'Exportiert: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'HINWEIS: Protokoll auf die letzten 10000 Zeilen gekürzt (gesamt: $arg1 Zeilen)',
      one:
          'HINWEIS: Protokoll auf die letzten 10000 Zeilen gekürzt (gesamt: $arg1 Zeile)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Video nicht gespielt: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Aufnahme löschen';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '$arg1 löschen?\nDies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get toast_recording_deleted => 'Aufzeichnung gelöscht';

  @override
  String get toast_recording_delete_failed =>
      'Aufnahme konnte nicht gelöscht werden';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 gelöscht, $arg2 fehlgeschlagen';
  }

  @override
  String get play_with_chooser => 'Spielen Sie mit';

  @override
  String setup_version_banner(Object arg1) {
    return 'Aktualisiert auf v$arg1 — erneut Autostart bestätigen, BYD löscht es bei jeder Installation';
  }

  @override
  String get setup_overlay_already_granted => 'Bereits gewährt';

  @override
  String camera_current_manual(Object arg1) {
    return 'Aktueller: Kamera $arg1 (Manual)';
  }

  @override
  String get camera_current_auto_label => 'Derzeit: Auto';

  @override
  String get soh_estimation_active => 'Schätzungsaktiv';

  @override
  String get soh_oem_readout =>
      'Fahrzeug-SOH-Auslesung — warte auf berechnete Schätzung';

  @override
  String get soh_nominal_baseline =>
      'Nominale Basislinie — warte auf vertrauenswürdige SOH-Daten';

  @override
  String get soh_no_estimate_yet => 'Noch keine Schätzung — Wartung auf Daten';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 ausgewählt';
  }

  @override
  String get video_player_playback_error => 'Wiedergabefehler';

  @override
  String get video_player_no_events => 'Keine Veranstaltungen';

  @override
  String get daemon_configuration_required => 'Konfiguration erforderlich';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Video-Player';

  @override
  String get status_overlay_notif_title => 'BladeWatch Status';

  @override
  String get status_overlay_notif_text => 'Statusüberlagerung aktiv';

  @override
  String get rail_dashboard => 'Übersicht';

  @override
  String get rail_live => 'Live';

  @override
  String get rail_recordings => 'Aufnahmen';

  @override
  String get rail_vehicle => 'Fahrzeug';

  @override
  String get rail_trips => 'Fahrten';

  @override
  String get rail_location => 'Standort';

  @override
  String get rail_diagnostics => 'Diagnostik';

  @override
  String get rail_settings => 'Einstellungen';

  @override
  String get settings_section_appearance => 'Aussehen';

  @override
  String get settings_section_recording => 'Aufzeichnung';

  @override
  String get settings_section_surveillance => 'Überwachung';

  @override
  String get settings_section_daemons => 'Dienste';

  @override
  String get settings_section_privacy => 'Datenschutz und Daten';

  @override
  String get settings_section_trips => 'Fahrten';

  @override
  String get settings_section_trips_subtitle =>
      'Kostensätze, Entfernungseinheit und Speicherort der Fahrten';

  @override
  String get settings_section_overlay => 'Statusüberlagerung';

  @override
  String get settings_overlay_subtitle =>
      'Wählen Sie, welche Segmente der schwimmenden Statuspille sichtbar bleiben.';

  @override
  String get settings_overlay_camera_title => 'Kamera-Anzeige';

  @override
  String get settings_overlay_camera_subtitle =>
      'Anzeigen Sie das REC / PROX-Badge, während die Aufnahme aktiv ist.';

  @override
  String get settings_overlay_trip_title => 'Angabe von Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Zeigen Sie das TRIP-Badge, während die Reiseaufdeckung läuft.';

  @override
  String get settings_section_about => 'Über';

  @override
  String get settings_subrail_overline => 'Einstellungen';

  @override
  String get cd_settings_subrail => 'Einstellungen-Unterleiste';

  @override
  String get settings_privacy_title => 'Datenschutz und Daten';

  @override
  String get settings_privacy_body =>
      'Zurücksetzen löscht den Aufnahmeindex, gespeicherte Anmeldedaten, den Dienststatus und die gerätebezogenen Einstellungen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get settings_about_title => 'Über BladeWatch';

  @override
  String get settings_about_version_label => 'Version';

  @override
  String get settings_about_package_label => 'Bauen Sie';

  @override
  String get settings_about_support_section =>
      'Von Leuten wie dir angetrieben.';

  @override
  String get settings_about_support_share_title =>
      'Sag es einem anderen Besitzer';

  @override
  String get settings_about_support_share_value =>
      'Jeder gemeinsame Link hilft einem anderen BYD-Besitzer, BladeWatch zu entdecken.';

  @override
  String get settings_about_support_share_message =>
      'Überprüfen Sie BladeWatch — Open-Source-Überwachung & Dashcam für BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'Teilen Sie Übertreibung';

  @override
  String get settings_about_open_link_failed =>
      'Link konnte nicht geöffnet werden.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'Keine Browser gefunden. URL kopiert: $arg1';
  }

  @override
  String get settings_about_support_kofi_title =>
      'Brennstoff für die nächste Veröffentlichung';

  @override
  String get settings_about_support_kofi_value =>
      'Ein Kaffee auf Ko-Fi hält die späten Nachtverpflichtungen an.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Lizenz';

  @override
  String get settings_about_license_value =>
      'MIT — Open Source. Tippen Sie, um den vollständigen Text anzuzeigen.';

  @override
  String get settings_about_source_title => 'Quellcode';

  @override
  String get settings_about_source_value =>
      'Github.com/yash-srivastava/BladeWatch-Veröffentlichung';

  @override
  String get settings_about_license_url =>
      'https://github.com/yash-srivastava/BladeWatch-release/blob/main/LICENSE';

  @override
  String get settings_about_source_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_star_title => 'Werfen Sie einen auf GitHub';

  @override
  String get settings_about_star_value => 'Dauert eine Sekunde. Bedeutet viel.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Danke';

  @override
  String get settings_about_thanks_subtitle =>
      'Mit Hilfe von Mitwirkenden und Unterstützern entstanden.';

  @override
  String get settings_about_contributors_title => 'Mitwirkende';

  @override
  String get settings_about_supporters_title => 'Unterstützer';

  @override
  String get settings_about_thanks_empty =>
      'Die Liste füllt sich, sobald jemand mitmacht.';

  @override
  String get settings_theme_label => 'Thema';

  @override
  String get settings_theme_auto => 'Automatisch (Systemeinstellung)';

  @override
  String get settings_theme_light => 'Hell';

  @override
  String get settings_theme_dark => 'Dunkel';

  @override
  String get settings_language_label => 'Sprache';

  @override
  String get settings_drive_side_label => 'Navigationsseite';

  @override
  String get settings_drive_side_subtitle =>
      'Wählen Sie, auf welcher Bildschirmseite das Navigationsmenü erscheint.';

  @override
  String get settings_drive_side_left => 'Links';

  @override
  String get settings_drive_side_left_hint => 'LHD · Standard';

  @override
  String get settings_drive_side_right => 'Rechts';

  @override
  String get settings_drive_side_right_hint => 'RHD-Fahrzeuge';

  @override
  String get settings_drive_side_auto => 'Automatisch';

  @override
  String get settings_drive_side_auto_hint => 'Vom Fahrzeug erkennen';

  @override
  String get settings_drive_side_caption_left => 'Navigation links';

  @override
  String get settings_drive_side_caption_right => 'Navigation rechts';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Auto — Fahrzeug meldet Linkslenker';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Auto — Fahrzeug meldet Rechtslenker';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Auto — Fahrzeug nicht verfügbar, verwende links';

  @override
  String get recordings_title => 'Aufnahmen';

  @override
  String get recordings_segment_dashcam => 'Dashcam';

  @override
  String get recordings_segment_surveillance => 'Überwachung';

  @override
  String get recordings_action_settings => 'Einstellungen';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 heute · $arg2 insgesamt · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashcam · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Überwachung · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title =>
      'Wählen Sie eine Aufnahme aus';

  @override
  String get recordings_preview_placeholder_body =>
      'Tippen Sie auf jedes Element links, um es abzuspielen.';

  @override
  String get diagnostics_section_adb_console => 'ADB-Konsole';

  @override
  String get diagnostics_section_traffic => 'Verkehrsmonitor';

  @override
  String get diagnostics_section_camera_probe => 'Kamera-Sonde';

  @override
  String get diagnostics_section_battery => 'Batteriengesundheit';

  @override
  String get diagnostics_section_performance => 'Leistung';

  @override
  String get diagnostics_hero_title => 'Systemdiagnose';

  @override
  String get diagnostics_hero_subtitle =>
      'Live Gesundheit, Logs und Sonden für das Gerät.';

  @override
  String get diagnostics_health_clear => 'Keine Probleme';

  @override
  String get diagnostics_health_section => 'Zustand';

  @override
  String get diagnostics_health_network => 'Netzwerk';

  @override
  String get diagnostics_health_storage => 'Speicher';

  @override
  String get diagnostics_health_camera => 'Kamera';

  @override
  String get diagnostics_health_battery => 'Batterie';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Online';

  @override
  String diagnostics_network_data_usage_line(Object arg1) {
    return '$arg1 diesen Monat';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Online';

  @override
  String get diagnostics_tunnel_state_offline => 'Offline';

  @override
  String get diagnostics_tunnel_state_connecting =>
      'Verbindung wird hergestellt';

  @override
  String get diagnostics_network_mobile => 'Mobilfunk';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Offline';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 Clips · $arg2 belegt',
      one: '$arg1 Clip · $arg2 belegt',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 frei';
  }

  @override
  String get diagnostics_logs_card_title => 'Live-Veranstaltungsprotokoll';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Streaming-Ausgabe von laufenden Diensten.';

  @override
  String get diagnostics_tools_section => 'Werkzeuge';

  @override
  String get diagnostics_traffic_subtitle => 'Beobachten Sie die Netzteile.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Inspektieren Sie die angeschlossenen Kamera-Streams.';

  @override
  String get diagnostics_adb_subtitle => 'Terminal auf dem Gerät öffnen.';

  @override
  String get diagnostics_battery_subtitle =>
      'Überprüfen Sie die Zelle SOH und packen Sie Statistiken.';

  @override
  String get diagnostics_settings_subtitle =>
      'Anwendungspräferenzen, Thema und Sprache.';

  @override
  String get settings_action_reset_data => 'Daten zurücksetzen…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'Auf Wache';

  @override
  String get dashboard_subtitle_all_systems => 'Alle Systeme online';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 von $arg2 Online-Dienste';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Fernzugriff offline';

  @override
  String get dashboard_metric_recordings => 'Heutige Aufnahmen';

  @override
  String get dashboard_metric_storage => 'Belegter Speicher';

  @override
  String get dashboard_metric_tunnel => 'Fernzugriff';

  @override
  String get dashboard_metric_services => 'Hintergrunddienste';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Fahrzeug';

  @override
  String get dashboard_chip_recording_active => 'Aufzeichnung';

  @override
  String get dashboard_chip_recording_idle => 'Inaktiv';

  @override
  String get dashboard_vehicle_tap_to_set => 'Zum Festlegen tippen';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Batteriekapazität festlegen';

  @override
  String get vehicle_dialog_model_label => 'Modell';

  @override
  String get vehicle_dialog_save => 'Speichern';

  @override
  String get settings_recording_tab_status => 'Status';

  @override
  String get settings_recording_tab_capture => 'Aufnahme';

  @override
  String get settings_recording_tab_quality => 'Qualität';

  @override
  String get settings_recording_tab_storage => 'Speicher';

  @override
  String get settings_recording_status_title => 'Aufnahmestatus';

  @override
  String get settings_recording_status_current_state => 'Aktueller Status';

  @override
  String get settings_recording_status_today_count => 'Aufnahmen heute';

  @override
  String get settings_recording_mode_title => 'Aufnahmemodus (Zündung an)';

  @override
  String get settings_recording_mode_description =>
      'Wählen Sie, wann die Dashcam-Aufnahme während der Fahrt erfolgen soll.';

  @override
  String get settings_recording_mode_none_label => 'Keine (Standard)';

  @override
  String get settings_recording_mode_none_desc =>
      'Keine Aufnahme — Überwachung funktioniert weiterhin';

  @override
  String get settings_recording_mode_continuous_label => 'Durchgehend';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Immer während der Fahrt aufnehmen';

  @override
  String get settings_recording_mode_drive_label => 'Fahrmodus';

  @override
  String get settings_recording_mode_drive_desc =>
      'Nur aufnehmen, wenn sich das Fahrzeug bewegt';

  @override
  String get settings_recording_mode_proximity_label => 'Näherungswache';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Aufnahme bei erkannter Bewegung';

  @override
  String get settings_recording_limit_title => 'Aufnahmelimit';

  @override
  String get settings_recording_limit_description =>
      'Maximale Länge pro Datei. Aufnahmen werden in diesem Intervall in neue Dateien aufgeteilt.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 Min';
  }

  @override
  String get settings_recording_priority_title => 'Aufnahmepriorität';

  @override
  String get settings_recording_priority_description =>
      'Wie die Aufnahme mit einem plötzlichen Stromausfall umgeht.';

  @override
  String get settings_recording_priority_performance_label => 'Leistung';

  @override
  String get settings_recording_priority_performance_desc =>
      'Verbraucht weniger CPU-Leistung. Bei plötzlichem Stromausfall kann das aktuelle Aufnahmesegment (bis zu Ihrem Aufnahmelimit) verloren gehen.';

  @override
  String get settings_recording_priority_reliability_label => 'Zuverlässigkeit';

  @override
  String get settings_recording_priority_reliability_desc =>
      'Verbraucht etwas mehr CPU-Leistung, um häufiger zu speichern. Bei plötzlichem Stromausfall geht höchstens etwa eine Minute verloren.';

  @override
  String get settings_recording_overlay_fields_title => 'Overlay-Felder';

  @override
  String get settings_recording_overlay_fields_description =>
      'Wähle, was im eingebrannten Overlay bei durchgehenden Aufnahmen erscheint.';

  @override
  String get settings_recording_overlay_field_speed => 'Geschwindigkeit';

  @override
  String get settings_recording_overlay_field_gear => 'Gang';

  @override
  String get settings_recording_overlay_field_turn_signal_left =>
      'Blinker links';

  @override
  String get settings_recording_overlay_field_turn_signal_right =>
      'Blinker rechts';

  @override
  String get settings_recording_overlay_field_brake_pedal => 'Bremspedal';

  @override
  String get settings_recording_overlay_field_accel_pedal => 'Gaspedal';

  @override
  String get settings_recording_overlay_field_seatbelt_driver =>
      'Sicherheitsgurt Fahrer';

  @override
  String get settings_recording_overlay_field_seatbelt_passenger =>
      'Sicherheitsgurt Beifahrer';

  @override
  String get settings_recording_overlay_field_timestamp => 'Datum und Uhrzeit';

  @override
  String get settings_recording_quality_title => 'Aufnahmequalität';

  @override
  String get settings_recording_storage_title => 'Aufnahmespeicher';

  @override
  String get settings_recording_storage_confirm_title => 'Aufnahmen löschen?';

  @override
  String settings_recording_storage_confirm_message(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Dadurch werden $arg1 Aufnahmen gelöscht ($arg2).',
      one: 'Dadurch wird $arg1 Aufnahme gelöscht ($arg2).',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_confirm_unknown_title =>
      'Auswirkung unbekannt';

  @override
  String get settings_recording_storage_confirm_unknown_message =>
      'Es konnte nicht ermittelt werden, was durch diese Änderung gelöscht würde. Eine Verringerung des Limits kann vorhandene Aufnahmen entfernen.';

  @override
  String get settings_recording_storage_location_label => 'Speicherort';

  @override
  String get settings_recording_storage_internal => 'Intern';

  @override
  String get settings_recording_storage_sd_card => 'SD-Karte';

  @override
  String get settings_recording_storage_sd_card_na => 'SD-Karte (n. v.)';

  @override
  String get settings_recording_storage_sd_mount_failed_title =>
      'SD-Karte wurde nicht eingebunden';

  @override
  String get settings_recording_storage_limit_label =>
      'Speicherlimit — löscht älteste Dateien automatisch bei Erreichen';

  @override
  String get settings_recording_storage_usage_label => 'Speichernutzung';

  @override
  String get settings_recording_storage_files_label => 'Dateien';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 von $arg2 belegt';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 Aufnahmen',
      one: '$arg1 Aufnahme',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Pfad';

  @override
  String get settings_recording_storage_sd_free_label => 'SD-Karte frei';

  @override
  String get settings_recording_storage_internal_free_label => 'Intern frei';

  @override
  String get settings_recording_format_title => 'Externes Laufwerk formatieren';

  @override
  String get settings_recording_format_warning =>
      'Löscht dauerhaft ALLE Daten auf der SD-Karte oder dem USB-Laufwerk.';

  @override
  String get settings_recording_format_confirm =>
      'Erneut tippen — ALLE Daten werden GELÖSCHT';

  @override
  String get settings_recording_format_running => 'Formatieren… bitte warten';

  @override
  String get settings_recording_format_button => 'SD-Karte/USB formatieren';

  @override
  String get settings_recording_format_no_drive =>
      'Kein Wechseldatenträger gefunden';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Erfolgreich formatiert. Neuer Pfad: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Datenbankkatalog';

  @override
  String get settings_recording_sync_description =>
      'Aufnahmeindex mit Dateien auf dem Datenträger abgleichen.';

  @override
  String get settings_recording_sync_running => 'Synchronisiere…';

  @override
  String get settings_recording_sync_button => 'Datenbank synchronisieren';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Synchronisiert: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress =>
      'Synchronisierung läuft bereits';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Synchronisierung fehlgeschlagen: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Änderungen anwenden';

  @override
  String get settings_recording_dismiss => 'Verwerfen';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Starten/Stoppen von $arg1 wird noch nicht unterstützt';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 verwendet · $arg2 frei';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Speicher —';

  @override
  String get dashboard_tunnel_offline => 'Offline';

  @override
  String get dashboard_tunnel_online => 'Online';

  @override
  String get dashboard_tunnel_connecting => 'Verbindung wird hergestellt…';

  @override
  String get dashboard_trips_this_week => 'Diese Woche';

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
  String get dashboard_trips_label_trips => 'Fahrten';

  @override
  String get dashboard_trips_label_distance => 'Strecke';

  @override
  String get dashboard_trips_label_time => 'Fahrzeit';

  @override
  String get dashboard_trips_no_data =>
      'Diese Woche keine Fahrten aufgezeichnet';

  @override
  String get dashboard_trips_unavailable =>
      'Losfahren, um Statistiken zu sehen';

  @override
  String get dashboard_trips_loading => 'Wird geladen…';

  @override
  String get dashboard_trips_view_all => 'Alle Fahrten anzeigen';

  @override
  String get dashboard_action_live => 'Live-Ansicht';

  @override
  String get dashboard_action_live_subtitle => 'Kameraansicht öffnen';

  @override
  String get dashboard_action_recordings => 'Aufnahmen';

  @override
  String get dashboard_action_settings => 'Einstellungen';

  @override
  String get dashboard_action_settings_subtitle => 'Präferenzen und';

  @override
  String get settings_hero_title => 'Einstellungen';

  @override
  String get settings_hero_overline => 'Übertrieb';

  @override
  String get settings_hero_subtitle =>
      'Anpassung von Aussehen, Aufzeichnung, Überwachung und Gerätedaten.';

  @override
  String get settings_overline_preferences => 'Vorläufe';

  @override
  String get settings_overline_about_data => 'Über & DATA';

  @override
  String get settings_quick_theme_label => 'Thema';

  @override
  String get settings_quick_language_label => 'Sprache';

  @override
  String get settings_section_recording_subtitle =>
      'Vor- und Nachbuffer, Codec, Speicherbegrenzungen.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Zeitplan, Bewegungsempfindlichkeit, Objekterkennung.';

  @override
  String get settings_section_daemons_subtitle =>
      'Fernzugriff (Pear) und Hintergrunddienste.';

  @override
  String get settings_about_row_title => 'Über BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Version, Lizenz, Supportentwicklung.';

  @override
  String get settings_reset_row_subtitle =>
      'Klar aufgezeichnet, Ereignisse oder alle Caches.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Thema, Sprache und visuelle Präferenzen.';

  @override
  String get settings_theme_active_auto_caption =>
      'Auto folgt Ihrem Systemdesign.';

  @override
  String get settings_theme_active_light_caption =>
      'Das helle Design ist immer aktiv.';

  @override
  String get settings_theme_active_dark_caption =>
      'Das dunkle Design ist immer aktiv.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 von $arg2 Sprachen verfügbar';
  }

  @override
  String get settings_language_card_title => 'Anzeigensprache';

  @override
  String get settings_privacy_stance_title => 'Gerät auf dem Gerät';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch läuft vollständig auf der Haupt-Einheit. Keine Telemetrie verlässt Ihr Auto, außer über die Tunnel und Integrationen, die Sie ausdrücklich konfigurieren.';

  @override
  String get settings_privacy_overline_storage => 'LOKALER Speicher';

  @override
  String get settings_privacy_overline_reset => 'Datensatz';

  @override
  String get settings_privacy_storage_clips_label => 'Klippe auf Festplatte';

  @override
  String get settings_privacy_storage_size_label => 'Gesamtgröße';

  @override
  String get settings_privacy_storage_unavailable => 'Nicht verfügbar';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 Clips',
      one: '$arg1 Clip',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Kategorien auswählen: Aufnahmen, Ereignisse, Dienstkonfigurationen, gespeicherte Telemetrie...';

  @override
  String get settings_developer_overline => 'ENTWICKLER';

  @override
  String get settings_developer_timing_logs_title => 'Dienst-Timing-Protokolle';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Zeitmarken beim Start des Dienstes protokollieren. Im Normalbetrieb deaktivieren, um logcat sauber zu halten.';

  @override
  String get settings_developer_debug_logs_title =>
      'Entwickler-Debug-Protokolle';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Alle Activity- und Fragment-Lebenszyklusereignisse und Startschritte nach /storage/emulated/0/BladeWatch/data/debug_app.log protokollieren. Abstürze werden immer erfasst. Standardmäßig aus.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Kamera $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Kamera $arg1 (Handbuch)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Wird geprüft…';

  @override
  String get diagnostics_camera_value_offline => 'Offline';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Ausstehende Daten';

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
      other: '$arg1 Clips · $arg2 aufgezeichnet',
      one: '$arg1 Clip · $arg2 aufgezeichnet',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Kofferraum';

  @override
  String get vehicle_tab_climate => 'Klima';

  @override
  String get vehicle_tab_windows => 'Fenster';

  @override
  String get vehicle_tab_lights => 'Lichter';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Aufladung';

  @override
  String get vehicle_locked => 'Verriegelt';

  @override
  String get vehicle_unlocked => 'Unverschlossen';

  @override
  String get vehicle_range_label => 'Reichweite';

  @override
  String get vehicle_data_unavailable => 'Fahrzeugdaten nicht verfügbar.';

  @override
  String get vehicle_action_failed =>
      'Aktion fehlgeschlagen. Fahrzeugverbindung prüfen.';

  @override
  String get vehicle_open_trunk => 'Kofferraum öffnen';

  @override
  String get vehicle_close_trunk => 'Kofferraum schließen';

  @override
  String get vehicle_trunk_info_open =>
      'Beim Öffnen des Kofferraums wird das Auto zuerst entriegelt.';

  @override
  String get vehicle_ac_on => 'AC an';

  @override
  String get vehicle_ac_off => 'AC aus';

  @override
  String get vehicle_max_cooling_on => 'Max. Kühlung: EIN';

  @override
  String get vehicle_max_cooling_off => 'Max. Kühlung: AUS';

  @override
  String get vehicle_screen_on => 'Bildschirm: EIN';

  @override
  String get vehicle_screen_off => 'Bildschirm: AUS';

  @override
  String get vehicle_media_volume_label => 'Medienlautstärke';

  @override
  String get vehicle_media_mute => 'Stumm';

  @override
  String get vehicle_media_muted => 'Stummgeschaltet';

  @override
  String get vehicle_front_defrost => 'Frontscheibenheizung';

  @override
  String get vehicle_rear_defrost => 'Heckscheibenheizung';

  @override
  String get vehicle_temp_label => 'Temperatur';

  @override
  String get vehicle_fan_speed_label => 'Lüfterstufe';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Stufe $arg1';
  }

  @override
  String vehicle_outside_temp_fmt(Object arg1) {
    return 'Außen: $arg1°C';
  }

  @override
  String get vehicle_all_windows => 'Alle Fenster';

  @override
  String get vehicle_window_awake_note =>
      'Funktioniert nur, wenn das Fahrzeug wach ist.';

  @override
  String get vehicle_window_front_left => 'Vorne links';

  @override
  String get vehicle_window_front_right => 'Vorne rechts';

  @override
  String get vehicle_window_rear_left => 'Hinten links';

  @override
  String get vehicle_window_rear_right => 'Hinten rechts';

  @override
  String get vehicle_window_close => 'Schließen';

  @override
  String get vehicle_window_close_vent => 'Spalt schließen';

  @override
  String get vehicle_window_vent_12 => 'Spalt 12%';

  @override
  String get vehicle_window_open_all => 'Alle öffnen';

  @override
  String get vehicle_sunroof => 'Sonnendach';

  @override
  String get vehicle_sunshade => 'Sonnenrollo';

  @override
  String get vehicle_btn_drl_title => 'Tageslich laufende Lichter';

  @override
  String get vehicle_btn_slw_title => 'Geschwindigkeitsbegrenzungswarnung';

  @override
  String get vehicle_control_section_charge_cap => 'Ladelimit';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Ladelimit wird von diesem Fahrzeug nicht unterstützt.';

  @override
  String get vehicle_charge_limit_label => 'Ladelimit';

  @override
  String get vehicle_enable_charge_limit => 'Ladelimit aktivieren';

  @override
  String get vehicle_charge_limit_range => 'Minimum 50%, Maximum 100%';

  @override
  String get vehicle_tyre_no_signal => 'KEIN SIGNAL';

  @override
  String get vehicle_tyre_slow_leak => 'LANGSAMES LECK';

  @override
  String get vehicle_tyre_fast_leak => 'SCHNELLES LECK';

  @override
  String get vehicle_tyre_low => 'NIEDRIG';

  @override
  String get vehicle_tyre_high => 'HOCH';

  @override
  String get vehicle_tyre_ok => 'OK';

  @override
  String get vehicle_tyre_check_pressure => 'Druck prüfen';

  @override
  String get vehicle_toggle_on => 'EIN';

  @override
  String get vehicle_toggle_off => 'AUS';

  @override
  String get vehicle_err_climate_control => 'Klimasteuerung fehlgeschlagen.';

  @override
  String get vehicle_err_max_cooling => 'Max. Kühlung fehlgeschlagen.';

  @override
  String get vehicle_err_drl_control =>
      'Tagfahrlicht-Steuerung fehlgeschlagen.';

  @override
  String get vehicle_err_slw_control => 'ADAS-Steuerung fehlgeschlagen.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Umschalten des Ladelimits fehlgeschlagen.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return '$arg1 verringern';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return '$arg1 erhöhen';
  }

  @override
  String get vehicle_stale_connecting => 'Verbinde…';

  @override
  String get vehicle_appearance_model_title => 'Modell auswählen';

  @override
  String get vehicle_appearance_custom_color => 'Eigene Farbe';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Ladung: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Reichweite: $arg1 km';
  }

  @override
  String vehicle_status_fuel_fmt(Object arg1) {
    return 'Kraftstoff: $arg1%';
  }

  @override
  String vehicle_status_fuel_range_fmt(Object arg1) {
    return 'Kraftstoffreichweite: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Ladung: —';

  @override
  String get vehicle_status_range_unknown => 'Reichweite: —';

  @override
  String get startup_subtitle => 'Ihre Dashcam wird vorbereitet';

  @override
  String get startup_header_preparing => 'Wird vorbereitet…';

  @override
  String get startup_header_starting => 'Wird gestartet…';

  @override
  String get startup_header_verifying => 'Fast bereit…';

  @override
  String get startup_header_ready => 'Alles bereit';

  @override
  String get startup_daemon_camera => 'Kamera';

  @override
  String get startup_daemon_camera_desc => 'Live-Ansicht & Aufzeichnung';

  @override
  String get startup_daemon_sentry => 'Sentry-Modus';

  @override
  String get startup_daemon_sentry_desc => 'Bewegungserkennung & Warnungen';

  @override
  String get startup_daemon_parking => 'Parkwächter';

  @override
  String get startup_daemon_parking_desc => 'Überwacht im geparkten Zustand';

  @override
  String get startup_status_waiting => 'Wartet';

  @override
  String get startup_status_starting => 'Startet';

  @override
  String get startup_status_ready => 'Bereit';

  @override
  String get startup_status_failed => 'Fehlgeschlagen';

  @override
  String get startup_continue_anyway => 'Trotzdem fortfahren';

  @override
  String get startup_continue => 'Weiter →';

  @override
  String get live_retry => 'Erneut versuchen';

  @override
  String get live_connecting => 'Verbinde mit Kamera…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Fehler: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Kamera nicht verfügbar\n$arg1';
  }

  @override
  String get live_direction_all => 'Alle';

  @override
  String get live_direction_front => 'Vorne';

  @override
  String get live_direction_right => 'Rechts';

  @override
  String get live_direction_rear => 'Hinten';

  @override
  String get live_direction_left => 'Links';

  @override
  String get trip_no_route_data => 'Keine Routendaten für diese Fahrt';

  @override
  String get trips_tab_trips => 'Fahrten';

  @override
  String get trips_tab_stats => 'Statistik';

  @override
  String get trips_tab_storage => 'Speicher';

  @override
  String get trips_filter_7_days => '7 Tage';

  @override
  String get trips_filter_14_days => '14 Tage';

  @override
  String get trips_filter_30_days => '30 Tage';

  @override
  String trips_load_error(Object message) {
    return 'Fehler: $message';
  }

  @override
  String get trips_empty_state => 'Noch keine Fahrten aufgezeichnet';

  @override
  String get trips_period_summary_title => 'Zeitraumübersicht';

  @override
  String get trips_stat_trips => 'Fahrten';

  @override
  String get trips_stat_hours => 'Stunden';

  @override
  String get trips_stat_efficiency => 'Effizienz';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Punkte: $score';
  }

  @override
  String get trips_driver_score_title => 'Fahrer-Score';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Gesamt: $score / 100';
  }

  @override
  String get trips_range_title => 'Persönliche Reichweite';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD-Schätzung: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'Kraftstoffreichweite: $km';
  }

  @override
  String get trips_range_no_data => 'Noch nicht genügend Daten';

  @override
  String get trips_dna_title => 'Fahr-DNA';

  @override
  String get trips_dna_anticipation => 'Vorausschau';

  @override
  String get trips_dna_smoothness => 'Gleichmäßigkeit';

  @override
  String get trips_dna_speed_discipline => 'Tempodisziplin';

  @override
  String get trips_dna_efficiency => 'Effizienz';

  @override
  String get trips_dna_consistency => 'Konstanz';

  @override
  String get trips_storage_title => 'Fahrtenspeicher';

  @override
  String get trips_storage_analytics_label => 'Fahrtanalyse';

  @override
  String get trips_storage_rate_label => 'Strompreis';

  @override
  String get trips_storage_fuel_price_label => 'Kraftstoffpreis (pro Liter)';

  @override
  String get trips_storage_tank_capacity_label => 'Tankvolumen (Liter)';

  @override
  String get trips_storage_distance_unit_label => 'Entfernungseinheit';

  @override
  String get trips_storage_location_label => 'Speicherort';

  @override
  String get trips_storage_internal => 'Intern';

  @override
  String get trips_storage_sd_card => 'SD-Karte';

  @override
  String get trips_storage_sd_card_unavailable => 'SD-Karte (n. v.)';

  @override
  String get trips_storage_apply => 'Änderungen übernehmen';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit von $limit MB belegt · $count Fahrten';
  }

  @override
  String get trips_sync_title => 'Datenbankkatalog';

  @override
  String get trips_sync_description =>
      'Gleicht den Fahrtenindex mit den Telemetriedateien auf dem Datenträger ab.';

  @override
  String get trips_sync_button => 'Datenbank abgleichen';

  @override
  String get trips_sync_running => 'Wird synchronisiert…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Erfolgreich synchronisiert: +$added -$removed ($total insgesamt)';
  }

  @override
  String get trips_sync_failed_generic => 'Synchronisierung fehlgeschlagen';

  @override
  String get trips_detail_summary_title => 'Fahrtübersicht';

  @override
  String get trips_detail_distance => 'Strecke';

  @override
  String get trips_detail_duration => 'Dauer';

  @override
  String get trips_detail_energy => 'Energie';

  @override
  String get trips_detail_avg_speed => 'Ø-Geschw.';

  @override
  String get trips_detail_max_speed => 'Max. Geschw.';

  @override
  String get trips_detail_soc => 'Ladestand';

  @override
  String get trips_detail_cost => 'Kosten';

  @override
  String get trips_detail_ext_temp => 'Außentemp.';

  @override
  String get trips_detail_fuel_used => 'Kraftstoff';

  @override
  String get trips_detail_fuel_cost => 'Kraftstoffkosten';

  @override
  String get trips_detail_electric_cost => 'Stromkosten';

  @override
  String get trips_detail_elev_gain => 'Höhengewinn';

  @override
  String get trips_detail_scores_title => 'Fahrbewertungen';

  @override
  String get trips_detail_unavailable => 'Fahrtdetails nicht verfügbar';

  @override
  String get trips_detail_loading => 'Fahrt wird geladen…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count GPS-Punkte aufgezeichnet';
  }

  @override
  String get rec_severity_critical => 'KRITISCH';

  @override
  String get rec_severity_alert => 'WARNUNG';

  @override
  String get location_loading_title => 'Karte wird geladen';

  @override
  String get location_permission_missing_title =>
      'Standortberechtigung erforderlich';

  @override
  String get location_permission_denied_title => 'Berechtigung verweigert';

  @override
  String get location_provider_disabled_title => 'GPS deaktiviert';

  @override
  String get location_waiting_for_fix_title => 'Warte auf GPS-Signal';

  @override
  String get location_car_location_title => 'Fahrzeugstandort';

  @override
  String get location_stale_title => 'Standort veraltet';

  @override
  String get location_tile_failure_title => 'Karte nicht verfügbar';

  @override
  String get location_tile_failure_subtitle => 'Netzwerk nicht verfügbar';

  @override
  String get location_error_title => 'Standortfehler';

  @override
  String get location_action_grant => 'Erlauben';

  @override
  String get location_action_retry => 'Erneut versuchen';

  @override
  String get location_mode_auto => 'Automatisch';

  @override
  String get location_mode_light => 'Hell';

  @override
  String get location_mode_dark => 'Dunkel';

  @override
  String get cd_recenter_on_car => 'Auf Fahrzeug zentrieren';

  @override
  String get recording_lib_no_recordings_normal => 'Keine normalen Aufnahmen';

  @override
  String get recording_lib_no_recordings_sentry =>
      'Keine Überwachungsereignisse';

  @override
  String get recording_lib_no_recordings_proximity =>
      'Keine Näherungsereignisse';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'Person';

  @override
  String get video_player_legend_car => 'Auto';

  @override
  String get video_player_legend_bike => 'Fahrrad';

  @override
  String get video_player_legend_motion => 'Bewegung';

  @override
  String get recording_lib_proximity_very_close => 'sehr nah';

  @override
  String get recording_lib_proximity_close => 'nah';

  @override
  String get recording_lib_proximity_mid => 'mittel';

  @override
  String get recording_lib_proximity_far => 'fern';

  @override
  String get surveillance_tab_general => 'Allgemein';

  @override
  String get surveillance_tab_detection => 'Erkennung';

  @override
  String get surveillance_tab_recording => 'Aufnahme';

  @override
  String get surveillance_tab_storage => 'Speicher';

  @override
  String get surveillance_tab_advanced => 'Erweitert';

  @override
  String get surveillance_general_title => 'Überwachungsmodus';

  @override
  String get surveillance_general_enable => 'Überwachung aktivieren';

  @override
  String get surveillance_general_status => 'Status';

  @override
  String get surveillance_general_status_running => 'Aktiv';

  @override
  String get surveillance_general_status_idle => 'Inaktiv';

  @override
  String get surveillance_general_events_today => 'Ereignisse heute';

  @override
  String get surveillance_safe_locations_title => 'Sichere Orte';

  @override
  String get surveillance_safe_locations_subtitle =>
      'Kamera startet hier beim Parken nicht';

  @override
  String get surveillance_safe_locations_enable =>
      'An sicheren Orten deaktivieren';

  @override
  String get surveillance_safe_locations_empty =>
      'Noch keine sicheren Orte hinzugefügt';

  @override
  String get surveillance_safe_locations_add_current =>
      'Aktuellen Standort als sicheren Bereich hinzufügen';

  @override
  String get surveillance_safe_locations_no_gps =>
      'GPS-Standort nicht verfügbar';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Erkennungseinstellungen';

  @override
  String get surveillance_detection_preset_label => 'Umgebungsprofil';

  @override
  String get surveillance_preset_outdoor => 'Außenbereich';

  @override
  String get surveillance_preset_garage => 'Garage';

  @override
  String get surveillance_preset_street => 'Straße';

  @override
  String get surveillance_preset_custom => 'Benutzerdefiniert';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Empfindlichkeit (1=streng, 5=empfindlich): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Objekte erkennen';

  @override
  String get surveillance_detection_object_person => 'Person';

  @override
  String get surveillance_detection_object_car => 'Auto';

  @override
  String get surveillance_detection_object_bike => 'Fahrrad';

  @override
  String get surveillance_recording_title => 'Ereignisaufnahme';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Vorlauf (Sekunden vor dem Ereignis): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Nachlauf (Sekunden nach dem Ereignis): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Überwachungsspeicher';

  @override
  String get surveillance_storage_location_label => 'Speicherort';

  @override
  String get surveillance_storage_internal => 'Intern';

  @override
  String get surveillance_storage_sd_card => 'SD-Karte';

  @override
  String get surveillance_storage_sd_card_na => 'SD-Karte (n. v.)';

  @override
  String get surveillance_storage_limit_label =>
      'Speicherlimit – löscht älteste Dateien automatisch';

  @override
  String get surveillance_storage_usage_label => 'Speichernutzung';

  @override
  String get surveillance_storage_files_label => 'Dateien';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 belegt / $arg2 Limit';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 Ereignisse',
      one: '$arg1 Ereignis',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'Pfad';

  @override
  String get surveillance_format_title => 'Externes Laufwerk formatieren';

  @override
  String get surveillance_format_warning =>
      'Löscht dauerhaft ALLE Daten auf der SD-Karte oder dem USB-Laufwerk.';

  @override
  String get surveillance_format_button => 'SD-Karte/USB formatieren';

  @override
  String get surveillance_format_confirm =>
      'Nochmal tippen — ALLE Daten werden GELÖSCHT';

  @override
  String get surveillance_format_running => 'Formatierung läuft … bitte warten';

  @override
  String get surveillance_dismiss => 'Verwerfen';

  @override
  String get surveillance_sync_title => 'Datenbankkatalog';

  @override
  String get surveillance_sync_description =>
      'Gleicht den Überwachungsindex mit den Dateien auf dem Speicher ab.';

  @override
  String get surveillance_sync_button => 'Datenbank synchronisieren';

  @override
  String get surveillance_sync_running => 'Synchronisiere…';

  @override
  String get surveillance_advanced_camera_title => 'Kameraauswahl';

  @override
  String get surveillance_advanced_camera_front => 'Vorne';

  @override
  String get surveillance_advanced_camera_right => 'Rechts';

  @override
  String get surveillance_advanced_camera_rear => 'Hinten';

  @override
  String get surveillance_advanced_camera_left => 'Links';

  @override
  String get surveillance_advanced_ai_title => 'KI & Abschreckung';

  @override
  String get surveillance_advanced_ai_detection => 'KI-Erkennung';

  @override
  String get surveillance_advanced_night_mode => 'Nachtmodus';

  @override
  String get surveillance_advanced_deterrent_label => 'Abschreckungsaktion';

  @override
  String get surveillance_deterrent_silent => 'Lautlos';

  @override
  String get surveillance_deterrent_horn => 'Hupe';

  @override
  String get surveillance_deterrent_flash => 'Blitzlicht';

  @override
  String get surveillance_apply_button => 'Änderungen übernehmen';

  @override
  String get surveillance_apply_failed => 'Speichern fehlgeschlagen';

  @override
  String get surveillance_general_battery_warning =>
      'Der Wächtermodus verbraucht zusätzlichen Strom aus der 12-V-Batterie, solange er aktiv ist.';

  @override
  String get surveillance_general_camera_contention_warning =>
      'Eine andere App verwendet die Kamera gerade.';

  @override
  String get pairing_title => 'Gerät koppeln';

  @override
  String get pairing_scan_hint =>
      'Mit der BladeWatch-App auf Ihrem Telefon oder Computer scannen. Der Code funktioniert nur einmal.';

  @override
  String pairing_expires_in(String time) {
    return 'Läuft ab in $time';
  }

  @override
  String get pairing_expired => 'Dieser Code ist abgelaufen.';

  @override
  String get pairing_new_code => 'Neuer Code';

  @override
  String get pairing_remote_note =>
      'Durch das Koppeln wird der Fernzugriff für dieses Fahrzeug eingeschaltet.';

  @override
  String get pairing_lan_title => 'Direktverbindung über dieses WLAN';

  @override
  String get pairing_lan_body =>
      'Ein gekoppeltes Gerät im selben WLAN wie das Fahrzeug verbindet sich direkt und verschlüsselt, ohne Umweg über das Internet. Aus, bis Sie es einschalten.';

  @override
  String get pairing_devices_title => 'Gekoppelte Geräte';

  @override
  String get pairing_devices_empty => 'Noch keine Geräte gekoppelt.';

  @override
  String get pairing_remove => 'Entfernen';

  @override
  String pairing_remove_confirm_title(String name) {
    return '$name entfernen?';
  }

  @override
  String get pairing_remove_confirm_body =>
      'Es verliert sofort den Zugriff. Ihre anderen Geräte funktionieren weiter.';

  @override
  String get pairing_error =>
      'Der Kameradienst hat nicht geantwortet. Bitte erneut versuchen.';

  @override
  String get daemon_name_pear => 'Fernzugriff (Pear)';

  @override
  String get pear_status_reachable => 'Von überall erreichbar';

  @override
  String get pear_status_unreachable =>
      'Nicht erreichbar: keine Verbindung zum Pear-Netzwerk';

  @override
  String get pear_status_unknown => 'Erreichbarkeit unbekannt';

  @override
  String pear_devices_connected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Geräte verbunden',
      one: '$count Gerät verbunden',
      zero: 'Keine Geräte verbunden',
    );
    return '$_temp0';
  }

  @override
  String pear_last_connection(String time) {
    return 'Letzte Verbindung: $time';
  }

  @override
  String get pear_tile_off => 'Aus';

  @override
  String get trips_cost_total => 'Gesamtkosten';

  @override
  String get trips_cost_no_rate =>
      'Legen Sie in den Fahrteinstellungen einen Strompreis fest, um Kosten zu sehen.';

  @override
  String get trips_cost_mixed_currency =>
      'Fahrten sind in mehr als einer Währung berechnet, daher wird keine Summe angezeigt.';

  @override
  String dashboard_chip_gear(String gear) {
    return 'Gang $gear';
  }

  @override
  String dashboard_chip_drive_mode(String mode) {
    return 'Modus: $mode';
  }

  @override
  String dashboard_chip_auto_hold(String state) {
    return 'Auto Hold: $state';
  }

  @override
  String get auto_hold_disabled => 'Aus';

  @override
  String get auto_hold_enabled => 'Ein';

  @override
  String get auto_hold_active => 'Hält';
}
