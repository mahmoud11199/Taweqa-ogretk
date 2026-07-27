import { useState, useEffect, useRef, type ReactNode, type CSSProperties } from 'react'
import {
  Navigation, Users, Star, Clock, Zap, Shield, ChevronRight,
  Check, X, Plus, MoreVertical, Bell, Settings, TrendingUp,
  Activity, Car, AlertTriangle, Wifi, WifiOff, Battery, Signal,
  ArrowLeft, Wallet, RefreshCw, Play, Pause, Download, Globe,
  LogOut, BarChart2, Map, UserCheck, Layers, ArrowUpRight,
  ArrowDownRight, Sun, Moon, Eye, EyeOff, Search, Home,
  Calendar, MessageSquare, Phone, Mail, MapPin, Banknote,
  Radio, ChevronDown, Gauge, Route, CreditCard
} from 'lucide-react'
import {
  AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line
} from 'recharts'

// ─── Types ────────────────────────────────────────────────────────────────────
type Screen =
  | 'splash' | 'role' | 'auth' | 'otp'
  | 'driver-dashboard' | 'driver-dispatch' | 'driver-payment' | 'driver-wallet'
  | 'passenger-home' | 'passenger-tracking' | 'passenger-rating'
  | 'admin-dashboard' | 'landing'

type Role = 'driver' | 'passenger' | 'admin' | null
type Theme = 'dark' | 'light'

// ─── Theme tokens ─────────────────────────────────────────────────────────────
const TK = {
  dark: {
    bg: '#080D18', bg2: '#0C1220', card: '#0F1628', card2: '#152038',
    border: '#1C2B45', border2: '#243558',
    text: '#EDF2FC', sub: '#8EA4C8', muted: '#526480',
    teal: '#00E5B8', teal2: '#00B896',
    amber: '#FFB020', red: '#FF3B5C', blue: '#4D9FFF', green: '#22C97A',
    map: '#080E1C',
  },
  light: {
    bg: '#F2F6FF', bg2: '#E8EEF8', card: '#FFFFFF', card2: '#F0F5FF',
    border: '#DDE6F4', border2: '#C8D7EE',
    text: '#08101E', sub: '#3A4E6A', muted: '#6880A4',
    teal: '#00A882', teal2: '#008C6C',
    amber: '#D98A00', red: '#E02040', blue: '#2878E0', green: '#159654',
    map: '#B8CCEC',
  }
}

// ─── Design primitives ────────────────────────────────────────────────────────
function useTheme(): [Theme, () => void] {
  const [t, setT] = useState<Theme>('dark')
  return [t, () => setT(p => p === 'dark' ? 'light' : 'dark')]
}

const px = (n: number) => `${n}px`

function s(...args: (CSSProperties | false | null | undefined)[]): CSSProperties {
  return Object.assign({}, ...args.filter(Boolean))
}

// ── Button ────────────────────────────────────────────────────────────────────
function Btn({
  children, variant = 'primary', size = 'md', full = false,
  onClick, disabled = false, style: extra = {}, icon
}: {
  children: ReactNode; variant?: 'primary'|'ghost'|'danger'|'teal'|'amber'|'outline'
  size?: 'xs'|'sm'|'md'|'lg'; full?: boolean; onClick?: ()=>void
  disabled?: boolean; style?: CSSProperties; icon?: ReactNode
}) {
  const pad  = { xs:'7px 12px', sm:'10px 18px', md:'13px 24px', lg:'17px 32px' }
  const fz   = { xs:11, sm:13, md:14, lg:16 }
  const vCol = {
    primary: { bg:'#00E5B8', fg:'#080D18', br:'transparent' },
    ghost:   { bg:'transparent', fg:'#8EA4C8', br:'#1C2B45' },
    danger:  { bg:'#FF3B5C', fg:'#fff', br:'transparent' },
    teal:    { bg:'rgba(0,229,184,0.12)', fg:'#00E5B8', br:'rgba(0,229,184,0.3)' },
    amber:   { bg:'rgba(255,176,32,0.14)', fg:'#FFB020', br:'rgba(255,176,32,0.35)' },
    outline: { bg:'transparent', fg:'#8EA4C8', br:'#243558' },
  }
  const c = vCol[variant]
  const [hov, setHov] = useState(false)
  return (
    <button
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      onClick={onClick} disabled={disabled}
      style={s({
        display:'flex', alignItems:'center', justifyContent:'center', gap:7,
        background: disabled ? '#131E33' : hov && variant==='primary' ? '#00CCA8' : c.bg,
        color: disabled ? '#394A62' : c.fg,
        border: `1.5px solid ${disabled ? '#1C2B45' : c.br}`,
        borderRadius: 10, padding: pad[size],
        fontSize: fz[size], fontWeight:700,
        fontFamily:"'Plus Jakarta Sans',sans-serif",
        cursor: disabled ? 'not-allowed' : 'pointer',
        width: full ? '100%' : 'auto',
        transition:'all 0.16s ease',
        letterSpacing:'0.01em',
        transform: hov && !disabled ? 'translateY(-1px)' : 'none',
        boxShadow: hov && variant==='primary' && !disabled ? '0 4px 20px rgba(0,229,184,0.3)' : 'none',
      }, extra)}
    >
      {icon && icon}
      {children}
    </button>
  )
}

// ── Badge ─────────────────────────────────────────────────────────────────────
function Badge({ label, color='teal', dot=false }: {
  label:string; color?:'teal'|'amber'|'red'|'gray'|'blue'|'green'; dot?:boolean
}) {
  const c = {
    teal:  { bg:'rgba(0,229,184,0.12)',  fg:'#00E5B8', br:'rgba(0,229,184,0.25)' },
    amber: { bg:'rgba(255,176,32,0.12)', fg:'#FFB020', br:'rgba(255,176,32,0.28)' },
    red:   { bg:'rgba(255,59,92,0.12)',  fg:'#FF3B5C', br:'rgba(255,59,92,0.28)' },
    gray:  { bg:'rgba(82,100,128,0.18)', fg:'#8EA4C8', br:'rgba(82,100,128,0.3)' },
    blue:  { bg:'rgba(77,159,255,0.12)', fg:'#4D9FFF', br:'rgba(77,159,255,0.28)' },
    green: { bg:'rgba(34,201,122,0.12)', fg:'#22C97A', br:'rgba(34,201,122,0.28)' },
  }[color]
  return (
    <span style={{
      display:'inline-flex', alignItems:'center', gap:5,
      background:c.bg, color:c.fg, border:`1px solid ${c.br}`,
      borderRadius:6, padding:'3px 8px',
      fontSize:10, fontWeight:700, letterSpacing:'0.06em', textTransform:'uppercase'
    }}>
      {dot && <span style={{ width:5, height:5, borderRadius:'50%', background:c.fg, flexShrink:0 }} />}
      {label}
    </span>
  )
}

// ── Divider ───────────────────────────────────────────────────────────────────
function Div({ my=16, color='#1C2B45' }: { my?:number; color?:string }) {
  return <div style={{ height:1, background:color, margin:`${my}px 0` }} />
}

// ─── Status bar ───────────────────────────────────────────────────────────────
function StatusBar({ theme }: { theme: Theme }) {
  const fg = theme==='dark' ? '#EDF2FC' : '#08101E'
  return (
    <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center',
      padding:'14px 26px 6px', fontSize:12, fontWeight:700, color:fg, flexShrink:0 }}>
      <span style={{ fontFamily:"'JetBrains Mono',monospace" }}>9:41</span>
      <div style={{ display:'flex', gap:7, alignItems:'center' }}>
        <Signal size={13} /><Wifi size={13} /><Battery size={14} />
      </div>
    </div>
  )
}

// ─── Phone frame ──────────────────────────────────────────────────────────────
function PhoneFrame({ children, theme, style: extra={} }: {
  children: ReactNode; theme: Theme; style?: CSSProperties
}) {
  const isDark = theme === 'dark'
  return (
    <div style={s({
      width: 393, minHeight: 852,
      background: isDark ? '#080D18' : '#F2F6FF',
      borderRadius: 50,
      border: `2.5px solid ${isDark ? '#1C2B45' : '#C8D7EE'}`,
      overflow: 'hidden', position:'relative',
      display:'flex', flexDirection:'column',
      boxShadow: isDark
        ? '0 48px 96px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.03) inset'
        : '0 40px 80px rgba(0,0,0,0.18)',
    }, extra)}>
      {children}
    </div>
  )
}

// ── Screen chrome (title bar inside phone) ────────────────────────────────────
function ScreenBar({ title, onBack, right, theme }: {
  title?:string; onBack?:()=>void; right?:ReactNode; theme:Theme
}) {
  const fg = theme==='dark' ? '#EDF2FC' : '#08101E'
  const br = theme==='dark' ? '#1C2B45' : '#DDE6F4'
  if (!title && !onBack && !right) return null
  return (
    <div style={{
      display:'flex', alignItems:'center', padding:'8px 20px 10px',
      borderBottom:`1px solid ${br}`, gap:10, flexShrink:0,
    }}>
      {onBack && (
        <button onClick={onBack} style={{
          background:'none', border:'none', cursor:'pointer', color:'#00E5B8',
          display:'flex', alignItems:'center', padding:4, borderRadius:8,
        }}>
          <ArrowLeft size={20} />
        </button>
      )}
      {title && <span style={{ flex:1, fontWeight:700, fontSize:17, color:fg }}>{title}</span>}
      {right}
    </div>
  )
}

// ─── Cairo map SVG ────────────────────────────────────────────────────────────
function CairoMap({ theme, showRoute=true, w=393, h=400, carX=196, carY=220 }: {
  theme:Theme; showRoute?:boolean; w?:number; h?:number; carX?:number; carY?:number
}) {
  const isDark = theme==='dark'
  const mapBg   = isDark ? '#080E1C' : '#B4C8E8'
  const gridCol = isDark ? 'rgba(20,35,65,0.9)' : 'rgba(100,130,175,0.4)'
  const rd1     = isDark ? '#0E1E38' : '#8AAAD0'  // major arterial
  const rd2     = isDark ? '#0A1630' : '#96B8DA'  // secondary
  const rd3     = isDark ? '#0C1A35' : '#9EC0E0'  // tertiary
  const blk     = isDark ? '#0A1428' : '#A8C0DD'  // building block
  const nilCol  = isDark ? '#0A1A40' : '#7AA4D0'  // nile

  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ position:'absolute', inset:0 }}>
      {/* Base */}
      <rect width={w} height={h} fill={mapBg} />
      {/* Fine grid */}
      {Array.from({length:Math.ceil(w/20)}, (_,i)=>(i+1)*20).map(x=>
        <line key={`gv${x}`} x1={x} y1={0} x2={x} y2={h} stroke={gridCol} strokeWidth={0.4} />
      )}
      {Array.from({length:Math.ceil(h/20)}, (_,i)=>(i+1)*20).map(y=>
        <line key={`gh${y}`} x1={0} y1={y} x2={w} y2={y} stroke={gridCol} strokeWidth={0.4} />
      )}

      {/* Nile river */}
      <path d={`M 90 0 Q 110 ${h/4} 80 ${h/2} Q 60 ${h*0.75} 90 ${h}`}
        stroke={nilCol} strokeWidth={18} fill="none" strokeLinecap="round" opacity={0.9} />

      {/* Major arterials */}
      <rect x={0} y={h*0.52} width={w} height={9} rx={1} fill={rd1} />
      <rect x={w*0.52} y={0} width={9} height={h} rx={1} fill={rd1} />

      {/* Secondary roads */}
      <rect x={0} y={h*0.27} width={w} height={6} fill={rd2} />
      <rect x={0} y={h*0.75} width={w} height={5} fill={rd2} />
      <rect x={w*0.27} y={0} width={5} height={h} fill={rd2} />
      <rect x={w*0.74} y={0} width={5} height={h} fill={rd2} />

      {/* Tertiary / local */}
      {[0.14,0.42,0.63,0.88].map(r=>(
        <rect key={`th${r}`} x={0} y={h*r} width={w} height={3} fill={rd3} />
      ))}
      {[0.14,0.39,0.62,0.86].map(r=>(
        <rect key={`tv${r}`} x={w*r} y={0} width={3} height={h} fill={rd3} />
      ))}

      {/* Building blocks */}
      {[
        [100,30, 100,85], [220,30,120,85], [102,110, 95,75],
        [100,210,95,100],[220,210,90,100],[320,210,60,100],
        [100,310,95,80], [220,310,85,70], [320,310,60,70],
        [100,60,200,10],
      ].map(([x,y,ww,hh],i)=>(
        <rect key={i} x={x} y={y} width={ww} height={hh} rx={3}
          fill={blk} stroke={isDark?'#0E1C35':'#9AB8D5'} strokeWidth={0.5} />
      ))}

      {/* Place labels */}
      {[
        [195,248,'Tahrir'], [300,248,'Downtown'], [110,248,'Zamalek'],
        [195,80, 'Heliopolis'], [300,80,'Airport'],
      ].map(([x,y,name])=>(
        <text key={String(name)} x={Number(x)} y={Number(y)} textAnchor="middle"
          fontSize={9} fontWeight="600" fill={isDark?'#3A5080':'#6080B0'}
          fontFamily="'Plus Jakarta Sans',sans-serif">{String(name)}</text>
      ))}

      {/* Route line */}
      {showRoute && <>
        {/* Shadow */}
        <path d={`M 80 340 Q 80 ${h*0.52+4} ${w*0.52+4} ${h*0.52+4} Q ${w*0.52+4} 90 ${w*0.74} 90`}
          stroke="rgba(0,0,0,0.3)" strokeWidth={5} fill="none" strokeLinecap="round" />
        {/* Route */}
        <path d={`M 80 340 Q 80 ${h*0.52} ${w*0.52} ${h*0.52} Q ${w*0.52} 90 ${w*0.74} 90`}
          stroke="#00E5B8" strokeWidth={3.5} fill="none" strokeLinecap="round"
          strokeDasharray="9 5" />
        {/* Pickup */}
        <circle cx={80} cy={340} r={14} fill="rgba(0,229,184,0.18)" />
        <circle cx={80} cy={340} r={7}  fill="#00E5B8" />
        <circle cx={80} cy={340} r={3}  fill="#080D18" />
        {/* Destination */}
        <circle cx={w*0.74} cy={90} r={14} fill="rgba(255,59,92,0.18)" />
        <circle cx={w*0.74} cy={90} r={7}  fill="#FF3B5C" />
        <circle cx={w*0.74} cy={90} r={3}  fill="#fff" />
      </>}

      {/* Car */}
      <circle cx={carX} cy={carY} r={20} fill="rgba(0,229,184,0.14)" />
      <circle cx={carX} cy={carY} r={20} stroke="#00E5B8" strokeWidth={1.5} fill="none" opacity={0.6} />
      <circle cx={carX} cy={carY} r={13} fill={isDark?'#0F1628':'#fff'} />
      <text x={carX} y={carY+5} textAnchor="middle" fontSize={14}>🚗</text>
    </svg>
  )
}

// ─── Fare meter digits ────────────────────────────────────────────────────────
function FareMeter({ value, isActive }: { value: number; isActive: boolean }) {
  const str   = value.toFixed(2).padStart(7, ' ')
  const parts = str.split('.')
  return (
    <div style={{ display:'flex', alignItems:'baseline', gap:0 }}>
      <div style={{
        fontFamily:"'JetBrains Mono',monospace",
        fontSize: 54, fontWeight: 800, lineHeight: 1,
        color: isActive ? '#FFB020' : '#3A5070',
        letterSpacing: -2,
        ...(isActive ? { textShadow:'0 0 28px rgba(255,176,32,0.6), 0 0 56px rgba(255,176,32,0.25)' } : {}),
        transition: 'color 0.5s ease',
      }}>
        {parts[0]}
      </div>
      <div style={{
        fontFamily:"'JetBrains Mono',monospace",
        fontSize: 30, fontWeight: 700, lineHeight: 1, paddingBottom: 2,
        color: isActive ? '#FFB020' : '#2A3C54',
        opacity: 0.85,
        ...(isActive ? { textShadow:'0 0 16px rgba(255,176,32,0.5)' } : {}),
      }}>
        .{parts[1]}
      </div>
      <div style={{
        fontFamily:"'JetBrains Mono',monospace",
        fontSize: 15, fontWeight: 600, marginLeft: 7, marginBottom: 3,
        color: '#526480', letterSpacing: '0.04em',
      }}>EGP</div>
    </div>
  )
}

// ─── Small stat pill ──────────────────────────────────────────────────────────
function StatPill({ icon, label, value, color='#8EA4C8' }: {
  icon:ReactNode; label:string; value:string; color?:string
}) {
  return (
    <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:4 }}>
      <div style={{ display:'flex', alignItems:'center', gap:4, color:'#526480', fontSize:10, fontWeight:600, textTransform:'uppercase', letterSpacing:'0.05em' }}>
        {icon} {label}
      </div>
      <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:14, fontWeight:700, color }}>{value}</div>
    </div>
  )
}

// ─── SCREEN: Splash ───────────────────────────────────────────────────────────
function SplashScreen({ onDone }: { onDone:()=>void }) {
  const [p, setP] = useState(0)
  useEffect(()=>{
    const t = setInterval(()=> setP(v => {
      if (v >= 100) { clearInterval(t); setTimeout(onDone, 200); return 100 }
      return v + 2
    }), 50)
    return ()=>clearInterval(t)
  },[onDone])

  return (
    <div style={{ width:393, height:852, background:'#050A14', borderRadius:50,
      border:'2.5px solid #1C2B45', overflow:'hidden', position:'relative',
      display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center',
      boxShadow:'0 48px 96px rgba(0,0,0,0.7)' }}>
      {/* concentric rings */}
      {[340,260,180,110].map((r,i)=>(
        <div key={i} style={{ position:'absolute', width:r, height:r, borderRadius:'50%',
          border:`1px solid rgba(0,229,184,${0.04+i*0.025})`,
          top:'50%',left:'50%',transform:'translate(-50%,-50%)' }} />
      ))}
      {/* dots at ring intersections */}
      {[0,60,120,180,240,300].map(deg=>(
        <div key={deg} style={{
          position:'absolute', width:4, height:4, borderRadius:'50%',
          background:'rgba(0,229,184,0.3)',
          top:`calc(50% + ${Math.sin(deg*Math.PI/180)*130}px)`,
          left:`calc(50% + ${Math.cos(deg*Math.PI/180)*130}px)`,
          transform:'translate(-50%,-50%)',
        }} />
      ))}

      <div style={{ position:'relative', zIndex:1, textAlign:'center' }}>
        {/* Icon */}
        <div style={{ width:96, height:96, borderRadius:28, margin:'0 auto 28px',
          background:'linear-gradient(140deg, #00E5B8 0%, #0088CC 100%)',
          display:'flex', alignItems:'center', justifyContent:'center',
          boxShadow:'0 0 48px rgba(0,229,184,0.35), 0 12px 32px rgba(0,0,0,0.4)' }}>
          <Navigation size={44} color="#050A14" strokeWidth={2} />
        </div>

        {/* Name */}
        <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:42, fontWeight:700,
          color:'#EDF2FC', letterSpacing:'0.02em', lineHeight:1 }}>
          Adady Maren
        </div>
        <div style={{ fontSize:24, color:'#00E5B8', marginTop:8, fontWeight:500, letterSpacing:'0.08em', direction:'rtl' }}>
          عدادي مَرِنْ
        </div>
        <div style={{ fontSize:12, color:'#526480', marginTop:12, letterSpacing:'0.1em', textTransform:'uppercase' }}>
          Smart Multi-Modal Ride Hailing
        </div>

        {/* Progress bar */}
        <div style={{ width:180, height:2, background:'#1C2B45', borderRadius:1, margin:'44px auto 0', overflow:'hidden' }}>
          <div style={{ height:'100%', width:`${p}%`, background:'linear-gradient(90deg,#00E5B8,#0088CC)',
            borderRadius:1, transition:'width 0.05s linear' }} />
        </div>
        <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:11, color:'#526480', marginTop:10 }}>
          {p}%
        </div>
      </div>
    </div>
  )
}

// ─── SCREEN: Role Select ──────────────────────────────────────────────────────
function RoleScreen({ onSelect }: { onSelect:(r:Role)=>void }) {
  const [hov, setHov] = useState<string|null>(null)
  const roles = [
    { id:'driver', emoji:'🚗', title:'Driver', ar:'سائق', desc:'Accept metered trips, earn transparently, manage your daily income.', accent:'#00E5B8', sub:'Join 2,400+ active drivers' },
    { id:'passenger', emoji:'👤', title:'Passenger', ar:'راكب', desc:'Book rides with live fare preview. Split with others for lower cost.', accent:'#FFB020', sub:'Fair prices, real-time tracking' },
    { id:'admin', emoji:'📊', title:'Admin', ar:'مشرف', desc:'Manage fleet, subscriptions and revenue from the web dashboard.', accent:'#4D9FFF', sub:'Full platform analytics' },
  ]
  return (
    <PhoneFrame theme="dark">
      <StatusBar theme="dark" />
      <div style={{ padding:'24px 24px 40px', flex:1, display:'flex', flexDirection:'column' }}>
        {/* Header */}
        <div style={{ marginBottom:36 }}>
          <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:20 }}>
            <div style={{ width:38, height:38, borderRadius:11, background:'linear-gradient(135deg,#00E5B8,#0088CC)',
              display:'flex', alignItems:'center', justifyContent:'center' }}>
              <Navigation size={18} color="#050A14" strokeWidth={2.5} />
            </div>
            <div>
              <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:20, fontWeight:700, color:'#EDF2FC', lineHeight:1 }}>Adady Maren</div>
              <div style={{ fontSize:11, color:'#526480' }}>عدادي مَرِنْ</div>
            </div>
          </div>
          <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:32, fontWeight:700, color:'#EDF2FC', lineHeight:1.1 }}>
            Who are<br />you today?
          </div>
          <div style={{ fontSize:13, color:'#526480', marginTop:8 }}>Select your role to get started</div>
        </div>

        {/* Role cards */}
        <div style={{ display:'flex', flexDirection:'column', gap:12, flex:1 }}>
          {roles.map(({ id, emoji, title, ar, desc, accent, sub })=>(
            <button key={id}
              onMouseEnter={()=>setHov(id)} onMouseLeave={()=>setHov(null)}
              onClick={()=>onSelect(id as Role)}
              style={{
                background: hov===id ? `rgba(${accent.match(/\d+/g)!.join(',')},0.06)` : '#0F1628',
                border:`1.5px solid ${hov===id ? accent+'55' : '#1C2B45'}`,
                borderRadius:18, padding:'18px 20px', cursor:'pointer', textAlign:'left',
                display:'flex', gap:16, alignItems:'center',
                transition:'all 0.2s ease',
                transform: hov===id ? 'translateY(-2px)' : 'none',
                boxShadow: hov===id ? `0 8px 32px rgba(0,0,0,0.3), 0 0 0 1px ${accent}22` : 'none',
              }}>
              <div style={{ width:54, height:54, borderRadius:15, flexShrink:0,
                background:`${accent}18`, border:`1px solid ${accent}30`,
                display:'flex', alignItems:'center', justifyContent:'center', fontSize:26 }}>
                {emoji}
              </div>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:3 }}>
                  <span style={{ fontSize:17, fontWeight:800, color:'#EDF2FC' }}>{title}</span>
                  <span style={{ fontSize:13, color:accent, fontWeight:500 }}>{ar}</span>
                </div>
                <div style={{ fontSize:11, color:'#526480', marginBottom:6, lineHeight:1.5 }}>{desc}</div>
                <div style={{ fontSize:10, color:accent, fontWeight:700, letterSpacing:'0.04em', textTransform:'uppercase' }}>{sub}</div>
              </div>
              <ChevronRight size={16} color="#243558" />
            </button>
          ))}
        </div>

        <div style={{ textAlign:'center', marginTop:20 }}>
          <button onClick={()=>onSelect(null)} style={{
            background:'none', border:'none', color:'#526480', fontSize:12,
            cursor:'pointer', fontFamily:"'Plus Jakarta Sans',sans-serif",
          }}>
            Open landing page →
          </button>
        </div>
      </div>
    </PhoneFrame>
  )
}

// ─── SCREEN: Auth ─────────────────────────────────────────────────────────────
function AuthScreen({ onNext, theme }: { onNext:()=>void; theme:Theme }) {
  const [tab, setTab] = useState<'phone'|'email'>('phone')
  const [val, setVal] = useState('')
  const [showPw, setShowPw] = useState(false)
  const isDark = theme==='dark'
  const C = TK[theme]

  const inputStyle: CSSProperties = {
    width:'100%', padding:'14px 14px 14px 48px',
    background: isDark ? '#0C1220' : '#E8EEF8',
    border:`1.5px solid ${C.border}`, borderRadius:12,
    color:C.text, fontSize:15, fontFamily:"'Plus Jakarta Sans',sans-serif",
    outline:'none', transition:'border-color 0.2s',
  }

  return (
    <PhoneFrame theme={theme}>
      <StatusBar theme={theme} />
      <div style={{ padding:'24px 24px 40px', overflowY:'auto' }}>
        {/* Logo */}
        <div style={{ textAlign:'center', marginBottom:36 }}>
          <div style={{ width:64, height:64, borderRadius:18, margin:'0 auto 14px',
            background:'linear-gradient(140deg,#00E5B8,#0088CC)',
            display:'flex', alignItems:'center', justifyContent:'center',
            boxShadow:'0 0 32px rgba(0,229,184,0.3)' }}>
            <Navigation size={28} color="#050A14" strokeWidth={2.5} />
          </div>
          <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:26, fontWeight:700, color:C.text }}>Sign In</div>
          <div style={{ fontSize:13, color:C.muted, marginTop:4 }}>Welcome back to Adady Maren</div>
        </div>

        {/* Tab switcher */}
        <div style={{ display:'flex', gap:4, background:isDark?'#0C1220':'#E0E8F5', borderRadius:12, padding:4, marginBottom:24 }}>
          {(['phone','email'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{
              flex:1, padding:'10px 0', borderRadius:9, border:'none', cursor:'pointer',
              background: tab===t ? C.teal : 'transparent',
              color: tab===t ? '#080D18' : C.muted,
              fontWeight:700, fontSize:13, fontFamily:"'Plus Jakarta Sans',sans-serif",
              transition:'all 0.18s',
            }}>
              {t==='phone' ? '📱 Phone' : '✉️ Email'}
            </button>
          ))}
        </div>

        {/* Fields */}
        <div style={{ display:'flex', flexDirection:'column', gap:14, marginBottom:24 }}>
          <div>
            <label style={{ fontSize:11, fontWeight:700, color:C.muted, display:'block', marginBottom:7, textTransform:'uppercase', letterSpacing:'0.05em' }}>
              {tab==='phone' ? 'Mobile Number' : 'Email Address'}
            </label>
            <div style={{ position:'relative' }}>
              <div style={{ position:'absolute', left:14, top:'50%', transform:'translateY(-50%)', color:C.muted, display:'flex', alignItems:'center', gap:6 }}>
                {tab==='phone' ? <><span style={{fontSize:16}}>🇪🇬</span><span style={{fontSize:12,fontWeight:700,color:C.sub}}>+20</span></> : <Mail size={16} />}
              </div>
              <input value={val} onChange={e=>setVal(e.target.value)}
                placeholder={tab==='phone' ? '010 XXXX XXXX' : 'you@example.com'}
                style={{ ...inputStyle, paddingLeft: tab==='phone' ? 72 : 44 }} />
            </div>
          </div>

          {tab==='email' && (
            <div>
              <label style={{ fontSize:11, fontWeight:700, color:C.muted, display:'block', marginBottom:7, textTransform:'uppercase', letterSpacing:'0.05em' }}>Password</label>
              <div style={{ position:'relative' }}>
                <div style={{ position:'absolute', left:14, top:'50%', transform:'translateY(-50%)', color:C.muted }}>
                  <Lock size={16} />
                </div>
                <input type={showPw?'text':'password'} placeholder="••••••••"
                  style={{ ...inputStyle, paddingRight:44 }} />
                <button onClick={()=>setShowPw(!showPw)} style={{
                  position:'absolute', right:14, top:'50%', transform:'translateY(-50%)',
                  background:'none', border:'none', cursor:'pointer', color:C.muted,
                }}>
                  {showPw ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>
          )}
        </div>

        <Btn full size="lg" onClick={onNext}>
          {tab==='phone' ? 'Send OTP →' : 'Continue →'}
        </Btn>

        <div style={{ textAlign:'center', margin:'20px 0', fontSize:12, color:C.muted }}>
          By continuing you agree to our{' '}
          <span style={{ color:C.teal, cursor:'pointer' }}>Terms of Service</span>
        </div>

        {/* Divider */}
        <div style={{ display:'flex', alignItems:'center', gap:12, marginBottom:16 }}>
          <div style={{ flex:1, height:1, background:C.border }} />
          <span style={{ fontSize:11, color:C.muted }}>or continue with</span>
          <div style={{ flex:1, height:1, background:C.border }} />
        </div>

        <button style={{
          width:'100%', padding:'14px', background:isDark?'#0C1220':'#E8EEF8',
          border:`1.5px solid ${C.border}`, borderRadius:12, cursor:'pointer',
          color:C.text, fontSize:14, fontWeight:600,
          fontFamily:"'Plus Jakarta Sans',sans-serif",
          display:'flex', alignItems:'center', justifyContent:'center', gap:10,
        }}>
          <span style={{fontSize:18}}>🌐</span> Google
        </button>
      </div>
    </PhoneFrame>
  )
}

// ─── SCREEN: OTP ──────────────────────────────────────────────────────────────
function OTPScreen({ onNext, theme }: { onNext:()=>void; theme:Theme }) {
  const [otp, setOtp] = useState(['','','','','',''])
  const [secs, setSecs] = useState(59)
  const refs = useRef<(HTMLInputElement|null)[]>([])
  const isDark = theme==='dark'
  const C = TK[theme]

  useEffect(()=>{
    if (secs<=0) return
    const t = setTimeout(()=>setSecs(s=>s-1), 1000)
    return ()=>clearTimeout(t)
  },[secs])

  const setDigit = (i:number, v:string)=>{
    if (!/^\d?$/.test(v)) return
    const n=[...otp]; n[i]=v; setOtp(n)
    if (v && i<5) refs.current[i+1]?.focus()
  }

  const allFilled = otp.every(d=>d!=='')
  const circ = 2*Math.PI*22
  const offset = circ - (secs/59)*circ

  return (
    <PhoneFrame theme={theme}>
      <StatusBar theme={theme} />
      <ScreenBar title="Verify Phone" theme={theme} />
      <div style={{ padding:'32px 24px 40px' }}>
        {/* Illustration */}
        <div style={{ textAlign:'center', marginBottom:40 }}>
          <div style={{ width:88, height:88, borderRadius:24, margin:'0 auto 20px',
            background:isDark?'#0F1628':'#E8EEF8',
            border:`1.5px solid ${C.border}`,
            display:'flex', alignItems:'center', justifyContent:'center', fontSize:40 }}>
            📱
          </div>
          <div style={{ fontSize:20, fontWeight:800, color:C.text }}>Enter your code</div>
          <div style={{ fontSize:13, color:C.muted, marginTop:8, lineHeight:1.7 }}>
            We sent a 6-digit code to<br />
            <span style={{ color:C.teal, fontWeight:700 }}>+20 010 1234 5678</span>
          </div>
        </div>

        {/* OTP boxes */}
        <div style={{ display:'flex', gap:9, justifyContent:'center', marginBottom:28 }}>
          {otp.map((d,i)=>(
            <input key={i} ref={el=>{refs.current[i]=el}}
              value={d} maxLength={1}
              onChange={e=>setDigit(i,e.target.value)}
              onKeyDown={e=>{ if(e.key==='Backspace'&&!d&&i>0) refs.current[i-1]?.focus() }}
              style={{
                width:50, height:60, textAlign:'center',
                fontSize:24, fontWeight:800,
                fontFamily:"'JetBrains Mono',monospace",
                background: isDark?(d?'#152038':'#0C1220'):(d?'#DCF5EF':'#E8EEF8'),
                border:`2px solid ${d?C.teal:C.border}`,
                borderRadius:14, color:C.text, outline:'none',
                transition:'all 0.15s',
                boxShadow: d ? `0 0 0 3px ${C.teal}20` : 'none',
              }} />
          ))}
        </div>

        {/* Countdown */}
        <div style={{ display:'flex', alignItems:'center', justifyContent:'center', gap:14, marginBottom:28 }}>
          <svg width={52} height={52} style={{ transform:'rotate(-90deg)' }}>
            <circle cx={26} cy={26} r={22} fill="none" stroke={C.border} strokeWidth={3} />
            <circle cx={26} cy={26} r={22} fill="none"
              stroke={secs<15 ? C.red : C.teal} strokeWidth={3}
              strokeLinecap="round" strokeDasharray={circ}
              strokeDashoffset={offset}
              style={{ transition:'stroke-dashoffset 1s linear, stroke 0.3s' }} />
          </svg>
          <div>
            <div style={{ fontFamily:"'JetBrains Mono',monospace",
              fontSize:22, fontWeight:800, color:secs<15?C.red:C.teal, lineHeight:1 }}>
              0:{secs.toString().padStart(2,'0')}
            </div>
            <div style={{ fontSize:11, color:C.muted, marginTop:2 }}>before expiry</div>
          </div>
        </div>

        <Btn full size="lg" disabled={!allFilled} onClick={onNext}>
          Verify & Continue
        </Btn>

        <div style={{ textAlign:'center', marginTop:20 }}>
          <button onClick={()=>setSecs(59)} disabled={secs>0}
            style={{ background:'none', border:'none', cursor:secs===0?'pointer':'default',
              color:secs===0?C.teal:C.muted, fontSize:13, fontFamily:"'Plus Jakarta Sans',sans-serif",
              display:'inline-flex', alignItems:'center', gap:6 }}>
            <RefreshCw size={13} /> Resend code
          </button>
        </div>

        {/* Security note */}
        <div style={{ marginTop:32, padding:'14px 16px',
          background:isDark?'rgba(0,229,184,0.04)':'rgba(0,168,130,0.06)',
          border:`1px solid ${C.teal}22`, borderRadius:14,
          display:'flex', gap:10, alignItems:'flex-start' }}>
          <Shield size={15} color={C.teal} style={{ flexShrink:0, marginTop:1 }} />
          <span style={{ fontSize:12, color:C.muted, lineHeight:1.6 }}>
            Adady Maren will <strong style={{color:C.sub}}>never</strong> ask for your OTP. Keep it private.
          </span>
        </div>
      </div>
    </PhoneFrame>
  )
}

// ─── DRIVER: GPS Dashboard & Live Meter ───────────────────────────────────────
function DriverDashboard({ nav }: { nav:(s:Screen)=>void }) {
  const [fare, setFare] = useState(24.50)
  const [active, setActive] = useState(true)
  const [speed, setSpeed] = useState(42)
  const [dist, setDist] = useState(8.3)
  const [time, setTime] = useState(24)
  const [wait, setWait] = useState(2)
  const [sheetH, setSheetH] = useState<'peek'|'half'|'full'>('half')
  const [carY, setCarY] = useState(220)

  useEffect(()=>{
    if (!active) return
    const t = setInterval(()=>{
      setFare(f=>Math.round((f+0.14)*100)/100)
      setDist(d=>Math.round((d+0.01)*100)/100)
      setTime(t=>t+1/60)
      setSpeed(s=>Math.max(0, Math.min(80, s+(Math.random()-.5)*8)))
      setCarY(y=>{ const ny=y-0.5; return ny<160?320:ny })
    }, 800)
    return ()=>clearInterval(t)
  },[active])

  const waitMode = speed < 5
  if (waitMode && active) setWait(w=>w+1/60)

  const sheetHeights = { peek:100, half:340, full:580 }
  const sh = sheetHeights[sheetH]

  const passengers = [
    { id:1, name:'Ahmed Kamal', dist:'3.2 km', fare:18.40, from:'Tahrir Sq', to:'Zamalek', avatar:'👨' },
    { id:2, name:'Sara Mohamed', dist:'1.8 km', fare:11.20, from:'Tahrir Sq', to:'Dokki', avatar:'👩' },
  ]

  return (
    <div style={{ width:393, height:852, position:'relative',
      background:'#080E1C', borderRadius:50, border:'2.5px solid #1C2B45',
      overflow:'hidden', boxShadow:'0 48px 96px rgba(0,0,0,0.7)' }}>

      <StatusBar theme="dark" />

      {/* Map */}
      <div style={{ position:'absolute', inset:0 }}>
        <CairoMap theme="dark" h={500} carX={196} carY={carY} />
      </div>

      {/* Top gradient overlay */}
      <div style={{ position:'absolute', top:0, left:0, right:0, height:280,
        background:'linear-gradient(to bottom, rgba(8,13,24,0.97) 0%, rgba(8,13,24,0.6) 60%, transparent 100%)',
        zIndex:10 }} />

      {/* ── Fare meter widget ── */}
      <div style={{ position:'absolute', top:38, left:16, right:16, zIndex:20 }}>
        <div style={{
          background:'rgba(9,14,26,0.92)', backdropFilter:'blur(20px)',
          border:`1.5px solid ${active?'rgba(255,176,32,0.3)':'#1C2B45'}`,
          borderRadius:22, padding:'18px 20px',
          boxShadow: active?'0 8px 48px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,176,32,0.08)':'0 8px 32px rgba(0,0,0,0.4)',
        }}>
          {/* Top row */}
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:4 }}>
            <div>
              <div style={{ fontSize:10, color:'#526480', fontWeight:700, textTransform:'uppercase',
                letterSpacing:'0.08em', marginBottom:6, display:'flex', alignItems:'center', gap:6 }}>
                <span style={{ width:6, height:6, borderRadius:'50%', background:active?'#FFB020':'#526480',
                  display:'inline-block', ...(active?{boxShadow:'0 0 8px #FFB020'}:{}) }} />
                Total Fare Meter
              </div>
              <FareMeter value={fare} isActive={active} />
            </div>

            {/* Right side */}
            <div style={{ display:'flex', flexDirection:'column', gap:8, alignItems:'flex-end' }}>
              <button onClick={()=>setActive(!active)} style={{
                background: active?'rgba(255,59,92,0.12)':'rgba(0,229,184,0.12)',
                border:`1.5px solid ${active?'rgba(255,59,92,0.4)':'rgba(0,229,184,0.4)'}`,
                borderRadius:10, padding:'9px 14px', cursor:'pointer',
                color: active?'#FF3B5C':'#00E5B8',
                fontWeight:800, fontSize:12, display:'flex', alignItems:'center', gap:6,
                fontFamily:"'Plus Jakarta Sans',sans-serif",
              }}>
                {active ? <><Pause size={13} />STOP</> : <><Play size={13} />START</>}
              </button>

              <div style={{ display:'flex', gap:8 }}>
                {waitMode && <Badge label="WAIT" color="blue" dot />}
                {active && <Badge label="LIVE" color="amber" dot />}
              </div>
            </div>
          </div>

          {/* Speed indicator */}
          <div style={{ marginTop:4, marginBottom:14 }}>
            <div style={{ display:'flex', justifyContent:'space-between', marginBottom:4 }}>
              <span style={{ fontSize:10, color:'#526480', fontWeight:600, textTransform:'uppercase', letterSpacing:'0.05em' }}>Speed</span>
              <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:11, color: speed<5?'#4D9FFF':'#8EA4C8' }}>
                {speed.toFixed(0)} km/h {speed<5?'· Wait mode active':''}
              </span>
            </div>
            <div style={{ height:3, background:'#1C2B45', borderRadius:2, overflow:'hidden' }}>
              <div style={{ height:'100%', width:`${(speed/80)*100}%`,
                background:`linear-gradient(90deg, ${speed<5?'#4D9FFF':'#00E5B8'}, ${speed<5?'#0066CC':'#00B896'})`,
                borderRadius:2, transition:'width 0.5s ease, background 0.3s' }} />
            </div>
          </div>

          {/* Sub-meters */}
          <div style={{ display:'flex', borderTop:'1px solid #1C2B45', paddingTop:13, gap:4 }}>
            <StatPill icon={<Route size={10} />} label="Distance" value={`${dist.toFixed(1)} km`} color="#8EA4C8" />
            <div style={{ width:1, background:'#1C2B45' }} />
            <StatPill icon={<Clock size={10} />} label="Time" value={`${Math.floor(time)} min`} color="#8EA4C8" />
            <div style={{ width:1, background:'#1C2B45' }} />
            <StatPill icon={<Pause size={10} />} label="Wait" value={`${Math.floor(wait)} min`} color={wait>0?'#4D9FFF':'#8EA4C8'} />
          </div>
        </div>
      </div>

      {/* Quick action buttons */}
      <div style={{ position:'absolute', right:14, top:210, zIndex:20, display:'flex', flexDirection:'column', gap:9 }}>
        {[
          { icon:<Plus size={18} />, col:'#00E5B8', label:'Add', onClick:()=>nav('driver-dispatch') },
          { icon:<AlertTriangle size={17} />, col:'#FF3B5C', label:'SOS', onClick:()=>{} },
          { icon:<WifiOff size={17} />, col:'#526480', label:'Offline', onClick:()=>{} },
        ].map(({ icon, col, label, onClick })=>(
          <button key={label} onClick={onClick} style={{
            width:46, height:46, borderRadius:13, cursor:'pointer',
            background:'rgba(8,13,24,0.88)', backdropFilter:'blur(12px)',
            border:`1.5px solid ${col}44`,
            display:'flex', alignItems:'center', justifyContent:'center', color:col,
            boxShadow:'0 4px 16px rgba(0,0,0,0.4)',
            transition:'all 0.18s',
          }} title={label}>{icon}</button>
        ))}
      </div>

      {/* ── Passengers bottom sheet ── */}
      <div style={{
        position:'absolute', bottom:0, left:0, right:0, zIndex:30,
        background:'rgba(9,14,26,0.96)', backdropFilter:'blur(24px)',
        borderTop:'1px solid #1C2B45', borderRadius:'22px 22px 0 0',
        height:sh, transition:'height 0.35s cubic-bezier(.32,.72,0,1)',
        display:'flex', flexDirection:'column',
      }}>
        {/* Handle */}
        <div onClick={()=>setSheetH(h=>h==='peek'?'half':h==='half'?'full':'half')}
          style={{ padding:'14px 0 0', cursor:'pointer', flexShrink:0 }}>
          <div style={{ width:40, height:4, borderRadius:2, background:'#243558', margin:'0 auto' }} />
        </div>

        {/* Sheet header */}
        <div style={{ padding:'10px 18px 10px', display:'flex', justifyContent:'space-between', alignItems:'center', flexShrink:0 }}>
          <div style={{ display:'flex', alignItems:'center', gap:8 }}>
            <Users size={16} color="#00E5B8" />
            <span style={{ fontSize:15, fontWeight:800, color:'#EDF2FC' }}>Shared Passengers</span>
            <span style={{ background:'#00E5B8', color:'#080D18', borderRadius:6, padding:'1px 8px', fontSize:11, fontWeight:800 }}>
              {passengers.length}
            </span>
          </div>
          <Btn variant="teal" size="xs" onClick={()=>nav('driver-dispatch')} icon={<Plus size={12} />}>
            Add
          </Btn>
        </div>

        {/* Passenger cards */}
        <div style={{ overflowY:'auto', padding:'0 14px 16px', flex:1 }}>
          {passengers.map(p=>(
            <div key={p.id} style={{
              background:'#0F1628', border:'1px solid #1C2B45', borderRadius:16,
              padding:'13px 14px', marginBottom:10,
              display:'flex', alignItems:'center', gap:12,
            }}>
              <div style={{ width:42, height:42, borderRadius:12, background:'#152038',
                display:'flex', alignItems:'center', justifyContent:'center', fontSize:20, flexShrink:0 }}>
                {p.avatar}
              </div>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ fontSize:14, fontWeight:800, color:'#EDF2FC' }}>{p.name}</div>
                <div style={{ fontSize:11, color:'#526480', marginTop:2 }}>{p.from} → {p.to}</div>
                <div style={{ display:'flex', gap:12, marginTop:6 }}>
                  <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:12, color:'#8EA4C8' }}>{p.dist}</span>
                  <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:13, color:'#FFB020', fontWeight:700 }}>{p.fare.toFixed(2)} EGP</span>
                </div>
              </div>
              <button style={{
                background:'rgba(255,59,92,0.1)', border:'1px solid rgba(255,59,92,0.3)',
                borderRadius:9, padding:'8px 11px', cursor:'pointer', color:'#FF3B5C',
                fontSize:11, fontWeight:700, fontFamily:"'Plus Jakarta Sans',sans-serif",
                whiteSpace:'nowrap',
              }}>
                End Sub
              </button>
            </div>
          ))}

          {/* Fare summary */}
          {sheetH==='full' && (
            <div style={{ background:'#0C1220', borderRadius:14, padding:'13px 14px', border:'1px solid #1C2B45' }}>
              <div style={{ fontSize:11, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.05em', marginBottom:10 }}>Session Summary</div>
              <div style={{ display:'flex', justifyContent:'space-between', marginBottom:6 }}>
                <span style={{ fontSize:13, color:'#8EA4C8' }}>Combined earnings</span>
                <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:14, color:'#00E5B8', fontWeight:700 }}>
                  {(fare+passengers.reduce((s,p)=>s+p.fare,0)).toFixed(2)} EGP
                </span>
              </div>
              <div style={{ display:'flex', gap:10, marginTop:10 }}>
                <Btn variant="teal" size="sm" full onClick={()=>nav('driver-payment')}>Checkout Trip</Btn>
              </div>
            </div>
          )}
        </div>

        {/* Bottom nav */}
        <div style={{ display:'flex', borderTop:'1px solid #1C2B45', padding:'10px 0 30px', flexShrink:0 }}>
          {[
            { icon:<Map size={20} />, label:'Map', active:true, to:'driver-dashboard' },
            { icon:<Calendar size={20} />, label:'Trips', active:false, to:'driver-dispatch' },
            { icon:<Wallet size={20} />, label:'Wallet', active:false, to:'driver-wallet' },
            { icon:<Settings size={20} />, label:'Settings', active:false, to:'driver-dashboard' },
          ].map(({ icon, label, active, to })=>(
            <button key={label} onClick={()=>nav(to as Screen)} style={{
              flex:1, background:'none', border:'none', cursor:'pointer',
              display:'flex', flexDirection:'column', alignItems:'center', gap:4,
              color: active?'#00E5B8':'#3A5070',
              fontFamily:"'Plus Jakarta Sans',sans-serif",
            }}>
              {icon}
              <span style={{ fontSize:10, fontWeight:700 }}>{label}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

// ─── DRIVER: Trip Dispatch ────────────────────────────────────────────────────
function DriverDispatch({ nav }: { nav:(s:Screen)=>void }) {
  const [tab, setTab] = useState<'instant'|'scheduled'>('instant')
  const [showReq, setShowReq] = useState(true)
  const [count, setCount] = useState(30)

  useEffect(()=>{
    if (!showReq||count<=0) return
    const t = setTimeout(()=>setCount(c=>c-1), 1000)
    return ()=>clearTimeout(t)
  },[showReq,count])

  const circ = 2*Math.PI*24
  const offset = circ-(count/30)*circ

  const scheduled = [
    { id:1, time:'14:30', date:'Today',     from:'Cairo International Airport', to:'Maadi Corniche', fare:145, dist:'28 km', tier:'Private Car', taken:false },
    { id:2, time:'09:15', date:'Tomorrow',  from:'Heliopolis — Roxy Square', to:'Downtown Cairo', fare:62, dist:'12 km', tier:'Private Car', taken:true },
    { id:3, time:'16:45', date:'Tomorrow',  from:'Mohandessin — Sphinx Sq', to:'Giza Pyramids Area', fare:88, dist:'15 km', tier:'TukTuk', taken:false },
    { id:4, time:'08:00', date:'Thu Jul 22',from:'Zamalek Club', to:'Sheikh Zayed City', fare:210, dist:'38 km', tier:'Private Car', taken:false },
  ]

  return (
    <PhoneFrame theme="dark">
      <StatusBar theme="dark" />
      <ScreenBar title="Trip Dispatch" onBack={()=>nav('driver-dashboard')} theme="dark"
        right={<Bell size={19} color="#526480" />} />

      {/* Request modal overlay */}
      {showReq && (
        <div className="anim-fadeIn" style={{
          position:'absolute', inset:0, zIndex:50,
          background:'rgba(4,7,14,0.82)', backdropFilter:'blur(6px)',
          display:'flex', alignItems:'center', justifyContent:'center', padding:18,
        }}>
          <div className="anim-slideUp" style={{
            background:'#0F1628', border:'1.5px solid rgba(0,229,184,0.4)',
            borderRadius:26, padding:'22px 20px', width:'100%',
            boxShadow:'0 0 80px rgba(0,229,184,0.12), 0 32px 64px rgba(0,0,0,0.6)',
          }}>
            {/* Header */}
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:18 }}>
              <div>
                <div style={{ fontSize:11, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.07em', marginBottom:5 }}>
                  ⚡ Incoming Request
                </div>
                <div style={{ fontSize:22, fontWeight:800, color:'#EDF2FC' }}>Ahmed Hassan</div>
                <div style={{ display:'flex', gap:7, marginTop:8 }}>
                  <Badge label="Private Car" color="teal" />
                  <Badge label="Shared OK" color="amber" />
                </div>
              </div>
              {/* Countdown ring */}
              <div style={{ position:'relative', width:58, height:58, flexShrink:0 }}>
                <svg width={58} height={58} style={{ transform:'rotate(-90deg)' }}>
                  <circle cx={29} cy={29} r={24} fill="none" stroke="#1C2B45" strokeWidth={3.5} />
                  <circle cx={29} cy={29} r={24} fill="none"
                    stroke={count<10?'#FF3B5C':'#00E5B8'} strokeWidth={3.5}
                    strokeLinecap="round" strokeDasharray={circ} strokeDashoffset={offset}
                    style={{ transition:'stroke-dashoffset 1s linear, stroke 0.3s' }} />
                </svg>
                <div style={{ position:'absolute', inset:0, display:'flex', alignItems:'center',
                  justifyContent:'center', fontFamily:"'JetBrains Mono',monospace",
                  fontSize:17, fontWeight:800, color:count<10?'#FF3B5C':'#EDF2FC' }}>
                  {count}
                </div>
              </div>
            </div>

            {/* Route info */}
            <div style={{ background:'#080D18', borderRadius:16, padding:16, marginBottom:16 }}>
              <div style={{ display:'flex', gap:12, alignItems:'stretch' }}>
                <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:0, paddingTop:2 }}>
                  <div style={{ width:9, height:9, borderRadius:'50%', background:'#00E5B8', flexShrink:0 }} />
                  <div style={{ width:1, flex:1, background:'repeating-linear-gradient(to bottom, #243558 0px, #243558 4px, transparent 4px, transparent 8px)', minHeight:24, margin:'3px 0' }} />
                  <div style={{ width:9, height:9, borderRadius:2, background:'#FF3B5C', flexShrink:0 }} />
                </div>
                <div style={{ flex:1 }}>
                  <div style={{ marginBottom:14 }}>
                    <div style={{ fontSize:10, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.05em', marginBottom:3 }}>Pickup</div>
                    <div style={{ fontSize:14, color:'#EDF2FC', fontWeight:600 }}>Tahrir Square, Cairo</div>
                  </div>
                  <div>
                    <div style={{ fontSize:10, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.05em', marginBottom:3 }}>Destination</div>
                    <div style={{ fontSize:14, color:'#EDF2FC', fontWeight:600 }}>Zamalek Club, Cairo</div>
                  </div>
                </div>
              </div>

              {/* Stats row */}
              <div style={{ display:'flex', gap:0, marginTop:14, paddingTop:12, borderTop:'1px solid #1C2B45' }}>
                {[
                  { l:'Pickup', v:'1.2 km', c:'#00E5B8' },
                  { l:'Trip', v:'5.4 km', c:'#EDF2FC' },
                  { l:'Est. Fare', v:'~34 EGP', c:'#FFB020' },
                ].map(({ l,v,c },i)=>(
                  <div key={l} style={{ flex:1, textAlign:'center', borderLeft:i>0?'1px solid #1C2B45':undefined }}>
                    <div style={{ fontSize:10, color:'#526480', textTransform:'uppercase', letterSpacing:'0.04em', marginBottom:3 }}>{l}</div>
                    <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:14, color:c, fontWeight:700 }}>{v}</div>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ display:'flex', gap:10 }}>
              <Btn variant="danger" full onClick={()=>setShowReq(false)}>
                <X size={16} /> Decline
              </Btn>
              <Btn variant="primary" full onClick={()=>{ setShowReq(false); nav('driver-dashboard') }}>
                <Check size={16} /> Accept
              </Btn>
            </div>
          </div>
        </div>
      )}

      {/* Tabs */}
      <div style={{ display:'flex', gap:4, background:'#0C1220', margin:'14px 16px 0', borderRadius:12, padding:4 }}>
        {(['instant','scheduled'] as const).map(t=>(
          <button key={t} onClick={()=>setTab(t)} style={{
            flex:1, padding:'10px', borderRadius:9, border:'none', cursor:'pointer',
            background: tab===t?'#00E5B8':'transparent',
            color: tab===t?'#080D18':'#526480',
            fontWeight:700, fontSize:13, fontFamily:"'Plus Jakarta Sans',sans-serif",
            transition:'all 0.18s',
          }}>
            {t==='instant'?'⚡ Instant':'📅 Scheduled'}
          </button>
        ))}
      </div>

      <div style={{ padding:'14px 16px 32px', overflowY:'auto' }}>
        {tab==='instant' ? (
          <div style={{ textAlign:'center', padding:'48px 0' }}>
            <div style={{ fontSize:52, marginBottom:16 }}>🔔</div>
            <div style={{ fontSize:17, fontWeight:800, color:'#8EA4C8', marginBottom:8 }}>Listening for requests…</div>
            <div style={{ fontSize:13, color:'#526480', marginBottom:28, lineHeight:1.6 }}>Stay online to receive live trip requests in real-time</div>
            <button onClick={()=>{ setShowReq(true); setCount(30) }} style={{
              background:'rgba(0,229,184,0.08)', border:'1px solid rgba(0,229,184,0.3)',
              borderRadius:14, padding:'13px 24px', cursor:'pointer', color:'#00E5B8',
              fontWeight:700, fontSize:14, fontFamily:"'Plus Jakarta Sans',sans-serif",
            }}>
              Simulate incoming request →
            </button>
          </div>
        ) : (
          <div style={{ display:'flex', flexDirection:'column', gap:11 }}>
            <div style={{ fontSize:11, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.05em', marginBottom:4 }}>
              {scheduled.filter(s=>!s.taken).length} available trips to claim
            </div>
            {scheduled.map(trip=>(
              <div key={trip.id} style={{
                background:'#0F1628',
                border:`1px solid ${trip.taken?'#152038':'#1C2B45'}`,
                borderRadius:18, padding:'15px 16px', opacity:trip.taken?0.55:1,
              }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:10 }}>
                  <div>
                    <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
                      <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:18, fontWeight:800, color:'#EDF2FC' }}>{trip.time}</span>
                      <span style={{ fontSize:12, color:'#526480' }}>{trip.date}</span>
                    </div>
                    <div style={{ fontSize:12, color:'#8EA4C8', lineHeight:1.5 }}>{trip.from}</div>
                    <div style={{ fontSize:11, color:'#526480', display:'flex', alignItems:'center', gap:4 }}>
                      <ChevronDown size={11} style={{ transform:'rotate(-90deg)' }} /> {trip.to}
                    </div>
                  </div>
                  <div style={{ textAlign:'right' }}>
                    <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:20, fontWeight:800, color:'#FFB020' }}>{trip.fare}</div>
                    <div style={{ fontSize:10, color:'#526480' }}>EGP est.</div>
                    <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:12, color:'#8EA4C8', marginTop:2 }}>{trip.dist}</div>
                  </div>
                </div>
                <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
                  <Badge label={trip.tier} color={trip.tier==='TukTuk'?'amber':'teal'} />
                  {trip.taken
                    ? <Badge label="Already Claimed" color="gray" />
                    : <button style={{
                        background:'#00E5B8', border:'none', borderRadius:10, padding:'9px 18px',
                        cursor:'pointer', color:'#080D18', fontWeight:800, fontSize:13,
                        fontFamily:"'Plus Jakarta Sans',sans-serif",
                      }}>Claim →</button>
                  }
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </PhoneFrame>
  )
}

// ─── DRIVER: Payment Modal ────────────────────────────────────────────────────
function DriverPayment({ nav }: { nav:(s:Screen)=>void }) {
  const [method, setMethod] = useState<'cash'|'paymob'|'vodafone'>('cash')

  const breakdown = [
    { label:'Base Fare',            amount:10.00, note:'' },
    { label:'Distance Fare',        amount:14.94, note:'8.3 km × 1.80 EGP' },
    { label:'Time Fare',            amount: 3.60, note:'24 min × 0.15 EGP' },
    { label:'Wait Time Fare',       amount: 1.00, note:'2 min × 0.50 EGP' },
  ]
  const total = breakdown.reduce((s,b)=>s+b.amount, 0)

  const methods = [
    { id:'cash'     as const, icon:'💵', label:'Cash',           sub:'Collect directly from passenger' },
    { id:'paymob'   as const, icon:'💳', label:'Paymob',         sub:'Card, wallet, or Paymob balance' },
    { id:'vodafone' as const, icon:'📱', label:'Vodafone Cash',  sub:'Direct mobile wallet transfer' },
  ]

  return (
    <PhoneFrame theme="dark">
      <StatusBar theme="dark" />
      <ScreenBar title="Trip Checkout" onBack={()=>nav('driver-dashboard')} theme="dark" />
      <div style={{ padding:'18px 18px 40px', overflowY:'auto' }}>

        {/* Passenger card */}
        <div style={{ background:'#0C1220', border:'1px solid #1C2B45', borderRadius:18, padding:'15px 16px', marginBottom:18, display:'flex', gap:14, alignItems:'center' }}>
          <div style={{ width:50, height:50, borderRadius:14, background:'#152038',
            display:'flex', alignItems:'center', justifyContent:'center', fontSize:24, flexShrink:0 }}>
            👨
          </div>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:16, fontWeight:800, color:'#EDF2FC' }}>Ahmed Hassan</div>
            <div style={{ fontSize:12, color:'#526480', marginTop:2 }}>Tahrir Sq → Zamalek Club · 8.3 km</div>
            <div style={{ display:'flex', alignItems:'center', gap:4, marginTop:6 }}>
              {[1,2,3,4,5].map(s=><Star key={s} size={12} fill="#FFB020" color="#FFB020" />)}
              <span style={{ fontSize:11, color:'#526480', marginLeft:4 }}>4.8 avg rating</span>
            </div>
          </div>
        </div>

        {/* Fare breakdown */}
        <div style={{ background:'#0F1628', border:'1px solid #1C2B45', borderRadius:18, padding:'16px 18px', marginBottom:18 }}>
          <div style={{ fontSize:11, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.06em', marginBottom:14 }}>
            Fare Breakdown
          </div>
          {breakdown.map(({ label, amount, note })=>(
            <div key={label} style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:12 }}>
              <div>
                <div style={{ fontSize:14, color:'#8EA4C8' }}>{label}</div>
                {note && <div style={{ fontSize:11, color:'#526480', marginTop:2 }}>{note}</div>}
              </div>
              <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:14, color:'#EDF2FC', fontWeight:700 }}>
                {amount.toFixed(2)}
              </div>
            </div>
          ))}
          <div style={{ height:1, background:'#1C2B45', margin:'14px 0' }} />
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
            <span style={{ fontSize:16, fontWeight:800, color:'#EDF2FC' }}>Total</span>
            <div style={{ display:'flex', alignItems:'baseline', gap:5 }}>
              <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:30, fontWeight:800,
                color:'#FFB020', textShadow:'0 0 20px rgba(255,176,32,0.4)' }}>
                {total.toFixed(2)}
              </span>
              <span style={{ fontSize:14, color:'#526480' }}>EGP</span>
            </div>
          </div>
        </div>

        {/* Payment methods */}
        <div style={{ marginBottom:22 }}>
          <div style={{ fontSize:11, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.06em', marginBottom:12 }}>
            Payment Method
          </div>
          <div style={{ display:'flex', flexDirection:'column', gap:9 }}>
            {methods.map(({ id, icon, label, sub })=>(
              <button key={id} onClick={()=>setMethod(id)} style={{
                background: method===id?'rgba(0,229,184,0.06)':'#0F1628',
                border:`2px solid ${method===id?'#00E5B8':'#1C2B45'}`,
                borderRadius:15, padding:'14px 16px', cursor:'pointer', textAlign:'left',
                display:'flex', alignItems:'center', gap:14, transition:'all 0.18s',
              }}>
                <span style={{ fontSize:24, flexShrink:0 }}>{icon}</span>
                <div style={{ flex:1 }}>
                  <div style={{ fontSize:15, fontWeight:700, color:'#EDF2FC' }}>{label}</div>
                  <div style={{ fontSize:12, color:'#526480', marginTop:2 }}>{sub}</div>
                </div>
                <div style={{
                  width:22, height:22, borderRadius:'50%', flexShrink:0,
                  background: method===id?'#00E5B8':'transparent',
                  border:`2px solid ${method===id?'#00E5B8':'#243558'}`,
                  display:'flex', alignItems:'center', justifyContent:'center',
                  transition:'all 0.18s',
                }}>
                  {method===id && <Check size={13} color="#080D18" strokeWidth={3} />}
                </div>
              </button>
            ))}
          </div>
        </div>

        <Btn full size="lg" onClick={()=>nav('driver-dashboard')}>
          Confirm Payment — {total.toFixed(2)} EGP
        </Btn>
        <Btn full variant="ghost" size="md" onClick={()=>nav('driver-dashboard')} style={{ marginTop:10 }}>
          Cancel Trip
        </Btn>
      </div>
    </PhoneFrame>
  )
}

// ─── DRIVER: Wallet & Subscription ───────────────────────────────────────────
function DriverWallet({ nav }: { nav:(s:Screen)=>void }) {
  const [rechargeOpen, setRechargeOpen] = useState(false)

  const txns = [
    { type:'earn', label:'Trip completed', detail:'Ahmed H. · Tahrir→Zamalek',   amount:+34.50, time:'2h ago' },
    { type:'earn', label:'Trip completed', detail:'Sara M. · Tahrir→Dokki',       amount:+18.40, time:'4h ago' },
    { type:'fee',  label:'Platform fee',   detail:'Deducted automatically',        amount: -5.00, time:'4h ago' },
    { type:'earn', label:'Trip completed', detail:'Mohamed A. · Heliopolis→Maadi',amount:+62.00, time:'Yesterday' },
    { type:'earn', label:'Trip completed', detail:'Nour K. · Zamalek→Giza',       amount:+44.80, time:'Yesterday' },
    { type:'sub',  label:'Subscription',   detail:'Pro plan auto-renewal',         amount:-299.00, time:'3 days ago' },
  ]

  const weekData = [
    { d:'Mon', earn:320 }, { d:'Tue', earn:480 }, { d:'Wed', earn:390 },
    { d:'Thu', earn:560 }, { d:'Fri', earn:720 }, { d:'Sat', earn:890 }, { d:'Sun', earn:642 },
  ]

  return (
    <PhoneFrame theme="dark">
      <StatusBar theme="dark" />
      <ScreenBar title="Wallet & Subscription" onBack={()=>nav('driver-dashboard')} theme="dark" />
      <div style={{ padding:'14px 16px 40px', overflowY:'auto' }}>

        {/* Balance card */}
        <div style={{
          background:'linear-gradient(140deg, #001A14 0%, #002E22 60%, #001E30 100%)',
          border:'1px solid rgba(0,229,184,0.2)', borderRadius:22, padding:'22px 22px', marginBottom:14,
          position:'relative', overflow:'hidden',
        }}>
          <div style={{ position:'absolute', right:-40, top:-40, width:160, height:160, borderRadius:'50%', background:'rgba(0,229,184,0.04)', pointerEvents:'none' }} />
          <div style={{ position:'absolute', right:20, bottom:-20, width:80, height:80, borderRadius:'50%', background:'rgba(0,229,184,0.04)', pointerEvents:'none' }} />
          <div style={{ fontSize:10, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.07em', marginBottom:8 }}>
            Wallet Balance
          </div>
          <div style={{ display:'flex', alignItems:'baseline', gap:6, marginBottom:18 }}>
            <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:42, fontWeight:800, color:'#00E5B8', lineHeight:1 }}>1,248</span>
            <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:22, color:'#00B896' }}>.90</span>
            <span style={{ fontSize:14, color:'#526480', fontWeight:600 }}>EGP</span>
          </div>
          <div style={{ display:'flex', gap:10 }}>
            <button onClick={()=>setRechargeOpen(true)} style={{
              flex:1, padding:'11px', background:'#00E5B8', border:'none', borderRadius:12,
              cursor:'pointer', color:'#080D18', fontWeight:800, fontSize:13,
              fontFamily:"'Plus Jakarta Sans',sans-serif",
            }}>+ Recharge</button>
            <button style={{
              flex:1, padding:'11px', background:'rgba(0,229,184,0.1)',
              border:'1px solid rgba(0,229,184,0.25)', borderRadius:12, cursor:'pointer',
              color:'#00E5B8', fontWeight:700, fontSize:13, fontFamily:"'Plus Jakarta Sans',sans-serif",
            }}>Withdraw</button>
          </div>
        </div>

        {/* Subscription card */}
        <div style={{
          background:'linear-gradient(140deg, #1A1200 0%, #2A1E00 60%, #201200 100%)',
          border:'1px solid rgba(255,176,32,0.2)', borderRadius:22, padding:'18px 20px', marginBottom:18,
          position:'relative', overflow:'hidden',
        }}>
          <div style={{ position:'absolute', right:-30, top:-30, width:120, height:120, borderRadius:'50%', background:'rgba(255,176,32,0.04)', pointerEvents:'none' }} />
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:12 }}>
            <div>
              <div style={{ fontSize:10, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.06em', marginBottom:6 }}>Monthly Plan</div>
              <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:26, fontWeight:800, color:'#FFB020', lineHeight:1 }}>299 <span style={{fontSize:14,fontWeight:600}}>EGP</span></div>
              <div style={{ fontSize:12, color:'#8EA4C8', marginTop:4 }}>Pro Driver · Renews Aug 20, 2026</div>
            </div>
            <Badge label="ACTIVE" color="amber" dot />
          </div>
          {/* Progress */}
          <div style={{ marginBottom:8 }}>
            <div style={{ height:5, background:'rgba(255,176,32,0.12)', borderRadius:3, overflow:'hidden' }}>
              <div style={{ height:'100%', width:'65%', background:'linear-gradient(90deg,#FFB020,#E89800)', borderRadius:3 }} />
            </div>
            <div style={{ display:'flex', justifyContent:'space-between', marginTop:5 }}>
              <span style={{ fontSize:10, color:'#526480' }}>20 days used</span>
              <span style={{ fontSize:10, color:'#526480' }}>11 days remaining</span>
            </div>
          </div>
          {/* Stats */}
          <div style={{ display:'flex', gap:10 }}>
            {[{ v:'142', l:'Trips this month' }, { v:'4,830', l:'EGP earned' }, { v:'4.87', l:'Avg. rating' }].map(({ v, l })=>(
              <div key={l} style={{ flex:1, textAlign:'center', background:'rgba(255,176,32,0.06)', borderRadius:10, padding:'9px 0' }}>
                <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:17, fontWeight:800, color:'#FFB020' }}>{v}</div>
                <div style={{ fontSize:9, color:'#526480', marginTop:2 }}>{l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Mini chart */}
        <div style={{ background:'#0F1628', border:'1px solid #1C2B45', borderRadius:18, padding:'14px 16px', marginBottom:18 }}>
          <div style={{ fontSize:13, fontWeight:700, color:'#EDF2FC', marginBottom:12 }}>This Week's Earnings</div>
          <ResponsiveContainer width="100%" height={90}>
            <AreaChart data={weekData} margin={{ top:0, right:0, left:-30, bottom:0 }}>
              <defs>
                <linearGradient id="wkGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#00E5B8" stopOpacity={0.25} />
                  <stop offset="95%" stopColor="#00E5B8" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="d" tick={{ fontSize:10, fill:'#526480' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize:9, fill:'#526480' }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ background:'#0F1628', border:'1px solid #1C2B45', borderRadius:8, fontSize:11 }} />
              <Area type="monotone" dataKey="earn" stroke="#00E5B8" strokeWidth={2} fill="url(#wkGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Transactions */}
        <div style={{ fontSize:11, color:'#526480', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.05em', marginBottom:12 }}>Transaction History</div>
        {txns.map((txn, i)=>(
          <div key={i} style={{ display:'flex', alignItems:'center', gap:12, padding:'12px 0', borderBottom:'1px solid #1C2B45' }}>
            <div style={{
              width:38, height:38, borderRadius:11, flexShrink:0, display:'flex', alignItems:'center', justifyContent:'center',
              background: txn.type==='earn'?'rgba(0,229,184,0.1)':txn.type==='sub'?'rgba(255,176,32,0.1)':'rgba(255,59,92,0.1)',
            }}>
              {txn.type==='earn' ? <ArrowUpRight size={18} color="#00E5B8" /> : txn.type==='sub' ? <RefreshCw size={16} color="#FFB020" /> : <ArrowDownRight size={18} color="#FF3B5C" />}
            </div>
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ fontSize:14, fontWeight:700, color:'#EDF2FC' }}>{txn.label}</div>
              <div style={{ fontSize:11, color:'#526480', marginTop:2 }}>{txn.detail}</div>
              <div style={{ fontSize:10, color:'#3A5070', marginTop:1 }}>{txn.time}</div>
            </div>
            <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:15, fontWeight:800,
              color:txn.amount>0?'#00E5B8':'#FF3B5C', flexShrink:0 }}>
              {txn.amount>0?'+':''}{txn.amount.toFixed(2)}
            </div>
          </div>
        ))}
      </div>

      {/* Recharge modal */}
      {rechargeOpen && (
        <div className="anim-fadeIn" style={{ position:'absolute', inset:0, zIndex:50, background:'rgba(4,7,14,0.8)', display:'flex', alignItems:'flex-end' }}>
          <div className="anim-slideUp" style={{ background:'#0F1628', borderRadius:'24px 24px 0 0',
            padding:'22px 18px 48px', width:'100%', border:'1px solid #1C2B45' }}>
            <div style={{ width:40, height:4, background:'#243558', borderRadius:2, margin:'0 auto 20px' }} />
            <div style={{ fontSize:20, fontWeight:800, color:'#EDF2FC', marginBottom:18 }}>Recharge Wallet</div>
            {[
              { icon:'💳', label:'Paymob', sub:'Credit/debit card or Paymob wallet' },
              { icon:'📱', label:'Vodafone Cash', sub:'Instant mobile wallet top-up' },
              { icon:'🏦', label:'Bank Transfer', sub:'EGP wire transfer (1–2 business days)' },
            ].map(({ icon, label, sub })=>(
              <button key={label} onClick={()=>setRechargeOpen(false)} style={{
                width:'100%', background:'#0C1220', border:'1px solid #1C2B45',
                borderRadius:15, padding:'15px 16px', cursor:'pointer', textAlign:'left',
                marginBottom:10, display:'flex', alignItems:'center', gap:14,
              }}>
                <span style={{ fontSize:26 }}>{icon}</span>
                <div style={{ flex:1 }}>
                  <div style={{ fontSize:15, fontWeight:700, color:'#EDF2FC' }}>{label}</div>
                  <div style={{ fontSize:12, color:'#526480', marginTop:2 }}>{sub}</div>
                </div>
                <ChevronRight size={16} color="#243558" />
              </button>
            ))}
          </div>
        </div>
      )}
    </PhoneFrame>
  )
}

// ─── PASSENGER: Home ──────────────────────────────────────────────────────────
function PassengerHome({ nav, theme }: { nav:(s:Screen)=>void; theme:Theme }) {
  const [shared, setShared] = useState(false)
  const [tier, setTier] = useState<'car'|'tuktuk'|'moto'>('car')
  const isDark = theme==='dark'
  const C = TK[theme]

  const tiers = [
    { id:'car'    as const, emoji:'🚗', label:'Private Car', base:'10 EGP', rate:'1.80/km', eta:'4 min', price: shared?26:38, color: C.teal },
    { id:'tuktuk' as const, emoji:'🛺', label:'TukTuk',      base:'5 EGP',  rate:'0.90/km', eta:'2 min', price: shared?12:18, color: C.amber },
    { id:'moto'   as const, emoji:'🏍️', label:'Motorcycle', base:'7 EGP',  rate:'1.20/km', eta:'3 min', price: shared?15:22, color: C.blue },
  ]

  return (
    <div style={{ width:393, height:852, position:'relative',
      background:C.map, borderRadius:50,
      border:`2.5px solid ${isDark?'#1C2B45':'#C8D7EE'}`, overflow:'hidden',
      boxShadow: isDark?'0 48px 96px rgba(0,0,0,0.7)':'0 40px 80px rgba(0,0,0,0.18)' }}>

      <StatusBar theme={theme} />

      {/* Map */}
      <div style={{ position:'absolute', inset:0 }}>
        <CairoMap theme={theme} showRoute={false} />
      </div>

      {/* Top overlay */}
      <div style={{ position:'absolute', top:0, left:0, right:0, height:200,
        background: isDark
          ? 'linear-gradient(to bottom, rgba(8,13,24,0.96) 0%, rgba(8,13,24,0.5) 70%, transparent 100%)'
          : 'linear-gradient(to bottom, rgba(242,246,255,0.96) 0%, rgba(242,246,255,0.5) 70%, transparent 100%)',
        zIndex:10 }} />

      {/* Location inputs */}
      <div style={{ position:'absolute', top:42, left:14, right:14, zIndex:20 }}>
        <div style={{
          background: isDark?'rgba(9,14,26,0.94)':'rgba(255,255,255,0.97)',
          backdropFilter:'blur(20px)',
          border:`1.5px solid ${C.border}`, borderRadius:20, overflow:'hidden',
          boxShadow: isDark?'0 8px 40px rgba(0,0,0,0.5)':'0 4px 24px rgba(0,0,0,0.1)',
        }}>
          {/* Pickup */}
          <div style={{ display:'flex', alignItems:'center', gap:12, padding:'14px 16px' }}>
            <div style={{ width:10, height:10, borderRadius:'50%', background:C.teal, flexShrink:0, boxShadow:`0 0 8px ${C.teal}` }} />
            <input defaultValue="Tahrir Square, Cairo"
              style={{ flex:1, border:'none', background:'transparent', fontSize:14,
                fontFamily:"'Plus Jakarta Sans',sans-serif", color:C.text, outline:'none', fontWeight:600 }} />
          </div>
          <div style={{ height:1, background:C.border, margin:'0 16px' }} />
          {/* Drop-off */}
          <div style={{ display:'flex', alignItems:'center', gap:12, padding:'14px 16px' }}>
            <div style={{ width:10, height:10, borderRadius:2, background:'#FF3B5C', flexShrink:0 }} />
            <input placeholder="Where to?"
              style={{ flex:1, border:'none', background:'transparent', fontSize:14,
                fontFamily:"'Plus Jakarta Sans',sans-serif", color:C.text, outline:'none',
                fontWeight:500 }} />
            <Search size={15} color={C.muted} />
          </div>
        </div>
      </div>

      {/* Bottom booking sheet */}
      <div style={{
        position:'absolute', bottom:0, left:0, right:0, zIndex:20,
        background: isDark?'rgba(8,13,24,0.97)':'rgba(242,246,255,0.97)',
        backdropFilter:'blur(20px)',
        borderTop:`1px solid ${C.border}`, borderRadius:'24px 24px 0 0',
        padding:'14px 16px 36px',
      }}>
        <div style={{ width:40, height:4, borderRadius:2, background:C.border, margin:'0 auto 16px' }} />

        {/* Header row */}
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:14 }}>
          <div>
            <div style={{ fontSize:16, fontWeight:800, color:C.text }}>Choose Your Ride</div>
            <div style={{ fontSize:12, color:C.muted, marginTop:2 }}>~8.3 km · estimated prices</div>
          </div>
          {/* Shared toggle */}
          <div style={{ display:'flex', alignItems:'center', gap:8 }}>
            <div style={{ fontSize:11, color:C.muted, fontWeight:700, textTransform:'uppercase', letterSpacing:'0.04em' }}>Share</div>
            <button onClick={()=>setShared(!shared)} style={{
              width:46, height:26, borderRadius:13, border:'none', cursor:'pointer', position:'relative',
              background: shared?C.teal:C.border, transition:'background 0.22s',
            }}>
              <div style={{ width:20, height:20, borderRadius:'50%', background:'#fff', position:'absolute',
                top:3, left:shared?23:3, transition:'left 0.22s', boxShadow:'0 1px 5px rgba(0,0,0,0.3)' }} />
            </button>
          </div>
        </div>

        {/* Shared note */}
        {shared && (
          <div style={{ background:`${C.teal}12`, border:`1px solid ${C.teal}30`, borderRadius:12,
            padding:'9px 13px', marginBottom:12, display:'flex', gap:8, alignItems:'center' }}>
            <Users size={13} color={C.teal} style={{ flexShrink:0 }} />
            <span style={{ fontSize:12, color:C.teal, fontWeight:600 }}>
              Pooled ride — pay only for your distance. Save up to 35%.
            </span>
          </div>
        )}

        {/* Tier cards */}
        <div style={{ display:'flex', flexDirection:'column', gap:9, marginBottom:16 }}>
          {tiers.map(({ id, emoji, label, base, rate, eta, price, color })=>(
            <button key={id} onClick={()=>setTier(id)} style={{
              background: tier===id
                ? (isDark?`rgba(${hexToRgb(color)},0.07)`:`rgba(${hexToRgb(color)},0.06)`)
                : (isDark?'#0F1628':'#FFFFFF'),
              border:`2px solid ${tier===id?color:C.border}`,
              borderRadius:16, padding:'13px 15px', cursor:'pointer', textAlign:'left',
              display:'flex', alignItems:'center', gap:13, transition:'all 0.18s',
              boxShadow: tier===id?(isDark?`0 0 0 1px ${color}22`:'0 2px 12px rgba(0,0,0,0.08)'):'none',
            }}>
              <span style={{ fontSize:28, flexShrink:0 }}>{emoji}</span>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:15, fontWeight:800, color:C.text }}>{label}</div>
                <div style={{ fontSize:11, color:C.muted, marginTop:2 }}>Base {base} · {rate}</div>
              </div>
              <div style={{ textAlign:'right', flexShrink:0 }}>
                <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:17, fontWeight:800,
                  color: shared?color:(isDark?'#8EA4C8':C.sub) }}>~{price} EGP</div>
                <div style={{ fontSize:11, color:C.muted }}>ETA {eta}</div>
              </div>
              {tier===id && (
                <div style={{ width:22, height:22, borderRadius:'50%', background:color,
                  display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>
                  <Check size={13} color="#080D18" strokeWidth={3} />
                </div>
              )}
            </button>
          ))}
        </div>

        <Btn full size="lg" onClick={()=>nav('passenger-tracking')}>
          Book {tiers.find(t=>t.id===tier)!.label} →
        </Btn>

        {/* Bottom nav */}
        <div style={{ display:'flex', justifyContent:'space-around', marginTop:16, paddingTop:12, borderTop:`1px solid ${C.border}` }}>
          {[
            { icon:<Home size={20} />, label:'Home', active:true },
            { icon:<Calendar size={20} />, label:'Trips', active:false },
            { icon:<MessageSquare size={20} />, label:'Support', active:false },
            { icon:<Settings size={20} />, label:'Account', active:false },
          ].map(({ icon, label, active })=>(
            <button key={label} style={{ background:'none', border:'none', cursor:'pointer',
              display:'flex', flexDirection:'column', alignItems:'center', gap:4,
              color: active?C.teal:C.muted, fontFamily:"'Plus Jakarta Sans',sans-serif" }}>
              {icon}
              <span style={{ fontSize:10, fontWeight:700 }}>{label}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

// hex to rgb helper
function hexToRgb(hex: string) {
  const r = parseInt(hex.slice(1,3),16)
  const g = parseInt(hex.slice(3,5),16)
  const b = parseInt(hex.slice(5,7),16)
  return `${r},${g},${b}`
}

// ─── PASSENGER: Live Tracking ─────────────────────────────────────────────────
function PassengerTracking({ nav, theme }: { nav:(s:Screen)=>void; theme:Theme }) {
  const [myFare, setMyFare] = useState(12.40)
  const [poolFare, setPoolFare] = useState(8.30)
  const [eta, setEta] = useState(7.4)
  const [carY, setCarY] = useState(340)
  const isDark = theme==='dark'
  const C = TK[theme]

  useEffect(()=>{
    const t = setInterval(()=>{
      setMyFare(f=>Math.round((f+0.10)*100)/100)
      setPoolFare(f=>Math.round((f+0.066)*100)/100)
      setEta(e=>Math.max(0.1,e-0.02))
      setCarY(y=>{ const ny=y-0.7; return ny<160?340:ny })
    }, 900)
    return ()=>clearInterval(t)
  },[])

  const saving = Math.round((1 - poolFare/myFare)*100)

  return (
    <div style={{ width:393, height:852, position:'relative',
      background:C.map, borderRadius:50,
      border:`2.5px solid ${isDark?'#1C2B45':'#C8D7EE'}`, overflow:'hidden',
      boxShadow: isDark?'0 48px 96px rgba(0,0,0,0.7)':'0 40px 80px rgba(0,0,0,0.18)' }}>

      <StatusBar theme={theme} />

      {/* Map */}
      <div style={{ position:'absolute', inset:0 }}>
        <CairoMap theme={theme} carY={carY} />
      </div>

      {/* ETA chip */}
      <div style={{ position:'absolute', top:52, left:'50%', transform:'translateX(-50%)', zIndex:20 }}>
        <div style={{
          background: isDark?'rgba(9,14,26,0.96)':'rgba(255,255,255,0.96)',
          backdropFilter:'blur(16px)', borderRadius:22, padding:'10px 20px',
          border:`1.5px solid ${C.teal}44`, display:'flex', alignItems:'center', gap:10,
          boxShadow:`0 4px 24px rgba(0,0,0,0.3), 0 0 0 1px ${C.teal}22`,
        }}>
          <div style={{ width:8, height:8, borderRadius:'50%', background:C.teal,
            boxShadow:`0 0 0 0 ${C.teal}`, animation:'pulse-ring 2s infinite' }} />
          <span style={{ fontSize:13, fontWeight:700, color:C.text }}>Driver arriving in</span>
          <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:17, fontWeight:800, color:C.teal }}>
            {Math.ceil(eta)} min
          </span>
        </div>
      </div>

      {/* Bottom overlay gradient */}
      <div style={{ position:'absolute', bottom:0, left:0, right:0, height:380,
        background: isDark
          ? 'linear-gradient(to top, rgba(8,13,24,0.98) 60%, transparent 100%)'
          : 'linear-gradient(to top, rgba(242,246,255,0.98) 60%, transparent 100%)',
        zIndex:10 }} />

      {/* Info panel */}
      <div style={{ position:'absolute', bottom:0, left:0, right:0, zIndex:20, padding:'0 14px 36px' }}>

        {/* Fare meters */}
        <div style={{
          background: isDark?'rgba(12,18,32,0.98)':'rgba(255,255,255,0.98)',
          border:`1.5px solid ${C.border}`, borderRadius:20, padding:'16px 18px', marginBottom:11,
          boxShadow: isDark?'0 0 40px rgba(255,176,32,0.1)':'0 4px 24px rgba(0,0,0,0.08)',
        }}>
          <div style={{ display:'flex', gap:0, alignItems:'stretch' }}>
            {/* My fare */}
            <div style={{ flex:1 }}>
              <div style={{ fontSize:10, color:C.muted, fontWeight:700, textTransform:'uppercase', letterSpacing:'0.07em', marginBottom:5 }}>Your Fare</div>
              <div style={{ display:'flex', alignItems:'baseline', gap:4 }}>
                <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:32, fontWeight:800,
                  color:C.amber, lineHeight:1,
                  textShadow: isDark?'0 0 20px rgba(255,176,32,0.5)':undefined }}>
                  {myFare.toFixed(2)}
                </span>
                <span style={{ fontSize:13, color:C.muted }}>EGP</span>
              </div>
            </div>
            <div style={{ width:1, background:C.border, margin:'0 16px' }} />
            {/* Pool fare */}
            <div style={{ flex:1 }}>
              <div style={{ fontSize:10, color:C.muted, fontWeight:700, textTransform:'uppercase', letterSpacing:'0.07em', marginBottom:5 }}>Pool Fare</div>
              <div style={{ display:'flex', alignItems:'baseline', gap:4 }}>
                <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:32, fontWeight:800,
                  color:C.teal, lineHeight:1 }}>
                  {poolFare.toFixed(2)}
                </span>
                <span style={{ fontSize:13, color:C.muted }}>EGP</span>
              </div>
              <div style={{ fontSize:10, color:C.teal, fontWeight:700, marginTop:3 }}>saving ~{saving}%</div>
            </div>
          </div>

          <div style={{ display:'flex', gap:0, marginTop:13, paddingTop:11, borderTop:`1px solid ${C.border}` }}>
            {[{ l:'Distance', v:'3.2 km' }, { l:'Time', v:'12 min' }, { l:'Wait', v:'0 min' }].map(({ l,v },i)=>(
              <div key={l} style={{ flex:1, textAlign:'center', borderLeft:i>0?`1px solid ${C.border}`:undefined }}>
                <div style={{ fontSize:9, color:C.muted, textTransform:'uppercase', letterSpacing:'0.05em', marginBottom:3 }}>{l}</div>
                <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:13, color:C.sub, fontWeight:700 }}>{v}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Driver info */}
        <div style={{
          background: isDark?'rgba(12,18,32,0.98)':'rgba(255,255,255,0.98)',
          border:`1px solid ${C.border}`, borderRadius:16, padding:'13px 15px',
          display:'flex', alignItems:'center', gap:12, marginBottom:10,
        }}>
          <div style={{ width:46, height:46, borderRadius:13, background:C.card2,
            display:'flex', alignItems:'center', justifyContent:'center', fontSize:22, flexShrink:0 }}>
            👨
          </div>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:15, fontWeight:800, color:C.text }}>Khaled Ahmed</div>
            <div style={{ fontSize:12, color:C.muted }}>Toyota Camry · ABC 1234</div>
            <div style={{ display:'flex', alignItems:'center', gap:3, marginTop:4 }}>
              {[1,2,3,4,5].map(s=><Star key={s} size={11} fill="#FFB020" color="#FFB020" />)}
              <span style={{ fontSize:11, color:C.muted, marginLeft:4 }}>4.93</span>
            </div>
          </div>
          <div style={{ display:'flex', gap:8 }}>
            <button style={{ width:40, height:40, borderRadius:11, background:C.card2,
              border:`1px solid ${C.border}`, cursor:'pointer',
              display:'flex', alignItems:'center', justifyContent:'center' }}>
              <Phone size={16} color={C.teal} />
            </button>
            <button style={{ width:40, height:40, borderRadius:11, background:C.card2,
              border:`1px solid ${C.border}`, cursor:'pointer',
              display:'flex', alignItems:'center', justifyContent:'center' }}>
              <MessageSquare size={16} color={C.teal} />
            </button>
          </div>
        </div>

        {/* Shared indicator */}
        <div style={{
          background: isDark?'rgba(0,229,184,0.06)':'rgba(0,168,130,0.06)',
          border:`1px solid ${C.teal}25`, borderRadius:12, padding:'9px 14px',
          display:'flex', alignItems:'center', gap:9, marginBottom:12,
        }}>
          <Users size={13} color={C.teal} />
          <span style={{ fontSize:12, color:C.sub, fontWeight:600 }}>
            Sharing with <strong style={{color:C.text}}>2 other passengers</strong> — each paying separately
          </span>
          <Badge label="POOLED" color="teal" />
        </div>

        <Btn full variant="danger" onClick={()=>nav('passenger-rating')}>
          End Trip
        </Btn>
      </div>
    </div>
  )
}

// ─── PASSENGER: Rating ────────────────────────────────────────────────────────
function PassengerRating({ nav, theme }: { nav:(s:Screen)=>void; theme:Theme }) {
  const [rating, setRating] = useState(0)
  const [hov, setHov] = useState(0)
  const [tags, setTags] = useState<string[]>([])
  const [comment, setComment] = useState('')
  const [done, setDone] = useState(false)
  const isDark = theme==='dark'
  const C = TK[theme]

  const goodTags = ['Great driver','Safe driving','Clean car','On time','Friendly','Accurate route']
  const badTags  = ['Late pickup','Reckless driving','Wrong route','Unfriendly']

  const toggleTag = (t:string) => setTags(prev => prev.includes(t) ? prev.filter(x=>x!==t) : [...prev, t])

  const starLabels = ['','Poor','Fair','Good','Great','Excellent!']

  if (done) return (
    <PhoneFrame theme={theme}>
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center',
        justifyContent:'center', height:852, padding:40, textAlign:'center' }}>
        <div style={{ fontSize:80, marginBottom:24 }}>🎉</div>
        <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:32, fontWeight:700,
          color:C.text, marginBottom:12 }}>Thank You!</div>
        <div style={{ fontSize:15, color:C.muted, lineHeight:1.8, maxWidth:280, marginBottom:36 }}>
          Your feedback helps keep Adady Maren's fleet excellent for every passenger.
        </div>
        <Btn full size="lg" onClick={()=>nav('passenger-home')}>Book Another Ride</Btn>
      </div>
    </PhoneFrame>
  )

  return (
    <PhoneFrame theme={theme}>
      <StatusBar theme={theme} />
      <ScreenBar title="Rate Your Trip" theme={theme} />
      <div style={{ padding:'20px 20px 40px', overflowY:'auto' }}>

        {/* Receipt card */}
        <div style={{
          background: isDark?'#0F1628':'#FFFFFF', border:`1px solid ${C.border}`,
          borderRadius:20, padding:'16px 18px', marginBottom:24,
          boxShadow: isDark?'none':'0 2px 12px rgba(0,0,0,0.06)',
        }}>
          <div style={{ display:'flex', gap:13, alignItems:'center', marginBottom:14 }}>
            <div style={{ width:48, height:48, borderRadius:14, background:C.card2,
              display:'flex', alignItems:'center', justifyContent:'center', fontSize:22, flexShrink:0 }}>👨</div>
            <div style={{ flex:1 }}>
              <div style={{ fontSize:16, fontWeight:800, color:C.text }}>Khaled Ahmed</div>
              <div style={{ fontSize:12, color:C.muted }}>Toyota Camry · ABC 1234</div>
            </div>
            <div style={{ textAlign:'right' }}>
              <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:22, fontWeight:800, color:C.amber }}>29.54</div>
              <div style={{ fontSize:10, color:C.muted }}>EGP · Cash</div>
            </div>
          </div>
          <div style={{ display:'flex', gap:14, fontSize:12, color:C.muted,
            borderTop:`1px solid ${C.border}`, paddingTop:11 }}>
            <span>📍 Tahrir → Zamalek</span>
            <span>⏱ 28 min</span>
            <span>📏 8.3 km</span>
          </div>
        </div>

        {/* Star rating */}
        <div style={{ textAlign:'center', marginBottom:24 }}>
          <div style={{ fontSize:16, fontWeight:800, color:C.text, marginBottom:16 }}>How was your experience?</div>
          <div style={{ display:'flex', justifyContent:'center', gap:10 }}>
            {[1,2,3,4,5].map(s=>(
              <button key={s}
                onMouseEnter={()=>setHov(s)} onMouseLeave={()=>setHov(0)}
                onClick={()=>setRating(s)}
                style={{
                  background:'none', border:'none', cursor:'pointer',
                  transform:`scale(${(hov||rating)>=s?1.2:1})`,
                  transition:'transform 0.15s',
                  filter:(hov||rating)>=s?'drop-shadow(0 0 8px #FFB020)':undefined,
                }}>
                <Star size={44} fill={(hov||rating)>=s?'#FFB020':'transparent'}
                  color={(hov||rating)>=s?'#FFB020':C.border} strokeWidth={1.5} />
              </button>
            ))}
          </div>
          {rating>0 && (
            <div style={{ fontSize:14, color:C.muted, marginTop:10, fontWeight:600 }}>
              {starLabels[rating]}
            </div>
          )}
        </div>

        {/* Tags */}
        {rating>0 && (
          <div style={{ marginBottom:20 }}>
            <div style={{ fontSize:12, fontWeight:700, color:C.muted, marginBottom:10 }}>
              {rating>=4 ? 'What was great?' : 'What went wrong?'}
            </div>
            <div style={{ display:'flex', flexWrap:'wrap', gap:8 }}>
              {(rating>=4 ? goodTags : badTags).map(t=>(
                <button key={t} onClick={()=>toggleTag(t)} style={{
                  padding:'8px 14px', borderRadius:20,
                  background: tags.includes(t)?(isDark?`rgba(${hexToRgb(C.teal)},0.12)`:`rgba(${hexToRgb(C.teal)},0.1)`):(isDark?'#0F1628':'#EDF2FF'),
                  border:`1.5px solid ${tags.includes(t)?C.teal:C.border}`,
                  color: tags.includes(t)?C.teal:C.muted,
                  fontSize:13, fontWeight:600, cursor:'pointer', transition:'all 0.15s',
                  fontFamily:"'Plus Jakarta Sans',sans-serif",
                }}>
                  {t}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Comment */}
        <div style={{ marginBottom:20 }}>
          <textarea value={comment} onChange={e=>setComment(e.target.value)}
            placeholder="Add a comment (optional)…" rows={3}
            style={{
              width:'100%', padding:'13px 15px', resize:'none',
              background: isDark?'#0C1220':'#EDF2FF',
              border:`1.5px solid ${C.border}`, borderRadius:14,
              color:C.text, fontSize:14, fontFamily:"'Plus Jakarta Sans',sans-serif",
              outline:'none', lineHeight:1.6, boxSizing:'border-box',
            }} />
        </div>

        {/* Safety note */}
        <div style={{
          background: isDark?'rgba(255,176,32,0.05)':'rgba(232,146,0,0.06)',
          border:`1px solid ${C.amber}22`, borderRadius:14,
          padding:'12px 15px', marginBottom:22, display:'flex', gap:10, alignItems:'flex-start',
        }}>
          <Shield size={14} color={C.amber} style={{ flexShrink:0, marginTop:1 }} />
          <span style={{ fontSize:12, color:C.muted, lineHeight:1.7 }}>
            <strong style={{color:C.amber}}>Safety system:</strong> Mutual 1-star ratings automatically block the driver and passenger from future matches.
          </span>
        </div>

        <Btn full size="lg" disabled={rating===0} onClick={()=>setDone(true)}>
          Submit Rating {rating>0 ? `— ${starLabels[rating]}` : ''}
        </Btn>
      </div>
    </PhoneFrame>
  )
}

// ─── ADMIN DASHBOARD ──────────────────────────────────────────────────────────
function AdminDashboard({ nav, theme, toggleTheme }: { nav:(s:Screen)=>void; theme:Theme; toggleTheme:()=>void }) {
  const [tab, setTab] = useState<'overview'|'map'|'drivers'|'analytics'>('overview')
  const isDark = theme==='dark'
  const C = TK[theme]

  const revenue = [
    { d:'Mon', rev:12400, trips:284 }, { d:'Tue', rev:15200, trips:342 },
    { d:'Wed', rev:18900, trips:421 }, { d:'Thu', rev:14300, trips:318 },
    { d:'Fri', rev:22100, trips:498 }, { d:'Sat', rev:28400, trips:634 },
    { d:'Sun', rev:19800, trips:441 },
  ]
  const tierData = [
    { name:'Private Car', v:58, col:'#00E5B8' },
    { name:'TukTuk',      v:26, col:'#FFB020' },
    { name:'Motorcycle',  v:16, col:'#4D9FFF' },
  ]
  const drivers = [
    { name:'Khaled Ahmed',   vehicle:'Toyota Camry',    status:'active',  trips:8,  rev:342, rating:4.9 },
    { name:'Mohamed Samir',  vehicle:'Bajaj TukTuk',    status:'active',  trips:12, rev:228, rating:4.7 },
    { name:'Ali Hassan',     vehicle:'Honda Motorbike', status:'idle',    trips:3,  rev:98,  rating:4.8 },
    { name:'Amr Adel',       vehicle:'Hyundai Accent',  status:'offline', trips:0,  rev:0,   rating:4.5 },
    { name:'Tarek Nour',     vehicle:'Toyota Camry',    status:'active',  trips:6,  rev:285, rating:4.6 },
    { name:'Nour El-Din',    vehicle:'Bajaj TukTuk',    status:'active',  trips:9,  rev:185, rating:4.8 },
  ]

  const cbg = isDark?'#0F1628':'#FFFFFF'
  const cbr = isDark?'#1C2B45':'#DDE6F4'
  const bg2 = isDark?'#080D18':'#F2F6FF'

  return (
    <div style={{ minHeight:'100vh', background:isDark?'#060B14':'#EDF3FF',
      fontFamily:"'Plus Jakarta Sans',sans-serif", color:C.text }}>
      <div style={{ display:'flex', minHeight:'100vh' }}>

        {/* Sidebar */}
        <aside style={{ width:228, background:cbg, borderRight:`1px solid ${cbr}`,
          display:'flex', flexDirection:'column', flexShrink:0,
          position:'sticky', top:0, height:'100vh', overflowY:'auto' }}>

          <div style={{ padding:'22px 18px 16px', borderBottom:`1px solid ${cbr}` }}>
            <div style={{ display:'flex', alignItems:'center', gap:10 }}>
              <div style={{ width:36, height:36, borderRadius:10,
                background:'linear-gradient(135deg,#00E5B8,#0088CC)',
                display:'flex', alignItems:'center', justifyContent:'center' }}>
                <Navigation size={18} color="#050A14" strokeWidth={2.5} />
              </div>
              <div>
                <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:16, fontWeight:700, color:C.text, lineHeight:1 }}>Adady Maren</div>
                <div style={{ fontSize:9, color:C.muted, marginTop:2 }}>Admin Console</div>
              </div>
            </div>
          </div>

          <nav style={{ padding:'14px 10px', flex:1 }}>
            {[
              { id:'overview',  icon:<BarChart2 size={17} />, label:'Overview' },
              { id:'map',       icon:<Map size={17} />, label:'Live Map' },
              { id:'drivers',   icon:<UserCheck size={17} />, label:'Drivers' },
              { id:'analytics', icon:<TrendingUp size={17} />, label:'Analytics' },
            ].map(({ id, icon, label })=>(
              <button key={id} onClick={()=>setTab(id as typeof tab)} style={{
                width:'100%', display:'flex', alignItems:'center', gap:9, padding:'10px 12px',
                borderRadius:10, border:'none', cursor:'pointer', marginBottom:3,
                background: tab===id?(isDark?'rgba(0,229,184,0.1)':'rgba(0,168,130,0.08)'):'transparent',
                color: tab===id?C.teal:C.muted,
                fontWeight: tab===id?700:500, fontSize:14,
                fontFamily:"'Plus Jakarta Sans',sans-serif", transition:'all 0.15s',
              }}>
                {icon} {label}
              </button>
            ))}

            <div style={{ height:1, background:cbr, margin:'12px 0' }} />
            {[
              { icon:<Layers size={17} />, label:'Subscriptions' },
              { icon:<CreditCard size={17} />, label:'Payments' },
              { icon:<Settings size={17} />, label:'Settings' },
            ].map(({ icon, label })=>(
              <button key={label} style={{ width:'100%', display:'flex', alignItems:'center', gap:9, padding:'10px 12px',
                borderRadius:10, border:'none', cursor:'pointer', marginBottom:3,
                background:'transparent', color:C.muted, fontWeight:500, fontSize:14,
                fontFamily:"'Plus Jakarta Sans',sans-serif" }}>
                {icon} {label}
              </button>
            ))}
          </nav>

          <div style={{ padding:'12px 10px 20px', borderTop:`1px solid ${cbr}` }}>
            <button onClick={()=>nav('landing')} style={{ width:'100%', display:'flex', alignItems:'center', gap:9, padding:'9px 12px',
              borderRadius:10, border:'none', cursor:'pointer', background:'transparent',
              color:C.muted, fontWeight:500, fontSize:13, fontFamily:"'Plus Jakarta Sans',sans-serif" }}>
              <Globe size={16} /> Landing Page
            </button>
            <button style={{ width:'100%', display:'flex', alignItems:'center', gap:9, padding:'9px 12px',
              borderRadius:10, border:'none', cursor:'pointer', background:'transparent',
              color:'#FF3B5C', fontWeight:600, fontSize:13, fontFamily:"'Plus Jakarta Sans',sans-serif" }}>
              <LogOut size={16} /> Sign Out
            </button>
          </div>
        </aside>

        {/* Main */}
        <main style={{ flex:1, overflowY:'auto', padding:'28px 28px 40px' }}>
          {/* Top bar */}
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:24 }}>
            <div>
              <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:26, fontWeight:700, color:C.text, lineHeight:1 }}>
                {tab==='overview'?'Dashboard':tab==='map'?'Live Fleet':tab==='drivers'?'Drivers':' Analytics'}
              </div>
              <div style={{ fontSize:12, color:C.muted, marginTop:4 }}>Sunday, July 20, 2026 · Cairo, Egypt</div>
            </div>
            <div style={{ display:'flex', gap:10, alignItems:'center' }}>
              <button onClick={toggleTheme} style={{
                background:isDark?'#0F1628':'#E8EEF8', border:`1px solid ${cbr}`,
                borderRadius:9, padding:'8px 12px', cursor:'pointer', color:C.text,
                display:'flex', alignItems:'center', gap:6, fontSize:13, fontWeight:600,
                fontFamily:"'Plus Jakarta Sans',sans-serif",
              }}>
                {isDark?<Sun size={15}/>:<Moon size={15}/>}
                {isDark?'Light':'Dark'}
              </button>
              <div style={{ position:'relative' }}>
                <Bell size={19} color={C.muted} style={{ cursor:'pointer' }} />
                <div style={{ position:'absolute', top:-2, right:-2, width:8, height:8, borderRadius:'50%', background:'#FF3B5C' }} />
              </div>
              <div style={{ width:36, height:36, borderRadius:10, background:'linear-gradient(135deg,#00E5B8,#0088CC)',
                display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer' }}>
                <span style={{ fontSize:17 }}>👤</span>
              </div>
            </div>
          </div>

          {/* ── OVERVIEW ── */}
          {tab==='overview' && (<>
            {/* Stat cards */}
            <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:14, marginBottom:20 }}>
              {[
                { label:'Active Drivers', val:'142', change:'+12', up:true, icon:<Car size={17} color={C.teal} /> },
                { label:"Today's Revenue", val:'22,100', unit:'EGP', change:'+18%', up:true, icon:<TrendingUp size={17} color={C.amber} /> },
                { label:'Active Trips', val:'38', change:'+5', up:true, icon:<Activity size={17} color={C.blue} /> },
                { label:'Sub Renewals', val:'89', change:'-3', up:false, icon:<RefreshCw size={17} color={C.red} /> },
              ].map(({ label, val, unit, change, up, icon })=>(
                <div key={label} style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, padding:'16px 18px',
                  boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
                  <div style={{ display:'flex', justifyContent:'space-between', marginBottom:12 }}>
                    <div style={{ width:36, height:36, borderRadius:10, background:isDark?'#152038':'#EDF2FF',
                      display:'flex', alignItems:'center', justifyContent:'center' }}>
                      {icon}
                    </div>
                    <div style={{ fontSize:12, color:up?C.green:C.red, fontWeight:700,
                      display:'flex', alignItems:'center', gap:3 }}>
                      {up?<ArrowUpRight size={13}/>:<ArrowDownRight size={13}/>} {change}
                    </div>
                  </div>
                  <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:22, fontWeight:800, color:C.text, marginBottom:3 }}>
                    {val} <span style={{ fontSize:13, fontWeight:500, color:C.muted }}>{unit||''}</span>
                  </div>
                  <div style={{ fontSize:12, color:C.muted }}>{label}</div>
                </div>
              ))}
            </div>

            {/* Charts row */}
            <div style={{ display:'grid', gridTemplateColumns:'2fr 1fr', gap:16, marginBottom:16 }}>
              <div style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, padding:'18px 18px 10px',
                boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
                <div style={{ fontSize:14, fontWeight:700, color:C.text, marginBottom:14 }}>Weekly Revenue (EGP)</div>
                <ResponsiveContainer width="100%" height={175}>
                  <AreaChart data={revenue}>
                    <defs>
                      <linearGradient id="rg" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%"  stopColor={C.teal} stopOpacity={0.28} />
                        <stop offset="95%" stopColor={C.teal} stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke={cbr} vertical={false} />
                    <XAxis dataKey="d" tick={{ fontSize:11, fill:C.muted }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize:10, fill:C.muted }} axisLine={false} tickLine={false} />
                    <Tooltip contentStyle={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:10, fontSize:12 }} />
                    <Area type="monotone" dataKey="rev" stroke={C.teal} strokeWidth={2.5} fill="url(#rg)" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>

              <div style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, padding:'18px',
                boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
                <div style={{ fontSize:14, fontWeight:700, color:C.text, marginBottom:14 }}>Vehicle Mix</div>
                <ResponsiveContainer width="100%" height={130}>
                  <PieChart>
                    <Pie data={tierData} cx="50%" cy="50%" innerRadius={38} outerRadius={60}
                      paddingAngle={4} dataKey="v">
                      {tierData.map((entry, i)=><Cell key={i} fill={entry.col} />)}
                    </Pie>
                    <Tooltip contentStyle={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:8, fontSize:12 }} />
                  </PieChart>
                </ResponsiveContainer>
                <div style={{ display:'flex', flexDirection:'column', gap:7, marginTop:10 }}>
                  {tierData.map(({ name, v, col })=>(
                    <div key={name} style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                      <div style={{ display:'flex', alignItems:'center', gap:7 }}>
                        <div style={{ width:8, height:8, borderRadius:'50%', background:col }} />
                        <span style={{ fontSize:12, color:C.muted }}>{name}</span>
                      </div>
                      <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:12, fontWeight:700, color:C.text }}>{v}%</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Trips bar */}
            <div style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, padding:'18px 18px 10px',
              boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
              <div style={{ fontSize:14, fontWeight:700, color:C.text, marginBottom:14 }}>Daily Trip Volume</div>
              <ResponsiveContainer width="100%" height={130}>
                <BarChart data={revenue}>
                  <CartesianGrid strokeDasharray="3 3" stroke={cbr} vertical={false} />
                  <XAxis dataKey="d" tick={{ fontSize:11, fill:C.muted }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize:10, fill:C.muted }} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:10, fontSize:12 }} />
                  <Bar dataKey="trips" fill={C.amber} radius={[5,5,0,0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </>)}

          {/* ── MAP ── */}
          {tab==='map' && (
            <div style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, overflow:'hidden',
              boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
              <div style={{ padding:'14px 18px', borderBottom:`1px solid ${cbr}`, display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <div style={{ fontSize:14, fontWeight:700, color:C.text }}>Live Fleet — Cairo Metro Area</div>
                <div style={{ display:'flex', gap:8 }}>
                  <Badge label="142 Online" color="teal" dot />
                  <Badge label="38 Trips" color="amber" dot />
                  <Badge label="24 Idle" color="gray" dot />
                </div>
              </div>
              <div style={{ position:'relative', height:540 }}>
                {/* Extended Cairo map */}
                <svg width="100%" height="540" viewBox="0 0 900 540">
                  <rect width="900" height="540" fill={isDark?'#080E1C':'#B4C8E8'} />
                  {/* Grid */}
                  {Array.from({length:45}, (_,i)=>(i+1)*20).map(x=><line key={`gv${x}`} x1={x} y1={0} x2={x} y2={540} stroke={isDark?'rgba(20,35,65,0.9)':'rgba(100,130,175,0.35)'} strokeWidth={0.4} />)}
                  {Array.from({length:27}, (_,i)=>(i+1)*20).map(y=><line key={`gh${y}`} x1={0} y1={y} x2={900} y2={y} stroke={isDark?'rgba(20,35,65,0.9)':'rgba(100,130,175,0.35)'} strokeWidth={0.4} />)}
                  {/* Nile */}
                  <path d="M 160 0 Q 190 135 155 270 Q 130 405 170 540" stroke={isDark?'#0A1A40':'#7AA4D0'} strokeWidth={24} fill="none" />
                  {/* Major roads */}
                  <rect x={0} y={265} width={900} height={10} fill={isDark?'#0E1E38':'#8AAAD0'} />
                  <rect x={0} y={130} width={900} height={7}  fill={isDark?'#0A1630':'#96B8DA'} />
                  <rect x={0} y={400} width={900} height={7}  fill={isDark?'#0A1630':'#96B8DA'} />
                  <rect x={440} y={0} width={10} height={540} fill={isDark?'#0E1E38':'#8AAAD0'} />
                  <rect x={220} y={0} width={7}  height={540} fill={isDark?'#0A1630':'#96B8DA'} />
                  <rect x={660} y={0} width={7}  height={540} fill={isDark?'#0A1630':'#96B8DA'} />
                  <rect x={0} y={55}  width={900} height={4}  fill={isDark?'#0C1A35':'#9EC0E0'} />
                  <rect x={0} y={475} width={900} height={4}  fill={isDark?'#0C1A35':'#9EC0E0'} />
                  <rect x={100} y={0} width={4}  height={540} fill={isDark?'#0C1A35':'#9EC0E0'} />
                  <rect x={330} y={0} width={4}  height={540} fill={isDark?'#0C1A35':'#9EC0E0'} />
                  <rect x={780} y={0} width={4}  height={540} fill={isDark?'#0C1A35':'#9EC0E0'} />
                  {/* Vehicle dots */}
                  {([
                    [130,210,'car'],[260,300,'car'],[390,180,'moto'],[470,380,'car'],
                    [560,280,'tuktuk'],[680,200,'car'],[90,350,'moto'],[340,450,'car'],
                    [740,430,'tuktuk'],[510,110,'car'],[180,290,'car'],[620,370,'car'],
                    [280,140,'moto'],[750,110,'car'],[460,480,'tuktuk'],[820,290,'car'],
                  ] as [number,number,string][]).map(([x,y,type], i)=>{
                    const col = type==='car'?'#00E5B8':type==='moto'?'#4D9FFF':'#FFB020'
                    return (
                      <g key={i}>
                        <circle cx={x} cy={y} r={14} fill={`${col}22`} />
                        <circle cx={x} cy={y} r={7}  fill={col} />
                        <text x={x} y={y+4} textAnchor="middle" fontSize={9}>{type==='car'?'🚗':type==='moto'?'🏍️':'🛺'}</text>
                      </g>
                    )
                  })}
                  {/* Place labels */}
                  {([
                    [440,260,'Tahrir'],  [220,260,'Zamalek'],  [660,260,'Maadi'],
                    [440,125,'Heliopolis'], [660,125,'New Cairo'], [220,125,'Mohandessin'],
                    [440,395,'Giza'],    [220,395,'Dokki'],     [760,395,'Katameya'],
                  ] as [number,number,string][]).map(([x,y,name])=>(
                    <text key={String(name)} x={x} y={y} textAnchor="middle"
                      fontSize={11} fontWeight="700" fill={isDark?'#3A5880':'#4A6898'}
                      fontFamily="'Plus Jakarta Sans',sans-serif">{String(name)}</text>
                  ))}
                </svg>

                {/* Legend */}
                <div style={{ position:'absolute', top:14, right:14, background:isDark?'rgba(12,18,32,0.95)':'rgba(255,255,255,0.95)',
                  backdropFilter:'blur(8px)', borderRadius:13, padding:'12px 14px', border:`1px solid ${cbr}` }}>
                  {[{ col:'#00E5B8', l:'Private Car (98)' }, { col:'#FFB020', l:'TukTuk (29)' }, { col:'#4D9FFF', l:'Motorcycle (15)' }].map(({ col, l })=>(
                    <div key={l} style={{ display:'flex', alignItems:'center', gap:8, marginBottom:7 }}>
                      <div style={{ width:9, height:9, borderRadius:'50%', background:col }} />
                      <span style={{ fontSize:12, color:C.muted }}>{l}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ── DRIVERS ── */}
          {tab==='drivers' && (
            <div style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, overflow:'hidden',
              boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
              <div style={{ padding:'14px 18px', borderBottom:`1px solid ${cbr}`, display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <div style={{ fontSize:14, fontWeight:700, color:C.text }}>Driver Roster — Active Today</div>
                <Btn size="sm" icon={<Plus size={13} />}>Add Driver</Btn>
              </div>
              <table style={{ width:'100%', borderCollapse:'collapse' }}>
                <thead>
                  <tr style={{ background:isDark?'#0A1220':'#F5F8FF' }}>
                    {['Driver','Vehicle','Status','Trips Today','Revenue','Rating',''].map(h=>(
                      <th key={h} style={{ padding:'11px 16px', textAlign:'left', fontSize:10, fontWeight:700,
                        color:C.muted, textTransform:'uppercase', letterSpacing:'0.05em', borderBottom:`1px solid ${cbr}` }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {drivers.map((d,i)=>(
                    <tr key={i} style={{ borderBottom:`1px solid ${cbr}` }}>
                      <td style={{ padding:'13px 16px' }}>
                        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
                          <div style={{ width:34, height:34, borderRadius:10, background:isDark?'#152038':'#EDF2FF',
                            display:'flex', alignItems:'center', justifyContent:'center', fontSize:17 }}>👨</div>
                          <span style={{ fontSize:14, fontWeight:600, color:C.text }}>{d.name}</span>
                        </div>
                      </td>
                      <td style={{ padding:'13px 16px', fontSize:13, color:C.muted }}>{d.vehicle}</td>
                      <td style={{ padding:'13px 16px' }}>
                        <Badge label={d.status.toUpperCase()}
                          color={d.status==='active'?'teal':d.status==='idle'?'amber':'gray'} dot />
                      </td>
                      <td style={{ padding:'13px 16px', fontFamily:"'JetBrains Mono',monospace", fontSize:14, color:C.text }}>{d.trips}</td>
                      <td style={{ padding:'13px 16px', fontFamily:"'JetBrains Mono',monospace", fontSize:14, color:C.amber, fontWeight:700 }}>
                        {d.rev>0?`${d.rev} EGP`:'—'}
                      </td>
                      <td style={{ padding:'13px 16px' }}>
                        <div style={{ display:'flex', alignItems:'center', gap:5 }}>
                          <Star size={13} fill="#FFB020" color="#FFB020" />
                          <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:13, color:C.text }}>{d.rating}</span>
                        </div>
                      </td>
                      <td style={{ padding:'13px 16px' }}>
                        <button style={{ background:'none', border:'none', cursor:'pointer', color:C.muted }}>
                          <MoreVertical size={15} />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* ── ANALYTICS ── */}
          {tab==='analytics' && (<>
            {/* Subscription plans */}
            <div style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, padding:20, marginBottom:16,
              boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
              <div style={{ fontSize:14, fontWeight:700, color:C.text, marginBottom:16 }}>Subscription Revenue</div>
              <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:12 }}>
                {[
                  { plan:'Basic', price:199, drivers:234, col:'#526480' },
                  { plan:'Pro',   price:299, drivers:189, col:'#00E5B8' },
                  { plan:'Premium', price:499, drivers:42, col:'#FFB020' },
                ].map(({ plan, price, drivers, col })=>(
                  <div key={plan} style={{ background:isDark?'#0C1220':'#F5F8FF', borderRadius:13, padding:16,
                    borderLeft:`3px solid ${col}` }}>
                    <div style={{ fontSize:12, color:C.muted, marginBottom:8 }}>{plan} — {price} EGP/mo</div>
                    <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:22, fontWeight:800, color:C.text }}>
                      {drivers} <span style={{ fontSize:12, color:C.muted, fontWeight:400 }}>drivers</span>
                    </div>
                    <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:15, color:col, marginTop:6, fontWeight:700 }}>
                      {(drivers*price).toLocaleString()} EGP
                    </div>
                  </div>
                ))}
              </div>
            </div>
            {/* Full chart */}
            <div style={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:16, padding:'18px 18px 10px',
              boxShadow: isDark?'none':'0 2px 8px rgba(0,0,0,0.05)' }}>
              <div style={{ fontSize:14, fontWeight:700, color:C.text, marginBottom:16 }}>Revenue vs Trips — Weekly Comparison</div>
              <ResponsiveContainer width="100%" height={220}>
                <LineChart data={revenue}>
                  <CartesianGrid strokeDasharray="3 3" stroke={cbr} vertical={false} />
                  <XAxis dataKey="d" tick={{ fontSize:11, fill:C.muted }} axisLine={false} tickLine={false} />
                  <YAxis yAxisId="l" tick={{ fontSize:10, fill:C.muted }} axisLine={false} tickLine={false} />
                  <YAxis yAxisId="r" orientation="right" tick={{ fontSize:10, fill:C.muted }} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ background:cbg, border:`1px solid ${cbr}`, borderRadius:10, fontSize:12 }} />
                  <Line yAxisId="l" type="monotone" dataKey="rev" stroke={C.teal} strokeWidth={2.5} dot={{ r:4, fill:C.teal }} />
                  <Line yAxisId="r" type="monotone" dataKey="trips" stroke={C.amber} strokeWidth={2.5} dot={{ r:4, fill:C.amber }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </>)}
        </main>
      </div>
    </div>
  )
}

// ─── Landing Page ─────────────────────────────────────────────────────────────
function LandingPage({ nav, theme, toggleTheme }: { nav:(s:Screen)=>void; theme:Theme; toggleTheme:()=>void }) {
  const isDark = theme==='dark'
  const C = TK[theme]

  const features = [
    { emoji:'📡', title:'GPS Live Meter', desc:'Real-time fare calculated on distance, time, and wait — transparent as a classic taxi meter, precise as modern GPS.' },
    { emoji:'👥', title:'Smart Pooling', desc:'Share rides with nearby passengers heading the same way. Each person pays only for their exact net distance — no guessing.' },
    { emoji:'🔌', title:'Offline Resilience', desc:'Works without internet. Fares calculate locally and sync automatically when connectivity returns.' },
    { emoji:'🛺', title:'Three Vehicle Tiers', desc:'Private cars, TukTuks, and motorcycles — match the right vehicle to your journey, budget, and route.' },
    { emoji:'💳', title:'Flexible Payment', desc:'Cash, Paymob, or Vodafone Cash direct transfer. Pay how you live.' },
    { emoji:'🛡️', title:'Mutual Safety', desc:'Verified drivers, real-time trip sharing, emergency SOS, and a mutual rating system that protects all parties.' },
  ]
  const tiers = [
    { emoji:'🚗', name:'Private Car', base:10, per:'1.80', time:'0.15', wait:'0.50', col:'#00E5B8' },
    { emoji:'🛺', name:'TukTuk',      base:5,  per:'0.90', time:'0.10', wait:'0.25', col:'#FFB020' },
    { emoji:'🏍️', name:'Motorcycle', base:7,  per:'1.20', time:'0.12', wait:'0.30', col:'#4D9FFF' },
  ]

  return (
    <div style={{ minHeight:'100vh', background:isDark?'#060B14':'#EEF3FF',
      fontFamily:"'Plus Jakarta Sans',sans-serif", color:C.text }}>

      {/* Nav */}
      <nav style={{ position:'sticky', top:0, zIndex:50,
        background: isDark?'rgba(6,11,20,0.92)':'rgba(238,243,255,0.94)',
        backdropFilter:'blur(20px)', borderBottom:`1px solid ${C.border}` }}>
        <div style={{ maxWidth:1200, margin:'0 auto', padding:'0 24px',
          display:'flex', alignItems:'center', height:66 }}>
          <div style={{ flex:1, display:'flex', alignItems:'center', gap:12 }}>
            <div style={{ width:36, height:36, borderRadius:10,
              background:'linear-gradient(135deg,#00E5B8,#0088CC)',
              display:'flex', alignItems:'center', justifyContent:'center' }}>
              <Navigation size={18} color="#050A14" strokeWidth={2.5} />
            </div>
            <span style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:20, fontWeight:700, color:C.text }}>Adady Maren</span>
            <span style={{ fontSize:13, color:C.muted }}>عدادي مَرِنْ</span>
          </div>
          <div style={{ display:'flex', gap:6, alignItems:'center' }}>
            {['Features','Pricing','For Drivers','About'].map(l=>(
              <button key={l} style={{ background:'none', border:'none', padding:'8px 14px', cursor:'pointer',
                color:C.muted, fontSize:14, fontFamily:"'Plus Jakarta Sans',sans-serif" }}>{l}</button>
            ))}
            <button onClick={toggleTheme} style={{ background:isDark?'#0F1628':'#E0E8F5',
              border:`1px solid ${C.border}`, borderRadius:9, padding:'7px 11px', cursor:'pointer',
              color:C.text, display:'flex', alignItems:'center', gap:5, fontSize:12,
              fontFamily:"'Plus Jakarta Sans',sans-serif", marginLeft:4 }}>
              {isDark?<Sun size={14}/>:<Moon size={14}/>}
            </button>
            <Btn size="sm" onClick={()=>nav('role')} style={{ marginLeft:8 }}>Get the App</Btn>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section style={{ maxWidth:1200, margin:'0 auto', padding:'80px 24px 64px',
        display:'grid', gridTemplateColumns:'1fr 420px', gap:72, alignItems:'center' }}>
        <div>
          <div style={{ display:'inline-flex', alignItems:'center', gap:8, padding:'6px 14px',
            background: isDark?'rgba(0,229,184,0.08)':'rgba(0,168,130,0.08)',
            border:`1px solid ${C.teal}30`, borderRadius:20, marginBottom:24,
            fontSize:12, color:C.teal, fontWeight:700 }}>
            <Zap size={12} /> Now live in Cairo, Egypt
          </div>
          <h1 style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:68, fontWeight:700, lineHeight:0.95,
            color:C.text, margin:'0 0 22px', letterSpacing:'-0.02em' }}>
            The Meter.<br />
            <span style={{ color:C.teal, display:'inline-block',
              textShadow: isDark?'0 0 40px rgba(0,229,184,0.3)':undefined }}>Reinvented.</span>
          </h1>
          <p style={{ fontSize:18, color:C.muted, lineHeight:1.75, maxWidth:460, margin:'0 0 34px' }}>
            Adady Maren brings GPS-precision fare metering to Egyptian streets — transparent, pooling-ready, and built to work even when your connection doesn't.
          </p>
          <div style={{ display:'flex', gap:14, flexWrap:'wrap', marginBottom:48 }}>
            <Btn size="lg" onClick={()=>nav('role')} icon={<Download size={18} />}>Download App</Btn>
            <Btn size="lg" variant="outline" onClick={()=>nav('admin-dashboard')}>View Admin Demo →</Btn>
          </div>
          {/* Stats */}
          <div style={{ display:'flex', gap:40 }}>
            {[{ v:'2,400+', l:'Active drivers' }, { v:'48K', l:'Trips/month' }, { v:'4.87★', l:'Avg. rating' }].map(({ v, l })=>(
              <div key={l}>
                <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:26, fontWeight:800, color:C.text, lineHeight:1 }}>{v}</div>
                <div style={{ fontSize:13, color:C.muted, marginTop:5 }}>{l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Phone preview stack */}
        <div style={{ display:'flex', position:'relative', justifyContent:'center', height:540, alignItems:'flex-end' }}>
          <div style={{ transform:'rotate(-7deg) translateY(24px)', transformOrigin:'bottom center',
            scale:'0.68', position:'absolute', left:-20, bottom:0, zIndex:1, transformBox:'fill-box' }}>
            <PassengerHome nav={nav} theme={theme} />
          </div>
          <div style={{ transform:'rotate(3deg)', transformOrigin:'bottom center',
            scale:'0.68', position:'absolute', right:-20, bottom:0, zIndex:2, transformBox:'fill-box' }}>
            <DriverDashboard nav={nav} />
          </div>
        </div>
      </section>

      {/* Features */}
      <section style={{ background:isDark?'#0A0F1E':'#E4ECFC', padding:'72px 24px' }}>
        <div style={{ maxWidth:1200, margin:'0 auto' }}>
          <div style={{ textAlign:'center', marginBottom:52 }}>
            <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:44, fontWeight:700, color:C.text, marginBottom:12 }}>
              Everything You Need
            </div>
            <div style={{ fontSize:17, color:C.muted, maxWidth:520, margin:'0 auto', lineHeight:1.7 }}>
              Built for Egyptian streets — where connectivity is unpredictable and every piaster counts.
            </div>
          </div>
          <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:18 }}>
            {features.map(({ emoji, title, desc })=>{
              const [hov, setHov] = useState(false)
              return (
                <div key={title}
                  onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)}
                  style={{
                    background: isDark?'#0F1628':'#FFFFFF',
                    border:`1px solid ${hov?(isDark?'rgba(0,229,184,0.3)':C.teal+'50'):C.border}`,
                    borderRadius:22, padding:'26px 24px',
                    boxShadow: hov
                      ? (isDark?'0 12px 48px rgba(0,0,0,0.4), 0 0 0 1px rgba(0,229,184,0.1)':'0 12px 40px rgba(0,0,0,0.1)')
                      : (isDark?'none':'0 2px 8px rgba(0,0,0,0.05)'),
                    transform: hov?'translateY(-4px)':'none',
                    transition:'all 0.22s ease', cursor:'default',
                  }}>
                  <div style={{ fontSize:38, marginBottom:14 }}>{emoji}</div>
                  <div style={{ fontSize:18, fontWeight:800, color:C.text, marginBottom:8 }}>{title}</div>
                  <div style={{ fontSize:14, color:C.muted, lineHeight:1.75 }}>{desc}</div>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section style={{ maxWidth:1200, margin:'0 auto', padding:'72px 24px' }}>
        <div style={{ textAlign:'center', marginBottom:48 }}>
          <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:44, fontWeight:700, color:C.text, marginBottom:12 }}>
            Transparent Pricing
          </div>
          <div style={{ fontSize:17, color:C.muted }}>No surge. No hidden fees. The meter shows exactly what you pay.</div>
        </div>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:20 }}>
          {tiers.map(({ emoji, name, base, per, time, wait, col })=>(
            <div key={name} style={{ background:isDark?'#0F1628':'#FFFFFF',
              border:`1.5px solid ${C.border}`, borderRadius:22, overflow:'hidden',
              boxShadow: isDark?'none':'0 2px 12px rgba(0,0,0,0.06)' }}>
              <div style={{ background:`${col}12`, borderBottom:`1.5px solid ${col}28`,
                padding:'22px 24px', display:'flex', alignItems:'center', gap:14 }}>
                <span style={{ fontSize:34 }}>{emoji}</span>
                <div>
                  <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:22, fontWeight:700, color:C.text }}>{name}</div>
                  <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:22, fontWeight:800, color:col, marginTop:3 }}>
                    {base} EGP
                  </div>
                  <div style={{ fontSize:10, color:C.muted }}>base fare</div>
                </div>
              </div>
              <div style={{ padding:'18px 24px' }}>
                {[{ l:'Per kilometer', v:`${per} EGP` }, { l:'Per minute (moving)', v:`${time} EGP` }, { l:'Per minute (wait)', v:`${wait} EGP` }].map(({ l,v })=>(
                  <div key={l} style={{ display:'flex', justifyContent:'space-between', padding:'9px 0', borderBottom:`1px solid ${C.border}` }}>
                    <span style={{ fontSize:13, color:C.muted }}>{l}</span>
                    <span style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:13, fontWeight:700, color:C.text }}>{v}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Driver CTA */}
      <section style={{ background:'#010D08', padding:'80px 24px' }}>
        <div style={{ maxWidth:900, margin:'0 auto', textAlign:'center' }}>
          <div style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:48, fontWeight:700, color:'#EDF2FC', marginBottom:16, lineHeight:1.05 }}>
            Drive. Earn.<br />Keep 100%.
          </div>
          <p style={{ fontSize:17, color:'#526480', maxWidth:560, margin:'0 auto 40px', lineHeight:1.8 }}>
            No commission on fares. A flat 299 EGP/month subscription. Join 2,400+ drivers already earning transparently on Adady Maren.
          </p>
          <div style={{ display:'flex', gap:14, justifyContent:'center', marginBottom:56 }}>
            <Btn size="lg" onClick={()=>nav('auth')}>Start Driving Today</Btn>
            <Btn size="lg" variant="outline" onClick={()=>nav('driver-wallet')}
              style={{ borderColor:'#243558', color:'#8EA4C8' }}>
              View Earnings
            </Btn>
          </div>
          <div style={{ display:'flex', gap:48, justifyContent:'center' }}>
            {[{ v:'299 EGP', l:'Flat monthly plan' }, { v:'0%', l:'Commission cut' }, { v:'<30s', l:'Request response' }].map(({ v, l })=>(
              <div key={l} style={{ textAlign:'center' }}>
                <div style={{ fontFamily:"'JetBrains Mono',monospace", fontSize:28, fontWeight:800, color:'#00E5B8', marginBottom:6 }}>{v}</div>
                <div style={{ fontSize:13, color:'#526480' }}>{l}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer style={{ borderTop:`1px solid ${C.border}`, padding:'36px 24px', background:isDark?'#080D18':'#EEF3FF' }}>
        <div style={{ maxWidth:1200, margin:'0 auto',
          display:'flex', justifyContent:'space-between', alignItems:'center', flexWrap:'wrap', gap:16 }}>
          <div style={{ display:'flex', alignItems:'center', gap:10 }}>
            <div style={{ width:30, height:30, borderRadius:8,
              background:'linear-gradient(135deg,#00E5B8,#0088CC)',
              display:'flex', alignItems:'center', justifyContent:'center' }}>
              <Navigation size={15} color="#050A14" strokeWidth={2.5} />
            </div>
            <span style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:17, fontWeight:700, color:C.text }}>Adady Maren</span>
            <span style={{ fontSize:12, color:C.muted }}>عدادي مَرِنْ</span>
          </div>
          <div style={{ fontSize:12, color:C.muted }}>© 2026 Adady Maren · Cairo, Egypt</div>
          <div style={{ display:'flex', gap:20 }}>
            {['Privacy','Terms','Support','Careers'].map(l=>(
              <span key={l} style={{ fontSize:12, color:C.muted, cursor:'pointer' }}>{l}</span>
            ))}
          </div>
        </div>
      </footer>
    </div>
  )
}

// Lock icon component (used in AuthScreen)
function Lock({ size=16 }: { size?:number }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
}

// ─── Navigation bar ───────────────────────────────────────────────────────────
function TopNav({ current, nav, role, theme, toggleTheme }: {
  current:Screen; nav:(s:Screen)=>void; role:Role; theme:Theme; toggleTheme:()=>void
}) {
  const isDark = theme==='dark'
  const C = TK[theme]
  const shared: {id:Screen;label:string}[] = [
    {id:'splash',label:'✨ Splash'}, {id:'role',label:'🎭 Role'}, {id:'auth',label:'🔐 Auth'}, {id:'otp',label:'📱 OTP'},
  ]
  const driver: {id:Screen;label:string}[] = [
    {id:'driver-dashboard',label:'🗺 Dashboard'},{id:'driver-dispatch',label:'⚡ Dispatch'},
    {id:'driver-payment',label:'💳 Payment'},{id:'driver-wallet',label:'👛 Wallet'},
  ]
  const passenger: {id:Screen;label:string}[] = [
    {id:'passenger-home',label:'🏠 Home'},{id:'passenger-tracking',label:'📍 Track'},{id:'passenger-rating',label:'⭐ Rate'},
  ]
  const admin: {id:Screen;label:string}[] = [
    {id:'admin-dashboard',label:'📊 Admin'},{id:'landing',label:'🌐 Landing'},
  ]

  const all = role==='driver' ? [...shared,...driver] :
              role==='passenger' ? [...shared,...passenger] :
              role==='admin' ? admin :
              [...shared,...driver,...passenger,...admin]

  return (
    <div style={{ background:isDark?'#080D18':'#FFFFFF', borderBottom:`1px solid ${isDark?'#1C2B45':'#DDE6F4'}`,
      padding:'8px 16px', display:'flex', gap:5, alignItems:'center', flexWrap:'wrap', rowGap:5 }}>
      <div style={{ display:'flex', alignItems:'center', gap:8, marginRight:12, flexShrink:0 }}>
        <div style={{ width:26, height:26, borderRadius:7,
          background:'linear-gradient(135deg,#00E5B8,#0088CC)',
          display:'flex', alignItems:'center', justifyContent:'center' }}>
          <Navigation size={13} color="#050A14" strokeWidth={2.5} />
        </div>
        <span style={{ fontFamily:"'Rajdhani',sans-serif", fontSize:15, fontWeight:700, color:C.text }}>Adady Maren</span>
      </div>
      {all.map(({ id, label })=>(
        <button key={id} onClick={()=>nav(id)} style={{
          padding:'6px 11px', borderRadius:8, border:'none', cursor:'pointer',
          background: current===id?'#00E5B8':(isDark?'#0F1628':'#EDF2FF'),
          color: current===id?'#080D18':C.muted,
          fontSize:12, fontWeight:700, whiteSpace:'nowrap',
          fontFamily:"'Plus Jakarta Sans',sans-serif", transition:'all 0.15s',
        }}>{label}</button>
      ))}
      <div style={{ marginLeft:'auto', display:'flex', gap:8, alignItems:'center' }}>
        <button onClick={toggleTheme} style={{
          background:isDark?'#0F1628':'#E8EEF8', border:`1px solid ${C.border}`,
          borderRadius:8, padding:'6px 10px', cursor:'pointer', color:C.text,
          display:'flex', alignItems:'center', gap:5, fontSize:12, fontWeight:600,
          fontFamily:"'Plus Jakarta Sans',sans-serif",
        }}>
          {isDark?<Sun size={13}/>:<Moon size={13}/>} {isDark?'Light':'Dark'}
        </button>
        <button onClick={()=>nav('role')} style={{
          background:'none', border:`1px solid ${C.border}`, borderRadius:8,
          padding:'6px 10px', cursor:'pointer', color:C.muted, fontSize:12,
          fontFamily:"'Plus Jakarta Sans',sans-serif",
        }}>Switch Role</button>
      </div>
    </div>
  )
}

// ─── App root ─────────────────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState<Screen>('splash')
  const [role, setRole] = useState<Role>(null)
  const [theme, toggleTheme] = useTheme()

  const nav = (s: Screen) => setScreen(s)

  const handleRole = (r: Role) => {
    setRole(r)
    if (r==='admin') setScreen('admin-dashboard')
    else if (r==='driver'||r==='passenger') setScreen('auth')
    else setScreen('landing')
  }

  const isFullWidth = screen==='admin-dashboard'||screen==='landing'
  const phoneTheme: Theme = role==='passenger' ? theme : 'dark'

  const renderScreen = () => {
    switch(screen) {
      case 'splash':              return <SplashScreen onDone={()=>setScreen('role')} />
      case 'role':                return <RoleScreen onSelect={handleRole} />
      case 'auth':                return <AuthScreen onNext={()=>setScreen('otp')} theme={phoneTheme} />
      case 'otp':                 return <OTPScreen onNext={()=>setScreen(role==='driver'?'driver-dashboard':'passenger-home')} theme={phoneTheme} />
      case 'driver-dashboard':    return <DriverDashboard nav={nav} />
      case 'driver-dispatch':     return <DriverDispatch nav={nav} />
      case 'driver-payment':      return <DriverPayment nav={nav} />
      case 'driver-wallet':       return <DriverWallet nav={nav} />
      case 'passenger-home':      return <PassengerHome nav={nav} theme={phoneTheme} />
      case 'passenger-tracking':  return <PassengerTracking nav={nav} theme={phoneTheme} />
      case 'passenger-rating':    return <PassengerRating nav={nav} theme={phoneTheme} />
      default: return <SplashScreen onDone={()=>setScreen('role')} />
    }
  }

  if (isFullWidth) return (
    <div style={{ minHeight:'100vh', background:theme==='dark'?'#060B14':'#EEF3FF' }}>
      <TopNav current={screen} nav={nav} role={role} theme={theme} toggleTheme={toggleTheme} />
      {screen==='admin-dashboard' && <AdminDashboard nav={nav} theme={theme} toggleTheme={toggleTheme} />}
      {screen==='landing'         && <LandingPage nav={nav} theme={theme} toggleTheme={toggleTheme} />}
    </div>
  )

  return (
    <div style={{ minHeight:'100vh',
      background: phoneTheme==='dark'
        ? 'radial-gradient(ellipse at 50% 0%, #0C1A30 0%, #060B14 60%)'
        : 'radial-gradient(ellipse at 50% 0%, #D8E8FF 0%, #C8D8F0 60%)',
      display:'flex', flexDirection:'column' }}>
      <TopNav current={screen} nav={nav} role={role} theme={theme} toggleTheme={toggleTheme} />
      <div style={{ flex:1, display:'flex', alignItems:'flex-start', justifyContent:'center', padding:'36px 24px 56px' }}>
        <div key={screen} className="anim-fadeUp">
          {renderScreen()}
        </div>
      </div>
    </div>
  )
}
