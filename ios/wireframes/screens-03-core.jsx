// Screens 11-15: Personality (alias → ScrInvestmentPersonality), Learning, Mock investing, Portfolio
// ScrPersonality — alias to merged ScrInvestmentPersonality (defined in screens-05-saju-v2.jsx)
// Kept for backward-compat; no artboard references remain.
function ScrPersonality() { return <ScrInvestmentPersonality />; }

function ScrLearning() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '14px 16px 8px' }}>
        <WText size={15} weight={700}>배움</WText>
      </div>
      {/* Tabs */}
      <div style={{ display: 'flex', gap: 14, padding: '0 16px', borderBottom: `1px solid ${WF.line3}` }}>
        {['이번 주', '사주 기초', '투자 기초', '오행별'].map((t, i) => (
          <div key={t} style={{ padding: '10px 0', borderBottom: i === 0 ? `2px solid ${WF.ink}` : 'none' }}>
            <WText size={11} weight={i === 0 ? 700 : 400} color={i === 0 ? WF.ink : WF.muted}>{t}</WText>
          </div>
        ))}
      </div>
      <div style={{ padding: 16, overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 10, paddingBottom: 80 }}>
        {/* Featured */}
        <WCard style={{ padding: 0, overflow: 'hidden' }}>
          <WPlaceholder h={110} label="커버 이미지" style={{ border: 'none' }}/>
          <div style={{ padding: 12 }}>
            <WText size={9} color={WF.muted}>FEATURED · 5분 읽기</WText>
            <div style={{ marginTop: 4 }}>
              <WText size={13} weight={700}>사주로 보는 5가지 투자 유형</WText>
            </div>
            <div style={{ marginTop: 4 }}>
              <WText size={10} color={WF.muted}>내 일주를 알면 전략이 보인다</WText>
            </div>
          </div>
        </WCard>

        {/* List items */}
        {[
          { t: '초보자를 위한 사주 입문', s: '기초 · 7분', free: true },
          { t: '오행과 자산 배분의 관계', s: '중급 · 10분', free: false },
          { t: '편재와 정재, 재물의 두 얼굴', s: '중급 · 8분', free: false },
          { t: '용신을 활용한 매매 타이밍', s: '고급 · 12분', free: false },
        ].map(x => (
          <WCard key={x.t}>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <WPlaceholder w={50} h={50} style={{ flexShrink: 0 }}/>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <WText size={12} weight={600}>{x.t}</WText>
                  {!x.free && (
                    <WBox style={{ padding: '1px 5px', borderRadius: 2, borderColor: WF.muted }}>
                      <WText size={8} color={WF.muted}>PRO</WText>
                    </WBox>
                  )}
                </div>
                <div style={{ marginTop: 4 }}>
                  <WText size={10} color={WF.muted}>{x.s}</WText>
                </div>
              </div>
            </div>
          </WCard>
        ))}
      </div>
      <WTabBar active={0} />
    </div>
  );
}

function ScrMockInvest() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '14px 16px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <WText size={15} weight={700}>모의 투자</WText>
          <div style={{ padding: '2px 6px', border: `1px solid #c44`, borderRadius: 4 }}>
            <WText size={8} weight={700} color='#c44'>모의</WText>
          </div>
        </div>
        <WText size={10} color={WF.muted}>순위 42위</WText>
      </div>
      <div style={{ flex: 1, overflow: 'auto', paddingBottom: 64, display: 'flex', flexDirection: 'column', gap: 0 }}>
        <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          {/* 오늘의 체크인 */}
          <WCard style={{ padding: 12 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <WText size={11} weight={700}>오늘의 체크인</WText>
                <div style={{ marginTop: 3 }}><WText size={10} color={WF.muted}>지금 투자 감정은 어떤가요?</WText></div>
              </div>
              <WText size={10} color={WF.muted}>›</WText>
            </div>
            <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
              {['조급함', '평온', '자신감', '불안'].map((t, i) => (
                <div key={t} style={{ padding: '4px 8px', borderRadius: 10, border: `1px solid ${i===1 ? WF.ink : WF.line2}`, background: i===1 ? WF.ink : '#fff' }}>
                  <WText size={9} color={i===1 ? '#fff' : WF.muted}>{t}</WText>
                </div>
              ))}
            </div>
          </WCard>

          {/* Balance card */}
          <WBox style={{ padding: 16, borderRadius: 10, background: WF.gray, borderColor: WF.line2 }}>
            <WText size={10} color={WF.muted}>총 자산 (모의)</WText>
            <div style={{ marginTop: 6 }}>
              <WText size={22} weight={700}>₩10,240,000</WText>
            </div>
            <div style={{ marginTop: 4 }}>
              <WText size={11} color={WF.muted}>+₩240,000 (+2.4%)</WText>
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
              <WButton w="50%" h={34} style={{ background: '#fff' }}>매수</WButton>
              <WButton w="50%" h={34} style={{ background: '#fff' }}>매도</WButton>
            </div>
          </WBox>

          {/* 자산군 우선 */}
          <WCard>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <WSectionLabel>오늘 기운과 어울리는 자산군</WSectionLabel>
              <WText size={9} color={WF.muted}>왜?</WText>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6, marginTop: 8 }}>
              {[
                { t: '배당주', s: '안정 추구 성향에 맞는', active: true },
                { t: 'ETF', s: '분산 효과', active: false },
                { t: '금', s: '水 기운 보완', active: false },
              ].map(x => (
                <div key={x.t} style={{ padding: '8px 6px', borderRadius: 6, border: `1px solid ${x.active ? WF.ink : WF.line2}`, background: x.active ? WF.gray : '#fff', textAlign: 'center' }}>
                  <WText size={11} weight={x.active ? 700 : 400}>{x.t}</WText>
                  <div style={{ marginTop: 3 }}><WText size={8} color={WF.muted}>{x.s}</WText></div>
                </div>
              ))}
            </div>
          </WCard>

          {/* Holdings */}
          <WCard>
            <WSectionLabel>내 보유 종목</WSectionLabel>
            <div style={{ marginTop: 6 }}>
              <div style={{ display: 'flex', alignItems: 'center', padding: '8px 0' }}>
                <div style={{ flex: 1 }}>
                  <WText size={12} weight={600}>카카오</WText>
                  <div><WText size={9} color={WF.muted}>10주 · 평균 ₩48,000</WText></div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <WText size={11} weight={600}>₩52,400</WText>
                  <div><WText size={9} color={WF.muted}>+9.1%</WText></div>
                </div>
              </div>
            </div>
          </WCard>
        </div>
      </div>
      <div style={{ marginBottom: 64 }}><WDisclaimer /></div>
      <WTabBar active={1} />
    </div>
  );
}

function ScrBuyOrder() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="삼성전자 매수" back right={<div style={{padding:'2px 6px',border:'1px solid #c44',borderRadius:4}}><WText size={8} weight={700} color='#c44'>모의</WText></div>}/>
      <div style={{ padding: 16, flex: 1, display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Saju hint banner */}
        <WBox style={{ padding: 10, borderRadius: 6, borderColor: WF.note, borderStyle: 'dashed' }}>
          <WText size={10} color={WF.note}>변동성 높은 날 — 분산 접근이 내 성향에 맞아요</WText>
        </WBox>

        <div>
          <WText size={10} color={WF.muted}>현재가</WText>
          <div><WText size={20} weight={700}>₩72,400</WText></div>
        </div>

        <div>
          <WText size={11} weight={600}>수량</WText>
          <WBox style={{ height: 44, marginTop: 6, display: 'flex', alignItems: 'center', padding: '0 12px', borderRadius: 6, justifyContent: 'space-between' }}>
            <WText size={9} color={WF.muted}>−</WText>
            <WText size={13} weight={600}>10 주</WText>
            <WText size={9} color={WF.muted}>+</WText>
          </WBox>
        </div>

        <div>
          <WText size={11} weight={600}>주문 가격</WText>
          <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
            <WBox style={{ flex: 1, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 6, background: WF.gray }}>
              <WText size={11} weight={600}>시장가</WText>
            </WBox>
            <WBox style={{ flex: 1, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 6 }}>
              <WText size={11}>지정가</WText>
            </WBox>
          </div>
        </div>

        <WBox style={{ padding: 10, borderRadius: 6, background: WF.gray }}>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <WText size={10} color={WF.muted}>총 매수금액</WText>
            <WText size={12} weight={700}>₩724,000</WText>
          </div>
        </WBox>

        <div style={{ flex: 1 }}/>
        <WText size={8} color={WF.muted} style={{ textAlign: 'center' }}>※ 모의 투자 · 실제 투자 결정은 본인 판단입니다</WText>
        <WButton primary>매수 주문</WButton>
      </div>
    </div>
  );
}

function ScrPortfolio() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="포트폴리오 분석" back />
      <div style={{ padding: 16, flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <WCard>
          <WSectionLabel>자산 배분</WSectionLabel>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginTop: 10 }}>
            <WPlaceholder w={90} h={90} label="도넛" style={{ borderRadius: '50%' }}/>
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4 }}>
              {[
                { t: '주식', v: '56%' }, { t: '현금', v: '24%' },
                { t: '금', v: '12%' }, { t: '코인', v: '8%' },
              ].map(x => (
                <div key={x.t} style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <div style={{ width: 8, height: 8, background: WF.ink, borderRadius: 1 }}/>
                  <WText size={10} style={{ flex: 1 }}>{x.t}</WText>
                  <WText size={10} weight={600}>{x.v}</WText>
                </div>
              ))}
            </div>
          </div>
        </WCard>

        <WCard>
          <WSectionLabel>사주와의 궁합</WSectionLabel>
          <div style={{ marginTop: 6 }}>
            <WText size={12} weight={700}>82점 · 좋음</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={10} color={WF.muted}>金 일주에 맞는 안정형 배분</WText>
          </div>
        </WCard>

        <WCard>
          <WSectionLabel>성향에 맞는 리밸런싱 참고</WSectionLabel>
          <WLocked>
            <WLine w="80%" style={{ marginTop: 8 }}/>
            <WLine w="60%" style={{ marginTop: 6 }}/>
            <WLine w="75%" style={{ marginTop: 6 }}/>
          </WLocked>
        </WCard>

        {/* 복기 일기 진입점 */}
        <WCard style={{ padding: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <WText size={11} weight={600}>복기 일기</WText>
              <div style={{ marginTop: 2 }}>
                <WText size={9} color={WF.muted}>어제 포지션 결과 기록 →</WText>
              </div>
            </div>
            <WText size={11} color={WF.muted}>›</WText>
          </div>
        </WCard>
        <WDisclaimer />
      </div>
    </div>
  );
}

Object.assign(window, { ScrPersonality, ScrLearning, ScrMockInvest, ScrBuyOrder, ScrPortfolio });
