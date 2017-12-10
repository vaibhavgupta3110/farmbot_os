defmodule Farmbot.BotState.Transport.AMQP.Socket do
  defmacro __using__(opts) do
    subscribe_to = Keyword.fetch!(opts, :subscribe_to)
    queue_sub_name = Keyword.fetch!(opts, :queue_sub_name)
    quote do
      use GenStage
      use AMQP
      alias Farmbot.System.ConfigStorage

      @exchange "amq.topic"

      @doc false
      def start_link do
        GenStage.start_link(__MODULE__, [], [name: __MODULE__])
      end

      # GenStage callbacks

      defmodule State do
        @moduledoc false
        defstruct [:conn, :chan, :queue_name, :bot, :handler_state]
      end

      def init([]) do
        token = ConfigStorage.get_config_value(:string, "authorization", "token")
        with {:ok, %{bot: device, mqtt: mqtt_server, vhost: vhost}} <- Farmbot.Jwt.decode(token),
             {:ok, conn} <- AMQP.Connection.open([host: mqtt_server, username: device, password: token, virtual_host: vhost || "/"]),
             {:ok, chan} <- AMQP.Channel.open(conn),
             queue_name  <- Enum.join([device, UUID.uuid1(), unquote(queue_sub_name)], "-"),
             :ok         <- AMQP.Basic.qos(chan, []),
             {:ok, _}    <- AMQP.Queue.declare(chan, queue_name, [auto_delete: true]),
             {:ok, _tag} <- AMQP.Basic.consume(chan, queue_name),
             {:ok, handler_state} <- handler_init(device, chan, queue_name),
             state       <- struct(State, [conn: conn, chan: chan, queue_name: queue_name, bot: device, handler_state: handler_state])
        do
          # Logger.success(3, "Connected to real time services.")
          {:consumer, state, subscribe_to: [unquote(subscribe_to)]}
        else
          {:error, {:auth_failure, msg}} = fail ->
            Farmbot.System.factory_reset(msg)
            {:stop, fail}
          {:error, reason} ->
            :ignore
        end
      end

      def handle_events(events, _from, state) do
        new_state = Enum.reduce(events, state.handler_state, fn(event, handler_state) ->
          {:ok, new_handler_state} = handle_data(event, state.bot, state.chan, handler_state)
          new_handler_state
        end)
        {:noreply, [], %{state | handler_state: new_state}}
      end

      # Confirmation sent by the broker after registering this process as a consumer
      def handle_info({:basic_consume_ok, _}, state) do
        {:noreply, [], state}
      end

      # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
      def handle_info({:basic_cancel, _}, state) do
        {:stop, :normal, state}
      end

      # Confirmation sent by the broker to the consumer process after a Basic.cancel
      def handle_info({:basic_cancel_ok, _}, state) do
        {:noreply, [], state}
      end

      def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
        {:ok, new_handler_state} = handle_deliver(payload, state.bot, state.chan, key, state.handler_state)
        {:noreply, [], %{state | handler_state: new_handler_state}}
      end

    end

  end
end
