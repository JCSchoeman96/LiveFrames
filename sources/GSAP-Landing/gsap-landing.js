gsap.registerPlugin(ScrollTrigger);

// Initial states
gsap.set(".nav", { opacity: 0, y: -20 });
gsap.set(".headline .word > span", { y: "105%" });
gsap.set("#inlineImg, #ideaPill", { scale: 0 });
gsap.set(".col-left > *, .col-right > *", { opacity: 0, y: 30 });
gsap.set(".big-image", { opacity: 0, y: 40, scale: 0.95 });
gsap.set(".try-pill-wrap", { opacity: 0, y: -20 });
gsap.set(".sphere", { scale: 0, opacity: 0 });
gsap.set(".feat-card, .cta-inner", { opacity: 0 });

// ============================================================
// INTRO TIMELINE
// ============================================================
const intro = gsap.timeline({ defaults: { ease: "power3.out" } });
intro
  .to(".nav", { opacity: 1, y: 0, duration: 0.8 }, 0.1)
  .to(".line-1 .word > span", { y: "0%", duration: 0.9, stagger: 0.1 }, 0.3)
  .to(".line-2 .word > span", { y: "0%", duration: 0.9 }, 0.55)
  .to("#inlineImg", { scale: 1, duration: 0.9, ease: "back.out(1.6)" }, 0.5)
  .to("#ideaPill", { scale: 1, duration: 0.9, ease: "back.out(1.6)" }, 0.7)
  .to(".line-3 .word > span", { y: "0%", duration: 0.9, stagger: 0.1 }, 0.75)
  .to(
    ".big-image",
    { opacity: 1, y: 0, scale: 1, duration: 1.1, ease: "back.out(1.3)" },
    1.0
  )
  .to(
    ".sphere",
    {
      scale: 1,
      opacity: 1,
      duration: 0.8,
      stagger: 0.05,
      ease: "back.out(1.6)"
    },
    1.2
  )
  .to(
    ".try-pill-wrap",
    { opacity: 1, y: 0, duration: 0.7, ease: "back.out(1.6)" },
    1.4
  )
  .to(".col-left > *", { opacity: 1, y: 0, duration: 0.8, stagger: 0.12 }, 1.3)
  .to(
    ".col-right > *",
    { opacity: 1, y: 0, duration: 0.8, stagger: 0.12 },
    1.4
  );

// ============================================================
// CONTINUOUS: inline img + idea pill + spheres bob
// ============================================================
gsap.to("#inlineImg", {
  y: "+=6",
  rotation: 2,
  duration: 2.8,
  delay: 1.8,
  ease: "sine.inOut",
  yoyo: true,
  repeat: -1
});
gsap.to("#ideaPill", {
  y: "+=5",
  rotation: -1.5,
  duration: 3.2,
  delay: 2.0,
  ease: "sine.inOut",
  yoyo: true,
  repeat: -1
});
document.querySelectorAll(".sphere").forEach((sp, i) => {
  gsap.to(sp, {
    y: `+=${5 + (i % 3) * 3}`,
    x: `+=${(i % 2 === 0 ? 1 : -1) * 4}`,
    rotation: `+=${i % 2 === 0 ? 3 : -3}`,
    duration: 3.5 + (i % 3) * 0.5,
    delay: 2 + i * 0.1,
    ease: "sine.inOut",
    yoyo: true,
    repeat: -1
  });
});

// ============================================================
// INLINE BADGE HOVER
// ============================================================
document.getElementById("inlineImg").addEventListener("mouseenter", (e) => {
  gsap.to(e.target, {
    scale: 1.08,
    rotation: 4,
    duration: 0.4,
    ease: "back.out(1.6)"
  });
});
document.getElementById("inlineImg").addEventListener("mouseleave", (e) => {
  gsap.to(e.target, {
    scale: 1,
    rotation: 0,
    duration: 0.6,
    ease: "elastic.out(1, 0.6)"
  });
});
document.getElementById("ideaPill").addEventListener("mouseenter", (e) => {
  gsap.to(e.currentTarget, {
    scale: 1.06,
    rotation: -3,
    duration: 0.4,
    ease: "back.out(1.6)"
  });
  gsap.to(e.currentTarget.querySelector(".leaf"), {
    rotation: 360,
    duration: 0.8,
    ease: "power2.inOut"
  });
});
document.getElementById("ideaPill").addEventListener("mouseleave", (e) => {
  gsap.to(e.currentTarget, {
    scale: 1,
    rotation: 0,
    duration: 0.6,
    ease: "elastic.out(1, 0.6)"
  });
});

// ============================================================
// MOUSE PARALLAX ON BIG IMAGE SPHERES
// ============================================================
const bigImg = document.getElementById("bigImage");
let mx = 0,
  my = 0,
  tx = 0,
  ty = 0;
bigImg.addEventListener("mousemove", (e) => {
  const r = bigImg.getBoundingClientRect();
  mx = ((e.clientX - r.left) / r.width - 0.5) * 2;
  my = ((e.clientY - r.top) / r.height - 0.5) * 2;
});
bigImg.addEventListener("mouseleave", () => {
  mx = 0;
  my = 0;
});

function parallax() {
  tx += (mx - tx) * 0.06;
  ty += (my - ty) * 0.06;
  document.querySelectorAll(".sphere").forEach((sp, i) => {
    const depth = 8 + (i % 3) * 4;
    sp.style.translate = `${tx * depth}px ${ty * depth}px`;
  });
  requestAnimationFrame(parallax);
}
parallax();

// ============================================================
// SCROLL: big image gets bigger / spheres parallax
// ============================================================
ScrollTrigger.create({
  trigger: ".below",
  start: "top 80%",
  end: "bottom top",
  scrub: 0.8,
  onUpdate: (self) => {
    const p = self.progress;
    gsap.set("#bigImage", { scale: 1 + 0.04 * p, rotation: 1 * p });
    document.querySelectorAll(".sphere").forEach((sp, i) => {
      const dir = i % 2 === 0 ? 1 : -1;
      gsap.set(sp, { y: dir * 20 * p, rotation: dir * 8 * p });
    });
  }
});

// Headline letters subtle spread on scroll
ScrollTrigger.create({
  trigger: ".hero",
  start: "top top",
  end: "bottom top",
  scrub: 0.8,
  onUpdate: (self) => {
    const p = self.progress;
    gsap.set(".headline", { y: -50 * p, opacity: 1 - p * 0.4 });
  }
});

// ============================================================
// FEATURES REVEAL
// ============================================================
gsap.from(".eyebrow, .features-head h2, .features-head p", {
  opacity: 0,
  y: 30,
  duration: 0.9,
  stagger: 0.1,
  ease: "power3.out",
  scrollTrigger: { trigger: ".features-head", start: "top 80%" }
});

gsap.to(".feat-card", {
  opacity: 1,
  y: 0,
  duration: 1,
  stagger: 0.12,
  ease: "power3.out",
  scrollTrigger: { trigger: ".features-grid", start: "top 50%" }
});
gsap.from(".feat-card", {
  y: 60,
  scale: 0.96,
  duration: 1,
  stagger: 0.12,
  ease: "back.out(1.3)",
  scrollTrigger: { trigger: ".features-grid", start: "top 0%" }
});

// Feature icon hover effect
document.querySelectorAll(".feat-card").forEach((card) => {
  const icon = card.querySelector(".feat-icon");
  card.addEventListener("mouseenter", () => {
    gsap.to(icon, {
      rotate: -10,
      y: -4,
      scale: 1.08,
      duration: 0.5,
      ease: "back.out(1.6)"
    });
  });
  card.addEventListener("mouseleave", () => {
    gsap.to(icon, {
      rotate: 0,
      y: 0,
      scale: 1,
      duration: 0.6,
      ease: "elastic.out(1, 0.6)"
    });
  });
});

// ============================================================
// CTA REVEAL + COUNTER
// ============================================================
gsap.to(".cta-inner", {
  opacity: 1,
  y: 0,
  duration: 1.2,
  ease: "power3.out",
  scrollTrigger: { trigger: ".cta-section", start: "top 80%" }
});
gsap.from(".cta-inner", {
  y: 60,
  scale: 0.97,
  duration: 1.2,
  ease: "power3.out",
  scrollTrigger: { trigger: ".cta-section", start: "top 80%" }
});

// 120+ counter
ScrollTrigger.create({
  trigger: ".col-right",
  start: "top 80%",
  onEnter: () => {
    const el = document.querySelector(".stat-block .num");
    const target = parseFloat(el.dataset.count);
    const span = el.querySelector("span");
    gsap.to(
      { v: 0 },
      {
        v: target,
        duration: 1.6,
        ease: "power2.out",
        onUpdate: function () {
          span.textContent = Math.floor(this.targets()[0].v).toLocaleString();
        }
      }
    );
  },
  once: true
});

// Button click pulse
document
  .querySelectorAll(".contact-pill, .try-pill, .cta-btn, .play-btn")
  .forEach((btn) => {
    btn.addEventListener("click", () => {
      gsap.fromTo(
        btn,
        { scale: 1 },
        {
          scale: 0.92,
          duration: 0.12,
          yoyo: true,
          repeat: 1,
          ease: "power2.inOut"
        }
      );
    });
  });
