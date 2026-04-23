// Investment personality, learning content, mock investing

// ─────────────── INVESTMENT PERSONALITY RESULT ───────────────
function ScrPersonality() {
  return (
    <WFScreen>
      <WFHeader title="투자 성향 분석"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div style={{ textAlign: 'center' }}>
          <WFPlaceholder h={90} w={90} label="타입 캐릭터" style={{ margin: '0 auto' }}/>
          <div style={{ height: 8 }}/>
          <WFBadge accent>TYPE · 03 / 12</WFBadge>
          <div style={{ height: 4 }}/>
          <WFText size={20} bold>신중한 탐험가</WFText>
          <div/>
          <WFText size={12} color={WF.inkSoft} italic>
            "돌다리도 두드려 보되,{'\n'}기회가 오면 움직이는 타입"
          </WFText>
        </div>

        <WFCard title="성향 설명" pad={10}>
          <WFText size={11}>
            안정성을 중시하지만 새로운 기회{'\n'}
            앞에서는 용기를 내는 균형형.{'\n'}
            분석 기반의 결정이 잘 맞아요.
          </WFText>
        </WFCard>

        <WFCard title="위험 선호도" pad={10}>
          <WFRow>
            <WFText size={10} color={WF.inkSoft}>낮음</WFText>
            <div style={{ flex: 1 }}><WFProgress value={0.35}/></div>
            <WFText size={10} color={WF.inkSoft}>높음</WFText>
          </WFRow>
          <div style={{ height: 6 }}/>
          <WFText size={10} color={WF.inkSoft}>ETF · 인덱스 · 우량주 중심 추천</WFText>
        </WFCard>

        <WFCard title="추천 공부 방향" pad={10}>
          {['① 자산배분 · 포트폴리오 기초', '② ETF / 인덱스 투자', '③ 재무제표 읽기 입문'].map(s => (
            <div key={s}><WFText size={11}>{s}</WFText></div>
          ))}
        </WFCard>

        <WFButton primary>추천 콘텐츠 보기 ›</WFButton>
      </div>
    </WFScreen>
  );
}

// ─────────────── LEARNING LIST ───────────────
function ScrLearningList() {
  return (
    <WFScreen>
      <WFStatusSpacer/>
      <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '8px 16px' }}>
          <WFText size={20} bold>학습</WFText>
          <div/>
          <WFText size={11} color={WF.inkSoft}>신중한 탐험가님을 위한 추천</WFText>
        </div>

        {/* tabs */}
        <div style={{ display: 'flex', gap: 6, padding: '0 16px 10px', borderBottom: `1px solid ${WF.inkFaint}` }}>
          {['추천', '입문', 'ETF', '차트', '리포트'].map((t, i) => (
            <div key={t} style={{
              padding: '6px 10px',
              borderBottom: i === 0 ? `2px solid ${WF.ink}` : 'none',
              fontFamily: WF.hand, fontSize: 12,
              fontWeight: i === 0 ? 700 : 400,
              color: i === 0 ? WF.ink : WF.inkSoft,
            }}>{t}</div>
          ))}
        </div>

        <div style={{ flex: 1, overflow: 'hidden', padding: '10px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[
            { t: '주식 첫 걸음', d: '5분 · 입문', lock: false, badge: 'NEW' },
            { t: 'ETF 한 번에 이해하기', d: '8분 · 초급', lock: false, badge: null },
            { t: '나의 성향별 자산배분', d: '리포트 · 중급', lock: true, badge: 'PRO' },
            { t: '차트 읽기 기본', d: '12분 · 중급', lock: false, badge: null },
            { t: '월간 종목 리포트', d: '리포트 · 고급', lock: true, badge: 'PRO' },
          ].map((c, i) => (
            <WFLock key={i} locked={c.lock}>
              <WFCard pad={10}>
                <WFRow>
                  <WFPlaceholder w={54} h={44} label=""/>
                  <div style={{ flex: 1 }}>
                    <WFRow>
                      <WFText size={12} bold>{c.t}</WFText>
                      {c.badge && <WFBadge accent={c.badge === 'PRO'}>{c.badge}</WFBadge>}
                    </WFRow>
                    <div/>
                    <WFText size={10} color={WF.inkSoft}>{c.d}</WFText>
                  </div>
                </WFRow>
              </WFCard>
            </WFLock>
          ))}
        </div>
      </div>
      <WFTabBar active={1}/>
    </WFScreen>
  );
}

// ─────────────── LEARNING DETAIL ───────────────
function ScrLearningDetail() {
  return (
    <WFScreen>
      <WFHeader title="ETF 한 번에 이해하기"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFPlaceholder h={140} label="cover image"/>
        <WFRow>
          <WFBadge>초급</WFBadge>
          <WFBadge>8분</WFBadge>
          <div style={{ flex: 1 }}/>
          <WFText size={11} color={WF.inkSoft}>🔖 저장</WFText>
        </WFRow>
        <WFText size={16} bold>ETF 한 번에 이해하기</WFText>

        <WFCard title="요약" pad={10}>
          <WFText size={11}>
            • 여러 종목을 하나로 묶은 상품{'\n'}
            • 분산 효과 + 낮은 비용{'\n'}
            • 초보가 시작하기 좋은 선택
          </WFText>
        </WFCard>

        {/* body preview, then lock */}
        <WFText size={11} color={WF.inkSoft}>— 본문 미리보기 —</WFText>
        <div style={{ position: 'relative' }}>
          <div style={{ height: 50, background: 'linear-gradient(transparent, rgba(250,250,247,0.95))',
            position: 'absolute', bottom: 0, left: 0, right: 0 }}/>
          <WFText size={10} color={WF.inkSoft}>
            ETF란 Exchange Traded Fund의 줄임말로{'\n'}
            여러 주식을 한 번에 담은 바구니라고{'\n'}
            생각하면 쉬워요. 예를 들어 KODEX 200은{'\n'}
            한국 대표 200개 기업을...
          </WFText>
        </div>

        <WFCard accent pad={10} style={{ textAlign: 'center' }}>
          <WFText size={12} bold color={WF.accent}>전체 보기 · 프리미엄</WFText>
          <div/>
          <WFText size={10} color={WF.inkSoft}>다음 콘텐츠까지 함께 잠금 해제</WFText>
        </WFCard>

        <WFButton primary>다음 콘텐츠 ›</WFButton>
      </div>
    </WFScreen>
  );
}

// ─────────────── MOCK INVESTING MAIN ───────────────
function ScrMockMain() {
  return (
    <WFScreen>
      <WFStatusSpacer/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '8px 16px 12px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFText size={20} bold>모의투자</WFText>

        {/* Balance hero */}
        <WFCard pad={14}>
          <WFText size={10} color={WF.inkSoft}>가상 자산</WFText>
          <div/>
          <WFText size={22} bold>₩ 10,250,400</WFText>
          <div/>
          <WFRow>
            <WFText size={11} color={WF.accent2}>+250,400 (+2.5%)</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={10} color={WF.inkSoft}>지난 30일</WFText>
          </WFRow>
          <div style={{ height: 6 }}/>
          <WFPlaceholder h={50} label="수익률 그래프"/>
        </WFCard>

        {/* Fit feedback */}
        <WFCard title="내 성향 적합도" accent pad={10}>
          <WFRow>
            <WFText size={11}>신중한 탐험가 성향과</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={13} bold color={WF.accent2}>82% 적합</WFText>
          </WFRow>
          <div style={{ height: 4 }}/>
          <WFProgress value={0.82} color={WF.accent2}/>
        </WFCard>

        <WFText size={12} bold>추천 종목 / ETF</WFText>
        {[
          { n: 'KODEX 200', t: 'ETF · 안정', p: '+1.2%' },
          { n: '삼성전자', t: '주식 · 우량', p: '-0.5%' },
          { n: 'TIGER 미국S&P500', t: 'ETF · 분산', p: '+0.8%' },
        ].map((r, i) => (
          <WFCard key={i} pad={8}>
            <WFRow>
              <div style={{ flex: 1 }}>
                <WFText size={12} bold>{r.n}</WFText>
                <div/>
                <WFText size={10} color={WF.inkSoft}>{r.t}</WFText>
              </div>
              <WFText size={12} bold color={r.p[0] === '+' ? WF.accent2 : WF.accent}>{r.p}</WFText>
              <WFButton small>매수</WFButton>
            </WFRow>
          </WFCard>
        ))}

        <div style={{ flex: 1 }}/>
        <WFRow>
          <WFButton style={{ flex: 1 }}>포트폴리오</WFButton>
          <WFButton primary style={{ flex: 1 }}>종목 찾기</WFButton>
        </WFRow>
      </div>
      <WFTabBar active={2}/>
    </WFScreen>
  );
}

// ─────────────── MOCK INVESTING — STOCK PICK + TRADE ───────────────
function ScrMockTrade() {
  return (
    <WFScreen>
      <WFHeader title="KODEX 200"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div>
          <WFText size={22} bold>₩ 34,250</WFText>
          <div/>
          <WFText size={11} color={WF.accent2}>+ 420 (+1.24%)</WFText>
        </div>
        <WFPlaceholder h={120} label="price chart · 1D 1W 1M 3M 1Y"/>

        <WFCard title="성향 피드백" pad={10}>
          <WFText size={11}>
            ✓ 분산 효과 높음{'\n'}
            ✓ 신중형에 적합{'\n'}
            △ 단기 변동성 주의
          </WFText>
        </WFCard>

        <WFCard title="수량 · 주문" pad={10}>
          <WFRow>
            <WFText size={11}>수량</WFText>
            <div style={{ flex: 1 }}/>
            <WFBox style={{ padding: '4px 10px' }}><WFMono>10</WFMono></WFBox>
          </WFRow>
          <div style={{ height: 6 }}/>
          <WFRow>
            <WFText size={11} color={WF.inkSoft}>예상 체결</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={12} bold>₩ 342,500</WFText>
          </WFRow>
        </WFCard>

        <div style={{ flex: 1 }}/>
        <WFRow>
          <WFButton style={{ flex: 1 }}>매도</WFButton>
          <WFButton primary style={{ flex: 1 }}>매수하기</WFButton>
        </WFRow>
      </div>
    </WFScreen>
  );
}

// ─────────────── PORTFOLIO ───────────────
function ScrPortfolio() {
  return (
    <WFScreen>
      <WFHeader title="내 포트폴리오"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFCard pad={12}>
          <WFText size={10} color={WF.inkSoft}>총 평가금액</WFText>
          <div/>
          <WFText size={20} bold>₩ 10,250,400</WFText>
          <div/>
          <WFText size={11} color={WF.accent2}>+ 250,400 (+2.50%)</WFText>
        </WFCard>

        <WFPlaceholder h={80} label="자산 구성 도넛 차트"/>

        <WFText size={12} bold>보유 종목</WFText>
        {[
          { n: 'KODEX 200', w: '40%', p: '+1.2%' },
          { n: '삼성전자', w: '25%', p: '-0.5%' },
          { n: 'TIGER S&P500', w: '20%', p: '+0.8%' },
          { n: '현금', w: '15%', p: '—' },
        ].map((r, i) => (
          <WFCard key={i} pad={8}>
            <WFRow>
              <div style={{ flex: 1 }}>
                <WFText size={12} bold>{r.n}</WFText>
                <div/>
                <WFText size={10} color={WF.inkSoft}>비중 {r.w}</WFText>
              </div>
              <WFText size={11} color={r.p[0] === '+' ? WF.accent2 : (r.p[0] === '-' ? WF.accent : WF.inkSoft)}>{r.p}</WFText>
            </WFRow>
          </WFCard>
        ))}
      </div>
    </WFScreen>
  );
}

Object.assign(window, {
  ScrPersonality, ScrLearningList, ScrLearningDetail,
  ScrMockMain, ScrMockTrade, ScrPortfolio,
});
