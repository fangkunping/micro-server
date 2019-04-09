defmodule MicroServer.LuaConst do
  defmacro create do
    quote do
      @default_function ~s/
      -- 载入模块函数
      function require()
      end
      function cache1_table()
      end
      function cache1_def_query()
      end
      /
      @const_http 1
      @const_websocket 2
      # 达到当前等级的vip限制, 例如, http_get vip1 只能 每两秒访问一次, 如果在短时间连续访问, 就会产生 vip limit
      @lib_vip_limit "vip limit"
      # 一般是系统某个缓冲池满了的情况, 例如 http_get 的缓冲池满, 就会得到这个信息
      @lib_system_limit "system limit"

      @script_split "-- S_S_Split &*(W:"
    end
  end
end
