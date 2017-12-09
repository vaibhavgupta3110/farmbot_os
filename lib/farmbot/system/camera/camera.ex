defmodule Farmbot.System.Camera do
  @moduledoc "Interface with Cameras connected to Farmbot."
  use GenStage

  @doc "Capture a frame from a camera"
  def frame(id \\ 0) do
    GenStage.call(__MODULE__, {:frame, id})
  end

  def detect_and_subscribe(id, pid) do
    spawn_link Farmbot.System.Camera.OpenCVHandler, :open_camera, [id, pid]
    # Farmbot.System.Camera.CameraSub.start_link
  end

  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    spawn_link __MODULE__, :detect_and_subscribe, [0, self()]
    {:producer, %{}, [dispatcher: GenStage.BroadcastDispatcher]}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_info({:image, camera, image}, state) when is_number(camera) and is_binary(image) do
    {:noreply, [{:image, camera, image}], Map.put(state, camera, image)}
  end

  def handle_call({:frame, id}, _, state) do
    {:reply, state[id], [], state}
  end
end
