// Home Dashboard v6 — Full redesign per 2026.04.23 spec
// Sections: 0 Header · 1 Hero · 2 Quick Actions · 3 Insights · 4 Yesterday · 5 Growth · 6 Portfolio · 7 Weekly · 8 Share · 9 PRO · 10 Disclaimer

// ── Section 0: Header ──────────────────────────────────────────────────────
function V6Header() {
  return (
    <div style={{ padding: '10px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: `1px solid ${WF.line3}` }}>
      <WText size={16} weight={700} style={{ letterSpacing: -0.5 }}>운테크</WText>
      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        {/* 알림 벨 */}
        <div style={{ position: 'relative' }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <path d="M9 2a5 5 0 0 0-5 5v3l-1.5 2h13L14 10V7a5 5 0 0 0-5-5z" stroke={WF.ink} strokeWidth="1.2"/>
            <path d="M7.5 14.5a1.5 1.5 0 0 0 3 0" stroke={WF.ink} strokeWidth="1.2"/>
          </svg>
          <div style={{ position: 'absolute', top: -3, right: -3, width: 8, height: 8, borderRadius: 4, background: WF.note, border: `1.5px solid ${WF.bg}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <WText size={5} color="#fff" weight={700}>2</WText>
          </div>
        </div>
        {/* 프로필 아바타 */}
        <div style={{ width: 26, height: 26, borderRadius: 13, border: `1px solid ${WF.line2}`, background: WF.gray, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <WText size={10} weight={700} color={WF.muted}>길</WText>
        </div>
      </div>
    </div>
  );
}

// ── Context badge ──────────────────────────────────────────────────────────
function V6Badge({ label, color }) {
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', padding: '2px 7px', border: `1px solid ${color || WF.line2}`, borderRadius: 10, background: WF.gray }}>
      <WText size={8} color={color || WF.muted} weight={600}>{label}</WText>
    </div>
  );
}

// ── Section 1: Hero (경량화) ───────────────────────────────────────────────
function V6Hero() {
  return (
    <div style={{ padding: '10px 16px 0' }}>
      <WText size={10} color={WF.muted}>2026.04.23 목요일</WText>
      <div style={{ marginTop: 2 }}>
        <WText size={14} weight={700}>길동님, 오늘의 투자 태도예요</WText>
      </div>
      <WCard style={{ marginTop: 10, padding: '14px 14px 10px' }}>
        <V6Badge label="투자 관점" />
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 10 }}>
          {/* 원형 지수 */}
          <div style={{ flexShrink: 0, textAlign: 'center' }}>
            <div style={{ width: 52, height: 52, borderRadius: 26, border: `2px solid ${WF.ink}`, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <WText size={18} weight={700}>72</WText>
            </div>
            <WText size={8} color={WF.muted} style={{ display: 'block', marginTop: 3 }}>/100</WText>
          </div>
          <div style={{ flex: 1 }}>
            <WText size={11} weight={600} style={{ lineHeight: 1.5 }}>"공격보다 관찰이 내 성향에 맞아요"</WText>
          </div>
        </div>
        <div style={{ marginTop: 10, textAlign: 'right' }}>
          <WText size={10} color={WF.muted}>상세 보기 ›</WText>
        </div>
      </WCard>
    </div>
  );
}

// ── Section 2: Quick Actions ───────────────────────────────────────────────
const V6_ACTIONS = [
  { icon: '💭', label: '체크인', done: false },
  { icon: '✓',  label: '실천',   done: true  },
  { icon: '💹', label: '모의',   done: false },
  { icon: '📝', label: '복기',   done: false },
];

function V6QuickActions() {
  return (
    <div style={{ padding: '12px 16px 0' }}>
      <WText size={10} weight={700} color={WF.muted} style={{ letterSpacing: 0.3 }}>오늘 할 일</WText>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 6, marginTop: 8 }}>
        {V6_ACTIONS.map(a => (
          <div key={a.label} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5 }}>
            <div style={{
              width: 44, height: 44, borderRadius: 22,
              border: `1.5px solid ${a.done ? WF.ink : WF.line2}`,
              background: a.done ? WF.ink : '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative',
            }}>
              <WText size={16} color={a.done ? '#fff' : WF.ink}>{a.icon}</WText>
              {a.done && (
                <div style={{ position: 'absolute', bottom: -1, right: -1, width: 14, height: 14, borderRadius: 7, background: WF.ink, border: `1.5px solid #fff`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <WText size={8} color="#fff" weight={700}>✓</WText>
                </div>
              )}
            </div>
            <WText size={9} color={a.done ? WF.ink : WF.muted} weight={a.done ? 600 : 400}>{a.label}</WText>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Section 3: 오늘의 인사이트 (가로 스크롤 3카드) ─────────────────────────
const V6_INSIGHT_CARDS = [
  {
    badge: '주의', badgeColor: '#c44',
    icon: '⚠',
    title: '추격매수',
    desc: '충동 매매 주의\n오후는 관망이 맞아요',
    label: '오늘의 금기',
    borderColor: '#c44',
  },
  {
    badge: '하루 전반', badgeColor: WF.muted,
    icon: '🤝',
    title: '협상·유대',
    desc: '애정운 82',
    label: '오늘의 일진',
    borderColor: WF.line2,
  },
  {
    badge: '액션', badgeColor: '#3a7',
    icon: '✓',
    title: '水 기운 보완',
    desc: '분산 배분\n점검해보기',
    label: '오늘의 실천',
    borderColor: '#3a7',
  },
];

function V6Insights() {
  return (
    <div style={{ padding: '12px 0 0' }}>
      <div style={{ padding: '0 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <WText size={10} weight={700} color={WF.muted} style={{ letterSpacing: 0.3 }}>오늘의 인사이트</WText>
        <WText size={9} color={WF.muted}>{"\n"}</WText>
      </div>
      <div style={{ marginTop: 8, display: 'flex', gap: 8, paddingLeft: 16, paddingRight: 16, overflowX: 'auto', paddingBottom: 4 }}>
        {V6_INSIGHT_CARDS.map(c => (
          <div key={c.label} style={{ flexShrink: 0, width: 110, border: `1px solid ${c.borderColor}`, borderRadius: 8, padding: 10, background: '#fff', boxSizing: 'border-box' }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', padding: '1px 6px', border: `1px solid ${c.badgeColor}`, borderRadius: 8 }}>
              <WText size={8} color={c.badgeColor} weight={600}>{c.badge}</WText>
            </div>
            <div style={{ marginTop: 8, fontSize: 18, lineHeight: 1 }}>{c.icon}</div>
            <div style={{ marginTop: 4 }}>
              <WText size={11} weight={700}>{c.title}</WText>
            </div>
            <div style={{ marginTop: 4 }}>
              <WText size={9} color={WF.muted} style={{ whiteSpace: 'pre-line', lineHeight: 1.5 }}>{c.desc}</WText>
            </div>
            <div style={{ marginTop: 8 }}>
              <WText size={8} color={WF.muted}>{c.label}</WText>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── ABOVE-FOLD SCREEN ──────────────────────────────────────────────────────
function ScrHomeV6Top() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <V6Header />
      <div style={{ flex: 1, overflow: 'auto', paddingBottom: 68 }}>
        <V6Hero />
        <V6Insights />
        {/* scroll hint */}
        <div style={{ padding: '10px 16px', textAlign: 'center' }}>
          <WText size={8} color={WF.line3}>↓ 스크롤하여 어제의 기록 · 성장 트래커 보기</WText>
        </div>
      </div>
      <WTabBar active={0} />
    </div>
  );
}

// ── Section 7: 이번 주 흐름 (full spec) ───────────────────────────────────

const V6_EVENTS = [
  {
    type: 'daewoon',
    icon: '🔄',
    title: '대운 전환',
    hanja: '大運',
    dday: 'D-89',
    ddayDate: '2026.05.12',
    impact: 'positive',
    oneLiner: '새로운 10년 주기 — 병진 대운 진입',
    investContext: '안정형 → 도전형 전환 신호 · 새 자산군 탐색 참고 시기',
    badge: '중요',
    timeGroup: '3개월 이내',
  },
  {
    type: 'jeolgi',
    icon: '🌿',
    title: '곡우(穀雨)',
    hanja: '穀雨',
    dday: 'D-2',
    ddayDate: '4/25 토',
    impact: 'neutral',
    oneLiner: '봄비의 절기 — 水 부족 해소 참고 시기',
    investContext: '월간 포지션 점검 참고 시기',
    timeGroup: '이번 주',
  },
  {
    type: 'hapchung',
    icon: '⚠',
    title: '월지충 · 卯↔酉',
    hanja: null,
    dday: 'D-4',
    ddayDate: '4/27 월',
    impact: 'negative',
    oneLiner: '직업궁 충돌 — 부서 이동·갈등 주의',
    investContext: '충동적 결정 주의 · 관망 참고',
    timeGroup: '이번 주',
  },
  {
    type: 'special',
    icon: '⭐',
    title: '경신일 귀환',
    hanja: null,
    dday: 'D-18',
    ddayDate: '5/11 월',
    impact: 'neutral',
    oneLiner: '내 일주와 같은 날 — 자기 성찰의 기회',
    investContext: '복기·성향 점검에 적합한 하루',
    timeGroup: '이번 달',
  },
];

// Time group divider
function V6TimeGroup({ label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '10px 0 6px' }}>
      <WText size={9} weight={700} color={WF.muted}>{label}</WText>
      <div style={{ flex: 1, height: 1, background: WF.line3 }}/>
    </div>
  );
}

// Single event card
function V6EventCard({ ev }) {
  const isNeg = ev.impact === 'negative';
  const isPos = ev.impact === 'positive' && ev.badge;
  return (
    <div style={{
      border: `1px solid ${isNeg ? WF.note : WF.line2}`,
      borderRadius: 8, background: '#fff', overflow: 'hidden',
      display: 'flex',
    }}>
      {/* left accent bar for negative */}
      {isNeg && <div style={{ width: 3, background: WF.note, flexShrink: 0 }}/>}
      <div style={{ flex: 1, padding: '10px 10px 8px' }}>
        {/* top row */}
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 6 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <WText size={16} style={{ lineHeight: 1 }}>{ev.icon}</WText>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                <WText size={11} weight={700}>{ev.title}</WText>
                {isPos && (
                  <div style={{ padding: '1px 5px', border: `1px solid ${WF.ink}`, borderRadius: 6 }}>
                    <WText size={7} weight={700}>{ev.badge}</WText>
                  </div>
                )}
              </div>
              <WText size={9} color={WF.muted}>{ev.oneLiner}</WText>
            </div>
          </div>
          {/* D-day badge */}
          <div style={{ flexShrink: 0, padding: '2px 6px', border: `1px solid ${isNeg ? WF.note : WF.line3}`, borderRadius: 8 }}>
            <WText size={8} weight={700} color={isNeg ? WF.note : WF.muted}>{ev.dday}</WText>
          </div>
        </div>
        {/* date */}
        <div style={{ marginTop: 4 }}>
          <WText size={8} color={WF.muted}>{ev.ddayDate}</WText>
        </div>
        {/* invest context */}
        <div style={{ marginTop: 6, padding: '5px 8px', background: WF.gray, borderRadius: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <WText size={9} color={WF.muted} style={{ flex: 1, lineHeight: 1.4 }}>💹 {ev.investContext}</WText>
          <WText size={8} color={WF.muted} style={{ flexShrink: 0, marginLeft: 6 }}>알림 ›</WText>
        </div>
      </div>
    </div>
  );
}

// 홈 내 섹션 카드 (컴팩트)
function V6Weekly() {
  const groups = ['이번 주', '이번 달', '3개월 이내'];
  return (
    <div style={{ padding: '14px 16px 0' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div>
          <WText size={10} weight={700} color={WF.muted} style={{ letterSpacing: 0.3 }}>이번 주 흐름</WText>
          <div><WText size={8} color={WF.muted}>다가올 절기·대운 이벤트</WText></div>
        </div>
        <WText size={9} color={WF.muted}>캘린더 보기 ›</WText>
      </div>
      <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 0 }}>
        {groups.map(g => {
          const evs = V6_EVENTS.filter(e => e.timeGroup === g);
          if (!evs.length) return null;
          return (
            <div key={g}>
              <V6TimeGroup label={g} />
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {evs.map(ev => <V6EventCard key={ev.title} ev={ev} />)}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ── Event Detail Screen ────────────────────────────────────────────────────
function ScrWeeklyDetail() {
  const ev = V6_EVENTS[0]; // 대운 전환 상세 예시
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="이벤트 상세" back right={<WText size={10} color={WF.muted}>공유</WText>} />
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {/* 타이틀 */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <WText size={24}>{ev.icon}</WText>
            <div>
              <WText size={13} weight={700}>{ev.title}</WText>
              <div><WText size={9} color={WF.muted}>{ev.oneLiner}</WText></div>
            </div>
          </div>
          <div style={{ marginTop: 10, padding: '8px 10px', background: WF.gray, borderRadius: 5, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <WText size={10} weight={700}>{ev.ddayDate}</WText>
              <WText size={10} color={WF.muted}> — {ev.dday}</WText>
            </div>
            <div style={{ padding: '2px 8px', border: `1px solid ${WF.ink}`, borderRadius: 8 }}>
              <WText size={8} weight={700}>{ev.badge || ev.dday}</WText>
            </div>
          </div>
        </WCard>

        {/* 의미 */}
        <WCard>
          <WSectionLabel>이 이벤트가 의미하는 것</WSectionLabel>
          <WText size={10} color={WF.muted} style={{ lineHeight: 1.7 }}>
            10년 주기로 바뀌는 큰 환경 변화. 기존 정재 중심에서 편관 중심으로 이동. 긴장감 있는 결정·변화의 시기.
          </WText>
        </WCard>

        {/* 내 사주와의 관계 */}
        <WCard>
          <WSectionLabel>내 사주와의 관계</WSectionLabel>
          <div style={{ padding: '8px 10px', background: WF.gray, borderRadius: 5 }}>
            <WText size={10} weight={600}>경금 일주 × 병진 대운 = 편관</WText>
            <div style={{ marginTop: 4 }}>
              <WText size={9} color={WF.muted}>압박과 성장이 공존하는 10년</WText>
            </div>
          </div>
        </WCard>

        {/* 투자 관점 */}
        <WCard>
          <WSectionLabel>💹 투자 관점</WSectionLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginTop: 4 }}>
            {['안정형 → 도전형 전환 신호', '단, 충동적 결정 경계', '새 자산군 탐색 참고 시기'].map(t => (
              <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: WF.ink, flexShrink: 0 }}/>
                <WText size={10} color={WF.muted}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* 액션 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <WButton style={{ height: 38, fontSize: 11, borderRadius: 7 }}>🔔 D-7 푸시 알림 받기</WButton>
          <WButton style={{ height: 38, fontSize: 11, borderRadius: 7 }}>📅 캘린더에 추가</WButton>
          <WButton primary style={{ height: 38, fontSize: 11, borderRadius: 7 }}>📖 대운 학습하기 →</WButton>
        </div>
        <WDisclaimer />
      </div>
    </div>
  );
}

// ── Section 8: 공유·바이럴 훅 ─────────────────────────────────────────────
function V6ShareHook() {
  return (
    <div style={{ padding: '14px 16px 0' }}>
      <WCard style={{ padding: 12, background: WF.gray, border: `1px solid ${WF.line3}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <WText size={18}>💌</WText>
          <div style={{ flex: 1 }}>
            <WText size={11} weight={700}>내 사주 카드로 친구 초대</WText>
            <div style={{ marginTop: 2 }}>
              <WText size={9} color={WF.muted}>둘 다 PRO 1개월 무료</WText>
            </div>
          </div>
        </div>
        <div style={{ marginTop: 10, display: 'flex', gap: 6 }}>
          <WButton style={{ flex: 1, height: 32, fontSize: 10, borderRadius: 5 }}>카드 미리보기</WButton>
          <WButton primary style={{ flex: 1, height: 32, fontSize: 10, borderRadius: 5 }}>공유하기</WButton>
        </div>
      </WCard>
    </div>
  );
}

// ── Section 9: PRO 티저 ────────────────────────────────────────────────────
function V6ProTeaser() {
  return (
    <div style={{ padding: '14px 16px 0' }}>
      <WCard style={{ padding: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <svg width="14" height="18" viewBox="0 0 14 18" fill="none">
            <rect x="1" y="7" width="12" height="10" rx="2" stroke={WF.ink} strokeWidth="1.2"/>
            <path d="M3 7V5a4 4 0 0 1 8 0v2" stroke={WF.ink} strokeWidth="1.2"/>
            <circle cx="7" cy="12" r="1.2" fill={WF.ink}/>
          </svg>
          <WText size={12} weight={700}>PRO로 더 깊은 분석</WText>
        </div>
        <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 5 }}>
          {['6개월 흐름 리포트', '성향 vs 실제 행동 주간 리포트', 'AI 사주 상담사'].map(f => (
            <div key={f} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ width: 14, height: 14, borderRadius: 7, border: `1px solid ${WF.line2}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <WText size={7} color={WF.muted}>›</WText>
              </div>
              <WText size={10} color={WF.muted}>{f}</WText>
            </div>
          ))}
        </div>
        <WButton primary style={{ marginTop: 10, height: 34, fontSize: 11, borderRadius: 6 }}>7일 무료 체험 →</WButton>
      </WCard>
    </div>
  );
}

// ── BELOW-FOLD SCREEN ──────────────────────────────────────────────────────
function ScrHomeV6Scroll() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '8px 16px 6px', borderBottom: `1px solid ${WF.line3}` }}>
        <WText size={9} color={WF.muted}>↑ 위로 스크롤 — Hero · Quick Actions · 인사이트</WText>
      </div>
      <div style={{ flex: 1, overflow: 'auto', paddingBottom: 68 }}>
        <V6Weekly />
        <V6ShareHook />
        <V6ProTeaser />
        <div style={{ padding: '12px 16px 0' }}>
          <WDisclaimer />
        </div>
        <div style={{ height: 8 }}/>
      </div>
      <WTabBar active={0} />
    </div>
  );
}

Object.assign(window, {
  ScrHomeV6Top, ScrHomeV6Scroll, ScrWeeklyDetail,
  V6Header, V6Hero, V6QuickActions, V6Insights,
  V6Weekly, V6ShareHook, V6ProTeaser,
});
