// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'BladeWatch 차량 모니터링을 백그라운드에서 계속 실행합니다. 이 서비스는 화면 내용을 읽거나 상호작용하지 않습니다.';

  @override
  String get action_cancel => '취소';

  @override
  String get action_clear_plain => '지우기';

  @override
  String get action_select_all => '모든 것을 선택';

  @override
  String get action_select_all_short => '모두';

  @override
  String get action_delete => '삭제';

  @override
  String get action_done => '완료';

  @override
  String get action_remind_me_later => '나중에 알림';

  @override
  String get action_retry => '다시 시도';

  @override
  String get action_run => '실행';

  @override
  String get action_clear_output => '출력 지우기';

  @override
  String get cd_camera => '카메라';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR 코드';

  @override
  String get cd_show_hide_token => '표시/숨기 표기';

  @override
  String get cd_copy_token => '토큰 복사';

  @override
  String get cd_copy_url => 'URL 복사';

  @override
  String get cd_clear_logs => '로그 지우기';

  @override
  String get cd_expand_collapse => '펼치기/접기';

  @override
  String get cd_recording_status => '기록 상태';

  @override
  String get cd_trip_tracking_status => '여행 추적 상태';

  @override
  String get cd_video_thumbnail => '비디오 줄여서';

  @override
  String get cd_play => '재생';

  @override
  String get cd_back => '뒤로';

  @override
  String get cd_play_pause => '재생/일시정지';

  @override
  String get cd_player_prev => '이전 녹화본';

  @override
  String get cd_player_next => '다음 녹화';

  @override
  String get cd_player_maximize => '플레이어 최대화';

  @override
  String get cd_player_minimize => '전체화면 종료';

  @override
  String get cd_delete => '삭제';

  @override
  String get cd_decrease => '낮추기';

  @override
  String get cd_increase => '높이기';

  @override
  String get cd_expand => '확장';

  @override
  String get cd_configure => '구성';

  @override
  String get cd_download_log => '로그 다운로드';

  @override
  String get cd_reset => '재설정';

  @override
  String get cd_battery => '배터리';

  @override
  String get cd_step_completed => '단계 완료';

  @override
  String get cd_permission_granted => '허가';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => '트립';

  @override
  String get daemon_card_subprocesses => '프로세스';

  @override
  String get logs_panel_title => '로그';

  @override
  String get url_connecting => '연결...';

  @override
  String get camera_selection_title => '카메라 선택';

  @override
  String get camera_selection_subtitle => '파노라마 카메라 소스를 선택';

  @override
  String get camera_current_auto => '현재: 자동';

  @override
  String get camera_option_auto => '자동 (실동 시 감지)';

  @override
  String get camera_option_0 => '카메라 0 — Atto 트림';

  @override
  String get camera_option_1 => '카메라 1 — Seal (전설)';

  @override
  String get camera_option_2 => '카메라 2';

  @override
  String get camera_option_3 => '카메라 3';

  @override
  String get camera_option_4 => '카메라 4';

  @override
  String get camera_option_5 => '카메라 5';

  @override
  String get camera_selection_hint =>
      '자동으로 부팅 시마다 차량 트림에 맞는 카메라를 선택합니다. 카메라 1 = BYD Seal, 카메라 0 = Atto 트림. 카메라 ID를 변경한 후 설정을 적용하려면 카메라 서비스를 재시작하세요.';

  @override
  String get dashboard_scan_to_connect => '연결하기 위해 스캔';

  @override
  String get dashboard_qr_waiting => '터널을 기다렸어';

  @override
  String get dashboard_daemons_running_default => '0/5 실행 중';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => '액세스 코드';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => '재생식 표본';

  @override
  String get dashboard_set_password => '비밀번호 설정';

  @override
  String get cd_set_password => '사용자 지정 비밀번호 설정';

  @override
  String get dialog_set_password_title => '사용자 지정 비밀번호 설정';

  @override
  String get dialog_set_password_message =>
      '새 접근 비밀번호를 입력하세요. 자동 생성된 토큰을 대체합니다.';

  @override
  String get dialog_set_password_hint => '새 비밀번호 (최소 12자)';

  @override
  String get toast_password_set => '비밀번호가 변경되었습니다';

  @override
  String get toast_password_too_short => '비밀번호는 최소 12자 이상이어야 합니다';

  @override
  String get toast_password_save_failed => '비밀번호 저장 실패 — 서비스가 준비되지 않았습니다';

  @override
  String get setup_guide_title => '시작';

  @override
  String get setup_guide_subtitle => '최고의 경험을 얻기 위한 세 가지 빠른 단계:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => '당신 의 언어 를 선택 하십시오';

  @override
  String get setup_language_body =>
      '기본값은 헤드유닛의 언어입니다. BladeWatch 앱과 웹 터널에 다른 언어를 사용하려면 탭하세요.';

  @override
  String get setup_language_button => '언어 를 선택 하십시오';

  @override
  String get setup_autostart_title => '자동 시작 제한을 비활성화';

  @override
  String get setup_autostart_body =>
      '아래를 눌러 BYD Auto-Start를 열고 BladeWatch와 BladeWatch 서비스의 체크를 모두 해제하세요. 이 설정을 하지 않으면 차량 시동 시 녹화가 시작되지 않아 매번 앱을 열어야 합니다. BYD는 설치할 때마다 이 설정을 초기화합니다.';

  @override
  String get setup_autostart_button => 'BYD 자동 시작 열';

  @override
  String get setup_overlay_title => '다른 앱에서 표시할 수 있도록 하십시오';

  @override
  String get setup_overlay_body =>
      '다른 앱에 녹화 및 여행 추적을 위한 부동 상태 지표를 표시하기 위해 이것을 활성화하십시오.';

  @override
  String get setup_overlay_button => '오버레이 설정 열기';

  @override
  String get cd_close => '닫기';

  @override
  String get language_picker_title => '언어';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '사용 가능한 $arg1 언어';
  }

  @override
  String get language_picker_subtitle_pending => '언어 를 선택 하십시오';

  @override
  String get language_auto_title => '자동차';

  @override
  String language_auto_subtitle(Object arg1) {
    return '추적 시스템 · $arg1';
  }

  @override
  String get language_not_saved => '언어를 적용했지만 저장하지 못했습니다. 앱을 다시 시작하면 되돌아갑니다.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · 자동';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => '명령어를 입력하세요…';

  @override
  String get adb_preset_commands_header => '미리 설정 명령어';

  @override
  String get adb_output_header => '출력';

  @override
  String get adb_output_ready => '명령에 대비해...';

  @override
  String get adb_console_hero_title => 'ADB 콘솔';

  @override
  String get adb_console_hero_subtitle => '장치에서 shell 명령어를 실행';

  @override
  String get adb_console_unavailable_title => 'ADB가 연결되어 있지 않습니다';

  @override
  String get adb_console_unavailable_body =>
      '이 차량에서는 개발자 옵션의 일반 “USB 디버깅” 토글만으로는 충분하지 않습니다. 헤드유닛 자체의 무선 ADB(네트워크 디버깅) 설정도 켜져 있어야 하며, 시스템 업데이트로 인해 초기화될 수 있습니다. 헤드유닛에서 무선 ADB를 다시 켜거나 USB로 연결하세요.';

  @override
  String get adb_console_auth_pending_title => '승인 대기 중';

  @override
  String get adb_console_auth_pending_body =>
      '헤드유닛 화면에서 “USB 디버깅을 허용하시겠습니까?” 메시지를 확인하고 승인한 다음 다시 시도하세요.';

  @override
  String get performance_connecting => '성능 모니터에 연결 중…';

  @override
  String get performance_hero_title => '시스템 성능';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => '시스템 사용률';

  @override
  String get performance_cpu_app_usage => '앱 사용률';

  @override
  String get performance_frequency_label => '주파수';

  @override
  String get performance_temperature_label => '온도';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => '메모리';

  @override
  String get performance_usage_label => '사용률';

  @override
  String get performance_memory_total => '전체';

  @override
  String get performance_memory_used => '사용 중';

  @override
  String get performance_memory_app => '앱';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => '앱 프로세스';

  @override
  String get performance_threads_label => '스레드';

  @override
  String get performance_gc_cycles_label => 'GC 횟수';

  @override
  String get performance_open_fds_label => '열린 FD';

  @override
  String get performance_refreshing_footer => '3초마다 새로 고침';

  @override
  String get webview_loading => '로딩...';

  @override
  String get reset_title => '데이터 초기화';

  @override
  String get reset_subtitle => '축적된 데이터를 카테고리별로 삭제';

  @override
  String get reset_warning =>
      '이 작업은 취소할 수 없습니다. 녹화, 주행 기록, 배터리 기록이 영구적으로 삭제됩니다.';

  @override
  String get reset_cat_trips => '주행 기록';

  @override
  String get reset_cat_trips_desc => '여행 역사, 노선, 주간/월간 순환';

  @override
  String get reset_cat_soc_history => 'SOC & 12V의 역사';

  @override
  String get reset_cat_soc_history_desc => 'SoC 샘플, 충전 세션, 전압 로그';

  @override
  String get reset_cat_recordings => '녹화 (비디오)';

  @override
  String get reset_cat_recordings_desc => '녹화 폴더의 모든 MP4';

  @override
  String get reset_cat_sentry_events => '감시 이벤트';

  @override
  String get reset_cat_sentry_events_desc => '감시 이벤트 클립 및 관련 JSON 파일';

  @override
  String get reset_cat_proximity => '근접 기록';

  @override
  String get reset_cat_proximity_desc => '레이더 트리거된 이벤트 MP4';

  @override
  String get reset_cat_trip_files => '여행 텔레메트리 파일';

  @override
  String get reset_cat_trip_files_desc => '디스크에 있는 여행당 JSON 텔레메트리';

  @override
  String get recording_lib_chip_any => '전체';

  @override
  String get recording_lib_chip_person => '사람';

  @override
  String get recording_lib_chip_vehicle => '차량';

  @override
  String get recording_lib_chip_bike => '자전거';

  @override
  String get recording_lib_chip_animal => '동물';

  @override
  String get recording_lib_chip_alert => '경고';

  @override
  String get recording_lib_chip_critical => '심각';

  @override
  String get recording_lib_selected_count_zero => '0 선택';

  @override
  String get recording_lib_no_recordings => '녹화 없음';

  @override
  String get recording_lib_filter_button => '필터';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return '필터 · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => '녹화 필터';

  @override
  String get recording_lib_filter_apply => '적용';

  @override
  String get recording_lib_filter_reset => '재설정';

  @override
  String get recording_lib_filter_section_what => '대상';

  @override
  String get recording_lib_filter_section_severity => '심각성';

  @override
  String get recording_lib_filter_section_type => '유형';

  @override
  String get recording_lib_chip_type_normal => '보통';

  @override
  String get recording_lib_chip_type_proximity => '근접';

  @override
  String get recording_lib_date_today => '오늘';

  @override
  String get recording_lib_date_yesterday => '어제';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '클립 $arg1개',
      one: '클립 $arg1개',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => '날짜 선택';

  @override
  String get recording_lib_date_all_days => '모든 날짜';

  @override
  String get cd_clear_date_filter => '모든 요일 표시';

  @override
  String get recording_lib_section_morning => '오전';

  @override
  String get recording_lib_section_afternoon => '오후';

  @override
  String get recording_lib_section_evening => '저녁';

  @override
  String get recording_lib_section_night => '야간';

  @override
  String get cd_previous_day => '전날';

  @override
  String get cd_next_day => '다음 날';

  @override
  String get cd_open_filters => '필터 열기';

  @override
  String get cd_clear_filter => '필터 지우기';

  @override
  String get player_title_recording => '녹화';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => '카메라 서비스';

  @override
  String get daemon_name_surveillance => '감시 서비스';

  @override
  String get daemon_name_acc => 'ACC 감시';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => '배경 서비스';

  @override
  String get daemons_count_pending => '로딩 서비스...';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '실행 중인 $arg1의 $arg2';
  }

  @override
  String get battery_health_title => '배터리 건강';

  @override
  String get battery_health_unavailable => '사용할 수 없음';

  @override
  String get battery_health_unavailable_desc => '배터리 상태 추정을 사용할 수 없습니다.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1%에서 $arg2';
  }

  @override
  String get dialog_ok => '확인';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '삭제된 $arg1 기록',
      one: '$arg1 기록이 삭제되었습니다',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 녹화을 삭제',
      one: '$arg1 녹화을 삭제',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '녹화 $arg1개를 영구적으로 삭제합니다. 이 작업은 취소할 수 없습니다.',
      one: '녹화 $arg1개를 영구적으로 삭제합니다. 이 작업은 취소할 수 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return '앱은 최신 (v$arg1)';
  }

  @override
  String get toast_storage_permission_required => '기록에 필요한 저장 권한';

  @override
  String get toast_url_copied_short => 'URL 복사!';

  @override
  String get toast_camera_set_to_auto => '자동으로 설정된 카메라';

  @override
  String get toast_failed_to_save_short => '저장하지 못했습니다';

  @override
  String toast_failed_with_message(Object arg1) {
    return '실패: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return '카메라 $arg1 설정됨 — 다음 ACC 사이클';
  }

  @override
  String get toast_clearing_camera_config => '카메라를 정비하고...';

  @override
  String get toast_restarting_camera_daemon => '카메라 서비스를 재시작하는 중...';

  @override
  String get toast_camera_daemon_restarting => '카메라 서비스가 전체 탐색으로 재시작됩니다';

  @override
  String get toast_camera_restart_failed =>
      '설정이 초기화되었지만 서비스 재시작에 실패했습니다. 수동으로 재시작하세요.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return '실패: $arg1';
  }

  @override
  String get toast_select_at_least_one_category => '적어도 하나의 범주를 선택하세요';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return '재설정 실패: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 트래픽 모니터...';
  }

  @override
  String get dialog_close => '닫기';

  @override
  String get dialog_reset => '재설정';

  @override
  String get dialog_delete => '삭제';

  @override
  String get dialog_save => '저장';

  @override
  String get dialog_enable => '사용';

  @override
  String get dialog_disable => '사용 안 함';

  @override
  String get dialog_keep_enabled => '활성 유지';

  @override
  String get dialog_keep_disabled => '비활성 유지';

  @override
  String get dialog_regenerate => '새로 생성';

  @override
  String get dialog_reset_selected => '선택 항목 초기화';

  @override
  String get dialog_reset_following_title => '다음 항목을 초기화할까요?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return '이 작업은 되돌릴 수 없습니다.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => '초기화 완료';

  @override
  String get dialog_traffic_cannot_check_title => '상태 확인 불가능';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB가 연결되어 있지 않으며, 앱이 자동으로 다시 연결하지 못했습니다.\n\n이 차량에서는 개발자 옵션의 일반적인 \"USB 디버깅\" 스위치만으로는 충분하지 않습니다 — 헤드 유닛 자체의 무선 ADB(네트워크 디버깅) 설정도 켜져 있어야 하며, 시스템 업데이트로 인해 꺼질 수 있습니다. 헤드 유닛에서 무선 ADB를 다시 활성화하거나 USB로 연결하십시오.\n\n연결되면 상태가 자동으로 업데이트됩니다.';

  @override
  String get dialog_traffic_disable_title => 'BYD 트래픽 모니터를 비활성화할까요?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor)는 백그라운드에서 도로 교통 상황을 계속 모니터링하는 내장 시스템 앱입니다.\n\n왜 끄나요?\n\n• 모바일 데이터를 소모합니다 (주차 중에도)\n• 백그라운드에서 CPU와 배터리를 사용합니다\n• 별도의 내비게이션 앱을 쓴다면 필요 없습니다\n• 대시캠의 네트워크 사용을 방해할 수 있습니다\n\n꺼도 안전합니다. 지도의 내장 교통 정보 레이어에만 영향을 주며 내비게이션, 블루투스 등 다른 차량 기능은 그대로입니다.\n\n끈 뒤에는 하드 재부팅이 필요합니다 (센터 콘솔 버튼을 5초간 길게 누르세요).';

  @override
  String get dialog_traffic_enable_title => 'BYD 트래픽 모니터를 다시 활성화하세요?';

  @override
  String get dialog_traffic_enable_message =>
      'BYD 트래픽 모니터는 현재 비활성화되어 있습니다. \n\n 다시 활성화하면 내장된 트래픽 상층을 내비게이션 지도에 복원합니다. 배경에서 실행되고 모바일 데이터를 소비한다는 점에 유의하십시오.\n\n 활성화 후 하드 리부팅이 필요합니다 (중앙 콘솔 버튼을 5 초 동안 유지하십시오).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return '트래픽 모니터 $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      '변경 사항이 적용되었습니다. 이제 하드 재부팅을 수행하십시오. 중앙 콘솔 버튼을 5 초 동안 누르십시오.';

  @override
  String get traffic_monitor_loading => '교통 모니터: 확인...';

  @override
  String get traffic_monitor_tap_to_check => '트래픽 모니터 (검색하기 위해 클릭)';

  @override
  String get reset_label_trips => '주행 기록';

  @override
  String get reset_label_soc_history => 'SoC + 12V의 역사';

  @override
  String get reset_label_recordings => '녹화';

  @override
  String get reset_label_sentry_events => '감시 이벤트';

  @override
  String get reset_label_proximity => '근접 기록';

  @override
  String get reset_label_trip_files => '여행 텔레메트리 파일';

  @override
  String get toast_access_code_copied => '액세스 코드를 복사';

  @override
  String get dialog_regenerate_token_title => '재생식 표본';

  @override
  String get dialog_regenerate_token_message =>
      '현재 토큰이 무효화됩니다. 활성 세션이 모두 로그아웃됩니다. 계속할까요?';

  @override
  String get toast_token_regenerated_logged_out =>
      '새로운 토큰이 생성됐습니다. 모든 세션들이 로그아웃됐습니다.';

  @override
  String get toast_token_regenerated_restart =>
      '토큰이 재생성됐습니다. 적용하려면 서비스를 재시작해야 할 수 있습니다.';

  @override
  String get toast_token_regenerated_no_notify =>
      '토큰이 재생성됐습니다. 백그라운드 서비스에 알릴 수 없었습니다.';

  @override
  String get toast_token_regenerated => '토큰 재생';

  @override
  String get dashboard_no_tunnel => '터널이 통하지 않습니다.';

  @override
  String get dashboard_starting_tor => 'Tor 터널 시작 중…';

  @override
  String get dashboard_waiting_url => '터널 URL 대기 중…';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 실행 중';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => '액세스 코드';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return '$arg1에 대한 구성이 필요하지 않습니다.';
  }

  @override
  String get toast_token_cannot_be_empty => '지표는 빈이 될 수 없습니다';

  @override
  String toast_fetching_log(Object arg1) {
    return '$arg1 로그를 가져오는...';
  }

  @override
  String get toast_log_empty_or_missing => '로그 파일은 빈 또는 발견되지 않았습니다';

  @override
  String get toast_log_empty => '로그 파일은 빈';

  @override
  String toast_log_save_failed(Object arg1) {
    return '로그 저장 실패: $arg1';
  }

  @override
  String get toast_log_not_found => '로그 파일이 발견되지 않거나 읽을 수 없습니다';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1 로그 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return '공유 $arg1 로그';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 로그 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return '출처: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return '수출: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '참고: 로그가 마지막 10000줄로 잘렸습니다 (전체: $arg1줄)',
      one: '참고: 로그가 마지막 10000줄로 잘렸습니다 (전체: $arg1줄)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return '비디오 재생 불가능: $arg1';
  }

  @override
  String get dialog_delete_recording_title => '녹화을 삭제';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '$arg1을(를) 삭제할까요?\n이 작업은 취소할 수 없습니다.';
  }

  @override
  String get toast_recording_deleted => '녹화 삭제';

  @override
  String get toast_recording_delete_failed => '녹화를 삭제하지 못했습니다';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1는 삭제되었고, $arg2는 실패했습니다.';
  }

  @override
  String get play_with_chooser => '놀아';

  @override
  String setup_version_banner(Object arg1) {
    return 'v$arg1에 업데이트 — 자동 시작을 다시 확인, BYD는 모든 설치에서 그것을 지워';
  }

  @override
  String get setup_overlay_already_granted => '이미 승인 되었습니다';

  @override
  String camera_current_manual(Object arg1) {
    return '현재: 카메라 $arg1 (동동)';
  }

  @override
  String get camera_current_auto_label => '현재: 자동';

  @override
  String get soh_estimation_active => '추정 활동';

  @override
  String get soh_oem_readout => '차량 SOH 판독값 — 계산된 추정값 대기 중';

  @override
  String get soh_nominal_baseline => '공칭 기준값 — 신뢰할 수 있는 SOH 데이터 대기 중';

  @override
  String get soh_no_estimate_yet => '아직 추정치 없습니다 — 자료를 기다리고 있습니다';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '선택된 $arg1';
  }

  @override
  String get video_player_playback_error => '재생 오류';

  @override
  String get video_player_no_events => '사건은 없습니다';

  @override
  String get daemon_configuration_required => '필요한 구성';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => '비디오 플레이어';

  @override
  String get status_overlay_notif_title => 'BladeWatch 상태';

  @override
  String get status_overlay_notif_text => '상태 덮개 활성';

  @override
  String get rail_dashboard => '대시보드';

  @override
  String get rail_live => '라이브';

  @override
  String get rail_recordings => '녹화';

  @override
  String get rail_vehicle => '차량';

  @override
  String get rail_trips => '주행 기록';

  @override
  String get rail_location => '위치';

  @override
  String get rail_diagnostics => '진단';

  @override
  String get rail_settings => '설정';

  @override
  String get settings_section_appearance => '겉모습';

  @override
  String get settings_section_recording => '녹화';

  @override
  String get settings_section_surveillance => '감시';

  @override
  String get settings_section_daemons => '서비스';

  @override
  String get settings_section_privacy => '개인 정보 보호 & 데이터';

  @override
  String get settings_section_overlay => '상태 덮개';

  @override
  String get settings_overlay_subtitle => '유동 상태 알약의 어떤 세그먼트가 눈에 띄는지를 선택하십시오.';

  @override
  String get settings_overlay_camera_title => '카메라 표시';

  @override
  String get settings_overlay_camera_subtitle =>
      '녹화가 활발한 상태에서 REC/ PROX 배지를 표시하십시오.';

  @override
  String get settings_overlay_trip_title => '또는 Trip을 나타냅니다';

  @override
  String get settings_overlay_trip_subtitle =>
      '여행 탐지가 실행되는 동안 TRIP 배지를 보여주십시오.';

  @override
  String get settings_section_about => '정보';

  @override
  String get settings_subrail_overline => '설정';

  @override
  String get cd_settings_subrail => '설정 사이드바';

  @override
  String get settings_privacy_title => '개인 정보 보호 & 데이터';

  @override
  String get settings_privacy_body =>
      '초기화하면 녹화 인덱스, 캐시된 인증 정보, 서비스 상태 및 기기 내 설정이 삭제됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get settings_about_title => 'BladeWatch에 대해';

  @override
  String get settings_about_version_label => '버전';

  @override
  String get settings_about_package_label => '건설';

  @override
  String get settings_about_support_section => '당신 같은 사람들로부터';

  @override
  String get settings_about_support_share_title => '다른 차주에게도 알려주세요';

  @override
  String get settings_about_support_share_value =>
      '공유된 모든 링크는 다른 BYD 소유자가 오버드라이브를 발견하는 데 도움이 됩니다.';

  @override
  String get settings_about_support_share_message =>
      'BYD에 대한 오픈소스 감시 및 대시캠을 확인하세요: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => '공유 과장';

  @override
  String get settings_about_open_link_failed => '링크를 열 수 없습니다.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return '브라우저가 없습니다. URL 복사: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => '다음 발매에 연료';

  @override
  String get settings_about_support_kofi_value =>
      'Ko-Fi에 커피 한잔하면 늦은 밤의 약속이 올 수 있습니다.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => '라이센스';

  @override
  String get settings_about_license_value => 'MIT — 오픈소스. 전체 텍스트를 보기 위해 누르십시오.';

  @override
  String get settings_about_source_title => '소스 코드';

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
  String get settings_about_star_title => 'GitHub에 를 던지십시오';

  @override
  String get settings_about_star_value => '잠깐이면 됩니다. 큰 힘이 됩니다.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => '감사합니다';

  @override
  String get settings_about_thanks_subtitle => '기여자와 후원자의 도움으로 만들어졌습니다.';

  @override
  String get settings_about_contributors_title => '기여자';

  @override
  String get settings_about_supporters_title => '후원자';

  @override
  String get settings_about_thanks_empty => '사람들이 참여하면 목록이 채워집니다.';

  @override
  String get settings_theme_label => '주제';

  @override
  String get settings_theme_auto => '자동 (시스템 설정 따르기)';

  @override
  String get settings_theme_light => '라이트';

  @override
  String get settings_theme_dark => '다크';

  @override
  String get settings_language_label => '언어';

  @override
  String get settings_drive_side_label => '내비게이션 위치';

  @override
  String get settings_drive_side_subtitle => '내비게이션 메뉴가 화면의 어느 쪽에 표시될지 선택하세요.';

  @override
  String get settings_drive_side_left => '왼쪽';

  @override
  String get settings_drive_side_left_hint => '좌측 운전석 · 기본값';

  @override
  String get settings_drive_side_right => '오른쪽';

  @override
  String get settings_drive_side_right_hint => '우측 운전석 차량';

  @override
  String get settings_drive_side_auto => '자동';

  @override
  String get settings_drive_side_auto_hint => '차량에서 감지';

  @override
  String get settings_drive_side_caption_left => '내비게이션 왼쪽 배치';

  @override
  String get settings_drive_side_caption_right => '내비게이션 오른쪽 배치';

  @override
  String get settings_drive_side_caption_auto_left => '자동 — 차량이 좌측 운전석으로 보고함';

  @override
  String get settings_drive_side_caption_auto_right => '자동 — 차량이 우측 운전석으로 보고함';

  @override
  String get settings_drive_side_caption_auto_unknown => '자동 — 차량 정보 없음, 왼쪽 사용';

  @override
  String get recordings_title => '녹화';

  @override
  String get recordings_segment_dashcam => '대시캠';

  @override
  String get recordings_segment_surveillance => '감시';

  @override
  String get recordings_action_settings => '설정';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '오늘 $arg1 · $arg2 총 · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'DASHCAM · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return '감시 · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => '녹화을 선택';

  @override
  String get recordings_preview_placeholder_body =>
      '왼쪽에 있는 모든 항목을 누르면 재생할 수 있습니다.';

  @override
  String get diagnostics_section_adb_console => 'ADB 콘솔';

  @override
  String get diagnostics_section_traffic => '교통 모니터';

  @override
  String get diagnostics_section_camera_probe => '카메라 점검';

  @override
  String get diagnostics_section_battery => '배터리 상태';

  @override
  String get diagnostics_section_performance => '성능';

  @override
  String get diagnostics_hero_title => '시스템 진단';

  @override
  String get diagnostics_hero_subtitle => '생체 건강, 로그, 그리고 기기의 탐사.';

  @override
  String get diagnostics_health_clear => '이상 없음';

  @override
  String get diagnostics_health_section => '상태';

  @override
  String get diagnostics_health_network => '네트워크';

  @override
  String get diagnostics_health_storage => '저장공간';

  @override
  String get diagnostics_health_camera => '카메라';

  @override
  String get diagnostics_health_battery => '배터리';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => '온라인';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return '터널 · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => '온라인';

  @override
  String get diagnostics_tunnel_state_offline => '오프라인';

  @override
  String get diagnostics_tunnel_state_connecting => '연결';

  @override
  String get diagnostics_network_mobile => '이동통신';

  @override
  String get diagnostics_network_ethernet => '이더넷';

  @override
  String get diagnostics_network_offline => '오프라인';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '클립 $arg1개 · 사용량 $arg2',
      one: '클립 $arg1개 · 사용량 $arg2',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 무료';
  }

  @override
  String get diagnostics_logs_card_title => '라이브 이벤트 로그';

  @override
  String get diagnostics_logs_card_subtitle => '실행 서비스에서 스트리밍 출력';

  @override
  String get diagnostics_tools_section => '도구';

  @override
  String get diagnostics_traffic_subtitle => '실시간 네트워크 전송을 보세요.';

  @override
  String get diagnostics_camera_probe_subtitle => '연결된 카메라 스트림을 검사하세요.';

  @override
  String get diagnostics_adb_subtitle => '기기의 터미널을 엽니다.';

  @override
  String get diagnostics_battery_subtitle => 'SOH 셀을 검사하고 통계를 포장하세요.';

  @override
  String get diagnostics_settings_subtitle => '앱 선호도, 테마, 언어';

  @override
  String get settings_action_reset_data => '데이터 초기화…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => '감시 중';

  @override
  String get dashboard_subtitle_all_systems => '모든 시스템 온라인';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1의 $arg2 온라인 서비스';
  }

  @override
  String get dashboard_subtitle_no_tunnel => '오프라인에서 원격 액세스';

  @override
  String get dashboard_metric_recordings => '오늘 녹화';

  @override
  String get dashboard_metric_storage => '사용된 저장장치';

  @override
  String get dashboard_metric_tunnel => '원격 접근';

  @override
  String get dashboard_metric_services => '배경 서비스';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => '차량';

  @override
  String get dashboard_chip_recording_active => '녹화 중';

  @override
  String get dashboard_chip_recording_idle => '유휴';

  @override
  String get dashboard_vehicle_tap_to_set => '탭하여 설정';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => '배터리 용량을 설정';

  @override
  String get vehicle_dialog_model_label => '모델';

  @override
  String get vehicle_dialog_save => '저장';

  @override
  String get settings_recording_tab_status => '상태';

  @override
  String get settings_recording_tab_capture => '캡처';

  @override
  String get settings_recording_tab_quality => '품질';

  @override
  String get settings_recording_tab_storage => '저장소';

  @override
  String get settings_recording_status_title => '녹화 상태';

  @override
  String get settings_recording_status_current_state => '현재 상태';

  @override
  String get settings_recording_status_today_count => '오늘 녹화 수';

  @override
  String get settings_recording_mode_title => '녹화 모드 (ACC ON)';

  @override
  String get settings_recording_mode_description => '주행 중 블랙박스가 녹화할 시점을 선택하세요.';

  @override
  String get settings_recording_mode_none_label => '없음 (기본값)';

  @override
  String get settings_recording_mode_none_desc => '녹화 안 함 — 감시는 계속 작동합니다';

  @override
  String get settings_recording_mode_continuous_label => '상시 녹화';

  @override
  String get settings_recording_mode_continuous_desc => '주행 중 항상 녹화';

  @override
  String get settings_recording_mode_drive_label => '주행 모드';

  @override
  String get settings_recording_mode_drive_desc => '차량이 움직일 때만 녹화';

  @override
  String get settings_recording_mode_proximity_label => '근접 감시';

  @override
  String get settings_recording_mode_proximity_desc => '움직임이 감지되면 녹화';

  @override
  String get settings_recording_limit_title => '녹화 길이 제한';

  @override
  String get settings_recording_limit_description =>
      '파일당 최대 길이입니다. 이 간격으로 새 파일로 나뉩니다.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => '녹화 품질';

  @override
  String get settings_recording_storage_title => '녹화 저장소';

  @override
  String get settings_recording_storage_location_label => '저장 위치';

  @override
  String get settings_recording_storage_internal => '내부 저장소';

  @override
  String get settings_recording_storage_sd_card => 'SD 카드';

  @override
  String get settings_recording_storage_sd_card_na => 'SD 카드 (없음)';

  @override
  String get settings_recording_storage_limit_label =>
      '저장 한도 — 도달하면 오래된 것부터 자동 삭제';

  @override
  String get settings_recording_storage_usage_label => '저장공간 사용량';

  @override
  String get settings_recording_storage_files_label => '파일';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 사용 / 한도 $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '녹화본 $arg1개',
      one: '녹화본 $arg1개',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => '경로';

  @override
  String get settings_recording_storage_sd_free_label => 'SD 카드 여유 공간';

  @override
  String get settings_recording_storage_internal_free_label => '내부 저장소 여유 공간';

  @override
  String get settings_recording_format_title => '외장 드라이브 포맷';

  @override
  String get settings_recording_format_warning =>
      'SD 카드 또는 USB 드라이브의 모든 데이터를 영구적으로 지웁니다.';

  @override
  String get settings_recording_format_confirm => '다시 탭하세요 — 모든 데이터가 삭제됩니다';

  @override
  String get settings_recording_format_running => '포맷 중… 잠시 기다려 주세요';

  @override
  String get settings_recording_format_button => 'SD 카드 / USB 포맷';

  @override
  String get settings_recording_format_no_drive => '이동식 드라이브를 찾을 수 없음';

  @override
  String settings_recording_format_success(Object arg1) {
    return '포맷이 완료되었습니다. 새 경로: $arg1';
  }

  @override
  String get settings_recording_sync_title => '데이터베이스 카탈로그';

  @override
  String get settings_recording_sync_description => '녹화 목록을 디스크의 파일과 대조합니다.';

  @override
  String get settings_recording_sync_running => '동기화 중…';

  @override
  String get settings_recording_sync_button => '데이터베이스 동기화';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return '동기화됨: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => '이미 동기화 중입니다';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return '동기화 실패: $arg1';
  }

  @override
  String get settings_recording_apply_button => '변경 사항 적용';

  @override
  String get settings_recording_dismiss => '닫기';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return '$arg1 시작/중지는 아직 지원되지 않습니다';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '사용 된 $arg1 · $arg2 무료';
  }

  @override
  String get dashboard_metric_storage_chip_pending => '저장공간 —';

  @override
  String get dashboard_tunnel_offline => '오프라인';

  @override
  String get dashboard_tunnel_online => '온라인';

  @override
  String get dashboard_tunnel_connecting => '연결 중…';

  @override
  String get dashboard_trips_this_week => '이번 주';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1회 주행',
      one: '$arg1회 주행',
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
  String get dashboard_trips_label_trips => '주행';

  @override
  String get dashboard_trips_label_distance => '거리';

  @override
  String get dashboard_trips_label_time => '주행 시간';

  @override
  String get dashboard_trips_no_data => '이번 주 기록된 주행이 없습니다';

  @override
  String get dashboard_trips_unavailable => '주행을 시작하면 통계가 표시됩니다';

  @override
  String get dashboard_trips_loading => '불러오는 중…';

  @override
  String get dashboard_trips_view_all => '모든 주행 보기';

  @override
  String get dashboard_action_live => '라이브 뷰';

  @override
  String get dashboard_action_live_subtitle => '카메라 화면 열기';

  @override
  String get dashboard_action_recordings => '녹화';

  @override
  String get dashboard_action_settings => '설정';

  @override
  String get dashboard_action_settings_subtitle => '우선 순위 및 약';

  @override
  String get settings_hero_title => '설정';

  @override
  String get settings_hero_overline => '과잉 운전';

  @override
  String get settings_hero_subtitle => '외모, 녹화, 감시 및 장치에 있는 데이터를 조정하십시오.';

  @override
  String get settings_overline_preferences => '우선순위';

  @override
  String get settings_overline_about_data => '에 관한 & DATA';

  @override
  String get settings_quick_theme_label => '주제';

  @override
  String get settings_quick_language_label => '언어';

  @override
  String get settings_section_recording_subtitle => '전/후 버퍼, 코덱, 저장 제한';

  @override
  String get settings_section_surveillance_subtitle => '일정, 동작 감도, 객체 감지.';

  @override
  String get settings_section_daemons_subtitle => 'Tor 터널 및 백그라운드 서비스.';

  @override
  String get settings_about_row_title => 'BladeWatch에 대해';

  @override
  String get settings_about_row_subtitle => '버전, 라이선스, 지원 개발.';

  @override
  String get settings_reset_row_subtitle => '녹화, 사건, 또는 모든 캐시';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle => '테마, 언어, 시각적 선호도';

  @override
  String get settings_theme_active_auto_caption => '자동으로 시스템 테마를 따라갑니다.';

  @override
  String get settings_theme_active_light_caption => '라이트 테마가 항상 켜져 있습니다.';

  @override
  String get settings_theme_active_dark_caption => '다크 테마가 항상 켜져 있습니다.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg2개 언어 중 $arg1개 사용 가능';
  }

  @override
  String get settings_language_card_title => '디스플레이 언어';

  @override
  String get settings_privacy_stance_title => '기본 장치';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch는 전용으로 작동합니다. 당신이 명시적으로 구성한 터널과 통합을 제외하고는 차에서 탈퇴할 수 없습니다.';

  @override
  String get settings_privacy_overline_storage => '로컬 스토리지';

  @override
  String get settings_privacy_overline_reset => '데이터 리셋';

  @override
  String get settings_privacy_storage_clips_label => '디스크에 있는 클립';

  @override
  String get settings_privacy_storage_size_label => '전체 크기는';

  @override
  String get settings_privacy_storage_unavailable => '가용되지 않습니다';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '클립 $arg1개',
      one: '클립 $arg1개',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      '카테고리를 선택하세요: 녹화, 이벤트, 서비스 설정, 캐시된 텔레메트리...';

  @override
  String get settings_developer_overline => '개발자';

  @override
  String get settings_developer_timing_logs_title => '서비스 타이밍 로그';

  @override
  String get settings_developer_timing_logs_subtitle =>
      '서비스 시작 중 경과 시간 마커를 기록합니다. 일반 사용 시에는 logcat을 깔끔하게 유지하려면 끄세요.';

  @override
  String get settings_developer_debug_logs_title => '개발자 디버그 로그';

  @override
  String get settings_developer_debug_logs_subtitle =>
      '모든 Activity 및 Fragment 수명 주기 이벤트와 시작 단계를 /storage/emulated/0/BladeWatch/data/debug_app.log에 기록합니다. 충돌은 항상 기록됩니다. 기본값은 꺼짐입니다.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return '카메라 $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return '카메라 $arg1 (손잡이)';
  }

  @override
  String get diagnostics_camera_value_probing => '확인 중…';

  @override
  String get diagnostics_camera_value_offline => '오프라인';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => '데이터 대기 중';

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
      other: '클립 $arg1개 · $arg2 녹화됨',
      one: '클립 $arg1개 · $arg2 녹화됨',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => '트렁크';

  @override
  String get vehicle_tab_climate => '공조';

  @override
  String get vehicle_tab_seats => '좌석';

  @override
  String get vehicle_tab_windows => '창문';

  @override
  String get vehicle_tab_lights => '조명';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => '충전';

  @override
  String get vehicle_locked => '잠금';

  @override
  String get vehicle_unlocked => '잠금 해제';

  @override
  String get vehicle_range_label => '주행거리';

  @override
  String get vehicle_data_unavailable => '차량 데이터를 사용할 수 없습니다.';

  @override
  String get vehicle_action_failed => '작업에 실패했습니다. 차량 연결을 확인하세요.';

  @override
  String get vehicle_open_trunk => '트렁크 열기';

  @override
  String get vehicle_close_trunk => '트렁크 닫기';

  @override
  String get vehicle_trunk_info_open => '트렁크를 열면 차량 잠금이 먼저 해제됩니다.';

  @override
  String get vehicle_ac_on => 'AC 켜짐';

  @override
  String get vehicle_ac_off => 'AC 꺼짐';

  @override
  String get vehicle_max_cooling_on => '최대 냉방: 켜짐';

  @override
  String get vehicle_max_cooling_off => '최대 냉방: 꺼짐';

  @override
  String get vehicle_temp_label => '온도';

  @override
  String get vehicle_fan_speed_label => '팬 속도';

  @override
  String vehicle_fan_level(Object arg1) {
    return '$arg1 단계';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return '실내: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => '운전석';

  @override
  String get vehicle_seat_passenger => '조수석';

  @override
  String get vehicle_seat_no_controls => '이 차량에는 사용 가능한 좌석 제어 기능이 없습니다.';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return '열선 $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return '통풍 $arg1';
  }

  @override
  String get vehicle_heat_off => '(꺼짐)';

  @override
  String get vehicle_heat_low => '(약)';

  @override
  String get vehicle_heat_high => '(강)';

  @override
  String get vehicle_seat_pos_1 => '위치 1';

  @override
  String get vehicle_seat_pos_2 => '위치 2';

  @override
  String get vehicle_all_windows => '전체 창문';

  @override
  String get vehicle_window_awake_note => '차량이 켜져 있을 때만 작동합니다.';

  @override
  String get vehicle_window_front_left => '앞 왼쪽';

  @override
  String get vehicle_window_front_right => '앞 오른쪽';

  @override
  String get vehicle_window_rear_left => '뒤 왼쪽';

  @override
  String get vehicle_window_rear_right => '뒤 오른쪽';

  @override
  String get vehicle_window_close => '닫기';

  @override
  String get vehicle_window_close_vent => '환기 닫기';

  @override
  String get vehicle_window_vent_12 => '환기 12%';

  @override
  String get vehicle_window_open_all => '모두 열기';

  @override
  String get vehicle_sunroof => '선루프';

  @override
  String get vehicle_sunshade => '햇빛 가리개';

  @override
  String get vehicle_btn_drl_title => '낮에 가동하는 조명';

  @override
  String get vehicle_btn_slw_title => '속도 제한 경고';

  @override
  String get vehicle_control_section_charge_cap => '충전 한도';

  @override
  String get vehicle_charge_cap_not_supported => '이 차량은 충전 한도를 지원하지 않습니다.';

  @override
  String get vehicle_charge_limit_label => '충전 한도';

  @override
  String get vehicle_enable_charge_limit => '충전 한도 사용';

  @override
  String get vehicle_charge_limit_range => '최소 50%, 최대 100%';

  @override
  String get vehicle_tyre_no_signal => '신호 없음';

  @override
  String get vehicle_tyre_slow_leak => '느린 누출';

  @override
  String get vehicle_tyre_fast_leak => '빠른 누출';

  @override
  String get vehicle_tyre_low => '낮음';

  @override
  String get vehicle_tyre_high => '높음';

  @override
  String get vehicle_tyre_ok => '정상';

  @override
  String get vehicle_tyre_check_pressure => '공기압 확인';

  @override
  String get vehicle_toggle_on => '켜짐';

  @override
  String get vehicle_toggle_off => '꺼짐';

  @override
  String get vehicle_err_climate_control => '공조 제어에 실패했습니다.';

  @override
  String get vehicle_err_max_cooling => '최대 냉방에 실패했습니다.';

  @override
  String get vehicle_err_drl_control => '주간주행등 제어에 실패했습니다.';

  @override
  String get vehicle_err_slw_control => 'ADAS 제어에 실패했습니다.';

  @override
  String get vehicle_err_charge_limit_toggle => '충전 한도 전환에 실패했습니다.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return '$arg1 낮추기';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return '$arg1 높이기';
  }

  @override
  String get vehicle_stale_connecting => '연결 중…';

  @override
  String get vehicle_appearance_model_title => '모델 선택';

  @override
  String get vehicle_appearance_custom_color => '사용자 지정 색상';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return '충전: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return '주행거리: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => '충전: —';

  @override
  String get vehicle_status_range_unknown => '주행거리: —';

  @override
  String get startup_subtitle => '대시캠을 준비하는 중';

  @override
  String get startup_header_preparing => '준비하는 중…';

  @override
  String get startup_header_starting => '시작하는 중…';

  @override
  String get startup_header_verifying => '거의 준비되었습니다…';

  @override
  String get startup_header_ready => '모든 준비가 완료되었습니다';

  @override
  String get startup_daemon_camera => '카메라';

  @override
  String get startup_daemon_camera_desc => '라이브 뷰 및 녹화';

  @override
  String get startup_daemon_sentry => '감시 모드';

  @override
  String get startup_daemon_sentry_desc => '움직임 감지 및 알림';

  @override
  String get startup_daemon_parking => '주차 감시';

  @override
  String get startup_daemon_parking_desc => '주차 중 감시 유지';

  @override
  String get startup_status_waiting => '대기 중';

  @override
  String get startup_status_starting => '시작 중';

  @override
  String get startup_status_ready => '준비됨';

  @override
  String get startup_status_failed => '실패';

  @override
  String get startup_continue_anyway => '그래도 계속';

  @override
  String get startup_continue => '계속 →';

  @override
  String get live_retry => '다시 시도';

  @override
  String get live_connecting => '카메라에 연결하는 중…';

  @override
  String live_error_fmt(Object arg1) {
    return '오류: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return '카메라를 사용할 수 없습니다\n$arg1';
  }

  @override
  String get live_direction_all => '전체';

  @override
  String get live_direction_front => '전방';

  @override
  String get live_direction_right => '우측';

  @override
  String get live_direction_rear => '후방';

  @override
  String get live_direction_left => '좌측';

  @override
  String get trip_no_route_data => '이 주행의 경로 데이터가 없습니다';

  @override
  String get trips_tab_trips => '주행';

  @override
  String get trips_tab_stats => '통계';

  @override
  String get trips_tab_storage => '저장공간';

  @override
  String get trips_filter_7_days => '7일';

  @override
  String get trips_filter_14_days => '14일';

  @override
  String get trips_filter_30_days => '30일';

  @override
  String trips_load_error(Object message) {
    return '오류: $message';
  }

  @override
  String get trips_empty_state => '아직 기록된 주행이 없습니다';

  @override
  String get trips_period_summary_title => '기간 요약';

  @override
  String get trips_stat_trips => '주행';

  @override
  String get trips_stat_hours => '시간';

  @override
  String get trips_stat_efficiency => '효율';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return '점수: $score';
  }

  @override
  String get trips_driver_score_title => '운전자 점수';

  @override
  String trips_driver_score_overall(Object score) {
    return '종합: $score / 100';
  }

  @override
  String get trips_range_title => '맞춤 주행 가능 거리';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD 추정: $km';
  }

  @override
  String get trips_range_no_data => '아직 데이터가 충분하지 않습니다';

  @override
  String get trips_dna_title => '운전 DNA';

  @override
  String get trips_dna_anticipation => '예측 주행';

  @override
  String get trips_dna_smoothness => '부드러움';

  @override
  String get trips_dna_speed_discipline => '속도 준수';

  @override
  String get trips_dna_efficiency => '효율';

  @override
  String get trips_dna_consistency => '일관성';

  @override
  String get trips_storage_title => '주행 저장공간';

  @override
  String get trips_storage_analytics_label => '주행 분석';

  @override
  String get trips_storage_rate_label => '전기 요금';

  @override
  String get trips_storage_distance_unit_label => '거리 단위';

  @override
  String get trips_storage_location_label => '저장 위치';

  @override
  String get trips_storage_internal => '내부 저장소';

  @override
  String get trips_storage_sd_card => 'SD 카드';

  @override
  String get trips_storage_sd_card_unavailable => 'SD 카드 (없음)';

  @override
  String get trips_storage_apply => '변경 사항 적용';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit 사용 / 한도 $limit MB · 주행 $count회';
  }

  @override
  String get trips_sync_title => '데이터베이스 카탈로그';

  @override
  String get trips_sync_description => '주행 목록을 디스크의 텔레메트리 파일과 대조합니다.';

  @override
  String get trips_sync_button => '데이터베이스 동기화';

  @override
  String get trips_sync_running => '동기화 중…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return '동기화 성공: +$added -$removed (총 $total건)';
  }

  @override
  String get trips_sync_failed_generic => '동기화 실패';

  @override
  String get trips_detail_summary_title => '주행 요약';

  @override
  String get trips_detail_distance => '거리';

  @override
  String get trips_detail_duration => '소요 시간';

  @override
  String get trips_detail_energy => '에너지';

  @override
  String get trips_detail_avg_speed => '평균 속도';

  @override
  String get trips_detail_max_speed => '최고 속도';

  @override
  String get trips_detail_soc => '충전 상태';

  @override
  String get trips_detail_cost => '비용';

  @override
  String get trips_detail_ext_temp => '외기 온도';

  @override
  String get trips_detail_elev_gain => '고도 상승';

  @override
  String get trips_detail_scores_title => '운전 점수';

  @override
  String get trips_detail_unavailable => '주행 세부정보를 사용할 수 없습니다';

  @override
  String get trips_detail_loading => '주행 불러오는 중…';

  @override
  String trips_detail_route_points(Object count) {
    return 'GPS 포인트 $count개 기록됨';
  }

  @override
  String get rec_severity_critical => '심각';

  @override
  String get rec_severity_alert => '경고';

  @override
  String get location_loading_title => '지도 불러오는 중';

  @override
  String get location_permission_missing_title => '위치 권한이 필요합니다';

  @override
  String get location_permission_denied_title => '권한이 거부되었습니다';

  @override
  String get location_provider_disabled_title => 'GPS 비활성화됨';

  @override
  String get location_waiting_for_fix_title => 'GPS 신호 대기 중';

  @override
  String get location_car_location_title => '차량 위치';

  @override
  String get location_stale_title => '위치 정보 오래됨';

  @override
  String get location_tile_failure_title => '지도를 사용할 수 없음';

  @override
  String get location_tile_failure_subtitle => '네트워크를 사용할 수 없음';

  @override
  String get location_error_title => '위치 오류';

  @override
  String get location_action_grant => '허용';

  @override
  String get location_action_retry => '다시 시도';

  @override
  String get location_mode_auto => '자동';

  @override
  String get location_mode_light => '밝게';

  @override
  String get location_mode_dark => '어둡게';

  @override
  String get cd_recenter_on_car => '차량으로 다시 중심 맞추기';

  @override
  String get recording_lib_no_recordings_normal => '일반 녹화 없음';

  @override
  String get recording_lib_no_recordings_sentry => '감시 이벤트 없음';

  @override
  String get recording_lib_no_recordings_proximity => '근접 이벤트 없음';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => '사람';

  @override
  String get video_player_legend_car => '자동차';

  @override
  String get video_player_legend_bike => '자전거';

  @override
  String get video_player_legend_motion => '움직임';

  @override
  String get recording_lib_proximity_very_close => '매우 가까움';

  @override
  String get recording_lib_proximity_close => '가까움';

  @override
  String get recording_lib_proximity_mid => '중간';

  @override
  String get recording_lib_proximity_far => '멀음';

  @override
  String get surveillance_tab_general => '일반';

  @override
  String get surveillance_tab_detection => '감지';

  @override
  String get surveillance_tab_recording => '녹화';

  @override
  String get surveillance_tab_storage => '저장공간';

  @override
  String get surveillance_tab_advanced => '고급';

  @override
  String get surveillance_general_title => '감시 모드';

  @override
  String get surveillance_general_enable => '감시 활성화';

  @override
  String get surveillance_general_status => '상태';

  @override
  String get surveillance_general_status_running => '실행 중';

  @override
  String get surveillance_general_status_idle => '대기 중';

  @override
  String get surveillance_general_events_today => '오늘의 이벤트';

  @override
  String get surveillance_safe_locations_title => '안전 지역';

  @override
  String get surveillance_safe_locations_subtitle =>
      '이 위치에 주차하면 카메라가 작동하지 않습니다';

  @override
  String get surveillance_safe_locations_enable => '안전 지역에서 비활성화';

  @override
  String get surveillance_safe_locations_empty => '아직 추가된 안전 지역이 없습니다';

  @override
  String get surveillance_safe_locations_add_current => '현재 위치를 안전 구역으로 추가';

  @override
  String get surveillance_safe_locations_no_gps => 'GPS 위치를 사용할 수 없습니다';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => '감지 설정';

  @override
  String get surveillance_detection_preset_label => '환경 프리셋';

  @override
  String get surveillance_preset_outdoor => '실외';

  @override
  String get surveillance_preset_garage => '차고';

  @override
  String get surveillance_preset_street => '거리';

  @override
  String get surveillance_preset_custom => '사용자 지정';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return '민감도 (1=엄격, 5=민감): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => '감지 대상';

  @override
  String get surveillance_detection_object_person => '사람';

  @override
  String get surveillance_detection_object_car => '자동차';

  @override
  String get surveillance_detection_object_bike => '자전거';

  @override
  String get surveillance_recording_title => '이벤트 녹화';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return '사전 녹화(이벤트 전 초): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return '사후 녹화(이벤트 후 초): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => '감시 저장공간';

  @override
  String get surveillance_storage_location_label => '저장 위치';

  @override
  String get surveillance_storage_internal => '내장';

  @override
  String get surveillance_storage_sd_card => 'SD 카드';

  @override
  String get surveillance_storage_sd_card_na => 'SD 카드(사용 불가)';

  @override
  String get surveillance_storage_limit_label => '저장 한도 — 도달 시 가장 오래된 항목 자동 삭제';

  @override
  String get surveillance_storage_usage_label => '저장공간 사용량';

  @override
  String get surveillance_storage_files_label => '파일';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 사용 / 한도 $arg2';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '이벤트 $arg1개',
      one: '이벤트 $arg1개',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => '경로';

  @override
  String get surveillance_format_title => '외장 드라이브 포맷';

  @override
  String get surveillance_format_warning =>
      'SD 카드 또는 USB 드라이브의 모든 데이터를 영구적으로 삭제합니다.';

  @override
  String get surveillance_format_button => 'SD 카드/USB 포맷';

  @override
  String get surveillance_format_confirm => '다시 탭하세요 — 모든 데이터가 삭제됩니다';

  @override
  String get surveillance_format_running => '포맷 중… 잠시 기다려 주세요';

  @override
  String get surveillance_dismiss => '닫기';

  @override
  String get surveillance_sync_title => '데이터베이스 카탈로그';

  @override
  String get surveillance_sync_description => '감시 색인을 디스크의 파일과 동기화합니다.';

  @override
  String get surveillance_sync_button => '데이터베이스 동기화';

  @override
  String get surveillance_sync_running => '동기화 중…';

  @override
  String get surveillance_advanced_camera_title => '카메라 선택';

  @override
  String get surveillance_advanced_camera_front => '전방';

  @override
  String get surveillance_advanced_camera_right => '우측';

  @override
  String get surveillance_advanced_camera_rear => '후방';

  @override
  String get surveillance_advanced_camera_left => '좌측';

  @override
  String get surveillance_advanced_ai_title => 'AI 및 저지 조치';

  @override
  String get surveillance_advanced_ai_detection => 'AI 감지';

  @override
  String get surveillance_advanced_night_mode => '야간 모드';

  @override
  String get surveillance_advanced_deterrent_label => '저지 동작';

  @override
  String get surveillance_deterrent_silent => '무음';

  @override
  String get surveillance_deterrent_horn => '경적';

  @override
  String get surveillance_deterrent_flash => '플래시';

  @override
  String get surveillance_apply_button => '변경 사항 적용';

  @override
  String get surveillance_apply_failed => '저장 실패';

  @override
  String get dashboard_tor_bootstrapping => 'Tor에 연결 중…';

  @override
  String get dashboard_tor_help_tooltip => '이 주소를 여는 방법';

  @override
  String get dashboard_tor_help_title => '이 주소 열기';

  @override
  String get dashboard_tor_help_android =>
      'Android: Google Play 또는 F-Droid에서 Tor Browser를 설치하고 실행한 뒤 주소를 붙여넣으세요.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone 및 iPad: App Store에서 Onion Browser를 설치하고 실행한 뒤 주소를 붙여넣으세요. iOS용 Tor Browser는 없습니다.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS, Linux: torproject.org에서 Tor Browser를 내려받아 실행한 뒤 주소를 붙여넣으세요.';

  @override
  String get dashboard_tor_help_password_note => '페이지가 열린 뒤에도 비밀번호가 필요합니다.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      '스캔하여 Tor Browser 다운로드 페이지로 이동';

  @override
  String get dashboard_tor_help_close => '확인';
}
