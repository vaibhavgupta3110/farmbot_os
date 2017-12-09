defmodule Farmbot.System.Camera.OpenCVHandler do
  def open_camera(pid) do
    streamer = Path.join(:code.priv_dir(:farmbot), "fb_jpg_stream")
    port = Port.open({:spawn_executable, streamer}, [:binary, {:args, [streamer]}])
    handle_port(port, %{buffer: <<>>, pid: pid})
  end

  def handle_port(port, state) do
    receive do
      {_port, {:data, data}} ->
        {buffer, images} = String.split(state.buffer <> data, "\n") |> List.pop_at(-1)
        for image <- images do
          unless match?(<<>>, image) do
            send state.pid, {:image, "0", image}
          end
        end
        handle_port port, %{state | buffer: buffer}
      stuff ->
        exit(stuff)
    end
  end
end
