// Onboarding, auth, referral code, saju input screens

// ─────────────── SPLASH ───────────────
function ScrSplash() {
  return (
    <WFScreen>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 20, padding: 24 }}>
        <WFCircle size={90}/>
        <WFText size={22} bold>[앱 로고]</WFText>
        <WFText size={13} color={WF.inkSoft} italic>사주로 시작하는 재테크</WFText>
        <div style={{ marginTop: 30 }}>
          <WFMono>· · ·  loading  · · ·</WFMono>
        </div>
      </div>
    </WFScreen>
  );
}

// ─────────────── ONBOARDING (3 pages) ───────────────
function ScrOnboarding() {
  return (
    <WFScreen>
      <div style={{ padding: '20px 20px 0', textAlign: 'right' }}>
        <WFText size={12} color={WF.inkSoft}>건너뛰기 ›</WFText>
      </div>
      <div style={{ flex: 1, padding: 24, display: 'flex', flexDirection: 'column', gap: 16 }}>
        <WFPlaceholder h={180} label="온보딩 일러스트 1/3"/>
        <WFText size={20} bold>내 사주로 찾는{'\n'}투자 성향</WFText>
        <WFText size={13} color={WF.inkSoft}>
          생년월일 하나로 나에게 맞는{'\n'}투자 공부의 방향을 알려드려요
        </WFText>
        <div style={{ flex: 1 }}/>
        {/* dots */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, margin: '8px 0' }}>
          <div style={{ width: 18, height: 4, background: WF.ink, borderRadius: 2 }}/>
          <div style={{ width: 4, height: 4, background: WF.inkFaint, borderRadius: 2 }}/>
          <div style={{ width: 4, height: 4, background: WF.inkFaint, borderRadius: 2 }}/>
        </div>
        <WFButton primary>다음</WFButton>
      </div>
    </WFScreen>
  );
}

// ─────────────── SIGNUP / LOGIN ───────────────
function ScrSignup() {
  return (
    <WFScreen>
      <WFHeader title="시작하기" back={false}/>
      <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 14 }}>
        <WFText size={18} bold>환영합니다</WFText>
        <WFText size={12} color={WF.inkSoft}>간편 로그인으로 시작하세요</WFText>

        <div style={{ height: 20 }}/>

        {['카카오로 시작하기', '애플로 시작하기', '이메일로 시작하기'].map((t, i) => (
          <div key={t} style={{
            border: `1px solid ${WF.ink}`, padding: '14px 16px',
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{ width: 20, height: 20, border: `1px solid ${WF.ink}`, borderRadius: 4 }}/>
            <WFText size={14}>{t}</WFText>
          </div>
        ))}

        <div style={{ flex: 1 }}/>
        <WFText size={10} color={WF.inkFaint} style={{ textAlign: 'center' }}>
          가입 시 이용약관 / 개인정보 처리방침 동의
        </WFText>
      </div>
    </WFScreen>
  );
}

// ─────────────── REFERRAL CODE ───────────────
function ScrReferralCode() {
  return (
    <WFScreen>
      <WFHeader title="추천인 코드"/>
      <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 14 }}>
        <WFText size={18} bold>추천인 코드가 있으신가요?</WFText>
        <WFText size={12} color={WF.inkSoft}>
          입력하시면 양쪽 모두 쿠폰을 받아요
        </WFText>

        <div style={{ height: 10 }}/>

        <WFBox style={{ padding: 16 }}>
          <WFMono color={WF.inkFaint}>코드 6자리 입력</WFMono>
          <div style={{ display: 'flex', gap: 6, marginTop: 10 }}>
            {[0,1,2,3,4,5].map(i => (
              <div key={i} style={{
                flex: 1, height: 40, border: `1px solid ${WF.ink}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: WF.hand, fontSize: 18,
              }}>{i < 2 ? 'A' : ''}</div>
            ))}
          </div>
        </WFBox>

        <WFCard title="이렇게 받아요" pad={10}>
          <WFRow><WFBadge>나</WFBadge><WFText size={11}>가입 완료 쿠폰 5,000원</WFText></WFRow>
          <div style={{ height: 4 }}/>
          <WFRow><WFBadge accent>친구</WFBadge><WFText size={11}>초대 보상 1,000P</WFText></WFRow>
        </WFCard>

        <div style={{ flex: 1 }}/>
        <WFButton>건너뛰기</WFButton>
        <WFButton primary>코드 적용하기</WFButton>
      </div>
    </WFScreen>
  );
}

// ─────────────── SAJU INPUT — SINGLE SCREEN (A) ───────────────
function ScrSajuInputSingle() {
  return (
    <WFScreen>
      <WFHeader title="사주 정보"/>
      <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 14, flex: 1 }}>
        <WFText size={18} bold>정확한 분석을 위해{'\n'}아래 정보를 입력해주세요</WFText>

        {/* 생년월일 */}
        <div>
          <WFText size={11} color={WF.inkSoft}>생년월일</WFText>
          <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
            <WFBox style={{ flex: 1, padding: '10px 12px' }}><WFMono>YYYY</WFMono></WFBox>
            <WFBox style={{ flex: 1, padding: '10px 12px' }}><WFMono>MM</WFMono></WFBox>
            <WFBox style={{ flex: 1, padding: '10px 12px' }}><WFMono>DD</WFMono></WFBox>
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
            <WFBox style={{ flex: 1, padding: '6px 10px', textAlign: 'center', background: WF.ink, color: WF.paper }}>
              <WFText size={11} color={WF.paper}>양력</WFText>
            </WFBox>
            <WFBox style={{ flex: 1, padding: '6px 10px', textAlign: 'center' }}>
              <WFText size={11}>음력</WFText>
            </WFBox>
          </div>
        </div>

        {/* 출생시간 */}
        <div>
          <WFText size={11} color={WF.inkSoft}>출생시간</WFText>
          <WFBox style={{ padding: '10px 12px', marginTop: 4, display: 'flex', justifyContent: 'space-between' }}>
            <WFMono>HH : MM</WFMono>
            <WFText size={11} color={WF.accent}>모름 ▢</WFText>
          </WFBox>
        </div>

        {/* 성별 */}
        <div>
          <WFText size={11} color={WF.inkSoft}>성별</WFText>
          <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
            <WFBox style={{ flex: 1, padding: '10px', textAlign: 'center' }}><WFText>여성</WFText></WFBox>
            <WFBox style={{ flex: 1, padding: '10px', textAlign: 'center' }}><WFText>남성</WFText></WFBox>
          </div>
        </div>

        <div style={{ flex: 1 }}/>
        <WFText size={10} color={WF.inkFaint}>🔒 정보는 분석에만 사용되며 암호화됩니다</WFText>
        <WFButton primary>다음 · 분석 시작</WFButton>
      </div>
    </WFScreen>
  );
}

// ─────────────── SAJU INPUT — STEPPED (B) — Step 1 of 3 ───────────────
function ScrSajuInputStep() {
  return (
    <WFScreen>
      <div style={{ padding: '10px 16px 0' }}>
        <WFRow>
          <WFText size={12} color={WF.inkSoft}>‹</WFText>
          <div style={{ flex: 1 }}><WFProgress value={0.33}/></div>
          <WFMono>1/3</WFMono>
        </WFRow>
      </div>
      <div style={{ padding: 24, flex: 1, display: 'flex', flexDirection: 'column', gap: 14 }}>
        <WFText size={22} bold>언제 태어나셨나요?</WFText>
        <WFText size={12} color={WF.inkSoft}>생년월일을 알려주세요</WFText>

        <div style={{ height: 20 }}/>

        <WFPlaceholder h={200} label="휠 데이트피커"/>

        <div style={{ display: 'flex', gap: 6 }}>
          <WFBox style={{ flex: 1, padding: '8px', textAlign: 'center', background: WF.ink, color: WF.paper }}>
            <WFText size={11} color={WF.paper}>양력</WFText>
          </WFBox>
          <WFBox style={{ flex: 1, padding: '8px', textAlign: 'center' }}>
            <WFText size={11}>음력</WFText>
          </WFBox>
        </div>

        <div style={{ flex: 1 }}/>
        <WFButton primary>다음</WFButton>
      </div>
    </WFScreen>
  );
}

Object.assign(window, {
  ScrSplash, ScrOnboarding, ScrSignup, ScrReferralCode,
  ScrSajuInputSingle, ScrSajuInputStep,
});
