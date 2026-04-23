// Screens 16-20: Referral, Coupons, Paywall, Profile

function ScrReferral() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="친구 초대" back />
      <div style={{ padding: 16, flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div style={{ textAlign: 'center', padding: '12px 0' }}>
          <WPlaceholder w={120} h={120} label="일러스트" style={{ margin: '0 auto' }}/>
          <div style={{ marginTop: 14 }}>
            <WText size={16} weight={700}>친구를 초대해보세요!</WText>
          </div>
          <div style={{ marginTop: 6 }}>
            <WText size={11} color={WF.muted}>친구가 가입하면 둘 다 PRO 1개월 이용권 지급!</WText>
          </div>
        </div>

        <WCard>
          <WSectionLabel>내 초대 코드</WSectionLabel>
          <WBox style={{ marginTop: 8, padding: 12, borderRadius: 6, borderStyle: 'dashed', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <WText size={14} weight={700} style={{ letterSpacing: 2 }}>YAYA-3F7K</WText>
            <WText size={10} color={WF.muted}>복사</WText>
          </WBox>
        </WCard>

        <div style={{ display: 'flex', gap: 8 }}>
          <WButton>카카오톡 공유</WButton>
          <WButton>링크 복사</WButton>
        </div>

        <WCard>
          <WSectionLabel>초대 현황</WSectionLabel>
          <div style={{ display: 'flex', justifyContent: 'space-around', marginTop: 10 }}>
            <div style={{ textAlign: 'center' }}>
              <WText size={18} weight={700}>3</WText>
              <div><WText size={9} color={WF.muted}>초대 성공</WText></div>
            </div>
            <div style={{ width: 1, background: WF.line3 }}/>
            <div style={{ textAlign: 'center' }}>
              <WText size={18} weight={700}>3개월</WText>
              <div><WText size={9} color={WF.muted}>획득 기간</WText></div>
            </div>
          </div>
        </WCard>
      </div>
    </div>
  );
}

function ScrCoupons() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="쿠폰함" back />
      <div style={{ display: 'flex', gap: 14, padding: '0 16px', borderBottom: `1px solid ${WF.line3}` }}>
        {['사용 가능 (2)', '사용 완료', '만료'].map((t, i) => (
          <div key={t} style={{ padding: '10px 0', borderBottom: i === 0 ? `2px solid ${WF.ink}` : 'none' }}>
            <WText size={11} weight={i === 0 ? 700 : 400} color={i === 0 ? WF.ink : WF.muted}>{t}</WText>
          </div>
        ))}
      </div>
      <div style={{ padding: 16, flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {/* Coupon with notched edges */}
        {[
          { t: '프로 1개월 무료', s: '2026.05.30 까지', badge: '초대 보상' },
          { t: '20% 할인', s: '2026.06.15 까지', badge: '웰컴' },
        ].map(x => (
          <div key={x.t} style={{ position: 'relative', border: `1px solid ${WF.line2}`, borderRadius: 8, padding: 14, background: '#fff', display: 'flex', gap: 12, alignItems: 'center' }}>
            <div style={{ position: 'absolute', left: 70, top: -6, width: 12, height: 12, borderRadius: '50%', background: WF.bg, border: `1px solid ${WF.line2}`, borderBottom: 'none', borderRight: 'none' }}/>
            <div style={{ position: 'absolute', left: 70, bottom: -6, width: 12, height: 12, borderRadius: '50%', background: WF.bg, border: `1px solid ${WF.line2}`, borderTop: 'none', borderLeft: 'none' }}/>
            <div style={{ width: 56, paddingRight: 12, borderRight: `1px dashed ${WF.line3}`, textAlign: 'center' }}>
              <WText size={9} color={WF.muted}>쿠폰</WText>
            </div>
            <div style={{ flex: 1 }}>
              <WBox style={{ display: 'inline-block', padding: '1px 5px', borderRadius: 2, borderColor: WF.muted }}>
                <WText size={8} color={WF.muted}>{x.badge}</WText>
              </WBox>
              <div style={{ marginTop: 6 }}>
                <WText size={12} weight={700}>{x.t}</WText>
              </div>
              <div style={{ marginTop: 3 }}>
                <WText size={9} color={WF.muted}>{x.s}</WText>
              </div>
            </div>
            <WButton w={60} h={30} primary>사용</WButton>
          </div>
        ))}
      </div>
    </div>
  );
}

function ScrPaywall() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '16px 20px', display: 'flex', justifyContent: 'space-between' }}>
        <WText size={11} color={WF.muted}>✕</WText>
        <WText size={11} color={WF.muted}>복원</WText>
      </div>
      <div style={{ padding: '0 20px', flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 14, paddingBottom: 20 }}>
        <div>
          <WText size={20} weight={700}>운테크 PRO</WText>
          <div style={{ marginTop: 4 }}>
            <WText size={12} color={WF.muted}>내 사주를 더 깊이, 내 성향을 더 정확히</WText>
          </div>
        </div>

        <WCard>
          <WSectionLabel>PRO 혜택</WSectionLabel>
          <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              '6개월 흐름 리포트 전체 열람',
              '상세 투자 성향 리포트',
              '일/주/월별 리스크 점검 알림',
              '오행별 심화 학습 콘텐츠',
              'AI 사주 상담사',
            ].map(t => (
              <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <svg width="12" height="12" viewBox="0 0 12 12"><path d="M2 6l3 3 5-6" fill="none" stroke={WF.ink} strokeWidth="1.5" strokeLinecap="round"/></svg>
                <WText size={11}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* Plans */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <WBox style={{ padding: 14, borderRadius: 8, borderWidth: 2, position: 'relative' }}>
            <div style={{ position: 'absolute', top: -8, right: 12, background: WF.ink, padding: '2px 8px', borderRadius: 3 }}>
              <WText size={9} weight={700} color="#fff">인기</WText>
            </div>
            <WText size={11} weight={600}>연간 플랜</WText>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 4 }}>
              <WText size={18} weight={700}>₩59,000</WText>
              <WText size={10} color={WF.muted}>/ 년 · 월 ₩4,917</WText>
            </div>
            <div style={{ marginTop: 2 }}>
              <WText size={9} color={WF.muted}>연 48% 절약 · 무료체험 7일</WText>
            </div>
          </WBox>
          <WBox style={{ padding: 14, borderRadius: 8 }}>
            <WText size={11} weight={600}>월간 플랜</WText>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 4 }}>
              <WText size={18} weight={700}>₩9,900</WText>
              <WText size={10} color={WF.muted}>/ 월</WText>
            </div>
          </WBox>
        </div>

        <WButton primary>7일 무료 체험 시작</WButton>
        <div style={{ textAlign: 'center' }}>
          <WText size={9} color={WF.muted}>언제든 취소 가능 · <span style={{textDecoration:'underline'}}>환불 정책</span> · 이용약관</WText>
        </div>
      </div>
    </div>
  );
}

function ScrProfile() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '16px 16px 0' }}>
        <WText size={15} weight={700}>마이페이지</WText>
      </div>
      <div style={{ padding: 16, flex: 1, overflow: 'auto', paddingBottom: 80, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WCard>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <WPlaceholder w={50} h={50} style={{ borderRadius: '50%' }}/>
            <div style={{ flex: 1 }}>
              <WText size={13} weight={700}>홍길동</WText>
              <div><WText size={10} color={WF.muted}>경금 일주 · 단단한 수집가형</WText></div>
            </div>
            <WBox style={{ padding: '4px 8px', borderRadius: 3, background: WF.ink, borderColor: WF.ink }}>
              <WText size={9} weight={700} color="#fff">PRO</WText>
            </WBox>
          </div>
        </WCard>

        {[
          { h: '사주', items: ['내 사주 정보', '투자 성향 리포트', '세운 업데이트', '사주 일기 · 적중률', '감정 체크 히스토리'] },
          { h: '구독·혜택', items: ['구독 관리', '쿠폰함 (2)', '친구 초대'] },
          { h: '설정', items: ['알림 설정', '고객 지원', '면책 고지 · 이용 정책', '로그아웃'] },
        ].map(g => (
          <div key={g.h}>
            <div style={{ padding: '8px 4px' }}>
              <WSectionLabel>{g.h}</WSectionLabel>
            </div>
            <WCard style={{ padding: 0 }}>
              {g.items.map((t, i) => (
                <div key={t} style={{ padding: '14px 14px', borderBottom: i < g.items.length - 1 ? `1px solid ${WF.line3}` : 'none', display: 'flex', alignItems: 'center' }}>
                  <WText size={11} style={{ flex: 1 }}>{t}</WText>
                  <WText size={10} color={WF.muted}>›</WText>
                </div>
              ))}
            </WCard>
          </div>
        ))}
      </div>
      <WTabBar active={3} />
    </div>
  );
}

function ScrResultLoader() {
  return (
    <div style={{ height: '100%', background: WF.bg, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 24, gap: 16 }}>
      <WPlaceholder w={100} h={100} label="애니메이션" />
      <div style={{ textAlign: 'center' }}>
        <WText size={14} weight={700}>사주를 분석 중입니다</WText>
        <div style={{ marginTop: 6 }}>
          <WText size={11} color={WF.muted}>1990년 3월 15일생의{'\n'}원국을 계산하고 있어요</WText>
        </div>
      </div>
      <div style={{ width: 180, height: 4, background: WF.gray2, borderRadius: 2, overflow: 'hidden' }}>
        <div style={{ width: '60%', height: '100%', background: WF.ink }}/>
      </div>
      <WText size={10} color={WF.muted}>60%</WText>

      {/* 명리학 팁 회전 표시 */}
      <div style={{ width: '100%', padding: '12px 14px', background: WF.gray, borderRadius: 8, textAlign: 'center' }}>
        <WText size={9} color={WF.muted}>알고 계셨나요?</WText>
        <div style={{ marginTop: 4 }}>
          <WText size={11}>"경금(庚金)은 차가운 금속의 기운으로{'\n'}원칙과 결단력을 나타내요"</WText>
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 4, marginTop: 8 }}>
          {[0,1,2].map(i => (
            <div key={i} style={{ width: i===0?12:5, height: 5, borderRadius: 3, background: i===0 ? WF.ink : WF.gray2 }}/>
          ))}
        </div>
      </div>

      <WText size={9} color={WF.muted}>Swiss Ephemeris 기반 정밀 계산 중</WText>
    </div>
  );
}

Object.assign(window, { ScrReferral, ScrCoupons, ScrPaywall, ScrProfile, ScrResultLoader });
