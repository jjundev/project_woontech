// Home dashboard — 3 variations, Today's saju detail, 6-month fortune

// ─────────────── HOME A — card stack, vertical scroll ───────────────
function ScrHomeA() {
  return (
    <WFScreen>
      <WFStatusSpacer/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '4px 16px 12px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* greeting */}
        <WFRow>
          <div style={{ flex: 1 }}>
            <WFText size={16} bold>안녕하세요, 지민님</WFText>
            <div/>
            <WFText size={11} color={WF.inkSoft}>오늘도 좋은 하루 되세요 🌙</WFText>
          </div>
          <WFCircle size={36}/>
        </WFRow>

        {/* Today's saju card — hero */}
        <WFCard title="오늘의 사주" accent pad={12}>
          <WFRow style={{ alignItems: 'flex-start' }}>
            <WFCircle size={44}/>
            <div style={{ flex: 1 }}>
              <WFText size={14} bold>흐름을 읽기 좋은 날</WFText>
              <div/>
              <WFText size={11} color={WF.inkSoft}>
                수(水) 기운 강함 · 직관보다 분석이 잘 통해요
              </WFText>
            </div>
          </WFRow>
          <div style={{ textAlign: 'right', marginTop: 8 }}>
            <WFText size={11} color={WF.accent}>자세히 보기 ›</WFText>
          </div>
        </WFCard>

        {/* 금전운 + 성향 side-by-side */}
        <div style={{ display: 'flex', gap: 10 }}>
          <WFCard title="금전운" style={{ flex: 1 }} pad={10}>
            <WFText size={22} bold>7.5</WFText>
            <div/>
            <WFText size={10} color={WF.inkSoft}>지출 주의</WFText>
          </WFCard>
          <WFCard title="투자 성향" style={{ flex: 1 }} pad={10}>
            <WFText size={13} bold>신중한{'\n'}탐험가형</WFText>
            <div/>
            <WFText size={10} color={WF.inkSoft}>상세 ›</WFText>
          </WFCard>
        </div>

        {/* 추천 학습 */}
        <WFCard title="추천 학습" pad={10}>
          <WFRow>
            <WFPlaceholder w={52} h={40} label=""/>
            <div style={{ flex: 1 }}>
              <WFText size={12} bold>ETF 입문 · 3분</WFText>
              <div/>
              <WFText size={10} color={WF.inkSoft}>신중형에게 맞는 콘텐츠</WFText>
            </div>
            <WFBadge accent>NEW</WFBadge>
          </WFRow>
        </WFCard>

        {/* 모의투자 바로가기 */}
        <WFCard title="모의투자" pad={10}>
          <WFRow>
            <div style={{ flex: 1 }}>
              <WFText size={12}>가상 자산</WFText>
              <div/>
              <WFText size={16} bold>₩ 10,250,400</WFText>
            </div>
            <WFButton small primary>시작 ›</WFButton>
          </WFRow>
        </WFCard>

        {/* 추천/쿠폰 바 */}
        <WFRow>
          <WFCard pad={8} style={{ flex: 1 }}>
            <WFText size={10} color={WF.inkSoft}>친구 추천</WFText>
            <div/>
            <WFText size={12} bold>2 / 5명</WFText>
          </WFCard>
          <WFCard pad={8} style={{ flex: 1 }}>
            <WFText size={10} color={WF.inkSoft}>쿠폰함</WFText>
            <div/>
            <WFText size={12} bold>3장</WFText>
          </WFCard>
        </WFRow>

        {/* Premium banner */}
        <WFCard accent pad={10}>
          <WFRow>
            <div style={{ flex: 1 }}>
              <WFText size={12} bold color={WF.accent}>PREMIUM</WFText>
              <div/>
              <WFText size={11}>더 깊은 분석 잠금 해제</WFText>
            </div>
            <WFText size={11} color={WF.accent} bold>업그레이드 ›</WFText>
          </WFRow>
        </WFCard>
      </div>
      <WFTabBar active={0}/>
    </WFScreen>
  );
}

// ─────────────── HOME B — big hero fortune, cards below ───────────────
function ScrHomeB() {
  return (
    <WFScreen>
      <WFStatusSpacer/>
      <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {/* Hero — full-width dark-ish fortune area */}
        <div style={{
          background: '#efece3', borderBottom: `1px solid ${WF.ink}`,
          padding: '14px 18px 18px',
        }}>
          <WFRow>
            <WFText size={11} color={WF.inkSoft}>4월 22일 화요일</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={11} color={WF.inkSoft}>🔔</WFText>
          </WFRow>
          <div style={{ height: 10 }}/>
          <WFText size={13} color={WF.inkSoft}>지민님의 오늘 사주</WFText>
          <div/>
          <WFText size={22} bold>흐름을 읽기{'\n'}좋은 날이에요</WFText>
          <div style={{ height: 8 }}/>
          <WFRow>
            <WFBadge>수(水) 강함</WFBadge>
            <WFBadge>분석형 ↑</WFBadge>
            <WFBadge accent>지출 주의</WFBadge>
          </WFRow>
        </div>

        <div style={{ padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 10, flex: 1, overflow: 'hidden' }}>
          {/* Quick stats row */}
          <div style={{ display: 'flex', gap: 8 }}>
            {[
              { l: '금전운', v: '7.5' },
              { l: '지출운', v: '4.2' },
              { l: '주의', v: '중' },
            ].map(x => (
              <WFCard key={x.l} pad={8} style={{ flex: 1, textAlign: 'center' }}>
                <WFText size={10} color={WF.inkSoft}>{x.l}</WFText>
                <div/>
                <WFText size={16} bold>{x.v}</WFText>
              </WFCard>
            ))}
          </div>

          <WFCard title="내 투자 성향" pad={10}>
            <WFRow>
              <WFCircle size={32}/>
              <div style={{ flex: 1 }}>
                <WFText size={13} bold>신중한 탐험가</WFText>
                <div/>
                <WFText size={10} color={WF.inkSoft}>위험 선호 · 낮음</WFText>
              </div>
              <WFText size={11} color={WF.accent}>›</WFText>
            </WFRow>
          </WFCard>

          <WFCard title="모의투자" pad={10}>
            <WFRow>
              <div style={{ flex: 1 }}>
                <WFText size={11} color={WF.inkSoft}>수익률</WFText>
                <div/>
                <WFText size={16} bold color={WF.accent2}>+2.5%</WFText>
              </div>
              <WFPlaceholder w={60} h={24} label=""/>
              <WFButton small primary>이어서</WFButton>
            </WFRow>
          </WFCard>

          <WFCard accent pad={10}>
            <WFText size={11} bold color={WF.accent}>6개월 운세 리포트가 도착했어요</WFText>
            <div/>
            <WFText size={10} color={WF.inkSoft}>프리미엄 전용 · 잠금</WFText>
          </WFCard>
        </div>
      </div>
      <WFTabBar active={0}/>
    </WFScreen>
  );
}

// ─────────────── HOME C — calendar / moon phase centric ───────────────
function ScrHomeC() {
  return (
    <WFScreen>
      <WFStatusSpacer/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '8px 16px 12px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFRow>
          <WFText size={13} bold>4月 22日 · 火</WFText>
          <div style={{ flex: 1 }}/>
          <WFText size={11} color={WF.inkSoft}>지민 ⌄</WFText>
        </WFRow>

        {/* Week strip */}
        <WFCard pad={8}>
          <div style={{ display: 'flex', gap: 4 }}>
            {['일','월','화','수','목','금','토'].map((d, i) => (
              <div key={d} style={{
                flex: 1, textAlign: 'center',
                padding: '6px 0',
                background: i === 2 ? WF.ink : 'transparent',
                color: i === 2 ? WF.paper : WF.ink,
                border: `1px solid ${WF.ink}`,
              }}>
                <WFText size={9} color={i === 2 ? WF.paper : WF.inkSoft}>{d}</WFText>
                <div/>
                <WFText size={12} bold color={i === 2 ? WF.paper : WF.ink}>{19 + i}</WFText>
                <div style={{
                  width: 4, height: 4, borderRadius: 2, margin: '2px auto 0',
                  background: i === 2 ? WF.paper : (i % 2 ? WF.accent : WF.inkFaint),
                }}/>
              </div>
            ))}
          </div>
        </WFCard>

        {/* Moon / hero */}
        <WFCard pad={14} style={{ textAlign: 'center' }}>
          <WFCircle size={54} style={{ margin: '0 auto' }}/>
          <div style={{ height: 6 }}/>
          <WFText size={15} bold>흐름 · 수(水)</WFText>
          <div/>
          <WFText size={10} color={WF.inkSoft}>오늘의 키워드</WFText>
        </WFCard>

        {/* Three tile grid */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {[
            { l: '오늘 사주', s: '분석 좋음' },
            { l: '금전운', s: '7.5 / 10' },
            { l: '내 성향', s: '신중형' },
            { l: '학습', s: '3편 추천' },
            { l: '모의투자', s: '+2.5%' },
            { l: '쿠폰함', s: '3장' },
          ].map((t, i) => (
            <WFCard key={i} pad={8} style={{ flex: '1 1 calc(33% - 8px)', minHeight: 60 }}>
              <WFText size={9} color={WF.inkSoft}>{t.l}</WFText>
              <div/>
              <WFText size={11} bold>{t.s}</WFText>
            </WFCard>
          ))}
        </div>

        <div style={{ flex: 1 }}/>
        <WFCard accent pad={8}>
          <WFRow>
            <WFText size={11} color={WF.accent} bold>⭐ PREMIUM</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={11} color={WF.accent}>7일 무료 ›</WFText>
          </WFRow>
        </WFCard>
      </div>
      <WFTabBar active={0}/>
    </WFScreen>
  );
}

// ─────────────── TODAY'S SAJU DETAIL ───────────────
function ScrTodaySaju() {
  return (
    <WFScreen>
      <WFHeader title="오늘의 사주"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div style={{ textAlign: 'center' }}>
          <WFCircle size={64} style={{ margin: '0 auto' }}/>
          <div style={{ height: 8 }}/>
          <WFText size={18} bold>흐름을 읽기 좋은 날</WFText>
          <div/>
          <WFText size={11} color={WF.inkSoft}>4월 22일 · 수(水) 기운 강함</WFText>
        </div>

        <WFCard title="오늘의 요약" pad={10}>
          <WFText size={11}>
            분석적 판단이 잘 통하는 하루.{'\n'}
            새로운 종목 탐색보다는 기존 포지션{'\n'}점검이 유리해요.
          </WFText>
        </WFCard>

        <WFCard title="금전 · 지출" pad={10}>
          <WFRow><WFText size={11}>금전운</WFText><div style={{ flex: 1 }}/><WFProgress value={0.75}/></WFRow>
          <div style={{ height: 6 }}/>
          <WFRow><WFText size={11}>지출 주의</WFText><div style={{ flex: 1 }}/><WFProgress value={0.4} color={WF.accent}/></WFRow>
        </WFCard>

        <WFLock locked>
          <WFCard title="깊이 있는 분석" accent pad={10}>
            <WFText size={11}>• 일주 분석 · 용신 해석{'\n'}• 오늘의 재물 방위{'\n'}• 시간대별 조언</WFText>
          </WFCard>
        </WFLock>

        <WFButton primary>성향 분석 결과 보기</WFButton>
      </div>
    </WFScreen>
  );
}

// ─────────────── 6-MONTH FORTUNE ───────────────
function Scr6Month() {
  return (
    <WFScreen>
      <WFHeader title="6개월 운세"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFText size={16} bold>5월 — 10월 흐름</WFText>
        <WFText size={11} color={WF.inkSoft}>월별 금전 · 투자 흐름 요약</WFText>

        <WFPlaceholder h={90} label="6-month trend line (low-fi)"/>

        {/* Month rows */}
        {[
          { m: '5월', k: '기반 다지기', v: 0.5, lock: false },
          { m: '6월', k: '신중한 관찰', v: 0.4, lock: false },
          { m: '7월', k: '기회 포착', v: 0.8, lock: true },
          { m: '8월', k: '재정비', v: 0.55, lock: true },
          { m: '9월', k: '확장 흐름', v: 0.75, lock: true },
          { m: '10월', k: '정리 국면', v: 0.3, lock: true },
        ].map((r, i) => (
          <WFLock key={i} locked={r.lock} label="PRO">
            <WFCard pad={8}>
              <WFRow>
                <WFText size={11} bold style={{ width: 28 }}>{r.m}</WFText>
                <WFText size={11} style={{ flex: 1 }}>{r.k}</WFText>
                <div style={{ width: 80 }}><WFProgress value={r.v}/></div>
              </WFRow>
            </WFCard>
          </WFLock>
        ))}

        <div style={{ flex: 1 }}/>
        <WFButton primary danger>전체 리포트 잠금 해제</WFButton>
      </div>
    </WFScreen>
  );
}

Object.assign(window, {
  ScrHomeA, ScrHomeB, ScrHomeC, ScrTodaySaju, Scr6Month,
});
