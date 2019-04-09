defmodule MicroServer.ServerLogConst do
  defmacro create do
    quote do
      @manual_shutdown 1001
      @normal_shutdown 1002
      @unknow_shutdown 1003
      @no_server_id_exist_in_database 1004
      @start_up 2001
      @hot_update 2002
      @lua_script_load_error 3001
      @lua_script_run_error 3002
    end
  end
end
