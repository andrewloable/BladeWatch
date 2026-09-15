// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Giữ BladeWatch giám sát xe hoạt động trong nền. Dịch vụ này không đọc hoặc tương tác với nội dung màn hình.';

  @override
  String get action_cancel => 'Huỷ';

  @override
  String get action_clear_plain => 'Xoá';

  @override
  String get action_select_all => 'Chọn tất cả';

  @override
  String get action_select_all_short => 'Tất cả';

  @override
  String get action_delete => 'Xoá';

  @override
  String get action_done => 'XONG';

  @override
  String get action_remind_me_later => 'NHẮC TÔI SAU';

  @override
  String get action_retry => 'Thử lại';

  @override
  String get action_run => 'Chạy';

  @override
  String get action_clear_output => 'Xóa đầu ra';

  @override
  String get cd_camera => 'Camera';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'Mã QR';

  @override
  String get cd_show_hide_token => 'Hiện/ẩn mã thông báo';

  @override
  String get cd_copy_token => 'Sao chép token';

  @override
  String get cd_copy_url => 'Sao chép URL';

  @override
  String get cd_clear_logs => 'Xóa nhật ký';

  @override
  String get cd_expand_collapse => 'Mở rộng/Thu gọn';

  @override
  String get cd_recording_status => 'Trạng thái ghi hình';

  @override
  String get cd_trip_tracking_status => 'Tình trạng theo dõi chuyến đi';

  @override
  String get cd_video_thumbnail => 'Hình ảnh nhỏ video';

  @override
  String get cd_play => 'Phát';

  @override
  String get cd_back => 'Quay lại';

  @override
  String get cd_play_pause => 'Phát/Tạm dừng';

  @override
  String get cd_player_prev => 'Bản ghi trước đó';

  @override
  String get cd_player_next => 'Bản ghi kế tiếp';

  @override
  String get cd_player_maximize => 'Phóng to trình phát';

  @override
  String get cd_player_minimize => 'Thoát toàn màn hình';

  @override
  String get cd_delete => 'Xoá';

  @override
  String get cd_decrease => 'Giảm';

  @override
  String get cd_increase => 'Tăng';

  @override
  String get cd_expand => 'Mở rộng';

  @override
  String get cd_configure => 'Thiết lập';

  @override
  String get cd_download_log => 'Tải nhật ký';

  @override
  String get cd_reset => 'Đặt lại';

  @override
  String get cd_battery => 'Pin';

  @override
  String get cd_step_completed => 'Bước hoàn thành';

  @override
  String get cd_permission_granted => 'Đã cấp quyền';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'TIẾN TRÌNH';

  @override
  String get logs_panel_title => 'Nhóm gỗ';

  @override
  String get url_connecting => 'Kết nối...';

  @override
  String get camera_selection_title => 'Chọn máy ảnh';

  @override
  String get camera_selection_subtitle => 'Chọn nguồn máy ảnh toàn cảnh';

  @override
  String get camera_current_auto => 'Hiện tại: tự động';

  @override
  String get camera_option_auto => 'Tự động (phát hiện khi khởi động)';

  @override
  String get camera_option_0 => 'Camera 0 — Atto trims';

  @override
  String get camera_option_1 => 'Máy ảnh 1 — Seal (tạm dịch mặc định)';

  @override
  String get camera_option_2 => 'Camera 2';

  @override
  String get camera_option_3 => 'Máy ảnh 3';

  @override
  String get camera_option_4 => 'Camera 4';

  @override
  String get camera_option_5 => 'Camera 5';

  @override
  String get camera_selection_hint =>
      'Tự động chọn camera phù hợp cho phiên bản xe của bạn khi mỗi lần khởi động. Camera 1 = BYD Seal, Camera 0 = các phiên bản Atto. Khởi động lại dịch vụ camera sau khi thay đổi ID camera để cài đặt có hiệu lực.';

  @override
  String get dashboard_scan_to_connect => 'Quét để kết nối';

  @override
  String get dashboard_qr_waiting => 'Chờ đường hầm...';

  @override
  String get dashboard_daemons_running_default => '0/5 đang chạy';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'Mã truy cập';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Tạo lại token';

  @override
  String get dashboard_set_password => 'Đặt mật khẩu';

  @override
  String get cd_set_password => 'Đặt mật khẩu tùy chỉnh';

  @override
  String get dialog_set_password_title => 'Đặt mật khẩu tùy chỉnh';

  @override
  String get dialog_set_password_message =>
      'Nhập mật khẩu truy cập mới. Mật khẩu này thay thế token tự tạo.';

  @override
  String get dialog_set_password_hint => 'Mật khẩu mới (tối thiểu 12 ký tự)';

  @override
  String get toast_password_set => 'Đã cập nhật mật khẩu';

  @override
  String get toast_password_too_short => 'Mật khẩu phải có ít nhất 12 ký tự';

  @override
  String get toast_password_save_failed =>
      'Không lưu được mật khẩu — dịch vụ chưa sẵn sàng';

  @override
  String get setup_guide_title => 'Bắt đầu';

  @override
  String get setup_guide_subtitle =>
      'Ba bước nhanh chóng để có được trải nghiệm tốt nhất:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Chọn ngôn ngữ';

  @override
  String get setup_language_body =>
      'Tiền thoại của đơn vị đầu tiên của bạn mặc định. Nhấn để chọn một ngôn ngữ khác cho ứng dụng BladeWatch và đường hầm web.';

  @override
  String get setup_language_button => 'Chọn ngôn ngữ';

  @override
  String get setup_autostart_title => 'Tắt hạn chế tự khởi động';

  @override
  String get setup_autostart_body =>
      'Nhấn bên dưới để mở BYD Auto-Start, sau đó bỏ chọn CẢ BladeWatch VÀ Dịch vụ BladeWatch. Nếu không, việc ghi hình sẽ không bắt đầu khi bạn khởi động xe — bạn phải mở ứng dụng mỗi lần. BYD xóa cài đặt này sau mỗi lần cài đặt.';

  @override
  String get setup_autostart_button => 'Mở BYD Auto-Start';

  @override
  String get setup_overlay_title => 'Cho phép hiển thị trên các ứng dụng khác';

  @override
  String get setup_overlay_body =>
      'Khả năng điều này để hiển thị một chỉ số trạng thái nổi để ghi lại và theo dõi chuyến đi trên đầu các ứng dụng khác.';

  @override
  String get setup_overlay_button => 'Mở cài đặt lớp phủ';

  @override
  String get cd_close => 'Đóng';

  @override
  String get language_picker_title => 'Ngôn ngữ';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return 'Có sẵn $arg1 ngôn ngữ';
  }

  @override
  String get language_picker_subtitle_pending => 'Chọn ngôn ngữ';

  @override
  String get language_auto_title => 'Tự động';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Theo cài đặt hệ thống · $arg1';
  }

  @override
  String get language_not_saved =>
      'Đã áp dụng ngôn ngữ nhưng không lưu được — sẽ đặt lại khi khởi động lại ứng dụng.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · tự động';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Nhập lệnh...';

  @override
  String get adb_preset_commands_header => 'Các lệnh cài đặt trước';

  @override
  String get adb_output_header => 'Đầu ra';

  @override
  String get adb_output_ready => 'Sẵn sàng cho lệnh...';

  @override
  String get adb_console_hero_title => 'Bảng điều khiển ADB';

  @override
  String get adb_console_hero_subtitle => 'Động hành lệnh shell trên thiết bị';

  @override
  String get adb_console_unavailable_title => 'ADB chưa kết nối';

  @override
  String get adb_console_unavailable_body =>
      'Trên xe này, công tắc “Gỡ lỗi USB” thông thường trong Tùy chọn nhà phát triển thôi chưa đủ — cài đặt ADB không dây (gỡ lỗi mạng) riêng của màn hình trung tâm cũng cần được bật, và bản cập nhật hệ thống có thể đặt lại cài đặt này. Hãy bật lại ADB không dây trên màn hình trung tâm, hoặc kết nối qua USB.';

  @override
  String get adb_console_auth_pending_title => 'Đang chờ phê duyệt';

  @override
  String get adb_console_auth_pending_body =>
      'Kiểm tra màn hình trung tâm để tìm thông báo “Cho phép gỡ lỗi USB?” và chấp nhận, sau đó thử lại.';

  @override
  String get performance_connecting =>
      'Đang kết nối tới trình giám sát hiệu năng…';

  @override
  String get performance_hero_title => 'Hiệu suất hệ thống';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'Mức dùng của hệ thống';

  @override
  String get performance_cpu_app_usage => 'Mức dùng của ứng dụng';

  @override
  String get performance_frequency_label => 'Tần số';

  @override
  String get performance_temperature_label => 'Nhiệt độ';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Bộ nhớ';

  @override
  String get performance_usage_label => 'Mức sử dụng';

  @override
  String get performance_memory_total => 'Tổng';

  @override
  String get performance_memory_used => 'Đã dùng';

  @override
  String get performance_memory_app => 'Ứng dụng';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'Tiến trình ứng dụng';

  @override
  String get performance_threads_label => 'Luồng';

  @override
  String get performance_gc_cycles_label => 'Chu kỳ GC';

  @override
  String get performance_open_fds_label => 'FD đang mở';

  @override
  String get performance_refreshing_footer => 'Làm mới mỗi 3 giây';

  @override
  String get webview_loading => 'Lái...';

  @override
  String get reset_title => 'Đặt lại dữ liệu';

  @override
  String get reset_subtitle => 'Xóa dữ liệu tích lũy theo các loại';

  @override
  String get reset_warning =>
      'Không thể hoàn tác. Các bản ghi, chuyến đi và lịch sử pin sẽ bị xóa vĩnh viễn.';

  @override
  String get reset_cat_trips => 'Chuyến đi';

  @override
  String get reset_cat_trips_desc =>
      'Lịch sử du lịch, tuyến đường, các chuyến đi hàng tuần/tháng';

  @override
  String get reset_cat_soc_history => 'Lịch sử SoC & 12V';

  @override
  String get reset_cat_soc_history_desc =>
      'Các mẫu SoC, các phiên sạc, nhật ký điện áp';

  @override
  String get reset_cat_recordings => 'Các bản ghi âm (video)';

  @override
  String get reset_cat_recordings_desc => 'Tất cả các MP4 trong thư mục ghi âm';

  @override
  String get reset_cat_sentry_events => 'Các sự kiện giám sát';

  @override
  String get reset_cat_sentry_events_desc =>
      'Clip sự kiện giám sát và tệp JSON đi kèm';

  @override
  String get reset_cat_proximity => 'Các bản ghi gần gũi';

  @override
  String get reset_cat_proximity_desc => 'Radar kích hoạt sự kiện MP4';

  @override
  String get reset_cat_trip_files => 'Dữ liệu telemetry chuyến đi';

  @override
  String get reset_cat_trip_files_desc => 'Điện đo trên đĩa JSON mỗi chuyến đi';

  @override
  String get recording_lib_chip_any => 'Bất kỳ';

  @override
  String get recording_lib_chip_person => 'Người';

  @override
  String get recording_lib_chip_vehicle => 'Chiếc xe';

  @override
  String get recording_lib_chip_bike => 'Xe đạp';

  @override
  String get recording_lib_chip_animal => 'Động vật';

  @override
  String get recording_lib_chip_alert => 'Cảnh báo';

  @override
  String get recording_lib_chip_critical => 'Nghiêm trọng';

  @override
  String get recording_lib_selected_count_zero => '0 được chọn';

  @override
  String get recording_lib_no_recordings => 'Không có bản ghi';

  @override
  String get recording_lib_filter_button => 'Bộ lọc';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Bộ lọc · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Lọc bản ghi';

  @override
  String get recording_lib_filter_apply => 'Áp dụng';

  @override
  String get recording_lib_filter_reset => 'Đặt lại';

  @override
  String get recording_lib_filter_section_what => 'Cái gì';

  @override
  String get recording_lib_filter_section_severity => 'Độ nghiêm trọng';

  @override
  String get recording_lib_filter_section_type => 'Loại';

  @override
  String get recording_lib_chip_type_normal => 'Thường';

  @override
  String get recording_lib_chip_type_proximity => 'Cận kề';

  @override
  String get recording_lib_date_today => 'Hôm nay';

  @override
  String get recording_lib_date_yesterday => 'Hôm qua';

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
  String get recording_lib_pick_date => 'Chọn một ngày';

  @override
  String get recording_lib_date_all_days => 'Tất cả các ngày';

  @override
  String get cd_clear_date_filter => 'Hiển thị tất cả các ngày';

  @override
  String get recording_lib_section_morning => 'Sáng';

  @override
  String get recording_lib_section_afternoon => 'Chiều';

  @override
  String get recording_lib_section_evening => 'Tối';

  @override
  String get recording_lib_section_night => 'Đêm';

  @override
  String get cd_previous_day => 'Ngày trước';

  @override
  String get cd_next_day => 'Ngày hôm sau';

  @override
  String get cd_open_filters => 'Mở bộ lọc';

  @override
  String get cd_clear_filter => 'Xóa bộ lọc';

  @override
  String get player_title_recording => 'Bản ghi';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Dịch vụ camera';

  @override
  String get daemon_name_surveillance => 'Dịch vụ giám sát';

  @override
  String get daemon_name_acc => 'Giám sát ACC';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'Dịch vụ nền';

  @override
  String get daemons_count_pending => 'Đang tải dịch vụ…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 của $arg2 chạy';
  }

  @override
  String get battery_health_title => 'Sức khỏe pin';

  @override
  String get battery_health_unavailable => 'Không khả dụng';

  @override
  String get battery_health_unavailable_desc =>
      'Ước tính tình trạng pin không khả dụng.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% trên $arg2';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Các bản ghi $arg1 bị xóa',
      one: 'Đăng ký $arg1 bị xóa',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Xóa bản ghi $arg1',
      one: 'Xóa bản ghi $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Thao tác này sẽ xóa vĩnh viễn $arg1 bản ghi. Không thể hoàn tác.',
      one: 'Thao tác này sẽ xóa vĩnh viễn $arg1 bản ghi. Không thể hoàn tác.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'Ứng dụng được cập nhật (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Giấy phép lưu trữ cần thiết cho các bản ghi';

  @override
  String get toast_url_copied_short => 'URL sao chép!';

  @override
  String get toast_camera_set_to_auto => 'Máy ảnh được thiết lập để tự động';

  @override
  String get toast_failed_to_save_short => 'Không cứu được';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Không thành công: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Đã đặt camera $arg1 — chu kỳ ACC tiếp theo';
  }

  @override
  String get toast_clearing_camera_config => 'Làm sạch cấu hình máy ảnh...';

  @override
  String get toast_restarting_camera_daemon =>
      'Đang khởi động lại dịch vụ camera...';

  @override
  String get toast_camera_daemon_restarting =>
      'Dịch vụ camera đang khởi động lại với thăm dò toàn bộ';

  @override
  String get toast_camera_restart_failed =>
      'Đã xóa cấu hình nhưng khởi động lại dịch vụ thất bại. Vui lòng khởi động lại thủ công.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Không thành công: $arg1';
  }

  @override
  String get toast_select_at_least_one_category => 'Chọn ít nhất một danh mục';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Đặt lại không thành công: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 Monitor giao thông...';
  }

  @override
  String get dialog_close => 'Đóng';

  @override
  String get dialog_reset => 'Đặt lại';

  @override
  String get dialog_delete => 'Xoá';

  @override
  String get dialog_save => 'Lưu';

  @override
  String get dialog_enable => 'Bật';

  @override
  String get dialog_disable => 'Tắt';

  @override
  String get dialog_keep_enabled => 'Giữ bật';

  @override
  String get dialog_keep_disabled => 'Giữ tắt';

  @override
  String get dialog_regenerate => 'Tạo lại';

  @override
  String get dialog_reset_selected => 'Đặt lại mục đã chọn';

  @override
  String get dialog_reset_following_title => 'Đặt lại những mục sau?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Không thể hoàn tác thao tác này.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Đã đặt lại xong';

  @override
  String get dialog_traffic_cannot_check_title =>
      'Không thể kiểm tra tình trạng';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB chưa được kết nối và ứng dụng không thể tự động kết nối lại.\n\nTrên chiếc xe này, công tắc \"Gỡ lỗi USB\" thông thường trong Tùy chọn nhà phát triển thôi là chưa đủ — cài đặt ADB không dây (gỡ lỗi qua mạng) riêng của màn hình trung tâm cũng cần được bật, và một bản cập nhật hệ thống có thể tắt nó đi. Hãy bật lại ADB không dây trên màn hình trung tâm, hoặc kết nối qua USB.\n\nTrạng thái sẽ tự động cập nhật ngay khi kết nối được.';

  @override
  String get dialog_traffic_disable_title => 'Tắt BYD Traffic Monitor?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) là ứng dụng hệ thống tích hợp, liên tục theo dõi tình hình giao thông trong nền.\n\nTại sao nên tắt?\n\n• Tiêu tốn dữ liệu di động (kể cả khi đỗ xe)\n• Dùng CPU và pin trong nền\n• Không cần nếu bạn dùng ứng dụng dẫn đường riêng\n• Có thể cản trở việc dùng mạng của camera hành trình\n\nTắt là an toàn: chỉ ảnh hưởng đến lớp giao thông tích hợp trên bản đồ. Dẫn đường, Bluetooth và mọi chức năng khác của xe vẫn giữ nguyên.\n\nSau khi tắt cần khởi động lại cứng (giữ nút trên bảng điều khiển trung tâm 5 giây).';

  @override
  String get dialog_traffic_enable_title =>
      'Khả năng kiểm tra giao thông BYD lại?';

  @override
  String get dialog_traffic_enable_message =>
      'BYD Traffic Monitor hiện đang vô hiệu hóa.\n\nKhả năng lại sẽ khôi phục lại lớp phủ giao thông tích hợp trên bản đồ điều hướng. Lưu ý rằng nó sẽ chạy trong nền và tiêu thụ dữ liệu di động.\n\nMột khởi động lại cứng là cần thiết sau khi kích hoạt (giữ nút bàn điều khiển trung tâm 5 giây).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Kiểm tra giao thông $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'Thay đổi đã được áp dụng.\n\nHãy khởi động lại cứng ngay bây giờ:\nGiữ nút trên bảng điều khiển trung tâm trong 5 giây.';

  @override
  String get traffic_monitor_loading => 'Kiểm tra giao thông: kiểm tra...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Kiểm tra giao thông (chạm vào để kiểm tra)';

  @override
  String get reset_label_trips => 'Chuyến đi';

  @override
  String get reset_label_soc_history => 'lịch sử SoC + 12V';

  @override
  String get reset_label_recordings => 'Bản ghi';

  @override
  String get reset_label_sentry_events => 'Các sự kiện giám sát';

  @override
  String get reset_label_proximity => 'Các bản ghi gần gũi';

  @override
  String get reset_label_trip_files => 'Dữ liệu telemetry chuyến đi';

  @override
  String get toast_access_code_copied => 'Mã truy cập sao chép';

  @override
  String get dialog_regenerate_token_title => 'Tạo lại token';

  @override
  String get dialog_regenerate_token_message =>
      'Thao tác này sẽ vô hiệu hóa token hiện tại. Tất cả phiên đang hoạt động sẽ bị đăng xuất. Tiếp tục?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Đã tạo token mới. Tất cả phiên đã bị đăng xuất.';

  @override
  String get toast_token_regenerated_restart =>
      'Token đã được tái tạo. Các dịch vụ có thể cần khởi động lại để áp dụng.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token đã được tái tạo. Không thể thông báo cho dịch vụ nền.';

  @override
  String get toast_token_regenerated => 'Tín hiệu được tái tạo';

  @override
  String get dashboard_no_tunnel => 'Không có đường hầm chạy';

  @override
  String get dashboard_starting_tor => 'Đang khởi động đường hầm Tor…';

  @override
  String get dashboard_waiting_url => 'Chờ đường hầm URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 đang chạy';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'Mã truy cập';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'Không cần thiết cấu hình cho $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'Đơn hiệu không thể trống rỗng';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Mang theo nhật ký $arg1...';
  }

  @override
  String get toast_log_empty_or_missing =>
      'Dữ liệu nhật ký trống hoặc không tìm thấy';

  @override
  String get toast_log_empty => 'Dữ liệu nhật ký trống';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Không lưu nhật ký: $arg1';
  }

  @override
  String get toast_log_not_found =>
      'Tệp nhật ký không tìm thấy hoặc không thể đọc được';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return 'Nhật ký $arg1 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Chia sẻ $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== Nhật ký $arg1 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Nguồn: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'Xuất khẩu: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'LƯU Ý: nhật ký đã bị cắt, chỉ còn 10000 dòng cuối (tổng cộng: $arg1 dòng)',
      one:
          'LƯU Ý: nhật ký đã bị cắt, chỉ còn 10000 dòng cuối (tổng cộng: $arg1 dòng)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Không thể phát video: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Xóa bản ghi';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'Xóa $arg1?\nKhông thể hoàn tác.';
  }

  @override
  String get toast_recording_deleted => 'Việc ghi lại bị xóa';

  @override
  String get toast_recording_delete_failed => 'Không thể xóa bản ghi';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 bị xóa, $arg2 thất bại';
  }

  @override
  String get play_with_chooser => 'Chơi với';

  @override
  String setup_version_banner(Object arg1) {
    return 'Cập nhật v$arg1 — xác nhận lại tự động khởi động, BYD xóa nó trên mỗi cài đặt';
  }

  @override
  String get setup_overlay_already_granted => 'Đã được cấp';

  @override
  String camera_current_manual(Object arg1) {
    return 'Hiện tại: Camera $arg1 (Hướng dẫn)';
  }

  @override
  String get camera_current_auto_label => 'Hiện tại: tự động';

  @override
  String get soh_estimation_active => 'Đánh giá hoạt động';

  @override
  String get soh_oem_readout => 'Số liệu SOH của xe — đang chờ ước tính';

  @override
  String get soh_nominal_baseline =>
      'Mốc danh định — đang chờ dữ liệu SOH tin cậy';

  @override
  String get soh_no_estimate_yet => 'Không có ước tính nào — chờ dữ liệu';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 được chọn';
  }

  @override
  String get video_player_playback_error => 'Trận lỗi phát lại';

  @override
  String get video_player_no_events => 'Không có sự kiện';

  @override
  String get daemon_configuration_required => 'Thiết lập cần thiết';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Trình phát video';

  @override
  String get status_overlay_notif_title => 'BladeWatch Tình trạng';

  @override
  String get status_overlay_notif_text => 'Status overlay hoạt động';

  @override
  String get rail_dashboard => 'Bảng điều khiển';

  @override
  String get rail_live => 'Trực tiếp';

  @override
  String get rail_recordings => 'Bản ghi';

  @override
  String get rail_vehicle => 'Xe';

  @override
  String get rail_trips => 'Chuyến đi';

  @override
  String get rail_location => 'Vị trí';

  @override
  String get rail_diagnostics => 'Chẩn đoán';

  @override
  String get rail_settings => 'Cài đặt';

  @override
  String get settings_section_appearance => 'Giao diện';

  @override
  String get settings_section_recording => 'Ghi hình';

  @override
  String get settings_section_surveillance => 'Giám sát';

  @override
  String get settings_section_daemons => 'Dịch Vụ';

  @override
  String get settings_section_privacy => 'Quyền riêng tư & dữ liệu';

  @override
  String get settings_section_overlay => 'Lớp phủ trạng thái';

  @override
  String get settings_overlay_subtitle =>
      'Chọn những phần nào của viên thuốc trạng thái nổi vẫn còn hiển thị.';

  @override
  String get settings_overlay_camera_title => 'Camera chỉ dẫn';

  @override
  String get settings_overlay_camera_subtitle =>
      'Hình bày thẻ REC / PROX trong khi ghi âm đang hoạt động.';

  @override
  String get settings_overlay_trip_title => 'Chỉ thị Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Cho thấy thẻ TRIP khi phát hiện chuyến đi đang chạy.';

  @override
  String get settings_section_about => 'Giới thiệu';

  @override
  String get settings_subrail_overline => 'Định hướng';

  @override
  String get cd_settings_subrail => 'Thanh bên cài đặt';

  @override
  String get settings_privacy_title => 'Bảo mật & dữ liệu';

  @override
  String get settings_privacy_body =>
      'Đặt lại sẽ xóa chỉ mục ghi âm, thông tin xác thực được lưu trong bộ nhớ đệm, trạng thái dịch vụ và tùy chọn trên thiết bị. Hành động này không thể hoàn tác.';

  @override
  String get settings_about_title => 'Về BladeWatch';

  @override
  String get settings_about_version_label => 'Phiên bản';

  @override
  String get settings_about_package_label => 'Xây dựng';

  @override
  String get settings_about_support_section =>
      'Được vận hành bởi những người như anh';

  @override
  String get settings_about_support_share_title => 'Hãy nói với chủ xe khác';

  @override
  String get settings_about_support_share_value =>
      'Mỗi liên kết được chia sẻ giúp một chủ sở hữu BYD khác khám phá BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Kiểm tra BladeWatch — giám sát nguồn mở & dashcam cho BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'Chia sẻ quá mức';

  @override
  String get settings_about_open_link_failed => 'Không thể mở liên kết.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'Không tìm thấy trình duyệt. URL sao chép: $arg1';
  }

  @override
  String get settings_about_support_kofi_title =>
      'Chất nhiên liệu phát hành tiếp theo';

  @override
  String get settings_about_support_kofi_value =>
      'Một tách cà phê trên Ko-fi giữ cho các cam kết đêm đến.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Giấy phép';

  @override
  String get settings_about_license_value =>
      'MIT — mã nguồn mở. Nhấp để xem toàn văn bản.';

  @override
  String get settings_about_source_title => 'Mã nguồn';

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
  String get settings_about_star_title => 'Thả trên GitHub';

  @override
  String get settings_about_star_value =>
      'Chỉ mất một giây thôi, có nghĩa là rất nhiều.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Cảm ơn';

  @override
  String get settings_about_thanks_subtitle =>
      'Được xây dựng với sự giúp đỡ của những người đóng góp và ủng hộ.';

  @override
  String get settings_about_contributors_title => 'Người đóng góp';

  @override
  String get settings_about_supporters_title => 'Người ủng hộ';

  @override
  String get settings_about_thanks_empty =>
      'Danh sách sẽ được điền khi có người tham gia.';

  @override
  String get settings_theme_label => 'Chủ đề';

  @override
  String get settings_theme_auto => 'Tự động (theo hệ thống)';

  @override
  String get settings_theme_light => 'Sáng';

  @override
  String get settings_theme_dark => 'Tối';

  @override
  String get settings_language_label => 'Ngôn ngữ';

  @override
  String get settings_drive_side_label => 'Bên điều hướng';

  @override
  String get settings_drive_side_subtitle =>
      'Chọn bên màn hình hiển thị menu điều hướng.';

  @override
  String get settings_drive_side_left => 'Trái';

  @override
  String get settings_drive_side_left_hint => 'Tay lái trái · mặc định';

  @override
  String get settings_drive_side_right => 'Phải';

  @override
  String get settings_drive_side_right_hint => 'Xe tay lái phải';

  @override
  String get settings_drive_side_auto => 'Tự động';

  @override
  String get settings_drive_side_auto_hint => 'Nhận diện từ xe';

  @override
  String get settings_drive_side_caption_left => 'Điều hướng bên trái';

  @override
  String get settings_drive_side_caption_right => 'Điều hướng bên phải';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Tự động — xe báo tay lái trái';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Tự động — xe báo tay lái phải';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Tự động — không có dữ liệu xe, dùng bên trái';

  @override
  String get recordings_title => 'Bản ghi';

  @override
  String get recordings_segment_dashcam => 'Camera hành trình';

  @override
  String get recordings_segment_surveillance => 'Giám sát';

  @override
  String get recordings_action_settings => 'Cài đặt';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 ngày hôm nay · $arg2 tổng số · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Camera hành trình · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Giám sát · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Chọn một bản ghi';

  @override
  String get recordings_preview_placeholder_body =>
      'Nhấn bất kỳ mục nào ở bên trái để chơi nó.';

  @override
  String get diagnostics_section_adb_console => 'Bảng điều khiển ADB';

  @override
  String get diagnostics_section_traffic => 'Kiểm tra giao thông';

  @override
  String get diagnostics_section_camera_probe => 'Dò tìm camera';

  @override
  String get diagnostics_section_battery => 'Sức khỏe pin';

  @override
  String get diagnostics_section_performance => 'Hiệu năng';

  @override
  String get diagnostics_hero_title => 'Chẩn đoán hệ thống';

  @override
  String get diagnostics_hero_subtitle =>
      'Sức khỏe trực tiếp, nhật ký và thăm dò cho thiết bị.';

  @override
  String get diagnostics_health_clear => 'Không có vấn đề';

  @override
  String get diagnostics_health_section => 'Sức khỏe';

  @override
  String get diagnostics_health_network => 'Mạng';

  @override
  String get diagnostics_health_storage => 'Bộ nhớ';

  @override
  String get diagnostics_health_camera => 'Máy ảnh';

  @override
  String get diagnostics_health_battery => 'Pin';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Trực tuyến';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Đường hầm · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Trực tuyến';

  @override
  String get diagnostics_tunnel_state_offline => 'Ngoại tuyến';

  @override
  String get diagnostics_tunnel_state_connecting => 'Kết nối';

  @override
  String get diagnostics_network_mobile => 'Điện thoại di động';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Ngoại tuyến';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clip · $arg2 đã dùng',
      one: '$arg1 clip · $arg2 đã dùng',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 miễn phí';
  }

  @override
  String get diagnostics_logs_card_title => 'Đăng ký sự kiện trực tiếp';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Tiếp tục phát ra từ các dịch vụ đang chạy.';

  @override
  String get diagnostics_tools_section => 'Công cụ';

  @override
  String get diagnostics_traffic_subtitle => 'Nhìn thông qua mạng trực tiếp.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Kiểm tra các dòng máy ảnh kết nối.';

  @override
  String get diagnostics_adb_subtitle => 'Mở đầu cuối trên thiết bị.';

  @override
  String get diagnostics_battery_subtitle =>
      'Kiểm tra tế bào SOH và đóng gói số liệu thống kê.';

  @override
  String get diagnostics_settings_subtitle =>
      'Ưu tiên ứng dụng, chủ đề và ngôn ngữ.';

  @override
  String get settings_action_reset_data => 'Đặt lại dữ liệu…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'Đang canh chừng';

  @override
  String get dashboard_subtitle_all_systems => 'Tất cả hệ thống trực tuyến';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 của các dịch vụ $arg2 trực tuyến';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Truy cập từ xa offline';

  @override
  String get dashboard_metric_recordings => 'Các bản ghi âm ngày hôm nay';

  @override
  String get dashboard_metric_storage => 'Dung lượng đã dùng';

  @override
  String get dashboard_metric_tunnel => 'Truy cập từ xa';

  @override
  String get dashboard_metric_services => 'Dịch vụ nền';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Xe';

  @override
  String get dashboard_chip_recording_active => 'Đang ghi hình';

  @override
  String get dashboard_chip_recording_idle => 'Rảnh';

  @override
  String get dashboard_vehicle_tap_to_set => 'Nhấn để thiết lập';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Đặt dung lượng pin';

  @override
  String get vehicle_dialog_model_label => 'Mẫu xe';

  @override
  String get vehicle_dialog_save => 'Lưu';

  @override
  String get settings_recording_tab_status => 'Trạng thái';

  @override
  String get settings_recording_tab_capture => 'Thu hình';

  @override
  String get settings_recording_tab_quality => 'Chất lượng';

  @override
  String get settings_recording_tab_storage => 'Lưu trữ';

  @override
  String get settings_recording_status_title => 'Trạng thái ghi';

  @override
  String get settings_recording_status_current_state => 'Trạng thái hiện tại';

  @override
  String get settings_recording_status_today_count => 'Bản ghi hôm nay';

  @override
  String get settings_recording_mode_title => 'Chế độ ghi (ACC BẬT)';

  @override
  String get settings_recording_mode_description =>
      'Chọn thời điểm camera hành trình ghi hình khi lái xe.';

  @override
  String get settings_recording_mode_none_label => 'Không (mặc định)';

  @override
  String get settings_recording_mode_none_desc =>
      'Không ghi — giám sát vẫn hoạt động';

  @override
  String get settings_recording_mode_continuous_label => 'Liên tục';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Ghi liên tục khi đang lái';

  @override
  String get settings_recording_mode_drive_label => 'Chế độ lái';

  @override
  String get settings_recording_mode_drive_desc =>
      'Chỉ ghi khi xe đang di chuyển';

  @override
  String get settings_recording_mode_proximity_label => 'Bảo vệ tiệm cận';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Ghi khi phát hiện chuyển động';

  @override
  String get settings_recording_limit_title => 'Giới hạn bản ghi';

  @override
  String get settings_recording_limit_description =>
      'Độ dài tối đa mỗi tệp. Bản ghi sẽ tách thành tệp mới theo khoảng này.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => 'Chất lượng ghi';

  @override
  String get settings_recording_storage_title => 'Lưu trữ bản ghi';

  @override
  String get settings_recording_storage_location_label => 'Vị trí lưu trữ';

  @override
  String get settings_recording_storage_internal => 'Bộ nhớ trong';

  @override
  String get settings_recording_storage_sd_card => 'Thẻ SD';

  @override
  String get settings_recording_storage_sd_card_na => 'Thẻ SD (không có)';

  @override
  String get settings_recording_storage_limit_label =>
      'Giới hạn lưu trữ — tự động xóa bản cũ nhất khi đạt giới hạn';

  @override
  String get settings_recording_storage_usage_label => 'Dung lượng đã dùng';

  @override
  String get settings_recording_storage_files_label => 'Tệp';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return 'Đã dùng $arg1 / giới hạn $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 bản ghi',
      one: '$arg1 bản ghi',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Đường dẫn';

  @override
  String get settings_recording_storage_sd_free_label =>
      'Dung lượng trống thẻ SD';

  @override
  String get settings_recording_storage_internal_free_label =>
      'Dung lượng trống bộ nhớ trong';

  @override
  String get settings_recording_format_title => 'Định dạng ổ ngoài';

  @override
  String get settings_recording_format_warning =>
      'Xóa vĩnh viễn TẤT CẢ dữ liệu trên thẻ SD hoặc ổ USB.';

  @override
  String get settings_recording_format_confirm =>
      'Chạm lần nữa — TẤT CẢ dữ liệu sẽ bị XÓA';

  @override
  String get settings_recording_format_running =>
      'Đang định dạng… vui lòng đợi';

  @override
  String get settings_recording_format_button => 'Định dạng thẻ SD / USB';

  @override
  String get settings_recording_format_no_drive => 'Không tìm thấy ổ đĩa rời';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Định dạng thành công. Đường dẫn mới: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Danh mục cơ sở dữ liệu';

  @override
  String get settings_recording_sync_description =>
      'Đối chiếu chỉ mục bản ghi với tệp trên đĩa.';

  @override
  String get settings_recording_sync_running => 'Đang đồng bộ…';

  @override
  String get settings_recording_sync_button => 'Đồng bộ cơ sở dữ liệu';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Đã đồng bộ: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => 'Đang đồng bộ rồi';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Đồng bộ thất bại: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Áp dụng thay đổi';

  @override
  String get settings_recording_dismiss => 'Bỏ qua';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Chưa hỗ trợ bật/tắt $arg1';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 được sử dụng · $arg2 miễn phí';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Bộ nhớ —';

  @override
  String get dashboard_tunnel_offline => 'Ngoại tuyến';

  @override
  String get dashboard_tunnel_online => 'Trực tuyến';

  @override
  String get dashboard_tunnel_connecting => 'Đang kết nối…';

  @override
  String get dashboard_trips_this_week => 'Tuần này';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 chuyến',
      one: '$arg1 chuyến',
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
  String get dashboard_trips_label_trips => 'Chuyến đi';

  @override
  String get dashboard_trips_label_distance => 'Quãng đường';

  @override
  String get dashboard_trips_label_time => 'Thời gian lái';

  @override
  String get dashboard_trips_no_data => 'Không có chuyến đi nào tuần này';

  @override
  String get dashboard_trips_unavailable => 'Bắt đầu lái để xem thống kê';

  @override
  String get dashboard_trips_loading => 'Đang tải…';

  @override
  String get dashboard_trips_view_all => 'Xem tất cả chuyến đi';

  @override
  String get dashboard_action_live => 'Hình ảnh trực tiếp';

  @override
  String get dashboard_action_live_subtitle => 'Mở chế độ xem camera';

  @override
  String get dashboard_action_recordings => 'Bản ghi';

  @override
  String get dashboard_action_settings => 'Cài đặt';

  @override
  String get dashboard_action_settings_subtitle => 'Ưu tiên và về';

  @override
  String get settings_hero_title => 'Cài đặt';

  @override
  String get settings_hero_overline => 'TÔNG CÁN';

  @override
  String get settings_hero_subtitle =>
      'Định hướng ngoại hình, ghi lại, giám sát và dữ liệu trên thiết bị.';

  @override
  String get settings_overline_preferences => 'TƯU ĐC';

  @override
  String get settings_overline_about_data => 'Về & DATA';

  @override
  String get settings_quick_theme_label => 'Chủ đề';

  @override
  String get settings_quick_language_label => 'Ngôn ngữ';

  @override
  String get settings_section_recording_subtitle =>
      'Bộ đệm trước/sau, codec, giới hạn lưu trữ.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Lịch trình, độ nhạy chuyển động, phát hiện đối tượng.';

  @override
  String get settings_section_daemons_subtitle =>
      'Đường hầm Tor và dịch vụ nền.';

  @override
  String get settings_about_row_title => 'Về BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Phiên bản, giấy phép, hỗ trợ phát triển.';

  @override
  String get settings_reset_row_subtitle =>
      'Chọn âm thanh, sự kiện, hoặc tất cả các kho lưu trữ.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Chủ đề, ngôn ngữ và sở thích hình ảnh.';

  @override
  String get settings_theme_active_auto_caption =>
      'Tự động theo giao diện hệ thống.';

  @override
  String get settings_theme_active_light_caption =>
      'Giao diện sáng luôn được bật.';

  @override
  String get settings_theme_active_dark_caption =>
      'Giao diện tối luôn được bật.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 trong $arg2 ngôn ngữ khả dụng';
  }

  @override
  String get settings_language_card_title => 'Ngôn ngữ hiển thị';

  @override
  String get settings_privacy_stance_title => 'Trên thiết bị theo mặc định';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch chạy hoàn toàn trên màn hình trung tâm. Không có dữ liệu telemetry nào rời khỏi xe, ngoại trừ qua các đường hầm và tích hợp mà bạn thiết lập rõ ràng.';

  @override
  String get settings_privacy_overline_storage => 'Lưu trữ tại địa phương';

  @override
  String get settings_privacy_overline_reset => 'DATA Reset';

  @override
  String get settings_privacy_storage_clips_label => 'Các clip trên đĩa';

  @override
  String get settings_privacy_storage_size_label => 'Tổng kích thước';

  @override
  String get settings_privacy_storage_unavailable => 'Không có sẵn';

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
      'Chọn danh mục: ghi âm, sự kiện, cấu hình dịch vụ, dữ liệu đo từ xa trong bộ nhớ đệm...';

  @override
  String get settings_developer_overline => 'NHÀ PHÁT TRIỂN';

  @override
  String get settings_developer_timing_logs_title =>
      'Nhật ký thời gian dịch vụ';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Ghi các mốc thời gian trong quá trình khởi động dịch vụ. Tắt khi dùng bình thường để giữ logcat gọn gàng.';

  @override
  String get settings_developer_debug_logs_title => 'Nhật ký gỡ lỗi';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Ghi toàn bộ sự kiện vòng đời Activity và Fragment cùng các bước khởi động vào /storage/emulated/0/BladeWatch/data/debug_app.log. Sự cố luôn được ghi lại. Mặc định tắt.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Máy ảnh $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Máy ảnh $arg1 (là tay)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Đang dò…';

  @override
  String get diagnostics_camera_value_offline => 'Ngoại tuyến';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Đang chờ dữ liệu';

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
      other: '$arg1 clip · đã ghi $arg2',
      one: '$arg1 clip · đã ghi $arg2',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Cốp xe';

  @override
  String get vehicle_tab_climate => 'Điều hòa';

  @override
  String get vehicle_tab_seats => 'Ghế';

  @override
  String get vehicle_tab_windows => 'Cửa kính';

  @override
  String get vehicle_tab_lights => 'Đèn';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Sạc';

  @override
  String get vehicle_locked => 'Đã khóa';

  @override
  String get vehicle_unlocked => 'Đã mở khóa';

  @override
  String get vehicle_range_label => 'Quãng đường';

  @override
  String get vehicle_data_unavailable => 'Không có dữ liệu xe.';

  @override
  String get vehicle_action_failed =>
      'Thao tác thất bại. Kiểm tra kết nối với xe.';

  @override
  String get vehicle_open_trunk => 'Mở cốp';

  @override
  String get vehicle_close_trunk => 'Đóng cốp';

  @override
  String get vehicle_trunk_info_open => 'Mở cốp sẽ mở khóa xe trước.';

  @override
  String get vehicle_ac_on => 'AC bật';

  @override
  String get vehicle_ac_off => 'AC tắt';

  @override
  String get vehicle_max_cooling_on => 'Làm mát tối đa: BẬT';

  @override
  String get vehicle_max_cooling_off => 'Làm mát tối đa: TẮT';

  @override
  String get vehicle_temp_label => 'Nhiệt độ';

  @override
  String get vehicle_fan_speed_label => 'Tốc độ quạt';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Mức $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return 'Trong xe: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => 'Người lái';

  @override
  String get vehicle_seat_passenger => 'Hành khách';

  @override
  String get vehicle_seat_no_controls => 'Xe này không có điều khiển ghế.';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return 'Sưởi $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return 'Mát $arg1';
  }

  @override
  String get vehicle_heat_off => '(Tắt)';

  @override
  String get vehicle_heat_low => '(Thấp)';

  @override
  String get vehicle_heat_high => '(Cao)';

  @override
  String get vehicle_seat_pos_1 => 'Vị trí 1';

  @override
  String get vehicle_seat_pos_2 => 'Vị trí 2';

  @override
  String get vehicle_all_windows => 'Tất cả cửa kính';

  @override
  String get vehicle_window_awake_note => 'Chỉ hoạt động khi xe đang thức.';

  @override
  String get vehicle_window_front_left => 'Trước trái';

  @override
  String get vehicle_window_front_right => 'Trước phải';

  @override
  String get vehicle_window_rear_left => 'Sau trái';

  @override
  String get vehicle_window_rear_right => 'Sau phải';

  @override
  String get vehicle_window_close => 'Đóng';

  @override
  String get vehicle_window_close_vent => 'Đóng khe thông gió';

  @override
  String get vehicle_window_vent_12 => 'Thông gió 12%';

  @override
  String get vehicle_window_open_all => 'Mở tất cả';

  @override
  String get vehicle_sunroof => 'Cửa sổ trời';

  @override
  String get vehicle_sunshade => 'Rèm che nắng';

  @override
  String get vehicle_btn_drl_title => 'Đèn chạy ban ngày';

  @override
  String get vehicle_btn_slw_title => 'Lời cảnh báo giới hạn tốc độ';

  @override
  String get vehicle_control_section_charge_cap => 'Giới hạn sạc';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Xe này không hỗ trợ giới hạn sạc.';

  @override
  String get vehicle_charge_limit_label => 'Giới hạn sạc';

  @override
  String get vehicle_enable_charge_limit => 'Bật giới hạn sạc';

  @override
  String get vehicle_charge_limit_range => 'Tối thiểu 50%, tối đa 100%';

  @override
  String get vehicle_tyre_no_signal => 'KHÔNG CÓ TÍN HIỆU';

  @override
  String get vehicle_tyre_slow_leak => 'RÒ RỈ CHẬM';

  @override
  String get vehicle_tyre_fast_leak => 'RÒ RỈ NHANH';

  @override
  String get vehicle_tyre_low => 'THẤP';

  @override
  String get vehicle_tyre_high => 'CAO';

  @override
  String get vehicle_tyre_ok => 'Bình thường';

  @override
  String get vehicle_tyre_check_pressure => 'Kiểm tra áp suất';

  @override
  String get vehicle_toggle_on => 'BẬT';

  @override
  String get vehicle_toggle_off => 'TẮT';

  @override
  String get vehicle_err_climate_control => 'Điều khiển điều hòa thất bại.';

  @override
  String get vehicle_err_max_cooling => 'Làm mát tối đa thất bại.';

  @override
  String get vehicle_err_drl_control => 'Điều khiển đèn ban ngày thất bại.';

  @override
  String get vehicle_err_slw_control => 'Điều khiển ADAS thất bại.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Bật/tắt giới hạn sạc thất bại.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Giảm $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Tăng $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Đang kết nối…';

  @override
  String get vehicle_appearance_model_title => 'Chọn mẫu xe';

  @override
  String get vehicle_appearance_custom_color => 'Màu tùy chỉnh';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Sạc: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Quãng đường: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Sạc: —';

  @override
  String get vehicle_status_range_unknown => 'Quãng đường: —';

  @override
  String get startup_subtitle => 'Đang chuẩn bị dashcam của bạn';

  @override
  String get startup_header_preparing => 'Đang chuẩn bị…';

  @override
  String get startup_header_starting => 'Đang khởi động…';

  @override
  String get startup_header_verifying => 'Sắp sẵn sàng…';

  @override
  String get startup_header_ready => 'Mọi thứ đã sẵn sàng';

  @override
  String get startup_daemon_camera => 'Camera';

  @override
  String get startup_daemon_camera_desc => 'Xem trực tiếp & ghi hình';

  @override
  String get startup_daemon_sentry => 'Chế độ giám sát';

  @override
  String get startup_daemon_sentry_desc => 'Phát hiện chuyển động & cảnh báo';

  @override
  String get startup_daemon_parking => 'Bảo vệ khi đỗ';

  @override
  String get startup_daemon_parking_desc => 'Canh giữ khi xe đang đỗ';

  @override
  String get startup_status_waiting => 'Đang chờ';

  @override
  String get startup_status_starting => 'Đang khởi động';

  @override
  String get startup_status_ready => 'Sẵn sàng';

  @override
  String get startup_status_failed => 'Thất bại';

  @override
  String get startup_continue_anyway => 'Vẫn tiếp tục';

  @override
  String get startup_continue => 'Tiếp tục →';

  @override
  String get live_retry => 'Thử lại';

  @override
  String get live_connecting => 'Đang kết nối với camera…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Lỗi: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Camera không khả dụng\n$arg1';
  }

  @override
  String get live_direction_all => 'Tất cả';

  @override
  String get live_direction_front => 'Trước';

  @override
  String get live_direction_right => 'Phải';

  @override
  String get live_direction_rear => 'Sau';

  @override
  String get live_direction_left => 'Trái';

  @override
  String get trip_no_route_data =>
      'Không có dữ liệu lộ trình cho chuyến đi này';

  @override
  String get trips_tab_trips => 'Chuyến đi';

  @override
  String get trips_tab_stats => 'Thống kê';

  @override
  String get trips_tab_storage => 'Bộ nhớ';

  @override
  String get trips_filter_7_days => '7 ngày';

  @override
  String get trips_filter_14_days => '14 ngày';

  @override
  String get trips_filter_30_days => '30 ngày';

  @override
  String trips_load_error(Object message) {
    return 'Lỗi: $message';
  }

  @override
  String get trips_empty_state => 'Chưa có chuyến đi nào được ghi lại';

  @override
  String get trips_period_summary_title => 'Tóm tắt kỳ';

  @override
  String get trips_stat_trips => 'Chuyến đi';

  @override
  String get trips_stat_hours => 'Giờ';

  @override
  String get trips_stat_efficiency => 'Hiệu suất';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Điểm: $score';
  }

  @override
  String get trips_driver_score_title => 'Điểm số tài xế';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Tổng: $score / 100';
  }

  @override
  String get trips_range_title => 'Quãng đường cá nhân hóa';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'Ước tính BYD: $km';
  }

  @override
  String get trips_range_no_data => 'Chưa đủ dữ liệu';

  @override
  String get trips_dna_title => 'DNA lái xe';

  @override
  String get trips_dna_anticipation => 'Dự đoán';

  @override
  String get trips_dna_smoothness => 'Độ mượt';

  @override
  String get trips_dna_speed_discipline => 'Kỷ luật tốc độ';

  @override
  String get trips_dna_efficiency => 'Hiệu suất';

  @override
  String get trips_dna_consistency => 'Tính nhất quán';

  @override
  String get trips_storage_title => 'Bộ nhớ chuyến đi';

  @override
  String get trips_storage_analytics_label => 'Phân tích chuyến đi';

  @override
  String get trips_storage_rate_label => 'Giá điện';

  @override
  String get trips_storage_distance_unit_label => 'Đơn vị khoảng cách';

  @override
  String get trips_storage_location_label => 'Vị trí lưu trữ';

  @override
  String get trips_storage_internal => 'Bộ nhớ trong';

  @override
  String get trips_storage_sd_card => 'Thẻ SD';

  @override
  String get trips_storage_sd_card_unavailable => 'Thẻ SD (không có)';

  @override
  String get trips_storage_apply => 'Áp dụng thay đổi';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return 'Đã dùng $used $unit / giới hạn $limit MB · $count chuyến';
  }

  @override
  String get trips_sync_title => 'Danh mục cơ sở dữ liệu';

  @override
  String get trips_sync_description =>
      'Đối chiếu chỉ mục chuyến đi với tệp telemetry trên đĩa.';

  @override
  String get trips_sync_button => 'Đồng bộ cơ sở dữ liệu';

  @override
  String get trips_sync_running => 'Đang đồng bộ…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Đồng bộ thành công: +$added -$removed (tổng $total)';
  }

  @override
  String get trips_sync_failed_generic => 'Đồng bộ thất bại';

  @override
  String get trips_detail_summary_title => 'Tóm tắt chuyến đi';

  @override
  String get trips_detail_distance => 'Quãng đường';

  @override
  String get trips_detail_duration => 'Thời lượng';

  @override
  String get trips_detail_energy => 'Năng lượng';

  @override
  String get trips_detail_avg_speed => 'Tốc độ TB';

  @override
  String get trips_detail_max_speed => 'Tốc độ tối đa';

  @override
  String get trips_detail_soc => 'Mức pin';

  @override
  String get trips_detail_cost => 'Chi phí';

  @override
  String get trips_detail_ext_temp => 'Nhiệt độ ngoài';

  @override
  String get trips_detail_elev_gain => 'Độ cao tăng';

  @override
  String get trips_detail_scores_title => 'Điểm số lái xe';

  @override
  String get trips_detail_unavailable => 'Không có chi tiết chuyến đi';

  @override
  String get trips_detail_loading => 'Đang tải chuyến đi…';

  @override
  String trips_detail_route_points(Object count) {
    return 'Đã ghi $count điểm GPS';
  }

  @override
  String get rec_severity_critical => 'NGHIÊM TRỌNG';

  @override
  String get rec_severity_alert => 'CẢNH BÁO';

  @override
  String get location_loading_title => 'Đang tải bản đồ';

  @override
  String get location_permission_missing_title => 'Cần quyền truy cập vị trí';

  @override
  String get location_permission_denied_title => 'Quyền bị từ chối';

  @override
  String get location_provider_disabled_title => 'GPS đã tắt';

  @override
  String get location_waiting_for_fix_title => 'Đang chờ tín hiệu GPS';

  @override
  String get location_car_location_title => 'Vị trí xe';

  @override
  String get location_stale_title => 'Vị trí đã cũ';

  @override
  String get location_tile_failure_title => 'Không có bản đồ';

  @override
  String get location_tile_failure_subtitle => 'Không có mạng';

  @override
  String get location_error_title => 'Lỗi vị trí';

  @override
  String get location_action_grant => 'Cho phép';

  @override
  String get location_action_retry => 'Thử lại';

  @override
  String get location_mode_auto => 'Tự động';

  @override
  String get location_mode_light => 'Sáng';

  @override
  String get location_mode_dark => 'Tối';

  @override
  String get cd_recenter_on_car => 'Căn giữa vào xe';

  @override
  String get recording_lib_no_recordings_normal =>
      'Không có bản ghi thông thường';

  @override
  String get recording_lib_no_recordings_sentry => 'Không có sự kiện giám sát';

  @override
  String get recording_lib_no_recordings_proximity => 'Không có sự kiện gần';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'người';

  @override
  String get video_player_legend_car => 'ô tô';

  @override
  String get video_player_legend_bike => 'xe đạp';

  @override
  String get video_player_legend_motion => 'chuyển động';

  @override
  String get recording_lib_proximity_very_close => 'rất gần';

  @override
  String get recording_lib_proximity_close => 'gần';

  @override
  String get recording_lib_proximity_mid => 'trung bình';

  @override
  String get recording_lib_proximity_far => 'xa';

  @override
  String get surveillance_tab_general => 'Chung';

  @override
  String get surveillance_tab_detection => 'Phát hiện';

  @override
  String get surveillance_tab_recording => 'Ghi hình';

  @override
  String get surveillance_tab_storage => 'Bộ nhớ';

  @override
  String get surveillance_tab_advanced => 'Nâng cao';

  @override
  String get surveillance_general_title => 'Chế độ giám sát';

  @override
  String get surveillance_general_enable => 'Bật giám sát';

  @override
  String get surveillance_general_status => 'Trạng thái';

  @override
  String get surveillance_general_status_running => 'Đang chạy';

  @override
  String get surveillance_general_status_idle => 'Rảnh';

  @override
  String get surveillance_general_events_today => 'Sự kiện hôm nay';

  @override
  String get surveillance_safe_locations_title => 'Vị trí an toàn';

  @override
  String get surveillance_safe_locations_subtitle =>
      'Camera sẽ không khởi động khi đỗ ở đây';

  @override
  String get surveillance_safe_locations_enable => 'Tắt tại vị trí an toàn';

  @override
  String get surveillance_safe_locations_empty =>
      'Chưa có vị trí an toàn nào được thêm';

  @override
  String get surveillance_safe_locations_add_current =>
      'Thêm vị trí hiện tại làm vùng an toàn';

  @override
  String get surveillance_safe_locations_no_gps => 'Không có vị trí GPS';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Cài đặt phát hiện';

  @override
  String get surveillance_detection_preset_label => 'Cấu hình môi trường';

  @override
  String get surveillance_preset_outdoor => 'Ngoài trời';

  @override
  String get surveillance_preset_garage => 'Nhà để xe';

  @override
  String get surveillance_preset_street => 'Đường phố';

  @override
  String get surveillance_preset_custom => 'Tuỳ chỉnh';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Độ nhạy (1=nghiêm ngặt, 5=nhạy): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Phát hiện đối tượng';

  @override
  String get surveillance_detection_object_person => 'người';

  @override
  String get surveillance_detection_object_car => 'ô tô';

  @override
  String get surveillance_detection_object_bike => 'xe đạp';

  @override
  String get surveillance_recording_title => 'Ghi sự kiện';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Ghi trước (giây trước sự kiện): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Ghi sau (giây sau sự kiện): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Bộ nhớ giám sát';

  @override
  String get surveillance_storage_location_label => 'Vị trí lưu trữ';

  @override
  String get surveillance_storage_internal => 'Nội bộ';

  @override
  String get surveillance_storage_sd_card => 'Thẻ SD';

  @override
  String get surveillance_storage_sd_card_na => 'Thẻ SD (không khả dụng)';

  @override
  String get surveillance_storage_limit_label =>
      'Giới hạn lưu trữ — tự động xoá tệp cũ nhất khi đầy';

  @override
  String get surveillance_storage_usage_label => 'Dung lượng đã dùng';

  @override
  String get surveillance_storage_files_label => 'Tệp';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return 'Đã dùng $arg1 / giới hạn $arg2';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 sự kiện',
      one: '$arg1 sự kiện',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'Đường dẫn';

  @override
  String get surveillance_format_title => 'Định dạng ổ đĩa ngoài';

  @override
  String get surveillance_format_warning =>
      'Xoá vĩnh viễn TẤT CẢ dữ liệu trên thẻ SD hoặc ổ USB.';

  @override
  String get surveillance_format_button => 'Định dạng thẻ SD/USB';

  @override
  String get surveillance_format_confirm =>
      'Nhấn lại — TẤT CẢ dữ liệu sẽ bị XOÁ';

  @override
  String get surveillance_format_running => 'Đang định dạng… vui lòng đợi';

  @override
  String get surveillance_dismiss => 'Đóng';

  @override
  String get surveillance_sync_title => 'Danh mục cơ sở dữ liệu';

  @override
  String get surveillance_sync_description =>
      'Đối chiếu chỉ mục giám sát với các tệp trên đĩa.';

  @override
  String get surveillance_sync_button => 'Đồng bộ cơ sở dữ liệu';

  @override
  String get surveillance_sync_running => 'Đang đồng bộ…';

  @override
  String get surveillance_advanced_camera_title => 'Chọn camera';

  @override
  String get surveillance_advanced_camera_front => 'Trước';

  @override
  String get surveillance_advanced_camera_right => 'Phải';

  @override
  String get surveillance_advanced_camera_rear => 'Sau';

  @override
  String get surveillance_advanced_camera_left => 'Trái';

  @override
  String get surveillance_advanced_ai_title => 'AI và răn đe';

  @override
  String get surveillance_advanced_ai_detection => 'Phát hiện bằng AI';

  @override
  String get surveillance_advanced_night_mode => 'Chế độ ban đêm';

  @override
  String get surveillance_advanced_deterrent_label => 'Hành động răn đe';

  @override
  String get surveillance_deterrent_silent => 'Im lặng';

  @override
  String get surveillance_deterrent_horn => 'Còi';

  @override
  String get surveillance_deterrent_flash => 'Đèn flash';

  @override
  String get surveillance_apply_button => 'Áp dụng thay đổi';

  @override
  String get surveillance_apply_failed => 'Lưu không thành công';

  @override
  String get dashboard_tor_bootstrapping => 'Đang kết nối tới Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'Cách mở địa chỉ này';

  @override
  String get dashboard_tor_help_title => 'Mở địa chỉ này';

  @override
  String get dashboard_tor_help_android =>
      'Android: cài Tor Browser từ Google Play hoặc F-Droid, mở ứng dụng và dán địa chỉ.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone và iPad: cài Onion Browser từ App Store, mở ứng dụng và dán địa chỉ. Tor Browser không có trên iOS.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS và Linux: tải Tor Browser tại torproject.org, mở lên và dán địa chỉ.';

  @override
  String get dashboard_tor_help_password_note =>
      'Bạn vẫn cần mật khẩu sau khi trang tải xong.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'Quét để mở trang tải Tor Browser';

  @override
  String get dashboard_tor_help_close => 'Đã hiểu';
}
