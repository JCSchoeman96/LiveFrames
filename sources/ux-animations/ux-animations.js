// ===== 1. RECEIPT PRINTER =====
const printBtn = document.getElementById("printBtn");
const receiptPaper = document.getElementById("receiptPaper");
printBtn.addEventListener("click", () => {
  receiptPaper.classList.remove("printed");
  void receiptPaper.offsetWidth; // restart animation
  requestAnimationFrame(() => receiptPaper.classList.add("printed"));
});

// ===== 2. CARD FLIP =====
document.getElementById("flipScene").addEventListener("click", function () {
  this.classList.toggle("flipped");
});

// ===== 3. PARTICLES =====
const canvas = document.getElementById("particleCanvas");
const ctx = canvas.getContext("2d");
const particleStage = canvas.parentElement;
function sizeCanvas() {
  canvas.width = particleStage.clientWidth;
  canvas.height = particleStage.clientHeight;
}
sizeCanvas();
window.addEventListener("resize", sizeCanvas);

let particles = [];
const particleColors = ["#6c47f5", "#8768ff", "#14183a", "#c3d1f0", "#efe9ff"];

function spawnParticles(x, y) {
  for (let i = 0; i < 40; i++) {
    const angle = Math.random() * Math.PI * 2;
    const speed = 2 + Math.random() * 5;
    particles.push({
      x,
      y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed - 2,
      gravity: 0.15,
      size: 2 + Math.random() * 4,
      color: particleColors[Math.floor(Math.random() * particleColors.length)],
      life: 1,
      decay: 0.012 + Math.random() * 0.012
    });
  }
}

function animateParticles() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  particles.forEach((p) => {
    p.x += p.vx;
    p.y += p.vy;
    p.vy += p.gravity;
    p.life -= p.decay;
    ctx.globalAlpha = Math.max(p.life, 0);
    ctx.fillStyle = p.color;
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
    ctx.fill();
  });
  ctx.globalAlpha = 1;
  particles = particles.filter((p) => p.life > 0);
  requestAnimationFrame(animateParticles);
}
animateParticles();

document.getElementById("particleBtn").addEventListener("click", (e) => {
  const rect = particleStage.getBoundingClientRect();
  spawnParticles(rect.width / 2, rect.height / 2);
});

// ===== 4. SPRING PHYSICS =====
(function () {
  const knob = document.getElementById("springKnob");
  const track = knob.parentElement;
  let dragging = false;
  let pos = 0; // current x offset
  let velocity = 0;
  let target = 0;
  let animId = null;
  const stiffness = 0.18;
  const damping = 0.72;
  const maxX = () => track.clientWidth - 48 - 48; // track padding minus knob width

  function springStep() {
    const force = (target - pos) * stiffness;
    velocity = (velocity + force) * damping;
    pos += velocity;
    knob.style.transform = `translateX(${pos}px)`;
    if (Math.abs(velocity) > 0.05 || Math.abs(target - pos) > 0.05) {
      animId = requestAnimationFrame(springStep);
    } else {
      pos = target;
      knob.style.transform = `translateX(${pos}px)`;
      animId = null;
    }
  }

  function startDrag(clientX) {
    dragging = true;
    knob.dataset.startX = clientX;
    knob.dataset.startPos = pos;
    if (animId) cancelAnimationFrame(animId);
  }
  function moveDrag(clientX) {
    if (!dragging) return;
    const delta = clientX - parseFloat(knob.dataset.startX);
    let newPos = parseFloat(knob.dataset.startPos) + delta;
    newPos = Math.max(0, Math.min(maxX(), newPos));
    pos = newPos;
    knob.style.transform = `translateX(${pos}px)`;
  }
  function endDrag() {
    if (!dragging) return;
    dragging = false;
    target = 0; // spring back to start
    velocity = 0;
    animId = requestAnimationFrame(springStep);
  }

  knob.addEventListener("mousedown", (e) => startDrag(e.clientX));
  window.addEventListener("mousemove", (e) => moveDrag(e.clientX));
  window.addEventListener("mouseup", endDrag);

  knob.addEventListener("touchstart", (e) => startDrag(e.touches[0].clientX), {
    passive: true
  });
  window.addEventListener("touchmove", (e) => moveDrag(e.touches[0].clientX), {
    passive: true
  });
  window.addEventListener("touchend", endDrag);
})();

// ===== 5. PHOTO STACK =====
(function () {
  const stage = document.getElementById("stackStage");
  const cardsData = [
    {
      tag: "Tip 01",
      text:
        "Match easing to weight — heavier elements settle slower than they accelerate."
    },
    {
      tag: "Tip 02",
      text:
        "Never animate two properties with different easing curves at once, it reads as broken."
    },
    {
      tag: "Tip 03",
      text: "Motion should explain a state change, not decorate an idle one."
    },
    {
      tag: "Tip 04",
      text:
        "200–400ms covers most UI transitions. Beyond that, it feels like waiting."
    },
    {
      tag: "Tip 05",
      text: "If you can't justify the animation in one sentence, cut it."
    }
  ];

  let deck = cardsData.map((d, i) => ({ ...d, id: i }));

  function render() {
    stage.innerHTML = "";
    deck.forEach((card, i) => {
      const el = document.createElement("div");
      el.className = "stack-card";
      const depth = deck.length - 1 - i;
      el.style.zIndex = i;
      el.style.transform = `translateY(${depth * 6}px) scale(${
        1 - depth * 0.04
      }) rotate(${depth === 0 ? 0 : depth % 2 === 0 ? -3 : 3}deg)`;
      el.style.opacity = depth > 2 ? 0 : 1;
      el.innerHTML = `<span class="tag">${card.tag}</span>${card.text}`;
      if (i === deck.length - 1) attachDrag(el, card);
      stage.appendChild(el);
    });
  }

  function attachDrag(el, card) {
    let startX = 0,
      currentX = 0,
      dragging = false;

    function down(x) {
      dragging = true;
      startX = x;
      el.style.transition = "none";
    }
    function move(x) {
      if (!dragging) return;
      currentX = x - startX;
      const rotate = currentX / 12;
      el.style.transform = `translateX(${currentX}px) rotate(${rotate}deg)`;
    }
    function up() {
      if (!dragging) return;
      dragging = false;
      el.style.transition =
        "transform 0.35s cubic-bezier(0.2, 0.8, 0.2, 1), opacity 0.35s ease";
      if (Math.abs(currentX) > 90) {
        el.style.transform = `translateX(${
          currentX > 0 ? 500 : -500
        }px) rotate(${currentX / 12}deg)`;
        el.style.opacity = "0";
        setTimeout(() => {
          deck.push(deck.shift());
          render();
        }, 320);
      } else {
        el.style.transform = "translateX(0) rotate(0)";
      }
      currentX = 0;
    }

    el.addEventListener("mousedown", (e) => down(e.clientX));
    window.addEventListener("mousemove", (e) => move(e.clientX));
    window.addEventListener("mouseup", up);
    el.addEventListener("touchstart", (e) => down(e.touches[0].clientX), {
      passive: true
    });
    window.addEventListener("touchmove", (e) => move(e.touches[0].clientX), {
      passive: true
    });
    window.addEventListener("touchend", up);
  }

  render();
})();

// ===== 6. COIN FLIP =====
(function () {
  const coin = document.getElementById("coin");
  const btn = document.getElementById("flipCoinBtn");
  btn.addEventListener("click", () => {
    coin.classList.remove("spinning", "result-tails");
    void coin.offsetWidth;
    const isTails = Math.random() > 0.5;
    coin.classList.add("spinning");
    setTimeout(() => {
      coin.classList.remove("spinning");
      if (isTails) coin.classList.add("result-tails");
    }, 1100);
  });
})();

// ===== 7. ORBIT =====
(function () {
  const stage = document.getElementById("orbitStage");
  const icons = [
    {
      color: "#e34c26",
      path:
        "M20 4 L24 30 L16 33 L8 30 L6 24 L10 24 L11 27 L16 29 L21 27 L21.5 22 L9 22 L8.5 18 L21.8 18 L22.2 14 L8 14 L7.5 10 L24.5 10 L24 4 Z"
    }, // html-ish
    { color: "#264de4", path: "M8 4 L24 4 L23 22 L16 25 L9 22 Z" }, // css-ish
    { color: "#f0db4f", path: "M6 6 H26 V26 H6 Z" }, // js-ish
    {
      color: "#6c47f5",
      path: "M16 4 L28 12 L28 24 L16 32 L4 24 L4 12 Z"
    } // generic node
  ];
  const radii = [56, 78, 100, 122];
  const items = [];

  icons.forEach((icon, i) => {
    const ring = document.createElement("div");
    const r = radii[i];
    ring.className = "orbit-ring";
    ring.style.width = r * 2 + "px";
    ring.style.height = r * 2 + "px";
    ring.style.marginLeft = -r + "px";
    ring.style.marginTop = -r + "px";
    stage.appendChild(ring);

    const item = document.createElement("div");
    item.className = "orbit-item";
    item.innerHTML = `<svg viewBox="0 0 32 32"><path d="${icon.path}" fill="${icon.color}"/></svg>`;
    stage.appendChild(item);
    items.push({
      el: item,
      radius: r,
      angle: ((Math.PI * 2) / icons.length) * i,
      speed: 0.01 - i * 0.0015,
      dir: -1
    });
  });

  function animateOrbit() {
    items.forEach((it) => {
      it.angle += it.speed * it.dir;
      const x = Math.cos(it.angle) * it.radius;
      const y = Math.sin(it.angle) * it.radius;
      it.el.style.transform = `translate(${x}px, ${y}px)`;
    });
    requestAnimationFrame(animateOrbit);
  }
  animateOrbit();
})();

// ===== 8. TICKER =====
(function () {
  const track = document.getElementById("tickerTrack");
  const skills = [
    "WordPress",
    "Core Web Vitals",
    "WooCommerce",
    "SEO",
    "JavaScript",
    "CSS Architecture",
    "AI Integration",
    "Performance"
  ];
  const full = [...skills, ...skills]; // duplicate for seamless loop
  track.innerHTML = full
    .map((s) => `<span class="ticker-chip">${s}</span>`)
    .join("");
})();

// ===== 9. REVEAL =====
document.getElementById("revealBtn").addEventListener("click", () => {
  const block = document.getElementById("revealBlock");
  block.classList.remove("shown");
  void block.offsetWidth;
  requestAnimationFrame(() => block.classList.add("shown"));
});

// ===== 10. DRAW =====
document.getElementById("drawBtn").addEventListener("click", () => {
  const svg = document.getElementById("drawSvg");
  svg.classList.remove("animate");
  void svg.offsetWidth;
  requestAnimationFrame(() => svg.classList.add("animate"));
});
