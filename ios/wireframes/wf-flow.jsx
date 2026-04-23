// Flow diagram: nodes + arrows showing user journey through the app

function FlowNode({ x, y, w = 120, h = 54, label, sub, accent, locked, onCanvas = true }) {
  return (
    <div style={{
      position: 'absolute', left: x, top: y, width: w, height: h,
      border: `${accent ? 2 : 1}px solid ${accent ? WF.accent : WF.ink}`,
      background: WF.paper,
      padding: 8, boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 2,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
        <span style={{ fontFamily: WF.hand, fontSize: 13, fontWeight: 700, color: WF.ink }}>{label}</span>
        {locked && (
          <svg width="10" height="10" viewBox="0 0 22 22" fill="none" stroke={WF.lock} strokeWidth="2">
            <rect x="4.5" y="10" width="13" height="9" rx="1"/>
            <path d="M7 10V7a4 4 0 018 0v3"/>
          </svg>
        )}
      </div>
      {sub && <span style={{ fontFamily: 'ui-monospace, monospace', fontSize: 9, color: WF.inkSoft }}>{sub}</span>}
    </div>
  );
}

// Simple arrow in SVG space — from (x1,y1) to (x2,y2)
function Arrow({ x1, y1, x2, y2, curve = 0, dashed, label, labelOffset = 0 }) {
  // curve: positive bends right/down, negative left/up
  const mx = (x1 + x2) / 2 + (curve ? 0 : 0);
  const my = (y1 + y2) / 2;
  const cx = mx + curve;
  const cy = my;
  const d = curve ? `M ${x1} ${y1} Q ${cx} ${cy} ${x2} ${y2}` : `M ${x1} ${y1} L ${x2} ${y2}`;
  return (
    <g>
      <path d={d} fill="none" stroke={WF.ink} strokeWidth="1"
        strokeDasharray={dashed ? '4 3' : 'none'}
        markerEnd="url(#arrowhead)"/>
      {label && (
        <text x={cx} y={cy + labelOffset} textAnchor="middle"
          fontFamily={WF.hand} fontSize="10" fill={WF.inkSoft}>{label}</text>
      )}
    </g>
  );
}

function FlowDiagram() {
  // Layout columns (left -> right) & rows
  // Canvas size: 1400 x 700
  const W = 1500, H = 760;

  const nodes = [
    // Column 1 — entry
    { x: 20, y: 80, label: '스플래시', sub: 'Splash' },
    { x: 20, y: 170, label: '온보딩', sub: '3 pages' },
    { x: 20, y: 260, label: '회원가입', sub: 'Sign up / in' },
    { x: 20, y: 350, label: '추천인 코드', sub: 'Referral (opt)' },

    // Column 2 — setup
    { x: 200, y: 260, label: '사주 입력', sub: '생년월일 · 시간 · 성별', accent: true },
    { x: 200, y: 350, label: '분석 중…', sub: 'loading' },

    // Column 3 — hub
    { x: 400, y: 260, w: 140, h: 64, label: '홈 대시보드', sub: 'A / B / C 3 variants', accent: true },

    // Column 4 — 4 branches from home
    { x: 620, y: 50, label: '오늘의 사주', sub: 'Today' },
    { x: 620, y: 130, label: '6개월 운세', sub: 'Premium partial', locked: true },
    { x: 620, y: 210, label: '성향 결과', sub: 'Personality' },
    { x: 620, y: 290, label: '학습 목록', sub: 'Learn' },
    { x: 620, y: 370, label: '모의투자', sub: 'Mock invest' },
    { x: 620, y: 450, label: '친구 추천', sub: 'Refer' },
    { x: 620, y: 530, label: '마이페이지', sub: 'Profile' },

    // Column 5 — details
    { x: 820, y: 130, label: '6개월 리포트', sub: '월별 흐름', locked: true },
    { x: 820, y: 210, label: '추천 콘텐츠', sub: 'matched to type' },
    { x: 820, y: 290, label: '콘텐츠 상세', sub: '미리보기 + 유도' },
    { x: 820, y: 370, label: '종목 / ETF', sub: 'pick' },
    { x: 820, y: 450, label: '쿠폰함', sub: 'wallet' },
    { x: 820, y: 530, label: '구독 관리', sub: 'settings' },

    // Column 6 — deeper
    { x: 1020, y: 370, label: '매매 (매수/매도)', sub: 'trade' },
    { x: 1020, y: 290, label: '깊은 리포트', sub: 'Paywall', locked: true, accent: true },

    // Column 7 — portfolio + conversion
    { x: 1220, y: 370, label: '포트폴리오', sub: 'returns', w: 130 },
    { x: 1220, y: 290, w: 140, label: '구독 / 결제', sub: 'Paywall screen', accent: true },
  ];

  return (
    <div style={{
      position: 'relative', width: W, height: H, margin: '0 auto',
      background: WF.paper,
    }}>
      {/* Arrows */}
      <svg width={W} height={H} style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
        <defs>
          <marker id="arrowhead" viewBox="0 0 10 10" refX="8" refY="5"
            markerWidth="8" markerHeight="8" orient="auto">
            <path d="M0 0 L9 5 L0 10 z" fill={WF.ink}/>
          </marker>
        </defs>

        {/* Linear entry flow */}
        <Arrow x1={80} y1={122} x2={80} y2={170}/>
        <Arrow x1={80} y1={212} x2={80} y2={260}/>
        <Arrow x1={80} y1={302} x2={80} y2={350}/>
        <Arrow x1={140} y1={290} x2={200} y2={290} label="→ 사주 입력" labelOffset={-6}/>
        <Arrow x1={140} y1={377} x2={200} y2={370} dashed label="skip" labelOffset={14}/>
        <Arrow x1={260} y1={320} x2={260} y2={350}/>
        <Arrow x1={320} y1={377} x2={400} y2={290} label="분석 완료"/>

        {/* Hub -> branches */}
        {[77, 157, 237, 317, 397, 477, 557].map((y, i) => (
          <Arrow key={i} x1={540} y1={292} x2={620} y2={y} curve={40}/>
        ))}

        {/* Branch deeper */}
        <Arrow x1={740} y1={157} x2={820} y2={157}/>
        <Arrow x1={740} y1={237} x2={820} y2={237}/>
        <Arrow x1={740} y1={317} x2={820} y2={317}/>
        <Arrow x1={740} y1={397} x2={820} y2={397}/>
        <Arrow x1={740} y1={477} x2={820} y2={477}/>
        <Arrow x1={740} y1={557} x2={820} y2={557}/>

        {/* Deeper still */}
        <Arrow x1={940} y1={397} x2={1020} y2={397}/>
        <Arrow x1={1140} y1={397} x2={1220} y2={397}/>

        {/* Paywall convergence — dashed lines from locked nodes */}
        <Arrow x1={940} y1={157} x2={1020} y2={315} curve={30} dashed label="🔒 유도"/>
        <Arrow x1={940} y1={317} x2={1020} y2={310} dashed/>
        <Arrow x1={1140} y1={317} x2={1220} y2={317} dashed/>
        <Arrow x1={1080} y1={330} x2={1220} y2={330} dashed label="결제 유도" labelOffset={14}/>
      </svg>

      {/* Nodes */}
      {nodes.map((n, i) => <FlowNode key={i} {...n}/>)}

      {/* Legend */}
      <div style={{
        position: 'absolute', right: 20, top: 20, padding: 10,
        border: `1px solid ${WF.ink}`, background: WF.paper,
        display: 'flex', flexDirection: 'column', gap: 6,
      }}>
        <WFText size={11} bold>범례 · Legend</WFText>
        <WFRow>
          <div style={{ width: 20, height: 10, border: `2px solid ${WF.accent}` }}/>
          <WFText size={10} color={WF.inkSoft}>핵심 화면</WFText>
        </WFRow>
        <WFRow>
          <svg width="20" height="10" viewBox="0 0 22 22" fill="none" stroke={WF.lock} strokeWidth="2">
            <rect x="4.5" y="10" width="13" height="9" rx="1"/>
            <path d="M7 10V7a4 4 0 018 0v3"/>
          </svg>
          <WFText size={10} color={WF.inkSoft}>유료 잠금</WFText>
        </WFRow>
        <WFRow>
          <svg width="20" height="8"><path d="M0 4 L20 4" stroke={WF.ink} strokeDasharray="4 3"/></svg>
          <WFText size={10} color={WF.inkSoft}>선택 / 결제 유도</WFText>
        </WFRow>
      </div>

      {/* Title */}
      <div style={{ position: 'absolute', left: 20, top: 20 }}>
        <WFText size={18} bold>End-to-end 사용자 흐름</WFText>
        <div/>
        <WFText size={11} color={WF.inkSoft} italic>
          설치 → 사주 입력 → 홈 → 콘텐츠/모의투자 → 추천/쿠폰 → 구독 전환
        </WFText>
      </div>
    </div>
  );
}

Object.assign(window, { FlowDiagram });
