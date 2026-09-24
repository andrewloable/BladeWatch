// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'ทำให้ระบบตรวจสอบรถยนต์ BladeWatch ทำงานในพื้นหลังตลอดเวลา บริการนี้จะไม่อ่านหรือยุ่งเกี่ยวกับเนื้อหาบนหน้าจอ';

  @override
  String get action_cancel => 'ยกเลิก';

  @override
  String get action_clear_plain => 'ล้างข้อมูล';

  @override
  String get action_select_all => 'เลือกทั้งหมด';

  @override
  String get action_select_all_short => 'ทั้งหมด';

  @override
  String get action_delete => 'ลบ';

  @override
  String get action_done => 'เสร็จสิ้น';

  @override
  String get action_remind_me_later => 'เตือนฉันภายหลัง';

  @override
  String get action_retry => 'ลองใหม่';

  @override
  String get action_run => 'ทำงาน';

  @override
  String get action_clear_output => 'ล้างผลลัพธ์';

  @override
  String get cd_camera => 'กล้อง';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'คิวอาร์โค้ด';

  @override
  String get cd_show_hide_token => 'แสดง/ซ่อน Token';

  @override
  String get cd_copy_token => 'คัดลอก Token';

  @override
  String get cd_copy_url => 'คัดลอก URL';

  @override
  String get cd_clear_logs => 'ล้าง Log';

  @override
  String get cd_expand_collapse => 'ขยาย/พับเก็บ';

  @override
  String get cd_recording_status => 'สถานะการบันทึก';

  @override
  String get cd_trip_tracking_status => 'สถานะการติดตามทริป';

  @override
  String get cd_video_thumbnail => 'ภาพตัวอย่างวิดีโอ';

  @override
  String get cd_play => 'เล่น';

  @override
  String get cd_back => 'ย้อนกลับ';

  @override
  String get cd_play_pause => 'เล่น/หยุดชั่วคราว';

  @override
  String get cd_player_prev => 'วิดีโอก่อนหน้า';

  @override
  String get cd_player_next => 'วิดีโอถัดไป';

  @override
  String get cd_player_maximize => 'ขยายเต็มจอ';

  @override
  String get cd_player_minimize => 'ออกจากการแสดงเต็มจอ';

  @override
  String get cd_delete => 'ลบ';

  @override
  String get cd_decrease => 'ลด';

  @override
  String get cd_increase => 'เพิ่ม';

  @override
  String get cd_expand => 'ขยาย';

  @override
  String get cd_configure => 'ตั้งค่า';

  @override
  String get cd_download_log => 'ดาวน์โหลด Log';

  @override
  String get cd_reset => 'รีเซ็ต';

  @override
  String get cd_battery => 'แบตเตอรี่';

  @override
  String get cd_step_completed => 'ขั้นตอนเสร็จสิ้น';

  @override
  String get cd_permission_granted => 'อนุญาตแล้ว';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'ทริป';

  @override
  String get daemon_card_subprocesses => 'กระบวนการ';

  @override
  String get logs_panel_title => 'บันทึก';

  @override
  String get url_connecting => 'กำลังเชื่อมต่อ…';

  @override
  String get camera_selection_title => 'เลือกกล้อง';

  @override
  String get camera_selection_subtitle => 'เลือกแหล่งภาพกล้องรอบคัน';

  @override
  String get camera_current_auto => 'ปัจจุบัน: อัตโนมัติ';

  @override
  String get camera_option_auto => 'อัตโนมัติ (ตรวจจับตอนเปิดเครื่อง)';

  @override
  String get camera_option_0 => 'กล้อง 0 — รุ่น Atto';

  @override
  String get camera_option_1 => 'กล้อง 1 — รุ่น Seal (ค่าเริ่มต้น)';

  @override
  String get camera_option_2 => 'กล้อง 2';

  @override
  String get camera_option_3 => 'กล้อง 3';

  @override
  String get camera_option_4 => 'กล้อง 4';

  @override
  String get camera_option_5 => 'กล้อง 5';

  @override
  String get camera_selection_hint =>
      'โหมดอัตโนมัติจะเลือกกล้องให้เหมาะกับรุ่นรถของคุณทุกครั้งที่เปิดเครื่อง กล้อง 1 = BYD Seal, กล้อง 0 = รุ่น Atto ต้องรีสตาร์ทบริการกล้องหลังเปลี่ยน ID กล้องเพื่อให้การตั้งค่ามีผล';

  @override
  String get dashboard_scan_to_connect => 'สแกนเพื่อเชื่อมต่อ';

  @override
  String get dashboard_qr_waiting => 'กำลังรอ Tunnel…';

  @override
  String get dashboard_daemons_running_default => 'ทำงาน 0/5';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'รหัสเข้าถึง';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'สร้าง Token ใหม่';

  @override
  String get dashboard_set_password => 'ตั้งรหัสผ่าน';

  @override
  String get cd_set_password => 'ตั้งรหัสผ่านเอง';

  @override
  String get dialog_set_password_title => 'ตั้งรหัสผ่านเอง';

  @override
  String get dialog_set_password_message =>
      'ใส่รหัสผ่านใหม่สำหรับเข้าถึง รหัสนี้จะใช้แทน Token ที่ระบบสร้างให้อัตโนมัติ';

  @override
  String get dialog_set_password_hint => 'รหัสผ่านใหม่ (อย่างน้อย 12 ตัวอักษร)';

  @override
  String get toast_password_set => 'อัปเดตรหัสผ่านแล้ว';

  @override
  String get toast_password_too_short => 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร';

  @override
  String get toast_password_save_failed =>
      'บันทึกรหัสผ่านไม่สำเร็จ — บริการยังไม่พร้อม';

  @override
  String get setup_guide_title => 'เริ่มต้นใช้งาน';

  @override
  String get setup_guide_subtitle => '3 ขั้นตอนง่ายๆ เพื่อเริ่มใช้งาน:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'เลือกภาษาของคุณ';

  @override
  String get setup_language_body =>
      'ค่าเริ่มต้นจะเป็นภาษาของหน้าจอรถ แตะเพื่อเปลี่ยนภาษาสำหรับแอป BladeWatch และเว็บ Tunnel';

  @override
  String get setup_language_button => 'เลือกภาษา';

  @override
  String get setup_autostart_title => 'ปิดการจำกัดการเริ่มแอปอัตโนมัติ';

  @override
  String get setup_autostart_body =>
      'แตะด้านล่างเพื่อเปิด BYD Auto-Start แล้วยกเลิกการเลือกทั้ง BladeWatch และ บริการ BladeWatch หากไม่ทำ การบันทึกจะไม่เริ่มเมื่อเปิดรถ และคุณต้องเปิดแอปทุกครั้ง BYD จะล้างค่านี้ทุกครั้งที่ติดตั้ง';

  @override
  String get setup_autostart_button => 'เปิด BYD Auto-Start';

  @override
  String get setup_overlay_title => 'อนุญาตให้แสดงทับแอปอื่น';

  @override
  String get setup_overlay_body =>
      'เปิดใช้งานเพื่อแสดงสถานะการบันทึกวิดีโอและติดตามทริปลอยอยู่บนแอปอื่น';

  @override
  String get setup_overlay_button => 'เปิดการตั้งค่า Overlay';

  @override
  String get cd_close => 'ปิด';

  @override
  String get language_picker_title => 'ภาษา';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return 'มีให้เลือก $arg1 ภาษา';
  }

  @override
  String get language_picker_subtitle_pending => 'เลือกภาษา';

  @override
  String get language_auto_title => 'อัตโนมัติ';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'ใช้ตามระบบ · $arg1';
  }

  @override
  String get language_not_saved =>
      'เปลี่ยนภาษาแล้ว แต่บันทึกไม่ได้ — จะกลับค่าเดิมเมื่อเปิดแอปใหม่';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · อัตโนมัติ';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'ใส่คำสั่ง…';

  @override
  String get adb_preset_commands_header => 'คำสั่งที่ตั้งไว้';

  @override
  String get adb_output_header => 'ผลลัพธ์';

  @override
  String get adb_output_ready => '\$ พร้อมรับคำสั่ง…';

  @override
  String get adb_console_hero_title => 'คอนโซล ADB';

  @override
  String get adb_console_hero_subtitle => 'รันคำสั่ง Shell บนอุปกรณ์';

  @override
  String get adb_console_unavailable_title => 'ADB ไม่ได้เชื่อมต่อ';

  @override
  String get adb_console_unavailable_body =>
      'สำหรับรถคันนี้ สวิตช์ “การแก้ไขข้อบกพร่องผ่าน USB” ปกติในตัวเลือกสำหรับนักพัฒนาเพียงอย่างเดียวไม่เพียงพอ — การตั้งค่า ADB ไร้สาย (การแก้ไขข้อบกพร่องผ่านเครือข่าย) ของเครื่องเล่นกลางเองก็ต้องเปิดอยู่ด้วย และการอัปเดตระบบอาจรีเซ็ตค่านี้ได้ เปิดใช้งาน ADB ไร้สายบนเครื่องเล่นกลางอีกครั้ง หรือเชื่อมต่อผ่าน USB';

  @override
  String get adb_console_auth_pending_title => 'กำลังรอการอนุมัติ';

  @override
  String get adb_console_auth_pending_body =>
      'ตรวจสอบหน้าจอเครื่องเล่นกลางว่ามีข้อความ “อนุญาตการแก้ไขข้อบกพร่องผ่าน USB หรือไม่” แล้วกดยอมรับ จากนั้นลองใหม่อีกครั้ง';

  @override
  String get performance_connecting =>
      'กำลังเชื่อมต่อกับตัวตรวจสอบประสิทธิภาพ…';

  @override
  String get performance_hero_title => 'ประสิทธิภาพของระบบ';

  @override
  String get performance_cpu_title => 'ซีพียู';

  @override
  String get performance_cpu_system_usage => 'การใช้งานของระบบ';

  @override
  String get performance_cpu_app_usage => 'การใช้งานของแอป';

  @override
  String get performance_frequency_label => 'ความถี่';

  @override
  String get performance_temperature_label => 'อุณหภูมิ';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'หน่วยความจำ';

  @override
  String get performance_usage_label => 'การใช้งาน';

  @override
  String get performance_memory_total => 'ทั้งหมด';

  @override
  String get performance_memory_used => 'ใช้ไป';

  @override
  String get performance_memory_app => 'แอป';

  @override
  String get performance_gpu_title => 'จีพียู';

  @override
  String get performance_app_process_title => 'โปรเซสของแอป';

  @override
  String get performance_threads_label => 'เธรด';

  @override
  String get performance_gc_cycles_label => 'รอบ GC';

  @override
  String get performance_open_fds_label => 'FD ที่เปิดอยู่';

  @override
  String get performance_refreshing_footer => 'รีเฟรชทุก 3 วินาที';

  @override
  String get webview_loading => 'กำลังโหลด…';

  @override
  String get reset_title => 'ล้างข้อมูล (Reset)';

  @override
  String get reset_subtitle => 'ลบข้อมูลที่เก็บสะสมไว้ตามหมวดหมู่';

  @override
  String get reset_warning =>
      'ลบแล้วกู้คืนไม่ได้นะ พวกไฟล์วิดีโอ ทริป และประวัติแบตเตอรี่จะหายเกลี้ยง';

  @override
  String get reset_cat_trips => 'ทริปการขับขี่';

  @override
  String get reset_cat_trips_desc =>
      'ประวัติการขับขี่ เส้นทาง สถิติรายสัปดาห์/เดือน';

  @override
  String get reset_cat_soc_history => 'ประวัติ SoC & 12V';

  @override
  String get reset_cat_soc_history_desc =>
      'ข้อมูลระดับแบตเตอรี่, ประวัติชาร์จ, แรงดันแบต 12V';

  @override
  String get reset_cat_recordings => 'ไฟล์วิดีโอทั้งหมด';

  @override
  String get reset_cat_recordings_desc => 'ลบไฟล์ MP4 ทุกไฟล์ในโฟลเดอร์';

  @override
  String get reset_cat_sentry_events => 'เหตุการณ์เฝ้าระวัง';

  @override
  String get reset_cat_sentry_events_desc =>
      'คลิปเหตุการณ์จากระบบเฝ้าระวังและไฟล์ JSON ประกอบ';

  @override
  String get reset_cat_proximity => 'วิดีโอเตือนเข้าใกล้';

  @override
  String get reset_cat_proximity_desc =>
      'ลบวิดีโอที่เรดาร์จับคนเข้าใกล้ได้ทั้งหมด';

  @override
  String get reset_cat_trip_files => 'ไฟล์สถานะรถของแต่ละทริป';

  @override
  String get reset_cat_trip_files_desc => 'ลบไฟล์สถานะรถของแต่ละทริป';

  @override
  String get recording_lib_chip_any => 'อะไรก็ได้';

  @override
  String get recording_lib_chip_person => 'คน';

  @override
  String get recording_lib_chip_vehicle => 'รถยนต์';

  @override
  String get recording_lib_chip_bike => 'จักรยาน/มอเตอร์ไซค์';

  @override
  String get recording_lib_chip_animal => 'สัตว์';

  @override
  String get recording_lib_chip_alert => 'เตือนภัย';

  @override
  String get recording_lib_chip_critical => 'วิกฤต';

  @override
  String get recording_lib_selected_count_zero => 'เลือกไว้ 0 ไฟล์';

  @override
  String get recording_lib_no_recordings => 'ไม่มีวิดีโอ';

  @override
  String get recording_lib_filter_button => 'ตัวกรอง';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'ตัวกรอง · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'กรองวิดีโอ';

  @override
  String get recording_lib_filter_apply => 'นำไปใช้';

  @override
  String get recording_lib_filter_reset => 'รีเซ็ต';

  @override
  String get recording_lib_filter_section_what => 'กรองหาอะไร';

  @override
  String get recording_lib_filter_section_severity => 'ความรุนแรง';

  @override
  String get recording_lib_filter_section_type => 'ประเภท';

  @override
  String get recording_lib_chip_type_normal => 'ปกติ';

  @override
  String get recording_lib_chip_type_proximity => 'เตือนเข้าใกล้';

  @override
  String get recording_lib_date_today => 'วันนี้';

  @override
  String get recording_lib_date_yesterday => 'เมื่อวาน';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 คลิป',
      one: '$arg1 คลิป',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'เลือกวันที่';

  @override
  String get recording_lib_date_all_days => 'ทุกวัน';

  @override
  String get cd_clear_date_filter => 'แสดงทุกวัน';

  @override
  String get recording_lib_section_morning => 'เช้า';

  @override
  String get recording_lib_section_afternoon => 'บ่าย';

  @override
  String get recording_lib_section_evening => 'เย็น';

  @override
  String get recording_lib_section_night => 'กลางคืน';

  @override
  String get cd_previous_day => 'วันก่อนหน้า';

  @override
  String get cd_next_day => 'วันถัดไป';

  @override
  String get cd_open_filters => 'เปิดตัวกรอง';

  @override
  String get cd_clear_filter => 'ล้างตัวกรอง';

  @override
  String get player_title_recording => 'วิดีโอ';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'บริการกล้อง';

  @override
  String get daemon_name_surveillance => 'บริการเฝ้าระวัง';

  @override
  String get daemon_name_acc => 'การเฝ้าระวัง ACC';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'ระบบเบื้องหลัง';

  @override
  String get daemons_count_pending => 'กำลังโหลดระบบเบื้องหลัง…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return 'ทำงาน $arg1 จาก $arg2';
  }

  @override
  String get battery_health_title => 'สุขภาพแบตเตอรี่';

  @override
  String get battery_health_unavailable => 'ไม่พร้อมใช้งาน';

  @override
  String get battery_health_unavailable_desc =>
      'การประเมินสุขภาพแบตเตอรี่ไม่พร้อมใช้งาน';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% ตอน $arg2';
  }

  @override
  String get dialog_ok => 'ตกลง';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'ลบไปแล้ว $arg1 ไฟล์',
      one: 'ลบไปแล้ว $arg1 ไฟล์',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'ลบ $arg1 วิดีโอ',
      one: 'ลบ $arg1 วิดีโอ',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'นี่จะเป็นการลบ $arg1 ไฟล์วิดีโอแบบถาวร ลบแล้วกู้คืนไม่ได้นะ',
      one: 'นี่จะเป็นการลบ $arg1 ไฟล์วิดีโอแบบถาวร ลบแล้วกู้คืนไม่ได้นะ',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'แอปเป็นเวอร์ชันล่าสุดแล้ว (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'ต้องอนุญาตให้เข้าถึงพื้นที่เก็บข้อมูลก่อนเพื่อบันทึกวิดีโอ';

  @override
  String get toast_url_copied_short => 'คัดลอก URL แล้ว!';

  @override
  String get toast_camera_set_to_auto => 'ตั้งค่ากล้องเป็นอัตโนมัติแล้ว';

  @override
  String get toast_failed_to_save_short => 'บันทึกไม่สำเร็จ';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'ล้มเหลว: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'ตั้งกล้องเป็นหมายเลข $arg1 แล้ว — จะมีผลตอนสตาร์ทรถ (ACC ON) ครั้งหน้า';
  }

  @override
  String get toast_clearing_camera_config => 'กำลังล้างการตั้งค่ากล้อง…';

  @override
  String get toast_restarting_camera_daemon => 'กำลังรีสตาร์ทบริการกล้อง…';

  @override
  String get toast_camera_daemon_restarting =>
      'บริการกล้องกำลังรีสตาร์ทพร้อมตรวจสอบใหม่เต็มรูปแบบ';

  @override
  String get toast_camera_restart_failed =>
      'ล้างการตั้งค่าแล้ว แต่รีสตาร์ทบริการไม่สำเร็จ กรุณารีสตาร์ทด้วยตัวเอง';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'ล้มเหลว: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'เลือกหมวดหมู่ที่ต้องการก่อนอย่างน้อย 1 อัน';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'รีเซ็ตไม่สำเร็จ: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return 'กำลังเปลี่ยนสถานะ Traffic Monitor: $arg1…';
  }

  @override
  String get dialog_close => 'ปิด';

  @override
  String get dialog_reset => 'รีเซ็ต';

  @override
  String get dialog_delete => 'ลบ';

  @override
  String get dialog_save => 'บันทึก';

  @override
  String get dialog_enable => 'เปิดใช้งาน';

  @override
  String get dialog_disable => 'ปิดใช้งาน';

  @override
  String get dialog_keep_enabled => 'เปิดทิ้งไว้';

  @override
  String get dialog_keep_disabled => 'ปิดทิ้งไว้';

  @override
  String get dialog_regenerate => 'สร้างใหม่';

  @override
  String get dialog_reset_selected => 'รีเซ็ตที่เลือกไว้';

  @override
  String get dialog_reset_following_title => 'รีเซ็ตข้อมูลตามนี้ไหม?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'ลบแล้วกู้คืนไม่ได้นะ\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'รีเซ็ตเสร็จเรียบร้อย';

  @override
  String get dialog_traffic_cannot_check_title => 'เช็กสถานะไม่ได้';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB ไม่ได้เชื่อมต่อ และแอปไม่สามารถเชื่อมต่อใหม่ได้โดยอัตโนมัติ\n\nสำหรับรถคันนี้ สวิตช์ \"USB Debugging\" ทั่วไปในตัวเลือกนักพัฒนาเพียงอย่างเดียวไม่เพียงพอ — ต้องเปิดการตั้งค่า ADB ไร้สาย (การดีบักผ่านเครือข่าย) ของเครื่องเล่นกลางด้วย ซึ่งการอัปเดตระบบอาจรีเซ็ตค่านี้ได้ กรุณาเปิดใช้งาน ADB ไร้สายบนเครื่องเล่นกลางอีกครั้ง หรือเชื่อมต่อผ่าน USB\n\nสถานะจะอัปเดตโดยอัตโนมัติเมื่อเชื่อมต่อสำเร็จ';

  @override
  String get dialog_traffic_disable_title =>
      'ปิดใช้งาน BYD Traffic Monitor ไหม?';

  @override
  String get dialog_traffic_disable_message =>
      'แอป BYD Traffic Monitor (com.byd.trafficmonitor) เป็นแอปติดเครื่องที่คอยเช็กสภาพการจราจรเบื้องหลังตลอดเวลา\n\nทำไมถึงควรปิดล่ะ?\n\n• มันแอบใช้เน็ต (ถึงจะจอดรถอยู่ก็เถอะ)\n• กิน CPU และแบตเตอรี่\n• ไม่จำเป็นเลยถ้าคุณใช้แอปนำทางตัวอื่นอยู่แล้ว\n• บางทีก็ไปกวนสัญญาณเน็ตของกล้องหน้ารถ\n\nปิดไปก็ไม่มีปัญหา — มันมีผลแค่แผนที่ของแอปนำทางเดิมที่ติดมากับรถ ไม่ได้เกี่ยวอะไรกับแอปนำทางตัวอื่น, บลูทูธ หรือระบบอื่นๆ ในรถเลย\n\nต้องรีบูตจอรถด้วยนะ (กดปุ่มกลางคอนโซลค้างไว้ 5 วินาที) ถึงจะเห็นผล';

  @override
  String get dialog_traffic_enable_title =>
      'เปิดใช้งาน BYD Traffic Monitor อีกครั้งไหม?';

  @override
  String get dialog_traffic_enable_message =>
      'แอป BYD Traffic Monitor ปิดใช้งานอยู่ตอนนี้\n\nถ้าเปิดใช้งาน มันจะดึงข้อมูลสภาพการจราจรกลับมาแสดงบนแผนที่ของรถเหมือนเดิม แต่มันจะทำงานเบื้องหลังและกินเน็ตไปด้วยนะ\n\nต้องรีบูตจอรถด้วยนะ (กดปุ่มกลางคอนโซลค้างไว้ 5 วินาที) ถึงจะเห็นผล';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'ตัวตรวจสอบการจราจร $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'บันทึกการตั้งค่าแล้ว\n\nกรุณารีบูตจอรถของคุณเลย:\nกดปุ่มตรงกลางคอนโซลค้างไว้ 5 วินาที';

  @override
  String get traffic_monitor_loading => 'Traffic Monitor: กำลังตรวจสอบ…';

  @override
  String get traffic_monitor_tap_to_check =>
      'Traffic Monitor (แตะเพื่อตรวจสอบ)';

  @override
  String get reset_label_trips => 'ทริปการขับขี่';

  @override
  String get reset_label_soc_history => 'ประวัติ SoC และแบต 12V';

  @override
  String get reset_label_recordings => 'ไฟล์วิดีโอทั้งหมด';

  @override
  String get reset_label_sentry_events => 'เหตุการณ์เฝ้าระวัง';

  @override
  String get reset_label_proximity => 'วิดีโอเตือนเข้าใกล้';

  @override
  String get reset_label_trip_files => 'ไฟล์สถานะรถของแต่ละทริป';

  @override
  String get toast_access_code_copied => 'คัดลอกรหัสเข้าถึงแล้ว';

  @override
  String get dialog_regenerate_token_title => 'สร้าง Token ใหม่';

  @override
  String get dialog_regenerate_token_message =>
      'Token เดิมจะใช้ไม่ได้อีกต่อไป เซสชันที่ล็อกอินอยู่ทั้งหมดจะถูกบังคับให้ออก คุณแน่ใจไหม?';

  @override
  String get toast_token_regenerated_logged_out =>
      'สร้าง Token ใหม่แล้ว เซสชันเก่าถูกเตะออกหมดแล้ว';

  @override
  String get toast_token_regenerated_restart =>
      'สร้าง Token ใหม่แล้ว บริการต่างๆ อาจต้องรีสตาร์ทเพื่อให้มีผล';

  @override
  String get toast_token_regenerated_no_notify =>
      'สร้าง Token ใหม่แล้ว แต่แจ้งเตือนบริการเบื้องหลังไม่ได้';

  @override
  String get toast_token_regenerated => 'สร้าง Token ใหม่แล้ว';

  @override
  String get dashboard_no_tunnel => 'ยังไม่มี Tunnel ทำงานอยู่';

  @override
  String get dashboard_starting_tor => 'กำลังเริ่มอุโมงค์ Tor…';

  @override
  String get dashboard_waiting_url => 'กำลังรอ Tunnel URL…';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return 'ทำงาน $arg1/$arg2';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'รหัสเข้าถึง';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'ไม่ต้องตั้งค่าสำหรับ $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'Token ต้องไม่ว่าง';

  @override
  String toast_fetching_log(Object arg1) {
    return 'กำลังดึง Log ของ $arg1…';
  }

  @override
  String get toast_log_empty_or_missing => 'ไฟล์ Log ว่างเปล่าหรือหาไม่เจอ';

  @override
  String get toast_log_empty => 'ไฟล์ Log ว่างเปล่า';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'บันทึก Log ไม่สำเร็จ: $arg1';
  }

  @override
  String get toast_log_not_found => 'หาไฟล์ Log ไม่เจอ หรืออ่านไม่ได้';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return 'บันทึก $arg1 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'แชร์ $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== บันทึก $arg1 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'แหล่งที่มา: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'ดึงข้อมูล: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'หมายเหตุ: แสดงเฉพาะ 10000 บรรทัดล่าสุด (จากทั้งหมด $arg1 บรรทัด)',
      one: 'หมายเหตุ: แสดงเฉพาะ 10000 บรรทัดล่าสุด (จากทั้งหมด $arg1 บรรทัด)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'เล่นวิดีโอไม่ได้: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'ลบไฟล์วิดีโอ';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'จะลบ $arg1 ทิ้งใช่ไหม?\nลบแล้วกู้คืนไม่ได้นะ';
  }

  @override
  String get toast_recording_deleted => 'ลบวิดีโอแล้ว';

  @override
  String get toast_recording_delete_failed => 'ลบวิดีโอไม่สำเร็จ';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return 'ลบแล้ว $arg1 ไฟล์, ล้มเหลว $arg2 ไฟล์';
  }

  @override
  String get play_with_chooser => 'เล่นด้วย';

  @override
  String setup_version_banner(Object arg1) {
    return 'อัปเดตเป็น v$arg1 แล้ว — อย่าลืมไปกดยืนยันการทำงานอัตโนมัติอีกรอบนะ BYD มันชอบรีเซ็ตตอนลงแอป';
  }

  @override
  String get setup_overlay_already_granted => 'อนุญาตแล้ว';

  @override
  String camera_current_manual(Object arg1) {
    return 'ปัจจุบัน: กล้อง $arg1 (ตั้งค่าเอง)';
  }

  @override
  String get camera_current_auto_label => 'ปัจจุบัน: อัตโนมัติ';

  @override
  String get soh_estimation_active => 'ประเมินค่า SOH ทำงานอยู่';

  @override
  String get soh_oem_readout => 'ค่า SOH จากรถ — กำลังรอผลประเมินที่คำนวณได้';

  @override
  String get soh_nominal_baseline =>
      'ค่าพื้นฐานมาตรฐาน — กำลังรอข้อมูล SOH ที่เชื่อถือได้';

  @override
  String get soh_no_estimate_yet => 'ยังไม่มีค่าประเมิน — รอข้อมูลอยู่';

  @override
  String recording_lib_selected_count(Object arg1) {
    return 'เลือกไว้ $arg1 ไฟล์';
  }

  @override
  String get video_player_playback_error => 'เล่นวิดีโอมีปัญหา';

  @override
  String get video_player_no_events => 'ไม่มีเหตุการณ์';

  @override
  String get daemon_configuration_required => 'จำเป็นต้องตั้งค่า';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'วิดีโอ';

  @override
  String get status_overlay_notif_title => 'สถานะ BladeWatch';

  @override
  String get status_overlay_notif_text => 'แถบสถานะทำงานอยู่';

  @override
  String get rail_dashboard => 'ภาพรวม';

  @override
  String get rail_live => 'ภาพสด';

  @override
  String get rail_recordings => 'วิดีโอ';

  @override
  String get rail_vehicle => 'รถ';

  @override
  String get rail_trips => 'ทริป';

  @override
  String get rail_location => 'ตำแหน่ง';

  @override
  String get rail_diagnostics => 'ตรวจระบบ';

  @override
  String get rail_settings => 'ตั้งค่า';

  @override
  String get settings_section_appearance => 'รูปลักษณ์';

  @override
  String get settings_section_recording => 'การบันทึกวิดีโอ';

  @override
  String get settings_section_surveillance => 'โหมดเฝ้าระวัง';

  @override
  String get settings_section_daemons => 'บริการ';

  @override
  String get settings_section_privacy => 'ความเป็นส่วนตัวและข้อมูล';

  @override
  String get settings_section_trips => 'การเดินทาง';

  @override
  String get settings_section_trips_subtitle =>
      'อัตราค่าใช้จ่าย หน่วยระยะทาง และที่จัดเก็บการเดินทาง';

  @override
  String get settings_section_overlay => 'ข้อมูลสถานะบนภาพ';

  @override
  String get settings_overlay_subtitle =>
      'เลือกส่วนของแถบสถานะที่จะให้ลอยอยู่บนหน้าจอ';

  @override
  String get settings_overlay_camera_title => 'สถานะกล้อง';

  @override
  String get settings_overlay_camera_subtitle =>
      'แสดงสัญลักษณ์ REC / PROX ตอนที่กำลังอัดวิดีโอ';

  @override
  String get settings_overlay_trip_title => 'สถานะทริป';

  @override
  String get settings_overlay_trip_subtitle =>
      'แสดงสัญลักษณ์ TRIP ตอนที่ระบบกำลังตามรอยการเดินทาง';

  @override
  String get settings_section_about => 'เกี่ยวกับ';

  @override
  String get settings_subrail_overline => 'ตั้งค่า';

  @override
  String get cd_settings_subrail => 'เมนูตั้งค่าย่อย';

  @override
  String get settings_privacy_title => 'ความเป็นส่วนตัวและข้อมูล';

  @override
  String get settings_privacy_body =>
      'รีเซ็ตจะล้างข้อมูลการบันทึกวิดีโอ ข้อมูลการเข้าสู่ระบบที่เก็บไว้ สถานะบริการ และการตั้งค่าบนเครื่อง ทำแล้วกู้คืนไม่ได้นะ';

  @override
  String get settings_about_title => 'เกี่ยวกับ BladeWatch';

  @override
  String get settings_about_version_label => 'เวอร์ชัน';

  @override
  String get settings_about_package_label => 'บิลด์';

  @override
  String get settings_about_support_section =>
      'โปรเจกต์นี้เดินหน้าได้เพราะคนแบบคุณ';

  @override
  String get settings_about_support_share_title =>
      'บอกต่อให้เพื่อนเจ้าของรถคนอื่น';

  @override
  String get settings_about_support_share_value =>
      'ช่วยแชร์ลิงก์ให้คนใช้ BYD คนอื่นได้รู้จักแอปนี้กันเยอะๆ';

  @override
  String get settings_about_support_share_message =>
      'ลองโหลด BladeWatch ดูดิ - แอปกล้องหน้ารถ+โหมดเฝ้าระวังแบบ Open-Source สำหรับ BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'แชร์ BladeWatch';

  @override
  String get settings_about_open_link_failed => 'เปิดลิงก์ไม่ได้';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'หาเบราว์เซอร์ไม่เจอ คัดลอก URL แล้ว: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => 'สนับสนุนเวอร์ชันถัดไป ☕';

  @override
  String get settings_about_support_kofi_value =>
      'เลี้ยงกาแฟเราใน Ko-fi สักแก้ว จะได้มีแรงตื่นมาเขียนโค้ดต่อ';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'ไลเซนส์';

  @override
  String get settings_about_license_value =>
      'MIT — Open Source กดดูเต็มๆ ได้เลย';

  @override
  String get settings_about_source_title => 'ซอร์สโค้ด (Source Code)';

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
  String get settings_about_star_title => 'ไปกด ⭐ ให้ใน GitHub หน่อย';

  @override
  String get settings_about_star_value =>
      'ใช้เวลาแค่แป๊บเดียว แต่มันมีความหมายกับคนทำมากนะ';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'ขอบคุณ';

  @override
  String get settings_about_thanks_subtitle =>
      'แอปนี้สร้างขึ้นมาได้เพราะความช่วยเหลือจากผู้ร่วมพัฒนาและคนสนับสนุนทุกคนเลยนะ';

  @override
  String get settings_about_contributors_title => 'ผู้ร่วมพัฒนา';

  @override
  String get settings_about_supporters_title => 'ผู้สนับสนุน';

  @override
  String get settings_about_thanks_empty =>
      'รายชื่อจะโผล่มาตรงนี้เมื่อมีคนเข้าร่วม';

  @override
  String get settings_theme_label => 'ธีม';

  @override
  String get settings_theme_auto => 'อัตโนมัติ (ตามระบบ)';

  @override
  String get settings_theme_light => 'สว่าง';

  @override
  String get settings_theme_dark => 'มืด';

  @override
  String get settings_language_label => 'ภาษา';

  @override
  String get settings_drive_side_label => 'ตำแหน่งเมนูนำทาง';

  @override
  String get settings_drive_side_subtitle =>
      'เลือกว่าจะให้เมนูนำทางอยู่ด้านไหนของหน้าจอ';

  @override
  String get settings_drive_side_left => 'ซ้าย';

  @override
  String get settings_drive_side_left_hint => 'พวงมาลัยซ้าย · ค่าเริ่มต้น';

  @override
  String get settings_drive_side_right => 'ขวา';

  @override
  String get settings_drive_side_right_hint => 'รถพวงมาลัยขวา';

  @override
  String get settings_drive_side_auto => 'อัตโนมัติ';

  @override
  String get settings_drive_side_auto_hint => 'ตรวจจับจากตัวรถ';

  @override
  String get settings_drive_side_caption_left => 'เมนูนำทางอยู่ด้านซ้าย';

  @override
  String get settings_drive_side_caption_right => 'เมนูนำทางอยู่ด้านขวา';

  @override
  String get settings_drive_side_caption_auto_left =>
      'อัตโนมัติ — รถแจ้งว่าเป็นพวงมาลัยซ้าย';

  @override
  String get settings_drive_side_caption_auto_right =>
      'อัตโนมัติ — รถแจ้งว่าเป็นพวงมาลัยขวา';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'อัตโนมัติ — เชื่อมต่อรถไม่ได้ ใช้ด้านซ้าย';

  @override
  String get recordings_title => 'ไฟล์วิดีโอ';

  @override
  String get recordings_segment_dashcam => 'กล้องหน้ารถ';

  @override
  String get recordings_segment_surveillance => 'โหมดเฝ้าระวัง';

  @override
  String get recordings_action_settings => 'ตั้งค่า';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return 'วันนี้ $arg1 · ทั้งหมด $arg2 · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'กล้องหน้ารถ · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'โหมดเฝ้าระวัง · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'เลือกวิดีโอสิ';

  @override
  String get recordings_preview_placeholder_body =>
      'กดเลือกวิดีโอทางซ้ายเพื่อเล่นได้เลย';

  @override
  String get diagnostics_section_adb_console => 'คอนโซล ADB';

  @override
  String get diagnostics_section_traffic => 'Traffic Monitor';

  @override
  String get diagnostics_section_camera_probe => 'ตรวจสอบกล้อง';

  @override
  String get diagnostics_section_battery => 'สุขภาพแบตเตอรี่';

  @override
  String get diagnostics_section_performance => 'ประสิทธิภาพ';

  @override
  String get diagnostics_hero_title => 'วิเคราะห์ระบบ';

  @override
  String get diagnostics_hero_subtitle =>
      'เช็กสุขภาพระบบ, Log และสถานะอุปกรณ์แบบเรียลไทม์';

  @override
  String get diagnostics_health_clear => 'ปกติทั้งหมด';

  @override
  String get diagnostics_health_section => 'สุขภาพ';

  @override
  String get diagnostics_health_network => 'เครือข่าย';

  @override
  String get diagnostics_health_storage => 'พื้นที่เก็บข้อมูล';

  @override
  String get diagnostics_health_camera => 'กล้อง';

  @override
  String get diagnostics_health_battery => 'แบตเตอรี่';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'ออนไลน์';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'อุโมงค์ · $arg1';
  }

  @override
  String diagnostics_network_data_usage_line(Object arg1) {
    return '$arg1 เดือนนี้';
  }

  @override
  String get diagnostics_tunnel_state_online => 'ออนไลน์';

  @override
  String get diagnostics_tunnel_state_offline => 'ออฟไลน์';

  @override
  String get diagnostics_tunnel_state_connecting => 'กำลังเชื่อมต่อ';

  @override
  String get diagnostics_network_mobile => 'เน็ตมือถือ';

  @override
  String get diagnostics_network_ethernet => 'สายแลน (Ethernet)';

  @override
  String get diagnostics_network_offline => 'ออฟไลน์';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 คลิป · ใช้ไป $arg2',
      one: '$arg1 คลิป · ใช้ไป $arg2',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return 'ว่าง $arg1';
  }

  @override
  String get diagnostics_logs_card_title => 'Log เหตุการณ์สด';

  @override
  String get diagnostics_logs_card_subtitle =>
      'ดู Log จากระบบที่ทำงานอยู่แบบสดๆ';

  @override
  String get diagnostics_tools_section => 'เครื่องมือ';

  @override
  String get diagnostics_traffic_subtitle => 'ดูปริมาณการใช้เน็ตสดๆ';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'เช็กสถานะกล้องที่เชื่อมต่ออยู่';

  @override
  String get diagnostics_adb_subtitle =>
      'เปิด Terminal เพื่อส่งคำสั่งเข้าตัวรถ';

  @override
  String get diagnostics_battery_subtitle => 'ดูค่า SOH และสถิติแบตเตอรี่';

  @override
  String get diagnostics_settings_subtitle => 'ตั้งค่าแอป, ธีม และภาษา';

  @override
  String get settings_action_reset_data => 'ล้างข้อมูล (Reset)…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'พร้อมเฝ้าระวัง';

  @override
  String get dashboard_subtitle_all_systems => 'ระบบทั้งหมดออนไลน์';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return 'ออนไลน์ $arg1 จาก $arg2 บริการ';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'ระบบควบคุมระยะไกลออฟไลน์';

  @override
  String get dashboard_metric_recordings => 'วิดีโอวันนี้';

  @override
  String get dashboard_metric_storage => 'พื้นที่เก็บข้อมูล';

  @override
  String get dashboard_metric_tunnel => 'ระบบควบคุมระยะไกล';

  @override
  String get dashboard_metric_services => 'ระบบเบื้องหลัง';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'รถยนต์';

  @override
  String get dashboard_chip_recording_active => 'กำลังอัดวิดีโอ';

  @override
  String get dashboard_chip_recording_idle => 'ว่าง';

  @override
  String get dashboard_vehicle_tap_to_set => 'แตะเพื่อตั้งค่า';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'ตั้งค่าความจุแบตเตอรี่';

  @override
  String get vehicle_dialog_model_label => 'รุ่น';

  @override
  String get vehicle_dialog_save => 'บันทึก';

  @override
  String get settings_recording_tab_status => 'สถานะ';

  @override
  String get settings_recording_tab_capture => 'การบันทึกภาพ';

  @override
  String get settings_recording_tab_quality => 'คุณภาพ';

  @override
  String get settings_recording_tab_storage => 'ที่จัดเก็บ';

  @override
  String get settings_recording_status_title => 'สถานะการบันทึก';

  @override
  String get settings_recording_status_current_state => 'สถานะปัจจุบัน';

  @override
  String get settings_recording_status_today_count => 'การบันทึกวันนี้';

  @override
  String get settings_recording_mode_title => 'โหมดบันทึก (ACC เปิด)';

  @override
  String get settings_recording_mode_description =>
      'เลือกว่าจะให้กล้องบันทึกเมื่อใดขณะขับขี่';

  @override
  String get settings_recording_mode_none_label => 'ไม่บันทึก (ค่าเริ่มต้น)';

  @override
  String get settings_recording_mode_none_desc =>
      'ไม่บันทึก — ระบบเฝ้าระวังยังทำงานอยู่';

  @override
  String get settings_recording_mode_continuous_label => 'ต่อเนื่อง';

  @override
  String get settings_recording_mode_continuous_desc =>
      'บันทึกตลอดเวลาขณะขับขี่';

  @override
  String get settings_recording_mode_drive_label => 'โหมดขับขี่';

  @override
  String get settings_recording_mode_drive_desc =>
      'บันทึกเฉพาะเมื่อรถเคลื่อนที่';

  @override
  String get settings_recording_mode_proximity_label => 'การเฝ้าระวังระยะใกล้';

  @override
  String get settings_recording_mode_proximity_desc =>
      'บันทึกเมื่อตรวจพบการเคลื่อนไหว';

  @override
  String get settings_recording_limit_title => 'ขีดจำกัดการบันทึก';

  @override
  String get settings_recording_limit_description =>
      'ความยาวสูงสุดต่อไฟล์ การบันทึกจะแยกเป็นไฟล์ใหม่ตามช่วงเวลานี้';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_priority_title => 'ลำดับความสำคัญการบันทึก';

  @override
  String get settings_recording_priority_description =>
      'การบันทึกจัดการกับไฟดับกะทันหันอย่างไร';

  @override
  String get settings_recording_priority_performance_label => 'ประสิทธิภาพ';

  @override
  String get settings_recording_priority_performance_desc =>
      'ใช้ CPU น้อยลง หากไฟดับกะทันหัน ส่วนการบันทึกปัจจุบัน (สูงสุดตามขีดจำกัดการบันทึกของคุณ) อาจสูญหาย';

  @override
  String get settings_recording_priority_reliability_label => 'ความน่าเชื่อถือ';

  @override
  String get settings_recording_priority_reliability_desc =>
      'ใช้ CPU มากขึ้นเล็กน้อยเพื่อบันทึกบ่อยขึ้น หากไฟดับกะทันหัน จะสูญเสียไม่เกินประมาณหนึ่งนาที';

  @override
  String get settings_recording_overlay_fields_title => 'ฟิลด์ซ้อนทับ';

  @override
  String get settings_recording_overlay_fields_description =>
      'เลือกสิ่งที่จะแสดงในฟิลด์ซ้อนทับที่ฝังอยู่บนวิดีโอต่อเนื่อง';

  @override
  String get settings_recording_overlay_field_speed => 'ความเร็ว';

  @override
  String get settings_recording_overlay_field_gear => 'เกียร์';

  @override
  String get settings_recording_overlay_field_turn_signal_left =>
      'ไฟเลี้ยวซ้าย';

  @override
  String get settings_recording_overlay_field_turn_signal_right =>
      'ไฟเลี้ยวขวา';

  @override
  String get settings_recording_overlay_field_brake_pedal => 'แป้นเบรก';

  @override
  String get settings_recording_overlay_field_accel_pedal => 'คันเร่ง';

  @override
  String get settings_recording_overlay_field_seatbelt_driver =>
      'เข็มขัดนิรภัยคนขับ';

  @override
  String get settings_recording_overlay_field_seatbelt_passenger =>
      'เข็มขัดนิรภัยผู้โดยสาร';

  @override
  String get settings_recording_overlay_field_timestamp => 'วันที่และเวลา';

  @override
  String get settings_recording_quality_title => 'คุณภาพการบันทึก';

  @override
  String get settings_recording_storage_title => 'ที่จัดเก็บการบันทึก';

  @override
  String get settings_recording_storage_confirm_title => 'ลบการบันทึกหรือไม่?';

  @override
  String settings_recording_storage_confirm_message(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'การดำเนินการนี้จะลบการบันทึก $arg1 รายการ ($arg2)',
      one: 'การดำเนินการนี้จะลบการบันทึก $arg1 รายการ ($arg2)',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_confirm_unknown_title =>
      'ไม่ทราบผลกระทบ';

  @override
  String get settings_recording_storage_confirm_unknown_message =>
      'ไม่สามารถระบุได้ว่าการเปลี่ยนแปลงนี้จะลบอะไรบ้าง การลดขีดจำกัดอาจลบการบันทึกที่มีอยู่';

  @override
  String get settings_recording_storage_location_label => 'ตำแหน่งจัดเก็บ';

  @override
  String get settings_recording_storage_internal => 'ที่จัดเก็บภายใน';

  @override
  String get settings_recording_storage_sd_card => 'การ์ด SD';

  @override
  String get settings_recording_storage_sd_card_na => 'การ์ด SD (ไม่มี)';

  @override
  String get settings_recording_storage_sd_mount_failed_title =>
      'การ์ด SD ไม่ได้ต่อเชื่อม';

  @override
  String get settings_recording_storage_limit_label =>
      'ขีดจำกัดพื้นที่ — ลบรายการเก่าที่สุดอัตโนมัติเมื่อถึงขีดจำกัด';

  @override
  String get settings_recording_storage_usage_label => 'การใช้พื้นที่จัดเก็บ';

  @override
  String get settings_recording_storage_files_label => 'ไฟล์';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return 'ใช้ $arg1 / จำกัด $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 รายการบันทึก',
      one: '$arg1 รายการบันทึก',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'เส้นทาง';

  @override
  String get settings_recording_storage_sd_free_label => 'พื้นที่ว่างการ์ด SD';

  @override
  String get settings_recording_storage_internal_free_label =>
      'พื้นที่ว่างภายใน';

  @override
  String get settings_recording_format_title => 'ฟอร์แมตไดรฟ์ภายนอก';

  @override
  String get settings_recording_format_warning =>
      'ลบข้อมูลทั้งหมดในการ์ด SD หรือไดรฟ์ USB อย่างถาวร';

  @override
  String get settings_recording_format_confirm =>
      'แตะอีกครั้ง — ข้อมูลทั้งหมดจะถูกลบ';

  @override
  String get settings_recording_format_running => 'กำลังฟอร์แมต… โปรดรอ';

  @override
  String get settings_recording_format_button => 'ฟอร์แมตการ์ด SD / USB';

  @override
  String get settings_recording_format_no_drive => 'ไม่พบไดรฟ์แบบถอดได้';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'ฟอร์แมตสำเร็จ เส้นทางใหม่: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'แคตตาล็อกฐานข้อมูล';

  @override
  String get settings_recording_sync_description =>
      'ปรับรายการบันทึกให้ตรงกับไฟล์บนดิสก์';

  @override
  String get settings_recording_sync_running => 'กำลังซิงค์…';

  @override
  String get settings_recording_sync_button => 'ซิงค์ฐานข้อมูล';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'ซิงค์แล้ว: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => 'กำลังซิงค์อยู่แล้ว';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'ซิงค์ล้มเหลว: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'ใช้การเปลี่ยนแปลง';

  @override
  String get settings_recording_dismiss => 'ปิด';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'ยังไม่รองรับการเริ่ม/หยุด $arg1';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return 'ใช้ไป $arg1 · ว่าง $arg2';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'พื้นที่เก็บข้อมูล —';

  @override
  String get dashboard_tunnel_offline => 'ออฟไลน์';

  @override
  String get dashboard_tunnel_online => 'ออนไลน์';

  @override
  String get dashboard_tunnel_connecting => 'กำลังเชื่อมต่อ…';

  @override
  String get dashboard_trips_this_week => 'สัปดาห์นี้';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 ทริป',
      one: '$arg1 ทริป',
    );
    return '$_temp0';
  }

  @override
  String dashboard_trips_distance_km(Object arg1) {
    return '$arg1 km';
  }

  @override
  String dashboard_trips_distance_mi(Object arg1) {
    return '$arg1 ไมล์';
  }

  @override
  String dashboard_trips_duration(Object arg1) {
    return '$arg1';
  }

  @override
  String get dashboard_trips_label_trips => 'ทริป';

  @override
  String get dashboard_trips_label_distance => 'ระยะทาง';

  @override
  String get dashboard_trips_label_time => 'เวลาขับ';

  @override
  String get dashboard_trips_no_data => 'ยังไม่มีทริปในสัปดาห์นี้';

  @override
  String get dashboard_trips_unavailable => 'เริ่มขับเพื่อดูสถิติ';

  @override
  String get dashboard_trips_loading => 'กำลังโหลด…';

  @override
  String get dashboard_trips_view_all => 'ดูทริปทั้งหมด';

  @override
  String get dashboard_action_live => 'ภาพสด';

  @override
  String get dashboard_action_live_subtitle => 'ดูกล้องสด';

  @override
  String get dashboard_action_recordings => 'ไฟล์วิดีโอ';

  @override
  String get dashboard_action_settings => 'ตั้งค่า';

  @override
  String get dashboard_action_settings_subtitle => 'การตั้งค่าและเกี่ยวกับ';

  @override
  String get settings_hero_title => 'ตั้งค่า';

  @override
  String get settings_hero_overline => 'BLADEWATCH';

  @override
  String get settings_hero_subtitle =>
      'ปรับหน้าตา, การบันทึกวิดีโอ, โหมดเฝ้าระวัง และข้อมูลต่างๆ บนเครื่อง';

  @override
  String get settings_overline_preferences => 'การตั้งค่าทั่วไป';

  @override
  String get settings_overline_about_data => 'ข้อมูล';

  @override
  String get settings_quick_theme_label => 'ธีม';

  @override
  String get settings_quick_language_label => 'ภาษา';

  @override
  String get settings_section_recording_subtitle =>
      'บัฟเฟอร์ก่อน/หลัง, โคเดก, ขีดจำกัดพื้นที่จัดเก็บ';

  @override
  String get settings_section_surveillance_subtitle =>
      'การตั้งเวลา, ความไวต่อการเคลื่อนไหว, การตรวจจับวัตถุ';

  @override
  String get settings_section_daemons_subtitle =>
      'อุโมงค์ Tor และบริการเบื้องหลัง';

  @override
  String get settings_about_row_title => 'เกี่ยวกับ BladeWatch';

  @override
  String get settings_about_row_subtitle => 'เวอร์ชัน, ไลเซนส์, สนับสนุนคนทำ';

  @override
  String get settings_reset_row_subtitle =>
      'ลบไฟล์วิดีโอ, เหตุการณ์ หรือเคลียร์แคช';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'ปรับเปลี่ยนธีม, ภาษา และรูปแบบหน้าจอ';

  @override
  String get settings_theme_active_auto_caption =>
      'เปลี่ยนตามธีมของตัวรถอัตโนมัติ';

  @override
  String get settings_theme_active_light_caption => 'ใช้ธีมสว่างเสมอ';

  @override
  String get settings_theme_active_dark_caption => 'ใช้ธีมมืดเสมอ';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return 'มีให้เลือก $arg1 จาก $arg2 ภาษา';
  }

  @override
  String get settings_language_card_title => 'ภาษาของแอป';

  @override
  String get settings_privacy_stance_title => 'เก็บข้อมูลในเครื่องคุณเท่านั้น';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch ทำงานบนจอรถของคุณ 100% จะไม่มีข้อมูลไหนถูกส่งออกจากรถยกเว้นผ่าน Tunnel และส่วนเสริมที่คุณตั้งค่าเอง';

  @override
  String get settings_privacy_overline_storage => 'พื้นที่เก็บข้อมูลในเครื่อง';

  @override
  String get settings_privacy_overline_reset => 'ล้างข้อมูล (RESET)';

  @override
  String get settings_privacy_storage_clips_label => 'วิดีโอที่เก็บไว้';

  @override
  String get settings_privacy_storage_size_label => 'ขนาดทั้งหมด';

  @override
  String get settings_privacy_storage_unavailable => 'ไม่มีข้อมูล';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 คลิป',
      one: '$arg1 คลิป',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'เลือกลบข้อมูล: ไฟล์วิดีโอ, เหตุการณ์, การตั้งค่าบริการ, แคชข้อมูลรถ…';

  @override
  String get settings_developer_overline => 'นักพัฒนา';

  @override
  String get settings_developer_timing_logs_title => 'Log เวลาทำงานของบริการ';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'บันทึกตัวจับเวลาตอนบริการเริ่มทำงาน ปิดไว้ตอนใช้งานปกติเพื่อให้ logcat สะอาด';

  @override
  String get settings_developer_debug_logs_title =>
      'Log สำหรับนักพัฒนา (Debug)';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'บันทึกเหตุการณ์ Activity และ Fragment ทั้งหมดรวมถึงขั้นตอนเริ่มทำงานไปที่ /storage/emulated/0/BladeWatch/data/debug_app.log ระบบจะเก็บข้อมูลตอนแครชเสมอ ค่าเริ่มต้นคือปิด';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'กล้อง $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'กล้อง $arg1 (ตั้งค่าเอง)';
  }

  @override
  String get diagnostics_camera_value_probing => 'กำลังตรวจสอบ…';

  @override
  String get diagnostics_camera_value_offline => 'ออฟไลน์';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'กำลังรอข้อมูล';

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
      other: '$arg1 คลิป · บันทึกแล้ว $arg2',
      one: '$arg1 คลิป · บันทึกแล้ว $arg2',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'ฝาท้าย';

  @override
  String get vehicle_tab_climate => 'แอร์';

  @override
  String get vehicle_tab_seats => 'เบาะนั่ง';

  @override
  String get vehicle_tab_windows => 'กระจก';

  @override
  String get vehicle_tab_lights => 'ไฟรถ';

  @override
  String get vehicle_tab_adas => 'ระบบช่วยขับ (ADAS)';

  @override
  String get vehicle_control_charging_tab => 'การชําระเงิน';

  @override
  String get vehicle_locked => 'ล็อกอยู่';

  @override
  String get vehicle_unlocked => 'ปลดล็อกแล้ว';

  @override
  String get vehicle_range_label => 'ระยะวิ่ง';

  @override
  String get vehicle_data_unavailable => 'ไม่มีข้อมูลรถ';

  @override
  String get vehicle_action_failed =>
      'ทำรายการไม่สำเร็จ ตรวจสอบการเชื่อมต่อกับรถ';

  @override
  String get vehicle_open_trunk => 'เปิดฝาท้าย';

  @override
  String get vehicle_close_trunk => 'ปิดฝากระโปรงท้าย';

  @override
  String get vehicle_trunk_info_open => 'การเปิดฝาท้ายจะปลดล็อกรถก่อน';

  @override
  String get vehicle_ac_on => 'เปิดแอร์แล้ว';

  @override
  String get vehicle_ac_off => 'ปิดแอร์แล้ว';

  @override
  String get vehicle_max_cooling_on => 'ทำความเย็นสูงสุด: เปิด';

  @override
  String get vehicle_max_cooling_off => 'ทำความเย็นสูงสุด: ปิด';

  @override
  String get vehicle_screen_on => 'หน้าจอ: เปิด';

  @override
  String get vehicle_screen_off => 'หน้าจอ: ปิด';

  @override
  String get vehicle_media_volume_label => 'ระดับเสียงสื่อ';

  @override
  String get vehicle_media_mute => 'ปิดเสียง';

  @override
  String get vehicle_media_muted => 'ปิดเสียงแล้ว';

  @override
  String get vehicle_front_defrost => 'ละลายน้ำแข็งกระจกหน้า';

  @override
  String get vehicle_rear_defrost => 'ละลายน้ำแข็งกระจกหลัง';

  @override
  String get vehicle_temp_label => 'อุณหภูมิ';

  @override
  String get vehicle_fan_speed_label => 'ความแรงพัดลม';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'ระดับ $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return 'ในรถ: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => 'คนขับ';

  @override
  String get vehicle_seat_passenger => 'ผู้โดยสาร';

  @override
  String get vehicle_seat_no_controls => 'รถคันนี้ไม่มีระบบควบคุมเบาะ';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return 'อุ่นเบาะ $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return 'เย็นเบาะ $arg1';
  }

  @override
  String get vehicle_heat_off => '(ปิด)';

  @override
  String get vehicle_heat_low => '(ต่ำ)';

  @override
  String get vehicle_heat_high => '(สูง)';

  @override
  String get vehicle_seat_pos_1 => 'ตำแหน่ง 1';

  @override
  String get vehicle_seat_pos_2 => 'ตำแหน่ง 2';

  @override
  String get vehicle_all_windows => 'กระจกทั้งหมด';

  @override
  String get vehicle_window_awake_note => 'ใช้งานได้เฉพาะเมื่อรถตื่นอยู่';

  @override
  String get vehicle_window_front_left => 'หน้าซ้าย';

  @override
  String get vehicle_window_front_right => 'หน้าขวา';

  @override
  String get vehicle_window_rear_left => 'หลังซ้าย';

  @override
  String get vehicle_window_rear_right => 'หลังขวา';

  @override
  String get vehicle_window_close => 'ปิด';

  @override
  String get vehicle_window_close_vent => 'ปิดช่องระบาย';

  @override
  String get vehicle_window_vent_12 => 'เปิดระบาย 12%';

  @override
  String get vehicle_window_open_all => 'เปิดทั้งหมด';

  @override
  String get vehicle_sunroof => 'ซันรูฟ';

  @override
  String get vehicle_sunshade => 'ม่านบังแดด';

  @override
  String get vehicle_btn_drl_title => 'ไฟส่องสว่างตอนกลางวัน (DRL)';

  @override
  String get vehicle_btn_slw_title => 'แจ้งเตือนจำกัดความเร็ว';

  @override
  String get vehicle_control_section_charge_cap => 'ขีดจำกัดการชาร์จ';

  @override
  String get vehicle_charge_cap_not_supported =>
      'รถคันนี้ไม่รองรับการตั้งขีดจำกัดการชาร์จ';

  @override
  String get vehicle_charge_limit_label => 'ขีดจำกัดการชาร์จ';

  @override
  String get vehicle_enable_charge_limit => 'เปิดขีดจำกัดการชาร์จ';

  @override
  String get vehicle_charge_limit_range => 'ต่ำสุด 50%, สูงสุด 100%';

  @override
  String get vehicle_tyre_no_signal => 'ไม่มีสัญญาณ';

  @override
  String get vehicle_tyre_slow_leak => 'ลมซึม';

  @override
  String get vehicle_tyre_fast_leak => 'ลมรั่วเร็ว';

  @override
  String get vehicle_tyre_low => 'ลมยางอ่อน';

  @override
  String get vehicle_tyre_high => 'ลมยางแข็ง';

  @override
  String get vehicle_tyre_ok => 'ปกติ';

  @override
  String get vehicle_tyre_check_pressure => 'เช็กลมยาง';

  @override
  String get vehicle_toggle_on => 'เปิด';

  @override
  String get vehicle_toggle_off => 'ปิด';

  @override
  String get vehicle_err_climate_control => 'ควบคุมแอร์ไม่สำเร็จ';

  @override
  String get vehicle_err_max_cooling => 'ทำความเย็นสูงสุดไม่สำเร็จ';

  @override
  String get vehicle_err_drl_control => 'ควบคุมไฟ DRL ไม่สำเร็จ';

  @override
  String get vehicle_err_slw_control => 'ควบคุม ADAS ไม่สำเร็จ';

  @override
  String get vehicle_err_charge_limit_toggle => 'สลับขีดจำกัดการชาร์จไม่สำเร็จ';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'ลด $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'เพิ่ม $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'กำลังเชื่อมต่อ…';

  @override
  String get vehicle_appearance_model_title => 'เลือกรุ่น';

  @override
  String get vehicle_appearance_custom_color => 'สีกำหนดเอง';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'แบต: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'ระยะวิ่ง: $arg1 km';
  }

  @override
  String vehicle_status_fuel_fmt(Object arg1) {
    return 'น้ำมัน: $arg1%';
  }

  @override
  String vehicle_status_fuel_range_fmt(Object arg1) {
    return 'ระยะวิ่งด้วยน้ำมัน: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'แบต: —';

  @override
  String get vehicle_status_range_unknown => 'ระยะวิ่ง: —';

  @override
  String get startup_subtitle => 'กำลังเตรียมกล้องหน้ารถให้พร้อม';

  @override
  String get startup_header_preparing => 'กำลังเตรียมความพร้อม…';

  @override
  String get startup_header_starting => 'กำลังเริ่มทำงาน…';

  @override
  String get startup_header_verifying => 'ใกล้พร้อมแล้ว…';

  @override
  String get startup_header_ready => 'ทุกอย่างพร้อมแล้ว';

  @override
  String get startup_daemon_camera => 'กล้อง';

  @override
  String get startup_daemon_camera_desc => 'ภาพสดและการบันทึก';

  @override
  String get startup_daemon_sentry => 'โหมดเฝ้าระวัง';

  @override
  String get startup_daemon_sentry_desc => 'ตรวจจับความเคลื่อนไหวและแจ้งเตือน';

  @override
  String get startup_daemon_parking => 'เฝ้าระวังขณะจอด';

  @override
  String get startup_daemon_parking_desc => 'คอยเฝ้าดูตอนจอดรถ';

  @override
  String get startup_status_waiting => 'กำลังรอ';

  @override
  String get startup_status_starting => 'กำลังเริ่ม';

  @override
  String get startup_status_ready => 'พร้อม';

  @override
  String get startup_status_failed => 'ล้มเหลว';

  @override
  String get startup_continue_anyway => 'ข้ามไปก่อน';

  @override
  String get startup_continue => 'ต่อไป →';

  @override
  String get live_retry => 'ลองใหม่';

  @override
  String get live_connecting => 'กำลังเชื่อมต่อกล้อง…';

  @override
  String live_error_fmt(Object arg1) {
    return 'ผิดพลาด: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'ใช้กล้องไม่ได้\n$arg1';
  }

  @override
  String get live_direction_all => 'ทั้งหมด';

  @override
  String get live_direction_front => 'หน้า';

  @override
  String get live_direction_right => 'ขวา';

  @override
  String get live_direction_rear => 'หลัง';

  @override
  String get live_direction_left => 'ซ้าย';

  @override
  String get trip_no_route_data => 'ไม่มีข้อมูลเส้นทางของทริปนี้';

  @override
  String get trips_tab_trips => 'การเดินทาง';

  @override
  String get trips_tab_stats => 'สถิติ';

  @override
  String get trips_tab_storage => 'พื้นที่จัดเก็บ';

  @override
  String get trips_filter_7_days => '7 วัน';

  @override
  String get trips_filter_14_days => '14 วัน';

  @override
  String get trips_filter_30_days => '30 วัน';

  @override
  String trips_load_error(Object message) {
    return 'ข้อผิดพลาด: $message';
  }

  @override
  String get trips_empty_state => 'ยังไม่มีการบันทึกการเดินทาง';

  @override
  String get trips_period_summary_title => 'สรุปช่วงเวลา';

  @override
  String get trips_stat_trips => 'ทริป';

  @override
  String get trips_stat_hours => 'ชั่วโมง';

  @override
  String get trips_stat_efficiency => 'ประสิทธิภาพ';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'คะแนน: $score';
  }

  @override
  String get trips_driver_score_title => 'คะแนนผู้ขับขี่';

  @override
  String trips_driver_score_overall(Object score) {
    return 'รวม: $score / 100';
  }

  @override
  String get trips_range_title => 'ระยะทางที่ปรับเฉพาะบุคคล';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'ค่าประมาณ BYD: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'ระยะทางจากน้ำมัน: $km';
  }

  @override
  String get trips_range_no_data => 'ข้อมูลยังไม่เพียงพอ';

  @override
  String get trips_dna_title => 'DNA การขับขี่';

  @override
  String get trips_dna_anticipation => 'การคาดการณ์';

  @override
  String get trips_dna_smoothness => 'ความนุ่มนวล';

  @override
  String get trips_dna_speed_discipline => 'วินัยความเร็ว';

  @override
  String get trips_dna_efficiency => 'ประสิทธิภาพ';

  @override
  String get trips_dna_consistency => 'ความสม่ำเสมอ';

  @override
  String get trips_storage_title => 'พื้นที่จัดเก็บการเดินทาง';

  @override
  String get trips_storage_analytics_label => 'การวิเคราะห์ทริป';

  @override
  String get trips_storage_rate_label => 'อัตราค่าไฟ';

  @override
  String get trips_storage_fuel_price_label => 'ราคาน้ำมัน (ต่อลิตร)';

  @override
  String get trips_storage_tank_capacity_label => 'ความจุถังน้ำมัน (ลิตร)';

  @override
  String get trips_storage_distance_unit_label => 'หน่วยระยะทาง';

  @override
  String get trips_storage_location_label => 'ตำแหน่งจัดเก็บ';

  @override
  String get trips_storage_internal => 'ที่จัดเก็บภายใน';

  @override
  String get trips_storage_sd_card => 'การ์ด SD';

  @override
  String get trips_storage_sd_card_unavailable => 'การ์ด SD (ไม่มี)';

  @override
  String get trips_storage_apply => 'ใช้การเปลี่ยนแปลง';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return 'ใช้ $used $unit / จำกัด $limit MB · $count ทริป';
  }

  @override
  String get trips_sync_title => 'แคตตาล็อกฐานข้อมูล';

  @override
  String get trips_sync_description =>
      'ปรับรายการทริปให้ตรงกับไฟล์เทเลเมทรีบนดิสก์';

  @override
  String get trips_sync_button => 'ซิงค์ฐานข้อมูล';

  @override
  String get trips_sync_running => 'กำลังซิงค์…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'ซิงค์สำเร็จ: +$added -$removed (รวม $total)';
  }

  @override
  String get trips_sync_failed_generic => 'การซิงค์ล้มเหลว';

  @override
  String get trips_detail_summary_title => 'สรุปการเดินทาง';

  @override
  String get trips_detail_distance => 'ระยะทาง';

  @override
  String get trips_detail_duration => 'ระยะเวลา';

  @override
  String get trips_detail_energy => 'พลังงาน';

  @override
  String get trips_detail_avg_speed => 'ความเร็วเฉลี่ย';

  @override
  String get trips_detail_max_speed => 'ความเร็วสูงสุด';

  @override
  String get trips_detail_soc => 'ระดับแบตเตอรี่';

  @override
  String get trips_detail_cost => 'ค่าใช้จ่าย';

  @override
  String get trips_detail_ext_temp => 'อุณหภูมิภายนอก';

  @override
  String get trips_detail_fuel_used => 'น้ำมัน';

  @override
  String get trips_detail_fuel_cost => 'ค่าน้ำมัน';

  @override
  String get trips_detail_electric_cost => 'ค่าไฟฟ้า';

  @override
  String get trips_detail_elev_gain => 'ความสูงที่ไต่';

  @override
  String get trips_detail_scores_title => 'คะแนนการขับขี่';

  @override
  String get trips_detail_unavailable => 'ไม่มีรายละเอียดการเดินทาง';

  @override
  String get trips_detail_loading => 'กำลังโหลดการเดินทาง…';

  @override
  String trips_detail_route_points(Object count) {
    return 'บันทึกจุด GPS $count จุด';
  }

  @override
  String get rec_severity_critical => 'วิกฤต';

  @override
  String get rec_severity_alert => 'เตือนภัย';

  @override
  String get location_loading_title => 'กำลังโหลดแผนที่';

  @override
  String get location_permission_missing_title => 'ต้องการสิทธิ์เข้าถึงตำแหน่ง';

  @override
  String get location_permission_denied_title => 'ปฏิเสธสิทธิ์';

  @override
  String get location_provider_disabled_title => 'ปิดใช้งาน GPS';

  @override
  String get location_waiting_for_fix_title => 'กำลังรอสัญญาณ GPS';

  @override
  String get location_car_location_title => 'ตำแหน่งรถ';

  @override
  String get location_stale_title => 'ตำแหน่งล้าสมัย';

  @override
  String get location_tile_failure_title => 'แผนที่ไม่พร้อมใช้งาน';

  @override
  String get location_tile_failure_subtitle => 'เครือข่ายไม่พร้อมใช้งาน';

  @override
  String get location_error_title => 'ข้อผิดพลาดด้านตำแหน่ง';

  @override
  String get location_action_grant => 'อนุญาต';

  @override
  String get location_action_retry => 'ลองอีกครั้ง';

  @override
  String get location_mode_auto => 'อัตโนมัติ';

  @override
  String get location_mode_light => 'สว่าง';

  @override
  String get location_mode_dark => 'มืด';

  @override
  String get cd_recenter_on_car => 'จัดกึ่งกลางที่รถ';

  @override
  String get recording_lib_no_recordings_normal => 'ไม่มีการบันทึกปกติ';

  @override
  String get recording_lib_no_recordings_sentry => 'ไม่มีเหตุการณ์เฝ้าระวัง';

  @override
  String get recording_lib_no_recordings_proximity =>
      'ไม่มีเหตุการณ์ความใกล้ชิด';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'คน';

  @override
  String get video_player_legend_car => 'รถยนต์';

  @override
  String get video_player_legend_bike => 'จักรยาน';

  @override
  String get video_player_legend_motion => 'การเคลื่อนไหว';

  @override
  String get recording_lib_proximity_very_close => 'ใกล้มาก';

  @override
  String get recording_lib_proximity_close => 'ใกล้';

  @override
  String get recording_lib_proximity_mid => 'ปานกลาง';

  @override
  String get recording_lib_proximity_far => 'ไกล';

  @override
  String get surveillance_tab_general => 'ทั่วไป';

  @override
  String get surveillance_tab_detection => 'การตรวจจับ';

  @override
  String get surveillance_tab_recording => 'การบันทึก';

  @override
  String get surveillance_tab_storage => 'ที่เก็บข้อมูล';

  @override
  String get surveillance_tab_advanced => 'ขั้นสูง';

  @override
  String get surveillance_general_title => 'โหมดเฝ้าระวัง';

  @override
  String get surveillance_general_enable => 'เปิดใช้งานการเฝ้าระวัง';

  @override
  String get surveillance_general_status => 'สถานะ';

  @override
  String get surveillance_general_status_running => 'กำลังทำงาน';

  @override
  String get surveillance_general_status_idle => 'ไม่ทำงาน';

  @override
  String get surveillance_general_events_today => 'เหตุการณ์วันนี้';

  @override
  String get surveillance_safe_locations_title => 'สถานที่ปลอดภัย';

  @override
  String get surveillance_safe_locations_subtitle =>
      'กล้องจะไม่เริ่มทำงานเมื่อจอดที่นี่';

  @override
  String get surveillance_safe_locations_enable => 'ปิดใช้งานที่สถานที่ปลอดภัย';

  @override
  String get surveillance_safe_locations_empty =>
      'ยังไม่มีการเพิ่มสถานที่ปลอดภัย';

  @override
  String get surveillance_safe_locations_add_current =>
      'เพิ่มตำแหน่งปัจจุบันเป็นเขตปลอดภัย';

  @override
  String get surveillance_safe_locations_no_gps => 'ไม่มีตำแหน่ง GPS';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'การตั้งค่าการตรวจจับ';

  @override
  String get surveillance_detection_preset_label =>
      'ค่าตั้งล่วงหน้าสภาพแวดล้อม';

  @override
  String get surveillance_preset_outdoor => 'กลางแจ้ง';

  @override
  String get surveillance_preset_garage => 'โรงรถ';

  @override
  String get surveillance_preset_street => 'ถนน';

  @override
  String get surveillance_preset_custom => 'กำหนดเอง';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'ความไว (1=เข้มงวด, 5=ไว): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'ตรวจจับวัตถุ';

  @override
  String get surveillance_detection_object_person => 'คน';

  @override
  String get surveillance_detection_object_car => 'รถยนต์';

  @override
  String get surveillance_detection_object_bike => 'จักรยาน';

  @override
  String get surveillance_recording_title => 'การบันทึกเหตุการณ์';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'บันทึกล่วงหน้า (วินาทีก่อนเหตุการณ์): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'บันทึกต่อ (วินาทีหลังเหตุการณ์): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'ที่เก็บข้อมูลการเฝ้าระวัง';

  @override
  String get surveillance_storage_location_label => 'ตำแหน่งที่เก็บข้อมูล';

  @override
  String get surveillance_storage_internal => 'ภายใน';

  @override
  String get surveillance_storage_sd_card => 'การ์ด SD';

  @override
  String get surveillance_storage_sd_card_na => 'การ์ด SD (ไม่มี)';

  @override
  String get surveillance_storage_limit_label =>
      'ขีดจำกัดที่เก็บข้อมูล — ลบไฟล์เก่าสุดอัตโนมัติเมื่อถึงขีดจำกัด';

  @override
  String get surveillance_storage_usage_label => 'การใช้พื้นที่จัดเก็บ';

  @override
  String get surveillance_storage_files_label => 'ไฟล์';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return 'ใช้ $arg1 / จำกัด $arg2';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 เหตุการณ์',
      one: '$arg1 เหตุการณ์',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'เส้นทาง';

  @override
  String get surveillance_format_title => 'ฟอร์แมตไดรฟ์ภายนอก';

  @override
  String get surveillance_format_warning =>
      'ลบข้อมูลทั้งหมดบนการ์ด SD หรือไดรฟ์ USB อย่างถาวร';

  @override
  String get surveillance_format_button => 'ฟอร์แมตการ์ด SD/USB';

  @override
  String get surveillance_format_confirm =>
      'แตะอีกครั้ง — ข้อมูลทั้งหมดจะถูกลบ';

  @override
  String get surveillance_format_running => 'กำลังฟอร์แมต… กรุณารอสักครู่';

  @override
  String get surveillance_dismiss => 'ปิด';

  @override
  String get surveillance_sync_title => 'แคตตาล็อกฐานข้อมูล';

  @override
  String get surveillance_sync_description =>
      'ปรับดัชนีการเฝ้าระวังให้ตรงกับไฟล์บนดิสก์';

  @override
  String get surveillance_sync_button => 'ซิงค์ฐานข้อมูล';

  @override
  String get surveillance_sync_running => 'กำลังซิงค์…';

  @override
  String get surveillance_advanced_camera_title => 'เลือกกล้อง';

  @override
  String get surveillance_advanced_camera_front => 'หน้า';

  @override
  String get surveillance_advanced_camera_right => 'ขวา';

  @override
  String get surveillance_advanced_camera_rear => 'หลัง';

  @override
  String get surveillance_advanced_camera_left => 'ซ้าย';

  @override
  String get surveillance_advanced_ai_title => 'AI และการยับยั้ง';

  @override
  String get surveillance_advanced_ai_detection => 'การตรวจจับด้วย AI';

  @override
  String get surveillance_advanced_night_mode => 'โหมดกลางคืน';

  @override
  String get surveillance_advanced_deterrent_label => 'การดำเนินการยับยั้ง';

  @override
  String get surveillance_deterrent_silent => 'เงียบ';

  @override
  String get surveillance_deterrent_horn => 'แตร';

  @override
  String get surveillance_deterrent_flash => 'แฟลช';

  @override
  String get surveillance_apply_button => 'นำการเปลี่ยนแปลงไปใช้';

  @override
  String get surveillance_apply_failed => 'บันทึกไม่สำเร็จ';

  @override
  String get dashboard_tor_bootstrapping => 'กำลังเชื่อมต่อกับ Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'วิธีเปิดที่อยู่นี้';

  @override
  String get dashboard_tor_help_title => 'การเปิดที่อยู่นี้';

  @override
  String get dashboard_tor_help_android =>
      'Android: ติดตั้ง Tor Browser จาก Google Play หรือ F-Droid เปิดแล้ววางที่อยู่';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone และ iPad: ติดตั้ง Onion Browser จาก App Store เปิดแล้ววางที่อยู่ Tor Browser ไม่มีบน iOS';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS และ Linux: ดาวน์โหลด Tor Browser จาก torproject.org เปิดแล้ววางที่อยู่';

  @override
  String get dashboard_tor_help_password_note =>
      'ยังต้องใช้รหัสผ่านหลังจากหน้าเว็บโหลดเสร็จ';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'สแกนเพื่อไปยังหน้าดาวน์โหลด Tor Browser';

  @override
  String get dashboard_tor_help_close => 'เข้าใจแล้ว';

  @override
  String get surveillance_general_battery_warning =>
      'โหมดเซนทรีใช้พลังงานแบตเตอรี่ 12V เพิ่มเติมขณะทำงาน';

  @override
  String get surveillance_general_camera_contention_warning =>
      'แอปอื่นกำลังใช้กล้องอยู่ในขณะนี้';

  @override
  String get pairing_title => 'จับคู่อุปกรณ์';

  @override
  String get pairing_scan_hint =>
      'สแกนด้วยแอป BladeWatch บนโทรศัพท์หรือคอมพิวเตอร์ของคุณ รหัสนี้ใช้ได้ครั้งเดียว';

  @override
  String pairing_expires_in(String time) {
    return 'หมดอายุใน $time';
  }

  @override
  String get pairing_expired => 'รหัสนี้หมดอายุแล้ว';

  @override
  String get pairing_new_code => 'รหัสใหม่';

  @override
  String get pairing_remote_note =>
      'การจับคู่จะเปิดการเข้าถึงระยะไกลสำหรับรถคันนี้';

  @override
  String get pairing_lan_title => 'เชื่อมต่อโดยตรงผ่าน Wi-Fi นี้';

  @override
  String get pairing_lan_body =>
      'อุปกรณ์ที่จับคู่แล้วซึ่งอยู่ใน Wi-Fi เดียวกับรถจะเชื่อมต่อโดยตรงและเข้ารหัส โดยไม่ผ่านอินเทอร์เน็ต ปิดอยู่จนกว่าคุณจะเปิด';

  @override
  String get pairing_devices_title => 'อุปกรณ์ที่จับคู่แล้ว';

  @override
  String get pairing_devices_empty => 'ยังไม่มีอุปกรณ์ที่จับคู่';

  @override
  String get pairing_remove => 'นำออก';

  @override
  String pairing_remove_confirm_title(String name) {
    return 'นำ $name ออกหรือไม่';
  }

  @override
  String get pairing_remove_confirm_body =>
      'อุปกรณ์นี้จะเสียสิทธิ์เข้าถึงทันที อุปกรณ์อื่นของคุณยังใช้งานได้ตามปกติ';

  @override
  String get pairing_error => 'บริการกล้องไม่ตอบสนอง โปรดลองอีกครั้ง';
}
