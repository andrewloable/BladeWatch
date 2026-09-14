// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      '在背景下保持BladeWatch车辆监测活动. 该服务不会读取或与屏幕内容交互.';

  @override
  String get action_cancel => '取消';

  @override
  String get action_clear_plain => '清除';

  @override
  String get action_select_all => '选择所有';

  @override
  String get action_select_all_short => '全部';

  @override
  String get action_delete => '删除';

  @override
  String get action_done => '完成';

  @override
  String get action_remind_me_later => '稍后提醒';

  @override
  String get action_retry => '重试';

  @override
  String get action_run => '运行';

  @override
  String get action_clear_output => '清除输出';

  @override
  String get cd_camera => '摄像头';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => '二维码';

  @override
  String get cd_show_hide_token => '显示/隐藏标志';

  @override
  String get cd_copy_token => '复制令牌';

  @override
  String get cd_copy_url => '复制 URL';

  @override
  String get cd_clear_logs => '清除日志';

  @override
  String get cd_expand_collapse => '展开/折叠';

  @override
  String get cd_recording_status => '记录状态';

  @override
  String get cd_trip_tracking_status => '旅行跟踪状态';

  @override
  String get cd_video_thumbnail => '视频缩影图';

  @override
  String get cd_play => '播放';

  @override
  String get cd_back => '返回';

  @override
  String get cd_play_pause => '播放/暂停';

  @override
  String get cd_player_prev => '上一个录制';

  @override
  String get cd_player_next => '下一个录制';

  @override
  String get cd_player_maximize => '最大化播放器';

  @override
  String get cd_player_minimize => '退出全屏';

  @override
  String get cd_delete => '删除';

  @override
  String get cd_expand => '展开';

  @override
  String get cd_configure => '配置';

  @override
  String get cd_download_log => '下载日志';

  @override
  String get cd_reset => '重置';

  @override
  String get cd_battery => '电池';

  @override
  String get cd_step_completed => '步骤已完成';

  @override
  String get cd_permission_granted => '授权';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => '旅行';

  @override
  String get log_entry_default_timestamp => '12:34:56';

  @override
  String get log_entry_default_tag => '[TAG]';

  @override
  String get log_entry_default_message => '在此记录消息';

  @override
  String get daemon_card_default_name => '服务名称';

  @override
  String get daemon_card_default_status => '状态信息';

  @override
  String get daemon_card_subprocesses => '进程';

  @override
  String get logs_panel_title => '长木';

  @override
  String get url_connecting => '连接...';

  @override
  String get camera_selection_title => '摄像机的选择';

  @override
  String get camera_selection_subtitle => '选择全景摄像头源';

  @override
  String get camera_current_auto => '当前：自动';

  @override
  String get camera_option_auto => '自动 (启动时检测)';

  @override
  String get camera_option_0 => '摄像头0 Atto剪装';

  @override
  String get camera_option_1 => '摄像头 1 — Seal (默认)';

  @override
  String get camera_option_2 => '摄像头2';

  @override
  String get camera_option_3 => '摄像头3';

  @override
  String get camera_option_4 => '摄像头4';

  @override
  String get camera_option_5 => '摄像头5';

  @override
  String get camera_selection_hint =>
      '每次启动时自动选择适合您车型的摄像头。摄像头1 = BYD Seal，摄像头0 = Atto车型。更改摄像头ID后，请重启摄像头服务使设置生效。';

  @override
  String get dashboard_scan_to_connect => '扫码连接';

  @override
  String get dashboard_qr_waiting => '等待道...';

  @override
  String get dashboard_daemons_running_default => '0/5 运行中';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => '访问代码';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => '复兴标志';

  @override
  String get dashboard_set_password => '设置密码';

  @override
  String get cd_set_password => '设置自定义密码';

  @override
  String get dialog_set_password_title => '设置自定义密码';

  @override
  String get dialog_set_password_message => '请输入新的访问密码。此密码将替换自动生成的令牌。';

  @override
  String get dialog_set_password_hint => '新密码（至少12个字符）';

  @override
  String get toast_password_set => '密码已更新';

  @override
  String get toast_password_too_short => '密码至少需要12个字符';

  @override
  String get toast_password_save_failed => '保存密码失败——服务尚未就绪';

  @override
  String get setup_guide_title => '开始';

  @override
  String get setup_guide_subtitle => '获得最佳体验的三个快速步骤:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => '选择自己的语言';

  @override
  String get setup_language_body => '默认使用车机的语言。点按可为 BladeWatch 应用和网页隧道选择其他语言。';

  @override
  String get setup_language_button => '选择语言';

  @override
  String get setup_autostart_title => '禁用自动启动限制';

  @override
  String get setup_autostart_body =>
      '按下来打开BYD自动启动. 在列表中找到BladeWatch,并打消框.BYD在每次安装时都会擦除它.';

  @override
  String get setup_autostart_button => '开启BYD自动启动';

  @override
  String get setup_overlay_title => '允许在其他应用程序上显示';

  @override
  String get setup_overlay_body => '在其他应用程序上,可显示浮动状态指标,以便记录和跟踪旅行.';

  @override
  String get setup_overlay_button => '打开叠加设置';

  @override
  String get cd_close => '关闭';

  @override
  String get language_picker_title => '语言';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '可用的$arg1语言';
  }

  @override
  String get language_picker_subtitle_pending => '选择一个语言';

  @override
  String get language_auto_title => '汽车';

  @override
  String language_auto_subtitle(Object arg1) {
    return '追踪系统 · $arg1';
  }

  @override
  String get language_not_saved => '语言已应用，但未能保存 — 重启应用后会恢复。';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · 自动';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => '输入命令…';

  @override
  String get adb_preset_commands_header => '预设命令';

  @override
  String get adb_output_header => '输出';

  @override
  String get adb_output_ready => '准备命令...';

  @override
  String get adb_console_hero_title => 'ADB 控制台';

  @override
  String get adb_console_hero_subtitle => '在设备上运行 shell 命令';

  @override
  String get adb_console_unavailable_title => 'ADB 未连接';

  @override
  String get adb_console_unavailable_body =>
      '在此车辆上，仅开发者选项中普通的“USB 调试”开关还不够 —— 中控屏自身的无线 ADB（网络调试）设置也需要开启，而系统更新可能会将其重置。请在中控屏上重新开启无线 ADB，或通过 USB 连接。';

  @override
  String get adb_console_auth_pending_title => '等待授权';

  @override
  String get adb_console_auth_pending_body =>
      '查看中控屏屏幕上的“允许 USB 调试吗？”提示并接受，然后重试。';

  @override
  String get performance_connecting => '正在连接性能监视器…';

  @override
  String get performance_hero_title => '系统性能';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => '系统使用率';

  @override
  String get performance_cpu_app_usage => '应用使用率';

  @override
  String get performance_frequency_label => '频率';

  @override
  String get performance_temperature_label => '温度';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => '内存';

  @override
  String get performance_usage_label => '使用率';

  @override
  String get performance_memory_total => '总计';

  @override
  String get performance_memory_used => '已用';

  @override
  String get performance_memory_app => '应用';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => '应用进程';

  @override
  String get performance_threads_label => '线程数';

  @override
  String get performance_gc_cycles_label => 'GC 次数';

  @override
  String get performance_open_fds_label => '打开的 FD';

  @override
  String get performance_refreshing_footer => '每 3 秒刷新一次';

  @override
  String get webview_loading => '装载...';

  @override
  String get webview_camera_daemon_not_running => '摄像头未运行';

  @override
  String get webview_start_camera_daemon => '请在\"服务\"页面启动摄像头服务以访问此页面。';

  @override
  String get zrok_enable_token_hint => '启用令牌';

  @override
  String get zrok_token_storage_note => '令牌已安全存储，并在应用与后台服务之间共享。';

  @override
  String get zrok_reset_environment => '重置Zrok环境';

  @override
  String get zrok_reset_environment_desc => '移除环境和令牌。您需要用令牌重新启用（会占用一个设备名额）。';

  @override
  String get reset_title => '重置数据';

  @override
  String get reset_subtitle => '按类别清除积累的数据';

  @override
  String get reset_warning => '此操作无法撤销。录像、行程和电池历史记录将被永久删除。';

  @override
  String get reset_cat_trips => '行程';

  @override
  String get reset_cat_trips_desc => '旅程历史,航线,每周/每月的行程';

  @override
  String get reset_cat_soc_history => 'SoC & 12V 历史';

  @override
  String get reset_cat_soc_history_desc => '电源电源样本,充电会议,电压记录';

  @override
  String get reset_cat_soh => 'SOH校准';

  @override
  String get reset_cat_soh_desc => '从BMS中重新检测名额容量,重新种植估计';

  @override
  String get reset_cat_recordings => '录像 (视频)';

  @override
  String get reset_cat_recordings_desc => '在录像文件中的所有MP4';

  @override
  String get reset_cat_sentry_events => '监控活动';

  @override
  String get reset_cat_sentry_events_desc => '监视活动剪辑和JSON侧车';

  @override
  String get reset_cat_proximity => '近距离记录';

  @override
  String get reset_cat_proximity_desc => '雷达触发事件MP4';

  @override
  String get reset_cat_trip_files => '旅行遥测文件';

  @override
  String get reset_cat_trip_files_desc => '每次旅行JSON电磁盘遥测';

  @override
  String get recording_lib_chip_any => '全部';

  @override
  String get recording_lib_chip_person => '人';

  @override
  String get recording_lib_chip_vehicle => '车辆';

  @override
  String get recording_lib_chip_bike => '自行车';

  @override
  String get recording_lib_chip_animal => '动物';

  @override
  String get recording_lib_chip_alert => '警报';

  @override
  String get recording_lib_chip_critical => '关键';

  @override
  String get recording_lib_selected_count_zero => '0 选择';

  @override
  String get recording_lib_no_recordings => '没有录像';

  @override
  String get recording_lib_filter_button => '筛选';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return '筛选 · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => '筛选录像';

  @override
  String get recording_lib_filter_apply => '应用';

  @override
  String get recording_lib_filter_reset => '重置';

  @override
  String get recording_lib_filter_section_what => '对象';

  @override
  String get recording_lib_filter_section_severity => '严重性';

  @override
  String get recording_lib_filter_section_type => '类型';

  @override
  String get recording_lib_chip_type_normal => '正常';

  @override
  String get recording_lib_chip_type_proximity => '邻近度';

  @override
  String get recording_lib_date_today => '今天';

  @override
  String get recording_lib_date_yesterday => '昨天';

  @override
  String recording_lib_clip_count(Object arg1) {
    return '片$arg1';
  }

  @override
  String recording_lib_clip_count_one(Object arg1) {
    return '$arg1剪辑';
  }

  @override
  String get recording_lib_pick_date => '选择日期';

  @override
  String get recording_lib_date_all_days => '所有日期';

  @override
  String get cd_clear_date_filter => '显示所有日子';

  @override
  String get recording_lib_section_morning => '上午';

  @override
  String get recording_lib_section_afternoon => '下午';

  @override
  String get recording_lib_section_evening => '傍晚';

  @override
  String get recording_lib_section_night => '夜间';

  @override
  String get cd_previous_day => '前一天';

  @override
  String get cd_next_day => '第二天';

  @override
  String get cd_open_filters => '打开筛选';

  @override
  String get cd_clear_filter => '清除筛选';

  @override
  String get player_title_recording => '录制';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => '摄像头服务';

  @override
  String get daemon_name_surveillance => '监控服务';

  @override
  String get daemon_name_acc => 'ACC 监控';

  @override
  String get daemon_name_zrok => 'Zrok Tunnel';

  @override
  String get daemons_hero_title => '背景服务';

  @override
  String get daemons_count_pending => '货运服务...';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '运行的$arg1或$arg2';
  }

  @override
  String get battery_health_title => '电池健康';

  @override
  String get battery_health_subtitle => '卫生状况';

  @override
  String get battery_health_dashes => '--';

  @override
  String get battery_health_waiting => '在等待数据...';

  @override
  String get battery_health_source => '来源';

  @override
  String get battery_health_method => '方法';

  @override
  String get battery_health_capacity => '产能';

  @override
  String get battery_health_samples => '样本';

  @override
  String get battery_health_last_updated => '最后更新';

  @override
  String get battery_health_unavailable => '不可用';

  @override
  String get battery_health_unavailable_desc => '此车辆不支持电池健康度估算。';

  @override
  String get battery_health_reset => '重置SOH估计';

  @override
  String get battery_health_reset_desc =>
      '清除所有数据并从零重新估算。如果更换了电池或读数看起来不正确，请使用此功能。';

  @override
  String get soh_dialog_model_label => '车型';

  @override
  String get soh_dialog_pack_capacity_label => '包装容量';

  @override
  String get soh_dialog_estimated_capacity_label => '有效产能';

  @override
  String get soh_dialog_calibration_anchor_label => '最后校准';

  @override
  String get soh_dialog_source_user => '用户组';

  @override
  String get soh_dialog_source_auto => '自动检测';

  @override
  String get soh_dialog_model_not_selected => '没有选择';

  @override
  String get soh_dialog_capacity_not_detected => '没有发现';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '在$arg2上,$arg1%';
  }

  @override
  String get dialog_ok => '确定';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '删除了$arg1录像',
      one: '删除$arg1记录',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '删除$arg1录像',
      one: '删除$arg1录像',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '将永久删除 $arg1 个录像。此操作无法撤销。',
      one: '将永久删除 $arg1 个录像。此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return '应用程序更新 (v$arg1)';
  }

  @override
  String get toast_storage_permission_required => '录像所需的存储许可';

  @override
  String get toast_url_copied_short => '已复制了URL!';

  @override
  String get toast_camera_set_to_auto => '摄像头设置为自动';

  @override
  String get toast_failed_to_save_short => '无法保存';

  @override
  String toast_failed_with_message(Object arg1) {
    return '失败:$arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return '摄像头$arg1设置 下一个ACC周期';
  }

  @override
  String get toast_clearing_camera_config => '清除摄像头配置...';

  @override
  String get toast_restarting_camera_daemon => '正在重启摄像头服务…';

  @override
  String get toast_camera_daemon_restarting => '摄像头服务正在执行完整探测重启';

  @override
  String get toast_camera_restart_failed => '配置已清除，但服务重启失败。请手动重启。';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return '失败:$arg1';
  }

  @override
  String get toast_soh_reset_success => 'SOH估计重置 将从下一个数据中重新计算';

  @override
  String get toast_soh_reset_failed_no_daemon => '重置失败——服务无响应且文件不可写';

  @override
  String toast_soh_reset_failed_with_message(Object arg1) {
    return '重置失败:$arg1';
  }

  @override
  String get toast_select_at_least_one_category => '选择至少一个类别';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return '设置失败:$arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '交通监视器$arg1...';
  }

  @override
  String get dialog_close => '关闭';

  @override
  String get dialog_reset => '重置';

  @override
  String get dialog_delete => '删除';

  @override
  String get dialog_save => '保存';

  @override
  String get dialog_enable => '启用';

  @override
  String get dialog_disable => '停用';

  @override
  String get dialog_keep_enabled => '保持启用';

  @override
  String get dialog_keep_disabled => '保持停用';

  @override
  String get dialog_regenerate => '重新生成';

  @override
  String get dialog_reset_selected => '重置所选项';

  @override
  String get dialog_reset_soh_title => '设置SOH估计?';

  @override
  String get dialog_reset_soh_message =>
      '这将清除所有SOH数据并从零开始强迫重新估计.\n\n如果:\n•电池被更换\n•SOH读取似乎不正确\n•您想重新校准\n\n系统将从下一个可用的数据源 (OEM,充电校准或即时读取) 中重新播放.';

  @override
  String get dialog_reset_following_title => '重置以下项目？';

  @override
  String dialog_reset_following_message(Object arg1) {
    return '此操作无法撤销。\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => '重置完成';

  @override
  String get dialog_traffic_cannot_check_title => '无法检查状态';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB 未连接,应用也无法自动重新连接。\n\n在此车辆上,仅在开发者选项中开启常见的\"USB 调试\"开关是不够的——主机自身的无线 ADB(网络调试)设置也必须开启,系统更新可能会将其重置。请在主机上重新启用无线 ADB,或改用 USB 连接。\n\n连接后,状态将自动更新。';

  @override
  String get dialog_traffic_disable_title => '关闭BYD交通监视器?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) 是内置系统应用，会在后台持续监测道路交通状况。\n\n为什么要禁用？\n\n• 消耗移动数据（即使停车时也是）\n• 在后台占用 CPU 和电量\n• 如果您使用其他导航应用则不需要\n• 可能干扰行车记录仪的网络使用\n\n禁用是安全的：它只影响地图上的内置路况图层。导航、蓝牙和其他所有车辆功能均不受影响。\n\n禁用后需要硬重启（长按中控台按键 5 秒）。';

  @override
  String get dialog_traffic_enable_title => '再启用BYD交通监测器?';

  @override
  String get dialog_traffic_enable_message =>
      '目前,BYD 交通监测器已被禁用.\n\n重新启用将恢复导航地图内置的交通覆盖.请注意,它将在背景中运行并消耗移动数据.\n\n启动后需要硬式重新启动 (保持中心控制台按5秒).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return '交通监视器$arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      '更改已应用。\n\n请立即执行硬重启:\n长按中控台按键 5 秒。';

  @override
  String get traffic_monitor_loading => '交通监视器:检查...';

  @override
  String get traffic_monitor_tap_to_check => '交通监测器 (点击查看)';

  @override
  String get reset_label_trips => '行程';

  @override
  String get reset_label_soc_history => 'SoC + 12V 历史记录';

  @override
  String get reset_label_soh => 'SOH校准';

  @override
  String get reset_label_recordings => '录像';

  @override
  String get reset_label_sentry_events => '监控活动';

  @override
  String get reset_label_proximity => '近距离记录';

  @override
  String get reset_label_trip_files => '旅行遥测文件';

  @override
  String get toast_access_code_copied => '复制访问代码';

  @override
  String get dialog_regenerate_token_title => '复兴标志';

  @override
  String get dialog_regenerate_token_message => '当前令牌将失效。所有活动会话都将被登出。是否继续？';

  @override
  String get toast_token_regenerated_logged_out => '已生成新令牌。所有会话均已登出。';

  @override
  String get toast_token_regenerated_restart => '令牌已重新生成。各服务可能需要重启才能生效。';

  @override
  String get toast_token_regenerated_no_notify => '令牌已重新生成。无法通知后台服务。';

  @override
  String get toast_token_regenerated => '令牌再生';

  @override
  String get dashboard_no_tunnel => '没有道运行';

  @override
  String get dashboard_starting_zrok => '启动Zrok道...';

  @override
  String get dashboard_waiting_url => '等待道URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 运行中';
  }

  @override
  String get tunnel_label_zrok => 'Zrok';

  @override
  String get clip_label_access_code => '访问代码';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return '对于$arg1没有配置';
  }

  @override
  String get dialog_zrok_token_title => 'Zrok道标志';

  @override
  String get dialog_zrok_token_message => '请输入 Zrok 启用令牌。\n获取地址: zrok.io';

  @override
  String get toast_token_cannot_be_empty => '标签不能空';

  @override
  String get dialog_zrok_reset_title => '重置Zrok环境';

  @override
  String get dialog_zrok_reset_message =>
      '此操作将:\n• 停止正在运行的 zrok 隧道\n• 从本设备移除 zrok 环境\n• 删除已保存的令牌\n\n您需要重新输入令牌并重新启用。这会占用您在 zrok.io 上 5 个设备名额中的 1 个。\n\n确定吗？';

  @override
  String get toast_resetting_zrok => '重新设置zrok环境...';

  @override
  String get toast_zrok_reset_success => 'Zrok环境重置. 输入一个新的令牌,重新设置.';

  @override
  String get toast_zrok_reset_partial => '环境重置 (令牌文件可能需要手动清理)';

  @override
  String toast_zrok_reset_warnings(Object arg1) {
    return '环境重置 (附警告:$arg1)';
  }

  @override
  String get zrok_no_token_configured => '未配置令牌。点按进行设置。';

  @override
  String get toast_zrok_token_saved => '存储的令牌';

  @override
  String get toast_zrok_token_save_failed => '未能保存令牌';

  @override
  String get toast_zrok_token_deleted => '删除的标志';

  @override
  String get toast_zrok_token_delete_failed => '未能删除令牌';

  @override
  String toast_fetching_log(Object arg1) {
    return '带来$arg1日志...';
  }

  @override
  String get toast_log_empty_or_missing => '记录文件是空的或没有找到';

  @override
  String get toast_log_empty => '记录文件是空的';

  @override
  String toast_log_save_failed(Object arg1) {
    return '未能保存日志:$arg1';
  }

  @override
  String get toast_log_not_found => '记录文件未找到或不可读';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1日志 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return '分享$arg1日志';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 日志 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return '来源:$arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return '出口:$arg1';
  }

  @override
  String log_header_truncated(Object arg1) {
    return '注:截至10000行的日志 (总数:$arg1行)';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return '无法播放视频:$arg1';
  }

  @override
  String get dialog_delete_recording_title => '删除录像';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '删除 $arg1？\n此操作无法撤销。';
  }

  @override
  String get toast_recording_deleted => '删除记录';

  @override
  String get toast_recording_delete_failed => '无法删除录像';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '已删除$arg1,失败的$arg2';
  }

  @override
  String get play_with_chooser => '玩一下';

  @override
  String setup_version_banner(Object arg1) {
    return '更新到v$arg1 重新确认自动启动,BYD在每次安装时都会擦除它';
  }

  @override
  String get setup_overlay_already_granted => '已授予';

  @override
  String camera_current_manual(Object arg1) {
    return '目前:摄像头$arg1 (手动)';
  }

  @override
  String get camera_current_auto_label => '当前：自动';

  @override
  String get soh_estimation_active => '估计活动';

  @override
  String get soh_oem_readout => '车辆SOH读数——等待估算值';

  @override
  String get soh_nominal_baseline => '标称基准——等待可信SOH数据';

  @override
  String get soh_no_estimate_yet => '尚未估计 等待数据';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '选择$arg1';
  }

  @override
  String get video_player_playback_error => '播放错误';

  @override
  String get video_player_no_events => '没有事件';

  @override
  String get daemon_configuration_required => '需要配置';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => '视频播放器';

  @override
  String get status_overlay_notif_title => 'BladeWatch 状态';

  @override
  String get status_overlay_notif_text => '状态覆盖活动';

  @override
  String get rail_dashboard => '仪表板';

  @override
  String get rail_live => '实时';

  @override
  String get rail_recordings => '录像';

  @override
  String get rail_vehicle => '车辆';

  @override
  String get rail_trips => '行程';

  @override
  String get rail_location => '位置';

  @override
  String get rail_diagnostics => '诊断';

  @override
  String get rail_settings => '设置';

  @override
  String get settings_section_appearance => '外观';

  @override
  String get settings_section_recording => '录制';

  @override
  String get settings_section_surveillance => '监控';

  @override
  String get settings_section_daemons => '服务';

  @override
  String get settings_section_privacy => '隐私与数据';

  @override
  String get settings_section_overlay => '状态覆盖';

  @override
  String get settings_overlay_subtitle => '选择漂浮状态药物的哪些部分保持可见.';

  @override
  String get settings_overlay_camera_title => '摄像头指标';

  @override
  String get settings_overlay_camera_subtitle => '在录像活动期间显示REC/ PROX标志.';

  @override
  String get settings_overlay_trip_title => '指向旅行';

  @override
  String get settings_overlay_trip_subtitle => '在旅行检测正在运行时,请显示TRIP标志.';

  @override
  String get settings_section_about => '关于';

  @override
  String get settings_subrail_overline => '设置';

  @override
  String get cd_settings_subrail => '设置侧栏';

  @override
  String get settings_privacy_title => '隐私与数据';

  @override
  String get settings_privacy_body => '重置将清除录像索引、缓存凭证、服务状态及设备端偏好设置。此操作不可撤销。';

  @override
  String get settings_about_title => '关于BladeWatch';

  @override
  String get settings_about_version_label => '版本';

  @override
  String get settings_about_package_label => '建设';

  @override
  String get settings_about_support_section => '由像你这样的人来推动';

  @override
  String get settings_about_support_share_title => '告诉另一位车主';

  @override
  String get settings_about_support_share_value =>
      '每个共享的链接都能帮助另一个BYD的所有者发现BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      '查看BYD的开源监控和仪表摄像头: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => '分享过度驱动';

  @override
  String get settings_about_open_link_failed => '无法打开链接.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return '没有浏览器. URL复制: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => '在下一个版本中加油';

  @override
  String get settings_about_support_kofi_value => '一杯咖啡让晚上的承诺持续下去.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => '许可证';

  @override
  String get settings_about_license_value => '开源. 点击查看全文.';

  @override
  String get settings_about_source_title => '源代码';

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
  String get settings_about_star_title => '在 GitHub 上放一个';

  @override
  String get settings_about_star_value => '需要一秒钟,这意味着很多.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => '致谢';

  @override
  String get settings_about_thanks_subtitle => '在贡献者和支持者的帮助下打造。';

  @override
  String get settings_about_contributors_title => '贡献者';

  @override
  String get settings_about_supporters_title => '支持者';

  @override
  String get settings_about_thanks_empty => '随着大家加入,这里会被填满。';

  @override
  String get settings_theme_label => '主题';

  @override
  String get settings_theme_auto => '自动（跟随系统）';

  @override
  String get settings_theme_light => '浅色';

  @override
  String get settings_theme_dark => '深色';

  @override
  String get settings_language_label => '语言';

  @override
  String get settings_drive_side_label => '导航位置';

  @override
  String get settings_drive_side_subtitle => '选择导航菜单显示在屏幕的哪一侧。';

  @override
  String get settings_drive_side_left => '左侧';

  @override
  String get settings_drive_side_left_hint => '左舵 · 默认';

  @override
  String get settings_drive_side_right => '右侧';

  @override
  String get settings_drive_side_right_hint => '右舵车辆';

  @override
  String get settings_drive_side_auto => '自动';

  @override
  String get settings_drive_side_auto_hint => '从车辆检测';

  @override
  String get settings_drive_side_caption_left => '导航在左侧';

  @override
  String get settings_drive_side_caption_right => '导航在右侧';

  @override
  String get settings_drive_side_caption_auto_left => '自动——车辆报告为左舵';

  @override
  String get settings_drive_side_caption_auto_right => '自动——车辆报告为右舵';

  @override
  String get settings_drive_side_caption_auto_unknown => '自动——车辆不可用，使用左侧';

  @override
  String get recordings_title => '录像';

  @override
  String get recordings_segment_dashcam => '行车记录';

  @override
  String get recordings_segment_surveillance => '监控';

  @override
  String get recordings_action_settings => '设置';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '今天的$arg1 · $arg2总数 · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return '行车记录 · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return '监控 · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => '选择录像';

  @override
  String get recordings_preview_placeholder_body => '在左边点击任何东西来播放.';

  @override
  String get diagnostics_section_adb_console => 'ADB 控制台';

  @override
  String get diagnostics_section_traffic => '交通监视器';

  @override
  String get diagnostics_section_camera_probe => '摄像头探测器';

  @override
  String get diagnostics_section_battery => '电池健康';

  @override
  String get diagnostics_section_performance => '性能';

  @override
  String get diagnostics_hero_title => '系统诊断';

  @override
  String get diagnostics_hero_subtitle => '现场健康,记录和探测器.';

  @override
  String get diagnostics_health_clear => '一切正常';

  @override
  String get diagnostics_health_section => '运行状况';

  @override
  String get diagnostics_health_network => '网络';

  @override
  String get diagnostics_health_storage => '存储空间';

  @override
  String get diagnostics_health_camera => '摄像头';

  @override
  String get diagnostics_health_battery => '电池';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => '在线';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return '道 · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => '在线';

  @override
  String get diagnostics_tunnel_state_offline => '离线';

  @override
  String get diagnostics_tunnel_state_connecting => '连接中';

  @override
  String get diagnostics_network_mobile => '移动';

  @override
  String get diagnostics_network_ethernet => '以太网';

  @override
  String get diagnostics_network_offline => '离线';

  @override
  String diagnostics_storage_used_line(Object arg1, Object arg2) {
    return '使用的$arg1剪辑 ·$arg2';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '免费的$arg1';
  }

  @override
  String get diagnostics_logs_card_title => '现场活动日志';

  @override
  String get diagnostics_logs_card_subtitle => '从运行服务中流出输出.';

  @override
  String get diagnostics_tools_section => '工具';

  @override
  String get diagnostics_traffic_subtitle => '观看直播网络的吞吐量.';

  @override
  String get diagnostics_camera_probe_subtitle => '检查连接的摄像头流.';

  @override
  String get diagnostics_adb_subtitle => '打开设备上的终端。';

  @override
  String get diagnostics_battery_subtitle => '检查细胞SOH和数据包.';

  @override
  String get diagnostics_settings_subtitle => '应用程序偏好,主题和语言.';

  @override
  String get settings_action_reset_data => '重置数据…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => '守望中';

  @override
  String get dashboard_subtitle_all_systems => '所有系统在线';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '在线提供$arg1的$arg2服务';
  }

  @override
  String get dashboard_subtitle_no_tunnel => '离线远程访问';

  @override
  String get dashboard_metric_recordings => '今天的录像';

  @override
  String get dashboard_metric_storage => '使用的存储';

  @override
  String get dashboard_metric_tunnel => '远程访问';

  @override
  String get dashboard_metric_services => '背景服务';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => '车辆';

  @override
  String get dashboard_chip_recording_active => '录制中';

  @override
  String get dashboard_chip_recording_idle => '空闲';

  @override
  String get dashboard_vehicle_tap_to_set => '点按以设置';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => '设置电池容量';

  @override
  String get vehicle_dialog_capacity_label => '容量 (kWh)';

  @override
  String get vehicle_dialog_capacity_suffix => 'kWh';

  @override
  String get vehicle_dialog_capacity_helper => '8至120 kWh。保留以使用模型默认值。';

  @override
  String get vehicle_dialog_model_label => '车型';

  @override
  String get vehicle_dialog_save => '保存';

  @override
  String get vehicle_dialog_reset => '重置为自动检测';

  @override
  String get vehicle_dialog_invalid_capacity => '容量必须为8-120kWh';

  @override
  String vehicle_dialog_summary_capacity(Object arg1) {
    return '容量:$arg1';
  }

  @override
  String vehicle_dialog_summary_soh(Object arg1) {
    return 'SOH: $arg1';
  }

  @override
  String vehicle_dialog_soh_source_live(Object arg1) {
    return '$arg1%(实时)';
  }

  @override
  String vehicle_dialog_soh_source_calibration(Object arg1) {
    return '$arg1%(上次充电)';
  }

  @override
  String vehicle_dialog_soh_source_oem(Object arg1) {
    return '$arg1%(车辆)';
  }

  @override
  String vehicle_dialog_soh_source_nominal(Object arg1) {
    return '$arg1%(标称)';
  }

  @override
  String get settings_recording_tab_status => '状态';

  @override
  String get settings_recording_tab_capture => '采集';

  @override
  String get settings_recording_tab_quality => '画质';

  @override
  String get settings_recording_tab_storage => '存储';

  @override
  String get settings_recording_status_title => '录制状态';

  @override
  String get settings_recording_status_current_state => '当前状态';

  @override
  String get settings_recording_status_today_count => '今日录制数';

  @override
  String get settings_recording_mode_title => '录制模式（ACC 开启）';

  @override
  String get settings_recording_mode_description => '选择行车时行车记录仪何时录制。';

  @override
  String get settings_recording_mode_none_label => '不录制（默认）';

  @override
  String get settings_recording_mode_none_desc => '不录制 — 监控仍然工作';

  @override
  String get settings_recording_mode_continuous_label => '持续录制';

  @override
  String get settings_recording_mode_continuous_desc => '行车时全程录制';

  @override
  String get settings_recording_mode_drive_label => '行驶模式';

  @override
  String get settings_recording_mode_drive_desc => '仅在车辆行驶时录制';

  @override
  String get settings_recording_mode_proximity_label => '接近守卫';

  @override
  String get settings_recording_mode_proximity_desc => '检测到移动时录制';

  @override
  String get settings_recording_limit_title => '录制时长上限';

  @override
  String get settings_recording_limit_description => '每个文件的最大时长。录制会按此间隔分割为新文件。';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => '录制画质';

  @override
  String get settings_recording_storage_title => '录制存储';

  @override
  String get settings_recording_storage_location_label => '存储位置';

  @override
  String get settings_recording_storage_internal => '内部存储';

  @override
  String get settings_recording_storage_sd_card => 'SD 卡';

  @override
  String get settings_recording_storage_sd_card_na => 'SD 卡（不可用）';

  @override
  String get settings_recording_storage_limit_label => '存储上限 — 达到后自动删除最旧的';

  @override
  String get settings_recording_storage_usage_label => '存储使用量';

  @override
  String get settings_recording_storage_files_label => '文件';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '已用 $arg1 / 上限 $arg2';
  }

  @override
  String settings_recording_storage_files(Object arg1) {
    return '$arg1 个录制';
  }

  @override
  String get settings_recording_storage_path_label => '路径';

  @override
  String get settings_recording_storage_sd_free_label => 'SD 卡可用空间';

  @override
  String get settings_recording_storage_internal_free_label => '内部可用空间';

  @override
  String get settings_recording_format_title => '格式化外部存储';

  @override
  String get settings_recording_format_warning => '将永久擦除 SD 卡或 USB 驱动器上的所有数据。';

  @override
  String get settings_recording_format_confirm => '再次点按 — 所有数据将被擦除';

  @override
  String get settings_recording_format_running => '正在格式化… 请稍候';

  @override
  String get settings_recording_format_button => '格式化 SD 卡 / USB';

  @override
  String get settings_recording_format_no_drive => '未找到可移动存储';

  @override
  String settings_recording_format_success(Object arg1) {
    return '格式化成功。新路径：$arg1';
  }

  @override
  String get settings_recording_sync_title => '数据库目录';

  @override
  String get settings_recording_sync_description => '将录制索引与磁盘上的文件核对。';

  @override
  String get settings_recording_sync_running => '正在同步…';

  @override
  String get settings_recording_sync_button => '同步数据库';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return '已同步：+$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => '同步已在进行中';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return '同步失败：$arg1';
  }

  @override
  String get settings_recording_apply_button => '应用更改';

  @override
  String get settings_recording_dismiss => '关闭';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return '暂不支持启动/停止 $arg1';
  }

  @override
  String get settings_daemons_zrok_configure => '配置';

  @override
  String get settings_daemons_zrok_reset_button => '重置环境';

  @override
  String vehicle_dialog_summary_effective(Object arg1) {
    return '有效:$arg1 kWh';
  }

  @override
  String vehicle_dialog_summary_model(Object arg1) {
    return '车型: $arg1';
  }

  @override
  String vehicle_dialog_summary_calibration(Object arg1, Object arg2) {
    return '最后校准:$arg1% 在$arg2';
  }

  @override
  String get vehicle_dialog_soh_unavailable => '无法获取';

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '使用的$arg1 ·免费的$arg2';
  }

  @override
  String get dashboard_metric_storage_chip_pending => '存储空间 —';

  @override
  String get dashboard_tunnel_offline => '离线';

  @override
  String get dashboard_tunnel_online => '在线';

  @override
  String get dashboard_tunnel_connecting => '连接中…';

  @override
  String get dashboard_trips_this_week => '本周';

  @override
  String dashboard_trips_count(Object arg1) {
    return '$arg1次行程';
  }

  @override
  String dashboard_trips_distance_km(Object arg1) {
    return '$arg1 km';
  }

  @override
  String dashboard_trips_distance_mi(Object arg1) {
    return '$arg1 英里';
  }

  @override
  String dashboard_trips_duration(Object arg1) {
    return '$arg1';
  }

  @override
  String get dashboard_trips_label_trips => '行程';

  @override
  String get dashboard_trips_label_distance => '距离';

  @override
  String get dashboard_trips_label_time => '驾驶时长';

  @override
  String get dashboard_trips_no_data => '本周暂无行程记录';

  @override
  String get dashboard_trips_unavailable => '开始驾驶以查看统计';

  @override
  String get dashboard_trips_loading => '加载中…';

  @override
  String get dashboard_trips_view_all => '查看所有行程';

  @override
  String get dashboard_action_live => '现场视频';

  @override
  String get dashboard_action_live_subtitle => '打开摄像头画面';

  @override
  String get dashboard_action_recordings => '录像';

  @override
  String get dashboard_action_settings => '设置';

  @override
  String get dashboard_action_settings_subtitle => '偏好和关于';

  @override
  String get settings_hero_title => '设置';

  @override
  String get settings_hero_overline => '过度驱动';

  @override
  String get settings_hero_subtitle => '调整外观,录像,监控和设备上的数据.';

  @override
  String get settings_overline_preferences => '预见';

  @override
  String get settings_overline_about_data => '关于 & DATA';

  @override
  String get settings_quick_theme_label => '主题';

  @override
  String get settings_quick_language_label => '语言';

  @override
  String get settings_section_recording_subtitle => '预/后缓冲器,代码,存储限制.';

  @override
  String get settings_section_surveillance_subtitle => '检测区域,时间表,运动敏感性.';

  @override
  String get settings_section_daemons_subtitle => 'Zrok 隧道与后台服务。';

  @override
  String get settings_about_row_title => '关于BladeWatch';

  @override
  String get settings_about_row_subtitle => '版本,许可证,支持开发.';

  @override
  String get settings_reset_row_subtitle => '清晰的录像,事件,或所有隐藏.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle => '的主题,语言和视觉偏好.';

  @override
  String get settings_theme_active_auto_caption => '自动跟随系统主题。';

  @override
  String get settings_theme_active_light_caption => '始终使用浅色主题。';

  @override
  String get settings_theme_active_dark_caption => '始终使用深色主题。';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg2 种语言中有 $arg1 种可用';
  }

  @override
  String get settings_language_card_title => '显示语言';

  @override
  String get settings_privacy_stance_title => '默认的设备上';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch 完全在车机上运行。除了您明确配置的隧道和集成之外，没有任何遥测数据离开您的车辆。';

  @override
  String get settings_privacy_overline_storage => '地方储存';

  @override
  String get settings_privacy_overline_reset => '数据重新设置';

  @override
  String get settings_privacy_storage_clips_label => '磁盘上的剪辑';

  @override
  String get settings_privacy_storage_size_label => '总规模';

  @override
  String get settings_privacy_storage_unavailable => '无法使用';

  @override
  String settings_privacy_storage_count_format(Object arg1) {
    return '$arg1剪辑';
  }

  @override
  String settings_privacy_storage_count_format_plural(Object arg1) {
    return '片$arg1';
  }

  @override
  String get settings_privacy_reset_subtitle => '选择类别：录像、事件、服务配置、缓存遥测数据…';

  @override
  String get settings_developer_overline => '开发者';

  @override
  String get settings_developer_timing_logs_title => '服务计时日志';

  @override
  String get settings_developer_timing_logs_subtitle =>
      '记录服务启动期间的耗时标记。正常使用时请关闭以保持 logcat 整洁。';

  @override
  String get settings_developer_debug_logs_title => '开发者调试日志';

  @override
  String get settings_developer_debug_logs_subtitle =>
      '将所有Activity和Fragment生命周期事件及启动步骤记录到/storage/emulated/0/BladeWatch/data/debug_app.log。崩溃信息始终会被捕获。默认关闭。';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return '摄像头$arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return '摄像头$arg1 (手动)';
  }

  @override
  String get diagnostics_camera_value_probing => '探测中…';

  @override
  String get diagnostics_camera_value_offline => '离线';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => '待定数据';

  @override
  String dashboard_recordings_value_live(Object arg1) {
    return '● $arg1';
  }

  @override
  String get dashboard_insight_welcome => '欢迎您 过度驱动是您的第二双眼睛.';

  @override
  String dashboard_insight_parked_charged_kwh(Object arg1, Object arg2) {
    return '在停车时拿到$arg1 (≈$arg2)';
  }

  @override
  String dashboard_insight_parked_charged(Object arg1) {
    return '在停车时拿到$arg1';
  }

  @override
  String dashboard_insight_parked_drained_kwh(Object arg1, Object arg2) {
    return '自从你停车以来,一直使用$arg1 (≈$arg2)';
  }

  @override
  String dashboard_insight_parked_drained(Object arg1) {
    return '自从你停车以来,一直使用$arg1';
  }

  @override
  String dashboard_insight_last_alert(Object arg1) {
    return '最后的监控警报:$arg1';
  }

  @override
  String dashboard_insight_last_charge(Object arg1, Object arg2) {
    return '最后的电荷:$arg2中的$arg1';
  }

  @override
  String dashboard_insight_storage_milestone(Object arg1, Object arg2) {
    return '记录的$arg1剪辑 · 记录的$arg2';
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
    return '时间:$arg1小时$arg2分钟';
  }

  @override
  String dashboard_insight_today_clips(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '今天录制的$arg1片段',
      one: '今天录制的$arg1片段',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_days_hours(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '在线开车$arg1天,$arg2小时',
      one: '在线开车$arg1天,$arg2小时',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_hours(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '在线开车$arg1小时',
      one: '在$arg1小时上网过车',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_minutes(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 min',
      one: '$arg1 min',
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
  String get vehicle_tab_trunk => '后备箱';

  @override
  String get vehicle_tab_climate => '空调';

  @override
  String get vehicle_tab_seats => '座椅';

  @override
  String get vehicle_tab_windows => '车窗';

  @override
  String get vehicle_tab_lights => '灯光';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => '充电';

  @override
  String get vehicle_locked => '锁定';

  @override
  String get vehicle_unlocked => '已解锁';

  @override
  String get vehicle_range_label => '续航';

  @override
  String get vehicle_data_unavailable => '车辆数据不可用。';

  @override
  String get vehicle_action_failed => '操作失败。请检查车辆连接。';

  @override
  String get vehicle_open_trunk => '打开后备箱';

  @override
  String get vehicle_close_trunk => '关闭后备箱';

  @override
  String get vehicle_trunk_info_open => '打开后备箱将先解锁车辆。';

  @override
  String get vehicle_ac_on => 'AC 开启';

  @override
  String get vehicle_ac_off => 'AC 关闭';

  @override
  String get vehicle_max_cooling_on => '最大制冷：开';

  @override
  String get vehicle_max_cooling_off => '最大制冷：关';

  @override
  String get vehicle_temp_label => '温度';

  @override
  String get vehicle_fan_speed_label => '风量';

  @override
  String vehicle_fan_level(Object arg1) {
    return '$arg1档';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return '车内：$arg1°C';
  }

  @override
  String get vehicle_seat_driver => '主驾';

  @override
  String get vehicle_seat_passenger => '副驾';

  @override
  String get vehicle_seat_no_controls => '此车辆无可用的座椅控制。';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return '加热 $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return '通风 $arg1';
  }

  @override
  String get vehicle_heat_off => '（关）';

  @override
  String get vehicle_heat_low => '（低）';

  @override
  String get vehicle_heat_high => '（高）';

  @override
  String get vehicle_seat_pos_1 => '位置1';

  @override
  String get vehicle_seat_pos_2 => '位置 2';

  @override
  String get vehicle_all_windows => '所有车窗';

  @override
  String get vehicle_window_front_left => '左前';

  @override
  String get vehicle_window_front_right => '右前';

  @override
  String get vehicle_window_rear_left => '左后';

  @override
  String get vehicle_window_rear_right => '右后';

  @override
  String get vehicle_window_close => '关闭';

  @override
  String get vehicle_window_close_vent => '关闭通风';

  @override
  String get vehicle_window_vent_12 => '通风 12%';

  @override
  String get vehicle_window_open_all => '全部打开';

  @override
  String get vehicle_sunroof => '天窗';

  @override
  String get vehicle_sunshade => '遮阳帘';

  @override
  String get vehicle_btn_drl_title => '白天运行灯';

  @override
  String get vehicle_btn_slw_title => '预警速度限制';

  @override
  String get vehicle_control_section_charge_cap => '充电上限';

  @override
  String get vehicle_charge_cap_not_supported => '此车辆不支持充电上限。';

  @override
  String get vehicle_charge_limit_label => '充电限制';

  @override
  String get vehicle_enable_charge_limit => '启用充电限制';

  @override
  String get vehicle_charge_limit_range => '最低50%，最高100%';

  @override
  String get vehicle_tyre_no_signal => '无信号';

  @override
  String get vehicle_tyre_slow_leak => '缓慢漏气';

  @override
  String get vehicle_tyre_fast_leak => '快速漏气';

  @override
  String get vehicle_tyre_low => '偏低';

  @override
  String get vehicle_tyre_high => '偏高';

  @override
  String get vehicle_tyre_ok => '正常';

  @override
  String get vehicle_tyre_check_pressure => '检查胎压';

  @override
  String get vehicle_toggle_on => '开';

  @override
  String get vehicle_toggle_off => '关';

  @override
  String get vehicle_err_climate_control => '空调控制失败。';

  @override
  String get vehicle_err_max_cooling => '最大制冷失败。';

  @override
  String get vehicle_err_drl_control => '日间行车灯控制失败。';

  @override
  String get vehicle_err_slw_control => 'ADAS控制失败。';

  @override
  String get vehicle_err_charge_limit_toggle => '充电限制切换失败。';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return '降低 $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return '提高 $arg1';
  }

  @override
  String get vehicle_stale_connecting => '连接中…';

  @override
  String get vehicle_appearance_model_title => '选择车型';

  @override
  String get vehicle_appearance_custom_color => '自定义颜色';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return '电量：$arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return '续航：$arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => '电量：—';

  @override
  String get vehicle_status_range_unknown => '续航：—';

  @override
  String get startup_subtitle => '正在准备您的行车记录仪';

  @override
  String get startup_header_preparing => '正在准备…';

  @override
  String get startup_header_starting => '正在启动…';

  @override
  String get startup_header_verifying => '即将就绪…';

  @override
  String get startup_header_ready => '一切就绪';

  @override
  String get startup_daemon_camera => '摄像头';

  @override
  String get startup_daemon_camera_desc => '实时画面与录制';

  @override
  String get startup_daemon_sentry => '哨兵模式';

  @override
  String get startup_daemon_sentry_desc => '运动检测与警报';

  @override
  String get startup_daemon_parking => '驻车守护';

  @override
  String get startup_daemon_parking_desc => '驻车期间持续监控';

  @override
  String get startup_status_waiting => '等待中';

  @override
  String get startup_status_starting => '启动中';

  @override
  String get startup_status_ready => '就绪';

  @override
  String get startup_status_failed => '失败';

  @override
  String get startup_continue_anyway => '仍然继续';

  @override
  String get startup_continue => '继续 →';

  @override
  String get live_retry => '重试';

  @override
  String get live_connecting => '正在连接摄像头…';

  @override
  String live_error_fmt(Object arg1) {
    return '错误：$arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return '摄像头不可用\n$arg1';
  }

  @override
  String get live_direction_all => '全部';

  @override
  String get live_direction_front => '前';

  @override
  String get live_direction_right => '右';

  @override
  String get live_direction_rear => '后';

  @override
  String get live_direction_left => '左';

  @override
  String get trip_no_route_data => '此行程无路线数据';

  @override
  String get trips_tab_trips => '行程';

  @override
  String get trips_tab_stats => '统计';

  @override
  String get trips_tab_storage => '存储';

  @override
  String get trips_filter_7_days => '7 天';

  @override
  String get trips_filter_14_days => '14 天';

  @override
  String get trips_filter_30_days => '30 天';

  @override
  String trips_load_error(Object message) {
    return '错误：$message';
  }

  @override
  String get trips_empty_state => '尚未记录任何行程';

  @override
  String get trips_period_summary_title => '周期摘要';

  @override
  String get trips_stat_trips => '行程';

  @override
  String get trips_stat_hours => '小时';

  @override
  String get trips_stat_efficiency => '效率';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return '评分：$score';
  }

  @override
  String get trips_driver_score_title => '驾驶评分';

  @override
  String trips_driver_score_overall(Object score) {
    return '总分：$score / 100';
  }

  @override
  String get trips_range_title => '个性化续航';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD 估算：$km 公里';
  }

  @override
  String get trips_range_no_data => '数据尚不足';

  @override
  String get trips_dna_title => '驾驶 DNA';

  @override
  String get trips_dna_anticipation => '预判';

  @override
  String get trips_dna_smoothness => '平顺度';

  @override
  String get trips_dna_speed_discipline => '速度遵守';

  @override
  String get trips_dna_efficiency => '效率';

  @override
  String get trips_dna_consistency => '稳定性';

  @override
  String get trips_storage_title => '行程存储';

  @override
  String get trips_storage_analytics_label => '行程分析';

  @override
  String get trips_storage_rate_label => '电价';

  @override
  String get trips_storage_distance_unit_label => '距离单位';

  @override
  String get trips_storage_location_label => '存储位置';

  @override
  String get trips_storage_internal => '内部存储';

  @override
  String get trips_storage_sd_card => 'SD 卡';

  @override
  String get trips_storage_sd_card_unavailable => 'SD 卡（不可用）';

  @override
  String get trips_storage_apply => '应用更改';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '已用 $used $unit / 上限 $limit MB · $count 次行程';
  }

  @override
  String get trips_sync_title => '数据库目录';

  @override
  String get trips_sync_description => '将行程索引与磁盘上的遥测文件核对。';

  @override
  String get trips_sync_button => '同步数据库';

  @override
  String get trips_sync_running => '正在同步…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return '同步成功：+$added -$removed（共 $total 条）';
  }

  @override
  String get trips_sync_failed_generic => '同步失败';

  @override
  String get trips_detail_summary_title => '行程摘要';

  @override
  String get trips_detail_distance => '距离';

  @override
  String get trips_detail_duration => '时长';

  @override
  String get trips_detail_energy => '能耗';

  @override
  String get trips_detail_avg_speed => '平均速度';

  @override
  String get trips_detail_max_speed => '最高速度';

  @override
  String get trips_detail_soc => '电量';

  @override
  String get trips_detail_cost => '费用';

  @override
  String get trips_detail_ext_temp => '外部温度';

  @override
  String get trips_detail_elev_gain => '爬升高度';

  @override
  String get trips_detail_scores_title => '驾驶评分';

  @override
  String get trips_detail_unavailable => '行程详情不可用';

  @override
  String get trips_detail_loading => '正在加载行程…';

  @override
  String trips_detail_route_points(Object count) {
    return '已记录 $count 个 GPS 点';
  }

  @override
  String get rec_severity_critical => '严重';

  @override
  String get rec_severity_alert => '警报';

  @override
  String get location_loading_title => '正在加载地图';

  @override
  String get location_permission_missing_title => '需要位置权限';

  @override
  String get location_permission_denied_title => '权限被拒绝';

  @override
  String get location_provider_disabled_title => 'GPS 已禁用';

  @override
  String get location_waiting_for_fix_title => '正在等待 GPS 信号';

  @override
  String get location_car_location_title => '车辆位置';

  @override
  String get location_stale_title => '位置信息已过期';

  @override
  String get location_tile_failure_title => '地图不可用';

  @override
  String get location_tile_failure_subtitle => '网络不可用';

  @override
  String get location_error_title => '位置错误';

  @override
  String get location_action_grant => '授予';

  @override
  String get location_action_retry => '重试';

  @override
  String get location_mode_auto => '自动';

  @override
  String get location_mode_light => '浅色';

  @override
  String get location_mode_dark => '深色';

  @override
  String get cd_recenter_on_car => '重新居中到车辆';

  @override
  String get recording_lib_no_recordings_normal => '没有普通录像';

  @override
  String get recording_lib_no_recordings_sentry => '没有哨兵事件';

  @override
  String get recording_lib_no_recordings_proximity => '没有距离事件';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => '人';

  @override
  String get video_player_legend_car => '车';

  @override
  String get video_player_legend_bike => '自行车';

  @override
  String get video_player_legend_motion => '运动';

  @override
  String get recording_lib_proximity_very_close => '非常近';

  @override
  String get recording_lib_proximity_close => '近';

  @override
  String get recording_lib_proximity_mid => '中等';

  @override
  String get recording_lib_proximity_far => '远';

  @override
  String get surveillance_tab_general => '常规';

  @override
  String get surveillance_tab_detection => '检测';

  @override
  String get surveillance_tab_recording => '录制';

  @override
  String get surveillance_tab_storage => '存储';

  @override
  String get surveillance_tab_advanced => '高级';

  @override
  String get surveillance_general_title => '监控模式';

  @override
  String get surveillance_general_enable => '启用监控';

  @override
  String get surveillance_general_status => '状态';

  @override
  String get surveillance_general_status_running => '运行中';

  @override
  String get surveillance_general_status_idle => '空闲';

  @override
  String get surveillance_general_events_today => '今日事件';

  @override
  String get surveillance_safe_locations_title => '安全位置';

  @override
  String get surveillance_safe_locations_subtitle => '停在此处时摄像头不会启动';

  @override
  String get surveillance_safe_locations_enable => '在安全位置停用';

  @override
  String get surveillance_safe_locations_empty => '尚未添加安全位置';

  @override
  String get surveillance_safe_locations_add_current => '将当前位置添加为安全区域';

  @override
  String get surveillance_safe_locations_no_gps => 'GPS 位置不可用';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_roi_title => '侦测区域';

  @override
  String get surveillance_roi_description => '点按添加顶点，拖动可移动顶点。最少三个，最多八个。';

  @override
  String get surveillance_roi_enable => '仅在此区域内侦测';

  @override
  String get action_undo => '撤销';

  @override
  String get surveillance_detection_title => '检测设置';

  @override
  String get surveillance_detection_preset_label => '环境预设';

  @override
  String get surveillance_preset_outdoor => '户外';

  @override
  String get surveillance_preset_garage => '车库';

  @override
  String get surveillance_preset_street => '街道';

  @override
  String get surveillance_preset_custom => '自定义';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return '灵敏度（1=严格，5=灵敏）：$arg1';
  }

  @override
  String get surveillance_detection_objects_label => '检测对象';

  @override
  String get surveillance_detection_object_person => '人';

  @override
  String get surveillance_detection_object_car => '车';

  @override
  String get surveillance_detection_object_bike => '自行车';

  @override
  String get surveillance_recording_title => '事件录制';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return '事件前预录（秒）：$arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return '事件后续录（秒）：$arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => '监控存储';

  @override
  String get surveillance_storage_location_label => '存储位置';

  @override
  String get surveillance_storage_internal => '内部';

  @override
  String get surveillance_storage_sd_card => 'SD 卡';

  @override
  String get surveillance_storage_sd_card_na => 'SD 卡（不可用）';

  @override
  String get surveillance_storage_limit_label => '存储上限 — 达到上限时自动删除最旧的文件';

  @override
  String get surveillance_storage_usage_label => '存储使用量';

  @override
  String get surveillance_storage_files_label => '文件';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '已用 $arg1 / 上限 $arg2';
  }

  @override
  String surveillance_storage_files(Object arg1) {
    return '$arg1 个事件';
  }

  @override
  String get surveillance_storage_path_label => '路径';

  @override
  String get surveillance_format_title => '格式化外部驱动器';

  @override
  String get surveillance_format_warning => '将永久清除 SD 卡或 U 盘上的所有数据。';

  @override
  String get surveillance_format_button => '格式化 SD 卡/USB';

  @override
  String get surveillance_format_confirm => '再次点按 — 所有数据将被清除';

  @override
  String get surveillance_format_running => '正在格式化…请稍候';

  @override
  String get surveillance_dismiss => '关闭';

  @override
  String get surveillance_sync_title => '数据库目录';

  @override
  String get surveillance_sync_description => '将监控索引与磁盘上的文件进行核对。';

  @override
  String get surveillance_sync_button => '同步数据库';

  @override
  String get surveillance_sync_running => '正在同步…';

  @override
  String get surveillance_advanced_camera_title => '摄像头选择';

  @override
  String get surveillance_advanced_camera_front => '前';

  @override
  String get surveillance_advanced_camera_right => '右';

  @override
  String get surveillance_advanced_camera_rear => '后';

  @override
  String get surveillance_advanced_camera_left => '左';

  @override
  String get surveillance_advanced_ai_title => 'AI 与威慑';

  @override
  String get surveillance_advanced_ai_detection => 'AI 检测';

  @override
  String get surveillance_advanced_night_mode => '夜间模式';

  @override
  String get surveillance_advanced_deterrent_label => '威慑动作';

  @override
  String get surveillance_deterrent_silent => '静音';

  @override
  String get surveillance_deterrent_horn => '喇叭';

  @override
  String get surveillance_deterrent_flash => '闪光';

  @override
  String get surveillance_apply_button => '应用更改';

  @override
  String get surveillance_apply_failed => '保存失败';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      '在背景下保持BladeWatch车辆监测活动. 该服务不会读取或与屏幕内容交互.';

  @override
  String get action_cancel => '取消';

  @override
  String get action_clear_plain => '清除';

  @override
  String get action_select_all => '选择所有';

  @override
  String get action_select_all_short => '全部';

  @override
  String get action_delete => '删除';

  @override
  String get action_done => '完成';

  @override
  String get action_remind_me_later => '稍后提醒';

  @override
  String get action_retry => '重试';

  @override
  String get action_run => '运行';

  @override
  String get action_clear_output => '清除输出';

  @override
  String get cd_camera => '摄像头';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => '二维码';

  @override
  String get cd_show_hide_token => '显示/隐藏标志';

  @override
  String get cd_copy_token => '复制令牌';

  @override
  String get cd_copy_url => '复制 URL';

  @override
  String get cd_clear_logs => '清除日志';

  @override
  String get cd_expand_collapse => '展开/折叠';

  @override
  String get cd_recording_status => '记录状态';

  @override
  String get cd_trip_tracking_status => '旅行跟踪状态';

  @override
  String get cd_video_thumbnail => '视频缩影图';

  @override
  String get cd_play => '播放';

  @override
  String get cd_back => '返回';

  @override
  String get cd_play_pause => '播放/暂停';

  @override
  String get cd_player_prev => '上一个录制';

  @override
  String get cd_player_next => '下一个录制';

  @override
  String get cd_player_maximize => '最大化播放器';

  @override
  String get cd_player_minimize => '退出全屏';

  @override
  String get cd_delete => '删除';

  @override
  String get cd_expand => '展开';

  @override
  String get cd_configure => '配置';

  @override
  String get cd_download_log => '下载日志';

  @override
  String get cd_reset => '重置';

  @override
  String get cd_battery => '电池';

  @override
  String get cd_step_completed => '步骤已完成';

  @override
  String get cd_permission_granted => '授权';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => '旅行';

  @override
  String get log_entry_default_timestamp => '12:34:56';

  @override
  String get log_entry_default_tag => '[TAG]';

  @override
  String get log_entry_default_message => '在此记录消息';

  @override
  String get daemon_card_default_name => '服务名称';

  @override
  String get daemon_card_default_status => '状态信息';

  @override
  String get daemon_card_subprocesses => '进程';

  @override
  String get logs_panel_title => '长木';

  @override
  String get url_connecting => '连接...';

  @override
  String get camera_selection_title => '摄像机的选择';

  @override
  String get camera_selection_subtitle => '选择全景摄像头源';

  @override
  String get camera_current_auto => '当前：自动';

  @override
  String get camera_option_auto => '自动 (启动时检测)';

  @override
  String get camera_option_0 => '摄像头0 Atto剪装';

  @override
  String get camera_option_1 => '摄像头 1 — Seal (默认)';

  @override
  String get camera_option_2 => '摄像头2';

  @override
  String get camera_option_3 => '摄像头3';

  @override
  String get camera_option_4 => '摄像头4';

  @override
  String get camera_option_5 => '摄像头5';

  @override
  String get camera_selection_hint =>
      '每次启动时自动选择适合您车型的摄像头。摄像头1 = BYD Seal，摄像头0 = Atto车型。更改摄像头ID后，请重启摄像头服务使设置生效。';

  @override
  String get dashboard_scan_to_connect => '扫码连接';

  @override
  String get dashboard_qr_waiting => '等待道...';

  @override
  String get dashboard_daemons_running_default => '0/5 运行中';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => '访问代码';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => '复兴标志';

  @override
  String get dashboard_set_password => '设置密码';

  @override
  String get cd_set_password => '设置自定义密码';

  @override
  String get dialog_set_password_title => '设置自定义密码';

  @override
  String get dialog_set_password_message => '请输入新的访问密码。此密码将替换自动生成的令牌。';

  @override
  String get dialog_set_password_hint => '新密码（至少12个字符）';

  @override
  String get toast_password_set => '密码已更新';

  @override
  String get toast_password_too_short => '密码至少需要12个字符';

  @override
  String get toast_password_save_failed => '保存密码失败——服务尚未就绪';

  @override
  String get setup_guide_title => '开始';

  @override
  String get setup_guide_subtitle => '获得最佳体验的三个快速步骤:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => '选择自己的语言';

  @override
  String get setup_language_body => '默认使用车机的语言。点按可为 BladeWatch 应用和网页隧道选择其他语言。';

  @override
  String get setup_language_button => '选择语言';

  @override
  String get setup_autostart_title => '禁用自动启动限制';

  @override
  String get setup_autostart_body =>
      '按下来打开BYD自动启动. 在列表中找到BladeWatch,并打消框.BYD在每次安装时都会擦除它.';

  @override
  String get setup_autostart_button => '开启BYD自动启动';

  @override
  String get setup_overlay_title => '允许在其他应用程序上显示';

  @override
  String get setup_overlay_body => '在其他应用程序上,可显示浮动状态指标,以便记录和跟踪旅行.';

  @override
  String get setup_overlay_button => '打开叠加设置';

  @override
  String get cd_close => '关闭';

  @override
  String get language_picker_title => '语言';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '可用的$arg1语言';
  }

  @override
  String get language_picker_subtitle_pending => '选择一个语言';

  @override
  String get language_auto_title => '汽车';

  @override
  String language_auto_subtitle(Object arg1) {
    return '追踪系统 · $arg1';
  }

  @override
  String get language_not_saved => '语言已应用，但未能保存 — 重启应用后会恢复。';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · 自动';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => '输入命令…';

  @override
  String get adb_preset_commands_header => '预设命令';

  @override
  String get adb_output_header => '输出';

  @override
  String get adb_output_ready => '准备命令...';

  @override
  String get adb_console_hero_title => 'ADB 控制台';

  @override
  String get adb_console_hero_subtitle => '在设备上运行 shell 命令';

  @override
  String get adb_console_unavailable_title => 'ADB 未连接';

  @override
  String get adb_console_unavailable_body =>
      '在此车辆上，仅开发者选项中普通的“USB 调试”开关还不够 —— 中控屏自身的无线 ADB（网络调试）设置也需要开启，而系统更新可能会将其重置。请在中控屏上重新开启无线 ADB，或通过 USB 连接。';

  @override
  String get adb_console_auth_pending_title => '等待授权';

  @override
  String get adb_console_auth_pending_body =>
      '查看中控屏屏幕上的“允许 USB 调试吗？”提示并接受，然后重试。';

  @override
  String get performance_connecting => '正在连接性能监视器…';

  @override
  String get performance_hero_title => '系统性能';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => '系统使用率';

  @override
  String get performance_cpu_app_usage => '应用使用率';

  @override
  String get performance_frequency_label => '频率';

  @override
  String get performance_temperature_label => '温度';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => '内存';

  @override
  String get performance_usage_label => '使用率';

  @override
  String get performance_memory_total => '总计';

  @override
  String get performance_memory_used => '已用';

  @override
  String get performance_memory_app => '应用';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => '应用进程';

  @override
  String get performance_threads_label => '线程数';

  @override
  String get performance_gc_cycles_label => 'GC 次数';

  @override
  String get performance_open_fds_label => '打开的 FD';

  @override
  String get performance_refreshing_footer => '每 3 秒刷新一次';

  @override
  String get webview_loading => '装载...';

  @override
  String get webview_camera_daemon_not_running => '摄像头未运行';

  @override
  String get webview_start_camera_daemon => '请在\"服务\"页面启动摄像头服务以访问此页面。';

  @override
  String get zrok_enable_token_hint => '启用令牌';

  @override
  String get zrok_token_storage_note => '令牌已安全存储，并在应用与后台服务之间共享。';

  @override
  String get zrok_reset_environment => '重置Zrok环境';

  @override
  String get zrok_reset_environment_desc => '移除环境和令牌。您需要用令牌重新启用（会占用一个设备名额）。';

  @override
  String get reset_title => '重置数据';

  @override
  String get reset_subtitle => '按类别清除积累的数据';

  @override
  String get reset_warning => '此操作无法撤销。录像、行程和电池历史记录将被永久删除。';

  @override
  String get reset_cat_trips => '行程';

  @override
  String get reset_cat_trips_desc => '旅程历史,航线,每周/每月的行程';

  @override
  String get reset_cat_soc_history => 'SoC & 12V 历史';

  @override
  String get reset_cat_soc_history_desc => '电源电源样本,充电会议,电压记录';

  @override
  String get reset_cat_soh => 'SOH校准';

  @override
  String get reset_cat_soh_desc => '从BMS中重新检测名额容量,重新种植估计';

  @override
  String get reset_cat_recordings => '录像 (视频)';

  @override
  String get reset_cat_recordings_desc => '在录像文件中的所有MP4';

  @override
  String get reset_cat_sentry_events => '监控活动';

  @override
  String get reset_cat_sentry_events_desc => '监视活动剪辑和JSON侧车';

  @override
  String get reset_cat_proximity => '近距离记录';

  @override
  String get reset_cat_proximity_desc => '雷达触发事件MP4';

  @override
  String get reset_cat_trip_files => '旅行遥测文件';

  @override
  String get reset_cat_trip_files_desc => '每次旅行JSON电磁盘遥测';

  @override
  String get recording_lib_chip_any => '全部';

  @override
  String get recording_lib_chip_person => '人';

  @override
  String get recording_lib_chip_vehicle => '车辆';

  @override
  String get recording_lib_chip_bike => '自行车';

  @override
  String get recording_lib_chip_animal => '动物';

  @override
  String get recording_lib_chip_alert => '警报';

  @override
  String get recording_lib_chip_critical => '关键';

  @override
  String get recording_lib_selected_count_zero => '0 选择';

  @override
  String get recording_lib_no_recordings => '没有录像';

  @override
  String get recording_lib_filter_button => '筛选';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return '筛选 · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => '筛选录像';

  @override
  String get recording_lib_filter_apply => '应用';

  @override
  String get recording_lib_filter_reset => '重置';

  @override
  String get recording_lib_filter_section_what => '对象';

  @override
  String get recording_lib_filter_section_severity => '严重性';

  @override
  String get recording_lib_filter_section_type => '类型';

  @override
  String get recording_lib_chip_type_normal => '正常';

  @override
  String get recording_lib_chip_type_proximity => '邻近度';

  @override
  String get recording_lib_date_today => '今天';

  @override
  String get recording_lib_date_yesterday => '昨天';

  @override
  String recording_lib_clip_count(Object arg1) {
    return '片$arg1';
  }

  @override
  String recording_lib_clip_count_one(Object arg1) {
    return '$arg1剪辑';
  }

  @override
  String get recording_lib_pick_date => '选择日期';

  @override
  String get recording_lib_date_all_days => '所有日期';

  @override
  String get cd_clear_date_filter => '显示所有日子';

  @override
  String get recording_lib_section_morning => '上午';

  @override
  String get recording_lib_section_afternoon => '下午';

  @override
  String get recording_lib_section_evening => '傍晚';

  @override
  String get recording_lib_section_night => '夜间';

  @override
  String get cd_previous_day => '前一天';

  @override
  String get cd_next_day => '第二天';

  @override
  String get cd_open_filters => '打开筛选';

  @override
  String get cd_clear_filter => '清除筛选';

  @override
  String get player_title_recording => '录制';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => '摄像头服务';

  @override
  String get daemon_name_surveillance => '监控服务';

  @override
  String get daemon_name_acc => 'ACC 监控';

  @override
  String get daemon_name_zrok => 'Zrok Tunnel';

  @override
  String get daemons_hero_title => '背景服务';

  @override
  String get daemons_count_pending => '货运服务...';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '运行的$arg1或$arg2';
  }

  @override
  String get battery_health_title => '电池健康';

  @override
  String get battery_health_subtitle => '卫生状况';

  @override
  String get battery_health_dashes => '--';

  @override
  String get battery_health_waiting => '在等待数据...';

  @override
  String get battery_health_source => '来源';

  @override
  String get battery_health_method => '方法';

  @override
  String get battery_health_capacity => '产能';

  @override
  String get battery_health_samples => '样本';

  @override
  String get battery_health_last_updated => '最后更新';

  @override
  String get battery_health_unavailable => '不可用';

  @override
  String get battery_health_unavailable_desc => '此车辆不支持电池健康度估算。';

  @override
  String get battery_health_reset => '重置SOH估计';

  @override
  String get battery_health_reset_desc =>
      '清除所有数据并从零重新估算。如果更换了电池或读数看起来不正确，请使用此功能。';

  @override
  String get soh_dialog_model_label => '车型';

  @override
  String get soh_dialog_pack_capacity_label => '包装容量';

  @override
  String get soh_dialog_estimated_capacity_label => '有效产能';

  @override
  String get soh_dialog_calibration_anchor_label => '最后校准';

  @override
  String get soh_dialog_source_user => '用户组';

  @override
  String get soh_dialog_source_auto => '自动检测';

  @override
  String get soh_dialog_model_not_selected => '没有选择';

  @override
  String get soh_dialog_capacity_not_detected => '没有发现';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '在$arg2上,$arg1%';
  }

  @override
  String get dialog_ok => '确定';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '删除了$arg1录像',
      one: '删除$arg1记录',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '删除$arg1录像',
      one: '删除$arg1录像',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '将永久删除 $arg1 个录像。此操作无法撤销。',
      one: '将永久删除 $arg1 个录像。此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return '应用程序更新 (v$arg1)';
  }

  @override
  String get toast_storage_permission_required => '录像所需的存储许可';

  @override
  String get toast_url_copied_short => '已复制了URL!';

  @override
  String get toast_camera_set_to_auto => '摄像头设置为自动';

  @override
  String get toast_failed_to_save_short => '无法保存';

  @override
  String toast_failed_with_message(Object arg1) {
    return '失败:$arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return '摄像头$arg1设置 下一个ACC周期';
  }

  @override
  String get toast_clearing_camera_config => '清除摄像头配置...';

  @override
  String get toast_restarting_camera_daemon => '正在重启摄像头服务…';

  @override
  String get toast_camera_daemon_restarting => '摄像头服务正在执行完整探测重启';

  @override
  String get toast_camera_restart_failed => '配置已清除，但服务重启失败。请手动重启。';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return '失败:$arg1';
  }

  @override
  String get toast_soh_reset_success => 'SOH估计重置 将从下一个数据中重新计算';

  @override
  String get toast_soh_reset_failed_no_daemon => '重置失败——服务无响应且文件不可写';

  @override
  String toast_soh_reset_failed_with_message(Object arg1) {
    return '重置失败:$arg1';
  }

  @override
  String get toast_select_at_least_one_category => '选择至少一个类别';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return '设置失败:$arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '交通监视器$arg1...';
  }

  @override
  String get dialog_close => '关闭';

  @override
  String get dialog_reset => '重置';

  @override
  String get dialog_delete => '删除';

  @override
  String get dialog_save => '保存';

  @override
  String get dialog_enable => '启用';

  @override
  String get dialog_disable => '停用';

  @override
  String get dialog_keep_enabled => '保持启用';

  @override
  String get dialog_keep_disabled => '保持停用';

  @override
  String get dialog_regenerate => '重新生成';

  @override
  String get dialog_reset_selected => '重置所选项';

  @override
  String get dialog_reset_soh_title => '设置SOH估计?';

  @override
  String get dialog_reset_soh_message =>
      '这将清除所有SOH数据并从零开始强迫重新估计.\n\n如果:\n•电池被更换\n•SOH读取似乎不正确\n•您想重新校准\n\n系统将从下一个可用的数据源 (OEM,充电校准或即时读取) 中重新播放.';

  @override
  String get dialog_reset_following_title => '重置以下项目？';

  @override
  String dialog_reset_following_message(Object arg1) {
    return '此操作无法撤销。\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => '重置完成';

  @override
  String get dialog_traffic_cannot_check_title => '无法检查状态';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB 未连接,应用也无法自动重新连接。\n\n在此车辆上,仅在开发者选项中开启常见的\"USB 调试\"开关是不够的——主机自身的无线 ADB(网络调试)设置也必须开启,系统更新可能会将其重置。请在主机上重新启用无线 ADB,或改用 USB 连接。\n\n连接后,状态将自动更新。';

  @override
  String get dialog_traffic_disable_title => '关闭BYD交通监视器?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) 是内置系统应用，会在后台持续监测道路交通状况。\n\n为什么要禁用？\n\n• 消耗移动数据（即使停车时也是）\n• 在后台占用 CPU 和电量\n• 如果您使用其他导航应用则不需要\n• 可能干扰行车记录仪的网络使用\n\n禁用是安全的：它只影响地图上的内置路况图层。导航、蓝牙和其他所有车辆功能均不受影响。\n\n禁用后需要硬重启（长按中控台按键 5 秒）。';

  @override
  String get dialog_traffic_enable_title => '再启用BYD交通监测器?';

  @override
  String get dialog_traffic_enable_message =>
      '目前,BYD 交通监测器已被禁用.\n\n重新启用将恢复导航地图内置的交通覆盖.请注意,它将在背景中运行并消耗移动数据.\n\n启动后需要硬式重新启动 (保持中心控制台按5秒).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return '交通监视器$arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      '更改已应用。\n\n请立即执行硬重启:\n长按中控台按键 5 秒。';

  @override
  String get traffic_monitor_loading => '交通监视器:检查...';

  @override
  String get traffic_monitor_tap_to_check => '交通监测器 (点击查看)';

  @override
  String get reset_label_trips => '行程';

  @override
  String get reset_label_soc_history => 'SoC + 12V 历史记录';

  @override
  String get reset_label_soh => 'SOH校准';

  @override
  String get reset_label_recordings => '录像';

  @override
  String get reset_label_sentry_events => '监控活动';

  @override
  String get reset_label_proximity => '近距离记录';

  @override
  String get reset_label_trip_files => '旅行遥测文件';

  @override
  String get toast_access_code_copied => '复制访问代码';

  @override
  String get dialog_regenerate_token_title => '复兴标志';

  @override
  String get dialog_regenerate_token_message => '当前令牌将失效。所有活动会话都将被登出。是否继续？';

  @override
  String get toast_token_regenerated_logged_out => '已生成新令牌。所有会话均已登出。';

  @override
  String get toast_token_regenerated_restart => '令牌已重新生成。各服务可能需要重启才能生效。';

  @override
  String get toast_token_regenerated_no_notify => '令牌已重新生成。无法通知后台服务。';

  @override
  String get toast_token_regenerated => '令牌再生';

  @override
  String get dashboard_no_tunnel => '没有道运行';

  @override
  String get dashboard_starting_zrok => '启动Zrok道...';

  @override
  String get dashboard_waiting_url => '等待道URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 运行中';
  }

  @override
  String get tunnel_label_zrok => 'Zrok';

  @override
  String get clip_label_access_code => '访问代码';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return '对于$arg1没有配置';
  }

  @override
  String get dialog_zrok_token_title => 'Zrok道标志';

  @override
  String get dialog_zrok_token_message => '请输入 Zrok 启用令牌。\n获取地址: zrok.io';

  @override
  String get toast_token_cannot_be_empty => '标签不能空';

  @override
  String get dialog_zrok_reset_title => '重置Zrok环境';

  @override
  String get dialog_zrok_reset_message =>
      '此操作将:\n• 停止正在运行的 zrok 隧道\n• 从本设备移除 zrok 环境\n• 删除已保存的令牌\n\n您需要重新输入令牌并重新启用。这会占用您在 zrok.io 上 5 个设备名额中的 1 个。\n\n确定吗？';

  @override
  String get toast_resetting_zrok => '重新设置zrok环境...';

  @override
  String get toast_zrok_reset_success => 'Zrok环境重置. 输入一个新的令牌,重新设置.';

  @override
  String get toast_zrok_reset_partial => '环境重置 (令牌文件可能需要手动清理)';

  @override
  String toast_zrok_reset_warnings(Object arg1) {
    return '环境重置 (附警告:$arg1)';
  }

  @override
  String get zrok_no_token_configured => '未配置令牌。点按进行设置。';

  @override
  String get toast_zrok_token_saved => '存储的令牌';

  @override
  String get toast_zrok_token_save_failed => '未能保存令牌';

  @override
  String get toast_zrok_token_deleted => '删除的标志';

  @override
  String get toast_zrok_token_delete_failed => '未能删除令牌';

  @override
  String toast_fetching_log(Object arg1) {
    return '带来$arg1日志...';
  }

  @override
  String get toast_log_empty_or_missing => '记录文件是空的或没有找到';

  @override
  String get toast_log_empty => '记录文件是空的';

  @override
  String toast_log_save_failed(Object arg1) {
    return '未能保存日志:$arg1';
  }

  @override
  String get toast_log_not_found => '记录文件未找到或不可读';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1日志 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return '分享$arg1日志';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 日志 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return '来源:$arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return '出口:$arg1';
  }

  @override
  String log_header_truncated(Object arg1) {
    return '注:截至10000行的日志 (总数:$arg1行)';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return '无法播放视频:$arg1';
  }

  @override
  String get dialog_delete_recording_title => '删除录像';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '删除 $arg1？\n此操作无法撤销。';
  }

  @override
  String get toast_recording_deleted => '删除记录';

  @override
  String get toast_recording_delete_failed => '无法删除录像';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '已删除$arg1,失败的$arg2';
  }

  @override
  String get play_with_chooser => '玩一下';

  @override
  String setup_version_banner(Object arg1) {
    return '更新到v$arg1 重新确认自动启动,BYD在每次安装时都会擦除它';
  }

  @override
  String get setup_overlay_already_granted => '已授予';

  @override
  String camera_current_manual(Object arg1) {
    return '目前:摄像头$arg1 (手动)';
  }

  @override
  String get camera_current_auto_label => '当前：自动';

  @override
  String get soh_estimation_active => '估计活动';

  @override
  String get soh_oem_readout => '车辆SOH读数——等待估算值';

  @override
  String get soh_nominal_baseline => '标称基准——等待可信SOH数据';

  @override
  String get soh_no_estimate_yet => '尚未估计 等待数据';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '选择$arg1';
  }

  @override
  String get video_player_playback_error => '播放错误';

  @override
  String get video_player_no_events => '没有事件';

  @override
  String get daemon_configuration_required => '需要配置';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => '视频播放器';

  @override
  String get status_overlay_notif_title => 'BladeWatch 状态';

  @override
  String get status_overlay_notif_text => '状态覆盖活动';

  @override
  String get rail_dashboard => '仪表板';

  @override
  String get rail_live => '实时';

  @override
  String get rail_recordings => '录像';

  @override
  String get rail_vehicle => '车辆';

  @override
  String get rail_trips => '行程';

  @override
  String get rail_location => '位置';

  @override
  String get rail_diagnostics => '诊断';

  @override
  String get rail_settings => '设置';

  @override
  String get settings_section_appearance => '外观';

  @override
  String get settings_section_recording => '录制';

  @override
  String get settings_section_surveillance => '监控';

  @override
  String get settings_section_daemons => '服务';

  @override
  String get settings_section_privacy => '隐私与数据';

  @override
  String get settings_section_overlay => '状态覆盖';

  @override
  String get settings_overlay_subtitle => '选择漂浮状态药物的哪些部分保持可见.';

  @override
  String get settings_overlay_camera_title => '摄像头指标';

  @override
  String get settings_overlay_camera_subtitle => '在录像活动期间显示REC/ PROX标志.';

  @override
  String get settings_overlay_trip_title => '指向旅行';

  @override
  String get settings_overlay_trip_subtitle => '在旅行检测正在运行时,请显示TRIP标志.';

  @override
  String get settings_section_about => '关于';

  @override
  String get settings_subrail_overline => '设置';

  @override
  String get cd_settings_subrail => '设置侧栏';

  @override
  String get settings_privacy_title => '隐私与数据';

  @override
  String get settings_privacy_body => '重置将清除录像索引、缓存凭证、服务状态及设备端偏好设置。此操作不可撤销。';

  @override
  String get settings_about_title => '关于BladeWatch';

  @override
  String get settings_about_version_label => '版本';

  @override
  String get settings_about_package_label => '建设';

  @override
  String get settings_about_support_section => '由像你这样的人来推动';

  @override
  String get settings_about_support_share_title => '告诉另一位车主';

  @override
  String get settings_about_support_share_value =>
      '每个共享的链接都能帮助另一个BYD的所有者发现BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      '查看BYD的开源监控和仪表摄像头: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => '分享过度驱动';

  @override
  String get settings_about_open_link_failed => '无法打开链接.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return '没有浏览器. URL复制: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => '在下一个版本中加油';

  @override
  String get settings_about_support_kofi_value => '一杯咖啡让晚上的承诺持续下去.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => '许可证';

  @override
  String get settings_about_license_value => '开源. 点击查看全文.';

  @override
  String get settings_about_source_title => '源代码';

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
  String get settings_about_star_title => '在 GitHub 上放一个';

  @override
  String get settings_about_star_value => '需要一秒钟,这意味着很多.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => '致谢';

  @override
  String get settings_about_thanks_subtitle => '在贡献者和支持者的帮助下打造。';

  @override
  String get settings_about_contributors_title => '贡献者';

  @override
  String get settings_about_supporters_title => '支持者';

  @override
  String get settings_about_thanks_empty => '随着大家加入,这里会被填满。';

  @override
  String get settings_theme_label => '主题';

  @override
  String get settings_theme_auto => '自动（跟随系统）';

  @override
  String get settings_theme_light => '浅色';

  @override
  String get settings_theme_dark => '深色';

  @override
  String get settings_language_label => '语言';

  @override
  String get settings_drive_side_label => '导航位置';

  @override
  String get settings_drive_side_subtitle => '选择导航菜单显示在屏幕的哪一侧。';

  @override
  String get settings_drive_side_left => '左侧';

  @override
  String get settings_drive_side_left_hint => '左舵 · 默认';

  @override
  String get settings_drive_side_right => '右侧';

  @override
  String get settings_drive_side_right_hint => '右舵车辆';

  @override
  String get settings_drive_side_auto => '自动';

  @override
  String get settings_drive_side_auto_hint => '从车辆检测';

  @override
  String get settings_drive_side_caption_left => '导航在左侧';

  @override
  String get settings_drive_side_caption_right => '导航在右侧';

  @override
  String get settings_drive_side_caption_auto_left => '自动——车辆报告为左舵';

  @override
  String get settings_drive_side_caption_auto_right => '自动——车辆报告为右舵';

  @override
  String get settings_drive_side_caption_auto_unknown => '自动——车辆不可用，使用左侧';

  @override
  String get recordings_title => '录像';

  @override
  String get recordings_segment_dashcam => '行车记录';

  @override
  String get recordings_segment_surveillance => '监控';

  @override
  String get recordings_action_settings => '设置';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '今天的$arg1 · $arg2总数 · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return '行车记录 · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return '监控 · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => '选择录像';

  @override
  String get recordings_preview_placeholder_body => '在左边点击任何东西来播放.';

  @override
  String get diagnostics_section_adb_console => 'ADB 控制台';

  @override
  String get diagnostics_section_traffic => '交通监视器';

  @override
  String get diagnostics_section_camera_probe => '摄像头探测器';

  @override
  String get diagnostics_section_battery => '电池健康';

  @override
  String get diagnostics_section_performance => '性能';

  @override
  String get diagnostics_hero_title => '系统诊断';

  @override
  String get diagnostics_hero_subtitle => '现场健康,记录和探测器.';

  @override
  String get diagnostics_health_clear => '一切正常';

  @override
  String get diagnostics_health_section => '运行状况';

  @override
  String get diagnostics_health_network => '网络';

  @override
  String get diagnostics_health_storage => '存储空间';

  @override
  String get diagnostics_health_camera => '摄像头';

  @override
  String get diagnostics_health_battery => '电池';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => '在线';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return '道 · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => '在线';

  @override
  String get diagnostics_tunnel_state_offline => '离线';

  @override
  String get diagnostics_tunnel_state_connecting => '连接中';

  @override
  String get diagnostics_network_mobile => '移动';

  @override
  String get diagnostics_network_ethernet => '以太网';

  @override
  String get diagnostics_network_offline => '离线';

  @override
  String diagnostics_storage_used_line(Object arg1, Object arg2) {
    return '使用的$arg1剪辑 ·$arg2';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '免费的$arg1';
  }

  @override
  String get diagnostics_logs_card_title => '现场活动日志';

  @override
  String get diagnostics_logs_card_subtitle => '从运行服务中流出输出.';

  @override
  String get diagnostics_tools_section => '工具';

  @override
  String get diagnostics_traffic_subtitle => '观看直播网络的吞吐量.';

  @override
  String get diagnostics_camera_probe_subtitle => '检查连接的摄像头流.';

  @override
  String get diagnostics_adb_subtitle => '打开设备上的终端。';

  @override
  String get diagnostics_battery_subtitle => '检查细胞SOH和数据包.';

  @override
  String get diagnostics_settings_subtitle => '应用程序偏好,主题和语言.';

  @override
  String get settings_action_reset_data => '重置数据…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => '守望中';

  @override
  String get dashboard_subtitle_all_systems => '所有系统在线';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '在线提供$arg1的$arg2服务';
  }

  @override
  String get dashboard_subtitle_no_tunnel => '离线远程访问';

  @override
  String get dashboard_metric_recordings => '今天的录像';

  @override
  String get dashboard_metric_storage => '使用的存储';

  @override
  String get dashboard_metric_tunnel => '远程访问';

  @override
  String get dashboard_metric_services => '背景服务';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => '车辆';

  @override
  String get dashboard_chip_recording_active => '录制中';

  @override
  String get dashboard_chip_recording_idle => '空闲';

  @override
  String get dashboard_vehicle_tap_to_set => '点按以设置';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => '设置电池容量';

  @override
  String get vehicle_dialog_capacity_label => '容量 (kWh)';

  @override
  String get vehicle_dialog_capacity_suffix => 'kWh';

  @override
  String get vehicle_dialog_capacity_helper => '8至120 kWh。保留以使用模型默认值。';

  @override
  String get vehicle_dialog_model_label => '车型';

  @override
  String get vehicle_dialog_save => '保存';

  @override
  String get vehicle_dialog_reset => '重置为自动检测';

  @override
  String get vehicle_dialog_invalid_capacity => '容量必须为8-120kWh';

  @override
  String vehicle_dialog_summary_capacity(Object arg1) {
    return '容量:$arg1';
  }

  @override
  String vehicle_dialog_summary_soh(Object arg1) {
    return 'SOH: $arg1';
  }

  @override
  String vehicle_dialog_soh_source_live(Object arg1) {
    return '$arg1%(实时)';
  }

  @override
  String vehicle_dialog_soh_source_calibration(Object arg1) {
    return '$arg1%(上次充电)';
  }

  @override
  String vehicle_dialog_soh_source_oem(Object arg1) {
    return '$arg1%(车辆)';
  }

  @override
  String vehicle_dialog_soh_source_nominal(Object arg1) {
    return '$arg1%(标称)';
  }

  @override
  String get settings_recording_tab_status => '状态';

  @override
  String get settings_recording_tab_capture => '采集';

  @override
  String get settings_recording_tab_quality => '画质';

  @override
  String get settings_recording_tab_storage => '存储';

  @override
  String get settings_recording_status_title => '录制状态';

  @override
  String get settings_recording_status_current_state => '当前状态';

  @override
  String get settings_recording_status_today_count => '今日录制数';

  @override
  String get settings_recording_mode_title => '录制模式（ACC 开启）';

  @override
  String get settings_recording_mode_description => '选择行车时行车记录仪何时录制。';

  @override
  String get settings_recording_mode_none_label => '不录制（默认）';

  @override
  String get settings_recording_mode_none_desc => '不录制 — 监控仍然工作';

  @override
  String get settings_recording_mode_continuous_label => '持续录制';

  @override
  String get settings_recording_mode_continuous_desc => '行车时全程录制';

  @override
  String get settings_recording_mode_drive_label => '行驶模式';

  @override
  String get settings_recording_mode_drive_desc => '仅在车辆行驶时录制';

  @override
  String get settings_recording_mode_proximity_label => '接近守卫';

  @override
  String get settings_recording_mode_proximity_desc => '检测到移动时录制';

  @override
  String get settings_recording_limit_title => '录制时长上限';

  @override
  String get settings_recording_limit_description => '每个文件的最大时长。录制会按此间隔分割为新文件。';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => '录制画质';

  @override
  String get settings_recording_storage_title => '录制存储';

  @override
  String get settings_recording_storage_location_label => '存储位置';

  @override
  String get settings_recording_storage_internal => '内部存储';

  @override
  String get settings_recording_storage_sd_card => 'SD 卡';

  @override
  String get settings_recording_storage_sd_card_na => 'SD 卡（不可用）';

  @override
  String get settings_recording_storage_limit_label => '存储上限 — 达到后自动删除最旧的';

  @override
  String get settings_recording_storage_usage_label => '存储使用量';

  @override
  String get settings_recording_storage_files_label => '文件';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '已用 $arg1 / 上限 $arg2';
  }

  @override
  String settings_recording_storage_files(Object arg1) {
    return '$arg1 个录制';
  }

  @override
  String get settings_recording_storage_path_label => '路径';

  @override
  String get settings_recording_storage_sd_free_label => 'SD 卡可用空间';

  @override
  String get settings_recording_storage_internal_free_label => '内部可用空间';

  @override
  String get settings_recording_format_title => '格式化外部存储';

  @override
  String get settings_recording_format_warning => '将永久擦除 SD 卡或 USB 驱动器上的所有数据。';

  @override
  String get settings_recording_format_confirm => '再次点按 — 所有数据将被擦除';

  @override
  String get settings_recording_format_running => '正在格式化… 请稍候';

  @override
  String get settings_recording_format_button => '格式化 SD 卡 / USB';

  @override
  String get settings_recording_format_no_drive => '未找到可移动存储';

  @override
  String settings_recording_format_success(Object arg1) {
    return '格式化成功。新路径：$arg1';
  }

  @override
  String get settings_recording_sync_title => '数据库目录';

  @override
  String get settings_recording_sync_description => '将录制索引与磁盘上的文件核对。';

  @override
  String get settings_recording_sync_running => '正在同步…';

  @override
  String get settings_recording_sync_button => '同步数据库';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return '已同步：+$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => '同步已在进行中';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return '同步失败：$arg1';
  }

  @override
  String get settings_recording_apply_button => '应用更改';

  @override
  String get settings_recording_dismiss => '关闭';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return '暂不支持启动/停止 $arg1';
  }

  @override
  String get settings_daemons_zrok_configure => '配置';

  @override
  String get settings_daemons_zrok_reset_button => '重置环境';

  @override
  String vehicle_dialog_summary_effective(Object arg1) {
    return '有效:$arg1 kWh';
  }

  @override
  String vehicle_dialog_summary_model(Object arg1) {
    return '车型: $arg1';
  }

  @override
  String vehicle_dialog_summary_calibration(Object arg1, Object arg2) {
    return '最后校准:$arg1% 在$arg2';
  }

  @override
  String get vehicle_dialog_soh_unavailable => '无法获取';

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '使用的$arg1 ·免费的$arg2';
  }

  @override
  String get dashboard_metric_storage_chip_pending => '存储空间 —';

  @override
  String get dashboard_tunnel_offline => '离线';

  @override
  String get dashboard_tunnel_online => '在线';

  @override
  String get dashboard_tunnel_connecting => '连接中…';

  @override
  String get dashboard_trips_this_week => '本周';

  @override
  String dashboard_trips_count(Object arg1) {
    return '$arg1次行程';
  }

  @override
  String dashboard_trips_distance_km(Object arg1) {
    return '$arg1 km';
  }

  @override
  String dashboard_trips_distance_mi(Object arg1) {
    return '$arg1 英里';
  }

  @override
  String dashboard_trips_duration(Object arg1) {
    return '$arg1';
  }

  @override
  String get dashboard_trips_label_trips => '行程';

  @override
  String get dashboard_trips_label_distance => '距离';

  @override
  String get dashboard_trips_label_time => '驾驶时长';

  @override
  String get dashboard_trips_no_data => '本周暂无行程记录';

  @override
  String get dashboard_trips_unavailable => '开始驾驶以查看统计';

  @override
  String get dashboard_trips_loading => '加载中…';

  @override
  String get dashboard_trips_view_all => '查看所有行程';

  @override
  String get dashboard_action_live => '现场视频';

  @override
  String get dashboard_action_live_subtitle => '打开摄像头画面';

  @override
  String get dashboard_action_recordings => '录像';

  @override
  String get dashboard_action_settings => '设置';

  @override
  String get dashboard_action_settings_subtitle => '偏好和关于';

  @override
  String get settings_hero_title => '设置';

  @override
  String get settings_hero_overline => '过度驱动';

  @override
  String get settings_hero_subtitle => '调整外观,录像,监控和设备上的数据.';

  @override
  String get settings_overline_preferences => '预见';

  @override
  String get settings_overline_about_data => '关于 & DATA';

  @override
  String get settings_quick_theme_label => '主题';

  @override
  String get settings_quick_language_label => '语言';

  @override
  String get settings_section_recording_subtitle => '预/后缓冲器,代码,存储限制.';

  @override
  String get settings_section_surveillance_subtitle => '检测区域,时间表,运动敏感性.';

  @override
  String get settings_section_daemons_subtitle => 'Zrok 隧道与后台服务。';

  @override
  String get settings_about_row_title => '关于BladeWatch';

  @override
  String get settings_about_row_subtitle => '版本,许可证,支持开发.';

  @override
  String get settings_reset_row_subtitle => '清晰的录像,事件,或所有隐藏.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle => '的主题,语言和视觉偏好.';

  @override
  String get settings_theme_active_auto_caption => '自动跟随系统主题。';

  @override
  String get settings_theme_active_light_caption => '始终使用浅色主题。';

  @override
  String get settings_theme_active_dark_caption => '始终使用深色主题。';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg2 种语言中有 $arg1 种可用';
  }

  @override
  String get settings_language_card_title => '显示语言';

  @override
  String get settings_privacy_stance_title => '默认的设备上';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch 完全在车机上运行。除了您明确配置的隧道和集成之外，没有任何遥测数据离开您的车辆。';

  @override
  String get settings_privacy_overline_storage => '地方储存';

  @override
  String get settings_privacy_overline_reset => '数据重新设置';

  @override
  String get settings_privacy_storage_clips_label => '磁盘上的剪辑';

  @override
  String get settings_privacy_storage_size_label => '总规模';

  @override
  String get settings_privacy_storage_unavailable => '无法使用';

  @override
  String settings_privacy_storage_count_format(Object arg1) {
    return '$arg1剪辑';
  }

  @override
  String settings_privacy_storage_count_format_plural(Object arg1) {
    return '片$arg1';
  }

  @override
  String get settings_privacy_reset_subtitle => '选择类别：录像、事件、服务配置、缓存遥测数据…';

  @override
  String get settings_developer_overline => '开发者';

  @override
  String get settings_developer_timing_logs_title => '服务计时日志';

  @override
  String get settings_developer_timing_logs_subtitle =>
      '记录服务启动期间的耗时标记。正常使用时请关闭以保持 logcat 整洁。';

  @override
  String get settings_developer_debug_logs_title => '开发者调试日志';

  @override
  String get settings_developer_debug_logs_subtitle =>
      '将所有Activity和Fragment生命周期事件及启动步骤记录到/storage/emulated/0/BladeWatch/data/debug_app.log。崩溃信息始终会被捕获。默认关闭。';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return '摄像头$arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return '摄像头$arg1 (手动)';
  }

  @override
  String get diagnostics_camera_value_probing => '探测中…';

  @override
  String get diagnostics_camera_value_offline => '离线';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => '待定数据';

  @override
  String dashboard_recordings_value_live(Object arg1) {
    return '● $arg1';
  }

  @override
  String get dashboard_insight_welcome => '欢迎您 过度驱动是您的第二双眼睛.';

  @override
  String dashboard_insight_parked_charged_kwh(Object arg1, Object arg2) {
    return '在停车时拿到$arg1 (≈$arg2)';
  }

  @override
  String dashboard_insight_parked_charged(Object arg1) {
    return '在停车时拿到$arg1';
  }

  @override
  String dashboard_insight_parked_drained_kwh(Object arg1, Object arg2) {
    return '自从你停车以来,一直使用$arg1 (≈$arg2)';
  }

  @override
  String dashboard_insight_parked_drained(Object arg1) {
    return '自从你停车以来,一直使用$arg1';
  }

  @override
  String dashboard_insight_last_alert(Object arg1) {
    return '最后的监控警报:$arg1';
  }

  @override
  String dashboard_insight_last_charge(Object arg1, Object arg2) {
    return '最后的电荷:$arg2中的$arg1';
  }

  @override
  String dashboard_insight_storage_milestone(Object arg1, Object arg2) {
    return '记录的$arg1剪辑 · 记录的$arg2';
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
    return '时间:$arg1小时$arg2分钟';
  }

  @override
  String dashboard_insight_today_clips(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '今天录制的$arg1片段',
      one: '今天录制的$arg1片段',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_days_hours(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '在线开车$arg1天,$arg2小时',
      one: '在线开车$arg1天,$arg2小时',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_hours(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '在线开车$arg1小时',
      one: '在$arg1小时上网过车',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_minutes(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 min',
      one: '$arg1 min',
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
  String get vehicle_tab_trunk => '后备箱';

  @override
  String get vehicle_tab_climate => '空调';

  @override
  String get vehicle_tab_seats => '座椅';

  @override
  String get vehicle_tab_windows => '车窗';

  @override
  String get vehicle_tab_lights => '灯光';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => '充电';

  @override
  String get vehicle_locked => '锁定';

  @override
  String get vehicle_unlocked => '已解锁';

  @override
  String get vehicle_range_label => '续航';

  @override
  String get vehicle_data_unavailable => '车辆数据不可用。';

  @override
  String get vehicle_action_failed => '操作失败。请检查车辆连接。';

  @override
  String get vehicle_open_trunk => '打开后备箱';

  @override
  String get vehicle_close_trunk => '关闭后备箱';

  @override
  String get vehicle_trunk_info_open => '打开后备箱将先解锁车辆。';

  @override
  String get vehicle_ac_on => 'AC 开启';

  @override
  String get vehicle_ac_off => 'AC 关闭';

  @override
  String get vehicle_max_cooling_on => '最大制冷：开';

  @override
  String get vehicle_max_cooling_off => '最大制冷：关';

  @override
  String get vehicle_temp_label => '温度';

  @override
  String get vehicle_fan_speed_label => '风量';

  @override
  String vehicle_fan_level(Object arg1) {
    return '$arg1档';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return '车内：$arg1°C';
  }

  @override
  String get vehicle_seat_driver => '主驾';

  @override
  String get vehicle_seat_passenger => '副驾';

  @override
  String get vehicle_seat_no_controls => '此车辆无可用的座椅控制。';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return '加热 $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return '通风 $arg1';
  }

  @override
  String get vehicle_heat_off => '（关）';

  @override
  String get vehicle_heat_low => '（低）';

  @override
  String get vehicle_heat_high => '（高）';

  @override
  String get vehicle_seat_pos_1 => '位置1';

  @override
  String get vehicle_seat_pos_2 => '位置 2';

  @override
  String get vehicle_all_windows => '所有车窗';

  @override
  String get vehicle_window_front_left => '左前';

  @override
  String get vehicle_window_front_right => '右前';

  @override
  String get vehicle_window_rear_left => '左后';

  @override
  String get vehicle_window_rear_right => '右后';

  @override
  String get vehicle_window_close => '关闭';

  @override
  String get vehicle_window_close_vent => '关闭通风';

  @override
  String get vehicle_window_vent_12 => '通风 12%';

  @override
  String get vehicle_window_open_all => '全部打开';

  @override
  String get vehicle_sunroof => '天窗';

  @override
  String get vehicle_sunshade => '遮阳帘';

  @override
  String get vehicle_btn_drl_title => '白天运行灯';

  @override
  String get vehicle_btn_slw_title => '预警速度限制';

  @override
  String get vehicle_control_section_charge_cap => '充电上限';

  @override
  String get vehicle_charge_cap_not_supported => '此车辆不支持充电上限。';

  @override
  String get vehicle_charge_limit_label => '充电限制';

  @override
  String get vehicle_enable_charge_limit => '启用充电限制';

  @override
  String get vehicle_charge_limit_range => '最低50%，最高100%';

  @override
  String get vehicle_tyre_no_signal => '无信号';

  @override
  String get vehicle_tyre_slow_leak => '缓慢漏气';

  @override
  String get vehicle_tyre_fast_leak => '快速漏气';

  @override
  String get vehicle_tyre_low => '偏低';

  @override
  String get vehicle_tyre_high => '偏高';

  @override
  String get vehicle_tyre_ok => '正常';

  @override
  String get vehicle_tyre_check_pressure => '检查胎压';

  @override
  String get vehicle_toggle_on => '开';

  @override
  String get vehicle_toggle_off => '关';

  @override
  String get vehicle_err_climate_control => '空调控制失败。';

  @override
  String get vehicle_err_max_cooling => '最大制冷失败。';

  @override
  String get vehicle_err_drl_control => '日间行车灯控制失败。';

  @override
  String get vehicle_err_slw_control => 'ADAS控制失败。';

  @override
  String get vehicle_err_charge_limit_toggle => '充电限制切换失败。';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return '降低 $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return '提高 $arg1';
  }

  @override
  String get vehicle_stale_connecting => '连接中…';

  @override
  String get vehicle_appearance_model_title => '选择车型';

  @override
  String get vehicle_appearance_custom_color => '自定义颜色';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return '电量：$arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return '续航：$arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => '电量：—';

  @override
  String get vehicle_status_range_unknown => '续航：—';

  @override
  String get startup_subtitle => '正在准备您的行车记录仪';

  @override
  String get startup_header_preparing => '正在准备…';

  @override
  String get startup_header_starting => '正在启动…';

  @override
  String get startup_header_verifying => '即将就绪…';

  @override
  String get startup_header_ready => '一切就绪';

  @override
  String get startup_daemon_camera => '摄像头';

  @override
  String get startup_daemon_camera_desc => '实时画面与录制';

  @override
  String get startup_daemon_sentry => '哨兵模式';

  @override
  String get startup_daemon_sentry_desc => '运动检测与警报';

  @override
  String get startup_daemon_parking => '驻车守护';

  @override
  String get startup_daemon_parking_desc => '驻车期间持续监控';

  @override
  String get startup_status_waiting => '等待中';

  @override
  String get startup_status_starting => '启动中';

  @override
  String get startup_status_ready => '就绪';

  @override
  String get startup_status_failed => '失败';

  @override
  String get startup_continue_anyway => '仍然继续';

  @override
  String get startup_continue => '继续 →';

  @override
  String get live_retry => '重试';

  @override
  String get live_connecting => '正在连接摄像头…';

  @override
  String live_error_fmt(Object arg1) {
    return '错误：$arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return '摄像头不可用\n$arg1';
  }

  @override
  String get live_direction_all => '全部';

  @override
  String get live_direction_front => '前';

  @override
  String get live_direction_right => '右';

  @override
  String get live_direction_rear => '后';

  @override
  String get live_direction_left => '左';

  @override
  String get trip_no_route_data => '此行程无路线数据';

  @override
  String get trips_tab_trips => '行程';

  @override
  String get trips_tab_stats => '统计';

  @override
  String get trips_tab_storage => '存储';

  @override
  String get trips_filter_7_days => '7 天';

  @override
  String get trips_filter_14_days => '14 天';

  @override
  String get trips_filter_30_days => '30 天';

  @override
  String trips_load_error(Object message) {
    return '错误：$message';
  }

  @override
  String get trips_empty_state => '尚未记录任何行程';

  @override
  String get trips_period_summary_title => '周期摘要';

  @override
  String get trips_stat_trips => '行程';

  @override
  String get trips_stat_hours => '小时';

  @override
  String get trips_stat_efficiency => '效率';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return '评分：$score';
  }

  @override
  String get trips_driver_score_title => '驾驶评分';

  @override
  String trips_driver_score_overall(Object score) {
    return '总分：$score / 100';
  }

  @override
  String get trips_range_title => '个性化续航';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD 估算：$km 公里';
  }

  @override
  String get trips_range_no_data => '数据尚不足';

  @override
  String get trips_dna_title => '驾驶 DNA';

  @override
  String get trips_dna_anticipation => '预判';

  @override
  String get trips_dna_smoothness => '平顺度';

  @override
  String get trips_dna_speed_discipline => '速度遵守';

  @override
  String get trips_dna_efficiency => '效率';

  @override
  String get trips_dna_consistency => '稳定性';

  @override
  String get trips_storage_title => '行程存储';

  @override
  String get trips_storage_analytics_label => '行程分析';

  @override
  String get trips_storage_rate_label => '电价';

  @override
  String get trips_storage_distance_unit_label => '距离单位';

  @override
  String get trips_storage_location_label => '存储位置';

  @override
  String get trips_storage_internal => '内部存储';

  @override
  String get trips_storage_sd_card => 'SD 卡';

  @override
  String get trips_storage_sd_card_unavailable => 'SD 卡（不可用）';

  @override
  String get trips_storage_apply => '应用更改';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '已用 $used $unit / 上限 $limit MB · $count 次行程';
  }

  @override
  String get trips_sync_title => '数据库目录';

  @override
  String get trips_sync_description => '将行程索引与磁盘上的遥测文件核对。';

  @override
  String get trips_sync_button => '同步数据库';

  @override
  String get trips_sync_running => '正在同步…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return '同步成功：+$added -$removed（共 $total 条）';
  }

  @override
  String get trips_sync_failed_generic => '同步失败';

  @override
  String get trips_detail_summary_title => '行程摘要';

  @override
  String get trips_detail_distance => '距离';

  @override
  String get trips_detail_duration => '时长';

  @override
  String get trips_detail_energy => '能耗';

  @override
  String get trips_detail_avg_speed => '平均速度';

  @override
  String get trips_detail_max_speed => '最高速度';

  @override
  String get trips_detail_soc => '电量';

  @override
  String get trips_detail_cost => '费用';

  @override
  String get trips_detail_ext_temp => '外部温度';

  @override
  String get trips_detail_elev_gain => '爬升高度';

  @override
  String get trips_detail_scores_title => '驾驶评分';

  @override
  String get trips_detail_unavailable => '行程详情不可用';

  @override
  String get trips_detail_loading => '正在加载行程…';

  @override
  String trips_detail_route_points(Object count) {
    return '已记录 $count 个 GPS 点';
  }

  @override
  String get rec_severity_critical => '严重';

  @override
  String get rec_severity_alert => '警报';

  @override
  String get location_loading_title => '正在加载地图';

  @override
  String get location_permission_missing_title => '需要位置权限';

  @override
  String get location_permission_denied_title => '权限被拒绝';

  @override
  String get location_provider_disabled_title => 'GPS 已禁用';

  @override
  String get location_waiting_for_fix_title => '正在等待 GPS 信号';

  @override
  String get location_car_location_title => '车辆位置';

  @override
  String get location_stale_title => '位置信息已过期';

  @override
  String get location_tile_failure_title => '地图不可用';

  @override
  String get location_tile_failure_subtitle => '网络不可用';

  @override
  String get location_error_title => '位置错误';

  @override
  String get location_action_grant => '授予';

  @override
  String get location_action_retry => '重试';

  @override
  String get location_mode_auto => '自动';

  @override
  String get location_mode_light => '浅色';

  @override
  String get location_mode_dark => '深色';

  @override
  String get cd_recenter_on_car => '重新居中到车辆';

  @override
  String get recording_lib_no_recordings_normal => '没有普通录像';

  @override
  String get recording_lib_no_recordings_sentry => '没有哨兵事件';

  @override
  String get recording_lib_no_recordings_proximity => '没有距离事件';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => '人';

  @override
  String get video_player_legend_car => '车';

  @override
  String get video_player_legend_bike => '自行车';

  @override
  String get video_player_legend_motion => '运动';

  @override
  String get recording_lib_proximity_very_close => '非常近';

  @override
  String get recording_lib_proximity_close => '近';

  @override
  String get recording_lib_proximity_mid => '中等';

  @override
  String get recording_lib_proximity_far => '远';

  @override
  String get surveillance_tab_general => '常规';

  @override
  String get surveillance_tab_detection => '检测';

  @override
  String get surveillance_tab_recording => '录制';

  @override
  String get surveillance_tab_storage => '存储';

  @override
  String get surveillance_tab_advanced => '高级';

  @override
  String get surveillance_general_title => '监控模式';

  @override
  String get surveillance_general_enable => '启用监控';

  @override
  String get surveillance_general_status => '状态';

  @override
  String get surveillance_general_status_running => '运行中';

  @override
  String get surveillance_general_status_idle => '空闲';

  @override
  String get surveillance_general_events_today => '今日事件';

  @override
  String get surveillance_safe_locations_title => '安全位置';

  @override
  String get surveillance_safe_locations_subtitle => '停在此处时摄像头不会启动';

  @override
  String get surveillance_safe_locations_enable => '在安全位置停用';

  @override
  String get surveillance_safe_locations_empty => '尚未添加安全位置';

  @override
  String get surveillance_safe_locations_add_current => '将当前位置添加为安全区域';

  @override
  String get surveillance_safe_locations_no_gps => 'GPS 位置不可用';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_roi_title => '侦测区域';

  @override
  String get surveillance_roi_description => '点按添加顶点，拖动可移动顶点。最少三个，最多八个。';

  @override
  String get surveillance_roi_enable => '仅在此区域内侦测';

  @override
  String get action_undo => '撤销';

  @override
  String get surveillance_detection_title => '检测设置';

  @override
  String get surveillance_detection_preset_label => '环境预设';

  @override
  String get surveillance_preset_outdoor => '户外';

  @override
  String get surveillance_preset_garage => '车库';

  @override
  String get surveillance_preset_street => '街道';

  @override
  String get surveillance_preset_custom => '自定义';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return '灵敏度（1=严格，5=灵敏）：$arg1';
  }

  @override
  String get surveillance_detection_objects_label => '检测对象';

  @override
  String get surveillance_detection_object_person => '人';

  @override
  String get surveillance_detection_object_car => '车';

  @override
  String get surveillance_detection_object_bike => '自行车';

  @override
  String get surveillance_recording_title => '事件录制';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return '事件前预录（秒）：$arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return '事件后续录（秒）：$arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => '监控存储';

  @override
  String get surveillance_storage_location_label => '存储位置';

  @override
  String get surveillance_storage_internal => '内部';

  @override
  String get surveillance_storage_sd_card => 'SD 卡';

  @override
  String get surveillance_storage_sd_card_na => 'SD 卡（不可用）';

  @override
  String get surveillance_storage_limit_label => '存储上限 — 达到上限时自动删除最旧的文件';

  @override
  String get surveillance_storage_usage_label => '存储使用量';

  @override
  String get surveillance_storage_files_label => '文件';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '已用 $arg1 / 上限 $arg2';
  }

  @override
  String surveillance_storage_files(Object arg1) {
    return '$arg1 个事件';
  }

  @override
  String get surveillance_storage_path_label => '路径';

  @override
  String get surveillance_format_title => '格式化外部驱动器';

  @override
  String get surveillance_format_warning => '将永久清除 SD 卡或 U 盘上的所有数据。';

  @override
  String get surveillance_format_button => '格式化 SD 卡/USB';

  @override
  String get surveillance_format_confirm => '再次点按 — 所有数据将被清除';

  @override
  String get surveillance_format_running => '正在格式化…请稍候';

  @override
  String get surveillance_dismiss => '关闭';

  @override
  String get surveillance_sync_title => '数据库目录';

  @override
  String get surveillance_sync_description => '将监控索引与磁盘上的文件进行核对。';

  @override
  String get surveillance_sync_button => '同步数据库';

  @override
  String get surveillance_sync_running => '正在同步…';

  @override
  String get surveillance_advanced_camera_title => '摄像头选择';

  @override
  String get surveillance_advanced_camera_front => '前';

  @override
  String get surveillance_advanced_camera_right => '右';

  @override
  String get surveillance_advanced_camera_rear => '后';

  @override
  String get surveillance_advanced_camera_left => '左';

  @override
  String get surveillance_advanced_ai_title => 'AI 与威慑';

  @override
  String get surveillance_advanced_ai_detection => 'AI 检测';

  @override
  String get surveillance_advanced_night_mode => '夜间模式';

  @override
  String get surveillance_advanced_deterrent_label => '威慑动作';

  @override
  String get surveillance_deterrent_silent => '静音';

  @override
  String get surveillance_deterrent_horn => '喇叭';

  @override
  String get surveillance_deterrent_flash => '闪光';

  @override
  String get surveillance_apply_button => '应用更改';

  @override
  String get surveillance_apply_failed => '保存失败';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      '讓 BladeWatch 車輛監控在背景持續執行。本服務不會讀取螢幕內容，也不會與其互動。';

  @override
  String get action_cancel => '取消';

  @override
  String get action_clear_plain => '清除';

  @override
  String get action_select_all => '選擇所有';

  @override
  String get action_select_all_short => '全部';

  @override
  String get action_delete => '刪除';

  @override
  String get action_done => '已完成';

  @override
  String get action_remind_me_later => '稍後提醒';

  @override
  String get action_retry => '重試';

  @override
  String get action_run => '執行';

  @override
  String get action_clear_output => '清除輸出';

  @override
  String get cd_camera => '攝影機';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR 碼';

  @override
  String get cd_show_hide_token => '顯示/隱藏符號';

  @override
  String get cd_copy_token => '複製權杖';

  @override
  String get cd_copy_url => '複製 URL';

  @override
  String get cd_clear_logs => '清除日誌';

  @override
  String get cd_expand_collapse => '展開/收合';

  @override
  String get cd_recording_status => '記錄狀態';

  @override
  String get cd_trip_tracking_status => '旅行跟蹤狀態';

  @override
  String get cd_video_thumbnail => '影片細圖片';

  @override
  String get cd_play => '播放';

  @override
  String get cd_back => '返回';

  @override
  String get cd_play_pause => '播放/暫停';

  @override
  String get cd_player_prev => '上一次錄制';

  @override
  String get cd_player_next => '下一次錄制';

  @override
  String get cd_player_maximize => '放大播放器';

  @override
  String get cd_player_minimize => '退出全螢幕';

  @override
  String get cd_delete => '刪除';

  @override
  String get cd_expand => '展開';

  @override
  String get cd_configure => '設定';

  @override
  String get cd_download_log => '下載日誌';

  @override
  String get cd_reset => '重設';

  @override
  String get cd_battery => '電池';

  @override
  String get cd_step_completed => '完成步骤';

  @override
  String get cd_permission_granted => '授予許可';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => '旅行';

  @override
  String get log_entry_default_timestamp => '12:34:56';

  @override
  String get log_entry_default_tag => '[TAG]';

  @override
  String get log_entry_default_message => '這裡的帳號訊息';

  @override
  String get daemon_card_default_name => '服務名稱';

  @override
  String get daemon_card_default_status => '狀況訊息';

  @override
  String get daemon_card_subprocesses => '處理程序';

  @override
  String get logs_panel_title => '記錄時間';

  @override
  String get url_connecting => '連線中…';

  @override
  String get camera_selection_title => '攝影機選擇';

  @override
  String get camera_selection_subtitle => '選擇全景攝影機來源';

  @override
  String get camera_current_auto => '目前：自動';

  @override
  String get camera_option_auto => '自動 (啟動時檢測)';

  @override
  String get camera_option_0 => '攝影機0 — Atto 裝飾';

  @override
  String get camera_option_1 => '攝影機 1 — Seal (默認)';

  @override
  String get camera_option_2 => '攝影機 2';

  @override
  String get camera_option_3 => '攝影機3';

  @override
  String get camera_option_4 => '攝影機 4';

  @override
  String get camera_option_5 => '攝影機 5';

  @override
  String get camera_selection_hint =>
      '每次開機時自動選取適合您車款的攝影機。攝影機 1 = BYD Seal，攝影機 0 = Atto 車款。變更攝影機 ID 後，請重新啟動攝影機服務使設定生效。';

  @override
  String get dashboard_scan_to_connect => '掃碼連線';

  @override
  String get dashboard_qr_waiting => '在等待道...';

  @override
  String get dashboard_daemons_running_default => '0/5 執行中';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => '存取碼';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => '恢復代號';

  @override
  String get dashboard_set_password => '設定密碼';

  @override
  String get cd_set_password => '設定自訂密碼';

  @override
  String get dialog_set_password_title => '設定自訂密碼';

  @override
  String get dialog_set_password_message => '輸入新的存取密碼。這將取代自動產生的權杖。';

  @override
  String get dialog_set_password_hint => '新密碼（至少 12 個字元）';

  @override
  String get toast_password_set => '密碼已更新';

  @override
  String get toast_password_too_short => '密碼至少需 12 個字元';

  @override
  String get toast_password_save_failed => '無法儲存密碼 — 服務尚未就緒';

  @override
  String get setup_guide_title => '開始工作';

  @override
  String get setup_guide_subtitle => '快速取得最佳體驗的三步:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => '選擇自己的語言';

  @override
  String get setup_language_body =>
      '預設使用車機的語言。點按可為 BladeWatch 應用程式和網頁通道選擇其他語言。';

  @override
  String get setup_language_button => '選擇語言';

  @override
  String get setup_autostart_title => '禁用自動啟動限制';

  @override
  String get setup_autostart_body =>
      '點按下方開啟 BYD 自動啟動。在清單中找到 BladeWatch 並取消勾選。BYD 每次安裝都會清除這項設定 — 更新後需要重做一次。';

  @override
  String get setup_autostart_button => '打開BYD自動啟動';

  @override
  String get setup_overlay_title => '在其他應用程式上允許顯示';

  @override
  String get setup_overlay_body => '在其他應用程式上顯示浮動狀態指標,';

  @override
  String get setup_overlay_button => '打開覆蓋設定';

  @override
  String get cd_close => '關閉';

  @override
  String get language_picker_title => '語言';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '提供$arg1語言';
  }

  @override
  String get language_picker_subtitle_pending => '選擇一種語言';

  @override
  String get language_auto_title => '自動使用';

  @override
  String language_auto_subtitle(Object arg1) {
    return '追蹤系統 · $arg1';
  }

  @override
  String get language_not_saved => '語言已套用，但無法儲存 — 重新啟動應用程式後會還原。';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · 自動';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => '輸入指令…';

  @override
  String get adb_preset_commands_header => '預設命令';

  @override
  String get adb_output_header => '輸出';

  @override
  String get adb_output_ready => '\$ 已準備好接收指令…';

  @override
  String get adb_console_hero_title => 'ADB 主控台';

  @override
  String get adb_console_hero_subtitle => '在裝置上執行 shell 命令';

  @override
  String get adb_console_unavailable_title => 'ADB 未連接';

  @override
  String get adb_console_unavailable_body =>
      '在此車輛上，僅開發者選項中普通的「USB 除錯」開關還不夠 —— 中控螢幕自身的無線 ADB（網路除錯）設定也需要開啟，而系統更新可能會將其重置。請在中控螢幕上重新開啟無線 ADB，或透過 USB 連接。';

  @override
  String get adb_console_auth_pending_title => '等待授權';

  @override
  String get adb_console_auth_pending_body =>
      '查看中控螢幕上的「允許 USB 除錯嗎？」提示並接受，然後重試。';

  @override
  String get performance_connecting => '正在連線至效能監視器…';

  @override
  String get performance_hero_title => '系統效能';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => '系統使用率';

  @override
  String get performance_cpu_app_usage => '應用程式使用率';

  @override
  String get performance_frequency_label => '頻率';

  @override
  String get performance_temperature_label => '溫度';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => '記憶體';

  @override
  String get performance_usage_label => '使用率';

  @override
  String get performance_memory_total => '總計';

  @override
  String get performance_memory_used => '已用';

  @override
  String get performance_memory_app => '應用程式';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => '應用程式程序';

  @override
  String get performance_threads_label => '執行緒數';

  @override
  String get performance_gc_cycles_label => 'GC 次數';

  @override
  String get performance_open_fds_label => '開啟的 FD';

  @override
  String get performance_refreshing_footer => '每 3 秒重新整理一次';

  @override
  String get webview_loading => '接收了這些東西.';

  @override
  String get webview_camera_daemon_not_running => '攝影機未運行';

  @override
  String get webview_start_camera_daemon => '請從「服務」畫面啟動攝影機服務，以存取此頁面。';

  @override
  String get zrok_enable_token_hint => '啟動權杖';

  @override
  String get zrok_token_storage_note => '權杖已安全儲存，並在應用程式與後台服務之間共用。';

  @override
  String get zrok_reset_environment => '重置Zrok環境';

  @override
  String get zrok_reset_environment_desc => '移除環境和權杖。您需要用權杖重新啟用（會佔用一個裝置名額）。';

  @override
  String get reset_title => '重置資料';

  @override
  String get reset_subtitle => '按類別清除累積的數據';

  @override
  String get reset_warning => '此操作無法復原。錄影、行程和電池記錄將被永久刪除。';

  @override
  String get reset_cat_trips => '行程';

  @override
  String get reset_cat_trips_desc => '旅行歷史,航線,週/月的行程';

  @override
  String get reset_cat_soc_history => 'SoC & 12V 的歷史';

  @override
  String get reset_cat_soc_history_desc => '接收時間,電壓記錄';

  @override
  String get reset_cat_soh => '顯示的數量';

  @override
  String get reset_cat_soh_desc => '在 BMS 中重新檢測名稱容量,重新種植估計';

  @override
  String get reset_cat_recordings => '錄影 (影片)';

  @override
  String get reset_cat_recordings_desc => '在錄影文件中的所有MP4';

  @override
  String get reset_cat_sentry_events => '監控活動';

  @override
  String get reset_cat_sentry_events_desc => '監控活動剪貼和JSON側車';

  @override
  String get reset_cat_proximity => '靠近的記錄';

  @override
  String get reset_cat_proximity_desc => '雷達啟動事件MP4';

  @override
  String get reset_cat_trip_files => '旅行遠隔測量檔案';

  @override
  String get reset_cat_trip_files_desc => '在磁盤上進行 JSON 每次旅行遠隔測量';

  @override
  String get recording_lib_chip_any => '全部';

  @override
  String get recording_lib_chip_person => '人';

  @override
  String get recording_lib_chip_vehicle => '車輛';

  @override
  String get recording_lib_chip_bike => '單車';

  @override
  String get recording_lib_chip_animal => '動物';

  @override
  String get recording_lib_chip_alert => '警示';

  @override
  String get recording_lib_chip_critical => '嚴重';

  @override
  String get recording_lib_selected_count_zero => '0 選擇';

  @override
  String get recording_lib_no_recordings => '沒有錄影';

  @override
  String get recording_lib_filter_button => '篩選';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return '篩選 · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => '篩選錄影';

  @override
  String get recording_lib_filter_apply => '套用';

  @override
  String get recording_lib_filter_reset => '重設';

  @override
  String get recording_lib_filter_section_what => '對象';

  @override
  String get recording_lib_filter_section_severity => '嚴重性';

  @override
  String get recording_lib_filter_section_type => '類別';

  @override
  String get recording_lib_chip_type_normal => '普通';

  @override
  String get recording_lib_chip_type_proximity => '接近';

  @override
  String get recording_lib_date_today => '今天';

  @override
  String get recording_lib_date_yesterday => '昨天';

  @override
  String recording_lib_clip_count(Object arg1) {
    return '片 $arg1';
  }

  @override
  String recording_lib_clip_count_one(Object arg1) {
    return '片 $arg1';
  }

  @override
  String get recording_lib_pick_date => '選擇一個日期';

  @override
  String get recording_lib_date_all_days => '所有日期';

  @override
  String get cd_clear_date_filter => '顯示所有日期';

  @override
  String get recording_lib_section_morning => '上午';

  @override
  String get recording_lib_section_afternoon => '下午';

  @override
  String get recording_lib_section_evening => '傍晚';

  @override
  String get recording_lib_section_night => '夜間';

  @override
  String get cd_previous_day => '前一天';

  @override
  String get cd_next_day => '次日';

  @override
  String get cd_open_filters => '開啟篩選';

  @override
  String get cd_clear_filter => '清除篩選';

  @override
  String get player_title_recording => '錄影';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => '攝影機服務';

  @override
  String get daemon_name_surveillance => '監控服務';

  @override
  String get daemon_name_acc => 'ACC 監控';

  @override
  String get daemon_name_zrok => 'Zrok Tunnel';

  @override
  String get daemons_hero_title => '背景服務';

  @override
  String get daemons_count_pending => '這裡有許多貨物.';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '在 $arg1 的 $arg2 上行';
  }

  @override
  String get battery_health_title => '電池健康';

  @override
  String get battery_health_subtitle => '衛生狀況';

  @override
  String get battery_health_dashes => '--';

  @override
  String get battery_health_waiting => '在等待數據...';

  @override
  String get battery_health_source => '來源';

  @override
  String get battery_health_method => '方法';

  @override
  String get battery_health_capacity => '容量';

  @override
  String get battery_health_samples => '標本';

  @override
  String get battery_health_last_updated => '最新更新';

  @override
  String get battery_health_unavailable => '不可用';

  @override
  String get battery_health_unavailable_desc => '此車輛不支援電池健康度估算。';

  @override
  String get battery_health_reset => '重置SOH估值';

  @override
  String get battery_health_reset_desc =>
      '清除所有資料並從零重新估算。如果更換了電池或讀值看起來不正確，請使用此功能。';

  @override
  String get soh_dialog_model_label => '車型';

  @override
  String get soh_dialog_pack_capacity_label => '包裝容量';

  @override
  String get soh_dialog_estimated_capacity_label => '有效的容量';

  @override
  String get soh_dialog_calibration_anchor_label => '最后校準';

  @override
  String get soh_dialog_source_user => '使用者集合';

  @override
  String get soh_dialog_source_auto => '自動檢測';

  @override
  String get soh_dialog_model_not_selected => '沒有選擇';

  @override
  String get soh_dialog_capacity_not_detected => '沒有發現';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1%（$arg2）';
  }

  @override
  String get dialog_ok => '確定';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '已取消$arg1錄影',
      one: '已取消$arg1錄影',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '刪除 $arg1 部錄影',
      one: '刪除 $arg1 部錄影',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '將永久刪除 $arg1 個錄影。此操作無法復原。',
      one: '將永久刪除 $arg1 個錄影。此操作無法復原。',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return '應用程式已更新 (v$arg1)';
  }

  @override
  String get toast_storage_permission_required => '需要存儲許可,';

  @override
  String get toast_url_copied_short => '這就是 URL複製!';

  @override
  String get toast_camera_set_to_auto => '攝影機設定為自動';

  @override
  String get toast_failed_to_save_short => '沒有儲存';

  @override
  String toast_failed_with_message(Object arg1) {
    return '失敗: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return '$arg1相機組 下一個 ACC週期';
  }

  @override
  String get toast_clearing_camera_config => '清除攝影機配置...';

  @override
  String get toast_restarting_camera_daemon => '正在重新啟動攝影機服務…';

  @override
  String get toast_camera_daemon_restarting => '攝影機服務正在完整重新偵測並重新啟動';

  @override
  String get toast_camera_restart_failed => '設定已清除，但服務重新啟動失敗，請手動重新啟動。';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return '失敗:$arg1';
  }

  @override
  String get toast_soh_reset_success => 'SOH估算重置 將從下一步數據中重新計算';

  @override
  String get toast_soh_reset_failed_no_daemon => '重置失敗 — 服務未回應且檔案無法寫入';

  @override
  String toast_soh_reset_failed_with_message(Object arg1) {
    return '重置失敗: $arg1';
  }

  @override
  String get toast_select_at_least_one_category => '選擇至少一個類別';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return '沒有重置: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '這裡是 $arg1 交通監測器.';
  }

  @override
  String get dialog_close => '關閉';

  @override
  String get dialog_reset => '重設';

  @override
  String get dialog_delete => '刪除';

  @override
  String get dialog_save => '儲存';

  @override
  String get dialog_enable => '啟用';

  @override
  String get dialog_disable => '停用';

  @override
  String get dialog_keep_enabled => '保持啟用';

  @override
  String get dialog_keep_disabled => '保持停用';

  @override
  String get dialog_regenerate => '重新產生';

  @override
  String get dialog_reset_selected => '重置所選項目';

  @override
  String get dialog_reset_soh_title => '預算的 SOH 預算?';

  @override
  String get dialog_reset_soh_message =>
      '此操作將清除所有 SOH 資料，並從頭強制重新估算。\n\n在下列情況下使用:\n• 電池已更換\n• SOH 讀值看起來不正確\n• 您想重新校正\n\n系統會從下一個可用的資料來源 (OEM、充電校正或即時讀值) 重新取得基準。';

  @override
  String get dialog_reset_following_title => '重置下列項目？';

  @override
  String dialog_reset_following_message(Object arg1) {
    return '此操作無法復原。\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => '重置完成';

  @override
  String get dialog_traffic_cannot_check_title => '無法檢查狀況';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB 未連接,應用程式也無法自動重新連接。\n\n在這輛車上,僅開啟開發人員選項中常見的「USB 偵錯」開關是不夠的 —— 主機本身的無線 ADB(網路偵錯)設定也必須開啟,而系統更新可能會將其重設。請在主機上重新啟用無線 ADB,或改用 USB 連接。\n\n連接後,狀態將自動更新。';

  @override
  String get dialog_traffic_disable_title => '關閉BYD交通監測器?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) 是內建系統應用程式，會在背景持續監測道路交通狀況。\n\n為什麼要停用？\n\n• 消耗行動數據（即使停車時也是）\n• 在背景占用 CPU 和電量\n• 如果您使用其他導航應用程式則不需要\n• 可能干擾行車記錄器的網路使用\n\n停用是安全的：只會影響地圖上的內建路況圖層。導航、藍牙和其他所有車輛功能都不受影響。\n\n停用後需要硬重開機（長按中控台按鍵 5 秒）。';

  @override
  String get dialog_traffic_enable_title => '請重新啟動BYD交通監測器?';

  @override
  String get dialog_traffic_enable_message =>
      'BYD 交通監測器目前已禁用.\n\n重新啟動將恢復導航地圖內置的交通覆蓋.請注意,它將在背景中運行,並消耗移動數據.\n\n啟動後需要硬式重啟 (保持中盤控制台按 5 秒).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return '交通監測器$arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      '變更已套用。\n\n請立即執行硬重開機:\n長按中控台按鍵 5 秒。';

  @override
  String get traffic_monitor_loading => '交通監測:檢查...';

  @override
  String get traffic_monitor_tap_to_check => '交通監測器 (點擊查詢)';

  @override
  String get reset_label_trips => '行程';

  @override
  String get reset_label_soc_history => '關於 SoC + 12V 的歷史';

  @override
  String get reset_label_soh => '顯示的數量';

  @override
  String get reset_label_recordings => '錄影';

  @override
  String get reset_label_sentry_events => '監控活動';

  @override
  String get reset_label_proximity => '靠近的記錄';

  @override
  String get reset_label_trip_files => '旅行遠隔測量檔案';

  @override
  String get toast_access_code_copied => '已複製的接入代碼';

  @override
  String get dialog_regenerate_token_title => '恢復代號';

  @override
  String get dialog_regenerate_token_message =>
      '目前的權杖將失效。所有使用中的工作階段都會被登出。要繼續嗎？';

  @override
  String get toast_token_regenerated_logged_out => '已產生新的權杖。所有工作階段皆已登出。';

  @override
  String get toast_token_regenerated_restart => '權杖已重新產生，服務可能需要重新啟動以套用變更。';

  @override
  String get toast_token_regenerated_no_notify => '權杖已重新產生，但無法通知後台服務。';

  @override
  String get toast_token_regenerated => '標誌再生';

  @override
  String get dashboard_no_tunnel => '沒有道運行';

  @override
  String get dashboard_starting_zrok => '開始Zrok道...';

  @override
  String get dashboard_waiting_url => '在等待道URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 執行中';
  }

  @override
  String get tunnel_label_zrok => 'Zrok';

  @override
  String get clip_label_access_code => '存取碼';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return '$arg1 沒有必要的配置';
  }

  @override
  String get dialog_zrok_token_title => 'Zrok道標記';

  @override
  String get dialog_zrok_token_message => '請輸入 Zrok 啟用權杖。\n取得位置: zrok.io';

  @override
  String get toast_token_cannot_be_empty => '符號不能空';

  @override
  String get dialog_zrok_reset_title => '重置Zrok環境';

  @override
  String get dialog_zrok_reset_message =>
      '此操作將:\n• 停止正在執行的 zrok 通道\n• 從本裝置移除 zrok 環境\n• 刪除已儲存的權杖\n\n您需要重新輸入權杖並重新啟用。這會佔用您在 zrok.io 上 5 個裝置名額中的 1 個。\n\n確定嗎？';

  @override
  String get toast_resetting_zrok => '還原zrok環境...';

  @override
  String get toast_zrok_reset_success => 'Zrok環境重置. 輸入新的權杖,重新設定.';

  @override
  String get toast_zrok_reset_partial => '環境重置 (權杖檔案可能需要手動清理)';

  @override
  String toast_zrok_reset_warnings(Object arg1) {
    return '環境重置 (附警告:$arg1)';
  }

  @override
  String get zrok_no_token_configured => '尚未設定權杖。點按以進行設定。';

  @override
  String get toast_zrok_token_saved => '存儲的權杖';

  @override
  String get toast_zrok_token_save_failed => '沒有儲存權杖';

  @override
  String get toast_zrok_token_deleted => '已取消的標籤';

  @override
  String get toast_zrok_token_delete_failed => '無法刪除權杖';

  @override
  String toast_fetching_log(Object arg1) {
    return '帶來$arg1日志...';
  }

  @override
  String get toast_log_empty_or_missing => '記錄檔是空的或沒有找到';

  @override
  String get toast_log_empty => '帳號檔案是空的';

  @override
  String toast_log_save_failed(Object arg1) {
    return '未能保存日志: $arg1';
  }

  @override
  String get toast_log_not_found => '沒有找到或無法閱讀的日志檔案';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1 記錄 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return '分享$arg1日志';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 日誌 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return '源:$arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return '輸出:$arg1';
  }

  @override
  String log_header_truncated(Object arg1) {
    return '註: 截圖截圖為10000行 (總數:$arg1行)';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return '不能播放影片: $arg1';
  }

  @override
  String get dialog_delete_recording_title => '刪除錄影';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '要刪除 $arg1 嗎？\n此操作無法復原。';
  }

  @override
  String get toast_recording_deleted => '已取消錄影';

  @override
  String get toast_recording_delete_failed => '無法刪除錄影';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '已刪除 $arg1 個，$arg2 個失敗';
  }

  @override
  String get play_with_chooser => '玩一下';

  @override
  String setup_version_banner(Object arg1) {
    return '已更新至 v$arg1 — 請重新確認自動啟動，BYD 每次安裝都會清除它';
  }

  @override
  String get setup_overlay_already_granted => '已授予';

  @override
  String camera_current_manual(Object arg1) {
    return '目前:$arg1相機 (手動)';
  }

  @override
  String get camera_current_auto_label => '目前：自動';

  @override
  String get soh_estimation_active => '估算活動';

  @override
  String get soh_oem_readout => '車輛 SOH 讀數 — 等待計算估值';

  @override
  String get soh_nominal_baseline => '標稱基準 — 等待可信的 SOH 資料';

  @override
  String get soh_no_estimate_yet => '目前沒有估算 等待數據';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '選擇$arg1';
  }

  @override
  String get video_player_playback_error => '播放錯誤';

  @override
  String get video_player_no_events => '沒有事件';

  @override
  String get daemon_configuration_required => '需要配置';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => '影片播放器';

  @override
  String get status_overlay_notif_title => 'BladeWatch 狀態';

  @override
  String get status_overlay_notif_text => '狀態覆蓋活動';

  @override
  String get rail_dashboard => '儀表板';

  @override
  String get rail_live => '即時';

  @override
  String get rail_recordings => '錄影';

  @override
  String get rail_vehicle => '車輛';

  @override
  String get rail_trips => '行程';

  @override
  String get rail_location => '位置';

  @override
  String get rail_diagnostics => '診斷';

  @override
  String get rail_settings => '設定';

  @override
  String get settings_section_appearance => '這樣的外觀';

  @override
  String get settings_section_recording => '錄影';

  @override
  String get settings_section_surveillance => '監控';

  @override
  String get settings_section_daemons => '服務';

  @override
  String get settings_section_privacy => '隱私與資料';

  @override
  String get settings_section_overlay => '狀態覆蓋';

  @override
  String get settings_overlay_subtitle => '選擇浮動狀態平板的哪些部分保持可見.';

  @override
  String get settings_overlay_camera_title => '攝影機表示';

  @override
  String get settings_overlay_camera_subtitle => '在錄影活動中顯示REC/ PROX標志.';

  @override
  String get settings_overlay_trip_title => '表示 Trip';

  @override
  String get settings_overlay_trip_subtitle => '顯示TRIP章, 在檢測行程進行時.';

  @override
  String get settings_section_about => '關於';

  @override
  String get settings_subrail_overline => '設定方式';

  @override
  String get cd_settings_subrail => '設定側欄';

  @override
  String get settings_privacy_title => '隱私與資料';

  @override
  String get settings_privacy_body => '重置將清除錄影索引、已快取的憑證、服務狀態及裝置上的偏好設定，此操作無法復原。';

  @override
  String get settings_about_title => '關於BladeWatch';

  @override
  String get settings_about_version_label => '版本';

  @override
  String get settings_about_package_label => '建構';

  @override
  String get settings_about_support_section => '靠像你這樣的人動力';

  @override
  String get settings_about_support_share_title => '告訴另一位車主';

  @override
  String get settings_about_support_share_value =>
      '每個共享的連結都幫助另一位BYD老板發現BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      '查看BladeWatch 開放源監控和Dashcam的BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => '分享過度驅動';

  @override
  String get settings_about_open_link_failed => '沒有辦法打開連結.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return '找不到瀏覽器。已複製網址: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => '在下次發行中,';

  @override
  String get settings_about_support_kofi_value => '咖啡讓晚上的約定持續.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => '授權使用';

  @override
  String get settings_about_license_value => '開源. 按下來查看全文.';

  @override
  String get settings_about_source_title => '源代碼';

  @override
  String get settings_about_source_value => '沒有任何相關資訊,';

  @override
  String get settings_about_license_url =>
      'https://github.com/yash-srivastava/BladeWatch-release/blob/main/LICENSE';

  @override
  String get settings_about_source_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_star_title => '在 GitHub 上放一個';

  @override
  String get settings_about_star_value => '需要一秒, 這意味著很多.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => '致謝';

  @override
  String get settings_about_thanks_subtitle => '在貢獻者和支持者的幫助下打造。';

  @override
  String get settings_about_contributors_title => '貢獻者';

  @override
  String get settings_about_supporters_title => '支持者';

  @override
  String get settings_about_thanks_empty => '隨著大家加入,這裡會被填滿。';

  @override
  String get settings_theme_label => '主題:';

  @override
  String get settings_theme_auto => '自動（跟隨系統）';

  @override
  String get settings_theme_light => '淺色';

  @override
  String get settings_theme_dark => '深色';

  @override
  String get settings_language_label => '語言';

  @override
  String get settings_drive_side_label => '導覽側邊';

  @override
  String get settings_drive_side_subtitle => '選擇導覽選單顯示在螢幕的哪一側。';

  @override
  String get settings_drive_side_left => '左側';

  @override
  String get settings_drive_side_left_hint => '左駕 · 預設';

  @override
  String get settings_drive_side_right => '右側';

  @override
  String get settings_drive_side_right_hint => '右駕車輛';

  @override
  String get settings_drive_side_auto => '自動';

  @override
  String get settings_drive_side_auto_hint => '依車輛偵測';

  @override
  String get settings_drive_side_caption_left => '導覽在左側';

  @override
  String get settings_drive_side_caption_right => '導覽在右側';

  @override
  String get settings_drive_side_caption_auto_left => '自動 — 車輛回報為左駕';

  @override
  String get settings_drive_side_caption_auto_right => '自動 — 車輛回報為右駕';

  @override
  String get settings_drive_side_caption_auto_unknown => '自動 — 車輛無法使用，採用左側';

  @override
  String get recordings_title => '錄影';

  @override
  String get recordings_segment_dashcam => '行車記錄';

  @override
  String get recordings_segment_surveillance => '監控';

  @override
  String get recordings_action_settings => '設定';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '現在的$arg1 · $arg2總數 · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return '行車記錄 · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return '監控 · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => '選擇錄影';

  @override
  String get recordings_preview_placeholder_body => '請按左邊任何項目的鍵,';

  @override
  String get diagnostics_section_adb_console => 'ADB 主控台';

  @override
  String get diagnostics_section_traffic => '交通監測器';

  @override
  String get diagnostics_section_camera_probe => '攝影機探測器';

  @override
  String get diagnostics_section_battery => '電池健康度';

  @override
  String get diagnostics_section_performance => '效能';

  @override
  String get diagnostics_hero_title => '系統診斷';

  @override
  String get diagnostics_hero_subtitle => '檢查了該裝置的情況,';

  @override
  String get diagnostics_health_clear => '一切正常';

  @override
  String get diagnostics_health_section => '運作狀況';

  @override
  String get diagnostics_health_network => '網路';

  @override
  String get diagnostics_health_storage => '儲存空間';

  @override
  String get diagnostics_health_camera => '攝影機';

  @override
  String get diagnostics_health_battery => '電池';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => '線上';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return '道 · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => '線上';

  @override
  String get diagnostics_tunnel_state_offline => '離線';

  @override
  String get diagnostics_tunnel_state_connecting => '連線中';

  @override
  String get diagnostics_network_mobile => '行動網路';

  @override
  String get diagnostics_network_ethernet => '乙太網路';

  @override
  String get diagnostics_network_offline => '離線';

  @override
  String diagnostics_storage_used_line(Object arg1, Object arg2) {
    return '使用的$arg1剪辑 ·$arg2';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 免費使用';
  }

  @override
  String get diagnostics_logs_card_title => '活動記錄';

  @override
  String get diagnostics_logs_card_subtitle => '在運行服務中流出.';

  @override
  String get diagnostics_tools_section => '工具';

  @override
  String get diagnostics_traffic_subtitle => '觀看直播網路通訊.';

  @override
  String get diagnostics_camera_probe_subtitle => '檢查連接的攝影機流量.';

  @override
  String get diagnostics_adb_subtitle => '開啟裝置上的終端機。';

  @override
  String get diagnostics_battery_subtitle => '檢查SOH的細胞,';

  @override
  String get diagnostics_settings_subtitle => '應用程式偏好,主題和語言.';

  @override
  String get settings_action_reset_data => '重置資料…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => '守望中';

  @override
  String get dashboard_subtitle_all_systems => '所有系統都在網路上';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '在網路上提供$arg1的$arg2服務';
  }

  @override
  String get dashboard_subtitle_no_tunnel => '遠端接入無線';

  @override
  String get dashboard_metric_recordings => '這就是今天的錄影.';

  @override
  String get dashboard_metric_storage => '使用的儲存';

  @override
  String get dashboard_metric_tunnel => '遠端接入';

  @override
  String get dashboard_metric_services => '背景服務';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => '車輛';

  @override
  String get dashboard_chip_recording_active => '正在錄影\n';

  @override
  String get dashboard_chip_recording_idle => '閒置';

  @override
  String get dashboard_vehicle_tap_to_set => '按一下設定';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => '設定電池容量';

  @override
  String get vehicle_dialog_capacity_label => '容量 (kWh)';

  @override
  String get vehicle_dialog_capacity_suffix => 'kWh';

  @override
  String get vehicle_dialog_capacity_helper => '8至120 kWh。保留以使用模型預設值。';

  @override
  String get vehicle_dialog_model_label => '車型';

  @override
  String get vehicle_dialog_save => '儲存';

  @override
  String get vehicle_dialog_reset => '重設為自動偵測';

  @override
  String get vehicle_dialog_invalid_capacity => '容量必須為 8 - 120 kWh';

  @override
  String vehicle_dialog_summary_capacity(Object arg1) {
    return '容量:$arg1';
  }

  @override
  String vehicle_dialog_summary_soh(Object arg1) {
    return 'SOH: $arg1';
  }

  @override
  String vehicle_dialog_soh_source_live(Object arg1) {
    return '$arg1%(即時)';
  }

  @override
  String vehicle_dialog_soh_source_calibration(Object arg1) {
    return '$arg1%(上次充電)';
  }

  @override
  String vehicle_dialog_soh_source_oem(Object arg1) {
    return '$arg1%(車輛)';
  }

  @override
  String vehicle_dialog_soh_source_nominal(Object arg1) {
    return '$arg1%(標稱)';
  }

  @override
  String get settings_recording_tab_status => '狀態';

  @override
  String get settings_recording_tab_capture => '擷取';

  @override
  String get settings_recording_tab_quality => '畫質';

  @override
  String get settings_recording_tab_storage => '儲存';

  @override
  String get settings_recording_status_title => '錄影狀態';

  @override
  String get settings_recording_status_current_state => '目前狀態';

  @override
  String get settings_recording_status_today_count => '今日錄影數';

  @override
  String get settings_recording_mode_title => '錄影模式（ACC 開啟）';

  @override
  String get settings_recording_mode_description => '選擇行車時行車記錄器何時錄影。';

  @override
  String get settings_recording_mode_none_label => '不錄影（預設）';

  @override
  String get settings_recording_mode_none_desc => '不錄影 — 監控仍然運作';

  @override
  String get settings_recording_mode_continuous_label => '持續錄影';

  @override
  String get settings_recording_mode_continuous_desc => '行車時全程錄影';

  @override
  String get settings_recording_mode_drive_label => '行駛模式';

  @override
  String get settings_recording_mode_drive_desc => '僅在車輛行駛時錄影';

  @override
  String get settings_recording_mode_proximity_label => '接近守衛';

  @override
  String get settings_recording_mode_proximity_desc => '偵測到移動時錄影';

  @override
  String get settings_recording_limit_title => '錄影長度上限';

  @override
  String get settings_recording_limit_description => '每個檔案的最大長度。錄影會依此間隔分割為新檔案。';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => '錄影畫質';

  @override
  String get settings_recording_storage_title => '錄影儲存';

  @override
  String get settings_recording_storage_location_label => '儲存位置';

  @override
  String get settings_recording_storage_internal => '內部儲存';

  @override
  String get settings_recording_storage_sd_card => 'SD 卡';

  @override
  String get settings_recording_storage_sd_card_na => 'SD 卡（不可用）';

  @override
  String get settings_recording_storage_limit_label => '儲存上限 — 達到後自動刪除最舊的';

  @override
  String get settings_recording_storage_usage_label => '儲存空間使用量';

  @override
  String get settings_recording_storage_files_label => '檔案';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '已用 $arg1 / 上限 $arg2';
  }

  @override
  String settings_recording_storage_files(Object arg1) {
    return '$arg1 個錄影';
  }

  @override
  String get settings_recording_storage_path_label => '路徑';

  @override
  String get settings_recording_storage_sd_free_label => 'SD 卡可用空間';

  @override
  String get settings_recording_storage_internal_free_label => '內部可用空間';

  @override
  String get settings_recording_format_title => '格式化外接儲存裝置';

  @override
  String get settings_recording_format_warning => '將永久清除 SD 卡或 USB 裝置上的所有資料。';

  @override
  String get settings_recording_format_confirm => '再次點按 — 所有資料將被清除';

  @override
  String get settings_recording_format_running => '正在格式化… 請稍候';

  @override
  String get settings_recording_format_button => '格式化 SD 卡 / USB';

  @override
  String get settings_recording_format_no_drive => '找不到可卸除式裝置';

  @override
  String settings_recording_format_success(Object arg1) {
    return '格式化成功。新路徑：$arg1';
  }

  @override
  String get settings_recording_sync_title => '資料庫目錄';

  @override
  String get settings_recording_sync_description => '將錄影索引與磁碟上的檔案核對。';

  @override
  String get settings_recording_sync_running => '正在同步…';

  @override
  String get settings_recording_sync_button => '同步資料庫';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return '已同步：+$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => '同步已在進行中';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return '同步失敗：$arg1';
  }

  @override
  String get settings_recording_apply_button => '套用變更';

  @override
  String get settings_recording_dismiss => '關閉';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return '暫不支援啟動/停止 $arg1';
  }

  @override
  String get settings_daemons_zrok_configure => '設定';

  @override
  String get settings_daemons_zrok_reset_button => '重設環境';

  @override
  String vehicle_dialog_summary_effective(Object arg1) {
    return '有效: $arg1 kWh';
  }

  @override
  String vehicle_dialog_summary_model(Object arg1) {
    return '車型: $arg1';
  }

  @override
  String vehicle_dialog_summary_calibration(Object arg1, Object arg2) {
    return '最后校準:$arg1% 在$arg2';
  }

  @override
  String get vehicle_dialog_soh_unavailable => '無法取得';

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '使用的$arg1 · 免費的$arg2';
  }

  @override
  String get dashboard_metric_storage_chip_pending => '儲存空間 —';

  @override
  String get dashboard_tunnel_offline => '離線';

  @override
  String get dashboard_tunnel_online => '線上';

  @override
  String get dashboard_tunnel_connecting => '連線中…';

  @override
  String get dashboard_trips_this_week => '本週';

  @override
  String dashboard_trips_count(Object arg1) {
    return '$arg1 趟行程';
  }

  @override
  String dashboard_trips_distance_km(Object arg1) {
    return '$arg1 km';
  }

  @override
  String dashboard_trips_distance_mi(Object arg1) {
    return '$arg1 英里';
  }

  @override
  String dashboard_trips_duration(Object arg1) {
    return '$arg1';
  }

  @override
  String get dashboard_trips_label_trips => '行程';

  @override
  String get dashboard_trips_label_distance => '距離';

  @override
  String get dashboard_trips_label_time => '行駛時間';

  @override
  String get dashboard_trips_no_data => '本週尚無行程紀錄';

  @override
  String get dashboard_trips_unavailable => '開始行駛以查看統計';

  @override
  String get dashboard_trips_loading => '載入中…';

  @override
  String get dashboard_trips_view_all => '查看所有行程';

  @override
  String get dashboard_action_live => '在線觀看';

  @override
  String get dashboard_action_live_subtitle => '開啟攝影機畫面';

  @override
  String get dashboard_action_recordings => '錄影';

  @override
  String get dashboard_action_settings => '設定';

  @override
  String get dashboard_action_settings_subtitle => '喜好與關于';

  @override
  String get settings_hero_title => '設定';

  @override
  String get settings_hero_overline => '超越使用量';

  @override
  String get settings_hero_subtitle => '調節外觀,錄影,監控和裝置上的數據.';

  @override
  String get settings_overline_preferences => '偏好設定';

  @override
  String get settings_overline_about_data => '關於 & 資料';

  @override
  String get settings_quick_theme_label => '主題:';

  @override
  String get settings_quick_language_label => '語言';

  @override
  String get settings_section_recording_subtitle => '預備/後期緩衝器,代克,存儲限制.';

  @override
  String get settings_section_surveillance_subtitle => '檢測區域,時間表,運動敏感性.';

  @override
  String get settings_section_daemons_subtitle => 'Zrok 隧道與後台服務。';

  @override
  String get settings_about_row_title => '關於BladeWatch';

  @override
  String get settings_about_row_subtitle => '版本,授權,支持開發.';

  @override
  String get settings_reset_row_subtitle => '或是所有隱藏資料.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle => '標題,語言和視覺偏好.';

  @override
  String get settings_theme_active_auto_caption => '自動跟隨系統主題。';

  @override
  String get settings_theme_active_light_caption => '一律使用淺色主題。';

  @override
  String get settings_theme_active_dark_caption => '一律使用深色主題。';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg2 種語言中有 $arg1 種可用';
  }

  @override
  String get settings_language_card_title => '顯示語言';

  @override
  String get settings_privacy_stance_title => '預設在裝置上';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch 完全在車機上執行。除了您明確設定的通道和整合之外，沒有任何遙測資料離開您的車輛。';

  @override
  String get settings_privacy_overline_storage => '地方儲存';

  @override
  String get settings_privacy_overline_reset => '數據重置';

  @override
  String get settings_privacy_storage_clips_label => '在磁盤上的剪辑';

  @override
  String get settings_privacy_storage_size_label => '總體尺寸';

  @override
  String get settings_privacy_storage_unavailable => '沒有提供';

  @override
  String settings_privacy_storage_count_format(Object arg1) {
    return '片 $arg1';
  }

  @override
  String settings_privacy_storage_count_format_plural(Object arg1) {
    return '片 $arg1';
  }

  @override
  String get settings_privacy_reset_subtitle => '選取類別：錄影、事件、服務設定、已快取的遙測資料…';

  @override
  String get settings_developer_overline => '開發者';

  @override
  String get settings_developer_timing_logs_title => '服務計時日誌';

  @override
  String get settings_developer_timing_logs_subtitle =>
      '在服務啟動期間記錄耗時標記。一般使用時請停用以保持 logcat 乾淨。';

  @override
  String get settings_developer_debug_logs_title => '開發者除錯日誌';

  @override
  String get settings_developer_debug_logs_subtitle =>
      '將所有 Activity 與 Fragment 生命週期事件及啟動步驟記錄至 /storage/emulated/0/BladeWatch/data/debug_app.log。當機一律會擷取。預設為關閉。';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return '攝影機$arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return '攝影機$arg1 (手動)';
  }

  @override
  String get diagnostics_camera_value_probing => '偵測中…';

  @override
  String get diagnostics_camera_value_offline => '離線';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => '目前的數據';

  @override
  String dashboard_recordings_value_live(Object arg1) {
    return '● $arg1';
  }

  @override
  String get dashboard_insight_welcome => '歡迎您來! 超駕駛是您的第二雙眼睛.';

  @override
  String dashboard_insight_parked_charged_kwh(Object arg1, Object arg2) {
    return '在停車場上, 接收了$arg1 (≈$arg2)';
  }

  @override
  String dashboard_insight_parked_charged(Object arg1) {
    return '在停車場上拿起$arg1';
  }

  @override
  String dashboard_insight_parked_drained_kwh(Object arg1, Object arg2) {
    return '自從你停車後使用了$arg1 (≈$arg2)';
  }

  @override
  String dashboard_insight_parked_drained(Object arg1) {
    return '自從你停車後使用了$arg1';
  }

  @override
  String dashboard_insight_last_alert(Object arg1) {
    return '最后的監控警報: $arg1';
  }

  @override
  String dashboard_insight_last_charge(Object arg1, Object arg2) {
    return '最后一次充電: +$arg1 在 $arg2';
  }

  @override
  String dashboard_insight_storage_milestone(Object arg1, Object arg2) {
    return '$arg1剪辑 · $arg2錄製';
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
    return '$arg1 小時 $arg2 分';
  }

  @override
  String dashboard_insight_today_clips(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '今天拍攝的$arg1片段',
      one: '截圖是今天錄製的 $arg1',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_days_hours(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '在網路上駕駛超過$arg1天,$arg2小時',
      one: '在 $arg1日, $arg2小時上線駕駛',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_hours(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '在網路上駕駛超過$arg1小時',
      one: '在 $arg1小時內開車',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_minutes(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 min',
      one: '$arg1 min',
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
  String get vehicle_tab_trunk => '後車廂';

  @override
  String get vehicle_tab_climate => '空調';

  @override
  String get vehicle_tab_seats => '座位';

  @override
  String get vehicle_tab_windows => '車窗';

  @override
  String get vehicle_tab_lights => '燈光';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => '充電';

  @override
  String get vehicle_locked => '鎖定';

  @override
  String get vehicle_unlocked => '已解鎖';

  @override
  String get vehicle_range_label => '續航里程';

  @override
  String get vehicle_data_unavailable => '車輛資料無法使用。';

  @override
  String get vehicle_action_failed => '操作失敗。請檢查車輛連線。';

  @override
  String get vehicle_open_trunk => '開啟後車廂';

  @override
  String get vehicle_close_trunk => '關閉後車廂';

  @override
  String get vehicle_trunk_info_open => '開啟後車廂將先解鎖車輛。';

  @override
  String get vehicle_ac_on => 'AC 開啟';

  @override
  String get vehicle_ac_off => 'AC 關閉';

  @override
  String get vehicle_max_cooling_on => '最大冷氣：開';

  @override
  String get vehicle_max_cooling_off => '最大冷氣：關';

  @override
  String get vehicle_temp_label => '溫度';

  @override
  String get vehicle_fan_speed_label => '風速';

  @override
  String vehicle_fan_level(Object arg1) {
    return '第 $arg1 段';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return '車內：$arg1°C';
  }

  @override
  String get vehicle_seat_driver => '駕駛座';

  @override
  String get vehicle_seat_passenger => '副駕駛座';

  @override
  String get vehicle_seat_no_controls => '此車輛無可用的座椅控制。';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return '加熱 $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return '通風 $arg1';
  }

  @override
  String get vehicle_heat_off => '（關）';

  @override
  String get vehicle_heat_low => '（低）';

  @override
  String get vehicle_heat_high => '（高）';

  @override
  String get vehicle_seat_pos_1 => '位置 1';

  @override
  String get vehicle_seat_pos_2 => '位置 2';

  @override
  String get vehicle_all_windows => '所有車窗';

  @override
  String get vehicle_window_front_left => '左前';

  @override
  String get vehicle_window_front_right => '右前';

  @override
  String get vehicle_window_rear_left => '左後';

  @override
  String get vehicle_window_rear_right => '右後';

  @override
  String get vehicle_window_close => '關閉';

  @override
  String get vehicle_window_close_vent => '關閉通風';

  @override
  String get vehicle_window_vent_12 => '通風 12%';

  @override
  String get vehicle_window_open_all => '全部開啟';

  @override
  String get vehicle_sunroof => '天窗';

  @override
  String get vehicle_sunshade => '遮陽簾';

  @override
  String get vehicle_btn_drl_title => '日子運行燈';

  @override
  String get vehicle_btn_slw_title => '預警速度限制';

  @override
  String get vehicle_control_section_charge_cap => '充電上限';

  @override
  String get vehicle_charge_cap_not_supported => '此車輛不支援充電上限。';

  @override
  String get vehicle_charge_limit_label => '充電上限';

  @override
  String get vehicle_enable_charge_limit => '啟用充電上限';

  @override
  String get vehicle_charge_limit_range => '最低 50%，最高 100%';

  @override
  String get vehicle_tyre_no_signal => '無訊號';

  @override
  String get vehicle_tyre_slow_leak => '緩慢漏氣';

  @override
  String get vehicle_tyre_fast_leak => '快速漏氣';

  @override
  String get vehicle_tyre_low => '偏低';

  @override
  String get vehicle_tyre_high => '偏高';

  @override
  String get vehicle_tyre_ok => '正常';

  @override
  String get vehicle_tyre_check_pressure => '檢查胎壓';

  @override
  String get vehicle_toggle_on => '開';

  @override
  String get vehicle_toggle_off => '關';

  @override
  String get vehicle_err_climate_control => '空調控制失敗。';

  @override
  String get vehicle_err_max_cooling => '最大冷氣失敗。';

  @override
  String get vehicle_err_drl_control => '日行燈控制失敗。';

  @override
  String get vehicle_err_slw_control => 'ADAS 控制失敗。';

  @override
  String get vehicle_err_charge_limit_toggle => '充電上限切換失敗。';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return '調降 $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return '調升 $arg1';
  }

  @override
  String get vehicle_stale_connecting => '連線中…';

  @override
  String get vehicle_appearance_model_title => '選擇車型';

  @override
  String get vehicle_appearance_custom_color => '自訂顏色';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return '電量：$arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return '續航：$arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => '電量：—';

  @override
  String get vehicle_status_range_unknown => '續航：—';

  @override
  String get startup_subtitle => '正在準備您的行車記錄器';

  @override
  String get startup_header_preparing => '準備中…';

  @override
  String get startup_header_starting => '啟動中…';

  @override
  String get startup_header_verifying => '即將就緒…';

  @override
  String get startup_header_ready => '一切就緒';

  @override
  String get startup_daemon_camera => '攝影機';

  @override
  String get startup_daemon_camera_desc => '即時影像與錄影';

  @override
  String get startup_daemon_sentry => '哨兵模式';

  @override
  String get startup_daemon_sentry_desc => '移動偵測與警報';

  @override
  String get startup_daemon_parking => '停車守護';

  @override
  String get startup_daemon_parking_desc => '停車時持續看守';

  @override
  String get startup_status_waiting => '等待中';

  @override
  String get startup_status_starting => '啟動中';

  @override
  String get startup_status_ready => '就緒';

  @override
  String get startup_status_failed => '失敗';

  @override
  String get startup_continue_anyway => '仍要繼續';

  @override
  String get startup_continue => '繼續 →';

  @override
  String get live_retry => '重試';

  @override
  String get live_connecting => '正在連線攝影機…';

  @override
  String live_error_fmt(Object arg1) {
    return '錯誤：$arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return '攝影機無法使用\n$arg1';
  }

  @override
  String get live_direction_all => '全部';

  @override
  String get live_direction_front => '前';

  @override
  String get live_direction_right => '右';

  @override
  String get live_direction_rear => '後';

  @override
  String get live_direction_left => '左';

  @override
  String get trip_no_route_data => '此行程無路線資料';

  @override
  String get trips_tab_trips => '行程';

  @override
  String get trips_tab_stats => '統計';

  @override
  String get trips_tab_storage => '儲存空間';

  @override
  String get trips_filter_7_days => '7 天';

  @override
  String get trips_filter_14_days => '14 天';

  @override
  String get trips_filter_30_days => '30 天';

  @override
  String trips_load_error(Object message) {
    return '錯誤：$message';
  }

  @override
  String get trips_empty_state => '尚未記錄任何行程';

  @override
  String get trips_period_summary_title => '期間摘要';

  @override
  String get trips_stat_trips => '行程';

  @override
  String get trips_stat_hours => '小時';

  @override
  String get trips_stat_efficiency => '效率';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return '評分：$score';
  }

  @override
  String get trips_driver_score_title => '駕駛評分';

  @override
  String trips_driver_score_overall(Object score) {
    return '總分：$score / 100';
  }

  @override
  String get trips_range_title => '個人化續航里程';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD 估算：$km 公里';
  }

  @override
  String get trips_range_no_data => '資料尚不足';

  @override
  String get trips_dna_title => '駕駛 DNA';

  @override
  String get trips_dna_anticipation => '預判';

  @override
  String get trips_dna_smoothness => '平順度';

  @override
  String get trips_dna_speed_discipline => '速度遵守';

  @override
  String get trips_dna_efficiency => '效率';

  @override
  String get trips_dna_consistency => '穩定性';

  @override
  String get trips_storage_title => '行程儲存空間';

  @override
  String get trips_storage_analytics_label => '行程分析';

  @override
  String get trips_storage_rate_label => '電價';

  @override
  String get trips_storage_distance_unit_label => '距離單位';

  @override
  String get trips_storage_location_label => '儲存位置';

  @override
  String get trips_storage_internal => '內部儲存';

  @override
  String get trips_storage_sd_card => 'SD 卡';

  @override
  String get trips_storage_sd_card_unavailable => 'SD 卡（不可用）';

  @override
  String get trips_storage_apply => '套用變更';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '已用 $used $unit / 上限 $limit MB · $count 次行程';
  }

  @override
  String get trips_sync_title => '資料庫目錄';

  @override
  String get trips_sync_description => '將行程索引與磁碟上的遙測檔案核對。';

  @override
  String get trips_sync_button => '同步資料庫';

  @override
  String get trips_sync_running => '正在同步…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return '同步成功：+$added -$removed（共 $total 筆）';
  }

  @override
  String get trips_sync_failed_generic => '同步失敗';

  @override
  String get trips_detail_summary_title => '行程摘要';

  @override
  String get trips_detail_distance => '距離';

  @override
  String get trips_detail_duration => '時長';

  @override
  String get trips_detail_energy => '能耗';

  @override
  String get trips_detail_avg_speed => '平均速度';

  @override
  String get trips_detail_max_speed => '最高速度';

  @override
  String get trips_detail_soc => '電量';

  @override
  String get trips_detail_cost => '費用';

  @override
  String get trips_detail_ext_temp => '外部溫度';

  @override
  String get trips_detail_elev_gain => '爬升高度';

  @override
  String get trips_detail_scores_title => '駕駛評分';

  @override
  String get trips_detail_unavailable => '行程詳細資料無法使用';

  @override
  String get trips_detail_loading => '正在載入行程…';

  @override
  String trips_detail_route_points(Object count) {
    return '已記錄 $count 個 GPS 點';
  }

  @override
  String get rec_severity_critical => '緊急';

  @override
  String get rec_severity_alert => '警示';

  @override
  String get location_loading_title => '正在載入地圖';

  @override
  String get location_permission_missing_title => '需要位置權限';

  @override
  String get location_permission_denied_title => '權限被拒絕';

  @override
  String get location_provider_disabled_title => 'GPS 已停用';

  @override
  String get location_waiting_for_fix_title => '正在等待 GPS 訊號';

  @override
  String get location_car_location_title => '車輛位置';

  @override
  String get location_stale_title => '位置資訊已過期';

  @override
  String get location_tile_failure_title => '地圖無法使用';

  @override
  String get location_tile_failure_subtitle => '網路無法使用';

  @override
  String get location_error_title => '位置錯誤';

  @override
  String get location_action_grant => '授予';

  @override
  String get location_action_retry => '重試';

  @override
  String get location_mode_auto => '自動';

  @override
  String get location_mode_light => '淺色';

  @override
  String get location_mode_dark => '深色';

  @override
  String get cd_recenter_on_car => '重新置中至車輛';

  @override
  String get recording_lib_no_recordings_normal => '沒有一般錄影';

  @override
  String get recording_lib_no_recordings_sentry => '沒有哨兵事件';

  @override
  String get recording_lib_no_recordings_proximity => '沒有距離事件';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => '人';

  @override
  String get video_player_legend_car => '車';

  @override
  String get video_player_legend_bike => '自行車';

  @override
  String get video_player_legend_motion => '運動';

  @override
  String get recording_lib_proximity_very_close => '非常近';

  @override
  String get recording_lib_proximity_close => '近';

  @override
  String get recording_lib_proximity_mid => '中等';

  @override
  String get recording_lib_proximity_far => '遠';

  @override
  String get surveillance_tab_general => '一般';

  @override
  String get surveillance_tab_detection => '偵測';

  @override
  String get surveillance_tab_recording => '錄影';

  @override
  String get surveillance_tab_storage => '儲存空間';

  @override
  String get surveillance_tab_advanced => '進階';

  @override
  String get surveillance_general_title => '監控模式';

  @override
  String get surveillance_general_enable => '啟用監控';

  @override
  String get surveillance_general_status => '狀態';

  @override
  String get surveillance_general_status_running => '執行中';

  @override
  String get surveillance_general_status_idle => '閒置';

  @override
  String get surveillance_general_events_today => '今日事件';

  @override
  String get surveillance_safe_locations_title => '安全位置';

  @override
  String get surveillance_safe_locations_subtitle => '停在此處時攝影機不會啟動';

  @override
  String get surveillance_safe_locations_enable => '在安全位置停用';

  @override
  String get surveillance_safe_locations_empty => '尚未新增安全位置';

  @override
  String get surveillance_safe_locations_add_current => '將目前位置新增為安全區域';

  @override
  String get surveillance_safe_locations_no_gps => 'GPS 位置無法使用';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_roi_title => '偵測區域';

  @override
  String get surveillance_roi_description => '點按新增頂點，拖曳可移動頂點。最少三個，最多八個。';

  @override
  String get surveillance_roi_enable => '僅在此區域內偵測';

  @override
  String get action_undo => '復原';

  @override
  String get surveillance_detection_title => '偵測設定';

  @override
  String get surveillance_detection_preset_label => '環境預設';

  @override
  String get surveillance_preset_outdoor => '戶外';

  @override
  String get surveillance_preset_garage => '車庫';

  @override
  String get surveillance_preset_street => '街道';

  @override
  String get surveillance_preset_custom => '自訂';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return '靈敏度（1=嚴格，5=靈敏）：$arg1';
  }

  @override
  String get surveillance_detection_objects_label => '偵測對象';

  @override
  String get surveillance_detection_object_person => '人';

  @override
  String get surveillance_detection_object_car => '車';

  @override
  String get surveillance_detection_object_bike => '自行車';

  @override
  String get surveillance_recording_title => '事件錄影';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return '事件前預錄（秒）：$arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return '事件後續錄（秒）：$arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => '監控儲存空間';

  @override
  String get surveillance_storage_location_label => '儲存位置';

  @override
  String get surveillance_storage_internal => '內部';

  @override
  String get surveillance_storage_sd_card => 'SD 卡';

  @override
  String get surveillance_storage_sd_card_na => 'SD 卡（不可用）';

  @override
  String get surveillance_storage_limit_label => '儲存上限 — 達到上限時自動刪除最舊的檔案';

  @override
  String get surveillance_storage_usage_label => '儲存空間使用量';

  @override
  String get surveillance_storage_files_label => '檔案';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '已用 $arg1 / 上限 $arg2';
  }

  @override
  String surveillance_storage_files(Object arg1) {
    return '$arg1 個事件';
  }

  @override
  String get surveillance_storage_path_label => '路徑';

  @override
  String get surveillance_format_title => '格式化外接磁碟機';

  @override
  String get surveillance_format_warning => '將永久清除 SD 卡或 USB 隨身碟上的所有資料。';

  @override
  String get surveillance_format_button => '格式化 SD 卡/USB';

  @override
  String get surveillance_format_confirm => '再次點按 — 所有資料將被清除';

  @override
  String get surveillance_format_running => '正在格式化…請稍候';

  @override
  String get surveillance_dismiss => '關閉';

  @override
  String get surveillance_sync_title => '資料庫目錄';

  @override
  String get surveillance_sync_description => '將監控索引與磁碟上的檔案進行核對。';

  @override
  String get surveillance_sync_button => '同步資料庫';

  @override
  String get surveillance_sync_running => '正在同步…';

  @override
  String get surveillance_advanced_camera_title => '攝影機選擇';

  @override
  String get surveillance_advanced_camera_front => '前';

  @override
  String get surveillance_advanced_camera_right => '右';

  @override
  String get surveillance_advanced_camera_rear => '後';

  @override
  String get surveillance_advanced_camera_left => '左';

  @override
  String get surveillance_advanced_ai_title => 'AI 與嚇阻';

  @override
  String get surveillance_advanced_ai_detection => 'AI 偵測';

  @override
  String get surveillance_advanced_night_mode => '夜間模式';

  @override
  String get surveillance_advanced_deterrent_label => '嚇阻動作';

  @override
  String get surveillance_deterrent_silent => '靜音';

  @override
  String get surveillance_deterrent_horn => '喇叭';

  @override
  String get surveillance_deterrent_flash => '閃光';

  @override
  String get surveillance_apply_button => '套用變更';

  @override
  String get surveillance_apply_failed => '儲存失敗';
}
