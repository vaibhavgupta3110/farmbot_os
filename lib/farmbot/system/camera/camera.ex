defmodule Farmbot.System.Camera do
  @moduledoc "Interface with Cameras connected to Farmbot."
  use GenStage
  use Farmbot.Logger

  @doc "Capture a frame from a camera"
  def frame(id \\ 0) do
    GenStage.call(__MODULE__, {:frame, id})
  end

  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:producer, do_detect(Path.wildcard("/dev/video*")), [dispatcher: GenStage.BroadcastDispatcher]}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_info({:image, camera, image}, state) when is_number(camera) and is_binary(image) do
    if camera in Map.keys(state) do
      {:noreply, [{:image, camera, image}], %{state | camera => %{state[camera] | image: image}}}
    else
      {:noreply, [], state}
    end
  end

  def handle_info({:DOWN, _ref, :process, dead_pid, _}, state) do
    Logger.error 1, "Camera handler exit."
    down = Enum.find_value(state, fn({key, %{handler: {pid, _}}}) ->
      if dead_pid == pid do
        key
      end
    end)
    {:noreply, [], Map.delete(state, down)}
  end

  def handle_call({:frame, id}, _, state) do
    if id in Map.keys(state) do
      {:reply, {:ok, state[id].image}, [], state}
    else
      {:reply, {:error, :no_camera}, state}
    end
  end

  defp do_detect(cameras, acc \\ %{})
  defp do_detect([path | rest], acc) do
    id = String.split(path, "video") |> List.last() |> String.to_integer
    handler = spawn_monitor(Farmbot.System.Camera.OpenCVHandler, :open_camera, [id, __MODULE__])
    acc = case handler do
      {pid, ref} when is_pid(pid) and is_reference(ref) ->
        Map.put(acc, id, %{handler: handler, image: nil})
      err ->
        Logger.error 1, "Failed to start camera handler: #{inspect err}"
        acc
    end
    do_detect(rest, acc)
  end

  defp do_detect([], acc), do: acc
end
