---
name: prompt-handoff
description: Extract typed Claude Code prompts from local session logs and mask them for hand-carrying out of a corporate environment into a personal vault. Use when the user asks to prepare, collect, mask, or export prompts for kagami, or mentions prompt handoff.
user-invocable: true
version: 0.1.0
license: CC0-1.0
---

# Prompt Handoff

`~/.claude/projects/*/*.jsonl` 의 직접 타이핑한 발화를 모아, 마스킹한 뒤 반출 가능한 하나의 파일로 만든다.
산출물은 개인 vault 의 `Meta/queue/prompts-YYYY-MM-DD` 가 되어 관측 에이전트 kagami 의 재료로 쓰인다.

핵심 통찰: **관측 재료는 짧은 반응이지, 긴 본문이 아니다.**
`설명을 먼저 하고 선택지를 주십쇼...` 같은 한 줄에는 기밀이 거의 없다.
기밀은 두 층에 몰려 있고 — 붙여넣은 덤프(12.8KB / 15.7KB / 21.9KB 짜리가 실재한다)와 수백 자짜리 작업 지시서 —
둘 다 **내용이지 움직임이 아니다.** 그래서 길이로 잘라내는 것이 정규식으로 훑는 것보다 확실하다.

개인 데스크탑 21일치 700 발화 실측:

| | 80자 미만 | 200자 미만 |
|---|---|---|
| 비율 | 74% | 95% |

임계값별 결과:

```
max-chars 600 : 절단 10건 / 의심 40건   ← 작업 지시서 6건이 티켓 키를 달고 그대로 통과
max-chars 200 : 절단 33건 / 의심 23건   ← 0건
```

**기본값이 200인 이유가 이것이다.** 잃는 것은 5%의 본문이고 전부 지시서다.
마스킹을 끄는 옵션은 없다 — 사내에서 실수로 끌 수 있는 스위치는 없는 편이 안전하다.

---

## Step 1: `collect` 실행

```
<skill-dir>/collect [--days N | --week N] [--max-chars N] [--out PATH]
```

- `--days N`: 최근 N일 (기본 7)
- `--week N`: N 주 전의 일요일~토요일 (0 = 이번 주)
- `--max-chars N`: 이 길이를 넘는 발화는 본문을 버리고 `[붙여넣음 1.4KB]` 로 남긴다 (기본 200)
- `--out PATH`: 산출 경로 (기본 `./prompt-handoff-<마지막날짜>.md`)

프로젝트명은 항상 토큰으로 치환되고, ARN / UUID / AWS 계정 ID / 액세스 키 / IP / 이메일 / URL / JWT /
32자 이상 16진 / 전화번호는 자리표시로 바뀐다.

stderr 로 나오는 요약과 의심 목록을 읽는다. **이것이 다음 단계의 입력이다.**

```
산출: ./prompt-handoff-2026-08-15.md
발화 214건 / 덩어리 절단 6건 / 패턴 치환 23건

검토 필요 (규칙에 안 걸렸으나 의심되는 줄): 7
  2026-08-10 10:36  tcp/443 만 허가하면 된다는건 어디 레퍼런스임?
```

발화가 없으면 그 사실만 알리고 끝난다. 이 경우 여기서 멈춘다.

---

## Step 2: 의심 목록 판정

의심 목록의 각 줄에 대해 **고유명사인지만** 판정한다. 문장의 좋고 나쁨은 보지 않는다.

**치환 대상:** 사내 조직명 · 제품/시스템 코드네임 · 고객사명 · 인명 · 티켓 키

**치환하지 않음:** 일반 기술 용어 (`tcp/443`, `render :edit`, `stg`, `DNS`), 공개된 OSS 이름

확신이 서지 않으면 **치환하는 쪽으로 기운다.** 재료가 조금 얇아지는 것이 유출보다 낫다.

---

## Step 3: 치환

치환할 값을 모아 **한 번에** 넘긴다.

```
<skill-dir>/token <kind> <value> [<kind> <value> ...]
```

`kind` 는 `org` / `person` / `system` / `proj` 같은 짧은 식별자다.
`<원본>\t<토큰>` 한 줄씩 나오므로, 그대로 산출물을 편집한다.

**토큰을 직접 지어내지 마라.** 스크립트가 준 것만 써야 회차를 넘어 같은 대상이 같은 토큰이 된다.

---

## Step 4: 게이트

산출물 **전문을 Shia에게 보여주고 확인을 받는다.**

이 단계를 건너뛰지 않는다. **마스킹 실패는 조용하다** — 규칙에 안 걸린 고유명사는 아무 신호도 내지 않고
그냥 그대로 나간다. 사람이 전문을 읽는 것이 마지막이자 유일한 검출 지점이다.

---

## Step 5: 반출

확인이 끝나면 Shia가 파일을 손으로 vault 의 `Meta/queue/prompts-YYYY-MM-DD` 로 옮긴다.

스킬은 vault 에 직접 쓰지 않는다. 사내 환경에는 vault 접근이 없고, 그것이 이 경계의 요점이다.

---

## Notes

- **salt 를 지우거나 덮어쓰지 마라.** `~/.config/prompt-handoff/salt` 가 바뀌면 같은 조직·같은 사람이
  회차마다 다른 토큰이 되어, kagami 가 회차 간 비교를 못 한다. 없을 때만 새로 만들어진다.
- **salt 자체는 절대 반출하지 않는다.** 산출물과 함께 나가면 토큰을 원본으로 되돌릴 수 있다.
- 이 스킬은 **사내 환경용**이다. 개인 데스크탑에서는 kagami 리포의 `bin/extract-prompts` 를 쓴다 —
  거기서는 마스킹이 필요 없고, 잘라낼 이유도 없다.
