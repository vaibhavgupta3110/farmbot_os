defmodule Farmbot.System.Camera.OpenCVHandler do
  use Farmbot.Logger

  def open_camera(id, pid) do
    streamer = Path.join(:code.priv_dir(:farmbot), "fb_jpg_stream")
    port = Port.open({:spawn_executable, streamer}, [:exit_status, :binary, {:args, [to_string(id)]}])
    res = handle_port(port, %{buffer: <<>>, pid: pid, camera_id: id})
    exit(res)
  end

  def handle_port(port, state) do
    receive do
      {_port, {:data, data}} ->
        {buffer, images} = String.split(state.buffer <> data, "\n") |> List.pop_at(-1)
        for image <- images do
          unless match?(<<>>, image) do
            send state.pid, {:image, state.camera_id, image}
          end
        end
        handle_port port, %{state | buffer: buffer}
      unexpected ->
        Logger.error 1, "Camera handler #{state.camera_id} Exiting: #{inspect unexpected}"
        exit(unexpected)
    end
  end
end
