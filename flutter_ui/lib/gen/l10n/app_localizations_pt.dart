// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Mantenha o monitoramento do veículo BladeWatch ativo em segundo plano. Este serviço não lê nem interage com o conteúdo da tela.';

  @override
  String get action_cancel => 'Cancelar';

  @override
  String get action_clear_plain => 'Limpar';

  @override
  String get action_select_all => 'Selecionar todos';

  @override
  String get action_select_all_short => 'Todos';

  @override
  String get action_delete => 'Excluir';

  @override
  String get action_done => 'CONCLUÍDO';

  @override
  String get action_remind_me_later => 'LEMBRAR MAIS TARDE';

  @override
  String get action_retry => 'Tentar novamente';

  @override
  String get action_run => 'Executar';

  @override
  String get action_clear_output => 'Limpar saída';

  @override
  String get cd_camera => 'Câmara';

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
  String get cd_clear_logs => 'Limpar registos';

  @override
  String get cd_expand_collapse => 'Expandir/Recolher';

  @override
  String get cd_recording_status => 'Status de gravação';

  @override
  String get cd_trip_tracking_status => 'Estatuto do rastreamento de viagens';

  @override
  String get cd_video_thumbnail => 'Miniatura de vídeo';

  @override
  String get cd_play => 'Reproduzir';

  @override
  String get cd_back => 'Voltar';

  @override
  String get cd_play_pause => 'Reproduzir/Pausar';

  @override
  String get cd_player_prev => 'Gravação anterior';

  @override
  String get cd_player_next => 'Próxima gravação';

  @override
  String get cd_player_maximize => 'Maximizar player';

  @override
  String get cd_player_minimize => 'Sair da tela cheia';

  @override
  String get cd_delete => 'Excluir';

  @override
  String get cd_decrease => 'Diminuir';

  @override
  String get cd_increase => 'Aumentar';

  @override
  String get cd_expand => 'Expandir';

  @override
  String get cd_configure => 'Configurar';

  @override
  String get cd_download_log => 'Descarregar registo';

  @override
  String get cd_reset => 'Redefinir';

  @override
  String get cd_battery => 'Bateria';

  @override
  String get cd_step_completed => 'Passo concluído';

  @override
  String get cd_permission_granted => 'Permissão concedida';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'PROCESSOS';

  @override
  String get logs_panel_title => 'Registros';

  @override
  String get url_connecting => 'Conectar...';

  @override
  String get camera_selection_title => 'Seleção de câmera';

  @override
  String get camera_selection_subtitle =>
      'Selecione a fonte da câmera panorâmica';

  @override
  String get camera_current_auto => 'Atual: Auto';

  @override
  String get camera_option_auto => 'Automático (detecção no início)';

  @override
  String get camera_option_0 => 'Câmara 0 — Tintas Atto';

  @override
  String get camera_option_1 => 'Câmara 1 — Seal (default)';

  @override
  String get camera_option_2 => 'Câmara 2';

  @override
  String get camera_option_3 => 'Câmara 3';

  @override
  String get camera_option_4 => 'Câmara 4';

  @override
  String get camera_option_5 => 'Câmara 5';

  @override
  String get camera_selection_hint =>
      'Auto seleciona a câmera correta para o seu acabamento a cada inicialização. Câmera 1 = BYD Seal, Câmera 0 = acabamentos Atto. Reinicie o serviço de câmera após alterar o ID da câmera para que a configuração entre em vigor.';

  @override
  String get dashboard_scan_to_connect => 'Digitalizar para ligar';

  @override
  String get dashboard_qr_waiting => 'À espera do túnel...';

  @override
  String get dashboard_daemons_running_default => '0/5 em execução';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'Código de acesso';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Regenerar token';

  @override
  String get dashboard_set_password => 'Definir senha';

  @override
  String get cd_set_password => 'Definir senha personalizada';

  @override
  String get dialog_set_password_title => 'Definir senha personalizada';

  @override
  String get dialog_set_password_message =>
      'Digite uma nova senha de acesso. Isso substitui o token gerado automaticamente.';

  @override
  String get dialog_set_password_hint => 'Nova senha (mín. 12 caracteres)';

  @override
  String get toast_password_set => 'Senha atualizada';

  @override
  String get toast_password_too_short =>
      'A senha deve ter pelo menos 12 caracteres';

  @override
  String get toast_password_save_failed =>
      'Falha ao salvar a senha — serviço não está pronto';

  @override
  String get setup_guide_title => 'Começando';

  @override
  String get setup_guide_subtitle =>
      'Três passos rápidos para obter a melhor experiência:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Escolha a sua língua';

  @override
  String get setup_language_body =>
      'Usa por predefinição o idioma da unidade principal. Toque para escolher outro para a aplicação BladeWatch e o túnel web.';

  @override
  String get setup_language_button => 'Escolha a língua';

  @override
  String get setup_autostart_title =>
      'Desativar a restrição de inicialização automática';

  @override
  String get setup_autostart_body =>
      'Toque abaixo para abrir o BYD Auto-Start e desmarque BladeWatch E Serviço BladeWatch. Sem isso, a gravação não inicia ao ligar o carro — terá de abrir a aplicação todas as vezes. A BYD apaga isto a cada instalação.';

  @override
  String get setup_autostart_button => 'Abrir BYD Auto-Start';

  @override
  String get setup_overlay_title => 'Permitir exibição em outros aplicativos';

  @override
  String get setup_overlay_body =>
      'Habilitar isso para mostrar um indicador de estado flutuante para gravação e rastreamento de viagens em cima de outros aplicativos.';

  @override
  String get setup_overlay_button => 'Abrir definições de sobreposição';

  @override
  String get cd_close => 'Fechar';

  @override
  String get language_picker_title => 'Língua';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return 'Línguas $arg1 disponíveis';
  }

  @override
  String get language_picker_subtitle_pending => 'Escolha uma língua';

  @override
  String get language_auto_title => 'Automático';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Sistema de seguimento · $arg1';
  }

  @override
  String get language_not_saved =>
      'Idioma aplicado, mas não foi possível guardá-lo — será reposto ao reiniciar.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Automático';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Introduza um comando…';

  @override
  String get adb_preset_commands_header => 'Comandações pré-configuradas';

  @override
  String get adb_output_header => 'Saída';

  @override
  String get adb_output_ready => 'Pronto para ordens...';

  @override
  String get adb_console_hero_title => 'Consola ADB';

  @override
  String get adb_console_hero_subtitle =>
      'Execute comandos shell no dispositivo';

  @override
  String get adb_console_unavailable_title => 'O ADB não está ligado';

  @override
  String get adb_console_unavailable_body =>
      'Neste veículo, o interruptor padrão «Depuração USB» nas Opções do programador não é suficiente por si só — a própria definição de ADB sem fios (depuração de rede) da unidade central também tem de estar ativada, e uma atualização do sistema pode repor essa definição. Reative o ADB sem fios na unidade central, ou ligue por USB.';

  @override
  String get adb_console_auth_pending_title => 'A aguardar aprovação';

  @override
  String get adb_console_auth_pending_body =>
      'Verifique no ecrã da unidade central o pedido «Permitir depuração USB?» e aceite-o, depois tente novamente.';

  @override
  String get performance_connecting => 'A ligar ao monitor de desempenho…';

  @override
  String get performance_hero_title => 'Desempenho do sistema';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'Utilização do sistema';

  @override
  String get performance_cpu_app_usage => 'Utilização da app';

  @override
  String get performance_frequency_label => 'Frequência';

  @override
  String get performance_temperature_label => 'Temperatura';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Memória';

  @override
  String get performance_usage_label => 'Utilização';

  @override
  String get performance_memory_total => 'Total';

  @override
  String get performance_memory_used => 'Utilizada';

  @override
  String get performance_memory_app => 'App';

  @override
  String get performance_gpu_title => 'GPU';

  @override
  String get performance_app_process_title => 'Processo da app';

  @override
  String get performance_threads_label => 'Threads';

  @override
  String get performance_gc_cycles_label => 'Ciclos de GC';

  @override
  String get performance_open_fds_label => 'FDs abertos';

  @override
  String get performance_refreshing_footer => 'A atualizar a cada 3 segundos';

  @override
  String get webview_loading => 'Carregando...';

  @override
  String get reset_title => 'Repor dados';

  @override
  String get reset_subtitle => 'Esvaziar os dados acumulados por categoria';

  @override
  String get reset_warning =>
      'Esta ação não pode ser anulada. As gravações, as viagens e o histórico da bateria serão apagados permanentemente.';

  @override
  String get reset_cat_trips => 'Viagens';

  @override
  String get reset_cat_trips_desc =>
      'História de viagem, rotas, rotulações semanais/ mensais';

  @override
  String get reset_cat_soc_history => 'História do SoC & 12V';

  @override
  String get reset_cat_soc_history_desc =>
      'Amostra de SoC, sessões de carregamento, registos de voltagem';

  @override
  String get reset_cat_recordings => 'Gravações (vídeos)';

  @override
  String get reset_cat_recordings_desc => 'Todos os MP4s na pasta de gravações';

  @override
  String get reset_cat_sentry_events => 'Eventos de vigilância';

  @override
  String get reset_cat_sentry_events_desc =>
      'Clipes de eventos de vigilância e ficheiros JSON associados';

  @override
  String get reset_cat_proximity => 'Registros de proximidade';

  @override
  String get reset_cat_proximity_desc =>
      'MP4s de eventos desencadeados por radar';

  @override
  String get reset_cat_trip_files => 'Arquivos de telemetria de viagem';

  @override
  String get reset_cat_trip_files_desc => 'Telemetria por viagem JSON em disco';

  @override
  String get recording_lib_chip_any => 'Qualquer';

  @override
  String get recording_lib_chip_person => 'Pessoa';

  @override
  String get recording_lib_chip_vehicle => 'Veículo';

  @override
  String get recording_lib_chip_bike => 'Bicicleta';

  @override
  String get recording_lib_chip_animal => 'Animais';

  @override
  String get recording_lib_chip_alert => 'Alerta';

  @override
  String get recording_lib_chip_critical => 'Crítico';

  @override
  String get recording_lib_selected_count_zero => '0 selecionado';

  @override
  String get recording_lib_no_recordings => 'Não há gravações';

  @override
  String get recording_lib_filter_button => 'Filtro';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filtro · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Filtrar gravações';

  @override
  String get recording_lib_filter_apply => 'Aplicar';

  @override
  String get recording_lib_filter_reset => 'Redefinir';

  @override
  String get recording_lib_filter_section_what => 'O quê';

  @override
  String get recording_lib_filter_section_severity => 'Gravidade';

  @override
  String get recording_lib_filter_section_type => 'Tipo';

  @override
  String get recording_lib_chip_type_normal => 'Normal';

  @override
  String get recording_lib_chip_type_proximity => 'Proximidade';

  @override
  String get recording_lib_date_today => 'Hoje';

  @override
  String get recording_lib_date_yesterday => 'Ontem';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clipes',
      one: '$arg1 clipe',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Escolha uma data';

  @override
  String get recording_lib_date_all_days => 'Todos os dias';

  @override
  String get cd_clear_date_filter => 'Mostrar todos os dias';

  @override
  String get recording_lib_section_morning => 'Manhã';

  @override
  String get recording_lib_section_afternoon => 'Tarde';

  @override
  String get recording_lib_section_evening => 'Noite';

  @override
  String get recording_lib_section_night => 'Madrugada';

  @override
  String get cd_previous_day => 'Dia anterior';

  @override
  String get cd_next_day => 'Dia seguinte';

  @override
  String get cd_open_filters => 'Abrir filtros';

  @override
  String get cd_clear_filter => 'Limpar filtro';

  @override
  String get player_title_recording => 'Gravação';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Serviço de câmera';

  @override
  String get daemon_name_surveillance => 'Serviço de vigilância';

  @override
  String get daemon_name_acc => 'Vigilância ACC';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'Serviços em segundo plano';

  @override
  String get daemons_count_pending => 'A carregar serviços…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 de $arg2 em execução';
  }

  @override
  String get battery_health_title => 'Saúde da bateria';

  @override
  String get battery_health_unavailable => 'Não disponível';

  @override
  String get battery_health_unavailable_desc =>
      'A estimativa da saúde da bateria não está disponível.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% em $arg2';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Os registos $arg1 excluídos',
      one: 'A gravação $arg1 foi apagada',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Excluir gravações $arg1',
      one: 'Eliminar a gravação $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'Isto elimina permanentemente $arg1 gravações. Esta ação não pode ser anulada.',
      one:
          'Isto elimina permanentemente $arg1 gravação. Esta ação não pode ser anulada.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'Aplicação atualizada (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Permissão de armazenamento necessária para gravações';

  @override
  String get toast_url_copied_short => 'URL copiado!';

  @override
  String get toast_camera_set_to_auto => 'Câmara configurada para Auto';

  @override
  String get toast_failed_to_save_short => 'Não consegui salvar';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Falha: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Câmara $arg1 definida — próximo ciclo ACC';
  }

  @override
  String get toast_clearing_camera_config =>
      'Descargar a configuração da câmera...';

  @override
  String get toast_restarting_camera_daemon =>
      'Reiniciando o serviço de câmera...';

  @override
  String get toast_camera_daemon_restarting =>
      'Serviço de câmera reiniciando com sonda completa';

  @override
  String get toast_camera_restart_failed =>
      'Configuração limpa, mas reinicialização do serviço falhou. Por favor, reinicie manualmente.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Falha: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'Selecione pelo menos uma categoria';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Reset falhou: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return 'Monitor de tráfego $arg1...';
  }

  @override
  String get dialog_close => 'Fechar';

  @override
  String get dialog_reset => 'Redefinir';

  @override
  String get dialog_delete => 'Excluir';

  @override
  String get dialog_save => 'Salvar';

  @override
  String get dialog_enable => 'Ativar';

  @override
  String get dialog_disable => 'Desativar';

  @override
  String get dialog_keep_enabled => 'Manter ativado';

  @override
  String get dialog_keep_disabled => 'Manter desativado';

  @override
  String get dialog_regenerate => 'Regenerar';

  @override
  String get dialog_reset_selected => 'Repor selecionados';

  @override
  String get dialog_reset_following_title => 'Repor o seguinte?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Esta ação não pode ser anulada.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Reposição concluída';

  @override
  String get dialog_traffic_cannot_check_title => 'Não pode verificar o status';

  @override
  String get dialog_traffic_cannot_check_message =>
      'O ADB não está conectado, e o aplicativo não conseguiu reconectar automaticamente.\n\nNeste veículo, a opção padrão \"Depuração USB\" nas Opções do desenvolvedor não é suficiente sozinha — a própria configuração de ADB sem fio (depuração de rede) da central multimídia também precisa estar ativada, e uma atualização do sistema pode desativá-la. Reative o ADB sem fio na central multimídia, ou conecte-se via USB.\n\nO status será atualizado automaticamente assim que houver conexão.';

  @override
  String get dialog_traffic_disable_title =>
      'Desativar o monitor de tráfego BYD?';

  @override
  String get dialog_traffic_disable_message =>
      'O BYD Traffic Monitor (com.byd.trafficmonitor) é uma aplicação de sistema integrada que monitoriza continuamente o trânsito em segundo plano.\n\nPorquê desativá-lo?\n\n• Consome dados móveis (mesmo estacionado)\n• Usa CPU e bateria em segundo plano\n• Desnecessário se usar outra aplicação de navegação\n• Pode interferir com o uso de rede da dashcam\n\nDesativar é seguro: afeta apenas a camada de trânsito integrada no mapa. A navegação, o Bluetooth e todas as outras funções do carro mantêm-se inalteradas.\n\nÉ necessário um reinício forçado após desativar (mantenha o botão da consola central premido 5 segundos).';

  @override
  String get dialog_traffic_enable_title =>
      'Reactiva o monitor de tráfego BYD?';

  @override
  String get dialog_traffic_enable_message =>
      'O Monitor de tráfego BYD está atualmente desativado.\n\nRe-activação irá restaurar a sobreposição de tráfego embutido no mapa de navegação. Observe que ele vai correr em segundo plano e consumir dados móveis.\n\nUm reinicio duro é necessário após a habilitação (pressa o botão central console 5 segundos).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Monitor de tráfego $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'A alteração foi aplicada. Por favor, reinicie agora: Pressione e mantenha o botão central da consola por 5 segundos.';

  @override
  String get traffic_monitor_loading => 'Monitor de tráfego: Verificação...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Monitor de tráfego (toque para verificar)';

  @override
  String get reset_label_trips => 'Viagens';

  @override
  String get reset_label_soc_history => 'História de SoC + 12V';

  @override
  String get reset_label_recordings => 'Gravações';

  @override
  String get reset_label_sentry_events => 'Eventos de vigilância';

  @override
  String get reset_label_proximity => 'Registros de proximidade';

  @override
  String get reset_label_trip_files => 'Arquivos de telemetria de viagem';

  @override
  String get toast_access_code_copied => 'Código de acesso copiado';

  @override
  String get dialog_regenerate_token_title => 'Regenerar token';

  @override
  String get dialog_regenerate_token_message =>
      'Isto invalida o token atual. Todas as sessões ativas serão terminadas. Continuar?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Novo token gerado. Todas as sessões foram terminadas.';

  @override
  String get toast_token_regenerated_restart =>
      'Token regenerado. Os serviços podem precisar ser reiniciados para aplicar.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token regenerado. Não foi possível notificar o serviço em segundo plano.';

  @override
  String get toast_token_regenerated => 'Marca regenerada';

  @override
  String get dashboard_no_tunnel => 'Não há túnel a correr.';

  @override
  String get dashboard_starting_tor => 'A iniciar o túnel Tor…';

  @override
  String get dashboard_waiting_url => 'À espera do túnel URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 em execução';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'Código de acesso';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'Nenhuma configuração necessária para o $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'O token não pode ser vazio';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Trazendo o registro $arg1...';
  }

  @override
  String get toast_log_empty_or_missing =>
      'Arquivo de registro está vazio ou não encontrado';

  @override
  String get toast_log_empty => 'Arquivo de registro está vazio';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Falha em salvar registro: $arg1';
  }

  @override
  String get toast_log_not_found =>
      'Arquivo de registro não encontrado ou ilegível';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return 'Registo de $arg1 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Compartilhar $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== Registo de $arg1 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Fonte: $arg1';
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
          'NOTA: registo truncado para as últimas 10000 linhas (total: $arg1 linhas)',
      one:
          'NOTA: registo truncado para as últimas 10000 linhas (total: $arg1 linha)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Não pode reproduzir vídeo: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Eliminar gravação';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'Eliminar $arg1?\nEsta ação não pode ser anulada.';
  }

  @override
  String get toast_recording_deleted => 'Gravação apagada';

  @override
  String get toast_recording_delete_failed =>
      'Não foi possível eliminar a gravação';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 apagado, $arg2 falhado';
  }

  @override
  String get play_with_chooser => 'Jogar com';

  @override
  String setup_version_banner(Object arg1) {
    return 'Atualizado para v$arg1 — reconfirmar auto-iniciação, BYD apagá-lo em cada instalação';
  }

  @override
  String get setup_overlay_already_granted => 'Já concedido';

  @override
  String camera_current_manual(Object arg1) {
    return 'Atual: Câmara $arg1 (Manual)';
  }

  @override
  String get camera_current_auto_label => 'Atual: Auto';

  @override
  String get soh_estimation_active => 'Atividade de estimativa';

  @override
  String get soh_oem_readout =>
      'Leitura de SOH do veículo — aguardando estimativa calculada';

  @override
  String get soh_nominal_baseline =>
      'Linha de base nominal — aguardando dados confiáveis de SOH';

  @override
  String get soh_no_estimate_yet =>
      'Ainda não há uma estimativa — Esperando dados';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 selecionado';
  }

  @override
  String get video_player_playback_error => 'Erro de reprodução';

  @override
  String get video_player_no_events => 'Não há eventos';

  @override
  String get daemon_configuration_required => 'Configuração necessária';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Reprodutor de vídeo';

  @override
  String get status_overlay_notif_title => 'BladeWatch Status';

  @override
  String get status_overlay_notif_text => 'Status superimposição ativa';

  @override
  String get rail_dashboard => 'Painel';

  @override
  String get rail_live => 'Ao vivo';

  @override
  String get rail_recordings => 'Gravações';

  @override
  String get rail_vehicle => 'Veículo';

  @override
  String get rail_trips => 'Viagens';

  @override
  String get rail_location => 'Localização';

  @override
  String get rail_diagnostics => 'Diagnóstico';

  @override
  String get rail_settings => 'Configurações';

  @override
  String get settings_section_appearance => 'Aparência';

  @override
  String get settings_section_recording => 'Registo';

  @override
  String get settings_section_surveillance => 'Vigilância';

  @override
  String get settings_section_daemons => 'Serviços';

  @override
  String get settings_section_privacy => 'Privacidade e dados';

  @override
  String get settings_section_trips => 'Viagens';

  @override
  String get settings_section_trips_subtitle =>
      'Tarifas de custo, unidade de distância e onde as viagens são guardadas';

  @override
  String get settings_section_overlay => 'Superposição de status';

  @override
  String get settings_overlay_subtitle =>
      'Escolha quais segmentos da pílula de status flutuante permanecem visíveis.';

  @override
  String get settings_overlay_camera_title => 'Indicador de câmera';

  @override
  String get settings_overlay_camera_subtitle =>
      'Mostre o distintivo REC / PROX enquanto a gravação estiver ativa.';

  @override
  String get settings_overlay_trip_title => 'Indicação de Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Mostre o distintivo TRIP enquanto a detecção de viagens está em funcionamento.';

  @override
  String get settings_section_about => 'Sobre';

  @override
  String get settings_subrail_overline => 'SETINGS';

  @override
  String get cd_settings_subrail => 'Barra lateral de definições';

  @override
  String get settings_privacy_title => 'Privacidade e dados';

  @override
  String get settings_privacy_body =>
      'Reset limpa o índice de gravações, credenciais armazenadas em cache, estado do serviço e preferências no dispositivo. Esta ação não pode ser desfeita.';

  @override
  String get settings_about_title => 'Sobre o BladeWatch';

  @override
  String get settings_about_version_label => 'Versão';

  @override
  String get settings_about_package_label => 'Construir';

  @override
  String get settings_about_support_section => 'Acionado por pessoas como tu';

  @override
  String get settings_about_support_share_title => 'Conte a outro proprietário';

  @override
  String get settings_about_support_share_value =>
      'Cada link compartilhado ajuda outro proprietário do BYD a descobrir o BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Confira o BladeWatch — vigilância de código aberto e dashcam para BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser =>
      'Compartilhar excesso de energia';

  @override
  String get settings_about_open_link_failed => 'Não consegui abrir a ligação.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'Nenhum navegador encontrado. URL copiado: $arg1';
  }

  @override
  String get settings_about_support_kofi_title =>
      'Combustível para a próxima versão';

  @override
  String get settings_about_support_kofi_value =>
      'Um café no Ko-Fi mantém os compromissos da noite chegando.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Licença';

  @override
  String get settings_about_license_value =>
      'MIT — código aberto. Toque para ver o texto completo.';

  @override
  String get settings_about_source_title => 'Código de origem';

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
  String get settings_about_star_title => 'Deixe um no GitHub';

  @override
  String get settings_about_star_value => 'Demora um segundo, significa muito.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Obrigado';

  @override
  String get settings_about_thanks_subtitle =>
      'Construído com a ajuda de colaboradores e apoiadores.';

  @override
  String get settings_about_contributors_title => 'Colaboradores';

  @override
  String get settings_about_supporters_title => 'Apoiadores';

  @override
  String get settings_about_thanks_empty =>
      'A lista é preenchida à medida que as pessoas contribuem.';

  @override
  String get settings_theme_label => 'Temática';

  @override
  String get settings_theme_auto => 'Auto (seguir o sistema)';

  @override
  String get settings_theme_light => 'Claro';

  @override
  String get settings_theme_dark => 'Escuro';

  @override
  String get settings_language_label => 'Língua';

  @override
  String get settings_drive_side_label => 'Lado da navegação';

  @override
  String get settings_drive_side_subtitle =>
      'Escolha em que lado da tela o menu de navegação aparece.';

  @override
  String get settings_drive_side_left => 'Esquerda';

  @override
  String get settings_drive_side_left_hint => 'LHD · padrão';

  @override
  String get settings_drive_side_right => 'Direita';

  @override
  String get settings_drive_side_right_hint => 'Veículos RHD';

  @override
  String get settings_drive_side_auto => 'Automático';

  @override
  String get settings_drive_side_auto_hint => 'Detectar do veículo';

  @override
  String get settings_drive_side_caption_left => 'Navegação à esquerda';

  @override
  String get settings_drive_side_caption_right => 'Navegação à direita';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Auto — veículo indica direção à esquerda';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Auto — veículo indica direção à direita';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Auto — veículo indisponível, usando a esquerda';

  @override
  String get recordings_title => 'Gravações';

  @override
  String get recordings_segment_dashcam => 'Dashcam';

  @override
  String get recordings_segment_surveillance => 'Vigilância';

  @override
  String get recordings_action_settings => 'Configurações';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 hoje · $arg2 total · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashcam · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Supervisão · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Selecionar uma gravação';

  @override
  String get recordings_preview_placeholder_body =>
      'Toque em qualquer item à esquerda para tocá-lo.';

  @override
  String get diagnostics_section_adb_console => 'Consola ADB';

  @override
  String get diagnostics_section_traffic => 'Monitor de tráfego';

  @override
  String get diagnostics_section_camera_probe => 'Sonda de câmera';

  @override
  String get diagnostics_section_battery => 'Saúde da bateria';

  @override
  String get diagnostics_section_performance => 'Desempenho';

  @override
  String get diagnostics_hero_title => 'Diagnóstico do sistema';

  @override
  String get diagnostics_hero_subtitle =>
      'A saúde ao vivo, registos e sondas para o dispositivo.';

  @override
  String get diagnostics_health_clear => 'Tudo em ordem';

  @override
  String get diagnostics_health_section => 'Saúde';

  @override
  String get diagnostics_health_network => 'Rede';

  @override
  String get diagnostics_health_storage => 'Armazenamento';

  @override
  String get diagnostics_health_camera => 'Câmara';

  @override
  String get diagnostics_health_battery => 'Bateria';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Online';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Túnel · $arg1';
  }

  @override
  String diagnostics_network_data_usage_line(Object arg1) {
    return '$arg1 este mês';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Online';

  @override
  String get diagnostics_tunnel_state_offline => 'Offline';

  @override
  String get diagnostics_tunnel_state_connecting => 'Conexão';

  @override
  String get diagnostics_network_mobile => 'Móvel';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Offline';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clipes · $arg2 utilizados',
      one: '$arg1 clipe · $arg2 utilizados',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 livre';
  }

  @override
  String get diagnostics_logs_card_title => 'Registro de eventos ao vivo';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Transmissão de saída de serviços em execução.';

  @override
  String get diagnostics_tools_section => 'Ferramentas';

  @override
  String get diagnostics_traffic_subtitle =>
      'Assista à transmissão da rede ao vivo.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Inspecte os fluxos de câmaras conectadas.';

  @override
  String get diagnostics_adb_subtitle => 'Abre o terminal do dispositivo.';

  @override
  String get diagnostics_battery_subtitle =>
      'Inspecte a célula SOH e encha estatísticas.';

  @override
  String get diagnostics_settings_subtitle =>
      'Preferências do aplicativo, tema e idioma.';

  @override
  String get settings_action_reset_data => 'Repor dados…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'Em vigília';

  @override
  String get dashboard_subtitle_all_systems => 'Todos os sistemas online';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 dos serviços online $arg2';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Acesso remoto offline';

  @override
  String get dashboard_metric_recordings => 'As gravações de hoje';

  @override
  String get dashboard_metric_storage => 'Armazenamento utilizado';

  @override
  String get dashboard_metric_tunnel => 'Acesso remoto';

  @override
  String get dashboard_metric_services => 'Serviços em segundo plano';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Veículo';

  @override
  String get dashboard_chip_recording_active => 'Gravação';

  @override
  String get dashboard_chip_recording_idle => 'Inativo';

  @override
  String get dashboard_vehicle_tap_to_set => 'Toque para definir';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Definir a capacidade da bateria';

  @override
  String get vehicle_dialog_model_label => 'Modelo';

  @override
  String get vehicle_dialog_save => 'Salvar';

  @override
  String get settings_recording_tab_status => 'Estado';

  @override
  String get settings_recording_tab_capture => 'Captura';

  @override
  String get settings_recording_tab_quality => 'Qualidade';

  @override
  String get settings_recording_tab_storage => 'Armazenamento';

  @override
  String get settings_recording_status_title => 'Estado da gravação';

  @override
  String get settings_recording_status_current_state => 'Estado atual';

  @override
  String get settings_recording_status_today_count => 'Gravações de hoje';

  @override
  String get settings_recording_mode_title => 'Modo de gravação (ACC ligado)';

  @override
  String get settings_recording_mode_description =>
      'Escolha quando a dashcam deve gravar durante a condução.';

  @override
  String get settings_recording_mode_none_label => 'Nenhuma (predefinição)';

  @override
  String get settings_recording_mode_none_desc =>
      'Sem gravação — a vigilância continua a funcionar';

  @override
  String get settings_recording_mode_continuous_label => 'Contínua';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Gravar sempre durante a condução';

  @override
  String get settings_recording_mode_drive_label => 'Modo de condução';

  @override
  String get settings_recording_mode_drive_desc =>
      'Gravar apenas quando o veículo está em movimento';

  @override
  String get settings_recording_mode_proximity_label => 'Guarda de proximidade';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Gravar quando for detetado movimento';

  @override
  String get settings_recording_limit_title => 'Limite de gravação';

  @override
  String get settings_recording_limit_description =>
      'Duração máxima por ficheiro. As gravações são divididas em novos ficheiros neste intervalo.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_priority_title => 'Prioridade de gravação';

  @override
  String get settings_recording_priority_description =>
      'Como a gravação lida com uma perda súbita de energia.';

  @override
  String get settings_recording_priority_performance_label => 'Desempenho';

  @override
  String get settings_recording_priority_performance_desc =>
      'Usa menos CPU. Se a energia for cortada abruptamente, o segmento de gravação atual (até ao seu Limite de Gravação) pode perder-se.';

  @override
  String get settings_recording_priority_reliability_label => 'Fiabilidade';

  @override
  String get settings_recording_priority_reliability_desc =>
      'Usa um pouco mais de CPU para guardar com mais frequência. Se a energia for cortada abruptamente, perde-se no máximo cerca de um minuto.';

  @override
  String get settings_recording_overlay_fields_title =>
      'Campos de sobreposição';

  @override
  String get settings_recording_overlay_fields_description =>
      'Escolhe o que aparece na sobreposição gravada nas gravações contínuas.';

  @override
  String get settings_recording_overlay_field_speed => 'Velocidade';

  @override
  String get settings_recording_overlay_field_gear => 'Mudança';

  @override
  String get settings_recording_overlay_field_turn_signal_left =>
      'Pisca esquerdo';

  @override
  String get settings_recording_overlay_field_turn_signal_right =>
      'Pisca direito';

  @override
  String get settings_recording_overlay_field_brake_pedal => 'Pedal de travão';

  @override
  String get settings_recording_overlay_field_accel_pedal =>
      'Pedal do acelerador';

  @override
  String get settings_recording_overlay_field_seatbelt_driver =>
      'Cinto do condutor';

  @override
  String get settings_recording_overlay_field_seatbelt_passenger =>
      'Cinto do passageiro';

  @override
  String get settings_recording_overlay_field_timestamp => 'Data e hora';

  @override
  String get settings_recording_quality_title => 'Qualidade da gravação';

  @override
  String get settings_recording_storage_title => 'Armazenamento de gravações';

  @override
  String get settings_recording_storage_confirm_title => 'Eliminar gravações?';

  @override
  String settings_recording_storage_confirm_message(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Isto irá eliminar $arg1 gravações ($arg2).',
      one: 'Isto irá eliminar $arg1 gravação ($arg2).',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_confirm_unknown_title =>
      'Impacto desconhecido';

  @override
  String get settings_recording_storage_confirm_unknown_message =>
      'Não foi possível determinar o que esta alteração iria eliminar. Reduzir o limite pode remover gravações existentes.';

  @override
  String get settings_recording_storage_location_label =>
      'Localização do armazenamento';

  @override
  String get settings_recording_storage_internal => 'Interno';

  @override
  String get settings_recording_storage_sd_card => 'Cartão SD';

  @override
  String get settings_recording_storage_sd_card_na => 'Cartão SD (N/D)';

  @override
  String get settings_recording_storage_sd_mount_failed_title =>
      'O cartão SD não foi montado';

  @override
  String get settings_recording_storage_limit_label =>
      'Limite de armazenamento — elimina automaticamente os mais antigos ao atingir';

  @override
  String get settings_recording_storage_usage_label =>
      'Utilização do armazenamento';

  @override
  String get settings_recording_storage_files_label => 'Ficheiros';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usados / limite $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 gravações',
      one: '$arg1 gravação',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Caminho';

  @override
  String get settings_recording_storage_sd_free_label =>
      'Espaço livre no cartão SD';

  @override
  String get settings_recording_storage_internal_free_label =>
      'Espaço livre interno';

  @override
  String get settings_recording_format_title => 'Formatar unidade externa';

  @override
  String get settings_recording_format_warning =>
      'Apaga PERMANENTEMENTE todos os dados do cartão SD ou da unidade USB.';

  @override
  String get settings_recording_format_confirm =>
      'Toque novamente — TODOS os dados serão APAGADOS';

  @override
  String get settings_recording_format_running => 'A formatar… aguarde';

  @override
  String get settings_recording_format_button => 'Formatar cartão SD / USB';

  @override
  String get settings_recording_format_no_drive =>
      'Nenhuma unidade removível encontrada';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Formatado com êxito. Novo caminho: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Catálogo da base de dados';

  @override
  String get settings_recording_sync_description =>
      'Reconcilia o índice de gravações com os ficheiros no disco.';

  @override
  String get settings_recording_sync_running => 'A sincronizar…';

  @override
  String get settings_recording_sync_button => 'Sincronizar base de dados';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Sincronizado: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress => 'Sincronização já em curso';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Falha na sincronização: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Aplicar alterações';

  @override
  String get settings_recording_dismiss => 'Dispensar';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Iniciar/parar $arg1 ainda não é suportado';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 utilizado · $arg2 livre';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Armazenamento —';

  @override
  String get dashboard_tunnel_offline => 'Offline';

  @override
  String get dashboard_tunnel_online => 'Online';

  @override
  String get dashboard_tunnel_connecting => 'A ligar…';

  @override
  String get dashboard_trips_this_week => 'Esta semana';

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
  String get dashboard_trips_label_trips => 'Viagens';

  @override
  String get dashboard_trips_label_distance => 'Distância';

  @override
  String get dashboard_trips_label_time => 'Tempo ao volante';

  @override
  String get dashboard_trips_no_data => 'Nenhuma viagem registrada esta semana';

  @override
  String get dashboard_trips_unavailable =>
      'Comece a dirigir para ver as estatísticas';

  @override
  String get dashboard_trips_loading => 'Carregando…';

  @override
  String get dashboard_trips_view_all => 'Ver todas as viagens';

  @override
  String get dashboard_action_live => 'Vista ao vivo';

  @override
  String get dashboard_action_live_subtitle => 'Abrir a vista da câmara';

  @override
  String get dashboard_action_recordings => 'Gravações';

  @override
  String get dashboard_action_settings => 'Configurações';

  @override
  String get dashboard_action_settings_subtitle => 'Preferências e sobre';

  @override
  String get settings_hero_title => 'Configurações';

  @override
  String get settings_hero_overline => 'BLADEWATCH';

  @override
  String get settings_hero_subtitle =>
      'Tune a aparência, gravação, vigilância e dados no dispositivo.';

  @override
  String get settings_overline_preferences => 'Preferências';

  @override
  String get settings_overline_about_data => 'Sobre e DATOS';

  @override
  String get settings_quick_theme_label => 'Temática';

  @override
  String get settings_quick_language_label => 'Língua';

  @override
  String get settings_section_recording_subtitle =>
      'Buffers pré/pós, codec, limites de armazenamento.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Horário, sensibilidade ao movimento, detecção de objetos.';

  @override
  String get settings_section_daemons_subtitle =>
      'Túnel Tor e serviços em segundo plano.';

  @override
  String get settings_about_row_title => 'Sobre o BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Versão, licença, desenvolvimento de suporte.';

  @override
  String get settings_reset_row_subtitle =>
      'Gravações claras, eventos ou todos os caches.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Temática, linguagem e preferências visuais.';

  @override
  String get settings_theme_active_auto_caption =>
      'Auto segue o seu tema do sistema.';

  @override
  String get settings_theme_active_light_caption =>
      'O tema claro está sempre ativo.';

  @override
  String get settings_theme_active_dark_caption =>
      'O tema escuro está sempre ativo.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 de $arg2 idiomas disponíveis';
  }

  @override
  String get settings_language_card_title => 'Língua de exibição';

  @override
  String get settings_privacy_stance_title =>
      'Dispositivos em dispositivo por padrão';

  @override
  String get settings_privacy_stance_body =>
      'A BladeWatch funciona inteiramente na unidade principal, sem telemetria sair do carro, exceto através dos túneis e integrações que você configurar explicitamente.';

  @override
  String get settings_privacy_overline_storage => 'Armazenamento local';

  @override
  String get settings_privacy_overline_reset => 'Reset de dados';

  @override
  String get settings_privacy_storage_clips_label => 'Clips no disco';

  @override
  String get settings_privacy_storage_size_label => 'Tamanho total';

  @override
  String get settings_privacy_storage_unavailable => 'Não disponível';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clipes',
      one: '$arg1 clipe',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Escolha categorias: gravações, eventos, configurações de serviços, telemetria em cache...';

  @override
  String get settings_developer_overline => 'DESENVOLVEDOR';

  @override
  String get settings_developer_timing_logs_title => 'Logs de tempo do serviço';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Registra marcadores de tempo decorrido durante a inicialização do serviço. Desative no uso normal para manter o logcat limpo.';

  @override
  String get settings_developer_debug_logs_title =>
      'Logs de depuração do desenvolvedor';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Registra todos os eventos de ciclo de vida de Activity e Fragment e etapas de inicialização em /storage/emulated/0/BladeWatch/data/debug_app.log. Falhas são sempre capturadas. Desativado por padrão.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Câmara $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Câmara $arg1 (manual)';
  }

  @override
  String get diagnostics_camera_value_probing => 'A verificar…';

  @override
  String get diagnostics_camera_value_offline => 'Offline';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Dados pendentes';

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
      other: '$arg1 clipes · $arg2 gravados',
      one: '$arg1 clipe · $arg2 gravados',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Porta-bagagens';

  @override
  String get vehicle_tab_climate => 'Clima';

  @override
  String get vehicle_tab_windows => 'Vidros';

  @override
  String get vehicle_tab_lights => 'Luzes';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Carregamento';

  @override
  String get vehicle_locked => 'Trancado';

  @override
  String get vehicle_unlocked => 'Desbloqueado';

  @override
  String get vehicle_range_label => 'Autonomia';

  @override
  String get vehicle_data_unavailable => 'Dados do veículo indisponíveis.';

  @override
  String get vehicle_action_failed =>
      'Ação falhou. Verifique a conexão com o veículo.';

  @override
  String get vehicle_open_trunk => 'Abrir porta-malas';

  @override
  String get vehicle_close_trunk => 'Fechar porta-bagagens';

  @override
  String get vehicle_trunk_info_open =>
      'Abrir o porta-malas vai destrancar o carro primeiro.';

  @override
  String get vehicle_ac_on => 'AC ligado';

  @override
  String get vehicle_ac_off => 'AC desligado';

  @override
  String get vehicle_max_cooling_on => 'Refrigeração máx.: ATIVADA';

  @override
  String get vehicle_max_cooling_off => 'Refrigeração máx.: DESATIVADA';

  @override
  String get vehicle_screen_on => 'Ecrã: LIGADO';

  @override
  String get vehicle_screen_off => 'Ecrã: DESLIGADO';

  @override
  String get vehicle_media_volume_label => 'Volume multimédia';

  @override
  String get vehicle_media_mute => 'Silenciar';

  @override
  String get vehicle_media_muted => 'Silenciado';

  @override
  String get vehicle_front_defrost => 'Descongelamento dianteiro';

  @override
  String get vehicle_rear_defrost => 'Descongelamento traseiro';

  @override
  String get vehicle_temp_label => 'Temperatura';

  @override
  String get vehicle_fan_speed_label => 'Velocidade do ventilador';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Nível $arg1';
  }

  @override
  String vehicle_outside_temp_fmt(Object arg1) {
    return 'Externa: $arg1°C';
  }

  @override
  String get vehicle_all_windows => 'Todas as janelas';

  @override
  String get vehicle_window_awake_note => 'Só funciona com o carro ativo.';

  @override
  String get vehicle_window_front_left => 'Dianteiro esquerdo';

  @override
  String get vehicle_window_front_right => 'Dianteiro direito';

  @override
  String get vehicle_window_rear_left => 'Traseiro esquerdo';

  @override
  String get vehicle_window_rear_right => 'Traseiro direito';

  @override
  String get vehicle_window_close => 'Fechar';

  @override
  String get vehicle_window_close_vent => 'Fechar ventilação';

  @override
  String get vehicle_window_vent_12 => 'Ventilação 12%';

  @override
  String get vehicle_window_open_all => 'Abrir todos';

  @override
  String get vehicle_sunroof => 'Teto de abrir';

  @override
  String get vehicle_sunshade => 'Cortina de sol';

  @override
  String get vehicle_btn_drl_title => 'Luzes de funcionamento diurno';

  @override
  String get vehicle_btn_slw_title => 'Aviso de limite de velocidade';

  @override
  String get vehicle_control_section_charge_cap => 'Limite de carga';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Limite de carga não é compatível com este veículo.';

  @override
  String get vehicle_charge_limit_label => 'Limite de carga';

  @override
  String get vehicle_enable_charge_limit => 'Ativar limite de carga';

  @override
  String get vehicle_charge_limit_range => 'Mínimo 50%, máximo 100%';

  @override
  String get vehicle_tyre_no_signal => 'SEM SINAL';

  @override
  String get vehicle_tyre_slow_leak => 'FUGA LENTA';

  @override
  String get vehicle_tyre_fast_leak => 'FUGA RÁPIDA';

  @override
  String get vehicle_tyre_low => 'BAIXA';

  @override
  String get vehicle_tyre_high => 'ALTA';

  @override
  String get vehicle_tyre_ok => 'OK';

  @override
  String get vehicle_tyre_check_pressure => 'Verificar pressão';

  @override
  String get vehicle_toggle_on => 'LIG.';

  @override
  String get vehicle_toggle_off => 'DESL.';

  @override
  String get vehicle_err_climate_control => 'Controle de climatização falhou.';

  @override
  String get vehicle_err_max_cooling => 'Refrigeração máxima falhou.';

  @override
  String get vehicle_err_drl_control => 'Controle de DRL falhou.';

  @override
  String get vehicle_err_slw_control => 'Controle de ADAS falhou.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Alternar limite de carga falhou.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Diminuir $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Aumentar $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Conectando…';

  @override
  String get vehicle_appearance_model_title => 'Selecionar modelo';

  @override
  String get vehicle_appearance_custom_color => 'Cor personalizada';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Carga: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Autonomia: $arg1 km';
  }

  @override
  String vehicle_status_fuel_fmt(Object arg1) {
    return 'Combustível: $arg1%';
  }

  @override
  String vehicle_status_fuel_range_fmt(Object arg1) {
    return 'Autonomia a combustível: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Carga: —';

  @override
  String get vehicle_status_range_unknown => 'Autonomia: —';

  @override
  String get startup_subtitle => 'Preparando sua dashcam';

  @override
  String get startup_header_preparing => 'Preparando tudo…';

  @override
  String get startup_header_starting => 'Iniciando…';

  @override
  String get startup_header_verifying => 'Quase pronto…';

  @override
  String get startup_header_ready => 'Tudo pronto';

  @override
  String get startup_daemon_camera => 'Câmera';

  @override
  String get startup_daemon_camera_desc => 'Visualização ao vivo e gravação';

  @override
  String get startup_daemon_sentry => 'Modo sentinela';

  @override
  String get startup_daemon_sentry_desc => 'Detecção de movimento e alertas';

  @override
  String get startup_daemon_parking => 'Guarda de estacionamento';

  @override
  String get startup_daemon_parking_desc => 'Vigia enquanto estacionado';

  @override
  String get startup_status_waiting => 'Aguardando';

  @override
  String get startup_status_starting => 'Iniciando';

  @override
  String get startup_status_ready => 'Pronto';

  @override
  String get startup_status_failed => 'Falhou';

  @override
  String get startup_continue_anyway => 'Continuar mesmo assim';

  @override
  String get startup_continue => 'Continuar →';

  @override
  String get live_retry => 'Tentar novamente';

  @override
  String get live_connecting => 'Conectando à câmera…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Erro: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Câmera indisponível\n$arg1';
  }

  @override
  String get live_direction_all => 'Todas';

  @override
  String get live_direction_front => 'Frente';

  @override
  String get live_direction_right => 'Direita';

  @override
  String get live_direction_rear => 'Trás';

  @override
  String get live_direction_left => 'Esquerda';

  @override
  String get trip_no_route_data => 'Sem dados de rota para esta viagem';

  @override
  String get trips_tab_trips => 'Viagens';

  @override
  String get trips_tab_stats => 'Estatísticas';

  @override
  String get trips_tab_storage => 'Armazenamento';

  @override
  String get trips_filter_7_days => '7 dias';

  @override
  String get trips_filter_14_days => '14 dias';

  @override
  String get trips_filter_30_days => '30 dias';

  @override
  String trips_load_error(Object message) {
    return 'Erro: $message';
  }

  @override
  String get trips_empty_state => 'Ainda não há viagens registadas';

  @override
  String get trips_period_summary_title => 'Resumo do período';

  @override
  String get trips_stat_trips => 'Viagens';

  @override
  String get trips_stat_hours => 'Horas';

  @override
  String get trips_stat_efficiency => 'Eficiência';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Pontuação: $score';
  }

  @override
  String get trips_driver_score_title => 'Pontuação do condutor';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Geral: $score / 100';
  }

  @override
  String get trips_range_title => 'Autonomia personalizada';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'Estimativa BYD: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'Autonomia a combustível: $km';
  }

  @override
  String get trips_range_no_data => 'Ainda não há dados suficientes';

  @override
  String get trips_dna_title => 'ADN de condução';

  @override
  String get trips_dna_anticipation => 'Antecipação';

  @override
  String get trips_dna_smoothness => 'Suavidade';

  @override
  String get trips_dna_speed_discipline => 'Disciplina de velocidade';

  @override
  String get trips_dna_efficiency => 'Eficiência';

  @override
  String get trips_dna_consistency => 'Consistência';

  @override
  String get trips_storage_title => 'Armazenamento de viagens';

  @override
  String get trips_storage_analytics_label => 'Análise de viagens';

  @override
  String get trips_storage_rate_label => 'Tarifa de eletricidade';

  @override
  String get trips_storage_fuel_price_label =>
      'Preço do combustível (por litro)';

  @override
  String get trips_storage_tank_capacity_label =>
      'Capacidade do tanque (litros)';

  @override
  String get trips_storage_distance_unit_label => 'Unidade de distância';

  @override
  String get trips_storage_location_label => 'Localização do armazenamento';

  @override
  String get trips_storage_internal => 'Interno';

  @override
  String get trips_storage_sd_card => 'Cartão SD';

  @override
  String get trips_storage_sd_card_unavailable => 'Cartão SD (N/D)';

  @override
  String get trips_storage_apply => 'Aplicar alterações';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit usados / limite $limit MB · $count viagens';
  }

  @override
  String get trips_sync_title => 'Catálogo da base de dados';

  @override
  String get trips_sync_description =>
      'Reconcilia o índice de viagens com os ficheiros de telemetria no disco.';

  @override
  String get trips_sync_button => 'Sincronizar base de dados';

  @override
  String get trips_sync_running => 'A sincronizar…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Sincronizado com sucesso: +$added -$removed ($total no total)';
  }

  @override
  String get trips_sync_failed_generic => 'Falha na sincronização';

  @override
  String get trips_detail_summary_title => 'Resumo da viagem';

  @override
  String get trips_detail_distance => 'Distância';

  @override
  String get trips_detail_duration => 'Duração';

  @override
  String get trips_detail_energy => 'Energia';

  @override
  String get trips_detail_avg_speed => 'Vel. média';

  @override
  String get trips_detail_max_speed => 'Vel. máx.';

  @override
  String get trips_detail_soc => 'Carga';

  @override
  String get trips_detail_cost => 'Custo';

  @override
  String get trips_detail_ext_temp => 'Temp. exterior';

  @override
  String get trips_detail_fuel_used => 'Combustível';

  @override
  String get trips_detail_fuel_cost => 'Custo de combustível';

  @override
  String get trips_detail_electric_cost => 'Custo de eletricidade';

  @override
  String get trips_detail_elev_gain => 'Ganho de altitude';

  @override
  String get trips_detail_scores_title => 'Pontuações de condução';

  @override
  String get trips_detail_unavailable => 'Detalhes da viagem indisponíveis';

  @override
  String get trips_detail_loading => 'A carregar viagem…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count pontos GPS registados';
  }

  @override
  String get rec_severity_critical => 'CRÍTICO';

  @override
  String get rec_severity_alert => 'ALERTA';

  @override
  String get location_loading_title => 'A carregar mapa';

  @override
  String get location_permission_missing_title =>
      'Permissão de localização necessária';

  @override
  String get location_permission_denied_title => 'Permissão negada';

  @override
  String get location_provider_disabled_title => 'GPS desativado';

  @override
  String get location_waiting_for_fix_title => 'A aguardar sinal de GPS';

  @override
  String get location_car_location_title => 'Localização do veículo';

  @override
  String get location_stale_title => 'Localização desatualizada';

  @override
  String get location_tile_failure_title => 'Mapa indisponível';

  @override
  String get location_tile_failure_subtitle => 'Rede indisponível';

  @override
  String get location_error_title => 'Erro de localização';

  @override
  String get location_action_grant => 'Conceder';

  @override
  String get location_action_retry => 'Tentar novamente';

  @override
  String get location_mode_auto => 'Automático';

  @override
  String get location_mode_light => 'Claro';

  @override
  String get location_mode_dark => 'Escuro';

  @override
  String get cd_recenter_on_car => 'Recentrar no veículo';

  @override
  String get recording_lib_no_recordings_normal => 'Sem gravações normais';

  @override
  String get recording_lib_no_recordings_sentry => 'Sem eventos de vigilância';

  @override
  String get recording_lib_no_recordings_proximity =>
      'Sem eventos de proximidade';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'pessoa';

  @override
  String get video_player_legend_car => 'carro';

  @override
  String get video_player_legend_bike => 'bicicleta';

  @override
  String get video_player_legend_motion => 'movimento';

  @override
  String get recording_lib_proximity_very_close => 'muito perto';

  @override
  String get recording_lib_proximity_close => 'perto';

  @override
  String get recording_lib_proximity_mid => 'médio';

  @override
  String get recording_lib_proximity_far => 'longe';

  @override
  String get surveillance_tab_general => 'Geral';

  @override
  String get surveillance_tab_detection => 'Deteção';

  @override
  String get surveillance_tab_recording => 'Gravação';

  @override
  String get surveillance_tab_storage => 'Armazenamento';

  @override
  String get surveillance_tab_advanced => 'Avançado';

  @override
  String get surveillance_general_title => 'Modo de vigilância';

  @override
  String get surveillance_general_enable => 'Ativar vigilância';

  @override
  String get surveillance_general_status => 'Estado';

  @override
  String get surveillance_general_status_running => 'Em execução';

  @override
  String get surveillance_general_status_idle => 'Inativo';

  @override
  String get surveillance_general_events_today => 'Eventos hoje';

  @override
  String get surveillance_safe_locations_title => 'Locais seguros';

  @override
  String get surveillance_safe_locations_subtitle =>
      'A câmara não arranca ao estacionar aqui';

  @override
  String get surveillance_safe_locations_enable =>
      'Desativar em locais seguros';

  @override
  String get surveillance_safe_locations_empty =>
      'Ainda não foram adicionados locais seguros';

  @override
  String get surveillance_safe_locations_add_current =>
      'Adicionar localização atual como zona segura';

  @override
  String get surveillance_safe_locations_no_gps =>
      'Localização GPS não disponível';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Definições de deteção';

  @override
  String get surveillance_detection_preset_label => 'Predefinição de ambiente';

  @override
  String get surveillance_preset_outdoor => 'Exterior';

  @override
  String get surveillance_preset_garage => 'Garagem';

  @override
  String get surveillance_preset_street => 'Rua';

  @override
  String get surveillance_preset_custom => 'Personalizado';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Sensibilidade (1=rigorosa, 5=sensível): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Detetar objetos';

  @override
  String get surveillance_detection_object_person => 'pessoa';

  @override
  String get surveillance_detection_object_car => 'carro';

  @override
  String get surveillance_detection_object_bike => 'bicicleta';

  @override
  String get surveillance_recording_title => 'Gravação de eventos';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Pré-gravação (segundos antes do evento): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Pós-gravação (segundos após o evento): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Armazenamento de vigilância';

  @override
  String get surveillance_storage_location_label =>
      'Localização de armazenamento';

  @override
  String get surveillance_storage_internal => 'Interno';

  @override
  String get surveillance_storage_sd_card => 'Cartão SD';

  @override
  String get surveillance_storage_sd_card_na => 'Cartão SD (N/D)';

  @override
  String get surveillance_storage_limit_label =>
      'Limite de armazenamento — elimina os mais antigos automaticamente';

  @override
  String get surveillance_storage_usage_label => 'Utilização do armazenamento';

  @override
  String get surveillance_storage_files_label => 'Ficheiros';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usados / limite $arg2';
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
  String get surveillance_storage_path_label => 'Caminho';

  @override
  String get surveillance_format_title => 'Formatar unidade externa';

  @override
  String get surveillance_format_warning =>
      'Apaga permanentemente TODOS os dados do cartão SD ou unidade USB.';

  @override
  String get surveillance_format_button => 'Formatar cartão SD/USB';

  @override
  String get surveillance_format_confirm =>
      'Toque novamente — TODOS os dados serão APAGADOS';

  @override
  String get surveillance_format_running => 'A formatar… aguarde';

  @override
  String get surveillance_dismiss => 'Dispensar';

  @override
  String get surveillance_sync_title => 'Catálogo da base de dados';

  @override
  String get surveillance_sync_description =>
      'Concilia o índice de vigilância com os ficheiros no disco.';

  @override
  String get surveillance_sync_button => 'Sincronizar base de dados';

  @override
  String get surveillance_sync_running => 'A sincronizar…';

  @override
  String get surveillance_advanced_camera_title => 'Seleção de câmara';

  @override
  String get surveillance_advanced_camera_front => 'Frente';

  @override
  String get surveillance_advanced_camera_right => 'Direita';

  @override
  String get surveillance_advanced_camera_rear => 'Trás';

  @override
  String get surveillance_advanced_camera_left => 'Esquerda';

  @override
  String get surveillance_advanced_ai_title => 'IA e dissuasão';

  @override
  String get surveillance_advanced_ai_detection => 'Deteção por IA';

  @override
  String get surveillance_advanced_night_mode => 'Modo noturno';

  @override
  String get surveillance_advanced_deterrent_label => 'Ação de dissuasão';

  @override
  String get surveillance_deterrent_silent => 'Silencioso';

  @override
  String get surveillance_deterrent_horn => 'Buzina';

  @override
  String get surveillance_deterrent_flash => 'Sinal de luzes';

  @override
  String get surveillance_apply_button => 'Aplicar alterações';

  @override
  String get surveillance_apply_failed => 'Falha ao guardar';

  @override
  String get dashboard_tor_bootstrapping => 'A ligar ao Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'Como abrir este endereço';

  @override
  String get dashboard_tor_help_title => 'Abrir este endereço';

  @override
  String get dashboard_tor_help_android =>
      'Android: instale o Tor Browser a partir do Google Play ou F-Droid, abra-o e cole o endereço.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone e iPad: instale o Onion Browser na App Store, abra-o e cole o endereço. O Tor Browser não existe em iOS.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS e Linux: transfira o Tor Browser em torproject.org, abra-o e cole o endereço.';

  @override
  String get dashboard_tor_help_password_note =>
      'A palavra-passe continua a ser necessária depois de a página carregar.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'Digitalize para a página de transferência do Tor Browser';

  @override
  String get dashboard_tor_help_close => 'Percebi';

  @override
  String get surveillance_general_battery_warning =>
      'O modo sentinela consome energia extra da bateria de 12V enquanto está ativo.';

  @override
  String get surveillance_general_camera_contention_warning =>
      'Outra aplicação está a utilizar a câmara neste momento.';

  @override
  String get pairing_title => 'Emparelhar um dispositivo';

  @override
  String get pairing_scan_hint =>
      'Digitalize com a aplicação BladeWatch no seu telemóvel ou computador. O código só funciona uma vez.';

  @override
  String pairing_expires_in(String time) {
    return 'Expira em $time';
  }

  @override
  String get pairing_expired => 'Este código expirou.';

  @override
  String get pairing_new_code => 'Novo código';

  @override
  String get pairing_remote_note =>
      'Emparelhar ativa o acesso remoto a este carro.';

  @override
  String get pairing_lan_title => 'Ligação direta nesta rede Wi-Fi';

  @override
  String get pairing_lan_body =>
      'Um dispositivo emparelhado na mesma rede Wi-Fi do carro liga-se diretamente e de forma encriptada, sem passar pela internet. Desativado até o ativar.';

  @override
  String get pairing_devices_title => 'Dispositivos emparelhados';

  @override
  String get pairing_devices_empty => 'Ainda não há dispositivos emparelhados.';

  @override
  String get pairing_remove => 'Remover';

  @override
  String pairing_remove_confirm_title(String name) {
    return 'Remover $name?';
  }

  @override
  String get pairing_remove_confirm_body =>
      'Perde o acesso imediatamente. Os seus outros dispositivos continuam a funcionar.';

  @override
  String get pairing_error =>
      'O serviço da câmara não respondeu. Tente novamente.';

  @override
  String get daemon_name_pear => 'Acesso remoto (Pear)';

  @override
  String get pear_status_reachable => 'Acessível a partir de qualquer lugar';

  @override
  String get pear_status_unreachable => 'Inacessível: sem ligação à rede Pear';

  @override
  String get pear_status_unknown => 'Acessibilidade desconhecida';

  @override
  String pear_devices_connected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos ligados',
      one: '$count dispositivo ligado',
      zero: 'Nenhum dispositivo ligado',
    );
    return '$_temp0';
  }

  @override
  String pear_last_connection(String time) {
    return 'Última ligação: $time';
  }

  @override
  String get pear_tile_off => 'Desligado';

  @override
  String get trips_cost_total => 'Custo total';

  @override
  String get trips_cost_no_rate =>
      'Defina uma tarifa de eletricidade nas definições de viagens para ver os custos.';

  @override
  String get trips_cost_mixed_currency =>
      'As viagens têm custos em mais de uma moeda, por isso nenhum total é mostrado.';

  @override
  String dashboard_chip_gear(String gear) {
    return 'Mudança $gear';
  }

  @override
  String dashboard_chip_drive_mode(String mode) {
    return 'Modo: $mode';
  }

  @override
  String dashboard_chip_auto_hold(String state) {
    return 'Auto Hold: $state';
  }

  @override
  String get auto_hold_disabled => 'Desligado';

  @override
  String get auto_hold_enabled => 'Ligado';

  @override
  String get auto_hold_active => 'A segurar';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get app_name => 'BladeWatch';

  @override
  String get accessibility_service_description =>
      'Mantenha o monitoramento do veículo BladeWatch ativo em segundo plano. Este serviço não lê nem interage com o conteúdo da tela.';

  @override
  String get action_cancel => 'Cancelar';

  @override
  String get action_clear_plain => 'Limpar';

  @override
  String get action_select_all => 'Selecionar todos';

  @override
  String get action_select_all_short => 'Todos';

  @override
  String get action_delete => 'Excluir';

  @override
  String get action_done => 'CONCLUÍDO';

  @override
  String get action_remind_me_later => 'LEMBRAR MAIS TARDE';

  @override
  String get action_retry => 'Tentar novamente';

  @override
  String get action_run => 'Executar';

  @override
  String get action_clear_output => 'Limpar saída';

  @override
  String get cd_camera => 'Câmara';

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
  String get cd_clear_logs => 'Limpar registros';

  @override
  String get cd_expand_collapse => 'Expandir/Recolher';

  @override
  String get cd_recording_status => 'Status de gravação';

  @override
  String get cd_trip_tracking_status => 'Estatuto do rastreamento de viagens';

  @override
  String get cd_video_thumbnail => 'Miniatura de vídeo';

  @override
  String get cd_play => 'Reproduzir';

  @override
  String get cd_back => 'Voltar';

  @override
  String get cd_play_pause => 'Reproduzir/Pausar';

  @override
  String get cd_player_prev => 'Gravação anterior';

  @override
  String get cd_player_next => 'Próxima gravação';

  @override
  String get cd_player_maximize => 'Maximizar player';

  @override
  String get cd_player_minimize => 'Sair da tela cheia';

  @override
  String get cd_delete => 'Excluir';

  @override
  String get cd_decrease => 'Diminuir';

  @override
  String get cd_increase => 'Aumentar';

  @override
  String get cd_expand => 'Expandir';

  @override
  String get cd_configure => 'Configurar';

  @override
  String get cd_download_log => 'Baixar log';

  @override
  String get cd_reset => 'Redefinir';

  @override
  String get cd_battery => 'Bateria';

  @override
  String get cd_step_completed => 'Passo concluído';

  @override
  String get cd_permission_granted => 'Permissão concedida';

  @override
  String get overlay_rec_inactive_label => 'REC';

  @override
  String get overlay_trip_inactive_label => 'TRIP';

  @override
  String get daemon_card_subprocesses => 'PROCESSOS';

  @override
  String get logs_panel_title => 'Registros';

  @override
  String get url_connecting => 'Conectar...';

  @override
  String get camera_selection_title => 'Seleção de câmera';

  @override
  String get camera_selection_subtitle =>
      'Selecione a fonte da câmera panorâmica';

  @override
  String get camera_current_auto => 'Atual: Auto';

  @override
  String get camera_option_auto => 'Automático (detecção no início)';

  @override
  String get camera_option_0 => 'Câmara 0 — Tintas Atto';

  @override
  String get camera_option_1 => 'Câmara 1 — Seal (default)';

  @override
  String get camera_option_2 => 'Câmara 2';

  @override
  String get camera_option_3 => 'Câmara 3';

  @override
  String get camera_option_4 => 'Câmara 4';

  @override
  String get camera_option_5 => 'Câmara 5';

  @override
  String get camera_selection_hint =>
      'Auto seleciona a câmera correta para o seu acabamento a cada inicialização. Câmera 1 = BYD Seal, Câmera 0 = acabamentos Atto. Reinicie o serviço de câmera após alterar o ID da câmera para que a configuração entre em vigor.';

  @override
  String get dashboard_scan_to_connect => 'Escanear para conectar';

  @override
  String get dashboard_qr_waiting => 'À espera do túnel...';

  @override
  String get dashboard_daemons_running_default => '0/5 em execução';

  @override
  String get dashboard_device_id_loading => '…';

  @override
  String get dashboard_access_code => 'Código de acesso';

  @override
  String get dashboard_token_masked => '••••••••';

  @override
  String get dashboard_regenerate_token => 'Regenerar token';

  @override
  String get dashboard_set_password => 'Definir senha';

  @override
  String get cd_set_password => 'Definir senha personalizada';

  @override
  String get dialog_set_password_title => 'Definir senha personalizada';

  @override
  String get dialog_set_password_message =>
      'Digite uma nova senha de acesso. Isso substitui o token gerado automaticamente.';

  @override
  String get dialog_set_password_hint => 'Nova senha (mín. 12 caracteres)';

  @override
  String get toast_password_set => 'Senha atualizada';

  @override
  String get toast_password_too_short =>
      'A senha deve ter pelo menos 12 caracteres';

  @override
  String get toast_password_save_failed =>
      'Falha ao salvar a senha — serviço não está pronto';

  @override
  String get setup_guide_title => 'Começando';

  @override
  String get setup_guide_subtitle =>
      'Três passos rápidos para obter a melhor experiência:';

  @override
  String get setup_step_one_label => '1';

  @override
  String get setup_step_two_label => '2';

  @override
  String get setup_step_three_label => '3';

  @override
  String get setup_language_title => 'Escolha a sua língua';

  @override
  String get setup_language_body =>
      'Usa por padrão o idioma da unidade principal. Toque para escolher outro para o aplicativo BladeWatch e o túnel web.';

  @override
  String get setup_language_button => 'Escolha a língua';

  @override
  String get setup_autostart_title =>
      'Desativar a restrição de inicialização automática';

  @override
  String get setup_autostart_body =>
      'Toque abaixo para abrir o BYD Auto-Start e desmarque BladeWatch E Serviço BladeWatch. Sem isso, a gravação não inicia ao ligar o carro — você terá que abrir o aplicativo toda vez. A BYD apaga isso a cada instalação.';

  @override
  String get setup_autostart_button => 'Abrir BYD Auto-Start';

  @override
  String get setup_overlay_title => 'Permitir exibição em outros aplicativos';

  @override
  String get setup_overlay_body =>
      'Habilitar isso para mostrar um indicador de estado flutuante para gravação e rastreamento de viagens em cima de outros aplicativos.';

  @override
  String get setup_overlay_button => 'Abrir configurações de sobreposição';

  @override
  String get cd_close => 'Fechar';

  @override
  String get language_picker_title => 'Língua';

  @override
  String language_picker_subtitle_fmt(Object arg1) {
    return 'Línguas $arg1 disponíveis';
  }

  @override
  String get language_picker_subtitle_pending => 'Escolha uma língua';

  @override
  String get language_auto_title => 'Automático';

  @override
  String language_auto_subtitle(Object arg1) {
    return 'Sistema de seguimento · $arg1';
  }

  @override
  String get language_not_saved =>
      'Idioma aplicado, mas não foi possível salvá-lo — será redefinido ao reiniciar.';

  @override
  String language_label_auto_fmt(Object arg1) {
    return '$arg1 · Automático';
  }

  @override
  String get adb_prompt => '\$';

  @override
  String get adb_command_hint => 'Digite um comando…';

  @override
  String get adb_preset_commands_header => 'Comandações pré-configuradas';

  @override
  String get adb_output_header => 'Saída';

  @override
  String get adb_output_ready => 'Pronto para ordens...';

  @override
  String get adb_console_hero_title => 'Consola ADB';

  @override
  String get adb_console_hero_subtitle =>
      'Execute comandos shell no dispositivo';

  @override
  String get adb_console_unavailable_title => 'O ADB não está conectado';

  @override
  String get adb_console_unavailable_body =>
      'Neste veículo, a chave padrão “Depuração USB” nas Opções do desenvolvedor não é suficiente sozinha — a própria configuração de ADB sem fio (depuração de rede) da central multimídia também precisa estar ativada, e uma atualização do sistema pode redefini-la. Reative o ADB sem fio na central multimídia, ou conecte-se via USB.';

  @override
  String get adb_console_auth_pending_title => 'Aguardando aprovação';

  @override
  String get adb_console_auth_pending_body =>
      'Verifique na tela da central multimídia o aviso “Permitir depuração USB?” e aceite-o, depois tente novamente.';

  @override
  String get performance_connecting => 'Conectando ao monitor de desempenho…';

  @override
  String get performance_hero_title => 'Desempenho do sistema';

  @override
  String get performance_cpu_title => 'CPU';

  @override
  String get performance_cpu_system_usage => 'Uso do sistema';

  @override
  String get performance_cpu_app_usage => 'Uso do app';

  @override
  String get performance_frequency_label => 'Frequência';

  @override
  String get performance_temperature_label => 'Temperatura';

  @override
  String get performance_temperature_na => 'N/A';

  @override
  String get performance_memory_title => 'Memória';

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
  String get performance_app_process_title => 'Processo do app';

  @override
  String get performance_threads_label => 'Threads';

  @override
  String get performance_gc_cycles_label => 'Ciclos de GC';

  @override
  String get performance_open_fds_label => 'FDs abertos';

  @override
  String get performance_refreshing_footer => 'Atualizando a cada 3 segundos';

  @override
  String get webview_loading => 'Carregando...';

  @override
  String get reset_title => 'Redefinir dados';

  @override
  String get reset_subtitle => 'Esvaziar os dados acumulados por categoria';

  @override
  String get reset_warning =>
      'Esta ação não pode ser desfeita. As gravações, as viagens e o histórico da bateria serão excluídos permanentemente.';

  @override
  String get reset_cat_trips => 'Viagens';

  @override
  String get reset_cat_trips_desc =>
      'História de viagem, rotas, rotulações semanais/ mensais';

  @override
  String get reset_cat_soc_history => 'História do SoC & 12V';

  @override
  String get reset_cat_soc_history_desc =>
      'Amostra de SoC, sessões de carregamento, registos de voltagem';

  @override
  String get reset_cat_recordings => 'Gravações (vídeos)';

  @override
  String get reset_cat_recordings_desc => 'Todos os MP4s na pasta de gravações';

  @override
  String get reset_cat_sentry_events => 'Eventos de vigilância';

  @override
  String get reset_cat_sentry_events_desc =>
      'Clipes de eventos de vigilância e arquivos JSON associados';

  @override
  String get reset_cat_proximity => 'Registros de proximidade';

  @override
  String get reset_cat_proximity_desc =>
      'MP4s de eventos desencadeados por radar';

  @override
  String get reset_cat_trip_files => 'Arquivos de telemetria de viagem';

  @override
  String get reset_cat_trip_files_desc => 'Telemetria por viagem JSON em disco';

  @override
  String get recording_lib_chip_any => 'Qualquer';

  @override
  String get recording_lib_chip_person => 'Pessoa';

  @override
  String get recording_lib_chip_vehicle => 'Veículo';

  @override
  String get recording_lib_chip_bike => 'Bicicleta';

  @override
  String get recording_lib_chip_animal => 'Animais';

  @override
  String get recording_lib_chip_alert => 'Alerta';

  @override
  String get recording_lib_chip_critical => 'Crítico';

  @override
  String get recording_lib_selected_count_zero => '0 selecionado';

  @override
  String get recording_lib_no_recordings => 'Não há gravações';

  @override
  String get recording_lib_filter_button => 'Filtro';

  @override
  String recording_lib_filter_button_active(Object arg1) {
    return 'Filtro · $arg1';
  }

  @override
  String get recording_lib_filter_sheet_title => 'Filtrar gravações';

  @override
  String get recording_lib_filter_apply => 'Aplicar';

  @override
  String get recording_lib_filter_reset => 'Redefinir';

  @override
  String get recording_lib_filter_section_what => 'O quê';

  @override
  String get recording_lib_filter_section_severity => 'Gravidade';

  @override
  String get recording_lib_filter_section_type => 'Tipo';

  @override
  String get recording_lib_chip_type_normal => 'Normal';

  @override
  String get recording_lib_chip_type_proximity => 'Proximidade';

  @override
  String get recording_lib_date_today => 'Hoje';

  @override
  String get recording_lib_date_yesterday => 'Ontem';

  @override
  String recording_lib_clip_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clipes',
      one: '$arg1 clipe',
    );
    return '$_temp0';
  }

  @override
  String get recording_lib_pick_date => 'Escolha uma data';

  @override
  String get recording_lib_date_all_days => 'Todos os dias';

  @override
  String get cd_clear_date_filter => 'Mostrar todos os dias';

  @override
  String get recording_lib_section_morning => 'Manhã';

  @override
  String get recording_lib_section_afternoon => 'Tarde';

  @override
  String get recording_lib_section_evening => 'Noite';

  @override
  String get recording_lib_section_night => 'Madrugada';

  @override
  String get cd_previous_day => 'Dia anterior';

  @override
  String get cd_next_day => 'Dia seguinte';

  @override
  String get cd_open_filters => 'Abrir filtros';

  @override
  String get cd_clear_filter => 'Limpar filtro';

  @override
  String get player_title_recording => 'Gravação';

  @override
  String get player_time_zero => '0:00';

  @override
  String get player_time_separator => ' / ';

  @override
  String get daemon_name_camera => 'Serviço de câmera';

  @override
  String get daemon_name_surveillance => 'Serviço de vigilância';

  @override
  String get daemon_name_acc => 'Vigilância ACC';

  @override
  String get daemon_name_tor => 'Tor Tunnel';

  @override
  String get daemons_hero_title => 'Serviços em segundo plano';

  @override
  String get daemons_count_pending => 'Carregando serviços…';

  @override
  String daemons_count_fmt(Object arg1, Object arg2) {
    return '$arg1 de $arg2 em execução';
  }

  @override
  String get battery_health_title => 'Saúde da bateria';

  @override
  String get battery_health_unavailable => 'Não disponível';

  @override
  String get battery_health_unavailable_desc =>
      'A estimativa da saúde da bateria não está disponível.';

  @override
  String soh_dialog_calibration_format(Object arg1, Object arg2) {
    return '$arg1% em $arg2';
  }

  @override
  String get dialog_ok => 'OK';

  @override
  String recordings_deleted_count(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Os registos $arg1 excluídos',
      one: 'A gravação $arg1 foi apagada',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_title(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Excluir gravações $arg1',
      one: 'Eliminar a gravação $arg1',
    );
    return '$_temp0';
  }

  @override
  String delete_recordings_message(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other:
          'Isso excluirá permanentemente $arg1 gravações. Esta ação não pode ser desfeita.',
      one:
          'Isso excluirá permanentemente $arg1 gravação. Esta ação não pode ser desfeita.',
    );
    return '$_temp0';
  }

  @override
  String toast_app_up_to_date(Object arg1) {
    return 'Aplicação atualizada (v$arg1)';
  }

  @override
  String get toast_storage_permission_required =>
      'Permissão de armazenamento necessária para gravações';

  @override
  String get toast_url_copied_short => 'URL copiado!';

  @override
  String get toast_camera_set_to_auto => 'Câmara configurada para Auto';

  @override
  String get toast_failed_to_save_short => 'Não consegui salvar';

  @override
  String toast_failed_with_message(Object arg1) {
    return 'Falha: $arg1';
  }

  @override
  String toast_camera_id_set(Object arg1) {
    return 'Câmera $arg1 definida — próximo ciclo ACC';
  }

  @override
  String get toast_clearing_camera_config =>
      'Descargar a configuração da câmera...';

  @override
  String get toast_restarting_camera_daemon =>
      'Reiniciando o serviço de câmera...';

  @override
  String get toast_camera_daemon_restarting =>
      'Serviço de câmera reiniciando com sonda completa';

  @override
  String get toast_camera_restart_failed =>
      'Configuração limpa, mas reinicialização do serviço falhou. Por favor, reinicie manualmente.';

  @override
  String toast_failed_with_message_x(Object arg1) {
    return 'Falha: $arg1';
  }

  @override
  String get toast_select_at_least_one_category =>
      'Selecione pelo menos uma categoria';

  @override
  String toast_reset_failed_with_error(Object arg1) {
    return 'Reset falhou: $arg1';
  }

  @override
  String toast_traffic_monitor_changing(Object arg1) {
    return 'Monitor de tráfego $arg1...';
  }

  @override
  String get dialog_close => 'Fechar';

  @override
  String get dialog_reset => 'Redefinir';

  @override
  String get dialog_delete => 'Excluir';

  @override
  String get dialog_save => 'Salvar';

  @override
  String get dialog_enable => 'Ativar';

  @override
  String get dialog_disable => 'Desativar';

  @override
  String get dialog_keep_enabled => 'Manter ativado';

  @override
  String get dialog_keep_disabled => 'Manter desativado';

  @override
  String get dialog_regenerate => 'Regenerar';

  @override
  String get dialog_reset_selected => 'Redefinir selecionados';

  @override
  String get dialog_reset_following_title => 'Redefinir o seguinte?';

  @override
  String dialog_reset_following_message(Object arg1) {
    return 'Esta ação não pode ser desfeita.\n\n$arg1';
  }

  @override
  String get dialog_reset_complete_title => 'Redefinição concluída';

  @override
  String get dialog_traffic_cannot_check_title => 'Não pode verificar o status';

  @override
  String get dialog_traffic_cannot_check_message =>
      'O ADB não está conectado, e o aplicativo não conseguiu reconectar automaticamente.\n\nNeste veículo, a opção padrão \"Depuração USB\" nas Opções do desenvolvedor não é suficiente sozinha — a própria configuração de ADB sem fio (depuração de rede) da central multimídia também precisa estar ativada, e uma atualização do sistema pode desativá-la. Reative o ADB sem fio na central multimídia, ou conecte-se via USB.\n\nO status será atualizado automaticamente assim que houver conexão.';

  @override
  String get dialog_traffic_disable_title =>
      'Desativar o monitor de tráfego BYD?';

  @override
  String get dialog_traffic_disable_message =>
      'O BYD Traffic Monitor (com.byd.trafficmonitor) é um app de sistema integrado que monitora continuamente o trânsito em segundo plano.\n\nPor que desativá-lo?\n\n• Consome dados móveis (mesmo estacionado)\n• Usa CPU e bateria em segundo plano\n• Desnecessário se você usa outro app de navegação\n• Pode interferir no uso de rede da dashcam\n\nDesativar é seguro: afeta apenas a camada de trânsito integrada no mapa. A navegação, o Bluetooth e todas as demais funções do carro permanecem inalteradas.\n\nÉ necessário um reinício forçado após desativar (segure o botão do console central por 5 segundos).';

  @override
  String get dialog_traffic_enable_title =>
      'Reactiva o monitor de tráfego BYD?';

  @override
  String get dialog_traffic_enable_message =>
      'O Monitor de tráfego BYD está atualmente desativado.\n\nRe-activação irá restaurar a sobreposição de tráfego embutido no mapa de navegação. Observe que ele vai correr em segundo plano e consumir dados móveis.\n\nUm reinicio duro é necessário após a habilitação (pressa o botão central console 5 segundos).';

  @override
  String dialog_traffic_status_title(Object arg1) {
    return 'Monitor de tráfego $arg1';
  }

  @override
  String get dialog_traffic_reboot_message =>
      'A alteração foi aplicada. Por favor, reinicie agora: Pressione e mantenha o botão central da consola por 5 segundos.';

  @override
  String get traffic_monitor_loading => 'Monitor de tráfego: Verificação...';

  @override
  String get traffic_monitor_tap_to_check =>
      'Monitor de tráfego (toque para verificar)';

  @override
  String get reset_label_trips => 'Viagens';

  @override
  String get reset_label_soc_history => 'História de SoC + 12V';

  @override
  String get reset_label_recordings => 'Gravações';

  @override
  String get reset_label_sentry_events => 'Eventos de vigilância';

  @override
  String get reset_label_proximity => 'Registros de proximidade';

  @override
  String get reset_label_trip_files => 'Arquivos de telemetria de viagem';

  @override
  String get toast_access_code_copied => 'Código de acesso copiado';

  @override
  String get dialog_regenerate_token_title => 'Regenerar token';

  @override
  String get dialog_regenerate_token_message =>
      'Isso invalidará o token atual. Todas as sessões ativas serão encerradas. Continuar?';

  @override
  String get toast_token_regenerated_logged_out =>
      'Novo token gerado. Todas as sessões foram encerradas.';

  @override
  String get toast_token_regenerated_restart =>
      'Token regenerado. Os serviços podem precisar ser reiniciados para aplicar.';

  @override
  String get toast_token_regenerated_no_notify =>
      'Token regenerado. Não foi possível notificar o serviço em segundo plano.';

  @override
  String get toast_token_regenerated => 'Marca regenerada';

  @override
  String get dashboard_no_tunnel => 'Não há túnel a correr.';

  @override
  String get dashboard_starting_tor => 'Iniciando o túnel Tor…';

  @override
  String get dashboard_waiting_url => 'À espera do túnel URL...';

  @override
  String dashboard_daemons_running(Object arg1, Object arg2) {
    return '$arg1/$arg2 em execução';
  }

  @override
  String get tunnel_label_tor => 'Tor';

  @override
  String get clip_label_access_code => 'Código de acesso';

  @override
  String get clip_label_url => 'URL';

  @override
  String toast_no_config_needed(Object arg1) {
    return 'Nenhuma configuração necessária para o $arg1';
  }

  @override
  String get toast_token_cannot_be_empty => 'O token não pode ser vazio';

  @override
  String toast_fetching_log(Object arg1) {
    return 'Trazendo o registro $arg1...';
  }

  @override
  String get toast_log_empty_or_missing =>
      'Arquivo de registro está vazio ou não encontrado';

  @override
  String get toast_log_empty => 'Arquivo de registro está vazio';

  @override
  String toast_log_save_failed(Object arg1) {
    return 'Falha em salvar registro: $arg1';
  }

  @override
  String get toast_log_not_found =>
      'Arquivo de registro não encontrado ou ilegível';

  @override
  String log_share_title(Object arg1, Object arg2) {
    return 'Log de $arg1 - $arg2';
  }

  @override
  String log_share_chooser(Object arg1) {
    return 'Compartilhar $arg1 Log';
  }

  @override
  String log_header_title(Object arg1) {
    return '=== Log de $arg1 ===';
  }

  @override
  String log_header_source(Object arg1) {
    return 'Fonte: $arg1';
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
          'NOTA: registro truncado para as últimas 10000 linhas (total: $arg1 linhas)',
      one:
          'NOTA: registro truncado para as últimas 10000 linhas (total: $arg1 linha)',
    );
    return '$_temp0';
  }

  @override
  String toast_cannot_play_video(Object arg1) {
    return 'Não pode reproduzir vídeo: $arg1';
  }

  @override
  String get dialog_delete_recording_title => 'Excluir gravação';

  @override
  String dialog_delete_recording_message(Object arg1) {
    return 'Excluir $arg1?\nEsta ação não pode ser desfeita.';
  }

  @override
  String get toast_recording_deleted => 'Gravação apagada';

  @override
  String get toast_recording_delete_failed =>
      'Não foi possível excluir a gravação';

  @override
  String toast_batch_delete_partial(Object arg1, Object arg2) {
    return '$arg1 apagado, $arg2 falhado';
  }

  @override
  String get play_with_chooser => 'Jogar com';

  @override
  String setup_version_banner(Object arg1) {
    return 'Atualizado para v$arg1 — reconfirmar auto-iniciação, BYD apagá-lo em cada instalação';
  }

  @override
  String get setup_overlay_already_granted => 'Já concedido';

  @override
  String camera_current_manual(Object arg1) {
    return 'Atual: Câmara $arg1 (Manual)';
  }

  @override
  String get camera_current_auto_label => 'Atual: Auto';

  @override
  String get soh_estimation_active => 'Atividade de estimativa';

  @override
  String get soh_oem_readout =>
      'Leitura de SOH do veículo — aguardando estimativa calculada';

  @override
  String get soh_nominal_baseline =>
      'Linha de base nominal — aguardando dados confiáveis de SOH';

  @override
  String get soh_no_estimate_yet =>
      'Ainda não há uma estimativa — Esperando dados';

  @override
  String recording_lib_selected_count(Object arg1) {
    return '$arg1 selecionado';
  }

  @override
  String get video_player_playback_error => 'Erro de reprodução';

  @override
  String get video_player_no_events => 'Não há eventos';

  @override
  String get daemon_configuration_required => 'Configuração necessária';

  @override
  String daemon_configuration_message(Object arg1) {
    return '$arg1';
  }

  @override
  String get nav_page_video_player => 'Reprodutor de vídeo';

  @override
  String get status_overlay_notif_title => 'BladeWatch Status';

  @override
  String get status_overlay_notif_text => 'Status superimposição ativa';

  @override
  String get rail_dashboard => 'Painel';

  @override
  String get rail_live => 'Ao vivo';

  @override
  String get rail_recordings => 'Gravações';

  @override
  String get rail_vehicle => 'Veículo';

  @override
  String get rail_trips => 'Viagens';

  @override
  String get rail_location => 'Localização';

  @override
  String get rail_diagnostics => 'Diagnóstico';

  @override
  String get rail_settings => 'Configurações';

  @override
  String get settings_section_appearance => 'Aparência';

  @override
  String get settings_section_recording => 'Registo';

  @override
  String get settings_section_surveillance => 'Vigilância';

  @override
  String get settings_section_daemons => 'Serviços';

  @override
  String get settings_section_privacy => 'Privacidade e dados';

  @override
  String get settings_section_trips => 'Viagens';

  @override
  String get settings_section_trips_subtitle =>
      'Tarifas de custo, unidade de distância e onde as viagens são salvas';

  @override
  String get settings_section_overlay => 'Superposição de status';

  @override
  String get settings_overlay_subtitle =>
      'Escolha quais segmentos da pílula de status flutuante permanecem visíveis.';

  @override
  String get settings_overlay_camera_title => 'Indicador de câmera';

  @override
  String get settings_overlay_camera_subtitle =>
      'Mostre o distintivo REC / PROX enquanto a gravação estiver ativa.';

  @override
  String get settings_overlay_trip_title => 'Indicação de Trip';

  @override
  String get settings_overlay_trip_subtitle =>
      'Mostre o distintivo TRIP enquanto a detecção de viagens está em funcionamento.';

  @override
  String get settings_section_about => 'Sobre';

  @override
  String get settings_subrail_overline => 'SETINGS';

  @override
  String get cd_settings_subrail => 'Barra lateral de configurações';

  @override
  String get settings_privacy_title => 'Privacidade e dados';

  @override
  String get settings_privacy_body =>
      'Reset limpa o índice de gravações, credenciais armazenadas em cache, estado do serviço e preferências no dispositivo. Esta ação não pode ser desfeita.';

  @override
  String get settings_about_title => 'Sobre o BladeWatch';

  @override
  String get settings_about_version_label => 'Versão';

  @override
  String get settings_about_package_label => 'Construir';

  @override
  String get settings_about_support_section => 'Acionado por pessoas como tu';

  @override
  String get settings_about_support_share_title => 'Conte a outro proprietário';

  @override
  String get settings_about_support_share_value =>
      'Cada link compartilhado ajuda outro proprietário do BYD a descobrir o BladeWatch.';

  @override
  String get settings_about_support_share_message =>
      'Confira o BladeWatch — vigilância de código aberto e dashcam para BYD: https://bladewatch-5lc.pages.dev/';

  @override
  String get settings_about_support_share_chooser =>
      'Compartilhar excesso de energia';

  @override
  String get settings_about_open_link_failed => 'Não consegui abrir a ligação.';

  @override
  String settings_about_open_link_copied(Object arg1) {
    return 'Nenhum navegador encontrado. URL copiado: $arg1';
  }

  @override
  String get settings_about_support_kofi_title =>
      'Combustível para a próxima versão';

  @override
  String get settings_about_support_kofi_value =>
      'Um café no Ko-Fi mantém os compromissos da noite chegando.';

  @override
  String get settings_about_support_kofi_url => 'https://ko-fi.com/E1E71XALHX';

  @override
  String get settings_about_license_title => 'Licença';

  @override
  String get settings_about_license_value =>
      'MIT — código aberto. Toque para ver o texto completo.';

  @override
  String get settings_about_source_title => 'Código de origem';

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
  String get settings_about_star_title => 'Deixe um no GitHub';

  @override
  String get settings_about_star_value => 'Demora um segundo, significa muito.';

  @override
  String get settings_about_star_url =>
      'https://github.com/yash-srivastava/BladeWatch-release';

  @override
  String get settings_about_thanks_title => 'Obrigado';

  @override
  String get settings_about_thanks_subtitle =>
      'Construído com a ajuda de colaboradores e apoiadores.';

  @override
  String get settings_about_contributors_title => 'Colaboradores';

  @override
  String get settings_about_supporters_title => 'Apoiadores';

  @override
  String get settings_about_thanks_empty =>
      'A lista é preenchida à medida que as pessoas contribuem.';

  @override
  String get settings_theme_label => 'Temática';

  @override
  String get settings_theme_auto => 'Auto (seguir o sistema)';

  @override
  String get settings_theme_light => 'Claro';

  @override
  String get settings_theme_dark => 'Escuro';

  @override
  String get settings_language_label => 'Língua';

  @override
  String get settings_drive_side_label => 'Lado da navegação';

  @override
  String get settings_drive_side_subtitle =>
      'Escolha em que lado da tela o menu de navegação aparece.';

  @override
  String get settings_drive_side_left => 'Esquerda';

  @override
  String get settings_drive_side_left_hint => 'LHD · padrão';

  @override
  String get settings_drive_side_right => 'Direita';

  @override
  String get settings_drive_side_right_hint => 'Veículos RHD';

  @override
  String get settings_drive_side_auto => 'Automático';

  @override
  String get settings_drive_side_auto_hint => 'Detectar do veículo';

  @override
  String get settings_drive_side_caption_left => 'Navegação à esquerda';

  @override
  String get settings_drive_side_caption_right => 'Navegação à direita';

  @override
  String get settings_drive_side_caption_auto_left =>
      'Auto — veículo indica direção à esquerda';

  @override
  String get settings_drive_side_caption_auto_right =>
      'Auto — veículo indica direção à direita';

  @override
  String get settings_drive_side_caption_auto_unknown =>
      'Auto — veículo indisponível, usando a esquerda';

  @override
  String get recordings_title => 'Gravações';

  @override
  String get recordings_segment_dashcam => 'Dashcam';

  @override
  String get recordings_segment_surveillance => 'Vigilância';

  @override
  String get recordings_action_settings => 'Configurações';

  @override
  String recordings_summary_format(Object arg1, Object arg2, Object arg3) {
    return '$arg1 hoje · $arg2 total · $arg3';
  }

  @override
  String recordings_segment_dashcam_count(Object arg1) {
    return 'Dashcam · $arg1';
  }

  @override
  String recordings_segment_surveillance_count(Object arg1) {
    return 'Supervisão · $arg1';
  }

  @override
  String get recordings_summary_pending => '—';

  @override
  String get recordings_preview_placeholder_title => 'Selecionar uma gravação';

  @override
  String get recordings_preview_placeholder_body =>
      'Toque em qualquer item à esquerda para tocá-lo.';

  @override
  String get diagnostics_section_adb_console => 'Consola ADB';

  @override
  String get diagnostics_section_traffic => 'Monitor de tráfego';

  @override
  String get diagnostics_section_camera_probe => 'Sonda de câmera';

  @override
  String get diagnostics_section_battery => 'Saúde da bateria';

  @override
  String get diagnostics_section_performance => 'Desempenho';

  @override
  String get diagnostics_hero_title => 'Diagnóstico do sistema';

  @override
  String get diagnostics_hero_subtitle =>
      'A saúde ao vivo, registos e sondas para o dispositivo.';

  @override
  String get diagnostics_health_clear => 'Tudo em ordem';

  @override
  String get diagnostics_health_section => 'Saúde';

  @override
  String get diagnostics_health_network => 'Rede';

  @override
  String get diagnostics_health_storage => 'Armazenamento';

  @override
  String get diagnostics_health_camera => 'Câmara';

  @override
  String get diagnostics_health_battery => 'Bateria';

  @override
  String get diagnostics_metric_pending => '—';

  @override
  String get diagnostics_metric_online => 'Online';

  @override
  String diagnostics_network_tunnel_label(Object arg1) {
    return 'Túnel · $arg1';
  }

  @override
  String diagnostics_network_data_usage_line(Object arg1) {
    return '$arg1 este mês';
  }

  @override
  String get diagnostics_tunnel_state_online => 'Online';

  @override
  String get diagnostics_tunnel_state_offline => 'Offline';

  @override
  String get diagnostics_tunnel_state_connecting => 'Conexão';

  @override
  String get diagnostics_network_mobile => 'Móvel';

  @override
  String get diagnostics_network_ethernet => 'Ethernet';

  @override
  String get diagnostics_network_offline => 'Offline';

  @override
  String diagnostics_storage_used_line(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clipes · $arg2 utilizados',
      one: '$arg1 clipe · $arg2 utilizados',
    );
    return '$_temp0';
  }

  @override
  String diagnostics_storage_free_line(Object arg1) {
    return '$arg1 livre';
  }

  @override
  String get diagnostics_logs_card_title => 'Registro de eventos ao vivo';

  @override
  String get diagnostics_logs_card_subtitle =>
      'Transmissão de saída de serviços em execução.';

  @override
  String get diagnostics_tools_section => 'Ferramentas';

  @override
  String get diagnostics_traffic_subtitle =>
      'Assista à transmissão da rede ao vivo.';

  @override
  String get diagnostics_camera_probe_subtitle =>
      'Inspecte os fluxos de câmaras conectadas.';

  @override
  String get diagnostics_adb_subtitle => 'Abre o terminal do dispositivo.';

  @override
  String get diagnostics_battery_subtitle =>
      'Inspecte a célula SOH e encha estatísticas.';

  @override
  String get diagnostics_settings_subtitle =>
      'Preferências do aplicativo, tema e idioma.';

  @override
  String get settings_action_reset_data => 'Redefinir dados…';

  @override
  String get cd_brand_logo => 'BladeWatch';

  @override
  String get dashboard_hero_headline => 'Em vigília';

  @override
  String get dashboard_subtitle_all_systems => 'Todos os sistemas online';

  @override
  String dashboard_subtitle_some_offline(Object arg1, Object arg2) {
    return '$arg1 dos serviços online $arg2';
  }

  @override
  String get dashboard_subtitle_no_tunnel => 'Acesso remoto offline';

  @override
  String get dashboard_metric_recordings => 'As gravações de hoje';

  @override
  String get dashboard_metric_storage => 'Armazenamento utilizado';

  @override
  String get dashboard_metric_tunnel => 'Acesso remoto';

  @override
  String get dashboard_metric_services => 'Serviços em segundo plano';

  @override
  String get dashboard_metric_value_pending => '—';

  @override
  String get dashboard_metric_vehicle => 'Veículo';

  @override
  String get dashboard_chip_recording_active => 'Gravação';

  @override
  String get dashboard_chip_recording_idle => 'Inativo';

  @override
  String get dashboard_vehicle_tap_to_set => 'Toque para definir';

  @override
  String dashboard_vehicle_summary(Object arg1, Object arg2) {
    return '$arg1 kWh · $arg2';
  }

  @override
  String get vehicle_dialog_title => 'Definir a capacidade da bateria';

  @override
  String get vehicle_dialog_model_label => 'Modelo';

  @override
  String get vehicle_dialog_save => 'Salvar';

  @override
  String get settings_recording_tab_status => 'Status';

  @override
  String get settings_recording_tab_capture => 'Captura';

  @override
  String get settings_recording_tab_quality => 'Qualidade';

  @override
  String get settings_recording_tab_storage => 'Armazenamento';

  @override
  String get settings_recording_status_title => 'Status da gravação';

  @override
  String get settings_recording_status_current_state => 'Estado atual';

  @override
  String get settings_recording_status_today_count => 'Gravações de hoje';

  @override
  String get settings_recording_mode_title => 'Modo de gravação (ACC ligado)';

  @override
  String get settings_recording_mode_description =>
      'Escolha quando a dashcam deve gravar durante a direção.';

  @override
  String get settings_recording_mode_none_label => 'Nenhuma (padrão)';

  @override
  String get settings_recording_mode_none_desc =>
      'Sem gravação — a vigilância continua funcionando';

  @override
  String get settings_recording_mode_continuous_label => 'Contínua';

  @override
  String get settings_recording_mode_continuous_desc =>
      'Gravar o tempo todo durante a direção';

  @override
  String get settings_recording_mode_drive_label => 'Modo de direção';

  @override
  String get settings_recording_mode_drive_desc =>
      'Gravar apenas quando o veículo está em movimento';

  @override
  String get settings_recording_mode_proximity_label => 'Guarda de proximidade';

  @override
  String get settings_recording_mode_proximity_desc =>
      'Gravar quando for detectado movimento';

  @override
  String get settings_recording_limit_title => 'Limite de gravação';

  @override
  String get settings_recording_limit_description =>
      'Duração máxima por arquivo. As gravações são divididas em novos arquivos neste intervalo.';

  @override
  String settings_recording_limit_minutes(Object arg1) {
    return '$arg1 min';
  }

  @override
  String get settings_recording_priority_title => 'Prioridade de gravação';

  @override
  String get settings_recording_priority_description =>
      'Como a gravação lida com uma perda repentina de energia.';

  @override
  String get settings_recording_priority_performance_label => 'Desempenho';

  @override
  String get settings_recording_priority_performance_desc =>
      'Usa menos CPU. Se a energia for cortada abruptamente, o segmento de gravação atual (até o seu Limite de Gravação) pode ser perdido.';

  @override
  String get settings_recording_priority_reliability_label => 'Confiabilidade';

  @override
  String get settings_recording_priority_reliability_desc =>
      'Usa um pouco mais de CPU para salvar com mais frequência. Se a energia for cortada abruptamente, no máximo cerca de um minuto pode ser perdido.';

  @override
  String get settings_recording_overlay_fields_title =>
      'Campos de sobreposição';

  @override
  String get settings_recording_overlay_fields_description =>
      'Escolha o que aparece na sobreposição gravada nas gravações contínuas.';

  @override
  String get settings_recording_overlay_field_speed => 'Velocidade';

  @override
  String get settings_recording_overlay_field_gear => 'Marcha';

  @override
  String get settings_recording_overlay_field_turn_signal_left =>
      'Seta esquerda';

  @override
  String get settings_recording_overlay_field_turn_signal_right =>
      'Seta direita';

  @override
  String get settings_recording_overlay_field_brake_pedal => 'Pedal de freio';

  @override
  String get settings_recording_overlay_field_accel_pedal =>
      'Pedal do acelerador';

  @override
  String get settings_recording_overlay_field_seatbelt_driver =>
      'Cinto do motorista';

  @override
  String get settings_recording_overlay_field_seatbelt_passenger =>
      'Cinto do passageiro';

  @override
  String get settings_recording_overlay_field_timestamp => 'Data e hora';

  @override
  String get settings_recording_quality_title => 'Qualidade da gravação';

  @override
  String get settings_recording_storage_title => 'Armazenamento de gravações';

  @override
  String get settings_recording_storage_confirm_title => 'Excluir gravações?';

  @override
  String settings_recording_storage_confirm_message(num arg1, Object arg2) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: 'Isso excluirá $arg1 gravações ($arg2).',
      one: 'Isso excluirá $arg1 gravação ($arg2).',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_confirm_unknown_title =>
      'Impacto desconhecido';

  @override
  String get settings_recording_storage_confirm_unknown_message =>
      'Não foi possível determinar o que esta alteração excluiria. Reduzir o limite pode remover gravações existentes.';

  @override
  String get settings_recording_storage_location_label =>
      'Local de armazenamento';

  @override
  String get settings_recording_storage_internal => 'Interno';

  @override
  String get settings_recording_storage_sd_card => 'Cartão SD';

  @override
  String get settings_recording_storage_sd_card_na => 'Cartão SD (N/D)';

  @override
  String get settings_recording_storage_sd_mount_failed_title =>
      'O cartão SD não foi montado';

  @override
  String get settings_recording_storage_limit_label =>
      'Limite de armazenamento — exclui automaticamente os mais antigos ao atingir';

  @override
  String get settings_recording_storage_usage_label => 'Uso do armazenamento';

  @override
  String get settings_recording_storage_files_label => 'Arquivos';

  @override
  String settings_recording_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usados / limite $arg2';
  }

  @override
  String settings_recording_storage_files(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 gravações',
      one: '$arg1 gravação',
    );
    return '$_temp0';
  }

  @override
  String get settings_recording_storage_path_label => 'Caminho';

  @override
  String get settings_recording_storage_sd_free_label =>
      'Espaço livre no cartão SD';

  @override
  String get settings_recording_storage_internal_free_label =>
      'Espaço livre interno';

  @override
  String get settings_recording_format_title => 'Formatar unidade externa';

  @override
  String get settings_recording_format_warning =>
      'Apaga PERMANENTEMENTE todos os dados do cartão SD ou da unidade USB.';

  @override
  String get settings_recording_format_confirm =>
      'Toque novamente — TODOS os dados serão APAGADOS';

  @override
  String get settings_recording_format_running => 'Formatando… aguarde';

  @override
  String get settings_recording_format_button => 'Formatar cartão SD / USB';

  @override
  String get settings_recording_format_no_drive =>
      'Nenhuma unidade removível encontrada';

  @override
  String settings_recording_format_success(Object arg1) {
    return 'Formatado com sucesso. Novo caminho: $arg1';
  }

  @override
  String get settings_recording_sync_title => 'Catálogo do banco de dados';

  @override
  String get settings_recording_sync_description =>
      'Reconcilia o índice de gravações com os arquivos no disco.';

  @override
  String get settings_recording_sync_running => 'Sincronizando…';

  @override
  String get settings_recording_sync_button => 'Sincronizar banco de dados';

  @override
  String settings_recording_sync_success(Object arg1, Object arg2) {
    return 'Sincronizado: +$arg1 -$arg2';
  }

  @override
  String get settings_recording_sync_in_progress =>
      'Sincronização já em andamento';

  @override
  String settings_recording_sync_failed(Object arg1) {
    return 'Falha na sincronização: $arg1';
  }

  @override
  String get settings_recording_apply_button => 'Aplicar alterações';

  @override
  String get settings_recording_dismiss => 'Dispensar';

  @override
  String settings_daemons_toggle_unsupported(Object arg1) {
    return 'Iniciar/parar $arg1 ainda não é compatível';
  }

  @override
  String dashboard_metric_storage_chip(Object arg1, Object arg2) {
    return '$arg1 utilizado · $arg2 livre';
  }

  @override
  String get dashboard_metric_storage_chip_pending => 'Armazenamento —';

  @override
  String get dashboard_tunnel_offline => 'Offline';

  @override
  String get dashboard_tunnel_online => 'Online';

  @override
  String get dashboard_tunnel_connecting => 'Conectando…';

  @override
  String get dashboard_trips_this_week => 'Esta semana';

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
  String get dashboard_trips_label_trips => 'Viagens';

  @override
  String get dashboard_trips_label_distance => 'Distância';

  @override
  String get dashboard_trips_label_time => 'Tempo ao volante';

  @override
  String get dashboard_trips_no_data => 'Nenhuma viagem registrada esta semana';

  @override
  String get dashboard_trips_unavailable =>
      'Comece a dirigir para ver as estatísticas';

  @override
  String get dashboard_trips_loading => 'Carregando…';

  @override
  String get dashboard_trips_view_all => 'Ver todas as viagens';

  @override
  String get dashboard_action_live => 'Vista ao vivo';

  @override
  String get dashboard_action_live_subtitle => 'Abrir a visualização da câmera';

  @override
  String get dashboard_action_recordings => 'Gravações';

  @override
  String get dashboard_action_settings => 'Configurações';

  @override
  String get dashboard_action_settings_subtitle => 'Preferências e sobre';

  @override
  String get settings_hero_title => 'Configurações';

  @override
  String get settings_hero_overline => 'BLADEWATCH';

  @override
  String get settings_hero_subtitle =>
      'Tune a aparência, gravação, vigilância e dados no dispositivo.';

  @override
  String get settings_overline_preferences => 'Preferências';

  @override
  String get settings_overline_about_data => 'Sobre e DATOS';

  @override
  String get settings_quick_theme_label => 'Temática';

  @override
  String get settings_quick_language_label => 'Língua';

  @override
  String get settings_section_recording_subtitle =>
      'Buffers pré/pós, codec, limites de armazenamento.';

  @override
  String get settings_section_surveillance_subtitle =>
      'Horário, sensibilidade ao movimento, detecção de objetos.';

  @override
  String get settings_section_daemons_subtitle =>
      'Túnel Tor e serviços em segundo plano.';

  @override
  String get settings_about_row_title => 'Sobre o BladeWatch';

  @override
  String get settings_about_row_subtitle =>
      'Versão, licença, desenvolvimento de suporte.';

  @override
  String get settings_reset_row_subtitle =>
      'Gravações claras, eventos ou todos os caches.';

  @override
  String settings_footer_format(Object arg1, Object arg2) {
    return 'BladeWatch $arg1 · $arg2';
  }

  @override
  String get settings_appearance_subtitle =>
      'Temática, linguagem e preferências visuais.';

  @override
  String get settings_theme_active_auto_caption =>
      'Auto segue o seu tema do sistema.';

  @override
  String get settings_theme_active_light_caption =>
      'O tema claro está sempre ativo.';

  @override
  String get settings_theme_active_dark_caption =>
      'O tema escuro está sempre ativo.';

  @override
  String settings_language_count_format(Object arg1, Object arg2) {
    return '$arg1 de $arg2 idiomas disponíveis';
  }

  @override
  String get settings_language_card_title => 'Língua de exibição';

  @override
  String get settings_privacy_stance_title =>
      'Dispositivos em dispositivo por padrão';

  @override
  String get settings_privacy_stance_body =>
      'A BladeWatch funciona inteiramente na unidade principal, sem telemetria sair do carro, exceto através dos túneis e integrações que você configurar explicitamente.';

  @override
  String get settings_privacy_overline_storage => 'Armazenamento local';

  @override
  String get settings_privacy_overline_reset => 'Reset de dados';

  @override
  String get settings_privacy_storage_clips_label => 'Clips no disco';

  @override
  String get settings_privacy_storage_size_label => 'Tamanho total';

  @override
  String get settings_privacy_storage_unavailable => 'Não disponível';

  @override
  String settings_privacy_storage_count_format_plural(num arg1) {
    String _temp0 = intl.Intl.pluralLogic(
      arg1,
      locale: localeName,
      other: '$arg1 clipes',
      one: '$arg1 clipe',
    );
    return '$_temp0';
  }

  @override
  String get settings_privacy_reset_subtitle =>
      'Escolha categorias: gravações, eventos, configurações de serviços, telemetria em cache...';

  @override
  String get settings_developer_overline => 'DESENVOLVEDOR';

  @override
  String get settings_developer_timing_logs_title => 'Logs de tempo do serviço';

  @override
  String get settings_developer_timing_logs_subtitle =>
      'Registra marcadores de tempo decorrido durante a inicialização do serviço. Desative no uso normal para manter o logcat limpo.';

  @override
  String get settings_developer_debug_logs_title =>
      'Logs de depuração do desenvolvedor';

  @override
  String get settings_developer_debug_logs_subtitle =>
      'Registra todos os eventos de ciclo de vida de Activity e Fragment e etapas de inicialização em /storage/emulated/0/BladeWatch/data/debug_app.log. Falhas são sempre capturadas. Desativado por padrão.';

  @override
  String diagnostics_camera_value_camera_n(Object arg1) {
    return 'Câmara $arg1';
  }

  @override
  String diagnostics_camera_value_camera_n_manual(Object arg1) {
    return 'Câmara $arg1 (manual)';
  }

  @override
  String get diagnostics_camera_value_probing => 'Verificando…';

  @override
  String get diagnostics_camera_value_offline => 'Offline';

  @override
  String diagnostics_battery_value_soh(Object arg1) {
    return '$arg1%';
  }

  @override
  String get diagnostics_battery_value_pending => 'Dados pendentes';

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
      other: '$arg1 clipes · $arg2 gravados',
      one: '$arg1 clipe · $arg2 gravados',
    );
    return '$_temp0';
  }

  @override
  String get vehicle_tab_trunk => 'Porta-malas';

  @override
  String get vehicle_tab_climate => 'Clima';

  @override
  String get vehicle_tab_windows => 'Vidros';

  @override
  String get vehicle_tab_lights => 'Luzes';

  @override
  String get vehicle_tab_adas => 'ADAS';

  @override
  String get vehicle_control_charging_tab => 'Carregamento';

  @override
  String get vehicle_locked => 'Trancado';

  @override
  String get vehicle_unlocked => 'Desbloqueado';

  @override
  String get vehicle_range_label => 'Autonomia';

  @override
  String get vehicle_data_unavailable => 'Dados do veículo indisponíveis.';

  @override
  String get vehicle_action_failed =>
      'Ação falhou. Verifique a conexão com o veículo.';

  @override
  String get vehicle_open_trunk => 'Abrir porta-malas';

  @override
  String get vehicle_close_trunk => 'Fechar porta-malas';

  @override
  String get vehicle_trunk_info_open =>
      'Abrir o porta-malas vai destrancar o carro primeiro.';

  @override
  String get vehicle_ac_on => 'AC ligado';

  @override
  String get vehicle_ac_off => 'AC desligado';

  @override
  String get vehicle_max_cooling_on => 'Refrigeração máx.: ATIVADA';

  @override
  String get vehicle_max_cooling_off => 'Refrigeração máx.: DESATIVADA';

  @override
  String get vehicle_screen_on => 'Tela: LIGADA';

  @override
  String get vehicle_screen_off => 'Tela: DESLIGADA';

  @override
  String get vehicle_media_volume_label => 'Volume da mídia';

  @override
  String get vehicle_media_mute => 'Silenciar';

  @override
  String get vehicle_media_muted => 'Silenciado';

  @override
  String get vehicle_front_defrost => 'Desembaçador dianteiro';

  @override
  String get vehicle_rear_defrost => 'Desembaçador traseiro';

  @override
  String get vehicle_temp_label => 'Temperatura';

  @override
  String get vehicle_fan_speed_label => 'Velocidade do ventilador';

  @override
  String vehicle_fan_level(Object arg1) {
    return 'Nível $arg1';
  }

  @override
  String vehicle_outside_temp_fmt(Object arg1) {
    return 'Externa: $arg1°C';
  }

  @override
  String get vehicle_all_windows => 'Todas as janelas';

  @override
  String get vehicle_window_awake_note => 'Só funciona com o carro ativo.';

  @override
  String get vehicle_window_front_left => 'Dianteiro esquerdo';

  @override
  String get vehicle_window_front_right => 'Dianteiro direito';

  @override
  String get vehicle_window_rear_left => 'Traseiro esquerdo';

  @override
  String get vehicle_window_rear_right => 'Traseiro direito';

  @override
  String get vehicle_window_close => 'Fechar';

  @override
  String get vehicle_window_close_vent => 'Fechar ventilação';

  @override
  String get vehicle_window_vent_12 => 'Ventilação 12%';

  @override
  String get vehicle_window_open_all => 'Abrir todos';

  @override
  String get vehicle_sunroof => 'Teto solar';

  @override
  String get vehicle_sunshade => 'Cortina de sol';

  @override
  String get vehicle_btn_drl_title => 'Luzes de funcionamento diurno';

  @override
  String get vehicle_btn_slw_title => 'Aviso de limite de velocidade';

  @override
  String get vehicle_control_section_charge_cap => 'Limite de carga';

  @override
  String get vehicle_charge_cap_not_supported =>
      'Limite de carga não é compatível com este veículo.';

  @override
  String get vehicle_charge_limit_label => 'Limite de carga';

  @override
  String get vehicle_enable_charge_limit => 'Ativar limite de carga';

  @override
  String get vehicle_charge_limit_range => 'Mínimo 50%, máximo 100%';

  @override
  String get vehicle_tyre_no_signal => 'SEM SINAL';

  @override
  String get vehicle_tyre_slow_leak => 'VAZAMENTO LENTO';

  @override
  String get vehicle_tyre_fast_leak => 'VAZAMENTO RÁPIDO';

  @override
  String get vehicle_tyre_low => 'BAIXA';

  @override
  String get vehicle_tyre_high => 'ALTA';

  @override
  String get vehicle_tyre_ok => 'OK';

  @override
  String get vehicle_tyre_check_pressure => 'Verificar pressão';

  @override
  String get vehicle_toggle_on => 'LIG.';

  @override
  String get vehicle_toggle_off => 'DESL.';

  @override
  String get vehicle_err_climate_control => 'Controle de climatização falhou.';

  @override
  String get vehicle_err_max_cooling => 'Refrigeração máxima falhou.';

  @override
  String get vehicle_err_drl_control => 'Controle de DRL falhou.';

  @override
  String get vehicle_err_slw_control => 'Controle de ADAS falhou.';

  @override
  String get vehicle_err_charge_limit_toggle =>
      'Alternar limite de carga falhou.';

  @override
  String vehicle_a11y_decrease_fmt(Object arg1) {
    return 'Diminuir $arg1';
  }

  @override
  String vehicle_a11y_increase_fmt(Object arg1) {
    return 'Aumentar $arg1';
  }

  @override
  String get vehicle_stale_connecting => 'Conectando…';

  @override
  String get vehicle_appearance_model_title => 'Selecionar modelo';

  @override
  String get vehicle_appearance_custom_color => 'Cor personalizada';

  @override
  String vehicle_status_charge_fmt(Object arg1) {
    return 'Carga: $arg1%';
  }

  @override
  String vehicle_status_range_fmt(Object arg1) {
    return 'Autonomia: $arg1 km';
  }

  @override
  String vehicle_status_fuel_fmt(Object arg1) {
    return 'Combustível: $arg1%';
  }

  @override
  String vehicle_status_fuel_range_fmt(Object arg1) {
    return 'Autonomia a combustível: $arg1 km';
  }

  @override
  String get vehicle_status_charge_unknown => 'Carga: —';

  @override
  String get vehicle_status_range_unknown => 'Autonomia: —';

  @override
  String get startup_subtitle => 'Preparando sua dashcam';

  @override
  String get startup_header_preparing => 'Preparando tudo…';

  @override
  String get startup_header_starting => 'Iniciando…';

  @override
  String get startup_header_verifying => 'Quase pronto…';

  @override
  String get startup_header_ready => 'Tudo pronto';

  @override
  String get startup_daemon_camera => 'Câmera';

  @override
  String get startup_daemon_camera_desc => 'Visualização ao vivo e gravação';

  @override
  String get startup_daemon_sentry => 'Modo sentinela';

  @override
  String get startup_daemon_sentry_desc => 'Detecção de movimento e alertas';

  @override
  String get startup_daemon_parking => 'Guarda de estacionamento';

  @override
  String get startup_daemon_parking_desc => 'Vigia enquanto estacionado';

  @override
  String get startup_status_waiting => 'Aguardando';

  @override
  String get startup_status_starting => 'Iniciando';

  @override
  String get startup_status_ready => 'Pronto';

  @override
  String get startup_status_failed => 'Falhou';

  @override
  String get startup_continue_anyway => 'Continuar mesmo assim';

  @override
  String get startup_continue => 'Continuar →';

  @override
  String get live_retry => 'Tentar novamente';

  @override
  String get live_connecting => 'Conectando à câmera…';

  @override
  String live_error_fmt(Object arg1) {
    return 'Erro: $arg1';
  }

  @override
  String live_camera_unavailable_fmt(Object arg1) {
    return 'Câmera indisponível\n$arg1';
  }

  @override
  String get live_direction_all => 'Todas';

  @override
  String get live_direction_front => 'Frente';

  @override
  String get live_direction_right => 'Direita';

  @override
  String get live_direction_rear => 'Traseira';

  @override
  String get live_direction_left => 'Esquerda';

  @override
  String get trip_no_route_data => 'Sem dados de rota para esta viagem';

  @override
  String get trips_tab_trips => 'Viagens';

  @override
  String get trips_tab_stats => 'Estatísticas';

  @override
  String get trips_tab_storage => 'Armazenamento';

  @override
  String get trips_filter_7_days => '7 dias';

  @override
  String get trips_filter_14_days => '14 dias';

  @override
  String get trips_filter_30_days => '30 dias';

  @override
  String trips_load_error(Object message) {
    return 'Erro: $message';
  }

  @override
  String get trips_empty_state => 'Nenhuma viagem registrada ainda';

  @override
  String get trips_period_summary_title => 'Resumo do período';

  @override
  String get trips_stat_trips => 'Viagens';

  @override
  String get trips_stat_hours => 'Horas';

  @override
  String get trips_stat_efficiency => 'Eficiência';

  @override
  String get trips_stat_kwh => 'kWh';

  @override
  String get trips_stat_kwh_per_100km => 'kWh/100km';

  @override
  String trips_score_label(Object score) {
    return 'Pontuação: $score';
  }

  @override
  String get trips_driver_score_title => 'Pontuação do motorista';

  @override
  String trips_driver_score_overall(Object score) {
    return 'Geral: $score / 100';
  }

  @override
  String get trips_range_title => 'Autonomia personalizada';

  @override
  String trips_range_byd_estimate(Object km) {
    return 'Estimativa BYD: $km';
  }

  @override
  String trips_range_fuel(Object km) {
    return 'Autonomia a combustível: $km';
  }

  @override
  String get trips_range_no_data => 'Ainda não há dados suficientes';

  @override
  String get trips_dna_title => 'DNA de condução';

  @override
  String get trips_dna_anticipation => 'Antecipação';

  @override
  String get trips_dna_smoothness => 'Suavidade';

  @override
  String get trips_dna_speed_discipline => 'Disciplina de velocidade';

  @override
  String get trips_dna_efficiency => 'Eficiência';

  @override
  String get trips_dna_consistency => 'Consistência';

  @override
  String get trips_storage_title => 'Armazenamento de viagens';

  @override
  String get trips_storage_analytics_label => 'Análise de viagens';

  @override
  String get trips_storage_rate_label => 'Tarifa de eletricidade';

  @override
  String get trips_storage_fuel_price_label =>
      'Preço do combustível (por litro)';

  @override
  String get trips_storage_tank_capacity_label =>
      'Capacidade do tanque (litros)';

  @override
  String get trips_storage_distance_unit_label => 'Unidade de distância';

  @override
  String get trips_storage_location_label => 'Local de armazenamento';

  @override
  String get trips_storage_internal => 'Interno';

  @override
  String get trips_storage_sd_card => 'Cartão SD';

  @override
  String get trips_storage_sd_card_unavailable => 'Cartão SD (N/D)';

  @override
  String get trips_storage_apply => 'Aplicar alterações';

  @override
  String trips_storage_usage_line(
    Object used,
    Object unit,
    Object limit,
    Object count,
  ) {
    return '$used $unit usados / limite $limit MB · $count viagens';
  }

  @override
  String get trips_sync_title => 'Catálogo do banco de dados';

  @override
  String get trips_sync_description =>
      'Reconcilia o índice de viagens com os arquivos de telemetria no disco.';

  @override
  String get trips_sync_button => 'Sincronizar banco de dados';

  @override
  String get trips_sync_running => 'Sincronizando…';

  @override
  String trips_sync_success(Object added, Object removed, Object total) {
    return 'Sincronizado com sucesso: +$added -$removed ($total no total)';
  }

  @override
  String get trips_sync_failed_generic => 'Falha na sincronização';

  @override
  String get trips_detail_summary_title => 'Resumo da viagem';

  @override
  String get trips_detail_distance => 'Distância';

  @override
  String get trips_detail_duration => 'Duração';

  @override
  String get trips_detail_energy => 'Energia';

  @override
  String get trips_detail_avg_speed => 'Vel. média';

  @override
  String get trips_detail_max_speed => 'Vel. máx.';

  @override
  String get trips_detail_soc => 'Carga';

  @override
  String get trips_detail_cost => 'Custo';

  @override
  String get trips_detail_ext_temp => 'Temp. externa';

  @override
  String get trips_detail_fuel_used => 'Combustível';

  @override
  String get trips_detail_fuel_cost => 'Custo de combustível';

  @override
  String get trips_detail_electric_cost => 'Custo de eletricidade';

  @override
  String get trips_detail_elev_gain => 'Ganho de altitude';

  @override
  String get trips_detail_scores_title => 'Pontuações de condução';

  @override
  String get trips_detail_unavailable => 'Detalhes da viagem indisponíveis';

  @override
  String get trips_detail_loading => 'Carregando viagem…';

  @override
  String trips_detail_route_points(Object count) {
    return '$count pontos GPS registrados';
  }

  @override
  String get rec_severity_critical => 'CRÍTICO';

  @override
  String get rec_severity_alert => 'ALERTA';

  @override
  String get location_loading_title => 'Carregando mapa';

  @override
  String get location_permission_missing_title =>
      'Permissão de localização necessária';

  @override
  String get location_permission_denied_title => 'Permissão negada';

  @override
  String get location_provider_disabled_title => 'GPS desativado';

  @override
  String get location_waiting_for_fix_title => 'Aguardando sinal de GPS';

  @override
  String get location_car_location_title => 'Localização do veículo';

  @override
  String get location_stale_title => 'Localização desatualizada';

  @override
  String get location_tile_failure_title => 'Mapa indisponível';

  @override
  String get location_tile_failure_subtitle => 'Rede indisponível';

  @override
  String get location_error_title => 'Erro de localização';

  @override
  String get location_action_grant => 'Conceder';

  @override
  String get location_action_retry => 'Tentar novamente';

  @override
  String get location_mode_auto => 'Automático';

  @override
  String get location_mode_light => 'Claro';

  @override
  String get location_mode_dark => 'Escuro';

  @override
  String get cd_recenter_on_car => 'Recentralizar no veículo';

  @override
  String get recording_lib_no_recordings_normal => 'Sem gravações normais';

  @override
  String get recording_lib_no_recordings_sentry => 'Sem eventos de vigilância';

  @override
  String get recording_lib_no_recordings_proximity =>
      'Sem eventos de proximidade';

  @override
  String recording_lib_camera_badge(Object arg1) {
    return 'C$arg1';
  }

  @override
  String get video_player_legend_person => 'pessoa';

  @override
  String get video_player_legend_car => 'carro';

  @override
  String get video_player_legend_bike => 'bicicleta';

  @override
  String get video_player_legend_motion => 'movimento';

  @override
  String get recording_lib_proximity_very_close => 'muito perto';

  @override
  String get recording_lib_proximity_close => 'perto';

  @override
  String get recording_lib_proximity_mid => 'médio';

  @override
  String get recording_lib_proximity_far => 'longe';

  @override
  String get surveillance_tab_general => 'Geral';

  @override
  String get surveillance_tab_detection => 'Detecção';

  @override
  String get surveillance_tab_recording => 'Gravação';

  @override
  String get surveillance_tab_storage => 'Armazenamento';

  @override
  String get surveillance_tab_advanced => 'Avançado';

  @override
  String get surveillance_general_title => 'Modo de vigilância';

  @override
  String get surveillance_general_enable => 'Ativar vigilância';

  @override
  String get surveillance_general_status => 'Status';

  @override
  String get surveillance_general_status_running => 'Em execução';

  @override
  String get surveillance_general_status_idle => 'Inativo';

  @override
  String get surveillance_general_events_today => 'Eventos hoje';

  @override
  String get surveillance_safe_locations_title => 'Locais seguros';

  @override
  String get surveillance_safe_locations_subtitle =>
      'A câmera não inicia ao estacionar aqui';

  @override
  String get surveillance_safe_locations_enable =>
      'Desativar em locais seguros';

  @override
  String get surveillance_safe_locations_empty =>
      'Ainda não há locais seguros adicionados';

  @override
  String get surveillance_safe_locations_add_current =>
      'Adicionar local atual como zona segura';

  @override
  String get surveillance_safe_locations_no_gps =>
      'Localização GPS não disponível';

  @override
  String surveillance_safe_locations_zone_label(Object arg1, Object arg2) {
    return '$arg1  (${arg2}m)';
  }

  @override
  String get surveillance_detection_title => 'Configurações de detecção';

  @override
  String get surveillance_detection_preset_label => 'Predefinição de ambiente';

  @override
  String get surveillance_preset_outdoor => 'Externo';

  @override
  String get surveillance_preset_garage => 'Garagem';

  @override
  String get surveillance_preset_street => 'Rua';

  @override
  String get surveillance_preset_custom => 'Personalizado';

  @override
  String surveillance_detection_sensitivity_label(Object arg1) {
    return 'Sensibilidade (1=rigorosa, 5=sensível): $arg1';
  }

  @override
  String get surveillance_detection_objects_label => 'Detectar objetos';

  @override
  String get surveillance_detection_object_person => 'pessoa';

  @override
  String get surveillance_detection_object_car => 'carro';

  @override
  String get surveillance_detection_object_bike => 'bicicleta';

  @override
  String get surveillance_recording_title => 'Gravação de eventos';

  @override
  String surveillance_recording_pre_label(Object arg1) {
    return 'Pré-gravação (segundos antes do evento): $arg1';
  }

  @override
  String surveillance_recording_post_label(Object arg1) {
    return 'Pós-gravação (segundos após o evento): $arg1';
  }

  @override
  String surveillance_seconds_value(Object arg1) {
    return '${arg1}s';
  }

  @override
  String get surveillance_storage_title => 'Armazenamento de vigilância';

  @override
  String get surveillance_storage_location_label => 'Local de armazenamento';

  @override
  String get surveillance_storage_internal => 'Interno';

  @override
  String get surveillance_storage_sd_card => 'Cartão SD';

  @override
  String get surveillance_storage_sd_card_na => 'Cartão SD (N/D)';

  @override
  String get surveillance_storage_limit_label =>
      'Limite de armazenamento — exclui os mais antigos automaticamente';

  @override
  String get surveillance_storage_usage_label => 'Uso do armazenamento';

  @override
  String get surveillance_storage_files_label => 'Arquivos';

  @override
  String surveillance_storage_usage(Object arg1, Object arg2) {
    return '$arg1 usados / limite $arg2';
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
  String get surveillance_storage_path_label => 'Caminho';

  @override
  String get surveillance_format_title => 'Formatar unidade externa';

  @override
  String get surveillance_format_warning =>
      'Apaga permanentemente TODOS os dados do cartão SD ou unidade USB.';

  @override
  String get surveillance_format_button => 'Formatar cartão SD/USB';

  @override
  String get surveillance_format_confirm =>
      'Toque novamente — TODOS os dados serão APAGADOS';

  @override
  String get surveillance_format_running => 'Formatando… aguarde';

  @override
  String get surveillance_dismiss => 'Dispensar';

  @override
  String get surveillance_sync_title => 'Catálogo do banco de dados';

  @override
  String get surveillance_sync_description =>
      'Concilia o índice de vigilância com os arquivos no disco.';

  @override
  String get surveillance_sync_button => 'Sincronizar banco de dados';

  @override
  String get surveillance_sync_running => 'Sincronizando…';

  @override
  String get surveillance_advanced_camera_title => 'Seleção de câmera';

  @override
  String get surveillance_advanced_camera_front => 'Frente';

  @override
  String get surveillance_advanced_camera_right => 'Direita';

  @override
  String get surveillance_advanced_camera_rear => 'Traseira';

  @override
  String get surveillance_advanced_camera_left => 'Esquerda';

  @override
  String get surveillance_advanced_ai_title => 'IA e dissuasão';

  @override
  String get surveillance_advanced_ai_detection => 'Detecção por IA';

  @override
  String get surveillance_advanced_night_mode => 'Modo noturno';

  @override
  String get surveillance_advanced_deterrent_label => 'Ação de dissuasão';

  @override
  String get surveillance_deterrent_silent => 'Silencioso';

  @override
  String get surveillance_deterrent_horn => 'Buzina';

  @override
  String get surveillance_deterrent_flash => 'Sinal de luzes';

  @override
  String get surveillance_apply_button => 'Aplicar alterações';

  @override
  String get surveillance_apply_failed => 'Falha ao salvar';

  @override
  String get dashboard_tor_bootstrapping => 'Conectando ao Tor…';

  @override
  String get dashboard_tor_help_tooltip => 'Como abrir este endereço';

  @override
  String get dashboard_tor_help_title => 'Abrir este endereço';

  @override
  String get dashboard_tor_help_android =>
      'Android: instale o Tor Browser pelo Google Play ou F-Droid, abra-o e cole o endereço.';

  @override
  String get dashboard_tor_help_ios =>
      'iPhone e iPad: instale o Onion Browser na App Store, abra-o e cole o endereço. O Tor Browser não está disponível no iOS.';

  @override
  String get dashboard_tor_help_desktop =>
      'Windows, macOS e Linux: baixe o Tor Browser em torproject.org, abra-o e cole o endereço.';

  @override
  String get dashboard_tor_help_password_note =>
      'A senha continua sendo necessária depois que a página carregar.';

  @override
  String get dashboard_tor_help_download_qr_label =>
      'Escaneie para a página de download do Tor Browser';

  @override
  String get dashboard_tor_help_close => 'Entendi';

  @override
  String get surveillance_general_battery_warning =>
      'O modo sentinela consome energia extra da bateria de 12V enquanto estiver ativo.';

  @override
  String get surveillance_general_camera_contention_warning =>
      'Outro aplicativo está usando a câmera neste momento.';

  @override
  String get pairing_title => 'Parear um dispositivo';

  @override
  String get pairing_scan_hint =>
      'Escaneie com o app BladeWatch no seu celular ou computador. O código funciona uma vez só.';

  @override
  String pairing_expires_in(String time) {
    return 'Expira em $time';
  }

  @override
  String get pairing_expired => 'Este código expirou.';

  @override
  String get pairing_new_code => 'Novo código';

  @override
  String get pairing_remote_note =>
      'O pareamento ativa o acesso remoto a este carro.';

  @override
  String get pairing_lan_title => 'Conexão direta nesta rede Wi-Fi';

  @override
  String get pairing_lan_body =>
      'Um dispositivo pareado na mesma rede Wi-Fi do carro se conecta diretamente e com criptografia, sem passar pela internet. Desativado até você ativar.';

  @override
  String get pairing_devices_title => 'Dispositivos pareados';

  @override
  String get pairing_devices_empty => 'Nenhum dispositivo pareado ainda.';

  @override
  String get pairing_remove => 'Remover';

  @override
  String pairing_remove_confirm_title(String name) {
    return 'Remover $name?';
  }

  @override
  String get pairing_remove_confirm_body =>
      'Ele perde o acesso na hora. Seus outros dispositivos continuam funcionando.';

  @override
  String get pairing_error =>
      'O serviço da câmera não respondeu. Tente de novo.';

  @override
  String get daemon_name_pear => 'Acesso remoto (Pear)';

  @override
  String get pear_status_reachable => 'Acessível de qualquer lugar';

  @override
  String get pear_status_unreachable =>
      'Inacessível: sem conexão com a rede Pear';

  @override
  String get pear_status_unknown => 'Acessibilidade desconhecida';

  @override
  String pear_devices_connected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos conectados',
      one: '$count dispositivo conectado',
      zero: 'Nenhum dispositivo conectado',
    );
    return '$_temp0';
  }

  @override
  String pear_last_connection(String time) {
    return 'Última conexão: $time';
  }

  @override
  String get pear_tile_off => 'Desligado';

  @override
  String get trips_cost_total => 'Custo total';

  @override
  String get trips_cost_no_rate =>
      'Defina uma tarifa de eletricidade nas configurações de viagens para ver os custos.';

  @override
  String get trips_cost_mixed_currency =>
      'As viagens têm custos em mais de uma moeda, por isso nenhum total é mostrado.';

  @override
  String dashboard_chip_gear(String gear) {
    return 'Marcha $gear';
  }

  @override
  String dashboard_chip_drive_mode(String mode) {
    return 'Modo: $mode';
  }

  @override
  String dashboard_chip_auto_hold(String state) {
    return 'Auto Hold: $state';
  }

  @override
  String get auto_hold_disabled => 'Desligado';

  @override
  String get auto_hold_enabled => 'Ligado';

  @override
  String get auto_hold_active => 'Segurando';
}
