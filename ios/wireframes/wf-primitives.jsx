// Wireframe primitives — monochrome, structural, Korean copy
// Low-fidelity: rectangles, thin strokes, neutral grays

const WF = {
  ink: '#1a1a1a',
  line: '#222',
  line2: '#777',
  line3: '#c4c4c4',
  bg: '#fafaf7',
  gray: '#ededea',
  gray2: '#d8d6d0',
  muted: '#8a8a86',
  note: '#c44',
  font: '-apple-system, "SF Pro", system-ui, sans-serif',
  // Korean font stack
  kfont: '"Apple SD Gothic Neo", "Noto Sans KR", -apple-system, system-ui, sans-serif',
};

// Thin framed box — wireframe default
function WBox({ children, style, stroke = WF.line, bg = 'transparent', pad = 0, round = 0 }) {
  return (
    <div style={{
      border: `1px solid ${stroke}`,
      background: bg,
      borderRadius: round,
      padding: pad,
      boxSizing: 'border-box',
      ...style,
    }}>{children}</div>
  );
}

// Placeholder rectangle with X (image / unknown content)
function WPlaceholder({ w = '100%', h = 80, label, style }) {
  return (
    <div style={{
      width: w, height: h, border: `1px solid ${WF.line2}`,
      position: 'relative', boxSizing: 'border-box',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: WF.kfont, fontSize: 10, color: WF.muted,
      background: '#fff',
      ...style,
    }}>
      <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0 }} preserveAspectRatio="none">
        <line x1="0" y1="0" x2="100%" y2="100%" stroke={WF.line3} strokeWidth="1"/>
        <line x1="100%" y1="0" x2="0" y2="100%" stroke={WF.line3} strokeWidth="1"/>
      </svg>
      {label && <span style={{ position: 'relative', background: '#fff', padding: '0 4px' }}>{label}</span>}
    </div>
  );
}

// Text-line placeholder (horizontal bar of "text")
function WLine({ w = '100%', h = 8, style }) {
  return <div style={{ width: w, height: h, background: WF.gray2, borderRadius: 1, ...style }} />;
}

// Title-weight line
function WTitle({ w = '60%', h = 14, style }) {
  return <div style={{ width: w, height: h, background: WF.line, borderRadius: 1, ...style }} />;
}

// Korean text — actual labels (we want readable)
function WText({ children, size = 11, weight = 400, color = WF.ink, style }) {
  return (
    <span style={{
      fontFamily: WF.kfont, fontSize: size, fontWeight: weight,
      color, lineHeight: 1.35, letterSpacing: -0.3,
      ...style,
    }}>{children}</span>
  );
}

// Button (wireframe style)
function WButton({ children, primary = false, w = '100%', h = 40, style }) {
  return (
    <div style={{
      width: w, height: h,
      border: `1px solid ${WF.line}`,
      background: primary ? WF.line : '#fff',
      color: primary ? '#fff' : WF.ink,
      borderRadius: 6,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: WF.kfont, fontSize: 13, fontWeight: 500,
      boxSizing: 'border-box',
      ...style,
    }}>{children}</div>
  );
}

// Locked section — blur + lock icon overlay
function WLocked({ children, label = '구독 후 열람' }) {
  return (
    <div style={{ position: 'relative' }}>
      <div style={{ filter: 'blur(3px)', opacity: 0.55, pointerEvents: 'none' }}>
        {children}
      </div>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex',
        alignItems: 'center', justifyContent: 'center', flexDirection: 'column',
        gap: 6, pointerEvents: 'none',
      }}>
        <svg width="18" height="22" viewBox="0 0 18 22" fill="none">
          <rect x="1" y="9" width="16" height="12" rx="2" stroke={WF.ink} strokeWidth="1.3"/>
          <path d="M4 9V6a5 5 0 0 1 10 0v3" stroke={WF.ink} strokeWidth="1.3"/>
          <circle cx="9" cy="15" r="1.3" fill={WF.ink}/>
        </svg>
        <WText size={10} weight={600}>{label}</WText>
      </div>
    </div>
  );
}

// Annotation — red callout with arrow
function WNote({ children, style, side = 'right', arrow = true }) {
  return (
    <div style={{
      position: 'absolute',
      fontFamily: WF.kfont, fontSize: 11, color: WF.note,
      lineHeight: 1.4, maxWidth: 180,
      ...style,
    }}>
      {arrow && side === 'left' && (
        <span style={{ marginRight: 6, color: WF.note }}>→</span>
      )}
      {children}
      {arrow && side === 'right' && (
        <span style={{ marginLeft: 6, color: WF.note }}>←</span>
      )}
    </div>
  );
}

// Tab bar (bottom nav) — 4 items
function WTabBar({ active = 0 }) {
  const tabs = ['홈', '투자', '사주', '마이'];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      height: 64, borderTop: `1px solid ${WF.line3}`,
      display: 'flex', background: '#fff', paddingBottom: 14, zIndex: 5,
    }}>
      {tabs.map((t, i) => (
        <div key={t} style={{
          flex: 1, display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center', gap: 3,
        }}>
          <div style={{
            width: 18, height: 18, border: `1.2px solid ${i === active ? WF.ink : WF.line2}`,
            borderRadius: 3,
          }}/>
          <WText size={9} weight={i === active ? 700 : 400} color={i === active ? WF.ink : WF.muted}>{t}</WText>
        </div>
      ))}
    </div>
  );
}

// Phone-screen frame (simpler than full iOS — notch, status bar, home bar)
function WPhone({ children, label, w = 300, h = 620 }) {
  return (
    <div style={{
      width: w, height: h, background: WF.bg,
      border: `1.2px solid ${WF.line}`,
      borderRadius: 28, position: 'relative', overflow: 'hidden',
      boxShadow: '0 2px 10px rgba(0,0,0,0.05)',
    }}>
      {/* status bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 34,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '0 20px', fontFamily: WF.font, fontSize: 11, fontWeight: 600,
        color: WF.ink, zIndex: 20,
      }}>
        <span>9:41</span>
        <div style={{
          position: 'absolute', left: '50%', top: 8, transform: 'translateX(-50%)',
          width: 70, height: 20, background: WF.ink, borderRadius: 12,
        }}/>
        <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
          <div style={{ width: 12, height: 8, border: `1px solid ${WF.ink}`, borderRadius: 1 }}/>
        </div>
      </div>
      {/* screen content */}
      <div style={{ position: 'absolute', inset: 0, paddingTop: 34, overflow: 'hidden' }}>
        {children}
      </div>
      {/* home indicator */}
      <div style={{
        position: 'absolute', bottom: 6, left: '50%', transform: 'translateX(-50%)',
        width: 100, height: 4, borderRadius: 2, background: WF.line, opacity: 0.4, zIndex: 30,
      }}/>
    </div>
  );
}

// Header inside a screen (title + optional back)
function WHeader({ title, back = false, right = null }) {
  return (
    <div style={{
      height: 44, display: 'flex', alignItems: 'center',
      padding: '0 16px', borderBottom: `1px solid ${WF.line3}`,
      position: 'relative',
    }}>
      {back && (
        <div style={{ width: 20, display: 'flex', alignItems: 'center' }}>
          <svg width="8" height="14" viewBox="0 0 8 14">
            <path d="M7 1L1 7l6 6" fill="none" stroke={WF.ink} strokeWidth="1.5" strokeLinecap="round"/>
          </svg>
        </div>
      )}
      <WText size={14} weight={600} style={{ flex: 1, textAlign: back ? 'center' : 'left', paddingRight: back ? 20 : 0 }}>{title}</WText>
      {right}
    </div>
  );
}

// Card — container with thin border
function WCard({ children, style }) {
  return (
    <div style={{
      border: `1px solid ${WF.line2}`,
      borderRadius: 8, padding: 12, background: '#fff',
      boxSizing: 'border-box',
      ...style,
    }}>{children}</div>
  );
}

// Section label (ALL CAPS small header above a section)
function WSectionLabel({ children, style }) {
  return (
    <div style={{
      fontFamily: WF.kfont, fontSize: 10, fontWeight: 700,
      color: WF.muted, letterSpacing: 0.5, textTransform: 'uppercase',
      marginBottom: 6, ...style,
    }}>{children}</div>
  );
}

// Disclaimer footer — 모든 투자 관련 화면 하단 상시 표시
function WDisclaimer() {
  return (
    <div style={{
      padding: '6px 14px', borderTop: `1px solid ${WF.line3}`,
      background: '#fafaf7',
    }}>
      <WText size={8} color={WF.muted}>
        본 앱은 학습·참고용이며 투자 권유가 아닙니다. 투자 결정은 본인 판단과 책임 하에 이루어져야 합니다.
      </WText>
    </div>
  );
}

Object.assign(window, {
  WF, WBox, WPlaceholder, WLine, WTitle, WText, WButton,
  WLocked, WNote, WTabBar, WPhone, WHeader, WCard, WSectionLabel, WDisclaimer,
});
