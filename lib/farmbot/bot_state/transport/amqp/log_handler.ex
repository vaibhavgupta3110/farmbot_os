# defmodule Farmbot.BotState.Transport.AMQP.LogHandler do
#   # use Farmbot.BotState.Transport.AMQP.Socket, queue_sub_name: "bot_state", subscribe_to: Farmbot.Logger
#
#   def handler_init(device, chan, queue_name) do
#     {:ok, %{}}
#   end
#
#
#   def handle_log_events(logs, state) do
#     for %Farmbot.Log{} = log <- logs do
#       if should_log?(log.module, log.verbosity) do
#         location_data = Map.get(state.state_cache || %{}, :location_data, %{position: %{x: -1, y: -1, z: -1}})
#         meta = %{
#           type: log.level,
#           x: nil, y: nil, z: nil,
#           verbosity: log.verbosity,
#           major_version: log.version.major,
#           minor_version: log.version.minor,
#           patch_version: log.version.patch,
#         }
#         log_without_pos = %{created_at: log.time, meta: meta, channels: log.meta[:channels] || [], message: log.message}
#         log = add_position_to_log(log_without_pos, location_data)
#         push_bot_log(state.chan, state.bot, log)
#       end
#     end
#
#     {:noreply, [], state}
#   end
#
#   defp push_bot_log(chan, bot, log) do
#     json = Poison.encode!(log)
#     :ok = AMQP.Basic.publish chan, @exchange, "bot.#{bot}.logs", json
#   end
#
#   defp add_position_to_log(%{meta: meta} = log, %{position: pos}) do
#     new_meta = Map.merge(meta, pos)
#     %{log | meta: new_meta}
#   end
# end
