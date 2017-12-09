defmodule Farmbot.System.Camera.CameraSub do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:consumer, [], subscribe_to: [Farmbot.System.Camera]}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_events(images, _, state) do
    for {:image, _, image} <- images do
      # require IEx; IEx.pry
      jpg = Base.decode64!(image)
      File.write("blah.jpg", jpg)
    end
    {:noreply, [], state}
  end

end
