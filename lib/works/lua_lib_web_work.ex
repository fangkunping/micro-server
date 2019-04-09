defmodule MicroServer.LuaLibWebWork do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:http, uri, method, params}, _from, state) do
    # result = get_http(uri, method, params)
    response =
      case method do
        :get ->
          HTTPoison.request(:get, uri)

        :post ->
          HTTPoison.request(
            :post,
            uri,
            {:form, params},
            [{"Accept", "application/x-www-form-urlencoded"}]
          )
      end

    result =
      case response do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          body

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          "404"

        {:error, %HTTPoison.Error{}} ->
          nil

        _ ->
          nil
      end

    {:reply, result, state}
  end

  # 从远程uri 获取信息
  # ("www.google.com", :get, %{a: 10})
  def get_http(uri) do
    get_http(uri, :get, nil)
  end

  def get_http(uri, method) do
    get_http(uri, method, nil)
  end

  def get_http(uri, method, params) do
    uri =
      if uri =~ "://" do
        uri
      else
        "http://#{uri}"
      end

    do_get_http(uri, method, params)
  end

  defp do_get_http(uri, :get, nil) do
    "curl -s --connect-timeout 5 -m 5  \"#{uri}\""
    |> KunERAUQS.D0_f.runOsCommand()
  end

  defp do_get_http(uri, :get, params) do
    "curl -s --connect-timeout 5 -m 5 \"#{uri}?#{URI.encode_query(params)}\""
    |> KunERAUQS.D0_f.runOsCommand()
  end

  defp do_get_http(uri, :post, params) do
    tmp_folder = Application.get_env(:micro_server, :tmp_folder)
    post_tmp_file = "#{tmp_folder}post_data_#{Ecto.UUID.generate()}.txt"
    File.write(post_tmp_file, URI.encode_query(params))

    "curl -s --connect-timeout 5 -m 5 -d \"@#{post_tmp_file}\" \"#{uri}\""
    |> KunERAUQS.D0_f.runOsCommand()
  end
end
