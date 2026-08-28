defmodule LiveFramesPreview.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: LiveFramesPreview.PubSub},
      LiveFramesPreviewWeb.Endpoint
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: LiveFramesPreview.Supervisor
    )
  end
end
