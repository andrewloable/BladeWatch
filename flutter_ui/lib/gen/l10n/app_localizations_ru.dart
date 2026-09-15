// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Поддерживает работу мониторинга автомобиля BladeWatch в фоновом режиме. Эта служба не читает содержимое экрана и не взаимодействует с ним.';

  @override
  String get action_cancel => 'Отмена';

  @override
  String get action_clear_plain => 'Очистить';

  @override
  String get action_select_all => 'Выберите все';

  @override
  String get action_select_all_short => 'Все';

  @override
  String get action_delete => 'Удалить';

  @override
  String get action_done => 'ГОТОВО';

  @override
  String get action_remind_me_later => 'НАПОМНИТЬ ПОЗЖЕ';

  @override
  String get action_retry => 'Повторить';

  @override
  String get action_run => 'Выполнить';

  @override
  String get action_clear_output => 'Очистить вывод';

  @override
  String get cd_camera => 'Камера';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'QR-код';

  @override
  String get cd_show_hide_token => 'Показать/скрыть токен';

  @override
  String get cd_copy_token => 'Копировать токен';

  @override
  String get cd_copy_url => 'Копировать URL';

  @override
  String get cd_clear_logs => 'Очистить журналы';

  @override
  String get cd_expand_collapse => 'Развернуть/Свернуть';

  @override
  String get cd_recording_status => 'Статус записи';

  @override
  String get cd_trip_tracking_status => 'Статус отслеживания путешествий';

  @override
  String get cd_video_thumbnail => 'Видео миниатюра';

  @override
  String get cd_play => 'Воспроизвести';

  @override
  String get cd_back => 'Назад';

  @override
  String get cd_play_pause => 'Воспроизведение/Пауза';

  @override
  String get cd_player_prev => 'Предыдущая запись';

  @override
  String get cd_player_next => 'Следующая запись';

  @override
  String get cd_player_maximize => 'Развернуть плеер';

  @override
  String get cd_player_minimize => 'Выйти из полноэкранного режима';

  @override
  String get cd_delete => 'Удалить';

  @override
  String get cd_decrease => 'Уменьшить';

  @override
  String get cd_increase => 'Увеличить';

  @override
  String get cd_expand => 'Развернуть';

  @override
  String get cd_configure => 'Настроить';

  @override
  String get cd_download_log => 'Скачать журнал';

  @override
  String get cd_reset => 'Сбросить';

  @override
  String get cd_battery => 'Аккумулятор';

  @override
  String get cd_step_completed => 'Шаг завершен';

  @override
  String get cd_permission_granted => 'Разрешение выдано';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'ТРИП';

  @override
  String get daemon_card_subprocesses => 'ПРОЦЕССЫ';

  @override
  String get logs_panel_title => 'Древницы';

  @override
  String get url_connecting => 'Подключение...';

  @override
  String get camera_selection_title => 'Выбор камеры';

  @override
  String get camera_selection_subtitle => 'Выберите источник панорамной камеры';

  @override
  String get camera_current_auto => 'Текущий: Авто';

  @override
  String get camera_option_auto => 'Авто (определяется при запуске)';

  @override
  String get camera_option_0 => 'Камера 0 — Atto отделки';

  @override
  String get camera_option_1 => 'Камера 1 — Seal (по умолчанию)';

  @override
  String get camera_option_2 => 'Камера 2';

  @override
  String get camera_option_3 => 'Камера 3';

  @override
  String get camera_option_4 => 'Камера 4';

  @override
  String get camera_option_5 => 'Камера 5';

  @override
  String get camera_selection_hint =>
      'Авто выбирает нужную камеру для вашей комплектации при каждом запуске. Камера 1 = BYD Seal, Камера 0 = комплектации Atto. После изменения идентификатора камеры перезапустите службу камеры, чтобы настройка вступила в силу.';

  @override
  String get dashboard_scan_to_connect => 'Сканировать для подключения';

  @override
  String get dashboard_qr_waiting => 'Ждём туннеля...';

  @override
  String get dashboard_daemons_running_default => '0/5 работает';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'Код доступа';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Создать новый токен';

  @override
  String get dashboard_set_password => 'Задать пароль';

  @override
  String get cd_set_password => 'Задать свой пароль';

  @override
  String get dialog_set_password_title => 'Задать свой пароль';

  @override
  String get dialog_set_password_message =>
      'Введите новый пароль доступа. Он заменит автоматически созданный токен.';

  @override
  String get dialog_set_password_hint => 'Новый пароль (мин. 12 символов)';

  @override
  String get toast_password_set => 'Пароль обновлён';

  @override
  String get toast_password_too_short =>
      'Пароль должен быть не короче 12 символов';

  @override
  String get toast_password_save_failed =>
      'Не удалось сохранить пароль — служба не готова';

  @override
  String get setup_guide_title => 'Начало';

  @override
  String get setup_guide_subtitle =>
      'Три быстрых шага для получения лучшего опыта:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Выберите свой язык';

  @override
  String get setup_language_body =>
      'По умолчанию используется язык головного устройства. Нажмите, чтобы выбрать другой для приложения BladeWatch и веб-туннеля.';

  @override
  String get setup_language_button => 'Выберите язык';

  @override
  String get setup_autostart_title => 'Отключить ограничение автозапуска';

  @override
  String get setup_autostart_body =>
      'Нажмите ниже, чтобы открыть BYD Auto-Start, и снимите флажки И с BladeWatch, И со Службы BladeWatch. Без этого запись не начнётся при включении автомобиля — придётся открывать приложение каждый раз. BYD сбрасывает эту настройку при каждой установке.';

  @override
  String get setup_autostart_button => 'Откройте BYD Автозапуск';

  @override
  String get setup_overlay_title =>
      'Позвольте отображаться в других приложениях';

  @override
  String get setup_overlay_body =>
      'Определить это, чтобы показать плавающий индикатор состояния для записи и отслеживания путешествий на вершине других приложений.';

  @override
  String get setup_overlay_button => 'Откройте настройки перекрытия';

  @override
  String get cd_close => 'Закрыть';

  @override
  String get language_picker_title => 'Язык';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return 'Доступно языков: $arg1';
  }

  @override
  String get language_picker_subtitle_pending => 'Выберите язык';

  @override
  String get language_auto_title => 'Авто';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Использовать язык системы · $arg1';
  }

  @override
  String get language_not_saved =>
      'Язык применён, но сохранить его не удалось — при перезапуске он сбросится.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Авто';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Введите команду...';

  @override
  String get adb_preset_commands_header => 'Предназначенные команды';

  @override
  String get adb_output_header => 'Вывод';

  @override
  String get adb_output_ready => 'Готовы к команде...';

  @override
  String get adb_console_hero_title => 'Консоль ADB';

  @override
  String get adb_console_hero_subtitle =>
      'Используйте команды shell на устройстве';

  @override
  String get adb_console_unavailable_title => 'ADB не подключён';

  @override
  String get adb_console_unavailable_body =>
      'На этом автомобиле обычного переключателя «Отладка по USB» в Параметрах для разработчиков недостаточно — собственная беспроводная настройка ADB (отладка по сети) головного устройства также должна быть включена, а обновление системы может её сбросить. Снова включите беспроводный ADB на головном устройстве или подключитесь через USB.';

  @override
  String get adb_console_auth_pending_title => 'Ожидание подтверждения';

  @override
  String get adb_console_auth_pending_body =>
      'Проверьте на экране головного устройства запрос «Разрешить отладку по USB?» и подтвердите его, затем повторите попытку.';

  @override
  String get performance_connecting =>
      'Подключение к монитору производительности…';

  @override
  String get performance_hero_title => 'Производительность системы';

  @override
  String get performance_cpu_title => 'Процессор';

  @override
  String get performance_cpu_system_usage => 'Использование системой';

  @override
  String get performance_cpu_app_usage => 'Использование приложением';

  @override
  String get performance_frequency_label => 'Частота';

  @override
  String get performance_temperature_label => 'Температура';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Память';

  @override
  String get performance_usage_label => 'Использование';

  @override
  String get performance_memory_total => 'Всего';

  @override
  String get performance_memory_used => 'Использовано';

  @override
  String get performance_memory_app => 'Приложение';

  @override
  String get performance_gpu_title => 'Графика';

  @override
  String get performance_app_process_title => 'Процесс приложения';

  @override
  String get performance_threads_label => 'Потоки';

  @override
  String get performance_gc_cycles_label => 'Циклы GC';

  @override
  String get performance_open_fds_label => 'Открытые FD';

  @override
  String get performance_refreshing_footer => 'Обновление каждые 3 секунды';

  @override
  String get webview_loading => 'Загрузка...';

  @override
  String get reset_title => 'Сбросить данные';

  @override
  String get reset_subtitle => 'Стерть накопленные данные по категориям';

  @override
  String get reset_warning =>
      'Это действие нельзя отменить. Записи, поездки и история аккумулятора будут удалены навсегда.';

  @override
  String get reset_cat_trips => 'Поездки';

  @override
  String get reset_cat_trips_desc =>
      'История путешествий, маршруты, еженедельные/месячные переходы';

  @override
  String get reset_cat_soc_history => 'История SoC & 12V';

  @override
  String get reset_cat_soc_history_desc =>
      'Образцы СОК, зарядные сеансы, журналы напряжения';

  @override
  String get reset_cat_recordings => 'Записи (видео)';

  @override
  String get reset_cat_recordings_desc => 'Все MP4 в папке записей';

  @override
  String get reset_cat_sentry_events => 'События наблюдения';

  @override
  String get reset_cat_sentry_events_desc =>
      'Клипы событий наблюдения и сопутствующие JSON-файлы';

  @override
  String get reset_cat_proximity => 'Записи приближения';

  @override
  String get reset_cat_proximity_desc =>
      'MP4 событий с радиолокационным задействованием';

  @override
  String get reset_cat_trip_files => 'Поездка телеметрические файлы';

  @override
  String get reset_cat_trip_files_desc => 'Телеметрия за поездку JSON на диске';

  @override
  String get recording_lib_chip_any => 'Любая';

  @override
  String get recording_lib_chip_person => 'Человек';

  @override
  String get recording_lib_chip_vehicle => 'Автомобиль';

  @override
  String get recording_lib_chip_bike => 'Велосипед';

  @override
  String get recording_lib_chip_animal => 'Животные';

  @override
  String get recording_lib_chip_alert => 'Предупреждение';

  @override
  String get recording_lib_chip_critical => 'Критическая';

  @override
  String get recording_lib_selected_count_zero => '0 выбран';

  @override
  String get recording_lib_no_recordings => 'Никаких записей';

  @override
  String get recording_lib_filter_button => 'Фильтр';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Фильтр · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Фильтр записей';

  @override
  String get recording_lib_filter_apply => 'Применить';

  @override
  String get recording_lib_filter_reset => 'Сбросить';

  @override
  String get recording_lib_filter_section_what => 'Что';

  @override
  String get recording_lib_filter_section_severity => 'Тяжесть';

  @override
  String get recording_lib_filter_section_type => 'Тип';

  @override
  String get recording_lib_chip_type_normal => 'Норм.';

  @override
  String get recording_lib_chip_type_proximity => 'Близость';

  @override
  String get recording_lib_date_today => 'Сегодня';

  @override
  String get recording_lib_date_yesterday => 'Вчера';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 клипов',
      many: '$arg1 клипов',
      few: '$arg1 клипа',
      one: '$arg1 клип',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Выберите дату';

  @override
  String get recording_lib_date_all_days => 'Все дни';

  @override
  String get cd_clear_date_filter => 'Показать все дни';

  @override
  String get recording_lib_section_morning => 'Утро';

  @override
  String get recording_lib_section_afternoon => 'День';

  @override
  String get recording_lib_section_evening => 'Вечер';

  @override
  String get recording_lib_section_night => 'Ночь';

  @override
  String get cd_previous_day => 'Предыдущий день';

  @override
  String get cd_next_day => 'На следующий день';

  @override
  String get cd_open_filters => 'Открыть фильтры';

  @override
  String get cd_clear_filter => 'Сбросить фильтр';

  @override
  String get player_title_recording => 'Запись';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Служба камеры';

  @override
  String get daemon_name_surveillance => 'Служба наблюдения';

  @override
  String get daemon_name_acc => 'Наблюдение ACC';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'Фоновые службы';

  @override
  String get daemons_count_pending => 'Загрузка служб…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 из $arg2 работающий';
  }

  @override
  String get battery_health_title => 'Здоровье батареи';

  @override
  String get battery_health_unavailable => 'Недоступно';

  @override
  String get battery_health_unavailable_desc =>
      'Оценка состояния батареи недоступна.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% на $arg2';
  }

  @override
  String get dialog_ok => 'ОК';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Записи $arg1 удалены',
      one: 'Запись $arg1 удалена',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Удалить записи $arg1',
      one: 'Удалить запись $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'Будет безвозвратно удалено записей: $arg1. Это действие нельзя отменить.',
      one:
          'Будет безвозвратно удалена $arg1 запись. Это действие нельзя отменить.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'Приложение обновлено (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Разрешение на хранение требуется для записей';

  @override
  String get toast_url_copied_short => 'URL скопирован!';

  @override
  String get toast_camera_set_to_auto => 'Камера настроена на Авто';

  @override
  String get toast_failed_to_save_short => 'Не удалось сохранить';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Не удалось: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Камера $arg1 выбрана — следующий цикл ACC';
  }

  @override
  String get toast_clearing_camera_config => 'Очищает конфигурацию камеры...';

  @override
  String get toast_restarting_camera_daemon => 'Перезапуск службы камеры...';

  @override
  String get toast_camera_daemon_restarting =>
      'Служба камеры перезапускается с полным зондированием';

  @override
  String get toast_camera_restart_failed =>
      'Конфигурация очищена, но перезапуск службы не удался. Пожалуйста, перезапустите вручную.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Не удалось: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'Выберите хотя бы одну категорию';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Не удалось перезагрузить: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return '$arg1 монитор трафика…';
  }

  @override
  String get dialog_close => 'Закрыть';

  @override
  String get dialog_reset => 'Сбросить';

  @override
  String get dialog_delete => 'Удалить';

  @override
  String get dialog_save => 'Сохранить';

  @override
  String get dialog_enable => 'Включить';

  @override
  String get dialog_disable => 'Отключить';

  @override
  String get dialog_keep_enabled => 'Оставить включённым';

  @override
  String get dialog_keep_disabled => 'Оставить отключённым';

  @override
  String get dialog_regenerate => 'Создать заново';

  @override
  String get dialog_reset_selected => 'Сбросить выбранное';

  @override
  String get dialog_reset_following_title => 'Сбросить следующее?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Это действие нельзя отменить.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Сброс завершён';

  @override
  String get dialog_traffic_cannot_check_title => 'Не могу проверить статус';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB не подключен, и приложению не удалось переподключиться автоматически.\n\nНа этом автомобиле обычного переключателя «Отладка по USB» в параметрах разработчика недостаточно — также должна быть включена собственная настройка беспроводного ADB (отладка по сети) головного устройства, а обновление системы может её сбросить. Включите беспроводной ADB на головном устройстве заново или подключитесь через USB.\n\nСтатус обновится автоматически после подключения.';

  @override
  String get dialog_traffic_disable_title => 'Отключить BYD Traffic Monitor?';

  @override
  String get dialog_traffic_disable_message =>
      'BYD Traffic Monitor (com.byd.trafficmonitor) — встроенное системное приложение, которое постоянно отслеживает дорожную обстановку в фоновом режиме.\n\nЗачем его отключать?\n\n• Расходует мобильный трафик (даже на парковке)\n• Нагружает процессор и аккумулятор в фоне\n• Не нужен, если вы пользуетесь отдельным навигатором\n• Может мешать сетевой работе видеорегистратора\n\nОтключать безопасно: это влияет только на встроенный слой пробок на карте. Навигация, Bluetooth и все остальные функции автомобиля не затрагиваются.\n\nПосле отключения нужна жёсткая перезагрузка (удерживайте кнопку центральной консоли 5 секунд).';

  @override
  String get dialog_traffic_enable_title =>
      'Возобновить управление на дороге BYD?';

  @override
  String get dialog_traffic_enable_message =>
      'Монитор трафика BYD в настоящее время отключен.\n\nВосстановление его активации восстановит встроенный перекрытие трафика на навигационной карте. Обратите внимание, что он будет работать в фоне и потреблять мобильные данные.\n\nСердкое перезагрузка требуется после включения (поддерживайте кнопку центральной консоли 5 секунд).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Монитор дорожного движения $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'Изменение было применено.\n\nПожалуйста, выполните жесткий перезапуск сейчас:\nНажмите и держите кнопку центральной консоли в течение 5 секунд.';

  @override
  String get traffic_monitor_loading =>
      'Монитор дорожного движения: проверка...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Монитор трафика (нажмите, чтобы проверить)';

  @override
  String get reset_label_trips => 'Поездки';

  @override
  String get reset_label_soc_history => 'История SoC + 12V';

  @override
  String get reset_label_recordings => 'Записи';

  @override
  String get reset_label_sentry_events => 'События наблюдения';

  @override
  String get reset_label_proximity => 'Записи приближения';

  @override
  String get reset_label_trip_files => 'Поездка телеметрические файлы';

  @override
  String get toast_access_code_copied => 'Код доступа скопирован';

  @override
  String get dialog_regenerate_token_title => 'Создать новый токен';

  @override
  String get dialog_regenerate_token_message =>
      'Текущий токен станет недействительным. Все активные сеансы будут завершены. Продолжить?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Создан новый токен. Все сеансы завершены.';

  @override
  String get toast_token_regenerated_restart =>
      'Токен обновлён. Возможно, потребуется перезапуск служб для применения.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Токен обновлён. Не удалось уведомить фоновую службу.';

  @override
  String get toast_token_regenerated => 'Регенерированный токен';

  @override
  String get dashboard_no_tunnel => 'Туннель не запущен';

  @override
  String get dashboard_starting_tor => 'Запуск туннеля Tor…';

  @override
  String get dashboard_waiting_url => 'Ждём туннеля URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 работает';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'Код доступа';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'Не требуется конфигурации для $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'Токен не может быть пустым';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Привозить журнал $arg1...';
  }

  @override
  String get toast_log_empty_or_missing => 'Файл журнала пустой или не найден';

  @override
  String get toast_log_empty => 'Файл журнала пустой';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Не удалось сохранить журнал: $arg1';
  }

  @override
  String get toast_log_not_found => 'Файл журнала не найден или нечитаемый';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return '$arg1 Журнал - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Поделиться $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 Логотип ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Источник: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'Экспорт: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'ПРИМЕЧАНИЕ: журнал сокращён до последних 10000 строк (всего: $arg1 строк)',
      many:
          'ПРИМЕЧАНИЕ: журнал сокращён до последних 10000 строк (всего: $arg1 строк)',
      few:
          'ПРИМЕЧАНИЕ: журнал сокращён до последних 10000 строк (всего: $arg1 строки)',
      one:
          'ПРИМЕЧАНИЕ: журнал сокращён до последних 10000 строк (всего: $arg1 строка)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Не могу воспроизвести видео: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Удалить запись';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'Удалить $arg1?\nЭто действие нельзя отменить.';
  }

  @override
  String get toast_recording_deleted => 'Запись удалена';

  @override
  String get toast_recording_delete_failed => 'Не удалось удалить запись';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 удалено, $arg2 не удалось';
  }

  @override
  String get play_with_chooser => 'Играть с';

  @override
  String setup_version_banner(Object arg1) {
    return 'Обновлено на v$arg1 — подтвердить автозапуск, BYD стирает его на каждой установке';
  }

  @override
  String get setup_overlay_already_granted => 'Уже предоставлено';

  @override
  String camera_current_manual(Object arg1) {
    return 'Текущая: Камера $arg1 (учебное пособие)';
  }

  @override
  String get camera_current_auto_label => 'Текущий: Авто';

  @override
  String get soh_estimation_active => 'Оценка активная';

  @override
  String get soh_oem_readout =>
      'Показания SOH автомобиля — ожидание расчётной оценки';

  @override
  String get soh_nominal_baseline =>
      'Номинальная база — ожидание достоверных данных SOH';

  @override
  String get soh_no_estimate_yet => 'Пока нет оценки — ожидается информация';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 выбран';
  }

  @override
  String get video_player_playback_error => 'Ошибка воспроизведения';

  @override
  String get video_player_no_events => 'Никаких событий';

  @override
  String get daemon_configuration_required => 'Необходимая конфигурация';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Видеоплейер';

  @override
  String get status_overlay_notif_title => 'Статус BladeWatch';

  @override
  String get status_overlay_notif_text => 'Статус накладки активный';

  @override
  String get rail_dashboard => 'Панель';

  @override
  String get rail_live => 'Эфир';

  @override
  String get rail_recordings => 'Записи';

  @override
  String get rail_vehicle => 'Автомобиль';

  @override
  String get rail_trips => 'Поездки';

  @override
  String get rail_location => 'Местоположение';

  @override
  String get rail_diagnostics => 'Диагностика';

  @override
  String get rail_settings => 'Настройки';

  @override
  String get settings_section_appearance => 'Внешний вид';

  @override
  String get settings_section_recording => 'Запись';

  @override
  String get settings_section_surveillance => 'Видеонаблюдение';

  @override
  String get settings_section_daemons => 'Службы';

  @override
  String get settings_section_privacy => 'Конфиденциальность и данные';

  @override
  String get settings_section_overlay => 'Наложение статуса';

  @override
  String get settings_overlay_subtitle =>
      'Выберите, какие сегменты плавающей таблетки остаются видимыми.';

  @override
  String get settings_overlay_camera_title => 'Камера указатель';

  @override
  String get settings_overlay_camera_subtitle =>
      'Покажите значок REC / PROX, пока запись работает.';

  @override
  String get settings_overlay_trip_title => 'Показать Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Покажите значок TRIP, пока работает детекция путешествий.';

  @override
  String get settings_section_about => 'О приложении';

  @override
  String get settings_subrail_overline => 'Устройства';

  @override
  String get cd_settings_subrail => 'Боковая панель настроек';

  @override
  String get settings_privacy_title => 'Конфиденциальность и данные';

  @override
  String get settings_privacy_body =>
      'Сброс очищает индекс записей, кешированные учётные данные, состояние служб и настройки на устройстве. Действие невозможно отменить.';

  @override
  String get settings_about_title => 'О BladeWatch';

  @override
  String get settings_about_version_label => 'Версия';

  @override
  String get settings_about_package_label => 'Построение';

  @override
  String get settings_about_support_section =>
      'Поддерживаются такими людьми, как ты.';

  @override
  String get settings_about_support_share_title =>
      'Расскажите другому владельцу';

  @override
  String get settings_about_support_share_value =>
      'Каждый общий ссылка помогает другому владельцу BYD обнаружить BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Проверьте BladeWatch — открытый код наблюдения и дашкамы для BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser =>
      'Распределяйте сверхвыгоду';

  @override
  String get settings_about_open_link_failed => 'Не удалось открыть ссылку.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'Никакой браузер не найден. URL скопирован: $arg1';
  }

  @override
  String get settings_about_support_kofi_title =>
      'Заправляйте следующий выпуск';

  @override
  String get settings_about_support_kofi_value =>
      'Кофе на Ко-Фи заставляет задерживаться поздней ночи.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Лицензия';

  @override
  String get settings_about_license_value =>
      'MIT — открытый код. Нажмите, чтобы просмотреть полный текст.';

  @override
  String get settings_about_source_title => 'Исходный код';

  @override
  String get settings_about_source_value =>
      'Github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_license_url =>
      'https://github.com/yash-srivastava/BladeWatch-release/blob/main/LICENSE';

  @override
  String get settings_about_source_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_star_title => 'Отпустить на GitHub';

  @override
  String get settings_about_star_value => 'Займёт секунду. Значит очень много.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Спасибо';

  @override
  String get settings_about_thanks_subtitle =>
      'Создано с помощью контрибьюторов и сторонников.';

  @override
  String get settings_about_contributors_title => 'Контрибьюторы';

  @override
  String get settings_about_supporters_title => 'Сторонники';

  @override
  String get settings_about_thanks_empty =>
      'Список заполнится, когда подключатся люди.';

  @override
  String get settings_theme_label => 'Тема';

  @override
  String get settings_theme_auto => 'Авто (как в системе)';

  @override
  String get settings_theme_light => 'Светлая';

  @override
  String get settings_theme_dark => 'Тёмная';

  @override
  String get settings_language_label => 'Язык';

  @override
  String get settings_drive_side_label => 'Сторона навигации';

  @override
  String get settings_drive_side_subtitle =>
      'Выберите, с какой стороны экрана будет меню навигации.';

  @override
  String get settings_drive_side_left => 'Слева';

  @override
  String get settings_drive_side_left_hint => 'ЛР · по умолчанию';

  @override
  String get settings_drive_side_right => 'Справа';

  @override
  String get settings_drive_side_right_hint => 'Праворульные авто';

  @override
  String get settings_drive_side_auto => 'Авто';

  @override
  String get settings_drive_side_auto_hint => 'Определять по авто';

  @override
  String get settings_drive_side_caption_left => 'Навигация слева';

  @override
  String get settings_drive_side_caption_right => 'Навигация справа';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Авто — авто сообщает левый руль';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Авто — авто сообщает правый руль';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Авто — авто недоступно, слева';

  @override
  String get recordings_title => 'Записи';

  @override
  String get recordings_segment_dashcam => 'Дашкам';

  @override
  String get recordings_segment_surveillance => 'Наблюдение';

  @override
  String get recordings_action_settings => 'Настройки';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 сегодня · $arg2 общее · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Видеорегистратор · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Наблюдение · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Выберите запись';

  @override
  String get recordings_preview_placeholder_body =>
      'Нажмите на любую вещь слева, чтобы просматривать ее.';

  @override
  String get diagnostics_section_adb_console => 'Консоль ADB';

  @override
  String get diagnostics_section_traffic => 'Монитор дорожного движения';

  @override
  String get diagnostics_section_camera_probe => 'Зонд камеры';

  @override
  String get diagnostics_section_battery => 'Состояние батареи';

  @override
  String get diagnostics_section_performance => 'Производительность';

  @override
  String get diagnostics_hero_title => 'Диагностика системы';

  @override
  String get diagnostics_hero_subtitle =>
      'Живое здоровье, журналы и зонды устройства.';

  @override
  String get diagnostics_health_clear => 'Всё в порядке';

  @override
  String get diagnostics_health_section => 'Здоровье';

  @override
  String get diagnostics_health_network => 'Сеть';

  @override
  String get diagnostics_health_storage => 'Хранилище';

  @override
  String get diagnostics_health_camera => 'Камера';

  @override
  String get diagnostics_health_battery => 'Аккумулятор';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Онлайн';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Тоннель · $arg1';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Онлайн';

  @override
  String get diagnostics_tunnel_state_offline => 'Оффлайн';

  @override
  String get diagnostics_tunnel_state_connecting => 'Подключение';

  @override
  String get diagnostics_network_mobile => 'Мобильные';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Оффлайн';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 клипов · занято $arg2',
      many: '$arg1 клипов · занято $arg2',
      few: '$arg1 клипа · занято $arg2',
      one: '$arg1 клип · занято $arg2',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 свободный';
  }

  @override
  String get diagnostics_logs_card_title => 'Запись событий в прямом эфире';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Поток выхода из работающих сервисов.';

  @override
  String get diagnostics_tools_section => 'Инструменты';

  @override
  String get diagnostics_traffic_subtitle => 'Смотрите на живую передачу сети.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Проверьте подключенные потоки камер.';

  @override
  String get diagnostics_adb_subtitle => 'Откройте терминал на устройстве.';

  @override
  String get diagnostics_battery_subtitle =>
      'Проверьте камеру SOH и упаковывайте статистику.';

  @override
  String get diagnostics_settings_subtitle =>
      'Предпочтения приложения, тема и язык.';

  @override
  String get settings_action_reset_data => 'Сбросить данные…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'На страже';

  @override
  String get dashboard_subtitle_all_systems => 'Все системы онлайн';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 услуг $arg2 онлайн';
  }

  @override
  String get dashboard_subtitle_no_tunnel =>
      'Дистанционный доступ в автономном режиме';

  @override
  String get dashboard_metric_recordings => 'Сегодняшние записи';

  @override
  String get dashboard_metric_storage => 'Используемое хранилище';

  @override
  String get dashboard_metric_tunnel => 'Дистанционный доступ';

  @override
  String get dashboard_metric_services => 'Фоновые службы';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Автомобиль';

  @override
  String get dashboard_chip_recording_active => 'Запись';

  @override
  String get dashboard_chip_recording_idle => 'Простой';

  @override
  String get dashboard_vehicle_tap_to_set => 'Нажмите, чтобы задать';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Задать ёмкость батареи';

  @override
  String get vehicle_dialog_model_label => 'Модель';

  @override
  String get vehicle_dialog_save => 'Сохранить';

  @override
  String get settings_recording_tab_status => 'Состояние';

  @override
  String get settings_recording_tab_capture => 'Съёмка';

  @override
  String get settings_recording_tab_quality => 'Качество';

  @override
  String get settings_recording_tab_storage => 'Хранилище';

  @override
  String get settings_recording_status_title => 'Состояние записи';

  @override
  String get settings_recording_status_current_state => 'Текущее состояние';

  @override
  String get settings_recording_status_today_count => 'Записей сегодня';

  @override
  String get settings_recording_mode_title => 'Режим записи (ACC вкл.)';

  @override
  String get settings_recording_mode_description =>
      'Выберите, когда видеорегистратор должен вести запись во время движения.';

  @override
  String get settings_recording_mode_none_label => 'Нет (по умолчанию)';

  @override
  String get settings_recording_mode_none_desc =>
      'Без записи — наблюдение продолжает работать';

  @override
  String get settings_recording_mode_continuous_label => 'Постоянная';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Запись всё время во время движения';

  @override
  String get settings_recording_mode_drive_label => 'Режим движения';

  @override
  String get settings_recording_mode_drive_desc =>
      'Запись только при движении автомобиля';

  @override
  String get settings_recording_mode_proximity_label =>
      'Охрана по датчику приближения';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Запись при обнаружении движения';

  @override
  String get settings_recording_limit_title => 'Длительность записи';

  @override
  String get settings_recording_limit_description =>
      'Максимальная длительность одного файла. Записи разбиваются на новые файлы с этим интервалом.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_quality_title => 'Качество записи';

  @override
  String get settings_recording_storage_title => 'Хранилище записей';

  @override
  String get settings_recording_storage_location_label => 'Место хранения';

  @override
  String get settings_recording_storage_internal => 'Внутренняя память';

  @override
  String get settings_recording_storage_sd_card => 'SD-карта';

  @override
  String get settings_recording_storage_sd_card_na => 'SD-карта (нет)';

  @override
  String get settings_recording_storage_limit_label =>
      'Лимит хранилища — при достижении старые записи удаляются автоматически';

  @override
  String get settings_recording_storage_usage_label =>
      'Использование хранилища';

  @override
  String get settings_recording_storage_files_label => 'Файлы';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return 'Использовано $arg1 из $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 записей',
      many: '$arg1 записей',
      few: '$arg1 записи',
      one: '$arg1 запись',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Путь';

  @override
  String get settings_recording_storage_sd_free_label => 'Свободно на SD-карте';

  @override
  String get settings_recording_storage_internal_free_label =>
      'Свободно во внутренней памяти';

  @override
  String get settings_recording_format_title =>
      'Форматировать внешний накопитель';

  @override
  String get settings_recording_format_warning =>
      'Безвозвратно удаляет ВСЕ данные с SD-карты или USB-накопителя.';

  @override
  String get settings_recording_format_confirm =>
      'Нажмите ещё раз — ВСЕ данные будут УДАЛЕНЫ';

  @override
  String get settings_recording_format_running => 'Форматирование… подождите';

  @override
  String get settings_recording_format_button => 'Форматировать SD-карту / USB';

  @override
  String get settings_recording_format_no_drive =>
      'Съёмный накопитель не найден';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Форматирование завершено. Новый путь: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Каталог базы данных';

  @override
  String get settings_recording_sync_description =>
      'Сверяет список записей с файлами на диске.';

  @override
  String get settings_recording_sync_running => 'Синхронизация…';

  @override
  String get settings_recording_sync_button => 'Синхронизировать базу';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Синхронизировано: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress =>
      'Синхронизация уже выполняется';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Ошибка синхронизации: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Применить изменения';

  @override
  String get settings_recording_dismiss => 'Закрыть';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Запуск/остановка $arg1 пока не поддерживается';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 используется · $arg2 свободный';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Хранилище —';

  @override
  String get dashboard_tunnel_offline => 'Оффлайн';

  @override
  String get dashboard_tunnel_online => 'Онлайн';

  @override
  String get dashboard_tunnel_connecting => 'Подключение...';

  @override
  String get dashboard_trips_this_week => 'На этой неделе';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 поездки',
      many: '$arg1 поездок',
      few: '$arg1 поездки',
      one: '$arg1 поездка',
    );
    return '$_temp0';
  }

  @override
  String dashboard_trips_distance_km(Object arg1) {
    return '$arg1 км';
  }

  @override
  String dashboard_trips_distance_mi(Object arg1) {
    return '$arg1 миль';
  }

  @override
  String dashboard_trips_duration(Object arg1) {
    return '$arg1';
  }

  @override
  String get dashboard_trips_label_trips => 'Поездки';

  @override
  String get dashboard_trips_label_distance => 'Расстояние';

  @override
  String get dashboard_trips_label_time => 'Время в пути';

  @override
  String get dashboard_trips_no_data => 'За эту неделю поездок нет';

  @override
  String get dashboard_trips_unavailable =>
      'Начните движение, чтобы увидеть статистику';

  @override
  String get dashboard_trips_loading => 'Загрузка…';

  @override
  String get dashboard_trips_view_all => 'Все поездки';

  @override
  String get dashboard_action_live => 'Прямой эфир';

  @override
  String get dashboard_action_live_subtitle => 'Открыть вид с камеры';

  @override
  String get dashboard_action_recordings => 'Записи';

  @override
  String get dashboard_action_settings => 'Настройки';

  @override
  String get dashboard_action_settings_subtitle => 'Предпочтения и о';

  @override
  String get settings_hero_title => 'Настройки';

  @override
  String get settings_hero_overline => 'ОПРЕДРИВАНИЕ';

  @override
  String get settings_hero_subtitle =>
      'Настройка внешнего вида, записи, наблюдения и данных на устройстве.';

  @override
  String get settings_overline_preferences => 'Преференции';

  @override
  String get settings_overline_about_data => 'О & DATA';

  @override
  String get settings_quick_theme_label => 'Тема';

  @override
  String get settings_quick_language_label => 'Язык';

  @override
  String get settings_section_recording_subtitle =>
      'Буферы до/после записи, кодек, лимиты хранилища.';

  @override
  String get settings_section_surveillance_subtitle =>
      'График, чувствительность к движению, обнаружение объектов.';

  @override
  String get settings_section_daemons_subtitle =>
      'Туннель Tor и фоновые службы.';

  @override
  String get settings_about_row_title => 'О BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Версия, лицензия, поддержка разработки.';

  @override
  String get settings_reset_row_subtitle =>
      'Чистые записи, события или все скрытые.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Тема, язык и визуальные предпочтения.';

  @override
  String get settings_theme_active_auto_caption => 'Авто следует теме системы.';

  @override
  String get settings_theme_active_light_caption =>
      'Светлая тема всегда включена.';

  @override
  String get settings_theme_active_dark_caption =>
      'Темная тема всегда включена.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return 'Доступно $arg1 из $arg2 языков';
  }

  @override
  String get settings_language_card_title => 'Язык отображения';

  @override
  String get settings_privacy_stance_title => 'На устройстве по умолчанию';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch работает полностью на головном устройстве. Никакая телеметрия не покидает вашу машину, кроме как через туннели и интеграции, которые вы изъявлено настройка.';

  @override
  String get settings_privacy_overline_storage => 'МЕЧЕСТВОЕ Хранилище';

  @override
  String get settings_privacy_overline_reset => 'Перезагрузка данных';

  @override
  String get settings_privacy_storage_clips_label => 'Клип на диске';

  @override
  String get settings_privacy_storage_size_label => 'Общий размер';

  @override
  String get settings_privacy_storage_unavailable => 'Недоступная';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 клипов',
      many: '$arg1 клипов',
      few: '$arg1 клипа',
      one: '$arg1 клип',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Выберите категории: записи, события, конфигурации служб, кешированная телеметрия...';

  @override
  String get settings_developer_overline => 'РАЗРАБОТЧИК';

  @override
  String get settings_developer_timing_logs_title => 'Журналы тайминга службы';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Записывать метки прошедшего времени при запуске службы. Отключите в обычном режиме, чтобы не засорять logcat.';

  @override
  String get settings_developer_debug_logs_title =>
      'Отладочные журналы разработчика';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Записывать все события жизненного цикла Activity и Fragment и шаги запуска в /storage/emulated/0/BladeWatch/data/debug_app.log. Сбои фиксируются всегда. По умолчанию выключено.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Камера $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Камера $arg1 (учебная)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Проверка...';

  @override
  String get diagnostics_camera_value_offline => 'Оффлайн';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Ожидаемые данные';

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
      other: '$arg1 клипов · записано $arg2',
      many: '$arg1 клипов · записано $arg2',
      few: '$arg1 клипа · записано $arg2',
      one: '$arg1 клип · записано $arg2',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Багажник';

  @override
  String get vehicle_tab_climate => 'Климат';

  @override
  String get vehicle_tab_seats => 'Сиденья';

  @override
  String get vehicle_tab_windows => 'Окна';

  @override
  String get vehicle_tab_lights => 'Освещение';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Зарядка';

  @override
  String get vehicle_locked => 'Закрыто';

  @override
  String get vehicle_unlocked => 'Открыто';

  @override
  String get vehicle_range_label => 'Запас хода';

  @override
  String get vehicle_data_unavailable => 'Данные авто недоступны.';

  @override
  String get vehicle_action_failed => 'Сбой действия. Проверьте связь с авто.';

  @override
  String get vehicle_open_trunk => 'Открыть багажник';

  @override
  String get vehicle_close_trunk => 'Закрыть багажник';

  @override
  String get vehicle_trunk_info_open =>
      'Открытие багажника сначала разблокирует авто.';

  @override
  String get vehicle_ac_on => 'AC Включен';

  @override
  String get vehicle_ac_off => 'AC выключен';

  @override
  String get vehicle_max_cooling_on => 'Макс. охлаждение: ВКЛ';

  @override
  String get vehicle_max_cooling_off => 'Макс. охлаждение: ВЫКЛ';

  @override
  String get vehicle_temp_label => 'Температура';

  @override
  String get vehicle_fan_speed_label => 'Скорость вентилятора';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Уровень $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return 'В салоне: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => 'Водитель';

  @override
  String get vehicle_seat_passenger => 'Пассажир';

  @override
  String get vehicle_seat_no_controls =>
      'Для этого авто нет управления сиденьями.';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return 'Подогрев $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return 'Охлаждение $arg1';
  }

  @override
  String get vehicle_heat_off => '(Выкл)';

  @override
  String get vehicle_heat_low => '(Низк.)';

  @override
  String get vehicle_heat_high => '(Выс.)';

  @override
  String get vehicle_seat_pos_1 => 'Положение 1';

  @override
  String get vehicle_seat_pos_2 => 'Положение 2';

  @override
  String get vehicle_all_windows => 'Все окна';

  @override
  String get vehicle_window_awake_note =>
      'Работает, только когда автомобиль активен.';

  @override
  String get vehicle_window_front_left => 'Перед. левое';

  @override
  String get vehicle_window_front_right => 'Перед. правое';

  @override
  String get vehicle_window_rear_left => 'Зад. левое';

  @override
  String get vehicle_window_rear_right => 'Зад. правое';

  @override
  String get vehicle_window_close => 'Закрыть';

  @override
  String get vehicle_window_close_vent => 'Закрыть проветривание';

  @override
  String get vehicle_window_vent_12 => 'Проветр. 12%';

  @override
  String get vehicle_window_open_all => 'Открыть все';

  @override
  String get vehicle_sunroof => 'Люк';

  @override
  String get vehicle_sunshade => 'Шторка люка';

  @override
  String get vehicle_btn_drl_title => 'Днем проходящие огни';

  @override
  String get vehicle_btn_slw_title => 'Предупреждение о ограничении скорости';

  @override
  String get vehicle_control_section_charge_cap => 'Лимит заряда';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Ограничение заряда не поддерживается этим авто.';

  @override
  String get vehicle_charge_limit_label => 'Лимит заряда';

  @override
  String get vehicle_enable_charge_limit => 'Включить лимит заряда';

  @override
  String get vehicle_charge_limit_range => 'Минимум 50%, максимум 100%';

  @override
  String get vehicle_tyre_no_signal => 'НЕТ СИГНАЛА';

  @override
  String get vehicle_tyre_slow_leak => 'МЕДЛЕННАЯ УТЕЧКА';

  @override
  String get vehicle_tyre_fast_leak => 'БЫСТРАЯ УТЕЧКА';

  @override
  String get vehicle_tyre_low => 'НИЗКОЕ';

  @override
  String get vehicle_tyre_high => 'ВЫСОКОЕ';

  @override
  String get vehicle_tyre_ok => 'НОРМА';

  @override
  String get vehicle_tyre_check_pressure => 'Проверьте давление';

  @override
  String get vehicle_toggle_on => 'ВКЛ';

  @override
  String get vehicle_toggle_off => 'ВЫКЛ';

  @override
  String get vehicle_err_climate_control => 'Сбой климат-контроля.';

  @override
  String get vehicle_err_max_cooling => 'Сбой макс. охлаждения.';

  @override
  String get vehicle_err_drl_control => 'Сбой управления ДХО.';

  @override
  String get vehicle_err_slw_control => 'Сбой управления ADAS.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Сбой переключения лимита заряда.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Уменьшить $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Увеличить $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Подключение…';

  @override
  String get vehicle_appearance_model_title => 'Выбор модели';

  @override
  String get vehicle_appearance_custom_color => 'Свой цвет';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Заряд: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Запас хода: $arg1 км';
  }

  @override
  String get vehicle_status_charge_unknown => 'Заряд: —';

  @override
  String get vehicle_status_range_unknown => 'Запас хода: —';

  @override
  String get startup_subtitle => 'Подготовка видеорегистратора';

  @override
  String get startup_header_preparing => 'Готовим всё…';

  @override
  String get startup_header_starting => 'Запуск…';

  @override
  String get startup_header_verifying => 'Почти готово…';

  @override
  String get startup_header_ready => 'Всё готово';

  @override
  String get startup_daemon_camera => 'Камера';

  @override
  String get startup_daemon_camera_desc => 'Прямой эфир и запись';

  @override
  String get startup_daemon_sentry => 'Режим охраны';

  @override
  String get startup_daemon_sentry_desc => 'Обнаружение движения и оповещения';

  @override
  String get startup_daemon_parking => 'Защита на парковке';

  @override
  String get startup_daemon_parking_desc => 'Наблюдает, пока авто на стоянке';

  @override
  String get startup_status_waiting => 'Ожидание';

  @override
  String get startup_status_starting => 'Запуск';

  @override
  String get startup_status_ready => 'Готово';

  @override
  String get startup_status_failed => 'Сбой';

  @override
  String get startup_continue_anyway => 'Всё равно продолжить';

  @override
  String get startup_continue => 'Продолжить →';

  @override
  String get live_retry => 'Повторить';

  @override
  String get live_connecting => 'Подключение к камере…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Ошибка: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Камера недоступна\n$arg1';
  }

  @override
  String get live_direction_all => 'Все';

  @override
  String get live_direction_front => 'Передняя';

  @override
  String get live_direction_right => 'Правая';

  @override
  String get live_direction_rear => 'Задняя';

  @override
  String get live_direction_left => 'Левая';

  @override
  String get trip_no_route_data => 'Нет данных маршрута для этой поездки';

  @override
  String get trips_tab_trips => 'Поездки';

  @override
  String get trips_tab_stats => 'Статистика';

  @override
  String get trips_tab_storage => 'Хранилище';

  @override
  String get trips_filter_7_days => '7 дней';

  @override
  String get trips_filter_14_days => '14 дней';

  @override
  String get trips_filter_30_days => '30 дней';

  @override
  String trips_load_error(Object message) {
    return 'Ошибка: $message';
  }

  @override
  String get trips_empty_state => 'Поездок пока не записано';

  @override
  String get trips_period_summary_title => 'Сводка за период';

  @override
  String get trips_stat_trips => 'Поездки';

  @override
  String get trips_stat_hours => 'Часы';

  @override
  String get trips_stat_efficiency => 'Эффективность';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Оценка: $score';
  }

  @override
  String get trips_driver_score_title => 'Оценка водителя';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Итого: $score / 100';
  }

  @override
  String get trips_range_title => 'Персональный запас хода';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'Оценка BYD: $km';
  }

  @override
  String get trips_range_no_data => 'Пока недостаточно данных';

  @override
  String get trips_dna_title => 'ДНК вождения';

  @override
  String get trips_dna_anticipation => 'Предвидение';

  @override
  String get trips_dna_smoothness => 'Плавность';

  @override
  String get trips_dna_speed_discipline => 'Соблюдение скорости';

  @override
  String get trips_dna_efficiency => 'Эффективность';

  @override
  String get trips_dna_consistency => 'Стабильность';

  @override
  String get trips_storage_title => 'Хранилище поездок';

  @override
  String get trips_storage_analytics_label => 'Аналитика поездок';

  @override
  String get trips_storage_rate_label => 'Тариф на электроэнергию';

  @override
  String get trips_storage_distance_unit_label => 'Единица расстояния';

  @override
  String get trips_storage_location_label => 'Место хранения';

  @override
  String get trips_storage_internal => 'Внутренняя память';

  @override
  String get trips_storage_sd_card => 'SD-карта';

  @override
  String get trips_storage_sd_card_unavailable => 'SD-карта (нет)';

  @override
  String get trips_storage_apply => 'Применить изменения';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return 'Использовано $used $unit из $limit МБ · поездок: $count';
  }

  @override
  String get trips_sync_title => 'Каталог базы данных';

  @override
  String get trips_sync_description =>
      'Сверяет список поездок с файлами телеметрии на диске.';

  @override
  String get trips_sync_button => 'Синхронизировать базу';

  @override
  String get trips_sync_running => 'Синхронизация…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Синхронизация выполнена: +$added -$removed (всего $total)';
  }

  @override
  String get trips_sync_failed_generic => 'Ошибка синхронизации';

  @override
  String get trips_detail_summary_title => 'Сводка поездки';

  @override
  String get trips_detail_distance => 'Расстояние';

  @override
  String get trips_detail_duration => 'Длительность';

  @override
  String get trips_detail_energy => 'Энергия';

  @override
  String get trips_detail_avg_speed => 'Средняя скорость';

  @override
  String get trips_detail_max_speed => 'Максимальная скорость';

  @override
  String get trips_detail_soc => 'Заряд';

  @override
  String get trips_detail_cost => 'Стоимость';

  @override
  String get trips_detail_ext_temp => 'Наружная темп.';

  @override
  String get trips_detail_elev_gain => 'Набор высоты';

  @override
  String get trips_detail_scores_title => 'Оценки вождения';

  @override
  String get trips_detail_unavailable => 'Детали поездки недоступны';

  @override
  String get trips_detail_loading => 'Загрузка поездки…';

  @override
  String trips_detail_route_points(Object count) {
    return 'Записано точек GPS: $count';
  }

  @override
  String get rec_severity_critical => 'КРИТИЧНО';

  @override
  String get rec_severity_alert => 'ТРЕВОГА';

  @override
  String get location_loading_title => 'Загрузка карты';

  @override
  String get location_permission_missing_title =>
      'Требуется разрешение на геолокацию';

  @override
  String get location_permission_denied_title => 'В разрешении отказано';

  @override
  String get location_provider_disabled_title => 'GPS отключен';

  @override
  String get location_waiting_for_fix_title => 'Ожидание сигнала GPS';

  @override
  String get location_car_location_title => 'Местоположение автомобиля';

  @override
  String get location_stale_title => 'Местоположение устарело';

  @override
  String get location_tile_failure_title => 'Карта недоступна';

  @override
  String get location_tile_failure_subtitle => 'Сеть недоступна';

  @override
  String get location_error_title => 'Ошибка определения местоположения';

  @override
  String get location_action_grant => 'Разрешить';

  @override
  String get location_action_retry => 'Повторить';

  @override
  String get location_mode_auto => 'Авто';

  @override
  String get location_mode_light => 'Светлая';

  @override
  String get location_mode_dark => 'Тёмная';

  @override
  String get cd_recenter_on_car => 'Центрировать на автомобиле';

  @override
  String get recording_lib_no_recordings_normal => 'Нет обычных записей';

  @override
  String get recording_lib_no_recordings_sentry => 'Нет событий наблюдения';

  @override
  String get recording_lib_no_recordings_proximity => 'Нет событий приближения';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'человек';

  @override
  String get video_player_legend_car => 'машина';

  @override
  String get video_player_legend_bike => 'велосипед';

  @override
  String get video_player_legend_motion => 'движение';

  @override
  String get recording_lib_proximity_very_close => 'очень близко';

  @override
  String get recording_lib_proximity_close => 'близко';

  @override
  String get recording_lib_proximity_mid => 'средне';

  @override
  String get recording_lib_proximity_far => 'далеко';

  @override
  String get surveillance_tab_general => 'Общие';

  @override
  String get surveillance_tab_detection => 'Обнаружение';

  @override
  String get surveillance_tab_recording => 'Запись';

  @override
  String get surveillance_tab_storage => 'Хранилище';

  @override
  String get surveillance_tab_advanced => 'Дополнительно';

  @override
  String get surveillance_general_title => 'Режим наблюдения';

  @override
  String get surveillance_general_enable => 'Включить наблюдение';

  @override
  String get surveillance_general_status => 'Статус';

  @override
  String get surveillance_general_status_running => 'Работает';

  @override
  String get surveillance_general_status_idle => 'Ожидание';

  @override
  String get surveillance_general_events_today => 'События сегодня';

  @override
  String get surveillance_safe_locations_title => 'Безопасные места';

  @override
  String get surveillance_safe_locations_subtitle =>
      'Камера не включится при парковке здесь';

  @override
  String get surveillance_safe_locations_enable =>
      'Отключать в безопасных местах';

  @override
  String get surveillance_safe_locations_empty =>
      'Безопасные места ещё не добавлены';

  @override
  String get surveillance_safe_locations_add_current =>
      'Добавить текущее местоположение как безопасную зону';

  @override
  String get surveillance_safe_locations_no_gps =>
      'GPS-местоположение недоступно';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Настройки обнаружения';

  @override
  String get surveillance_detection_preset_label => 'Профиль окружения';

  @override
  String get surveillance_preset_outdoor => 'На улице';

  @override
  String get surveillance_preset_garage => 'Гараж';

  @override
  String get surveillance_preset_street => 'Улица';

  @override
  String get surveillance_preset_custom => 'Пользовательский';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Чувствительность (1=строгая, 5=высокая): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Обнаруживать объекты';

  @override
  String get surveillance_detection_object_person => 'человек';

  @override
  String get surveillance_detection_object_car => 'машина';

  @override
  String get surveillance_detection_object_bike => 'велосипед';

  @override
  String get surveillance_recording_title => 'Запись событий';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Предзапись (секунд до события): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Дозапись (секунд после события): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Хранилище наблюдения';

  @override
  String get surveillance_storage_location_label => 'Место хранения';

  @override
  String get surveillance_storage_internal => 'Внутреннее';

  @override
  String get surveillance_storage_sd_card => 'SD-карта';

  @override
  String get surveillance_storage_sd_card_na => 'SD-карта (недоступна)';

  @override
  String get surveillance_storage_limit_label =>
      'Лимит хранилища — автоматически удаляет самые старые файлы';

  @override
  String get surveillance_storage_usage_label => 'Использование хранилища';

  @override
  String get surveillance_storage_files_label => 'Файлы';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return 'Использовано $arg1 из $arg2';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 событий',
      many: '$arg1 событий',
      few: '$arg1 события',
      one: '$arg1 событие',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'Путь';

  @override
  String get surveillance_format_title => 'Форматировать внешний накопитель';

  @override
  String get surveillance_format_warning =>
      'Безвозвратно удаляет ВСЕ данные с SD-карты или USB-накопителя.';

  @override
  String get surveillance_format_button => 'Форматировать SD-карту/USB';

  @override
  String get surveillance_format_confirm =>
      'Нажмите ещё раз — ВСЕ данные будут УДАЛЕНЫ';

  @override
  String get surveillance_format_running => 'Форматирование… подождите';

  @override
  String get surveillance_dismiss => 'Скрыть';

  @override
  String get surveillance_sync_title => 'Каталог базы данных';

  @override
  String get surveillance_sync_description =>
      'Сверяет индекс наблюдения с файлами на диске.';

  @override
  String get surveillance_sync_button => 'Синхронизировать базу данных';

  @override
  String get surveillance_sync_running => 'Синхронизация…';

  @override
  String get surveillance_advanced_camera_title => 'Выбор камер';

  @override
  String get surveillance_advanced_camera_front => 'Передняя';

  @override
  String get surveillance_advanced_camera_right => 'Правая';

  @override
  String get surveillance_advanced_camera_rear => 'Задняя';

  @override
  String get surveillance_advanced_camera_left => 'Левая';

  @override
  String get surveillance_advanced_ai_title => 'ИИ и отпугивание';

  @override
  String get surveillance_advanced_ai_detection => 'ИИ-обнаружение';

  @override
  String get surveillance_advanced_night_mode => 'Ночной режим';

  @override
  String get surveillance_advanced_deterrent_label => 'Действие отпугивания';

  @override
  String get surveillance_deterrent_silent => 'Тихо';

  @override
  String get surveillance_deterrent_horn => 'Сигнал';

  @override
  String get surveillance_deterrent_flash => 'Вспышка';

  @override
  String get surveillance_apply_button => 'Применить изменения';

  @override
  String get surveillance_apply_failed => 'Не удалось сохранить';

  @override
  String get dashboard_tor_bootstrapping => 'Подключение к Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'Как открыть этот адрес';

  @override
  String get dashboard_tor_help_title => 'Как открыть этот адрес';

  @override
  String get dashboard_tor_help_android =>
      'Android: установите Tor Browser из Google Play или F-Droid, откройте его и вставьте адрес.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone и iPad: установите Onion Browser из App Store, откройте его и вставьте адрес. Tor Browser для iOS не существует.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS и Linux: скачайте Tor Browser с torproject.org, откройте его и вставьте адрес.';

  @override
  String get dashboard_tor_help_password_note =>
      'Пароль всё равно понадобится после загрузки страницы.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'Отсканируйте, чтобы открыть страницу загрузки Tor Browser';

  @override
  String get dashboard_tor_help_close => 'Понятно';
}
