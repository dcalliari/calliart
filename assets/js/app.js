import "../css/app.css";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

// ── helpers ────────────────────────────────────────────────────────────────
const caPad = (n) => (n < 10 ? "0" : "") + n;

// ── hooks ──────────────────────────────────────────────────────────────────
const Hooks = {};

Hooks.CalliartHook = {
  mounted() {
    this._ed = parseInt(this.el.dataset.ed || "0");
    this._frame = 0;
    this._frameCount = parseInt(this.el.dataset.frameCount || "1");
    this._activeWrap = null;
    this._dotsEl = null;

    this._onScroll = () => this._handleScroll();
    this._onWheel  = (e) => this._handleWheel(e);
    this._onKeydown = (e) => this._handleKeydown(e);
    this._onDotClick = (e) => {
      const d = e.target.closest("[data-fi]");
      if (d) this._scrollToFrame(parseInt(d.dataset.fi));
    };
    this._raf = null;
    this._scrolling = false;

    window.addEventListener("keydown", this._onKeydown);
    this._setupWrap(this._ed);
  },

  updated() {
    const newEd = parseInt(this.el.dataset.ed || "0");
    this._frameCount = parseInt(this.el.dataset.frameCount || "1");
    if (newEd !== this._ed) {
      this._ed = newEd;
      this._frame = 0;
      this._setupWrap(newEd);
    }
  },

  destroyed() {
    window.removeEventListener("keydown", this._onKeydown);
    if (this._raf) cancelAnimationFrame(this._raf);
    if (this._activeWrap) {
      this._activeWrap.removeEventListener("scroll", this._onScroll);
      this._activeWrap.removeEventListener("wheel", this._onWheel);
    }
    if (this._dotsEl) this._dotsEl.removeEventListener("click", this._onDotClick);
  },

  _setupWrap(ed) {
    if (this._raf) { cancelAnimationFrame(this._raf); this._raf = null; }
    this._scrolling = false;
    if (this._activeWrap) {
      this._activeWrap.removeEventListener("scroll", this._onScroll);
      this._activeWrap.removeEventListener("wheel", this._onWheel);
    }
    if (this._dotsEl) this._dotsEl.removeEventListener("click", this._onDotClick);

    const wrap = document.getElementById(`ca-wrap-${ed}`);
    if (wrap) {
      this._activeWrap = wrap;
      wrap.scrollTop = 0;
      wrap.addEventListener("scroll", this._onScroll, { passive: true });
      wrap.addEventListener("wheel", this._onWheel, { passive: false });
    }

    const dotsEl = document.getElementById("ca-dots");
    if (dotsEl) {
      this._dotsEl = dotsEl;
      dotsEl.addEventListener("click", this._onDotClick);
    }

    this._updateDots(0);
    const prog = document.getElementById("ca-prog");
    if (prog) prog.style.width = "0%";
    const fc = document.getElementById("ca-frame-counter");
    if (fc) fc.textContent = "01 / " + caPad(this._frameCount);
  },

  _handleScroll() {
    const wrap = this._activeWrap;
    if (!wrap) return;
    const vh = wrap.clientHeight || 1;
    const max = wrap.scrollHeight - vh;
    const frame = Math.max(0, Math.min(this._frameCount - 1, Math.round(wrap.scrollTop / vh)));

    const prog = document.getElementById("ca-prog");
    if (prog) prog.style.width = (max > 0 ? (wrap.scrollTop / max) * 100 : 0) + "%";

    if (frame !== this._frame) {
      this._frame = frame;
      this._updateDots(frame);
      const fc = document.getElementById("ca-frame-counter");
      if (fc) fc.textContent = caPad(frame + 1) + " / " + caPad(this._frameCount);
    }
  },

  _handleKeydown(e) {
    if (e.key === "Escape") { this.pushEvent("close_overlays", {}); return; }
    if (e.key === "ArrowLeft")  { e.preventDefault(); this.pushEvent("prev_ed", {}); }
    if (e.key === "ArrowRight") { e.preventDefault(); this.pushEvent("next_ed", {}); }
  },

  _handleWheel(e) {
    e.preventDefault();
    if (this._scrolling) return;
    const dir = e.deltaY > 0 ? 1 : -1;
    const target = Math.max(0, Math.min(this._frameCount - 1, this._frame + dir));
    if (target !== this._frame) this._animateTo(target);
  },

  _animateTo(fi) {
    const wrap = this._activeWrap;
    if (!wrap) return;
    const from = wrap.scrollTop;
    const to = fi * wrap.clientHeight;
    if (from === to) return;

    const duration = 700;
    const ease = (t) => t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t + 2, 3) / 2;
    let start = null;
    this._scrolling = true;
    wrap.style.scrollSnapType = "none"; // previne snap em posições intermediárias

    const tick = (ts) => {
      if (!start) start = ts;
      const p = Math.min((ts - start) / duration, 1);
      wrap.scrollTop = from + (to - from) * ease(p);
      if (p < 1) {
        this._raf = requestAnimationFrame(tick);
      } else {
        wrap.scrollTop = to;
        wrap.style.scrollSnapType = "";
        this._scrolling = false;
        this._raf = null;
      }
    };
    this._raf = requestAnimationFrame(tick);
  },

  _scrollToFrame(fi) {
    this._animateTo(fi);
  },

  _updateDots(active) {
    for (let i = 0; i < this._frameCount; i++) {
      const dot = document.getElementById(`ca-dot-${i}`);
      if (dot) dot.classList.toggle("ca-dot--active", i === active);
    }
  },
};

// ── live socket ────────────────────────────────────────────────────────────
const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

liveSocket.connect();
window.liveSocket = liveSocket;
