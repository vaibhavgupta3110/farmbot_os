defmodule Farmbot.BotState.Transport.HTTP.Router do
  @moduledoc "Underlying router for HTTP Transport."

  use Plug.Router

  alias Farmbot.BotState.Transport.HTTP
  alias HTTP.AuthPlug

  use Plug.Debugger, otp_app: :farmbot
  plug Plug.Logger, log: :debug
  plug AuthPlug, env: Mix.env()
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart, :json], json_decoder: Poison)
  plug :match
  plug :dispatch

  get "/api/v1/bot/state" do
    data = Farmbot.BotState.force_state_push() |> Poison.encode!()
    send_resp conn, 200, data
  end

  post "/api/v1/celery_script" do
    with {:ok, _, conn} <- conn |> read_body(),
         {:ok, ast} <- Farmbot.CeleryScript.AST.decode(conn.params)
    do
      case Farmbot.CeleryScript.execute(ast) do
        {:ok, _} -> send_resp(conn, 200, "ok")
        {:error, reason} when is_binary(reason) or is_atom(reason) -> send_resp conn, 500, reason
        {:error, reason} -> send_resp conn, 500, "#{inspect reason}"
      end
    else
      err -> send_resp conn, 500, "#{inspect err}"
    end
  end

  get "/api/v1/camera/0/latest" do
    {:ok, base64_image} = Farmbot.System.Camera.frame()
    image = Base.decode64!(base64_image)
    send_resp(conn, 200, image)
  end

  @stream_boundry "w58EW1cEpjzydSCq"

  get "/api/v1/camera/0/stream" do
    conn = put_resp_header(conn, "content-type", "multipart/x-mixed-replace; boundary=#{@stream_boundry}")
    conn = send_chunked(conn, 200)
    send_picture(conn)
    conn
  end

  defp send_picture(conn) do
    image = Farmbot.System.Camera.frame() |> elem(1) |> Base.decode64!()
    size = byte_size(image)
    header = "------#{@stream_boundry}\r\nContent-Type: \"image/jpeg\"\r\nContent-length: #{size}\r\n\r\n"
    footer = "\r\n"
    with {:ok, conn} <- chunk(conn, header),
         {:ok, conn} <- chunk(conn, image),
         {:ok, conn} <- chunk(conn, footer)
    do
      send_picture(conn)
    end
    conn
  end

  # THIS IS A LEGACY ENDPOINT
  post "/celery_script" do
    loc = "/api/v1/celery_script"
    conn = put_resp_header(conn, "location", loc)
    send_resp(conn, 300, loc)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
