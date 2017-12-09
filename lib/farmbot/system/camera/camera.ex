defmodule Farmbot.System.Camera do
  use GenStage

  def detect_and_subscribe(pid) do
    spawn_link Farmbot.System.Camera.OpenCVHandler, :open_camera, [pid]
  end

  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    spawn_link __MODULE__, :detect_and_subscribe, [self()]
    {:producer, [], [dispatcher: GenStage.BroadcastDispatcher]}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_info({:image, camera, image}, state) do
    {:noreply, [{:image, camera, image}], state}
  end
end
