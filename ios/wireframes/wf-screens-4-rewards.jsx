// Referral, coupons, subscription, my page, flow diagram

// ─────────────── REFERRAL / INVITE ───────────────
function ScrReferral() {
  return (
    <WFScreen>
      <WFStatusSpacer/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '8px 16px 12px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFText size={20} bold>친구 추천</WFText>
        <WFText size={11} color={WF.inkSoft}>친구가 가입하면 쿠폰을 드려요</WFText>

        <WFCard pad={14} style={{ textAlign: 'center' }}>
          <WFText size={10} color={WF.inkSoft}>내 추천 코드</WFText>
          <div/>
          <WFText size={26} bold style={{ letterSpacing: 4 }}>JIMIN42</WFText>
          <div style={{ height: 8 }}/>
          <WFRow>
            <WFButton small style={{ flex: 1 }}>복사</WFButton>
            <WFButton small primary style={{ flex: 1 }}>공유하기</WFButton>
          </WFRow>
        </WFCard>

        {/* Progress toward reward */}
        <WFCard title="보상 달성 현황" accent pad={10}>
          <WFRow>
            <WFText size={12} bold>2 / 5명 초대 완료</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={10} color={WF.accent}>3명 남음</WFText>
          </WFRow>
          <div style={{ height: 4 }}/>
          <WFProgress value={0.4} color={WF.accent}/>
          <div style={{ height: 8 }}/>
          <WFRow>
            {[1,2,3,4,5].map(i => (
              <div key={i} style={{
                flex: 1, textAlign: 'center',
                padding: '4px 0',
                border: `1px solid ${i <= 2 ? WF.ink : WF.inkFaint}`,
                background: i <= 2 ? WF.ink : 'transparent',
                color: i <= 2 ? WF.paper : WF.inkFaint,
                fontFamily: WF.hand, fontSize: 11,
                marginRight: i < 5 ? 4 : 0,
              }}>{i}</div>
            ))}
          </WFRow>
        </WFCard>

        <WFCard title="초대한 친구" pad={10}>
          {[
            { n: '김**', s: '가입 완료', d: '4/20' },
            { n: '박**', s: '가입 완료', d: '4/15' },
            { n: '초대 링크 전송', s: '대기', d: '4/22' },
          ].map((r, i) => (
            <WFRow key={i} style={{ padding: '6px 0', borderTop: i > 0 ? `0.5px solid ${WF.inkFaint}` : 'none' }}>
              <WFText size={11} style={{ width: 50 }}>{r.n}</WFText>
              <WFBadge accent={r.s === '대기'}>{r.s}</WFBadge>
              <div style={{ flex: 1 }}/>
              <WFMono>{r.d}</WFMono>
            </WFRow>
          ))}
        </WFCard>

        <WFCard title="쿠폰 지급" pad={10}>
          <WFRow>
            <WFText size={11}>5명 완료 시</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={12} bold color={WF.accent}>스타벅스 쿠폰</WFText>
          </WFRow>
          <div style={{ height: 4 }}/>
          <WFText size={10} color={WF.inkSoft}>지급 예정: 달성일 +3일 이내</WFText>
        </WFCard>
      </div>
      <WFTabBar active={3}/>
    </WFScreen>
  );
}

// ─────────────── COUPON WALLET ───────────────
function ScrCoupons() {
  return (
    <WFScreen>
      <WFHeader title="쿠폰함"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {/* tabs */}
        <WFRow>
          {['보유', '사용완료', '지급예정'].map((t, i) => (
            <div key={t} style={{
              padding: '6px 12px',
              background: i === 0 ? WF.ink : 'transparent',
              color: i === 0 ? WF.paper : WF.ink,
              border: `1px solid ${WF.ink}`,
              fontFamily: WF.hand, fontSize: 11,
              marginRight: 6,
            }}>{t}</div>
          ))}
        </WFRow>

        {[
          { n: '스타벅스 5,000원권', e: '~ 2026.05.31', s: '보유' },
          { n: '가입 축하 쿠폰 3,000P', e: '~ 2026.04.30', s: '보유' },
          { n: '친구 추천 1,000P', e: '~ 2026.06.15', s: '보유' },
        ].map((c, i) => (
          <WFCard key={i} pad={10}>
            <WFRow>
              <WFPlaceholder w={44} h={44} label=""/>
              <div style={{ flex: 1 }}>
                <WFText size={12} bold>{c.n}</WFText>
                <div/>
                <WFText size={10} color={WF.inkSoft}>유효 {c.e}</WFText>
              </div>
              <WFButton small>사용</WFButton>
            </WFRow>
          </WFCard>
        ))}

        <WFCard pad={10} dashed>
          <WFRow>
            <WFText size={11} color={WF.inkSoft}>지급 예정 쿠폰</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={11} bold color={WF.accent}>2장</WFText>
          </WFRow>
        </WFCard>
      </div>
    </WFScreen>
  );
}

// ─────────────── SUBSCRIPTION PLANS ───────────────
function ScrSubscription() {
  return (
    <WFScreen>
      <WFHeader title="구독"/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFText size={18} bold>더 깊은 분석을{'\n'}만나보세요</WFText>

        {/* Plan comparison grid */}
        <WFCard pad={0}>
          <div style={{ display: 'flex', borderBottom: `1px solid ${WF.ink}` }}>
            <div style={{ width: 80 }}/>
            {['무료', '베이직', '프리미엄', 'VIP'].map((p, i) => (
              <div key={p} style={{
                flex: 1, textAlign: 'center', padding: 6,
                background: i === 2 ? WF.ink : 'transparent',
                color: i === 2 ? WF.paper : WF.ink,
                borderLeft: `0.5px solid ${WF.inkFaint}`,
                fontFamily: WF.hand, fontSize: 10, fontWeight: 700,
              }}>{p}</div>
            ))}
          </div>
          {[
            ['오늘의 사주', '✓', '✓', '✓', '✓'],
            ['6개월 운세', '—', '✓', '✓', '✓'],
            ['성향 리포트', '요약', '전체', '전체', '전체'],
            ['학습 콘텐츠', '일부', '전체', '전체', '전체'],
            ['종목 리포트', '—', '—', '✓', '✓'],
            ['1:1 상담', '—', '—', '—', '✓'],
          ].map((row, i) => (
            <div key={i} style={{ display: 'flex', borderBottom: i < 5 ? `0.5px solid ${WF.inkFaint}` : 'none' }}>
              <div style={{ width: 80, padding: 6, fontFamily: WF.hand, fontSize: 10, color: WF.inkSoft }}>{row[0]}</div>
              {row.slice(1).map((v, j) => (
                <div key={j} style={{
                  flex: 1, textAlign: 'center', padding: 6,
                  background: j === 2 ? 'rgba(200,60,60,0.05)' : 'transparent',
                  fontFamily: WF.hand, fontSize: 10,
                  color: v === '—' ? WF.inkFaint : WF.ink,
                  fontWeight: j === 2 ? 700 : 400,
                }}>{v}</div>
              ))}
            </div>
          ))}
        </WFCard>

        {/* Plan cards */}
        <WFCard accent pad={12}>
          <WFRow>
            <div style={{ flex: 1 }}>
              <WFBadge accent>추천</WFBadge>
              <div/>
              <WFText size={14} bold>프리미엄</WFText>
              <div/>
              <WFText size={11} color={WF.inkSoft}>₩ 9,900 / 월</WFText>
            </div>
            <WFText size={10} color={WF.accent} bold>7일 무료 체험</WFText>
          </WFRow>
        </WFCard>

        <WFCard pad={10}>
          <WFRow>
            <div style={{ flex: 1 }}>
              <WFText size={13} bold>VIP</WFText>
              <div/>
              <WFText size={10} color={WF.inkSoft}>₩ 29,900 / 월 · 1:1 상담 포함</WFText>
            </div>
          </WFRow>
        </WFCard>

        <div style={{ flex: 1 }}/>
        <WFButton primary danger>프리미엄 시작하기</WFButton>
        <WFText size={9} color={WF.inkFaint} style={{ textAlign: 'center' }}>
          구독은 언제든 해지할 수 있어요
        </WFText>
      </div>
    </WFScreen>
  );
}

// ─────────────── PAYWALL (preview + pay) ───────────────
function ScrPaywall() {
  return (
    <WFScreen>
      <WFHeader title=""/>
      <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {/* Preview content */}
        <div style={{ flex: 1, padding: 16, position: 'relative', overflow: 'hidden' }}>
          <WFText size={18} bold>6개월 금전운 리포트</WFText>
          <div style={{ height: 10 }}/>
          <WFText size={11}>
            5월은 기반을 다지는 시기.{'\n'}
            6월 중순 이후 재물 흐름이{'\n'}
            점차 강해집니다.{'\n\n'}
            특히 7월에는...
          </WFText>
          {/* fade overlay */}
          <div style={{
            position: 'absolute', left: 0, right: 0, bottom: 0, height: 200,
            background: 'linear-gradient(transparent, rgba(250,250,247,0.95) 60%, rgba(250,250,247,1))',
          }}/>
        </div>

        {/* sticky CTA sheet */}
        <div style={{
          borderTop: `1px solid ${WF.ink}`, padding: 16, background: WF.paper,
          display: 'flex', flexDirection: 'column', gap: 8,
        }}>
          <WFText size={13} bold style={{ textAlign: 'center' }}>
            🔒 나머지 내용은 프리미엄에서
          </WFText>
          <WFText size={10} color={WF.inkSoft} style={{ textAlign: 'center' }}>
            7일 무료 체험 · 언제든 해지
          </WFText>
          <WFButton primary danger>프리미엄 시작하기 · ₩9,900/월</WFButton>
          <WFText size={10} color={WF.inkFaint} style={{ textAlign: 'center' }}>요금제 비교</WFText>
        </div>
      </div>
    </WFScreen>
  );
}

// ─────────────── MY PAGE ───────────────
function ScrMyPage() {
  return (
    <WFScreen>
      <WFStatusSpacer/>
      <div style={{ flex: 1, overflow: 'hidden', padding: '8px 16px 12px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <WFText size={20} bold>마이</WFText>

        <WFCard pad={12}>
          <WFRow>
            <WFCircle size={44}/>
            <div style={{ flex: 1 }}>
              <WFText size={14} bold>지민</WFText>
              <div/>
              <WFText size={10} color={WF.inkSoft}>신중한 탐험가 · 무료</WFText>
            </div>
            <WFBadge accent>업그레이드</WFBadge>
          </WFRow>
        </WFCard>

        {[
          '내 사주 정보',
          '투자 성향 다시 보기',
          '쿠폰함',
          '구독 관리',
          '알림 설정',
          '이용약관 · 개인정보',
          '로그아웃',
        ].map((s, i) => (
          <WFRow key={s} style={{ padding: '12px 4px', borderBottom: `0.5px solid ${WF.inkFaint}` }}>
            <WFText size={12}>{s}</WFText>
            <div style={{ flex: 1 }}/>
            <WFText size={12} color={WF.inkFaint}>›</WFText>
          </WFRow>
        ))}
      </div>
      <WFTabBar active={4}/>
    </WFScreen>
  );
}

Object.assign(window, {
  ScrReferral, ScrCoupons, ScrSubscription, ScrPaywall, ScrMyPage,
});
