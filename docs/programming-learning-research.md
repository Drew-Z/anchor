# Programming Knowledge Learning Research

Date: 2026-07-15

## Scope

Research question:

> How should a local-first programming learning app ingest official
> documentation and source code with provenance, licensing/version boundaries,
> prerequisite relationships, layered tutoring, exercises, and review closure?

The broad smart-search provider passed `doctor`, but its real search request
returned an empty response. `smart-search diagnose openai-compatible` confirmed
that lightweight chat worked while the real search shape received HTTP 429 in
non-stream mode and an empty HTTP 200 stream. The research therefore used the
documented source-first fallback and fetched official pages directly.

On 2026-07-15, the provider/model acceptance work reran `smart-search doctor`.
The configured broad model route returned an upstream HTTP 429, while the
configured Tavily fetch and Context7 documentation capabilities were healthy.
The research therefore used `smart-search fetch` only for known official OpenAI
pages and did not silently switch to native web search. The fetched evidence was:

- `https://developers.openai.com/api/docs/guides/latest-model.md`
- `https://developers.openai.com/api/docs/guides/migrate-to-responses.md`
- `https://developers.openai.com/api/docs/guides/evals`
- `https://developers.openai.com/api/docs/pricing`

These sources support the current GPT-5.6 model-family labels, Responses as the
recommended new-project API, repeatable eval criteria with usage tracking, and
the direct OpenAI pricing entries used by the optional estimator. Custom relay
pricing and App client compatibility remain empirical properties and are not
inferred from OpenAI documentation.

## Findings Applied To Branch 18

1. Provenance must be first-class data. W3C PROV defines provenance as
   information about the entities, activities, and people involved in producing
   data, specifically so quality, reliability, and trustworthiness can be
   assessed. Duoduo therefore needs more than a trust label: it must retain the
   source identity, publisher, acquisition event, revision, and integrity hash.
2. Version and content identity are separate. Python publishes official docs by
   explicit version, while Git uses content-addressed objects and commit snapshots.
   A programming source should retain both a human version/revision and a content
   hash when available.
3. Reuse rights cannot be inferred from authority. MDN documents and code samples
   use different licenses and attribution rules. The app should record license
   information when known and display an explicit unknown state otherwise.
4. Automated web acquisition must remain a later, policy-gated feature. RFC 9309
   requires crawlers to honor applicable robots rules and clarifies that robots
   is not access authorization. Leaf 18.1 therefore supports auditable manual
   snapshots; future web import must separately enforce robots, terms, and access.
5. Learning relationships need canonical identifiers and typed associations.
   1EdTech CASE uses canonical identifiers plus association types such as
   `isChildOf` and `precedes`. Duoduo will use explicit prerequisite edges,
   user review, and cycle rejection instead of hiding order inside free-text tags.
6. Tutor dialogue should require learners to construct explanations instead of
   only rereading generated prose. The U.S. Institute of Education Sciences
   practice guide recommends asking and answering deep questions, and reports
   that interactive construction of explanations can outperform merely reading
   explanations when problems are appropriately challenging. Leaf 18.3 therefore
   moves from layered explanation into an answer-feedback-next-question loop.
7. “One question at a time” is an auditability constraint chosen by Duoduo, not
   a verbatim IES prescription. Keeping one active question lets each saved turn
   bind a specific user answer, feedback, misconception, next question, and set
   of source citations; unsupported turns stop instead of opening another topic.
8. The same IES guide supports active retrieval and learner-generated
   explanations rather than passive rereading. Leaf 18.4 applies that principle
   through explanation, code-reading, boundary, and implementation exercises,
   followed by a source-grounded retest after an error. The exact four scoring
   dimensions, the 80-point repair threshold, and mandatory human verification
   are Duoduo product contracts for auditability, not claims copied from IES.
9. Model-provider configuration is a Branch 19 correctness concern, not a
   prerequisite for the local Branch 18 state machine. The current app only
   sends OpenAI-compatible Chat Completions and parses prompt-requested JSON.
   DeepSeek's official documentation now lists `deepseek-v4-flash` and
   `deepseek-v4-pro`, and says the legacy `deepseek-chat` and
   `deepseek-reasoner` aliases will be deprecated on 2026-07-24. Its JSON mode
   also requires `response_format: {"type":"json_object"}`, which Duoduo does
   not yet send. The first live acceptance profile should therefore use a
   low-quota development key and must test structured-output behavior before
   generated content is trusted.
10. Current official catalogs also show why model names cannot remain static in
    the client. OpenAI's model page recommends the GPT-5.6 family and foregrounds
    the Responses API, while Alibaba Bailian currently lists `qwen3.7-max`,
    `qwen3.7-plus`, and `qwen3.6-flash`. Branch 19 should store provider
    capabilities and task profiles instead of treating a hard-coded dropdown as
    the model architecture.
11. Correctness work needs a fixed, human-labelled dataset before prompts,
    rankings, or providers change. OpenAI's evaluation guidance recommends
    representative test data with typical, edge, and adversarial cases, human
    expert labels, and quantitative metrics for automated regression testing.
    Leaf 19.1 therefore stores expected relevance, support, and refusal labels in
    a versioned fixture while keeping model execution outside the metric service.
12. Ranked retrieval must be measured at the context depth the product actually
    uses. The Stanford IR text defines top-k precision/recall evaluation and
    rank-aware measures for search results. Duoduo starts with macro `Recall@k`
    plus mean reciprocal rank so it can distinguish “evidence was retrieved”
    from “evidence appeared early enough to be used.”
13. A response-level citation count is not enough. The ACL ALCE benchmark scores
    citation recall per statement only when the cited passages fully support that
    statement, and separately identifies unsupported or irrelevant citations.
    Duoduo's first deterministic approximation uses human-labelled claims,
    supporting evidence IDs, citation coverage, and unsupported-claim rate; an
    automatic entailment judge remains a later acceptance option, not ground truth.
14. NIST AI 600-1 frames measurement, documentation, testing, and monitoring as
    lifecycle controls for generative AI risks including confabulation. The fixed
    corpus and refusal labels are therefore retained as auditable product evidence,
    not transient test prompts or a provider dashboard score.
15. Leaf 19.3 operationalizes the ALCE statement-level citation principle with a
    deterministic local gate: every emitted claim carries one or more source
    chunk IDs and exact source quotes, while invalid evidence is removed before
    user-visible text, mastery, or review scheduling is produced. The gate and
    its `grounded/partial/refused/legacy` disposition are persisted for later
    audit. Exact quote containment proves that the cited text exists, but does
    not by itself prove semantic entailment; provider/model acceptance and any
    future judge therefore remain separate measured layers rather than being
    presented as ground truth.

## Fetched Evidence

- [W3C PROV Overview](https://www.w3.org/TR/prov-overview/)
- [RFC 9309: Robots Exclusion Protocol](https://www.rfc-editor.org/rfc/rfc9309.html)
- [MDN attribution and copyright licensing](https://developer.mozilla.org/en-US/docs/MDN/Writing_guidelines/Attrib_copyright_license)
- [Git Internals: Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)
- [SPDX 3.0.1 CreationInfo](https://spdx.github.io/spdx-spec/v3.0.1/model/Core/Classes/CreationInfo/)
- [SPDX 3.0.1 LicenseExpression](https://spdx.github.io/spdx-spec/v3.0.1/model/SimpleLicensing/Classes/LicenseExpression/)
- [Python 3 documentation](https://docs.python.org/3/)
- [1EdTech CASE v1.1 implementation guide](https://www.imsglobal.org/spec/CASE/v1p1/impl)
- [IES: Organizing Instruction and Study to Improve Student Learning](https://ies.ed.gov/ncee/wwc/PracticeGuide/1)
- [IES full practice guide PDF](https://ies.ed.gov/ncee/WWC/Docs/PracticeGuide/20072004.pdf)
- [OpenAI models](https://platform.openai.com/docs/models)
- [DeepSeek models and pricing](https://api-docs.deepseek.com/quick_start/pricing)
- [DeepSeek JSON Output](https://api-docs.deepseek.com/guides/json_mode)
- [Alibaba Bailian model catalog](https://help.aliyun.com/zh/model-studio/getting-started/models)
- [OpenAI evaluation best practices](https://platform.openai.com/docs/guides/evaluation-best-practices)
- [Stanford IR book: Evaluation of ranked retrieval results](https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-ranked-retrieval-results-1.html)
- [ACL Anthology: Enabling Large Language Models to Generate Text with Citations](https://aclanthology.org/2023.emnlp-main.398/)
- [NIST AI 600-1: Generative AI Profile](https://doi.org/10.6028/NIST.AI.600-1)

## Reproducible Commands

```powershell
smart-search doctor --format json
smart-search deep "How should a local-first programming learning app ingest official documentation and source code with provenance, trust ranking, licensing and robots boundaries, versioning, prerequisite relationships, layered tutoring, Socratic questions, exercises, and review closure?" --budget deep --format json
smart-search diagnose openai-compatible --format markdown
smart-search fetch "https://www.w3.org/TR/prov-overview/" --format markdown
smart-search fetch "https://www.rfc-editor.org/rfc/rfc9309.html" --format markdown
smart-search fetch "https://developer.mozilla.org/en-US/docs/MDN/Writing_guidelines/Attrib_copyright_license" --format markdown
smart-search fetch "https://git-scm.com/book/en/v2/Git-Internals-Git-Objects" --format markdown
smart-search fetch "https://spdx.github.io/spdx-spec/v3.0.1/model/Core/Classes/CreationInfo/" --format markdown
smart-search fetch "https://spdx.github.io/spdx-spec/v3.0.1/model/SimpleLicensing/Classes/LicenseExpression/" --format markdown
smart-search fetch "https://docs.python.org/3/" --format markdown
smart-search fetch "https://www.imsglobal.org/spec/CASE/v1p1/impl" --format markdown
smart-search deep "How should an evidence-grounded programming tutor structure layered explanations and one-question-at-a-time Socratic feedback while refusing unsupported claims?" --budget deep --format json
smart-search search "evidence grounded Socratic tutoring one question at a time feedback misconceptions learning science" --validation balanced --extra-sources 5 --timeout 90 --format json
smart-search fetch "https://ies.ed.gov/ncee/wwc/PracticeGuide/1" --format markdown
smart-search fetch "https://ies.ed.gov/ncee/WWC/Docs/PracticeGuide/20072004.pdf" --format markdown
smart-search fetch "https://platform.openai.com/docs/models" --format json --output C:\tmp\smart-search-evidence\20260715-duoduo-models\openai-models-fetch.json
smart-search fetch "https://api-docs.deepseek.com/quick_start/pricing" --format json --output C:\tmp\smart-search-evidence\20260715-duoduo-models\deepseek-pricing-fetch.json
smart-search fetch "https://api-docs.deepseek.com/guides/json_mode" --format json --output C:\tmp\smart-search-evidence\20260715-duoduo-models\deepseek-json-fetch.json
smart-search fetch "https://help.aliyun.com/zh/model-studio/getting-started/models" --format json --output C:\tmp\smart-search-evidence\20260715-duoduo-models\qwen-models-fetch.json
smart-search fetch "https://platform.openai.com/docs/guides/evaluation-best-practices" --format markdown --output C:\tmp\smart-search-evidence\20260715-duoduo-correctness\05-openai-eval-best-practices.md
smart-search fetch "https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-ranked-retrieval-results-1.html" --format markdown --output C:\tmp\smart-search-evidence\20260715-duoduo-correctness\02-stanford-ranked-retrieval.md
smart-search fetch "https://aclanthology.org/2023.emnlp-main.398.pdf" --format markdown --output C:\tmp\smart-search-evidence\20260715-duoduo-correctness\06-alce-paper.md
smart-search fetch "https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf" --format markdown --output C:\tmp\smart-search-evidence\20260715-duoduo-correctness\07-nist-ai-600-1.md
```

Saved evidence directory:

```text
C:\tmp\smart-search-evidence\20260715-0128-how-should-a-local-first-programming-learning-ap
C:\tmp\smart-search-evidence\20260715-0956-how-should-an-evidence-grounded-programming-tuto
C:\tmp\smart-search-evidence\20260715-duoduo-models
C:\tmp\smart-search-evidence\20260715-duoduo-correctness
```
