// Saju-accurate screens — based on algorithm_of_saju.md
// Upgrades: 4-pillar chart (사주 원국), 십성 (Ten Gods), 합충 (harmony/clash)
// Per-category scores (재물/애정/직장/건강), empty-state for time-unknown

// ───────── 4-Pillar chart component (사주 원국) ─────────
// Layout: 時 日 月 年 (right to left, traditional order)
// Each pillar: 천간(top) / 지지(bottom) with 오행 label
function SajuChart({ compact = false, highlight = 'day', noHour = false }) {
  const pillars = [
    noHour
      ? { p: '시주', pHan: '時', gan: '?', ji: '?', ganEl: '-', jiEl: '-', gName: '미입력', jName: '', unknown: true }
      : { p: '시주', pHan: '時', gan: '丁', ji: '巳', ganEl: '화', jiEl: '화', gName: '정', jName: '사' },
    { p: '일주', pHan: '日', gan: '庚', ji: '申', ganEl: '금', jiEl: '금', gName: '경', jName: '신', day: true },
    { p: '월주', pHan: '月', gan: '己', ji: '卯', ganEl: '토', jiEl: '목', gName: '기', jName: '묘' },
    { p: '년주', pHan: '年', gan: '庚', ji: '午', ganEl: '금', jiEl: '화', gName: '경', jName: '오' },
  ];
  const cell = compact ? 38 : 50;
  const fs = compact ? 16 : 20;
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 4 }}>
      {pillars.map(x => (
        <div key={x.p} style={{ textAlign: 'center' }}>
          <WText size={9} color={WF.muted}>{x.p}</WText>
          <div style={{ marginTop: 1 }}><WText size={7} color={WF.muted}>{x.pHan}</WText></div>
          {/* 천간 */}
          <WBox style={{
            height: cell, marginTop: 3, display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
            background: x.unknown ? WF.gray : (x.day && highlight === 'day' ? WF.ink : '#fff'),
            borderColor: x.unknown ? WF.line2 : (x.day && highlight === 'day' ? WF.ink : WF.line2),
            borderStyle: x.unknown ? 'dashed' : 'solid',
            borderRadius: 4,
          }}>
            <span style={{ fontSize: fs, fontWeight: 700, fontFamily: 'serif',
              color: x.unknown ? WF.muted : (x.day && highlight === 'day' ? '#fff' : WF.ink), lineHeight: 1 }}>{x.gan}</span>
            {!compact && <span style={{ fontSize: 7, color: x.unknown ? WF.muted : (x.day && highlight === 'day' ? 'rgba(255,255,255,0.7)' : WF.muted), marginTop: 2 }}>{x.ganEl}</span>}
          </WBox>
          {/* 지지 */}
          <WBox style={{
            height: cell, marginTop: 3, display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center', borderRadius: 4,
            background: x.unknown ? WF.gray : '#fff',
            borderStyle: x.unknown ? 'dashed' : 'solid',
          }}>
            <span style={{ fontSize: fs, fontWeight: 700, fontFamily: 'serif', color: x.unknown ? WF.muted : WF.ink, lineHeight: 1 }}>{x.ji}</span>
            {!compact && <span style={{ fontSize: 7, color: WF.muted, marginTop: 2 }}>{x.jiEl}</span>}
          </WBox>
          <div style={{ marginTop: 3 }}>
            <WText size={8} color={WF.muted}>{x.gName}{x.jName}</WText>
          </div>
        </div>
      ))}
    </div>
  );
}

// ───────── Updated: Today's detail with 사주 원국 + 십성 + 합충 ─────────
function ScrTodayDetailV2() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="오늘의 일진" back right={<WText size={10} color={WF.muted}>공유</WText>}/>
      <div style={{ padding: 14, overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>

        {/* 오늘의 금기 — 최상단 */}
        <WCard style={{ borderColor: '#c44' }}>
          <WSectionLabel style={{ color: '#c44' }}>오늘의 금기</WSectionLabel>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
            <WText size={14}>⚠️</WText>
            <WText size={11} weight={600}>추격매수</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={10} color={WF.muted}>오늘의 충·형살 기운으로 충동적 매수는 내 성향과 맞지 않아요</WText>
          </div>
        </WCard>

        {/* Score hero with per-category */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <WText size={9} color={WF.muted}>2026.04.22 · 일진</WText>
              <div style={{ marginTop: 2 }}>
                <WText size={14} weight={700}>경신일</WText>
                <span style={{ fontFamily: 'serif', fontSize: 11, color: WF.muted }}> (庚申) · 금 기운</span>
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <WText size={20} weight={700}>73</WText>
              <WText size={9} color={WF.muted}> / 100</WText>
              <div style={{ marginTop: 3 }}>
                <WText size={8} color={WF.muted} style={{ textDecoration: 'underline' }}>점수 근거 펼쳐보기 ›</WText>
              </div>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 6, marginTop: 12 }}>
            {[
              { t: '재물운', v: 68 },
              { t: '애정운', v: 82 },
              { t: '직장운', v: 54 },
              { t: '건강운', v: 75 },
            ].map(x => (
              <div key={x.t}>
                <WText size={9} color={WF.muted}>{x.t}</WText>
                <div style={{ marginTop: 4, height: 4, background: WF.gray, borderRadius: 2, overflow: 'hidden' }}>
                  <div style={{ width: `${x.v}%`, height: '100%', background: WF.ink }}/>
                </div>
                <div style={{ marginTop: 3 }}>
                  <WText size={10} weight={600}>{x.v}</WText>
                </div>
              </div>
            ))}
          </div>
        </WCard>

        {/* 오늘의 한 마디 — 사주 원국 상단 */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <WSectionLabel>오늘의 한 마디</WSectionLabel>
            <WText size={8} color={WF.muted}>AI 해석</WText>
          </div>
          <div style={{ marginTop: 6, padding: 10, background: WF.gray, borderRadius: 6 }}>
            <WText size={10} style={{ lineHeight: 1.5 }}>
              "오늘은 긴장의 날이에요. 직장에서 예상 밖의 압박이 올 수 있지만, 가까운 사람과의 유대는 오히려 깊어져요. 큰 결정보다 한 박자 쉬어가기를 참고해봐요."
            </WText>
          </div>
        </WCard>

        {/* 스크롤 힌트 */}
        <div style={{ textAlign: 'center', padding: '4px 0' }}>
          <WText size={9} color={WF.muted}>↓ 스크롤 — 사주 원국 · 십성 · 합충</WText>
        </div>

      </div>
    </div>
  );
}

// ───────── ScrPersonalityV2 — alias to ScrInvestmentPersonality ─────────
// Old two-screen flow (8+9) replaced by merged ScrInvestmentPersonality.
// Kept as alias for any stale references.
function ScrPersonalityV2() { return <ScrInvestmentPersonality />; }
function _ScrPersonalityV2_DEAD() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="나의 사주 원국" back right={<WText size={10} color={WF.muted}>공유</WText>}/>
      <div style={{ padding: 14, overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>

        {/* ★ 감탄 레이어 FIRST — 유형 카드 크게 */}
        <WCard style={{ textAlign: 'center', padding: '20px 14px' }}>
          <WText size={10} color={WF.muted}>당신의 투자 성향</WText>
          <div style={{ marginTop: 10 }}>
            <WText size={22} weight={700}>"단단한 수집가형"</WText>
          </div>
          <div style={{ marginTop: 6 }}>
            <WText size={12} color={WF.muted}>경금(庚金) 일주 · 정재 중심</WText>
          </div>
          <div style={{ marginTop: 12, padding: '8px 12px', background: WF.gray, borderRadius: 6 }}>
            <WText size={11}>"꼼꼼하고 안정을 추구하는 기질. 무모한 베팅보다 분산이 더 잘 맞아요."</WText>
          </div>
        </WCard>

        {/* 사주 원국 4주 차트 */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <WSectionLabel>사주 원국 (Natal Chart)</WSectionLabel>
            <WText size={9} color={WF.muted}>양력 1990.03.15 09:20</WText>
          </div>
          <div style={{ marginTop: 10 }}>
            <SajuChart />
          </div>
          <div style={{ marginTop: 10, padding: 8, background: WF.gray, borderRadius: 4, textAlign: 'center' }}>
            <WText size={9} color={WF.muted}>일간(日干) · 나</WText>
            <div style={{ marginTop: 2 }}>
              <WText size={14} weight={700}>경금 일주</WText>
              <span style={{ fontFamily: 'serif', fontSize: 10, color: WF.muted }}> (庚金)</span>
            </div>
          </div>
        </WCard>

        {/* 오행 분포 — 접힘 기본 */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <WSectionLabel style={{ marginBottom: 0 }}>오행(五行) 분포</WSectionLabel>
            <WText size={9} color={WF.muted}>펼치기 ▾</WText>
          </div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'flex-end', height: 80, marginTop: 12 }}>
            {[
              { e: '목', han: '木', h: 20, n: 1 },
              { e: '화', han: '火', h: 60, n: 3 },
              { e: '토', han: '土', h: 20, n: 1 },
              { e: '금', han: '金', h: 60, n: 3 },
              { e: '수', han: '水', h: 0, n: 0 },
            ].map(x => (
              <div key={x.e} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <WText size={9} weight={600}>{x.n}</WText>
                <div style={{ width: '70%', height: x.h || 2, background: x.h ? WF.ink : WF.gray2, borderRadius: 2 }}/>
                <div style={{ textAlign: 'center' }}>
                  <WText size={11} weight={700}>{x.e}</WText>
                  <div><span style={{ fontFamily: 'serif', fontSize: 8, color: WF.muted }}>{x.han}</span></div>
                </div>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 8, padding: 8, background: WF.gray, borderRadius: 4 }}>
            <WText size={10}><b>수(Water) 기운 부재</b> · 화·금 과다</WText>
            <div style={{ marginTop: 3 }}>
              <WText size={9} color={WF.muted}>치우칠 수 기운이 없어 충동적 판단 제어가 필요</WText>
            </div>
          </div>
        </WCard>

        {/* 십성 distribution */}
        <WCard>
          <WSectionLabel>십성(十星) 분포</WSectionLabel>
          <div style={{ marginTop: 8, display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 6 }}>
            {[
              { k: '비견', c: 1, d: '동료·경쟁' },
              { k: '정재', c: 2, d: '안정 수입', strong: true },
              { k: '편관', c: 1, d: '압박·승부' },
              { k: '정인', c: 1, d: '문서·학문' },
            ].map(x => (
              <WBox key={x.k} style={{ padding: 8, borderRadius: 4, background: x.strong ? WF.gray : '#fff' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <WText size={10} weight={700}>{x.k}</WText>
                  <WText size={9} color={WF.muted}>×{x.c}</WText>
                </div>
                <div style={{ marginTop: 2 }}>
                  <WText size={9} color={WF.muted}>{x.d}</WText>
                </div>
              </WBox>
            ))}
          </div>
          <div style={{ marginTop: 6 }}>
            <WText size={9} color={WF.muted}>정재 중심 → 꼼꼼하고 안정을 추구하는 기질</WText>
          </div>
        </WCard>

        {/* Type label */}
        <WCard style={{ textAlign: 'center', padding: 14 }}>
          <WText size={10} color={WF.muted}>당신의 유형</WText>
          <div style={{ marginTop: 6 }}>
            <WText size={16} weight={700}>"단단한 수집가형"</WText>
          </div>
          <div style={{ marginTop: 4 }}>
            <WText size={10} color={WF.muted}>경금 일주 · 정재 성향</WText>
          </div>
        </WCard>

        <WCard>
          <WSectionLabel>상세 성향 리포트</WSectionLabel>
          <WLocked>
            <WLine w="90%" style={{ marginTop: 8 }}/>
            <WLine w="70%" style={{ marginTop: 6 }}/>
            <WLine w="85%" style={{ marginTop: 6 }}/>
            <WLine w="60%" style={{ marginTop: 6 }}/>
          </WLocked>
        </WCard>

        <WCard>
          <WSectionLabel>대운(大運) · 10년 단위 흐름</WSectionLabel>
          <WLocked>
            <WPlaceholder h={60} label="대운 타임라인" style={{ marginTop: 6 }}/>
          </WLocked>
        </WCard>
      </div>
      <div style={{ padding: 14, borderTop: `1px solid ${WF.line3}`, background: '#fff' }}>
        <WButton primary>다음 — 투자 성향 확인하기</WButton>
      </div>
    </div>
  );
}

// ───────── New: Saju input with true-solar-time + birth location ─────────
function ScrSajuInputV2() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <WHeader title="사주 정보 입력" back />
      <div style={{ height: 3, background: WF.gray }}>
        <div style={{ width: '75%', height: '100%', background: WF.ink }}/>
      </div>
      <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 14, flex: 1, overflow: 'auto' }}>

        <WBox style={{ padding: 10, borderRadius: 6, background: WF.gray }}>
          <WText size={9} color={WF.muted}>정확도 안내</WText>
          <div style={{ marginTop: 3 }}>
            <WText size={10}>출생 지역의 경도·시차·균시차를 보정해 진태양시로 계산합니다.</WText>
          </div>
        </WBox>

        <div>
          <WText size={11} weight={600}>생년월일시</WText>
          <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
            <WBox style={{ flex: 1.4, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 6 }}>
              <WText size={12} weight={600}>1990.03.15</WText>
            </WBox>
            <WBox style={{ flex: 1, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 6 }}>
              <WText size={12} weight={600}>09:20</WText>
            </WBox>
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ width: 12, height: 12, borderRadius: 6, background: WF.ink }}/>
              <WText size={10}>양력</WText>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ width: 12, height: 12, borderRadius: 6, border: `1.3px solid ${WF.line2}` }}/>
              <WText size={10} color={WF.muted}>음력</WText>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ width: 12, height: 12, borderRadius: 6, border: `1.3px solid ${WF.line2}` }}/>
              <WText size={10} color={WF.muted}>윤달</WText>
            </div>
          </div>
        </div>

        {/* Unknown time fallback */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 12, height: 12, border: `1.3px solid ${WF.line2}`, borderRadius: 2 }}/>
            <WText size={10} color={WF.muted}>태어난 시간을 모름 → 시주 제외 (3주로 분석)</WText>
          </div>
        </div>

        <div>
          <WText size={11} weight={600}>출생 지역</WText>
          <WBox style={{ height: 44, marginTop: 6, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 12px', borderRadius: 6 }}>
            <WText size={11}>서울특별시 (GMT+8.5 보정)</WText>
            <WText size={10} color={WF.muted}>검색 ▾</WText>
          </WBox>
          <div style={{ marginTop: 4 }}>
            <WText size={9} color={WF.muted}>경도 126.97° · 균시차 자동 적용</WText>
          </div>
        </div>

        {/* Computed preview */}
        <WBox style={{ padding: 10, borderRadius: 6, borderStyle: 'dashed' }}>
          <WText size={9} color={WF.muted}>연산 결과 미리보기</WText>
          <div style={{ marginTop: 6 }}>
            <SajuChart compact />
          </div>
          <div style={{ marginTop: 8 }}>
            <WText size={9} color={WF.muted}>절입시: 경칩 이후 · 월주 기묘(己卯) 확정</WText>
          </div>
        </WBox>

        <div style={{ flex: 1 }}/>
        <WButton primary>사주 분석 시작</WButton>
      </div>
    </div>
  );
}

// ───────── Home — saju-rich top card ─────────
function ScrHomeSajuV2() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '12px 16px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <WText size={10} color={WF.muted}>2026.04.22 수요일</WText>
          <div><WText size={14} weight={700}>안녕하세요, 길동님</WText></div>
        </div>
        <div style={{ width: 28, height: 28, border: `1px solid ${WF.line2}`, borderRadius: 14 }}/>
      </div>

      <div style={{ padding: '0 16px', flex: 1, overflow: 'auto', paddingBottom: 80, display: 'flex', flexDirection: 'column', gap: 10 }}>

        {/* Today's 일진 — serif 한자 hero */}
        <WCard style={{ padding: 14 }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
            <WSectionLabel>오늘의 일진</WSectionLabel>
            <WText size={9} color={WF.muted}>자세히 →</WText>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 8 }}>
            <WBox style={{ width: 60, height: 72, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', borderRadius: 6 }}>
              <WText size={12} weight={700}>경신</WText>
              <span style={{ fontFamily: 'serif', fontSize: 14, color: WF.muted, marginTop: 4 }}>庚申</span>
            </WBox>
            <div style={{ flex: 1 }}>
              <WText size={12} weight={700}>경신일 · 편관(偏官)</WText>
              <div style={{ marginTop: 3 }}>
                <WText size={10} color={WF.muted}>일지충(沖) 발생 · 직장운 주의</WText>
              </div>
              <div style={{ display: 'flex', gap: 4, marginTop: 8 }}>
                <WBox style={{ padding: '2px 6px', borderRadius: 3, borderColor: WF.line2 }}>
                  <WText size={8}>財 68</WText>
                </WBox>
                <WBox style={{ padding: '2px 6px', borderRadius: 3, borderColor: WF.line2 }}>
                  <WText size={8}>愛 82</WText>
                </WBox>
                <WBox style={{ padding: '2px 6px', borderRadius: 3, borderColor: WF.note }}>
                  <WText size={8} color={WF.note}>職 54</WText>
                </WBox>
                <WBox style={{ padding: '2px 6px', borderRadius: 3, borderColor: WF.line2 }}>
                  <WText size={8}>健 75</WText>
                </WBox>
              </div>
            </div>
          </div>
        </WCard>

        {/* My chart at-a-glance */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <WSectionLabel>내 사주 원국</WSectionLabel>
            <WText size={9} color={WF.muted}>경금 일주</WText>
          </div>
          <div style={{ marginTop: 8 }}>
            <SajuChart compact />
          </div>
        </WCard>

        {/* Favorites — 즐겨찾기 (family/partner charts) */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <WSectionLabel>즐겨찾기</WSectionLabel>
            <WText size={9} color={WF.muted}>+ 추가</WText>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
            {[
              { n: '배우자', s: 72 },
              { n: '어머니', s: 61 },
              { n: '자녀', s: 88 },
            ].map(x => (
              <WBox key={x.n} style={{ flex: 1, padding: 8, borderRadius: 6, textAlign: 'center' }}>
                <div style={{ width: 28, height: 28, border: `1px solid ${WF.line2}`, borderRadius: 14, margin: '0 auto' }}/>
                <div style={{ marginTop: 4 }}><WText size={9}>{x.n}</WText></div>
                <div><WText size={11} weight={700}>{x.s}</WText></div>
              </WBox>
            ))}
          </div>
        </WCard>

        {/* 6-month 재물운 locked */}
        <WCard>
          <WSectionLabel>6개월 흐름 참고 리포트</WSectionLabel>
          <WLocked>
            <WPlaceholder h={70} label="월별 그래프" style={{ marginTop: 6 }}/>
          </WLocked>
        </WCard>
      </div>
      <WTabBar active={0} />
    </div>
  );
}

// ───────── FINAL: 나의 투자 성향 — merged single result page ─────────
// Mock state variables
const MOCK = {
  userName: '길동',
  birthDate: '1990.03.15',
  birthTime: '09:20',
  birthPlace: '서울',
  gender: '남',
  trueSolarTimeOn: true,
  hourKnown: true,
  lunarInput: false,
};

function ScrInvestmentPersonality() {
  const { userName, birthDate, birthTime, birthPlace, gender, trueSolarTimeOn, hourKnown, lunarInput } = MOCK;
  const displayName = userName ? (userName.length > 10 ? userName.slice(0, 8) + '…' : userName) : null;
  const heroTitle = displayName ? `${displayName}님의 투자 성향` : '당신의 투자 성향';

  // Accuracy badge
  let accuracyLabel, accuracyCta;
  if (hourKnown && birthPlace && trueSolarTimeOn) {
    accuracyLabel = '정확도: 높음';
  } else if (hourKnown) {
    accuracyLabel = '정확도: 보통';
  } else {
    accuracyLabel = '정확도: 보통';
    accuracyCta = '시간 추가하면 정교해져요 →';
  }

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <WHeader title="나의 투자 성향" back right={<WText size={10} color={WF.muted}>공유</WText>}/>
      <div style={{ overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 10, padding: '12px 14px 14px' }}>

        {/* [1] 감탄 Hero */}
        <WCard style={{ padding: '20px 14px', textAlign: 'center' }}>
          <WText size={10} color={WF.muted}>{heroTitle}</WText>
          <div style={{ height: 1, background: WF.line3, margin: '10px 0' }}/>
          <WText size={22} weight={700}>"단단한 수집가형"</WText>
          <div style={{ marginTop: 6 }}>
            <WText size={11} color={WF.muted}>경금(庚金) 일주 · 정재 중심</WText>
          </div>
          <div style={{ marginTop: 12, padding: '8px 12px', background: WF.gray, borderRadius: 6, textAlign: 'left' }}>
            <WText size={10} style={{ lineHeight: 1.6 }}>"꼼꼼하고 안정을 추구하는 기질. 무모한 베팅보다 분산이 더 맞아요."</WText>
          </div>
        </WCard>

        {/* [2] 사주 원국 미니 차트 */}
        <WCard>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <WSectionLabel style={{ marginBottom: 0 }}>사주 원국</WSectionLabel>
            <WText size={9} color={WF.muted}>일간(日干) = 나</WText>
          </div>
          <div style={{ marginTop: 8 }}>
            <SajuChart compact noHour={!hourKnown} />
          </div>
          {/* 입력·보정 메타 */}
          <div style={{ marginTop: 8, paddingTop: 8, borderTop: `1px solid ${WF.line3}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <WText size={9} color={WF.muted}>양력 {birthDate} {birthTime}</WText>
              <WText size={9} color={WF.muted}>{birthPlace}</WText>
            </div>
            <div style={{ marginTop: 3 }}>
              {trueSolarTimeOn
                ? <WText size={9} color={WF.muted}>진태양시 보정 반영 (−32분)</WText>
                : <WText size={9} color={WF.muted}>진태양시 보정 미적용</WText>}
              {lunarInput && <div style={{ marginTop: 2 }}><WText size={9} color={WF.muted}>음력 → 양력 변환</WText></div>}
            </div>
          </div>
          <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <WText size={10} color={WF.muted}>경금 일주 · 庚金</WText>
            <WText size={10} color={WF.muted} style={{ textDecoration: 'underline' }}>내 사주 자세히 보기 →</WText>
          </div>
        </WCard>

        {/* [3] 오행 균형 */}
        <WCard>
          <WSectionLabel>오행(五行) 균형</WSectionLabel>
          <div style={{ display: 'flex', gap: 6, alignItems: 'flex-end', height: 72, marginTop: 10 }}>
            {[
              { e: '목', han: '木', h: 16, n: 1 },
              { e: '화', han: '火', h: 48, n: 3 },
              { e: '토', han: '土', h: 16, n: 1 },
              { e: '금', han: '金', h: 48, n: 3 },
              { e: '수', han: '水', h: 0, n: 0 },
            ].map(x => (
              <div key={x.e} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>
                <WText size={9} weight={600}>{x.n}</WText>
                <div style={{ width: '65%', height: x.h || 2, background: x.h ? WF.ink : WF.gray2, borderRadius: 2 }}/>
                <WText size={10} weight={700}>{x.e}</WText>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 8, padding: '6px 10px', background: WF.gray, borderRadius: 4 }}>
            <WText size={9}>⚠ 水 부재 · 火·金 과다 — 충동 판단 제어가 필요한 구성</WText>
          </div>
        </WCard>

        {/* [4] 강점 */}
        <WCard>
          <WSectionLabel>강점</WSectionLabel>
          <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {['분석력 · 인내심', '큰 흐름 파악', '리스크 관리'].map(t => (
              <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: WF.ink, flexShrink: 0 }}/>
                <WText size={11}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* [5] 주의점 */}
        <WCard>
          <WSectionLabel>주의점</WSectionLabel>
          <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {['충동 매수보다 관망이 맞는 시기를 구분해야 해요', '수익 실현 타이밍을 놓치는 경향 주의', '과도한 분석으로 진입 시기를 미루지 않도록'].map((t, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: '#c44', flexShrink: 0, marginTop: 5 }}/>
                <WText size={11} style={{ lineHeight: 1.5 }}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* [6] 성향에 맞는 접근 참고 */}
        <WCard>
          <WSectionLabel>성향에 맞는 접근 참고</WSectionLabel>
          <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {['분산 투자 위주로 포트폴리오 구성', '단기 변동보다 3~6개월 중기 흐름 참고', '매수 전 체크리스트 루틴 만들기'].map((t, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: WF.ink, flexShrink: 0 }}/>
                <WText size={11}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* 입력 정보 요약 · 수정 진입점 */}
        <WCard style={{ padding: 10, background: WF.gray }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ flex: 1 }}>
              <WText size={9} color={WF.muted}>입력 정보</WText>
              <div style={{ marginTop: 2 }}>
                <WText size={10}>{birthDate} {birthTime} · {birthPlace} · {gender}</WText>
              </div>
            </div>
            <div style={{ padding: '4px 10px', border: `1px solid ${WF.line2}`, borderRadius: 4, background: '#fff' }}>
              <WText size={9} weight={600}>수정</WText>
            </div>
          </div>
        </WCard>

        <WButton primary>시작하기</WButton>
        <WButton style={{ textAlign: 'center' }}>공유하기</WButton>
        <WDisclaimer />
      </div>
    </div>
  );
}

// ───────── 나의 투자 성향 — 스크롤↓ (아래 부분) ─────────
function ScrInvestmentPersonalityScroll() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: WF.bg }}>
      <div style={{ padding: '8px 14px 6px', borderBottom: `1px solid ${WF.line3}` }}>
        <WText size={9} color={WF.muted}>↑ 위로 스크롤 — Hero 유형 · 사주 원국 · 오행 균형</WText>
      </div>
      <div style={{ overflow: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 10, padding: '12px 14px 14px' }}>

        {/* [4] 강점 */}
        <WCard>
          <WSectionLabel>강점</WSectionLabel>
          <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {['분석력 · 인내심', '큰 흐름 파악', '리스크 관리'].map(t => (
              <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: WF.ink, flexShrink: 0 }}/>
                <WText size={11}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* [5] 주의점 */}
        <WCard>
          <WSectionLabel>주의점</WSectionLabel>
          <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {['충동 매수보다 관망이 맞는 시기를 구분해야 해요', '수익 실현 타이밍을 놓치는 경향 주의', '과도한 분석으로 진입 시기를 미루지 않도록'].map((t, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: '#c44', flexShrink: 0, marginTop: 5 }}/>
                <WText size={11} style={{ lineHeight: 1.5 }}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* [6] 성향에 맞는 접근 참고 */}
        <WCard>
          <WSectionLabel>성향에 맞는 접근 참고</WSectionLabel>
          <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {['분산 투자 위주로 포트폴리오 구성', '단기 변동보다 3~6개월 중기 흐름 참고', '매수 전 체크리스트 루틴 만들기'].map((t, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ width: 4, height: 4, borderRadius: 2, background: WF.ink, flexShrink: 0 }}/>
                <WText size={11}>{t}</WText>
              </div>
            ))}
          </div>
        </WCard>

        {/* 입력 정보 요약 동기화 */}
        <WCard style={{ padding: 10, background: WF.gray }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ flex: 1 }}>
              <WText size={9} color={WF.muted}>입력 정보</WText>
              <div style={{ marginTop: 2 }}>
                <WText size={10}>{MOCK.birthDate} {MOCK.birthTime} · {MOCK.birthPlace} · {MOCK.gender}</WText>
              </div>
            </div>
            <div style={{ padding: '4px 10px', border: `1px solid ${WF.line2}`, borderRadius: 4, background: '#fff' }}>
              <WText size={9} weight={600}>수정</WText>
            </div>
          </div>
        </WCard>

        <WButton primary>시작하기</WButton>
        <WButton style={{ textAlign: 'center' }}>공유하기</WButton>
        <WDisclaimer />
      </div>
    </div>
  );
}

Object.assign(window, { SajuChart, ScrTodayDetailV2, ScrPersonalityV2, ScrInvestmentPersonality, ScrInvestmentPersonalityScroll, ScrSajuInputV2, ScrHomeSajuV2 });
