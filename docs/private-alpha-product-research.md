# Anchor Learning Private Alpha Product Research

Date: 2026-07-16

## Research Question

How should Anchor Learning turn its existing source-grounded local learning Agent into a
private-alpha product for developers who need to understand and explain their
own AI application projects while learning the related programming knowledge?

This research distinguishes three evidence classes:

- `Observed`: behavior verified in the current Anchor Learning codebase and test suite.
- `Sourced`: behavior stated in a fetched first-party product or research page.
- `Hypothesis`: a Anchor Learning product choice that must be tested with alpha users.

Alpha targets in this document are hypotheses. They are not presented as
industry benchmarks.

## Research Method

`smart-search doctor --format json` found that the configured broad model route
was limited by an upstream HTTP 429. Tavily fetch and Context7 remained healthy.
The research therefore followed the documented source-first fallback: generate
a deep-research plan, fetch known first-party pages, and derive product claims
only from the fetched text. Native web search was not used.

Evidence was saved under:

```text
C:\tmp\smart-search-evidence\20260716-anchor-learning-private-alpha
```

## Current Anchor Learning Baseline

The product is not starting from a chat prototype. The current implementation
already has these observed capabilities:

- Local directory, ZIP, Android document-tree, text, and programming-source
  ingestion with source identity, revision, locator, and integrity metadata.
- Source-grounded knowledge extraction, human verification, project
  understanding, knowledge answers, tutoring, interviewing, programming
  exercises, weak-point memory, review actions, and deterministic next actions.
- One unified Agent workspace for project, programming, and mixed interview
  goals, backed by planner, policy, executor, checkpoint, trace, and memory
  contracts.
- Claim-level citation gates, partial/refused outcomes, deterministic retrieval
  evaluation, and a fixed source-grounded golden path.
- Provider-scoped API keys stored through `flutter_secure_storage`, Responses and
  Chat Completions routing, usage capture,
  diagnostics, and a fixed five-task model acceptance gate.

The current product gaps are primarily product-facing:

- No goal-led first-run experience that gets a new user from install to a
  meaningful source-grounded session.
- No product event contract for activation, task completion, learning outcome,
  reliability, or return behavior.
- No coherent interview outcome artifact that proves what the user can explain,
  where the evidence is, and what remains weak.
- No private-alpha feedback intake, consent boundary, or support bundle.
- No explicit release checklist covering data deletion, backup/export,
  accessibility, crash recovery, and supported-device behavior.

## Adjacent Product Findings

| Product | First-party evidence | Mechanism worth borrowing | Boundary for Anchor Learning |
| --- | --- | --- | --- |
| NotebookLM | Google states that flashcards and quizzes are generated from user documents, are grounded entirely in sources, and can explain answers with citations to original material. Its Learning Guide uses probing questions and step-by-step explanations. | Make each generated learning action visibly source-derived; allow explanation and deeper questioning from the same evidence. | Anchor Learning should specialize in code/project understanding, interview performance, durable weak-point memory, and next review rather than reproduce a general notebook studio. |
| ChatGPT Study Mode | OpenAI describes Socratic questions, hints, self-reflection, scaffolded responses, personalization, and knowledge checks; it also says the initial behavior was released through instructions to learn from real feedback despite possible inconsistency. | Calibrate from the learner's goal and current ability; prefer active participation over immediate answer delivery; use alpha feedback to improve behavior. | Anchor Learning's formal learning surfaces must remain constrained by stored sources and deterministic policy instead of relying only on conversational instructions. |
| Anki | The Anki manual identifies active recall and spaced repetition as its core mechanisms: attempting recall strengthens memory, failed recall reveals relearning needs, and review intervals expand with ease. | Measure retrieval attempts and schedule the next review rather than count passive reading. | Anchor Learning should schedule concepts, interview answers, and programming boundaries with evidence context, not become a general flashcard editor in Alpha. |
| RemNote | RemNote advertises one-click card creation from files or links followed by spaced-repetition practice across devices. | Keep source-to-practice setup short and make the next review immediately actionable. | Broad file/media ingestion and cross-device parity are later expansion paths; Alpha first proves the local project interview loop. |
| DeepWiki | Devin documents automatic repository wikis with architecture diagrams, source links, summaries, contextual questions, and explicit repo notes/pages to steer coverage; it warns AI responses may contain mistakes. | Let users direct which repository areas matter, expose file/line evidence, and produce a navigable project model. | A wiki is an intermediate representation. Anchor Learning's outcome is that the project owner can retrieve, explain, defend, and revisit the implementation. |
| Sourcegraph Cody | Sourcegraph describes retrieval of context from local and remote codebases, files, symbols, APIs, and usage patterns for code understanding and editing. | Context selection must understand repository structure and let users focus or exclude areas. | Anchor Learning is not an IDE coding assistant in Alpha; it converts selected project evidence into an assessed learning and interview loop. |

## Measurement And Trust Findings

- The Google HEART paper provides a reusable process for mapping product goals
  to user-centered metrics. Anchor Learning uses the categories as an organizing frame,
  not as preset thresholds.
- NIST describes AI risk management as lifecycle work across design,
  development, use, and evaluation. Product release controls therefore need
  traceability, testing, user-visible limitations, monitoring, and recovery;
  model output quality cannot be treated as a one-time prompt decision.
- The existing Anchor Learning correctness work already applies stronger source controls
  than most adjacent learning products: AI output is not a source, formal claims
  require stored evidence, and insufficient evidence becomes partial or refused
  output. Productization should make these controls understandable rather than
  hide them as implementation detail.

## Product Opportunity

The defensible product wedge is:

> Import the project you built and the official material behind it, then use one
> source-grounded Agent to learn, practice, explain, and revisit the exact
> knowledge needed to defend that project in an AI application interview.

This combines four mechanisms that adjacent products usually separate:

1. Repository and official-document evidence with inspectable locations.
2. Tutor, interview, and programming practice over the same target context.
3. Cross-surface weak-point memory and deterministic next action.
4. An outcome artifact showing what the user can explain and what evidence
   supports that explanation.

The product should not position itself as a generic second brain, a generic AI
chat app, an IDE copilot, or an automatic documentation generator.

## Product Decisions Derived From Evidence

1. Start with one narrow alpha persona: a developer preparing for AI application
   interviews who has at least one project they need to understand and explain.
2. Treat first value as a completed source-grounded learning turn, not a source
   upload, generated summary, account creation, or model connection.
3. Keep the first run goal-led: project interview, project understanding, or
   programming concept. The selected goal determines import guidance and the
   first Agent plan.
4. Preserve human verification before generated content enters formal learning.
5. Make citations, source quality, and evidence insufficiency visible in normal
   user language; do not force users to read runtime diagnostics.
6. Create a project interview outcome artifact from verified implementation and
   actual learning history, not a one-shot generated report.
7. Collect product events locally by default. Private-alpha export is explicit
   and inspectable; silent third-party behavioral tracking is not required to
   learn from the first cohort.
8. Keep remote runtime, cloud accounts, vector databases, and multi-agent
   orchestration behind the existing measured trigger gates.

## Official Sources

- [Google: NotebookLM student features](https://blog.google/innovation-and-ai/models-and-research/google-labs/notebooklm-student-features/)
- [NotebookLM Help: Flashcards and quizzes](https://support.google.com/notebooklm/answer/16958963?hl=en)
- [OpenAI: Introducing study mode](https://openai.com/index/chatgpt-study-mode/)
- [Anki Manual: Background](https://docs.ankiweb.net/background.html)
- [RemNote: AI Flashcards](https://www.remnote.com/any_source_to_cards)
- [Devin Docs: DeepWiki](https://docs.devin.ai/work-with-devin/deepwiki)
- [Sourcegraph Docs: Cody](https://sourcegraph.com/docs/cody)
- [Google Research: HEART framework](https://research.google/pubs/measuring-the-user-experience-on-a-large-scale-user-centered-metrics-for-web-applications/)
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)

## Reproducible Commands

```powershell
smart-search doctor --format json
smart-search deep "为一个面向 AI 应用开发面试和编程学习的可溯源个人知识库学习 Agent 制定 Private Alpha 产品契约：调研 NotebookLM、ChatGPT Study Mode、RemNote/Anki、DeepWiki/代码库理解产品的当前能力、差异化机会、可信来源原则、首用激活和学习效果指标" --budget deep --format json
smart-search fetch "https://blog.google/innovation-and-ai/models-and-research/google-labs/notebooklm-student-features/" --format markdown
smart-search fetch "https://support.google.com/notebooklm/answer/16958963?hl=en" --format markdown
smart-search fetch "https://openai.com/index/chatgpt-study-mode/" --format markdown
smart-search fetch "https://docs.ankiweb.net/background.html" --format markdown
smart-search fetch "https://www.remnote.com/any_source_to_cards" --format markdown
smart-search fetch "https://docs.devin.ai/work-with-devin/deepwiki" --format markdown
smart-search fetch "https://sourcegraph.com/docs/cody" --format markdown
smart-search fetch "https://research.google/pubs/measuring-the-user-experience-on-a-large-scale-user-centered-metrics-for-web-applications/" --format markdown
smart-search fetch "https://www.nist.gov/itl/ai-risk-management-framework" --format markdown
```
