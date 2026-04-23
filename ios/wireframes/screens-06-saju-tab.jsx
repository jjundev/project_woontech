// 사주 탭 — 내 사주 상세 + 사주 학습
// Tab index 2 (사주)

// ───────── 1. 사주 탭 홈 ─────────
function ScrSajuTabHome() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '14px 16px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <WText size={15} weight={700}>사주</WText>
        <div style={{ width: 20, height: 20, border: `1px solid ${WF.line2}`, borderRadius: 10 }}/>
      </div>

      <div style={{ padding: '8px 16px 80px', flex: 1, overflow: 'auto' }}>
        {/* 내 원국 요약 카드 */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <WText size={11} color={WF.muted}>내 사주 원국</WText>
            <WText size={10} color={WF.muted}>전체 보기 ›</WText>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 6, marginTop: 10 }}>
            {[['時','庚','申'],['日','丙','午'],['月','辛','卯'],['年','庚','午']].map(([p,g,z]) => (
              <div key={p} style={{ textAlign: 'center' }}>
                <WText size={9} color={WF.muted}>{p}</WText>
                <WBox style={{ height: 36, marginTop: 4, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 4, background: p==='日' ? WF.gray : '#fff' }}>
                  <WText size={14} weight={700}>{g}</WText>
                </WBox>
                <WBox style={{ height: 36, marginTop: 3, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 4 }}>
                  <WText size={14} weight={700}>{z}</WText>
                </WBox>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 10, padding: 8, background: WF.gray, borderRadius: 5 }}>
            <WText size={10}>일간 <b>丙火</b> · 양의 불 — 따뜻함, 표현력, 리더십</WText>
          </div>
        </WCard>

        {/* 섹션 1 — 내 사주 자세히 */}
        <div style={{ marginTop: 16, marginBottom: 8 }}>
          <WText size={12} weight={700}>내 사주 자세히</WText>
        </div>
        {[
          { t: '오행 분포', s: '火 3 · 金 2 · 木 1 · 水 0 · 土 2', badge: '부족: 水' },
          { t: '십성 분석', s: '비견·식신·정재 강함', badge: null },
          { t: '대운 · 세운', s: '현재 丁巳 대운 (32~41)', badge: '전환기' },
          { t: '합충형파', s: '일지-시지 合, 월지 沖', badge: null },
          { t: '용신 · 희신', s: '水 용신, 金 희신', badge: null },
          // 근거 보기 진입점은 아래 렌더에서 추가
        ].map(x => (
          <WCard key={x.t} style={{ padding: 14, marginBottom: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <WText size={12} weight={600}>{x.t}</WText>
                  {x.badge && (
                    <div style={{ padding: '1px 6px', border: `1px solid ${WF.line2}`, borderRadius: 8 }}>
                      <WText size={8} color={WF.muted}>{x.badge}</WText>
                    </div>
                  )}
                </div>
                <div style={{ marginTop: 3 }}>
                  <WText size={10} color={WF.muted}>{x.s}</WText>
                </div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 3 }}>
                <WText size={11} color={WF.muted}>›</WText>
                <WText size={8} color={WF.muted} style={{ textDecoration: 'underline' }}>근거 보기</WText>
              </div>
            </div>
          </WCard>
        ))}

        {/* 섹션 2 — 사주 공부하기 */}
        <div style={{ marginTop: 18, marginBottom: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <WText size={12} weight={700}>사주 공부하기</WText>
            <div style={{ padding: '2px 7px', border: `1px solid ${WF.line2}`, borderRadius: 8, background: WF.gray }}>
              <WText size={9} weight={700}>🔥 연속 3일</WText>
            </div>
          </div>
          <WText size={10} color={WF.muted}>전체 ›</WText>
        </div>

        {/* 오늘의 한 가지 */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <WPlaceholder w={50} h={50} label="图" />
            <div style={{ flex: 1 }}>
              <WText size={9} color={WF.muted}>오늘의 한 가지</WText>
              <div style={{ marginTop: 2 }}>
                <WText size={12} weight={700}>십성이란 무엇인가?</WText>
              </div>
              <div style={{ marginTop: 2 }}>
                <WText size={9} color={WF.muted}>3분 · 초급</WText>
              </div>
            </div>
          </div>
        </WCard>

        {/* 학습 경로 */}
        <div style={{ marginTop: 10, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {[
            { t: '입문', s: '7강', dot: 1 },
            { t: '오행', s: '5강', dot: 0.6 },
            { t: '십성', s: '8강', dot: 0.3 },
            { t: '대운', s: '6강', dot: 0 },
          ].map(x => (
            <WCard key={x.t} style={{ padding: 12 }}>
              <WText size={12} weight={700}>{x.t}</WText>
              <div style={{ marginTop: 4 }}>
                <WText size={9} color={WF.muted}>{x.s}</WText>
              </div>
              <div style={{ height: 3, background: WF.gray2, borderRadius: 2, marginTop: 8 }}>
                <div style={{ width: `${x.dot*100}%`, height: '100%', background: WF.ink, borderRadius: 2 }}/>
              </div>
            </WCard>
          ))}
        </div>

        {/* 용어 사전 */}
        <WCard style={{ padding: 14, marginTop: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 32, height: 32, border: `1px solid ${WF.line2}`, borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <WText size={14} weight={700}>A</WText>
            </div>
            <div style={{ flex: 1 }}>
              <WText size={12} weight={600}>용어 사전</WText>
              <div style={{ marginTop: 2 }}>
                <WText size={10} color={WF.muted}>명리학 용어 120개</WText>
              </div>
            </div>
            <WText size={11} color={WF.muted}>›</WText>
          </div>
        </WCard>
        <WDisclaimer />
      </div>
      <WTabBar active={2} />
    </div>
  );
}

// ───────── 2. 오행 분포 상세 ─────────
function ScrSajuElements() {
  const els = [
    { k: '火', ko: '불', n: 3, max: 4, note: '왕성' },
    { k: '木', ko: '나무', n: 1, max: 4, note: '보통' },
    { k: '土', ko: '흙', n: 2, max: 4, note: '보통' },
    { k: '金', ko: '쇠', n: 2, max: 4, note: '보통' },
    { k: '水', ko: '물', n: 0, max: 4, note: '부족 ⚠' },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="오행 분포" back />
      <div style={{ padding: 16, overflow: 'auto', flex: 1 }}>
        <WCard style={{ padding: 14 }}>
          <WText size={11} color={WF.muted}>오행 요약</WText>
          <div style={{ marginTop: 6 }}>
            <WText size={13} weight={700}>火가 많고 水가 전혀 없는 사주</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={10} color={WF.muted}>열정·추진력이 강하나 침착함·저축의 기운이 부족합니다.</WText>
          </div>
        </WCard>

        {/* Bar chart */}
        <WCard style={{ padding: 14, marginTop: 10 }}>
          <WSectionLabel>5행 분포</WSectionLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 10 }}>
            {els.map(e => (
              <div key={e.k}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <div>
                    <WText size={13} weight={700}>{e.k}</WText>
                    <WText size={10} color={WF.muted}>  {e.ko}</WText>
                  </div>
                  <WText size={10} color={WF.muted}>{e.note} · {e.n}/8</WText>
                </div>
                <div style={{ height: 8, background: WF.gray2, borderRadius: 4, marginTop: 4, overflow: 'hidden' }}>
                  <div style={{ width: `${(e.n/e.max)*100}%`, height: '100%', background: e.n === 0 ? WF.line2 : WF.ink }}/>
                </div>
              </div>
            ))}
          </div>
        </WCard>

        {/* 보완 가이드 */}
        <WDisclaimer />
        <WCard style={{ padding: 14, marginTop: 10 }}>
          <WSectionLabel>부족한 水를 보완하려면</WSectionLabel>
          <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 8 }}>
            {['방향 — 북쪽이 유리', '색상 — 검정·파랑 계열', '시간 — 저녁 23시 ~ 새벽 1시', '행동 — 계획·독서·수영'].map(t => (
              <div key={t} style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: WF.ink, marginTop: 6 }}/>
                <WText size={11}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>
      </div>
    </div>
  );
}

// ───────── 2-B. 십성 분석 상세 ─────────
function ScrSajuTenGods() {
  const groups = [
    { name: '비겁', han: '比劫', meaning: '주체성·동료', items: ['비견', '겁재'], counts: [1, 0], total: 1 },
    { name: '식상', han: '食傷', meaning: '표현·생산', items: ['식신', '상관'], counts: [0, 0], total: 0, absent: true },
    { name: '재성', han: '財星', meaning: '재물·실리', items: ['편재', '정재'], counts: [0, 2], total: 2, core: true },
    { name: '관성', han: '官星', meaning: '명예·규율', items: ['편관', '정관'], counts: [1, 0], total: 1 },
    { name: '인성', han: '印星', meaning: '학문·수용성', items: ['편인', '정인'], counts: [0, 1], total: 1 },
  ];
  const top3 = [
    { name: '정재', han: '正財', count: 2, meaning: '안정 수입·꼼꼼한 관리', invest: '장기 보유·분산 선호' },
    { name: '비견', han: '比肩', count: 1, meaning: '독립심·자기 원칙', invest: '독자적 판단, 군중 추종 회피' },
    { name: '정인', han: '正印', count: 1, meaning: '학습력·신중함', invest: '데이터·근거 기반 매매 선호' },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="십성 분석" back />
      <div style={{ padding: 16, overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>

        {/* 섹션 1 — 요약 */}
        <WCard style={{ padding: 14 }}>
          <WText size={11} color={WF.muted}>십성 요약</WText>
          <div style={{ marginTop: 6 }}>
            <WText size={13} weight={700}>정재가 중심인 사주</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={10} color={WF.muted}>꼼꼼하고 안정을 추구하는 기질. 재물에 대한 감각이 예민하며 충동적 결정보다 검증된 패턴을 선호합니다.</WText>
          </div>
        </WCard>

        {/* 섹션 2 — 5그룹 분포 차트 */}
        <WCard style={{ padding: 14 }}>
          <WSectionLabel>5그룹 분포</WSectionLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 10 }}>
            {groups.map(g => (
              <div key={g.name}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <WText size={12} weight={700}>{g.name}</WText>
                    <span style={{ fontFamily: 'serif', fontSize: 9, color: WF.muted }}>{g.han}</span>
                    {g.core && <div style={{ padding: '1px 5px', borderRadius: 4, background: WF.ink }}>
                      <WText size={8} color="#fff">핵심</WText>
                    </div>}
                  </div>
                  <WText size={10} color={g.absent ? '#c44' : WF.muted}>
                    {g.absent ? '부재 ⚠' : `${g.total}/8`}
                  </WText>
                </div>
                <div style={{ height: 7, background: WF.gray2, borderRadius: 4, marginTop: 5, overflow: 'hidden' }}>
                  <div style={{ width: `${(g.total / 3) * 100}%`, height: '100%', background: g.absent ? WF.line2 : WF.ink, borderRadius: 4 }}/>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 3 }}>
                  <WText size={9} color={WF.muted}>{g.meaning}</WText>
                  <WText size={9} color={WF.muted}>
                    {g.items.map((it, i) => g.counts[i] > 0 ? it : null).filter(Boolean).join(' · ') || '—'}
                  </WText>
                </div>
              </div>
            ))}
          </div>
        </WCard>

        {/* 섹션 3 — 핵심 십성 Top 3 */}
        <WCard style={{ padding: 14 }}>
          <WSectionLabel>나의 핵심 십성</WSectionLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 10 }}>
            {top3.map((t, i) => (
              <div key={t.name} style={{ padding: 12, borderRadius: 8, border: `1px solid ${i === 0 ? WF.line2 : WF.line3}`, background: i === 0 ? WF.gray : '#fff' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 5 }}>
                    <WText size={13} weight={700}>{t.name}</WText>
                    <span style={{ fontFamily: 'serif', fontSize: 9, color: WF.muted }}>{t.han}</span>
                  </div>
                  <WText size={9} color={WF.muted}>×{t.count}</WText>
                </div>
                <div style={{ marginTop: 3 }}>
                  <WText size={10} color={WF.muted}>{t.meaning}</WText>
                </div>
                <div style={{ marginTop: 7, padding: '6px 9px', background: WF.gray2, borderRadius: 5, display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontSize: 11 }}>💹</span>
                  <WText size={9} color={WF.muted}>{t.invest}</WText>
                </div>
              </div>
            ))}
          </div>
        </WCard>

        {/* 섹션 4 — 부재 십성 주의 */}
        <WCard style={{ padding: 14, borderColor: '#c44' }}>
          <WSectionLabel style={{ color: '#c44' }}>주의 — 부재 십성</WSectionLabel>
          <div style={{ marginTop: 6 }}>
            <WText size={12} weight={700}>식상(식신·상관) 부재</WText>
          </div>
          <div style={{ marginTop: 5, padding: '8px 10px', background: '#fff5f5', borderRadius: 6 }}>
            <WText size={10} style={{ lineHeight: 1.6 }}>창의적 직관 매매보다 검증된 패턴 매매가 내 성향에 맞아요</WText>
          </div>
        </WCard>

        {/* 섹션 5 — 학습 유도 */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 22 }}>📚</span>
            <div style={{ flex: 1 }}>
              <WText size={12} weight={600}>십성이란 무엇인가요?</WText>
              <div style={{ marginTop: 2 }}>
                <WText size={9} color={WF.muted}>3분 레슨 · 초급</WText>
              </div>
            </div>
            <WText size={12} color={WF.muted}>›</WText>
          </div>
        </WCard>

        <WDisclaimer />
      </div>
    </div>
  );
}

// ───────── 3. 사주 공부 (레슨 리스트) ─────────
function ScrSajuLearn() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="사주 공부" back right={<WText size={10} color={WF.muted}>검색</WText>} />
      <div style={{ padding: '0 16px 80px', overflow: 'auto', flex: 1 }}>
        {/* Pills */}
        <div style={{ display: 'flex', gap: 6, padding: '12px 0 14px', overflow: 'auto' }}>
          {['전체', '입문', '오행', '십성', '대운', '합충'].map((t, i) => (
            <div key={t} style={{ padding: '5px 12px', borderRadius: 12, border: `1px solid ${i===0 ? WF.ink : WF.line2}`, background: i===0 ? WF.ink : '#fff', flexShrink: 0 }}>
              <WText size={10} weight={i===0 ? 700 : 400} color={i===0 ? '#fff' : WF.ink}>{t}</WText>
            </div>
          ))}
        </div>

        {/* Progress banner */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <WText size={11} color={WF.muted}>이번 주 학습</WText>
                <div style={{ padding: '2px 7px', border: `1px solid ${WF.line2}`, borderRadius: 8, background: WF.gray }}>
                  <WText size={9} weight={700}>🔥 연속 3일</WText>
                </div>
              </div>
              <div style={{ marginTop: 2 }}>
                <WText size={14} weight={700}>3 / 5강 완료</WText>
              </div>
            </div>
            <WPlaceholder w={44} h={44} label="%"/>
          </div>
          <div style={{ height: 4, background: WF.gray2, borderRadius: 2, marginTop: 10, overflow: 'hidden' }}>
            <div style={{ width: '60%', height: '100%', background: WF.ink }}/>
          </div>
        </WCard>

        {/* 코스: 입문 */}
        <div style={{ marginTop: 18, marginBottom: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <WText size={12} weight={700}>입문 코스</WText>
          <WText size={10} color={WF.muted}>7강 · 평균 3분</WText>
        </div>
        {[
          { n: 1, t: '사주란 무엇인가', d: '3분', done: true },
          { n: 2, t: '천간과 지지', d: '4분', done: true },
          { n: 3, t: '오행의 의미', d: '3분', done: true },
          { n: 4, t: '일간이 나를 나타낸다', d: '5분', done: false, cur: true },
          { n: 5, t: '지장간이란', d: '4분', done: false, locked: true },
          { n: 6, t: '절기와 월주', d: '4분', done: false, locked: true },
          { n: 7, t: '내 사주를 읽는 법', d: '6분', done: false, locked: true },
        ].map(x => (
          <WCard key={x.n} style={{ padding: 12, marginBottom: 6 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 28, height: 28, borderRadius: 14, border: `1.3px solid ${x.cur ? WF.ink : WF.line2}`, background: x.done ? WF.ink : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {x.done
                  ? <svg width="12" height="10" viewBox="0 0 12 10"><path d="M1 5 L4.5 8.5 L11 1.5" stroke="#fff" strokeWidth="1.6" fill="none"/></svg>
                  : <WText size={10} weight={600} color={x.locked ? WF.muted : WF.ink}>{x.n}</WText>
                }
              </div>
              <div style={{ flex: 1 }}>
                <WText size={12} weight={x.cur ? 700 : 500} color={x.locked ? WF.muted : WF.ink}>{x.t}</WText>
                <div style={{ marginTop: 2, display: 'flex', gap: 6 }}>
                  <WText size={9} color={WF.muted}>{x.d}</WText>
                  {x.cur && <><WText size={9} color={WF.muted}>·</WText><WText size={9} weight={600}>이어보기</WText></>}
                </div>
              </div>
              {x.locked
                ? <svg width="10" height="12" viewBox="0 0 10 12"><rect x="1" y="5" width="8" height="6" stroke={WF.muted} fill="none" strokeWidth="1"/><path d="M2.5 5V3.2a2.5 2.5 0 0 1 5 0V5" stroke={WF.muted} fill="none" strokeWidth="1"/></svg>
                : <WText size={11} color={WF.muted}>›</WText>
              }
            </div>
          </WCard>
        ))}

        {/* 추천 아티클 */}
        <div style={{ marginTop: 18, marginBottom: 8 }}>
          <WText size={12} weight={700}>이번 주 읽을거리</WText>
        </div>
        {[
          { t: '내 사주 일간이 丙(병)이면 어떤 사람?', s: '읽기 · 4분' },
          { t: '水가 없는 사주, 투자에 미치는 영향', s: '읽기 · 5분' },
        ].map(x => (
          <WCard key={x.t} style={{ padding: 12, marginBottom: 6 }}>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <WPlaceholder w={44} h={44} label="img"/>
              <div style={{ flex: 1 }}>
                <WText size={11} weight={600}>{x.t}</WText>
                <div style={{ marginTop: 2 }}>
                  <WText size={9} color={WF.muted}>{x.s}</WText>
                </div>
              </div>
            </div>
          </WCard>
        ))}
      </div>
    </div>
  );
}

// ───────── 4. 레슨 상세 (학습 경험) ─────────
function ScrSajuLesson() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="3강 · 오행의 의미" back right={<WText size={10} color={WF.muted}>3/7</WText>}/>
      {/* progress bar */}
      <div style={{ height: 3, background: WF.gray }}>
        <div style={{ width: '42%', height: '100%', background: WF.ink }}/>
      </div>

      <div style={{ padding: 18, overflow: 'auto', flex: 1 }}>
        <WText size={9} color={WF.muted}>기본 개념</WText>
        <div style={{ marginTop: 6 }}>
          <WText size={17} weight={700}>오행이란?</WText>
        </div>

        <WBox style={{ padding: 16, marginTop: 14, borderRadius: 8, background: WF.gray }}>
          <WText size={11}>오행은 木·火·土·金·水의 다섯 요소로, 세상 모든 것을 다섯 기운의 흐름으로 설명하는 명리학의 기본 틀입니다.</WText>
        </WBox>

        {/* 다이어그램 placeholder */}
        <div style={{ marginTop: 14, textAlign: 'center' }}>
          <WPlaceholder w={200} h={140} label="상생·상극 다이어그램" style={{ margin: '0 auto' }}/>
        </div>

        {/* Inline quiz */}
        <WCard style={{ padding: 14, marginTop: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ padding: '2px 6px', border: `1px solid ${WF.ink}`, borderRadius: 3 }}>
              <WText size={8} weight={700}>Q</WText>
            </div>
            <WText size={10} color={WF.muted}>간단 체크</WText>
          </div>
          <div style={{ marginTop: 8 }}>
            <WText size={12} weight={600}>水를 생(生)하는 오행은?</WText>
          </div>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {['木', '火', '金', '土'].map((t, i) => (
              <WBox key={t} style={{ padding: '10px 12px', borderRadius: 6, borderColor: i === 2 ? WF.ink : WF.line2, background: i === 2 ? WF.gray : '#fff' }}>
                <WText size={11} weight={i === 2 ? 700 : 400}>{t}</WText>
              </WBox>
            ))}
          </div>
        </WCard>
      </div>

      <div style={{ padding: 16, borderTop: `1px solid ${WF.line3}`, background: '#fff' }}>
        <WButton primary>다음 강의</WButton>
      </div>
    </div>
  );
}

Object.assign(window, { ScrSajuTabHome, ScrSajuElements, ScrSajuTenGods, ScrSajuLearn, ScrSajuLesson });
