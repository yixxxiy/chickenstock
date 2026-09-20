'use client';
import { useEffect, useRef, useState, type MouseEvent, type PointerEvent, type ReactNode } from 'react';
import { sfx } from './sfx';

type Toast = { id: number; text: string };
type Flyer = { id: number; kind: 'egg' | 'cake' | 'coin' | 'spend' | 'chick' | 'payout' | 'waste' | 'burst-coin' | 'burst-chick'; at?: 'coop' | 'bakery' | 'hatch'; x?: number; y?: number; delay?: number };
type NewsId = 'hoard' | 'cake' | 'rain';
type Summary = { broken: number; grown: number; cakesSold: number; oldPrice: number; newPrice: number; day: number; hatched?: number; wealth?: number; flock?: number; news?: NewsId } | null;
type GameResult = 'ended' | 'won' | 'bankrupt' | null;
const NEWS: Record<NewsId, { text: string; up: boolean; weather: string }> = {
  hoard: { text: '狼商囤粮', up: true, weather: '/ui/weather-cloud.png' },
  cake: { text: '蛋糕热销', up: true, weather: '/ui/weather-sun.png' },
  rain: { text: '雨天减产', up: false, weather: '/ui/weather-rain.png' },
};
function isNews(v: unknown): v is NewsId { return v === 'hoard' || v === 'cake' || v === 'rain'; }
function pickNews(price: number): NewsId {
  const p = Math.max(50, Math.min(680, price || 300)), roll = Math.random();
  if (roll < 0.11 && p >= 110) return 'rain';
  if (roll < 0.22 && p <= 520) return 'hoard';
  return 'cake';
}
type FlockBird = { key: string; kind: 'hen' | 'young'; left: number; top: number; z: number; size: number; grown: boolean };
type FlockView = { nest: FlockBird[]; yard: FlockBird[] };

const YARD_POLY: [number, number][] = [
  [18, 59], [28, 56], [45, 55], [62, 56], [78, 59],
  [82, 65], [70, 70], [48, 72], [28, 70], [18, 65],
];
function pointInPoly(x: number, y: number, poly: [number, number][]) {
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [xi, yi] = poly[i], [xj, yj] = poly[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi || 1e-6) + xi) inside = !inside;
  }
  return inside;
}
function inYard(x: number, y: number) {
  const dx = x - 50, dy = y - 60;
  if (dx * dx + dy * dy < 52) return false;
  return pointInPoly(x, y, YARD_POLY);
}
const YARD_SPOTS: [number, number][] = (() => {
  const s: [number, number][] = [];
  for (let y = 56; y <= 71; y += 2.6) {
    for (let x = 18; x <= 82; x += 3.2) {
      if (inYard(x, y)) s.push([x, y]);
    }
  }
  return s;
})();
function rng(seed: number) {
  let s = seed | 0;
  return () => {
    s = Math.imul(s ^ (s >>> 16), 0x7feb352d);
    s = Math.imul(s ^ (s >>> 15), 0x846ca68b);
    return ((s ^ (s >>> 16)) >>> 0) / 4294967296;
  };
}

const DAY_MS = 20000, DUSK_WARN_MS = 5000, WEALTH_GOAL = 3000, FLOCK_GOAL = 15, SAVE_KEY = 'cluck-farm-v7';
const CHICK_COST = 50, CHICK_SALE = 40, CAKE_SALE = 150;
const ranks = [
  { lv: 1, min: 0, title: '流浪小鸡', mascot: '🐥', tone: 'low', copy: '口袋空空，八日收场有点潦倒。' },
  { lv: 2, min: 300, title: '见习股民', mascot: '🐣', tone: 'low', copy: '刚摸到股市门槛，还得精打细算。' },
  { lv: 3, min: 600, title: '咯咯佃农', mascot: '🐔', tone: 'mid', copy: '农场能转了，但还谈不上宽裕。' },
  { lv: 4, min: 1000, title: '小本鸡舍', mascot: '🥚', tone: 'mid', copy: '有点积蓄，在动物街站稳了脚跟。' },
  { lv: 5, min: 1500, title: '温饱农场', mascot: '🧁', tone: 'mid', copy: '日子过得去，离新贵还差一截。' },
  { lv: 6, min: 2000, title: '街口商贩', mascot: '📈', tone: 'good', copy: '买卖开始像样，邻居开始打听你。' },
  { lv: 7, min: 2500, title: '农场掌柜', mascot: '🐔', tone: 'good', copy: '鸡舍和股市两边都能转。' },
  { lv: 8, min: 3000, title: '动物街新贵', mascot: '🏆', tone: 'high', copy: '资产过三千，真正在街上扬名。' },
  { lv: 9, min: 4500, title: '金币大亨', mascot: '💎', tone: 'high', copy: '股价和农场都听你的。' },
  { lv: 10, min: 6000, title: '农场传奇', mascot: '👑', tone: 'top', copy: '八日登顶，动物街都会记得你。' },
] as const;
type Rank = typeof ranks[number];
function rankOf(wealth: number): Rank { let r: Rank = ranks[0]; for (const x of ranks) if (wealth >= x.min) r = x; return r; }

const start = {
  coins: 140, eggs: 0, readyEggs: 3, pendingEggs: 0, hens: 1, youngChicks: 0, cakes: 0, cakesSold: 0, shares: 0,
  price: 120, day: 1, leftMs: DAY_MS, history: [108, 96, 132, 114, 120], wealthLog: [140] as number[],
  baking: 0, hatching: 0, hatched: 0, boardOpen: true as boolean, seenGoal: 0, seenTitle: 0,
  news: 'cake' as NewsId,
};

function piePath(frac: number) {
  const f = Math.max(0, Math.min(1, frac));
  if (f <= .001) return '';
  if (f >= .999) return 'M18 2.2 A15.8 15.8 0 1 1 17.99 2.2 Z';
  const sweep = f * 360, rad = (d: number) => (d - 90) * Math.PI / 180;
  const x = 18 + 15.8 * Math.cos(rad(sweep)), y = 18 + 15.8 * Math.sin(rad(sweep));
  return `M18 18 L18 2.2 A15.8 15.8 0 ${sweep > 180 ? 1 : 0} 1 ${x.toFixed(2)} ${y.toFixed(2)} Z`;
}
function nextPrice(current: number, news: NewsId) {
  const floor = 50, cap = 680, fair = 300, p = Math.max(floor, Math.min(cap, current || fair));
  const factor = news === 'rain' ? 0.55 + Math.random() * 0.18 : news === 'hoard' ? 1.22 + Math.random() * 0.28 : 1.05 + Math.random() * 0.12;
  let next = Math.round((p + (fair - p) * 0.18) * factor);
  if (news === 'rain') next = Math.min(next, p - Math.max(12, Math.round(p * 0.1)));
  else next = Math.max(next, p + Math.max(news === 'hoard' ? 24 : 8, Math.round(p * (news === 'hoard' ? 0.16 : 0.05))));
  return Math.max(floor, Math.min(cap, next));
}
function clampFlock(hens: number, young: number) { return { hens: Math.max(0, hens), youngChicks: Math.max(0, young) }; }
function flockSprites(hens: number, young: number, justGrown: number): FlockView {
  const total = hens + young, shrink = Math.max(0.42, 1.02 - Math.max(0, total - 3) * 0.035);
  const grownFrom = Math.max(0, hens - justGrown);
  const all: { kind: 'hen' | 'young'; grown: boolean; i: number }[] = [
    ...Array.from({ length: hens }, (_, i) => ({ kind: 'hen' as const, grown: justGrown > 0 && i >= grownFrom, i })),
    ...Array.from({ length: young }, (_, i) => ({ kind: 'young' as const, grown: false, i: hens + i })),
  ];
  const nest: FlockBird[] = [], yard: FlockBird[] = [];
  all.forEach(b => {
    const rand = rng(0x9E3779B9 ^ Math.imul(b.i + 1, 747796405) ^ (b.kind === 'hen' ? 0xA5A5 : 0xC3C3));
    const spot = YARD_SPOTS[Math.floor(rand() * Math.max(1, YARD_SPOTS.length))] ?? [36, 62];
    yard.push({
      key: `${b.kind}-${b.i}`, kind: b.kind, grown: b.grown,
      left: spot[0] - 4.2 + (rand() - 0.5) * 2.2, top: spot[1] - 4.6 + (rand() - 0.5) * 1.2,
      z: 8 + Math.round(spot[1]), size: (b.kind === 'hen' ? 0.68 : 0.4) * Math.max(0.4, shrink * 0.9),
    });
  });
  return { nest, yard };
}
function useRepeater(action: (quiet?: boolean) => boolean) {
  const actionRef = useRef(action); actionRef.current = action;
  const holdRef = useRef(0), repeatRef = useRef(0);
  const stop = () => { clearTimeout(holdRef.current); clearInterval(repeatRef.current); holdRef.current = 0; repeatRef.current = 0; };
  useEffect(() => stop, []);
  const down = (e: PointerEvent<HTMLButtonElement>) => {
    if (e.button !== 0 || e.currentTarget.disabled) return;
    e.preventDefault();
    try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* ignore */ }
    if (!actionRef.current(false)) return;
    holdRef.current = window.setTimeout(() => {
      repeatRef.current = window.setInterval(() => { if (!actionRef.current(true)) stop(); }, 110);
    }, 260);
  };
  return { onPointerDown: down, onPointerUp: stop, onPointerCancel: stop, onLostPointerCapture: stop, onContextMenu: (e: MouseEvent) => { e.preventDefault(); } };
}
type Save = typeof start & { gameResult: GameResult; settling: boolean; dawn: boolean; summary: Summary };
function readSave(): Save | null {
  try {
    if (typeof window === 'undefined') return null;
    const raw = localStorage.getItem(SAVE_KEY); if (!raw) return null;
    const s = JSON.parse(raw);
    if (typeof s.readyEggs !== 'number' || typeof s.coins !== 'number') return null;
    const overlay = !!(s.summary || s.gameResult);
    const wealthLog = Array.isArray(s.wealthLog) ? s.wealthLog.filter((n: unknown) => typeof n === 'number' && Number.isFinite(n)) : [];
    const flock = clampFlock(typeof s.hens === 'number' ? s.hens : start.hens, typeof s.youngChicks === 'number' ? s.youngChicks : start.youngChicks);
    const price = Math.max(1, typeof s.price === 'number' ? s.price : start.price);
    const shares = Math.max(0, typeof s.shares === 'number' ? s.shares : 0);
    const coins = Math.max(0, typeof s.coins === 'number' ? s.coins : start.coins);
    const hatching = Math.max(0, Math.min(1, typeof s.hatching === 'number' ? s.hatching : 0));
    const pendingEggs = Math.max(0, typeof s.pendingEggs === 'number' ? s.pendingEggs : 0);
    const seenTitle = typeof s.seenTitle === 'number' ? s.seenTitle : 0;
    const news = isNews(s.news) ? s.news : pickNews(price);
    return {
      ...start, ...s, ...flock, price, shares, coins, hatching, pendingEggs, seenTitle, news,
      leftMs: typeof s.leftMs === 'number' ? Math.max(0, Math.min(DAY_MS, s.leftMs)) : DAY_MS,
      history: Array.isArray(s.history) && s.history.length ? s.history.map((n: number) => Math.max(1, n)) : start.history,
      wealthLog: wealthLog.length ? wealthLog : start.wealthLog,
      settling: overlay, dawn: false, gameResult: s.gameResult ?? null, summary: s.summary ?? null,
    };
  } catch { return null; }
}
function TickNum({ value, ms }: { value: number; ms: number }) {
  const [n, setN] = useState(value); const shown = useRef(value);
  useEffect(() => {
    const from = shown.current, to = value; if (from === to) return;
    const t0 = performance.now(); let raf = 0;
    const step = (now: number) => {
      const t = Math.min(1, (now - t0) / Math.max(80, ms)), e = 1 - Math.pow(1 - t, 3), cur = Math.round(from + (to - from) * e);
      shown.current = cur; setN(cur); if (t < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step); return () => cancelAnimationFrame(raf);
  }, [value, ms]);
  return <span className="tick-num">{n}</span>;
}

export default function Home() {
  const [booted, setBooted] = useState(false);
  const [coins, setCoins] = useState(start.coins);
  const [eggs, setEggs] = useState(start.eggs);
  const [readyEggs, setReadyEggs] = useState(start.readyEggs);
  const [pendingEggs, setPendingEggs] = useState(start.pendingEggs);
  const [hens, setHens] = useState(start.hens);
  const [youngChicks, setYoungChicks] = useState(start.youngChicks);
  const [cakes, setCakes] = useState(start.cakes);
  const [cakesSold, setCakesSold] = useState(start.cakesSold);
  const [shares, setShares] = useState(start.shares);
  const [price, setPrice] = useState(start.price);
  const [day, setDay] = useState(start.day);
  const [leftMs, setLeftMs] = useState(start.leftMs);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [flyers, setFlyers] = useState<Flyer[]>([]);
  const [history, setHistory] = useState(start.history);
  const [wealthLog, setWealthLog] = useState(start.wealthLog);
  const [baking, setBaking] = useState(start.baking);
  const [hatching, setHatching] = useState(start.hatching);
  const [hatched, setHatched] = useState(start.hatched);
  const [showQuest, setShowQuest] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [settling, setSettling] = useState(false);
  const [dawn, setDawn] = useState(false);
  const [summary, setSummary] = useState<Summary>(null);
  const [gameResult, setGameResult] = useState<GameResult>(null);
  const [wealthPop, setWealthPop] = useState<'off' | 'pop' | 'big'>('off');
  const [boardOpen, setBoardOpen] = useState(true);
  const [seenGoal, setSeenGoal] = useState(start.seenGoal);
  const [seenTitle, setSeenTitle] = useState(start.seenTitle);
  const [retryWait, setRetryWait] = useState(0);
  const [audioOn, setAudioOn] = useState(true);
  const [ambOn, setAmbOn] = useState(true);
  const [tickMs, setTickMs] = useState(480);
  const [reveal, setReveal] = useState<'off' | 'spoil' | 'news' | 'price' | 'card'>('off');
  const [flash, setFlash] = useState<'off' | 'up' | 'down' | 'up-big' | 'down-big'>('off');
  const [banner, setBanner] = useState<Rank | null>(null);
  const [fanfare, setFanfare] = useState(false);
  const [stamped, setStamped] = useState(false);
  const [justGrown, setJustGrown] = useState(0);
  const [news, setNews] = useState<NewsId>(start.news);

  const leftMsRef = useRef(leftMs); leftMsRef.current = leftMs;
  const sharesRef = useRef(shares); sharesRef.current = Math.max(0, shares);
  const coinsRef = useRef(coins); coinsRef.current = Math.max(0, coins);
  const hensRef = useRef(hens); hensRef.current = hens;
  const youngRef = useRef(youngChicks); youngRef.current = youngChicks;
  const readyEggsRef = useRef(readyEggs); readyEggsRef.current = readyEggs;
  const pendingEggsRef = useRef(pendingEggs); pendingEggsRef.current = pendingEggs;
  const eggsRef = useRef(eggs); eggsRef.current = eggs;
  const hatchedRef = useRef(hatched); hatchedRef.current = hatched;
  const cakesRef = useRef(cakes); cakesRef.current = cakes;
  const cakesSoldRef = useRef(cakesSold); cakesSoldRef.current = cakesSold;
  const hatchingRef = useRef(hatching); hatchingRef.current = hatching;
  const bakingRef = useRef(baking); bakingRef.current = baking;
  const fanfareRef = useRef(false); fanfareRef.current = fanfare;
  const seenTitleRef = useRef(seenTitle); seenTitleRef.current = seenTitle;
  const questDone = useRef(false);
  const skipQuestFx = useRef(true);
  const panicTold = useRef(false);
  const newsRef = useRef<NewsId>(start.news); newsRef.current = news;

  const cash = Math.max(0, coins), held = Math.max(0, shares);
  const total = cash + held * Math.max(1, price);
  const stockValue = held * Math.max(1, price);
  const birds = hens + youngChicks + hatched + hatching;
  const wealthHit = total >= WEALTH_GOAL, flockHit = birds >= FLOCK_GOAL, questComplete = wealthHit && flockHit;
  const endRank = rankOf(total);
  const prevPrice = Math.max(1, history.at(-2) ?? price);
  const priceUp = price >= prevPrice, priceDelta = price - prevPrice;
  const priceLine = (history.at(-1) === price ? history : [...history, price]).map(v => Math.max(1, v));
  const timeGone = leftMs <= 0 && !settling && !gameResult;
  const leftoverEggs = eggs + readyEggs + pendingEggs;
  const eggPanic = !settling && !gameResult && leftMs > 0 && leftMs <= DUSK_WARN_MS && leftoverEggs > 0;
  const canBuy = cash >= price && price > 0;
  const wealthPts = wealthLog.at(-1) === total ? wealthLog : [...wealthLog, total];
  const coopBirds = flockSprites(hens, youngChicks, justGrown);
  const dayGone = Math.max(0, Math.min(1, 1 - leftMs / DAY_MS));

  const notify = (text: string) => {
    const id = Date.now();
    setToasts(a => [...a.slice(-2), { id, text }]);
    setTimeout(() => setToasts(a => a.filter(x => x.id !== id)), 2200);
  };
  const pingWealth = (big = false) => {
    setWealthPop(big ? 'big' : 'pop');
    setTimeout(() => setWealthPop('off'), big ? 640 : 420);
  };
  const spawn = (kind: Flyer['kind'], delay = 0, at?: Flyer['at']) => {
    const id = Date.now() + Math.random();
    const burst = kind === 'burst-coin' || kind === 'burst-chick';
    const extra = burst ? { x: 8 + Math.random() * 84, y: 6 + Math.random() * 66 } : undefined;
    const add = () => {
      setFlyers(a => [...a, { id, kind, at, ...extra }]);
      setTimeout(() => setFlyers(a => a.filter(x => x.id !== id)), burst ? 1600 : kind === 'payout' ? 820 : kind === 'waste' ? 1400 : 780);
    };
    delay ? setTimeout(add, delay) : add();
  };

  useEffect(() => {
    const s = readSave();
    if (s) {
      setCoins(s.coins); setEggs(s.eggs); setReadyEggs(s.readyEggs);
      setPendingEggs(s.pendingEggs || 0); pendingEggsRef.current = s.pendingEggs || 0;
      setHens(s.hens); setYoungChicks(s.youngChicks); setCakes(s.cakes); cakesSoldRef.current = typeof s.cakesSold === 'number' ? s.cakesSold : 0; setCakesSold(cakesSoldRef.current); setShares(s.shares);
      setPrice(s.price); setDay(s.day); setLeftMs(s.leftMs); leftMsRef.current = s.leftMs;
      setHistory(s.history); setWealthLog(s.wealthLog); setBaking(s.baking || 0);
      setHatching(s.hatching || 0); setHatched(s.hatched || 0); setBoardOpen(s.boardOpen !== false);
      setSeenGoal(s.seenGoal || 0); setSeenTitle(s.seenTitle || 0); seenTitleRef.current = s.seenTitle || 0;
      setGameResult(s.gameResult ?? null); setSettling(!!s.settling);
      setReveal(s.summary || s.gameResult ? 'card' : 'off'); setDawn(false); setSummary(s.summary ?? null);
      const loadedNews = isNews(s.news) ? s.news : pickNews(s.price); setNews(loadedNews); newsRef.current = loadedNews;
    } else {
      const n = pickNews(start.price); setNews(n); newsRef.current = n;
    }
    const a = sfx.prefs(); setAudioOn(a.sfx); setAmbOn(a.amb);
    setBooted(true);
  }, []);
  useEffect(() => {
    if (!booted) return;
    sfx.setFlock(hens, youngChicks + hatched);
  }, [booted, hens, youngChicks, hatched]);
  useEffect(() => {
    if (!booted) return;
    const payload: Save = {
      coins: cash, eggs, readyEggs, pendingEggs, hens, youngChicks, cakes, cakesSold, shares: held, price, day,
      leftMs: leftMsRef.current, history, wealthLog, baking, hatching, hatched, boardOpen, seenGoal, seenTitle, news,
      gameResult, settling, dawn, summary,
    };
    localStorage.setItem(SAVE_KEY, JSON.stringify(payload));
  }, [booted, cash, eggs, readyEggs, pendingEggs, hens, youngChicks, cakes, cakesSold, held, price, day, history, wealthLog, baking, hatching, hatched, boardOpen, seenGoal, seenTitle, news, gameResult, settling, dawn, summary]);
  useEffect(() => {
    if (!booted) return;
    const t = setInterval(() => {
      try { const raw = localStorage.getItem(SAVE_KEY); if (!raw) return; const s = JSON.parse(raw); s.leftMs = leftMsRef.current; localStorage.setItem(SAVE_KEY, JSON.stringify(s)); } catch { /* ignore */ }
    }, 1000);
    return () => clearInterval(t);
  }, [booted]);
  useEffect(() => {
    if (!booted || settling || gameResult) return;
    let last = performance.now(), acc = 0, raf = 0;
    const loop = (now: number) => {
      const dt = now - last; last = now;
      if (fanfareRef.current) { raf = requestAnimationFrame(loop); return; }
      if (typeof document === 'undefined' || !document.hidden) {
        acc += dt;
        if (acc >= 80) { const spent = acc; acc = 0; setLeftMs(v => { const n = Math.max(0, v - spent); leftMsRef.current = n; return n; }); }
      }
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [booted, settling, gameResult]);
  useEffect(() => {
    if (!booted) return;
    setWealthLog(v => v.at(-1) === total ? v : [...v.slice(-31), total]);
  }, [booted, total]);
  useEffect(() => {
    if (!booted || gameResult || reveal === 'card') return;
    const r = rankOf(total);
    if (r.min <= seenTitleRef.current || r.min === 0) return;
    seenTitleRef.current = r.min; setSeenTitle(r.min); setBanner(r);
    sfx.rank();
    const t = window.setTimeout(() => setBanner(b => b && b.lv === r.lv ? null : b), 1600);
    return () => clearTimeout(t);
  }, [booted, total, gameResult, settling, reveal]);
  useEffect(() => {
    if (!booted || gameResult || settling) return;
    if (skipQuestFx.current) { skipQuestFx.current = false; questDone.current = questComplete; if (questComplete) setStamped(true); return; }
    if (questComplete) {
      if (questDone.current) return;
      questDone.current = true; setFanfare(true); fanfareRef.current = true; setShowQuest(true); setStamped(false);
      sfx.quest();
      notify('双线达标！');
      for (let i = 0; i < 22; i++) {
        const kind = i % 3 === 0 ? 'burst-chick' as const : 'burst-coin' as const;
        spawn(kind, i * 55, undefined);
      }
      window.setTimeout(() => { setStamped(true); sfx.stamp(); }, 780);
      window.setTimeout(() => { setFanfare(false); fanfareRef.current = false; }, 3400);
    } else { questDone.current = false; setStamped(false); }
  }, [booted, questComplete, gameResult, settling]);
  useEffect(() => { if (showQuest) setSeenGoal(1); }, [showQuest]);
  useEffect(() => {
    if (!booted || settling || gameResult || fanfare || leftMs <= 0) return;
    if (leftMs > DUSK_WARN_MS) { panicTold.current = false; return; }
    if (pendingEggsRef.current > 0) {
      readyEggsRef.current += pendingEggsRef.current;
      setReadyEggs(readyEggsRef.current);
      pendingEggsRef.current = 0; setPendingEggs(0);
    }
    if (!panicTold.current && leftoverEggs > 0) {
      panicTold.current = true;
      notify('天快黑了，蛋会碎！');
      sfx.warn();
    }
  }, [booted, leftMs, leftoverEggs, settling, gameResult, fanfare]);
  useEffect(() => {
    if (!gameResult) { setRetryWait(0); return; }
    setRetryWait(3);
    const t = window.setInterval(() => setRetryWait(v => v <= 1 ? (clearInterval(t), 0) : v - 1), 1000);
    return () => clearInterval(t);
  }, [gameResult]);
  useEffect(() => {
    if (!baking || baking >= 100 || fanfare) return;
    const timer = setInterval(() => setBaking(v => Math.min(100, v + 5)), 120);
    return () => clearInterval(timer);
  }, [baking, fanfare]);
  useEffect(() => {
    if (baking === 100) {
      cakesRef.current += 1; setCakes(cakesRef.current);
      sfx.bakeDone();
      const timer = setTimeout(() => { setBaking(0); bakingRef.current = 0; }, 700);
      return () => clearTimeout(timer);
    }
  }, [baking]);
  useEffect(() => {
    if (baking || eggs < 2 || settling || gameResult || fanfare || leftMsRef.current <= 0) return;
    const timer = setTimeout(() => {
      if (bakingRef.current || eggsRef.current < 2 || leftMsRef.current <= 0 || fanfareRef.current) return;
      setEggs(v => { const n = Math.max(0, v - 2); eggsRef.current = n; return n; });
      setBaking(5); bakingRef.current = 5;
      sfx.bakeStart();
    }, 450);
    return () => clearTimeout(timer);
  }, [baking, eggs, settling, gameResult, fanfare]);
  useEffect(() => {
    if (!booted || settling || gameResult || fanfare || pendingEggs < 1) return;
    const remain = pendingEggsRef.current, wait = Math.max(900, Math.min(2800, (leftMsRef.current - 1400) / Math.max(1, remain)));
    const timer = window.setTimeout(() => {
      if (settling || gameResult || fanfareRef.current || pendingEggsRef.current < 1 || leftMsRef.current <= 0) return;
      pendingEggsRef.current -= 1; setPendingEggs(pendingEggsRef.current);
      readyEggsRef.current += 1; setReadyEggs(readyEggsRef.current);
      sfx.eggReady();
    }, wait);
    return () => clearTimeout(timer);
  }, [booted, settling, gameResult, fanfare, pendingEggs]);

  const nextDay = () => {
    if (settling || gameResult) return;
    if (bakingRef.current > 0 && bakingRef.current < 100) { cakesRef.current += 1; setCakes(cakesRef.current); }
    setBaking(0); bakingRef.current = 0;
    const stored = eggsRef.current, loose = readyEggsRef.current + pendingEggsRef.current, leftover = stored + loose;
    const hatchOpen = hatchingRef.current < 1 && hatchedRef.current < 1;
    let autoHatch = false, broken = 0;
    if (hatchOpen && leftover === 1) {
      hatchingRef.current = 1; setHatching(1); autoHatch = true;
      eggsRef.current = 0; setEggs(0); readyEggsRef.current = 0; setReadyEggs(0); pendingEggsRef.current = 0; setPendingEggs(0);
      sfx.hatch();
    } else if (leftover > 0) {
      broken = leftover;
      const showStore = Math.min(8, stored), showLoose = Math.min(8, loose);
      for (let i = 0; i < showLoose; i++) spawn('waste', i * 80, 'coop');
      for (let i = 0; i < showStore; i++) spawn('waste', i * 80, hatchOpen ? 'hatch' : 'bakery');
      eggsRef.current = 0; setEggs(0); readyEggsRef.current = 0; setReadyEggs(0); pendingEggsRef.current = 0; setPendingEggs(0);
      sfx.shatter();
    }
    const tonight = newsRef.current, oldP = price, p = nextPrice(price, tonight), big = Math.abs(p - oldP) / Math.max(1, oldP) >= .22;
    const heldNow = Math.max(0, sharesRef.current), closingTotal = Math.max(0, coinsRef.current) + heldNow * p;
    const grown = youngRef.current, hatchReady = hatchingRef.current, sold = cakesSoldRef.current;
    const birdsNow = hensRef.current + youngRef.current + hatchingRef.current + hatchedRef.current;
    const jumpMs = big ? 700 : 400 + Math.round(Math.random() * 180);
    const startNight = () => {
      setShowQuest(false); setShowSettings(false); setSettling(true); setDawn(false); setSummary(null);
      setReveal('news'); setFlash('off');
      sfx.setNight(true); sfx.dusk();
      window.setTimeout(() => {
        setReveal('price'); setFlash(p >= oldP ? (big ? 'up-big' : 'up') : (big ? 'down-big' : 'down'));
        setTickMs(jumpMs); setPrice(p); setHistory(v => [...v.slice(-6), p]);
        sfx.price(p >= oldP, big);
        window.setTimeout(() => {
          setFlash('off');
          if (autoHatch) notify('孵蛋器空着，剩下的 1 枚蛋放进去了');
          else if (leftover > 0) notify('今天的蛋没有留到明天');
          setReveal('card');
          if (day === 8) { setGameResult('ended'); sfx.ending(rankOf(closingTotal).tone); return; }
          setSummary({ broken, grown, cakesSold: sold, oldPrice: oldP, newPrice: p, day: day + 1, hatched: hatchReady, wealth: closingTotal, flock: birdsNow, news: tonight });
        }, jumpMs + (big ? 280 : 90));
      }, 1500);
    };
    setShowQuest(false); setShowSettings(false); setSettling(true); setDawn(false); setSummary(null); setFlash('off');
    if (broken > 0) {
      setReveal('spoil');
      const spoilMs = 1180 + Math.max(0, Math.max(Math.min(8, stored), Math.min(8, loose)) - 1) * 80;
      window.setTimeout(startNight, spoilMs);
    } else startNight();
  };
  const nextDayRef = useRef(nextDay); nextDayRef.current = nextDay;
  useEffect(() => {
    if (!booted || leftMs > 0 || settling || gameResult) return;
    const timer = setTimeout(() => nextDayRef.current(), 400);
    return () => clearTimeout(timer);
  }, [booted, leftMs, settling, gameResult]);

  const wakeToDawn = () => {
    if (dawn || !summary) return;
    const grown = summary.grown || 0, nextHens = hens + grown, laid = Math.max(0, nextHens);
    setDay(summary.day); setLeftMs(DAY_MS); leftMsRef.current = DAY_MS;
    setHens(nextHens); hensRef.current = nextHens; setYoungChicks(0); youngRef.current = 0; setJustGrown(grown);
    setHatched(v => v + (summary.hatched || 0)); setHatching(0); hatchingRef.current = 0;
    setReadyEggs(laid > 0 ? 1 : 0); readyEggsRef.current = laid > 0 ? 1 : 0;
    setPendingEggs(Math.max(0, laid - 1)); pendingEggsRef.current = Math.max(0, laid - 1);
    setEggs(0); eggsRef.current = 0; setCakesSold(0); cakesSoldRef.current = 0; setSummary(null); setReveal('off'); setDawn(true); setTickMs(480);
    panicTold.current = false;
    const n = pickNews(price); setNews(n); newsRef.current = n;
    sfx.setNight(false); sfx.dawn();
    window.setTimeout(() => setJustGrown(0), 900);
    window.setTimeout(() => { setSettling(false); setDawn(false); }, 1600);
  };
  const blocked = () => !!(gameResult || settling || leftMsRef.current <= 0);
  const collectEgg = (quiet = false) => {
    if (blocked()) return false;
    if (readyEggsRef.current < 1) { if (!quiet) { notify('今天的鸡蛋已经收完啦'); sfx.deny(); } return false; }
    readyEggsRef.current -= 1; setReadyEggs(readyEggsRef.current); spawn('egg'); sfx.egg();
    setTimeout(() => setEggs(v => { const n = v + 1; eggsRef.current = n; return n; }), 650);
    return true;
  };
  const collectChick = (quiet = false) => {
    if (blocked()) return false;
    if (hatchedRef.current < 1) { if (!quiet) { notify('还没有孵出来的小鸡'); sfx.deny(); } return false; }
    hatchedRef.current -= 1; setHatched(hatchedRef.current); spawn('chick'); sfx.chick();
    setTimeout(() => setYoungChicks(v => v + 1), 650);
    return true;
  };
  const startHatch = (quiet = false) => {
    if (blocked()) return false;
    if (hatchingRef.current >= 1) { if (!quiet) { notify('每天只能孵 1 枚蛋'); sfx.deny(); } return false; }
    if (eggsRef.current < 1) { if (!quiet) { notify('还差鸡蛋'); sfx.deny(); } return false; }
    eggsRef.current -= 1; setEggs(eggsRef.current); hatchingRef.current = 1; setHatching(1);
    sfx.hatch();
    if (!quiet) notify('放进孵蛋器啦，明天出壳');
    return true;
  };
  const sellOneCake = (quiet = false) => {
    if (blocked()) return false;
    if (cakesRef.current < 1) { if (!quiet) { notify('还没有可出售的蛋糕'); sfx.deny(); } return false; }
    cakesRef.current -= 1; setCakes(cakesRef.current); cakesSoldRef.current += 1; setCakesSold(cakesSoldRef.current); spawn('cake'); spawn('payout', 80, 'bakery'); setTickMs(500);
    setTimeout(() => { sfx.coin(); setCoins(v => { const n = v + CAKE_SALE; coinsRef.current = n; return n; }); pingWealth(); }, 720);
    return true;
  };
  const buyShares = (quiet = false) => {
    if (blocked()) return false;
    if (price <= 0 || coinsRef.current < price) { if (!quiet) { notify('金币不够买入一股'); sfx.deny(); } return false; }
    setTickMs(920); coinsRef.current -= price; sharesRef.current += 1; setCoins(coinsRef.current); setShares(sharesRef.current);
    spawn('spend'); sfx.buyShare(); setTimeout(() => pingWealth(true), 280);
    return true;
  };
  const sellShares = (quiet = false) => {
    if (blocked()) return false;
    if (sharesRef.current < 1) { if (!quiet) { notify('还没有持股'); sfx.deny(); } return false; }
    const gain = Math.max(0, price); setTickMs(900); sharesRef.current -= 1; setShares(sharesRef.current); spawn('coin');
    sfx.sellShare();
    setTimeout(() => { setCoins(v => { const n = Math.max(0, v + gain); coinsRef.current = n; return n; }); pingWealth(true); }, 720);
    return true;
  };
  const buyChick = (quiet = false) => {
    if (blocked()) return false;
    if (coinsRef.current < CHICK_COST) { if (!quiet) { notify('金币不够买小鸡'); sfx.deny(); } return false; }
    setTickMs(480); coinsRef.current -= CHICK_COST; setCoins(coinsRef.current); setYoungChicks(v => v + 1); spawn('spend'); sfx.spend(); sfx.chick(); pingWealth();
    return true;
  };
  const sellHen = (quiet = false) => {
    if (blocked()) return false;
    if (hensRef.current < 1) { if (!quiet) { notify('还没有可以卖的母鸡'); sfx.deny(); } return false; }
    setTickMs(480); hensRef.current -= 1; setHens(hensRef.current); spawn('coin'); sfx.coin();
    setTimeout(() => { setCoins(v => { const n = v + CHICK_SALE; coinsRef.current = n; return n; }); pingWealth(); }, 650);
    return true;
  };
  const holdEgg = useRepeater(collectEgg), holdChick = useRepeater(collectChick), holdHatch = useRepeater(startHatch), holdCake = useRepeater(sellOneCake);
  const holdBuyShare = useRepeater(buyShares), holdSellShare = useRepeater(sellShares), holdBuyChick = useRepeater(buyChick), holdSellHen = useRepeater(sellHen);
  const restart = () => {
    localStorage.removeItem(SAVE_KEY);
    setCoins(start.coins); setEggs(start.eggs); setReadyEggs(start.readyEggs); setPendingEggs(start.pendingEggs); pendingEggsRef.current = 0;
    setHens(start.hens); setYoungChicks(start.youngChicks); setCakes(start.cakes); setCakesSold(0); cakesSoldRef.current = 0; setShares(start.shares); setPrice(start.price);
    setDay(start.day); setLeftMs(DAY_MS); leftMsRef.current = DAY_MS; setHistory(start.history); setWealthLog(start.wealthLog);
    setBaking(0); setHatching(0); setHatched(0); setFlyers([]); setShowQuest(false); setShowSettings(false); setBoardOpen(true);
    setSeenGoal(0); setSeenTitle(0); seenTitleRef.current = 0; setSettling(false); setDawn(false); setSummary(null); setGameResult(null);
    setRetryWait(0); setReveal('off'); setFlash('off'); setBanner(null); setFanfare(false); fanfareRef.current = false;
    setJustGrown(0); setTickMs(480); questDone.current = false; skipQuestFx.current = false; setStamped(false); panicTold.current = false;
    const n = pickNews(start.price); setNews(n); newsRef.current = n;
    sfx.setNight(false);
  };

  if (!booted) return <main className="game" />;
  const showCard = reveal === 'card';
  const popClass = wealthPop === 'big' ? ' big-pop' : wealthPop === 'pop' ? ' pop' : '';
  const headline = NEWS[news];
  return <main className="game"><div className={`map${settling && reveal !== 'spoil' ? ` dusk${dawn ? ' dawn' : ''}` : ''}${reveal === 'spoil' ? ' egg-spoil' : ''}${reveal === 'news' ? ' news-reveal' : ''}${reveal === 'price' ? ' price-reveal' : ''}${fanfare ? ' fanfare' : ''}`} aria-label="咯咯农场手绘地图" onPointerDown={() => sfx.unlock()}>
    {banner && <div className="title-banner" role="status"><strong>{banner.title}</strong></div>}
    <header className="hud">
      <DayClock left={leftMs} day={day} empty={timeGone} />
      <div className="hud-right">
        <div className={`hud-bar${popClass}`}>
          <div className="hud-stat" title="口袋里的金币"><GameIcon name="coin" className="hud-ico" /><div><small>现金</small><strong><TickNum value={cash} ms={tickMs} /></strong></div></div>
          <i className="hud-split" />
          <div className="hud-stat" title="持股市值"><GameIcon name="stock" className="hud-ico chart" /><div><small>股票</small><strong><TickNum value={stockValue} ms={tickMs} /></strong></div></div>
        </div>
        <button className="settings-button" onClick={() => setShowSettings(true)} aria-label="打开游戏设置">⚙</button>
      </div>
    </header>
    {timeGone && <div className="steps-banner" role="status">今日已尽 · 正在收工过夜</div>}
    <div className="nest-flock" aria-hidden="true">{coopBirds.nest.map(b => <FlockUnit bird={b} key={b.key} />)}</div>
    {coopBirds.yard.length > 0 && <div className="yard-flock" aria-hidden="true">{coopBirds.yard.map(b => <FlockUnit bird={b} key={b.key} />)}</div>}
    {readyEggs > 0 && <button className={`thought coop-thought${eggPanic ? ' egg-panic' : ''}`} {...holdEgg} disabled={timeGone} aria-label={timeGone ? '今日已尽，无法收蛋' : eggPanic ? `天快黑了，快收蛋，剩余 ${readyEggs} 枚` : `收集鸡蛋，剩余 ${readyEggs} 枚`}><img className="thought-egg" src="/ui/egg-basket.png" alt="" /><b>×{readyEggs}</b></button>}
    <div className="wolf-shop">
      <div className="wolf-talk">
        <p>小鸡五十，母鸡四十回收～</p>
        <div className="chick-rows">
          <button className="price-btn buy" {...holdBuyChick} disabled={cash < CHICK_COST || timeGone} aria-label={timeGone ? '今日已尽' : cash < CHICK_COST ? '金币不够买小鸡' : '买一只小鸡'}><span>买小鸡</span><em><GameIcon name="coin" />{CHICK_COST}</em></button>
          <button className="price-btn sell" {...holdSellHen} disabled={hens < 1 || timeGone} aria-label={timeGone ? '今日已尽' : hens < 1 ? '还没有可以卖的母鸡' : '卖掉一只母鸡'}><span>卖母鸡</span><em><GameIcon name="coin" />{CHICK_SALE}</em></button>
        </div>
      </div>
      <div className="wolf-merchant" aria-hidden="true"><SheetSprite row={4} play="loop" /></div>
    </div>
    <Landmark cls={`hatch-building map-incubator${hatching ? ' warming' : ''}${hatched ? ' ready' : ''}`}>{(hatching > 0 || hatched > 0) && <span className={`hatch-egg${hatched ? ' popped' : ''}`}><SheetSprite key={hatched ? 'out' : 'in'} row={3} play={hatched ? 'once' : 'warm'} /></span>}</Landmark>
    {hatched > 0 && <button className="thought hatch-thought ready" {...holdChick} disabled={timeGone} aria-label={timeGone ? '今日已尽，无法领小鸡' : `领取小鸡，剩余 ${hatched} 只`}><SheetSprite row={1} play="loop" className="thought-chick" /><b>×{hatched}</b></button>}
    {!hatched && hatching > 0 && <button className="thought hatch-thought warming" onClick={() => notify('每天只能孵 1 枚，明天出壳')} disabled={timeGone} aria-label="孵蛋中，明天出壳"><GameIcon name="egg" /><small>明</small></button>}
    {!hatched && !hatching && eggs > 0 && <button className={`thought hatch-thought${eggPanic ? ' egg-panic' : ''}`} {...holdHatch} disabled={timeGone} aria-label={timeGone ? '今日已尽，无法孵蛋' : eggPanic ? '天快黑了，把蛋放进孵蛋器' : '把鸡蛋放进孵蛋器'}><GameIcon name="egg" /></button>}
    <Landmark cls="bakery-building">{baking > 0 && <div className="baker-sprite" aria-hidden="true"><i /></div>}{eggs > 0 && <b className="bakery-eggs"><GameIcon name="egg" />{eggs}</b>}</Landmark>
    {(baking > 0 || cakes > 0) && <button className={`thought bakery-thought${baking > 0 ? ' baking' : ''}`} {...holdCake} disabled={cakes < 1 || timeGone} aria-label={timeGone ? '今日已尽，无法卖蛋糕' : cakes > 0 ? `出售蛋糕，现有 ${cakes} 个` : baking > 0 ? `蛋糕制作中 ${baking}%` : '暂无可出售蛋糕'}><GameIcon name="cake" />{cakes > 0 && <b>×{cakes}</b>}{baking > 0 && <i className="thought-bar"><em style={{ width: `${baking}%` }} /></i>}</button>}
    <div className="ticker-cluster">
      <Landmark cls="ticker-building">
        <div className={`ticker-face ${priceUp ? 'up' : 'down'}${flash === 'up' || flash === 'up-big' ? ' flash-up' : flash === 'down' || flash === 'down-big' ? ' flash-down' : ''}${flash.endsWith('big') ? ' flash-big' : ''}${reveal === 'price' ? ' open-box' : ''}`}>
          <div className="ticker-head"><small>金币</small><strong><TickNum value={price} ms={tickMs} /></strong><b>{priceUp ? '▲' : '▼'}{Math.abs(priceDelta)}</b></div>
          <StockGraph values={priceLine} up={priceUp} />
          <p className="ticker-hold">{held}股</p>
        </div>
      </Landmark>
      <div className="trade-row">
        <button className="trade buy" {...holdBuyShare} disabled={!canBuy || timeGone} aria-label={timeGone ? '今日已尽' : !canBuy ? '现金不足' : '买入 1 股'}>买1股</button>
        <button className="trade sell" {...holdSellShare} disabled={held < 1 || timeGone} aria-label={timeGone ? '今日已尽' : held < 1 ? '暂无持仓' : '卖出 1 股'}>卖1股</button>
      </div>
    </div>
    <button className={`quest-button${fanfare ? ' celebrate' : ''}`} onClick={() => { if (reveal === 'news') return; setShowQuest(v => !v); }} aria-label={`今夜告示：${headline.text}。查看农场任务`}>
      <img src="/layers/notice-board.png" alt="" />
      <span className={`board-note${headline.up ? ' up' : ' down'}`}><img className="board-weather" src={headline.weather} alt="" /><b>{headline.text.slice(0, 2)}</b><b>{headline.text.slice(2)}</b></span>
      {reveal !== 'news' && (questComplete ? <i className="thought-mark done">✓</i> : seenGoal < 1 && !showQuest ? <i className="thought-mark">!</i> : <b className="quest-chip">{(wealthHit ? 1 : 0) + (flockHit ? 1 : 0)}/2</b>)}
    </button>
    {showSettings && <div className="scrim settings-scrim" onMouseDown={() => setShowSettings(false)}><section className="settings-panel" onMouseDown={e => e.stopPropagation()} role="dialog" aria-label="游戏设置"><button className="close" aria-label="关闭游戏设置" onClick={() => setShowSettings(false)}>×</button><h2>设置</h2>
      <div className="setting-row sound-row"><GameIcon name="sound" /><div><strong>音效</strong><small>收蛋、买卖、过夜都有轻反馈</small></div>
        <button type="button" className={`audio-switch${audioOn ? ' on' : ''}`} onClick={() => { const n = !audioOn; setAudioOn(n); sfx.setSfx(n); if (n) sfx.egg(); }}>{audioOn ? '开' : '关'}</button>
      </div>
      <div className="setting-row sound-row"><GameIcon name="wind" /><div><strong>环境音</strong><small>微风，每只鸡会不定时叫，鸡越多越热闹</small></div>
        <button type="button" className={`audio-switch${ambOn ? ' on' : ''}`} onClick={() => { const n = !ambOn; setAmbOn(n); sfx.setAmb(n); }}>{ambOn ? '开' : '关'}</button>
      </div>
      <div className="setting-row"><span>🕒</span><div><strong>时钟走完就过夜</strong><small>白天里收蛋、买卖、孵蛋都不耗次数</small></div></div>
      <p>只点气泡和按钮。长按可以连续收、买、卖。告示牌白天先写出今夜消息，过夜按告示 → 股价 → 结算揭晓。鸡没有数量上限。河边孵蛋器每天只能孵 1 枚，过夜后点气泡领回鸡舍。天黑前 5 秒鸡蛋气泡会狂闪，当天没用完的鸡蛋不会留到明天。蛋糕自动加工，点蛋糕气泡卖掉。</p>
      <button className="restart-button" onClick={restart}>↻ 重新开始</button></section></div>}
    {showQuest && <section className={`quest-pop${questComplete ? ' done' : ''}${stamped ? ' stamped' : ''}${fanfare ? ' celebrating' : ''}`}>
      <small>农场任务</small>
      <strong>{questComplete ? '同一时刻双线达标' : '资产 3000，同时养 15 只鸡'}</strong>
      {stamped && <i className="quest-stamp">达标</i>}
      <div className="quest-metrics">
        <article className={wealthHit ? 'hit' : 'now'}>
          <GameIcon name="coin" /><small>总资产</small><b>{total}<i>/{WEALTH_GOAL}</i></b>
          <div className="mini-bar"><em style={{ width: `${Math.min(100, total / WEALTH_GOAL * 100)}%` }} /></div>
          <em>{wealthHit ? '已达标' : `还差 ${Math.max(0, WEALTH_GOAL - total)}`}</em>
        </article>
        <article className={flockHit ? 'hit' : ''}>
          <span>🐔</span><small>拥有鸡</small><b>{birds}<i>/{FLOCK_GOAL}</i></b>
          <div className="mini-bar"><em style={{ width: `${Math.min(100, birds / FLOCK_GOAL * 100)}%` }} /></div>
          <em>{flockHit ? '已达标' : `还差 ${Math.max(0, FLOCK_GOAL - birds)} 只`}</em>
        </article>
      </div>
      <p className={`quest-news${headline.up ? ' up' : ' down'}`}><img src={headline.weather} alt="" />今夜告示 · {headline.text}</p>
      <p className="quest-done-note">{questComplete ? '三千金币和十五只鸡，同一时刻到手。' : '两项要同时达到。资产掉下去或把鸡卖掉，完成会取消。'}</p>
    </section>}
    <div className="finish-dock"><button className={`day-end ${timeGone ? 'hurry empty' : ''}${!timeGone && leftMs <= DUSK_WARN_MS ? ' late' : ''}`} onClick={nextDay} disabled={settling} aria-label={day === 8 ? '最终结算' : '结束本日'}><GameIcon name="sun" className="sun" /><span className="track"><em style={{ width: `${dayGone * 100}%` }} /><i className="knob" style={{ left: `${dayGone * 100}%` }} /></span><GameIcon name={day === 8 ? 'trophy' : 'moon'} className="moon" /></button></div>
    <div className="fly-layer" aria-hidden="true">{flyers.map(f => {
      const burst = f.kind === 'burst-coin' || f.kind === 'burst-chick';
      const icon = f.kind === 'chick' || f.kind === 'burst-chick' ? <SheetSprite row={1} play="loop" /> : f.kind === 'waste' ? <SheetSprite row={2} play="once" /> : f.kind === 'payout' ? '+' + CAKE_SALE : f.kind === 'egg' ? '🥚' : f.kind === 'cake' ? '🧁' : '🪙';
      return <span className={`flyer ${f.kind}${f.at ? ` from-${f.at}` : ''}`} key={f.id} style={burst ? { ['--burst-x' as string]: `${f.x ?? 50}%`, ['--burst-y' as string]: `${f.y ?? 40}%` } : undefined}>{icon}</span>;
    })}</div>
    {settling && reveal !== 'spoil' && <div className={`night-layer${gameResult ? ' finale' : showCard && summary ? ' daily' : ''}${reveal === 'news' ? ' news' : ''}${reveal === 'price' ? ' reveal' : ''}`}>
      <div className="night-veil" />
      <div className="night-sky">✦ · ✧ · ✦</div>
      <div className="night-moon">{gameResult ? endRank.mascot : dawn ? '☀️' : '🌙'}</div>
      {reveal !== 'price' && reveal !== 'news' && !summary && !gameResult && <p className="cycle-copy">{dawn ? '新的一天亮了' : '农场慢慢安静下来了…'}</p>}
      {showCard && summary && <section className="settlement daily"><h2>今日结算</h2><div className="report-day">第 {summary.day - 1} 天 → 第 {summary.day} 天</div>{summary.news && <p className={`news-echo ${NEWS[summary.news].up ? 'up' : 'down'}`}>{NEWS[summary.news].text}</p>}<div className="day-ledger"><div className={summary.broken > 0 ? 'bad' : ''}><small>碎了</small><strong>{summary.broken}</strong><em>枚蛋</em></div><div><small>长成</small><strong>{summary.grown}</strong><em>只鸡</em></div><div><small>卖出</small><strong>{summary.cakesSold}</strong><em>块蛋糕</em></div></div><div className={`price-close ${summary.newPrice >= summary.oldPrice ? 'rise' : 'fall'}`}><small>股价</small><strong>{summary.newPrice}</strong><b>{summary.newPrice >= summary.oldPrice ? '▲' : '▼'}{Math.abs(summary.newPrice - summary.oldPrice)}</b></div>{(summary.hatched || 0) > 0 && <p className="flock-note">新孵 {summary.hatched} 只待领</p>}<button onClick={wakeToDawn}>开始新一天</button></section>}
      {showCard && gameResult && <section className={`settlement result-card ${endRank.tone}`}><small className="rank-tag">第 {endRank.lv} / 10 等</small><h2>{endRank.title}</h2><div className="result-mascot">{endRank.mascot}</div><div className="rank-pips">{ranks.map(r => <i className={r.lv === endRank.lv ? 'now' : total >= r.min ? 'hit' : ''} title={`${r.lv} ${r.title}`} key={r.lv} />)}</div><div className="report-grid flock-grid"><div><span>🪙</span><small>总资产</small><strong>{total}</strong></div><div><span>🐔</span><small>鸡</small><strong>{birds}</strong></div></div><p>{endRank.copy}{questComplete ? ' 任务也完成了。' : ' 任务未在八日内同时达成。'}</p><div className="wealth-wrap"><span>{Math.max(0, ...wealthPts)}</span><WealthChart values={wealthPts} /><div className="wealth-axis"><b>{Math.max(0, Math.min(...wealthPts))}</b><em>八日资产曲线</em></div></div><div className="price-result"><span>现金 {cash}</span><b>＋</b><span>股票 {held * Math.max(1, price)}</span></div><button className={retryWait ? 'waiting' : ''} onClick={restart} disabled={retryWait > 0}>{retryWait > 0 ? `${retryWait} 秒后可再挑战` : '重新挑战八天'}</button></section>}
    </div>}
  </div>
    <div className="toasts" aria-live="polite">{toasts.map(t => <div key={t.id}>{t.text}</div>)}</div>
  </main>;
}

function DayClock({ left, day, empty }: { left: number; day: number; empty: boolean }) {
  const frac = left / DAY_MS, late = left > 0 && left <= DUSK_WARN_MS, angle = (1 - frac) * 360;
  return <div className={`day-clock${empty ? ' empty' : late ? ' late' : ''}`} role="timer" aria-label={`第 ${day} / 8 天`}>
    <svg viewBox="0 0 36 36" aria-hidden="true">
      <circle className="clock-disk" cx="18" cy="18" r="16.6" />
      <path className="clock-remain" d={piePath(frac)} />
      {Array.from({ length: 12 }, (_, i) => { const a = i * 30 * Math.PI / 180, inner = i % 3 === 0 ? 12.6 : 14.1; return <line className={i % 3 === 0 ? 'clock-tick major' : 'clock-tick'} key={i} x1={18 + Math.sin(a) * inner} y1={18 - Math.cos(a) * inner} x2={18 + Math.sin(a) * 15.8} y2={18 - Math.cos(a) * 15.8} />; })}
      <line className="clock-hand" x1="18" y1="18" x2="18" y2="5.4" transform={`rotate(${angle} 18 18)`} />
      <circle className="clock-cap" cx="18" cy="18" r="1.7" />
    </svg>
    <div className="day-label">{day}/8天</div>
  </div>;
}
type GameIconName = 'coin' | 'coins' | 'egg' | 'basket' | 'cake' | 'stock' | 'share' | 'heart' | 'chick' | 'hen' | 'hatch' | 'wolf' | 'flock' | 'bad-egg' | 'buy' | 'sell' | 'sun' | 'moon' | 'cloud' | 'rain' | 'clock' | 'settings' | 'sound' | 'wind' | 'trophy' | 'crown' | 'gem' | 'ribbon' | 'complete' | 'tip' | 'up' | 'down';
function GameIcon({ name, className }: { name: GameIconName; className?: string }) {
  return <span className={`game-icon gi-${name}${className ? ` ${className}` : ''}`} aria-hidden="true" />;
}
function SheetSprite({ row, play = 'loop', className }: { row: 0 | 1 | 2 | 3 | 4; play?: 'loop' | 'once' | 'warm' | 'hold'; className?: string }) {
  return <span className={`sheet-sprite r${row} ${play}${className ? ` ${className}` : ''}`} aria-hidden="true"><i /></span>;
}
function FlockUnit({ bird }: { bird: FlockBird }) {
  return <span className={`coop-bird${bird.grown ? ' grown-pop' : ''}${bird.kind === 'young' ? ' young' : ''}`} style={{ left: `${bird.left}%`, top: `${bird.top}%`, zIndex: bird.z, ['--bird-scale' as string]: bird.size }}>
    <SheetSprite row={bird.kind === 'hen' ? 0 : 1} play="loop" />
  </span>;
}
function Landmark({ cls, src, children }: { cls: string; src?: string; children?: ReactNode }) {
  return <div className={`open-building ${cls}`} aria-hidden="true">{src ? <img src={src} alt="" /> : null}<div className="building-contents">{children}</div></div>;
}
function StockGraph({ values, up }: { values: number[]; up: boolean }) {
  const pts = values.length ? values.map(v => Math.max(0, v)) : [25], min = Math.min(...pts), max = Math.max(...pts), pad = Math.max((max - min) * 0.22, 4), lo = Math.max(0, min - pad), hi = max + pad, span = hi - lo || 1, n = Math.max(pts.length - 1, 1);
  const xy = pts.map((v, i) => ({ x: 2 + (i / n) * 96, y: 3 + (1 - (v - lo) / span) * 32 }));
  const line = xy.map((p, i) => `${i ? 'L' : 'M'}${p.x.toFixed(1)} ${p.y.toFixed(1)}`).join(' ');
  const last = xy[xy.length - 1];
  const area = `M${xy[0].x.toFixed(1)} 38 ${xy.map(p => `L${p.x.toFixed(1)} ${p.y.toFixed(1)}`).join(' ')} L${last.x.toFixed(1)} 38 Z`;
  return <svg className={`stock-graph ${up ? 'up' : 'down'}`} viewBox="0 0 100 38" preserveAspectRatio="none" aria-hidden="true"><path d={area} className="stock-fill" /><path d={line} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>;
}
function WealthChart({ values }: { values: number[] }) {
  const src = values.length ? values : [0], min = 0, max = Math.max(...src, ranks[9].min), pad = Math.max(max * 0.08, 40), span = (max + pad) - min || 1;
  const xy = src.length < 2 ? [{ x: 0, y: 4 + (1 - (src[0] - min) / span) * 34 }, { x: 100, y: 4 + (1 - (src[0] - min) / span) * 34 }] : src.map((v, i) => ({ x: (i / (src.length - 1)) * 100, y: 4 + (1 - (v - min) / span) * 34 }));
  const line = xy.map((p, i) => `${i ? 'L' : 'M'}${p.x.toFixed(2)} ${p.y.toFixed(2)}`).join(' ');
  const area = `M${xy[0].x.toFixed(2)} 42 ${xy.map(p => `L${p.x.toFixed(2)} ${p.y.toFixed(2)}`).join(' ')} L${xy[xy.length - 1].x.toFixed(2)} 42 Z`;
  return <svg className={`wealth-chart ${src[src.length - 1] >= src[0] ? 'up' : 'down'}`} viewBox="0 0 100 42" preserveAspectRatio="none" aria-hidden="true"><path d={area} className="wealth-fill" /><path d={line} fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>;
}
