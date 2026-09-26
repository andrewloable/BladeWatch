// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Mantenere il monitoraggio del veicolo BladeWatch attivo in background. Questo servizio non legge né interagisce con il contenuto dello schermo.';

  @override
  String get action_cancel => 'Annulla';

  @override
  String get action_clear_plain => 'Cancella';

  @override
  String get action_select_all => 'Selezionare tutti';

  @override
  String get action_select_all_short => 'Tutti';

  @override
  String get action_delete => 'Elimina';

  @override
  String get action_done => 'FATTO';

  @override
  String get action_remind_me_later => 'RICORDAMELO PIÙ TARDI';

  @override
  String get action_retry => 'Riprova';

  @override
  String get action_run => 'Esegui';

  @override
  String get action_clear_output => 'Cancella output';

  @override
  String get cd_camera => 'Fotocamera';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'Codice QR';

  @override
  String get cd_clear_logs => 'Cancella i log';

  @override
  String get cd_expand_collapse => 'Espandi/Comprimi';

  @override
  String get cd_recording_status => 'Stato di registrazione';

  @override
  String get cd_trip_tracking_status => 'Lo stato del tracciamento dei viaggi';

  @override
  String get cd_video_thumbnail => 'Miniatura video';

  @override
  String get cd_play => 'Riproduci';

  @override
  String get cd_back => 'Indietro';

  @override
  String get cd_play_pause => 'Riproduzione/Pausa';

  @override
  String get cd_player_prev => 'Registrazione precedente';

  @override
  String get cd_player_next => 'Prossima registrazione';

  @override
  String get cd_player_maximize => 'Ingrandisci lettore';

  @override
  String get cd_player_minimize => 'Esci da schermo intero';

  @override
  String get cd_delete => 'Elimina';

  @override
  String get cd_decrease => 'Diminuisci';

  @override
  String get cd_increase => 'Aumenta';

  @override
  String get cd_expand => 'Espandi';

  @override
  String get cd_configure => 'Configura';

  @override
  String get cd_download_log => 'Scarica registro';

  @override
  String get cd_reset => 'Ripristina';

  @override
  String get cd_battery => 'Batteria';

  @override
  String get cd_step_completed => 'Passo completato';

  @override
  String get cd_permission_granted => 'Permesso concesso';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'PROCESSI';

  @override
  String get logs_panel_title => 'Reggi';

  @override
  String get url_connecting => 'Connessione...';

  @override
  String get camera_selection_title => 'Selezione della telecamera';

  @override
  String get camera_selection_subtitle =>
      'Selezionare la fonte della fotocamera panoramica';

  @override
  String get camera_current_auto => 'Attuale: Auto';

  @override
  String get camera_option_auto => 'Auto (rilevato all\'avvio)';

  @override
  String get camera_option_0 => 'Fotocamera 0 — Atto';

  @override
  String get camera_option_1 => 'Fotocamera 1 — Seal (di default)';

  @override
  String get camera_option_2 => 'Fotocamera 2';

  @override
  String get camera_option_3 => 'Fotocamera 3';

  @override
  String get camera_option_4 => 'Fotocamera 4';

  @override
  String get camera_option_5 => 'Fotocamera 5';

  @override
  String get camera_selection_hint =>
      'Auto sceglie la fotocamera giusta per il tuo allestimento a ogni avvio. Camera 1 = BYD Seal, Camera 0 = allestimenti Atto. Riavvia il servizio fotocamera dopo aver cambiato l\'ID della fotocamera affinché l\'impostazione abbia effetto.';

  @override
  String get dashboard_qr_waiting => 'Aspettando il tunnel...';

  @override
  String get dashboard_daemons_running_default => '0/5 in esecuzione';

  @override
  String get dashboard_regenerate_token => 'Rigenera token';

  @override
  String get cd_set_password => 'Imposta password personalizzata';

  @override
  String get toast_password_save_failed =>
      'Salvataggio password non riuscito — servizio non pronto';

  @override
  String get setup_guide_title => 'Iniziare';

  @override
  String get setup_guide_subtitle =>
      'Tre passi veloci per ottenere la migliore esperienza:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Scegli la tua lingua';

  @override
  String get setup_language_body =>
      'Per impostazione predefinita usa la lingua dell’unità principale. Tocca per sceglierne un’altra per l’app BladeWatch e il tunnel web.';

  @override
  String get setup_language_button => 'Scegliete la lingua';

  @override
  String get setup_autostart_title =>
      'Disattivare la restrizione di avvio automatico';

  @override
  String get setup_autostart_body =>
      'Tocca qui sotto per aprire BYD Auto-Start, poi deseleziona BladeWatch E Servizio BladeWatch. Senza questo, la registrazione non si avvia all’accensione dell’auto — dovrai aprire l’app ogni volta. BYD azzera questa impostazione a ogni installazione.';

  @override
  String get setup_autostart_button => 'Apri BYD Auto-Start';

  @override
  String get setup_overlay_title =>
      'Permettere la visualizzazione su altre app';

  @override
  String get setup_overlay_body =>
      'Abilitare questo per mostrare un indicatore di stato fluttuante per la registrazione e il tracciamento dei viaggi in cima ad altre app.';

  @override
  String get setup_overlay_button => 'Apri le impostazioni di sovrapposizione';

  @override
  String get cd_close => 'Chiudi';

  @override
  String get language_picker_title => 'Lingua';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return 'Lingue disponibili $arg1';
  }

  @override
  String get language_picker_subtitle_pending => 'Scegliere una lingua';

  @override
  String get language_auto_title => 'Autovettura';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Sistema di seguimento · $arg1';
  }

  @override
  String get language_not_saved =>
      'Lingua applicata, ma non è stato possibile salvarla: verrà reimpostata al riavvio.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Automatico';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Digita un comando…';

  @override
  String get adb_preset_commands_header => 'Comandi predefiniti';

  @override
  String get adb_output_header => 'Output';

  @override
  String get adb_output_ready => 'Pronti per i comandi...';

  @override
  String get adb_console_hero_title => 'Consola ADB';

  @override
  String get adb_console_hero_subtitle =>
      'Eseguire i comandi shell sul dispositivo';

  @override
  String get adb_console_unavailable_title => 'ADB non è connesso';

  @override
  String get adb_console_unavailable_body =>
      'Su questo veicolo, il normale interruttore «Debug USB» nelle Opzioni sviluppatore non basta da solo: deve essere attiva anche l\'impostazione ADB wireless (debug di rete) dell\'head unit, e un aggiornamento di sistema può disattivarla. Riattiva l\'ADB wireless sull\'head unit, oppure collegati via USB.';

  @override
  String get adb_console_auth_pending_title => 'In attesa di approvazione';

  @override
  String get adb_console_auth_pending_body =>
      'Controlla sullo schermo dell\'head unit la richiesta «Consentire il debug USB?» e accettala, poi riprova.';

  @override
  String get performance_connecting => 'Connessione al monitor prestazioni…';

  @override
  String get performance_hero_title => 'Prestazioni di sistema';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'Utilizzo sistema';

  @override
  String get performance_cpu_app_usage => 'Utilizzo app';

  @override
  String get performance_frequency_label => 'Frequenza';

  @override
  String get performance_temperature_label => 'Temperatura';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Memoria';

  @override
  String get performance_usage_label => 'Utilizzo';

  @override
  String get performance_memory_total => 'Totale';

  @override
  String get performance_memory_used => 'Usata';

  @override
  String get performance_memory_app => 'App';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'Processo dell\'app';

  @override
  String get performance_threads_label => 'Thread';

  @override
  String get performance_gc_cycles_label => 'Cicli GC';

  @override
  String get performance_open_fds_label => 'FD aperti';

  @override
  String get performance_refreshing_footer => 'Aggiornamento ogni 3 secondi';

  @override
  String get webview_loading => 'Caricamento...';

  @override
  String get reset_title => 'Reimposta i dati';

  @override
  String get reset_subtitle => 'Pulire i dati accumulati per categoria';

  @override
  String get reset_warning =>
      'Questa operazione non può essere annullata. Le registrazioni, i viaggi e la cronologia della batteria saranno eliminati definitivamente.';

  @override
  String get reset_cat_trips => 'Viaggi';

  @override
  String get reset_cat_trips_desc =>
      'Storia del viaggio, percorsi, rilievi settimanali/mensili';

  @override
  String get reset_cat_soc_history => 'Storia SoC & 12V';

  @override
  String get reset_cat_soc_history_desc =>
      'campioni SoC, sessioni di ricarica, registri di tensione';

  @override
  String get reset_cat_recordings => 'Registrazioni (video)';

  @override
  String get reset_cat_recordings_desc =>
      'Tutti i file MP4 nella cartella delle registrazioni';

  @override
  String get reset_cat_sentry_events => 'Eventi di sorveglianza';

  @override
  String get reset_cat_sentry_events_desc =>
      'Clip di eventi di sorveglianza e file JSON associati';

  @override
  String get reset_cat_proximity => 'Registrazioni di prossimità';

  @override
  String get reset_cat_proximity_desc => 'Radar-triggered eventi MP4';

  @override
  String get reset_cat_trip_files => 'Archivi di telemetria di viaggio';

  @override
  String get reset_cat_trip_files_desc =>
      'Telemetria per viaggio JSON su disco';

  @override
  String get recording_lib_chip_any => 'Qualsiasi';

  @override
  String get recording_lib_chip_person => 'Persona';

  @override
  String get recording_lib_chip_vehicle => 'Veicolo';

  @override
  String get recording_lib_chip_bike => 'Bicicletta';

  @override
  String get recording_lib_chip_animal => 'Animali';

  @override
  String get recording_lib_chip_alert => 'Avviso';

  @override
  String get recording_lib_chip_critical => 'Critico';

  @override
  String get recording_lib_selected_count_zero => '0 selezionato';

  @override
  String get recording_lib_no_recordings => 'Nessuna registrazione';

  @override
  String get recording_lib_filter_button => 'Filtro';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filtro · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Filtra registrazioni';

  @override
  String get recording_lib_filter_apply => 'Applica';

  @override
  String get recording_lib_filter_reset => 'Ripristina';

  @override
  String get recording_lib_filter_section_what => 'Cosa';

  @override
  String get recording_lib_filter_section_severity => 'Gravità';

  @override
  String get recording_lib_filter_section_type => 'Tipo';

  @override
  String get recording_lib_chip_type_normal => 'Normale';

  @override
  String get recording_lib_chip_type_proximity => 'Vicinanza';

  @override
  String get recording_lib_date_today => 'Oggi';

  @override
  String get recording_lib_date_yesterday => 'Ieri';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clip',
      one: '$arg1 clip',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Scegli una data';

  @override
  String get recording_lib_date_all_days => 'Tutti i giorni';

  @override
  String get cd_clear_date_filter => 'Mostra tutti i giorni';

  @override
  String get recording_lib_section_morning => 'Mattina';

  @override
  String get recording_lib_section_afternoon => 'Pomeriggio';

  @override
  String get recording_lib_section_evening => 'Sera';

  @override
  String get recording_lib_section_night => 'Notte';

  @override
  String get cd_previous_day => 'Giorno precedente';

  @override
  String get cd_next_day => 'Giorno successivo';

  @override
  String get cd_open_filters => 'Apri filtri';

  @override
  String get cd_clear_filter => 'Cancella filtro';

  @override
  String get player_title_recording => 'Registrazione';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Servizio fotocamera';

  @override
  String get daemon_name_surveillance => 'Servizio di sorveglianza';

  @override
  String get daemon_name_acc => 'Sorveglianza ACC';

  @override
  String get daemons_hero_title => 'Servizi di background';

  @override
  String get daemons_count_pending => 'Caricamento servizi…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 di $arg2 in esecuzione';
  }

  @override
  String get battery_health_title => 'Salute della batteria';

  @override
  String get battery_health_unavailable => 'Non disponibile';

  @override
  String get battery_health_unavailable_desc =>
      'La stima dello stato della batteria non è disponibile.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% su $arg2';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Le registrazioni $arg1 sono state cancellate',
      one: 'La registrazione $arg1 è cancellata',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Cancellare le registrazioni $arg1',
      one: 'Cancellare la registrazione $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'Questa azione eliminerà definitivamente $arg1 registrazioni. Non può essere annullata.',
      one:
          'Questa azione eliminerà definitivamente $arg1 registrazione. Non può essere annullata.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'L\'app è aggiornata (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Permesso di archiviazione richiesto per le registrazioni';

  @override
  String get toast_url_copied_short => 'URL copiato!';

  @override
  String get toast_camera_set_to_auto => 'Camera impostata su Auto';

  @override
  String get toast_failed_to_save_short => 'Non riuscito a salvare';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Fallito: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Fotocamera $arg1 impostata — prossimo ciclo ACC';
  }

  @override
  String get toast_clearing_camera_config =>
      'Riprendo la configurazione della telecamera...';

  @override
  String get toast_restarting_camera_daemon =>
      'Riavvio del servizio fotocamera...';

  @override
  String get toast_camera_daemon_restarting =>
      'Servizio fotocamera in riavvio con scansione completa';

  @override
  String get toast_camera_restart_failed =>
      'Configurazione azzerata, ma il riavvio del servizio non è riuscito. Riavviare manualmente.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Fallito: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'Selezionare almeno una categoria';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Fallito ripristino: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return 'Il monitor del traffico $arg1...';
  }

  @override
  String get dialog_close => 'Chiudi';

  @override
  String get dialog_reset => 'Ripristina';

  @override
  String get dialog_delete => 'Elimina';

  @override
  String get dialog_save => 'Salva';

  @override
  String get dialog_enable => 'Attiva';

  @override
  String get dialog_disable => 'Disattiva';

  @override
  String get dialog_keep_enabled => 'Mantieni attivo';

  @override
  String get dialog_keep_disabled => 'Mantieni disattivato';

  @override
  String get dialog_regenerate => 'Rigenera';

  @override
  String get dialog_reset_selected => 'Reimposta selezionati';

  @override
  String get dialog_reset_following_title => 'Reimpostare quanto segue?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Questa azione non può essere annullata.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Reimpostazione completata';

  @override
  String get dialog_traffic_cannot_check_title =>
      'Non riesce a controllare lo stato';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB non è connesso e l\'app non è riuscita a riconnettersi automaticamente.\n\nSu questo veicolo, il normale interruttore \"Debug USB\" nelle Opzioni sviluppatore da solo non basta: deve essere attiva anche l\'impostazione ADB wireless (debug di rete) dell\'unità centrale, che un aggiornamento di sistema può disattivare. Riattivi l\'ADB wireless sull\'unità centrale, oppure si colleghi via USB.\n\nLo stato si aggiornerà automaticamente una volta connesso.';

  @override
  String get dialog_traffic_disable_title =>
      'Disattivare il monitor del traffico BYD?';

  @override
  String get dialog_traffic_disable_message =>
      'Il BYD Traffic Monitor (com.byd.trafficmonitor) è un’app di sistema integrata che monitora di continuo il traffico stradale in background.\n\nPerché disattivarlo?\n\n• Consuma dati mobili (anche a veicolo fermo)\n• Occupa CPU e batteria in background\n• Non serve se usi un’app di navigazione separata\n• Può interferire con l’uso della rete da parte della dashcam\n\nDisattivarlo è sicuro: incide solo sul livello traffico integrato nella mappa. Navigazione, Bluetooth e tutte le altre funzioni dell’auto restano invariate.\n\nDopo la disattivazione serve un riavvio forzato (tieni premuto il pulsante della console centrale 5 secondi).';

  @override
  String get dialog_traffic_enable_title =>
      'Riattivare il monitor del traffico BYD?';

  @override
  String get dialog_traffic_enable_message =>
      'Il Traffic Monitor BYD è attualmente disabilitato.\n\nRiattivarlo ripristinerà la sovrapposizione del traffico integrata sulla mappa di navigazione. Si noti che eseguirà in background e consumerà dati mobili.\n\nÈ necessario un reboot duro dopo l\'attivazione (tenere il pulsante della console centrale 5 secondi).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Monitor del traffico $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'La modifica è stata applicata.\n\nEsegui ora un riavvio forzato:\nTieni premuto il pulsante della console centrale per 5 secondi.';

  @override
  String get traffic_monitor_loading => 'Monitor del traffico: controllo...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Monitor del traffico (toccare per controllare)';

  @override
  String get reset_label_trips => 'Viaggi';

  @override
  String get reset_label_soc_history => 'Storia SoC + 12V';

  @override
  String get reset_label_recordings => 'Registrazioni';

  @override
  String get reset_label_sentry_events => 'Eventi di sorveglianza';

  @override
  String get reset_label_proximity => 'Registrazioni di prossimità';

  @override
  String get reset_label_trip_files => 'Archivi di telemetria di viaggio';

  @override
  String get dialog_regenerate_token_title => 'Rigenera token';

  @override
  String get dialog_regenerate_token_message =>
      'Questo invaliderà il token corrente. Tutte le sessioni attive verranno disconnesse. Continuare?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Nuovo token generato. Tutte le sessioni sono state disconnesse.';

  @override
  String get toast_token_regenerated_restart =>
      'Token rigenerato. Potrebbe essere necessario riavviare i servizi per applicarlo.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token rigenerato. Impossibile notificare il servizio in background.';

  @override
  String get toast_token_regenerated => 'Token rigenerato';

  @override
  String get dashboard_waiting_url => 'In attesa del tunnel URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 in esecuzione';
  }

  @override
  String get clip_label_access_code => 'Codice di accesso';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'Non è necessaria alcuna configurazione per $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'Il token non può essere vuoto';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Prendo il registro $arg1...';
  }

  @override
  String get toast_log_empty_or_missing =>
      'Il file log è vuoto o non è stato trovato';

  @override
  String get toast_log_empty => 'Il file log è vuoto';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Non riuscito a salvare il registro: $arg1';
  }

  @override
  String get toast_log_not_found =>
      'File di registro non trovato o illeggibile';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return 'Log $arg1 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Condividere $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== Log $arg1 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Fonte: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'Esportazione: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'NOTA: registro troncato alle ultime 10000 righe (totale: $arg1 righe)',
      one:
          'NOTA: registro troncato alle ultime 10000 righe (totale: $arg1 riga)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Non riesco a riprodurre video: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Elimina registrazione';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'Eliminare $arg1?\nL’operazione non può essere annullata.';
  }

  @override
  String get toast_recording_deleted => 'La registrazione è cancellata';

  @override
  String get toast_recording_delete_failed =>
      'Non è stato possibile eliminare la registrazione';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 cancellato, $arg2 fallito';
  }

  @override
  String get play_with_chooser => 'Giocare con';

  @override
  String setup_version_banner(Object arg1) {
    return 'Aggiornato a v$arg1 — riconferma autoavvio, BYD lo cancella su ogni installazione';
  }

  @override
  String get setup_overlay_already_granted => 'Già concesso';

  @override
  String camera_current_manual(Object arg1) {
    return 'Attuale: Camera $arg1 (Manuale)';
  }

  @override
  String get camera_current_auto_label => 'Attuale: Auto';

  @override
  String get soh_estimation_active => 'Attivo di stima';

  @override
  String get soh_oem_readout =>
      'Lettura SOH del veicolo — in attesa della stima calcolata';

  @override
  String get soh_nominal_baseline =>
      'Riferimento nominale — in attesa di dati SOH attendibili';

  @override
  String get soh_no_estimate_yet => 'Nessuna stima ancora — attesa di dati';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 selezionato';
  }

  @override
  String get video_player_playback_error => 'Errore di riproduzione';

  @override
  String get video_player_no_events => 'Nessun evento';

  @override
  String get daemon_configuration_required => 'Configurazione necessaria';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Giocatore video';

  @override
  String get status_overlay_notif_title => 'BladeWatch Statuto';

  @override
  String get status_overlay_notif_text => 'Status overlay attivo';

  @override
  String get rail_dashboard => 'Pannello';

  @override
  String get rail_live => 'In diretta';

  @override
  String get rail_recordings => 'Registrazioni';

  @override
  String get rail_vehicle => 'Veicolo';

  @override
  String get rail_trips => 'Viaggi';

  @override
  String get rail_location => 'Posizione';

  @override
  String get rail_diagnostics => 'Diagnostiche';

  @override
  String get rail_settings => 'Impostazioni';

  @override
  String get settings_section_appearance => 'Apparizione';

  @override
  String get settings_section_recording => 'Registrazione';

  @override
  String get settings_section_surveillance => 'Sorveglianza';

  @override
  String get settings_section_daemons => 'Servizi';

  @override
  String get settings_section_privacy => 'Privacy & dati';

  @override
  String get settings_section_trips => 'Viaggi';

  @override
  String get settings_section_trips_subtitle =>
      'Tariffe, unità di distanza e dove vengono salvati i viaggi';

  @override
  String get settings_section_overlay => 'Overlay di stato';

  @override
  String get settings_overlay_subtitle =>
      'Scegliere quali segmenti della pillola di stato galleggiante rimangono visibili.';

  @override
  String get settings_overlay_camera_title => 'Indicatore di telecamera';

  @override
  String get settings_overlay_camera_subtitle =>
      'Mostra il badge REC / PROX mentre l\' registrazione è attiva.';

  @override
  String get settings_overlay_trip_title => 'Indicare Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Mostrate il distintivo TRIP mentre la rilevazione dei viaggi è in corso.';

  @override
  String get settings_section_about => 'Informazioni';

  @override
  String get settings_subrail_overline => 'SETTINGI';

  @override
  String get cd_settings_subrail => 'Barra laterale impostazioni';

  @override
  String get settings_privacy_title => 'Privacy & dati';

  @override
  String get settings_privacy_body =>
      'Il ripristino elimina l\'indice di registrazione, le credenziali in cache, lo stato del servizio e le preferenze sul dispositivo. L\'operazione non può essere annullata.';

  @override
  String get settings_about_title => 'A proposito di BladeWatch';

  @override
  String get settings_about_version_label => 'Versione';

  @override
  String get settings_about_package_label => 'Costruire';

  @override
  String get settings_about_support_section => 'Spinto da persone come te.';

  @override
  String get settings_about_support_share_title =>
      'Parlane a un altro proprietario';

  @override
  String get settings_about_support_share_value =>
      'Ogni link condiviso aiuta un altro proprietario di BYD a scoprire BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Controlla BladeWatch — monitoraggio open source e dashcam per BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'Condividere eccessivo';

  @override
  String get settings_about_open_link_failed =>
      'Impossibile aprire il collegamento.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'Nessun browser trovato. URL copiato: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => 'Fuel il prossimo rilascio';

  @override
  String get settings_about_support_kofi_value =>
      'Un caffè su Ko-Fi fa arrivare gli impegni notturni.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Licenza';

  @override
  String get settings_about_license_value =>
      'MIT — open source. Tocca per visualizzare il testo completo.';

  @override
  String get settings_about_source_title => 'Codice sorgente';

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
  String get settings_about_star_title => 'Lanciare un su GitHub';

  @override
  String get settings_about_star_value =>
      'Ci vuole un secondo, significa molto.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Grazie';

  @override
  String get settings_about_thanks_subtitle =>
      'Realizzato con l\'aiuto di collaboratori e sostenitori.';

  @override
  String get settings_about_contributors_title => 'Collaboratori';

  @override
  String get settings_about_supporters_title => 'Sostenitori';

  @override
  String get settings_about_thanks_empty =>
      'L\'elenco si popola man mano che le persone partecipano.';

  @override
  String get settings_theme_label => 'Tema';

  @override
  String get settings_theme_auto => 'Auto (segui il sistema)';

  @override
  String get settings_theme_light => 'Chiaro';

  @override
  String get settings_theme_dark => 'Scuro';

  @override
  String get settings_language_label => 'Lingua';

  @override
  String get settings_drive_side_label => 'Lato di navigazione';

  @override
  String get settings_drive_side_subtitle =>
      'Scegli su quale lato dello schermo appare il menu di navigazione.';

  @override
  String get settings_drive_side_left => 'Sinistra';

  @override
  String get settings_drive_side_left_hint => 'Guida a sinistra · predefinito';

  @override
  String get settings_drive_side_right => 'Destra';

  @override
  String get settings_drive_side_right_hint => 'Veicoli con guida a destra';

  @override
  String get settings_drive_side_auto => 'Automatico';

  @override
  String get settings_drive_side_auto_hint => 'Rileva dal veicolo';

  @override
  String get settings_drive_side_caption_left => 'Navigazione a sinistra';

  @override
  String get settings_drive_side_caption_right => 'Navigazione a destra';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Auto — il veicolo indica guida a sinistra';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Auto — il veicolo indica guida a destra';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Auto — veicolo non disponibile, uso sinistra';

  @override
  String get recordings_title => 'Registrazioni';

  @override
  String get recordings_segment_dashcam => 'Dashcam';

  @override
  String get recordings_segment_surveillance => 'Sorveglianza';

  @override
  String get recordings_action_settings => 'Impostazioni';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 oggi · $arg2 totale · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashcam · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Servizi di sorveglianza · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title =>
      'Selezionare una registrazione';

  @override
  String get recordings_preview_placeholder_body =>
      'Tocca qualsiasi elemento sulla sinistra per riprodurlo.';

  @override
  String get diagnostics_section_adb_console => 'Consola ADB';

  @override
  String get diagnostics_section_traffic => 'Monitor del traffico';

  @override
  String get diagnostics_section_camera_probe => 'Sonda della telecamera';

  @override
  String get diagnostics_section_battery => 'Salute della batteria';

  @override
  String get diagnostics_section_performance => 'Prestazioni';

  @override
  String get diagnostics_hero_title => 'Diagnostica del sistema';

  @override
  String get diagnostics_hero_subtitle =>
      'Salute dal vivo, registri e sonde per il dispositivo.';

  @override
  String get diagnostics_health_clear => 'Nessun problema';

  @override
  String get diagnostics_health_section => 'Salute';

  @override
  String get diagnostics_health_network => 'Rete';

  @override
  String get diagnostics_health_storage => 'Archiviazione';

  @override
  String get diagnostics_health_camera => 'Fotocamera';

  @override
  String get diagnostics_health_battery => 'Batteria';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Online';

  @override
  String diagnostics_network_data_usage_line(Object arg1) {
    return '$arg1 questo mese';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Online';

  @override
  String get diagnostics_tunnel_state_offline => 'Offline';

  @override
  String get diagnostics_tunnel_state_connecting => 'Connessione';

  @override
  String get diagnostics_network_mobile => 'Rete mobile';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Offline';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clip · $arg2 utilizzati',
      one: '$arg1 clip · $arg2 utilizzati',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 libero';
  }

  @override
  String get diagnostics_logs_card_title => 'Registro di eventi in diretta';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Riproduzione in streaming da servizi in esecuzione.';

  @override
  String get diagnostics_tools_section => 'Strumenti';

  @override
  String get diagnostics_traffic_subtitle => 'Guarda la rete in diretta.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Controlla i flussi di telecamere collegati.';

  @override
  String get diagnostics_adb_subtitle => 'Apri il terminal sul dispositivo.';

  @override
  String get diagnostics_battery_subtitle =>
      'Ispezionare la cellula SOH e raccogliere le statistiche.';

  @override
  String get diagnostics_settings_subtitle =>
      'Preferenze dell\'app, tema e lingua.';

  @override
  String get settings_action_reset_data => 'Reimposta i dati…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'In guardia';

  @override
  String get dashboard_subtitle_all_systems => 'Tutti i sistemi online';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return 'Servizi online di $arg1 di $arg2';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Accesso remoto offline';

  @override
  String get dashboard_metric_recordings => 'Le registrazioni di oggi';

  @override
  String get dashboard_metric_storage => 'Spazio utilizzato';

  @override
  String get dashboard_metric_tunnel => 'Accesso remoto';

  @override
  String get dashboard_metric_services => 'Servizi di background';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Veicolo';

  @override
  String get dashboard_chip_recording_active => 'Registrazione';

  @override
  String get dashboard_chip_recording_idle => 'Inattivo';

  @override
  String get dashboard_vehicle_tap_to_set => 'Toccare per impostare';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Imposta la capacità della batteria';

  @override
  String get vehicle_dialog_model_label => 'Modello';

  @override
  String get vehicle_dialog_save => 'Salva';

  @override
  String get settings_recording_tab_status => 'Stato';

  @override
  String get settings_recording_tab_capture => 'Acquisizione';

  @override
  String get settings_recording_tab_quality => 'Qualità';

  @override
  String get settings_recording_tab_storage => 'Archiviazione';

  @override
  String get settings_recording_status_title => 'Stato registrazione';

  @override
  String get settings_recording_status_current_state => 'Stato attuale';

  @override
  String get settings_recording_status_today_count => 'Registrazioni di oggi';

  @override
  String get settings_recording_mode_title =>
      'Modalità di registrazione (ACC ON)';

  @override
  String get settings_recording_mode_description =>
      'Scegli quando registrare durante la guida.';

  @override
  String get settings_recording_mode_none_label => 'Nessuna (predefinito)';

  @override
  String get settings_recording_mode_none_desc =>
      'Nessuna registrazione — la sorveglianza resta attiva';

  @override
  String get settings_recording_mode_continuous_label => 'Continua';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Registra sempre durante la guida';

  @override
  String get settings_recording_mode_drive_label => 'Modalità guida';

  @override
  String get settings_recording_mode_drive_desc =>
      'Registra solo quando il veicolo è in movimento';

  @override
  String get settings_recording_mode_proximity_label => 'Guardia di prossimità';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Registra quando viene rilevato un movimento';

  @override
  String get settings_recording_limit_title => 'Limite registrazione';

  @override
  String get settings_recording_limit_description =>
      'Durata massima per file. Le registrazioni vengono divise in nuovi file a questo intervallo.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_priority_title => 'Priorità di registrazione';

  @override
  String get settings_recording_priority_description =>
      'Come la registrazione gestisce un\'improvvisa interruzione di corrente.';

  @override
  String get settings_recording_priority_performance_label => 'Prestazioni';

  @override
  String get settings_recording_priority_performance_desc =>
      'Utilizza meno CPU. In caso di interruzione improvvisa dell\'alimentazione, il segmento di registrazione corrente (fino al limite di registrazione impostato) potrebbe andare perso.';

  @override
  String get settings_recording_priority_reliability_label => 'Affidabilità';

  @override
  String get settings_recording_priority_reliability_desc =>
      'Utilizza un po\' più di CPU per salvare più spesso. In caso di interruzione improvvisa dell\'alimentazione, si perde al massimo circa un minuto.';

  @override
  String get settings_recording_overlay_fields_title => 'Campi overlay';

  @override
  String get settings_recording_overlay_fields_description =>
      'Scegli cosa appare nella sovrimpressione incisa nelle registrazioni continue.';

  @override
  String get settings_recording_overlay_field_speed => 'Velocità';

  @override
  String get settings_recording_overlay_field_gear => 'Marcia';

  @override
  String get settings_recording_overlay_field_turn_signal_left =>
      'Freccia sinistra';

  @override
  String get settings_recording_overlay_field_turn_signal_right =>
      'Freccia destra';

  @override
  String get settings_recording_overlay_field_brake_pedal => 'Pedale del freno';

  @override
  String get settings_recording_overlay_field_accel_pedal =>
      'Pedale dell\'acceleratore';

  @override
  String get settings_recording_overlay_field_seatbelt_driver =>
      'Cintura del conducente';

  @override
  String get settings_recording_overlay_field_seatbelt_passenger =>
      'Cintura del passeggero';

  @override
  String get settings_recording_overlay_field_timestamp => 'Data e ora';

  @override
  String get settings_recording_quality_title => 'Qualità registrazione';

  @override
  String get settings_recording_storage_title => 'Archiviazione registrazioni';

  @override
  String get settings_recording_storage_confirm_title =>
      'Eliminare le registrazioni?';

  @override
  String settings_recording_storage_confirm_message(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Verranno eliminate $arg1 registrazioni ($arg2).',
      one: 'Verrà eliminata $arg1 registrazione ($arg2).',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_confirm_unknown_title =>
      'Impatto sconosciuto';

  @override
  String get settings_recording_storage_confirm_unknown_message =>
      'Non è stato possibile determinare cosa verrebbe eliminato con questa modifica. Ridurre il limite potrebbe rimuovere le registrazioni esistenti.';

  @override
  String get settings_recording_storage_location_label =>
      'Posizione di archiviazione';

  @override
  String get settings_recording_storage_internal => 'Interno';

  @override
  String get settings_recording_storage_sd_card => 'Scheda SD';

  @override
  String get settings_recording_storage_sd_card_na => 'Scheda SD (N/D)';

  @override
  String get settings_recording_storage_sd_mount_failed_title =>
      'La scheda SD non è stata montata';

  @override
  String get settings_recording_storage_limit_label =>
      'Limite di spazio — elimina automaticamente i più vecchi al raggiungimento';

  @override
  String get settings_recording_storage_usage_label => 'Utilizzo dello spazio';

  @override
  String get settings_recording_storage_files_label => 'File';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usati / limite $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 registrazioni',
      one: '$arg1 registrazione',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Percorso';

  @override
  String get settings_recording_storage_sd_free_label => 'Spazio libero su SD';

  @override
  String get settings_recording_storage_internal_free_label =>
      'Spazio libero interno';

  @override
  String get settings_recording_format_title => 'Formatta unità esterna';

  @override
  String get settings_recording_format_warning =>
      'Cancella DEFINITIVAMENTE tutti i dati sulla scheda SD o sull’unità USB.';

  @override
  String get settings_recording_format_confirm =>
      'Tocca di nuovo — TUTTI i dati verranno CANCELLATI';

  @override
  String get settings_recording_format_running => 'Formattazione… attendere';

  @override
  String get settings_recording_format_button => 'Formatta scheda SD / USB';

  @override
  String get settings_recording_format_no_drive =>
      'Nessuna unità rimovibile trovata';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Formattazione riuscita. Nuovo percorso: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Catalogo del database';

  @override
  String get settings_recording_sync_description =>
      'Allinea l’indice delle registrazioni ai file su disco.';

  @override
  String get settings_recording_sync_running => 'Sincronizzazione…';

  @override
  String get settings_recording_sync_button => 'Sincronizza database';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Sincronizzato: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress =>
      'Sincronizzazione già in corso';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Sincronizzazione non riuscita: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Applica modifiche';

  @override
  String get settings_recording_dismiss => 'Ignora';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Avviare/arrestare $arg1 non è ancora supportato';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 utilizzato · $arg2 libero';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Archiviazione —';

  @override
  String get dashboard_tunnel_offline => 'Offline';

  @override
  String get dashboard_tunnel_online => 'Online';

  @override
  String get dashboard_tunnel_connecting => 'Connessione…';

  @override
  String get dashboard_trips_this_week => 'Questa settimana';

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
  String get dashboard_trips_label_trips => 'Viaggi';

  @override
  String get dashboard_trips_label_distance => 'Distanza';

  @override
  String get dashboard_trips_label_time => 'Tempo di guida';

  @override
  String get dashboard_trips_no_data =>
      'Nessun viaggio registrato questa settimana';

  @override
  String get dashboard_trips_unavailable =>
      'Inizia a guidare per vedere le statistiche';

  @override
  String get dashboard_trips_loading => 'Caricamento…';

  @override
  String get dashboard_trips_view_all => 'Vedi tutti i viaggi';

  @override
  String get dashboard_action_live => 'In diretta';

  @override
  String get dashboard_action_live_subtitle => 'Apri la vista fotocamera';

  @override
  String get dashboard_action_recordings => 'Registrazioni';

  @override
  String get dashboard_action_settings => 'Impostazioni';

  @override
  String get dashboard_action_settings_subtitle => 'Preferenze e circa';

  @override
  String get settings_hero_title => 'Impostazioni';

  @override
  String get settings_hero_overline => 'BLADEWATCH';

  @override
  String get settings_hero_subtitle =>
      'Aggiungere l\'aspetto, la registrazione, la sorveglianza e i dati sul dispositivo.';

  @override
  String get settings_overline_preferences => 'Preferenze';

  @override
  String get settings_overline_about_data => 'SONO & DATI';

  @override
  String get settings_quick_theme_label => 'Tema';

  @override
  String get settings_quick_language_label => 'Lingua';

  @override
  String get settings_section_recording_subtitle =>
      'Buffer pre/post, codec, limiti di stoccaggio.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Programma, sensibilità al movimento, rilevamento oggetti.';

  @override
  String get settings_section_daemons_subtitle =>
      'Accesso remoto (Pear) e servizi in background.';

  @override
  String get settings_about_row_title => 'A proposito di BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Versione, licenza, sviluppo di supporto.';

  @override
  String get settings_reset_row_subtitle =>
      'Clari registrazioni, eventi, o tutte le cache.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Tema, linguaggio e preferenze visive.';

  @override
  String get settings_theme_active_auto_caption =>
      'Auto segue il tema del sistema.';

  @override
  String get settings_theme_active_light_caption =>
      'Il tema chiaro è sempre attivo.';

  @override
  String get settings_theme_active_dark_caption =>
      'Il tema scuro è sempre attivo.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 di $arg2 lingue disponibili';
  }

  @override
  String get settings_language_card_title => 'Lingua di visualizzazione';

  @override
  String get settings_privacy_stance_title =>
      'On-device per impostazione predefinita';

  @override
  String get settings_privacy_stance_body =>
      'La BladeWatch funziona interamente sull\'unità principale, nessuna telemetria lascia la tua auto, tranne attraverso i tunnel e le integrazioni che tu configuri esplicitamente.';

  @override
  String get settings_privacy_overline_storage => 'COMPRESSO LOCALE';

  @override
  String get settings_privacy_overline_reset => 'Ripristino dei dati';

  @override
  String get settings_privacy_storage_clips_label => 'Clips su disco';

  @override
  String get settings_privacy_storage_size_label => 'Dimensione totale';

  @override
  String get settings_privacy_storage_unavailable => 'Non disponibile';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clip',
      one: '$arg1 clip',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Scegli le categorie: registrazioni, eventi, configurazioni dei servizi, telemetria in cache...';

  @override
  String get settings_developer_overline => 'SVILUPPATORE';

  @override
  String get settings_developer_timing_logs_title =>
      'Log di temporizzazione del servizio';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Registra i marcatori di tempo trascorso durante l\'avvio del servizio. Disattivalo nell\'uso normale per mantenere pulito il logcat.';

  @override
  String get settings_developer_debug_logs_title => 'Log di debug sviluppatore';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Registra tutti gli eventi del ciclo di vita di Activity e Fragment e i passaggi di avvio in /storage/emulated/0/BladeWatch/data/debug_app.log. I crash vengono sempre catturati. Disattivato per impostazione predefinita.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Fotocamera $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Fotocamera $arg1 (manuale)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Rilevamento…';

  @override
  String get diagnostics_camera_value_offline => 'Offline';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Dati in sospeso';

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
      other: '$arg1 clip · $arg2 registrati',
      one: '$arg1 clip · $arg2 registrati',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Bagagliaio';

  @override
  String get vehicle_tab_climate => 'Climatizzazione';

  @override
  String get vehicle_tab_windows => 'Finestrini';

  @override
  String get vehicle_tab_lights => 'Luci';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Ricarica';

  @override
  String get vehicle_locked => 'Chiuso a chiave';

  @override
  String get vehicle_unlocked => 'Sbloccato';

  @override
  String get vehicle_range_label => 'Autonomia';

  @override
  String get vehicle_data_unavailable => 'Dati del veicolo non disponibili.';

  @override
  String get vehicle_action_failed =>
      'Azione non riuscita. Verifica la connessione al veicolo.';

  @override
  String get vehicle_open_trunk => 'Apri bagagliaio';

  @override
  String get vehicle_close_trunk => 'Chiudi bagagliaio';

  @override
  String get vehicle_trunk_info_open =>
      'L\'apertura del bagagliaio sbloccherà prima l\'auto.';

  @override
  String get vehicle_ac_on => 'A/C acceso';

  @override
  String get vehicle_ac_off => 'A/C spento';

  @override
  String get vehicle_max_cooling_on => 'Raffreddamento max: ON';

  @override
  String get vehicle_max_cooling_off => 'Raffreddamento max: OFF';

  @override
  String get vehicle_screen_on => 'Schermo: ACCESO';

  @override
  String get vehicle_screen_off => 'Schermo: SPENTO';

  @override
  String get vehicle_media_volume_label => 'Volume media';

  @override
  String get vehicle_media_mute => 'Muto';

  @override
  String get vehicle_media_muted => 'Silenziato';

  @override
  String get vehicle_front_defrost => 'Sbrinatore anteriore';

  @override
  String get vehicle_rear_defrost => 'Sbrinatore posteriore';

  @override
  String get vehicle_temp_label => 'Temperatura';

  @override
  String get vehicle_fan_speed_label => 'Velocità ventola';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Livello $arg1';
  }

  @override
  String vehicle_outside_temp_fmt(Object arg1) {
    return 'Esterno: $arg1°C';
  }

  @override
  String get vehicle_all_windows => 'Tutte le finestre';

  @override
  String get vehicle_window_awake_note =>
      'Funziona solo quando l’auto è attiva.';

  @override
  String get vehicle_window_front_left => 'Anteriore sinistro';

  @override
  String get vehicle_window_front_right => 'Anteriore destro';

  @override
  String get vehicle_window_rear_left => 'Posteriore sinistro';

  @override
  String get vehicle_window_rear_right => 'Posteriore destro';

  @override
  String get vehicle_window_close => 'Chiudi';

  @override
  String get vehicle_window_close_vent => 'Chiudi fessura';

  @override
  String get vehicle_window_vent_12 => 'Fessura 12%';

  @override
  String get vehicle_window_open_all => 'Apri tutti';

  @override
  String get vehicle_sunroof => 'Tetto apribile';

  @override
  String get vehicle_sunshade => 'Tendina parasole';

  @override
  String get vehicle_btn_drl_title => 'Luce di corsa diurne';

  @override
  String get vehicle_btn_slw_title => 'Avviso di limite di velocità';

  @override
  String get vehicle_control_section_charge_cap => 'Limite di carica';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Il limite di ricarica non è supportato da questo veicolo.';

  @override
  String get vehicle_charge_limit_label => 'Limite di ricarica';

  @override
  String get vehicle_enable_charge_limit => 'Attiva limite di ricarica';

  @override
  String get vehicle_charge_limit_range => 'Minimo 50%, massimo 100%';

  @override
  String get vehicle_tyre_no_signal => 'NESSUN SEGNALE';

  @override
  String get vehicle_tyre_slow_leak => 'PERDITA LENTA';

  @override
  String get vehicle_tyre_fast_leak => 'PERDITA RAPIDA';

  @override
  String get vehicle_tyre_low => 'BASSA';

  @override
  String get vehicle_tyre_high => 'ALTA';

  @override
  String get vehicle_tyre_ok => 'OK';

  @override
  String get vehicle_tyre_check_pressure => 'Controlla pressione';

  @override
  String get vehicle_toggle_on => 'ACCESO';

  @override
  String get vehicle_toggle_off => 'SPENTO';

  @override
  String get vehicle_err_climate_control =>
      'Controllo climatizzazione non riuscito.';

  @override
  String get vehicle_err_max_cooling => 'Raffreddamento max non riuscito.';

  @override
  String get vehicle_err_drl_control => 'Controllo luci diurne non riuscito.';

  @override
  String get vehicle_err_slw_control => 'Controllo ADAS non riuscito.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Attivazione limite di ricarica non riuscita.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Riduci $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Aumenta $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Connessione…';

  @override
  String get vehicle_appearance_model_title => 'Seleziona modello';

  @override
  String get vehicle_appearance_custom_color => 'Colore personalizzato';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Carica: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Autonomia: $arg1 km';
  }

  @override
  String vehicle_status_fuel_fmt(Object arg1) {
    return 'Carburante: $arg1%';
  }

  @override
  String vehicle_status_fuel_range_fmt(Object arg1) {
    return 'Autonomia carburante: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Carica: —';

  @override
  String get vehicle_status_range_unknown => 'Autonomia: —';

  @override
  String get startup_subtitle => 'Preparazione della dashcam';

  @override
  String get startup_header_preparing => 'Preparazione in corso…';

  @override
  String get startup_header_starting => 'Avvio in corso…';

  @override
  String get startup_header_verifying => 'Quasi pronto…';

  @override
  String get startup_header_ready => 'Tutto pronto';

  @override
  String get startup_daemon_camera => 'Fotocamera';

  @override
  String get startup_daemon_camera_desc =>
      'Visualizzazione live e registrazione';

  @override
  String get startup_daemon_sentry => 'Modalità Sentinella';

  @override
  String get startup_daemon_sentry_desc => 'Rilevamento movimento e avvisi';

  @override
  String get startup_daemon_parking => 'Guardia parcheggio';

  @override
  String get startup_daemon_parking_desc => 'Sorveglia mentre sei parcheggiato';

  @override
  String get startup_status_waiting => 'In attesa';

  @override
  String get startup_status_starting => 'Avvio';

  @override
  String get startup_status_ready => 'Pronto';

  @override
  String get startup_status_failed => 'Fallito';

  @override
  String get startup_continue_anyway => 'Continua comunque';

  @override
  String get startup_continue => 'Continua →';

  @override
  String get live_retry => 'Riprova';

  @override
  String get live_connecting => 'Connessione alla fotocamera…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Errore: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Fotocamera non disponibile\n$arg1';
  }

  @override
  String get live_direction_all => 'Tutte';

  @override
  String get live_direction_front => 'Anteriore';

  @override
  String get live_direction_right => 'Destra';

  @override
  String get live_direction_rear => 'Posteriore';

  @override
  String get live_direction_left => 'Sinistra';

  @override
  String get trip_no_route_data => 'Nessun dato di percorso per questo viaggio';

  @override
  String get trips_tab_trips => 'Viaggi';

  @override
  String get trips_tab_stats => 'Statistiche';

  @override
  String get trips_tab_storage => 'Archiviazione';

  @override
  String get trips_filter_7_days => '7 giorni';

  @override
  String get trips_filter_14_days => '14 giorni';

  @override
  String get trips_filter_30_days => '30 giorni';

  @override
  String trips_load_error(Object message) {
    return 'Errore: $message';
  }

  @override
  String get trips_empty_state => 'Nessun viaggio registrato ancora';

  @override
  String get trips_period_summary_title => 'Riepilogo del periodo';

  @override
  String get trips_stat_trips => 'Viaggi';

  @override
  String get trips_stat_hours => 'Ore';

  @override
  String get trips_stat_efficiency => 'Efficienza';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Punteggio: $score';
  }

  @override
  String get trips_driver_score_title => 'Punteggio del guidatore';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Totale: $score / 100';
  }

  @override
  String get trips_range_title => 'Autonomia personalizzata';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'Stima BYD: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'Autonomia a carburante: $km';
  }

  @override
  String get trips_range_no_data => 'Dati non ancora sufficienti';

  @override
  String get trips_dna_title => 'DNA di guida';

  @override
  String get trips_dna_anticipation => 'Anticipazione';

  @override
  String get trips_dna_smoothness => 'Fluidità';

  @override
  String get trips_dna_speed_discipline => 'Disciplina di velocità';

  @override
  String get trips_dna_efficiency => 'Efficienza';

  @override
  String get trips_dna_consistency => 'Costanza';

  @override
  String get trips_storage_title => 'Archiviazione viaggi';

  @override
  String get trips_storage_analytics_label => 'Analisi viaggi';

  @override
  String get trips_storage_rate_label => 'Tariffa elettrica';

  @override
  String get trips_storage_fuel_price_label =>
      'Prezzo del carburante (al litro)';

  @override
  String get trips_storage_tank_capacity_label =>
      'Capacità del serbatoio (litri)';

  @override
  String get trips_storage_distance_unit_label => 'Unità di distanza';

  @override
  String get trips_storage_location_label => 'Posizione di archiviazione';

  @override
  String get trips_storage_internal => 'Interno';

  @override
  String get trips_storage_sd_card => 'Scheda SD';

  @override
  String get trips_storage_sd_card_unavailable => 'Scheda SD (N/D)';

  @override
  String get trips_storage_apply => 'Applica modifiche';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit usati / limite $limit MB · $count viaggi';
  }

  @override
  String get trips_sync_title => 'Catalogo del database';

  @override
  String get trips_sync_description =>
      'Allinea l’indice dei viaggi ai file di telemetria su disco.';

  @override
  String get trips_sync_button => 'Sincronizza database';

  @override
  String get trips_sync_running => 'Sincronizzazione…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Sincronizzazione riuscita: +$added -$removed ($total totali)';
  }

  @override
  String get trips_sync_failed_generic => 'Sincronizzazione non riuscita';

  @override
  String get trips_detail_summary_title => 'Riepilogo del viaggio';

  @override
  String get trips_detail_distance => 'Distanza';

  @override
  String get trips_detail_duration => 'Durata';

  @override
  String get trips_detail_energy => 'Energia';

  @override
  String get trips_detail_avg_speed => 'Vel. media';

  @override
  String get trips_detail_max_speed => 'Vel. max';

  @override
  String get trips_detail_soc => 'Carica';

  @override
  String get trips_detail_cost => 'Costo';

  @override
  String get trips_detail_ext_temp => 'Temp. esterna';

  @override
  String get trips_detail_fuel_used => 'Carburante';

  @override
  String get trips_detail_fuel_cost => 'Costo carburante';

  @override
  String get trips_detail_electric_cost => 'Costo elettrico';

  @override
  String get trips_detail_elev_gain => 'Dislivello +';

  @override
  String get trips_detail_scores_title => 'Punteggi di guida';

  @override
  String get trips_detail_unavailable => 'Dettagli del viaggio non disponibili';

  @override
  String get trips_detail_loading => 'Caricamento viaggio…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count punti GPS registrati';
  }

  @override
  String get rec_severity_critical => 'CRITICO';

  @override
  String get rec_severity_alert => 'AVVISO';

  @override
  String get location_loading_title => 'Caricamento mappa';

  @override
  String get location_permission_missing_title =>
      'Autorizzazione posizione richiesta';

  @override
  String get location_permission_denied_title => 'Autorizzazione negata';

  @override
  String get location_provider_disabled_title => 'GPS disattivato';

  @override
  String get location_waiting_for_fix_title => 'In attesa del segnale GPS';

  @override
  String get location_car_location_title => 'Posizione del veicolo';

  @override
  String get location_stale_title => 'Posizione non aggiornata';

  @override
  String get location_tile_failure_title => 'Mappa non disponibile';

  @override
  String get location_tile_failure_subtitle => 'Rete non disponibile';

  @override
  String get location_error_title => 'Errore di posizione';

  @override
  String get location_action_grant => 'Concedi';

  @override
  String get location_action_retry => 'Riprova';

  @override
  String get location_mode_auto => 'Automatico';

  @override
  String get location_mode_light => 'Chiaro';

  @override
  String get location_mode_dark => 'Scuro';

  @override
  String get cd_recenter_on_car => 'Ricentra sul veicolo';

  @override
  String get recording_lib_no_recordings_normal =>
      'Nessuna registrazione normale';

  @override
  String get recording_lib_no_recordings_sentry =>
      'Nessun evento di sorveglianza';

  @override
  String get recording_lib_no_recordings_proximity =>
      'Nessun evento di prossimità';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'persona';

  @override
  String get video_player_legend_car => 'auto';

  @override
  String get video_player_legend_bike => 'bici';

  @override
  String get video_player_legend_motion => 'movimento';

  @override
  String get recording_lib_proximity_very_close => 'molto vicino';

  @override
  String get recording_lib_proximity_close => 'vicino';

  @override
  String get recording_lib_proximity_mid => 'medio';

  @override
  String get recording_lib_proximity_far => 'lontano';

  @override
  String get surveillance_tab_general => 'Generale';

  @override
  String get surveillance_tab_detection => 'Rilevamento';

  @override
  String get surveillance_tab_recording => 'Registrazione';

  @override
  String get surveillance_tab_storage => 'Archiviazione';

  @override
  String get surveillance_tab_advanced => 'Avanzate';

  @override
  String get surveillance_general_title => 'Modalità sorveglianza';

  @override
  String get surveillance_general_enable => 'Attiva sorveglianza';

  @override
  String get surveillance_general_status => 'Stato';

  @override
  String get surveillance_general_status_running => 'In esecuzione';

  @override
  String get surveillance_general_status_idle => 'Inattivo';

  @override
  String get surveillance_general_events_today => 'Eventi di oggi';

  @override
  String get surveillance_safe_locations_title => 'Luoghi sicuri';

  @override
  String get surveillance_safe_locations_subtitle =>
      'La fotocamera non si avvia se parcheggi qui';

  @override
  String get surveillance_safe_locations_enable =>
      'Disattiva nei luoghi sicuri';

  @override
  String get surveillance_safe_locations_empty =>
      'Nessun luogo sicuro ancora aggiunto';

  @override
  String get surveillance_safe_locations_add_current =>
      'Aggiungi la posizione attuale come zona sicura';

  @override
  String get surveillance_safe_locations_no_gps =>
      'Posizione GPS non disponibile';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Impostazioni di rilevamento';

  @override
  String get surveillance_detection_preset_label => 'Preimpostazione ambiente';

  @override
  String get surveillance_preset_outdoor => 'Esterno';

  @override
  String get surveillance_preset_garage => 'Garage';

  @override
  String get surveillance_preset_street => 'Strada';

  @override
  String get surveillance_preset_custom => 'Personalizzato';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Sensibilità (1=rigida, 5=sensibile): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Rileva oggetti';

  @override
  String get surveillance_detection_object_person => 'persona';

  @override
  String get surveillance_detection_object_car => 'auto';

  @override
  String get surveillance_detection_object_bike => 'bici';

  @override
  String get surveillance_recording_title => 'Registrazione eventi';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Pre-registrazione (secondi prima dell\'evento): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Post-registrazione (secondi dopo l\'evento): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Archiviazione sorveglianza';

  @override
  String get surveillance_storage_location_label =>
      'Posizione di archiviazione';

  @override
  String get surveillance_storage_internal => 'Interna';

  @override
  String get surveillance_storage_sd_card => 'Scheda SD';

  @override
  String get surveillance_storage_sd_card_na => 'Scheda SD (N/D)';

  @override
  String get surveillance_storage_limit_label =>
      'Limite di archiviazione: elimina automaticamente i più vecchi';

  @override
  String get surveillance_storage_usage_label => 'Utilizzo dello spazio';

  @override
  String get surveillance_storage_files_label => 'File';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usati / limite $arg2';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 eventi',
      one: '$arg1 evento',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'Percorso';

  @override
  String get surveillance_format_title => 'Formatta unità esterna';

  @override
  String get surveillance_format_warning =>
      'Cancella definitivamente TUTTI i dati sulla scheda SD o unità USB.';

  @override
  String get surveillance_format_button => 'Formatta scheda SD/USB';

  @override
  String get surveillance_format_confirm =>
      'Tocca di nuovo — TUTTI i dati verranno CANCELLATI';

  @override
  String get surveillance_format_running => 'Formattazione in corso… attendere';

  @override
  String get surveillance_dismiss => 'Ignora';

  @override
  String get surveillance_sync_title => 'Catalogo del database';

  @override
  String get surveillance_sync_description =>
      'Riconcilia l\'indice di sorveglianza con i file su disco.';

  @override
  String get surveillance_sync_button => 'Sincronizza database';

  @override
  String get surveillance_sync_running => 'Sincronizzazione…';

  @override
  String get surveillance_advanced_camera_title => 'Selezione fotocamera';

  @override
  String get surveillance_advanced_camera_front => 'Anteriore';

  @override
  String get surveillance_advanced_camera_right => 'Destra';

  @override
  String get surveillance_advanced_camera_rear => 'Posteriore';

  @override
  String get surveillance_advanced_camera_left => 'Sinistra';

  @override
  String get surveillance_advanced_ai_title => 'IA e deterrente';

  @override
  String get surveillance_advanced_ai_detection => 'Rilevamento IA';

  @override
  String get surveillance_advanced_night_mode => 'Modalità notturna';

  @override
  String get surveillance_advanced_deterrent_label => 'Azione deterrente';

  @override
  String get surveillance_deterrent_silent => 'Silenzioso';

  @override
  String get surveillance_deterrent_horn => 'Clacson';

  @override
  String get surveillance_deterrent_flash => 'Lampeggio';

  @override
  String get surveillance_apply_button => 'Applica modifiche';

  @override
  String get surveillance_apply_failed => 'Salvataggio non riuscito';

  @override
  String get surveillance_general_battery_warning =>
      'La modalità sentinella consuma energia extra dalla batteria a 12V mentre è attiva.';

  @override
  String get surveillance_general_camera_contention_warning =>
      'Un\'altra app sta utilizzando la fotocamera in questo momento.';

  @override
  String get pairing_title => 'Associa un dispositivo';

  @override
  String get pairing_scan_hint =>
      'Scansiona con l\'app BladeWatch sul telefono o sul computer. Il codice funziona una sola volta.';

  @override
  String pairing_expires_in(String time) {
    return 'Scade tra $time';
  }

  @override
  String get pairing_expired => 'Questo codice è scaduto.';

  @override
  String get pairing_new_code => 'Nuovo codice';

  @override
  String get pairing_remote_note =>
      'L\'associazione attiva l\'accesso remoto per questa auto.';

  @override
  String get pairing_lan_title => 'Connessione diretta su questa Wi-Fi';

  @override
  String get pairing_lan_body =>
      'Un dispositivo associato sulla stessa Wi-Fi dell\'auto si collega direttamente e in modo cifrato, senza passare da Internet. Disattivata finché non la attivi.';

  @override
  String get pairing_devices_title => 'Dispositivi associati';

  @override
  String get pairing_devices_empty => 'Nessun dispositivo associato.';

  @override
  String get pairing_remove => 'Rimuovi';

  @override
  String pairing_remove_confirm_title(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get pairing_remove_confirm_body =>
      'Perde subito l\'accesso. Gli altri dispositivi continuano a funzionare.';

  @override
  String get pairing_error =>
      'Il servizio fotocamera non ha risposto. Riprova.';

  @override
  String get daemon_name_pear => 'Accesso remoto (Pear)';

  @override
  String get pear_status_reachable => 'Raggiungibile ovunque';

  @override
  String get pear_status_unreachable =>
      'Non raggiungibile: nessuna connessione alla rete Pear';

  @override
  String get pear_status_unknown => 'Raggiungibilità sconosciuta';

  @override
  String pear_devices_connected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivi connessi',
      one: '$count dispositivo connesso',
      zero: 'Nessun dispositivo connesso',
    );
    return '$_temp0';
  }

  @override
  String pear_last_connection(String time) {
    return 'Ultima connessione: $time';
  }

  @override
  String get pear_tile_off => 'Disattivato';

  @override
  String get trips_cost_total => 'Costo totale';

  @override
  String get trips_cost_no_rate =>
      'Imposta una tariffa elettrica nelle impostazioni dei viaggi per vedere i costi.';

  @override
  String get trips_cost_mixed_currency =>
      'I viaggi hanno costi in più valute, quindi non viene mostrato alcun totale.';

  @override
  String dashboard_chip_gear(String gear) {
    return 'Marcia $gear';
  }

  @override
  String dashboard_chip_drive_mode(String mode) {
    return 'Modalità: $mode';
  }

  @override
  String dashboard_chip_auto_hold(String state) {
    return 'Auto Hold: $state';
  }

  @override
  String get auto_hold_disabled => 'Disattivato';

  @override
  String get auto_hold_enabled => 'Attivato';

  @override
  String get auto_hold_active => 'In tenuta';
}
