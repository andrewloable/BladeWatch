// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'BladeWatch holder kjøretøyet overvåket aktivt i bakgrunnen. Denne tjenesten leser ikke eller interagerer med skjerminnholdet.';

  @override
  String get action_cancel => 'Avbryt';

  @override
  String get action_clear_plain => 'Tøm';

  @override
  String get action_select_all => 'Velg alle';

  @override
  String get action_select_all_short => 'Alle';

  @override
  String get action_delete => 'Slett';

  @override
  String get action_done => 'FERDIG';

  @override
  String get action_remind_me_later => 'PÅMINN MEG SENERE';

  @override
  String get action_retry => 'Prøv igjen';

  @override
  String get action_run => 'Kjør';

  @override
  String get action_clear_output => 'Tøm utdata';

  @override
  String get cd_camera => 'Kamera';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR-kode';

  @override
  String get cd_show_hide_token => 'Vis/skjul token';

  @override
  String get cd_copy_token => 'Kopier token';

  @override
  String get cd_copy_url => 'Kopier URL';

  @override
  String get cd_clear_logs => 'Tøm logg';

  @override
  String get cd_expand_collapse => 'Vis/skjul';

  @override
  String get cd_recording_status => 'Registreringsstatus';

  @override
  String get cd_trip_tracking_status => 'Status for sporing av reise';

  @override
  String get cd_video_thumbnail => 'Video miniatur';

  @override
  String get cd_play => 'Spill av';

  @override
  String get cd_back => 'Tilbake';

  @override
  String get cd_play_pause => 'Spill av / pause';

  @override
  String get cd_player_prev => 'Forrige opptak';

  @override
  String get cd_player_next => 'Neste opptak';

  @override
  String get cd_player_maximize => 'Maksimer avspiller';

  @override
  String get cd_player_minimize => 'Avslutt fullskjerm';

  @override
  String get cd_delete => 'Slett';

  @override
  String get cd_decrease => 'Reduser';

  @override
  String get cd_increase => 'Øk';

  @override
  String get cd_expand => 'Vis mer';

  @override
  String get cd_configure => 'Konfigurer';

  @override
  String get cd_download_log => 'Last ned logg';

  @override
  String get cd_reset => 'Tilbakestill';

  @override
  String get cd_battery => 'Batteri';

  @override
  String get cd_step_completed => 'Trinn fullført';

  @override
  String get cd_permission_granted => 'Tillatelse gitt';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'PROSESSER';

  @override
  String get logs_panel_title => 'Logger';

  @override
  String get url_connecting => 'Kobler til…';

  @override
  String get camera_selection_title => 'Kamerautvalg';

  @override
  String get camera_selection_subtitle => 'Velg panorama kamera kilde';

  @override
  String get camera_current_auto => 'Gjeldende: Auto';

  @override
  String get camera_option_auto => 'Automatisk (detekteres ved start)';

  @override
  String get camera_option_0 => 'Kamera 0 — Atto trimmer';

  @override
  String get camera_option_1 => 'Kamera 1 — Seal (avhengig)';

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
      'Auto velger riktig kamera for din trim ved hver oppstart. Kamera 1 = BYD Seal, Kamera 0 = Atto-trimmer. Start kameratjenesten på nytt etter å ha endret kamera-ID for at innstillingen skal tre i kraft.';

  @override
  String get dashboard_scan_to_connect => 'Scan for å koble';

  @override
  String get dashboard_qr_waiting => 'Ventet på tunnelen...';

  @override
  String get dashboard_daemons_running_default => '0/5 kjører';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'Tilgangskode';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Generer token på nytt';

  @override
  String get dashboard_set_password => 'Angi passord';

  @override
  String get cd_set_password => 'Angi eget passord';

  @override
  String get dialog_set_password_title => 'Angi eget passord';

  @override
  String get dialog_set_password_message =>
      'Skriv inn et nytt tilgangspassord. Dette erstatter det autogenererte tokenet.';

  @override
  String get dialog_set_password_hint => 'Nytt passord (minst 12 tegn)';

  @override
  String get toast_password_set => 'Passord oppdatert';

  @override
  String get toast_password_too_short => 'Passordet må være minst 12 tegn';

  @override
  String get toast_password_save_failed =>
      'Kunne ikke lagre passord — tjenesten er ikke klar';

  @override
  String get setup_guide_title => 'Begynnelsen';

  @override
  String get setup_guide_subtitle =>
      'Tre raske trinn for å få den beste opplevelsen:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Velg ditt språk';

  @override
  String get setup_language_body =>
      'Forutsetning til hovedenheten språk. Trykk for å velge en annen for BladeWatch app og web tunnelen.';

  @override
  String get setup_language_button => 'Velg språk';

  @override
  String get setup_autostart_title => 'Deaktiver autostart-begrensningen';

  @override
  String get setup_autostart_body =>
      'Trykk nedenfor for å åpne BYD Auto-Start, og fjern haken for BÅDE BladeWatch og BladeWatch-tjeneste. Uten dette starter ikke opptaket når du slår på bilen — du må åpne appen hver gang. BYD nullstiller dette ved hver installasjon.';

  @override
  String get setup_autostart_button => 'Åpne BYD Autostart';

  @override
  String get setup_overlay_title => 'Tillat visning over andre apper';

  @override
  String get setup_overlay_body =>
      'Aktiver dette for å vise en flytende statusindikator for opptak og reise sporing på toppen av andre apper.';

  @override
  String get setup_overlay_button => 'Åpne overlegg innstillinger';

  @override
  String get cd_close => 'Lukk';

  @override
  String get language_picker_title => 'Språk';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '$arg1 språk tilgjengelig';
  }

  @override
  String get language_picker_subtitle_pending => 'Velg et språk';

  @override
  String get language_auto_title => 'Automatisk';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Følg system · $arg1';
  }

  @override
  String get language_not_saved =>
      'Språket er tatt i bruk, men kunne ikke lagres — det tilbakestilles ved omstart.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Automatisk';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Skriv en kommando…';

  @override
  String get adb_preset_commands_header => 'Forutsette kommandoer';

  @override
  String get adb_output_header => 'Utdata';

  @override
  String get adb_output_ready => 'Klar til kommandoer...';

  @override
  String get adb_console_hero_title => 'ADB konsol';

  @override
  String get adb_console_hero_subtitle => 'Kjør Shell-kommandoer på enheten';

  @override
  String get adb_console_unavailable_title => 'ADB er ikke tilkoblet';

  @override
  String get adb_console_unavailable_body =>
      'På dette kjøretøyet er ikke den vanlige «USB-feilsøking»-bryteren i Utvikleralternativer nok alene — hovedenhetens egen trådløse ADB-innstilling (nettverksfeilsøking) må også være på, og en systemoppdatering kan tilbakestille den. Slå på trådløs ADB på hovedenheten igjen, eller koble til via USB.';

  @override
  String get adb_console_auth_pending_title => 'Venter på godkjenning';

  @override
  String get adb_console_auth_pending_body =>
      'Se etter meldingen «Tillat USB-feilsøking?» på hovedenhetens skjerm og godta den, prøv deretter igjen.';

  @override
  String get performance_connecting => 'Kobler til ytelsesmonitor…';

  @override
  String get performance_hero_title => 'Systemytelse';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'Systembruk';

  @override
  String get performance_cpu_app_usage => 'App-bruk';

  @override
  String get performance_frequency_label => 'Frekvens';

  @override
  String get performance_temperature_label => 'Temperatur';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Minne';

  @override
  String get performance_usage_label => 'Bruk';

  @override
  String get performance_memory_total => 'Totalt';

  @override
  String get performance_memory_used => 'Brukt';

  @override
  String get performance_memory_app => 'App';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'App-prosess';

  @override
  String get performance_threads_label => 'Tråder';

  @override
  String get performance_gc_cycles_label => 'GC-sykluser';

  @override
  String get performance_open_fds_label => 'Åpne FD-er';

  @override
  String get performance_refreshing_footer => 'Oppdaterer hvert 3. sekund';

  @override
  String get webview_loading => 'Ladding...';

  @override
  String get reset_title => 'Tilbakestill data';

  @override
  String get reset_subtitle => 'Slette akkumulerte data etter kategori';

  @override
  String get reset_warning =>
      'Dette kan ikke angres. Opptak, turer og batterihistorikk blir slettet permanent.';

  @override
  String get reset_cat_trips => 'Turer';

  @override
  String get reset_cat_trips_desc =>
      'Reisehistorie, ruter, ukentlige/månedlige oppføringer';

  @override
  String get reset_cat_soc_history => 'SoC & 12V historie';

  @override
  String get reset_cat_soc_history_desc =>
      'SoC-prøver, ladesessioner, spenningslogger';

  @override
  String get reset_cat_recordings => 'Opptagelser (videoer)';

  @override
  String get reset_cat_recordings_desc => 'Alle MP4 i opptagelsesmappen';

  @override
  String get reset_cat_sentry_events => 'Overvåkningsarrangementer';

  @override
  String get reset_cat_sentry_events_desc =>
      'Klipp fra overvåkingshendelser og tilhørende JSON-filer';

  @override
  String get reset_cat_proximity => 'Nærhetsopptak';

  @override
  String get reset_cat_proximity_desc => 'Radar-triggerte hendelser MP4';

  @override
  String get reset_cat_trip_files => 'Reise telemetry filer';

  @override
  String get reset_cat_trip_files_desc => 'Telemetri per tur JSON på disk';

  @override
  String get recording_lib_chip_any => 'Alle';

  @override
  String get recording_lib_chip_person => 'Person';

  @override
  String get recording_lib_chip_vehicle => 'Kjøretøy';

  @override
  String get recording_lib_chip_bike => 'Sykkel';

  @override
  String get recording_lib_chip_animal => 'Dyr';

  @override
  String get recording_lib_chip_alert => 'Varsel';

  @override
  String get recording_lib_chip_critical => 'Kritisk';

  @override
  String get recording_lib_selected_count_zero => '0 valgt';

  @override
  String get recording_lib_no_recordings => 'Ingen opptak';

  @override
  String get recording_lib_filter_button => 'Filter';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filter · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Filtrer opptak';

  @override
  String get recording_lib_filter_apply => 'Bruk';

  @override
  String get recording_lib_filter_reset => 'Tilbakestill';

  @override
  String get recording_lib_filter_section_what => 'Hva';

  @override
  String get recording_lib_filter_section_severity => 'Alvorlighet';

  @override
  String get recording_lib_filter_section_type => 'Type';

  @override
  String get recording_lib_chip_type_normal => 'Vanlig';

  @override
  String get recording_lib_chip_type_proximity => 'Nærhet';

  @override
  String get recording_lib_date_today => 'I dag';

  @override
  String get recording_lib_date_yesterday => 'I går';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 klipp',
      one: '$arg1 klipp',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Velg en dato';

  @override
  String get recording_lib_date_all_days => 'Alle dager';

  @override
  String get cd_clear_date_filter => 'Vis alle dager';

  @override
  String get recording_lib_section_morning => 'Morgen';

  @override
  String get recording_lib_section_afternoon => 'Ettermiddag';

  @override
  String get recording_lib_section_evening => 'Kveld';

  @override
  String get recording_lib_section_night => 'Natt';

  @override
  String get cd_previous_day => 'Forrige dag';

  @override
  String get cd_next_day => 'Neste dag';

  @override
  String get cd_open_filters => 'Åpne filtre';

  @override
  String get cd_clear_filter => 'Fjern filter';

  @override
  String get player_title_recording => 'Opptak';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Kameratjeneste';

  @override
  String get daemon_name_surveillance => 'Overvåkingstjeneste';

  @override
  String get daemon_name_acc => 'ACC-overvåking';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'Bakgrunnstjenester';

  @override
  String get daemons_count_pending => 'Laster tjenester…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 av $arg2 som kjører';
  }

  @override
  String get battery_health_title => 'Batteri helse';

  @override
  String get battery_health_unavailable => 'Ikke tilgjengelig';

  @override
  String get battery_health_unavailable_desc =>
      'Estimering av batterihelse er ikke tilgjengelig.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% på $arg2';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1-opptak slettet',
      one: '$arg1-opptak slettet',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Slett $arg1-opptak',
      one: 'Slett $arg1 opptak',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Dette sletter $arg1 opptak permanent. Dette kan ikke angres.',
      one: 'Dette sletter $arg1 opptak permanent. Dette kan ikke angres.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'App er oppdatert (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Lagring tillatelse som kreves for opptak';

  @override
  String get toast_url_copied_short => 'URL kopiert!';

  @override
  String get toast_camera_set_to_auto => 'Kamera satt til Auto';

  @override
  String get toast_failed_to_save_short => 'Ikke reddet';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Feil: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Kamera $arg1 er valgt — neste ACC-syklus';
  }

  @override
  String get toast_clearing_camera_config => 'Å rydde kamera konfigurasjon...';

  @override
  String get toast_restarting_camera_daemon =>
      'Starter kameratjenesten på nytt...';

  @override
  String get toast_camera_daemon_restarting =>
      'Kameratjenesten starter på nytt med full sondering';

  @override
  String get toast_camera_restart_failed =>
      'Konfigurasjon tømt, men omstart av tjenesten mislyktes. Start den manuelt.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Mislyktes: $arg1';
  }

  @override
  String get toast_select_at_least_one_category => 'Velg minst en kategori';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Utilpasning mislyktes: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 trafikkmonitor...';
  }

  @override
  String get dialog_close => 'Lukk';

  @override
  String get dialog_reset => 'Tilbakestill';

  @override
  String get dialog_delete => 'Slett';

  @override
  String get dialog_save => 'Lagre';

  @override
  String get dialog_enable => 'Aktiver';

  @override
  String get dialog_disable => 'Deaktiver';

  @override
  String get dialog_keep_enabled => 'Behold aktivert';

  @override
  String get dialog_keep_disabled => 'Behold deaktivert';

  @override
  String get dialog_regenerate => 'Generer på nytt';

  @override
  String get dialog_reset_selected => 'Tilbakestill valgte';

  @override
  String get dialog_reset_following_title => 'Tilbakestille følgende?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Dette kan ikke angres.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Tilbakestilling fullført';

  @override
  String get dialog_traffic_cannot_check_title => 'Kan ikke sjekke status';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB er ikke tilkoblet, og appen klarte ikke å koble til på nytt automatisk.\n\nPå dette kjøretøyet er ikke den vanlige «USB-feilsøking»-bryteren i utvikleralternativer nok alene — hodeenhetens egen innstilling for trådløs ADB (nettverksfeilsøking) må også være på, og en systemoppdatering kan nullstille den. Slå på trådløs ADB på hodeenheten igjen, eller koble til med USB.\n\nStatusen oppdateres automatisk når tilkoblingen er på plass.';

  @override
  String get dialog_traffic_disable_title => 'Deaktivere BYD Traffic Monitor?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) er en innebygd systemapp som kontinuerlig overvåker trafikkforholdene i bakgrunnen.\n\nHvorfor deaktivere den?\n\n• Bruker mobildata (også når bilen står parkert)\n• Bruker CPU og batteri i bakgrunnen\n• Unødvendig hvis du bruker en egen navigasjonsapp\n• Kan forstyrre dashkameraets nettverksbruk\n\nDet er trygt å deaktivere — det påvirker bare det innebygde trafikklaget på kartet. Navigasjon, Bluetooth og alle andre bilfunksjoner er upåvirket.\n\nEn hard omstart er nødvendig etter deaktivering (hold knappen på midtkonsollen inne i 5 sekunder).';

  @override
  String get dialog_traffic_enable_title => 'Å aktivere BYD trafikkmonitor?';

  @override
  String get dialog_traffic_enable_message =>
      'BYD Traffic Monitor er for øyeblikket deaktivert.\n\n Å aktivere det igjen vil gjenopprette det innebygde trafikkoverlaget på navigasjonskortet. Vær oppmerksom på at det vil kjøre i bakgrunnen og forbruke mobildata.\n\nEn hard reboot er nødvendig etter aktivering (hold sentrum konsolknappen 5 sekunder).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Trafikkovervåker $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'Endringen er påført.\n\nVennligst utfør en hard reboot nå:\nTrykk og hold sentrale konsolknappen i 5 sekunder.';

  @override
  String get traffic_monitor_loading => 'Trafikkrev: Kontrollering...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Trafikkontroller (task for å sjekke)';

  @override
  String get reset_label_trips => 'Turer';

  @override
  String get reset_label_soc_history => 'SoC + 12V historie';

  @override
  String get reset_label_recordings => 'Opptak';

  @override
  String get reset_label_sentry_events => 'Overvåkningsarrangementer';

  @override
  String get reset_label_proximity => 'Nærhetsopptak';

  @override
  String get reset_label_trip_files => 'Reise telemetry filer';

  @override
  String get toast_access_code_copied => 'Oppdatert tilgangskode';

  @override
  String get dialog_regenerate_token_title => 'Generer token på nytt';

  @override
  String get dialog_regenerate_token_message =>
      'Dette vil invalidere den nåværende tokenen. Alle aktive sesjoner vil bli logget ut. Fortsett?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Nytt token generert. Alle økter er logget ut.';

  @override
  String get toast_token_regenerated_restart =>
      'Token regenerert. Tjenestene må kanskje startes på nytt for å ta det i bruk.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token regenerert. Kunne ikke varsle bakgrunnstjenesten.';

  @override
  String get toast_token_regenerated => 'Token gjenopprettet';

  @override
  String get dashboard_no_tunnel => 'Ingen tunnel løper';

  @override
  String get dashboard_starting_tor => 'Starter Tor-tunnel…';

  @override
  String get dashboard_waiting_url => 'Ventet på tunnelen URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 kjører';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'Tilgangskode';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'Ingen konfigurasjon nødvendig for $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'Token kan ikke være tomt';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Jeg henter $arg1 logg...';
  }

  @override
  String get toast_log_empty_or_missing => 'Loggfil er tom eller ikke funnet';

  @override
  String get toast_log_empty => 'Loggfil er tomt';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Ikke lagre logg: $arg1';
  }

  @override
  String get toast_log_not_found => 'Loggfil ikke funnet eller ulesbart';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1-logg – $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Del $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1-logg ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Kilde: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'Eksport: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'MERK: loggen er forkortet til de siste 10000 linjene (totalt: $arg1 linjer)',
      one:
          'MERK: loggen er forkortet til de siste 10000 linjene (totalt: $arg1 linje)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Kan ikke spille video: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Slett opptak';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'Slette $arg1?\nDette kan ikke angres.';
  }

  @override
  String get toast_recording_deleted => 'Registrering slettet';

  @override
  String get toast_recording_delete_failed => 'Kunne ikke slette opptaket';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 slettet, $arg2 mislyktes';
  }

  @override
  String get play_with_chooser => 'Spill med';

  @override
  String setup_version_banner(Object arg1) {
    return 'Oppdatert til v$arg1 — bekreft automatisk start, BYD sletter det på hver installasjon';
  }

  @override
  String get setup_overlay_already_granted => 'Allerede innvilget';

  @override
  String camera_current_manual(Object arg1) {
    return 'Aktuell: Kamera $arg1 (manuell)';
  }

  @override
  String get camera_current_auto_label => 'Gjeldende: Auto';

  @override
  String get soh_estimation_active => 'Aktiv estimering';

  @override
  String get soh_oem_readout =>
      'SOH-avlesning fra kjøretøy — venter på beregnet estimat';

  @override
  String get soh_nominal_baseline =>
      'Nominell grunnverdi — venter på pålitelige SOH-data';

  @override
  String get soh_no_estimate_yet => 'Ingen vurdering ennå — Ventende på data';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 valgt';
  }

  @override
  String get video_player_playback_error => 'Spilling feilen';

  @override
  String get video_player_no_events => 'Ingen hendelser';

  @override
  String get daemon_configuration_required => 'Konfigurasjon som kreves';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Videospiller';

  @override
  String get status_overlay_notif_title => 'BladeWatch Status';

  @override
  String get status_overlay_notif_text => 'Status overlay aktiv';

  @override
  String get rail_dashboard => 'Oversikt';

  @override
  String get rail_live => 'Direkte';

  @override
  String get rail_recordings => 'Opptak';

  @override
  String get rail_vehicle => 'Kjøretøy';

  @override
  String get rail_trips => 'Turer';

  @override
  String get rail_location => 'Plassering';

  @override
  String get rail_diagnostics => 'Diagnostikk';

  @override
  String get rail_settings => 'Innstillinger';

  @override
  String get settings_section_appearance => 'Utseende';

  @override
  String get settings_section_recording => 'Opptak';

  @override
  String get settings_section_surveillance => 'Overvåking';

  @override
  String get settings_section_daemons => 'Tjenester';

  @override
  String get settings_section_privacy => 'Personvern og data';

  @override
  String get settings_section_overlay => 'Status overlapning';

  @override
  String get settings_overlay_subtitle =>
      'Velg hvilke segmenter av flytende statuspille som er synlige.';

  @override
  String get settings_overlay_camera_title => 'Kameraindikator';

  @override
  String get settings_overlay_camera_subtitle =>
      'Vis REC / PROX- insignet mens opptaket er aktivt.';

  @override
  String get settings_overlay_trip_title => 'indikerer Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Vis TRIP-skiltene mens detektering av reiser kjører.';

  @override
  String get settings_section_about => 'Om';

  @override
  String get settings_subrail_overline => 'Innstillinger';

  @override
  String get cd_settings_subrail => 'Innstillinger-sidelinje';

  @override
  String get settings_privacy_title => 'Personvern og data';

  @override
  String get settings_privacy_body =>
      'Tilbakestilling tømmer opptaksindeksen, hurtigbufrede opplysninger, tjenestetilstanden og innstillinger på enheten. Handlingen kan ikke angres.';

  @override
  String get settings_about_title => 'Om BladeWatch';

  @override
  String get settings_about_version_label => 'Versjon';

  @override
  String get settings_about_package_label => 'Bygg';

  @override
  String get settings_about_support_section => 'Styret av folk som deg';

  @override
  String get settings_about_support_share_title => 'Si ifra til en annen eier';

  @override
  String get settings_about_support_share_value =>
      'Hver delte lenke hjelper en annen BYD eier oppdage BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Sjekk BladeWatch — åpen kildekode overvåking & dashcam for BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'Del bladewatch';

  @override
  String get settings_about_open_link_failed => 'Jeg kunne ikke åpne lenken.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'Ingen nettleser funnet. URL kopiert: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => 'Brensel til neste utgivelse';

  @override
  String get settings_about_support_kofi_value =>
      'En kaffe på Ko-Fi holder sent natt forpliktelser kommer.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Lisense';

  @override
  String get settings_about_license_value =>
      'MIT — åpen kildekode. Trykk for å se full tekst.';

  @override
  String get settings_about_source_title => 'Kildekode';

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
  String get settings_about_star_title => 'Drop en på GitHub';

  @override
  String get settings_about_star_value => 'Det tar et øyeblikk, det betyr mye.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Takk';

  @override
  String get settings_about_thanks_subtitle =>
      'Bygget med hjelp fra bidragsytere og støttespillere.';

  @override
  String get settings_about_contributors_title => 'Bidragsytere';

  @override
  String get settings_about_supporters_title => 'Støttespillere';

  @override
  String get settings_about_thanks_empty =>
      'Listen fylles opp etter hvert som folk bidrar.';

  @override
  String get settings_theme_label => 'Tema';

  @override
  String get settings_theme_auto => 'Automatisk (følg systemet)';

  @override
  String get settings_theme_light => 'Lys';

  @override
  String get settings_theme_dark => 'Mørk';

  @override
  String get settings_language_label => 'Språk';

  @override
  String get settings_drive_side_label => 'Navigasjonsside';

  @override
  String get settings_drive_side_subtitle =>
      'Velg hvilken side av skjermen navigasjonsmenyen vises på.';

  @override
  String get settings_drive_side_left => 'Venstre';

  @override
  String get settings_drive_side_left_hint => 'LHD · standard';

  @override
  String get settings_drive_side_right => 'Høyre';

  @override
  String get settings_drive_side_right_hint => 'RHD-kjøretøy';

  @override
  String get settings_drive_side_auto => 'Automatisk';

  @override
  String get settings_drive_side_auto_hint => 'Hent fra kjøretøy';

  @override
  String get settings_drive_side_caption_left => 'Navigasjon til venstre';

  @override
  String get settings_drive_side_caption_right => 'Navigasjon til høyre';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Auto — kjøretøy melder venstrestyring';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Auto — kjøretøy melder høyrestyring';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Auto — kjøretøy utilgjengelig, bruker venstre';

  @override
  String get recordings_title => 'Opptak';

  @override
  String get recordings_segment_dashcam => 'Dashkamera';

  @override
  String get recordings_segment_surveillance => 'Overvåking';

  @override
  String get recordings_action_settings => 'Innstillinger';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 i dag · $arg2 totalt · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashkamera · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Overvåkning · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Velg en opptak';

  @override
  String get recordings_preview_placeholder_body =>
      'Trykk på noe på venstre side for å spille det.';

  @override
  String get diagnostics_section_adb_console => 'ADB konsol';

  @override
  String get diagnostics_section_traffic => 'Trafikkovervåker';

  @override
  String get diagnostics_section_camera_probe => 'Kamera-sonde';

  @override
  String get diagnostics_section_battery => 'Batterihelse';

  @override
  String get diagnostics_section_performance => 'Ytelse';

  @override
  String get diagnostics_hero_title => 'Systemdiagnostikk';

  @override
  String get diagnostics_hero_subtitle =>
      'Live helse, logger, og sonder for enheten.';

  @override
  String get diagnostics_health_clear => 'Alt i orden';

  @override
  String get diagnostics_health_section => 'Helse';

  @override
  String get diagnostics_health_network => 'Nettverk';

  @override
  String get diagnostics_health_storage => 'Lagring';

  @override
  String get diagnostics_health_camera => 'Kamera';

  @override
  String get diagnostics_health_battery => 'Batteri';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Tilkoblet';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Tunnel · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Tilkoblet';

  @override
  String get diagnostics_tunnel_state_offline => 'Frakoblet';

  @override
  String get diagnostics_tunnel_state_connecting => 'Forbindelse';

  @override
  String get diagnostics_network_mobile => 'Mobil';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Frakoblet';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 klipp · $arg2 brukt',
      one: '$arg1 klipp · $arg2 brukt',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 fri';
  }

  @override
  String get diagnostics_logs_card_title => 'Live hendelseslogg';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Streaming av output fra drift av tjenester.';

  @override
  String get diagnostics_tools_section => 'Verktøy';

  @override
  String get diagnostics_traffic_subtitle => 'Se live nettverks gjennomgang.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Sjekk tilkoblede kamera strømmer.';

  @override
  String get diagnostics_adb_subtitle => 'Åpne terminal på enheten.';

  @override
  String get diagnostics_battery_subtitle =>
      'Sjekk celle SOH og pakke statistikk.';

  @override
  String get diagnostics_settings_subtitle =>
      'App-innstillinger, tema og språk.';

  @override
  String get settings_action_reset_data => 'Tilbakestill data…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'På vakt';

  @override
  String get dashboard_subtitle_all_systems => 'Alle systemer online';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 av $arg2 tjenester online';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Fjerntilgang offline';

  @override
  String get dashboard_metric_recordings => 'Dagens opptak';

  @override
  String get dashboard_metric_storage => 'Lagring brukt';

  @override
  String get dashboard_metric_tunnel => 'Fjerntilgang';

  @override
  String get dashboard_metric_services => 'Bakgrunnstjenester';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Kjøretøy';

  @override
  String get dashboard_chip_recording_active => 'Opptak';

  @override
  String get dashboard_chip_recording_idle => 'Inaktiv';

  @override
  String get dashboard_vehicle_tap_to_set => 'Trykk på innstillingen';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Angi batterikapasitet';

  @override
  String get vehicle_dialog_model_label => 'Modell';

  @override
  String get vehicle_dialog_save => 'Lagre';

  @override
  String get settings_recording_tab_status => 'Status';

  @override
  String get settings_recording_tab_capture => 'Opptak';

  @override
  String get settings_recording_tab_quality => 'Kvalitet';

  @override
  String get settings_recording_tab_storage => 'Lagring';

  @override
  String get settings_recording_status_title => 'Opptaksstatus';

  @override
  String get settings_recording_status_current_state => 'Gjeldende tilstand';

  @override
  String get settings_recording_status_today_count => 'Opptak i dag';

  @override
  String get settings_recording_mode_title => 'Opptaksmodus (ACC PÅ)';

  @override
  String get settings_recording_mode_description =>
      'Velg når dashkameraet skal ta opp under kjøring.';

  @override
  String get settings_recording_mode_none_label => 'Ingen (standard)';

  @override
  String get settings_recording_mode_none_desc =>
      'Ingen opptak — overvåking virker fortsatt';

  @override
  String get settings_recording_mode_continuous_label => 'Kontinuerlig';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Ta opp hele tiden under kjøring';

  @override
  String get settings_recording_mode_drive_label => 'Kjøremodus';

  @override
  String get settings_recording_mode_drive_desc =>
      'Ta bare opp når kjøretøyet er i bevegelse';

  @override
  String get settings_recording_mode_proximity_label => 'Nærhetsvakt';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Ta opp når bevegelse oppdages';

  @override
  String get settings_recording_limit_title => 'Opptaksgrense';

  @override
  String get settings_recording_limit_description =>
      'Maksimal lengde per fil. Opptak deles i nye filer ved dette intervallet.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => 'Opptakskvalitet';

  @override
  String get settings_recording_storage_title => 'Opptakslagring';

  @override
  String get settings_recording_storage_location_label => 'Lagringsplassering';

  @override
  String get settings_recording_storage_internal => 'Intern';

  @override
  String get settings_recording_storage_sd_card => 'SD-kort';

  @override
  String get settings_recording_storage_sd_card_na => 'SD-kort (utilgj.)';

  @override
  String get settings_recording_storage_limit_label =>
      'Lagringsgrense — sletter eldste automatisk når den nås';

  @override
  String get settings_recording_storage_usage_label => 'Lagringsbruk';

  @override
  String get settings_recording_storage_files_label => 'Filer';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 brukt / grense $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 opptak',
      one: '$arg1 opptak',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Bane';

  @override
  String get settings_recording_storage_sd_free_label => 'Ledig på SD-kort';

  @override
  String get settings_recording_storage_internal_free_label => 'Ledig internt';

  @override
  String get settings_recording_format_title => 'Formater ekstern stasjon';

  @override
  String get settings_recording_format_warning =>
      'Sletter ALLE data på SD-kortet eller USB-stasjonen permanent.';

  @override
  String get settings_recording_format_confirm =>
      'Trykk igjen — ALLE data blir SLETTET';

  @override
  String get settings_recording_format_running => 'Formaterer… vent litt';

  @override
  String get settings_recording_format_button => 'Formater SD-kort / USB';

  @override
  String get settings_recording_format_no_drive =>
      'Fant ingen flyttbar stasjon';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Formatering fullført. Ny bane: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Databasekatalog';

  @override
  String get settings_recording_sync_description =>
      'Avstem opptaksindeksen mot filene på disken.';

  @override
  String get settings_recording_sync_running => 'Synkroniserer…';

  @override
  String get settings_recording_sync_button => 'Synkroniser database';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Synkronisert: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress =>
      'Synkronisering pågår allerede';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Synkronisering mislyktes: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Bruk endringer';

  @override
  String get settings_recording_dismiss => 'Lukk';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Å starte/stoppe $arg1 støttes ikke ennå';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 brukt · $arg2 gratis';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Lagring —';

  @override
  String get dashboard_tunnel_offline => 'Frakoblet';

  @override
  String get dashboard_tunnel_online => 'Tilkoblet';

  @override
  String get dashboard_tunnel_connecting => 'Kobler til…';

  @override
  String get dashboard_trips_this_week => 'Denne uken';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 turer',
      one: '$arg1 tur',
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
  String get dashboard_trips_label_trips => 'Turer';

  @override
  String get dashboard_trips_label_distance => 'Distanse';

  @override
  String get dashboard_trips_label_time => 'Kjøretid';

  @override
  String get dashboard_trips_no_data => 'Ingen turer registrert denne uken';

  @override
  String get dashboard_trips_unavailable =>
      'Begynn å kjøre for å se statistikk';

  @override
  String get dashboard_trips_loading => 'Laster…';

  @override
  String get dashboard_trips_view_all => 'Vis alle turer';

  @override
  String get dashboard_action_live => 'Direktevisning';

  @override
  String get dashboard_action_live_subtitle => 'Åpne kameravisning';

  @override
  String get dashboard_action_recordings => 'Opptak';

  @override
  String get dashboard_action_settings => 'Innstillinger';

  @override
  String get dashboard_action_settings_subtitle => 'Preferanser og om';

  @override
  String get settings_hero_title => 'Innstillinger';

  @override
  String get settings_hero_overline => 'Overdrevet';

  @override
  String get settings_hero_subtitle =>
      'Tone utseende, opptak, overvåking og data på enheten.';

  @override
  String get settings_overline_preferences => 'Foreløp';

  @override
  String get settings_overline_about_data => 'Om & DATA';

  @override
  String get settings_quick_theme_label => 'Tema';

  @override
  String get settings_quick_language_label => 'Språk';

  @override
  String get settings_section_recording_subtitle =>
      'Pre/post buffere, codec, lagringsgrenser.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Tidsplan, bevegelsesfølsomhet, objektdeteksjon.';

  @override
  String get settings_section_daemons_subtitle =>
      'Tor-tunnel og bakgrunnstjenester.';

  @override
  String get settings_about_row_title => 'Om BladeWatch';

  @override
  String get settings_about_row_subtitle => 'Versjon, lisens, støtteutvikling.';

  @override
  String get settings_reset_row_subtitle =>
      'Klar opptak, hendelser, eller alle cache.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Tema, språk og visuelle preferanser.';

  @override
  String get settings_theme_active_auto_caption =>
      'Automatisk følger systemets tema.';

  @override
  String get settings_theme_active_light_caption => 'Lyst tema er alltid på.';

  @override
  String get settings_theme_active_dark_caption => 'Mørkt tema er alltid på.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 av $arg2 språk tilgjengelig';
  }

  @override
  String get settings_language_card_title => 'Visningsspråk';

  @override
  String get settings_privacy_stance_title => 'På enheten som standard';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch kjører utelukkende på hovedenheten. Ingen telemetry forlater bilen din bortsett fra gjennom tunneler og integrasjoner du uttrykkelig konfigurerer.';

  @override
  String get settings_privacy_overline_storage => 'Lokal lagring';

  @override
  String get settings_privacy_overline_reset => 'Data tilbakestilling';

  @override
  String get settings_privacy_storage_clips_label => 'Klipper på disk';

  @override
  String get settings_privacy_storage_size_label => 'Total størrelse';

  @override
  String get settings_privacy_storage_unavailable => 'Ikke tilgjengelig';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 klipp',
      one: '$arg1 klipp',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Velg kategorier: opptak, hendelser, tjenestekonfigurasjoner, hurtigbufret telemetri...';

  @override
  String get settings_developer_overline => 'UTVIKLER';

  @override
  String get settings_developer_timing_logs_title => 'Tidslogger for tjenester';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Logg tidsmarkører under oppstart av tjenester. Slå av ved normal bruk for å holde logcat ren.';

  @override
  String get settings_developer_debug_logs_title =>
      'Feilsøkingslogger for utvikler';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Logg alle Activity- og Fragment-livssyklushendelser og oppstartstrinn til /storage/emulated/0/BladeWatch/data/debug_app.log. Krasj fanges alltid. Av som standard.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Kamera $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Kamera $arg1 (manuell)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Undersøker…';

  @override
  String get diagnostics_camera_value_offline => 'Frakoblet';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Ventelige data';

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
      other: '$arg1 klipp · $arg2 tatt opp',
      one: '$arg1 klipp · $arg2 tatt opp',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Bagasjerom';

  @override
  String get vehicle_tab_climate => 'Klima';

  @override
  String get vehicle_tab_seats => 'Seter';

  @override
  String get vehicle_tab_windows => 'Vinduer';

  @override
  String get vehicle_tab_lights => 'Lys';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Lading';

  @override
  String get vehicle_locked => 'Låst';

  @override
  String get vehicle_unlocked => 'Ulåst';

  @override
  String get vehicle_range_label => 'Rekkevidde';

  @override
  String get vehicle_data_unavailable => 'Kjøretøydata utilgjengelig.';

  @override
  String get vehicle_action_failed =>
      'Handling mislyktes. Sjekk tilkoblingen til kjøretøyet.';

  @override
  String get vehicle_open_trunk => 'Åpne bagasjerom';

  @override
  String get vehicle_close_trunk => 'Lukk bagasjerom';

  @override
  String get vehicle_trunk_info_open =>
      'Når du åpner bagasjerommet, låses bilen opp først.';

  @override
  String get vehicle_ac_on => 'AC På';

  @override
  String get vehicle_ac_off => 'AC av';

  @override
  String get vehicle_max_cooling_on => 'Maks kjøling: PÅ';

  @override
  String get vehicle_max_cooling_off => 'Maks kjøling: AV';

  @override
  String get vehicle_temp_label => 'Temperatur';

  @override
  String get vehicle_fan_speed_label => 'Viftehastighet';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Nivå $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return 'Inne: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => 'Fører';

  @override
  String get vehicle_seat_passenger => 'Passasjer';

  @override
  String get vehicle_seat_no_controls =>
      'Ingen setekontroller tilgjengelig for dette kjøretøyet.';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return 'Varme $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return 'Kjøling $arg1';
  }

  @override
  String get vehicle_heat_off => '(Av)';

  @override
  String get vehicle_heat_low => '(Lav)';

  @override
  String get vehicle_heat_high => '(Høy)';

  @override
  String get vehicle_seat_pos_1 => 'Posisjon 1';

  @override
  String get vehicle_seat_pos_2 => 'Posisjon 2';

  @override
  String get vehicle_all_windows => 'Alle vinduer';

  @override
  String get vehicle_window_awake_note => 'Fungerer bare når bilen er våken.';

  @override
  String get vehicle_window_front_left => 'Foran venstre';

  @override
  String get vehicle_window_front_right => 'Foran høyre';

  @override
  String get vehicle_window_rear_left => 'Bak venstre';

  @override
  String get vehicle_window_rear_right => 'Bak høyre';

  @override
  String get vehicle_window_close => 'Lukk';

  @override
  String get vehicle_window_close_vent => 'Lukk lufting';

  @override
  String get vehicle_window_vent_12 => 'Lufting 12%';

  @override
  String get vehicle_window_open_all => 'Åpne alle';

  @override
  String get vehicle_sunroof => 'Soltak';

  @override
  String get vehicle_sunshade => 'Solgardin';

  @override
  String get vehicle_btn_drl_title => 'Tidstidens løpende lys';

  @override
  String get vehicle_btn_slw_title => 'Varsel om hastighetsbegrensning';

  @override
  String get vehicle_control_section_charge_cap => 'Ladegrense';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Ladegrense støttes ikke av dette kjøretøyet.';

  @override
  String get vehicle_charge_limit_label => 'Ladegrense';

  @override
  String get vehicle_enable_charge_limit => 'Aktiver ladegrense';

  @override
  String get vehicle_charge_limit_range => 'Minimum 50%, maksimum 100%';

  @override
  String get vehicle_tyre_no_signal => 'INGEN SIGNAL';

  @override
  String get vehicle_tyre_slow_leak => 'SAKTE LEKKASJE';

  @override
  String get vehicle_tyre_fast_leak => 'RASK LEKKASJE';

  @override
  String get vehicle_tyre_low => 'LAV';

  @override
  String get vehicle_tyre_high => 'HØY';

  @override
  String get vehicle_tyre_ok => 'OK';

  @override
  String get vehicle_tyre_check_pressure => 'Sjekk trykk';

  @override
  String get vehicle_toggle_on => 'PÅ';

  @override
  String get vehicle_toggle_off => 'AV';

  @override
  String get vehicle_err_climate_control => 'Klimakontroll mislyktes.';

  @override
  String get vehicle_err_max_cooling => 'Maks kjøling mislyktes.';

  @override
  String get vehicle_err_drl_control => 'Kjørelys-kontroll mislyktes.';

  @override
  String get vehicle_err_slw_control => 'ADAS-kontroll mislyktes.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Veksling av ladegrense mislyktes.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Reduser $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Øk $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Kobler til…';

  @override
  String get vehicle_appearance_model_title => 'Velg modell';

  @override
  String get vehicle_appearance_custom_color => 'Egendefinert farge';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Lading: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Rekkevidde: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Lading: —';

  @override
  String get vehicle_status_range_unknown => 'Rekkevidde: —';

  @override
  String get startup_subtitle => 'Gjør dashcam-en din klar';

  @override
  String get startup_header_preparing => 'Gjør klar…';

  @override
  String get startup_header_starting => 'Starter opp…';

  @override
  String get startup_header_verifying => 'Nesten klar…';

  @override
  String get startup_header_ready => 'Alt er klart';

  @override
  String get startup_daemon_camera => 'Kamera';

  @override
  String get startup_daemon_camera_desc => 'Livevisning og opptak';

  @override
  String get startup_daemon_sentry => 'Vaktmodus';

  @override
  String get startup_daemon_sentry_desc => 'Bevegelsesdeteksjon og varsler';

  @override
  String get startup_daemon_parking => 'Parkeringsvakt';

  @override
  String get startup_daemon_parking_desc => 'Holder vakt mens du står parkert';

  @override
  String get startup_status_waiting => 'Venter';

  @override
  String get startup_status_starting => 'Starter';

  @override
  String get startup_status_ready => 'Klar';

  @override
  String get startup_status_failed => 'Mislyktes';

  @override
  String get startup_continue_anyway => 'Fortsett likevel';

  @override
  String get startup_continue => 'Fortsett →';

  @override
  String get live_retry => 'Prøv igjen';

  @override
  String get live_connecting => 'Kobler til kamera…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Feil: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Kamera utilgjengelig\n$arg1';
  }

  @override
  String get live_direction_all => 'Alle';

  @override
  String get live_direction_front => 'Foran';

  @override
  String get live_direction_right => 'Høyre';

  @override
  String get live_direction_rear => 'Bak';

  @override
  String get live_direction_left => 'Venstre';

  @override
  String get trip_no_route_data => 'Ingen rutedata for denne turen';

  @override
  String get trips_tab_trips => 'Turer';

  @override
  String get trips_tab_stats => 'Statistikk';

  @override
  String get trips_tab_storage => 'Lagring';

  @override
  String get trips_filter_7_days => '7 dager';

  @override
  String get trips_filter_14_days => '14 dager';

  @override
  String get trips_filter_30_days => '30 dager';

  @override
  String trips_load_error(Object message) {
    return 'Feil: $message';
  }

  @override
  String get trips_empty_state => 'Ingen turer registrert ennå';

  @override
  String get trips_period_summary_title => 'Periodesammendrag';

  @override
  String get trips_stat_trips => 'Turer';

  @override
  String get trips_stat_hours => 'Timer';

  @override
  String get trips_stat_efficiency => 'Effektivitet';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Poeng: $score';
  }

  @override
  String get trips_driver_score_title => 'Sjåførpoeng';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Totalt: $score / 100';
  }

  @override
  String get trips_range_title => 'Personlig rekkevidde';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD-estimat: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'Drivstoffrekkevidde: $km';
  }

  @override
  String get trips_range_no_data => 'Ikke nok data ennå';

  @override
  String get trips_dna_title => 'Kjøre-DNA';

  @override
  String get trips_dna_anticipation => 'Forutseenhet';

  @override
  String get trips_dna_smoothness => 'Jevnhet';

  @override
  String get trips_dna_speed_discipline => 'Fartsdisiplin';

  @override
  String get trips_dna_efficiency => 'Effektivitet';

  @override
  String get trips_dna_consistency => 'Konsistens';

  @override
  String get trips_storage_title => 'Turlagring';

  @override
  String get trips_storage_analytics_label => 'Turanalyse';

  @override
  String get trips_storage_rate_label => 'Strømpris';

  @override
  String get trips_storage_fuel_price_label => 'Drivstoffpris (per liter)';

  @override
  String get trips_storage_tank_capacity_label => 'Tankvolum (liter)';

  @override
  String get trips_storage_distance_unit_label => 'Distanseenhet';

  @override
  String get trips_storage_location_label => 'Lagringsplassering';

  @override
  String get trips_storage_internal => 'Intern';

  @override
  String get trips_storage_sd_card => 'SD-kort';

  @override
  String get trips_storage_sd_card_unavailable => 'SD-kort (utilgj.)';

  @override
  String get trips_storage_apply => 'Bruk endringer';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit brukt / grense $limit MB · $count turer';
  }

  @override
  String get trips_sync_title => 'Databasekatalog';

  @override
  String get trips_sync_description =>
      'Avstemmer turindeksen mot telemetrifilene på disken.';

  @override
  String get trips_sync_button => 'Synkroniser database';

  @override
  String get trips_sync_running => 'Synkroniserer…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Synkronisert: +$added -$removed ($total totalt)';
  }

  @override
  String get trips_sync_failed_generic => 'Synkronisering mislyktes';

  @override
  String get trips_detail_summary_title => 'Tursammendrag';

  @override
  String get trips_detail_distance => 'Distanse';

  @override
  String get trips_detail_duration => 'Varighet';

  @override
  String get trips_detail_energy => 'Energi';

  @override
  String get trips_detail_avg_speed => 'Gj.sn. fart';

  @override
  String get trips_detail_max_speed => 'Maks. fart';

  @override
  String get trips_detail_soc => 'Ladenivå';

  @override
  String get trips_detail_cost => 'Kostnad';

  @override
  String get trips_detail_ext_temp => 'Utetemp.';

  @override
  String get trips_detail_fuel_used => 'Drivstoff';

  @override
  String get trips_detail_fuel_cost => 'Drivstoffkostnad';

  @override
  String get trips_detail_electric_cost => 'Strømkostnad';

  @override
  String get trips_detail_elev_gain => 'Stigning';

  @override
  String get trips_detail_scores_title => 'Kjørepoeng';

  @override
  String get trips_detail_unavailable => 'Turdetaljer utilgjengelig';

  @override
  String get trips_detail_loading => 'Laster tur…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count GPS-punkter registrert';
  }

  @override
  String get rec_severity_critical => 'KRITISK';

  @override
  String get rec_severity_alert => 'VARSEL';

  @override
  String get location_loading_title => 'Laster kart';

  @override
  String get location_permission_missing_title => 'Posisjonstillatelse kreves';

  @override
  String get location_permission_denied_title => 'Tillatelse avslått';

  @override
  String get location_provider_disabled_title => 'GPS deaktivert';

  @override
  String get location_waiting_for_fix_title => 'Venter på GPS-signal';

  @override
  String get location_car_location_title => 'Bilens posisjon';

  @override
  String get location_stale_title => 'Posisjon utdatert';

  @override
  String get location_tile_failure_title => 'Kart utilgjengelig';

  @override
  String get location_tile_failure_subtitle => 'Nettverk utilgjengelig';

  @override
  String get location_error_title => 'Posisjonsfeil';

  @override
  String get location_action_grant => 'Gi tillatelse';

  @override
  String get location_action_retry => 'Prøv igjen';

  @override
  String get location_mode_auto => 'Automatisk';

  @override
  String get location_mode_light => 'Lys';

  @override
  String get location_mode_dark => 'Mørk';

  @override
  String get cd_recenter_on_car => 'Sentrer på bilen';

  @override
  String get recording_lib_no_recordings_normal => 'Ingen vanlige opptak';

  @override
  String get recording_lib_no_recordings_sentry => 'Ingen overvåkingshendelser';

  @override
  String get recording_lib_no_recordings_proximity => 'Ingen nærhetshendelser';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'person';

  @override
  String get video_player_legend_car => 'bil';

  @override
  String get video_player_legend_bike => 'sykkel';

  @override
  String get video_player_legend_motion => 'bevegelse';

  @override
  String get recording_lib_proximity_very_close => 'svært nær';

  @override
  String get recording_lib_proximity_close => 'nær';

  @override
  String get recording_lib_proximity_mid => 'middels';

  @override
  String get recording_lib_proximity_far => 'langt unna';

  @override
  String get surveillance_tab_general => 'Generelt';

  @override
  String get surveillance_tab_detection => 'Deteksjon';

  @override
  String get surveillance_tab_recording => 'Opptak';

  @override
  String get surveillance_tab_storage => 'Lagring';

  @override
  String get surveillance_tab_advanced => 'Avansert';

  @override
  String get surveillance_general_title => 'Overvåkingsmodus';

  @override
  String get surveillance_general_enable => 'Aktiver overvåking';

  @override
  String get surveillance_general_status => 'Status';

  @override
  String get surveillance_general_status_running => 'Kjører';

  @override
  String get surveillance_general_status_idle => 'Inaktiv';

  @override
  String get surveillance_general_events_today => 'Hendelser i dag';

  @override
  String get surveillance_safe_locations_title => 'Trygge steder';

  @override
  String get surveillance_safe_locations_subtitle =>
      'Kameraet starter ikke når du parkerer her';

  @override
  String get surveillance_safe_locations_enable => 'Deaktiver på trygge steder';

  @override
  String get surveillance_safe_locations_empty =>
      'Ingen trygge steder lagt til ennå';

  @override
  String get surveillance_safe_locations_add_current =>
      'Legg til nåværende posisjon som trygg sone';

  @override
  String get surveillance_safe_locations_no_gps =>
      'GPS-posisjon ikke tilgjengelig';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Deteksjonsinnstillinger';

  @override
  String get surveillance_detection_preset_label => 'Miljøforhåndsinnstilling';

  @override
  String get surveillance_preset_outdoor => 'Utendørs';

  @override
  String get surveillance_preset_garage => 'Garasje';

  @override
  String get surveillance_preset_street => 'Gate';

  @override
  String get surveillance_preset_custom => 'Tilpasset';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Følsomhet (1=streng, 5=følsom): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Oppdag objekter';

  @override
  String get surveillance_detection_object_person => 'person';

  @override
  String get surveillance_detection_object_car => 'bil';

  @override
  String get surveillance_detection_object_bike => 'sykkel';

  @override
  String get surveillance_recording_title => 'Hendelsesopptak';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Forhåndsopptak (sekunder før hendelsen): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Etteropptak (sekunder etter hendelsen): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Overvåkingslagring';

  @override
  String get surveillance_storage_location_label => 'Lagringssted';

  @override
  String get surveillance_storage_internal => 'Internt';

  @override
  String get surveillance_storage_sd_card => 'SD-kort';

  @override
  String get surveillance_storage_sd_card_na => 'SD-kort (ikke tilgjengelig)';

  @override
  String get surveillance_storage_limit_label =>
      'Lagringsgrense – sletter eldste automatisk ved grensen';

  @override
  String get surveillance_storage_usage_label => 'Lagringsbruk';

  @override
  String get surveillance_storage_files_label => 'Filer';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 brukt / grense $arg2';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 hendelser',
      one: '$arg1 hendelse',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'Bane';

  @override
  String get surveillance_format_title => 'Formater ekstern stasjon';

  @override
  String get surveillance_format_warning =>
      'Sletter permanent ALL data på SD-kortet eller USB-stasjonen.';

  @override
  String get surveillance_format_button => 'Formater SD-kort/USB';

  @override
  String get surveillance_format_confirm =>
      'Trykk igjen – ALL data vil bli SLETTET';

  @override
  String get surveillance_format_running => 'Formaterer … vennligst vent';

  @override
  String get surveillance_dismiss => 'Lukk';

  @override
  String get surveillance_sync_title => 'Databasekatalog';

  @override
  String get surveillance_sync_description =>
      'Avstemmer overvåkingsindeksen med filene på disken.';

  @override
  String get surveillance_sync_button => 'Synkroniser database';

  @override
  String get surveillance_sync_running => 'Synkroniserer …';

  @override
  String get surveillance_advanced_camera_title => 'Kameravalg';

  @override
  String get surveillance_advanced_camera_front => 'Foran';

  @override
  String get surveillance_advanced_camera_right => 'Høyre';

  @override
  String get surveillance_advanced_camera_rear => 'Bak';

  @override
  String get surveillance_advanced_camera_left => 'Venstre';

  @override
  String get surveillance_advanced_ai_title => 'KI og avskrekking';

  @override
  String get surveillance_advanced_ai_detection => 'KI-deteksjon';

  @override
  String get surveillance_advanced_night_mode => 'Nattmodus';

  @override
  String get surveillance_advanced_deterrent_label => 'Avskrekkingshandling';

  @override
  String get surveillance_deterrent_silent => 'Stille';

  @override
  String get surveillance_deterrent_horn => 'Horn';

  @override
  String get surveillance_deterrent_flash => 'Blits';

  @override
  String get surveillance_apply_button => 'Bruk endringer';

  @override
  String get surveillance_apply_failed => 'Lagring mislyktes';

  @override
  String get dashboard_tor_bootstrapping => 'Kobler til Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'Slik åpner du denne adressen';

  @override
  String get dashboard_tor_help_title => 'Åpne denne adressen';

  @override
  String get dashboard_tor_help_android =>
      'Android: installer Tor Browser fra Google Play eller F-Droid, åpne den og lim inn adressen.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone og iPad: installer Onion Browser fra App Store, åpne den og lim inn adressen. Tor Browser finnes ikke for iOS.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS og Linux: last ned Tor Browser fra torproject.org, åpne den og lim inn adressen.';

  @override
  String get dashboard_tor_help_password_note =>
      'Passordet trengs fortsatt når siden er lastet.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'Skann for nedlastingssiden til Tor Browser';

  @override
  String get dashboard_tor_help_close => 'Greit';
}
