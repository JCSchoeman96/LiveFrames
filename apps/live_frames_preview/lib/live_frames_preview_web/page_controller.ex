defmodule LiveFramesPreviewWeb.PageController do
  use LiveFramesPreviewWeb, :controller

  @home_html """
  <!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>LiveFrames Preview</title>
    </head>
    <body>
      <main>
        <h1>LiveFrames Preview</h1>
        <p>The Phoenix preview foundation is running.</p>
        <p>Compiler and catalogue phases are intentionally not enabled yet.</p>
      </main>
    </body>
  </html>
  """

  def home(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, @home_html)
  end

  def health(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok\n")
  end
end
