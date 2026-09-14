// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'オバードライブの車両モニタリングをバックグラウンドで活性化します.このサービスは画面コンテンツを読み取ったり相互作用したりしません.';

  @override
  String get action_cancel => 'キャンセル';

  @override
  String get action_clear_plain => 'クリア';

  @override
  String get action_select_all => 'すべてを選択';

  @override
  String get action_select_all_short => 'すべて';

  @override
  String get action_delete => '削除';

  @override
  String get action_done => '完成';

  @override
  String get action_remind_me_later => '後で通知';

  @override
  String get action_retry => '再試行';

  @override
  String get action_run => '実行';

  @override
  String get action_clear_output => '出力をクリア';

  @override
  String get cd_camera => 'カメラ';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QRコード';

  @override
  String get cd_show_hide_token => '表示/隠すトークン';

  @override
  String get cd_copy_token => 'トークンをコピー';

  @override
  String get cd_copy_url => 'URLをコピー';

  @override
  String get cd_clear_logs => 'ログをクリア';

  @override
  String get cd_expand_collapse => '展開/折りたたみ';

  @override
  String get cd_recording_status => '録画状態';

  @override
  String get cd_trip_tracking_status => '旅行追跡状況';

  @override
  String get cd_video_thumbnail => '動画のサムネイル';

  @override
  String get cd_play => '再生';

  @override
  String get cd_back => '戻る';

  @override
  String get cd_play_pause => '再生/一時停止';

  @override
  String get cd_player_prev => '前の録画';

  @override
  String get cd_player_next => '次の録画';

  @override
  String get cd_player_maximize => 'プレーヤーを最大化';

  @override
  String get cd_player_minimize => '全画面を終了';

  @override
  String get cd_delete => '削除';

  @override
  String get cd_expand => '展開';

  @override
  String get cd_configure => '設定';

  @override
  String get cd_download_log => 'ログをダウンロード';

  @override
  String get cd_reset => 'リセット';

  @override
  String get cd_battery => 'バッテリー';

  @override
  String get cd_step_completed => 'ステップ完了';

  @override
  String get cd_permission_granted => '許可が認められた';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'トリップ';

  @override
  String get log_entry_default_timestamp => '12:34:56';

  @override
  String get log_entry_default_tag => '[TAG]';

  @override
  String get log_entry_default_message => 'ログメッセージ';

  @override
  String get daemon_card_default_name => 'サービス名';

  @override
  String get daemon_card_default_status => '状態メッセージ';

  @override
  String get daemon_card_subprocesses => 'プロセス';

  @override
  String get logs_panel_title => 'ログ';

  @override
  String get url_connecting => '接続する...';

  @override
  String get camera_selection_title => 'カメラ選択';

  @override
  String get camera_selection_subtitle => 'パノラマカメラ源を選択する';

  @override
  String get camera_current_auto => '現在の: 自動';

  @override
  String get camera_option_auto => '自動 (起動時に検出)';

  @override
  String get camera_option_0 => 'カメラ 0 — Atto トリム';

  @override
  String get camera_option_1 => 'カメラ 1 — Seal (デフォルト)';

  @override
  String get camera_option_2 => 'カメラ2';

  @override
  String get camera_option_3 => 'カメラ3';

  @override
  String get camera_option_4 => 'カメラ4';

  @override
  String get camera_option_5 => 'カメラ5';

  @override
  String get camera_selection_hint =>
      '起動時に車種に合ったカメラを自動選択します。カメラ1 = BYD Seal、カメラ0 = Attoシリーズ。カメラIDを変更した後は、設定を反映させるためにカメラサービスを再起動してください。';

  @override
  String get dashboard_scan_to_connect => 'スキャンして接続';

  @override
  String get dashboard_qr_waiting => 'トンネルを待ってる';

  @override
  String get dashboard_daemons_running_default => '0/5 実行中';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'アクセスコード';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => '再生する記号';

  @override
  String get dashboard_set_password => 'パスワード設定';

  @override
  String get cd_set_password => 'カスタムパスワードを設定';

  @override
  String get dialog_set_password_title => 'カスタムパスワードを設定';

  @override
  String get dialog_set_password_message =>
      '新しいアクセスパスワードを入力してください。自動生成されたトークンを置き換えます。';

  @override
  String get dialog_set_password_hint => '新しいパスワード（12文字以上）';

  @override
  String get toast_password_set => 'パスワードを更新しました';

  @override
  String get toast_password_too_short => 'パスワードは12文字以上にしてください';

  @override
  String get toast_password_save_failed => 'パスワードを保存できません — サービスが未準備です';

  @override
  String get setup_guide_title => '始めること';

  @override
  String get setup_guide_subtitle => '最高の体験を得るための3つの簡単なステップ';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => '言語 を 選ぶ';

  @override
  String get setup_language_body =>
      '既定ではヘッドユニットの言語を使用します。BladeWatch アプリとウェブトンネルで別の言語を選ぶにはタップしてください。';

  @override
  String get setup_language_button => '言語 を 選ぶ';

  @override
  String get setup_autostart_title => '自動開始制限を無効にする';

  @override
  String get setup_autostart_body =>
      'BYD Auto-Start を開くには,下記にタップします.リストで BladeWatch を検索して,ボックスを消します. BYD は,インストールごとにこれを消します. 更新後再起動します.';

  @override
  String get setup_autostart_button => 'BYD オートスタートを開く';

  @override
  String get setup_overlay_title => '他のアプリで表示を許可する';

  @override
  String get setup_overlay_body => '他のアプリの上に記録およびトラッキングの移動状態を示す浮動状態表示を有効にします.';

  @override
  String get setup_overlay_button => 'オーバーレイ設定を開く';

  @override
  String get cd_close => '閉じる';

  @override
  String get language_picker_title => '言語';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return '$arg1 の言語';
  }

  @override
  String get language_picker_subtitle_pending => '言語を選択する';

  @override
  String get language_auto_title => '自動運転';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'フォローシステム · $arg1';
  }

  @override
  String get language_not_saved => '言語を適用しましたが保存できませんでした。アプリを再起動すると元に戻ります。';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · オート';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'コマンドを入力…';

  @override
  String get adb_preset_commands_header => '前設定コマンド';

  @override
  String get adb_output_header => '出力';

  @override
  String get adb_output_ready => '命令を準備する';

  @override
  String get adb_console_hero_title => 'ADB コンソール';

  @override
  String get adb_console_hero_subtitle => 'デバイスでシェルコマンドを実行する';

  @override
  String get adb_console_unavailable_title => 'ADBが接続されていません';

  @override
  String get adb_console_unavailable_body =>
      'この車両では、開発者向けオプションの通常の「USBデバッグ」トグルだけでは不十分です。ヘッドユニット自体のワイヤレスADB（ネットワークデバッグ）設定も有効にする必要があり、システムアップデートでリセットされることがあります。ヘッドユニットでワイヤレスADBを再度有効にするか、USBで接続してください。';

  @override
  String get adb_console_auth_pending_title => '承認待ち';

  @override
  String get adb_console_auth_pending_body =>
      'ヘッドユニットの画面に表示される「USBデバッグを許可しますか？」というプロンプトを確認して承認し、もう一度お試しください。';

  @override
  String get performance_connecting => 'パフォーマンスモニターに接続中…';

  @override
  String get performance_hero_title => 'システムパフォーマンス';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'システム使用率';

  @override
  String get performance_cpu_app_usage => 'アプリ使用率';

  @override
  String get performance_frequency_label => 'クロック周波数';

  @override
  String get performance_temperature_label => '温度';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'メモリ';

  @override
  String get performance_usage_label => '使用率';

  @override
  String get performance_memory_total => '合計';

  @override
  String get performance_memory_used => '使用中';

  @override
  String get performance_memory_app => 'アプリ';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'アプリプロセス';

  @override
  String get performance_threads_label => 'スレッド数';

  @override
  String get performance_gc_cycles_label => 'GC 回数';

  @override
  String get performance_open_fds_label => 'オープン FD 数';

  @override
  String get performance_refreshing_footer => '3秒ごとに更新';

  @override
  String get webview_loading => '荷物...';

  @override
  String get webview_camera_daemon_not_running => 'カメラが起動していません';

  @override
  String get webview_start_camera_daemon =>
      'このページにアクセスするには、サービス画面からカメラサービスを起動してください。';

  @override
  String get zrok_enable_token_hint => 'トークンを有効にする';

  @override
  String get zrok_token_storage_note =>
      'トークンは安全に保存され、アプリとバックグラウンドサービス間で共有されます。';

  @override
  String get zrok_reset_environment => 'Zrok 環境をリセットする';

  @override
  String get zrok_reset_environment_desc =>
      '環境とトークンを削除します. トークンを再び有効にする必要があります (デバイススロットを使用します).';

  @override
  String get reset_title => 'データをリセットする';

  @override
  String get reset_subtitle => 'カテゴリー別で蓄積されたデータを消す';

  @override
  String get reset_warning => 'この操作は元に戻せません。録画、走行履歴、バッテリー履歴は完全に削除されます。';

  @override
  String get reset_cat_trips => '走行履歴';

  @override
  String get reset_cat_trips_desc => '旅行履歴,経路,週刊/月刊のロールアップ';

  @override
  String get reset_cat_soc_history => 'SoC & 12Vの歴史';

  @override
  String get reset_cat_soc_history_desc => 'SoCサンプル,充電セッション,電圧ログ';

  @override
  String get reset_cat_recordings => '録画 (ビデオ)';

  @override
  String get reset_cat_recordings_desc => '録画フォルダのMP4すべて';

  @override
  String get reset_cat_sentry_events => '監視イベント';

  @override
  String get reset_cat_sentry_events_desc => '監視イベントクリップとJSONサイドカー';

  @override
  String get reset_cat_proximity => '接近記録';

  @override
  String get reset_cat_proximity_desc => 'ラダーで触発されたイベント MP4';

  @override
  String get reset_cat_trip_files => '旅行テレメトリファイル';

  @override
  String get reset_cat_trip_files_desc => 'ドライブで1回のJSONテレメトリ';

  @override
  String get recording_lib_chip_any => 'すべて';

  @override
  String get recording_lib_chip_person => '人';

  @override
  String get recording_lib_chip_vehicle => '車両';

  @override
  String get recording_lib_chip_bike => '自転車';

  @override
  String get recording_lib_chip_animal => '動物';

  @override
  String get recording_lib_chip_alert => '警告';

  @override
  String get recording_lib_chip_critical => '重大';

  @override
  String get recording_lib_selected_count_zero => '0 選択した';

  @override
  String get recording_lib_no_recordings => '記録なし';

  @override
  String get recording_lib_filter_button => 'フィルター';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'フィルター · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => '録画を絞り込む';

  @override
  String get recording_lib_filter_apply => '適用';

  @override
  String get recording_lib_filter_reset => 'リセット';

  @override
  String get recording_lib_filter_section_what => '対象';

  @override
  String get recording_lib_filter_section_severity => '重度';

  @override
  String get recording_lib_filter_section_type => 'タイプ';

  @override
  String get recording_lib_chip_type_normal => '標準';

  @override
  String get recording_lib_chip_type_proximity => '近接';

  @override
  String get recording_lib_date_today => '今日';

  @override
  String get recording_lib_date_yesterday => '昨日';

  @override
  String recording_lib_clip_count(Object arg1) {
    return '$arg1クリップ';
  }

  @override
  String recording_lib_clip_count_one(Object arg1) {
    return '$arg1 クリップ';
  }

  @override
  String get recording_lib_pick_date => '日付を決める';

  @override
  String get recording_lib_date_all_days => 'すべての日';

  @override
  String get cd_clear_date_filter => 'すべての日を表示';

  @override
  String get recording_lib_section_morning => '午前';

  @override
  String get recording_lib_section_afternoon => '午後';

  @override
  String get recording_lib_section_evening => '夕方';

  @override
  String get recording_lib_section_night => '夜間';

  @override
  String get cd_previous_day => '前日';

  @override
  String get cd_next_day => '翌日';

  @override
  String get cd_open_filters => 'フィルターを開く';

  @override
  String get cd_clear_filter => 'フィルターをクリア';

  @override
  String get player_title_recording => '録画';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'カメラサービス';

  @override
  String get daemon_name_surveillance => '監視サービス';

  @override
  String get daemon_name_acc => 'ACC監視';

  @override
  String get daemon_name_zrok => 'Zrok Tunnel';

  @override
  String get daemons_hero_title => '背景サービス';

  @override
  String get daemons_count_pending => '運搬サービス...';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 の $arg2 の実行';
  }

  @override
  String get battery_health_title => 'バッテリーの健康';

  @override
  String get battery_health_subtitle => '健康状態';

  @override
  String get battery_health_dashes => '--';

  @override
  String get battery_health_waiting => 'データを待ってる';

  @override
  String get battery_health_source => 'ソース';

  @override
  String get battery_health_method => 'メソッド';

  @override
  String get battery_health_capacity => '容量';

  @override
  String get battery_health_samples => 'サンプル';

  @override
  String get battery_health_last_updated => '最新更新された';

  @override
  String get battery_health_unavailable => '利用できません';

  @override
  String get battery_health_unavailable_desc => 'バッテリー劣化度の推定を利用できません。';

  @override
  String get battery_health_reset => 'SOH推定をリセットする';

  @override
  String get battery_health_reset_desc =>
      'すべてのデータを消去し、最初から推定し直します。バッテリーを交換した場合や、表示値が正しくないと思われる場合に使用します。';

  @override
  String get soh_dialog_model_label => 'モデル';

  @override
  String get soh_dialog_pack_capacity_label => 'パッケージ容量';

  @override
  String get soh_dialog_estimated_capacity_label => '効果的な能力';

  @override
  String get soh_dialog_calibration_anchor_label => '最後のキャリブレーション';

  @override
  String get soh_dialog_source_user => 'ユーザーセット';

  @override
  String get soh_dialog_source_auto => '自動検出';

  @override
  String get soh_dialog_model_not_selected => '選択されていない';

  @override
  String get soh_dialog_capacity_not_detected => '検出されていない';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1%は $arg2で';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1の記録が削除された',
      one: '$arg1の記録は削除',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1録画を削除する',
      one: '$arg1 レコーディングを削除する',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1件の録画を完全に削除します。この操作は元に戻せません。',
      one: '$arg1件の録画を完全に削除します。この操作は元に戻せません。',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'アプリは最新 (v$arg1)';
  }

  @override
  String get toast_storage_permission_required => '記録に必要な保存許可';

  @override
  String get toast_url_copied_short => 'URLをコピーした!';

  @override
  String get toast_camera_set_to_auto => 'カメラを自動設定';

  @override
  String get toast_failed_to_save_short => '保存できなかった';

  @override
  String toast_failed_with_message(Object arg1) {
    return '失敗: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'カメラ $arg1セット 次の ACCサイクル';
  }

  @override
  String get toast_clearing_camera_config => 'カメラの設定をクリアする...';

  @override
  String get toast_restarting_camera_daemon => 'カメラサービスを再起動しています…';

  @override
  String get toast_camera_daemon_restarting => 'カメラサービスをフルプローブで再起動しています';

  @override
  String get toast_camera_restart_failed =>
      '設定はクリアされましたが、サービスの再起動に失敗しました。手動で再起動してください。';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return '失敗: $arg1';
  }

  @override
  String get toast_soh_reset_success => 'SOH推定リセット は次のデータから再計算されます';

  @override
  String get toast_soh_reset_failed_no_daemon =>
      'リセット失敗 — サービスが応答せず、ファイルへの書き込みもできません';

  @override
  String toast_soh_reset_failed_with_message(Object arg1) {
    return 'リセット失敗: $arg1';
  }

  @override
  String get toast_select_at_least_one_category => '少なくとも1つのカテゴリを選択する';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return '復元失敗: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 交通モニター...';
  }

  @override
  String get dialog_close => '閉じる';

  @override
  String get dialog_reset => 'リセット';

  @override
  String get dialog_delete => '削除';

  @override
  String get dialog_save => '保存';

  @override
  String get dialog_enable => '有効';

  @override
  String get dialog_disable => '無効';

  @override
  String get dialog_keep_enabled => '有効のままにする';

  @override
  String get dialog_keep_disabled => '無効のままにする';

  @override
  String get dialog_regenerate => '再生成';

  @override
  String get dialog_reset_selected => '選択項目をリセット';

  @override
  String get dialog_reset_following_title => '次の設定をリセットしますか?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'この操作は取り消せません。\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'リセット完了';

  @override
  String get dialog_traffic_cannot_check_title => 'ステータスを確認できない';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADBが接続されておらず、アプリは自動的に再接続できませんでした。\n\nこの車両では、開発者向けオプションの通常の「USBデバッグ」トグルだけでは不十分です — ヘッドユニット自体のワイヤレスADB(ネットワークデバッグ)設定もオンになっている必要があり、システムアップデートによってリセットされることがあります。ヘッドユニットでワイヤレスADBを再度有効にするか、USBで接続してください。\n\n接続されると、ステータスは自動的に更新されます。';

  @override
  String get dialog_traffic_disable_title => 'BYD Traffic Monitor を無効にしますか？';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) は、バックグラウンドで道路交通状況を継続的に監視する内蔵システムアプリです。\n\n無効にする理由\n\n• モバイルデータを消費します (駐車中でも)\n• バックグラウンドで CPU とバッテリーを使用します\n• 別のナビアプリを使う場合は不要です\n• ドライブレコーダーの通信を妨げることがあります\n\n無効にしても安全です。影響するのは地図上の内蔵交通情報レイヤーだけで、ナビ、Bluetooth、その他の車両機能はそのまま使えます。\n\n無効化後はハードリブートが必要です (センターコンソールのボタンを 5 秒長押し)。';

  @override
  String get dialog_traffic_enable_title => 'BYDトラフィックモニターを再起動する?';

  @override
  String get dialog_traffic_enable_message =>
      'BYD トラフィックモニターは現在無効です.\n\n再起動すると,ナビゲーションマップの内蔵のトラフィックオーバーレイを回復します.バックグラウンドで実行し,モバイルデータを消費することを注意してください.\n\n有効化後にハードリブートが必要です (中央コンソールボタンを5秒保持します).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return '交通モニター $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      '変更が適用されました. 硬いリブートを実行してください. 鍵を押して中央コンソールボタンを5秒押してください.';

  @override
  String get traffic_monitor_loading => '交通モニター: チェック...';

  @override
  String get traffic_monitor_tap_to_check => '交通モニター (チェックするにはタップ)';

  @override
  String get reset_label_trips => '走行履歴';

  @override
  String get reset_label_soc_history => 'SoC + 12V 過去';

  @override
  String get reset_label_recordings => '録画';

  @override
  String get reset_label_sentry_events => '監視イベント';

  @override
  String get reset_label_proximity => '接近記録';

  @override
  String get reset_label_trip_files => '旅行テレメトリファイル';

  @override
  String get toast_access_code_copied => 'アクセスコードをコピーした';

  @override
  String get dialog_regenerate_token_title => '再生する記号';

  @override
  String get dialog_regenerate_token_message =>
      '現在のトークンは無効になります。アクティブなセッションはすべてログアウトされます。続行しますか？';

  @override
  String get toast_token_regenerated_logged_out =>
      '新しいトークンを生成しました。すべてのセッションがログアウトされました。';

  @override
  String get toast_token_regenerated_restart =>
      'トークンを再生成しました。適用するにはサービスの再起動が必要な場合があります。';

  @override
  String get toast_token_regenerated_no_notify =>
      'トークンを再生成しました。バックグラウンドサービスへの通知に失敗しました。';

  @override
  String get toast_token_regenerated => 'トークン再生';

  @override
  String get dashboard_no_tunnel => 'トンネルが走らない';

  @override
  String get dashboard_starting_zrok => 'Zrokトンネルを起動する';

  @override
  String get dashboard_waiting_url => 'トンネルURLを待ってる';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 実行中';
  }

  @override
  String get tunnel_label_zrok => 'Zrok';

  @override
  String get clip_label_access_code => 'アクセスコード';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return '$arg1 の設定は必要ありません';
  }

  @override
  String get dialog_zrok_token_title => 'Zrokトンネルトークン';

  @override
  String get dialog_zrok_token_message =>
      'Zrok の有効化トークンを入力してください。\n取得先: zrok.io';

  @override
  String get toast_token_cannot_be_empty => '符号は空きすることはできません';

  @override
  String get dialog_zrok_reset_title => 'Zrok 環境をリセットする';

  @override
  String get dialog_zrok_reset_message =>
      '次の処理を行います:\n• 実行中であれば zrok トンネルを停止します\n• このデバイスから zrok 環境を削除します\n• 保存されたトークンを削除します\n\nトークンを再入力して有効化し直す必要があります。zrok.io の 5 つのデバイス枠のうち 1 つを使用します。\n\nよろしいですか？';

  @override
  String get toast_resetting_zrok => 'Zrok環境をリセットする...';

  @override
  String get toast_zrok_reset_success => 'Zrok 環境リセット. また設定するために新しいトークンを入力します.';

  @override
  String get toast_zrok_reset_partial =>
      '環境リセット (トークンファイルは手動の掃除が必要になる可能性があります)';

  @override
  String toast_zrok_reset_warnings(Object arg1) {
    return '環境リセット (警告: $arg1)';
  }

  @override
  String get zrok_no_token_configured => 'トークンが設定されていません。タップして設定してください。';

  @override
  String get toast_zrok_token_saved => '保存されたトークン';

  @override
  String get toast_zrok_token_save_failed => '記号保存に失敗';

  @override
  String get toast_zrok_token_deleted => 'トークン削除';

  @override
  String get toast_zrok_token_delete_failed => '記号を削除できませんでした';

  @override
  String toast_fetching_log(Object arg1) {
    return '$arg1の記録を...';
  }

  @override
  String get toast_log_empty_or_missing => 'ログファイルは空か見つかりませんでした';

  @override
  String get toast_log_empty => 'ログファイルは空いている';

  @override
  String toast_log_save_failed(Object arg1) {
    return '記録保存失敗: $arg1';
  }

  @override
  String get toast_log_not_found => 'ログファイルが見つかりませんでした';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1 ログ - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return '共有 $arg1 ログ';
  }

  @override
  String log_header_title(Object arg1) {
    return '$arg1 ログ';
  }

  @override
  String log_header_source(Object arg1) {
    return 'ソース: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return '輸出: $arg1';
  }

  @override
  String log_header_truncated(Object arg1) {
    return '注記:10000行までの短縮されたログ (合計:$arg1行)';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'ビデオ再生できない: $arg1';
  }

  @override
  String get dialog_delete_recording_title => '記録を削除する';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '$arg1を削除しますか？\nこの操作は元に戻せません。';
  }

  @override
  String get toast_recording_deleted => '記録は削除された';

  @override
  String get toast_recording_delete_failed => '録画を削除できませんでした';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1は削除され,$arg2は失敗';
  }

  @override
  String get play_with_chooser => '遊びなさい';

  @override
  String setup_version_banner(Object arg1) {
    return '更新された v$arg1 再び確認自動起動,BYDは,すべてのインストールでそれを消す';
  }

  @override
  String get setup_overlay_already_granted => 'すでに 認め られ て いる';

  @override
  String camera_current_manual(Object arg1) {
    return '現在のカメラ: $arg1 (マニュアル)';
  }

  @override
  String get camera_current_auto_label => '現在の: 自動';

  @override
  String get soh_estimation_active => '推定活動';

  @override
  String get soh_oem_readout => '車両SOH値 — 推定値を計算中';

  @override
  String get soh_nominal_baseline => '公称基準値 — 信頼できるSOHデータを待機中';

  @override
  String get soh_no_estimate_yet => '推定はまだありません — データを待っています';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1が選択された';
  }

  @override
  String get video_player_playback_error => '再生エラー';

  @override
  String get video_player_no_events => 'イベントなし';

  @override
  String get daemon_configuration_required => '設定が必要';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'ビデオプレーヤー';

  @override
  String get status_overlay_notif_title => 'BladeWatch 状態';

  @override
  String get status_overlay_notif_text => 'ステータスオーバーレイ アクティブ';

  @override
  String get rail_dashboard => 'ダッシュボード';

  @override
  String get rail_live => 'ライブ';

  @override
  String get rail_recordings => '録画';

  @override
  String get rail_vehicle => '車両';

  @override
  String get rail_trips => '走行履歴';

  @override
  String get rail_location => '位置情報';

  @override
  String get rail_diagnostics => '診断';

  @override
  String get rail_settings => '設定';

  @override
  String get settings_section_appearance => '外見';

  @override
  String get settings_section_recording => '記録';

  @override
  String get settings_section_surveillance => '監視';

  @override
  String get settings_section_daemons => 'サービス';

  @override
  String get settings_section_privacy => 'プライバシーとデータ';

  @override
  String get settings_section_overlay => 'ステータスオーバーレイ';

  @override
  String get settings_overlay_subtitle => '浮動状態の錠剤のどの部分が目に見えるかを選択してください.';

  @override
  String get settings_overlay_camera_title => 'カメラ表示';

  @override
  String get settings_overlay_camera_subtitle =>
      '録画が動いている間に REC/ PROX バッジを表示します.';

  @override
  String get settings_overlay_trip_title => 'Trip を表示する';

  @override
  String get settings_overlay_trip_subtitle => 'トリップバッジを表示する';

  @override
  String get settings_section_about => '情報';

  @override
  String get settings_subrail_overline => '設定';

  @override
  String get cd_settings_subrail => '設定サイドバー';

  @override
  String get settings_privacy_title => 'プライバシーとデータ';

  @override
  String get settings_privacy_body =>
      'リセットすると、録画インデックス、キャッシュされた認証情報、サービスの状態、およびデバイス上の設定がクリアされます。この操作は元に戻せません。';

  @override
  String get settings_about_title => 'BladeWatchについて';

  @override
  String get settings_about_version_label => 'バージョン';

  @override
  String get settings_about_package_label => '建設する';

  @override
  String get settings_about_support_section => 'あなたのような人々によって動かす';

  @override
  String get settings_about_support_share_title => '他のオーナーにも伝えよう';

  @override
  String get settings_about_support_share_value =>
      '共有されたリンクは 他のBYDのオーナーがBladeWatchを発見するのに役立ちます';

  @override
  String get settings_about_support_share_message =>
      'BYDのBladeWatch オープンソース監視とダッシュカメラをチェックしてください: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'シェア 過剰運転';

  @override
  String get settings_about_open_link_failed => 'リンクを開けられなかった';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'ブラウザが見つかりませんでした. URLコピー: $arg1';
  }

  @override
  String get settings_about_support_kofi_title => '次のリリースに燃料';

  @override
  String get settings_about_support_kofi_value => 'カフェは夜明けの約束を支える';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'ライセンス';

  @override
  String get settings_about_license_value =>
      'MIT オープンソース. 完全テキストを表示するにはタップします.';

  @override
  String get settings_about_source_title => 'ソースコード';

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
  String get settings_about_star_title => 'を GitHub に 落とす';

  @override
  String get settings_about_star_value => 'ほんの一瞬で終わります。とても励みになります。';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'ありがとう';

  @override
  String get settings_about_thanks_subtitle => 'コントリビューターとサポーターの皆さんに支えられています。';

  @override
  String get settings_about_contributors_title => 'コントリビューター';

  @override
  String get settings_about_supporters_title => 'サポーター';

  @override
  String get settings_about_thanks_empty => '参加してくれる人が増えると、ここに表示されます。';

  @override
  String get settings_theme_label => 'テーマ';

  @override
  String get settings_theme_auto => '自動 (システムに合わせる)';

  @override
  String get settings_theme_light => 'ライト';

  @override
  String get settings_theme_dark => 'ダーク';

  @override
  String get settings_language_label => '言語';

  @override
  String get settings_drive_side_label => 'ナビ表示位置';

  @override
  String get settings_drive_side_subtitle => 'ナビゲーションメニューを画面のどちら側に表示するか選択します。';

  @override
  String get settings_drive_side_left => '左';

  @override
  String get settings_drive_side_left_hint => '左ハンドル · 既定';

  @override
  String get settings_drive_side_right => '右';

  @override
  String get settings_drive_side_right_hint => '右ハンドル車';

  @override
  String get settings_drive_side_auto => '自動';

  @override
  String get settings_drive_side_auto_hint => '車両から検出';

  @override
  String get settings_drive_side_caption_left => 'ナビを左に表示';

  @override
  String get settings_drive_side_caption_right => 'ナビを右に表示';

  @override
  String get settings_drive_side_caption_auto_left => '自動 — 車両は左ハンドルを報告';

  @override
  String get settings_drive_side_caption_auto_right => '自動 — 車両は右ハンドルを報告';

  @override
  String get settings_drive_side_caption_auto_unknown => '自動 — 車両が利用不可、左を使用';

  @override
  String get recordings_title => '録画';

  @override
  String get recordings_segment_dashcam => 'ダッシュキャム';

  @override
  String get recordings_segment_surveillance => '監視';

  @override
  String get recordings_action_settings => '設定';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1今日 · $arg2合計 · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'ダッシュキャム · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return '監視 · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => '記録を選択する';

  @override
  String get recordings_preview_placeholder_body => '左側にある任意のアイテムをタップして演奏します.';

  @override
  String get diagnostics_section_adb_console => 'ADB コンソール';

  @override
  String get diagnostics_section_traffic => '交通モニター';

  @override
  String get diagnostics_section_camera_probe => 'カメラ検出';

  @override
  String get diagnostics_section_battery => 'バッテリー状態';

  @override
  String get diagnostics_section_performance => 'パフォーマンス';

  @override
  String get diagnostics_hero_title => 'システム診断';

  @override
  String get diagnostics_hero_subtitle => '生体健康 記録 探査機';

  @override
  String get diagnostics_health_clear => '異常なし';

  @override
  String get diagnostics_health_section => '状態';

  @override
  String get diagnostics_health_network => 'ネットワーク';

  @override
  String get diagnostics_health_storage => 'ストレージ';

  @override
  String get diagnostics_health_camera => 'カメラ';

  @override
  String get diagnostics_health_battery => 'バッテリー';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'オンライン';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'トンネル · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => 'オンライン';

  @override
  String get diagnostics_tunnel_state_offline => 'オフライン';

  @override
  String get diagnostics_tunnel_state_connecting => '接続';

  @override
  String get diagnostics_network_mobile => 'モバイル';

  @override
  String get diagnostics_network_ethernet => 'イーサネット';

  @override
  String get diagnostics_network_offline => 'オフライン';

  @override
  String diagnostics_storage_used_line(Object arg1, Object arg2) {
    return '$arg1クリップ · $arg2を使用';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 無料';
  }

  @override
  String get diagnostics_logs_card_title => 'ライブイベントログ';

  @override
  String get diagnostics_logs_card_subtitle => '実行サービスからのストリーミング出力';

  @override
  String get diagnostics_tools_section => 'ツール';

  @override
  String get diagnostics_traffic_subtitle => 'ネットワークの直播を監視する';

  @override
  String get diagnostics_camera_probe_subtitle => '接続されたカメラのストリームを検査する';

  @override
  String get diagnostics_adb_subtitle => 'デバイス上のターミナルを開きます。';

  @override
  String get diagnostics_battery_subtitle => 'SOHを検査して 統計をまとめて';

  @override
  String get diagnostics_settings_subtitle => 'アプリの好み テーマ 言語';

  @override
  String get settings_action_reset_data => 'データをリセット…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => '監視中';

  @override
  String get dashboard_subtitle_all_systems => 'すべてのシステムはオンライン';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return 'オンラインでの$arg1の$arg2サービス';
  }

  @override
  String get dashboard_subtitle_no_tunnel => '遠隔アクセスオフライン';

  @override
  String get dashboard_metric_recordings => '今日の録画';

  @override
  String get dashboard_metric_storage => '使用された貯蔵庫';

  @override
  String get dashboard_metric_tunnel => 'リモートアクセス';

  @override
  String get dashboard_metric_services => '背景サービス';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => '車両';

  @override
  String get dashboard_chip_recording_active => '録画';

  @override
  String get dashboard_chip_recording_idle => '待機中';

  @override
  String get dashboard_vehicle_tap_to_set => 'タップして設定';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'バッテリーの容量設定';

  @override
  String get vehicle_dialog_capacity_label => '容量 (kWh)';

  @override
  String get vehicle_dialog_capacity_suffix => 'kWh';

  @override
  String get vehicle_dialog_capacity_helper =>
      '8 ～ 120 kWh.モデルのデフォルトを使用する場合はそのままにします。';

  @override
  String get vehicle_dialog_model_label => 'モデル';

  @override
  String get vehicle_dialog_save => '保存';

  @override
  String get vehicle_dialog_reset => '自動検出にリセット';

  @override
  String get vehicle_dialog_invalid_capacity => '容量は8~120ZkWh';

  @override
  String vehicle_dialog_summary_capacity(Object arg1) {
    return '容量: $arg1';
  }

  @override
  String vehicle_dialog_summary_soh(Object arg1) {
    return 'SOH: $arg1';
  }

  @override
  String vehicle_dialog_soh_source_live(Object arg1) {
    return '$arg1%(ライブ)';
  }

  @override
  String vehicle_dialog_soh_source_calibration(Object arg1) {
    return '$arg1%(前回の充電時)';
  }

  @override
  String vehicle_dialog_soh_source_oem(Object arg1) {
    return '$arg1%(車両)';
  }

  @override
  String vehicle_dialog_soh_source_nominal(Object arg1) {
    return '$arg1%(公称値)';
  }

  @override
  String get settings_recording_tab_status => 'ステータス';

  @override
  String get settings_recording_tab_capture => 'キャプチャ';

  @override
  String get settings_recording_tab_quality => '画質';

  @override
  String get settings_recording_tab_storage => 'ストレージ';

  @override
  String get settings_recording_status_title => '録画ステータス';

  @override
  String get settings_recording_status_current_state => '現在の状態';

  @override
  String get settings_recording_status_today_count => '本日の録画数';

  @override
  String get settings_recording_mode_title => '録画モード（ACC ON）';

  @override
  String get settings_recording_mode_description =>
      '走行中にドライブレコーダーが録画するタイミングを選びます。';

  @override
  String get settings_recording_mode_none_label => 'なし（既定）';

  @override
  String get settings_recording_mode_none_desc => '録画しない — 監視は引き続き動作します';

  @override
  String get settings_recording_mode_continuous_label => '常時録画';

  @override
  String get settings_recording_mode_continuous_desc => '走行中は常に録画';

  @override
  String get settings_recording_mode_drive_label => '走行モード';

  @override
  String get settings_recording_mode_drive_desc => '車両の走行中のみ録画';

  @override
  String get settings_recording_mode_proximity_label => '近接ガード';

  @override
  String get settings_recording_mode_proximity_desc => '動きを検知したときに録画';

  @override
  String get settings_recording_limit_title => '録画の分割長';

  @override
  String get settings_recording_limit_description =>
      '1ファイルあたりの最大長。この間隔で新しいファイルに分割されます。';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => '録画品質';

  @override
  String get settings_recording_storage_title => '録画の保存先';

  @override
  String get settings_recording_storage_location_label => '保存先';

  @override
  String get settings_recording_storage_internal => '内部ストレージ';

  @override
  String get settings_recording_storage_sd_card => 'SDカード';

  @override
  String get settings_recording_storage_sd_card_na => 'SDカード（なし）';

  @override
  String get settings_recording_storage_limit_label =>
      '保存容量の上限 — 到達すると古いものから自動削除';

  @override
  String get settings_recording_storage_usage_label => 'ストレージ使用量';

  @override
  String get settings_recording_storage_files_label => 'ファイル';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 使用 / 上限 $arg2';
  }

  @override
  String settings_recording_storage_files(Object arg1) {
    return '録画 $arg1 件';
  }

  @override
  String get settings_recording_storage_path_label => 'パス';

  @override
  String get settings_recording_storage_sd_free_label => 'SDカードの空き';

  @override
  String get settings_recording_storage_internal_free_label => '内部ストレージの空き';

  @override
  String get settings_recording_format_title => '外部ドライブをフォーマット';

  @override
  String get settings_recording_format_warning =>
      'SDカードまたはUSBドライブ上のすべてのデータを完全に消去します。';

  @override
  String get settings_recording_format_confirm => 'もう一度タップ — すべてのデータが消去されます';

  @override
  String get settings_recording_format_running => 'フォーマット中… お待ちください';

  @override
  String get settings_recording_format_button => 'SDカード / USB をフォーマット';

  @override
  String get settings_recording_format_no_drive => 'リムーバブルドライブが見つかりません';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'フォーマットが完了しました。新しいパス: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'データベースカタログ';

  @override
  String get settings_recording_sync_description =>
      '録画インデックスをディスク上のファイルと照合します。';

  @override
  String get settings_recording_sync_running => '同期中…';

  @override
  String get settings_recording_sync_button => 'データベースを同期';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return '同期完了: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => 'すでに同期中です';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return '同期に失敗しました: $arg1';
  }

  @override
  String get settings_recording_apply_button => '変更を適用';

  @override
  String get settings_recording_dismiss => '閉じる';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return '$arg1 の開始/停止はまだ対応していません';
  }

  @override
  String get settings_daemons_zrok_configure => '設定';

  @override
  String get settings_daemons_zrok_reset_button => '環境をリセット';

  @override
  String vehicle_dialog_summary_effective(Object arg1) {
    return '効力: $arg1 kWh';
  }

  @override
  String vehicle_dialog_summary_model(Object arg1) {
    return 'モデル: $arg1';
  }

  @override
  String vehicle_dialog_summary_calibration(Object arg1, Object arg2) {
    return '前回の校正: $arg2 に $arg1%';
  }

  @override
  String get vehicle_dialog_soh_unavailable => '取得不可';

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1使用 · $arg2 無料';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'ストレージ —';

  @override
  String get dashboard_tunnel_offline => 'オフライン';

  @override
  String get dashboard_tunnel_online => 'オンライン';

  @override
  String get dashboard_tunnel_connecting => '接続中…';

  @override
  String get dashboard_trips_this_week => '今週';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 回の走行',
      one: '$arg1 回の走行',
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
  String get dashboard_trips_label_trips => '走行回数';

  @override
  String get dashboard_trips_label_distance => '距離';

  @override
  String get dashboard_trips_label_time => '運転時間';

  @override
  String get dashboard_trips_no_data => '今週の走行記録はありません';

  @override
  String get dashboard_trips_unavailable => '運転を開始すると統計が表示されます';

  @override
  String get dashboard_trips_loading => '読み込み中…';

  @override
  String get dashboard_trips_view_all => 'すべての走行を表示';

  @override
  String get dashboard_action_live => 'ライブビュー';

  @override
  String get dashboard_action_live_subtitle => 'カメラビューを開く';

  @override
  String get dashboard_action_recordings => '録画';

  @override
  String get dashboard_action_settings => '設定';

  @override
  String get dashboard_action_settings_subtitle => '優先順位について';

  @override
  String get settings_hero_title => '設定';

  @override
  String get settings_hero_overline => '過剰運転';

  @override
  String get settings_hero_subtitle => '外見,記録,監視,およびデバイス上のデータを調節する.';

  @override
  String get settings_overline_preferences => '優先順位';

  @override
  String get settings_overline_about_data => 'DATAについて';

  @override
  String get settings_quick_theme_label => 'テーマ';

  @override
  String get settings_quick_language_label => '言語';

  @override
  String get settings_section_recording_subtitle => '預設/後設バッファ,コードック,保存制限';

  @override
  String get settings_section_surveillance_subtitle => 'スケジュール、動体検知感度、物体検知。';

  @override
  String get settings_section_daemons_subtitle => 'Zrokトンネルとバックグラウンドサービス。';

  @override
  String get settings_about_row_title => 'BladeWatchについて';

  @override
  String get settings_about_row_subtitle => 'バージョン ライセンス サポート開発';

  @override
  String get settings_reset_row_subtitle => '記録,イベント,またはすべてのキャッシュ.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle => 'テーマ,言語,視覚の好み';

  @override
  String get settings_theme_active_auto_caption => '自動はシステムのテーマに従います。';

  @override
  String get settings_theme_active_light_caption => 'ライトテーマは常に有効です。';

  @override
  String get settings_theme_active_dark_caption => 'ダークテーマは常に有効です。';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg2 言語中 $arg1 言語が利用可能';
  }

  @override
  String get settings_language_card_title => 'ディスプレイ言語';

  @override
  String get settings_privacy_stance_title => 'デフォルトでデバイス内';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch はヘッドユニット上で完結して動作します。明示的に設定したトンネルと連携機能を除き、テレメトリが車外に出ることはありません。';

  @override
  String get settings_privacy_overline_storage => 'ローカル ストレージ';

  @override
  String get settings_privacy_overline_reset => 'データのリセット';

  @override
  String get settings_privacy_storage_clips_label => 'ディスク上のクリップ';

  @override
  String get settings_privacy_storage_size_label => '総規模';

  @override
  String get settings_privacy_storage_unavailable => '入手できない';

  @override
  String settings_privacy_storage_count_format(Object arg1) {
    return '$arg1 クリップ';
  }

  @override
  String settings_privacy_storage_count_format_plural(Object arg1) {
    return '$arg1クリップ';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'カテゴリーを選択してください：録画、イベント、サービス設定、キャッシュされたテレメトリ…';

  @override
  String get settings_developer_overline => '開発者';

  @override
  String get settings_developer_timing_logs_title => 'サービス起動タイミングログ';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'サービス起動中の経過時間マーカーを記録します。通常使用時はlogcatを整理するため無効にしてください。';

  @override
  String get settings_developer_debug_logs_title => '開発者デバッグログ';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'すべてのActivityとFragmentのライフサイクルイベントおよび起動手順を /storage/emulated/0/BladeWatch/data/debug_app.log に記録します。クラッシュは常に記録されます。既定はオフ。';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'カメラ$arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'カメラ$arg1 (手動)';
  }

  @override
  String get diagnostics_camera_value_probing => '検出中…';

  @override
  String get diagnostics_camera_value_offline => 'オフライン';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => '待機データ';

  @override
  String diagnostics_battery_value_charge(Object arg1) {
    return '$arg1%';
  }

  @override
  String dashboard_recordings_value_live(Object arg1) {
    return '● $arg1';
  }

  @override
  String get dashboard_insight_welcome => 'お待たせしました オーバードライブはもう2番目の目です';

  @override
  String dashboard_insight_parked_charged_kwh(Object arg1, Object arg2) {
    return '駐車中に$arg1 (≈$arg2) を拾った';
  }

  @override
  String dashboard_insight_parked_charged(Object arg1) {
    return '駐車中に$arg1を拾った';
  }

  @override
  String dashboard_insight_parked_drained_kwh(Object arg1, Object arg2) {
    return '駐車して以来 $arg1 (≈$arg2) を使った';
  }

  @override
  String dashboard_insight_parked_drained(Object arg1) {
    return '駐車して以来$arg1を使っています';
  }

  @override
  String dashboard_insight_last_alert(Object arg1) {
    return '最後の監視警報: $arg1';
  }

  @override
  String dashboard_insight_last_charge(Object arg1, Object arg2) {
    return '最後の電荷: $arg2 で +$arg1';
  }

  @override
  String dashboard_insight_storage_milestone(Object arg1, Object arg2) {
    return '$arg1クリップ · $arg2録画';
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
    return '$arg1 時間 $arg2 分';
  }

  @override
  String dashboard_insight_today_clips(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '今日録画された$arg1クリップ',
      one: '$arg1クリップは今日録画されました',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_days_hours(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1日,$arg2時間,オンラインで運転する',
      one: '$arg1日,$arg2時間でオンラインでドライブ',
    );
    return '$_temp0';
  }

  @override
  String dashboard_insight_uptime_hours(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1時間 オンラインでオーバードライブ',
      one: '$arg1時間 オンラインでオーバードライブ',
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
  String get vehicle_tab_trunk => 'トランク';

  @override
  String get vehicle_tab_climate => 'エアコン';

  @override
  String get vehicle_tab_seats => '座席';

  @override
  String get vehicle_tab_windows => 'ウィンドウ';

  @override
  String get vehicle_tab_lights => 'ライト';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => '充電';

  @override
  String get vehicle_locked => '施錠';

  @override
  String get vehicle_unlocked => '解錠';

  @override
  String get vehicle_range_label => '航続距離';

  @override
  String get vehicle_data_unavailable => '車両データを取得できません。';

  @override
  String get vehicle_action_failed => '操作に失敗しました。車両との接続を確認してください。';

  @override
  String get vehicle_open_trunk => 'トランクを開ける';

  @override
  String get vehicle_close_trunk => 'トランクを閉める';

  @override
  String get vehicle_trunk_info_open => 'トランクを開けると先に車のロックが解除されます。';

  @override
  String get vehicle_ac_on => 'AC オン';

  @override
  String get vehicle_ac_off => 'AC オフ';

  @override
  String get vehicle_max_cooling_on => '最大冷房: オン';

  @override
  String get vehicle_max_cooling_off => '最大冷房: オフ';

  @override
  String get vehicle_temp_label => '温度';

  @override
  String get vehicle_fan_speed_label => '風量';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'レベル $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return '室内: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => '運転席';

  @override
  String get vehicle_seat_passenger => '助手席';

  @override
  String get vehicle_seat_no_controls => 'この車両ではシート操作を利用できません。';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return '暖房 $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return '冷房 $arg1';
  }

  @override
  String get vehicle_heat_off => '（オフ）';

  @override
  String get vehicle_heat_low => '（弱）';

  @override
  String get vehicle_heat_high => '（強）';

  @override
  String get vehicle_seat_pos_1 => '位置 1';

  @override
  String get vehicle_seat_pos_2 => '位置 2';

  @override
  String get vehicle_all_windows => '全ウィンドウ';

  @override
  String get vehicle_window_front_left => '前左';

  @override
  String get vehicle_window_front_right => '前右';

  @override
  String get vehicle_window_rear_left => '後左';

  @override
  String get vehicle_window_rear_right => '後右';

  @override
  String get vehicle_window_close => '閉じる';

  @override
  String get vehicle_window_close_vent => '換気を閉じる';

  @override
  String get vehicle_window_vent_12 => '換気 12%';

  @override
  String get vehicle_window_open_all => 'すべて開ける';

  @override
  String get vehicle_sunroof => 'サンルーフ';

  @override
  String get vehicle_sunshade => 'サンシェード';

  @override
  String get vehicle_btn_drl_title => '日中の走行灯';

  @override
  String get vehicle_btn_slw_title => '速度制限警告';

  @override
  String get vehicle_control_section_charge_cap => '充電上限';

  @override
  String get vehicle_charge_cap_not_supported => 'この車両は充電上限に対応していません。';

  @override
  String get vehicle_charge_limit_label => '充電上限';

  @override
  String get vehicle_enable_charge_limit => '充電上限を有効にする';

  @override
  String get vehicle_charge_limit_range => '最小50%、最大100%';

  @override
  String get vehicle_tyre_no_signal => '信号なし';

  @override
  String get vehicle_tyre_slow_leak => 'ゆるやかな空気漏れ';

  @override
  String get vehicle_tyre_fast_leak => '急速な空気漏れ';

  @override
  String get vehicle_tyre_low => '低圧';

  @override
  String get vehicle_tyre_high => '高圧';

  @override
  String get vehicle_tyre_ok => '正常';

  @override
  String get vehicle_tyre_check_pressure => '空気圧を確認';

  @override
  String get vehicle_toggle_on => 'オン';

  @override
  String get vehicle_toggle_off => 'オフ';

  @override
  String get vehicle_err_climate_control => '空調操作に失敗しました。';

  @override
  String get vehicle_err_max_cooling => '最大冷房に失敗しました。';

  @override
  String get vehicle_err_drl_control => 'デイライト操作に失敗しました。';

  @override
  String get vehicle_err_slw_control => 'ADAS操作に失敗しました。';

  @override
  String get vehicle_err_charge_limit_toggle => '充電上限の切り替えに失敗しました。';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return '$arg1を下げる';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return '$arg1を上げる';
  }

  @override
  String get vehicle_stale_connecting => '接続中…';

  @override
  String get vehicle_appearance_model_title => 'モデルを選択';

  @override
  String get vehicle_appearance_custom_color => 'カスタムカラー';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return '充電: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return '航続: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => '充電: —';

  @override
  String get vehicle_status_range_unknown => '航続: —';

  @override
  String get startup_subtitle => 'ドライブレコーダーを準備しています';

  @override
  String get startup_header_preparing => '準備しています…';

  @override
  String get startup_header_starting => '起動しています…';

  @override
  String get startup_header_verifying => 'もうすぐ完了…';

  @override
  String get startup_header_ready => '準備が完了しました';

  @override
  String get startup_daemon_camera => 'カメラ';

  @override
  String get startup_daemon_camera_desc => 'ライブ表示と録画';

  @override
  String get startup_daemon_sentry => 'セントリーモード';

  @override
  String get startup_daemon_sentry_desc => '動体検知とアラート';

  @override
  String get startup_daemon_parking => '駐車監視';

  @override
  String get startup_daemon_parking_desc => '駐車中も見守ります';

  @override
  String get startup_status_waiting => '待機中';

  @override
  String get startup_status_starting => '起動中';

  @override
  String get startup_status_ready => '準備完了';

  @override
  String get startup_status_failed => '失敗';

  @override
  String get startup_continue_anyway => 'このまま続行';

  @override
  String get startup_continue => '続行 →';

  @override
  String get live_retry => '再試行';

  @override
  String get live_connecting => 'カメラに接続中…';

  @override
  String live_error_fmt(Object arg1) {
    return 'エラー: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'カメラを利用できません\n$arg1';
  }

  @override
  String get live_direction_all => 'すべて';

  @override
  String get live_direction_front => '前';

  @override
  String get live_direction_right => '右';

  @override
  String get live_direction_rear => '後';

  @override
  String get live_direction_left => '左';

  @override
  String get trip_no_route_data => 'この走行の経路データはありません';

  @override
  String get trips_tab_trips => 'トリップ';

  @override
  String get trips_tab_stats => '統計';

  @override
  String get trips_tab_storage => 'ストレージ';

  @override
  String get trips_filter_7_days => '7日間';

  @override
  String get trips_filter_14_days => '14日間';

  @override
  String get trips_filter_30_days => '30日間';

  @override
  String trips_load_error(Object message) {
    return 'エラー: $message';
  }

  @override
  String get trips_empty_state => 'まだトリップが記録されていません';

  @override
  String get trips_period_summary_title => '期間サマリー';

  @override
  String get trips_stat_trips => '走行';

  @override
  String get trips_stat_hours => '時間';

  @override
  String get trips_stat_efficiency => '効率';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'スコア: $score';
  }

  @override
  String get trips_driver_score_title => 'ドライバースコア';

  @override
  String trips_driver_score_overall(Object score) {
    return '総合: $score / 100';
  }

  @override
  String get trips_range_title => 'パーソナライズド航続距離';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'BYD推定: $km km';
  }

  @override
  String get trips_range_no_data => 'まだデータが十分ではありません';

  @override
  String get trips_dna_title => '運転DNA';

  @override
  String get trips_dna_anticipation => '先読み';

  @override
  String get trips_dna_smoothness => 'スムーズさ';

  @override
  String get trips_dna_speed_discipline => '速度遵守';

  @override
  String get trips_dna_efficiency => '効率';

  @override
  String get trips_dna_consistency => '一貫性';

  @override
  String get trips_storage_title => 'トリップストレージ';

  @override
  String get trips_storage_analytics_label => '走行分析';

  @override
  String get trips_storage_rate_label => '電気料金';

  @override
  String get trips_storage_distance_unit_label => '距離の単位';

  @override
  String get trips_storage_location_label => '保存先';

  @override
  String get trips_storage_internal => '内部ストレージ';

  @override
  String get trips_storage_sd_card => 'SDカード';

  @override
  String get trips_storage_sd_card_unavailable => 'SDカード（なし）';

  @override
  String get trips_storage_apply => '変更を適用';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit 使用 / 上限 $limit MB・$count 件の走行';
  }

  @override
  String get trips_sync_title => 'データベースカタログ';

  @override
  String get trips_sync_description => '走行履歴のインデックスをディスク上のテレメトリファイルと照合します。';

  @override
  String get trips_sync_button => 'データベースを同期';

  @override
  String get trips_sync_running => '同期中…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return '同期に成功しました: +$added -$removed（合計$total件）';
  }

  @override
  String get trips_sync_failed_generic => '同期に失敗しました';

  @override
  String get trips_detail_summary_title => 'トリップサマリー';

  @override
  String get trips_detail_distance => '走行距離';

  @override
  String get trips_detail_duration => '所要時間';

  @override
  String get trips_detail_energy => '消費電力';

  @override
  String get trips_detail_avg_speed => '平均速度';

  @override
  String get trips_detail_max_speed => '最高速度';

  @override
  String get trips_detail_soc => '充電残量';

  @override
  String get trips_detail_cost => '費用';

  @override
  String get trips_detail_ext_temp => '外気温';

  @override
  String get trips_detail_elev_gain => '獲得標高';

  @override
  String get trips_detail_scores_title => '運転スコア';

  @override
  String get trips_detail_unavailable => 'トリップの詳細を利用できません';

  @override
  String get trips_detail_loading => 'トリップを読み込み中…';

  @override
  String trips_detail_route_points(Object count) {
    return 'GPSポイント $count 件を記録';
  }

  @override
  String get rec_severity_critical => '重大';

  @override
  String get rec_severity_alert => '警告';

  @override
  String get location_loading_title => '地図を読み込み中';

  @override
  String get location_permission_missing_title => '位置情報の許可が必要です';

  @override
  String get location_permission_denied_title => '許可が拒否されました';

  @override
  String get location_provider_disabled_title => 'GPSが無効です';

  @override
  String get location_waiting_for_fix_title => 'GPS信号を待っています';

  @override
  String get location_car_location_title => '車両の位置';

  @override
  String get location_stale_title => '位置情報が古くなっています';

  @override
  String get location_tile_failure_title => '地図を利用できません';

  @override
  String get location_tile_failure_subtitle => 'ネットワークが利用できません';

  @override
  String get location_error_title => '位置情報エラー';

  @override
  String get location_action_grant => '許可する';

  @override
  String get location_action_retry => '再試行';

  @override
  String get location_mode_auto => '自動';

  @override
  String get location_mode_light => 'ライト';

  @override
  String get location_mode_dark => 'ダーク';

  @override
  String get cd_recenter_on_car => '車両を中心に戻す';

  @override
  String get recording_lib_no_recordings_normal => '通常録画はありません';

  @override
  String get recording_lib_no_recordings_sentry => '見張りイベントはありません';

  @override
  String get recording_lib_no_recordings_proximity => '近接イベントはありません';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => '人';

  @override
  String get video_player_legend_car => '車';

  @override
  String get video_player_legend_bike => '自転車';

  @override
  String get video_player_legend_motion => '動き';

  @override
  String get recording_lib_proximity_very_close => '非常に近い';

  @override
  String get recording_lib_proximity_close => '近い';

  @override
  String get recording_lib_proximity_mid => '中程度';

  @override
  String get recording_lib_proximity_far => '遠い';

  @override
  String get surveillance_tab_general => '一般';

  @override
  String get surveillance_tab_detection => '検知';

  @override
  String get surveillance_tab_recording => '録画';

  @override
  String get surveillance_tab_storage => 'ストレージ';

  @override
  String get surveillance_tab_advanced => '詳細設定';

  @override
  String get surveillance_general_title => '監視モード';

  @override
  String get surveillance_general_enable => '監視を有効にする';

  @override
  String get surveillance_general_status => 'ステータス';

  @override
  String get surveillance_general_status_running => '実行中';

  @override
  String get surveillance_general_status_idle => '待機中';

  @override
  String get surveillance_general_events_today => '本日のイベント';

  @override
  String get surveillance_safe_locations_title => 'セーフロケーション';

  @override
  String get surveillance_safe_locations_subtitle => 'この場所に駐車してもカメラは起動しません';

  @override
  String get surveillance_safe_locations_enable => 'セーフロケーションで無効にする';

  @override
  String get surveillance_safe_locations_empty => 'セーフロケーションはまだ追加されていません';

  @override
  String get surveillance_safe_locations_add_current => '現在地をセーフゾーンとして追加';

  @override
  String get surveillance_safe_locations_no_gps => 'GPS位置情報が利用できません';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => '検知設定';

  @override
  String get surveillance_detection_preset_label => '環境プリセット';

  @override
  String get surveillance_preset_outdoor => '屋外';

  @override
  String get surveillance_preset_garage => 'ガレージ';

  @override
  String get surveillance_preset_street => '路上';

  @override
  String get surveillance_preset_custom => 'カスタム';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return '感度（1=厳格、5=高感度）: $arg1';
  }

  @override
  String get surveillance_detection_objects_label => '検知対象';

  @override
  String get surveillance_detection_object_person => '人';

  @override
  String get surveillance_detection_object_car => '車';

  @override
  String get surveillance_detection_object_bike => '自転車';

  @override
  String get surveillance_recording_title => 'イベント録画';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'プリ録画（イベント前の秒数）: $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'ポスト録画（イベント後の秒数）: $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => '監視ストレージ';

  @override
  String get surveillance_storage_location_label => '保存場所';

  @override
  String get surveillance_storage_internal => '内部';

  @override
  String get surveillance_storage_sd_card => 'SDカード';

  @override
  String get surveillance_storage_sd_card_na => 'SDカード（利用不可）';

  @override
  String get surveillance_storage_limit_label => 'ストレージ上限 — 上限到達で最も古いものを自動削除';

  @override
  String get surveillance_storage_usage_label => 'ストレージ使用量';

  @override
  String get surveillance_storage_files_label => 'ファイル';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 使用 / 上限 $arg2';
  }

  @override
  String surveillance_storage_files(Object arg1) {
    return '$arg1 件のイベント';
  }

  @override
  String get surveillance_storage_path_label => 'パス';

  @override
  String get surveillance_format_title => '外部ドライブをフォーマット';

  @override
  String get surveillance_format_warning =>
      'SDカードまたはUSBドライブ上のすべてのデータを完全に消去します。';

  @override
  String get surveillance_format_button => 'SDカード／USBをフォーマット';

  @override
  String get surveillance_format_confirm => 'もう一度タップ — すべてのデータが消去されます';

  @override
  String get surveillance_format_running => 'フォーマット中…お待ちください';

  @override
  String get surveillance_dismiss => '閉じる';

  @override
  String get surveillance_sync_title => 'データベースカタログ';

  @override
  String get surveillance_sync_description => '監視インデックスをディスク上のファイルと照合します。';

  @override
  String get surveillance_sync_button => 'データベースを同期';

  @override
  String get surveillance_sync_running => '同期中…';

  @override
  String get surveillance_advanced_camera_title => 'カメラ選択';

  @override
  String get surveillance_advanced_camera_front => '前';

  @override
  String get surveillance_advanced_camera_right => '右';

  @override
  String get surveillance_advanced_camera_rear => '後';

  @override
  String get surveillance_advanced_camera_left => '左';

  @override
  String get surveillance_advanced_ai_title => 'AIと威嚇';

  @override
  String get surveillance_advanced_ai_detection => 'AI検知';

  @override
  String get surveillance_advanced_night_mode => 'ナイトモード';

  @override
  String get surveillance_advanced_deterrent_label => '威嚇アクション';

  @override
  String get surveillance_deterrent_silent => 'サイレント';

  @override
  String get surveillance_deterrent_horn => 'クラクション';

  @override
  String get surveillance_deterrent_flash => 'フラッシュ';

  @override
  String get surveillance_apply_button => '変更を適用';

  @override
  String get surveillance_apply_failed => '保存に失敗しました';
}
