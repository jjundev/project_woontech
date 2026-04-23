// Screens 06-10: Home dashboard (3 variations), Today's Saju detail

// Home variation A — Feed layout (cards stacked)
function ScrHomeA() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '12px 16px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <WText size={10} color={WF.muted}>2026.04.22 수요일</WText>
          <div style={{ marginTop: 2 }}>
            <WText size={15} weight={700}>안녕하세요, 길동님</WText>
          </div>
        </div>
        <div style={{ width: 30, height: 30, border: `1px solid ${WF.line2}`, borderRadius: 15 }}/>
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 12, paddingBottom: 80, overflow: 'auto', flex: 1 }}>
        {/* Today's Saju hero */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <WSectionLabel>오늘의 투자 사주</WSectionLabel>
            <WText size={9} color={WF.muted}>자세히 →</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={14} weight={700}>"오늘은 관망의 날"</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={11} color={WF.muted}>火 기운이 강해 충동적 매매 주의</WText>
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 10 }}>
            {['주식 · 하', '코인 · 중', '부동산 · 상'].map(t => (
              <WBox key={t} style={{ flex: 1, padding: '6px 0', borderRadius: 4, textAlign: 'center', borderColor: WF.line3 }}>
                <WText size={9}>{t}</WText>
              </WBox>
            ))}
          </div>
        </WCard>

        {/* Portfolio preview */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <WSectionLabel>내 모의 포트폴리오</WSectionLabel>
            <WText size={9} color={WF.muted}>+2.4%</WText>
          </div>
          <WPlaceholder h={60} label="차트" style={{ marginTop: 6 }}/>
        </WCard>

        {/* 6-month fortune teaser (locked) */}
        <WCard>
          <WSectionLabel>6개월 흐름 참고 리포트</WSectionLabel>
          <WLocked label="구독 후 열람">
            <WPlaceholder h={70} label="그래프" style={{ marginTop: 6 }}/>
            <div style={{ marginTop: 8 }}>
              <WText size={10} color={WF.muted}>5월 ▲  6월 ▼  7월 ▲  8월 ▲  9월 ▼  10월 ▲</WText>
            </div>
          </WLocked>
        </WCard>

        {/* Learning card */}
        <WCard>
          <WSectionLabel>오늘의 학습</WSectionLabel>
          <div style={{ marginTop: 4 }}>
            <WText size={12} weight={600}>"金 일주의 투자 스타일"</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={10} color={WF.muted}>3분 읽기 · 초급</WText>
          </div>
        </WCard>
      </div>
      <WTabBar active={0} />
    </div>
  );
}

// Context badge pill
function CtxBadge({ label }) {
  return (
    <div style={{
      display: 'inline-block', padding: '2px 7px',
      border: `1px solid ${WF.line2}`, borderRadius: 10,
      background: WF.gray,
    }}>
      <WText size={8} color={WF.muted}>{label}</WText>
    </div>
  );
}

// Home variation B — 방향 B+A 조합: 내용 분화 + 맥락 배지
function ScrHomeB() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '14px 16px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <WText size={14} weight={700}>운테크</WText>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <div style={{ padding: '3px 8px', border: `1px solid ${WF.line2}`, borderRadius: 8 }}>
            <WText size={9} color={WF.muted}>오늘의 체크인 →</WText>
          </div>
          <div style={{ width: 20, height: 20, border: `1px solid ${WF.line2}`, borderRadius: 10 }}/>
        </div>
      </div>

      <div style={{ overflow: 'auto', flex: 1, paddingBottom: 80 }}>
        <div style={{ padding: '12px 16px 0' }}>
          <WText size={11} color={WF.muted}>2026.04.23 목요일</WText>
          <div style={{ marginTop: 3 }}>
            <WText size={16} weight={700}>길동님, 오늘의 투자 태도예요</WText>
          </div>
        </div>

        {/* ★ Hero — 오늘의 투자 태도 */}
        <div style={{ padding: '12px 16px 0' }}>
          <WCard style={{ padding: '16px 16px 14px' }}>
            <CtxBadge label="투자 관점" />
            <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 12 }}>
              <div style={{ textAlign: 'center', flexShrink: 0 }}>
                <WPlaceholder w={56} h={56} label="지수" style={{ borderRadius: '50%' }}/>
                <div style={{ marginTop: 6 }}>
                  <WText size={24} weight={700}>72</WText>
                  <WText size={10} color={WF.muted}>/100</WText>
                </div>
              </div>
              <div style={{ flex: 1 }}>
                <WText size={11} weight={600} style={{ lineHeight: 1.4 }}>"공격보다 관찰이 내 성향에 맞아요"</WText>
                <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 5 }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 6 }}>
                    <WText size={10} weight={700}>✓</WText>
                    <div>
                      <WText size={9} color={WF.muted}>권장</WText>
                      <WText size={10}> 관망 · 분산 배분 점검</WText>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 6 }}>
                    <WText size={10} weight={700} color={WF.note}>✗</WText>
                    <div>
                      <WText size={9} color={WF.muted}>피할</WText>
                      <WText size={10}> 추격매수 · 손실 만회 심리</WText>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div style={{ marginTop: 10, padding: '7px 10px', background: WF.gray, borderRadius: 5 }}>
              <WText size={9} color={WF.muted} style={{ whiteSpace: 'pre-line' }}>{'💡 일진은 좋으나 충동성 주의\n— 내 성향엔 관찰이 맞아요'}</WText>
            </div>
            <div style={{ marginTop: 8, textAlign: 'right' }}>
              <WText size={10} color={WF.muted}>상세 보기 ›</WText>
            </div>
          </WCard>
        </div>

        {/* 작은 카드 2개 */}
        <div style={{ padding: '10px 16px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {/* 오늘의 일진 — 한 단어 중심 */}
          <WCard style={{ padding: 12 }}>
            <CtxBadge label="하루 전반" />
            <div style={{ marginTop: 8, fontSize: 22, lineHeight: 1 }}>🤝</div>
            <div style={{ marginTop: 4 }}>
              <WText size={12} weight={700}>협상·유대</WText>
            </div>
            <div style={{ marginTop: 4 }}>
              <WText size={9} color={WF.muted}>애정운 82 ›</WText>
            </div>
            <div style={{ marginTop: 6 }}>
              <WText size={8} color={WF.muted}>오늘의 일진</WText>
            </div>
          </WCard>
          {/* 6개월 흐름 */}
          <WCard style={{ padding: 12 }}>
            <CtxBadge label="중장기" />
            <div style={{ marginTop: 8 }}>
              <svg width="12" height="14" viewBox="0 0 12 14"><rect x="1" y="6" width="10" height="7" stroke={WF.muted} fill="none" strokeWidth="1"/><path d="M3 6V4a3 3 0 0 1 6 0v2" stroke={WF.muted} fill="none" strokeWidth="1"/></svg>
            </div>
            <div style={{ marginTop: 4 }}>
              <WText size={9} color={WF.muted}>PRO</WText>
            </div>
            <div style={{ marginTop: 4 }}>
              <WText size={9} color={WF.muted}>하반기 개선</WText>
            </div>
            <div style={{ marginTop: 6 }}>
              <WText size={8} color={WF.muted}>6개월 흐름</WText>
            </div>
          </WCard>
        </div>

        {/* 오늘의 실천 */}
        <div style={{ padding: '10px 16px 0' }}>
          <WCard style={{ padding: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ width: 28, height: 28, border: `1px solid ${WF.line2}`, borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <WText size={14}>✓</WText>
              </div>
              <div style={{ flex: 1 }}>
                <WText size={10} color={WF.muted}>오늘의 실천</WText>
                <div style={{ marginTop: 2 }}>
                  <WText size={12} weight={600}>부족한 水 기운 — 오늘 분산 배분 점검해보기</WText>
                </div>
              </div>
            </div>
          </WCard>
        </div>
        <div style={{ height: 8 }}/>
      </div>
      <WTabBar active={0} />
    </div>
  );
}

// Home variation C — Minimal / zen
function ScrHomeC() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <WText size={11} color={WF.muted}>수요일, 4월 22일</WText>
        <div style={{ width: 24, height: 24, border: `1px solid ${WF.line2}`, borderRadius: 12 }}/>
      </div>

      <div style={{ padding: '0 20px', flex: 1, display: 'flex', flexDirection: 'column', paddingBottom: 80, overflow: 'auto' }}>
        {/* Centered hero */}
        <div style={{ padding: '30px 0 20px', textAlign: 'center' }}>
          <WText size={10} color={WF.muted}>오늘의 투자 운세</WText>
          <div style={{ marginTop: 16 }}>
            <WPlaceholder w={80} h={80} label="지수" style={{ margin: '0 auto', borderRadius: '50%' }}/>
          </div>
          <div style={{ marginTop: 14 }}>
            <WText size={22} weight={700}>중상</WText>
          </div>
          <div style={{ marginTop: 6 }}>
            <WText size={11} color={WF.muted}>"재물의 기운은 약하나 기회를 볼 때"</WText>
          </div>
        </div>

        {/* Divider line */}
        <div style={{ height: 1, background: WF.line3 }}/>

        {/* Single list */}
        <div style={{ marginTop: 14 }}>
          {[
            { t: '상세 운세 보기', s: '오늘의 투자 가이드' },
            { t: '6개월 흐름 참고 리포트', s: '중장기 흐름', locked: true },
            { t: '나의 투자 사주', s: '나는 어떤 투자자인가' },
            { t: '모의 포트폴리오', s: '수익률 +2.4%' },
          ].map(x => (
            <div key={x.t} style={{ padding: '14px 0', borderBottom: `1px solid ${WF.line3}`, display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ flex: 1 }}>
                <WText size={12} weight={600}>{x.t}</WText>
                <div style={{ marginTop: 2 }}>
                  <WText size={10} color={WF.muted}>{x.s}</WText>
                </div>
              </div>
              {x.locked && (
                <svg width="12" height="14" viewBox="0 0 12 14">
                  <rect x="1" y="6" width="10" height="7" stroke={WF.muted} fill="none" strokeWidth="1"/>
                  <path d="M3 6V4a3 3 0 0 1 6 0v2" stroke={WF.muted} fill="none" strokeWidth="1"/>
                </svg>
              )}
              <WText size={11} color={WF.muted}>›</WText>
            </div>
          ))}
        </div>
      </div>
      <WTabBar active={0} />
    </div>
  );
}

// Today's saju detail
function ScrTodayDetail() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="오늘의 투자 사주" back right={<WText size={10} color={WF.muted}>공유</WText>}/>
      <div style={{ padding: 16, overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* Score hero */}
        <WCard style={{ padding: 16, textAlign: 'center' }}>
          <WText size={10} color={WF.muted}>2026.04.22 · 병오일 (丙午)</WText>
          <div style={{ marginTop: 2 }}>
            <WText size={9} color={WF.muted}>불(火) 기운이 강한 날</WText>
          </div>
          <div style={{ marginTop: 12 }}>
            <WPlaceholder w={100} h={100} label="지수 차트" style={{ margin: '0 auto' }}/>
          </div>
          <div style={{ marginTop: 10 }}>
            <WText size={20} weight={700}>73</WText>
            <WText size={11} color={WF.muted}> / 100</WText>
          </div>
        </WCard>

        {/* 4-pillar mini chart with Korean labels */}
        <WCard>
          <WSectionLabel>나의 사주 × 오늘</WSectionLabel>
          <div style={{ marginTop: 4, marginBottom: 8 }}>
            <WText size={9} color={WF.muted}>내 사주 네 기둥과 오늘의 기운이 어떻게 만나는지 보여드려요</WText>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6, marginTop: 8 }}>
            {[
              { han: '年', kor: '연주', sub: '태어난 해' },
              { han: '月', kor: '월주', sub: '태어난 달' },
              { han: '日', kor: '일주', sub: '나 자신' },
              { han: '時', kor: '시주', sub: '태어난 시' },
            ].map((p, i) => (
              <div key={p.han} style={{ textAlign: 'center' }}>
                <WText size={10} weight={600}>{p.kor}</WText>
                <div>
                  <WText size={8} color={WF.muted}>{p.sub}</WText>
                </div>
                <WBox style={{ height: 40, marginTop: 4, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', borderRadius: 4, background: i === 2 ? WF.gray : '#fff' }}>
                  <WText size={13} weight={700}>丙</WText>
                  <WText size={8} color={WF.muted}>병(불)</WText>
                </WBox>
                <WBox style={{ height: 40, marginTop: 3, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', borderRadius: 4 }}>
                  <WText size={13} weight={700}>午</WText>
                  <WText size={8} color={WF.muted}>오(말)</WText>
                </WBox>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 10, padding: 8, background: WF.gray, borderRadius: 4 }}>
            <WText size={10} color={WF.muted}>
              💡 "일주"는 나 자신을 뜻해요. 오늘은 나의 기운과 하늘의 기운이 만나는 날이에요.
            </WText>
          </div>
        </WCard>

        {/* Categories */}
        {[
          { t: '주식', l: '하', s: '충동 매매 주의 — 오후는 관망이 내 성향에 맞아요' },
          { t: '코인', l: '중', s: '변동성 높음 — 분할 접근 참고' },
          { t: '부동산', l: '상', s: '정보 수집 활발한 시기' },
        ].map(x => (
          <WCard key={x.t}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <WBox style={{ width: 40, height: 40, borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <WText size={13} weight={700}>{x.l}</WText>
              </WBox>
              <div style={{ flex: 1 }}>
                <WText size={12} weight={600}>{x.t}</WText>
                <div style={{ marginTop: 2 }}>
                  <WText size={10} color={WF.muted}>{x.s}</WText>
                </div>
              </div>
              <WText size={11} color={WF.muted}>›</WText>
            </div>
          </WCard>
        ))}

        {/* CTA */}
        <WButton>모의 포트폴리오 조정하기 →</WButton>
      </div>
    </div>
  );
}

// 6-month fortune page (with paywall locking)
function ScrSixMonth() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="6개월 흐름 참고 리포트" back />
      <div style={{ padding: 16, overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <WCard>
          <WSectionLabel>흐름 그래프</WSectionLabel>
          <WPlaceholder h={100} label="월별 지수 라인" style={{ marginTop: 6 }}/>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
            {['5월', '6월', '7월', '8월', '9월', '10월'].map(m => (
              <WText key={m} size={9} color={WF.muted}>{m}</WText>
            ))}
          </div>
        </WCard>

        {/* First month unlocked */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <WText size={12} weight={700}>2026년 5월</WText>
            <WText size={10} color={WF.muted}>재물운 ▲</WText>
          </div>
          <div style={{ marginTop: 6 }}>
            <WText size={10} color={WF.muted}>새로운 투자 기회가 들어오는 달. 단, 5/12~5/18 주의.</WText>
          </div>
        </WCard>

        {/* Locked rest */}
        <WCard>
          <WLocked>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <WText size={12} weight={700}>2026년 6월</WText>
              <WText size={10} color={WF.muted}>재물운 ▼</WText>
            </div>
            <div style={{ marginTop: 6 }}>
              <WText size={10} color={WF.muted}>보수적 운영이 필요한 달...</WText>
            </div>
          </WLocked>
        </WCard>
        <WCard>
          <WLocked>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <WText size={12} weight={700}>2026년 7월</WText>
              <WText size={10} color={WF.muted}>재물운 ▲</WText>
            </div>
            <div style={{ marginTop: 6 }}>
              <WText size={10} color={WF.muted}>기회의 달...</WText>
            </div>
          </WLocked>
        </WCard>

        <WButton primary>더 깊은 흐름 보기</WButton>
        <WDisclaimer />
      </div>
    </div>
  );
}

Object.assign(window, { ScrHomeA, ScrHomeB, ScrHomeC, ScrTodayDetail, ScrSixMonth });
