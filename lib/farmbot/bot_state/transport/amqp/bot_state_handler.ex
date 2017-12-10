defmodule Farmbot.BotState.Transport.AMQP.BotStateHandler do
  use Farmbot.BotState.Transport.AMQP.Socket, queue_sub_name: "bot_state", subscribe_to: Farmbot.BotState
  use Farmbot.Logger

  def handler_init(device, chan, queue_name) do
    :ok = AMQP.Queue.bind(chan, queue_name, @exchange, [routing_key: "bot.#{device}.from_clients"])
    :ok = AMQP.Queue.bind(chan, queue_name, @exchange, [routing_key: "bot.#{device}.sync.#"])
    {:ok, %{}}
  end

  def handle_data({:emit, ast}, bot, chan, state) do
    emit_cs(chan, bot, ast)
    {:ok, state}
  end

  def handle_data(bot_state_msg, bot, chan, state) do
    json = Poison.encode!(bot_state_msg)
    :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.status", json
    {:ok, state}
  end

  def handle_deliver(payload, device, _chan, key, state) do
    route = String.split(key, ".")
    case route do
      ["bot", ^device, "from_clients"] ->
        handle_celery_script(payload, state)
        {:ok, state}
      ["bot", ^device, "sync", resource, _]
      when resource in ["Log", "User", "Image", "WebcamFeed"] ->
        {:ok, state}
      ["bot", ^device, "sync", resource, id] ->
        handle_sync_cmd(resource, id, payload, state)
      ["bot", ^device, "logs"]        -> {:ok, state}
      ["bot", ^device, "status"]      -> {:ok, state}
      ["bot", ^device, "from_device"] -> {:ok, state}
      _ ->
        Logger.warn 3, "got unknown routing key: #{key}"
        {:ok, state}
    end
  end

  defp handle_sync_cmd(kind, id, payload, state) do
    mod = Module.concat(["Farmbot", "Repo", kind])
    if Code.ensure_loaded?(mod) do
      %{"body" => body, "args" => %{"label" => uuid}} = Poison.decode!(payload, as: %{"body" => struct(mod)})
      Farmbot.Repo.register_sync_cmd(String.to_integer(id), kind, body)

      if Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "auto_sync") do
        Farmbot.Repo.flip()
      end

      Farmbot.CeleryScript.AST.Node.RpcOk.execute(%{label: uuid}, [], struct(Macro.Env))
    else
      Logger.warn 2, "Unknown syncable: #{mod}: #{inspect Poison.decode!(payload)}"
    end
    {:ok, state}
  end

  defp handle_celery_script(payload, _state) do
    case Farmbot.CeleryScript.AST.decode(payload) do
      {:ok, ast} -> spawn Farmbot.CeleryScript, :execute, [ast]
      _ -> :ok
    end
  end

  defp emit_cs(chan, bot, cs) do
    with {:ok, map} <- Farmbot.CeleryScript.AST.encode(cs),
         {:ok, json} <- Poison.encode(map)
    do
      :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.from_device", json
    end
  end
end
