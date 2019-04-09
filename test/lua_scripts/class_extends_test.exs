defmodule MicroServerTest.LuaScript.ClassExtendsTest do
  use MicroServerTest.MyCase, async: false

  setup_all do
    lua_script = ~s|
    -- Meta class
    Shape = {area = 0}

    -- 基础类方法 new
    function Shape:new (o,side)
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



    Square = Shape:new()
    -- 派生类方法 new
    function Square:new (o,side)
      o = o or Shape:new(o,side)
      setmetatable(o, self)
      self.__index = self
      return o
    end

    -- 派生类方法 getArea
    function Square:getArea ()
      return self.area
    end



    Rectangle = Shape:new()
    -- 派生类方法 new
    function Rectangle:new (o,length,breadth)
      o = o or Shape:new(o)
      setmetatable(o, self)
      self.__index = self
      self.area = length * breadth
      return o
    end

    -- 派生类方法 getArea
    function Rectangle:getArea ()
      return self.area
    end

    local action = {}
    action.shape = function()
      -- 创建对象
      local myshape = Shape:new(nil,10)
      return myshape:getArea()
    end

    action.square = function()
      -- 创建对象
      local mysquare = Square:new(nil,12)
      return mysquare:getArea()
    end

    action.rectangle = function()
      -- 创建对象
      local myrectangle = Rectangle:new(nil,10,20)
      return myrectangle:getArea()
    end

    function on_http(ticket, message)
      return action[message.c]()
    end

    |
    MicroServer.Repo.query!(~s/update `scripts` set `content` = '#{lua_script}' where id = 1/)
    start_server()
    :ok
  end

  test "shape" do
    [response] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c"=>"shape"}})
    assert response === 100.0
  end

  test "square" do
    [response] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c"=>"square"}})
    assert response === 144.0
  end

  test "rectangle" do
    [response] = MicroServer.ServerUtility.call(@server_id, {:lua_event, :on_http, %{"c"=>"rectangle"}})
    assert response === 200.0
  end

end
