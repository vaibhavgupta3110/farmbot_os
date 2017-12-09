defmodule Farmbot.System.Camera.CameraSub do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:consumer, [true], subscribe_to: [Farmbot.System.Camera]}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_events(images, _, _) do
    require IEx; IEx.pry

    {:noreply, [], [false]}
  end

end
