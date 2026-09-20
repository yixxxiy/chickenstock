const PREF_KEY = 'cluck-farm-audio';
const EGG_SCALE = [392, 440, 494, 587, 659, 784];

type Prefs = { sfx: boolean; amb: boolean };

function readPrefs(): Prefs {
  try {
    const raw = localStorage.getItem(PREF_KEY);
    if (!raw) return { sfx: true, amb: true };
    const p = JSON.parse(raw) as Partial<Prefs>;
    return { sfx: p.sfx !== false, amb: p.amb !== false };
  } catch {
    return { sfx: true, amb: true };
  }
}

function writePrefs(p: Prefs) {
  try { localStorage.setItem(PREF_KEY, JSON.stringify(p)); } catch { /* ignore */ }
}

let ctx: AudioContext | null = null;
let master: GainNode | null = null;
let sfxBus: GainNode | null = null;
let ambBus: GainNode | null = null;
let nightGain: GainNode | null = null;
let noiseBuf: AudioBuffer | null = null;
let ambStarted = false;
let eggStep = 0;
let prefs = { sfx: true, amb: true };
type FlockVoice = { kind: 'hen' | 'chick'; due: number };
let flockVoices: FlockVoice[] = [];
let flockRaf = 0;
let flockBusy = 0;

function ac() {
  if (typeof window === 'undefined') return null;
  if (!ctx) {
    ctx = new AudioContext();
    master = ctx.createGain();
    master.gain.value = .72;
    const lp = ctx.createBiquadFilter();
    lp.type = 'lowpass';
    lp.frequency.value = 3800;
    lp.Q.value = .4;
    const comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -18;
    comp.knee.value = 12;
    comp.ratio.value = 2.2;
    comp.attack.value = .004;
    comp.release.value = .12;
    master.connect(lp); lp.connect(comp); comp.connect(ctx.destination);
    sfxBus = ctx.createGain(); sfxBus.gain.value = 1; sfxBus.connect(master);
    nightGain = ctx.createGain(); nightGain.gain.value = 1;
    ambBus = ctx.createGain(); ambBus.gain.value = 0;
    ambBus.connect(nightGain); nightGain.connect(master);
  }
  if (ctx.state === 'suspended') void ctx.resume();
  return ctx;
}

function noise() {
  const c = ac(); if (!c) return null;
  if (!noiseBuf) {
    const n = Math.floor(c.sampleRate * .35);
    noiseBuf = c.createBuffer(1, n, c.sampleRate);
    const d = noiseBuf.getChannelData(0);
    let last = 0;
    for (let i = 0; i < n; i++) {
      last = last * .86 + (Math.random() * 2 - 1) * .14;
      d[i] = last;
    }
  }
  return noiseBuf;
}

function env(g: GainNode, t: number, vol: number, dur: number, attack = .008) {
  const peak = Math.max(.0008, vol);
  g.gain.setValueAtTime(.0008, t);
  g.gain.exponentialRampToValueAtTime(peak, t + attack);
  g.gain.exponentialRampToValueAtTime(.0008, t + dur);
}

function tone(opts: {
  freq: number; t?: number; dur?: number; vol?: number; type?: OscillatorType;
  slide?: number; filter?: number; bus?: GainNode;
}) {
  const c = ac(); if (!c || !sfxBus) return;
  const dest = opts.bus ?? sfxBus;
  const t = opts.t ?? c.currentTime;
  const dur = opts.dur ?? .14;
  const osc = c.createOscillator();
  osc.type = opts.type ?? 'triangle';
  osc.frequency.setValueAtTime(Math.max(40, opts.freq), t);
  if (opts.slide) osc.frequency.exponentialRampToValueAtTime(Math.max(40, opts.slide), t + dur * .9);
  const g = c.createGain();
  env(g, t, opts.vol ?? .05, dur);
  if (opts.filter) {
    const f = c.createBiquadFilter();
    f.type = 'lowpass'; f.frequency.value = opts.filter;
    osc.connect(f); f.connect(g);
  } else osc.connect(g);
  g.connect(dest);
  osc.start(t); osc.stop(t + dur + .02);
}

function scratch(t: number, vol: number, freq: number, dur: number, dest: GainNode) {
  const c = ac(); if (!c) return;
  const buf = noise(); if (!buf) return;
  const src = c.createBufferSource(); src.buffer = buf;
  const bp = c.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = freq; bp.Q.value = 1.4;
  const g = c.createGain();
  env(g, t, vol, dur, .003);
  src.connect(bp); bp.connect(g); g.connect(dest);
  src.start(t); src.stop(t + dur + .02);
}

function click(t: number, vol = .05, freq = 1800, dur = .05) {
  const c = ac(); if (!c || !sfxBus) return;
  scratch(t, vol, freq, dur, sfxBus);
}

function henGap() { return 8000 + Math.random() * 12000; }
function chickGap() { return 5500 + Math.random() * 9500; }

function trimVoices(kind: 'hen' | 'chick', keep: number) {
  let n = 0;
  for (const v of flockVoices) if (v.kind === kind) n++;
  if (n <= keep) return;
  const next: FlockVoice[] = [];
  let kept = 0;
  for (const v of flockVoices) {
    if (v.kind !== kind) { next.push(v); continue; }
    if (kept < keep) { next.push(v); kept++; }
  }
  flockVoices = next;
}

function growVoices(kind: 'hen' | 'chick', want: number, now: number) {
  let n = 0;
  for (const v of flockVoices) if (v.kind === kind) n++;
  while (n < want) {
    flockVoices.push({ kind, due: now + 500 + Math.random() * (kind === 'hen' ? 7000 : 5000) });
    n++;
  }
}

function playHenCall() {
  if (!prefs.amb || !ctx || !ambBus) return;
  if (flockBusy >= 4) return;
  flockBusy += 1;
  window.setTimeout(() => { flockBusy = Math.max(0, flockBusy - 1); }, 340);
  const t = ctx.currentTime;
  const base = 250 + Math.random() * 95;
  const n = Math.random() < .38 ? 3 : 2;
  const vol = .03;
  for (let i = 0; i < n; i++) {
    const at = t + i * (.082 + Math.random() * .028);
    const f = base * (1 - i * .07);
    tone({ freq: f * 1.22, t: at, dur: .078, vol, type: 'triangle', slide: f * .66, filter: 1180, bus: ambBus });
    scratch(at, vol * .42, 470 + Math.random() * 90, .048, ambBus);
  }
}

function playChickCall() {
  if (!prefs.amb || !ctx || !ambBus) return;
  if (flockBusy >= 4) return;
  flockBusy += 1;
  window.setTimeout(() => { flockBusy = Math.max(0, flockBusy - 1); }, 220);
  const t = ctx.currentTime;
  const a = 1380 + Math.random() * 680;
  const n = Math.random() < .42 ? 2 : 1;
  const vol = .02;
  for (let i = 0; i < n; i++) {
    const at = t + i * .1;
    tone({ freq: a * (1 + i * .03), t: at, dur: .048, vol, type: 'sine', slide: a * 1.16, filter: 3900, bus: ambBus });
  }
}

function stopFlockLoop() {
  if (flockRaf) { cancelAnimationFrame(flockRaf); flockRaf = 0; }
}

function ensureFlockLoop() {
  if (!prefs.amb || flockRaf || flockVoices.length < 1) return;
  if (!ctx || ctx.state === 'suspended') return;
  const now = performance.now();
  for (const v of flockVoices) {
    if (v.due < now) v.due = now + 700 + Math.random() * 5000;
  }
  const tick = () => {
    flockRaf = 0;
    if (!prefs.amb || flockVoices.length < 1) return;
    const hidden = typeof document !== 'undefined' && document.hidden;
    if (!hidden && ctx && ctx.state !== 'suspended') {
      const t = performance.now();
      for (const v of flockVoices) {
        if (t < v.due) continue;
        v.due = t + (v.kind === 'hen' ? henGap() : chickGap());
        if (v.kind === 'hen') playHenCall();
        else playChickCall();
      }
    }
    if (prefs.amb && flockVoices.length) flockRaf = requestAnimationFrame(tick);
  };
  flockRaf = requestAnimationFrame(tick);
}

function syncFlock(hens: number, chicks: number) {
  const henCount = Math.max(0, hens | 0);
  const chickCount = Math.max(0, chicks | 0);
  const now = performance.now();
  growVoices('hen', henCount, now);
  growVoices('chick', chickCount, now);
  trimVoices('hen', henCount);
  trimVoices('chick', chickCount);
  if (!flockVoices.length) stopFlockLoop();
  else if (prefs.amb) ensureFlockLoop();
}

function chord(notes: number[], gap = .08, dur = .16, vol = .045, type: OscillatorType = 'triangle') {
  const c = ac(); if (!c) return;
  notes.forEach((f, i) => tone({ freq: f, t: c.currentTime + i * gap, dur, vol, type, filter: 3200 }));
}

function live() {
  return !!ac() && prefs.sfx;
}

function startAmbience() {
  const c = ac(); if (!c || !ambBus || !prefs.amb) return;
  const bus = ambBus;
  if (!ambStarted) {
    ambStarted = true;
    const buf = noise(); if (!buf) return;
    const wind = c.createBufferSource();
    wind.buffer = buf; wind.loop = true;
    const f = c.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = 420; f.Q.value = .5;
    const g = c.createGain(); g.gain.value = .045;
    wind.connect(f); f.connect(g); g.connect(bus); wind.start();
    const pad = (freq: number, vol: number) => {
      const osc = c.createOscillator(); osc.type = 'sine'; osc.frequency.value = freq;
      const og = c.createGain(); og.gain.value = vol;
      const lfo = c.createOscillator(); lfo.frequency.value = .07 + Math.random() * .04;
      const lg = c.createGain(); lg.gain.value = vol * .35;
      lfo.connect(lg); lg.connect(og.gain);
      osc.connect(og); og.connect(bus);
      osc.start(); lfo.start();
    };
    pad(196, .012); pad(293.66, .01); pad(392, .006);
  }
  bus.gain.cancelScheduledValues(c.currentTime);
  bus.gain.setValueAtTime(Math.max(.0008, bus.gain.value), c.currentTime);
  bus.gain.exponentialRampToValueAtTime(.9, c.currentTime + 1.6);
  ensureFlockLoop();
}

function stopAmbience() {
  const c = ctx;
  if (c && ambBus) {
    ambBus.gain.cancelScheduledValues(c.currentTime);
    ambBus.gain.setValueAtTime(Math.max(.0008, ambBus.gain.value), c.currentTime);
    ambBus.gain.exponentialRampToValueAtTime(.0008, c.currentTime + .4);
  }
  stopFlockLoop();
}

export const sfx = {
  prefs(): Prefs { return { ...prefs }; },
  unlock() {
    prefs = readPrefs();
    ac();
    if (prefs.amb) startAmbience();
  },
  setSfx(on: boolean) {
    prefs = { ...prefs, sfx: on };
    writePrefs(prefs);
    if (on) this.unlock();
  },
  setAmb(on: boolean) {
    prefs = { ...prefs, amb: on };
    writePrefs(prefs);
    if (on) { this.unlock(); startAmbience(); }
    else stopAmbience();
  },
  setFlock(hens: number, chicks: number) { syncFlock(hens, chicks); },
  setNight(night: boolean) {
    const c = ac(); if (!c || !nightGain) return;
    nightGain.gain.cancelScheduledValues(c.currentTime);
    nightGain.gain.setValueAtTime(Math.max(.0008, nightGain.gain.value), c.currentTime);
    nightGain.gain.exponentialRampToValueAtTime(night ? .22 : 1, c.currentTime + .7);
  },
  egg() {
    if (!live()) return;
    navigator.vibrate?.(12);
    const c = ac()!;
    const f = EGG_SCALE[eggStep % EGG_SCALE.length];
    eggStep += 1;
    click(c.currentTime, .04, 1400, .04);
    tone({ freq: f, dur: .11, vol: .055, type: 'triangle', slide: f * 1.01, filter: 2800 });
    tone({ freq: f * 2, dur: .07, vol: .012, type: 'sine', filter: 4000 });
  },
  chick() {
    if (!live()) return;
    const c = ac()!;
    tone({ freq: 880, t: c.currentTime, dur: .07, vol: .04, type: 'sine', slide: 1175, filter: 3600 });
    tone({ freq: 1175, t: c.currentTime + .07, dur: .08, vol: .035, type: 'sine', slide: 988, filter: 3600 });
  },
  hatch() {
    if (!live()) return;
    const c = ac()!;
    click(c.currentTime, .06, 420, .08);
    tone({ freq: 247, dur: .22, vol: .05, type: 'sine', slide: 330, filter: 1600 });
    tone({ freq: 392, t: c.currentTime + .12, dur: .16, vol: .03, type: 'triangle', filter: 2200 });
  },
  bakeStart() {
    if (!live()) return;
    tone({ freq: 330, dur: .12, vol: .03, type: 'sine', filter: 1800 });
  },
  bakeDone() {
    if (!live()) return;
    const c = ac()!;
    tone({ freq: 659, t: c.currentTime, dur: .12, vol: .05, type: 'triangle', filter: 2800 });
    tone({ freq: 784, t: c.currentTime + .1, dur: .18, vol: .055, type: 'triangle', filter: 2800 });
  },
  coin() {
    if (!live()) return;
    navigator.vibrate?.(22);
    const c = ac()!;
    click(c.currentTime, .05, 2400, .04);
    tone({ freq: 659, t: c.currentTime, dur: .1, vol: .05, type: 'triangle', filter: 3400 });
    tone({ freq: 880, t: c.currentTime + .07, dur: .12, vol: .055, type: 'triangle', filter: 3400 });
    tone({ freq: 1175, t: c.currentTime + .14, dur: .16, vol: .04, type: 'sine', filter: 4000 });
  },
  spend() {
    if (!live()) return;
    const c = ac()!;
    click(c.currentTime, .035, 900, .06);
    tone({ freq: 523, t: c.currentTime, dur: .1, vol: .04, type: 'triangle', slide: 392, filter: 2400 });
    tone({ freq: 330, t: c.currentTime + .08, dur: .12, vol: .03, type: 'sine', filter: 1800 });
  },
  buyShare() {
    if (!live()) return;
    navigator.vibrate?.(18);
    const c = ac()!;
    tone({ freq: 392, t: c.currentTime, dur: .14, vol: .045, type: 'triangle', slide: 294, filter: 2000 });
    tone({ freq: 247, t: c.currentTime + .12, dur: .2, vol: .05, type: 'sine', filter: 1400 });
    click(c.currentTime + .18, .04, 700, .08);
  },
  sellShare() {
    if (!live()) return;
    navigator.vibrate?.(24);
    chord([523, 659, 784, 1046], .09, .15, .05);
  },
  deny() {
    if (!live()) return;
    tone({ freq: 196, dur: .16, vol: .04, type: 'sine', slide: 147, filter: 900 });
    click(ac()!.currentTime, .03, 280, .08);
  },
  dusk() {
    if (!live()) return;
    chord([392, 330, 294, 247], .14, .28, .04, 'sine');
  },
  dawn() {
    if (!live()) return;
    const c = ac()!;
    chord([330, 392, 494, 587], .11, .22, .045, 'sine');
    tone({ freq: 1760, t: c.currentTime + .35, dur: .06, vol: .02, type: 'sine', slide: 2100, filter: 4000 });
  },
  price(up: boolean, big: boolean) {
    if (!live()) return;
    if (up) chord(big ? [392, 523, 659, 784, 1046] : [523, 659, 784], big ? .1 : .08, big ? .2 : .14, big ? .055 : .042);
    else chord(big ? [494, 392, 330, 247] : [440, 349, 294], big ? .12 : .1, big ? .22 : .16, .04, 'sine');
  },
  shatter() {
    if (!live()) return;
    const c = ac()!;
    const t = c.currentTime, buf = noise(); if (!buf) return;
    const src = c.createBufferSource(); src.buffer = buf;
    const bp = c.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 1800; bp.Q.value = .8;
    const g = c.createGain(); env(g, t, .08, .22, .004);
    src.connect(bp); bp.connect(g); g.connect(sfxBus!);
    src.start(t); src.stop(t + .24);
    [349, 262, 196].forEach((f, i) => tone({ freq: f, t: t + i * .05, dur: .12, vol: .035, type: 'triangle', filter: 1400 }));
  },
  warn() {
    if (!live()) return;
    navigator.vibrate?.([16, 40, 16]);
    const c = ac()!;
    tone({ freq: 988, dur: .07, vol: .045, type: 'triangle', filter: 2400 });
    tone({ freq: 784, t: c.currentTime + .09, dur: .08, vol: .04, type: 'triangle', filter: 2200 });
    click(c.currentTime, .03, 1600, .05);
  },
  stamp() {
    if (!live()) return;
    navigator.vibrate?.(28);
    click(ac()!.currentTime, .07, 420, .1);
    tone({ freq: 196, dur: .14, vol: .05, type: 'sine', filter: 900 });
    chord([523, 659, 784], .05, .18, .05);
  },
  rank() {
    if (!live()) return;
    chord([392, 494, 587, 784], .09, .18, .05);
  },
  quest() {
    if (!live()) return;
    navigator.vibrate?.(30);
    chord([392, 523, 659, 784, 1046, 1318], .08, .2, .055);
  },
  eggReady() {
    if (!live()) return;
    click(ac()!.currentTime, .025, 1100, .05);
    tone({ freq: 587, dur: .09, vol: .02, type: 'sine', filter: 2400 });
  },
  ending(toneName: string) {
    if (!live()) return;
    if (toneName === 'top' || toneName === 'high') chord([392, 523, 659, 784, 988, 1175], .1, .24, .055);
    else if (toneName === 'good') chord([392, 494, 587, 740], .1, .2, .05);
    else if (toneName === 'mid') chord([330, 392, 494], .12, .2, .045, 'sine');
    else chord([294, 247, 220], .14, .26, .04, 'sine');
  },
};

if (typeof window !== 'undefined') prefs = readPrefs();
