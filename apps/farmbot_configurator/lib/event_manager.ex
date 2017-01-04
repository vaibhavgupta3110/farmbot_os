defmodule Farmbot.Configurator.EventManager do
  def start_link() do
    GenEvent.start_link(name: __MODULE__)
  end

  def send_socket(event) do
    GenEvent.notify(__MODULE__, event)
  end
end
