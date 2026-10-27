import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/live_frames";

const csrfToken = document.querySelector("meta[name='csrf-token']");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken?.getAttribute("content") },
  hooks: { ...colocatedHooks }
});

liveSocket.connect();
window.liveSocket = liveSocket;
