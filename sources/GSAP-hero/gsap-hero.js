document.addEventListener("DOMContentLoaded", () => {
  gsap.registerPlugin(ScrollTrigger);

  // 1. Initial Entrance Animations
  const tl = gsap.timeline();

  tl.from(".gsap-nav", {
    y: -20,
    opacity: 0,
    duration: 0.8,
    stagger: 0.2,
    ease: "power2.out"
  })
    .from(
      ".gsap-bg-text",
      {
        scale: 0.9,
        opacity: 0,
        duration: 1.5,
        ease: "power2.out"
      },
      "-=0.8"
    )
    .from(
      ".gsap-main-img",
      {
        y: 100,
        opacity: 0,
        duration: 1.5,
        ease: "power3.out"
      },
      "-=1.2"
    )
    .from(
      ".gsap-hero",
      {
        x: -30,
        opacity: 0,
        duration: 0.8,
        stagger: 0.1,
        ease: "power3.out"
      },
      "-=1"
    );

  // 2. Continuous Organic Floating (Clay Feeling)
  gsap.utils.toArray(".float-anim").forEach((el, i) => {
    gsap.to(el, {
      y: "-=10",
      rotation: "1",
      duration: 2.5 + i * 0.2,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
      delay: i * 0.1
    });
  });

  gsap.utils.toArray(".float-anim-alt").forEach((el, i) => {
    gsap.to(el, {
      y: "+=10",
      rotation: "-1",
      duration: 2.8 + i * 0.2,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
      delay: i * 0.15
    });
  });

  gsap.to(".float-anim-slow", {
    y: "-=15",
    duration: 4,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut"
  });

  // 3. Scroll Reveal & Parallax Animations

  // Background Text Parallax
  gsap.to(".bg-text", {
    y: -150,
    ease: "none",
    scrollTrigger: {
      trigger: ".hero",
      start: "top top",
      end: "bottom top",
      scrub: 1
    }
  });

  // Main Product Image Parallax
  gsap.to(".hero-main-img", {
    y: 50,
    scale: 0.95,
    ease: "none",
    scrollTrigger: {
      trigger: ".hero",
      start: "top top",
      end: "bottom top",
      scrub: true
    }
  });

  // Bottom Section Text Reveal
  gsap.from(".gsap-s2", {
    y: 40,
    opacity: 0,
    duration: 1,
    stagger: 0.2,
    ease: "power3.out",
    scrollTrigger: {
      trigger: ".bottom-section",
      start: "top 70%"
    }
  });

  // Giant Pills Stagger Reveal
  gsap.from(".gsap-pill", {
    y: 60,
    opacity: 0,
    scale: 0.8,
    rotation: () => gsap.utils.random(-8, 8),
    duration: 1,
    stagger: 0.15,
    ease: "back.out(1.2)",
    scrollTrigger: {
      trigger: ".pill-container",
      start: "top 85%"
    }
  });

  // 4. Interactive Clay Button Press Effect
  const clayButtons = document.querySelectorAll(".giant-pill, .clay-widget");
  clayButtons.forEach((btn) => {
    btn.addEventListener("mousedown", () => {
      gsap.to(btn, { scale: 0.95, duration: 0.1 });
    });
    btn.addEventListener("mouseup", () => {
      gsap.to(btn, { scale: 1, duration: 0.3, ease: "back.out(2)" });
    });
  });
});
