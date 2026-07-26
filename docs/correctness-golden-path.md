# Correctness Golden Path

## Purpose

This deterministic scenario closes Branch 19 by proving that the same
source-grounding contract is enforced across retrieval, knowledge answers,
tutor feedback, interview evaluation, and programming-exercise evaluation.
It is a regression contract, not a claim that one small fixture represents
real-world model quality.

```text
trusted and untrusted sources
-> explainable ranking
-> bounded answer context
-> grounded, partial, or refused answer
-> cited tutor, interview, and exercise feedback
-> fixed correctness metrics
-> Android-visible evidence states and navigation
```

## Fixed Inputs

- Fixture:
  `test/fixtures/golden_path/correctness_closure_fixture.json`
- Service test: `test/correctness_golden_path_test.dart`
- Widget test: `test/correctness_golden_path_widget_test.dart`
- Retrieval stress fixture:
  `test/fixtures/evaluation/correctness_retrieval_stress_v1.json`
- Retrieval stress test: `test/correctness_retrieval_stress_test.dart`
- Independent labeled fixture:
  `test/fixtures/evaluation/correctness_labeled_set_v1.json`
- Independent labeled test: `test/correctness_labeled_set_test.dart`
- Human labeling contract: `docs/correctness-labeling-guide.md`
- Query: `JSON schema guarantee`
- Trusted evidence: an official OpenAI Structured Outputs guide chunk stating
  that JSON mode guarantees valid JSON but not schema conformance.
- Contradictory evidence: a personal note claiming that every response
  automatically satisfies a schema.
- AI boundary: six queued deterministic JSON responses. No live provider,
  network call, or API key is used.
- Evaluation surfaces: knowledge answer, tutor feedback, interview evaluation,
  and programming-exercise evaluation.

## Required Behaviors

| Surface | Fixed assertion |
| --- | --- |
| Retrieval | The official chunk ranks above the personal note and is selected as the single answer context. |
| Ranking explanation | The selected candidate retains inspectable term, title/body, and source-trust reasons. |
| Grounded answer | Supported claims remain and resolve to exact quotes in the supplied chunk. |
| Partial answer | The supported claim remains, the unsupported schema claim is removed, and the UI says `部分主张未支持`. |
| Refusal | An answer with no supported claim is emptied and the UI says `证据不足已拒答`. |
| Tutor | Feedback, reference answer, and misconception remain citation-grounded. |
| Interview | Scores, feedback, reference answer, weak point, and follow-up retain the supplied source boundary. |
| Programming exercise | Four-dimensional evaluation remains grounded and returns the fixed average score of 93. |

## Fixed Metrics

The closure fixture contains one labeled retrieval case and six generation
cases across all four correctness surfaces.

| Metric | Result |
| --- | ---: |
| Recall@1 | 1.0 |
| Mean reciprocal rank | 1.0 |
| Citation coverage | 1.0 |
| Unsupported claim rate after grounding gates | 0.0 |
| Refusal accuracy | 1.0 |

These values must remain reproducible in the deterministic test suite. The
unsupported-claim metric measures the post-gate output: unsupported claims are
removed or cause refusal before evaluation. A larger independently labeled set
is still required before treating these values as production quality estimates.

## Retrieval Stress Baseline

The follow-up fixture adds three deterministic retrieval risks without a live
provider or network dependency:

- a compact Chinese-English query asks whether JSON mode guarantees schema
  conformance while a personal note repeats the incorrect claim in Chinese;
- 64 generated article chunks contain partial transaction keywords around the
  official SQLite atomic commit/rollback boundary;
- a keyword-stuffed personal retry note conflicts with the checked-in client
  implementation's bounded exponential-backoff rule.

The query-term layer preserves the old pure-English token contract. Chinese
queries add a small, explicit set of bilingual AI/programming concepts, and the
English `rollback` token also recognizes documented `roll(s) ... back` forms.
The ranker itself keeps the existing relevance, trust, stable-id, locator, and
reason-label contract; it does not grant an unconditional official-source win.

| Stress metric | Result |
| --- | ---: |
| Cases | 3 |
| Recall@1 | 1.0 |
| Mean reciprocal rank | 1.0 |
| Generated distractor chunks | 64 |

Every selected context must retain a non-empty locator and contain the labeled
exact quote. The stress fixture is a regression boundary, not a broad claim of
cross-language semantic retrieval quality.

## Independent Labeled Set V1

The next versioned fixture separates retrieval wording from source correctness.
It contains six source-backed topics, three query variants per topic, and six
lexically similar but false personal-note chunks as hard negatives.

| Query variant | Cases | Recall@1 | MRR |
| --- | ---: | ---: | ---: |
| Canonical technical wording | 6 | 1.0 | 1.0 |
| Natural Chinese paraphrase | 6 | 1.0 | 1.0 |
| Natural English paraphrase | 6 | 1.0 | 1.0 |

The first run exposed a real bilingual normalization failure: the Chinese
atomic-transaction query added `rollback` but not the documented English forms
such as `rolls them back`, allowing a contradictory personal note to rank first.
The fix expands both English phrase queries and Chinese concepts to the same
explicit word forms. Trust weights were not increased to hide the relevance
failure.

Claim annotations separately include `full`, `partial`, and `none` semantic
support. Their contract is human labeling: locator and quote presence make a
citation inspectable, while quote containment alone is not semantic entailment.
The set is checked in for regression and was visible during implementation, so
it is not a held-out production estimate.

## Frozen Blind Proxy V1

Two clean-context agents independently authored candidate AI and Agent
engineering questions without receiving the current query-term aliases. Before
the first retrieval run, invalid or mismatched candidates were removed and six
official sources were fetched with `smart-search fetch`: OpenAI function calling
and embeddings, OWASP prompt injection, RFC 9110 idempotency, Apache Flink
checkpointing, and the OpenTelemetry observability primer.

The resulting 18-query fixture was frozen at SHA-256
`ec321abf442232fb01a682b5597994cdfff120628907f0867c08effdca14cee7` before
evaluation. No search implementation or alias was changed after seeing these
results.

| Untuned variant | Cases | Recall@1 | MRR |
| --- | ---: | ---: | ---: |
| Canonical technical wording | 6 | 1.0000 | 1.0000 |
| Natural Chinese wording | 6 | 0.1667 | 0.1667 |
| Natural English wording | 6 | 0.8333 | 0.9167 |

The baseline is stored separately and acts only as a no-regression floor;
future retrieval may improve it without changing the frozen fixture. The large
Chinese gap is evidence for evaluating a general bilingual or hybrid retrieval
layer instead of extending a hand-written alias list from these held-out cases.
This is still a proxy authored by agents, not naturally collected user traffic.

## Hybrid Retrieval Contract

The first implementation step is an orchestration contract, not a bundled
embedding model. `HybridKnowledgeSearchService` always runs the original local
lexical query and may accept a bounded set of independently produced model or
local-semantic query variants. It fuses branch rankings with reciprocal-rank
fusion while retaining each underlying lexical score explanation.

The contract guarantees:

- an augmentation provider cannot replace or delete the original query;
- duplicate, empty, oversized, and excess variants are rejected;
- provider errors return the same deterministic lexical ordering;
- every result records original/model/local-semantic branch ranks and its RRF
  score;
- the existing source trust, locator, exact-quote, and citation-selection path
  remains outside the augmentation provider.

SQLite FTS5 remains useful for corpus scale and token indexing, but cannot by
itself bridge a pure Chinese question to a pure English chunk. A bundled local
multilingual embedding model is deferred because the repository currently has
no inference runtime, model asset, vector index, ABI plan, or measured package
budget. A model rewrite adapter is possible through the existing provider
protocols, but must be opt-in, debounced, limited to the explicit query, and
privacy-screened before it is connected to the live search UI.

## Opt-in Model Query Rewrite

The live knowledge search now keeps two stages. A 300 ms debouncer commits only
the final input, then the existing lexical provider renders local results. When
the separately persisted `modelAssistedSearchEnabled` preference is explicitly
enabled, a second provider asks the accepted model for bounded query variants
and replaces the visible list only after hybrid fusion completes.

The adapter sends exactly the trimmed search-box query as `userContent`. It has
no corpus parameter and does not receive source bodies, chunks, paths, history,
answers, or credentials. Queries changed by `PrivacyRedactor` are rejected
before transport. Output must be a complete JSON object (optionally inside one
Markdown JSON fence); prose, arrays, and malformed JSON produce no variants and
therefore preserve local search.

The setting defaults to off. Missing credentials, an unaccepted model/profile,
provider errors, sensitive-query refusal, and parse failures all retain the
original lexical branch. The UI shows whether model variants were fused or the
request fell back locally; clearing input or disposing the screen cancels a
pending debounce callback.

## Android Acceptance

Acceptance was run on `emulator-5554` on 2026-07-15 with temporary records
prefixed `leaf19-validation-`.

- Answer history visibly distinguishes `证据合格`, `部分主张未支持`, and
  `证据不足已拒答`:
  `build/validation/duoduo-leaf19-5-history-states.png`
- Searching `JSON schema guarantee` shows `排序依据` on every result and ranks
  the official OpenAI chunk above the personal note:
  `build/validation/duoduo-leaf19-5-search-ranking.png`
- Opening the grounded answer's citation navigates to the official source
  detail and highlights `当前引用片段`:
  `build/validation/duoduo-leaf19-5-citation-navigation.png`
- Matching UI hierarchy evidence is stored beside each PNG as XML.
- After evidence capture, all two temporary sources, two chunks, and three
  learning sessions were deleted. SQLite `integrity_check` returned `ok`.
- A post-cleanup relaunch reached the knowledge base with no
  `FATAL EXCEPTION`, `E/flutter`, or App ANR in
  `build/validation/duoduo-leaf19-5-post-cleanup-logcat.txt`.

## Current Android Build Artifact

- APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Size: `140,589,086` bytes
- SHA-256:
  `e8dbf4ec2c057303248a86920f552fdcb584a0b39ae5bfc271e2fb0a0078766a`
- Android build-tools: `37.0.0`
- `apksigner verify --verbose`: verifies with APK Signature Scheme v2 and one
  Android debug signer.
- APK inspection finds `lib/arm64-v8a/libflutter.so` and no other Flutter
  engine ABI. This follow-up build has not replaced the earlier emulator UI
  evidence and still awaits the app-only physical-device click check.

## Why Vector Retrieval Is Not Triggered

The current lexical and trust-aware ranker passes the fixed labeled path,
produces inspectable reasons, selects the correct official context, and has no
demonstrated latency or corpus-size blocker. Adding embeddings now would add a
second retrieval system before there is evidence that the current one fails.

Reconsider hybrid or vector retrieval when at least one of these signals is
captured in the labeled evaluation set:

- semantic or synonym queries repeatedly miss evidence that users can find;
- Recall@K or reciprocal-rank results regress below an agreed product target;
- corpus growth makes local ranking or context selection too slow;
- latency degrades enough to block the learning workflow;
- lexical ranking cannot separate relevant and irrelevant sources without
  brittle query-specific rules.

Any future vector implementation must preserve source trust, locators, exact
quotes, deterministic fallback, and the current ranking explanation contract.

## Remaining Risks

- The frozen blind proxy adds an untuned 18-query measurement and demonstrates
  a large Chinese natural-language recall gap. It was independently authored
  and hash-frozen, but it is still agent-generated rather than naturally
  collected user traffic and does not represent production corpus scale.
- Queued responses prove task contracts and grounding gates, not live-provider
  consistency. Formal learning calls remain blocked until the same provider,
  base URL, model, and protocol pass the in-App acceptance matrix.
- Android acceptance currently covers one emulator/API configuration.
- The local Flutter Maven mirror is a machine-local offline build workaround,
  not a checked-in dependency distribution strategy.
- Existing analyzer info lints and Android toolchain upgrade notices remain
  non-blocking maintenance debt.

## Repeatable Commands

```powershell
flutter test --no-pub test/correctness_golden_path_test.dart
flutter test --no-pub test/correctness_golden_path_widget_test.dart
flutter test --no-pub test/correctness_retrieval_stress_test.dart
flutter test --no-pub test/correctness_labeled_set_test.dart
flutter test --no-pub test/correctness_blind_proxy_test.dart
flutter test --no-pub test/hybrid_knowledge_search_service_test.dart
flutter test --no-pub test/model_search_query_variant_provider_test.dart
flutter test --no-pub test/search_preferences_test.dart
flutter test --no-pub test/search_query_debouncer_test.dart
flutter test --no-pub
flutter analyze --no-pub --no-fatal-infos
```
