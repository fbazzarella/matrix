input bool matrix_global_async               = false;
input bool matrix_global_print_data_raw      = false;
input bool matrix_global_print_data_compiled = false;
input bool matrix_global_dump_data_raw       = true;
input bool matrix_global_dump_data_compiled  = true;

datetime   matrix_global_time_initialization = TimeTradeServer();
bool       matrix_global_time_activity_flag  = false;
int        matrix_global_time_activity_count = 0,
           matrix_global_parameters_count    = 0;
