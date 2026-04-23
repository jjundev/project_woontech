// Screens 01: Splash, Onboarding, Signup, Saju Input (stepped, one info per screen)

function ScrSplash() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center', padding: 24, gap: 40 }}>
      <WPlaceholder w={100} h={100} label="LOGO" />
      <div style={{ textAlign: 'center' }}>
        <WText size={18} weight={700}>운테크</WText>
        <div style={{ marginTop: 6 }}>
          <WText size={11} color={WF.muted}>오늘의 투자 태도를 점검하세요</WText>
        </div>
      </div>
      <div style={{ width: 24, height: 24, border: `2px solid ${WF.line3}`,
        borderTopColor: WF.ink, borderRadius: '50%' }}/>
    </div>
  );
}

function ScrOnboarding({ step = 1 }) {
  const content = [
    { t: '내 사주로 투자 성향 진단', s: '생년월일시를 입력하면\n나만의 투자 성향을 알려드려요' },
    { t: '매일 바뀌는 내 투자 리스크 점검', s: '오늘 나의 투자 감정과 리스크를\n사주 기반으로 점검해드려요' },
    { t: '실전 전에 모의 투자', s: '내 성향과 오늘의 흐름으로\n부담 없이 연습해보세요' },
  ][step - 1];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', padding: '20px 20px 16px', boxSizing: 'border-box' }}>
      <div style={{ alignSelf: 'flex-end' }}>
        <WText size={11} color={WF.muted}>건너뛰기</WText>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', gap: 14, minHeight: 0 }}>
        <WPlaceholder w={140} h={140} label={`일러스트 ${step}`} />
        <div style={{ textAlign: 'center' }}>
          <WText size={16} weight={700}>{content.t}</WText>
          <div style={{ marginTop: 8, whiteSpace: 'pre-line' }}>
            <WText size={11} color={WF.muted}>{content.s}</WText>
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginBottom: 14 }}>
        {[1,2,3].map(i => (
          <div key={i} style={{
            width: i === step ? 16 : 6, height: 6, borderRadius: 3,
            background: i === step ? WF.ink : WF.gray2,
          }}/>
        ))}
      </div>
      {step === 3 && (
        <div style={{ marginBottom: 10 }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, padding: '10px 0' }}>
            <div style={{ width: 16, height: 16, border: `1.5px solid ${WF.ink}`, borderRadius: 3, marginTop: 1, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: WF.ink }}>
              <svg width="10" height="8" viewBox="0 0 10 8"><path d="M1 4L3.5 6.5L9 1" stroke="#fff" strokeWidth="1.4" fill="none"/></svg>
            </div>
            <WText size={10} color={WF.ink} style={{ whiteSpace: 'pre-line' }}>{'본 앱은 학습·참고용이며 투자 권유가 아닙니다.\n'}</WText>
          </div>
        </div>
      )}
      <WButton primary>{step === 3 ? '시작하기' : '다음'}</WButton>
      {step === 3 && (
        <div style={{ textAlign: 'center', marginTop: 8 }}>
          <WText size={8} color={WF.muted}>투자 결정은 본인 판단과 책임 하에 이루어져야 합니다</WText>
        </div>
      )}
      <div style={{ height: 20 }}/>
    </div>
  );
}

function ScrSignup() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <WHeader title="시작하기" back />
      <div style={{ padding: 20, display: 'flex', flexDirection: 'column', flex: 1 }}>
        <div style={{ textAlign: 'center', padding: '20px 0 28px' }}>
          <WPlaceholder w={70} h={70} label="LOGO" style={{ margin: '0 auto' }}/>
          <div style={{ marginTop: 14 }}>
            <WText size={15} weight={700}>3초 만에 시작하기</WText>
          </div>
          <div style={{ marginTop: 6 }}>
            <WText size={11} color={WF.muted}>결과 저장을 위해 가입이 필요해요</WText>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <WButton primary h={48} style={{ position: 'relative', justifyContent: 'center' }}>
            <div style={{ position: 'absolute', left: 14, width: 18, height: 18, border: `1.2px solid #fff`, borderRadius: 3 }}/>
            카카오로 계속하기
          </WButton>
          <WButton h={48} style={{ position: 'relative', justifyContent: 'center' }}>
            <div style={{ position: 'absolute', left: 14, width: 18, height: 18, border: `1.2px solid ${WF.line2}`, borderRadius: 9 }}/>
            Google로 계속하기
          </WButton>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ textAlign: 'center', marginBottom: 8 }}>
          <WText size={11} color={WF.muted}>이메일로 가입 </WText>
          <WText size={11} weight={600} style={{ textDecoration: 'underline' }}>여기</WText>
        </div>
        <div style={{ padding: '12px 0', borderTop: `1px solid ${WF.line3}`, textAlign: 'center' }}>
          <WText size={11} weight={600} color={WF.muted}>게스트로 먼저 체험하기 →</WText>
          <div style={{ marginTop: 4 }}>
            <WText size={9} color={WF.muted}>단, 결과는 저장되지 않아요</WText>
          </div>
        </div>
        <div style={{ textAlign: 'center', marginTop: 8 }}>
          <WText size={9} color={WF.muted}>계속 진행 시 이용약관 및 개인정보 처리방침에 동의합니다.</WText>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────
// Saju input — one piece of info per screen (6 steps)
// ─────────────────────────────────────────────────

const TOTAL_STEPS = 6;

function StepShell({ step, title, hint, children, ctaLabel = '다음' }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <WHeader title={`${step} / ${TOTAL_STEPS}`} back />
      <div style={{ height: 3, background: WF.gray }}>
        <div style={{ width: `${(step/TOTAL_STEPS)*100}%`, height: '100%', background: WF.ink }}/>
      </div>
      <div style={{ padding: '32px 20px 20px', display: 'flex', flexDirection: 'column', gap: 22, flex: 1 }}>
        <div>
          <WText size={17} weight={700}>{title}</WText>
          {hint && (
            <div style={{ marginTop: 6 }}>
              <WText size={11} color={WF.muted}>{hint}</WText>
            </div>
          )}
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'flex-start' }}>
          {children}
        </div>
        <WButton primary>{ctaLabel}</WButton>
      </div>
    </div>
  );
}

// Step 1 — 성별
function ScrSajuStep1() {
  return (
    <StepShell step={1} title="성별을 선택해주세요" hint="사주 해석의 기본 정보예요">
      <div style={{ display: 'flex', gap: 10 }}>
        <WBox style={{ flex: 1, height: 80, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 10, background: WF.gray, borderColor: WF.ink, borderWidth: 1.5 }}>
          <WText size={18} weight={700}>남</WText>
        </WBox>
        <WBox style={{ flex: 1, height: 80, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 10 }}>
          <WText size={18} color={WF.muted}>여</WText>
        </WBox>
      </div>
    </StepShell>
  );
}

// Step 2 — 이름
function ScrSajuStep2() {
  return (
    <StepShell step={2} title="이름을 알려주세요" hint="사주 리포트에 표시됩니다">
      <div>
        <WBox style={{ height: 52, display: 'flex', alignItems: 'center', padding: '0 16px', borderRadius: 8 }}>
          <WText size={15} weight={600}>홍길동</WText>
          <div style={{ flex: 1 }}/>
          <div style={{ width: 1, height: 18, background: WF.ink }}/>
        </WBox>
        <div style={{ marginTop: 8 }}>
          <WText size={10} color={WF.muted}>* 본명이 아니어도 괜찮아요</WText>
        </div>
      </div>
    </StepShell>
  );
}

// Step 3 — 생년월일 (wheel picker only, single focus)
function ScrSajuStep3() {
  return (
    <StepShell step={3} title="언제 태어나셨나요?" hint="사주 분석의 가장 중요한 정보예요">
      <div>

        <div style={{ display: 'flex', gap: 10, marginBottom: 14 }}>
          <WBox style={{ flex: 1, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 20, background: WF.ink }}>
            <WText size={11} weight={600} color="#fff">양력</WText>
          </WBox>
          <WBox style={{ flex: 1, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 20 }}>
            <WText size={11} color={WF.muted}>음력</WText>
          </WBox>
        </div>
        {/* 3-column wheel picker */}
        <WBox style={{ height: 220, borderRadius: 12, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: 42,
            transform: 'translateY(-50%)', borderTop: `1px solid ${WF.line3}`,
            borderBottom: `1px solid ${WF.line3}`, background: WF.gray }}/>
          <div style={{ position: 'absolute', inset: 0, display: 'grid', gridTemplateColumns: '1.4fr 1fr 1fr' }}>
            {[
              [1988, 1989, 1990, 1991, 1992],
              ['01월', '02월', '03월', '04월', '05월'],
              ['13일', '14일', '15일', '16일', '17일'],
            ].map((col, ci) => (
              <div key={ci} style={{ display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center', gap: 6 }}>
                {col.map((v, i) => (
                  <WText key={i} size={i === 2 ? 17 : 12} weight={i === 2 ? 700 : 400}
                    color={i === 2 ? WF.ink : WF.muted}>{v}</WText>
                ))}
              </div>
            ))}
          </div>
        </WBox>
      </div>
    </StepShell>
  );
}

// Step 4 — 태어난 시간
function ScrSajuStep4() {
  return (
    <StepShell step={4} title="몇 시에 태어나셨나요?" hint="시주는 사주의 네 기둥 중 하나예요">
      <div>
        <WBox style={{ height: 200, borderRadius: 12, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: 42,
            transform: 'translateY(-50%)', borderTop: `1px solid ${WF.line3}`,
            borderBottom: `1px solid ${WF.line3}`, background: WF.gray }}/>
          <div style={{ position: 'absolute', inset: 0, display: 'grid', gridTemplateColumns: '1fr 1fr' }}>
            {[
              ['12시', '13시', '14시', '15시', '16시'],
              ['00분', '15분', '30분', '45분', '50분'],
            ].map((col, ci) => (
              <div key={ci} style={{ display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center', gap: 6 }}>
                {col.map((v, i) => (
                  <WText key={i} size={i === 2 ? 17 : 12} weight={i === 2 ? 700 : 400}
                    color={i === 2 ? WF.ink : WF.muted}>{v}</WText>
                ))}
              </div>
            ))}
          </div>
        </WBox>

        {/* 시간 모르겠어요 체크 + 신뢰도 시그널 */}
        <div style={{ marginTop: 14 }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
            <div style={{ width: 16, height: 16, border: `1.3px solid ${WF.line2}`, borderRadius: 3, marginTop: 2, flexShrink: 0 }}/>
            <WText size={11} color={WF.muted} style={{ whiteSpace: 'pre-line' }}>시간을 모르겠어요{'\n'}(시주 없이 3주 기반 분석, 나중에 업데이트 가능)</WText>
          </div>

        </div>
      </div>
    </StepShell>
  );
}

// Step 5 — 출생지 (city search, one focus)
function ScrSajuStep5() {
  return (
    <StepShell step={5} title="어디서 태어나셨나요?" hint="진태양시 보정에 사용돼요">
      <div>
        <WBox style={{ height: 48, display: 'flex', alignItems: 'center', padding: '0 14px', borderRadius: 8, gap: 10 }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <circle cx="7" cy="7" r="5" stroke={WF.muted} strokeWidth="1.3"/>
            <path d="M11 11L15 15" stroke={WF.muted} strokeWidth="1.3" strokeLinecap="round"/>
          </svg>
          <WText size={12}>서울특별시</WText>
          <div style={{ flex: 1 }}/>
          <div style={{ width: 1, height: 18, background: WF.ink }}/>
        </WBox>
        <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column' }}>
          {['서울특별시', '부산광역시', '인천광역시', '대구광역시', '광주광역시', '대전광역시'].map((t, i) => (
            <div key={t} style={{ padding: '12px 4px', borderBottom: i < 3 ? `1px solid ${WF.line3}` : 'none', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <WText size={12} weight={i === 0 ? 600 : 400} color={i === 0 ? WF.ink : WF.muted}>{t}</WText>
              {i === 0 && (
                <svg width="14" height="11" viewBox="0 0 14 11" fill="none">
                  <path d="M1 5.5L5 9.5L13 1.5" stroke={WF.ink} strokeWidth="1.5" strokeLinecap="round"/>
                </svg>
              )}
            </div>
          ))}
        </div>
        <div style={{ marginTop: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 16, height: 16, border: `1.3px solid ${WF.line2}`, borderRadius: 3 }}/>
          <WText size={11} color={WF.muted}>국외 출생 (경도 직접 입력)</WText>
        </div>
      </div>
    </StepShell>
  );
}

// Step 6 — 진태양시 보정 확인
function ScrSajuStep6() {
  const [showPopup, setShowPopup] = React.useState(false);
  return (
    <StepShell step={6} title="진태양시로 보정할까요?" hint="표준시와 실제 태양시의 차이를 보정해요" ctaLabel="사주 분석 시작">
      <div style={{ position: 'relative' }}>
        {/* 도움말 링크 */}
        <div style={{ marginBottom: 12 }}>
          <WText size={10} color={WF.muted} style={{ textDecoration: 'underline', cursor: 'pointer' }}
            onClick={() => setShowPopup(true)}>진태양시가 뭔가요? →</WText>
        </div>
        {/* toggle row */}
        <WBox style={{ padding: '16px 14px', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ flex: 1 }}>
            <WText size={13} weight={700}>진태양시 보정</WText>
            <div style={{ marginTop: 4 }}>
              <WText size={10} color={WF.muted}>정확한 분석을 위해 권장</WText>
            </div>
          </div>
          <div style={{ width: 40, height: 24, borderRadius: 12, background: WF.ink, position: 'relative', flexShrink: 0 }}>
            <div style={{ position: 'absolute', top: 2, right: 2, width: 20, height: 20, borderRadius: 10, background: '#fff' }}/>
          </div>
        </WBox>

        {/* calculated preview */}
        <WBox style={{ marginTop: 10, padding: '14px 14px', borderRadius: 10, background: WF.gray }}>
          <WText size={10} color={WF.muted}>계산 결과</WText>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <WText size={11} color={WF.muted}>경도</WText>
              <WText size={11} weight={600}>126.9780° E</WText>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <WText size={11} color={WF.muted}>표준시 차이</WText>
              <WText size={11} weight={600}>−32분</WText>
            </div>
            <div style={{ height: 1, background: WF.line3, margin: '4px 0' }}/>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <WText size={11} color={WF.muted}>보정된 출생시</WText>
              <WText size={12} weight={700}>13:28</WText>
            </div>
          </div>
        </WBox>

        {/* 진태양시 설명 팝업 */}
        {showPopup && (
          <div style={{
            position: 'absolute', inset: 0, zIndex: 100,
            background: 'rgba(0,0,0,0.45)', borderRadius: 12,
            display: 'flex', alignItems: 'flex-end',
          }} onClick={() => setShowPopup(false)}>
            <div style={{
              width: '100%', background: '#fff', borderRadius: '14px 14px 0 0',
              padding: '20px 18px 24px',
            }} onClick={e => e.stopPropagation()}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <WText size={14} weight={700}>진태양시(眞太陽時)란?</WText>
                <div style={{ cursor: 'pointer', padding: '0 4px' }} onClick={() => setShowPopup(false)}>
                  <WText size={13} color={WF.muted}>✕</WText>
                </div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <div style={{ padding: '10px 12px', background: WF.gray, borderRadius: 8 }}>
                  <WText size={10} style={{ lineHeight: 1.6 }}>
                    우리가 쓰는 <b>표준시(KST)</b>는 동경 135°를 기준으로 맞춰져 있어요. 하지만 실제 태양이 남중(정오)하는 시각은 출생 지역의 경도에 따라 달라집니다.
                  </WText>
                </div>
                <div style={{ padding: '10px 12px', background: WF.gray, borderRadius: 8 }}>
                  <WText size={10} style={{ lineHeight: 1.6 }}>
                    예를 들어 서울(경도 126.97°)은 기준 경도보다 약 <b>8.03° 서쪽</b>에 있어, 표준시보다 약 <b>−32분</b> 차이가 납니다.
                  </WText>
                </div>
                <div style={{ padding: '10px 12px', background: WF.gray, borderRadius: 8 }}>
                  <WText size={10} style={{ lineHeight: 1.6 }}>
                    사주 명리학은 <b>실제 태양의 움직임</b>을 기준으로 하기 때문에, 이 보정을 적용하면 더 정확한 사주 원국을 얻을 수 있어요.
                  </WText>
                </div>
                <div style={{ marginTop: 4 }}>
                  <WText size={9} color={WF.muted}>※ 보정 적용 여부는 언제든 변경할 수 있습니다.</WText>
                </div>
              </div>
              <div style={{ marginTop: 16, padding: '10px', background: WF.ink, borderRadius: 8, textAlign: 'center', cursor: 'pointer' }}
                onClick={() => setShowPopup(false)}>
                <WText size={12} weight={600} color="#fff">확인</WText>
              </div>
            </div>
          </div>
        )}
      </div>
    </StepShell>
  );
}

// ─────────────────────────────────────────────────
// 공유 카드 컴포넌트 (ShareCard)
// ─────────────────────────────────────────────────
function ShareCard({ compact = false }) {
  const sz = compact ? 0.72 : 1;
  return (
    <div style={{
      width: 240 * sz, background: WF.ink, borderRadius: 14 * sz,
      padding: `${20 * sz}px`, boxSizing: 'border-box', color: '#fff',
      fontFamily: WF.kfont, position: 'relative', overflow: 'hidden',
    }}>
      {/* 배경 패턴 */}
      <div style={{ position: 'absolute', top: -20, right: -20, width: 120 * sz, height: 120 * sz,
        borderRadius: '50%', border: `1px solid rgba(255,255,255,0.12)` }}/>
      <div style={{ position: 'absolute', top: 10, right: 10, width: 70 * sz, height: 70 * sz,
        borderRadius: '50%', border: `1px solid rgba(255,255,255,0.08)` }}/>
      {/* 앱명 */}
      <div style={{ fontSize: 10 * sz, opacity: 0.6, marginBottom: 16 * sz }}>운테크 · 투자 성향 카드</div>
      {/* 유형 */}
      <div style={{ fontSize: 18 * sz, fontWeight: 700, lineHeight: 1.2, marginBottom: 6 * sz }}>
        "단단한 수집가형"
      </div>
      <div style={{ fontSize: 11 * sz, opacity: 0.7, marginBottom: 16 * sz }}>
        경금(庚金) 일주 · 정재 중심
      </div>
      {/* 오행 미니 바 */}
      <div style={{ display: 'flex', gap: 3 * sz, marginBottom: 16 * sz }}>
        {[['木','15%'],['火','38%'],['土','15%'],['金','32%'],['水','0%']].map(([e, w]) => (
          <div key={e} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>
            <div style={{ width: '100%', height: 3 * sz, background: 'rgba(255,255,255,0.2)', borderRadius: 2, overflow: 'hidden' }}>
              <div style={{ width: w, height: '100%', background: w === '0%' ? 'rgba(255,255,255,0.1)' : '#fff' }}/>
            </div>
            <span style={{ fontSize: 8 * sz, opacity: 0.5 }}>{e}</span>
          </div>
        ))}
      </div>
      {/* 한 줄 설명 */}
      <div style={{ fontSize: 10 * sz, opacity: 0.65, lineHeight: 1.45 }}>
        "꼼꼼하고 안정을 추구하는 기질.<br/>무모한 베팅보다 분산이 더 잘 맞아요."
      </div>
      {/* 하단 */}
      <div style={{ marginTop: 16 * sz, paddingTop: 12 * sz, borderTop: '1px solid rgba(255,255,255,0.15)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 9 * sz, opacity: 0.5 }}>운테크.app</span>
        <span style={{ fontSize: 9 * sz, opacity: 0.5 }}>2026.04.23</span>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────
// 친구 초대 — 공유 카드 미리보기 + 인스타 스토리 버튼
// ─────────────────────────────────────────────────
function ScrReferral() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="친구 초대" back right={<WText size={10} color={WF.muted}>내 코드: YA7X2</WText>}/>
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 16px 20px', display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* 혜택 배너 */}
        <WCard style={{ padding: 14 }}>
          <WText size={11} weight={700}>친구 초대 혜택</WText>
          <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 4 }}>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <div style={{ padding: '2px 7px', border: `1px solid ${WF.line2}`, borderRadius: 10, background: WF.gray }}>
                <WText size={9} weight={700}>나</WText>
              </div>
              <WText size={11}>가입 완료 쿠폰 5,000원</WText>
            </div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <div style={{ padding: '2px 7px', border: `1px solid ${WF.ink}`, borderRadius: 10, background: WF.ink }}>
                <WText size={9} weight={700} color="#fff">친구</WText>
              </div>
              <WText size={11}>초대 보상 1,000P</WText>
            </div>
          </div>
        </WCard>

        {/* ★ 공유 카드 미리보기 */}
        <div>
          <WSectionLabel>내 사주 카드 미리보기</WSectionLabel>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 10 }}>
            <ShareCard compact />
          </div>
          <div style={{ marginTop: 4, textAlign: 'center' }}>
            <WText size={9} color={WF.muted}>친구에게 공유할 카드 디자인</WText>
          </div>
        </div>

        {/* 공유 방법 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <WButton primary h={44} style={{ justifyContent: 'center' }}>
            인스타그램 스토리로 공유
          </WButton>
          <WButton h={44} style={{ justifyContent: 'center' }}>
            링크 복사하기
          </WButton>
          <WButton h={44} style={{ justifyContent: 'center' }}>
            카카오톡으로 공유
          </WButton>
        </div>

        {/* 내 초대 코드 */}
        <WCard style={{ padding: 12 }}>
          <WText size={10} color={WF.muted}>내 초대 코드</WText>
          <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <WText size={20} weight={700} style={{ letterSpacing: 3 }}>YA7X2</WText>
            <WBox style={{ padding: '6px 12px', borderRadius: 6, background: WF.gray }}>
              <WText size={10} weight={600}>복사</WText>
            </WBox>
          </div>
          <div style={{ marginTop: 6 }}>
            <WText size={9} color={WF.muted}>초대한 친구: 3명 · 받은 보상: 3,000P</WText>
          </div>
        </WCard>
      </div>
    </div>
  );
}

// Keep legacy names as aliases so HTML references still resolve
const ScrSajuInputB = ScrSajuStep3;
const ScrSajuInputLocation = ScrSajuStep5;

Object.assign(window, {
  ScrSplash, ScrOnboarding, ScrSignup,
  ScrSajuStep1, ScrSajuStep2, ScrSajuStep3, ScrSajuStep4, ScrSajuStep5, ScrSajuStep6,
  ScrSajuInputB, ScrSajuInputLocation,
  ShareCard, ScrReferral,
});
