defmodule Farmbot.System.Camera.OpenCVHandler do
  def open_camera(pid) do
    port = Port.open({:spawn, "c_src/fb_jpg_stream/fb_jpg_stream"}, [:binary])
    handle_port(port, %{buffer: <<>>, pid: pid})
  end

  def handle_port(port, state) do
    receive do
      {_port, {:data, <<"\n">>}} ->
        send state.pid, {:image, "0", state.buffer}
        handle_port port, %{state | buffer: <<>>}
      {_port, {:data, data}} ->
        handle_port port, %{state | buffer: state.buffer <> data}
      stuff ->
        exit(stuff)
    end
  end
end
