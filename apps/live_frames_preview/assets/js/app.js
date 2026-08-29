import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document.querySelector("meta[name='csrf-token']");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken?.getAttribute("content") }
});

liveSocket.connect();
window.liveSocket = liveSocket;
