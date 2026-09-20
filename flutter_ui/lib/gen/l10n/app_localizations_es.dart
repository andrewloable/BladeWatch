// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Mantenga activo el seguimiento del vehículo de BladeWatch en segundo plano. Este servicio no lee ni interactúa con el contenido de la pantalla.';

  @override
  String get action_cancel => 'Cancelar';

  @override
  String get action_clear_plain => 'Borrar';

  @override
  String get action_select_all => 'Seleccione todos';

  @override
  String get action_select_all_short => 'Todos';

  @override
  String get action_delete => 'Eliminar';

  @override
  String get action_done => 'HECHO';

  @override
  String get action_remind_me_later => 'RECORDAR MÁS TARDE';

  @override
  String get action_retry => 'Reintentar';

  @override
  String get action_run => 'Ejecutar';

  @override
  String get action_clear_output => 'Borrar salida';

  @override
  String get cd_camera => 'Cámara';

  @override
  String get cd_qr => 'QR';

  @override
  String get cd_qr_code => 'Código QR';

  @override
  String get cd_show_hide_token => 'Mostrar/ocultar token';

  @override
  String get cd_copy_token => 'Copiar token';

  @override
  String get cd_copy_url => 'Copiar URL';

  @override
  String get cd_clear_logs => 'Borrar registros';

  @override
  String get cd_expand_collapse => 'Expandir/Contraer';

  @override
  String get cd_recording_status => 'Estado de registro';

  @override
  String get cd_trip_tracking_status => 'Estatus de seguimiento de viajes';

  @override
  String get cd_video_thumbnail => 'Miniatura de vídeo';

  @override
  String get cd_play => 'Reproducir';

  @override
  String get cd_back => 'Atrás';

  @override
  String get cd_play_pause => 'Reproducir/Pausar';

  @override
  String get cd_player_prev => 'Grabación anterior';

  @override
  String get cd_player_next => 'Grabación siguiente';

  @override
  String get cd_player_maximize => 'Maximizar reproductor';

  @override
  String get cd_player_minimize => 'Salir de pantalla completa';

  @override
  String get cd_delete => 'Eliminar';

  @override
  String get cd_decrease => 'Disminuir';

  @override
  String get cd_increase => 'Aumentar';

  @override
  String get cd_expand => 'Expandir';

  @override
  String get cd_configure => 'Configurar';

  @override
  String get cd_download_log => 'Registro de descarga';

  @override
  String get cd_reset => 'Restablecer';

  @override
  String get cd_battery => 'Batería';

  @override
  String get cd_step_completed => 'Paso completado';

  @override
  String get cd_permission_granted => 'Permiso concedido';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'PROCESOS';

  @override
  String get logs_panel_title => 'Registros';

  @override
  String get url_connecting => 'Conectando...';

  @override
  String get camera_selection_title => 'Selección de cámara';

  @override
  String get camera_selection_subtitle =>
      'Seleccione la fuente de la cámara panorámica';

  @override
  String get camera_current_auto => 'Actual: Automático';

  @override
  String get camera_option_auto => 'Auto (detectación al inicio)';

  @override
  String get camera_option_0 => 'Cámara 0 — Atto recubrimientos';

  @override
  String get camera_option_1 => 'Cámara 1 — Seal (por defecto)';

  @override
  String get camera_option_2 => 'La cámara 2';

  @override
  String get camera_option_3 => 'La cámara 3';

  @override
  String get camera_option_4 => 'La cámara 4';

  @override
  String get camera_option_5 => 'La cámara 5';

  @override
  String get camera_selection_hint =>
      'Auto elige la cámara adecuada para su versión en cada arranque. Cámara 1 = BYD Seal, Cámara 0 = versiones Atto. Reinicie el servicio de cámara después de cambiar el ID de cámara para que la configuración entre en vigor.';

  @override
  String get dashboard_scan_to_connect => 'Escanear para conectar';

  @override
  String get dashboard_qr_waiting => 'Esperando el túnel...';

  @override
  String get dashboard_daemons_running_default => '0/5 en ejecución';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'Código de acceso';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Regenerar token';

  @override
  String get dashboard_set_password => 'Establecer contraseña';

  @override
  String get cd_set_password => 'Establecer contraseña personalizada';

  @override
  String get dialog_set_password_title => 'Establecer contraseña personalizada';

  @override
  String get dialog_set_password_message =>
      'Introduzca una nueva contraseña de acceso. Esto reemplaza el token generado automáticamente.';

  @override
  String get dialog_set_password_hint =>
      'Nueva contraseña (mín. 12 caracteres)';

  @override
  String get toast_password_set => 'Contraseña actualizada';

  @override
  String get toast_password_too_short =>
      'La contraseña debe tener al menos 12 caracteres';

  @override
  String get toast_password_save_failed =>
      'No se pudo guardar la contraseña — el servicio no está listo';

  @override
  String get setup_guide_title => 'Comenzando';

  @override
  String get setup_guide_subtitle =>
      'Tres pasos rápidos para obtener la mejor experiencia:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Elige tu lenguaje';

  @override
  String get setup_language_body =>
      'Por defecto en el idioma de su unidad principal. Toque para elegir uno diferente para la aplicación BladeWatch y el túnel web.';

  @override
  String get setup_language_button => 'Elige el idioma';

  @override
  String get setup_autostart_title =>
      'Deshabilitar la restricción de arranque automático';

  @override
  String get setup_autostart_body =>
      'Toca abajo para abrir BYD Auto-Start y desmarca BladeWatch Y Servicio BladeWatch. Sin esto, la grabación no se inicia al encender el coche: tendrás que abrir la aplicación cada vez. BYD lo restablece en cada instalación.';

  @override
  String get setup_autostart_button => 'Abre BYD arranque automático';

  @override
  String get setup_overlay_title =>
      'Permite que se muestre en otras aplicaciones';

  @override
  String get setup_overlay_body =>
      'Habilitar esto para mostrar un indicador de estado flotante para grabar y rastrear viajes en la parte superior de otras aplicaciones.';

  @override
  String get setup_overlay_button =>
      'Abre las configuraciones de superposición';

  @override
  String get cd_close => 'Cerrar';

  @override
  String get language_picker_title => 'Lenguaje';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return 'Idiomas $arg1 disponibles';
  }

  @override
  String get language_picker_subtitle_pending => 'Elige un idioma';

  @override
  String get language_auto_title => 'Automático';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Sistema de seguimiento · $arg1';
  }

  @override
  String get language_not_saved =>
      'Idioma aplicado, pero no se pudo guardar: se restablecerá al reiniciar la aplicación.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Automático';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Ingrese el comando...';

  @override
  String get adb_preset_commands_header => 'Los comandos preset';

  @override
  String get adb_output_header => 'Salida';

  @override
  String get adb_output_ready => 'Preparados para los comandos...';

  @override
  String get adb_console_hero_title => 'Consola ADB';

  @override
  String get adb_console_hero_subtitle =>
      'Ejecutar los comandos de shell en el dispositivo';

  @override
  String get adb_console_unavailable_title => 'ADB no está conectado';

  @override
  String get adb_console_unavailable_body =>
      'En este vehículo, el interruptor estándar de «Depuración USB» en Opciones de desarrollador no es suficiente por sí solo: el propio ajuste de ADB inalámbrico (depuración de red) de la unidad central también debe estar activado, y una actualización del sistema puede restablecerlo. Vuelva a activar el ADB inalámbrico en la unidad central, o conéctese por USB.';

  @override
  String get adb_console_auth_pending_title => 'Esperando aprobación';

  @override
  String get adb_console_auth_pending_body =>
      'Busque en la pantalla de la unidad central el aviso «¿Permitir depuración USB?» y acéptelo, luego reintente.';

  @override
  String get performance_connecting =>
      'Conectando con el monitor de rendimiento…';

  @override
  String get performance_hero_title => 'Rendimiento del sistema';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'Uso del sistema';

  @override
  String get performance_cpu_app_usage => 'Uso de la app';

  @override
  String get performance_frequency_label => 'Frecuencia';

  @override
  String get performance_temperature_label => 'Temperatura';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Memoria';

  @override
  String get performance_usage_label => 'Uso';

  @override
  String get performance_memory_total => 'Total';

  @override
  String get performance_memory_used => 'Usada';

  @override
  String get performance_memory_app => 'App';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'Proceso de la app';

  @override
  String get performance_threads_label => 'Hilos';

  @override
  String get performance_gc_cycles_label => 'Ciclos de GC';

  @override
  String get performance_open_fds_label => 'FD abiertos';

  @override
  String get performance_refreshing_footer => 'Actualizando cada 3 segundos';

  @override
  String get webview_loading => 'Cargando...';

  @override
  String get reset_title => 'Restablecer datos';

  @override
  String get reset_subtitle => 'Eliminar los datos acumulados por categoría';

  @override
  String get reset_warning =>
      'Esta acción no se puede deshacer. Las grabaciones, los trayectos y el historial de la batería se eliminarán permanentemente.';

  @override
  String get reset_cat_trips => 'Viajes';

  @override
  String get reset_cat_trips_desc =>
      'Historial de viaje, rutas, recorridos semanales/mensuales';

  @override
  String get reset_cat_soc_history => 'Historia de los SoC y 12V';

  @override
  String get reset_cat_soc_history_desc =>
      'Muestras de SoC, sesiones de carga, registros de voltaje';

  @override
  String get reset_cat_recordings => 'Grabaciones (vídeos)';

  @override
  String get reset_cat_recordings_desc =>
      'Todos los MP4 en la carpeta de grabaciones';

  @override
  String get reset_cat_sentry_events => 'Eventos de vigilancia';

  @override
  String get reset_cat_sentry_events_desc =>
      'Clips de eventos de vigilancia y archivos JSON asociados';

  @override
  String get reset_cat_proximity => 'Registros de proximidad';

  @override
  String get reset_cat_proximity_desc => 'MP4s de eventos activados por radar';

  @override
  String get reset_cat_trip_files => 'Archivos de telemetría de viaje';

  @override
  String get reset_cat_trip_files_desc => 'Telemetría por viaje JSON en disco';

  @override
  String get recording_lib_chip_any => 'Cualquier';

  @override
  String get recording_lib_chip_person => 'Persona';

  @override
  String get recording_lib_chip_vehicle => 'Vehículo';

  @override
  String get recording_lib_chip_bike => 'Bicicleta';

  @override
  String get recording_lib_chip_animal => 'Animales';

  @override
  String get recording_lib_chip_alert => 'Alerta';

  @override
  String get recording_lib_chip_critical => 'Crítico';

  @override
  String get recording_lib_selected_count_zero => '0 seleccionado';

  @override
  String get recording_lib_no_recordings => 'No hay grabaciones.';

  @override
  String get recording_lib_filter_button => 'Filtro';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filtro · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Filtrar grabaciones';

  @override
  String get recording_lib_filter_apply => 'Aplicar';

  @override
  String get recording_lib_filter_reset => 'Restablecer';

  @override
  String get recording_lib_filter_section_what => 'Qué';

  @override
  String get recording_lib_filter_section_severity => 'Gravedad';

  @override
  String get recording_lib_filter_section_type => 'Tipo';

  @override
  String get recording_lib_chip_type_normal => 'Normal';

  @override
  String get recording_lib_chip_type_proximity => 'Proximidad';

  @override
  String get recording_lib_date_today => 'Hoy';

  @override
  String get recording_lib_date_yesterday => 'Ayer';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clips',
      one: '$arg1 clip',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Elige una fecha';

  @override
  String get recording_lib_date_all_days => 'Todos los días';

  @override
  String get cd_clear_date_filter => 'Mostrar todos los días';

  @override
  String get recording_lib_section_morning => 'Mañana';

  @override
  String get recording_lib_section_afternoon => 'Tarde';

  @override
  String get recording_lib_section_evening => 'Noche';

  @override
  String get recording_lib_section_night => 'Madrugada';

  @override
  String get cd_previous_day => 'Día anterior';

  @override
  String get cd_next_day => 'Día siguiente';

  @override
  String get cd_open_filters => 'Abrir filtros';

  @override
  String get cd_clear_filter => 'Borrar filtro';

  @override
  String get player_title_recording => 'Grabación';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Servicio de cámara';

  @override
  String get daemon_name_surveillance => 'Servicio de vigilancia';

  @override
  String get daemon_name_acc => 'Vigilancia ACC';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'Servicios en segundo plano';

  @override
  String get daemons_count_pending => 'Cargando servicios…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 de $arg2 en funcionamiento';
  }

  @override
  String get battery_health_title => 'Salud de la batería';

  @override
  String get battery_health_unavailable => 'No disponible';

  @override
  String get battery_health_unavailable_desc =>
      'La estimación del estado de la batería no está disponible.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% en $arg2';
  }

  @override
  String get dialog_ok => 'Aceptar';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Se suprimieron las grabaciones de $arg1',
      one: 'Se suprimió el registro $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Eliminar las grabaciones $arg1',
      one: 'Eliminar la grabación $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'Esto eliminará permanentemente $arg1 grabaciones. Esta acción no se puede deshacer.',
      one:
          'Esto eliminará permanentemente $arg1 grabación. Esta acción no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'La aplicación está actualizada (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Permiso de almacenamiento requerido para las grabaciones';

  @override
  String get toast_url_copied_short => '¡URL copiado!';

  @override
  String get toast_camera_set_to_auto => 'La cámara se ajusta a Auto';

  @override
  String get toast_failed_to_save_short => 'No pudo salvar';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Fallado: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Cámara $arg1 seleccionada — próximo ciclo ACC';
  }

  @override
  String get toast_clearing_camera_config =>
      'Despejar la configuración de la cámara...';

  @override
  String get toast_restarting_camera_daemon =>
      'Reiniciando el servicio de cámara...';

  @override
  String get toast_camera_daemon_restarting =>
      'Servicio de cámara reiniciando con sondeo completo';

  @override
  String get toast_camera_restart_failed =>
      'Configuración eliminada pero el reinicio del servicio falló. Por favor reinicie manualmente.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Fallido: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'Seleccione al menos una categoría';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Fallo de restablecimiento: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return 'El monitor de tráfico $arg1...';
  }

  @override
  String get dialog_close => 'Cerrar';

  @override
  String get dialog_reset => 'Restablecer';

  @override
  String get dialog_delete => 'Eliminar';

  @override
  String get dialog_save => 'Guardar';

  @override
  String get dialog_enable => 'Activar';

  @override
  String get dialog_disable => 'Desactivar';

  @override
  String get dialog_keep_enabled => 'Mantener activado';

  @override
  String get dialog_keep_disabled => 'Mantener desactivado';

  @override
  String get dialog_regenerate => 'Regenerar';

  @override
  String get dialog_reset_selected => 'Restablecer lo seleccionado';

  @override
  String get dialog_reset_following_title => '¿Restablecer lo siguiente?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Esto no se puede deshacer.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Restablecimiento completado';

  @override
  String get dialog_traffic_cannot_check_title =>
      'No puedo comprobar el estado';

  @override
  String get dialog_traffic_cannot_check_message =>
      'ADB no está conectado y la aplicación no pudo reconectarse automáticamente.\n\nEn este vehículo, el interruptor habitual de \"Depuración USB\" en Opciones de desarrollador no es suficiente por sí solo: la propia opción de ADB inalámbrico (depuración por red) de la unidad central también debe estar activada, y una actualización del sistema puede desactivarla. Vuelva a activar el ADB inalámbrico en la unidad central, o conéctese por USB.\n\nEl estado se actualizará automáticamente en cuanto se conecte.';

  @override
  String get dialog_traffic_disable_title =>
      '¿Desactivar el monitor de tráfico BYD?';

  @override
  String get dialog_traffic_disable_message =>
      'El BYD Traffic Monitor (com.byd.trafficmonitor) es una app de sistema integrada que supervisa continuamente el tráfico en segundo plano.\n\n¿Por qué desactivarlo?\n\n• Consume datos móviles (incluso aparcado)\n• Usa CPU y batería en segundo plano\n• No hace falta si usas otra app de navegación\n• Puede interferir con el uso de red de la dashcam\n\nDesactivarlo es seguro: solo afecta a la capa de tráfico integrada del mapa. La navegación, el Bluetooth y el resto de funciones del coche no se ven afectadas.\n\nDespués de desactivarlo hace falta un reinicio forzado (mantén pulsado el botón de la consola central 5 segundos).';

  @override
  String get dialog_traffic_enable_title =>
      '¿Rehabilitar el monitor de tráfico BYD?';

  @override
  String get dialog_traffic_enable_message =>
      'El monitor de tráfico BYD está actualmente desactivado.\n\nReactivarlo restablecerá la superposición de tráfico integrada en el mapa de navegación. Tenga en cuenta que se ejecutará en segundo plano y consumirá datos móviles.\n\nSe requiere un reinicio duro después de activarlo (mantenga el botón de la consola central 5 segundos).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Monitor de tráfico $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'Se ha aplicado el cambio.\n\nHaz ahora un reinicio forzado:\nMantén pulsado el botón de la consola central 5 segundos.';

  @override
  String get traffic_monitor_loading => 'Monitor de tráfico: Verificación...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Monitor de tráfico (tipo para comprobar)';

  @override
  String get reset_label_trips => 'Viajes';

  @override
  String get reset_label_soc_history => 'Historial de la SoC + 12V';

  @override
  String get reset_label_recordings => 'Grabaciones';

  @override
  String get reset_label_sentry_events => 'Eventos de vigilancia';

  @override
  String get reset_label_proximity => 'Registros de proximidad';

  @override
  String get reset_label_trip_files => 'Archivos de telemetría de viaje';

  @override
  String get toast_access_code_copied => 'Código de acceso copiado';

  @override
  String get dialog_regenerate_token_title => 'Regenerar token';

  @override
  String get dialog_regenerate_token_message =>
      'Esto invalidará el token actual. Se cerrarán todas las sesiones activas. ¿Continuar?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Nuevo token generado. Se cerraron todas las sesiones.';

  @override
  String get toast_token_regenerated_restart =>
      'Token regenerado. Es posible que los servicios necesiten reiniciarse para aplicarlo.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token regenerado. No se pudo notificar al servicio en segundo plano.';

  @override
  String get toast_token_regenerated => 'El token regenerado';

  @override
  String get dashboard_no_tunnel => 'No hay túnel corriendo';

  @override
  String get dashboard_starting_tor => 'Iniciando el túnel Tor…';

  @override
  String get dashboard_waiting_url => 'Esperando el túnel URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 en ejecución';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'Código de acceso';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'No se necesita ninguna configuración para $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'El token no puede estar vacío';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Trae el registro $arg1...';
  }

  @override
  String get toast_log_empty_or_missing =>
      'El archivo de registro está vacío o no se encuentra';

  @override
  String get toast_log_empty => 'El archivo de registro está vacío';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'No logró guardar el registro: $arg1';
  }

  @override
  String get toast_log_not_found =>
      'Archivo de registro no encontrado o ilegible';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return 'Registro de $arg1 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Compartir $arg1 Registro';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== $arg1 Registro ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Fuente: $arg1';
  }

  @override
  String log_header_exported(Object arg1) {
    return 'Exportado: $arg1';
  }

  @override
  String log_header_truncated(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'NOTA: registro truncado a las últimas 10000 líneas (total: $arg1 líneas)',
      one:
          'NOTA: registro truncado a las últimas 10000 líneas (total: $arg1 línea)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'No puedo reproducir video: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Eliminar la grabación';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return '¿Eliminar $arg1?\nEsta acción no se puede deshacer.';
  }

  @override
  String get toast_recording_deleted => 'Se suprimió la grabación';

  @override
  String get toast_recording_delete_failed =>
      'No se pudo eliminar la grabación';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 eliminado, $arg2 fallido';
  }

  @override
  String get play_with_chooser => 'Juega con';

  @override
  String setup_version_banner(Object arg1) {
    return 'Actualizado a v$arg1 — Re-confirmar auto arranque, BYD se borra en cada instalación';
  }

  @override
  String get setup_overlay_already_granted => 'Ya otorgado';

  @override
  String camera_current_manual(Object arg1) {
    return 'Corriente: cámara $arg1 (Manual)';
  }

  @override
  String get camera_current_auto_label => 'Actual: Automático';

  @override
  String get soh_estimation_active => 'Actividad de estimación';

  @override
  String get soh_oem_readout =>
      'Lectura de SOH del vehículo — esperando la estimación calculada';

  @override
  String get soh_nominal_baseline =>
      'Base nominal — esperando datos de SOH fiables';

  @override
  String get soh_no_estimate_yet =>
      'No hay estimación todavía — espera de datos';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 seleccionado';
  }

  @override
  String get video_player_playback_error => 'Erro de reproducción';

  @override
  String get video_player_no_events => 'No hay eventos';

  @override
  String get daemon_configuration_required => 'Configuración requerida';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Reproductor de vídeo';

  @override
  String get status_overlay_notif_title => 'BladeWatch Estado';

  @override
  String get status_overlay_notif_text => 'Superposición de estado activa';

  @override
  String get rail_dashboard => 'Panel';

  @override
  String get rail_live => 'En vivo';

  @override
  String get rail_recordings => 'Grabaciones';

  @override
  String get rail_vehicle => 'Vehículo';

  @override
  String get rail_trips => 'Viajes';

  @override
  String get rail_location => 'Ubicación';

  @override
  String get rail_diagnostics => 'Diagnósticos';

  @override
  String get rail_settings => 'Ajustes';

  @override
  String get settings_section_appearance => 'Apariencia';

  @override
  String get settings_section_recording => 'Grabación';

  @override
  String get settings_section_surveillance => 'Vigilancia';

  @override
  String get settings_section_daemons => 'Servicios';

  @override
  String get settings_section_privacy => 'Privacidad y datos';

  @override
  String get settings_section_trips => 'Viajes';

  @override
  String get settings_section_trips_subtitle =>
      'Tarifas de coste, unidad de distancia y dónde se guardan los viajes';

  @override
  String get settings_section_overlay => 'Superposición de estado';

  @override
  String get settings_overlay_subtitle =>
      'Elige qué segmentos de la píldora de estado flotante permanecen visibles.';

  @override
  String get settings_overlay_camera_title => 'Indicador de cámara';

  @override
  String get settings_overlay_camera_subtitle =>
      'Muestre la insignia REC / PROX mientras la grabación esté activa.';

  @override
  String get settings_overlay_trip_title => 'Indicación de Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Muestre la insignia TRIP mientras se está ejecutando la detección de viajes.';

  @override
  String get settings_section_about => 'Acerca de';

  @override
  String get settings_subrail_overline => 'SETIMENTADES';

  @override
  String get cd_settings_subrail => 'Barra lateral de ajustes';

  @override
  String get settings_privacy_title => 'Privacidad y datos';

  @override
  String get settings_privacy_body =>
      'El restablecimiento elimina el índice de grabaciones, credenciales almacenadas en caché, estado del servicio y preferencias en el dispositivo. Esta acción no se puede deshacer.';

  @override
  String get settings_about_title => 'Sobre BladeWatch';

  @override
  String get settings_about_version_label => 'Versión';

  @override
  String get settings_about_package_label => 'Construir';

  @override
  String get settings_about_support_section => 'Alimentado por gente como tú';

  @override
  String get settings_about_support_share_title =>
      'Cuéntaselo a otro propietario';

  @override
  String get settings_about_support_share_value =>
      'Cada enlace compartido ayuda a otro propietario de BYD a descubrir BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Consulte BladeWatch — vigilancia de código abierto y dashcam para BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser => 'Compartir el exceso';

  @override
  String get settings_about_open_link_failed => 'No pude abrir el enlace.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'No se ha encontrado ningún navegador. URL copiado: $arg1';
  }

  @override
  String get settings_about_support_kofi_title =>
      'Combustible para el próximo lanzamiento';

  @override
  String get settings_about_support_kofi_value =>
      'Un café en Ko-Fi mantiene los compromisos nocturnos.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Licencia';

  @override
  String get settings_about_license_value =>
      'MIT — código abierto. Toque para ver el texto completo.';

  @override
  String get settings_about_source_title => 'Código fuente';

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
  String get settings_about_star_title => 'Deja un en GitHub';

  @override
  String get settings_about_star_value => 'Toma un segundo, significa mucho.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Gracias';

  @override
  String get settings_about_thanks_subtitle =>
      'Construido con la ayuda de colaboradores y patrocinadores.';

  @override
  String get settings_about_contributors_title => 'Colaboradores';

  @override
  String get settings_about_supporters_title => 'Patrocinadores';

  @override
  String get settings_about_thanks_empty =>
      'La lista se completa a medida que la gente colabora.';

  @override
  String get settings_theme_label => 'Temática';

  @override
  String get settings_theme_auto => 'Automático (seguir el sistema)';

  @override
  String get settings_theme_light => 'Claro';

  @override
  String get settings_theme_dark => 'Oscuro';

  @override
  String get settings_language_label => 'Lenguaje';

  @override
  String get settings_drive_side_label => 'Lado de navegación';

  @override
  String get settings_drive_side_subtitle =>
      'Elija en qué lado de la pantalla aparece el menú de navegación.';

  @override
  String get settings_drive_side_left => 'Izquierda';

  @override
  String get settings_drive_side_left_hint => 'LHD · predeterminado';

  @override
  String get settings_drive_side_right => 'Derecha';

  @override
  String get settings_drive_side_right_hint => 'Vehículos RHD';

  @override
  String get settings_drive_side_auto => 'Automático';

  @override
  String get settings_drive_side_auto_hint => 'Detectar del vehículo';

  @override
  String get settings_drive_side_caption_left => 'Navegación a la izquierda';

  @override
  String get settings_drive_side_caption_right => 'Navegación a la derecha';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Auto — el vehículo indica volante a la izquierda';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Auto — el vehículo indica volante a la derecha';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Auto — vehículo no disponible, usando izquierda';

  @override
  String get recordings_title => 'Grabaciones';

  @override
  String get recordings_segment_dashcam => 'Dashcam';

  @override
  String get recordings_segment_surveillance => 'Vigilancia';

  @override
  String get recordings_action_settings => 'Ajustes';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 hoy · $arg2 total · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashcam · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Supervisión · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Seleccione una grabación';

  @override
  String get recordings_preview_placeholder_body =>
      'Toca cualquier elemento de la izquierda para reproducirlo.';

  @override
  String get diagnostics_section_adb_console => 'Consola ADB';

  @override
  String get diagnostics_section_traffic => 'Monitor de tráfico';

  @override
  String get diagnostics_section_camera_probe => 'Sondeo de cámara';

  @override
  String get diagnostics_section_battery => 'Salud de la batería';

  @override
  String get diagnostics_section_performance => 'Rendimiento';

  @override
  String get diagnostics_hero_title => 'Diagnóstico del sistema';

  @override
  String get diagnostics_hero_subtitle =>
      'Salud en vivo, registros y sondas para el dispositivo.';

  @override
  String get diagnostics_health_clear => 'Todo correcto';

  @override
  String get diagnostics_health_section => 'Estado';

  @override
  String get diagnostics_health_network => 'Red';

  @override
  String get diagnostics_health_storage => 'Almacenamiento';

  @override
  String get diagnostics_health_camera => 'La cámara';

  @override
  String get diagnostics_health_battery => 'Batería';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'En línea';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Túnel · $arg1';
  }

  @override
  String diagnostics_network_data_usage_line(Object arg1) {
    return '$arg1 este mes';
  }

  @override
  String get diagnostics_tunnel_state_online => 'En línea';

  @override
  String get diagnostics_tunnel_state_offline => 'Sin conexión';

  @override
  String get diagnostics_tunnel_state_connecting => 'Conexión';

  @override
  String get diagnostics_network_mobile => 'Datos móviles';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Sin conexión';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clips · $arg2 utilizados',
      one: '$arg1 clip · $arg2 utilizados',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 libre';
  }

  @override
  String get diagnostics_logs_card_title => 'Registro de eventos en vivo';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Transmisiones de salida de los servicios en ejecución.';

  @override
  String get diagnostics_tools_section => 'Herramientas';

  @override
  String get diagnostics_traffic_subtitle =>
      'Mira el rendimiento de la red en vivo.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Inspeccione las cámaras conectadas.';

  @override
  String get diagnostics_adb_subtitle => 'Abre el terminal en el dispositivo.';

  @override
  String get diagnostics_battery_subtitle =>
      'Inspeccione la célula SOH y empaque las estadísticas.';

  @override
  String get diagnostics_settings_subtitle =>
      'Las preferencias de la aplicación, el tema y el idioma.';

  @override
  String get settings_action_reset_data => 'Restablecer datos…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'En vigilancia';

  @override
  String get dashboard_subtitle_all_systems => 'Todos los sistemas en línea';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 de los servicios $arg2 en línea';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Acceso remoto fuera de línea';

  @override
  String get dashboard_metric_recordings => 'Las grabaciones de hoy';

  @override
  String get dashboard_metric_storage => 'Almacenamiento utilizado';

  @override
  String get dashboard_metric_tunnel => 'Acceso remoto';

  @override
  String get dashboard_metric_services => 'Servicios en segundo plano';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Vehículo';

  @override
  String get dashboard_chip_recording_active => 'Grabando';

  @override
  String get dashboard_chip_recording_idle => 'Inactivo';

  @override
  String get dashboard_vehicle_tap_to_set => 'Toca para establecer';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Establecer la capacidad de la batería';

  @override
  String get vehicle_dialog_model_label => 'Modelo';

  @override
  String get vehicle_dialog_save => 'Guardar';

  @override
  String get settings_recording_tab_status => 'Estado';

  @override
  String get settings_recording_tab_capture => 'Captura';

  @override
  String get settings_recording_tab_quality => 'Calidad';

  @override
  String get settings_recording_tab_storage => 'Almacenamiento';

  @override
  String get settings_recording_status_title => 'Estado de grabación';

  @override
  String get settings_recording_status_current_state => 'Estado actual';

  @override
  String get settings_recording_status_today_count => 'Grabaciones de hoy';

  @override
  String get settings_recording_mode_title =>
      'Modo de grabación (con contacto)';

  @override
  String get settings_recording_mode_description =>
      'Elige cuándo debe grabar la dashcam mientras conduces.';

  @override
  String get settings_recording_mode_none_label => 'Ninguno (predeterminado)';

  @override
  String get settings_recording_mode_none_desc =>
      'Sin grabación — la vigilancia sigue funcionando';

  @override
  String get settings_recording_mode_continuous_label => 'Continuo';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Grabar todo el tiempo mientras conduces';

  @override
  String get settings_recording_mode_drive_label => 'Modo conducción';

  @override
  String get settings_recording_mode_drive_desc =>
      'Grabar solo cuando el vehículo esté en movimiento';

  @override
  String get settings_recording_mode_proximity_label => 'Guardia de proximidad';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Grabar cuando se detecte movimiento';

  @override
  String get settings_recording_limit_title => 'Límite de grabación';

  @override
  String get settings_recording_limit_description =>
      'Duración máxima por archivo. Las grabaciones se dividen en archivos nuevos en este intervalo.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_priority_title => 'Prioridad de grabación';

  @override
  String get settings_recording_priority_description =>
      'Cómo gestiona la grabación un corte de energía repentino.';

  @override
  String get settings_recording_priority_performance_label => 'Rendimiento';

  @override
  String get settings_recording_priority_performance_desc =>
      'Usa menos CPU. Si se corta la energía de forma abrupta, el segmento de grabación actual (hasta su Límite de grabación) puede perderse.';

  @override
  String get settings_recording_priority_reliability_label => 'Fiabilidad';

  @override
  String get settings_recording_priority_reliability_desc =>
      'Usa un poco más de CPU para guardar con más frecuencia. Si se corta la energía de forma abrupta, se puede perder como máximo un minuto aproximadamente.';

  @override
  String get settings_recording_overlay_fields_title =>
      'Campos de superposición';

  @override
  String get settings_recording_overlay_fields_description =>
      'Elige qué aparece en la superposición grabada en las grabaciones continuas.';

  @override
  String get settings_recording_overlay_field_speed => 'Velocidad';

  @override
  String get settings_recording_overlay_field_gear => 'Marcha';

  @override
  String get settings_recording_overlay_field_turn_signal_left =>
      'Intermitente izquierdo';

  @override
  String get settings_recording_overlay_field_turn_signal_right =>
      'Intermitente derecho';

  @override
  String get settings_recording_overlay_field_brake_pedal => 'Pedal de freno';

  @override
  String get settings_recording_overlay_field_accel_pedal =>
      'Pedal del acelerador';

  @override
  String get settings_recording_overlay_field_seatbelt_driver =>
      'Cinturón del conductor';

  @override
  String get settings_recording_overlay_field_seatbelt_passenger =>
      'Cinturón del pasajero';

  @override
  String get settings_recording_overlay_field_timestamp => 'Fecha y hora';

  @override
  String get settings_recording_quality_title => 'Calidad de grabación';

  @override
  String get settings_recording_storage_title =>
      'Almacenamiento de grabaciones';

  @override
  String get settings_recording_storage_confirm_title =>
      '¿Eliminar grabaciones?';

  @override
  String settings_recording_storage_confirm_message(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Esto eliminará $arg1 grabaciones ($arg2).',
      one: 'Esto eliminará $arg1 grabación ($arg2).',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_confirm_unknown_title =>
      'Impacto desconocido';

  @override
  String get settings_recording_storage_confirm_unknown_message =>
      'No se pudo determinar qué eliminaría este cambio. Reducir el límite puede eliminar grabaciones existentes.';

  @override
  String get settings_recording_storage_location_label =>
      'Ubicación de almacenamiento';

  @override
  String get settings_recording_storage_internal => 'Interno';

  @override
  String get settings_recording_storage_sd_card => 'Tarjeta SD';

  @override
  String get settings_recording_storage_sd_card_na => 'Tarjeta SD (N/D)';

  @override
  String get settings_recording_storage_sd_mount_failed_title =>
      'La tarjeta SD no se montó';

  @override
  String get settings_recording_storage_limit_label =>
      'Límite de almacenamiento — elimina lo más antiguo al alcanzarlo';

  @override
  String get settings_recording_storage_usage_label => 'Uso de almacenamiento';

  @override
  String get settings_recording_storage_files_label => 'Archivos';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usados / límite $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 grabaciones',
      one: '$arg1 grabación',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Ruta';

  @override
  String get settings_recording_storage_sd_free_label => 'Espacio libre en SD';

  @override
  String get settings_recording_storage_internal_free_label =>
      'Espacio interno libre';

  @override
  String get settings_recording_format_title => 'Formatear unidad externa';

  @override
  String get settings_recording_format_warning =>
      'Borra permanentemente TODOS los datos de la tarjeta SD o unidad USB.';

  @override
  String get settings_recording_format_confirm =>
      'Toca de nuevo — se BORRARÁN todos los datos';

  @override
  String get settings_recording_format_running => 'Formateando… espera';

  @override
  String get settings_recording_format_button => 'Formatear tarjeta SD/USB';

  @override
  String get settings_recording_format_no_drive =>
      'No se encontró ninguna unidad extraíble';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Formateado correctamente. Nueva ruta: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Catálogo de la base de datos';

  @override
  String get settings_recording_sync_description =>
      'Concilia el índice de grabaciones con los archivos del disco.';

  @override
  String get settings_recording_sync_running => 'Sincronizando…';

  @override
  String get settings_recording_sync_button => 'Sincronizar base de datos';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Sincronizado: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress =>
      'Ya hay una sincronización en curso';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Error de sincronización: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Aplicar cambios';

  @override
  String get settings_recording_dismiss => 'Descartar';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Iniciar/detener $arg1 aún no es compatible';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 utilizado · $arg2 libre';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Almacenamiento —';

  @override
  String get dashboard_tunnel_offline => 'Sin conexión';

  @override
  String get dashboard_tunnel_online => 'En línea';

  @override
  String get dashboard_tunnel_connecting => 'Conectando...';

  @override
  String get dashboard_trips_this_week => 'Esta semana';

  @override
  String dashboard_trips_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 viajes',
      one: '$arg1 viaje',
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
  String get dashboard_trips_label_trips => 'Viajes';

  @override
  String get dashboard_trips_label_distance => 'Distancia';

  @override
  String get dashboard_trips_label_time => 'Tiempo de conducción';

  @override
  String get dashboard_trips_no_data => 'No hay viajes registrados esta semana';

  @override
  String get dashboard_trips_unavailable =>
      'Empiece a conducir para ver estadísticas';

  @override
  String get dashboard_trips_loading => 'Cargando…';

  @override
  String get dashboard_trips_view_all => 'Ver todos los viajes';

  @override
  String get dashboard_action_live => 'Vista en vivo';

  @override
  String get dashboard_action_live_subtitle => 'Abrir la vista de cámara';

  @override
  String get dashboard_action_recordings => 'Grabaciones';

  @override
  String get dashboard_action_settings => 'Ajustes';

  @override
  String get dashboard_action_settings_subtitle => 'Las preferencias y sobre';

  @override
  String get settings_hero_title => 'Ajustes';

  @override
  String get settings_hero_overline => 'Sobreviviendo';

  @override
  String get settings_hero_subtitle =>
      'Ajuste la apariencia, la grabación, la vigilancia y los datos en el dispositivo.';

  @override
  String get settings_overline_preferences => 'Preferencias';

  @override
  String get settings_overline_about_data => 'Sobre y datos';

  @override
  String get settings_quick_theme_label => 'Temática';

  @override
  String get settings_quick_language_label => 'Lenguaje';

  @override
  String get settings_section_recording_subtitle =>
      'Buffers pre/post, codec, límites de almacenamiento.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Horario, sensibilidad al movimiento, detección de objetos.';

  @override
  String get settings_section_daemons_subtitle =>
      'Túnel Tor y servicios en segundo plano.';

  @override
  String get settings_about_row_title => 'Sobre BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Versión, licencia, desarrollo de soporte.';

  @override
  String get settings_reset_row_subtitle =>
      'Grabaciones claras, eventos, o todos los cachés.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Temas, lenguaje y preferencias visuales.';

  @override
  String get settings_theme_active_auto_caption =>
      'Auto sigue su tema del sistema.';

  @override
  String get settings_theme_active_light_caption =>
      'El tema claro está siempre activo.';

  @override
  String get settings_theme_active_dark_caption =>
      'El tema oscuro está siempre activo.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 de $arg2 idiomas disponibles';
  }

  @override
  String get settings_language_card_title => 'Lenguaje de visualización';

  @override
  String get settings_privacy_stance_title => 'En el dispositivo por defecto';

  @override
  String get settings_privacy_stance_body =>
      'BladeWatch funciona completamente en la unidad principal. No sale telemetría de su coche excepto a través de los túneles e integraciones que usted configure explícitamente.';

  @override
  String get settings_privacy_overline_storage => 'Almacenamiento local';

  @override
  String get settings_privacy_overline_reset => 'Reset de datos';

  @override
  String get settings_privacy_storage_clips_label => 'Clips en el disco';

  @override
  String get settings_privacy_storage_size_label => 'Tamaño total';

  @override
  String get settings_privacy_storage_unavailable => 'No está disponible';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clips',
      one: '$arg1 clip',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Elige categorías: grabaciones, eventos, configuraciones de servicio, telemetría almacenada en caché...';

  @override
  String get settings_developer_overline => 'DESARROLLADOR';

  @override
  String get settings_developer_timing_logs_title =>
      'Registros de tiempo del servicio';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Registra marcas de tiempo transcurrido durante el inicio del servicio. Desactívelo en uso normal para mantener logcat limpio.';

  @override
  String get settings_developer_debug_logs_title =>
      'Registros de depuración para desarrolladores';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Registra todos los eventos del ciclo de vida de Activity y Fragment y los pasos de inicio en /storage/emulated/0/BladeWatch/data/debug_app.log. Los fallos siempre se capturan. Desactivado por defecto.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Cámara $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Cámara $arg1 (manual)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Comprobando…';

  @override
  String get diagnostics_camera_value_offline => 'Sin conexión';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Datos pendientes';

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
      other: '$arg1 clips · $arg2 grabados',
      one: '$arg1 clip · $arg2 grabados',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Maletero';

  @override
  String get vehicle_tab_climate => 'Climatización';

  @override
  String get vehicle_tab_seats => 'Asientos';

  @override
  String get vehicle_tab_windows => 'Ventanas';

  @override
  String get vehicle_tab_lights => 'Luces';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Carga';

  @override
  String get vehicle_locked => 'Cerrado con llave';

  @override
  String get vehicle_unlocked => 'Desbloqueado';

  @override
  String get vehicle_range_label => 'Autonomía';

  @override
  String get vehicle_data_unavailable => 'Datos del vehículo no disponibles.';

  @override
  String get vehicle_action_failed =>
      'Acción fallida. Compruebe la conexión del vehículo.';

  @override
  String get vehicle_open_trunk => 'Abrir maletero';

  @override
  String get vehicle_close_trunk => 'Cerrar maletero';

  @override
  String get vehicle_trunk_info_open =>
      'Abrir el maletero desbloqueará primero el coche.';

  @override
  String get vehicle_ac_on => 'AC encendido';

  @override
  String get vehicle_ac_off => 'AC apagado';

  @override
  String get vehicle_max_cooling_on => 'Refrigeración máx.: ON';

  @override
  String get vehicle_max_cooling_off => 'Refrigeración máx.: OFF';

  @override
  String get vehicle_screen_on => 'Pantalla: ENCENDIDA';

  @override
  String get vehicle_screen_off => 'Pantalla: APAGADA';

  @override
  String get vehicle_media_volume_label => 'Volumen multimedia';

  @override
  String get vehicle_media_mute => 'Silenciar';

  @override
  String get vehicle_media_muted => 'Silenciado';

  @override
  String get vehicle_front_defrost => 'Desempañador delantero';

  @override
  String get vehicle_rear_defrost => 'Desempañador trasero';

  @override
  String get vehicle_temp_label => 'Temperatura';

  @override
  String get vehicle_fan_speed_label => 'Velocidad del ventilador';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Nivel $arg1';
  }

  @override
  String vehicle_inside_temp_fmt(Object arg1) {
    return 'Interior: $arg1°C';
  }

  @override
  String get vehicle_seat_driver => 'Conductor';

  @override
  String get vehicle_seat_passenger => 'Pasajero';

  @override
  String get vehicle_seat_no_controls =>
      'No hay controles de asiento disponibles para este vehículo.';

  @override
  String vehicle_seat_heat_label(Object arg1) {
    return 'Calor $arg1';
  }

  @override
  String vehicle_seat_cool_label(Object arg1) {
    return 'Frío $arg1';
  }

  @override
  String get vehicle_heat_off => '(Apagado)';

  @override
  String get vehicle_heat_low => '(Bajo)';

  @override
  String get vehicle_heat_high => '(Alto)';

  @override
  String get vehicle_seat_pos_1 => 'Posición 1';

  @override
  String get vehicle_seat_pos_2 => 'Posición 2';

  @override
  String get vehicle_all_windows => 'Todas las ventanas';

  @override
  String get vehicle_window_awake_note =>
      'Solo funciona con el coche despierto.';

  @override
  String get vehicle_window_front_left => 'Delantera izquierda';

  @override
  String get vehicle_window_front_right => 'Delantera derecha';

  @override
  String get vehicle_window_rear_left => 'Trasera izquierda';

  @override
  String get vehicle_window_rear_right => 'Trasera derecha';

  @override
  String get vehicle_window_close => 'Cerrar';

  @override
  String get vehicle_window_close_vent => 'Cerrar ventilación';

  @override
  String get vehicle_window_vent_12 => 'Ventilación 12%';

  @override
  String get vehicle_window_open_all => 'Abrir todas';

  @override
  String get vehicle_sunroof => 'Techo solar';

  @override
  String get vehicle_sunshade => 'Cortinilla';

  @override
  String get vehicle_btn_drl_title =>
      'Lámparas de funcionamiento durante el día';

  @override
  String get vehicle_btn_slw_title => 'Advertencia de límite de velocidad';

  @override
  String get vehicle_control_section_charge_cap => 'Límite de carga';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Este vehículo no admite el límite de carga.';

  @override
  String get vehicle_charge_limit_label => 'Límite de carga';

  @override
  String get vehicle_enable_charge_limit => 'Activar límite de carga';

  @override
  String get vehicle_charge_limit_range => 'Mínimo 50%, máximo 100%';

  @override
  String get vehicle_tyre_no_signal => 'SIN SEÑAL';

  @override
  String get vehicle_tyre_slow_leak => 'FUGA LENTA';

  @override
  String get vehicle_tyre_fast_leak => 'FUGA RÁPIDA';

  @override
  String get vehicle_tyre_low => 'BAJA';

  @override
  String get vehicle_tyre_high => 'ALTA';

  @override
  String get vehicle_tyre_ok => 'OK';

  @override
  String get vehicle_tyre_check_pressure => 'Comprobar presión';

  @override
  String get vehicle_toggle_on => 'ENCENDIDO';

  @override
  String get vehicle_toggle_off => 'APAGADO';

  @override
  String get vehicle_err_climate_control => 'Falló el control de clima.';

  @override
  String get vehicle_err_max_cooling => 'Falló la refrigeración máxima.';

  @override
  String get vehicle_err_drl_control => 'Falló el control de luces diurnas.';

  @override
  String get vehicle_err_slw_control => 'Falló el control ADAS.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Falló el cambio del límite de carga.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Reducir $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Aumentar $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Conectando…';

  @override
  String get vehicle_appearance_model_title => 'Seleccionar modelo';

  @override
  String get vehicle_appearance_custom_color => 'Color personalizado';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Carga: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Autonomía: $arg1 km';
  }

  @override
  String vehicle_status_fuel_fmt(Object arg1) {
    return 'Combustible: $arg1%';
  }

  @override
  String vehicle_status_fuel_range_fmt(Object arg1) {
    return 'Autonomía de combustible: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Carga: —';

  @override
  String get vehicle_status_range_unknown => 'Autonomía: —';

  @override
  String get startup_subtitle => 'Preparando su dashcam';

  @override
  String get startup_header_preparing => 'Preparando todo…';

  @override
  String get startup_header_starting => 'Iniciando…';

  @override
  String get startup_header_verifying => 'Casi listo…';

  @override
  String get startup_header_ready => 'Todo listo';

  @override
  String get startup_daemon_camera => 'Cámara';

  @override
  String get startup_daemon_camera_desc => 'Vista en vivo y grabación';

  @override
  String get startup_daemon_sentry => 'Modo Centinela';

  @override
  String get startup_daemon_sentry_desc => 'Detección de movimiento y alertas';

  @override
  String get startup_daemon_parking => 'Guardia de aparcamiento';

  @override
  String get startup_daemon_parking_desc => 'Vigila mientras está aparcado';

  @override
  String get startup_status_waiting => 'En espera';

  @override
  String get startup_status_starting => 'Iniciando';

  @override
  String get startup_status_ready => 'Listo';

  @override
  String get startup_status_failed => 'Falló';

  @override
  String get startup_continue_anyway => 'Continuar de todos modos';

  @override
  String get startup_continue => 'Continuar →';

  @override
  String get live_retry => 'Reintentar';

  @override
  String get live_connecting => 'Conectando con la cámara…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Error: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Cámara no disponible\n$arg1';
  }

  @override
  String get live_direction_all => 'Todas';

  @override
  String get live_direction_front => 'Delantera';

  @override
  String get live_direction_right => 'Derecha';

  @override
  String get live_direction_rear => 'Trasera';

  @override
  String get live_direction_left => 'Izquierda';

  @override
  String get trip_no_route_data => 'No hay datos de ruta para este viaje';

  @override
  String get trips_tab_trips => 'Viajes';

  @override
  String get trips_tab_stats => 'Estadísticas';

  @override
  String get trips_tab_storage => 'Almacenamiento';

  @override
  String get trips_filter_7_days => '7 días';

  @override
  String get trips_filter_14_days => '14 días';

  @override
  String get trips_filter_30_days => '30 días';

  @override
  String trips_load_error(Object message) {
    return 'Error: $message';
  }

  @override
  String get trips_empty_state => 'Aún no se han registrado viajes';

  @override
  String get trips_period_summary_title => 'Resumen del período';

  @override
  String get trips_stat_trips => 'Viajes';

  @override
  String get trips_stat_hours => 'Horas';

  @override
  String get trips_stat_efficiency => 'Eficiencia';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Puntuación: $score';
  }

  @override
  String get trips_driver_score_title => 'Puntuación del conductor';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Total: $score / 100';
  }

  @override
  String get trips_range_title => 'Autonomía personalizada';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'Estimación de BYD: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'Autonomía de combustible: $km';
  }

  @override
  String get trips_range_no_data => 'Aún no hay suficientes datos';

  @override
  String get trips_dna_title => 'ADN de conducción';

  @override
  String get trips_dna_anticipation => 'Anticipación';

  @override
  String get trips_dna_smoothness => 'Suavidad';

  @override
  String get trips_dna_speed_discipline => 'Disciplina de velocidad';

  @override
  String get trips_dna_efficiency => 'Eficiencia';

  @override
  String get trips_dna_consistency => 'Consistencia';

  @override
  String get trips_storage_title => 'Almacenamiento de viajes';

  @override
  String get trips_storage_analytics_label => 'Analítica de viajes';

  @override
  String get trips_storage_rate_label => 'Tarifa eléctrica';

  @override
  String get trips_storage_fuel_price_label =>
      'Precio del combustible (por litro)';

  @override
  String get trips_storage_tank_capacity_label =>
      'Capacidad del depósito (litros)';

  @override
  String get trips_storage_distance_unit_label => 'Unidad de distancia';

  @override
  String get trips_storage_location_label => 'Ubicación de almacenamiento';

  @override
  String get trips_storage_internal => 'Interno';

  @override
  String get trips_storage_sd_card => 'Tarjeta SD';

  @override
  String get trips_storage_sd_card_unavailable => 'Tarjeta SD (N/D)';

  @override
  String get trips_storage_apply => 'Aplicar cambios';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit usados / límite $limit MB · $count viajes';
  }

  @override
  String get trips_sync_title => 'Catálogo de la base de datos';

  @override
  String get trips_sync_description =>
      'Concilia el índice de viajes con los archivos de telemetría del disco.';

  @override
  String get trips_sync_button => 'Sincronizar base de datos';

  @override
  String get trips_sync_running => 'Sincronizando…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Sincronizado correctamente: +$added -$removed ($total en total)';
  }

  @override
  String get trips_sync_failed_generic => 'Error al sincronizar';

  @override
  String get trips_detail_summary_title => 'Resumen del viaje';

  @override
  String get trips_detail_distance => 'Distancia';

  @override
  String get trips_detail_duration => 'Duración';

  @override
  String get trips_detail_energy => 'Energía';

  @override
  String get trips_detail_avg_speed => 'Vel. media';

  @override
  String get trips_detail_max_speed => 'Vel. máx.';

  @override
  String get trips_detail_soc => 'Carga';

  @override
  String get trips_detail_cost => 'Coste';

  @override
  String get trips_detail_ext_temp => 'Temp. exterior';

  @override
  String get trips_detail_fuel_used => 'Combustible';

  @override
  String get trips_detail_fuel_cost => 'Coste de combustible';

  @override
  String get trips_detail_electric_cost => 'Coste de electricidad';

  @override
  String get trips_detail_elev_gain => 'Desnivel pos.';

  @override
  String get trips_detail_scores_title => 'Puntuaciones de conducción';

  @override
  String get trips_detail_unavailable => 'Detalles del viaje no disponibles';

  @override
  String get trips_detail_loading => 'Cargando viaje…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count puntos GPS registrados';
  }

  @override
  String get rec_severity_critical => 'CRÍTICO';

  @override
  String get rec_severity_alert => 'ALERTA';

  @override
  String get location_loading_title => 'Cargando mapa';

  @override
  String get location_permission_missing_title =>
      'Se requiere permiso de ubicación';

  @override
  String get location_permission_denied_title => 'Permiso denegado';

  @override
  String get location_provider_disabled_title => 'GPS desactivado';

  @override
  String get location_waiting_for_fix_title => 'Esperando señal GPS';

  @override
  String get location_car_location_title => 'Ubicación del vehículo';

  @override
  String get location_stale_title => 'Ubicación obsoleta';

  @override
  String get location_tile_failure_title => 'Mapa no disponible';

  @override
  String get location_tile_failure_subtitle => 'Red no disponible';

  @override
  String get location_error_title => 'Error de ubicación';

  @override
  String get location_action_grant => 'Conceder';

  @override
  String get location_action_retry => 'Reintentar';

  @override
  String get location_mode_auto => 'Automático';

  @override
  String get location_mode_light => 'Claro';

  @override
  String get location_mode_dark => 'Oscuro';

  @override
  String get cd_recenter_on_car => 'Centrar en el vehículo';

  @override
  String get recording_lib_no_recordings_normal => 'Sin grabaciones normales';

  @override
  String get recording_lib_no_recordings_sentry => 'Sin eventos de vigilancia';

  @override
  String get recording_lib_no_recordings_proximity =>
      'Sin eventos de proximidad';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'persona';

  @override
  String get video_player_legend_car => 'coche';

  @override
  String get video_player_legend_bike => 'bicicleta';

  @override
  String get video_player_legend_motion => 'movimiento';

  @override
  String get recording_lib_proximity_very_close => 'muy cerca';

  @override
  String get recording_lib_proximity_close => 'cerca';

  @override
  String get recording_lib_proximity_mid => 'media';

  @override
  String get recording_lib_proximity_far => 'lejos';

  @override
  String get surveillance_tab_general => 'General';

  @override
  String get surveillance_tab_detection => 'Detección';

  @override
  String get surveillance_tab_recording => 'Grabación';

  @override
  String get surveillance_tab_storage => 'Almacenamiento';

  @override
  String get surveillance_tab_advanced => 'Avanzado';

  @override
  String get surveillance_general_title => 'Modo de vigilancia';

  @override
  String get surveillance_general_enable => 'Activar vigilancia';

  @override
  String get surveillance_general_status => 'Estado';

  @override
  String get surveillance_general_status_running => 'En ejecución';

  @override
  String get surveillance_general_status_idle => 'Inactivo';

  @override
  String get surveillance_general_events_today => 'Eventos hoy';

  @override
  String get surveillance_safe_locations_title => 'Ubicaciones seguras';

  @override
  String get surveillance_safe_locations_subtitle =>
      'La cámara no se iniciará al estacionar aquí';

  @override
  String get surveillance_safe_locations_enable =>
      'Desactivar en ubicaciones seguras';

  @override
  String get surveillance_safe_locations_empty =>
      'Aún no se han añadido ubicaciones seguras';

  @override
  String get surveillance_safe_locations_add_current =>
      'Añadir ubicación actual como zona segura';

  @override
  String get surveillance_safe_locations_no_gps =>
      'Ubicación GPS no disponible';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Ajustes de detección';

  @override
  String get surveillance_detection_preset_label => 'Perfil de entorno';

  @override
  String get surveillance_preset_outdoor => 'Exterior';

  @override
  String get surveillance_preset_garage => 'Garaje';

  @override
  String get surveillance_preset_street => 'Calle';

  @override
  String get surveillance_preset_custom => 'Personalizado';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Sensibilidad (1=estricta, 5=sensible): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Detectar objetos';

  @override
  String get surveillance_detection_object_person => 'persona';

  @override
  String get surveillance_detection_object_car => 'coche';

  @override
  String get surveillance_detection_object_bike => 'bicicleta';

  @override
  String get surveillance_recording_title => 'Grabación de eventos';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Pregrabación (segundos antes del evento): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Posgrabación (segundos después del evento): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Almacenamiento de vigilancia';

  @override
  String get surveillance_storage_location_label =>
      'Ubicación de almacenamiento';

  @override
  String get surveillance_storage_internal => 'Interno';

  @override
  String get surveillance_storage_sd_card => 'Tarjeta SD';

  @override
  String get surveillance_storage_sd_card_na => 'Tarjeta SD (N/D)';

  @override
  String get surveillance_storage_limit_label =>
      'Límite de almacenamiento: elimina lo más antiguo automáticamente';

  @override
  String get surveillance_storage_usage_label => 'Uso de almacenamiento';

  @override
  String get surveillance_storage_files_label => 'Archivos';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usados / límite $arg2';
  }

  @override
  String surveillance_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 eventos',
      one: '$arg1 evento',
    );
    return '$_temp0';
  }

  @override
  String get surveillance_storage_path_label => 'Ruta';

  @override
  String get surveillance_format_title => 'Formatear unidad externa';

  @override
  String get surveillance_format_warning =>
      'Borra permanentemente TODOS los datos de la tarjeta SD o unidad USB.';

  @override
  String get surveillance_format_button => 'Formatear tarjeta SD/USB';

  @override
  String get surveillance_format_confirm =>
      'Toca de nuevo: se BORRARÁN TODOS los datos';

  @override
  String get surveillance_format_running => 'Formateando… espera';

  @override
  String get surveillance_dismiss => 'Descartar';

  @override
  String get surveillance_sync_title => 'Catálogo de la base de datos';

  @override
  String get surveillance_sync_description =>
      'Concilia el índice de vigilancia con los archivos del disco.';

  @override
  String get surveillance_sync_button => 'Sincronizar base de datos';

  @override
  String get surveillance_sync_running => 'Sincronizando…';

  @override
  String get surveillance_advanced_camera_title => 'Selección de cámara';

  @override
  String get surveillance_advanced_camera_front => 'Delantera';

  @override
  String get surveillance_advanced_camera_right => 'Derecha';

  @override
  String get surveillance_advanced_camera_rear => 'Trasera';

  @override
  String get surveillance_advanced_camera_left => 'Izquierda';

  @override
  String get surveillance_advanced_ai_title => 'IA y disuasión';

  @override
  String get surveillance_advanced_ai_detection => 'Detección por IA';

  @override
  String get surveillance_advanced_night_mode => 'Modo nocturno';

  @override
  String get surveillance_advanced_deterrent_label => 'Acción disuasoria';

  @override
  String get surveillance_deterrent_silent => 'Silencioso';

  @override
  String get surveillance_deterrent_horn => 'Bocina';

  @override
  String get surveillance_deterrent_flash => 'Destello';

  @override
  String get surveillance_apply_button => 'Aplicar cambios';

  @override
  String get surveillance_apply_failed => 'Error al guardar';

  @override
  String get dashboard_tor_bootstrapping => 'Conectando a Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'Cómo abrir esta dirección';

  @override
  String get dashboard_tor_help_title => 'Abrir esta dirección';

  @override
  String get dashboard_tor_help_android =>
      'Android: instala Tor Browser desde Google Play o F-Droid, ábrelo y pega la dirección.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone y iPad: instala Onion Browser desde la App Store, ábrelo y pega la dirección. Tor Browser no está disponible en iOS.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS y Linux: descarga Tor Browser desde torproject.org, ábrelo y pega la dirección.';

  @override
  String get dashboard_tor_help_password_note =>
      'Seguirás necesitando la contraseña cuando cargue la página.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'Escanea para ir a la descarga de Tor Browser';

  @override
  String get dashboard_tor_help_close => 'Entendido';

  @override
  String get surveillance_general_battery_warning =>
      'El modo centinela consume energía adicional de la batería de 12V mientras está activo.';

  @override
  String get surveillance_general_camera_contention_warning =>
      'Otra aplicación está usando la cámara en este momento.';
}
