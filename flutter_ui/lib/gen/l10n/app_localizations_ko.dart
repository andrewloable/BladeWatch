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
      '이 서비스는 스크린 콘텐츠를 읽거나 상호 작용하지 않습니다.';

  @override
  String get action_cancel => '취소';

  @override
  String get action_clear_plain => '지우기';

  @override
  String get action_select_all => '모든 것을 선택';

  @override
  String get action_select_all_short => '모두들';

  @override
  String get action_delete => '삭제';

  @override
  String get action_done => '완료';

  @override
  String get action_remind_me_later => '나중에 기억해';

  @override
  String get action_retry => '다시 시도';

  @override
  String get action_run => '도망쳐';

  @override
  String get action_clear_output => '명확한 출력';

  @override
  String get cd_camera => '카메라';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR 코드';

  @override
  String get cd_show_hide_token => '표시/숨기 표기';

  @override
  String get cd_copy_token => '복제 표기';

  @override
  String get cd_copy_url => '복사 URL';

  @override
  String get cd_clear_logs => '맑은 로그';

  @override
  String get cd_expand_collapse => '확장/ 붕괴';

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
  String get cd_play_pause => '플레이/파우즈';

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
  String get cd_expand => '확장';

  @override
  String get cd_configure => '구성';

  @override
  String get cd_download_log => '다운로드 로그';

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
  String get log_entry_default_timestamp => '12시 34분56분';

  @override
  String get log_entry_default_tag => '[ TAG]';

  @override
  String get log_entry_default_message => '로그 메시지는 여기';

  @override
  String get daemon_card_default_name => '서비스 이름';

  @override
  String get daemon_card_default_status => '상태 메시지';

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
  String get camera_option_0 => '카메라 0  Atto 트림';

  @override
  String get camera_option_1 => '카메라 1  Seal (전설)';

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
  String get dashboard_daemons_running_default => '0/5 실행';

  @override
  String get dashboard_device_id_loading => '...';

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
      'BladeWatch 앱과 웹 터널에 다른 언어를 선택하기 위해 버튼을 누르십시오.';

  @override
  String get setup_language_button => '언어 를 선택 하십시오';

  @override
  String get setup_autostart_title => '자동 시작 제한을 비활성화';

  @override
  String get setup_autostart_body =>
      '아래를 누르면 BYD 자동 시작을 열 수 있습니다. 목록에서 BladeWatch를 찾아 상자를 삭제합니다. BYD는 모든 설치에서 이것을 삭제합니다. 업데이트 후에 다시 할 것입니다.';

  @override
  String get setup_autostart_button => 'BYD 자동 시작 열';

  @override
  String get setup_overlay_title => '다른 앱에서 표시할 수 있도록 하십시오';

  @override
  String get setup_overlay_body =>
      '다른 앱에 녹화 및 여행 추적을 위한 부동 상태 지표를 표시하기 위해 이것을 활성화하십시오.';

  @override
  String get setup_overlay_button => '겹치기 설정을 열';

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
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · 자동';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => '명령에 들어가...';

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
  String get performance_connecting => 'Connecting to performance monitor…';

  @override
  String get performance_hero_title => '시스템 성능';

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
  String get performance_memory_title => '메모리';

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
  String get performance_app_process_title => '앱 프로세스';

  @override
  String get performance_threads_label => 'Threads';

  @override
  String get performance_gc_cycles_label => 'GC Cycles';

  @override
  String get performance_open_fds_label => 'Open FDs';

  @override
  String get performance_refreshing_footer => 'Refreshing every 3 seconds';

  @override
  String get webview_loading => '로딩...';

  @override
  String get webview_camera_daemon_not_running => '카메라가 실행 중이지 않습니다';

  @override
  String get webview_start_camera_daemon =>
      '이 페이지에 접속하려면 서비스 화면에서 카메라 서비스를 시작하세요.';

  @override
  String get zrok_enable_token_hint => '토큰을 활성화';

  @override
  String get zrok_token_storage_note => '토큰은 안전하게 저장되어 앱과 백그라운드 서비스 사이에 공유됩니다.';

  @override
  String get zrok_reset_environment => 'Zrok 환경을 다시 설정';

  @override
  String get zrok_reset_environment_desc =>
      '환경과 토큰을 제거합니다. 토큰으로 다시 활성화해야 합니다 (기기 슬롯을 사용합니다).';

  @override
  String get reset_title => '재설정 데이터';

  @override
  String get reset_subtitle => '축적된 데이터를 카테고리별로 삭제';

  @override
  String get reset_warning =>
      '이 작업 을 취소 할 수 없습니다. 녹음, 여행 및 배터리 역사 는 영구 히 삭제 됩니다.';

  @override
  String get reset_cat_trips => '주행 기록';

  @override
  String get reset_cat_trips_desc => '여행 역사, 노선, 주간/월간 순환';

  @override
  String get reset_cat_soc_history => 'SOC & 12V의 역사';

  @override
  String get reset_cat_soc_history_desc => 'SoC 샘플, 충전 세션, 전압 로그';

  @override
  String get reset_cat_soh => 'SOH 캘리브레이션';

  @override
  String get reset_cat_soh_desc => 'BMS에서 명칭 용량을 재발견, 재배량 추정';

  @override
  String get reset_cat_recordings => '녹음 (비디오)';

  @override
  String get reset_cat_recordings_desc => '녹음 폴더의 모든 MP4';

  @override
  String get reset_cat_sentry_events => '감시 이벤트';

  @override
  String get reset_cat_sentry_events_desc => '감시 이벤트 클립과 JSON 사이드카르';

  @override
  String get reset_cat_proximity => '근접 기록';

  @override
  String get reset_cat_proximity_desc => '레이더 트리거된 이벤트 MP4';

  @override
  String get reset_cat_trip_files => '여행 텔레메트리 파일';

  @override
  String get reset_cat_trip_files_desc => '디스크에 있는 여행당 JSON 텔레메트리';

  @override
  String get recording_lib_chip_any => '어떤 것도';

  @override
  String get recording_lib_chip_person => '개인';

  @override
  String get recording_lib_chip_vehicle => '차량';

  @override
  String get recording_lib_chip_bike => '자전거';

  @override
  String get recording_lib_chip_animal => '동물';

  @override
  String get recording_lib_chip_alert => '경고';

  @override
  String get recording_lib_chip_critical => '비평적';

  @override
  String get recording_lib_selected_count_zero => '0 선택';

  @override
  String get recording_lib_no_recordings => '녹음도 없다';

  @override
  String get recording_lib_filter_button => '필터';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return '필터 · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => '필터 녹음';

  @override
  String get recording_lib_filter_apply => '적용';

  @override
  String get recording_lib_filter_reset => '재설정';

  @override
  String get recording_lib_filter_section_what => '무슨 일이야?';

  @override
  String get recording_lib_filter_section_severity => '심각성';

  @override
  String get recording_lib_filter_section_type => '유형';

  @override
  String get recording_lib_chip_type_normal => '보통';

  @override
  String get recording_lib_chip_type_proximity => '거리';

  @override
  String get recording_lib_date_today => '오늘날';

  @override
  String get recording_lib_date_yesterday => '어제';

  @override
  String recording_lib_clip_count(Object arg1) {
    return '$arg1 클립';
  }

  @override
  String recording_lib_clip_count_one(Object arg1) {
    return '$arg1 클립';
  }

  @override
  String get recording_lib_pick_date => '데이트를 선택하세요';

  @override
  String get recording_lib_date_all_days => '종일';

  @override
  String get cd_clear_date_filter => '모든 요일 표시';

  @override
  String get recording_lib_section_morning => '아침';

  @override
  String get recording_lib_section_afternoon => '안녕하세요';

  @override
  String get recording_lib_section_evening => '저녁';

  @override
  String get recording_lib_section_night => '밤';

  @override
  String get cd_previous_day => '전날';

  @override
  String get cd_next_day => '다음 날';

  @override
  String get cd_open_filters => '열 필터';

  @override
  String get cd_clear_filter => '맑은 필터';

  @override
  String get player_title_recording => '녹음';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

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
  String get battery_health_subtitle => '건강 상태';

  @override
  String get battery_health_dashes => '--';

  @override
  String get battery_health_waiting => '자료를 기다리고 있어...';

  @override
  String get battery_health_source => '출처';

  @override
  String get battery_health_method => '방법';

  @override
  String get battery_health_capacity => '용량';

  @override
  String get battery_health_samples => '표본';

  @override
  String get battery_health_last_updated => '마지막 업데이트';

  @override
  String get battery_health_reset => 'SOH 추정값을 재설정';

  @override
  String get battery_health_reset_desc =>
      '모든 데이터를 삭제하고 처음부터 재평가합니다. 배터리가 교체되거나 읽기 잘못 된 경우 사용하십시오.';

  @override
  String get soh_dialog_model_label => '모델';

  @override
  String get soh_dialog_pack_capacity_label => '포장 용량은';

  @override
  String get soh_dialog_estimated_capacity_label => '효율적인 용량';

  @override
  String get soh_dialog_calibration_anchor_label => '마지막 캘리브레이션';

  @override
  String get soh_dialog_source_user => '사용자 집합';

  @override
  String get soh_dialog_source_auto => '자동 감지';

  @override
  String get soh_dialog_model_not_selected => '선택되지 않았습니다';

  @override
  String get soh_dialog_capacity_not_detected => '발견되지 않았습니다.';

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
      other: '$arg1 녹음을 삭제',
      one: '$arg1 녹음을 삭제',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '이것은 $arg1 녹음을 영구적으로 삭제합니다. 이것은 취소할 수 없습니다.',
      one: '이것은 $arg1 녹음을 영구적으로 삭제합니다. 이것은 취소할 수 없습니다.',
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
  String get toast_failed_to_save_short => '구하지 못했어요';

  @override
  String toast_failed_with_message(Object arg1) {
    return '실패: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return '카메라 $arg1 세트  다음 ACC 사이클';
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
  String get toast_soh_reset_success => 'SOH 추정 재설정  다음 데이터에서 재 계산됩니다';

  @override
  String get toast_soh_reset_failed_no_daemon =>
      '재설정 실패 — 서비스가 응답하지 않고 파일을 쓸 수 없습니다';

  @override
  String toast_soh_reset_failed_with_message(Object arg1) {
    return '재설정 실패: $arg1';
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
  String get dialog_keep_enabled => '계속 사용 할 수 있게 하라';

  @override
  String get dialog_keep_disabled => '장애 를 유지 하십시오';

  @override
  String get dialog_regenerate => '재생';

  @override
  String get dialog_reset_selected => '재설정 선택';

  @override
  String get dialog_reset_soh_title => 'SOH 추정값을 재설정하세요?';

  @override
  String get dialog_reset_soh_message =>
      '이 방법은 모든 SOH 데이터를 삭제하고 처음부터 재평가를 강요합니다. 이 경우:\n\n• 배터리가 교체되었습니다.\n• SOH 판독은 잘못된 것 같습니다.\n• 당신은 재계열을 원하고 있습니다.\n\n시스템은 다음 사용할 수 있는 데이터 소스에서 재계열됩니다. (OEM, 충전 캘리브레이션, 또는 즉각적인 판독).';

  @override
  String get dialog_reset_following_title => '다음을 다시 설정하세요?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'This cannot be undone.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => '다시 설정 완료';

  @override
  String get dialog_traffic_cannot_check_title => '상태 확인 불가능';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB가 연결되어 있지 않으며, 앱이 자동으로 다시 연결하지 못했습니다.\n\n이 차량에서는 개발자 옵션의 일반적인 \"USB 디버깅\" 스위치만으로는 충분하지 않습니다 — 헤드 유닛 자체의 무선 ADB(네트워크 디버깅) 설정도 켜져 있어야 하며, 시스템 업데이트로 인해 꺼질 수 있습니다. 헤드 유닛에서 무선 ADB를 다시 활성화하거나 USB로 연결하십시오.\n\n연결되면 상태가 자동으로 업데이트됩니다.';

  @override
  String get dialog_traffic_disable_title => 'BYD 트래픽 모니터를 비활성화하세요?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD 트래픽 모니터 (com.byd.trafficmonitor) 는 백그라운드에서 도로 교통 상태를 지속적으로 모니터링하는 내장 시스템 응용 프로그램입니다. \n\n️ 왜 비활성화해야합니까?\n\n• 모바일 데이터를 소비합니다 (파크 할 때에도) \n• 배경에서 CPU와 배터리를 사용합니다\n• 별도의 내비게이션 응용 프로그램을 사용하면 필요하지 않습니다\n• 대시캠 네트워크 사용에 방해를 줄 수 있습니다\n\n이 안전하게 비활성화 할 수 있습니다.';

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
  String get reset_label_soh => 'SOH 캘리브레이션';

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
      '이것은 현재 토큰을 무효화합니다. 모든 활성 세션이 로그 아웃됩니다. 계속하세요?';

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
  String get dashboard_starting_zrok => 'Zrok 터널 시작...';

  @override
  String get dashboard_waiting_url => '터널 URL를 기다렸어요';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 실행';
  }

  @override
  String get tunnel_label_zrok => 'Zrok';

  @override
  String get clip_label_access_code => '액세스 코드';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return '$arg1에 대한 구성이 필요하지 않습니다.';
  }

  @override
  String get dialog_zrok_token_title => 'Zrok 터널 토큰';

  @override
  String get dialog_zrok_token_message => 'Zrok 활성화 토큰을 입력합니다.';

  @override
  String get toast_token_cannot_be_empty => '지표는 빈이 될 수 없습니다';

  @override
  String get dialog_zrok_reset_title => 'Zrok 환경을 다시 설정';

  @override
  String get dialog_zrok_reset_message =>
      '이것은:\n• 실행되는 경우 zrok 터널을 중지합니다\n• 이 장치에서 zrok 환경을 제거합니다\n• 저장된 토큰을 삭제합니다\n\n당신은 다시 토큰을 입력하고 다시 활성화해야합니다. 이것은 zrok.io에서 5 개의 장치 슬롯 중 하나를 사용합니다.\n\n당신은 확실합니까?';

  @override
  String get toast_resetting_zrok => 'Zrok 환경을 재설정...';

  @override
  String get toast_zrok_reset_success =>
      'Zrok 환경 리셋. 다시 설정하기 위해 새로운 토큰을 입력하십시오.';

  @override
  String get toast_zrok_reset_partial => '환경 리셋 (토큰 파일은 수동으로 청소가 필요할 수 있습니다)';

  @override
  String toast_zrok_reset_warnings(Object arg1) {
    return '환경 리셋 (주의사항: $arg1)';
  }

  @override
  String get zrok_no_token_configured => '토큰이 설정되지 않았습니다. 설정하기 위해 탭하세요.';

  @override
  String get toast_zrok_token_saved => '저장된 토큰';

  @override
  String get toast_zrok_token_save_failed => '토큰 저장 실패';

  @override
  String get toast_zrok_token_deleted => '지표 삭제';

  @override
  String get toast_zrok_token_delete_failed => '토큰 삭제 실패';

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
  String log_header_truncated(Object arg1) {
    return '참고: 줄여서 10000 라인까지의 로그 (전체: $arg1 라인)';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return '비디오 재생 불가능: $arg1';
  }

  @override
  String get dialog_delete_recording_title => '녹음을 삭제';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '$arg1를 삭제하세요';
  }

  @override
  String get toast_recording_deleted => '녹음 삭제';

  @override
  String get toast_recording_delete_failed => '녹음을 삭제하지 못함';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1는 삭제되었고, $arg2는 실패했습니다.';
  }

  @override
  String get play_with_chooser => '놀아';

  @override
  String setup_version_banner(Object arg1) {
    return 'v$arg1에 업데이트  자동 시작을 다시 확인, BYD는 모든 설치에서 그것을 지워';
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
  String get soh_no_estimate_yet => '아직 추정치 없습니다  자료를 기다리고 있습니다';

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
  String get rail_live => '생생하게';

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
  String get settings_section_recording => '녹음';

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
  String get cd_settings_subrail => '설정 하부 철도';

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
  String get settings_about_open_link_failed => '링크를 열지 못했어요';

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
  String get settings_about_license_value => 'MIT  오픈소스. 전체 텍스트를 보기 위해 누르십시오.';

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
  String get settings_about_star_value => '잠깐만요, 많은 것을 의미하죠';

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
  String get settings_theme_auto => '자동 (따르기 시스템)';

  @override
  String get settings_theme_light => '빛';

  @override
  String get settings_theme_dark => '어둠';

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
  String get recordings_preview_placeholder_title => '녹음을 선택';

  @override
  String get recordings_preview_placeholder_body =>
      '왼쪽에 있는 모든 항목을 누르면 재생할 수 있습니다.';

  @override
  String get diagnostics_section_adb_console => 'ADB 콘솔';

  @override
  String get diagnostics_section_traffic => '교통 모니터';

  @override
  String get diagnostics_section_camera_probe => '카메라 탐사선';

  @override
  String get diagnostics_section_battery => '배터리 건강';

  @override
  String get diagnostics_section_performance => '성능';

  @override
  String get diagnostics_hero_title => '시스템 진단';

  @override
  String get diagnostics_hero_subtitle => '생체 건강, 로그, 그리고 기기의 탐사.';

  @override
  String get diagnostics_health_clear => '모든 것이 정해졌어요';

  @override
  String get diagnostics_health_section => '건강';

  @override
  String get diagnostics_health_network => '네트워크';

  @override
  String get diagnostics_health_storage => '저장';

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
  String diagnostics_storage_used_line(Object arg1, Object arg2) {
    return '$arg1 클립 · $arg2 사용';
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
  String get diagnostics_adb_subtitle => '장치에 연결된 터미널을 열고';

  @override
  String get diagnostics_battery_subtitle => 'SOH 셀을 검사하고 통계를 포장하세요.';

  @override
  String get diagnostics_settings_subtitle => '앱 선호도, 테마, 언어';

  @override
  String get settings_action_reset_data => '데이터 리셋...';

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
  String get dashboard_metric_recordings => '오늘 녹음';

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
  String get dashboard_chip_recording_active => '등기';

  @override
  String get dashboard_chip_recording_idle => '유휴';

  @override
  String get dashboard_vehicle_tap_to_set => '설정하기 위해 탭';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => '배터리 용량을 설정';

  @override
  String get vehicle_dialog_capacity_label => '용량 (kWh)';

  @override
  String get vehicle_dialog_capacity_suffix => 'kWh';

  @override
  String get vehicle_dialog_capacity_helper =>
      '8 ~ 120kWh. 모델 기본값을 사용하려면 그대로 둡니다.';

  @override
  String get vehicle_dialog_model_label => '모델';

  @override
  String get vehicle_dialog_save => '저장';

  @override
  String get vehicle_dialog_reset => '자동 탐지 설정';

  @override
  String get vehicle_dialog_invalid_capacity => '용량은 8 ~ 120 kWh';

  @override
  String vehicle_dialog_summary_capacity(Object arg1) {
    return '용량: $arg1';
  }

  @override
  String vehicle_dialog_summary_soh(Object arg1) {
    return 'SOH: $arg1';
  }

  @override
  String vehicle_dialog_soh_source_live(Object arg1) {
    return '$arg1% (실시간)';
  }

  @override
  String vehicle_dialog_soh_source_calibration(Object arg1) {
    return '$arg1% (마지막 충전 기준)';
  }

  @override
  String vehicle_dialog_soh_source_oem(Object arg1) {
    return '$arg1% (차량)';
  }

  @override
  String vehicle_dialog_soh_source_nominal(Object arg1) {
    return '$arg1% (공칭)';
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
    return '유효성: $arg1 kWh';
  }

  @override
  String vehicle_dialog_summary_model(Object arg1) {
    return '모델: $arg1';
  }

  @override
  String vehicle_dialog_summary_calibration(Object arg1, Object arg2) {
    return '마지막 캘리브레이션: $arg1% $arg2';
  }

  @override
  String get vehicle_dialog_soh_unavailable => '사용할 수 없습니다';

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '사용 된 $arg1 · $arg2 무료';
  }

  @override
  String get dashboard_metric_storage_chip_pending => '저장 ';

  @override
  String get dashboard_tunnel_offline => '오프라인';

  @override
  String get dashboard_tunnel_online => '온라인';

  @override
  String get dashboard_tunnel_connecting => '연결...';

  @override
  String get dashboard_trips_this_week => '이번 주';

  @override
  String dashboard_trips_count(Object arg1) {
    return '$arg1회 주행';
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
  String get dashboard_action_live_subtitle => '카메라 뷰 오픈';

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
  String get settings_hero_subtitle => '외모, 녹음, 감시 및 장치에 있는 데이터를 조정하십시오.';

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
  String get settings_section_surveillance_subtitle => '탐지 구역, 일정, 움직임 감수성';

  @override
  String get settings_section_daemons_subtitle => 'Zrok 터널 및 백그라운드 서비스.';

  @override
  String get settings_about_row_title => 'BladeWatch에 대해';

  @override
  String get settings_about_row_subtitle => '버전, 라이선스, 지원 개발.';

  @override
  String get settings_reset_row_subtitle => '녹음, 사건, 또는 모든 캐시';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle => '테마, 언어, 시각적 선호도';

  @override
  String get settings_theme_active_auto_caption => '자동으로 시스템 테마를 따라갑니다.';

  @override
  String get settings_theme_active_light_caption => '빛의 주제는 항상 켜져 있습니다.';

  @override
  String get settings_theme_active_dark_caption => '어두운 테마는 항상 켜져 있어요.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '사용 가능한 $arg1의 $arg2 언어';
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
  String settings_privacy_storage_count_format(Object arg1) {
    return '$arg1 클립';
  }

  @override
  String settings_privacy_storage_count_format_plural(Object arg1) {
    return '$arg1 클립';
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
  String get diagnostics_camera_value_probing => '탐구...';

  @override
  String get diagnostics_camera_value_offline => '오프라인';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => '대기하는 자료';

  @override
  String dashboard_recordings_value_live(Object arg1) {
    return '● $arg1';
  }

  @override
  String get dashboard_insight_welcome => '환영합니다  오버드라이브는 이제 두 번째 눈입니다.';

  @override
  String dashboard_insight_parked_charged_kwh(Object arg1, Object arg2) {
    return '주차 중 $arg1 (≈$arg2) 를 가져왔습니다';
  }

  @override
  String dashboard_insight_parked_charged(Object arg1) {
    return '주차 중 $arg1를 가져왔어요';
  }

  @override
  String dashboard_insight_parked_drained_kwh(Object arg1, Object arg2) {
    return '주차한 이후로 $arg1 (≈$arg2) 를 사용했어요';
  }

  @override
  String dashboard_insight_parked_drained(Object arg1) {
    return '주차한 이후로 $arg1를 사용했어요';
  }

  @override
  String dashboard_insight_last_alert(Object arg1) {
    return '마지막 감시 경보: $arg1';
  }

  @override
  String dashboard_insight_last_charge(Object arg1, Object arg2) {
    return '마지막 충전: $arg2에서 +$arg1';
  }

  @override
  String dashboard_insight_storage_milestone(Object arg1, Object arg2) {
    return '$arg1 클립 · $arg2 녹음';
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
      other: '오늘 녹음된 $arg1 클립',
      one: '오늘 녹음된 $arg1 클립',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_days_hours(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 일 동안 온라인에서 오버 드라이브, $arg2 hr',
      one: '$arg1 일, $arg2 시간 동안 오프라인 운전',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_hours(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 시간 동안 오프라인 운전',
      one: '$arg1 시간 동안 오버 드라이브 온라인',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_minutes(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 분',
      one: '$arg1 분',
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
  String get vehicle_tab_trunk => '트렁크';

  @override
  String get vehicle_tab_climate => '기후';

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
  String get vehicle_close_trunk => '닫힌 트렁크';

  @override
  String get vehicle_trunk_info_open => '트렁크를 열면 차량 잠금이 먼저 해제됩니다.';

  @override
  String get vehicle_ac_on => 'AC 가동';

  @override
  String get vehicle_ac_off => 'AC 종료';

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
  String get vehicle_seat_pos_1 => '포지션 1';

  @override
  String get vehicle_seat_pos_2 => '포지션 2';

  @override
  String get vehicle_all_windows => '모든 창';

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
  String get vehicle_sunroof => '태양 지붕';

  @override
  String get vehicle_sunshade => '햇빛 보호막';

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
  String get vehicle_tyre_no_signal => '신호가 없습니다';

  @override
  String get vehicle_tyre_slow_leak => '느린 누출';

  @override
  String get vehicle_tyre_fast_leak => '빠른 누출';

  @override
  String get vehicle_tyre_low => '낮은';

  @override
  String get vehicle_tyre_high => '높은';

  @override
  String get vehicle_tyre_ok => '확인';

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
  String get startup_header_verifying => '거의 다 됐어요…';

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
  String get trips_filter_7_days => '7 Days';

  @override
  String get trips_filter_14_days => '14 Days';

  @override
  String get trips_filter_30_days => '30 Days';

  @override
  String trips_load_error(Object message) {
    return '오류: $message';
  }

  @override
  String get trips_empty_state => '아직 기록된 주행이 없습니다';

  @override
  String get trips_period_summary_title => '기간 요약';

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
  String get trips_driver_score_title => '운전자 점수';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Overall: $score / 100';
  }

  @override
  String get trips_range_title => '맞춤 주행 가능 거리';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD estimate: $km km';
  }

  @override
  String get trips_range_no_data => '아직 데이터가 충분하지 않습니다';

  @override
  String get trips_dna_title => '운전 DNA';

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
  String get trips_storage_title => '주행 저장공간';

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
  String get trips_sync_title => '데이터베이스 카탈로그';

  @override
  String get trips_sync_description =>
      'Reconcile the trips index with telemetry files on disk.';

  @override
  String get trips_sync_button => 'Sync Database';

  @override
  String get trips_sync_running => 'Syncing…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return '동기화 성공: +$added -$removed (총 $total건)';
  }

  @override
  String get trips_sync_failed_generic => '동기화 실패';

  @override
  String get trips_detail_summary_title => '주행 요약';

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
  String get trips_detail_scores_title => '운전 점수';

  @override
  String get trips_detail_unavailable => '주행 세부정보를 사용할 수 없습니다';

  @override
  String get trips_detail_loading => '주행 불러오는 중…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count GPS points recorded';
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
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 used / $arg2 limit';
  }

  @override
  String surveillance_storage_files(Object arg1) {
    return '이벤트 $arg1개';
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
}
