---
name: empirical-tuning
description: Use when a skill scores inconsistently across runs, or when confirming robustness before `crystallize` — dispatches blind-executor subagents to collect subjective + metric feedback, then refines the skill's instructions. Pairs with `scoring` and `reviewing` as a pre-crystallize hardening loop.
---

# Empirical Prompt Tuning

作成者バイアスを排除するため、**別エージェントに盲目実行させて**主観+指標で評価し、指示を改善する。

Based on mizchi's [empirical-prompt-tuning](https://github.com/mizchi/chezmoi-dotfiles/blob/main/dot_claude/skills/empirical-prompt-tuning/SKILL.md). Adapted for singularity-claude integration.

## Overview

- Skill authors can't objectively re-read their own prompts; blind-runner dispatch is structural, not stylistic
- Two-sided evaluation: qualitative (unclear points, discretion filled in) + quantitative (checklist pass rate, step count, duration)
- Convergence is declared only after **2 consecutive iterations** meet both sides — prevents one-shot luck from being mistaken for robustness
- Integrates with `singularity-claude:scoring` as a pre-scoring harness (post-hoc self-run scoring still applies)

## When to use

- singularity-managed skill が `review` で構造 OK だが実行がブレる
- crystallize 判定（5 run, avg>=90）前に堅牢性を確信したい
- scoring が直近 3 run 以内で大きく振れている
- 新規 skill の initial 5 run を blind で稼ぎたい

## When NOT to use

- 一回限りのプロンプト
- dispatch 不能環境（本体セッションで Agent tool が禁止されている場合）

## Core principle

「作成者が『明瞭だ』と思うものほど、別 agent が読むと詰まる」

**自己再読は禁止。** 直前に書いた文章を客観視するのは構造的に不可能。blind executor を必ず介す。

## Workflow

### Step 0 — Description/Body 整合チェック（静的、先に）

`frontmatter.description` が謳う用途と body の実装範囲の乖離を確認。乖離があれば先に修正してから iter 1 に進む。
省略すると subagent が description 側を優先して body の不足を自動補完してしまい、偽陽性になる。

### Step 1 — ベースライン準備

1. **評価シナリオ 2～3 種**を準備
   - 中央値的な現実シナリオ 1
   - エッジケース 1～2
2. **要件チェックリスト** をシナリオごとに 3～7 項目
   - `[critical]` タグを最低 1 つ
   - 事前固定、iter 中に動かさない

精度 = 満たした項目 / 全項目 × 100%

### Step 2 — Subagent dispatch（blind 読み）

対象 skill の body 全文を blind executor に渡す。`Agent` tool で `subagent_type: general-purpose` (haiku or sonnet)。

**契約プロンプト**:

```
あなたは <skill-name> を白紙で読む実行者です。

## 対象スキル
<body 全文、あるいは絶対パス>

## シナリオ
<1 段落>

## 要件チェックリスト
1. [critical] <最低ライン>
2. <通常>
3. <通常>

## タスク
1. スキルに従ってシナリオを実行し成果物を出す
2. 下のレポート構造で返答

## レポート構造
- 成果物: <サマリ>
- 要件達成: 各項目 ○/×/部分的（理由付き）
- 不明瞭点: 詰まった箇所（箇条書き）
- 裁量補完: 指示で決まっていなかった判断（箇条書き）
- 再試行: 回数と理由
```

複数シナリオは単一メッセージで並列 dispatch。

### Step 3 — 実行 → レポート回収

subagent から上記レポートを受領。同時に Agent tool の usage から `tool_uses` と `duration_ms` を記録。

### Step 4 — 両面評価

| 軸 | 取り方 | 意味 |
|---|---|---|
| 成功/失敗 | `[critical]` 全項目 ○ で ○ | 最低ライン |
| 精度 | チェックリスト達成率 | 部分成功の程度 |
| ステップ数 | `tool_uses` | 指示の無駄 |
| 所要時間 | `duration_ms` | 認知負荷代替 |
| 再試行 | 自己申告 | 曖昧さシグナル |
| 不明瞭点 | 自己申告 | **質的主軸** |
| 裁量補完 | 自己申告 | 暗黙仕様の炙り出し |

**重み付け**: 質的を主、量的を補助。シナリオ間で step 数が 3-5x 差なら決定木的（自己完結性低）のサイン。

### Step 5 — 差分適用（1 iter = 1 テーマ）

- 修正前に「この修正がチェックリストのどれを満たすか」を言語化
- 最小修正。関連する微修正 2-3 件は 1 iter にまとめて OK、分けすぎ NG
- 複数テーマ混ぜると何が効いたか追えない

### Step 6 — 再評価

**新規 subagent で Step 2-5 を回す。** 同一 subagent は禁止（前回改善を学習してるため）。

### Step 7 — 収束判定

**連続 2 回、以下全てを満たせば収束**:
- 新規不明瞭点: 0
- 精度改善: +3pt 以下
- ステップ数変動: ±10% 以内
- duration 変動: ±15% 以内
- 過適合 hold-out: 直近平均から 15pt 以上落ちたら baseline に戻る

重要スキルは連続 3 回で確定。

**発散**: 3 iter 以上で不明瞭点が減らない → 設計方針ごと書き直し。

#### 質的収束判定（CCC 拡張）

blind-runner は本質的に非決定的で、同じ指示でも run ごとに指摘点が揺れる。量的メトリクス（精度・step・duration）だけでは「本当に skill が固まったか」を捉えきれない。そこで location convergence を主判定、severity variance を許容ノイズとして分離する。

**Location convergence（主判定・収束を前に進める根拠）**:
- 独立した evaluator 2 体以上が**同じ該当箇所**（行番号・セクション見出し・要件項目番号のいずれかで一致）を不明瞭点としてフラグした場合、その曖昧さは "confirmed ambiguity" として確定
- evaluator 1 体のみの指摘は "candidate ambiguity"。次 iter で 2 体目が現れるまで保留
- confirmed ambiguity が 0 になるのが収束。candidate が残っていても収束可（ノイズとして受容）

**Severity variance（許容ノイズ・収束を止める根拠にしない）**:
- 同一 location に対する evaluator 間での severity 評価（○ / 部分的 / × や、精度スコア差）の揺れは、±15pt 以内なら許容
- 15pt 超の差は「location は一致しているが、どちらかの evaluator が要件の読み違いをしている」可能性があるので、要件文言そのものを見直す（要件側のバグ）

**実運用ルール**:
- iter レポートに「confirmed ambiguities（今残っているもの）」を列挙する節を足すと、Step 7 の収束判定が視認しやすくなる
- 新出 confirmed ambiguity が出た iter は収束カウンタをリセット。candidate 止まりならカウンタは維持
- この質的判定は量的メトリクス（Step 7 の 4 条件）と AND で使う。両方クリアして初めて収束

### Step 8 — singularity registry 反映

収束したら:

```bash
"${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/empirical-tuning}/scripts/log-empirical.sh" <skill-name> \
  --iterations <n> \
  --final-precision <%> \
  --report-path <path>
```

スクリプトが無ければ手動で `~/.claude/singularity/telemetry/<skill-name>/empirical-<ts>.json` に記録。scoring 側が次回参照できるよう `empirical_validated: true` を registry に追記。

## Output format（iter 報告）

```
## Iteration N

### 変更点（前回差分）
- <修正 1 行>

### 実行結果
| シナリオ | 成功/失敗 | 精度 | steps | duration | retries |
|---|---|---|---|---|---|
| A | ○ | 90% | 4 | 20s | 0 |
| B | × | 60% | 9 | 41s | 2 |

### 不明瞭点（新出）
- <シナリオ B>: [critical] 項目 N が × — <理由>

### 裁量補完（新出）
- <シナリオ B>: <補完>

### 次の修正案
- <最小修正 1 行>

（収束判定: 連続 X / 停止まであと Y）
```

## Red flags

| 合理化 | 実態 |
|---|---|
| 自分で読み直せば同じ | 構造的に無理、別 agent 必須 |
| 1 シナリオで充分 | 過適合する。min 2, ideal 3 |
| 1 回クリアで終わり | 偶然かも、連続 2 回で確定 |
| 複数不明瞭点を一気に潰す | 何が効いたか追えない |
| メトリクス良好だから質的無視 | 時間短縮は痩せすぎサイン |
| 書き直した方が早い | 3 iter 未満なら逃げ |
| 同一 subagent 再利用 | 前回学習が混入 |

## Integration with singularity-claude

本 skill は `singularity-claude:scoring` の**前段補助**として機能する:

- scoring = post-hoc 実行品質計測（self-run）
- empirical = 事前の指示堅牢性検証（blind-run）

scoring が振れる skill / crystallize 直前の skill に empirical を挟み、registry に `empirical_validated` フラグを立てる。crystallizing skill が将来このフラグを必須化するのが筋（PR 案件）。

## References

- Origin: [mizchi/empirical-prompt-tuning](https://github.com/mizchi/chezmoi-dotfiles/blob/main/dot_claude/skills/empirical-prompt-tuning/SKILL.md)
- Related: `singularity-claude:scoring`, `singularity-claude:reviewing`, `singularity-claude:crystallizing`
