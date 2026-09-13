// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Bu hizmet ekran içeriğini okumamaktadır veya etkileşime girmez.';

  @override
  String get action_cancel => 'İptal';

  @override
  String get action_clear_plain => 'Temizle';

  @override
  String get action_select_all => 'Tümünü seç';

  @override
  String get action_select_all_short => 'Hepsi .';

  @override
  String get action_delete => 'Sil';

  @override
  String get action_done => 'Yapıldı';

  @override
  String get action_remind_me_later => 'Beni daha sonra hatırla .';

  @override
  String get action_retry => 'Tekrar dene';

  @override
  String get action_run => 'Kaç .';

  @override
  String get action_clear_output => 'Açık Çıkış';

  @override
  String get cd_camera => 'Kamera';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR kodu';

  @override
  String get cd_show_hide_token => 'Göster / Sakla İşaret';

  @override
  String get cd_copy_token => 'Kopya Tokeni';

  @override
  String get cd_copy_url => 'Kopya URL';

  @override
  String get cd_clear_logs => 'Açık kütükler';

  @override
  String get cd_expand_collapse => 'Genişleme / çökme';

  @override
  String get cd_recording_status => 'Kayıt durumu';

  @override
  String get cd_trip_tracking_status => 'Seyahat izleme durumu';

  @override
  String get cd_video_thumbnail => 'Video miniatürü';

  @override
  String get cd_play => 'Oynat';

  @override
  String get cd_back => 'Geri';

  @override
  String get cd_play_pause => 'Çalışma/Aravalı';

  @override
  String get cd_player_prev => 'Önceki kayıt';

  @override
  String get cd_player_next => 'Sonraki kayıt';

  @override
  String get cd_player_maximize => 'Oynatıcıyı büyüt';

  @override
  String get cd_player_minimize => 'Tam ekrandan çık';

  @override
  String get cd_delete => 'Sil';

  @override
  String get cd_expand => 'Genişle';

  @override
  String get cd_configure => 'Yapılandırma';

  @override
  String get cd_download_log => 'İndirme günlüğü';

  @override
  String get cd_reset => 'Sıfırla';

  @override
  String get cd_battery => 'Batarya';

  @override
  String get cd_step_completed => 'Adım tamamlandı';

  @override
  String get cd_permission_granted => 'Verilmiş izin';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get log_entry_default_timestamp => '12:34:56\'da.';

  @override
  String get log_entry_default_tag => '- Hayır, hayır.';

  @override
  String get log_entry_default_message => 'Kayıt mesajı buraya';

  @override
  String get daemon_card_default_name => 'Servis Adı';

  @override
  String get daemon_card_default_status => 'Durum mesajı';

  @override
  String get daemon_card_subprocesses => 'İŞLEMLER';

  @override
  String get logs_panel_title => 'Kaynaklar';

  @override
  String get url_connecting => 'Bağlantı...';

  @override
  String get camera_selection_title => 'Kamera Seçimi';

  @override
  String get camera_selection_subtitle => 'Panoramik kamera kaynağını seçin';

  @override
  String get camera_current_auto => 'Akım: Otomatik';

  @override
  String get camera_option_auto => 'Otomatik (başlatma sırasında tespit)';

  @override
  String get camera_option_0 => 'Kamera 0  Atto süsleri';

  @override
  String get camera_option_1 => 'Kamera 1  Seal (öntemli olarak)';

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
      'Otomatik, her açılışta trim\'iniz için doğru kamerayı seçer. Kamera 1 = BYD Seal, Kamera 0 = Atto trim\'leri. Ayarın geçerli olması için kamera kimliğini değiştirdikten sonra kamera servisini yeniden başlatın.';

  @override
  String get dashboard_scan_to_connect => 'Bağlantı için taray';

  @override
  String get dashboard_qr_waiting => 'Tünel için bekliyordum...';

  @override
  String get dashboard_daemons_running_default => '0/5 Çıkıyor';

  @override
  String get dashboard_device_id_loading => '- Evet .';

  @override
  String get dashboard_access_code => 'Erişim Kodu';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Yeniden Yükleme İşaretleri';

  @override
  String get dashboard_set_password => 'Şifre Belirle';

  @override
  String get cd_set_password => 'Özel şifre belirle';

  @override
  String get dialog_set_password_title => 'Özel Şifre Belirle';

  @override
  String get dialog_set_password_message =>
      'Yeni bir erişim şifresi girin. Bu, otomatik oluşturulan tokeni değiştirir.';

  @override
  String get dialog_set_password_hint => 'Yeni şifre (en az 12 karakter)';

  @override
  String get toast_password_set => 'Şifre güncellendi';

  @override
  String get toast_password_too_short => 'Şifre en az 12 karakter olmalı';

  @override
  String get toast_password_save_failed =>
      'Şifre kaydedilemedi — servis hazır değil';

  @override
  String get setup_guide_title => 'Başlamak';

  @override
  String get setup_guide_subtitle =>
      'En iyi deneyimi elde etmek için üç hızlı adım:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Dilinizi Seçin';

  @override
  String get setup_language_body =>
      'BladeWatch uygulaması ve web tüneli için farklı bir dil seçmek için basın.';

  @override
  String get setup_language_button => 'Dil Seç';

  @override
  String get setup_autostart_title => 'Otomatik Başlatma Sınırını Engelle';

  @override
  String get setup_autostart_body =>
      'BYD Otomatik Başlatma açmak için aşağıdakine tıklayın. BladeWatch listesinde bulun ve kutuyu açın. BYD bunu her yüklemede siler  güncelleştirmelerden sonra yeniden yapacaksınız.';

  @override
  String get setup_autostart_button => 'BYD Otomatik Başlatma Aç';

  @override
  String get setup_overlay_title =>
      'Diğer Uygulamalarda Gösterilmesine İzin Ver';

  @override
  String get setup_overlay_body =>
      'Diğer uygulamalar üzerinde kaydetme ve seyahat izleme için yüzen bir durum göstergesi göstermek için bunu etkinleştirin.';

  @override
  String get setup_overlay_button => 'Açık Ekleme Ayarları';

  @override
  String get cd_close => 'Kapat';

  @override
  String get language_picker_title => 'Dil';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '$arg1 dilleri mevcut';
  }

  @override
  String get language_picker_subtitle_pending => 'Dil seçin';

  @override
  String get language_auto_title => 'Otomatik';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'İzleme sistemi · $arg1';
  }

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Otomatik';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Komutanlığı girin...';

  @override
  String get adb_preset_commands_header => 'Öntanımlı komutlar';

  @override
  String get adb_output_header => 'Çıktı';

  @override
  String get adb_output_ready => 'Komutlara hazır...';

  @override
  String get adb_console_hero_title => 'ADB Konsolu';

  @override
  String get adb_console_hero_subtitle => 'Cihazda Shell komutlarını çalıştır';

  @override
  String get adb_console_unavailable_title => 'ADB bağlı değil';

  @override
  String get adb_console_unavailable_body =>
      'Bu araçta, Geliştirici Seçenekleri\'ndeki standart “USB hata ayıklama” anahtarı tek başına yeterli değildir — baş ünitenin kendi kablosuz ADB (ağ hata ayıklama) ayarı da açık olmalıdır ve bir sistem güncellemesi bunu sıfırlayabilir. Baş ünitede kablosuz ADB\'yi yeniden etkinleştirin veya USB ile bağlanın.';

  @override
  String get adb_console_auth_pending_title => 'Onay bekleniyor';

  @override
  String get adb_console_auth_pending_body =>
      'Baş ünitenin ekranında “USB hata ayıklamaya izin verilsin mi?” istemini kontrol edip kabul edin, sonra tekrar deneyin.';

  @override
  String get performance_connecting => 'Connecting to performance monitor…';

  @override
  String get performance_hero_title => 'Sistem Performansı';

  @override
  String get performance_cpu_title => 'İşlemci';

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
  String get performance_memory_title => 'Bellek';

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
  String get performance_app_process_title => 'Uygulama Süreci';

  @override
  String get performance_threads_label => 'Threads';

  @override
  String get performance_gc_cycles_label => 'GC Cycles';

  @override
  String get performance_open_fds_label => 'Open FDs';

  @override
  String get performance_refreshing_footer => 'Refreshing every 3 seconds';

  @override
  String get webview_loading => 'Karga...';

  @override
  String get webview_camera_daemon_not_running => 'Kamera Çalışmıyor';

  @override
  String get webview_start_camera_daemon =>
      'Bu sayfaya erişmek için Kamera servisini Servisler ekranından başlatın.';

  @override
  String get zrok_enable_token_hint => 'İşaret etkinleştir';

  @override
  String get zrok_token_storage_note =>
      'Token güvenli bir şekilde saklanır ve uygulama ile arka plan servisleri arasında paylaşılır.';

  @override
  String get zrok_reset_environment => 'Zrok Çevresini Yeniden Oturt';

  @override
  String get zrok_reset_environment_desc =>
      'Çevre ve token çıkarır. token ile yeniden etkinleştirmeniz gerekir (bir cihaz yuvasını kullanır).';

  @override
  String get reset_title => 'Verileri Yeniden Oturt';

  @override
  String get reset_subtitle => 'Toplanan verileri kategoriye göre sil';

  @override
  String get reset_warning =>
      'Bu işlem iptal edilemez. Kayıtlar, yolculuklar ve pil geçmişi kalıcı olarak silinecektir.';

  @override
  String get reset_cat_trips => 'Seyahatler';

  @override
  String get reset_cat_trips_desc =>
      'Gezinti tarihi, rotalar, haftalık/aylık uçuşlar';

  @override
  String get reset_cat_soc_history => 'SoC & 12V tarihi';

  @override
  String get reset_cat_soc_history_desc =>
      'SoC örnekleri, şarj seansları, voltaj kayıtları';

  @override
  String get reset_cat_soh => 'SoH kalibrasyonu';

  @override
  String get reset_cat_soh_desc =>
      'İsimsel kapasiteyi yeniden tespit eder, BMS\'den yeniden tohumların tahminini';

  @override
  String get reset_cat_recordings => 'Kayıtlar (videolar)';

  @override
  String get reset_cat_recordings_desc => 'Kayıtlar klasöründeki tüm MP4\'ler';

  @override
  String get reset_cat_sentry_events => 'Gözetim etkinlikleri';

  @override
  String get reset_cat_sentry_events_desc =>
      'Gözetim etkinliği klipleri ve JSON yan arabaları';

  @override
  String get reset_cat_proximity => 'Yakınlık kayıtları';

  @override
  String get reset_cat_proximity_desc =>
      'Radarla tetiklenen etkinlik MP4\'leri';

  @override
  String get reset_cat_trip_files => 'Yolculuk Telemetri Dosyaları';

  @override
  String get reset_cat_trip_files_desc =>
      'JSON\'in bir yolculuk için disket telemetrisi';

  @override
  String get recording_lib_chip_any => 'Herhangi bir';

  @override
  String get recording_lib_chip_person => 'Kişiler';

  @override
  String get recording_lib_chip_vehicle => 'Araç';

  @override
  String get recording_lib_chip_bike => 'Bisiklet';

  @override
  String get recording_lib_chip_animal => 'Hayvan';

  @override
  String get recording_lib_chip_alert => 'Uyarı';

  @override
  String get recording_lib_chip_critical => 'Kritik';

  @override
  String get recording_lib_selected_count_zero => '0 seçili';

  @override
  String get recording_lib_no_recordings => 'Kayıt yok.';

  @override
  String get recording_lib_filter_button => 'Filtre';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filtre · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Filtre kayıtları';

  @override
  String get recording_lib_filter_apply => 'Uygula';

  @override
  String get recording_lib_filter_reset => 'Sıfırla';

  @override
  String get recording_lib_filter_section_what => 'Ne oldu?';

  @override
  String get recording_lib_filter_section_severity => 'Ağırlık';

  @override
  String get recording_lib_filter_section_type => 'Tür';

  @override
  String get recording_lib_chip_type_normal => 'Normal';

  @override
  String get recording_lib_chip_type_proximity => 'Yakınlık';

  @override
  String get recording_lib_date_today => 'Bugün';

  @override
  String get recording_lib_date_yesterday => '- Dün .';

  @override
  String recording_lib_clip_count(Object arg1) {
    return '$arg1 klipleri';
  }

  @override
  String recording_lib_clip_count_one(Object arg1) {
    return '$arg1 klipi';
  }

  @override
  String get recording_lib_pick_date => 'Bir randevu seç .';

  @override
  String get recording_lib_date_all_days => 'Tüm Günler';

  @override
  String get cd_clear_date_filter => 'Tüm günleri göster';

  @override
  String get recording_lib_section_morning => 'Sabah .';

  @override
  String get recording_lib_section_afternoon => 'Günaydın .';

  @override
  String get recording_lib_section_evening => 'Akşam';

  @override
  String get recording_lib_section_night => 'Gece .';

  @override
  String get cd_previous_day => 'Önceki gün';

  @override
  String get cd_next_day => 'Ertesi gün';

  @override
  String get cd_open_filters => 'Açık filtreler';

  @override
  String get cd_clear_filter => 'Açık filtre';

  @override
  String get player_title_recording => 'Kayıt';

  @override
  String get player_time_zero => 'Saat 0: 00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemons_hero_title => 'Arka plan hizmetleri';

  @override
  String get daemons_count_pending => 'Kargo hizmetleri...';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1\'nin $arg2\'i çalıştırmak';
  }

  @override
  String get battery_health_title => 'Batarya Sağlığı';

  @override
  String get battery_health_subtitle => 'Sağlık durumu';

  @override
  String get battery_health_dashes => '--';

  @override
  String get battery_health_waiting => 'Verileri bekliyoruz...';

  @override
  String get battery_health_source => 'Kaynak';

  @override
  String get battery_health_method => 'Metod';

  @override
  String get battery_health_capacity => 'Kapasite';

  @override
  String get battery_health_samples => 'Örnekler';

  @override
  String get battery_health_last_updated => 'Son Güncelleştirilmiş';

  @override
  String get battery_health_reset => 'SOH Tahmini Yeniden Değiştir';

  @override
  String get battery_health_reset_desc =>
      'Tüm verileri temizler ve sıfırdan yeniden değerlendirir.';

  @override
  String get soh_dialog_model_label => 'Model';

  @override
  String get soh_dialog_pack_capacity_label => 'Paket kapasitesi';

  @override
  String get soh_dialog_estimated_capacity_label => 'Etkili kapasite';

  @override
  String get soh_dialog_calibration_anchor_label => 'Son kalibrlenmiş';

  @override
  String get soh_dialog_source_user => 'Kullanıcı seti';

  @override
  String get soh_dialog_source_auto => 'Otomatik olarak tespit edilir';

  @override
  String get soh_dialog_model_not_selected => 'Seçilmemiş';

  @override
  String get soh_dialog_capacity_not_detected => 'tespit edilmedi';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% $arg2 üzerinde';
  }

  @override
  String get dialog_ok => 'Tamam';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 kayıtları silindi',
      one: '$arg1 kaydı kaldırıldı',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 Kayıtlarını Sil',
      one: '$arg1 Kayıtını Sil',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Bu $arg1 kayıtlarını kalıcı olarak siler.',
      one: '$arg1 kayıtlarını kalıcı olarak siler.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'Uygulama güncel (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Kayıtlar için gerekli depolama izni';

  @override
  String get toast_url_copied_short => 'URL kopyalandı!';

  @override
  String get toast_camera_set_to_auto => 'Otomatik olarak ayarlanmış kamera';

  @override
  String get toast_failed_to_save_short => 'Kurtaramadım.';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Başarısız: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Kamera $arg1 seti  sonraki ACC döngüsü';
  }

  @override
  String get toast_clearing_camera_config =>
      'Kamera konfigürasyonunu temizliyorum...';

  @override
  String get toast_restarting_camera_daemon =>
      'Kamera servisi yeniden başlatılıyor...';

  @override
  String get toast_camera_daemon_restarting =>
      'Kamera servisi tam sonda ile yeniden başlatılıyor';

  @override
  String get toast_camera_restart_failed =>
      'Yapılandırma temizlendi ancak servis yeniden başlatılamadı. Lütfen elle yeniden başlatın.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Başarısız: $arg1';
  }

  @override
  String get toast_soh_reset_success =>
      'SOH tahminini yeniden ayarlamak  sonraki verilerden yeniden hesaplanacak';

  @override
  String get toast_soh_reset_failed_no_daemon =>
      'Sıfırlama başarısız — servis yanıt vermiyor ve dosya yazılamıyor';

  @override
  String toast_soh_reset_failed_with_message(Object arg1) {
    return 'Yeniden ayarlama başarısız oldu: $arg1';
  }

  @override
  String get toast_select_at_least_one_category => 'En az bir kategori seçin';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Yeniden ayarlama başarısız oldu: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 trafik monitörü...';
  }

  @override
  String get dialog_close => 'Kapat';

  @override
  String get dialog_reset => 'Sıfırla';

  @override
  String get dialog_delete => 'Sil';

  @override
  String get dialog_save => 'Kaydet';

  @override
  String get dialog_enable => 'Etkinleştir';

  @override
  String get dialog_disable => 'Devre dışı';

  @override
  String get dialog_keep_enabled => 'İzin Vermeye Devam Edin';

  @override
  String get dialog_keep_disabled => 'Engelli Kalın';

  @override
  String get dialog_regenerate => 'Yenilenme';

  @override
  String get dialog_reset_selected => 'Seçili Yeniden Oturtma';

  @override
  String get dialog_reset_soh_title => 'SOH Tahmini yeniden ayarlayalım mı?';

  @override
  String get dialog_reset_soh_message =>
      'Bu, tüm SOH verilerini temizleyecek ve sıfırdan yeniden değerlendirmeyi zorlayacaktır.\n\nBattery değiştirildiyse bunu kullanın\n• SOH okuma yanlış görünüyor\n• Yeniden kalibrlemek isterseniz\n\nSistem bir sonraki mevcut veri kaynağından (OEM, şarj kalibrasyonu veya anlık okuma) yeniden üretecektir.';

  @override
  String get dialog_reset_following_title =>
      'Aşağıdakileri yeniden ayarlıyor musun?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'This cannot be undone.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Yeniden ayarlama tamamlandı';

  @override
  String get dialog_traffic_cannot_check_title => 'Durumu kontrol edemiyorum';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB bağlı değil ve uygulama otomatik olarak yeniden bağlanamadı.\n\nBu araçta, Geliştirici Seçenekleri\'ndeki standart \"USB Hata Ayıklama\" anahtarı tek başına yeterli değildir — cihazın kendi kablosuz ADB (ağ üzerinden hata ayıklama) ayarının da açık olması gerekir ve bir sistem güncellemesi bunu sıfırlayabilir. Kablosuz ADB\'yi baş ünitede yeniden etkinleştirin veya USB ile bağlanın.\n\nBağlantı kurulduğunda durum otomatik olarak güncellenecektir.';

  @override
  String get dialog_traffic_disable_title =>
      'BYD Trafik Gözlemini devre dışı bırakmak mı?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) arka planda yol trafiği koşullarını sürekli olarak izleyen bir sistem uygulamasıdır.\n\n️ Neden devre dışı bırakın?\n\n• Mobil verileri tüketir (parkedildiğinde bile)\n• ZCPU ve arka planda pil kullanır\n• Ayrı bir navigasyon uygulaması kullanırsanız gerekmez\n• Dashcam\'ın ağ kullanımına müdahale edebilir\n\nBu, sadece haritada yerleşmiş trafik örtüsünü etkilemektedir. Navigasyonunuz, ZBluetooth ve diğer tüm otomobil fonksiyonları etkilenmez kalır.\n\n\nBir sert yeniden başlatma devre dışı bırakıldıktan sonra gereklidir (orta konsol düğmesini 5 saniye tutun).';

  @override
  String get dialog_traffic_enable_title =>
      'BYD Trafik Monitörü yeniden etkinleştirmek mi?';

  @override
  String get dialog_traffic_enable_message =>
      'BYD Traffic Monitor şu anda devre dışı.\n\nOnun yeniden etkinleştirilmesi, gezinme haritasındaki yerleşik trafik örtüsünü geri getirecektir.Arka planda çalışacak ve mobil verileri tüketeceğini unutmayın.\n\nOnun etkinleştirildikten sonra sert bir yeniden başlatma gereklidir (orta konsol düğmesini 5 saniye tutun).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Trafik İzleyicisi $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'Değişim uygulandı. Lütfen şimdi sert bir yeniden başlatma yapın:';

  @override
  String get traffic_monitor_loading => 'Trafik monitörü: Kontrol...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Trafik monitörü (kontrol etmek için dokun)';

  @override
  String get reset_label_trips => 'Seyahatler';

  @override
  String get reset_label_soc_history => 'SoC + 12V tarihi';

  @override
  String get reset_label_soh => 'SoH kalibrasyonu';

  @override
  String get reset_label_recordings => 'Kayıtlar';

  @override
  String get reset_label_sentry_events => 'Gözetim etkinlikleri';

  @override
  String get reset_label_proximity => 'Yakınlık kayıtları';

  @override
  String get reset_label_trip_files => 'Yolculuk Telemetri Dosyaları';

  @override
  String get toast_access_code_copied => 'Giriş kodu kopyalandı';

  @override
  String get dialog_regenerate_token_title => 'Yeniden Yükleme İşaretleri';

  @override
  String get dialog_regenerate_token_message =>
      'Bu, mevcut token\'ı geçersiz kılacak.';

  @override
  String get toast_token_regenerated_logged_out =>
      'Yeni bir token oluşturuldu.';

  @override
  String get toast_token_regenerated_restart =>
      'Token yenilendi. Servislerin uygulaması için yeniden başlatılması gerekebilir.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token yenilendi. Arka plan servisi bilgilendirilemedi.';

  @override
  String get toast_token_regenerated => 'Token Yenilenmiş';

  @override
  String get dashboard_no_tunnel => 'Hiç tünel yürümedi .';

  @override
  String get dashboard_starting_zrok => 'Zrok tünelini başlatıyorum...';

  @override
  String get dashboard_waiting_url => 'URL tünelini bekliyoruz...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 Çalışma';
  }

  @override
  String get tunnel_label_zrok => 'Zrok';

  @override
  String get clip_label_access_code => 'Erişim Kodu';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return '$arg1 için yapılandırma gerekmez';
  }

  @override
  String get dialog_zrok_token_title => 'Zrok tünel simgesi';

  @override
  String get dialog_zrok_token_message =>
      'Zrok etkinleştirme simgelerinizi girin.';

  @override
  String get toast_token_cannot_be_empty => 'İşaret boş olamaz .';

  @override
  String get dialog_zrok_reset_title => 'Zrok Çevresini Yeniden Oturt';

  @override
  String get dialog_zrok_reset_message =>
      'Bu:\n• Zrok tünelini durdurur eğer çalışır\n• Zrok ortamını bu cihazdan çıkarın\n• Kaydedilen token\'u silin\n\nToken\'inizi yeniden girmeniz ve yeniden etkinleştirmeniz gerekir. Bu zrok.io\'daki 5 cihaz yuvasından birini kullanır.\n\nEmin misiniz?';

  @override
  String get toast_resetting_zrok => 'Zrok ortamını yeniden ayarlayın...';

  @override
  String get toast_zrok_reset_success =>
      'Zrok ortamı yeniden ayarlayın. Yeniden ayarlamak için yeni bir token girin.';

  @override
  String get toast_zrok_reset_partial =>
      'Çevre sıfırlaması (token dosyası manuel temizlenmeye ihtiyaç duyabilir)';

  @override
  String toast_zrok_reset_warnings(Object arg1) {
    return 'Çevre sıfırlaması (açıklamalarla: $arg1)';
  }

  @override
  String get zrok_no_token_configured => 'İşaret yapılandırılmamış.';

  @override
  String get toast_zrok_token_saved => 'Kaydedilen token';

  @override
  String get toast_zrok_token_save_failed => 'Token kaydetmeyi başaramadım';

  @override
  String get toast_zrok_token_deleted => 'İşaret silinmiş';

  @override
  String get toast_zrok_token_delete_failed => 'Token silmeyi başaramadı';

  @override
  String toast_fetching_log(Object arg1) {
    return '$arg1 logunu getirmek...';
  }

  @override
  String get toast_log_empty_or_missing => 'Günlük dosyası boş veya bulunamadı';

  @override
  String get toast_log_empty => 'Günlük dosyası boş';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Kayıt kaydedilemedi: $arg1';
  }

  @override
  String get toast_log_not_found => 'Günlük dosyası bulunamadı veya okunamıyor';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1 Log - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Paylaşım $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '$arg1 Log';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Kaynak: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'İhracat: $arg1';
  }

  @override
  String log_header_truncated(Object arg1) {
    return 'NOT: 10000 satır boyunca kısaltılmış kütüphane (toplamı: $arg1 satırlar)';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Video çalılamıyor: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Kayıtları Sil';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '$arg1\'i sil?';
  }

  @override
  String get toast_recording_deleted => 'Kayıt kaldırıldı';

  @override
  String get toast_recording_delete_failed => 'Kayıt silinemedi';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 silindi, $arg2 başarısız oldu';
  }

  @override
  String get play_with_chooser => 'Oynayın .';

  @override
  String setup_version_banner(Object arg1) {
    return 'V$arg1\'ye güncellenmiş  Otomatik başlatmayı yeniden onaylayın, BYD onu her kurulumda siler';
  }

  @override
  String get setup_overlay_already_granted => 'Zaten verildi';

  @override
  String camera_current_manual(Object arg1) {
    return 'Şimdiki: Kamera $arg1 (Manual)';
  }

  @override
  String get camera_current_auto_label => 'Akım: Otomatik';

  @override
  String get soh_estimation_active => 'Değerlendirme etkinliği';

  @override
  String get soh_oem_readout =>
      'Araç SOH okuması — hesaplanan tahmin bekleniyor';

  @override
  String get soh_nominal_baseline =>
      'Nominal referans — güvenilir SOH verisi bekleniyor';

  @override
  String get soh_no_estimate_yet => 'Henüz bir tahmin yok  Veriler bekliyor';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 seçili';
  }

  @override
  String get video_player_playback_error => 'Çalışma hatası';

  @override
  String get video_player_no_events => 'Hiçbir olay yok .';

  @override
  String get daemon_configuration_required => 'Yapılandırma Gerekli';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Video Oyuncusu';

  @override
  String get status_overlay_notif_title => 'BladeWatch Durumu';

  @override
  String get status_overlay_notif_text => 'Durum üstü aktif';

  @override
  String get rail_dashboard => 'Tablo';

  @override
  String get rail_live => 'Canlı';

  @override
  String get rail_recordings => 'Kayıtlar';

  @override
  String get rail_vehicle => 'Araç';

  @override
  String get rail_trips => 'Seyahatler';

  @override
  String get rail_location => 'Konum';

  @override
  String get rail_diagnostics => 'Teşhisler';

  @override
  String get rail_settings => 'Ayarlar';

  @override
  String get settings_section_appearance => 'Görünüm';

  @override
  String get settings_section_recording => 'Kayıt';

  @override
  String get settings_section_surveillance => 'Gözetim';

  @override
  String get settings_section_daemons => 'Servisler';

  @override
  String get settings_section_privacy => 'Gizlilik & Veriler';

  @override
  String get settings_section_overlay => 'Durum örtüsü';

  @override
  String get settings_overlay_subtitle =>
      'Uçan durum hapının hangi bölümlerinin görünür kalmasını seçin.';

  @override
  String get settings_overlay_camera_title => 'Kamera göstergesi';

  @override
  String get settings_overlay_camera_subtitle =>
      'Kayıt aktifken REC / PROX badgesini göster.';

  @override
  String get settings_overlay_trip_title => 'Trip\'i gösterir';

  @override
  String get settings_overlay_trip_subtitle =>
      'Seyahat tespiti çalışırken TRIP rozetini göster.';

  @override
  String get settings_section_about => 'Hakkında';

  @override
  String get settings_subrail_overline => 'SETIMLER';

  @override
  String get cd_settings_subrail => 'Yapılandırma alt demiryolu';

  @override
  String get settings_privacy_title => 'Gizlilik & Veriler';

  @override
  String get settings_privacy_body =>
      'Sıfırlama; kayıt indeksini, önbelleğe alınan kimlik bilgilerini, servis durumunu ve cihazdaki tercihleri temizler. Bu işlem geri alınamaz.';

  @override
  String get settings_about_title => 'BladeWatch hakkında';

  @override
  String get settings_about_version_label => 'Versiyon';

  @override
  String get settings_about_package_label => 'İnşaat';

  @override
  String get settings_about_support_section =>
      'Senin gibi insanlar tarafından güçlendirilmiş.';

  @override
  String get settings_about_support_share_title =>
      'Başka bir araç sahibine bahset';

  @override
  String get settings_about_support_share_value =>
      'Paylaşılan her bağlantı başka bir BYD sahibinin BladeWatch\'i keşfetmesine yardımcı olur.';

  @override
  String get settings_about_support_share_message =>
      'BYD için BladeWatch  açık kaynaklı gözetim & dashcam\'ı kontrol edin: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'Paylaşım Aşırı Sürüş';

  @override
  String get settings_about_open_link_failed => 'Bağlantıyı açamadım.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'URL kopyalandı: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => 'Sonraki versiyon için yakıt';

  @override
  String get settings_about_support_kofi_value =>
      'Ko-Fi\'de kahve içmek gece geç saatleri bekliyor.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Lisans';

  @override
  String get settings_about_license_value =>
      'MIT  açık kaynak. Tam metni görüntülemek için dokunun.';

  @override
  String get settings_about_source_title => 'Kaynak kodu';

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
  String get settings_about_star_title => 'GitHub\'da bir bırak';

  @override
  String get settings_about_star_value =>
      'Bir saniye sürer, çok şey ifade eder.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Teşekkürler';

  @override
  String get settings_about_thanks_subtitle =>
      'Katkıda bulunanların ve destekçilerin yardımıyla kuruldu.';

  @override
  String get settings_about_contributors_title => 'Katkıda bulunanlar';

  @override
  String get settings_about_supporters_title => 'Destekçiler';

  @override
  String get settings_about_thanks_empty =>
      'İnsanlar katıldıkça liste dolmaya başlar.';

  @override
  String get settings_theme_label => 'Tema';

  @override
  String get settings_theme_auto => 'Otomatik (önderleme sistemi)';

  @override
  String get settings_theme_light => 'Işık';

  @override
  String get settings_theme_dark => 'Karanlık';

  @override
  String get settings_language_label => 'Dil';

  @override
  String get settings_drive_side_label => 'Navigasyon Tarafı';

  @override
  String get settings_drive_side_subtitle =>
      'Navigasyon menüsünün ekranın hangi tarafında görüneceğini seçin.';

  @override
  String get settings_drive_side_left => 'Sol';

  @override
  String get settings_drive_side_left_hint => 'LHD · varsayılan';

  @override
  String get settings_drive_side_right => 'Sağ';

  @override
  String get settings_drive_side_right_hint => 'RHD araçlar';

  @override
  String get settings_drive_side_auto => 'Otomatik';

  @override
  String get settings_drive_side_auto_hint => 'Araçtan algıla';

  @override
  String get settings_drive_side_caption_left => 'Navigasyon solda';

  @override
  String get settings_drive_side_caption_right => 'Navigasyon sağda';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Otomatik — araç soldan direksiyon bildiriyor';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Otomatik — araç sağdan direksiyon bildiriyor';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Otomatik — araç erişilemez, sol kullanılıyor';

  @override
  String get recordings_title => 'Kayıtlar';

  @override
  String get recordings_segment_dashcam => 'Dashcam';

  @override
  String get recordings_segment_surveillance => 'Gözetim';

  @override
  String get recordings_action_settings => 'Ayarlar';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 bugün · $arg2 toplam · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashcam · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Gözetim · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Kayıt seçin';

  @override
  String get recordings_preview_placeholder_body =>
      'Soldaki herhangi bir şeyi çalmak için dokun.';

  @override
  String get diagnostics_section_adb_console => 'ADB Konsolu';

  @override
  String get diagnostics_section_traffic => 'Trafik monitörü';

  @override
  String get diagnostics_section_camera_probe => 'Kamera sondası';

  @override
  String get diagnostics_section_battery => 'Batarya sağlığı';

  @override
  String get diagnostics_section_performance => 'Performans';

  @override
  String get diagnostics_hero_title => 'Sistem teşhisleri';

  @override
  String get diagnostics_hero_subtitle =>
      'Sağlık kayıtları ve cihazın sondajları.';

  @override
  String get diagnostics_health_clear => 'Her şey açık .';

  @override
  String get diagnostics_health_section => 'Sağlık';

  @override
  String get diagnostics_health_network => 'Ağ';

  @override
  String get diagnostics_health_storage => 'Depolama';

  @override
  String get diagnostics_health_camera => 'Kamera';

  @override
  String get diagnostics_health_battery => 'Batarya';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Çevrimiçi';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Tunel · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Çevrimiçi';

  @override
  String get diagnostics_tunnel_state_offline => 'İletişimden uzak';

  @override
  String get diagnostics_tunnel_state_connecting => 'Bağlantı';

  @override
  String get diagnostics_network_mobile => 'Mobil';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'İletişimden uzak';

  @override
  String diagnostics_storage_used_line(Object arg1, Object arg2) {
    return '$arg1 klipleri · $arg2 kullanılır';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 ücretsiz';
  }

  @override
  String get diagnostics_logs_card_title => 'Canlı etkinlik kaydı';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Çalışan hizmetlerden gelen akış çıkışı.';

  @override
  String get diagnostics_tools_section => 'Araçlar';

  @override
  String get diagnostics_traffic_subtitle => 'Canlı ağ geçişini izle.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Bağlı kamera akışlarını kontrol et.';

  @override
  String get diagnostics_adb_subtitle => 'Cihazın terminalini aç.';

  @override
  String get diagnostics_battery_subtitle =>
      'SOH hücresini kontrol et ve istatistikleri topla.';

  @override
  String get diagnostics_settings_subtitle =>
      'Uygulama tercihleri, tema ve dil.';

  @override
  String get settings_action_reset_data => 'Verileri yeniden ayarlayın...';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'Nöbette';

  @override
  String get dashboard_subtitle_all_systems => 'Tüm sistemler çevrimiçi';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 of $arg2 online hizmetleri';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Uzaktan erişim çevrimdışı';

  @override
  String get dashboard_metric_recordings => 'Bugünün kayıtları .';

  @override
  String get dashboard_metric_storage => 'Kullanılan depolama';

  @override
  String get dashboard_metric_tunnel => 'Uzaktan erişim';

  @override
  String get dashboard_metric_services => 'Arka plan hizmetleri';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Araç';

  @override
  String get dashboard_chip_recording_active => 'Kayıt';

  @override
  String get dashboard_chip_recording_idle => 'Boşta';

  @override
  String get dashboard_vehicle_tap_to_set => 'Yapılandırmaya dokun';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Batarya kapasitesini ayarlayın';

  @override
  String get vehicle_dialog_capacity_label => 'Kapasite (kWh)';

  @override
  String get vehicle_dialog_capacity_suffix => 'kWh';

  @override
  String get vehicle_dialog_capacity_helper =>
      '8 ila 120 kWh. Model varsayılanını kullanmak için bırakın.';

  @override
  String get vehicle_dialog_model_label => 'Model';

  @override
  String get vehicle_dialog_save => 'Kaydet';

  @override
  String get vehicle_dialog_reset => 'Otomatik tespit için yeniden ayarlayın';

  @override
  String get vehicle_dialog_invalid_capacity =>
      'Kapasite 8 - 120 kWh olmalıdır.';

  @override
  String vehicle_dialog_summary_capacity(Object arg1) {
    return 'Kapasite: $arg1';
  }

  @override
  String vehicle_dialog_summary_soh(Object arg1) {
    return 'SOH: $arg1';
  }

  @override
  String vehicle_dialog_soh_source_live(Object arg1) {
    return '$arg1% (canlı)';
  }

  @override
  String vehicle_dialog_soh_source_calibration(Object arg1) {
    return '$arg1% (son şarjdan)';
  }

  @override
  String vehicle_dialog_soh_source_oem(Object arg1) {
    return '$arg1% (araç)';
  }

  @override
  String vehicle_dialog_soh_source_nominal(Object arg1) {
    return '$arg1% (nominal)';
  }

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
  String get settings_recording_quality_title => 'Recording Quality';

  @override
  String get settings_recording_storage_title => 'Recording Storage';

  @override
  String get settings_recording_storage_location_label => 'Storage Location';

  @override
  String get settings_recording_storage_internal => 'Internal';

  @override
  String get settings_recording_storage_sd_card => 'SD Card';

  @override
  String get settings_recording_storage_sd_card_na => 'SD Card (N/A)';

  @override
  String get settings_recording_storage_limit_label =>
      'Storage Limit — auto-deletes oldest when reached';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 used / $arg2 limit';
  }

  @override
  String settings_recording_storage_files(Object arg1) {
    return '$arg1 recordings';
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
  String get settings_daemons_zrok_configure => 'Configure';

  @override
  String get settings_daemons_zrok_reset_button => 'Reset Environment';

  @override
  String vehicle_dialog_summary_effective(Object arg1) {
    return 'Etkili: $arg1 kWh';
  }

  @override
  String vehicle_dialog_summary_model(Object arg1) {
    return 'Model: $arg1';
  }

  @override
  String vehicle_dialog_summary_calibration(Object arg1, Object arg2) {
    return 'Son kalibrasyon: $arg1% $arg2';
  }

  @override
  String get vehicle_dialog_soh_unavailable => 'kullanılamıyor';

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 kullanıldı · $arg2 ücretsiz';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Depolama ';

  @override
  String get dashboard_tunnel_offline => 'İletişimden uzak';

  @override
  String get dashboard_tunnel_online => 'Çevrimiçi';

  @override
  String get dashboard_tunnel_connecting => 'Bağlantı...';

  @override
  String get dashboard_trips_this_week => 'Bu Hafta';

  @override
  String dashboard_trips_count(Object arg1) {
    return '$arg1 yolculuk';
  }

  @override
  String dashboard_trips_distance_km(Object arg1) {
    return '$arg1 km';
  }

  @override
  String dashboard_trips_distance_mi(Object arg1) {
    return '$arg1 mil';
  }

  @override
  String dashboard_trips_duration(Object arg1) {
    return '$arg1';
  }

  @override
  String get dashboard_trips_label_trips => 'Yolculuklar';

  @override
  String get dashboard_trips_label_distance => 'Mesafe';

  @override
  String get dashboard_trips_label_time => 'Sürüş Süresi';

  @override
  String get dashboard_trips_no_data => 'Bu hafta kaydedilmiş yolculuk yok';

  @override
  String get dashboard_trips_unavailable =>
      'İstatistikleri görmek için sürmeye başlayın';

  @override
  String get dashboard_trips_loading => 'Yükleniyor…';

  @override
  String get dashboard_trips_view_all => 'Tüm yolculukları gör';

  @override
  String get dashboard_action_live => 'Canlı görüntü';

  @override
  String get dashboard_action_live_subtitle => 'Açık kamera görüntüsü';

  @override
  String get dashboard_action_recordings => 'Kayıtlar';

  @override
  String get dashboard_action_settings => 'Ayarlar';

  @override
  String get dashboard_action_settings_subtitle => 'Tercihleri ve hakkında';

  @override
  String get settings_hero_title => 'Ayarlar';

  @override
  String get settings_hero_overline => 'ÜZÜR KATLAR';

  @override
  String get settings_hero_subtitle =>
      'Görünüm, kayıt, gözetim ve cihazdaki verileri ayarlayın.';

  @override
  String get settings_overline_preferences => 'ÖNEMLER';

  @override
  String get settings_overline_about_data => 'BİRLEŞİK & DATA';

  @override
  String get settings_quick_theme_label => 'Tema';

  @override
  String get settings_quick_language_label => 'Dil';

  @override
  String get settings_section_recording_subtitle =>
      'Ön / sonrası tamponlar, kodekler, depolama sınırları.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Deteksiyon bölgeleri, program, hareket hassasiyeti.';

  @override
  String get settings_section_daemons_subtitle =>
      'Zrok tüneli ve arka plan servisleri.';

  @override
  String get settings_about_row_title => 'BladeWatch hakkında';

  @override
  String get settings_about_row_subtitle =>
      'Versiyon, lisans, destek geliştirme.';

  @override
  String get settings_reset_row_subtitle =>
      'Kayıtları, olayları ya da tüm gizli yerleri temizle.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle => 'Tema, dil ve görsel tercihler.';

  @override
  String get settings_theme_active_auto_caption =>
      'Otomatik sistem temasını takip eder.';

  @override
  String get settings_theme_active_light_caption =>
      'Işık teması her zaman açık.';

  @override
  String get settings_theme_active_dark_caption =>
      'Karanlık konu her zaman açık.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1\'den $arg2 dillerinde mevcut';
  }

  @override
  String get settings_language_card_title => 'Gösterim dili';

  @override
  String get settings_privacy_stance_title => 'Öntanımlı olarak cihazda';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch tamamen ana birimle çalışır. Arabanızdan açıkça ayarladığınız tüneller ve entegrasyonlar dışında hiçbir telemetri çıkmaz.';

  @override
  String get settings_privacy_overline_storage => 'Yerel depolama';

  @override
  String get settings_privacy_overline_reset => 'Veri Yeniden Sunu';

  @override
  String get settings_privacy_storage_clips_label => 'Disk üzerindeki klipler';

  @override
  String get settings_privacy_storage_size_label => 'Toplam boyut';

  @override
  String get settings_privacy_storage_unavailable => 'Kullanılamıyor';

  @override
  String settings_privacy_storage_count_format(Object arg1) {
    return '$arg1 klipi';
  }

  @override
  String settings_privacy_storage_count_format_plural(Object arg1) {
    return '$arg1 klipleri';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Kategorileri seçin: kayıtlar, olaylar, servis yapılandırmaları, önbelleğe alınmış telemetri...';

  @override
  String get settings_developer_overline => 'GELİŞTİRİCİ';

  @override
  String get settings_developer_timing_logs_title =>
      'Servis zamanlama günlükleri';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Servis başlatma sırasında geçen süre işaretlerini kaydet. Logcat\'i temiz tutmak için normal kullanımda kapatın.';

  @override
  String get settings_developer_debug_logs_title =>
      'Geliştirici hata ayıklama günlükleri';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Tüm Activity ve Fragment yaşam döngüsü olaylarını ve başlatma adımlarını /storage/emulated/0/BladeWatch/data/debug_app.log dosyasına kaydet. Çökmeler her zaman kaydedilir. Varsayılan olarak kapalı.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Kamera $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Kamera $arg1 (elçici)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Araştıran...';

  @override
  String get diagnostics_camera_value_offline => 'İletişimden uzak';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Bekleyen veriler';

  @override
  String dashboard_recordings_value_live(Object arg1) {
    return '● $arg1';
  }

  @override
  String get dashboard_insight_welcome =>
      'Hoşgeldiniz  BladeWatch şimdi ikinci göz çiftiniz.';

  @override
  String dashboard_insight_parked_charged_kwh(Object arg1, Object arg2) {
    return '$arg1 (≈$arg2) park ederken alındı.';
  }

  @override
  String dashboard_insight_parked_charged(Object arg1) {
    return '$arg1\'i park ederken aldım.';
  }

  @override
  String dashboard_insight_parked_drained_kwh(Object arg1, Object arg2) {
    return 'Park ettiğinden beri $arg1 (≈$arg2) kullandın';
  }

  @override
  String dashboard_insight_parked_drained(Object arg1) {
    return 'Park ettiğinden beri $arg1 kullanıyorum.';
  }

  @override
  String dashboard_insight_last_alert(Object arg1) {
    return 'Son güvenlik uyarısı: $arg1';
  }

  @override
  String dashboard_insight_last_charge(Object arg1, Object arg2) {
    return 'Son şarj: $arg2\'de +$arg1';
  }

  @override
  String dashboard_insight_storage_milestone(Object arg1, Object arg2) {
    return '$arg1 klipleri · $arg2 kaydedildi';
  }

  @override
  String dashboard_insight_kwh_format(Object arg1) {
    return '$arg1 kWh';
  }

  @override
  String dashboard_insight_percent_format(Object arg1) {
    return '$arg1%';
  }

  @override
  String dashboard_insight_hours_minutes(Object arg1, Object arg2) {
    return '$arg1 hr $arg2 min';
  }

  @override
  String dashboard_insight_today_clips(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Bugün kaydedilen $arg1 klipleri',
      one: '$arg1 klipi bugün kaydedildi .',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_days_hours(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 günleri, $arg2 saatleri için online sürüş',
      one: '$arg1 gün, $arg2 saat için çevrimiçi sürüş',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_hours(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 saat boyunca online sürüş',
      one: '$arg1 saat boyunca online sürüş',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_minutes(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 dakika',
      one: '$arg1 dakika',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_hours(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 hr',
      one: '$arg1 hr',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Çanta';

  @override
  String get vehicle_tab_climate => 'İklim';

  @override
  String get vehicle_tab_seats => 'Koltuklar';

  @override
  String get vehicle_tab_windows => 'Camlar';

  @override
  String get vehicle_tab_lights => 'Işıklar';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Şarj';

  @override
  String get vehicle_locked => 'Kilitli .';

  @override
  String get vehicle_unlocked => 'Kilitlenmemiş';

  @override
  String get vehicle_range_label => 'Menzil';

  @override
  String get vehicle_data_unavailable => 'Araç verisi mevcut değil.';

  @override
  String get vehicle_action_failed =>
      'İşlem başarısız. Araç bağlantısını kontrol edin.';

  @override
  String get vehicle_open_trunk => 'Bagajı Aç';

  @override
  String get vehicle_close_trunk => 'Kapalı Çanta';

  @override
  String get vehicle_trunk_info_open =>
      'Bagajı açmak önce aracın kilidini açar.';

  @override
  String get vehicle_ac_on => 'AC Açık';

  @override
  String get vehicle_ac_off => 'AC Açık';

  @override
  String get vehicle_max_cooling_on => 'Maks Soğutma: AÇIK';

  @override
  String get vehicle_max_cooling_off => 'Maks Soğutma: KAPALI';

  @override
  String get vehicle_temp_label => 'Sıcaklık';

  @override
  String get vehicle_fan_speed_label => 'Fan Hızı';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Seviye $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return 'İçeride: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => 'Sürücü';

  @override
  String get vehicle_seat_passenger => 'Yolcu';

  @override
  String get vehicle_seat_no_controls => 'Bu araç için koltuk kontrolü yok.';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return 'Isıtma $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return 'Soğutma $arg1';
  }

  @override
  String get vehicle_heat_off => '(Kapalı)';

  @override
  String get vehicle_heat_low => '(Düşük)';

  @override
  String get vehicle_heat_high => '(Yüksek)';

  @override
  String get vehicle_seat_pos_1 => '1. pozisyon';

  @override
  String get vehicle_seat_pos_2 => '2. pozisyon';

  @override
  String get vehicle_all_windows => 'Tüm Pencereler';

  @override
  String get vehicle_window_front_left => 'Sol Ön';

  @override
  String get vehicle_window_front_right => 'Sağ Ön';

  @override
  String get vehicle_window_rear_left => 'Sol Arka';

  @override
  String get vehicle_window_rear_right => 'Sağ Arka';

  @override
  String get vehicle_window_close => 'Kapat';

  @override
  String get vehicle_window_close_vent => 'Havalandırmayı Kapat';

  @override
  String get vehicle_window_vent_12 => 'Havalandırma 12%';

  @override
  String get vehicle_window_open_all => 'Tümünü Aç';

  @override
  String get vehicle_sunroof => 'Güneş çatısı';

  @override
  String get vehicle_sunshade => 'Güneş gölgesi';

  @override
  String get vehicle_btn_drl_title => 'Gündüz çalışan ışıklar';

  @override
  String get vehicle_btn_slw_title => 'Hız sınırı uyarısı';

  @override
  String get vehicle_control_section_charge_cap => 'Şarj limiti';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Şarj sınırı bu araç tarafından desteklenmiyor.';

  @override
  String get vehicle_charge_limit_label => 'Şarj Sınırı';

  @override
  String get vehicle_enable_charge_limit => 'Şarj Sınırını Etkinleştir';

  @override
  String get vehicle_charge_limit_range => 'En az 50%, en fazla 100%';

  @override
  String get vehicle_tyre_no_signal => 'İNSANLAR yok .';

  @override
  String get vehicle_tyre_slow_leak => 'SLOW LEAK';

  @override
  String get vehicle_tyre_fast_leak => 'Hızlı sızıntı';

  @override
  String get vehicle_tyre_low => 'Düşük';

  @override
  String get vehicle_tyre_high => 'Yüksek';

  @override
  String get vehicle_tyre_ok => 'Tamam';

  @override
  String get vehicle_tyre_check_pressure => 'Basıncı kontrol et';

  @override
  String get vehicle_toggle_on => 'AÇIK';

  @override
  String get vehicle_toggle_off => 'KAPALI';

  @override
  String get vehicle_err_climate_control => 'İklim kontrolü başarısız.';

  @override
  String get vehicle_err_max_cooling => 'Maks soğutma başarısız.';

  @override
  String get vehicle_err_drl_control => 'Gündüz farı kontrolü başarısız.';

  @override
  String get vehicle_err_slw_control => 'ADAS kontrolü başarısız.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Şarj sınırı değiştirme başarısız.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return '$arg1 azalt';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return '$arg1 artır';
  }

  @override
  String get vehicle_stale_connecting => 'Bağlanıyor…';

  @override
  String get vehicle_appearance_model_title => 'Model Seç';

  @override
  String get vehicle_appearance_custom_color => 'Özel renk';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Şarj: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Menzil: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Şarj: —';

  @override
  String get vehicle_status_range_unknown => 'Menzil: —';

  @override
  String get startup_subtitle => 'Araç kameranız hazırlanıyor';

  @override
  String get startup_header_preparing => 'Hazırlanıyor…';

  @override
  String get startup_header_starting => 'Başlatılıyor…';

  @override
  String get startup_header_verifying => 'Neredeyse hazır…';

  @override
  String get startup_header_ready => 'Her şey hazır';

  @override
  String get startup_daemon_camera => 'Kamera';

  @override
  String get startup_daemon_camera_desc => 'Canlı görüntü ve kayıt';

  @override
  String get startup_daemon_sentry => 'Nöbet Modu';

  @override
  String get startup_daemon_sentry_desc => 'Hareket algılama ve uyarılar';

  @override
  String get startup_daemon_parking => 'Park Koruması';

  @override
  String get startup_daemon_parking_desc => 'Park halindeyken nöbet tutar';

  @override
  String get startup_status_waiting => 'Bekliyor';

  @override
  String get startup_status_starting => 'Başlatılıyor';

  @override
  String get startup_status_ready => 'Hazır';

  @override
  String get startup_status_failed => 'Başarısız';

  @override
  String get startup_continue_anyway => 'Yine de devam et';

  @override
  String get startup_continue => 'Devam et →';

  @override
  String get live_retry => 'Tekrar dene';

  @override
  String get live_connecting => 'Kameraya bağlanıyor…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Hata: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Kamera kullanılamıyor\n$arg1';
  }

  @override
  String get live_direction_all => 'Tümü';

  @override
  String get live_direction_front => 'Ön';

  @override
  String get live_direction_right => 'Sağ';

  @override
  String get live_direction_rear => 'Arka';

  @override
  String get live_direction_left => 'Sol';

  @override
  String get trip_no_route_data => 'Bu yolculuk için rota verisi yok';

  @override
  String get trips_tab_trips => 'Yolculuklar';

  @override
  String get trips_tab_stats => 'İstatistikler';

  @override
  String get trips_tab_storage => 'Depolama';

  @override
  String get trips_filter_7_days => '7 Days';

  @override
  String get trips_filter_14_days => '14 Days';

  @override
  String get trips_filter_30_days => '30 Days';

  @override
  String trips_load_error(Object message) {
    return 'Hata: $message';
  }

  @override
  String get trips_empty_state => 'Henüz kayıtlı yolculuk yok';

  @override
  String get trips_period_summary_title => 'Dönem Özeti';

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
  String get trips_driver_score_title => 'Sürücü Puanı';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Overall: $score / 100';
  }

  @override
  String get trips_range_title => 'Kişiselleştirilmiş Menzil';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD estimate: $km km';
  }

  @override
  String get trips_range_no_data => 'Henüz yeterli veri yok';

  @override
  String get trips_dna_title => 'Sürüş DNA\'sı';

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
  String get trips_storage_title => 'Yolculuk Depolama';

  @override
  String get trips_storage_analytics_label => 'Trip Analytics';

  @override
  String get trips_storage_rate_label => 'Electricity Rate';

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
  String get trips_sync_title => 'Veritabanı Kataloğu';

  @override
  String get trips_sync_description =>
      'Reconcile the trips index with telemetry files on disk.';

  @override
  String get trips_sync_button => 'Sync Database';

  @override
  String get trips_sync_running => 'Syncing…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Başarıyla senkronize edildi: +$added -$removed (toplam $total)';
  }

  @override
  String get trips_sync_failed_generic => 'Senkronizasyon başarısız oldu';

  @override
  String get trips_detail_summary_title => 'Yolculuk Özeti';

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
  String get trips_detail_elev_gain => 'Elev Gain';

  @override
  String get trips_detail_scores_title => 'Sürüş Puanları';

  @override
  String get trips_detail_unavailable => 'Yolculuk ayrıntıları kullanılamıyor';

  @override
  String get trips_detail_loading => 'Yolculuk yükleniyor…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count GPS points recorded';
  }

  @override
  String get rec_severity_critical => 'KRİTİK';

  @override
  String get rec_severity_alert => 'UYARI';

  @override
  String get location_loading_title => 'Harita yükleniyor';

  @override
  String get location_permission_missing_title => 'Konum izni gerekli';

  @override
  String get location_permission_denied_title => 'İzin reddedildi';

  @override
  String get location_provider_disabled_title => 'GPS devre dışı';

  @override
  String get location_waiting_for_fix_title => 'GPS sinyali bekleniyor';

  @override
  String get location_car_location_title => 'Araç konumu';

  @override
  String get location_stale_title => 'Konum güncel değil';

  @override
  String get location_tile_failure_title => 'Harita kullanılamıyor';

  @override
  String get location_tile_failure_subtitle => 'Ağ kullanılamıyor';

  @override
  String get location_error_title => 'Konum hatası';

  @override
  String get location_action_grant => 'İzin ver';

  @override
  String get location_action_retry => 'Tekrar dene';

  @override
  String get location_mode_auto => 'Otomatik';

  @override
  String get location_mode_light => 'Açık';

  @override
  String get location_mode_dark => 'Koyu';

  @override
  String get cd_recenter_on_car => 'Aracı ortala';

  @override
  String get recording_lib_no_recordings_normal => 'Normal kayıt yok';

  @override
  String get recording_lib_no_recordings_sentry => 'Gözetim olayı yok';

  @override
  String get recording_lib_no_recordings_proximity => 'Yakınlık olayı yok';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'kişi';

  @override
  String get video_player_legend_car => 'araba';

  @override
  String get video_player_legend_bike => 'bisiklet';

  @override
  String get video_player_legend_motion => 'hareket';

  @override
  String get recording_lib_proximity_very_close => 'çok yakın';

  @override
  String get recording_lib_proximity_close => 'yakın';

  @override
  String get recording_lib_proximity_mid => 'orta';

  @override
  String get recording_lib_proximity_far => 'uzak';

  @override
  String get surveillance_tab_general => 'Genel';

  @override
  String get surveillance_tab_detection => 'Algılama';

  @override
  String get surveillance_tab_recording => 'Kayıt';

  @override
  String get surveillance_tab_storage => 'Depolama';

  @override
  String get surveillance_tab_advanced => 'Gelişmiş';

  @override
  String get surveillance_general_title => 'Gözetim modu';

  @override
  String get surveillance_general_enable => 'Gözetimi etkinleştir';

  @override
  String get surveillance_general_status => 'Durum';

  @override
  String get surveillance_general_status_running => 'Çalışıyor';

  @override
  String get surveillance_general_status_idle => 'Boşta';

  @override
  String get surveillance_general_events_today => 'Bugünkü olaylar';

  @override
  String get surveillance_safe_locations_title => 'Güvenli konumlar';

  @override
  String get surveillance_safe_locations_subtitle =>
      'Burada park edildiğinde kamera başlamaz';

  @override
  String get surveillance_safe_locations_enable =>
      'Güvenli konumlarda devre dışı bırak';

  @override
  String get surveillance_safe_locations_empty =>
      'Henüz güvenli konum eklenmedi';

  @override
  String get surveillance_safe_locations_add_current =>
      'Mevcut konumu güvenli bölge olarak ekle';

  @override
  String get surveillance_safe_locations_no_gps => 'GPS konumu kullanılamıyor';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Algılama ayarları';

  @override
  String get surveillance_detection_preset_label => 'Ortam ön ayarı';

  @override
  String get surveillance_preset_outdoor => 'Açık alan';

  @override
  String get surveillance_preset_garage => 'Garaj';

  @override
  String get surveillance_preset_street => 'Sokak';

  @override
  String get surveillance_preset_custom => 'Özel';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Hassasiyet (1=katı, 5=hassas): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Nesneleri algıla';

  @override
  String get surveillance_detection_object_person => 'kişi';

  @override
  String get surveillance_detection_object_car => 'araba';

  @override
  String get surveillance_detection_object_bike => 'bisiklet';

  @override
  String get surveillance_recording_title => 'Olay kaydı';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Ön kayıt (olaydan önceki saniye): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Son kayıt (olaydan sonraki saniye): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Gözetim depolaması';

  @override
  String get surveillance_storage_location_label => 'Depolama konumu';

  @override
  String get surveillance_storage_internal => 'Dahili';

  @override
  String get surveillance_storage_sd_card => 'SD kart';

  @override
  String get surveillance_storage_sd_card_na => 'SD kart (yok)';

  @override
  String get surveillance_storage_limit_label =>
      'Depolama sınırı — sınıra ulaşınca en eskisini otomatik siler';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 used / $arg2 limit';
  }

  @override
  String surveillance_storage_files(Object arg1) {
    return '$arg1 olay';
  }

  @override
  String get surveillance_storage_path_label => 'Yol';

  @override
  String get surveillance_format_title => 'Harici sürücüyü biçimlendir';

  @override
  String get surveillance_format_warning =>
      'SD kart veya USB sürücüdeki TÜM verileri kalıcı olarak siler.';

  @override
  String get surveillance_format_button => 'SD Kart/USB\'yi biçimlendir';

  @override
  String get surveillance_format_confirm =>
      'Tekrar dokunun — TÜM veriler SİLİNECEK';

  @override
  String get surveillance_format_running =>
      'Biçimlendiriliyor… lütfen bekleyin';

  @override
  String get surveillance_dismiss => 'Kapat';

  @override
  String get surveillance_sync_title => 'Veritabanı kataloğu';

  @override
  String get surveillance_sync_description =>
      'Gözetim dizinini diskteki dosyalarla uzlaştırır.';

  @override
  String get surveillance_sync_button => 'Veritabanını senkronize et';

  @override
  String get surveillance_sync_running => 'Senkronize ediliyor…';

  @override
  String get surveillance_advanced_camera_title => 'Kamera seçimi';

  @override
  String get surveillance_advanced_camera_front => 'Ön';

  @override
  String get surveillance_advanced_camera_right => 'Sağ';

  @override
  String get surveillance_advanced_camera_rear => 'Arka';

  @override
  String get surveillance_advanced_camera_left => 'Sol';

  @override
  String get surveillance_advanced_ai_title => 'YZ ve caydırma';

  @override
  String get surveillance_advanced_ai_detection => 'YZ algılama';

  @override
  String get surveillance_advanced_night_mode => 'Gece modu';

  @override
  String get surveillance_advanced_deterrent_label => 'Caydırma eylemi';

  @override
  String get surveillance_deterrent_silent => 'Sessiz';

  @override
  String get surveillance_deterrent_horn => 'Korna';

  @override
  String get surveillance_deterrent_flash => 'Flaş';

  @override
  String get surveillance_apply_button => 'Değişiklikleri uygula';

  @override
  String get surveillance_apply_failed => 'Kaydetme başarısız';
}
