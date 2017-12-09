defmodule Farmbot.System.Camera.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    workers = [
      worker(Farmbot.System.Camera, [])
    ]
    supervise(workers, strategy: :one_for_one)
  end
end
