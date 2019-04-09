defmodule MicroServerTest.LuaScript.ClassTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
    -- Meta class
    Shape = {area = 0}

    -- 基础类方法 new
    function Shape:new (o,side)
      -- 没有就创建
      o = o or {}
      setmetatable(o, self)
      self.__index = self
      side = side or 0
      self.area = side*side;
      return o
    end

    -- 基础类方法 getArea
    function Shape:getArea ()
      return self.area
    end

    function on_http(ticket, ...)
      -- 创建对象
      myshape = Shape:new(nil,10)

      return myshape:getArea()
    end

    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "class" do
    [response] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{}})
    assert response === 100.0
  end

end
