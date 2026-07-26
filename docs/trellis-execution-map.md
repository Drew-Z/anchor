# Trellis Execution Map

## 推进方式

这个项目按 Trellis 方式推进：

```text
Root Goal
-> Branches
-> Leaves
-> Acceptance Gates
```

规则：

- 每次只做一个 leaf task。
- 每个 leaf task 必须有明确输入、输出、涉及文件和验收标准。
- 父分支未完成时，不做依赖它的后续分支。
- 每完成一个 leaf task，就运行可用检查，并更新状态。
- 不把 UI 装饰、复杂导入、RAG、云同步提前。

## Root Goal

把 Duoduo 从“AI 拆题 + 游戏化刷题 app”重建为：

```text
个人本地优先的 source-grounded learning agent
```

第一目标：

- 帮用户准备 AI 应用开发面试。
- 帮用户真正讲清楚自己 vibe coding 做出的项目。
- 帮用户学习编程知识，并保证内容有来源依据。

## Progress

```text
2026-07-08: Leaf 0.1 completed - established database migration entrypoint.
2026-07-08: Leaf 0.2 completed - matching preview now renders answer-based pairs.
2026-07-08: Leaf 0.3 completed - added deck/question/study repositories.
2026-07-08: Leaf 1.1 completed - added Source model, repository, and sources table.
2026-07-08: Leaf 1.2 completed - added SourceChunk model, repository, and source_chunks table.
2026-07-08: Leaf 1.3 completed - added KnowledgePoint models, repository, and relation tables.
2026-07-08: Leaf 1.4 completed - extended Question with knowledge, citation, and review fields.
2026-07-08: Leaf 2.1 completed - added AiTaskResult foundation.
2026-07-08: Leaf 2.2 completed - added KnowledgeExtractionTask draft output.
2026-07-08: Leaf 2.3 completed - added QuestionGenerationTask with citation-aware drafts.
2026-07-08: Leaf 2.4 completed - added CitationVerificationTask precheck output.
2026-07-08: Leaf 3.1 completed - added KnowledgeReviewScreen evidence display.
2026-07-08: Leaf 3.2 completed - added verified, pending, and delete review decisions.
2026-07-08: Leaf 3.3 completed - added manual question editing with pending reset.
2026-07-08: Leaf 4.1 completed - added project import wizard saving project source chunks.
2026-07-08: Leaf 4.2 completed - added code path and line range locators.
2026-07-08: Leaf 5.1 completed - added Agent tab and Agent home screen.
2026-07-08: Leaf 5.2 completed - added interviewer question and answer evaluation service layer.
2026-07-08: Leaf 5.3 completed - added learning session and interview turn persistence.
2026-07-08: Leaf 6.1 completed - added mastery service for knowledge point updates.
2026-07-08: Leaf 6.2 completed - added today review queue and scheduling writeback.
2026-07-08: Leaf 7.1 completed - added Knowledge Base tab with source, knowledge point, and pending review views.
2026-07-08: Leaf 7.2 completed - added source, knowledge point, and question evidence detail views.
2026-07-08: Leaf 8.1 completed - wired project import to AI draft generation, review, and persistence.
2026-07-08: Leaf 9.1 completed - activated interview agent UI with persisted turns and mastery updates.
2026-07-08: Leaf 9.2 completed - added interview history and evidence-backed review screens.
2026-07-08: Leaf 9.3 completed - activated source-grounded tutor mode for knowledge point explanations.
2026-07-08: Leaf 9.4 completed - activated review agent mode with due queue and weak point practice.
2026-07-08: Leaf 10.1 completed - routed text ingestion through source-grounded review and persistence.
2026-07-08: Leaf 10.2 completed - delayed project source persistence until review save.
2026-07-08: Leaf 10.3 completed - added pending question verification actions in Knowledge Base.
2026-07-08: Leaf 10.4 completed - centralized source-grounded ingestion rules in a shared service.
2026-07-08: Leaf 10.5 completed - restricted formal quiz entry points to verified questions.
2026-07-08: Leaf 10.6 completed - made reviewed source-grounded ingestion persistence transactional.
2026-07-08: Leaf 10.7 completed - aligned initial review status actions with citation rules.
2026-07-08: Leaf 10.8 completed - aligned deck study entry availability with verified question counts.
2026-07-08: Leaf 10.9 completed - separated all-question management providers from verified study providers.
2026-07-08: Leaf 10.10 completed - added an all-question management tab to Knowledge Base.
2026-07-08: Leaf 10.11 completed - added status filters to Knowledge Base all-question tab.
2026-07-08: Leaf 10.12 completed - linked knowledge point detail pages to related questions.
2026-07-08: Leaf 10.13 completed - linked source detail pages to related knowledge points.
2026-07-08: Leaf 10.14 completed - linked evidence chunks back to their source detail pages.
2026-07-08: Leaf 10.15 completed - linked question evidence pages back to their knowledge point.
2026-07-08: Leaf 10.16 completed - added learning actions to knowledge point detail pages.
2026-07-08: Leaf 10.17 completed - refreshed question and knowledge point providers after quiz attempts.
2026-07-08: Leaf 10.18 completed - restricted interview agent candidates to evidence-backed knowledge points.
2026-07-08: Leaf 10.19 completed - sanitized interview question drafts against known knowledge points and citations.
2026-07-08: Leaf 10.20 completed - sanitized interview answer evaluation ids against known context.
2026-07-08: Leaf 10.21 completed - sanitized extracted knowledge point source chunk ids against known chunks.
2026-07-08: Leaf 10.22 completed - sanitized generated question knowledge point and citation ids against known context.
2026-07-08: Leaf 10.23 completed - filtered question citation ids again before reviewed ingestion save.
2026-07-08: Leaf 10.24 completed - sanitized citation verification ids against provided cited chunks.
2026-07-08: Leaf 10.25 completed - filtered question citations before citation precheck fallback paths.
2026-07-08: Leaf 10.26 completed - required tutor explanations to keep only valid source citations.
2026-07-08: Leaf 10.27 completed - filtered interview turn citations against evaluated chunks before saving.
2026-07-08: Leaf 10.28 completed - restricted tutor mode point list to evidence-backed knowledge points.
2026-07-08: Leaf 10.29 completed - restricted review weak-point practice list to points with verified questions.
2026-07-08: Leaf 10.30 completed - cleaned citation ids during Knowledge Base status updates.
2026-07-08: Leaf 10.31 completed - made legacy image preview saves explicitly no-source and non-formal.
2026-07-08: Leaf 10.32 completed - refreshed Home learning state after quiz exits.
2026-07-08: Leaf 10.33 completed - refreshed deck library state after study and delete actions.
2026-07-08: Leaf 10.34 completed - refreshed knowledge point detail state after practice exits.
2026-07-08: Leaf 10.35 completed - routed image imports with text through source-grounded review.
2026-07-08: Leaf 10.36 completed - displayed source uri in source detail pages.
2026-07-08: Leaf 10.37 completed - added trust-level selection for regular text ingestion.
2026-07-08: Leaf 10.38 completed - surfaced Agent mode readiness on the Agent home screen.
2026-07-08: Leaf 10.39 completed - disabled knowledge point tutor action when evidence is missing.
2026-07-08: Leaf 10.40 completed - aligned tutor empty state with evidence-backed readiness.
2026-07-08: Leaf 10.41 completed - normalized no-source questions to empty citations.
2026-07-08: Leaf 10.42 completed - enforced no-source citation cleanup at model parse boundaries.
2026-07-08: Leaf 10.43 completed - enabled SQLite foreign key enforcement.
2026-07-08: Leaf 10.44 completed - restricted interview evaluation to question citations.
2026-07-08: Leaf 10.45 completed - required cited chunks for answer evaluation task.
2026-07-08: Leaf 10.46 completed - showed verified quiz citations after answering.
2026-07-08: Leaf 10.47 completed - added source trust labels to quiz citations.
2026-07-08: Leaf 10.48 completed - added source trust labels to tutor citations.
2026-07-08: Leaf 10.49 completed - added source trust labels to interview citations.
2026-07-08: Leaf 10.50 completed - extracted shared source citation block.
2026-07-08: Leaf 10.51 completed - hid review citations for no-source decisions.
2026-07-08: Leaf 10.52 completed - normalized interview ids at parse and persistence boundaries.
2026-07-08: Leaf 10.53 completed - deduplicated AI list fields at JSON parse boundaries.
2026-07-08: Leaf 10.54 completed - made Source parsing tolerant of missing trust metadata.
2026-07-08: Branch 10 closed - source-grounded learning loop is ready for agent planning work.
2026-07-08: Leaf 11.1 completed - added local learning agent planner model and provider.
2026-07-08: Leaf 11.2 completed - surfaced learning agent plan on Agent home.
2026-07-08: Leaf 11.3 completed - added learning agent goal switching on Agent home.
2026-07-08: Leaf 11.4 completed - routed learning agent next step to existing workflows.
2026-07-08: Leaf 11.5 completed - routed verification plan step directly to pending review tab.
2026-07-08: Leaf 11.6 completed - routed practice plan step directly to verified quiz.
2026-07-08: Leaf 11.7 completed - displayed the full learning route on Agent home.
2026-07-08: Leaf 11.8 completed - added disabled reasons to learning route steps.
2026-07-08: Leaf 11.9 completed - added local focus point recommendations to learning plans.
2026-07-08: Leaf 11.10 completed - started tutor plan steps from the top focus point.
2026-07-08: Leaf 11.11 completed - focused practice plan steps on recommended knowledge points.
2026-07-08: Leaf 11.12 completed - linked focus point recommendations to knowledge point details.
2026-07-08: Leaf 11.13 completed - persisted selected learning agent goal.
2026-07-08: Leaf 11.14 completed - displayed evidence and verified-question support for focus points.
2026-07-08: Leaf 11.15 completed - added learning agent session summary context.
2026-07-08: Leaf 11.16 completed - added learning agent execution preflight guard.
2026-07-08: Leaf 11.17 completed - started agent interview sessions from recommended focus points.
2026-07-08: Leaf 11.18 completed - focused review sessions on recommended knowledge points.
2026-07-08: Leaf 11.19 completed - centralized agent top focus point resolution.
2026-07-08: Leaf 11.20 completed - added a dedicated learning agent session launch screen.
2026-07-08: Leaf 11.21 completed - centralized learning agent session preflight rules.
2026-07-08: Leaf 11.22 completed - linked session launch focus points to knowledge details.
2026-07-08: Leaf 11.23 completed - previewed focus point evidence on the agent launch screen.
2026-07-08: Leaf 11.24 completed - previewed verified focus point questions on the agent launch screen.
2026-07-08: Leaf 11.25 completed - linked launch question previews to evidence details.
2026-07-08: Leaf 11.26 completed - surfaced plan blockers on the agent launch screen.
2026-07-08: Leaf 11.27 completed - added per-session success criteria to the agent launch screen.
2026-07-08: Leaf 11.28 completed - added per-session reflection prompts to the agent launch screen.
2026-07-08: Leaf 11.29 completed - kept agent launch screen open for completion review.
2026-07-08: Leaf 11.30 completed - reset completion review state when restarting a session.
2026-07-08: Leaf 11.31 completed - turned session success criteria into a local completion checklist.
2026-07-08: Leaf 11.32 completed - added local reflection notes to the session completion review.
2026-07-08: Leaf 11.33 completed - persisted agent session completion summaries.
2026-07-08: Leaf 11.34 completed - displayed saved agent session summaries on Agent home.
2026-07-08: Leaf 11.35 completed - added saved agent session detail review.
2026-07-08: Leaf 11.36 completed - linked saved agent sessions back to target knowledge points.
2026-07-08: Leaf 11.37 completed - saved checked success criteria in agent session summaries.
2026-07-08: Leaf 11.38 completed - saved next follow-up questions from agent session reviews.
2026-07-08: Leaf 11.39 completed - surfaced prior follow-up questions on agent session launch.
2026-07-08: Leaf 11.40 completed - added full agent session history list.
2026-07-08: Leaf 11.41 completed - added goal filters to agent session history.
2026-07-08: Leaf 11.42 completed - added follow-up-only filter to agent session history.
2026-07-08: Leaf 11.43 completed - centralized agent session summary parsing.
2026-07-08: Leaf 11.44 completed - surfaced local learning memory metrics on Agent home.
2026-07-08: Leaf 11.45 completed - linked Agent home follow-up metrics to filtered history.
2026-07-08: Leaf 11.46 completed - linked Agent home goal metrics to filtered history.
2026-07-08: Leaf 11.47 completed - added local search to agent session history.
2026-07-08: Leaf 11.48 completed - added clear filters action to agent session history.
2026-07-08: Leaf 11.49 completed - showed goal counts in agent session history filters.
2026-07-08: Leaf 11.50 completed - passed prior follow-up questions into tutor sessions.
2026-07-08: Leaf 11.51 completed - passed prior follow-up questions into interview sessions.
2026-07-08: Leaf 11.52 completed - added follow-up learning actions to agent session details.
2026-07-08: Leaf 11.53 completed - refreshed learning records after follow-up actions.
2026-07-08: Leaf 11.54 completed - saved active follow-up questions in agent session summaries.
2026-07-08: Leaf 11.55 completed - inferred open follow-up questions from agent session history.
2026-07-08: Leaf 11.56 completed - hid follow-up actions for already handled questions.
2026-07-08: Leaf 11.57 completed - recorded handled follow-ups only after completed learning actions.
2026-07-08: Leaf 11.58 completed - surfaced follow-up action completion feedback.
2026-07-08: Leaf 11.59 completed - prevented duplicate follow-up action launches.
2026-07-08: Leaf 11.60 completed - reused open follow-up inference on the session launch screen.
2026-07-08: Leaf 11.61 completed - surfaced follow-up status on recent Agent Session cards.
2026-07-08: Leaf 11.62 completed - recorded launch follow-ups only after completed learning actions.
2026-07-08: Leaf 11.63 completed - hardened launch follow-up completion count null safety.
2026-07-08: Leaf 11.64 completed - surfaced launch follow-up completion feedback.
2026-07-08: Leaf 11.65 completed - centralized completed learning session point matching.
2026-07-08: Leaf 11.66 completed - showed open follow-up count in history filters.
2026-07-08: Leaf 11.67 completed - scoped history follow-up count to the selected goal.
2026-07-08: Leaf 11.68 completed - surfaced selected-goal follow-up memory on Agent home.
2026-07-08: Leaf 11.69 completed - centralized goal-scoped open follow-up counts.
2026-07-08: Leaf 11.70 completed - added history filter follow-up summary text.
2026-07-08: Leaf 11.71 completed - tailored empty history states to active filters.
2026-07-08: Leaf 11.72 completed - added clear-filter action to empty history states.
2026-07-08: Leaf 11.73 completed - showed target follow-up backlog on the session launch screen.
2026-07-08: Leaf 11.74 completed - linked launch follow-up backlog to target-filtered history.
2026-07-08: Leaf 11.75 completed - labeled target-filtered Agent Session history views.
2026-07-08: Leaf 11.76 completed - allowed clearing only the target history filter.
2026-07-08: Leaf 11.77 completed - cleared target filters when switching history goal chips.
2026-07-08: Leaf 11.78 completed - always exposed full Agent Session history when records exist.
2026-07-08: Leaf 11.79 completed - aligned earlier history-entry docs with current behavior.
2026-07-08: Leaf 11.80 completed - showed Agent Session total count on the home history entry.
2026-07-08: Leaf 11.81 completed - showed counts on Agent memory history action labels.
2026-07-08: Leaf 11.82 completed - surfaced selected-goal follow-up reminders in the plan card.
2026-07-08: Leaf 11.83 completed - linked the plan card to selected-goal Agent Session history.
2026-07-08: Leaf 11.84 completed - centralized selected-goal Agent Session counts.
2026-07-09: Leaf 11.85 completed - precomputed Agent Session follow-up counts.
2026-07-09: Leaf 11.86 completed - reused an Agent Session memory index on Agent home.
2026-07-09: Leaf 11.87 completed - reused the Agent Session memory index on history views.
2026-07-09: Leaf 11.88 completed - reused the Agent Session memory index on launch follow-ups.
2026-07-09: Leaf 11.89 completed - reused the Agent Session memory index on detail follow-up status.
2026-07-09: Leaf 11.90 completed - moved Agent Session memory parsing to the service layer.
2026-07-09: Leaf 11.91 completed - added an Agent Session memory index provider.
2026-07-09: Leaf 11.92 completed - reused the Agent Session memory provider on launch and detail views.
2026-07-09: Leaf 11.93 completed - explicitly refreshed Agent Session memory after session changes.
2026-07-09: Leaf 11.94 completed - passed Agent Session memory context into learning plans.
2026-07-09: Leaf 11.95 completed - made the plan card read Agent memory from the plan.
2026-07-09: Leaf 11.96 completed - surfaced Agent memory reminders in session summaries.
2026-07-09: Leaf 11.97 completed - surfaced Agent memory reminders on the launch screen.
2026-07-09: Leaf 11.98 completed - prioritized open follow-ups in the learning route.
2026-07-09: Leaf 11.99 completed - labeled learning route step counts with units.
2026-07-09: Leaf 11.100 completed - prevented follow-up history routing from creating empty completions.
2026-07-09: Leaf 11.101 completed - used a dedicated primary action for follow-up route steps.
2026-07-09: Leaf 11.102 completed - exposed a continue action on open follow-up history cards.
2026-07-09: Leaf 11.103 completed - normalized Agent Session memory ordering by start time.
2026-07-09: Leaf 11.104 completed - added latest same-goal Agent Session context to memory reminders.
2026-07-09: Leaf 11.105 completed - linked the Agent memory bar to the latest same-goal review.
2026-07-09: Leaf 11.106 completed - surfaced the latest same-goal review on the launch screen.
2026-07-09: Leaf 11.107 completed - summarized goal and follow-up status on review details.
2026-07-09: Leaf 11.108 completed - linked review details back to same-goal history.
2026-07-09: Leaf 11.109 completed - linked review details to same-target history.
2026-07-09: Leaf 11.110 completed - showed follow-up backlog counts on review history actions.
2026-07-09: Leaf 11.111 completed - made review detail goal typing explicit.
2026-07-09: Leaf 11.112 completed - showed same-target session counts on review history actions.
2026-07-09: Leaf 11.113 completed - clarified target-filtered history summaries.
2026-07-09: Leaf 11.114 completed - normalized target ids for memory and history lookups.
2026-07-09: Leaf 11.115 completed - normalized target filter state in history views.
2026-07-09: Leaf 11.116 completed - fixed review detail history action button structure.
2026-07-09: Leaf 11.117 completed - centralized Agent Session target id normalization.
2026-07-09: Leaf 11.118 completed - clarified same-target counts in history filters.
2026-07-09: Leaf 11.119 completed - persisted follow-up questions on tutor and interview sessions.
2026-07-09: Leaf 11.120 completed - matched completed follow-up sessions by question text.
2026-07-09: Leaf 11.121 completed - surfaced follow-up questions on recent interview cards.
2026-07-09: Leaf 11.122 completed - centralized learning session follow-up parsing.
2026-07-09: Leaf 11.123 completed - surfaced recent tutor sessions on Agent Home.
2026-07-09: Leaf 11.124 completed - linked recent tutor sessions to knowledge point details.
2026-07-09: Leaf 11.125 completed - refreshed Agent Home inputs after direct mode sessions.
2026-07-09: Leaf 11.126 completed - refreshed Agent Home after Agent Session history routes.
2026-07-09: Leaf 11.127 completed - refreshed Agent Home after Agent Session detail routes.
2026-07-09: Leaf 11.128 completed - refreshed learning activity providers from Agent Session launch.
2026-07-09: Leaf 11.129 completed - refreshed Agent Session memory from launch actions.
2026-07-09: Leaf 11.130 completed - consolidated launch screen learning record refreshes.
2026-07-09: Leaf 11.131 completed - centralized Agent learning record provider refreshes.
2026-07-09: Leaf 11.132 completed - reused Agent learning record refreshes after ordinary sessions.
2026-07-09: Leaf 11.133 completed - reused Agent Home session refreshes after direct modes.
2026-07-09: Leaf 11.134 completed - centralized learning agent plan input refreshes.
2026-07-09: Leaf 11.135 completed - consolidated review agent input refreshes.
2026-07-09: Leaf 11.136 completed - routed recent interview details through Agent Home refreshes.
2026-07-09: Leaf 11.137 completed - routed knowledge point details through Agent Home refreshes.
2026-07-09: Branch 11 closed - local learning Agent workflow is ready for knowledge search work.
2026-07-09: Leaf 12.1 completed - added local knowledge search corpus providers.
2026-07-09: Leaf 12.2 completed - surfaced local knowledge search in Knowledge Base.
2026-07-09: Leaf 12.3 completed - realigned Knowledge Base tab entry indexes.
2026-07-09: Leaf 12.4 completed - highlighted matched source chunks from search results.
2026-07-09: Leaf 12.5 completed - ranked knowledge search by source trust and verification.
2026-07-09: Leaf 12.6 completed - added source-grounded knowledge answer task.
2026-07-09: Leaf 12.7 completed - derived answer context chunks from knowledge search.
2026-07-09: Leaf 12.8 completed - added source-grounded answers to Knowledge Base search.
2026-07-09: Leaf 12.9 completed - highlighted cited chunks when opening their source.
2026-07-09: Leaf 12.10 completed - made source-grounded answer follow-ups searchable.
2026-07-09: Leaf 12.11 completed - saved source-grounded knowledge answers as learning records.
2026-07-09: Leaf 12.12 completed - surfaced recent knowledge answers in search.
2026-07-09: Leaf 12.13 completed - centralized knowledge answer summary parsing.
2026-07-09: Leaf 12.14 completed - surfaced recent knowledge answers on Agent Home.
2026-07-09: Leaf 12.15 completed - fixed knowledge answer search resume refreshes.
2026-07-09: Leaf 12.16 completed - centralized knowledge answer summary writing.
2026-07-09: Leaf 12.17 completed - refreshed knowledge search after question verification changes.
2026-07-09: Leaf 12.18 completed - parsed knowledge answer trace metadata for recent records.
2026-07-09: Leaf 12.19 completed - added knowledge answer review detail entries.
2026-07-09: Leaf 12.20 completed - routed knowledge answer follow-ups back to search.
2026-07-09: Leaf 12.21 completed - surfaced source titles on knowledge answer citations.
2026-07-09: Leaf 12.22 completed - added full knowledge answer history search.
2026-07-09: Leaf 12.23 completed - added source-gap filter to knowledge answer history.
2026-07-09: Leaf 12.24 completed - added missing-citation filter to knowledge answer history.
2026-07-09: Leaf 12.25 completed - summarized evidence quality in knowledge answer history.
2026-07-09: Leaf 12.26 completed - added clear filters action to knowledge answer history.
2026-07-09: Leaf 12.27 completed - made knowledge answer quality stats filterable.
2026-07-09: Leaf 12.28 completed - linked knowledge answer citations to source details.
2026-07-09: Leaf 12.29 completed - routed knowledge answer source gaps back to search.
2026-07-09: Leaf 12.30 completed - labeled citation-highlighted source chunks clearly.
2026-07-09: Leaf 12.31 completed - matched highlighted source chunk icons to context.
2026-07-09: Leaf 12.32 completed - centralized knowledge answer quality stats.
2026-07-09: Leaf 12.33 completed - surfaced knowledge answer quality debt on Agent Home.
2026-07-09: Leaf 12.34 completed - allowed initial quality filters for knowledge answer history.
2026-07-09: Leaf 12.35 completed - routed Agent Home quality notice to filtered history.
2026-07-09: Leaf 12.36 completed - surfaced knowledge answer quality debt in Knowledge Base.
2026-07-09: Leaf 12.37 completed - reused the knowledge answer quality notice component.
2026-07-09: Leaf 12.38 completed - allowed initial search text for knowledge answer history.
2026-07-09: Leaf 12.39 completed - summarized active filters in knowledge answer history.
2026-07-09: Leaf 12.40 completed - routed live answer source gaps back to search.
2026-07-09: Leaf 12.41 completed - surfaced missing citations on knowledge answer records.
2026-07-09: Leaf 12.42 completed - added evidence repair actions to knowledge answer history cards.
2026-07-09: Leaf 12.43 completed - centralized knowledge answer evidence repair queries.
2026-07-09: Leaf 12.44 completed - reused evidence repair actions on recent knowledge answer entries.
2026-07-09: Leaf 12.45 completed - reused evidence repair actions on knowledge answer details.
2026-07-09: Leaf 12.46 completed - included trace labels in knowledge answer history search.
2026-07-09: Leaf 12.47 completed - clarified missing citation evidence repair guidance.
2026-07-09: Leaf 12.48 completed - clarified evidence repair action tooltips.
2026-07-09: Leaf 12.49 completed - centralized knowledge answer evidence repair kind.
2026-07-09: Leaf 12.50 completed - included evidence repair action labels in history search.
2026-07-09: Leaf 12.51 completed - summarized repairable knowledge answer count.
2026-07-09: Leaf 12.52 completed - added repairable filter to knowledge answer history.
2026-07-09: Leaf 12.53 completed - routed repairable notices to filtered history.
2026-07-09: Leaf 12.54 completed - aligned knowledge answer history search hint with searchable labels.
2026-07-09: Leaf 12.55 completed - colored active knowledge answer history filters semantically.
2026-07-09: Leaf 12.56 completed - clarified empty states for filtered knowledge answer history.
2026-07-09: Leaf 12.57 completed - surfaced active filters in the knowledge answer history title.
2026-07-09: Leaf 12.58 completed - distinguished repairable and non-repairable evidence quality debt.
2026-07-09: Leaf 12.59 completed - surfaced clean and quality-debt knowledge answer counts.
2026-07-09: Leaf 12.60 completed - added clean-evidence filtering to knowledge answer history.
2026-07-09: Leaf 12.61 completed - routed clean-evidence quality notices to filtered history.
2026-07-09: Leaf 12.62 completed - labeled clean-evidence knowledge answers in trace metadata.
2026-07-09: Leaf 12.63 completed - styled clean-evidence trace labels semantically.
2026-07-09: Leaf 12.64 completed - centralized knowledge answer evidence quality getters.
2026-07-09: Leaf 12.65 completed - added evidence quality badges to knowledge answer history cards.
2026-07-09: Leaf 12.66 completed - reused evidence quality badges in recent knowledge answer previews.
2026-07-09: Leaf 12.67 completed - added explanations to evidence quality badges.
2026-07-09: Leaf 12.68 completed - added evidence quality guidance to knowledge answer details.
2026-07-09: Leaf 12.69 completed - surfaced live answer evidence quality before saving.
2026-07-09: Leaf 12.70 completed - centralized evidence quality guidance text.
2026-07-09: Leaf 12.71 completed - included evidence quality badge labels in history search.
2026-07-09: Leaf 12.72 completed - added needs-review filtering for knowledge answer quality debt.
2026-07-09: Leaf 12.73 completed - added quality-debt filtering to knowledge answer history.
2026-07-09: Leaf 12.74 completed - routed quality-debt notices to filtered history.
2026-07-09: Leaf 12.75 completed - made quality-debt records searchable by label.
2026-07-09: Leaf 12.76 completed - centralized repairable and needs-review quality getters.
2026-07-09: Leaf 12.77 completed - added tooltips to knowledge answer history stats.
2026-07-09: Leaf 12.78 completed - surfaced missing citation ids in knowledge answer details.
2026-07-09: Leaf 12.79 completed - confirmed full citation coverage in knowledge answer details.
2026-07-09: Leaf 12.80 completed - surfaced missing citation source records in knowledge answer details.
2026-07-09: Leaf 12.81 completed - summarized citation coverage in knowledge answer details.
2026-07-09: Leaf 12.82 completed - allowed copying unresolved citation identifiers.
2026-07-09: Leaf 12.83 completed - allowed copying citation chunk ids from detail cards.
2026-07-09: Leaf 12.84 completed - exposed missing source ids on citation cards.
2026-07-09: Leaf 12.85 completed - clarified citation card open-source action.
2026-07-09: Leaf 12.86 completed - summarized citation source trust in knowledge answer details.
2026-07-09: Leaf 12.87 completed - stabilized citation source trust summary order.
2026-07-09: Leaf 12.88 completed - clarified citation coverage summary tooltip.
2026-07-09: Leaf 12.89 completed - hid empty citation source trust summary.
2026-07-09: Leaf 12.90 completed - clarified unknown trust label in citation summary.
2026-07-09: Leaf 12.91 completed - added copyable knowledge answer review text.
2026-07-09: Leaf 12.92 completed - added copy review action to knowledge answer history cards.
2026-07-09: Leaf 12.93 completed - added copy review action to agent home recent answers.
2026-07-09: Leaf 12.94 completed - added copy review action to knowledge base recent answers.
2026-07-09: Leaf 12.95 completed - extracted shared knowledge answer review copy button.
2026-07-09: Leaf 12.96 completed - included evidence guidance in copied answer review text.
2026-07-09: Leaf 12.97 completed - included repair action query in copied answer review text.
2026-07-09: Leaf 12.98 completed - included trace labels in copied answer review text.
2026-07-09: Leaf 12.99 completed - made missing citations explicit in copied answer review text.
2026-07-09: Leaf 12.100 completed - clarified copied answer review snackbar feedback.
2026-07-09: Leaf 12.101 completed - clarified copied answer review tooltip.
2026-07-09: Leaf 12.102 completed - made source gap absence explicit in copied answer review text.
2026-07-09: Leaf 12.103 completed - made follow-up absence explicit in copied answer review text.
2026-07-09: Leaf 12.104 completed - made answer absence explicit in copied answer review text.
2026-07-09: Leaf 12.105 completed - made key point absence explicit in copied answer review text.
2026-07-09: Leaf 12.106 completed - made question absence explicit in copied answer review text.
2026-07-09: Leaf 12.107 completed - made completion time absence explicit in copied answer review text.
2026-07-09: Leaf 12.108 completed - added copy review action to immediate knowledge answer panel.
2026-07-09: Leaf 12.109 completed - allowed custom tooltip for immediate answer review copy action.
2026-07-09: Leaf 12.110 completed - included record status in immediate copied answer review text.
2026-07-09: Leaf 12.111 completed - allowed custom snackbar for immediate answer review copy action.
2026-07-09: Leaf 12.112 completed - allowed citation context in copied answer review text.
2026-07-09: Leaf 12.113 completed - included immediate answer citation context in copied review text.
2026-07-09: Leaf 12.114 completed - clarified truncated or empty citation context in copied review text.
2026-07-09: Leaf 12.115 completed - included detail citation context in copied answer review text.
2026-07-09: Leaf 12.116 completed - centralized copied citation context formatting.
2026-07-09: Leaf 12.117 completed - included saved record status in copied answer review text.
2026-07-09: Leaf 12.118 completed - included saved timestamp in immediate copied answer review text.
2026-07-09: Leaf 12.119 completed - included generated timestamp in immediate copied answer review text.
2026-07-09: Leaf 12.120 completed - displayed saved timestamp in immediate answer panel status.
2026-07-09: Leaf 12.121 completed - displayed generated timestamp in unsaved immediate answer panel status.
2026-07-09: Leaf 12.122 completed - displayed saving status in immediate answer panel and copied review text.
2026-07-09: Leaf 12.123 completed - added retry save action for failed immediate answer records.
2026-07-09: Leaf 12.124 completed - showed citation id save count in immediate answer saving and retry states.
2026-07-09: Leaf 12.125 completed - recorded immediate answer save failure time in panel and copied review.
2026-07-09: Leaf 12.126 completed - tracked immediate answer save attempt count across retries.
2026-07-09: Leaf 12.127 completed - added retry action for failed immediate answer generation.
2026-07-09: Leaf 12.128 completed - displayed retry source chunk count after immediate answer generation failure.
2026-07-09: Leaf 12.129 completed - recorded immediate answer generation failure time.
2026-07-09: Leaf 12.130 completed - tracked immediate answer generation attempt count.
2026-07-09: Leaf 12.131 completed - added copyable diagnostic text for immediate answer generation failure.
2026-07-09: Leaf 12.132 completed - separated fresh answer generation count from retry count.
2026-07-09: Leaf 12.133 completed - included generation retry success status in copied answer review.
2026-07-09: Leaf 12.134 completed - included source chunk summaries in copied answer generation failure diagnostics.
2026-07-09: Leaf 12.135 completed - added copyable diagnostics for immediate answer record save failures.
2026-07-09: Leaf 12.136 completed - added retry and diagnostics for answer context loading failures.
2026-07-09: Leaf 12.137 completed - added copyable diagnostics for no answer context matches.
2026-07-09: Leaf 12.138 completed - added refresh action for no answer context matches.
2026-07-09: Leaf 12.139 completed - added source tab shortcut for no answer context matches.
2026-07-09: Leaf 12.140 completed - added source import entry from empty sources tab.
2026-07-09: Leaf 12.141 completed - added source import entry at top of populated sources list.
2026-07-09: Leaf 12.142 completed - added retry and diagnostics for source list loading failures.
2026-07-09: Leaf 12.143 completed - centralized reusable knowledge library error recovery UI.
2026-07-09: Leaf 12.144 completed - added retry and diagnostics for knowledge point list loading failures.
2026-07-09: Leaf 12.145 completed - added retry and diagnostics for question list loading failures.
2026-07-09: Leaf 12.146 completed - added retry and diagnostics for pending verification list loading failures.
2026-07-09: Leaf 12.147 completed - added retry and query diagnostics for search result loading failures.
2026-07-09: Leaf 12.148 completed - added retry and diagnostics for recent knowledge answer loading failures.
2026-07-09: Leaf 12.149 completed - added retry and diagnostics for source detail loading failures.
2026-07-09: Leaf 12.150 completed - added retry and diagnostics for knowledge point detail loading failures.
2026-07-09: Leaf 12.151 completed - added retry and diagnostics for question evidence loading failures.
2026-07-09: Leaf 12.152 completed - removed the obsolete plain knowledge base error state.
2026-07-09: Leaf 12.153 completed - shared knowledge library error recovery UI across screens.
2026-07-09: Leaf 12.154 completed - added retry and diagnostics for knowledge answer detail citation loading failures.
2026-07-09: Leaf 12.155 completed - added retry and diagnostics for Agent Home knowledge answer loading failures.
2026-07-09: Leaf 12.156 completed - added retry and diagnostics for Agent Home readiness loading failures.
2026-07-09: Leaf 12.157 completed - added retry and diagnostics for chunk source loading failures.
2026-07-09: Leaf 12.158 completed - added retry and diagnostics for missing chunk source records.
2026-07-09: Leaf 12.159 completed - added retry and diagnostics to shared source citation blocks.
2026-07-09: Leaf 12.160 completed - added retry and diagnostics for Agent Home recent record loading failures.
2026-07-09: Leaf 12.161 completed - added retry and diagnostics for Agent Home learning plan loading failures.
2026-07-09: Leaf 12.162 completed - added retry and diagnostics for Agent Session history loading failures.
2026-07-09: Leaf 12.163 completed - added retry and diagnostics for Agent Session detail knowledge point loading failures.
2026-07-09: Leaf 12.164 completed - added retry and diagnostics for interview review loading failures.
2026-07-09: Leaf 12.165 completed - added retry and diagnostics for quiz citation loading failures.
2026-07-09: Leaf 12.166 completed - added retry and diagnostics for review agent loading failures.
2026-07-09: Leaf 12.167 completed - added retry and diagnostics for tutor mode loading and generation failures.
2026-07-09: Leaf 12.168 completed - added retry and diagnostics for Agent Session launch preview loading failures.
2026-07-09: Leaf 12.169 completed - added retry and diagnostics for Agent Session launch history loading failures.
2026-07-09: Leaf 12.170 completed - added retry and diagnostics for Agent Session completion save failures.
2026-07-09: Leaf 12.171 completed - added retry and diagnostics for deck list loading failures.
2026-07-09: Leaf 13.1 completed - documented the local-first agent runtime architecture decision.
2026-07-09: Leaf 13.2 completed - added the LearningAgentState model for runtime phases and evidence context.
2026-07-09: Leaf 13.3 completed - added pure LearningAgentPolicy checks for source-grounded runtime gates.
2026-07-09: Leaf 13.4 completed - added LearningAgentTraceEvent model for local runtime traces.
2026-07-09: Leaf 13.5 completed - added LearningAgentToolRegistry metadata for runtime tools.
2026-07-09: Leaf 13.6 completed - introduced LearningAgentExecutor and moved Agent Session startup dispatch out of the UI.
2026-07-09: Leaf 13.7 completed - added executor policy gates with copyable launch-screen diagnostics.
2026-07-09: Leaf 13.8 completed - recorded local agent trace events in execution results and saved Agent Session summaries.
2026-07-09: Leaf 13.9 completed - added LearningAgentMemoryStore facade and connected planner memory input to it.
2026-07-09: Leaf 13.10 completed - added LearningAgentRuntime session preparation and wired launch execution through it.
2026-07-09: Leaf 13.11 completed - routed executor follow-up lookup through LearningAgentMemoryStore.
2026-07-09: Leaf 13.12 completed - exposed LearningAgentExecutor through a provider and removed concrete executor construction from the launch UI.
2026-07-09: Leaf 13.13 completed - moved runtime/executor providers into an agent provider file to avoid core provider import cycles.
2026-07-09: Leaf 13.14 completed - surfaced Agent Session trace on the completion review panel before saving.
2026-07-09: Leaf 13.15 completed - centralized Agent Trace text formatting for summaries, diagnostics, and memory parsing.
2026-07-09: Leaf 13.16 completed - added a lightweight Agent Trace recorder to keep event lists and runtime state trace ids aligned.
2026-07-09: Leaf 13.17 completed - centralized Agent runtime phase transitions in a pure state transition policy.
2026-07-09: Leaf 13.18 completed - centralized Agent runtime state diagnostics for executor and launch-screen failure reports.
2026-07-09: Leaf 13.19 completed - added Agent Session resume readiness policy and diagnostics without enabling actual resume.
2026-07-09: Leaf 13.20 completed - defined the Agent Session resume trace event contract without recording resume events.
2026-07-09: Leaf 13.21 completed - added an Agent runtime contract barrel and routed feature-layer runtime imports through it.
2026-07-09: Leaf 13.22 completed - added copyable Agent runtime contract checklist diagnostics.
2026-07-09: Leaf 13.23 completed - surfaced an Agent runtime interview explanation card on the Agent Session launch screen.
2026-07-09: Leaf 13.24 completed - added runtime interview self-test prompts to the Agent Session explanation card.
2026-07-09: Leaf 13.25 completed - added answer outlines to Agent runtime interview self-test prompts.
2026-07-09: Leaf 13.26 completed - added copyable Agent runtime interview study notes.
2026-07-09: Leaf 13.27 completed - added framework mapping to Agent runtime interview notes.
2026-07-09: Leaf 13.28 completed - added honest runtime boundary notes to Agent interview materials.
2026-07-09: Leaf 13.29 completed - added code evidence anchors to Agent runtime interview notes.
2026-07-09: Leaf 13.30 completed - added a 60-second Agent runtime interview answer script.
2026-07-09: Leaf 13.31 completed - added an Agent runtime interview answer rubric.
2026-07-09: Leaf 13.32 completed - added single-action copying for the 60-second runtime answer.
2026-07-09: Leaf 13.33 completed - added external framework source references to Agent runtime interview notes.
2026-07-10: Leaf 13.34 completed - added trust labels to Agent runtime external source references.
2026-07-10: Leaf 13.35 completed - added verification metadata to Agent runtime external source references.
2026-07-10: Leaf 13.36 completed - compacted Agent runtime interview card sections without truncating study material.
2026-07-10: Leaf 13.37 completed - added a copyable Agent runtime interview Q&A practice packet.
2026-07-10: Leaf 13.38 completed - added evidence hints to Agent runtime interview prompts.
2026-07-10: Leaf 13.39 completed - added evidence coverage summaries to Agent runtime interview materials.
2026-07-10: Leaf 13.40 completed - added sample answers to Agent runtime interview prompts.
2026-07-10: Leaf 13.41 completed - added self-check criteria to Agent runtime interview prompts.
2026-07-10: Leaf 13.42 completed - added a structured Agent runtime interview practice flow.
2026-07-10: Leaf 13.43 completed - added a copyable blind drill sheet for Agent runtime interview practice.
2026-07-10: Leaf 13.44 completed - consolidated Agent runtime interview copy actions into a menu.
2026-07-10: Leaf 13.45 completed - added Agent runtime interview glossary terms.
2026-07-10: Leaf 13.46 completed - added Agent runtime interview pitfall guardrails.
2026-07-10: Leaf 13.47 completed - added Agent runtime framework evolution roadmap.
2026-07-10: Leaf 13.48 completed - added Agent runtime architecture decision records.
2026-07-10: Leaf 13.49 completed - added Agent runtime framework migration triggers.
2026-07-10: Leaf 13.50 completed - added Agent runtime maturity ladder.
2026-07-10: Leaf 13.51 completed - added Agent runtime framework selection matrix.
2026-07-10: Leaf 13.52 completed - added Agent runtime code walkthrough route.
2026-07-10: Leaf 13.53 completed - added Agent runtime debugging scenarios.
2026-07-10: Leaf 13.54 completed - added Agent runtime debugging drill copy packet.
2026-07-10: Leaf 13.55 completed - added Agent runtime interview demo script.
2026-07-10: Leaf 13.56 completed - added Agent runtime source-grounding audit checklist.
2026-07-10: Leaf 13.57 completed - added Agent runtime interview answer frames.
2026-07-10: Leaf 13.58 completed - added Agent runtime interview challenge responses.
2026-07-10: Leaf 13.59 completed - added Agent runtime challenge drill copy packet.
2026-07-10: Leaf 13.60 completed - added Agent runtime experience stories.
2026-07-10: Leaf 13.61 completed - added Agent runtime experience drill copy packet.
2026-07-10: Leaf 13.62 completed - added Agent runtime mock interview rounds.
2026-07-10: Leaf 13.63 completed - added Agent runtime mock interview drill copy packet.
2026-07-10: Leaf 13.64 completed - added Agent runtime mock interview score rules.
2026-07-10: Leaf 13.65 completed - added Agent runtime mock interview score sheet copy packet.
2026-07-10: Leaf 13.66 completed - added Agent runtime mock interview repair drills.
2026-07-10: Leaf 13.67 completed - added Agent runtime mock interview repair drill copy packet.
2026-07-13: Branch 13 closed - local Agent runtime contracts and interview learning material are established.
2026-07-13: Leaf 14.1 completed - added SQLite-backed Agent runtime checkpoint persistence.
2026-07-13: Leaf 14.2 completed - persisted Agent checkpoints across prepare, result, and reflection lifecycle stages.
2026-07-13: Leaf 14.3 completed - added plan-snapshot-backed cross-restart Agent Session resume.
2026-07-14: Leaf 14.4 completed - added structured human-in-the-loop resume decisions.
2026-07-14: Leaf 14.5 completed - added revision-based checkpoint optimistic concurrency.
2026-07-14: Leaf 14.6 completed - added a durable checkpoint before real tool invocation.
2026-07-14: Leaf 14.7 completed - added attempt-based unknown tool outcome recovery with explicit user reconciliation.
2026-07-14: Leaf 14.8 completed - separated stable tool operation identity from per-invocation attempt identity.
2026-07-14: Leaf 14.9 completed - added persisted routing-input snapshots and rejected changed-input retries before tool start.
2026-07-14: Branch 14 closed - durable local Agent Sessions are frozen at the MVP boundary; further idempotency work is deferred until remote tools exist.
2026-07-14: Leaf 15.1 completed - restored Flutter 3.44.6 and Dart 3.12.2 for repeatable project verification.
2026-07-14: Leaf 15.2 completed - dependency resolution, formatting, analysis, and the 44-test suite pass.
2026-07-14: Leaf 15.3 completed - verified schema v12 migration and durable Agent checkpoint compatibility.
2026-07-14: Leaf 15.4 completed - added a source-drift-checked golden-path fixture, production-chain test, and acceptance document.
2026-07-14: Leaf 15.5 completed - built, installed, and cold-started the Android debug app without Flutter, AndroidRuntime, or ANR failures.
2026-07-14: Branch 15 closed - the engineering gates and project-material-to-review golden path are reproducible; Branch 16 project source ingestion is next.
2026-07-14: Leaf 16.1 completed - defined directory/ZIP snapshots and structured file/line/hash/revision provenance.
2026-07-14: Leaf 16.2 completed - added desktop directory, ZIP, and Android SAF tree import with persisted URI access.
2026-07-14: Leaf 16.3 completed - enforced generated, sensitive, path, encoding, binary, count, and byte safety limits.
2026-07-14: Leaf 16.4 completed - added file selection UI and persisted source/chunk provenance through schema v13.
2026-07-14: Leaf 16.5 completed - 51 tests, analyzer and Android API 36 directory/ZIP acceptance passed.
2026-07-14: Branch 16 closed - local project source ingestion is usable and verifiable; Branch 17 project understanding is next.
2026-07-14: Leaf 17.1 completed - added schema v14 typed project-understanding units with backward-compatible concept migration.
2026-07-14: Leaf 17.2 completed - project import now generates source-only typed units and previews each unit's cited code before save.
2026-07-15: Leaf 17.3 completed - added explicit unit decisions, safe associated-question filtering, knowledge-only saves, and clickable evidence-backed code walkthroughs.
2026-07-15: Leaf 17.4 completed - converted project interviews to auditable one-question turns with deterministic stage progression and evidence-grounded answer-gap follow-ups.
2026-07-15: Leaf 17.5 completed - persisted cited weak-dimension review actions, atomically scheduled verified questions, and exposed focused review/interview retry entries.
2026-07-15: Branch 17 closed - project source now flows through typed understanding, explicit verification, evidence-focused interview, weak-point review, and next-interview scheduling.
```

## Branch 0：Baseline Stabilization

目的：让现有项目具备安全扩展基础。

### Leaf 0.1：建立数据库迁移入口

输入：

- 当前 `DatabaseHelper`。

输出：

- `openDatabase` 支持 `onUpgrade`。
- 数据库版本管理有清晰注释。

涉及文件：

```text
lib/data/database/database_helper.dart
```

验收：

- 现有表创建逻辑不破坏。
- 后续新增表可以通过版本升级实现。

### Leaf 0.2：修复匹配题预览错配风险

输入：

- 当前 `DeckPreviewScreen`。
- 匹配题 `answer` 字段。

输出：

- 预览页按 `answer` 展示正确匹配关系，而不是直接按左右数组下标配对。

涉及文件：

```text
lib/features/ingestion/deck_preview_screen.dart
```

验收：

- `match_right` 即使被打乱，预览也显示正确答案关系。

### Leaf 0.3：抽出 repository 边界

输入：

- 当前 `DatabaseHelper` 直接承担全部读写。

输出：

- 为后续 sources、knowledge points、questions 提供 repository 边界。

涉及文件：

```text
lib/data/repositories/
lib/core/providers/providers.dart
```

验收：

- 现有功能仍可通过 repository 或兼容层访问数据库。

## Branch 1：Source-Grounded Data Model

依赖：

- Branch 0 完成。

目的：建立“来源 -> 片段 -> 知识点 -> 题目”的主线。

### Leaf 1.1：新增 Source 模型和表

输出：

- `Source` model。
- `sources` table。

涉及文件：

```text
lib/data/models/source.dart
lib/data/database/database_helper.dart
```

验收：

- 可以插入、读取 source。
- source 支持 type 和 trust level。

### Leaf 1.2：新增 SourceChunk 模型和表

输出：

- `SourceChunk` model。
- `source_chunks` table。
- 支持 locator，如 URL、页码、文件路径、行号。

涉及文件：

```text
lib/data/models/source_chunk.dart
lib/data/database/database_helper.dart
```

验收：

- 可以将一段代码或文本保存为可引用片段。

### Leaf 1.3：新增 KnowledgePoint 模型和表

输出：

- `KnowledgePoint` model。
- `knowledge_points` table。
- `knowledge_point_sources` relation table。

涉及文件：

```text
lib/data/models/knowledge_point.dart
lib/data/models/knowledge_point_source.dart
lib/data/database/database_helper.dart
```

验收：

- 一个知识点可以关联多个 source chunks。

### Leaf 1.4：扩展 Question 模型

输出：

- `Question` 支持 knowledge point、source status、citations、review fields。

涉及文件：

```text
lib/data/models/question.dart
lib/data/database/database_helper.dart
```

验收：

- 旧题目仍能读取。
- 新题目能保存引用信息。

## Branch 2：Structured AI Tasks

依赖：

- Branch 1 至少完成 Source、SourceChunk、KnowledgePoint。

目的：替代 prompt 文本解析，让 AI 输出稳定结构。

### Leaf 2.1：封装 AI task result

输出：

- `AiTaskResult<T>`。
- 统一成功、失败、解析错误状态。

涉及文件：

```text
lib/services/ai/ai_task_result.dart
```

验收：

- 任务调用方不再靠 try/catch 猜结果。

### Leaf 2.2：实现 KnowledgeExtractionTask

输出：

- 从 source chunks 生成 knowledge points。

涉及文件：

```text
lib/services/ai/tasks/knowledge_extraction_task.dart
```

验收：

- 输出包含知识点和引用 chunk IDs。

### Leaf 2.3：实现 QuestionGenerationTask

输出：

- 从 knowledge points 生成 questions。

涉及文件：

```text
lib/services/ai/tasks/question_generation_task.dart
```

验收：

- 每道题包含 citation IDs。
- 没有 citation 的题目标记为 `no_source`。

### Leaf 2.4：实现 CitationVerificationTask

输出：

- 对引用做自动预检。

涉及文件：

```text
lib/services/ai/tasks/citation_verification_task.dart
```

验收：

- 能输出 `verified_candidate`、`weak_evidence`、`no_source`。

## Branch 3：Human Verification Gate

依赖：

- Branch 1。
- Branch 2。

目的：AI 生成内容进入正式学习前必须核验。

### Leaf 3.1：创建 KnowledgeReviewScreen

输出：

- 展示来源、知识点、题目和引用片段。

涉及文件：

```text
lib/features/ingestion/knowledge_review_screen.dart
```

验收：

- 用户能看到每道题的来源依据。

### Leaf 3.2：支持确认、待核验、删除

输出：

- 用户可将题目标记为 `verified`、`pending` 或删除。

涉及文件：

```text
lib/features/ingestion/knowledge_review_screen.dart
lib/core/providers/providers.dart
```

验收：

- 只有 `verified` 默认进入正式学习路径。

### Leaf 3.3：支持手动编辑题目

输出：

- 用户可编辑题干、答案、解析。

验收：

- 编辑后引用关系仍保留或提示需要重新核验。

## Branch 4：Project Import

依赖：

- Branch 1。
- Branch 3。

目的：支持面试准备的项目材料导入。

### Leaf 4.1：创建项目导入向导

输出：

- 项目名称、目标、技术栈、README、目录结构、关键代码片段表单。

涉及文件：

```text
lib/features/ingestion/project_import_screen.dart
```

验收：

- 用户能创建 project source。

### Leaf 4.2：支持代码片段 locator

输出：

- 用户可为代码片段填写文件路径和行号范围。

验收：

- source chunk locator 可保存为 `path:start-end`。

## Branch 5：Interview Agent MVP

依赖：

- Branch 1。
- Branch 2。
- Branch 4。

目的：先实现最符合用户目标的 agent 模式。

### Leaf 5.1：创建 Agent tab

输出：

- 底部导航新增 Agent。

涉及文件：

```text
lib/app.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户能进入 Agent 首页。

### Leaf 5.2：创建 InterviewerService

输出：

- 生成面试问题。
- 用户先回答。
- AI 再评价。

涉及文件：

```text
lib/services/agent/interviewer_service.dart
lib/services/ai/tasks/interview_question_task.dart
lib/services/ai/tasks/answer_evaluation_task.dart
```

验收：

- 一次只问一个问题。
- 用户回答前不展示参考答案。

### Leaf 5.3：保存学习会话

输出：

- `learning_sessions`。
- `interview_turns`。

涉及文件：

```text
lib/data/models/learning_session.dart
lib/data/models/interview_turn.dart
lib/data/database/database_helper.dart
```

验收：

- 每轮问题、回答、反馈、参考答案和引用可回看。

## Branch 6：Mastery and Review

依赖：

- Branch 5。

目的：让训练结果进入长期复习。

### Leaf 6.1：实现 mastery 计算

输出：

- 知识点 mastery 根据 quiz、interview 和复习稳定性更新。

涉及文件：

```text
lib/services/scheduling/mastery_service.dart
```

验收：

- 面试低分会降低相关知识点 mastery。

### Leaf 6.2：实现今日复习队列

输出：

- 根据 next review date 生成今日任务。

涉及文件：

```text
lib/services/scheduling/review_scheduler_service.dart
lib/features/home/home_screen.dart
```

验收：

- 首页能展示今日应复习知识点。

## Branch 7：Knowledge Base UI

依赖：

- Branch 1。
- Branch 3。

目的：让用户管理来源和知识点。

### Leaf 7.1：创建知识库 tab

输出：

- 底部导航新增知识库入口。

涉及文件：

```text
lib/app.dart
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 用户能查看来源、知识点、待核验内容。

### Leaf 7.2：来源和知识点详情页

输出：

- 从知识点跳到来源片段。
- 从题目跳到来源片段。

验收：

- 所有正式学习内容都可追溯来源。

## Branch 8：Project Import AI Pipeline

依赖：

- Branch 2。
- Branch 3。
- Branch 4。
- Branch 7。

目的：让“导入项目材料”不只保存来源，而是生成可核验、可学习、可复习的内容。

### Leaf 8.1：项目材料生成学习草稿

输出：

- 项目材料保存为 source 和 source chunks。
- AI 从 source chunks 抽取 knowledge points。
- AI 基于 knowledge points 和 source chunks 生成 questions。
- CitationVerificationTask 对引用做预核验。
- 结果进入 KnowledgeReviewScreen。
- 用户保存核验结果后，落库 knowledge points、knowledge_point_sources、deck、questions。

涉及文件：

```text
lib/features/ingestion/project_import_screen.dart
lib/features/ingestion/knowledge_review_screen.dart
lib/services/ai/tasks/
```

验收：

- 导入项目材料后能进入人工核验页。
- 保存核验结果后，知识库能看到来源和知识点。
- 保存核验结果后，题库能看到生成的问题。
- 没有引用依据的题目不能被保存为 verified。

## Branch 9：Agent Runtime UI

依赖：

- Branch 5。
- Branch 7。
- Branch 8。

目的：把 Agent 从“服务层能力”接成用户可实际训练的界面。

### Leaf 9.1：启用面试官模式

输出：

- Agent 首页的“面试官模式”进入真实训练页。
- 训练页从知识库选择面试相关知识点和来源片段。
- AI 先提问，用户回答后才显示反馈和参考答案。
- 每轮回答保存为 interview_turn。
- 回答评估结果更新相关知识点 mastery。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/interview_session_screen.dart
lib/services/agent/interviewer_service.dart
lib/data/models/interview_turn.dart
lib/data/models/learning_session.dart
```

验收：

- 用户能从 Agent tab 进入面试官模式。
- 没有知识点或没有来源片段时给出明确提示。
- 一轮面试回答后能看到评分、反馈、参考答案和依据片段。
- 面试回合能保存到 SQLite。
- 面试低分或薄弱点会进入 mastery 更新。

### Leaf 9.2：面试历史复盘

输出：

- Agent 首页展示最近面试训练记录。
- 用户可打开某次面试复盘。
- 复盘页展示每轮问题、用户回答、评分、反馈、参考答案和引用片段。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/interview_session_detail_screen.dart
```

验收：

- 完成面试后返回 Agent 首页能看到历史记录。
- 历史记录能显示轮数和平均分。
- 打开复盘能看到保存过的 interview_turns。
- 有 citation ids 时复盘能展示对应 source chunks。

### Leaf 9.3：启用导师模式

输出：

- Agent 首页的“导师模式”进入真实学习页。
- 用户可以从知识库选择知识点。
- AI 基于 knowledge point 和 source chunks 做分层讲解。
- 讲解包含简明解释、深入理解、项目联系、面试表达、易错点和自测问题。
- 讲解页展示支撑内容的引用片段。

涉及文件：

```text
lib/services/ai/tasks/tutor_explanation_task.dart
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/tutor_session_screen.dart
```

验收：

- 导师模式不再是 coming soon。
- 没有知识点时提示先导入材料。
- 没有来源片段的知识点不会生成无依据讲解。
- AI 讲解结果能展示引用片段。
- 讲解行为会保存一条 tutor learning session。

### Leaf 9.4：启用复习模式

输出：

- Agent 首页的“复习模式”进入真实复习页。
- 复习页展示今日到期知识点队列、题量和逾期数量。
- 用户可以开始今日复习或针对单个知识点复习。
- 没有到期任务时，展示低掌握度知识点作为主动练习入口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/review_agent_screen.dart
lib/services/scheduling/review_scheduler_service.dart
lib/features/learning/quiz_screen.dart
```

验收：

- 复习模式不再是 coming soon。
- 到期队列来自 `todayReviewQueueProvider`。
- 完成复习后刷新今日队列和知识点掌握度。
- 薄弱知识点练习只使用已核验题目。

## Branch 10：General Source-Grounded Ingestion

依赖：

- Branch 2。
- Branch 3。
- Branch 7。
- Branch 8。

目的：让普通文本导入也符合“有来源依据”的学习目标，而不是只生成无引用题包。

### Leaf 10.1：纯文本导入进入来源核验流程

输出：

- 纯文本导入构建 `Source` 和 `SourceChunk` 草稿。
- AI 从文本片段抽取 `KnowledgePoint`。
- AI 基于知识点和文本片段生成带引用题目。
- `CitationVerificationTask` 预核验题目引用。
- 结果进入 `KnowledgeReviewScreen`。
- 用户保存后落库 source、source chunks、knowledge points、relations、deck 和 questions。
- 有图片的导入暂时保留旧流程，直到图片能表达为可引用来源片段。

涉及文件：

```text
lib/features/ingestion/ingestion_screen.dart
lib/features/ingestion/knowledge_review_screen.dart
lib/services/ai/tasks/
```

验收：

- 纯文本导入不再直接进入旧 DeckPreview。
- 纯文本导入会进入人工核验页。
- 保存核验结果后，知识库和题库都能看到内容。
- 没有有效引用的题目不能被保存为 verified。

### Leaf 10.2：核验前不落库项目来源

输出：

- 项目导入时，source 和 source chunks 先作为草稿留在内存中。
- 只有用户在 KnowledgeReviewScreen 保存核验结果后，才持久化 source、chunks、knowledge points、relations、deck 和 questions。

涉及文件：

```text
lib/features/ingestion/project_import_screen.dart
```

验收：

- AI 生成失败不会留下孤立 source/chunks。
- 用户取消核验不会留下孤立 source/chunks。
- 保存核验后，项目来源仍能在知识库中被查看和引用。

### Leaf 10.3：知识库待核验二次处理

输出：

- 知识库中的待核验题目详情页支持更新核验状态。
- 有引用片段时可以标记为已核验。
- 没有引用片段时不能标记为已核验。
- 可以降级为无来源或保留待核验。
- 状态更新后刷新待核验列表、题库和复习队列。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/data/repositories/question_repository.dart
```

验收：

- pending question 可以在知识库内被确认。
- no_source question 不会误进入 verified。
- verified 后题目可以进入正式学习/复习路径。

### Leaf 10.4：来源化导入规则服务化

输出：

- 文本导入和项目导入共用知识点草稿构建规则。
- 文本导入和项目导入共用引用预核验规则。
- 审核后保存 source、chunks、knowledge points、relations、deck、questions 的逻辑集中在服务层。
- 保留页面各自的输入收集、状态展示和导航逻辑。

涉及文件：

```text
lib/services/ingestion/source_grounded_ingestion_service.dart
lib/core/providers/providers.dart
lib/features/ingestion/ingestion_screen.dart
lib/features/ingestion/project_import_screen.dart
lib/features/ingestion/knowledge_review_screen.dart
```

验收：

- 文本导入和项目导入不会维护两份来源状态规则。
- 无有效引用的题目保存时仍会被降级为 no_source。
- 用户删除全部题目时不会写入空题包。

### Leaf 10.5：正式练习只使用已核验题目

输出：

- 随机学习模式只从 verified 题目集合中抽题。
- 题包练习加载题目时过滤掉 pending/no_source。
- 正式学习入口使用 verified-only 题目集合。
- 没有已核验题目时，答题页提示先完成来源核验。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/home/home_screen.dart
lib/features/learning/quiz_screen.dart
```

验收：

- pending/no_source 题目不会进入正式答题、复习调度或掌握度更新路径。
- 待核验题仍保留在知识库的核验流程中。

### Leaf 10.6：审核后入库事务化

输出：

- 保存已审核来源化内容时，source、chunks、knowledge points、relations、deck、questions 在同一个 SQLite transaction 内写入。
- 任一写入失败时，整条导入链路回滚，不留下半套知识库数据。
- 保留已删除题目不入库、无有效引用题目降级为 no_source 的规则。

涉及文件：

```text
lib/services/ingestion/source_grounded_ingestion_service.dart
lib/core/providers/providers.dart
```

验收：

- 来源化导入服务不再通过多次独立 repository 调用完成保存。
- 事务覆盖 source 到 questions 的完整写入链路。
- UI 保存成功后的 provider 刷新逻辑不变。

### Leaf 10.7：初次核验状态操作与引用规则一致

输出：

- KnowledgeReviewScreen 的题目卡片支持选择已核验、待核验、无来源。
- 没有 citation chunks 的题目不能在 UI 中标记为已核验。
- 初次核验页的状态表达与保存服务的 no_source 降级规则一致。

涉及文件：

```text
lib/features/ingestion/knowledge_review_screen.dart
```

验收：

- 无引用题目不会在初次核验界面被误标为 verified。
- 用户可以主动把弱证据题目标记为 no_source。

### Leaf 10.8：题包学习入口显示已核验可用性

输出：

- 题库卡片显示已核验题数和总题数。
- 题库卡片在没有已核验题时禁用学习按钮，并显示待核验。
- 首页知识点学习路径节点显示已核验题数。
- 首页知识点学习路径节点在没有已核验题时不可进入。

涉及文件：

```text
lib/features/deck/deck_list_screen.dart
lib/features/home/home_screen.dart
```

验收：

- 用户不会从题包列表或首页路径进入只有 pending/no_source 题目的正式练习。
- UI 展示的题目可用性与 verified-only provider 规则一致。

### Leaf 10.9：管理题目集合与正式学习题目集合分离

输出：

- `allQuestionsProvider` 恢复为全部题目集合，供知识库和管理视图使用。
- 新增 `verifiedQuestionsProvider`，供随机学习等正式学习入口使用。
- `deckQuestionsProvider` 恢复为题包全部题目集合。
- 新增 `verifiedDeckQuestionsProvider`，供题包学习入口和可用性展示使用。
- 保存和核验状态更新后同时刷新全部题目集合与 verified-only 题目集合。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/home/home_screen.dart
lib/features/deck/deck_list_screen.dart
lib/features/ingestion/ingestion_screen.dart
lib/features/ingestion/project_import_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 知识库/管理功能不会因为正式学习过滤规则而丢失 pending/no_source 题目。
- 正式学习入口仍然只读取 verified 题目。

### Leaf 10.10：知识库全部题目管理视图

输出：

- 知识库新增“题目”tab。
- 题目 tab 使用 `allQuestionsProvider` 展示 verified、pending、no_source 全部题目。
- 每道题显示题型、来源状态、引用数量。
- 点击题目进入现有 QuestionEvidenceScreen，可继续查看证据和调整状态。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- verified/no_source 题目不会因为离开“待核验”列表而从知识库管理视图消失。
- 知识库可以统一巡检所有题目的来源状态。

### Leaf 10.11：知识库题目状态筛选

输出：

- 知识库“题目”tab 支持按全部、已核验、待核验、无来源筛选。
- 每个筛选项显示当前数量。
- 筛选后为空时展示对应空状态。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 用户可以快速巡检 no_source 和 pending 题目。
- 题目管理视图在题量增长后仍能按来源状态维护。

### Leaf 10.12：知识点详情关联题目

输出：

- 新增 `knowledgePointQuestionsProvider`，按知识点查询相关题目。
- 知识点详情页在证据片段下方展示相关题目。
- 相关题目显示题型、来源状态、引用数量。
- 点击相关题目进入 QuestionEvidenceScreen，继续查看证据和调整核验状态。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 用户可以从知识点跳到题目，再从题目查看引用片段。
- 核验状态变化后会刷新知识点相关题目列表。

### Leaf 10.13：来源详情关联知识点

输出：

- 新增 `sourceKnowledgePointsProvider`，按来源查询关联知识点。
- 来源详情页在来源片段下方展示关联知识点。
- 点击关联知识点进入 KnowledgePointDetailScreen。
- 导入保存后刷新来源片段和来源关联知识点缓存。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/ingestion/ingestion_screen.dart
lib/features/ingestion/project_import_screen.dart
```

验收：

- 用户可以从来源跳到知识点，再从知识点跳到相关题目。
- 来源、知识点、题目、引用片段之间形成可追踪的知识库证据链。

### Leaf 10.14：证据片段回链来源

输出：

- 新增 `sourceProvider`，按 source id 查询单个来源。
- 证据片段卡片显示所属来源标题。
- 在知识点详情和题目证据页中，点击片段来源可进入 SourceDetailScreen。
- 来源详情页自身展示片段时关闭来源回链，避免重复跳转。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/ingestion/ingestion_screen.dart
lib/features/ingestion/project_import_screen.dart
```

验收：

- 用户从题目证据片段可以回到原始来源。
- 引用片段不再脱离来源上下文单独展示。

### Leaf 10.15：题目证据关联知识点

输出：

- 新增 `knowledgePointProvider`，按 knowledge point id 查询单个知识点。
- 题目证据页在答案前展示关联知识点。
- 点击关联知识点进入 KnowledgePointDetailScreen。
- 没有关联知识点的旧题目保持现有简洁展示。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 用户可以从题目证据页回到所属知识点。
- 题目、知识点、来源、引用片段之间可以双向追踪关键上下文。

### Leaf 10.16：知识点详情学习动作

输出：

- TutorSessionScreen 支持从指定知识点进入并自动生成导师讲解。
- 知识点详情页新增“导师讲解”入口。
- 知识点详情页新增“练习已核验题”入口。
- 练习入口只使用 verified 题目；没有已核验题时禁用。

涉及文件：

```text
lib/features/agent/tutor_session_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 用户可以从一个知识点直接进入来源化导师讲解。
- 用户可以从一个知识点直接练习它下面的已核验题目。

### Leaf 10.17：答题后刷新知识状态

输出：

- QuizScreen 在每次答题写回复习计划和掌握度后刷新相关 provider。
- 刷新今日复习队列、全部题目、已核验题目、题包题目缓存。
- 若题目绑定知识点，则刷新知识点列表、单知识点缓存和知识点相关题目列表。

涉及文件：

```text
lib/features/learning/quiz_screen.dart
```

验收：

- 从知识点详情进入练习后，答题结果能推动知识点掌握度和相关题目视图刷新。
- 复习队列和题目列表不会继续显示答题前的缓存状态。

### Leaf 10.18：面试 Agent 只使用有来源知识点

输出：

- InterviewSessionScreen 在选择面试知识点前过滤掉没有来源片段的知识点。
- 无来源知识点不会被送入面试题生成任务。
- 面试回答评估更新掌握度后，刷新知识点列表、单知识点缓存和相关题目列表。

涉及文件：

```text
lib/features/agent/interview_session_screen.dart
```

验收：

- 面试问题生成只基于存在 source chunks 的知识点。
- 面试训练后的掌握度变化能及时反馈到知识库详情和列表。

### Leaf 10.19：面试题生成结果来源清洗

输出：

- InterviewQuestionTask 要求 source chunks 非空。
- 面试题生成后过滤未知 knowledge point ids。
- 面试题生成后过滤未知 citation ids。
- 丢弃没有有效知识点或没有有效引用依据的面试题。

涉及文件：

```text
lib/services/ai/tasks/interview_question_task.dart
```

验收：

- AI 输出跑偏时，不会把无来源引用的面试问题带入 UI。
- 面试问题中的知识点和引用 id 都来自本次传入的已知上下文。

### Leaf 10.20：面试回答评估结果清洗

输出：

- AnswerEvaluationResult 新增 copyWith。
- AnswerEvaluationTask 清洗 weak_knowledge_point_ids，只保留本题关联知识点。
- AnswerEvaluationTask 清洗 citation_ids，只保留本次评估传入的 cited chunks。
- Prompt 明确要求弱点 id 和引用 id 来自已提供上下文。

涉及文件：

```text
lib/services/ai/tasks/answer_evaluation_task.dart
```

验收：

- 面试评估不会用模型幻觉的知识点 id 更新掌握度。
- 面试复盘不会保存模型幻觉的 citation ids。

### Leaf 10.21：知识点抽取结果来源清洗

输出：

- ExtractedKnowledgePoint 新增 copyWith。
- KnowledgeExtractionTask 清洗 source_chunk_ids，只保留本次传入的 source chunks。
- 清洗后没有有效 source_chunk_ids 的知识点会被丢弃。
- Prompt 明确要求 source_chunk_ids 必须来自已提供片段。

涉及文件：

```text
lib/services/ai/tasks/knowledge_extraction_task.dart
```

验收：

- AI 不会把幻觉 source chunk id 带入知识点草稿。
- 文本导入和项目导入生成的知识点都必须有真实来源片段。

### Leaf 10.22：题目生成结果上下文清洗

输出：

- GeneratedQuestionDraft 新增 copyWith。
- QuestionGenerationTask 清洗 citation_ids，只保留本次传入的 source chunks。
- QuestionGenerationTask 丢弃未绑定到本次传入 knowledge points 的题目。
- 有有效引用的 AI 草稿统一回到 pending，必须经过预核验和人工核验。
- Prompt 明确要求 knowledge_point_id 和 citation_ids 必须来自已提供上下文。

涉及文件：

```text
lib/services/ai/tasks/question_generation_task.dart
```

验收：

- AI 不会把幻觉 knowledge point id 或 source chunk id 带入题目草稿。
- 题目生成阶段不会绕过来源核验直接产生 verified 题目。

### Leaf 10.23：审核保存前引用再清洗

输出：

- SourceGroundedIngestionService 保存题目前再次过滤 citationIds。
- 只把属于本次 request.chunks 的 citationIds 写入 SQLite。
- 清洗后没有有效引用的题目自动降级为 no_source。

涉及文件：

```text
lib/services/ingestion/source_grounded_ingestion_service.dart
```

验收：

- 即使 UI 决策或旧草稿混入无效 citation id，最终入库也不会保存幻觉引用。
- 最终保存层和正式学习 verified-only 规则保持一致。

### Leaf 10.24：引用预核验结果清洗

输出：

- CitationVerificationResult 新增 copyWith。
- CitationVerificationTask 清洗 supported_citation_ids 和 missing_citation_ids。
- 核验结果只保留本次传入 cited chunks 的 id。
- 清洗后没有 supported_citation_ids 的结果保守降级为 no_source。
- Prompt 明确要求引用 id 必须来自提供的 citation chunks。

涉及文件：

```text
lib/services/ai/tasks/citation_verification_task.dart
```

验收：

- AI 不会把幻觉 citation id 带回题目预核验结果。
- 预核验结果不能在没有有效支持引用时保持 verified_candidate 或 weak_evidence。

### Leaf 10.25：预核验入口引用过滤

输出：

- SourceGroundedIngestionService 在调用 CitationVerificationTask 前过滤题目 citationIds。
- 预核验失败回退路径使用过滤后的 citationIds。
- AI 核验无 supported_citation_ids 时，保留过滤后的有效引用供人工复核。

涉及文件：

```text
lib/services/ingestion/source_grounded_ingestion_service.dart
```

验收：

- 预核验页不会因为任务失败或 no_source 回退而重新带回无效 citation id。
- 初次核验 UI、引用预核验和最终保存使用同一套有效来源片段集合。

### Leaf 10.26：导师讲解引用清洗

输出：

- TutorExplanationResult 新增 copyWith。
- TutorExplanationTask 清洗 citation_ids，只保留本次传入的 source chunks。
- 清洗后没有有效 citation_ids 的导师讲解会失败。
- Prompt 明确要求 citation_ids 必须来自已提供来源片段。

涉及文件：

```text
lib/services/ai/tasks/tutor_explanation_task.dart
```

验收：

- 导师模式不会展示带幻觉 citation id 的讲解。
- 导师讲解必须能回链到真实来源片段。

### Leaf 10.27：面试复盘引用保存清洗

输出：

- InterviewSessionScreen 保存 interview_turn 前计算本轮实际评估 chunk ids。
- evaluation citation_ids 为空时仍可回退到题目 citation_ids。
- 最终写入 interview_turn 的 citation_ids 必须属于本轮 citedChunks。

涉及文件：

```text
lib/features/agent/interview_session_screen.dart
```

验收：

- 面试复盘不会保存未参与本轮评估的 citation id。
- 回答评估、复盘证据展示和来源片段上下文保持一致。

### Leaf 10.28：导师模式只展示有来源知识点

输出：

- 新增 evidenceBackedKnowledgePointListProvider。
- Provider 会确认知识点关系中的 source chunk 真实存在。
- TutorSessionScreen 使用 evidence-backed 知识点列表。
- 导入、答题、面试和复习后同步刷新 evidence-backed 知识点列表。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/tutor_session_screen.dart
lib/features/ingestion/ingestion_screen.dart
lib/features/ingestion/project_import_screen.dart
lib/features/learning/quiz_screen.dart
lib/features/agent/interview_session_screen.dart
lib/features/agent/review_agent_screen.dart
```

验收：

- 导师模式不会把无来源知识点作为可选项。
- 导师模式列表会随导入和掌握度变化刷新。

### Leaf 10.29：复习薄弱点只展示可练知识点

输出：

- 新增 practiceableKnowledgePointListProvider。
- Provider 只返回至少拥有一题 verified 题目的知识点。
- ReviewAgentScreen 的“薄弱知识点”列表使用可练知识点集合。
- 导入、核验状态变化、答题、面试和复习后同步刷新可练知识点列表。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/review_agent_screen.dart
lib/features/ingestion/ingestion_screen.dart
lib/features/ingestion/project_import_screen.dart
lib/features/learning/quiz_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/interview_session_screen.dart
```

验收：

- 复习模式薄弱点不会展示没有 verified 题目的知识点。
- 用户从薄弱点入口看到的项目应能直接进入正式练习。

### Leaf 10.30：知识库二次核验引用清洗

输出：

- QuestionEvidenceScreen 更新核验状态时清洗 citationIds。
- 只保存当前能加载到的 source chunk ids。
- 清洗后没有有效引用时自动降级为 no_source。
- 状态更新后刷新 citation chunks、题目集合、复习队列和可练知识点列表。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 旧题或异常草稿中的无效 citation id 不会在二次核验后继续保留。
- 知识库题目引用数量与真实可展示来源片段保持一致。

### Leaf 10.31：图片旧流程显式无来源

输出：

- DeckOperations 保存旧 AnalysisResult 时显式设置 sourceStatus = no_source。
- 旧流程保存题目时清空 knowledgePointId 和 citationIds。
- 保存后刷新全部题目、已核验题目、题包题目和可练知识点缓存。
- DeckPreviewScreen 对图片导入展示“无来源、不进入正式练习”的提示。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/ingestion/deck_preview_screen.dart
```

验收：

- 图片旧流程不会绕过来源核验生成 verified 题目。
- 用户在保存图片生成题包前能看到来源状态限制。

### Leaf 10.32：首页练习返回后刷新学习状态

输出：

- HomeScreen 新增 _refreshLearningState。
- 今日复习、随机练习和题包练习返回后刷新复习队列、题包、题目和知识点缓存。
- 随机关卡完成进度保存改为 await。
- 题包练习返回后刷新对应 deck 的全部题目和 verified 题目缓存。

涉及文件：

```text
lib/features/home/home_screen.dart
```

验收：

- 用户完成首页任一练习入口后，首页与 Agent 相关列表不会继续显示答题前状态。
- 题包掌握度、今日复习队列和可练知识点列表能跟随练习结果刷新。

### Leaf 10.33：题库练习和删除后刷新状态

输出：

- DeckOperations.deleteDeck 删除后刷新题包、题目、复习队列和可练知识点缓存。
- DeckListScreen 题包练习返回后刷新题包、题目、知识点、复习队列和可练知识点缓存。
- 题库页学习入口继续使用 verifiedDeckQuestionsProvider 控制可用性。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/deck/deck_list_screen.dart
```

验收：

- 从题库页完成练习后，题包掌握度和相关复习状态能及时更新。
- 删除题包后，正式学习和复习入口不会继续引用已删除题目。

### Leaf 10.34：知识点详情练习后刷新状态

输出：

- _KnowledgePointLearningActions 改为 ConsumerWidget。
- 从知识点详情进入练习并返回后刷新复习队列、题目集合、知识点集合和当前知识点缓存。
- 保持练习入口只使用 verified 题目。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 用户从知识点详情练习后，掌握度、相关题目和可练知识点列表不会停留在答题前状态。
- 知识点详情练习仍不会使用 pending/no_source 题目。

### Leaf 10.35：图片配文进入来源核验

输出：

- IngestionScreen 在文本非空时优先走 source-grounded 导入链路。
- 图片路径保存为 Source.uri，文字仍作为 SourceChunk 内容和引用依据。
- 图片配文片段 locator 使用 image_note_text 前缀。
- 纯图片无文字时继续走旧预览流程，并保持 no_source 限制。
- 输入页展示图片配文的来源规则提示。

涉及文件：

```text
lib/features/ingestion/ingestion_screen.dart
```

验收：

- “图片 + 文字”不会再被图片旧流程绕过来源核验。
- 不把未 OCR/未转写的纯图片内容伪装成可核验来源。

### Leaf 10.36：来源详情展示 URI

输出：

- SourceDetailScreen 在 Source.uri 非空时展示 URI。
- URI 文本可选择，便于用户核对本地图片路径、网页或文档位置。
- 普通无 URI 的文本来源保持原详情布局。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 图片配文导入后，来源详情能回看关联图片路径。
- 用户查看来源时不只依赖标题判断原始出处。

### Leaf 10.37：普通导入来源可信度选择

输出：

- IngestionScreen 新增来源可信度选择器。
- 普通文本/图片配文导入保存 Source.trustLevel 时使用用户选择。
- 选择“官方文档”时 Source.type 保存为 official_doc。
- 图片配文仍保存为 user_note 类型，避免把图片附件误认为官方来源。

涉及文件：

```text
lib/features/ingestion/ingestion_screen.dart
```

验收：

- 用户可以区分个人笔记、文章、书籍/课程和官方文档来源。
- 知识库来源列表和详情能显示更准确的来源可信度。

### Leaf 10.38：Agent 首页展示模式可用性

输出：

- AgentHomeScreen 读取有来源知识点数量。
- 面试官模式和导师模式在没有有来源知识点时禁用。
- AgentHomeScreen 读取可练习知识点数量。
- 复习模式在没有 verified 题目可练时禁用。
- 卡片副标题展示当前可训练/可复习数量或缺失条件。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户无需进入子页面就能知道 Agent 模式是否已具备来源化学习材料。
- Agent 首页不会把缺少来源或缺少已核验题目的模式表现成可直接训练。

### Leaf 10.39：知识点详情导师入口前置来源条件

输出：

- KnowledgePointDetailScreen 的学习动作同时读取 evidence chunks 和相关题目。
- _KnowledgePointLearningActions 接收 evidenceChunks。
- 没有来源片段时禁用“导师讲解”入口。
- 练习入口继续只使用 verified 题目。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
```

验收：

- 用户不会从无来源知识点详情页进入导师讲解后才失败。
- 知识点详情页与 Agent 首页、导师模式列表的来源约束一致。

### Leaf 10.40：导师模式空状态说明来源要求

输出：

- TutorSessionScreen 的空状态文案改为明确说明缺少“带来源依据的知识点”。
- 文案引导用户先导入项目材料或编程资料，并在审核后保留来源片段。

涉及文件：

```text
lib/features/agent/tutor_session_screen.dart
```

验收：

- 用户进入导师模式时能理解不可用原因是来源证据不足，而不是知识库完全为空。
- 导师模式空状态与 Agent 首页、知识点详情的来源约束一致。

### Leaf 10.41：无来源题目清空引用不变量

输出：

- 题目证据页手动标记“无来源”时清空 citationIds。
- 预核验结果为 no_source 时不再保留候选引用。
- 审核保存服务在最终入库前再次保证 no_source 题目 citationIds 为空。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/services/ingestion/source_grounded_ingestion_service.dart
```

验收：

- no_source 题目不会继续显示或保存来源引用。
- pending/verified 题目仍然只保留当前来源集合内的有效引用。
- 最终入库层能兜住 UI 或 AI 输出中的状态/引用不一致。

### Leaf 10.42：题目模型边界清理无来源引用

输出：

- Question.toMap 在写库前按 sourceStatus 归一化 citationIds。
- Question.fromMap 读取历史数据时把 no_source 或空引用题目视为 no_source。
- Question.fromJson 清理 no_source 状态下的 citationIds。
- GeneratedQuestionDraft.fromJson 对 AI 草稿执行同样的 no_source 引用清理。

涉及文件：

```text
lib/data/models/question.dart
lib/services/ai/tasks/question_generation_task.dart
```

验收：

- DB/JSON 边界不会重新产生 no_source 但带 citationIds 的题目。
- verified/pending 题目若缺少引用，会在模型边界降级为 no_source。
- AI 生成草稿自称 no_source 时不会保留引用数组。

### Leaf 10.43：启用 SQLite 外键约束

输出：

- DatabaseHelper.openDatabase 增加 onConfigure。
- onConfigure 执行 PRAGMA foreign_keys = ON。
- 已定义的 ON DELETE CASCADE / SET NULL 约束在新连接上生效。

涉及文件：

```text
lib/data/database/database_helper.dart
```

验收：

- 数据库连接建立时启用外键约束。
- 来源、来源片段、知识点、题包、学习记录等表的关系约束不只停留在 schema 声明。
- 现有手动删除清理逻辑保持不变，数据库约束作为额外保护。

### Leaf 10.44：面试评估只使用问题引用

输出：

- InterviewSessionScreen 的 _chunksForQuestion 移除“取前 4 个来源片段”的兜底。
- 当前问题缺少有效引用时停止评估，并提示无法进行来源约束评估。
- 面试问题卡展示引用依据数量，但不提前展示片段内容。

涉及文件：

```text
lib/features/agent/interview_session_screen.dart
```

验收：

- 面试回答评估不会因为问题引用失效而使用不相关来源片段。
- 用户能在答题前看到该问题具备多少条依据，但不会被直接展示答案线索。
- 实时面试评估和问题生成的 citation 边界一致。

### Leaf 10.45：回答评估任务要求来源片段

输出：

- AnswerEvaluationTask.run 在 citedChunks 为空时返回 validation failure。
- 面试 UI 层之外的新调用也不能在无来源片段时触发评估请求。

涉及文件：

```text
lib/services/ai/tasks/answer_evaluation_task.dart
```

验收：

- 回答评估任务不会向 AI 发送空来源上下文。
- 面试评估的服务层约束与 UI 层约束一致。

### Leaf 10.46：测验结果展示引用依据

输出：

- QuizScreen 在显示答题结果后读取当前题目的 citation chunks。
- 答题结果区域新增“引用依据”区块。
- 引用依据只在作答后展示，不影响答题前的练习过程。

涉及文件：

```text
lib/features/learning/quiz_screen.dart
```

验收：

- 用户每次练习 verified 题目后都能回看来源片段。
- 测验页的学习反馈不只给答案和解析，也给可追溯依据。
- 引用加载失败时显示错误提示，不影响答题流程。

### Leaf 10.47：测验引用展示来源可信度

输出：

- Quiz citation block 改为 ConsumerWidget。
- 每条引用读取 Source，并展示来源标题与 trustLevel label。
- 来源缺失、加载中、读取失败都有明确文案。

涉及文件：

```text
lib/features/learning/quiz_screen.dart
```

验收：

- 用户在测验结果中不只看到片段位置，也能看到来源名称和可信度。
- 官方文档、源码、书籍/课程、文章、个人笔记等可信度信息进入练习反馈。
- 来源读取失败不阻塞题目解析和引用片段内容展示。

### Leaf 10.48：导师讲解引用展示来源可信度

输出：

- TutorSessionScreen 的引用块改为 ConsumerWidget。
- 导师讲解依据片段展示来源标题与 trustLevel label。
- 来源缺失、加载中、读取失败都有明确文案。

涉及文件：

```text
lib/features/agent/tutor_session_screen.dart
```

验收：

- 用户阅读导师讲解时能直接判断讲解依据来自哪类来源。
- 导师模式与测验页的来源可信度展示保持一致。

### Leaf 10.49：面试引用展示来源可信度

输出：

- InterviewSessionScreen 的实时反馈引用块展示来源标题与 trustLevel label。
- InterviewSessionDetailScreen 的复盘引用块展示来源标题与 trustLevel label。
- 来源缺失、加载中、读取失败都有明确文案。

涉及文件：

```text
lib/features/agent/interview_session_screen.dart
lib/features/agent/interview_session_detail_screen.dart
```

验收：

- 用户在实时面试反馈和历史复盘里都能看到依据来源可信度。
- 面试训练、导师讲解、测验结果的引用可信度展示保持一致。

### Leaf 10.50：抽取共享来源引用组件

输出：

- 新增 SourceCitationBlock 共享组件。
- SourceCitationBlock 统一展示来源标题、trustLevel、locator 和片段内容。
- QuizScreen、TutorSessionScreen、InterviewSessionScreen、InterviewSessionDetailScreen 改用共享组件。
- 保留不同页面对背景、边框、margin 和内容行高的少量样式配置。

涉及文件：

```text
lib/shared/widgets/source_citation_block.dart
lib/features/learning/quiz_screen.dart
lib/features/agent/tutor_session_screen.dart
lib/features/agent/interview_session_screen.dart
lib/features/agent/interview_session_detail_screen.dart
```

验收：

- 测验、导师、面试实时反馈、面试复盘的引用展示逻辑不再重复。
- 后续新增来源跳转或可信度样式时可以在共享组件集中修改。
- 各页面仍能保持原有视觉语境。

### Leaf 10.51：审核页无来源状态隐藏引用

输出：

- KnowledgeReviewScreen 在渲染题目卡时先计算 sourceStatus。
- 当 sourceStatus 为 no_source 时，传给 _QuestionReviewCard 的 citationChunks 为空。
- 草稿题目的原 citationIds 不在 UI 层直接清掉，用户切回待核验时还能恢复预览。

涉及文件：

```text
lib/features/ingestion/knowledge_review_screen.dart
```

验收：

- 审核页选择“无来源”后，卡片不会继续展示引用依据。
- 保存层仍会在最终入库前清空 no_source citationIds。
- 用户切换回“待核验”时可以重新看到原候选引用。

### Leaf 10.52：面试 ID 边界去空去重

输出：

- InterviewQuestionDraft.fromJson 对 knowledgePointIds 和 citationIds 去空去重。
- InterviewTurn.toMap 写库前清理 citationIds 和 weakKnowledgePointIds。
- InterviewTurn.fromMap 读取历史回合时清理 citationIds 和 weakKnowledgePointIds。

涉及文件：

```text
lib/services/ai/tasks/interview_question_task.dart
lib/data/models/interview_turn.dart
```

验收：

- 面试问题草稿不会携带重复知识点或重复引用 ID。
- 面试复盘不会因为历史脏数据显示空标签或重复引用块。
- 面试回合持久化边界与其他来源 ID 清理规则一致。

### Leaf 10.53：AI JSON 列表字段解析去重

输出：

- AnswerEvaluationResult.fromJson 对 weakKnowledgePointIds 和 citationIds 去空去重。
- TutorExplanationResult.fromJson 对 pitfalls、checkQuestions 和 citationIds 去空去重。
- ExtractedKnowledgePoint.fromJson 对 tags 和 sourceChunkIds 去空去重。
- CitationVerificationResult.fromJson 对 supported/missing citation ids 去空去重。

涉及文件：

```text
lib/services/ai/tasks/answer_evaluation_task.dart
lib/services/ai/tasks/tutor_explanation_task.dart
lib/services/ai/tasks/knowledge_extraction_task.dart
lib/services/ai/tasks/citation_verification_task.dart
```

验收：

- AI 输出中的重复列表项不会进入后续 UI 或持久化流程。
- 上下文过滤仍保留在各 task 的 sanitize 阶段。
- 不改变已有评分、讲解、知识点抽取的业务含义。

### Leaf 10.54：来源模型兼容缺失可信度字段

输出：

- Source.fromMap 读取 type 时缺失则回退为 text。
- Source.fromMap 读取 trust_level 时缺失则回退为 unknown。

涉及文件：

```text
lib/data/models/source.dart
```

验收：

- 旧库或异常来源记录缺少 trust_level 时不会导致来源列表、引用块或知识库详情崩溃。
- 来源可信度缺失时明确显示为“未知”。

## Branch 11：Knowledge Learning Agent

目的：在已来源化、已核验的学习材料之上，建立本地优先的学习 Agent 工作流。

原则：

- Agent 只基于本地知识库、来源片段和已核验题目做正式学习决策。
- Agent 的每个动作都能解释“为什么现在做这一步”。
- AI 调用负责生成讲解、追问和反馈；本地规划层负责判断可用性、缺口和下一步。
- 学习工作流围绕三个目标展开：AI 应用开发面试、讲清项目细节、编程知识学习。

### Leaf 11.1：本地学习 Agent 规划模型

输出：

- 新增 LearningAgentGoal，覆盖 AI 应用开发面试、讲清项目细节、编程知识学习。
- 新增 LearningAgentReadiness，统计有来源知识点、可练习知识点、已核验题目、待核验题目。
- 新增 LearningAgentPlanStep 和 LearningAgentPlan。
- 新增 LearningAgentPlannerService，根据目标和本地状态生成下一步学习路线。
- 新增 learningAgentPlannerServiceProvider 和 learningAgentPlanProvider。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/core/providers/providers.dart
```

验收：

- 不调用 AI、不改数据库，即可生成学习 Agent 的本地计划。
- 计划能区分材料导入、来源核验、导师讲解、面试训练、练习和复习。
- 后续 UI 和 Agent 会话可以共用同一个 planning provider。

### Leaf 11.2：Agent 首页展示学习路线

输出：

- AgentHomeScreen 读取 AI 应用开发面试目标的 learningAgentPlanProvider。
- 首页新增学习 Agent 路线卡。
- 路线卡展示准备度、来源知识点数、可练习知识点数、已核验题数、待核验题数。
- 路线卡展示下一步建议和当前缺口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户进入 Agent 首页即可看到学习 Agent 的本地规划判断。
- Agent 首页不只展示模式入口，也展示为什么下一步应该这样学。
- 规划卡仍然只读取本地状态，不触发 AI 调用。

### Leaf 11.3：Agent 首页学习目标切换

输出：

- 新增 learningAgentGoalProvider 保存当前学习目标。
- AgentHomeScreen 根据当前目标读取 learningAgentPlanProvider。
- Agent 首页新增目标选择器，支持 AI 应用开发面试、讲清项目细节、编程知识学习。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户可以在 Agent 首页切换三个学习目标。
- 路线卡会跟随目标变化展示对应下一步。
- 目标切换仍然只影响本地 planning，不触发 AI 调用。

### Leaf 11.4：学习路线下一步可执行

输出：

- LearningAgentPlanCard 新增“执行下一步”按钮。
- importSources 路由到 IngestionScreen。
- verifyQuestions 路由到 KnowledgeBaseScreen。
- tutor 路由到 TutorSessionScreen。
- interview 路由到 InterviewSessionScreen，并返回后刷新面试复盘。
- practice/review 路由到 ReviewAgentScreen。
- 页面返回后刷新规划输入 provider 和当前目标的 learningAgentPlanProvider。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- Agent 首页的规划不只是说明文字，可以启动现有学习工作流。
- 路由仍复用已来源约束的导师、面试、复习、导入和知识库页面。
- 执行后返回 Agent 首页会重新计算路线。

### Leaf 11.5：核验步骤直达待核验 Tab

输出：

- KnowledgeBaseScreen 新增 initialTabIndex 参数。
- DefaultTabController 使用 initialTabIndex，并限制在合法 tab 范围内。
- Agent 路线中的 verifyQuestions 步骤打开 KnowledgeBaseScreen(initialTabIndex: 4)。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户点击“核验待确认题目”时直接进入知识库待核验 tab。
- 知识库默认入口仍保持从来源 tab 打开。
- initialTabIndex 越界时不会导致 TabController 异常。

### Leaf 11.6：练习步骤直达已核验题目测验

输出：

- AgentHomeScreen 为 practice 步骤读取 verifiedQuestionsProvider。
- practice 步骤打开 QuizScreen(questions: questions)。
- review 步骤继续进入 ReviewAgentScreen。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- 编程知识学习目标的“练习已核验题目”不会绕到复习 Agent。
- 练习步骤只使用已核验题目，沿用 QuizScreen 的来源约束和引用反馈。
- 复习模式仍保留到期复习和薄弱点逻辑。

### Leaf 11.7：Agent 首页展示完整学习路线

输出：

- LearningAgentPlanCard 展示 plan.steps 的完整列表。
- 每个步骤显示标题、数量和可执行/条件未满足状态。
- 当前可执行步骤使用高亮图标，不可执行步骤使用锁定图标。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户不只看到下一步，也能看到 Agent 为当前目标生成的完整路线。
- 每个步骤是否可执行由本地 readiness 决定。
- 路线解释仍然不触发 AI 调用。

### Leaf 11.8：学习路线步骤展示锁定原因

输出：

- LearningAgentPlanStep 新增 disabledReason。
- Planner 为导入、核验、导师、面试、练习、复习步骤提供不可执行原因。
- Agent 首页步骤列表展示具体锁定原因，而不是泛化的“条件未满足”。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户能理解每个步骤为什么暂时不可执行。
- 锁定原因仍来自本地 readiness，不触发 AI 调用。
- 下一步建议和完整路线共享同一份 planner 输出。

### Leaf 11.9：学习路线推荐优先关注知识点

输出：

- 新增 LearningAgentFocusPoint。
- LearningAgentPlan 新增 focusPoints。
- LearningAgentPlannerService 根据目标、本地掌握度、面试相关度和来源可用性推荐最多 3 个知识点。
- Agent 首页路线卡新增“优先关注”区域。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 学习 Agent 不只给步骤，也给当前最值得优先学习的知识点。
- 推荐逻辑完全基于本地知识库状态，不触发 AI 调用。
- 推荐理由能解释为什么这些知识点优先。

### Leaf 11.10：导师步骤优先讲解推荐知识点

输出：

- AgentHomeScreen 的执行逻辑改为接收整个 LearningAgentPlan。
- tutor 步骤存在 focusPoints 时，读取第一个推荐知识点并传给 TutorSessionScreen(initialPoint)。
- 推荐知识点缺失时，仍然进入 TutorSessionScreen 列表模式。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- 学习 Agent 的“导师讲解”步骤会围绕当前推荐知识点启动。
- 规划推荐和执行动作开始联动。
- 不改变 TutorSessionScreen 现有来源约束。

### Leaf 11.11：练习步骤优先练推荐知识点

输出：

- practice 步骤读取 verifiedQuestionsProvider 后，优先筛选第一个 focus point 的题目。
- 若推荐知识点没有可练题目，则回退到全部已核验题目。
- QuizScreen 继续负责 verified 二次过滤和引用反馈展示。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- 编程知识学习目标的练习动作会尽量围绕当前推荐知识点展开。
- 推荐知识点和实际练习动作开始联动。
- 没有推荐点题目时仍能进行全库已核验题练习。

### Leaf 11.12：推荐知识点可打开详情

输出：

- LearningAgentPlanCard 接收 onFocusPointTap。
- AgentHomeScreen 点击推荐知识点时读取 KnowledgePoint 并进入 KnowledgePointDetailScreen。
- 推荐知识点缺失时回退打开 KnowledgeBaseScreen(initialTabIndex: 2)。
- 推荐知识点行改为可点击 Material/InkWell。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户可以从 Agent 路线里的“优先关注”直接进入知识点详情。
- 知识点详情继续展示证据片段、相关题目和学习动作。
- 推荐数据与详情数据不一致时仍有知识库回退路径。

### Leaf 11.13：持久化学习 Agent 目标

输出：

- LearningAgentGoal 新增 fromString。
- learningAgentGoalProvider 改为 StateNotifierProvider。
- 新增 LearningAgentGoalNotifier，从 SharedPreferences 读取 learning_agent_goal。
- 目标切换时写入 SharedPreferences。
- AgentHomeScreen 目标选择器改为调用 setGoal。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户选择的学习目标在 app 重启后仍能恢复。
- 无效或缺失的本地保存值回退到 AI 应用开发面试目标。
- 持久化目标只影响本地 planning，不触发 AI 调用。

### Leaf 11.14：推荐知识点展示支撑度

输出：

- LearningAgentFocusPoint 新增 evidenceChunkCount 与 verifiedQuestionCount。
- learningAgentPlanProvider 按知识点统计已存在的证据片段数。
- learningAgentPlanProvider 按知识点统计已核验题目数。
- LearningAgentPlannerService 将支撑度数据写入推荐知识点。
- AgentHomeScreen 在“优先关注”行展示证据数和已核验题数。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户能在推荐知识点上看到这个建议背后有多少来源片段支撑。
- 用户能在推荐知识点上看到可以正式练习的已核验题数量。
- 缺少支撑数据时显示 0，不影响计划生成和页面打开。

### Leaf 11.15：生成 Agent Session 摘要上下文

输出：

- 新增 LearningAgentSessionSummary，描述当前目标、下一步、焦点知识点、执行目标和来源约束。
- LearningAgentPlan 持有 sessionSummary，供后续独立 Agent 工作流复用。
- LearningAgentPlannerService 根据 next step、focus point 和 readiness 生成 session 摘要。
- AgentHomeScreen 在路线卡片中展示当前 Agent Session 的目标和来源约束。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户在执行下一步前能看到这次 Agent Session 想完成什么。
- 用户能看到本次执行受到哪些来源或已核验题约束。
- 摘要层不写入 LearningSession 表，不污染真实学习记录。

### Leaf 11.16：执行下一步前做 Agent Session 预检查

输出：

- AgentHomeScreen 在执行下一步前读取 sessionSummary。
- 新增 preflight 检查，确保当前 session 仍有可执行 step。
- 针对导入、核验、导师、面试、练习、复习分别检查必要 readiness。
- 启动或阻断时用本地提示告诉用户原因。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- 没有可执行 Agent Session 时不会静默失败。
- 数据不足时会给出明确阻断原因。
- 数据满足时会显示本次启动的 session 标题和目标。

### Leaf 11.17：面试 Agent 从推荐知识点开始

输出：

- InterviewSessionScreen 支持可选 initialPoint。
- 面试知识点排序时将有效的 initialPoint 放在第一位。
- AgentHomeScreen 的 interview plan step 读取 top focus point 并传给面试页。
- 普通面试官模式入口继续使用全局知识点排序。

涉及文件：

```text
lib/features/agent/interview_session_screen.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 从 Agent 路线启动面试时，题目生成优先围绕推荐知识点。
- initialPoint 必须仍然存在于有来源知识点集合中，否则自动回退全局排序。
- 普通面试入口不受推荐焦点影响。

### Leaf 11.18：复习 Agent 从推荐知识点开始

输出：

- ReviewAgentScreen 支持可选 initialPoint。
- 复习页标题在有 initialPoint 时显示优先复习目标。
- 今日复习队列将 initialPoint 对应知识点放在第一位，同时保留其他队列顺序。
- 薄弱知识点列表将 initialPoint 放在第一位。
- AgentHomeScreen 的 review plan step 读取 top focus point 并传给复习页。

涉及文件：

```text
lib/features/agent/review_agent_screen.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 从 Agent 路线启动复习时，页面优先呈现推荐知识点。
- initialPoint 没有到期复习题时，今日复习按钮仍回退到全局到期队列。
- 普通复习入口不受推荐焦点影响。
- 复习仍然只使用已核验题目。

### Leaf 11.19：集中读取 Agent 推荐焦点

输出：

- AgentHomeScreen 新增 _loadTopFocusPoint。
- tutor、interview、review plan step 复用同一个 top focus point 读取逻辑。
- 后续调整推荐焦点解析规则时只需要改一个入口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
```

验收：

- tutor、interview、review 三个执行路径仍能收到同一个推荐焦点。
- 没有 focusPoints 时返回 null，并保留原有全局行为。
- 不改变 planner 的推荐排序规则。

### Leaf 11.20：新增 Agent Session 准备页

输出：

- 新增 AgentSessionLaunchScreen。
- 准备页展示当前 session title、objective、target、goal 和来源约束。
- 准备页展示推荐 focus point 的证据片段数和已核验题数。
- 准备页展示完整执行路线，并高亮当前 next step。
- AgentHomeScreen 的“执行下一步”先进入准备页。
- 准备页根据 next step 启动导入、核验、导师、面试、练习或复习。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_home_screen.dart
```

验收：

- 用户执行下一步前会先看到独立 Agent Session 准备页。
- 准备页能复用 LearningAgentSessionSummary 的目标和来源约束。
- 准备页启动具体学习模式后会刷新 Agent 相关 provider。
- 不写入 LearningSession 表，真实学习记录仍由具体模式维护。

### Leaf 11.21：集中 Agent Session 启动预检查

输出：

- LearningAgentPlan 新增 canStartSession。
- LearningAgentPlan 新增 startBlockReason，集中判断 session 是否可启动。
- AgentHomeScreen 改为读取 plan.startBlockReason。
- AgentSessionLaunchScreen 改为读取 plan.startBlockReason 与 plan.canStartSession。
- 移除首页和准备页重复的 preflight switch。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
```

验收：

- 首页和准备页使用同一套启动阻断原因。
- 新增执行步骤时只需要在 planner plan 层维护启动规则。
- 启动规则不写数据库，也不触发 AI 调用。

### Leaf 11.22：准备页推荐焦点可打开详情

输出：

- AgentSessionLaunchScreen 的 focus point panel 改为可点击。
- 点击推荐焦点时读取真实 KnowledgePoint。
- 知识点存在时打开 KnowledgePointDetailScreen。
- 知识点缺失时回退到 KnowledgeBaseScreen(initialTabIndex: 2)。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
```

验收：

- 用户能在启动 Agent Session 前查看推荐知识点详情。
- 详情页继续展示来源片段、相关题目和学习动作。
- 推荐焦点数据失效时仍能回到知识库管理视图。

### Leaf 11.23：准备页预览推荐焦点证据

输出：

- AgentSessionLaunchScreen 读取 knowledgePointEvidenceChunksProvider。
- 准备页在推荐焦点下方展示“证据预览”。
- 证据预览复用 SourceCitationBlock，展示来源标题、trust label、locator 和片段内容。
- 默认展示前 2 个证据片段，更多证据提示进入知识点详情查看。
- 证据加载、为空、失败时提供本地状态提示。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在启动 Agent Session 前能直接看到推荐知识点的来源依据。
- 证据预览使用现有共享引用组件，避免和其他页面展示格式分叉。
- 没有证据或读取失败时不会阻断页面渲染。

### Leaf 11.24：准备页预览推荐焦点已核验题

输出：

- AgentSessionLaunchScreen 读取 knowledgePointQuestionsProvider。
- 准备页在证据预览下方展示“已核验题预览”。
- 题目预览只展示 sourceStatus = verified 的题目。
- 默认展示前 2 道已核验题，更多题目提示进入详情或练习查看。
- 题目加载、为空、失败时提供本地状态提示。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在启动 Agent Session 前能看到推荐知识点是否有正式练习题。
- pending/no_source 题目不会出现在准备页正式题目预览里。
- 题目预览不会阻断 session 启动。

### Leaf 11.25：准备页题目预览可打开证据详情

输出：

- 已核验题预览行改为 Material/InkWell。
- 点击题目预览进入 QuestionEvidenceScreen。
- 预览行展示 chevron，提示可继续查看证据。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能从 Agent Session 准备页直接查看题目的引用证据。
- 题目证据详情沿用既有 verified/pending/no_source 展示规则。
- 只对准备页已核验题预览开放入口。

### Leaf 11.26：准备页展示计划缺口

输出：

- AgentSessionLaunchScreen 在 plan.blockers 非空时展示“仍需注意”。
- 缺口面板最多展示前 3 个 blocker。
- blocker 超过 3 个时提示还有剩余缺口。
- 缺口提醒不改变 plan.canStartSession，也不阻断启动。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在启动 Agent Session 前能看到来源、题目核验等剩余缺口。
- 可启动 session 不会因为存在非阻断缺口而被禁用。
- 缺口展示复用 LearningAgentPlan.blockers，不新增第二套规则。

### Leaf 11.27：准备页展示本次成功标准

输出：

- LearningAgentSessionSummary 新增 successCriteria。
- LearningAgentPlannerService 按 next step 生成本次成功标准。
- AgentSessionLaunchScreen 新增“本次成功标准”面板。
- 成功标准覆盖导入、核验、导师、面试、练习和复习六类动作。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在启动 Agent Session 前能看到这一轮完成后应该达成什么。
- 成功标准由 planner 统一生成，准备页只负责展示。
- 成功标准不写数据库、不触发 AI 调用、不改变启动规则。

### Leaf 11.28：准备页展示完成后复盘问题

输出：

- LearningAgentSessionSummary 新增 reflectionPrompts。
- LearningAgentPlannerService 按 next step 生成复盘问题。
- AgentSessionLaunchScreen 新增“完成后复盘”面板。
- 复盘问题覆盖导入、核验、导师、面试、练习和复习六类动作。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在启动前能看到完成后应该反思的问题。
- 复盘问题帮助把学习结果转成面试表达或下一轮学习输入。
- 复盘问题由 planner 统一生成，不触发 AI 调用。

### Leaf 11.29：学习动作完成后留在准备页复盘

输出：

- AgentSessionLaunchScreen 新增 _hasCompletedStep 状态。
- 具体学习模式返回后不再立刻 pop 回 Agent 首页。
- 准备页展示“本轮学习已返回”完成回顾面板。
- 完成回顾面板提示用户按成功标准和复盘问题检查。
- 新增“完成并返回 Agent”按钮，点击后才返回首页刷新下一步。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户从导师、面试、练习、复习等页面返回后仍停留在 Agent Session 准备页。
- 用户能在返回首页前看到成功标准和复盘问题。
- 返回 Agent 首页仍会触发 provider 刷新。

### Leaf 11.30：再次执行时重置完成状态

输出：

- AgentSessionLaunchScreen 在 _startSession 开始时清空 _hasCompletedStep。
- 再次执行 session 时隐藏上一轮完成回顾面板。
- 保留学习动作返回后重新展示完成回顾的行为。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户点击“再次执行”后不会同时看到上一轮完成回顾和启动中状态。
- 新一轮学习返回后仍会重新进入完成回顾状态。
- 不改变具体学习模式的内部行为。

### Leaf 11.31：成功标准变成本地完成清单

输出：

- AgentSessionLaunchScreen 新增 _checkedCriteria 本地状态。
- _SuccessCriteriaPanel 支持 checkedIndexes、enabled 和 onChanged。
- 学习动作返回后，用户可以逐条勾选成功标准。
- 再次执行 session 时清空上一轮勾选状态。
- 完成回顾面板展示已确认成功标准数量。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动前成功标准只作为提示展示。
- 学习动作返回后成功标准可以逐条勾选。
- 勾选状态只保存在当前页面本地，不写数据库。

### Leaf 11.32：完成回顾支持本地复盘笔记

输出：

- AgentSessionLaunchScreen 新增 _reflectionController。
- 页面销毁时 dispose 复盘输入 controller。
- 再次执行 session 时清空上一轮本地复盘草稿。
- CompletionReviewPanel 展示本地复盘输入框。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在学习动作返回后可以写下本轮复盘笔记。
- 复盘笔记暂时只保存在当前页面本地，不写数据库。
- 再次执行时不会带入上一轮复盘草稿。

### Leaf 11.33：保存 Agent Session 完成摘要

输出：

- LearningSessionMode 新增 agentSession。
- AgentSessionLaunchScreen 记录 _lastStartedAt。
- 点击“完成并返回 Agent”时保存一条 LearningSession。
- 完成摘要包含目标、成功标准确认数和本地复盘笔记。
- 保存后刷新 learningSessionListProvider。

涉及文件：

```text
lib/data/models/learning_session.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent Session 完成回顾可以落到 learning_sessions 表。
- 保存不影响具体导师、面试、练习、复习模式自己的记录逻辑。
- 复盘保存失败时停留在当前页并提示错误。

### Leaf 11.34：Agent 首页展示已保存 Session 摘要

输出：

- 新增 agentSessionListProvider，只返回 agentSession 模式记录。
- Agent 首页新增“最近 Agent Session”历史区。
- 已保存 Agent Session 展示目标、成功标准和复盘摘要。
- 无记录时展示专用空状态。
- 保存 Agent Session 后刷新 agentSessionListProvider。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 完成 Agent Session 并返回首页后，最近记录会出现在 Agent 首页。
- Agent Session 历史不混入普通面试复盘列表。
- 没有历史时页面不会因为缺少空状态组件而构建失败。

### Leaf 11.35：已保存 Agent Session 可查看完整复盘

输出：

- 新增 AgentSessionDetailScreen。
- Agent Session 历史卡片可点击进入详情。
- 详情页展示本轮标题、开始/完成时间、目标、成功标准和复盘笔记。
- 摘要解析只使用本地 LearningSession.summary，不新增外部依赖。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能从 Agent 首页打开已保存 Agent Session 的完整复盘。
- 摘要为空或旧数据不符合新格式时，详情页仍能显示兜底内容。
- Agent Session 详情不混用面试 turn 数据或未核验知识内容。

### Leaf 11.36：Agent Session 复盘回链知识点

输出：

- AgentSessionDetailScreen 读取 session.targetId 对应的 KnowledgePoint。
- targetId 命中知识点时展示可点击的知识点入口。
- 点击入口进入现有 KnowledgePointDetailScreen。
- targetId 不是知识点或旧数据缺失时，详情页保持可用。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 围绕焦点知识点完成的 Agent Session 可以回到知识库详情。
- 非知识点目标的 Agent Session 不显示错误入口。
- 回链不改变知识点详情页已有的来源、题目和学习动作规则。

### Leaf 11.37：复盘摘要保留已确认成功标准

输出：

- AgentSessionLaunchScreen 保存完成摘要时写入已勾选成功标准文本。
- AgentSessionDetailScreen 解析并展示“已确认标准”。
- 旧记录没有该字段时继续只展示成功标准数量。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户完成 Agent Session 后能回看自己具体确认了哪些成功标准。
- 未勾选任何标准时不写入空的“已确认”字段。
- 旧 Agent Session 摘要仍可正常查看。

### Leaf 11.38：复盘摘要保留下一步追问

输出：

- AgentSessionLaunchScreen 完成回顾新增“下次追问”输入。
- 再次执行 Agent Session 时清空上一轮追问草稿。
- 保存完成摘要时写入“下次追问”字段。
- AgentSessionDetailScreen 解析并展示“下次追问”。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能把本轮学习产生的下一步问题结构化保存下来。
- 未填写追问时不写入空字段。
- 旧 Agent Session 详情仍能正常展示复盘笔记和成功标准。

### Leaf 11.39：启动页带入上次追问

输出：

- AgentSessionLaunchScreen 读取已保存 Agent Session 历史。
- 根据当前 session targetId 查找同目标最近的“下次追问”。
- 启动页在成功标准前展示“上次留下的问题”。
- AgentSessionDetailScreen 支持多行“下次追问”解析。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 同一知识点或同一步骤再次启动 Agent Session 时，能看到上一轮留下的追问。
- 没有历史追问时启动页不显示空面板。
- 该提示只读取本地历史，不触发 AI 调用，也不放宽来源约束。

### Leaf 11.40：完整 Agent Session 历史列表

输出：

- 新增 AgentSessionHistoryScreen。
- 历史页读取 agentSessionListProvider，展示全部已保存 Agent Session。
- 历史卡片展示标题、目标、成功标准、完成时间和下一步追问。
- Agent 首页在存在记录时显示“查看全部 Agent Session”入口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户不只依赖首页最近 3 条，也能进入完整 Agent Session 历史。
- 点击任意历史记录能进入 AgentSessionDetailScreen。
- 无历史、加载中和加载失败都有明确状态。

### Leaf 11.41：Agent Session 历史支持目标筛选

输出：

- AgentSessionHistoryScreen 支持全部、AI 应用开发面试、讲清项目细节、编程知识学习筛选。
- 筛选状态只保存在当前页面本地。
- 筛选依据来自 Agent Session 摘要首行中的目标标签。
- 当前筛选无记录时显示明确空状态。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能按学习目标回看 Agent Session 历史。
- 旧记录或无法识别目标的记录仍留在“全部”视图。
- 筛选不改数据库、不触发 AI 调用，也不影响首页最近记录。

### Leaf 11.42：Agent Session 历史支持只看未处理追问

输出：

- AgentSessionHistoryScreen 新增“只看未处理追问”筛选。
- 目标筛选和未处理追问筛选可以组合使用。
- 筛选依据来自本地摘要中的“下次追问”字段。
- 当前筛选无记录时复用明确空状态。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能快速找到需要下一轮继续追问的 Agent Session。
- 筛选只读本地历史，不写数据库、不触发 AI。
- 没有未处理追问记录时不会显示误导性的空白列表。

### Leaf 11.43：集中 Agent Session 摘要解析

输出：

- 新增 AgentSessionSummaryRecord 共享解析器。
- AgentSessionDetailScreen 使用共享解析器读取目标、成功标准、追问和复盘。
- AgentSessionHistoryScreen 使用共享解析器做目标筛选和未处理追问筛选。
- AgentSessionLaunchScreen 使用共享解析器读取上一轮追问。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_detail_screen.dart
lib/features/agent/agent_session_history_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent Session 摘要字段不再在多个页面重复解析。
- 旧记录为空或格式不完整时仍有标题、目标和成功标准兜底展示。
- 历史筛选、详情展示和启动页上一轮追问使用同一套字段解释。

### Leaf 11.44：Agent 首页展示本地学习记忆摘要

输出：

- AgentHomeScreen 在目标选择后展示“学习记忆”摘要。
- 摘要展示累计 Agent Session 数、当前目标记录数、未处理追问数。
- 摘要统计使用 AgentSessionSummaryRecord 共享解析器。
- 加载中显示轻量占位，读取失败时不阻塞学习路线。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户进入 Agent 首页即可看到本地学习历史沉淀。
- 切换学习目标后，当前目标记录数随之变化。
- 统计只读取本地 Agent Session 历史，不触发 AI 调用。

### Leaf 11.45：学习记忆直达未处理追问队列

输出：

- AgentSessionHistoryScreen 支持 initialGoal 和 initialOnlyWithFollowUp。
- Agent 首页学习记忆摘要在存在未处理追问时显示“查看未处理追问”入口。
- 点击入口打开完整历史页，并自动启用“只看未处理追问”。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能从 Agent 首页直接进入待继续学习的问题队列。
- 没有未处理追问记录时不显示无效入口。
- 跳转只改变历史页初始筛选，不改写任何学习记录。

### Leaf 11.46：学习记忆直达当前目标历史

输出：

- Agent 首页学习记忆摘要在当前目标有记录时显示“查看当前目标记录”入口。
- 点击入口打开 AgentSessionHistoryScreen，并传入 initialGoal。
- 历史页沿用已有目标筛选，不新增数据库字段。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能从 Agent 首页直接进入当前学习目标的历史记录。
- 当前目标没有历史时不显示无效入口。
- 跳转只改变历史页初始筛选，不改写任何学习记录。

### Leaf 11.47：Agent Session 历史支持本地搜索

输出：

- AgentSessionHistoryScreen 新增搜索输入。
- 搜索可匹配标题、目标、成功标准、已确认标准、下次追问、复盘笔记和完整摘要。
- 搜索可与目标筛选、未处理追问筛选组合使用。
- 无搜索结果时显示明确空状态。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能在完整历史中按关键词找回学习记录。
- 搜索只在本地已加载 Agent Session 上执行，不触发 AI 或网络。
- 搜索不改写任何学习记录或筛选持久状态。

### Leaf 11.48：Agent Session 历史支持清除筛选

输出：

- AgentSessionHistoryScreen 检测目标筛选、未处理追问筛选和搜索词是否激活。
- 有激活筛选时显示“清除筛选”操作。
- 点击后重置目标、未处理追问开关和搜索输入。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能一键回到完整历史列表。
- 没有激活筛选时不显示多余操作。
- 清除筛选只影响当前页面状态，不改写任何学习记录。

### Leaf 11.49：历史筛选显示目标记录数

输出：

- AgentSessionHistoryScreen 统计各学习目标的 Agent Session 数量。
- 目标筛选 chip 展示目标名称和记录数。
- “全部”chip 展示总记录数。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能在筛选前看到每个学习目标的历史记录分布。
- 统计使用 AgentSessionSummaryRecord 共享解析器。
- 目标计数只读本地历史，不改数据库、不触发 AI。

### Leaf 11.50：导师模式接收上次追问

输出：

- TutorSessionScreen 新增 initialFollowUpQuestion。
- AgentSessionLaunchScreen 启动 tutor 步骤时读取同 target 的最近“下次追问”并传入导师模式。
- TutorSessionScreen 展示本轮优先追问，并在生成讲解时传给 TutorExplanationTask。
- TutorExplanationTask 将 follow_up_question 放入用户内容，并要求来源不足时明确说明。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/tutor_session_screen.dart
lib/services/ai/tasks/tutor_explanation_task.dart
docs/trellis-execution-map.md
```

验收：

- 上一轮 Agent Session 留下的问题可以进入下一轮导师讲解上下文。
- 导师讲解仍只允许基于提供的 knowledge point 和 source chunks。
- 没有上次追问时导师模式保持原行为。

### Leaf 11.51：面试模式接收上次追问

输出：

- InterviewSessionScreen 新增 initialFollowUpQuestion。
- AgentSessionLaunchScreen 启动 interview 步骤时读取同 target 的最近“下次追问”并传入面试模式。
- InterviewerService 和 InterviewQuestionTask 支持 followUpQuestion。
- InterviewQuestionTask 将 follow_up_question 放入用户内容，并继续执行 knowledge point 和 citation id 清洗。
- 面试进度头部展示本轮优先追问。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/interview_session_screen.dart
lib/services/agent/interviewer_service.dart
lib/services/ai/tasks/interview_question_task.dart
docs/trellis-execution-map.md
```

验收：

- 上一轮 Agent Session 留下的问题可以影响下一轮面试追问生成。
- 生成的问题仍必须绑定有效 knowledge_point_ids 和 citation_ids。
- 没有上次追问时面试模式保持原行为。

### Leaf 11.52：复盘详情直达追问学习动作

输出：

- AgentSessionDetailScreen 在存在 target 知识点和“下次追问”时显示继续学习动作。
- “导师追问”打开 TutorSessionScreen，并传入 initialPoint 和 initialFollowUpQuestion。
- “面试追问”打开 InterviewSessionScreen，并传入 initialPoint 和 initialFollowUpQuestion。
- 非知识点目标、旧记录或没有追问时不显示无效动作。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能从 Agent Session 复盘详情直接继续处理上次留下的问题。
- 继续学习动作复用已来源约束的导师和面试模式。
- 缺少知识点或追问内容时详情页保持只读展示。

### Leaf 11.53：追问学习后刷新学习记录

输出：

- InterviewSessionScreen 完成面试后刷新 learningSessionListProvider 和 interviewSessionListProvider。
- AgentSessionDetailScreen 的导师追问和面试追问返回后刷新学习记录相关 provider。
- 刷新只影响本地 provider 状态，不改写 Agent Session 历史。

涉及文件：

```text
lib/features/agent/interview_session_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从复盘详情继续学习后，返回时首页/历史能读到新学习记录状态。
- 面试完成后的复盘列表不会依赖外层页面手动刷新。
- 追问动作仍不修改原 Agent Session 摘要。

### Leaf 11.54：Agent Session 摘要记录本轮追问

输出：

- AgentSessionLaunchScreen 在导师或面试步骤带入上次追问时，记录本轮使用的追问。
- 完成摘要新增“本轮追问”字段。
- AgentSessionSummaryRecord 解析“本轮追问”。
- AgentSessionDetailScreen 展示本轮追问。
- AgentSessionHistoryScreen 支持搜索和列表展示本轮追问。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_detail_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能区分一轮 Agent Session 处理了哪个历史追问，以及留下了哪个新的下次追问。
- 没有带入历史追问时不写入空的“本轮追问”字段。
- 旧 Agent Session 摘要仍能正常解析和展示。

### Leaf 11.55：从历史推断未处理追问

输出：

- 新增 AgentSessionFollowUpIndex，根据 Agent Session 历史推断未处理追问。
- 后续 session 的“本轮追问”会抵消同 target 下较早 session 的“下次追问”。
- Agent 首页“未处理追问”指标使用 AgentSessionFollowUpIndex。
- AgentSessionHistoryScreen 的“只看未处理追问”只展示尚未被后续 session 处理的追问。
- 历史列表中已处理的追问显示为“已处理追问”。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 已经被后续 Agent Session 作为“本轮追问”处理过的问题，不再进入未处理追问队列。
- 未处理追问推断只读取本地历史，不改写旧摘要或数据库。
- 首页指标、历史筛选和列表标记使用同一套未处理追问判断。

### Leaf 11.56：复盘详情区分未处理与已处理追问

输出：

- AgentSessionDetailScreen 使用 AgentSessionFollowUpIndex 判断当前复盘的下次追问是否仍未处理。
- 未处理追问显示“未处理追问”，并保留导师追问/面试追问动作。
- 已处理追问显示“已处理追问”，不再显示继续学习动作。
- 历史判断加载中时先显示中性标题“下次追问”，避免误标为已处理。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 已被后续 Agent Session 处理过的追问不会在复盘详情中继续显示学习动作。
- 未处理追问仍能从复盘详情继续进入导师或面试追问。
- 详情页、首页和历史列表使用同一套未处理追问判断。

### Leaf 11.57：完成学习动作后才记录追问已处理

输出：

- AgentSessionDetailScreen 的导师追问/面试追问动作在打开子学习页前记录已完成 session 数量。
- 子学习页返回后再次读取本地学习记录，只在完成数量增加时保存一条轻量 Agent Session。
- 轻量记录写入“本轮追问”，用于 AgentSessionFollowUpIndex 抵消历史“下次追问”。
- 用户只打开子学习页后返回、或面试未完成时，不会误标追问为已处理。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从复盘详情完成导师追问后，历史追问会变为已处理。
- 从复盘详情完成面试追问后，历史追问会变为已处理。
- 未完成导师/面试动作直接返回时，不新增处理记录，也不隐藏原追问动作。

### Leaf 11.58：追问动作返回后给出完成反馈

输出：

- AgentSessionDetailScreen 在追问动作返回后提示用户是否检测到完成记录。
- 已成功写入轻量 Agent Session 时提示“已记录为已处理追问”。
- 未检测到完成导师/面试记录时提示追问仍保持未处理。
- 保存失败继续显示错误提示，不吞掉异常原因。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户完成导师追问或面试追问并返回后，会收到已处理反馈。
- 用户打开追问动作但未完成学习时，会收到未完成反馈。
- 反馈只展示本地判定结果，不改变 11.57 的数据写入条件。

### Leaf 11.59：避免追问动作重复触发

输出：

- _FollowUpActionCard 从无状态组件改为本地有运行态的组件。
- 用户点击导师追问或面试追问后，两个追问按钮都会暂时禁用。
- 子学习页返回或动作结束后恢复按钮可用。
- 数据写入仍由 AgentSessionDetailScreen 的完成判定控制。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 快速重复点击追问按钮不会连续打开多个学习页。
- 防重复触发不改变导师/面试模式本身的来源约束。
- 防重复触发不改变追问已处理记录的写入条件。

### Leaf 11.60：启动页只带入未处理追问

输出：

- AgentSessionLaunchScreen 查找历史追问时复用 AgentSessionFollowUpIndex。
- 启动页“上次留下的问题”只展示同 target 下仍未处理的追问。
- 导师和面试步骤只接收仍未处理的 initialFollowUpQuestion。
- 已被后续 Agent Session 或详情页处理记录抵消的追问，不再被下一轮启动页带入。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 已处理追问不会重新出现在 Agent Session 启动页。
- 启动导师/面试步骤时不会再次传入已处理追问。
- 启动页、详情页、历史页和首页使用同一套未处理追问判断。

### Leaf 11.61：首页最近记录显示追问状态

输出：

- Agent 首页最近 Agent Session 卡片使用 AgentSessionSummaryRecord 解析摘要。
- 最近卡片展示本轮追问，帮助用户回忆本轮处理的问题。
- 最近卡片展示未处理追问或已处理追问状态。
- 首页最近记录使用 AgentSessionFollowUpIndex，与完整历史和详情页保持一致。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 首页最近 Agent Session 能看到本轮追问。
- 首页最近 Agent Session 能区分未处理和已处理追问。
- 首页最近记录、完整历史、详情页的追问状态判断一致。

### Leaf 11.62：启动页完成学习动作后才记录本轮追问

输出：

- AgentSessionLaunchScreen 启动导师/面试追问前记录对应知识点的已完成 session 数量。
- 导师/面试页面返回后再次读取本地学习记录。
- 只有完成数量增加时，完成摘要才写入“本轮追问”。
- 用户只打开导师/面试页面后返回时，不会通过 Agent Session 完成摘要误标追问为已处理。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动页进入导师追问并完成讲解后，完成摘要会记录本轮追问。
- 启动页进入面试追问并完成面试后，完成摘要会记录本轮追问。
- 未完成导师/面试动作直接返回时，完成摘要不写入本轮追问。

### Leaf 11.63：启动页追问完成计数空安全加固

输出：

- AgentSessionLaunchScreen 的追问完成计数 helper 稳定返回 int。
- 缺少知识点、缺少追问或追问为空时，计数结果回落为 0。
- 完成前后计数比较不再依赖 nullable int。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动页追问完成判定不会出现 nullable int 直接比较。
- 没有历史追问时导师/面试步骤保持原有行为。
- 空安全加固不改变 11.62 的完成后才记录本轮追问规则。

### Leaf 11.64：启动页追问处理结果给出反馈

输出：

- AgentSessionLaunchScreen 在导师/面试追问返回后检查历史追问是否完成处理。
- 检测到完成记录时提示本轮复盘会记录这条本轮追问。
- 未检测到完成记录时提示本轮复盘不会把追问标记为已处理。
- 没有历史追问时不显示额外提示。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动页追问完成后用户能看到明确的已处理反馈。
- 启动页追问未完成直接返回时用户能看到未处理反馈。
- 反馈只说明本地完成判定，不改变追问记录写入条件。

### Leaf 11.65：集中完成学习记录的知识点匹配规则

输出：

- 新增 AgentSessionCompletionMatcher.matchesCompletedPoint。
- 统一判断 session mode、endedAt 和 targetId 是否匹配目标知识点。
- AgentSessionDetailScreen 的追问完成计数使用共享 matcher。
- AgentSessionLaunchScreen 的追问完成计数使用共享 matcher。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_detail_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 导师 session 仍按单一 targetId 匹配知识点。
- 面试 session 仍按 \x00 分隔的多 targetId 匹配知识点。
- 详情页和启动页使用同一套完成记录匹配规则。

### Leaf 11.66：历史页追问筛选显示未处理数量

输出：

- AgentSessionHistoryScreen 从 AgentSessionFollowUpIndex 读取未处理追问数量。
- _GoalFilterBar 接收 openFollowUpCount。
- “只看未处理追问”筛选旁展示当前未处理追问总数。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户进入完整历史页即可看到未处理追问队列规模。
- 未处理数量使用与首页、详情页一致的 AgentSessionFollowUpIndex。
- 数量展示只读本地历史，不改写任何学习记录。

### Leaf 11.67：历史页追问数量跟随目标筛选

输出：

- AgentSessionHistoryScreen 新增 _openFollowUpCount helper。
- 未选择目标时，“只看未处理追问”旁显示全局未处理数量。
- 已选择目标时，该数量只统计当前目标下的未处理追问。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 目标筛选切换后，未处理追问数量随当前目标变化。
- 未选择目标时仍能看到全局未处理追问数量。
- 数量计算仍复用 AgentSessionFollowUpIndex，不引入新的追问判断规则。

### Leaf 11.68：首页学习记忆显示当前目标追问

输出：

- Agent 首页学习记忆新增“当前目标追问”指标。
- 指标统计当前学习目标下仍未处理的历史追问。
- 当前目标存在未处理追问时，入口优先打开当前目标的未处理追问历史。
- 当前目标没有未处理追问但全局存在时，保留全局未处理追问入口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 切换 Agent 学习目标后，当前目标追问数随之变化。
- 当前目标追问入口会带入 initialGoal 和 initialOnlyWithFollowUp。
- 追问数量继续复用 AgentSessionFollowUpIndex。

### Leaf 11.69：集中当前目标未处理追问计数

输出：

- AgentSessionFollowUpIndex 新增 openFollowUpCountForGoal。
- Agent 首页“当前目标追问”使用共享索引计数。
- Agent Session 历史页目标筛选下的未处理追问数量使用共享索引计数。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 首页和历史页使用同一个方法统计目标维度未处理追问。
- 全局未处理追问数量继续使用 openFollowUpCount。
- 不新增数据库字段，也不改写任何 Agent Session 摘要。

### Leaf 11.70：历史筛选栏显示追问摘要

输出：

- AgentSessionHistoryScreen 的筛选栏在记录数下展示未处理追问摘要。
- 未选择目标时显示当前视图的未处理追问数量。
- 已选择目标时显示当前目标的未处理追问数量。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户无需点筛选即可看到当前视图还有多少未处理追问。
- 摘要数量与“只看未处理追问”旁的数量一致。
- 该摘要只读本地历史，不改变筛选状态和学习记录。

### Leaf 11.71：历史空状态跟随筛选语境

输出：

- AgentSessionHistoryScreen 新增 _emptyFilteredMessage。
- “只看未处理追问”无结果时提示没有未处理追问。
- 搜索无结果时提示当前搜索没有匹配记录。
- 目标筛选无结果时提示当前目标还没有 Agent Session 记录。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 未处理追问筛选为空时不会误导为普通历史为空。
- 搜索为空结果时用户能知道是搜索条件导致。
- 空状态只读当前页面状态，不改写任何本地记录。

### Leaf 11.72：历史空状态支持清除筛选

输出：

- _EmptyFilteredHistory 接收可选 onClearFilters。
- 有激活筛选且结果为空时，空状态卡片显示“清除筛选”入口。
- 点击入口复用 AgentSessionHistoryScreen 已有 _clearFilters。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 搜索、目标筛选或追问筛选导致空结果时，可以从空状态直接清除筛选。
- 没有激活筛选时不显示无效清除按钮。
- 清除动作只影响当前页面状态，不改写任何学习记录。

### Leaf 11.73：启动页提示同目标追问积压

输出：

- AgentSessionFollowUpIndex 新增 openFollowUpCountForTarget。
- AgentSessionLaunchScreen 在展示“上次留下的问题”时统计同 target 未处理追问数量。
- 同一 target 还有多条未处理追问时，在提示卡片中显示剩余数量。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动页仍只带入最近一条未处理追问进入导师/面试上下文。
- 同目标存在多条未处理追问时，用户能看到剩余积压数量。
- 统计只读取本地 Agent Session 历史，不触发 AI 或改写记录。

### Leaf 11.74：启动页积压追问直达同目标历史

输出：

- AgentSessionHistoryScreen 支持 initialTargetId 和 initialTargetLabel。
- 历史页可在初始状态下按 targetId 过滤 Agent Session。
- 启动页“上次留下的问题”在同 target 有多条未处理追问时显示“查看这组追问”入口。
- 点击入口打开历史页，并带入 initialGoal、initialOnlyWithFollowUp、initialTargetId 和 initialTargetLabel。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动页存在同目标追问积压时，用户可以直接进入同目标未处理追问队列。
- 历史页 target 初始筛选可以被“清除筛选”重置。
- 入口只改变历史页初始筛选，不触发 AI，也不改写学习记录。

### Leaf 11.75：历史页标识 target 筛选状态

输出：

- _GoalFilterBar 接收 hasTargetFilter。
- target 筛选存在时，筛选栏标题使用 target label 或“当前目标”兜底。
- target 筛选存在时，筛选栏展示“目标筛选”标识。
- target 筛选存在时，追问摘要使用当前目标语境。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从启动页进入同目标追问队列后，历史页明确显示当前处于目标筛选。
- 缺少 target label 时仍有“当前目标”兜底文案。
- 目标筛选标识只反映页面筛选状态，不改写学习记录。

### Leaf 11.76：历史页支持单独移除 target 筛选

输出：

- AgentSessionHistoryScreen 新增 _clearTargetFilter。
- _GoalFilterBar 接收 onClearTargetFilter。
- 目标筛选标识新增关闭按钮，只移除 targetId 和 targetLabel。
- 其他筛选状态，如目标类别、未处理追问和搜索词，保持不变。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从目标筛选标识直接移除 target 筛选。
- 单独移除 target 筛选不会清空搜索词或未处理追问筛选。
- 该操作只影响当前页面状态，不改写任何学习记录。

### Leaf 11.77：切换历史目标时清除 target 筛选

输出：

- AgentSessionHistoryScreen 的目标 chip 回调在设置 selectedGoal 时清空 targetId 和 targetLabel。
- 从 target-filtered 历史页点击“全部”或任一学习目标后，页面回到目标类别筛选视图。
- 搜索词和“只看未处理追问”状态保持不变。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户切换目标 chip 后不会继续被旧 targetId 隐性过滤。
- 未处理追问筛选和搜索筛选在目标切换后仍保持当前页面状态。
- 切换目标只影响页面筛选状态，不改写任何学习记录。

### Leaf 11.78：首页非空历史始终可进入完整历史

输出：

- Agent 首页最近 Agent Session 区域在存在任意记录时展示“查看全部 Agent Session”入口。
- 入口不再依赖记录数超过 3 条。
- 无历史时继续显示空状态，不显示无效入口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户只有 1 到 3 条 Agent Session 记录时，也能进入完整历史页使用搜索和筛选。
- 最近记录区仍只预览最多 3 条记录。
- 该入口只打开历史页，不改写任何学习记录。

### Leaf 11.79：同步历史入口文档条件

输出：

- 更新 Leaf 11.40 中 Agent 首页完整历史入口的描述。
- 旧描述从“记录超过 3 条”调整为“存在记录”。
- Leaf 11.40 和 Leaf 11.78 对完整历史入口的规则保持一致。

涉及文件：

```text
docs/trellis-execution-map.md
```

验收：

- Trellis 文档不再同时保留互相冲突的完整历史入口条件。
- 文档说明与 AgentHomeScreen 当前行为一致。
- 该变更只更新规划文档，不改变应用运行逻辑。

### Leaf 11.80：首页完整历史入口显示总数

输出：

- Agent 首页“查看全部 Agent Session”入口文案展示当前 Agent Session 总数。
- 文案从固定文本改为“查看全部 N 条 Agent Session”。
- 无历史时继续显示空状态，不显示入口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在首页即可知道完整历史里有多少条 Agent Session。
- 记录总数来自 agentSessionListProvider 当前数据。
- 入口仍只打开历史页，不改写任何学习记录。

### Leaf 11.81：首页学习记忆入口显示对应数量

输出：

- “查看当前目标记录”入口展示当前目标记录数。
- “查看当前目标追问”入口展示当前目标未处理追问数。
- “查看未处理追问”入口展示全局未处理追问数。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 首页学习记忆指标和入口文案中的数量一致。
- 入口跳转逻辑保持不变。
- 数量展示只读本地 Agent Session 历史，不改写记录。

### Leaf 11.82：路线卡片提示当前目标追问

输出：

- AgentHomeScreen 从 agentSessionListProvider 读取当前目标未处理追问数量。
- _LearningAgentPlanCard 接收 goalFollowUpCount 和 onOpenGoalFollowUps。
- 当前目标存在未处理追问时，路线卡片展示追问提醒。
- 点击提醒中的“查看”进入当前目标的未处理追问历史页。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent 路线卡片能提醒用户当前目标仍有未处理追问。
- 提醒入口打开 AgentSessionHistoryScreen，并带入 initialGoal 和 initialOnlyWithFollowUp。
- 提醒只读取本地历史，不改变学习计划算法或学习记录。

### Leaf 11.83：路线卡片直达当前目标历史

输出：

- AgentHomeScreen 从 agentSessionListProvider 读取当前目标 Agent Session 数量。
- _LearningAgentPlanCard 接收 goalSessionCount 和 onOpenGoalHistory。
- 当前目标已有 Agent Session 时，路线卡片展示“查看当前目标 N 条记录”入口。
- 点击入口进入带 initialGoal 的 AgentSessionHistoryScreen。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent 路线卡片能直达当前目标的历史记录。
- 当前目标没有历史记录时不显示历史入口。
- 历史入口只读取本地 Agent Session，不改变学习计划算法或学习记录。

### Leaf 11.84：集中当前目标 Agent Session 计数

输出：

- Agent Session memory index service 新增 AgentSessionGoalIndex。
- 首页当前目标记录数改用 AgentSessionGoalIndex。
- 历史页 goal filter 计数改用 AgentSessionGoalIndex。
- 移除历史页内重复的 _goalCounts 私有统计逻辑。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 当前目标 Agent Session 数量只有一个集中统计入口。
- 首页路线卡片、学习记忆栏和历史页目标筛选数量保持同一推导规则。
- 统计逻辑只读取本地 Agent Session，不改变学习计划算法或学习记录。

### Leaf 11.85：预计算 Agent Session 追问统计

输出：

- AgentSessionFollowUpIndex 构建时预计算全局未处理追问总数。
- AgentSessionFollowUpIndex 构建时预计算目标维度未处理追问数量。
- AgentSessionFollowUpIndex 构建时预计算 target 维度未处理追问数量。
- openFollowUpCount、openFollowUpCountForGoal 和 openFollowUpCountForTarget 保持原有调用方式。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
docs/trellis-execution-map.md
```

验收：

- 首页、历史页和启动页继续通过同一个追问索引读取数量。
- 追问数量只在索引构建时从本地 Agent Session 历史推导。
- 统计逻辑不改变追问打开/处理判断规则，也不写入学习记录。

### Leaf 11.86：首页复用 Agent Session memory index

输出：

- Agent Session memory index service 新增 AgentSessionMemoryIndex。
- AgentHomeScreen 从 agentSessionListProvider 构建一次 AgentSessionMemoryIndex。
- 路线卡片计数、学习记忆栏和最近 Agent Session 状态复用同一个 memory index。
- 最近 Agent Session 入口总数改从 memory index 读取。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent 首页不再为同一批 Agent Session 历史重复构建目标索引和追问索引。
- 首页所有学习记忆数量仍来自本地 Agent Session 历史。
- memory index 只读本地历史，不改变学习计划算法或学习记录。

### Leaf 11.87：历史页复用 Agent Session memory index

输出：

- AgentSessionMemoryIndex 新增 openFollowUpCountForTarget。
- AgentSessionHistoryScreen 构建一次 AgentSessionMemoryIndex。
- 历史页目标筛选数量、总数和追问数量从 memory index 读取。
- 历史页筛选列表复用 memory index 中的 sessions 和 followUps。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent 历史页和首页使用同一套本地 memory index 读取学习记忆数量。
- target、goal 和全局未处理追问数量保持原有筛选语义。
- 历史页只读取本地 Agent Session 历史，不改变学习计划算法或学习记录。

### Leaf 11.88：启动页复用 Agent Session memory index

输出：

- AgentSessionMemoryIndex 新增 latestOpenFollowUpQuestionForTarget。
- AgentSessionLaunchScreen 顶部追问提醒改用 AgentSessionMemoryIndex。
- Tutor/Interview 启动前加载历史追问改用 AgentSessionMemoryIndex。
- 移除启动页内重复的 _latestFollowUpQuestion 私有扫描逻辑。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动页展示追问 backlog 与实际注入 Tutor/Interview 的追问使用同一套 memory index。
- 最新未处理追问仍按原本的本地 Agent Session 顺序读取。
- 启动页只读取本地历史，不改变学习计划算法或学习记录。

### Leaf 11.89：详情页复用 Agent Session memory index

输出：

- AgentSessionDetailScreen 追问状态判断改用 AgentSessionMemoryIndex。
- 详情页不再直接构建 AgentSessionFollowUpIndex。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent Session 详情页追问状态与首页、历史页、启动页使用同一套 memory index。
- 追问状态仍只从本地 Agent Session 历史推导。
- 详情页不改变追问处理、学习计划算法或学习记录写入路径。

### Leaf 11.90：Agent Session memory 进入 service 层

输出：

- 将 AgentSessionSummaryRecord、AgentSessionGoalIndex、AgentSessionFollowUpIndex、AgentSessionMemoryIndex 和 AgentSessionCompletionMatcher 移到 service 层。
- 新文件为 lib/services/agent/agent_session_memory_index.dart。
- Agent 首页、历史页、启动页和详情页更新 import。
- 移除 features/agent 下的旧 agent_session_summary_parser.dart 文件。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_history_screen.dart
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent Session memory 解析和索引逻辑不再位于 UI feature 文件夹。
- 所有 Agent 页面都从 service 层导入同一套 memory index。
- 文件移动不改变本地历史推导规则、学习计划算法或学习记录写入路径。

### Leaf 11.91：新增 Agent Session memory provider

输出：

- providers.dart 新增 agentSessionMemoryIndexProvider。
- provider 基于 agentSessionListProvider 构建 AgentSessionMemoryIndex。
- AgentHomeScreen 改为 watch agentSessionMemoryIndexProvider。
- AgentSessionHistoryScreen 改为 watch agentSessionMemoryIndexProvider。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 首页和历史页不再各自从 agentSessionListProvider 手动构建 memory index。
- 现有对 agentSessionListProvider 的刷新仍会驱动 memory provider 更新。
- provider 只读取本地 Agent Session 历史，不改变学习计划算法或学习记录写入路径。

### Leaf 11.92：启动页和详情页复用 memory provider

输出：

- AgentSessionLaunchScreen 顶部追问提醒改为 watch agentSessionMemoryIndexProvider。
- AgentSessionLaunchScreen 启动 Tutor/Interview 前加载追问改为 read agentSessionMemoryIndexProvider.future；后续 Leaf 13.11 已将 executor 内追问读取迁到 LearningAgentMemoryStore。
- AgentSessionDetailScreen 追问状态判断改为 watch agentSessionMemoryIndexProvider。
- Agent UI 页面不再手动构建 AgentSessionMemoryIndex。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 启动页、详情页、首页和历史页都通过同一个 memory provider 读取 Agent Session memory。
- 现有对 agentSessionListProvider 的刷新仍会驱动 memory provider 更新。
- 追问读取和状态判断规则不变，不改变学习计划算法或学习记录写入路径。

### Leaf 11.93：Agent Session 变化后显式刷新 memory

输出：

- AgentHomeScreen 从 Agent Session 启动页返回完成时刷新 agentSessionMemoryIndexProvider。
- AgentSessionLaunchScreen 保存复盘后刷新 agentSessionMemoryIndexProvider。
- AgentSessionDetailScreen 完成追问动作后刷新 agentSessionMemoryIndexProvider。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 所有现有 agentSessionListProvider 刷新点同步刷新 memory provider。
- 刷新动作只让 UI 重新读取本地历史，不新增写入路径。
- 追问状态、历史数量和启动页 backlog 能在 Agent Session 变化后及时更新。

### Leaf 11.94：学习计划接收 Agent Session memory context

输出：

- LearningAgentPlan 新增 LearningAgentMemoryState。
- LearningAgentPlannerService.buildPlan 接收当前目标记录数和当前目标未处理追问数。
- learningAgentPlanProvider 从 agentSessionMemoryIndexProvider 读取当前目标 memory context。
- AgentHomeScreen 路线卡片计数改为读取 plan.memory。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 学习计划对象本身携带当前目标的 Agent Session 记忆摘要。
- 路线卡片使用 plan.memory 展示当前目标历史和追问提醒。
- memory context 只读本地 Agent Session 历史，不改变学习步骤选择或学习记录写入路径。

### Leaf 11.95：路线卡片直接读取 plan.memory

输出：

- _LearningAgentPlanCard 移除 goalSessionCount 和 goalFollowUpCount 入参。
- _LearningAgentPlanCard 内部从 plan.memory 读取当前目标历史数和追问数。
- AgentHomeScreen 只根据 plan.memory 决定历史/追问入口是否可打开。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 路线卡片 memory 展示以 LearningAgentPlan.memory 为唯一来源。
- AgentHomeScreen 不再单独计算路线卡片的当前目标历史数和追问数。
- UI 行为不变，不改变学习计划算法或学习记录写入路径。

### Leaf 11.96：Session 摘要展示学习记忆提示

输出：

- LearningAgentSessionSummary 新增 memoryReminder。
- LearningAgentPlannerService 根据 plan.memory 生成当前目标追问/历史提示。
- AgentHomeScreen 的 Agent Session 摘要展示学习记忆提示。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 当前目标有未处理追问时，路线摘要提示优先处理追问。
- 当前目标没有追问但有历史时，路线摘要提示先回看复盘。
- 记忆提示只读 plan.memory，不改变学习步骤选择或学习记录写入路径。

### Leaf 11.97：启动页展示学习记忆提示

输出：

- AgentSessionLaunchScreen 的 session hero 展示 summary.memoryReminder。
- 记忆提示与目标/路线信息使用同一 InfoLine 样式。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在真正启动 Agent Session 前也能看到当前目标追问/历史提示。
- 启动页和首页使用同一条 summary.memoryReminder。
- 展示逻辑不改变学习步骤选择、追问注入或学习记录写入路径。

### Leaf 11.98：学习路线优先处理未处理追问

输出：

- LearningAgentStepType 新增 handleFollowUps。
- LearningAgentPlannerService 在准备步骤后、正式学习步骤前加入“处理历史追问”步骤。
- 当前目标存在未处理追问时，该步骤成为下一步。
- AgentHomeScreen 执行该步骤时直接打开当前目标未处理追问历史页。
- AgentSessionLaunchScreen 补齐 handleFollowUps 的兜底路由和 step id。

涉及文件：

```text
lib/services/agent/learning_agent_planner_service.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 当前目标有未处理追问时，学习路线下一步显示为“处理历史追问”。
- 点击“执行下一步”只打开带 initialGoal 和 initialOnlyWithFollowUp 的历史页。
- 该步骤不新增学习记录写入路径，不改变来源核验、导师、面试或练习规则。

### Leaf 11.99：路线步骤数量显示单位

输出：

- _PlanStepRow 将 targetCount 从裸数字改为带单位标签。
- 待核验和练习步骤显示“道题”。
- 处理历史追问步骤显示“条追问”。
- 导师、面试和复习步骤显示“个知识点”。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能从路线步骤里直接看懂数量代表题目、追问还是知识点。
- 只改变展示文案，不改变步骤启用条件或学习记录写入路径。

### Leaf 11.100：追问历史路由不标记完成

输出：

- AgentSessionLaunchScreen 的 handleFollowUps 兜底分支打开历史页后直接返回。
- 返回前刷新 Agent 输入状态并关闭启动中状态。
- 不进入 completion review，也不允许保存空 Agent Session 复盘。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- handleFollowUps 只负责打开追问历史页。
- 从兜底路由返回后不会把查看历史页当成已完成学习动作。
- 不新增学习记录写入路径，不改变首页直接打开追问历史的主路径。

### Leaf 11.101：追问步骤使用专属主按钮

输出：

- _LearningAgentPlanCard 识别 handleFollowUps 下一步。
- 处理历史追问时，主按钮文案从“执行下一步”改为“查看未处理追问”。
- 处理历史追问时，主按钮图标改为 question_answer_outlined。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能从主按钮文案看出该动作只会打开追问历史页。
- 按钮点击逻辑保持不变，仍由 AgentHomeScreen 打开筛选后的历史页。
- 不改变学习步骤选择、追问处理或学习记录写入路径。

### Leaf 11.102：历史卡片显示继续追问入口

输出：

- AgentSessionHistoryScreen 的未处理追问卡片显示“继续追问”按钮。
- 按钮复用原有卡片 onTap，进入 Agent Session 详情页。
- 已处理追问卡片不显示该按钮。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户从“查看未处理追问”路线进入历史页后，可以直接看到继续入口。
- 继续入口仍进入详情页中的导师/面试追问动作，不新增写入路径。
- 已处理追问不会出现误导性的继续按钮。

### Leaf 11.103：Agent Session memory 按开始时间规范排序

输出：

- AgentSessionMemoryIndex 构建时按 startedAt 倒序保存 sessions。
- AgentSessionFollowUpIndex 构建时按 startedAt 倒序读取 sessions。
- latestOpenFollowUpQuestionForTarget 在规范化后的倒序 sessions 上读取最新未处理追问。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
docs/trellis-execution-map.md
```

验收：

- 最新未处理追问不依赖调用方传入列表的原始顺序。
- 首页、历史页和启动页读取的 Agent Session 顺序仍为最近优先。
- 只改变本地 memory index 的读取顺序，不改变学习记录写入路径。

### Leaf 11.104：学习记忆提示展示最近同目标记录

输出：

- AgentSessionMemoryIndex 新增 latestRecordForGoal。
- LearningAgentMemoryState 记录当前目标最近 Agent Session 的标题、目标和开始时间。
- LearningAgentPlannerService 的 memoryReminder 在已有历史或追问时补充最近记录上下文。
- learningAgentPlanProvider 将 Agent Session memory index 的最近记录传入学习计划。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/services/agent/learning_agent_planner_service.dart
lib/core/providers/providers.dart
docs/trellis-execution-map.md
```

验收：

- 当前目标有历史记录时，首页和启动页的学习记忆提示能指出最近一次同目标记录。
- 当前目标有未处理追问时，提示仍优先提醒追问，并带上最近记录上下文。
- 只读取本地 Agent Session summary，不新增数据库字段或学习记录写入路径。

### Leaf 11.105：首页学习记忆条直达最近复盘

输出：

- AgentSessionMemoryIndex 新增 latestSessionForGoal。
- AgentHomeScreen 的学习记忆条展示当前目标最近 Agent Session。
- 最近记录行显示标题、目标和开始时间。
- 用户可以从最近记录行直接打开 Agent Session 复盘详情。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 当前目标有历史记录时，学习记忆条出现“最近”记录入口。
- 点击“回看”进入对应 AgentSessionDetailScreen。
- 只新增本地历史读取和导航入口，不改变学习计划算法或学习记录写入路径。

### Leaf 11.106：启动页展示最近同目标复盘入口

输出：

- AgentSessionLaunchScreen 复用 agentSessionMemoryIndexProvider。
- 启动页 hero 下方展示当前目标最近一次 Agent Session 复盘。
- 最近复盘卡片显示标题、目标和开始时间。
- 用户可以从启动页直接打开 AgentSessionDetailScreen 回看复盘。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 当前目标有历史记录时，启动页显示“最近一次同目标复盘”。
- 点击“回看复盘”进入对应 AgentSessionDetailScreen。
- 只新增本地历史读取和导航入口，不改变 Agent Session 启动、完成复盘或追问写入路径。

### Leaf 11.107：复盘详情顶部展示目标和追问状态

输出：

- AgentSessionDetailScreen 的顶部摘要卡接收当前追问状态。
- 摘要卡展示 Agent Session 对应的学习目标。
- 摘要卡在存在下次追问时展示“有未处理追问 / 追问已处理 / 追问状态读取中”。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户从首页或启动页回看复盘时，顶部即可看到该记录属于哪个学习目标。
- 有下次追问的复盘顶部能直接看出追问是否仍未处理。
- 只新增本地展示逻辑，不改变追问处理、完成记录或学习计划算法。

### Leaf 11.108：复盘详情直达同目标历史

输出：

- AgentSessionDetailScreen 在存在学习目标时展示“同目标历史”入口。
- 点击“查看同目标历史”打开带 initialGoal 的 AgentSessionHistoryScreen。
- 当前复盘仍有未处理追问时，额外展示“查看未处理追问”入口。
- “查看未处理追问”打开带 initialGoal 和 initialOnlyWithFollowUp 的历史页。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户从复盘详情页可以回到同一学习目标的 Agent Session 历史。
- 对仍有未处理追问的复盘，用户可以直接进入当前目标未处理追问列表。
- 只新增本地导航入口，不改变追问处理、完成记录或学习计划算法。

### Leaf 11.109：复盘详情直达同目标对象历史

输出：

- AgentSessionDetailScreen 的同目标历史卡识别当前复盘的 targetId。
- targetId 存在时展示“查看本目标记录”入口。
- “查看本目标记录”打开带 initialGoal、initialTargetId 和 initialTargetLabel 的历史页。
- 当前复盘仍有未处理追问且 targetId 存在时，“查看未处理追问”优先进入同目标对象过滤后的追问列表。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户从复盘详情页可以只看同一知识点或同一目标对象的 Agent Session 历史。
- 未处理追问入口在存在 targetId 时能精确过滤到同一目标对象。
- 只新增本地导航入口，不改变追问处理、完成记录或学习计划算法。

### Leaf 11.110：复盘详情历史入口显示追问数量

输出：

- AgentSessionDetailScreen 从 AgentSessionMemoryIndex 读取未处理追问数量。
- 当前复盘有 targetId 时，数量优先使用同目标对象的未处理追问数。
- 当前复盘没有 targetId 但有学习目标时，数量回退到同学习目标的未处理追问数。
- “查看未处理追问”按钮在数量可用时显示具体条数。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在复盘详情页能看到未处理追问入口对应的积压数量。
- 数量与按钮打开的历史筛选范围一致：优先 targetId，其次学习目标。
- 只读取本地 Agent Session memory，不改变追问处理、完成记录或学习计划算法。

### Leaf 11.111：复盘详情显式导入学习目标类型

输出：

- AgentSessionDetailScreen 显式导入 learning_agent_planner_service.dart。
- _GoalHistoryActionCard 的 LearningAgentGoal 类型不再依赖间接 import。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- AgentSessionDetailScreen 中的 LearningAgentGoal 类型来源明确。
- 只修复类型依赖，不改变复盘详情展示、追问处理或历史导航行为。

### Leaf 11.112：复盘详情本目标记录入口显示数量

输出：

- AgentSessionMemoryIndex 新增 countForTarget。
- AgentSessionDetailScreen 从 AgentSessionMemoryIndex 读取同目标对象 Agent Session 数量。
- “查看本目标记录”按钮在数量可用时显示具体条数。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 当前复盘有 targetId 时，详情页能显示本目标对象历史记录数量。
- 数量与“查看本目标记录”打开的 target 过滤范围一致。
- 只读取本地 Agent Session memory，不改变追问处理、完成记录或学习计划算法。

### Leaf 11.113：目标对象历史筛选摘要更清楚

输出：

- AgentSessionHistoryScreen 的 target 过滤摘要改为同时展示当前视图记录数和当前目标未处理追问数。
- target 过滤摘要不再只显示未处理追问数。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户从复盘详情进入本目标历史后，能看到当前筛选视图中有多少条记录。
- target 过滤与“只看未处理追问”或搜索同时启用时，摘要仍描述当前视图记录数。
- 只修改展示文案，不改变历史筛选逻辑、追问处理或学习计划算法。

### Leaf 11.114：targetId 读取口径统一

输出：

- AgentSessionMemoryIndex 的 countForTarget 对传入 targetId 和 session.targetId 做 trim/空值规范化。
- latestOpenFollowUpQuestionForTarget 使用规范化 targetId 比较。
- AgentSessionFollowUpIndex 的 openFollowUpCountForTarget 和 target 计数 map 使用规范化 targetId。
- AgentSessionHistoryScreen 的 target 筛选比较使用规范化 targetId。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- targetId 前后空白不会导致同目标对象计数和历史筛选错开。
- 空 targetId 不会进入 target 计数 map。
- 只统一本地读取和筛选口径，不改变 Agent Session 写入路径。

### Leaf 11.115：历史页 target 筛选状态规范化

输出：

- AgentSessionHistoryScreen 初始化时规范化 initialTargetId。
- initialTargetId 为空时同步清空 targetLabel。
- AgentSessionHistoryScreen 新增 _hasTargetFilter getter。
- hasActiveFilters、空状态文案和追问数量读取统一使用规范化后的 target 筛选判断。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 空 initialTargetId 不会让历史页误以为 target 筛选已开启。
- target badge、空状态文案、清筛选入口和追问数量读取使用同一筛选状态。
- 只修正本地筛选状态，不改变 Agent Session 写入路径。

### Leaf 11.116：复盘详情历史操作结构修正

输出：

- 将 _GoalHistoryActionCard 中三个历史操作按钮的重复样式提取为局部 ButtonStyle。
- 保持按钮闭合层级清晰，避免后续维护误判嵌套结构。
- 保持同目标历史、本目标历史和未处理追问三个入口的展示逻辑不变。
- Trellis 记录本次语法结构修复，避免后续叶子建立在不可编译的详情页上。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- _GoalHistoryActionCard 的 Wrap children 结构闭合清晰。
- 同目标历史按钮仍调用 onOpenHistory。
- 不改变 Agent Session 历史筛选、追问计数或导航参数。

### Leaf 11.117：Agent Session targetId 规范化工具

输出：

- 新增 normalizeAgentSessionTargetId，集中处理 trim 和空字符串归 null。
- AgentSessionMemoryIndex、AgentSessionHistoryScreen、AgentSessionDetailScreen 复用同一 targetId 规范化入口。
- 移除 memory index 和 history screen 中重复的私有 _normalizedTargetId。

涉及文件：

```text
lib/services/agent/agent_session_target_id.dart
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_history_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- countForTarget、openFollowUpCountForTarget、latestOpenFollowUpQuestionForTarget 仍使用同一 targetId 口径。
- 历史页 initialTargetId、筛选状态和 session.targetId 比较复用共享规范化函数。
- 只抽取本地工具函数，不改变 Agent Session 写入、导航参数或追问匹配规则。

### Leaf 11.118：历史筛选栏显示当前 target 总数

输出：

- AgentSessionHistoryScreen 在 target 筛选启用时计算当前 target 的全部记录数。
- _GoalFilterBar 新增 targetTotalCount，用于 target 筛选标题的分母。
- target 筛选摘要明确显示“当前目标总数 / 当前视图数量 / 未处理追问数量”。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从复盘详情进入本目标历史时，标题不再用全局 Agent Session 总数作为分母。
- 同时启用 goal、追问或搜索筛选时，摘要仍能说明当前 target 总数和当前视图数量。
- 不改变历史筛选条件、追问状态判断或 Session 写入逻辑。

### Leaf 11.119：追问进入的学习记录保存追问文本

输出：

- TutorSessionScreen 保存导师学习记录时，如果本轮来自 Agent 追问，则在 summary 中写入“本轮追问”。
- InterviewSessionScreen 完成面试记录时，如果本轮来自 Agent 追问，则在 summary 中写入“本轮追问”。
- 为后续更精确地判断“具体哪条追问已处理”提供普通学习记录证据。

涉及文件：

```text
lib/features/agent/tutor_session_screen.dart
lib/features/agent/interview_session_screen.dart
docs/trellis-execution-map.md
```

验收：

- 普通导师讲解记录仍保留原有标题。
- 普通面试完成记录仍保留完成轮数字段。
- 只有传入并实际使用 initialFollowUpQuestion 时，学习记录 summary 才追加追问文本。
- 不改变 AI 生成任务、数据库结构或 Agent Session 追问匹配规则。

### Leaf 11.120：追问完成检测匹配具体问题

输出：

- AgentSessionCompletionMatcher 支持可选 followUpQuestion 参数。
- 当传入 followUpQuestion 时，完成检测要求学习记录 summary 中存在同一条“本轮追问”。
- AgentSessionLaunchScreen 和 AgentSessionDetailScreen 的追问完成检测传入当前追问文本。

涉及文件：

```text
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 新增导师/面试记录只有命中同一知识点且包含同一追问文本时，才会被视为处理了历史追问。
- 未传入 followUpQuestion 的普通完成点匹配仍保持原有行为。
- 不改变 Agent Session 未处理追问索引的抵消规则。

### Leaf 11.121：最近面试复盘展示追问来源

输出：

- Agent 首页最近面试复盘卡片从 session.summary 读取“本轮追问”。
- 如果面试来自 Agent 历史追问，卡片直接显示追问文本。
- 加载失败时不展示追问行，避免把不完整状态误当复盘内容。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 普通面试卡片仍显示状态、轮数和平均分。
- 来自 Agent 追问的面试卡片额外显示“本轮追问”。
- 不改变面试详情、Agent Session 记忆索引或完成检测规则。

### Leaf 11.122：普通学习记录追问解析统一

输出：

- 新增 followUpQuestionFromLearningSessionSummary，集中解析普通学习记录 summary 中的“本轮追问”。
- AgentSessionCompletionMatcher 使用共享解析函数匹配具体追问文本。
- Agent 首页最近面试复盘卡片使用同一解析函数展示追问。

涉及文件：

```text
lib/services/agent/agent_learning_session_summary.dart
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 追问完成检测和最近面试卡片展示使用同一解析口径。
- 空 summary 或没有“本轮追问”的记录仍返回空。
- 不改变普通导师/面试记录写入格式。

### Leaf 11.123：Agent 首页展示最近导师讲解

输出：

- 新增 tutorSessionListProvider，筛选普通导师学习记录。
- Agent 首页在存在导师记录时展示“最近导师讲解”区块。
- 导师记录卡片展示讲解标题、完成时间和可选“本轮追问”。
- TutorSessionScreen 和 Agent Session 相关刷新路径会刷新 tutorSessionListProvider。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/tutor_session_screen.dart
lib/features/agent/agent_session_detail_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 没有导师记录时首页不新增空区块。
- 最近导师记录能在首页看到，追问进入的导师记录能显示“本轮追问”。
- 不改变导师模式生成、Agent Session 记忆索引或普通学习记录写入格式。

### Leaf 11.124：最近导师讲解可回到知识点详情

输出：

- Agent 首页最近导师讲解卡片读取 session.targetId 对应的知识点。
- 能找到知识点时，导师记录卡片可点击进入 KnowledgePointDetailScreen。
- 找不到知识点或 targetId 为空时，卡片保持静态展示。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 最近导师讲解能回到知识点来源、题目和详情上下文。
- 无法定位知识点时不抛错、不显示误导性入口。
- 不改变导师学习记录写入或 Agent Session 追问完成检测。

### Leaf 11.125：直接模式返回后刷新首页输入

输出：

- Agent 首页直接进入面试、导师、复习模式后，返回时统一检查 context.mounted。
- 面试和导师模式返回后刷新 learningSessionListProvider 及对应最近记录 provider。
- 复习模式返回后刷新 learningSessionListProvider。
- _refreshPlanInputs 额外刷新 todayReviewQueueProvider，让复习队列和 Agent 计划输入同步更新。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从首页直接完成面试后，最近面试复盘和学习路线输入会刷新。
- 从首页直接完成导师讲解后，最近导师讲解和学习路线输入会刷新。
- 从首页直接完成复习后，复习队列、练习可用性和学习路线输入会刷新。

### Leaf 11.126：Agent Session 历史返回后刷新首页

输出：

- AgentHomeScreen 新增 _openAgentSessionHistory，统一打开 Agent Session 历史页并在返回后刷新。
- AgentHomeScreen 新增 _refreshAgentSessionInputs，集中刷新学习记录、导师/面试最近记录、Agent Session 记忆和学习路线输入。
- Plan 卡片的同目标历史/追问入口、学习记忆条的历史/追问入口、最近 Agent Session 的“查看全部”入口复用同一刷新路径。
- handleFollowUps 计划步骤和完成 Agent Session 后也复用同一 Agent Session 输入刷新函数。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从首页进入 Agent Session 历史页并处理追问后，返回首页会刷新记忆条和学习路线。
- 首页各个 Agent Session 历史入口使用同一刷新口径。
- 不改变 Agent Session 历史筛选、追问处理或普通学习记录写入逻辑。

### Leaf 11.127：Agent Session 详情返回后刷新首页

输出：

- AgentHomeScreen 新增 _openAgentSessionDetail，统一打开 Agent Session 复盘详情并在返回后刷新。
- 最近 Agent Session 列表卡片复用 _openAgentSessionDetail。
- 学习记忆条中的最近同目标复盘入口复用 _openAgentSessionDetail。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从首页打开 Agent Session 复盘详情并处理追问后，返回首页会刷新记忆条和学习路线。
- 首页打开 Agent Session 详情的入口使用同一刷新口径。
- 不改变复盘详情页的追问处理、记录写入或历史筛选逻辑。

### Leaf 11.128：Agent Session 启动页刷新普通学习记录

输出：

- AgentSessionLaunchScreen 保存 Agent Session 复盘后同步刷新 interviewSessionListProvider。
- AgentSessionLaunchScreen 的 _invalidateAgentInputs 同步刷新 learningSessionListProvider。
- AgentSessionLaunchScreen 的 _invalidateAgentInputs 同步刷新 tutorSessionListProvider。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- Agent Session 中完成面试追问并保存复盘后，最近面试复盘不会依赖外层页面额外刷新。
- Agent Session 中完成导师讲解后，普通学习记录和最近导师记录 provider 会被刷新。
- 只补齐 provider 刷新，不改变 Agent Session 保存、追问完成判定或学习路线算法。

### Leaf 11.129：Agent Session 启动页刷新记忆索引

输出：

- AgentSessionLaunchScreen 的 _invalidateAgentInputs 同步刷新 agentSessionListProvider。
- AgentSessionLaunchScreen 的 _invalidateAgentInputs 同步刷新 agentSessionMemoryIndexProvider。
- 从启动页进入历史追问处理、普通学习动作或复习动作后，启动页本地 Agent 记忆读取口径更一致。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从 Agent Session 启动页打开历史追问并处理后，返回启动页会刷新 Agent Session 记忆索引。
- _invalidateAgentInputs 覆盖普通学习记录、Agent Session 记录和学习路线输入。
- 不改变 Agent Session 写入、历史筛选或追问完成判定。

### Leaf 11.130：启动页学习记录刷新口径收敛

输出：

- AgentSessionLaunchScreen 新增 _invalidateLearningRecordIndexes。
- _finishAndReturn 复用 _invalidateLearningRecordIndexes 刷新普通学习记录、导师/面试最近记录和 Agent Session 记忆。
- _invalidateAgentInputs 复用 _invalidateLearningRecordIndexes，再刷新学习路线相关输入。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 保存 Agent Session 复盘后的刷新行为不变。
- 启动页内部动作返回后的刷新行为不变。
- 学习记录和 Agent Session 记忆刷新 provider 不再在启动页重复手写两遍。

### Leaf 11.131：Agent 学习记录刷新 helper

输出：

- providers.dart 新增 invalidateAgentLearningRecordProviders。
- AgentHomeScreen 的 _refreshAgentSessionInputs 复用共享刷新 helper。
- AgentSessionLaunchScreen 的 _invalidateLearningRecordIndexes 复用共享刷新 helper。
- AgentSessionDetailScreen 的 _refreshLearningRecords 复用共享刷新 helper。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 普通学习记录、面试/导师最近记录、Agent Session 列表和 Agent Session 记忆索引使用同一刷新口径。
- 首页、启动页和复盘详情页的刷新行为保持不变。
- 只收敛 provider 刷新调用，不改变业务流程、数据写入或历史筛选逻辑。

### Leaf 11.132：普通学习会话复用记录刷新 helper

输出：

- TutorSessionScreen 保存导师讲解记录后复用 invalidateAgentLearningRecordProviders。
- InterviewSessionScreen 完成面试记录后复用 invalidateAgentLearningRecordProviders。
- 普通学习动作完成后同时刷新普通记录、最近导师/面试记录和 Agent Session 记忆索引。

涉及文件：

```text
lib/features/agent/tutor_session_screen.dart
lib/features/agent/interview_session_screen.dart
docs/trellis-execution-map.md
```

验收：

- 导师讲解保存后，依赖学习记录的 Agent 首页和 Agent Session 记忆索引可被统一刷新。
- 面试会话完成后，依赖学习记录的 Agent 首页和 Agent Session 记忆索引可被统一刷新。
- 不改变普通导师/面试会话的数据写入、总结文本或完成状态。

### Leaf 11.133：首页直接模式复用 Agent 刷新入口

输出：

- AgentHomeScreen 的面试官模式返回后复用 _refreshAgentSessionInputs。
- AgentHomeScreen 的导师模式返回后复用 _refreshAgentSessionInputs。
- AgentHomeScreen 的复习模式返回后复用 _refreshAgentSessionInputs。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从首页直接进入面试、导师或复习模式返回后，学习路线输入继续刷新。
- 从首页直接进入面试或导师模式返回后，最近学习记录和 Agent Session 记忆索引使用统一刷新口径。
- 不改变三个直接模式入口、可用性判断或路由目标。

### Leaf 11.134：学习路线输入刷新 helper

输出：

- providers.dart 新增 invalidateLearningAgentPlanInputProviders。
- AgentHomeScreen 的 _refreshPlanInputs 复用共享路线输入刷新 helper。
- AgentSessionLaunchScreen 的 _invalidateAgentInputs 复用共享路线输入刷新 helper。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 学习路线依赖的知识点、题目、待审核问题、今日复习队列和当前目标计划刷新口径集中在 providers.dart。
- 首页和 Agent Session 启动页的刷新行为保持一致。
- 不改变学习计划生成逻辑、目标选择状态或路由流程。

### Leaf 11.135：复习 Agent 输入刷新收敛

输出：

- ReviewAgentScreen 新增 _refreshReviewAgentInputs。
- 下拉刷新、今日复习、单个复习队列和薄弱点练习完成后复用同一刷新函数。
- 今日复习队列、知识点列表和可练习知识点列表刷新口径保持一致。

涉及文件：

```text
lib/features/agent/review_agent_screen.dart
docs/trellis-execution-map.md
```

验收：

- 复习模式内所有复习动作完成后仍刷新今日复习队列。
- 复习模式内所有复习动作完成后仍刷新知识点与可练习知识点状态。
- 不改变复习题目选择、QuizScreen 路由或空状态提示。

### Leaf 11.136：最近面试复盘返回刷新首页

输出：

- AgentHomeScreen 新增 _openInterviewSessionDetail。
- 最近面试复盘卡片的打开动作从卡片内部上提到首页。
- 从面试复盘详情返回后复用 _refreshAgentSessionInputs。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 最近面试复盘仍能打开 InterviewSessionDetailScreen。
- 从面试复盘详情返回首页后，最近学习记录、Agent Session 记忆和学习路线输入会统一刷新。
- 不改变面试复盘详情页展示、turn 读取或最近面试卡片布局。

### Leaf 11.137：知识点详情返回刷新首页

输出：

- AgentHomeScreen 新增 _openKnowledgePointDetail。
- 推荐焦点详情入口复用 _openKnowledgePointDetail。
- 最近导师讲解卡片的知识点详情打开动作从卡片内部上提到首页。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 推荐焦点仍能打开知识点详情。
- 最近导师讲解仍能回到对应知识点详情。
- 从知识点详情返回首页后，最近学习记录、Agent Session 记忆和学习路线输入会统一刷新。

## Branch 12：Knowledge Base Learning Agent

目的：在已经来源化、可核验、可复习的知识库之上，建立“问我的知识库 / 学我的知识库”的本地优先 Agent 能力。

原则：

- 第一版只使用 SQLite、本地来源片段、知识点和题目，不提前引入向量数据库。
- 检索结果必须能回到来源、来源片段、知识点或题目。
- AI 后续可以负责回答组织和追问，但候选依据必须先由本地检索给出。
- 用户笔记可以参与检索，但正式学习优先展示高可信来源和已核验题目。

### Leaf 12.1：本地知识检索 corpus

输出：

- 新增 KnowledgeSearchService，支持按 query 检索来源、来源片段、知识点和题目。
- 新增 KnowledgeSearchCorpus 和 KnowledgeSearchResult 结构。
- providers.dart 新增 knowledgeSearchServiceProvider、knowledgeSearchCorpusProvider 和 knowledgeSearchResultsProvider。

涉及文件：

```text
lib/services/agent/knowledge_search_service.dart
lib/core/providers/providers.dart
docs/trellis-execution-map.md
```

验收：

- 空 query 返回空结果，不触发 AI 调用。
- 检索结果保留类型、标题、片段摘要、分数和可回跳 id。
- corpus 从本地 sources、source_chunks、knowledge_points 和 questions 构建，不新增数据库结构。

### Leaf 12.2：知识库本地检索 Tab

输出：

- KnowledgeBaseScreen 新增“检索”Tab。
- 检索 Tab 使用 knowledgeSearchResultsProvider 展示本地来源、来源片段、知识点和题目结果。
- 检索结果可打开 SourceDetailScreen、KnowledgePointDetailScreen 或 QuestionEvidenceScreen。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 空关键词时不查询结果。
- 输入关键词后展示本地检索结果和命中片段摘要。
- 点击结果可以回到对应来源、知识点或题目证据页。

### Leaf 12.3：知识库入口 Tab 索引修正

输出：

- AgentHomeScreen 中知识点缺失回退入口改为 KnowledgeBaseScreen(initialTabIndex: 2)。
- AgentSessionLaunchScreen 的待核验入口改为 KnowledgeBaseScreen(initialTabIndex: 4)。
- AgentSessionLaunchScreen 中知识点缺失回退入口改为 KnowledgeBaseScreen(initialTabIndex: 2)。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 新增“检索”Tab 后，待核验路线仍打开待核验 Tab。
- 知识点缺失回退仍打开知识点 Tab。
- 不改变知识库默认入口；默认仍打开检索 Tab。

### Leaf 12.4：检索来源片段高亮回跳

输出：

- SourceDetailScreen 支持 highlightedChunkId。
- 检索结果中的来源片段打开 SourceDetailScreen 时传入 sourceChunkId。
- _ChunkList 将命中片段临时置顶，并由 _ChunkCard 标记为“检索命中片段”。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 点击“来源片段”类型的检索结果后，来源详情页能明确标出命中的片段。
- 命中片段在详情页片段列表顶部显示，方便回溯依据。
- 不改变 source_chunks 数据顺序或数据库结构。

### Leaf 12.5：检索排序优先可信依据

输出：

- KnowledgeSearchService 对官方文档、源码、书籍/课程等高可信来源增加排序权重。
- 已核验题目在检索结果中优先于待核验和无来源题目。
- 权重只影响已命中 query 的结果排序，不让未命中内容进入结果。

涉及文件：

```text
lib/services/agent/knowledge_search_service.dart
docs/trellis-execution-map.md
```

验收：

- 同样命中关键词时，高可信来源和来源片段排序更靠前。
- 同样命中关键词时，verified 题目排序优先于 pending/no_source 题目。
- 不改变检索 corpus、不新增数据库结构、不调用 AI。

### Leaf 12.6：来源约束知识库回答任务

输出：

- 新增 KnowledgeAnswerTask，基于 source chunks 回答知识库问题。
- KnowledgeAnswerResult 返回 answer、key_points、follow_up_questions、source_gaps 和 citation_ids。
- providers.dart 新增 knowledgeAnswerTaskProvider。

涉及文件：

```text
lib/services/ai/tasks/knowledge_answer_task.dart
lib/core/providers/providers.dart
docs/trellis-execution-map.md
```

验收：

- 没有问题文本或没有来源片段时返回 validation failure。
- 有回答时必须带有效 citation_ids，且 citation_ids 必须来自输入 source chunks。
- 来源不足时允许返回 source_gaps，不编造无引用回答。

### Leaf 12.7：检索结果生成回答上下文片段

输出：

- KnowledgeSearchResult 携带题目 citationIds。
- providers.dart 新增 knowledgeAnswerContextChunksProvider。
- 回答上下文从检索命中的 sourceChunkId、题目 citationIds 和来源命中的片段中整理最多 8 条 SourceChunk。

涉及文件：

```text
lib/services/agent/knowledge_search_service.dart
lib/core/providers/providers.dart
docs/trellis-execution-map.md
```

验收：

- 空 query 返回空上下文。
- 题目检索结果能把题目引用片段纳入回答上下文。
- 来源和来源片段检索结果能提供实际 SourceChunk，供 KnowledgeAnswerTask 使用。

### Leaf 12.8：知识库检索支持来源约束回答

输出：

- Knowledge Base 检索 Tab 在有回答上下文时展示“基于来源回答”动作。
- 点击后调用 KnowledgeAnswerTask，并展示 answer、key points、source gaps、follow-up questions 和引用依据。
- 搜索词变化时清空旧回答，异步旧请求不会覆盖新 query 的结果。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 没有可引用片段时，回答按钮不可用。
- 生成回答时只传入 knowledgeAnswerContextChunksProvider 输出的 SourceChunk。
- 回答展示包含引用依据；来源不足时展示 source gaps。

### Leaf 12.9：引用片段打开来源时定位片段

输出：

- _ChunkCard 打开 SourceDetailScreen 时传入当前 chunk.id。
- 来源详情页复用 highlightedChunkId 将引用片段置顶并高亮。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从回答引用、题目证据或知识点证据里的片段打开来源时，来源详情能定位到对应片段。
- 不改变 SourceDetailScreen 默认入口；未传 highlightedChunkId 时仍按原顺序展示。
- 不改变来源片段持久化顺序。

### Leaf 12.10：来源回答追问可继续检索

输出：

- Knowledge Base 检索 Tab 支持点击回答里的 follow-up questions。
- 点击追问后自动填入搜索框并重新触发本地检索。
- _CompactList 支持可选 item 点击回调，并为可点击追问展示搜索图标。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 回答里的“继续追问”不再只是静态文本。
- 点击追问会清空旧回答，并用追问文本作为新的 query。
- 不改变 key points、source gaps 的普通展示逻辑。

### Leaf 12.11：来源回答保存为学习记录

输出：

- LearningSessionMode 新增 knowledgeAnswer。
- Knowledge Base 来源约束回答生成成功后写入 learning_sessions。
- 回答面板展示“已保存到学习记录”或保存失败提示。

涉及文件：

```text
lib/data/models/learning_session.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 每次成功生成来源约束回答后，会保存一条 knowledge_answer 学习记录。
- 学习记录 summary 包含问题、回答、要点、来源缺口、继续追问和引用 id。
- 旧的 quiz/interview/tutor/agent_session 模式不受影响。

### Leaf 12.12：检索页展示最近知识库问答

输出：

- providers.dart 新增 knowledgeAnswerSessionListProvider。
- Knowledge Base 检索空状态展示最近知识库问答。
- 点击历史问答会把原问题填入检索框，继续本地检索。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 没有历史问答时，检索页仍显示原来的输入提示。
- 有历史问答时，检索页展示最近 5 条 knowledge_answer 记录。
- 新生成来源约束回答并保存后，最近知识库问答 provider 会刷新。

### Leaf 12.13：知识库问答 summary 解析统一

输出：

- 新增 knowledge_answer_session_summary.dart。
- 集中解析 knowledge_answer 学习记录中的问题和回答行。
- Knowledge Base 最近问答列表复用共享解析函数。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 最近知识库问答列表不再在多个 widget 内重复解析 summary。
- 空 summary 或缺少对应行时返回 null。
- 不改变 knowledge_answer summary 写入格式。

### Leaf 12.14：首页展示最近知识库问答

输出：

- KnowledgeBaseScreen 支持 initialSearchQuery。
- AgentHomeScreen 读取 knowledgeAnswerSessionListProvider。
- Agent 首页展示最近 3 条知识库问答，点击可打开知识库检索并预填原问题。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从 Agent 首页可以看到最近知识库问答。
- 点击问答卡片会进入 Knowledge Base 检索 Tab，并自动使用原问题检索。
- 不改变 KnowledgeBaseScreen 默认入口；没有 initialSearchQuery 时仍按 initialTabIndex 打开。

### Leaf 12.15：知识库问答恢复检索与刷新修正

输出：

- _KnowledgeSearchTab 初始化时读取 initialQuery，并写入搜索框与本地 query 状态。
- invalidateAgentLearningRecordProviders 同步刷新 knowledgeAnswerSessionListProvider。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/core/providers/providers.dart
docs/trellis-execution-map.md
```

验收：

- 从 Agent 首页点击最近知识库问答后，Knowledge Base 会直接显示该问题的检索结果。
- 从 Knowledge Base 生成新的知识库问答并返回 Agent 首页后，首页问答列表会刷新。
- 不改变其他学习记录 provider 的刷新口径。

### Leaf 12.16：知识库问答 summary 写入统一

输出：

- knowledge_answer_session_summary.dart 新增 buildKnowledgeAnswerSessionSummary。
- Knowledge Base 保存 knowledge_answer 学习记录时复用共享 summary builder。
- UI 不再手写 knowledge_answer summary 格式。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- knowledge_answer summary 的写入和解析口径集中在同一个 service 文件。
- summary 仍包含问题、回答、要点、来源缺口、继续追问和引用。
- 不改变已有 knowledge_answer summary 的解析规则。

### Leaf 12.17：题目核验后刷新知识检索

输出：

- QuestionEvidenceScreen 修改题目来源状态后刷新 knowledgeSearchCorpusProvider。
- 检索排序中的 verified/pending/no_source 权重能跟随核验状态更新。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 题目从 pending 改为 verified 后，知识库检索 corpus 会刷新。
- 题目改为 no_source 后，检索结果不继续沿用旧引用/旧状态。
- 不改变题目核验写入、引用清洗或复习队列刷新逻辑。

### Leaf 12.18：知识库问答记录展示追溯信息

输出：

- KnowledgeAnswerSessionSummaryRecord 统一解析问题、回答、要点、来源缺口、继续追问和引用 id。
- 知识库检索空状态的最近问答行展示引用数、来源缺口数和追问数。
- Agent 首页最近知识库问答卡片展示同一套追溯计数，并保留回答摘要。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 最近知识库问答的 summary 解析不再只暴露问题和回答。
- 有引用、来源缺口或继续追问时，最近记录能显示对应数量。
- 不改变 knowledge_answer summary 的写入格式或学习记录存储结构。

### Leaf 12.19：知识库问答复盘详情入口

输出：

- 新增 KnowledgeAnswerSessionDetailScreen，展示问题、回答、要点、来源缺口、继续追问和引用片段。
- Knowledge Base 检索空状态的最近问答行打开问答复盘详情。
- Agent 首页最近知识库问答卡片打开问答复盘详情，并可从详情页重新进入检索。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 最近知识库问答不再只能恢复检索，也能先复盘当时的来源约束回答。
- 详情页只读取本地 LearningSession.summary 和 source_chunks，不新增存储字段。
- 从详情页点击“重新检索”能继续使用原问题进入检索流。

### Leaf 12.20：知识库问答复盘追问可继续检索

输出：

- KnowledgeAnswerSessionDetailScreen 的继续追问列表改为可点击条目。
- 点击某条继续追问会将该问题返回上层检索入口。
- Knowledge Base 内打开详情时，追问会填入检索框；Agent 首页打开详情时，追问会进入 Knowledge Base 检索。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 复盘详情中的继续追问不再只是静态文本。
- 点击追问后复用既有检索恢复路径，不新增额外存储或 AI 调用。
- 重新检索原问题和继续检索追问两个返回路径互不冲突。

### Leaf 12.21：知识库问答引用展示来源标题

输出：

- KnowledgeAnswerSessionDetailScreen 读取引用片段时同步读取对应 Source。
- 引用依据列表展示来源标题和来源信任级别。
- 引用依据仍保留 locator/片段号和正文摘录。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户查看知识库问答复盘时，可以知道每条引用来自哪个来源。
- 找不到来源记录时，引用列表仍能展示片段内容并标记为未知来源。
- 不改变 citation_ids 写入格式，也不新增数据库字段。

### Leaf 12.22：完整知识库问答历史

输出：

- 新增 KnowledgeAnswerHistoryScreen，展示全部 knowledge_answer 学习记录。
- 历史页支持按问题、回答、要点、来源缺口、继续追问和引用 id 本地搜索。
- Knowledge Base 检索空状态和 Agent 首页最近知识库问答区新增“查看全部”入口。
- 历史页打开问答复盘详情后，可以继续返回原问题或追问进入检索流。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户不只依赖最近 3/5 条预览，也能查看完整知识库问答历史。
- 历史搜索只使用本地 LearningSession.summary，不新增外部依赖或 AI 调用。
- 从历史详情返回的原问题或继续追问能复用既有 Knowledge Base 检索入口。

### Leaf 12.23：知识库问答历史筛选来源缺口

输出：

- KnowledgeAnswerHistoryScreen 新增“有来源缺口”筛选。
- 筛选条件复用 KnowledgeAnswerSessionSummaryRecord.sourceGaps。
- 筛选和文本搜索可以叠加使用。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以快速找到需要补充来源依据的知识库问答记录。
- 筛选只读取本地 LearningSession.summary，不触发 AI 或改写记录。
- 关闭筛选后完整历史列表恢复。

### Leaf 12.24：知识库问答历史筛选缺少引用

输出：

- KnowledgeAnswerHistoryScreen 新增“缺少引用”筛选。
- 筛选条件复用 KnowledgeAnswerSessionSummaryRecord.citationIds。
- 历史筛选区改为 Wrap，避免多个筛选项在窄屏溢出。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以快速找到没有 citation ids 的知识库问答记录。
- “缺少引用”“有来源缺口”和文本搜索可以叠加使用。
- 筛选只读取本地 summary，不触发 AI 或改写记录。

### Leaf 12.25：知识库问答历史展示证据质量统计

输出：

- KnowledgeAnswerHistoryScreen 统计全部问答数量、缺少引用数量和来源缺口数量。
- 历史页搜索框下方展示证据质量统计 pill。
- 统计信息和当前筛选显示数量一起展示。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户进入知识库问答历史时，可以直接看到证据质量概况。
- 统计只读取本地 LearningSession.summary，不触发 AI 或写库。
- 筛选变化后，“显示 N”会跟随当前筛选结果更新。

### Leaf 12.26：知识库问答历史一键清空筛选

输出：

- KnowledgeAnswerHistoryScreen 新增一键清空筛选动作。
- 筛选面板在存在搜索词或质量筛选时显示“清除筛选”。
- 筛选结果为空时，空状态也提供“清除筛选”动作。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户叠加搜索、缺少引用、来源缺口筛选后，可以一键恢复完整历史。
- 清空搜索框仍只清搜索词，不会误清质量筛选。
- 筛选为空状态不会把用户困在空列表里。

### Leaf 12.27：知识库问答历史统计可快捷筛选

输出：

- 证据质量统计中的“缺少引用”可直接切换缺少引用筛选。
- 证据质量统计中的“来源缺口”可直接切换来源缺口筛选。
- 存在激活筛选时，点击总数统计可清空筛选。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从证据质量概况直接进入对应质量问题列表。
- 统计快捷筛选和下方 FilterChip 使用同一份本地筛选状态。
- 不触发 AI、不改写学习记录，也不改变 summary 格式。

### Leaf 12.28：知识库问答引用直达来源详情

输出：

- KnowledgeAnswerSessionDetailScreen 支持注入引用片段打开回调。
- 知识库问答复盘里的引用片段可打开 SourceDetailScreen。
- 打开来源详情时高亮对应 source chunk。
- Knowledge Base 最近问答、完整问答历史和 Agent 首页问答入口都传入同一打开逻辑。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 有 source 记录的引用片段显示打开图标，并能进入来源详情。
- 来源详情能高亮当前引用 chunk。
- 找不到 source 的引用仍展示片段内容，不阻塞问答复盘。

### Leaf 12.29：知识库问答来源缺口可继续检索

输出：

- KnowledgeAnswerSessionDetailScreen 的来源缺口列表改为可点击条目。
- 点击某条来源缺口会将缺口文本返回上层检索入口。
- 来源缺口条目使用搜索图标，和继续追问区分颜色。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 复盘详情中的来源缺口不再只是静态文本。
- 点击来源缺口后复用既有 Knowledge Base 检索路径。
- 不触发 AI、不改写学习记录，也不改变 summary 格式。

### Leaf 12.30：知识库问答引用高亮标签语义化

输出：

- SourceDetailScreen 支持自定义高亮片段标签文案。
- 默认检索跳转仍显示“检索命中片段”。
- 知识库问答引用跳转显示“当前引用片段”。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从普通检索打开来源详情时，高亮标签语义不变。
- 从知识库问答引用打开来源详情时，高亮标签说明这是当前引用。
- 不改变 highlightedChunkId 的置顶和高亮逻辑。

### Leaf 12.31：来源详情高亮图标语义化

输出：

- SourceDetailScreen 支持自定义高亮片段图标。
- 普通检索高亮继续使用搜索图标。
- 知识库问答引用高亮使用链接图标。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 检索命中和问答引用两种高亮来源有不同图标语义。
- 默认调用不需要传参，仍保持原检索图标。
- 不改变来源详情的数据读取、chunk 排序或跳转路径。

### Leaf 12.32：知识库问答质量统计口径统一

输出：

- knowledge_answer_session_summary.dart 新增 KnowledgeAnswerSessionStats。
- KnowledgeAnswerHistoryScreen 改用共享 stats 计算总数、缺少引用数量和来源缺口数量。
- 质量统计口径从页面私有实现移到 service 层。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 缺少引用和来源缺口统计不再只存在于历史页私有类。
- 历史页证据质量统计展示行为保持不变。
- 不改变 knowledge_answer summary 写入格式。

### Leaf 12.33：Agent 首页提示知识库问答证据待补

输出：

- Agent 首页最近知识库问答区读取 KnowledgeAnswerSessionStats。
- 存在缺少引用或来源缺口时展示“证据待补”提示。
- 点击提示进入完整知识库问答历史继续处理。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户不进入历史页也能看到知识库问答的证据质量债。
- 没有质量问题时不额外打扰首页。
- 提示入口复用既有完整历史页，不新增 AI 调用或存储字段。

### Leaf 12.34：知识库问答历史支持初始质量筛选

输出：

- KnowledgeAnswerHistoryScreen 支持 initialOnlyWithoutCitations。
- KnowledgeAnswerHistoryScreen 支持 initialOnlyWithSourceGaps。
- 默认打开历史页时仍不启用质量筛选。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 外部入口可以直接打开“缺少引用”筛选后的知识库问答历史。
- 外部入口可以直接打开“来源缺口”筛选后的知识库问答历史。
- 既有“查看全部”入口仍展示完整历史。

### Leaf 12.35：Agent 首页质量提示直达筛选历史

输出：

- Agent 首页“证据待补”提示改为分别展示“缺少引用”和“有来源缺口”动作。
- 点击“缺少引用”打开已启用缺少引用筛选的完整问答历史。
- 点击“有来源缺口”打开已启用来源缺口筛选的完整问答历史。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从首页直接进入对应证据质量问题列表。
- 两个动作复用 KnowledgeAnswerHistoryScreen 的本地筛选状态。
- 不新增 AI 调用、不改写学习记录，也不改变 summary 格式。

### Leaf 12.36：Knowledge Base 提示知识库问答证据待补

输出：

- Knowledge Base 检索空状态的最近知识库问答区读取 KnowledgeAnswerSessionStats。
- 存在缺少引用或来源缺口时展示“证据待补”提示。
- 点击“缺少引用”或“有来源缺口”可打开对应筛选后的完整问答历史。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Knowledge Base 内也能看到知识库问答的证据质量债。
- “查看全部”仍打开完整历史，不自动启用筛选。
- 质量提示动作复用 KnowledgeAnswerHistoryScreen 的本地筛选状态，不触发 AI 或写库。

### Leaf 12.37：Knowledge Base 质量提示复用组件

输出：

- 新增共享 KnowledgeAnswerQualityNotice，用于展示知识库问答证据待补状态。
- Agent 首页最近知识库问答区改用共享质量提示组件。
- Knowledge Base 检索空状态最近问答区改用共享质量提示组件。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
lib/features/agent/agent_home_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- “缺少引用”和“有来源缺口”两个动作在两个入口保持一致。
- 质量提示组件只接收统计和导航回调，不读取 provider、不触发 AI、不写数据库。
- 两个页面不再保留重复的私有质量提示实现。

### Leaf 12.38：Knowledge Answer History 支持初始搜索词

输出：

- KnowledgeAnswerHistoryScreen 新增 initialSearchQuery。
- 历史页初始化时会把初始搜索词写入搜索框和本地筛选查询。
- Agent 首页和 Knowledge Base 的历史打开方法预留 initialSearchQuery 透传。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/agent/agent_home_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 外部入口传入搜索词时，历史页首屏直接展示对应搜索结果。
- 清除筛选会同时清掉初始搜索词、质量筛选和输入框内容。
- 既有“查看全部”“缺少引用”“有来源缺口”入口保持默认行为。

### Leaf 12.39：知识库问答历史保留当前筛选说明

输出：

- KnowledgeAnswerHistoryScreen 根据搜索词、缺少引用和来源缺口生成当前筛选说明。
- 搜索面板在存在筛选时展示“当前筛选”摘要。
- 空结果状态同步展示当前筛选摘要，并保留一键清除入口。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户从外部质量入口进入历史页后，能看到当前启用的筛选条件。
- 搜索词、缺少引用、来源缺口可以组合显示。
- 空结果时用户可以直接理解为什么没有内容，并一键恢复完整历史。

### Leaf 12.40：即时回答来源缺口可继续检索

输出：

- Knowledge Base 来源约束回答面板中的“来源缺口”改为可点击条目。
- 点击来源缺口后会把缺口文本写入检索框，并复用本地知识库检索流程。
- _CompactList 支持为可点击条目配置动作颜色和图标，继续追问保持蓝色，来源缺口使用金色语义。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户刚生成回答时，不必进入复盘详情也能继续围绕来源缺口检索。
- 点击来源缺口会清空旧回答状态，并用缺口文本作为新的 query。
- 不触发 AI、不写库、不改变 knowledge_answer summary 格式。

### Leaf 12.41：知识库问答记录标明缺少引用

输出：

- KnowledgeAnswerSessionSummaryRecord 新增 hasMissingCitations。
- traceLabels 在没有 citation ids 时返回“缺少引用”，让最近记录、完整历史和详情页都能显示质量提示。
- KnowledgeAnswerSessionDetailScreen 为“缺少引用”使用 link_off 图标和红色语义。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 缺少引用的知识库问答不再只在统计里可见，单条记录也能看见问题。
- 有引用的记录仍显示“n 条引用”。
- 不改变 knowledge_answer summary 写入格式，不新增 AI 调用或数据库字段。

### Leaf 12.42：知识库问答历史卡片快捷补证

输出：

- KnowledgeAnswerHistoryScreen 的历史卡片支持证据修复快捷动作。
- 有来源缺口的记录显示“检索缺口”，点击后将第一条来源缺口返回 Knowledge Base 检索。
- 没有来源缺口但缺少引用的记录显示“补齐引用”，点击后将原问题返回 Knowledge Base 检索。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在完整历史列表里可以直接处理证据质量问题，不必先进入详情。
- 卡片主体点击仍打开知识库问答复盘详情。
- 快捷动作只返回检索文本，不触发 AI、不写库、不改变 summary 格式。

### Leaf 12.43：知识库问答补证查询口径集中

输出：

- KnowledgeAnswerSessionSummaryRecord 新增 evidenceRepairQuery。
- evidenceRepairQuery 优先返回第一条来源缺口；没有来源缺口但缺少引用时返回原问题。
- KnowledgeAnswerHistoryScreen 的快捷补证动作改用共享 repair query。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 补证入口对“先补来源缺口，再补缺少引用”的判断集中在 summary service。
- 历史卡片的“检索缺口”“补齐引用”行为保持不变。
- 不改变 knowledge_answer summary 写入格式，不新增 AI 调用或数据库字段。

### Leaf 12.44：最近知识库问答复用快捷补证

输出：

- 新增 KnowledgeAnswerRepairActionButton，共享“检索缺口/补齐引用”按钮展示。
- 完整知识库问答历史卡片改用共享补证按钮。
- Knowledge Base 检索空状态的最近问答行展示补证按钮。
- Agent 首页最近知识库问答卡片展示补证按钮。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_repair_action_button.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在首页、Knowledge Base 最近问答和完整历史中都能直接处理证据质量问题。
- 补证按钮复用 KnowledgeAnswerSessionSummaryRecord.evidenceRepairQuery。
- 快捷动作只返回检索文本，不触发 AI、不写库、不改变 summary 格式。

### Leaf 12.45：知识库问答复盘详情快捷补证

输出：

- KnowledgeAnswerSessionDetailScreen 复用 KnowledgeAnswerRepairActionButton。
- 存在来源缺口或缺少引用时，详情页 trace 信息下方展示“检索缺口/补齐引用”动作。
- 点击动作后将 evidenceRepairQuery 返回上层 Knowledge Base 检索入口。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在复盘详情里也能直接处理证据质量问题。
- 原有“重新检索”、来源缺口条目点击、继续追问点击仍保留。
- 快捷动作只返回检索文本，不触发 AI、不写库、不改变 summary 格式。

### Leaf 12.46：知识库问答历史搜索包含追溯标签

输出：

- KnowledgeAnswerHistoryScreen 的本地搜索文本纳入 KnowledgeAnswerSessionSummaryRecord.traceLabels。
- 用户搜索“缺少引用”“来源缺口”“追问”等可见追溯标签时也能命中对应记录。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 历史页搜索覆盖页面实际展示的质量/追溯标签。
- 既有问题、回答、要点、来源缺口、继续追问和引用 id 搜索能力保留。
- 只读取本地 summary，不触发 AI、不写库、不改变 summary 格式。

### Leaf 12.47：知识库问答详情引用缺失提示补证

输出：

- KnowledgeAnswerSessionDetailScreen 的“引用依据”空状态文案说明可使用上方补证动作继续检索依据。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 缺少 citation ids 的问答详情不会只给出静态缺失提示。
- 文案与详情页上方的 KnowledgeAnswerRepairActionButton 保持一致。
- 不触发 AI、不写库、不改变 summary 格式。

### Leaf 12.48：知识库问答补证按钮说明语义化

输出：

- KnowledgeAnswerRepairActionButton 为“检索缺口”增加 tooltip：使用来源缺口继续检索依据。
- KnowledgeAnswerRepairActionButton 为“补齐引用”增加 tooltip：使用原问题补齐引用依据。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_repair_action_button.dart
docs/trellis-execution-map.md
```

验收：

- 补证按钮在多个入口复用时都有一致的悬停说明。
- “检索缺口”和“补齐引用”的动作差异更明确。
- 不改变 evidenceRepairQuery、导航回调、AI 调用或写库行为。

### Leaf 12.49：知识库问答补证类型口径集中

输出：

- knowledge_answer_session_summary.dart 新增 KnowledgeAnswerEvidenceRepairKind。
- KnowledgeAnswerSessionSummaryRecord 新增 evidenceRepairKind。
- evidenceRepairQuery 基于 evidenceRepairKind 选择补证查询文本。
- KnowledgeAnswerRepairActionButton 改用 evidenceRepairKind 选择按钮文案、图标、颜色和 tooltip。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_repair_action_button.dart
docs/trellis-execution-map.md
```

验收：

- “来源缺口优先，其次缺少引用”的补证类型判断集中在 summary service。
- 补证按钮不再直接根据 sourceGaps 重复判断动作类型。
- 不改变补证按钮展示位置、导航回调、AI 调用或写库行为。

### Leaf 12.50：知识库问答历史搜索包含补证动作

输出：

- knowledge_answer_session_summary.dart 新增 knowledgeAnswerEvidenceRepairKindLabel。
- KnowledgeAnswerRepairActionButton 改用共享补证动作标签。
- KnowledgeAnswerHistoryScreen 的本地搜索文本纳入补证动作标签。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_repair_action_button.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户搜索“检索缺口”或“补齐引用”时能命中对应可处理记录。
- 补证按钮文案与历史搜索标签使用同一口径。
- 不改变 evidenceRepairQuery、导航回调、AI 调用或写库行为。

### Leaf 12.51：知识库问答可补证数量统计

输出：

- KnowledgeAnswerSessionStats 新增 repairableCount。
- repairableCount 统计 evidenceRepairQuery 非空的知识库问答记录。
- KnowledgeAnswerHistoryScreen 的证据质量统计展示“可补证 N”。
- KnowledgeAnswerQualityNotice 文案展示当前可直接补证数量。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
docs/trellis-execution-map.md
```

验收：

- 统计层能区分质量问题数量和当前可直接补证数量。
- 历史页和质量提示使用同一个 repairableCount 口径。
- 不改变 evidenceRepairQuery、导航回调、AI 调用或写库行为。

### Leaf 12.52：知识库问答历史筛选可补证记录

输出：

- KnowledgeAnswerHistoryScreen 新增“可补证”本地筛选状态。
- 证据质量统计中的“可补证 N”可直接切换可补证筛选。
- 筛选区新增“可补证” FilterChip。
- 当前筛选摘要和清除筛选动作覆盖可补证筛选。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从完整历史直接聚焦 evidenceRepairQuery 非空的记录。
- “可补证”可以和文本搜索、缺少引用、来源缺口筛选叠加。
- 筛选只读取本地 summary，不触发 AI、不写库、不改变 summary 格式。

### Leaf 12.53：质量提示直达可补证历史

输出：

- KnowledgeAnswerHistoryScreen 支持 initialOnlyRepairable。
- Agent 首页和 Knowledge Base 的历史打开方法支持 initialOnlyRepairable 透传。
- KnowledgeAnswerQualityNotice 新增“可补证”动作。
- 点击“可补证”可打开已启用可补证筛选的完整知识库问答历史。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从首页或 Knowledge Base 的质量提示直接进入可补证记录列表。
- “缺少引用”“有来源缺口”“可补证”三个入口使用同一历史筛选状态系统。
- 不触发 AI、不写库、不改变 summary 格式。

### Leaf 12.54：知识库问答历史搜索提示对齐

输出：

- KnowledgeAnswerHistoryScreen 搜索框 hint 改为“搜索问题、回答、缺口、引用或标签”。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 搜索提示覆盖 traceLabels 和补证动作标签等可搜索内容。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.55：知识库问答历史当前筛选语义色

输出：

- KnowledgeAnswerHistoryScreen 的当前筛选摘要从纯文本 label 改为 _ActiveFilterInfo。
- 搜索筛选使用绿色，缺少引用使用红色，来源缺口和可补证使用金色。
- 空结果状态复用同一套当前筛选语义色。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 当前筛选摘要和上方筛选控件的颜色语义一致。
- 空结果时仍能看到当前筛选条件，并保留一键清除入口。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.56：知识库问答历史筛选空状态说明

输出：

- KnowledgeAnswerHistoryScreen 的空结果状态会根据当前筛选类型展示更具体的标题。
- “可补证”“来源缺口”“缺少引用”和组合质量筛选都有对应说明。
- 搜索为空时提示可尝试问题关键词、引用 id 或追溯标签。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 仅搜索无结果时仍展示搜索向空状态说明。
- 从质量提示进入“可补证/来源缺口/缺少引用”历史页时，空状态能说明当前质量筛选没有匹配记录。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.57：知识库问答历史标题显示筛选上下文

输出：

- KnowledgeAnswerHistoryScreen 的 AppBar title 改为内部标题组件。
- 当前存在搜索词或质量筛选时，标题下方展示当前筛选摘要。
- 筛选摘要复用 _ActiveFilterInfo label，并限制单行省略。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 从“可补证/来源缺口/缺少引用”入口进入历史页时，顶部标题区能看到当前筛选上下文。
- 清除筛选后标题恢复为单行“知识库问答历史”。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.58：知识库问答质量统计区分可补证债务

输出：

- KnowledgeAnswerSessionStats 增加记录级 qualityIssueCount 和 cleanCount。
- KnowledgeAnswerSessionStats 增加 nonRepairableQualityIssueCount、hasRepairableIssues、hasNonRepairableQualityIssues。
- KnowledgeAnswerQualityNotice 使用新口径区分“可直接补证”和“需要打开历史继续判断”的证据质量债。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
docs/trellis-execution-map.md
```

验收：

- hasQualityIssues 基于记录级 qualityIssueCount，而不是缺引用数和来源缺口数的组合推断。
- 质量提示在同时存在可补证和不可直接补证记录时，会分别说明两类数量。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.59：知识库问答质量统计显性展示

输出：

- KnowledgeAnswerHistoryScreen 统计区展示“证据合格”和“质量债”数量。
- KnowledgeAnswerQualityNotice 顶部展示待补证据和已合格记录概览。
- 新增展示复用 KnowledgeAnswerSessionStats 的 cleanCount 和 qualityIssueCount。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
docs/trellis-execution-map.md
```

验收：

- 历史页能直接看到记录级证据健康数量。
- Agent 首页和 Knowledge Base 的质量提示能显示待补证据与已合格记录数量。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.60：知识库问答历史筛选证据合格记录

输出：

- KnowledgeAnswerHistoryScreen 增加“证据合格”筛选状态。
- “证据合格”筛选只展示有引用且没有来源缺口的知识库问答。
- 统计区的“证据合格” pill 可直接切换该筛选，筛选区也提供对应 FilterChip。
- 空状态能说明“证据合格”和待补证据条件通常互斥。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 点击“证据合格”后，只保留有引用且无来源缺口的记录。
- 当前筛选摘要和 AppBar 副标题能展示“证据合格”。
- 与“缺少引用/来源缺口/可补证”组合导致空结果时，空状态能说明筛选互斥。
- 不改变 AI 调用、写库行为或已有质量筛选入口。

### Leaf 12.61：质量提示直达证据合格历史

输出：

- KnowledgeAnswerHistoryScreen 支持 initialOnlyCleanEvidence 初始筛选。
- KnowledgeAnswerQualityNotice 增加“证据合格”直达动作。
- Agent 首页和 Knowledge Base 的质量提示可直接打开证据合格筛选后的完整知识库问答历史。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 点击质量提示里的“证据合格”会进入已启用证据合格筛选的知识库问答历史。
- AppBar 副标题和当前筛选摘要显示“证据合格”。
- 不改变缺少引用、来源缺口、可补证三个既有入口。

### Leaf 12.62：知识库问答追溯标签标记证据合格

输出：

- KnowledgeAnswerSessionSummaryRecord.traceLabels 在记录有引用且没有来源缺口时加入“证据合格”。
- 历史搜索、最近问答和详情页复用 traceLabels 后可自然展示或命中该标签。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 证据合格记录的追溯标签包含“证据合格”。
- 搜索“证据合格”能通过 traceLabels 命中对应知识库问答。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.63：知识库问答证据合格标签语义化

输出：

- KnowledgeAnswerSessionDetailScreen 的追溯标签识别“证据合格”。
- “证据合格”使用绿色 verified 图标，不再走默认问答标签样式。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 证据合格记录详情页的追溯标签呈现为绿色正向状态。
- 缺少引用、引用数量、来源缺口等既有标签颜色不变。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.64：知识库问答证据质量 getter 集中

输出：

- KnowledgeAnswerSessionSummaryRecord 增加 hasSourceGaps、hasQualityIssue、hasCleanEvidence。
- evidenceRepairKind、traceLabels、KnowledgeAnswerSessionStats 改用集中 getter。
- KnowledgeAnswerHistoryScreen 的证据合格和来源缺口筛选改用集中 getter。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- “证据合格”口径集中为无缺少引用且无来源缺口。
- 统计、标签、历史筛选共用同一组记录级质量 getter。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.65：知识库问答历史卡片展示证据质量徽标

输出：

- KnowledgeAnswerHistoryScreen 历史卡片增加紧凑证据质量徽标。
- 证据合格记录显示绿色“证据合格”徽标。
- 待补证据记录显示“缺少引用”“来源缺口”“可补证”或“需核查”徽标。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户扫完整历史列表时，可以直接区分证据合格记录和待补证据记录。
- 可补证记录仍保留原有快捷补证按钮。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.66：最近知识库问答复用证据质量徽标

输出：

- 新增 KnowledgeAnswerEvidenceQualityBadges 共享组件。
- KnowledgeAnswerHistoryScreen 历史卡片改用共享证据质量徽标。
- Agent 首页最近知识库问答卡片展示证据质量徽标。
- Knowledge Base 最近知识库问答行展示证据质量徽标，并保留补证按钮。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_evidence_quality_badges.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在首页、Knowledge Base 空搜索态、完整历史页都能看到同一套证据质量徽标。
- 可补证记录在最近问答预览中仍保留快捷补证入口。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.67：知识库问答证据质量徽标说明

输出：

- KnowledgeAnswerEvidenceQualityBadges 中每个徽标增加 tooltip。
- “证据合格”“缺少引用”“来源缺口”“可补证”“需核查”都有对应解释。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_evidence_quality_badges.dart
docs/trellis-execution-map.md
```

验收：

- 用户悬停证据质量徽标时，可以理解该状态的含义。
- 现有徽标颜色、图标和展示位置不变。
- 不改变历史搜索逻辑、筛选状态、AI 调用或写库行为。

### Leaf 12.68：知识库问答详情展示证据质量判断

输出：

- KnowledgeAnswerSessionDetailScreen 增加“证据质量”区块。
- 详情页复用 KnowledgeAnswerEvidenceQualityBadges 展示证据状态。
- 详情页根据 clean evidence、可补证、需核查状态给出复盘建议文案。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户进入单条知识库问答复盘时，可以看到这条回答是否适合作为高质量复盘样本。
- 可补证记录会提示优先继续检索依据。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.69：即时知识库回答展示证据质量

输出：

- KnowledgeAnswerSessionSummaryRecord 增加 fromFields 工厂，支持未保存回答复用同一质量口径。
- Knowledge Base 的即时“来源约束回答”面板展示 KnowledgeAnswerEvidenceQualityBadges。
- 即时回答在保存为学习记录前也能看到证据合格、来源缺口、缺少引用等状态。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 刚生成来源约束回答时，不必等待进入历史记录也能看到证据质量徽标。
- 保存后的历史记录和即时回答使用同一套证据质量判断。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.70：知识库问答证据质量建议文案集中

输出：

- knowledgeAnswerEvidenceQualityGuidance 集中生成证据质量建议文案。
- KnowledgeAnswerSessionDetailScreen 复用集中建议文案。
- Knowledge Base 即时回答面板在证据质量徽标下展示同一建议文案。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 即时回答和历史详情对同一证据状态给出一致建议。
- 证据合格回答提示适合作为复盘样本，可补证回答提示优先继续检索依据。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.71：知识库问答历史搜索包含证据质量徽标

输出：

- knowledgeAnswerEvidenceQualityLabels 集中生成证据质量徽标标签。
- KnowledgeAnswerEvidenceQualityBadges 改为复用集中质量标签。
- KnowledgeAnswerHistoryScreen 搜索文本纳入证据质量徽标标签。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_evidence_quality_badges.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户搜索“证据合格”“可补证”“需核查”等徽标文本时能命中对应记录。
- UI 展示的质量徽标和历史搜索使用同一套标签来源。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.72：知识库问答历史筛选需核查质量债

输出：

- KnowledgeAnswerHistoryScreen 支持 initialOnlyNeedsReview 初始筛选。
- 知识库问答历史页新增“需核查”统计 pill 和 FilterChip。
- “需核查”筛选只展示有质量问题但没有直接补证动作的记录。
- KnowledgeAnswerQualityNotice 增加“需核查”直达动作，Agent 首页和 Knowledge Base 均接入。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从历史页或质量提示直接查看“需核查”的知识库问答。
- “需核查”和“可补证”组合为空时，空状态能说明二者通常互斥。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.73：知识库问答历史筛选质量债记录

输出：

- KnowledgeAnswerHistoryScreen 支持 initialOnlyQualityIssues 初始筛选。
- 历史页“质量债 N”统计 pill 可直接切换质量债筛选。
- 筛选区新增“质量债” FilterChip。
- “质量债”筛选只展示有证据质量问题的知识库问答。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 点击“质量债 N”后，只展示缺少引用、来源缺口、可补证或需核查的问答。
- “证据合格”和“质量债”组合为空时，空状态能说明二者通常互斥。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.74：质量提示直达质量债历史

输出：

- KnowledgeAnswerQualityNotice 增加“质量债”总览动作。
- Agent 首页质量提示可直接打开质量债筛选后的知识库问答历史。
- Knowledge Base 质量提示可直接打开质量债筛选后的知识库问答历史。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_quality_notice.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 点击质量提示里的“质量债”会进入已启用质量债筛选的知识库问答历史。
- 缺少引用、来源缺口、可补证、需核查、证据合格等既有入口仍保留。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.75：知识库问答历史搜索质量债标签

输出：

- KnowledgeAnswerHistoryScreen 搜索文本在记录存在证据质量问题时加入“质量债”语义标签。
- “质量债”仅参与搜索，不新增额外可见徽标。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户搜索“质量债”时能命中所有有证据质量问题的知识库问答。
- 现有证据质量徽标展示不变。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.76：知识库问答可补证与需核查 getter 集中

输出：

- KnowledgeAnswerSessionSummaryRecord 增加 hasRepairableQualityIssue。
- KnowledgeAnswerSessionSummaryRecord 增加 hasNonRepairableQualityIssue。
- 证据质量建议、质量徽标标签、统计、历史筛选和最近问答补证入口改用集中 getter。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- “可补证”口径集中为存在 evidenceRepairQuery 的质量问题记录。
- “需核查”口径集中为有质量问题但没有直接补证动作的记录。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.77：知识库问答历史统计说明

输出：

- KnowledgeAnswerHistoryScreen 的统计 pill 支持 tooltip。
- “证据合格”“质量债”“缺少引用”“来源缺口”“可补证”“需核查”“显示”等统计都有简短说明。
- “共 N 条”在存在筛选时提示可清除筛选查看全部记录。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户悬停历史页统计 pill 时，可以理解对应质量口径。
- 统计 pill 的点击筛选行为保持不变。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.78：知识库问答详情展示缺失引用 id

输出：

- KnowledgeAnswerSessionDetailScreen 在引用 id 已保存但本地找不到片段时展示具体缺失 id。
- 引用列表部分找到、部分缺失时，会在已找到片段前展示缺失 id 提示。
- 缺失引用提示使用 link_off 和红色语义。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户查看知识库问答详情时，可以知道哪些 citation id 无法解析到本地片段。
- 已找到的引用片段仍继续展示并可打开来源详情。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.79：知识库问答详情确认引用覆盖完整

输出：

- KnowledgeAnswerSessionDetailScreen 在所有引用 id 都解析到本地片段时显示正向确认。
- 引用覆盖完整提示使用 verified 和绿色语义。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 引用全部可解析时，用户能看到“已找到全部引用片段”的确认。
- 引用缺失时仍展示缺失引用 id，不误报完整覆盖。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.80：知识库问答详情提示引用来源缺失

输出：

- KnowledgeAnswerSessionDetailScreen 在引用片段存在但 Source 记录缺失时展示聚合提示。
- 提示列出来源记录缺失的 chunk id，最多展示前 6 条并说明剩余数量。
- 缺失来源提示使用 warning_amber 和金色语义。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 引用片段可解析但来源记录缺失时，用户能看到哪些 chunk 缺少来源上下文。
- 引用片段卡片仍保留“未知来源”展示，不阻塞查看片段内容。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.81：知识库问答详情展示引用覆盖率

输出：

- KnowledgeAnswerSessionDetailScreen 的引用依据区固定展示已找到引用片段数量。
- 引用全部找到时显示“已找到全部 N 条引用片段”。
- 引用部分缺失或全部缺失时显示“已找到 X/N 条引用片段”，并继续展示缺失 id。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户进入引用依据区时，可以先看到引用片段覆盖率。
- 引用部分缺失时既显示覆盖率，也显示缺失 citation id。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.82：知识库问答详情复制缺失引用标识

输出：

- KnowledgeAnswerSessionDetailScreen 的缺失 citation id 提示增加复制按钮。
- Source 记录缺失提示增加复制 chunk id 按钮。
- 复制后使用 SnackBar 告知已复制的 id 数量。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以一键复制缺失 citation id 或缺失来源记录的 chunk id。
- 复制动作不影响已找到引用片段的展示和打开行为。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.83：知识库问答详情复制引用片段 id

输出：

- KnowledgeAnswerSessionDetailScreen 的引用片段卡片增加复制片段 id 按钮。
- 复制动作复用缺失引用 id 的复制反馈。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从任意已展示引用片段复制 source chunk id。
- 打开来源详情的行为保持不变。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.84：知识库问答详情展示缺失来源 id

输出：

- KnowledgeAnswerSessionDetailScreen 的未知来源引用卡片展示 source id。
- 未知来源引用卡片增加复制 source id 按钮。
- 有正常 Source 记录的引用卡片不新增额外 source id 展示。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- Source 记录缺失时，用户能看到并复制对应 source id。
- 有 Source 记录的引用片段仍显示来源标题和可信度标签。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.85：知识库问答详情引用打开动作说明

输出：

- KnowledgeAnswerSessionDetailScreen 的引用片段打开图标增加 tooltip。
- tooltip 文案说明会打开来源并定位片段。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户悬停引用片段打开图标时，能理解该动作会定位来源片段。
- 引用片段卡片点击打开来源的行为保持不变。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.86：知识库问答详情汇总引用来源可信度

输出：

- KnowledgeAnswerSessionDetailScreen 的引用依据区新增来源可信度摘要。
- 摘要按 SourceTrustLevel 统计引用片段数量。
- 找不到 Source 记录的引用片段计入“未知来源”。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户查看知识库问答详情时，可以快速判断引用依据来自官方文档、源码、文章等哪类来源。
- 引用来源缺失时仍能在可信度摘要中看到“未知来源”数量。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.87：知识库问答详情引用可信度摘要排序稳定

输出：

- KnowledgeAnswerSessionDetailScreen 的来源可信度摘要按固定可信度顺序展示。
- 固定顺序为官方文档、源码、书籍/课程、文章、个人笔记、可信度未知、未知来源。
- 来源可信度摘要标签增加 tooltip，说明对应统计含义。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 同一组引用片段即使引用顺序不同，来源可信度摘要的展示顺序也保持稳定。
- 未标注可信度的来源与缺失来源记录的引用片段仍能区分显示。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.88：知识库问答详情引用覆盖率提示说明

输出：

- KnowledgeAnswerSessionDetailScreen 的引用覆盖率提示增加 tooltip。
- 覆盖完整时说明所有引用 id 都能解析到本地来源片段。
- 覆盖不完整时说明保存的引用 id 总数和本地可解析片段数。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户悬停引用覆盖率提示时，能理解“已找到 X/N 条引用片段”的检查口径。
- 引用缺失 id 和来源记录缺失提示仍分别展示，不混淆两类问题。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.89：知识库问答详情隐藏空可信度摘要

输出：

- KnowledgeAnswerSessionDetailScreen 仅在存在可展示引用片段时显示来源可信度摘要。
- 引用 id 全部解析失败时，不再显示只有标题、没有统计标签的“来源可信度”行。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 全部引用 id 缺失时，引用依据区只展示覆盖率和缺失引用提示。
- 存在至少一个可解析引用片段时，来源可信度摘要仍正常展示。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.90：知识库问答详情区分未知可信度文案

输出：

- KnowledgeAnswerSessionDetailScreen 的来源可信度摘要将 SourceTrustLevel.unknown 显示为“可信度未知”。
- 找不到 Source 记录的引用片段仍显示为“未知来源”。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能区分“来源记录存在但可信度未标注”和“来源记录缺失”。
- 引用片段卡片仍沿用来源自身的 trustLevel label，不改变数据模型。
- 不改变 summary 写入格式、AI 调用或写库行为。

### Leaf 12.91：知识库问答详情复制复盘文本

输出：

- KnowledgeAnswerSessionSummary 新增复盘文本导出函数。
- KnowledgeAnswerSessionDetailScreen 顶部增加“复制复盘”动作。
- 复制内容包含问题、证据质量、回答、要点、来源缺口、继续追问和引用片段 id。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户可以从知识库问答详情一键复制结构化复盘内容，用于面试准备或外部笔记。
- 复盘文本保留证据质量和引用片段 id，避免脱离来源上下文。
- 不改变 summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.92：知识库问答历史卡片复制复盘

输出：

- KnowledgeAnswerHistoryScreen 的问答历史卡片新增“复制复盘”图标动作。
- 历史卡片复用 KnowledgeAnswerSessionSummary 的复盘文本导出函数。
- 复制内容与详情页保持一致，包含证据质量和引用片段 id。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户不进入详情页，也能从完整历史列表复制结构化问答复盘。
- 历史卡片复制动作不影响点击卡片进入详情或补证按钮行为。
- 不改变 summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.93：Agent 首页最近问答复制复盘

输出：

- AgentHomeScreen 的最近知识库问答卡片新增“复制复盘”图标动作。
- Agent 首页复制动作复用 KnowledgeAnswerSessionSummary 的复盘文本导出函数。
- 复制内容与详情页、完整历史列表保持一致。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent 首页可以直接复制最近知识库问答复盘。
- 复制动作不影响点击最近问答卡片进入详情或补证按钮行为。
- 不改变 summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.94：Knowledge Base 最近问答复制复盘

输出：

- KnowledgeBaseScreen 的最近知识库问答行新增“复制复盘”图标动作。
- _LibraryRow 支持可选 trailingWidget，以便只为问答行放置复制按钮和进入详情箭头。
- 复制内容复用 KnowledgeAnswerSessionSummary 的复盘文本导出函数。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Knowledge Base 检索页的最近问答区可以直接复制结构化问答复盘。
- 其他复用 _LibraryRow 的来源、知识点和题目行保持原有右侧图标行为。
- 不改变 summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.95：知识库问答复制复盘按钮组件化

输出：

- 新增 KnowledgeAnswerReviewCopyButton，共享复制复盘、写剪贴板和成功提示逻辑。
- KnowledgeAnswerSessionDetailScreen、KnowledgeAnswerHistoryScreen、AgentHomeScreen 和 KnowledgeBaseScreen 改用共享按钮。
- 页面级重复 Clipboard helper 被移除。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_review_copy_button.dart
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/agent/agent_home_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 四个入口的“复制复盘”行为、tooltip 和成功提示保持一致。
- 后续修改复盘复制行为时只需更新共享按钮。
- 不改变复盘文本格式、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.96：知识库问答复制复盘包含证据建议

输出：

- buildKnowledgeAnswerReviewText 在证据质量标签后加入证据建议。
- 证据建议复用 knowledgeAnswerEvidenceQualityGuidance 的统一口径。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制问答复盘到外部笔记后，仍能看到这条回答适合作为复盘样本、应补证还是需核查。
- 证据建议与详情页证据质量说明保持同一口径。
- 不改变 summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.97：知识库问答复制复盘包含补证查询

输出：

- buildKnowledgeAnswerReviewText 在存在 evidenceRepairQuery 时加入补证动作。
- buildKnowledgeAnswerReviewText 在存在 evidenceRepairQuery 时加入补证查询文本。
- 补证动作复用 knowledgeAnswerEvidenceRepairKindLabel 的统一口径。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制可补证问答复盘到外部笔记后，可以直接看到下一步应用“检索缺口”还是“补齐引用”。
- 用户复制可补证问答复盘到外部笔记后，可以直接看到应继续检索的查询文本。
- 不改变 summary 写入格式、补证按钮导航、AI 调用、引用读取或写库行为。

### Leaf 12.98：知识库问答复制复盘包含追溯标签

输出：

- buildKnowledgeAnswerReviewText 在证据质量后加入追溯标签。
- 追溯标签复用 KnowledgeAnswerSessionSummaryRecord.traceLabels。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制问答复盘到外部笔记后，可以看到证据合格、缺少引用、引用数量、来源缺口和追问数量等摘要。
- 复制文本中的追溯标签与详情页、历史列表展示口径一致。
- 不改变 summary 写入格式、补证按钮导航、AI 调用、引用读取或写库行为。

### Leaf 12.99：知识库问答复制复盘显式标记缺少引用

输出：

- buildKnowledgeAnswerReviewText 始终输出“引用片段 id”区块。
- citationIds 为空时，引用片段区块显示“未保存引用 id”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制缺少引用的问答复盘到外部笔记后，可以明确看到该记录没有保存引用 id。
- 用户复制有引用的问答复盘时，引用片段 id 仍按列表输出。
- 不改变 summary 写入格式、补证按钮导航、AI 调用、引用读取或写库行为。

### Leaf 12.100：知识库问答复制复盘成功提示说明

输出：

- KnowledgeAnswerReviewCopyButton 的复制成功提示说明复盘包含证据状态。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_review_copy_button.dart
docs/trellis-execution-map.md
```

验收：

- 用户点击任一“复制复盘”入口后，能从提示确认复制内容包含证据状态。
- 四个复用共享按钮的入口提示保持一致。
- 不改变复制文本格式、summary 写入格式、补证按钮导航、AI 调用、引用读取或写库行为。

### Leaf 12.101：知识库问答复制复盘 Tooltip 说明

输出：

- KnowledgeAnswerReviewCopyButton 的 tooltip 改为说明会复制含证据状态的复盘。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_review_copy_button.dart
docs/trellis-execution-map.md
```

验收：

- 用户悬停任一复制复盘入口时，可以知道复制内容包含证据状态。
- 四个复用共享按钮的入口 tooltip 保持一致。
- 不改变复制文本格式、summary 写入格式、补证按钮导航、AI 调用、引用读取或写库行为。

### Leaf 12.102：知识库问答复制复盘显式标记来源缺口

输出：

- buildKnowledgeAnswerReviewText 始终输出“来源缺口”区块。
- sourceGaps 为空时，来源缺口区块显示“未记录来源缺口”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制没有来源缺口的问答复盘到外部笔记后，可以明确看到该记录未记录来源缺口。
- 用户复制有来源缺口的问答复盘时，来源缺口仍按列表输出。
- 不改变 summary 写入格式、补证按钮导航、AI 调用、引用读取或写库行为。

### Leaf 12.103：知识库问答复制复盘显式标记继续追问

输出：

- buildKnowledgeAnswerReviewText 始终输出“继续追问”区块。
- followUpQuestions 为空时，继续追问区块显示“未记录继续追问”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制没有继续追问的问答复盘到外部笔记后，可以明确看到该记录未记录继续追问。
- 用户复制有继续追问的问答复盘时，继续追问仍按列表输出。
- 不改变 summary 写入格式、追问点击导航、AI 调用、引用读取或写库行为。

### Leaf 12.104：知识库问答复制复盘显式标记回答缺失

输出：

- buildKnowledgeAnswerReviewText 始终输出“回答”区块。
- answer 为空时，回答区块显示“未记录回答”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制没有回答文本的问答复盘到外部笔记后，可以明确看到该记录未记录回答。
- 用户复制有回答文本的问答复盘时，回答内容仍按原文输出。
- 不改变 summary 写入格式、追问点击导航、AI 调用、引用读取或写库行为。

### Leaf 12.105：知识库问答复制复盘显式标记要点缺失

输出：

- buildKnowledgeAnswerReviewText 始终输出“要点”区块。
- keyPoints 为空时，要点区块显示“未记录要点”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制没有要点的问答复盘到外部笔记后，可以明确看到该记录未记录要点。
- 用户复制有要点的问答复盘时，要点仍按列表输出。
- 不改变 summary 写入格式、追问点击导航、AI 调用、引用读取或写库行为。

### Leaf 12.106：知识库问答复制复盘显式标记问题缺失

输出：

- buildKnowledgeAnswerReviewText 始终输出“问题”字段。
- question 为空时，问题字段显示“未记录问题”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制缺少问题文本的问答复盘到外部笔记后，可以明确看到该记录未记录问题。
- 用户复制有问题文本的问答复盘时，问题仍按原文输出。
- 不改变 summary 写入格式、追问点击导航、AI 调用、引用读取或写库行为。

### Leaf 12.107：知识库问答复制复盘显式标记完成时间缺失

输出：

- buildKnowledgeAnswerReviewText 始终输出“完成时间”字段。
- completedText 为空时，完成时间字段显示“未记录完成时间”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制缺少完成时间的问答复盘到外部笔记后，可以明确看到该记录未记录完成时间。
- 用户复制有完成时间的问答复盘时，完成时间仍按传入文本输出。
- 不改变 summary 写入格式、追问点击导航、AI 调用、引用读取或写库行为。

### Leaf 12.108：即时知识库回答复制复盘

输出：

- KnowledgeBaseScreen 的即时“来源约束回答”面板新增复制复盘按钮。
- 即时回答复制复用 KnowledgeAnswerReviewCopyButton 和 buildKnowledgeAnswerReviewText。
- 即时回答复制内容包含证据状态、证据建议、来源缺口、继续追问和引用片段 id。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户刚生成来源约束回答时，不必进入历史记录即可复制结构化复盘。
- 即时回答尚未绑定 LearningSession 完成时间时，复制文本会显示“未记录完成时间”。
- 不改变回答保存、summary 写入格式、追问点击导航、AI 调用、引用读取或写库行为。

### Leaf 12.109：即时知识库回答复制 Tooltip 语义化

输出：

- KnowledgeAnswerReviewCopyButton 支持可选 tooltip 覆盖。
- 即时“来源约束回答”面板复制按钮使用“复制即时回答复盘”文案。
- 其他复用入口保持默认“复制含证据状态的复盘”文案。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_review_copy_button.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户悬停即时回答复制入口时，能区分这是复制当前即时回答复盘。
- 历史、详情和最近问答入口的默认 tooltip 不变。
- 不改变复制文本格式、回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.110：即时知识库回答复制复盘包含记录状态

输出：

- buildKnowledgeAnswerReviewText 支持可选记录状态字段。
- KnowledgeAnswerReviewCopyButton 透传可选记录状态。
- 即时“来源约束回答”面板复制复盘时写入当前保存状态。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_review_copy_button.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制即时回答复盘到外部笔记后，可以看到该回答是否已保存到学习记录、保存失败或尚未确认保存状态。
- 历史、详情和最近问答入口不传记录状态时，复制文本保持原有结构。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.111：即时知识库回答复制成功提示语义化

输出：

- KnowledgeAnswerReviewCopyButton 支持可选成功提示文案。
- 即时“来源约束回答”面板复制成功提示使用“已复制即时回答复盘，包含证据状态”。
- 其他复用入口保持默认“已复制问答复盘，包含证据状态”。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_review_copy_button.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制即时回答复盘后，可以从成功提示区分当前复制的是即时回答。
- 历史、详情和最近问答入口的默认成功提示不变。
- 不改变复制文本格式、回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.112：知识库问答复制复盘支持引用片段摘要

输出：

- buildKnowledgeAnswerReviewText 支持可选 citationContextLines。
- KnowledgeAnswerReviewCopyButton 透传可选 citationContextLines。
- citationContextLines 非空时，复制文本新增“引用片段摘要”区块。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_review_copy_button.dart
docs/trellis-execution-map.md
```

验收：

- 调用方不传 citationContextLines 时，历史、详情和最近问答复制文本保持原有结构。
- 调用方传入 citationContextLines 时，复制文本能附带可读的引用片段摘要。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.113：即时知识库回答复制复盘包含引用片段摘要

输出：

- KnowledgeBaseScreen 的即时回答复制复盘传入引用片段摘要。
- 引用片段摘要包含 chunk id、locator 或片段序号、source id 和内容摘录。
- 即时回答引用片段摘要最多包含前 5 条，避免复制内容过长。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制即时来源约束回答后，可以在外部笔记中直接看到引用片段的可读摘要。
- 没有引用片段时，复制文本仍只显示“未保存引用 id”，不会出现空摘要区块。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.114：即时知识库回答引用摘要边界提示

输出：

- 即时回答复制复盘的引用片段摘要在内容为空时显示“内容为空”。
- 即时回答复制复盘的引用片段摘要超过 5 条时显示剩余未列出数量。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 引用片段内容为空时，复制文本不会留下空白摘要。
- 引用片段超过 5 条时，复制文本能说明还有多少引用片段未列出。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.115：知识库问答详情复制复盘包含引用片段摘要

输出：

- KnowledgeAnswerSessionDetailScreen 顶部复制复盘按钮在引用片段加载完成后传入引用摘要。
- 详情页引用摘要包含 chunk id、来源标题、来源可信度、locator 或片段序号和内容摘录。
- 详情页引用摘要最多包含前 5 条，并在超过 5 条时提示未列出数量。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在知识库问答详情页复制复盘时，可以在外部笔记中看到可读引用片段摘要。
- 引用片段尚未加载或没有可解析引用片段时，复制文本仍保持无摘要的原有结构。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.116：知识库问答复制引用摘要格式集中

输出：

- knowledge_answer_session_summary.dart 新增引用摘要行格式化 helper。
- knowledge_answer_session_summary.dart 新增引用 locator 和摘要截断 helper。
- KnowledgeBaseScreen 和 KnowledgeAnswerSessionDetailScreen 的复制引用摘要改用共享 helper。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 即时回答和详情页复制复盘的引用摘要截断、空内容、locator 文案口径一致。
- 后续调整引用摘要格式时集中修改 summary service helper。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.117：知识库问答复制复盘包含已保存状态

输出：

- knowledge_answer_session_summary.dart 新增保存状态共享文案。
- KnowledgeAnswerSessionDetailScreen、KnowledgeAnswerHistoryScreen、AgentHomeScreen 和 KnowledgeBaseScreen 最近问答复制复盘时写入“已保存到学习记录”。
- 即时回答复制复盘复用同一保存状态文案，未确认保存状态也集中为共享文案。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/agent/agent_home_screen.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制保存后的知识库问答复盘时，可以在外部笔记中看到该记录已保存到学习记录。
- 用户复制即时回答复盘时，保存成功状态与保存后记录使用同一文案。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.118：即时知识库回答复制复盘包含保存时间

输出：

- KnowledgeBaseScreen 记录即时回答保存成功时间。
- _KnowledgeAnswerPanel 接收 recordSavedAt。
- 即时回答保存成功后复制复盘时，完成时间使用保存成功时间。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在即时回答保存成功后复制复盘，完成时间不再显示“未记录完成时间”。
- 即时回答未保存或保存失败时，复制复盘仍通过记录状态说明当前情况。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.119：即时知识库回答复制复盘包含生成时间

输出：

- KnowledgeBaseScreen 记录即时回答生成完成时间。
- _KnowledgeAnswerPanel 接收 answerCompletedAt。
- 即时回答复制复盘的完成时间优先使用保存成功时间，未保存时回退到生成完成时间。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制尚未保存的即时回答复盘时，完成时间不再显示“未记录完成时间”。
- 用户复制保存失败的即时回答复盘时，仍能看到回答生成完成时间和保存失败状态。
- 保存成功后仍优先使用保存成功时间。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.120：即时知识库回答保存状态显示时间

输出：

- KnowledgeBaseScreen 即时回答面板保存成功状态显示保存时间。
- recordSavedAt 为空时仍显示原有保存成功文案。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在即时回答面板看到“已保存到学习记录”时，也能看到保存成功时间。
- 保存时间缺失时不会显示空时间。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.121：即时知识库回答未保存状态显示生成时间

输出：

- KnowledgeBaseScreen 即时回答面板在未保存或保存失败时显示生成完成时间。
- 保存成功时仍以保存成功时间作为主要状态，不重复显示生成时间。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在即时回答尚未保存时，可以看到回答生成完成时间。
- 用户在即时回答保存失败时，可以同时看到保存失败提示和回答生成完成时间。
- 保存成功后状态仍显示保存时间，不额外重复生成时间。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.122：即时知识库回答显示保存中状态

输出：

- knowledge_answer_session_summary.dart 新增“正在保存到学习记录”共享文案。
- KnowledgeBaseScreen 记录即时回答保存中状态。
- 即时回答面板和复制复盘在保存中时显示“正在保存到学习记录”。

涉及文件：

```text
lib/services/agent/knowledge_answer_session_summary.dart
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户刚生成即时回答、学习记录仍在写入时，可以看到保存中状态。
- 用户在保存中点击复制复盘时，记录状态显示为正在保存到学习记录。
- 保存成功和保存失败状态仍按既有路径更新。
- 不改变回答保存、summary 写入格式、AI 调用、引用读取或写库行为。

### Leaf 12.123：即时知识库回答保存失败可重试

输出：

- KnowledgeBaseScreen 在即时回答保存到学习记录失败时显示重试保存动作。
- 重试复用当前问题、回答和引用 id，继续走原有学习记录写入路径。
- 保存中或保存成功后不再显示重试动作。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户看到“回答已生成，但学习记录保存失败”时，可以直接重试保存当前回答。
- 重试不会重新调用 AI 生成回答，也不会改变已有回答内容。
- 重试期间继续显示保存中状态，成功或再次失败后复用既有状态更新。
- 不改变回答 summary 格式、引用读取、AI 调用或学习记录 schema。

### Leaf 12.124：即时知识库回答保存状态说明引用数量

输出：

- KnowledgeBaseScreen 即时回答保存中状态显示将保存的引用 id 数量。
- 保存失败状态显示重试会保存的引用 id 数量。
- 没有引用 id 时明确说明本次回答没有可保存引用 id。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在即时回答保存中，可以看到本次写入会携带多少条引用 id。
- 用户在保存失败后准备重试时，可以看到重试会复用当前回答的引用 id。
- 没有引用 id 的回答不会被误导为有可保存证据。
- 不改变回答 summary 格式、引用读取、AI 调用或学习记录 schema。

### Leaf 12.125：即时知识库回答保存失败记录失败时间

输出：

- KnowledgeBaseScreen 记录即时回答保存失败发生时间。
- 即时回答面板在保存失败时显示“保存失败于”时间。
- 复制即时回答复盘时，记录状态包含保存失败时间。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在保存失败后能看到失败发生时间，而不是只看到错误文案。
- 用户复制保存失败的即时回答复盘时，外部笔记也能保留失败时间。
- 开始保存、保存成功、切换查询时会清空旧失败时间。
- 不改变回答 summary 格式、引用读取、AI 调用或学习记录 schema。

### Leaf 12.126：即时知识库回答记录保存尝试次数

输出：

- KnowledgeBaseScreen 记录即时回答保存尝试次数。
- 保存中、保存失败、重试后保存成功状态在多次尝试时显示次数。
- 复制即时回答复盘时，记录状态包含多次保存尝试信息。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 第一次保存不额外显示噪音状态。
- 保存失败后重试时，用户能看到当前是第几次保存尝试。
- 多次尝试后复制复盘，外部笔记能保留尝试次数。
- 切换查询或重新生成回答时，尝试次数归零。
- 不改变回答 summary 格式、引用读取、AI 调用或学习记录 schema。

### Leaf 12.127：即时知识库回答生成失败可重试

输出：

- KnowledgeBaseScreen 即时回答生成失败状态显示“重新生成回答”动作。
- 重试复用当前问题和已缓存的来源片段。
- 没有可用来源片段时重试动作保持不可用。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户看到即时回答生成失败时，可以直接从错误面板重新生成。
- 重试使用当前问题和本轮已读取的来源片段，不要求用户重新点击上方回答按钮。
- 重试会走既有回答生成流程，成功后继续触发原有学习记录保存逻辑。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.128：即时知识库回答生成失败显示重试来源数量

输出：

- KnowledgeBaseScreen 即时回答生成失败状态显示重试会复用的来源片段数量。
- 没有可用来源片段时明确说明不能基于缓存来源重试。
- 重试按钮可用性继续由是否存在缓存来源片段决定。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户看到生成失败时，可以知道重试会继续受多少条来源片段约束。
- 没有来源片段时，错误面板不会误导用户以为可以来源约束重试。
- 只改变失败状态展示，不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.129：即时知识库回答生成失败记录失败时间

输出：

- KnowledgeBaseScreen 记录即时回答生成失败发生时间。
- 生成失败面板显示“生成失败于”时间。
- 重新生成成功或切换查询时清空旧失败时间。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户看到即时回答生成失败时，可以知道失败发生时间。
- 重新生成成功后不会继续显示旧失败时间。
- 切换查询后不会把上一题的失败时间带到新问题。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.130：即时知识库回答记录生成尝试次数

输出：

- KnowledgeBaseScreen 记录即时回答生成尝试次数。
- 生成失败后多次重试时显示已尝试生成次数。
- 重试成功后显示第几次生成成功，第一次成功不额外显示噪音状态。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 第一次生成失败不会额外显示尝试次数噪音。
- 第二次及以后失败时，用户能看到已尝试生成次数。
- 多次尝试后成功，回答面板能显示第几次生成成功。
- 切换查询后生成尝试次数归零。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.131：即时知识库回答生成失败可复制诊断

输出：

- KnowledgeBaseScreen 生成失败面板新增复制失败诊断动作。
- 诊断文本包含问题、错误、失败时间、生成尝试次数和来源片段数量。
- 复制成功后显示本地 SnackBar 反馈。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在即时回答生成失败时，可以一键复制排查信息。
- 诊断文本能说明失败发生在哪个问题、何时失败、尝试了几次、使用了多少来源片段。
- 该诊断只写入剪贴板，不保存为学习记录或知识内容。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.132：即时知识库回答区分初次生成与重试计数

输出：

- KnowledgeBaseScreen 的普通“回答”动作会重置生成尝试次数并从第 1 次开始。
- 生成失败面板的“重新生成回答”动作会延续本轮生成尝试次数。
- `_answerQuestion` 支持显式控制是否重置生成尝试次数。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户对同一问题重新点击上方“回答”时，不会被误标为失败重试后的第 N 次生成。
- 用户在失败面板点击“重新生成回答”时，尝试次数继续累加。
- 重试成功后的“第 N 次生成成功”只代表本轮失败恢复链路。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.133：即时知识库回答复制复盘保留生成重试成功状态

输出：

- KnowledgeBaseScreen 即时回答复制复盘的记录状态包含生成重试成功信息。
- UI 中的“第 N 次生成成功”和复制文本保持一致。
- 未发生生成重试时复制文本不额外增加生成尝试噪音。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制重试后成功的即时回答复盘，可以在外部笔记看到第几次生成成功。
- 用户复制第一次成功的即时回答复盘，不会看到多余的生成尝试状态。
- 保存成功、保存中、保存失败状态仍按既有文案展示。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.134：即时知识库回答生成失败诊断包含来源片段摘要

输出：

- KnowledgeBaseScreen 复制生成失败诊断时包含来源片段摘要。
- 来源摘要复用即时回答引用摘要格式，最多列出前 5 条并显示溢出提示。
- 没有缓存来源片段时明确写入“未缓存来源片段”。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户复制生成失败诊断后，可以看到本轮生成使用的来源片段 id、定位和内容摘要。
- 来源片段超过 5 条时，诊断文本说明还有多少条未列出。
- 没有来源片段时，诊断文本不会只显示空白来源摘要。
- 诊断仍只写入剪贴板，不保存为学习记录或知识内容。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.135：即时知识库回答保存失败可复制诊断

输出：

- KnowledgeBaseScreen 保存失败状态新增复制保存失败诊断动作。
- 保存失败诊断包含问题、错误、失败时间、保存尝试次数、生成状态、引用 id 和引用片段摘要。
- `_AnswerRecordStatus` 支持第二个可选动作按钮，用于同一状态同时提供重试和复制诊断。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在即时回答已生成但保存学习记录失败时，可以一键复制排查信息。
- 诊断文本能说明保存失败发生在哪个问题、何时失败、尝试了几次、回答是否由重试生成。
- 诊断文本包含本轮回答准备保存的引用 id 和可解析引用片段摘要。
- 该诊断只写入剪贴板，不保存为学习记录或知识内容。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.136：即时知识库回答上下文读取失败可恢复

输出：

- KnowledgeBaseScreen 将回答上下文读取失败状态升级为可操作错误条。
- 错误条支持重试读取 `knowledgeAnswerContextChunksProvider(query)`。
- 错误条支持复制上下文读取诊断，包含查询、错误和复制时间。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在回答上下文读取失败时，可以直接重试读取来源片段。
- 重试只刷新上下文 provider，不触发 AI 回答生成。
- 用户可以复制上下文读取失败诊断用于排查。
- 诊断只写入剪贴板，不保存为学习记录或知识内容。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.137：即时知识库回答无可引用片段可复制诊断

输出：

- KnowledgeBaseScreen 在回答上下文读取成功但没有可引用片段时显示复制诊断动作。
- 无引用诊断包含查询、状态、可引用片段数量和复制时间。
- 有可引用片段时不显示该诊断动作，保持原有回答入口。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在“暂无可引用片段”状态下可以复制诊断，用于记录当前查询没有命中来源上下文。
- 诊断说明这是上下文读取成功但命中 0 条来源片段，而不是 AI 生成失败。
- 诊断只写入剪贴板，不保存为学习记录或知识内容。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.138：即时知识库回答无可引用片段可重新匹配

输出：

- KnowledgeBaseScreen 在“暂无可引用片段”状态显示重新匹配来源片段动作。
- 重新匹配复用当前 query 刷新 `knowledgeAnswerContextChunksProvider(query)`。
- 有可引用片段时不显示该动作，保持原有回答入口。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户导入或调整来源后，可以在当前 query 下直接重新匹配来源片段。
- 重新匹配只刷新上下文 provider，不触发 AI 回答生成。
- “基于来源回答”按钮仍在 0 条可引用片段时保持不可用。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.139：即时知识库回答无可引用片段可查看来源

输出：

- KnowledgeBaseScreen 在“暂无可引用片段”状态显示查看来源动作。
- 查看来源动作切换到当前知识库页的来源 tab。
- 有可引用片段时不显示该动作，保持原有回答入口。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在当前 query 无可引用片段时，可以直接查看来源列表。
- 查看来源只切换 tab，不改变 query、不触发 AI 回答生成。
- “基于来源回答”按钮仍在 0 条可引用片段时保持不可用。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.140：知识库来源空状态可导入来源

输出：

- KnowledgeBaseScreen 来源 tab 空状态显示导入来源动作。
- 导入来源动作打开现有 IngestionScreen。
- 导入页继续复用既有保存和 provider invalidate 流程。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户进入来源 tab 看到“暂无来源”时，可以直接打开导入来源页面。
- 导入入口不改变已有来源列表展示和来源详情入口。
- 导入入口不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.141：知识库来源列表可继续导入来源

输出：

- KnowledgeBaseScreen 来源 tab 非空列表顶部显示“导入新来源”入口。
- 导入新来源入口打开现有 IngestionScreen。
- 现有来源行继续按原顺序展示在导入入口之后。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户已有来源时，也能从来源 tab 直接继续补充来源。
- 点击现有来源仍打开对应 SourceDetailScreen。
- 导入入口不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.142：知识库来源列表读取失败可恢复

输出：

- KnowledgeBaseScreen 来源 tab 读取失败状态显示重试读取来源动作。
- 来源读取失败状态支持复制诊断，包含错误和复制时间。
- `_SourcesTab` 改为 ConsumerWidget，以便在错误状态刷新 `sourceListProvider`。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在来源列表读取失败时，可以直接重试读取来源。
- 用户可以复制来源读取失败诊断用于排查。
- 错误文案过长时不会撑爆错误页布局。
- 不改变已有来源列表展示、导入入口或来源详情入口。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.143：知识库列表错误恢复组件可复用

输出：

- KnowledgeBaseScreen 将来源列表错误状态抽为 `_KnowledgeLibraryErrorState`。
- 列表错误诊断复制逻辑抽为 `_copyKnowledgeLibraryErrorDiagnostic`。
- 来源 tab 继续复用同一重试、诊断和错误文案行为。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 来源列表读取失败时，用户仍能重试读取来源和复制诊断。
- 复制诊断的标题和成功提示可由调用方配置。
- 后续知识点、题目等 tab 可以复用同一错误恢复组件。
- 不改变已有来源列表展示、导入入口或来源详情入口。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.144：知识库知识点列表读取失败可恢复

输出：

- KnowledgeBaseScreen 知识点 tab 读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 知识点读取失败状态支持重试读取 `knowledgePointListProvider`。
- 知识点读取失败状态支持复制诊断。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在知识点列表读取失败时，可以直接重试读取知识点。
- 用户可以复制知识点读取失败诊断用于排查。
- 知识点空状态、列表展示和详情入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.145：知识库题目列表读取失败可恢复

输出：

- KnowledgeBaseScreen 题目 tab 读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 题目读取失败状态支持重试读取 `allQuestionsProvider`。
- 题目读取失败状态支持复制诊断。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在题目列表读取失败时，可以直接重试读取题目。
- 用户可以复制题目读取失败诊断用于排查。
- 题目空状态、筛选、列表展示和详情入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.146：知识库待核验列表读取失败可恢复

输出：

- KnowledgeBaseScreen 待核验 tab 读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 待核验读取失败状态支持重试读取 `pendingQuestionListProvider`。
- 待核验读取失败状态支持复制诊断。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在待核验列表读取失败时，可以直接重试读取待核验内容。
- 用户可以复制待核验读取失败诊断用于排查。
- 待核验空状态、列表展示和证据页入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.147：知识库检索结果读取失败可恢复

输出：

- KnowledgeBaseScreen 检索结果读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 检索结果读取失败状态支持刷新 `knowledgeSearchCorpusProvider` 和当前 query 的 `knowledgeSearchResultsProvider`。
- 通用列表错误诊断支持额外诊断行，检索失败诊断包含当前查询。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在检索结果读取失败时，可以直接重试当前查询。
- 重试检索只刷新本地检索 corpus 和结果 provider，不触发 AI 回答生成。
- 用户可以复制包含当前查询的检索失败诊断用于排查。
- 检索空结果、结果列表和结果回跳入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.148：知识库最近问答读取失败可恢复

输出：

- KnowledgeBaseScreen 检索空状态中的最近知识库问答读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 最近问答读取失败状态支持重试读取 `knowledgeAnswerSessionListProvider`。
- 最近问答读取失败状态支持复制诊断。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在检索页最近问答读取失败时，可以直接重试读取最近问答。
- 用户可以复制最近问答读取失败诊断用于排查。
- 检索空状态、最近问答列表、质量提示和历史入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.149：来源详情读取失败可恢复

输出：

- SourceDetailScreen 来源片段读取失败状态复用 `_KnowledgeLibraryErrorState`。
- SourceDetailScreen 关联知识点读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 来源详情读取失败诊断包含来源标题和来源 ID。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在来源详情片段读取失败时，可以直接重试读取当前来源片段。
- 用户在来源详情关联知识点读取失败时，可以直接重试读取当前来源的关联知识点。
- 用户可以复制包含来源上下文的读取失败诊断用于排查。
- 来源详情头部、URI 展示、片段高亮和关联知识点入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.150：知识点详情读取失败可恢复

输出：

- KnowledgePointDetailScreen 学习动作依赖数据读取失败状态复用 `_KnowledgeLibraryErrorState`。
- KnowledgePointDetailScreen 证据片段和相关题目读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 知识点详情读取失败诊断包含知识点标题和知识点 ID。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在知识点详情学习动作读取失败时，可以直接重试读取当前知识点的证据或题目。
- 用户在证据片段读取失败时，可以直接重试读取当前知识点证据。
- 用户在相关题目读取失败时，可以直接重试读取当前知识点题目。
- 用户可以复制包含知识点上下文的读取失败诊断用于排查。
- 知识点详情头部、摘要、学习动作、证据列表和相关题目入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.151：题目证据读取失败可恢复

输出：

- QuestionEvidenceScreen 关联知识点读取失败状态复用 `_KnowledgeLibraryErrorState`。
- QuestionEvidenceScreen 引用片段读取失败状态复用 `_KnowledgeLibraryErrorState`。
- 题目证据读取失败诊断包含题目、题目 ID、题包 ID、引用数量和引用 ID。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在题目证据页关联知识点读取失败时，可以直接重试读取当前关联知识点。
- 用户在题目证据页引用片段读取失败时，可以直接重试读取当前引用片段。
- 用户可以复制包含题目和引用上下文的读取失败诊断用于排查。
- 题目证据页头部、答案区、引用片段列表和核验动作保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.152：知识库裸错误状态清理

输出：

- 移除 KnowledgeBaseScreen 中已无调用点的 `_ErrorState` 私有组件。
- 确认知识库主文件的读取失败入口统一走可重试、可复制诊断的恢复组件。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- `knowledge_base_screen.dart` 中不再存在 `_ErrorState` 调用点。
- 知识库主文件中的列表、详情和证据读取失败状态保持可恢复。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.153：知识库错误恢复组件共享

输出：

- 新增 `knowledge_library_error_state.dart`，沉淀可重试、可复制诊断的知识库错误恢复组件。
- KnowledgeBaseScreen 改为复用共享 `KnowledgeLibraryErrorState`。
- KnowledgeAnswerHistoryScreen 问答历史读取失败状态改为复用共享 `KnowledgeLibraryErrorState`。
- 问答历史读取失败诊断包含当前筛选上下文。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/knowledge_base/knowledge_answer_history_screen.dart
lib/features/knowledge_base/knowledge_library_error_state.dart
docs/trellis-execution-map.md
```

验收：

- 用户在知识库问答历史读取失败时，可以直接重试读取历史。
- 用户可以复制包含当前筛选上下文的问答历史读取失败诊断用于排查。
- KnowledgeBaseScreen 中的错误恢复 UI 行为保持不变，只切换到共享组件。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.154：知识库问答详情引用读取失败可恢复

输出：

- KnowledgeAnswerSessionDetailScreen 引用依据读取失败状态复用 `KnowledgeLibraryErrorState`。
- 引用依据读取失败状态支持重试当前问答记录的 citation key。
- 引用依据读取失败诊断包含问题、记录 ID、完成时间、引用数量和引用 ID。

涉及文件：

```text
lib/features/knowledge_base/knowledge_answer_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在知识库问答详情引用依据读取失败时，可以直接重试读取引用依据。
- 用户可以复制包含问答记录和引用上下文的失败诊断用于排查。
- 问答详情头部、复盘复制、证据质量、回答、要点、来源缺口和继续追问保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.155：Agent 首页知识库问答读取失败可恢复

输出：

- AgentHomeScreen 最近知识库问答读取失败状态复用 `KnowledgeLibraryErrorState`。
- Agent 首页最近知识库问答读取失败状态支持重试 `knowledgeAnswerSessionListProvider`。
- Agent 首页最近知识库问答读取失败诊断标明入口来源。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent 首页最近知识库问答读取失败时，可以直接重试读取问答记录。
- 用户可以复制标明 Agent 首页入口的读取失败诊断用于排查。
- Agent 首页的质量提示、最近问答卡片、历史入口和检索回跳保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.156：Agent 首页学习准备度读取失败可恢复

输出：

- AgentHomeScreen 在有来源知识点读取失败时展示可重试、可复制诊断的恢复面板。
- AgentHomeScreen 在可练习知识点读取失败时展示可重试、可复制诊断的恢复面板。
- 学习准备度读取失败诊断标明 Agent 首页入口和对应用途。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent 首页有来源知识点读取失败时，可以直接重试刷新学习路线输入。
- 用户在 Agent 首页可练习知识点读取失败时，可以直接重试刷新学习路线输入。
- 用户可以复制标明入口和用途的学习准备度读取失败诊断用于排查。
- 面试官模式、导师模式、复习模式的启用规则和原有跳转保持不变。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.157：来源片段来源读取失败可恢复

输出：

- KnowledgeBaseScreen 的片段来源行支持错误态图标和错误态颜色。
- 片段来源读取失败时支持重试读取当前 `sourceProvider(sourceId)`。
- 片段来源读取失败时支持复制包含来源 ID、片段 ID 和片段位置的诊断。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在来源片段卡片的来源读取失败时，可以直接重试读取来源记录。
- 用户可以复制包含来源和片段上下文的失败诊断用于排查。
- 来源读取成功、来源缺失、片段高亮和打开来源详情行为保持原有逻辑。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.158：来源片段缺失来源记录可诊断

输出：

- KnowledgeBaseScreen 的片段来源行在来源记录缺失时展示错误态图标和错误态颜色。
- 片段来源记录缺失时支持重试读取当前 `sourceProvider(sourceId)`。
- 片段来源记录缺失时支持复制包含来源 ID、片段 ID 和片段位置的诊断。

涉及文件：

```text
lib/features/knowledge_base/knowledge_base_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在来源片段卡片显示来源已缺失时，可以直接重试读取来源记录。
- 用户可以复制包含来源和片段上下文的缺失来源诊断用于排查。
- 来源读取成功、来源读取失败、片段高亮和打开来源详情行为保持原有逻辑。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.159：共享引用块来源读取失败可恢复

输出：

- SourceCitationBlock 在来源读取失败时展示可重试、可复制诊断的紧凑状态行。
- SourceCitationBlock 在来源记录缺失时展示可重试、可复制诊断的紧凑状态行。
- 共享引用块来源诊断包含来源 ID、片段 ID 和片段位置。

涉及文件：

```text
lib/shared/widgets/source_citation_block.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 quiz、导师讲解或面试复盘的引用块来源读取失败时，可以直接重试读取来源。
- 用户在共享引用块显示来源已缺失时，可以复制包含来源和片段上下文的诊断。
- 引用块的来源读取成功、片段位置和片段正文展示保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.160：Agent 首页最近记录读取失败可恢复

输出：

- AgentHomeScreen 最近 Agent Session 读取失败状态复用 `KnowledgeLibraryErrorState`。
- AgentHomeScreen 最近导师讲解读取失败状态复用 `KnowledgeLibraryErrorState`。
- AgentHomeScreen 最近面试复盘读取失败状态复用 `KnowledgeLibraryErrorState`。
- 最近记录读取失败诊断标明 Agent 首页入口。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent 首页最近 Agent Session 读取失败时，可以直接重试刷新学习记录输入。
- 用户在 Agent 首页最近导师讲解或面试复盘读取失败时，可以直接重试刷新学习记录输入。
- 用户可以复制标明入口的最近记录读取失败诊断用于排查。
- 最近 Agent Session、导师讲解、知识库问答和面试复盘的成功展示保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.161：Agent 首页学习路线读取失败可恢复

输出：

- AgentHomeScreen 学习路线读取失败状态复用 `KnowledgeLibraryErrorState`。
- 学习路线读取失败状态支持重试刷新当前目标的学习路线输入。
- 学习路线读取失败诊断包含 Agent 首页入口和当前学习目标。
- 移除 AgentHomeScreen 中已无调用点的 `_PlanErrorCard`。

涉及文件：

```text
lib/features/agent/agent_home_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent 首页学习路线读取失败时，可以直接重试刷新当前目标路线。
- 用户可以复制包含当前学习目标的学习路线读取失败诊断用于排查。
- 学习路线读取成功、加载态、执行下一步和路线入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.162：Agent Session 历史读取失败可恢复

输出：

- AgentSessionHistoryScreen 读取失败状态复用 `KnowledgeLibraryErrorState`。
- Agent Session 历史读取失败状态支持重试刷新 `agentSessionListProvider` 和 `agentSessionMemoryIndexProvider`。
- Agent Session 历史读取失败诊断包含入口、目标筛选、未处理追问筛选、目标筛选和搜索词。

涉及文件：

```text
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent Session 历史读取失败时，可以直接重试读取历史。
- 用户可以复制包含当前筛选上下文的历史读取失败诊断用于排查。
- Agent Session 历史读取成功、加载态、筛选栏、空筛选态和详情入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.163：Agent Session 详情关联知识点读取失败可恢复

输出：

- AgentSessionDetailScreen 关联知识点读取失败状态复用 `KnowledgeLibraryErrorState`。
- Agent Session 详情关联知识点读取失败状态支持重试当前 `knowledgePointProvider(targetId)`。
- Agent Session 详情关联知识点读取失败诊断包含记录 ID、目标 ID、目标标题和学习目标。

涉及文件：

```text
lib/features/agent/agent_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent Session 详情关联知识点读取失败时，可以直接重试读取知识点。
- 用户可以复制包含当前复盘和目标上下文的知识点读取失败诊断用于排查。
- Agent Session 详情的成功展示、加载态、追问动作和历史入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.164：面试复盘读取失败可恢复

输出：

- InterviewSessionDetailScreen 面试回合读取失败状态复用 `KnowledgeLibraryErrorState`。
- InterviewSessionDetailScreen 单轮引用片段读取失败状态复用 `KnowledgeLibraryErrorState`。
- 面试复盘读取失败诊断包含记录 ID，单轮引用读取失败诊断包含轮次、问题和引用 ID。

涉及文件：

```text
lib/features/agent/interview_session_detail_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在面试复盘回合读取失败时，可以直接重试读取当前复盘。
- 用户在单轮引用片段读取失败时，可以直接重试读取当前引用片段。
- 用户可以复制包含面试复盘和引用上下文的失败诊断用于排查。
- 面试复盘成功展示、加载态、分数摘要、反馈和引用块展示保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.165：答题引用读取失败可恢复

输出：

- QuizScreen 答题结果引用依据读取失败状态复用 `KnowledgeLibraryErrorState`。
- 答题引用依据读取失败状态支持重试当前题目的 `questionCitationChunksProvider(citationKey)`。
- 答题引用读取失败诊断包含题目 ID、题包 ID、题目内容、引用数量和引用 ID。

涉及文件：

```text
lib/features/learning/quiz_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在答题结果引用依据读取失败时，可以直接重试读取当前题目引用。
- 用户可以复制包含题目和引用上下文的失败诊断用于排查。
- 答题结果、解析、引用读取成功展示和答题流程保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.166：复习模式读取失败可恢复

输出：

- ReviewAgentScreen 今日复习队列读取失败状态复用 `KnowledgeLibraryErrorState`。
- ReviewAgentScreen 薄弱知识点读取失败状态复用 `KnowledgeLibraryErrorState`。
- 复习模式读取失败诊断包含入口和初始知识点上下文。
- 移除 ReviewAgentScreen 中已无调用点的 `_ErrorBlock`。

涉及文件：

```text
lib/features/agent/review_agent_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在复习模式今日复习队列读取失败时，可以直接重试刷新复习输入。
- 用户在复习模式薄弱知识点读取失败时，可以直接重试刷新复习输入。
- 用户可以复制包含初始知识点上下文的复习模式读取失败诊断用于排查。
- 复习模式成功展示、加载态、下拉刷新、主动复习和到期复习入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.167：导师模式读取与生成失败可恢复

输出：

- TutorSessionScreen 知识点读取失败状态复用 `KnowledgeLibraryErrorState`。
- TutorSessionScreen 导师讲解生成失败状态复用 `KnowledgeLibraryErrorState`。
- 导师模式失败诊断包含入口、知识点、知识点 ID、本轮追问和来源片段数。
- 移除 TutorSessionScreen 中已无调用点的 `_ErrorBlock`。

涉及文件：

```text
lib/features/agent/tutor_session_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在导师模式知识点读取失败时，可以直接重试读取有来源知识点。
- 用户在导师讲解生成失败时，可以直接重试当前知识点讲解。
- 用户可以复制包含知识点和追问上下文的导师模式失败诊断用于排查。
- 导师模式成功展示、加载态、来源引用块、重新讲解和追问入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.168：Agent Session 准备页预览读取失败可恢复

输出：

- AgentSessionLaunchScreen 证据预览读取失败状态提供重试和复制诊断。
- AgentSessionLaunchScreen 已核验题预览读取失败状态提供重试和复制诊断。
- 准备页预览读取失败诊断包含入口和知识点 ID。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent Session 准备页证据预览读取失败时，可以直接重试读取当前知识点证据。
- 用户在 Agent Session 准备页题目预览读取失败时，可以直接重试读取当前知识点题目。
- 用户可以复制包含知识点 ID 的准备页预览读取失败诊断用于排查。
- Agent Session 准备页成功展示、加载态、空状态、来源片段预览和题目预览入口保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.169：Agent Session 准备页历史上下文读取失败可恢复

输出：

- AgentSessionLaunchScreen 历史上下文读取失败状态复用 `KnowledgeLibraryErrorState`。
- 历史上下文读取失败状态支持重试刷新 `agentSessionListProvider` 和 `agentSessionMemoryIndexProvider`。
- 准备页历史上下文读取失败诊断包含入口、学习目标和当前目标。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent Session 准备页历史上下文读取失败时，可以直接重试读取历史上下文。
- 用户可以复制包含目标上下文的准备页历史读取失败诊断用于排查。
- 准备页读取历史成功、没有历史、未处理追问提示和启动流程保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.170：Agent Session 复盘保存失败可恢复

输出：

- AgentSessionLaunchScreen 记录复盘保存失败错误和失败时间。
- AgentSessionLaunchScreen 复盘保存失败后展示可重试、可复制诊断的恢复面板。
- 复盘保存失败诊断包含学习目标、目标、执行步骤、成功标准、追问、复盘笔记和失败时间。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在 Agent Session 复盘保存失败时，可以保留当前复盘内容并直接重新保存。
- 用户可以复制包含复盘上下文和失败时间的保存失败诊断用于排查。
- 新一轮 Agent Session 启动时会清空旧保存失败状态。
- Agent Session 保存成功、返回 Agent 和学习记录 schema 保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

### Leaf 12.171：题包列表读取失败可恢复

输出：

- DeckListScreen 题包列表读取失败状态复用 `KnowledgeLibraryErrorState`。
- 题包列表读取失败状态支持重试读取 `deckListProvider`。
- 题包列表读取失败诊断包含题库入口和当前搜索词。

涉及文件：

```text
lib/features/deck/deck_list_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户在题库页题包列表读取失败时，可以直接重试读取题包。
- 用户可以复制包含当前搜索词的题包读取失败诊断用于排查。
- 题包列表读取成功、搜索、空状态、导入入口、删除和进入答题保持原有行为。
- 不改变回答 prompt、summary 格式、引用读取或学习记录 schema。

## Branch 13：Agent Runtime Foundation

依赖：

- Branch 10。
- Branch 11。
- Branch 12 中已完成的错误恢复基础。

目的：把当前“确定性学习流程编排器”升级为一个轻量、本地优先、可解释、可追踪、可逐步扩展的 agent runtime。第一阶段不改变用户可见行为，不直接引入 Python 后端或重型框架。

架构结论：

```text
LangGraph-style state machine
+ OpenAI Agents SDK-style tool loop / handoffs / guardrails / sessions / tracing
+ Parlant-style behavior policy / source-grounding rules
+ AgentScope-style events / permissions / trace
```

本地 Dart 组件：

```text
LearningAgentState
LearningAgentStateDiagnostics
LearningAgentResumePolicy
LearningAgentResumeTraceContract
LearningAgentPlanner
LearningAgentToolRegistry
LearningAgentExecutor
LearningAgentPolicy
LearningAgentStateTransitionPolicy
LearningAgentTrace
LearningAgentMemoryStore
LearningAgentRuntimeContracts
LearningAgentRuntimeContractDiagnostics
LearningAgentRuntimeInterviewCard
LearningAgentInterviewPrompt
LearningAgentFrameworkMapping
LearningAgentRuntimeBoundaryNote
LearningAgentRuntimeEvidenceAnchor
LearningAgentRuntimeAnswerRubricItem
LearningAgentRuntimeSourceReference
```

### Leaf 13.1：记录 agent runtime 架构决策

输出：

- 新增 `docs/agent-runtime-architecture.md`。
- 明确当前 agent 不是完整 agent framework，而是学习流程编排器。
- 明确最合理的本地 Dart runtime 架构。
- 明确 LangGraph、OpenAI Agents SDK、Parlant、AgentScope、LangChain、CrewAI、AutoGen、Swarm、Microsoft Agent Framework、Genkit Dart、LangChain.dart 的取舍。

涉及文件：

```text
docs/agent-runtime-architecture.md
docs/trellis-execution-map.md
```

验收：

- 文档开头保留用户确认过的总结：LangGraph 风格状态机、OpenAI Agents SDK 风格工具循环、Parlant 风格学习规范/证据规则、AgentScope 风格事件权限 trace。
- 文档列出 `LearningAgentState`、`LearningAgentStateDiagnostics`、`LearningAgentResumePolicy`、`LearningAgentResumeTraceContract`、`LearningAgentPlanner`、`LearningAgentToolRegistry`、`LearningAgentExecutor`、`LearningAgentPolicy`、`LearningAgentStateTransitionPolicy`、`LearningAgentTrace`、`LearningAgentMemoryStore`、`LearningAgentRuntimeContracts`、`LearningAgentRuntimeContractDiagnostics`、`LearningAgentRuntimeInterviewCard`。
- 文档说明为什么当前不直接引入 Python agent 框架。
- 文档包含后续 runtime leaf 的推进顺序。

### Leaf 13.2：新增 LearningAgentState 模型

输出：

- 新增 agent state/phase/target/evidence/policy warning 数据结构。
- 先不接 UI，不改变现有学习路径行为。

涉及文件：

```text
lib/services/agent/learning_agent_state.dart
docs/trellis-execution-map.md
```

验收：

- 状态模型能表达 plan、retrieve、act、verify、reflect、complete、blocked 阶段。
- 状态模型能记录目标、推荐知识点、证据片段、待用户决策和策略警告。
- 不改变现有 provider、页面跳转或学习记录 schema。

### Leaf 13.3：新增 LearningAgentPolicy

输出：

- 新增来源约束、引用约束、正式学习约束的纯函数 policy 层。
- 先只提供检查结果，不拦截现有 UI。

涉及文件：

```text
lib/services/agent/learning_agent_policy.dart
docs/trellis-execution-map.md
```

验收：

- 能检查正式练习必须使用 verified questions。
- 能检查导师和面试必须绑定真实 source chunks。
- 能检查无来源或缺失引用时应要求补充来源。
- 不改变 prompt、AI 任务或页面跳转。

### Leaf 13.4：新增 LearningAgentTraceEvent

输出：

- 新增本地 trace event model。
- 暂不落库，先作为 runtime 返回结构。

涉及文件：

```text
lib/services/agent/learning_agent_trace.dart
docs/trellis-execution-map.md
```

验收：

- 能表达 plan_created、policy_checked、tool_selected、tool_started、tool_completed、tool_failed、evidence_attached、user_interrupted、session_resumed、reflection_saved。
- trace event 包含时间、session id、目标、事件类型和简短说明。
- 不改变现有学习记录 schema。

### Leaf 13.5：新增 LearningAgentToolRegistry 骨架

输出：

- 把现有导入、核验、检索、导师、面试、练习、复习、复盘保存声明为 tool metadata。
- 不移动页面执行逻辑。

涉及文件：

```text
lib/services/agent/learning_agent_tool_registry.dart
docs/trellis-execution-map.md
```

验收：

- 每个 tool 有 id、标题、描述、所需能力、证据要求和失败诊断标题。
- tool registry 可被 planner/executor 查询。
- 不改变现有 UI 行为。

### Leaf 13.6：引入 LearningAgentExecutor

输出：

- 新增 executor 接口和默认实现。
- 将 Agent Session 启动动作从 UI switch 逐步迁入 executor。

涉及文件：

```text
lib/services/agent/learning_agent_executor.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户点击启动 Agent Session 后的页面跳转和原行为保持一致。
- executor 返回可诊断的成功、取消、失败结果。
- UI 不再直接承担全部工具选择和执行细节。

### Leaf 13.7：执行前 policy gate

输出：

- executor 在启动工具前调用 `LearningAgentPolicy`。
- 对缺失来源、缺失引用、无 verified question 的路径返回可展示阻断原因。

涉及文件：

```text
lib/services/agent/learning_agent_executor.dart
lib/services/agent/learning_agent_policy.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 非法路径不会静默启动。
- 阻断原因能被 UI 显示和复制诊断。
- 已合法的导入、核验、导师、面试、练习、复习路径保持原行为。

### Leaf 13.8：记录本地 agent trace

输出：

- Agent Session 启动、工具完成、工具失败、复盘保存写入本地 trace。
- 第一版可先挂在 session summary 或内存结构，后续再独立建表。

涉及文件：

```text
lib/services/agent/learning_agent_trace.dart
lib/services/agent/learning_agent_executor.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户能在复盘或诊断中看到 agent 为什么启动该步骤。
- trace 包含所用目标、证据约束、工具结果和失败信息。
- 不改变正式学习来源规则。

### Leaf 13.9：新增 LearningAgentMemoryStore facade

输出：

- 新增 `LearningAgentMemoryStore`，把现有 `AgentSessionMemoryIndex` 包装成 runtime-facing 记忆接口。
- 新增 goal memory 和 target memory snapshot。
- plan provider 从 memory store 读取 goal memory 输入。

涉及文件：

```text
lib/services/agent/learning_agent_memory_store.dart
lib/core/providers/providers.dart
docs/trellis-execution-map.md
```

验收：

- planner 不再直接依赖 `AgentSessionMemoryIndex` 的具体查询方法。
- goal memory 能表达同目标记录数、未处理追问数和最近同目标记录。
- target memory 能表达同目标记录数、未处理追问数和最新未处理追问。
- Agent 首页、Agent Session 准备页、历史页和详情页既有行为保持不变。

### Leaf 13.10：新增 LearningAgentRuntime facade

输出：

- 新增 `LearningAgentRuntime`，负责准备一次 Agent Session 的 session id、初始 state、可用工具和 plan_created trace。
- 新增 `learningAgentRuntimeProvider`。
- Agent Session 准备页通过 runtime session 创建 executor context。

涉及文件：

```text
lib/services/agent/learning_agent_runtime.dart
lib/services/agent/learning_agent_executor.dart
lib/features/agent/agent_session_launch_screen.dart
lib/core/providers/providers.dart
docs/trellis-execution-map.md
```

验收：

- runtime 能生成带 `LearningAgentState` 的 Agent Session 初始运行上下文。
- executor trace 能延续 runtime 生成的 `plan_created` 事件。
- Agent Session 启动、阻断、失败、完成和复盘保存行为保持原有用户路径。
- 不引入后端、云同步、向量数据库或重型 agent 框架。

### Leaf 13.11：Executor 复用 LearningAgentMemoryStore

输出：

- `LearningAgentExecutor` 启动导师/面试前，通过 `LearningAgentMemoryStore` 读取目标级最新未处理追问。
- 保留 `AgentSessionCompletionMatcher` 作为完成追问检测逻辑。

涉及文件：

```text
lib/services/agent/learning_agent_executor.dart
docs/trellis-execution-map.md
```

验收：

- executor 不再直接读取 `agentSessionMemoryIndexProvider.future` 来获取目标追问。
- 导师和面试启动时仍能收到同一条最新未处理追问。
- 追问完成检测行为保持不变。
- 不改变 Agent Session UI、summary 格式或学习记录 schema。

### Leaf 13.12：Executor provider 边界

输出：

- 新增 `learningAgentExecutorProvider`。
- Agent Session 准备页通过 provider 读取 `LearningAgentExecutor` 抽象接口。
- 移除准备页对 `DefaultLearningAgentExecutor` 的直接构造。

涉及文件：

```text
lib/core/providers/providers.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- UI 不再直接选择 executor 默认实现。
- 当前默认 executor 行为保持不变。
- Agent Session 启动、阻断、失败、完成和复盘保存路径保持不变。
- 不引入后端、云同步、向量数据库或重型 agent 框架。

### Leaf 13.13：Agent runtime provider 依赖边界

输出：

- 新增 `learning_agent_providers.dart`，集中暴露 `learningAgentRuntimeProvider` 和 `learningAgentExecutorProvider`。
- 从核心 `providers.dart` 移除 executor/runtime provider。
- Agent Session 准备页改为从 agent 专属 provider 文件读取 runtime/executor provider。

涉及文件：

```text
lib/services/agent/learning_agent_providers.dart
lib/core/providers/providers.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- `providers.dart` 不再 import `learning_agent_executor.dart` 或 `learning_agent_runtime.dart`。
- `learning_agent_executor.dart` 仍可读取核心 provider，不形成 core provider 和 executor 的双向 import。
- UI 仍通过 provider 读取 runtime/executor。
- 当前 Agent Session 启动行为保持不变。

### Leaf 13.14：完成复盘展示 Agent Trace

输出：

- Agent Session 准备页完成学习返回后，在复盘保存前展示本轮执行轨迹。
- 轨迹行展示事件类型、摘要、时间、证据数量和策略问题数量。
- 仍然在保存复盘时把完整 trace 写入 summary。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 用户完成 Agent Session 后，不必先保存并进入详情页，也能看到本轮 agent 为什么执行该步骤。
- 轨迹预览不改变复盘输入、成功标准勾选、保存和返回流程。
- 保存后的 Agent Session 详情页仍能显示完整 Agent Trace。
- 不改变 learning_sessions schema 或正式学习来源规则。

### Leaf 13.15：集中 Agent Trace 文本格式

输出：

- 在 `LearningAgentTrace` 附近集中定义 `Agent Trace:` header、`Trace:` 行格式、时间格式和单行摘要清洗。
- Agent Session summary 保存、executor 失败诊断、completion save 诊断复用同一套 trace formatter。
- Agent Session 记忆索引解析复用同一 header 常量。

涉及文件：

```text
lib/services/agent/learning_agent_trace.dart
lib/services/agent/learning_agent_executor.dart
lib/services/agent/agent_session_memory_index.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- summary 保存和失败诊断使用同一个 canonical trace 文本格式。
- 已保存的 Agent Session 仍能通过 `Agent Trace:` 解析出 trace lines。
- 完成复盘面板的结构化 Agent Trace 预览保持不变。
- 不改变 learning_sessions schema 或正式学习来源规则。

### Leaf 13.16：新增 Agent Trace Recorder

输出：

- 新增 `LearningAgentTraceRecorder`，集中维护当前 Agent Session 的 trace event 列表。
- recorder 在记录事件时同步更新 runtime state 的 phase、evidence context 和 `traceEventIds`。
- `LearningAgentExecutor` 改为通过 recorder 记录 tool selected、policy checked、tool started、tool completed、tool failed 等事件。
- `LearningAgentExecutionResult` 返回可选 runtime state，为后续 trace sink、session resume 或独立 trace 表保留入口。
- Agent Session 准备页保留最新 runtime state，并在诊断中展示当前 agent 阶段。

涉及文件：

```text
lib/services/agent/learning_agent_trace.dart
lib/services/agent/learning_agent_executor.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- executor 不再直接手动维护可变 `traceEvents` 列表。
- 阻断、失败、取消和完成路径仍返回完整 trace event 列表。
- 返回结果能携带 recorder 更新后的 runtime state。
- Agent Session 诊断能显示最新 runtime phase。
- 不改变 Agent Session UI、learning_sessions schema 或正式学习来源规则。

### Leaf 13.17：集中 Agent state transition policy

输出：

- 新增 `LearningAgentStateTransitionPolicy`，集中表达 runtime phase 转换规则。
- executor 不再直接决定 policy check、tool start、tool result、tool failure 后进入哪个 phase。
- 完成但不需要复盘面板的路径进入 `complete`，需要复盘面板的路径进入 `reflect`。

涉及文件：

```text
lib/services/agent/learning_agent_state_transition_policy.dart
lib/services/agent/learning_agent_executor.dart
docs/trellis-execution-map.md
```

验收：

- phase 转换规则是纯 Dart 服务，不依赖 Flutter UI 或 Navigator。
- policy 阻断进入 `blocked`，policy 通过进入 `verify`，工具启动进入 `act`。
- 工具取消保持 `act`，工具失败进入 `blocked`。
- 完成路径能根据是否需要复盘进入 `reflect` 或 `complete`。
- 不改变 Agent Session UI、learning_sessions schema 或正式学习来源规则。

### Leaf 13.18：集中 Agent runtime state diagnostics

输出：

- 新增 `learningAgentStateDiagnosticLines`，统一格式化 runtime state 的 phase、tool、available tools、evidence、policy warnings、trace count 和目标 ID。
- executor 的 policy 阻断和异常失败诊断复用 state diagnostics。
- Agent Session 准备页的保存失败和执行失败诊断复用 state diagnostics，并避免重复输出。

涉及文件：

```text
lib/services/agent/learning_agent_state_diagnostics.dart
lib/services/agent/learning_agent_executor.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- state diagnostic formatter 不依赖 Flutter UI 或 Navigator。
- 阻断、失败和保存失败诊断都能显示统一的 runtime state 快照。
- 执行失败诊断不会重复显示 state diagnostic lines。
- 不改变 Agent Session UI、learning_sessions schema 或正式学习来源规则。

### Leaf 13.19：Agent Session resume readiness

输出：

- 新增 `LearningAgentResumePolicy`，判断 runtime state 是否可恢复。
- 定义 ready、waitingForUser、missingState、missingTool、missingEvidence、completed、blocked 等恢复状态。
- 新增 resume readiness 诊断行，显示恢复状态、是否可恢复和恢复提示。
- executor 的 policy 阻断和异常失败诊断加入 resume readiness。
- Agent Session 准备页的保存失败和执行失败诊断加入 resume readiness，并避免重复输出。

涉及文件：

```text
lib/services/agent/learning_agent_resume_policy.dart
lib/services/agent/learning_agent_executor.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- resume readiness policy 是纯 Dart 服务，不依赖 Flutter UI、Navigator 或数据库。
- 已完成、已阻断、缺 state、缺 tool、缺证据的 state 不会被标记为可恢复。
- 等待用户决策的 state 会标记为可恢复但需要用户决策。
- 诊断输出能说明当前 state 是否可恢复和原因。
- 不真正启用恢复入口，不改变 Agent Session UI、learning_sessions schema 或正式学习来源规则。

### Leaf 13.20：Agent resume trace event contract

输出：

- 新增 `LearningAgentResumeTraceContract`，定义未来恢复时如何生成 `session_resumed` trace event。
- 新增 `LearningAgentResumeTraceDraft`，在不记录事件的前提下表达 readiness、待记录事件和原 trace id 保留列表。
- `session_resumed` detail 固定包含恢复状态、恢复原因、原阶段、工具、原 trace 数量、最近 trace id、证据数量和策略警告。
- `LearningAgentRuntime` 暴露 `draftResumeTrace`，只生成恢复 trace 草稿，不启用恢复入口。

涉及文件：

```text
lib/services/agent/learning_agent_resume_trace_contract.dart
lib/services/agent/learning_agent_runtime.dart
docs/trellis-execution-map.md
```

验收：

- resume trace contract 是纯 Dart 服务，不依赖 Flutter UI、Navigator 或数据库。
- 只有 `LearningAgentResumePolicy` 判定可恢复的 state 才会生成 `session_resumed` trace event。
- 不可恢复 state 返回 draft 但不生成 event。
- 生成的 event 保留原 session id、goal、phase、target id、tool id、evidence ids 和 policy warning codes。
- 不真正记录恢复事件，不改变 Agent Session UI、learning_sessions schema 或正式学习来源规则。

### Leaf 13.21：Agent runtime contract barrel

输出：

- 新增 `learning_agent_runtime_contracts.dart`，作为 feature 层读取 Agent runtime contract 的统一入口。
- barrel 导出 planner、runtime、executor interface、provider、state、trace、tool registry、resume policy、resume trace contract 和 diagnostics。
- Agent Session launch/home/detail/history 页面改为通过 barrel 导入 runtime contract。
- 服务层内部继续使用直接 import，避免 barrel 反向影响内部依赖边界。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_contracts.dart
lib/features/agent/agent_session_launch_screen.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_detail_screen.dart
lib/features/agent/agent_session_history_screen.dart
docs/trellis-execution-map.md
```

验收：

- feature 层不再直接 import 多个 `learning_agent_*` runtime contract 文件。
- `AgentSessionLaunchScreen` 的 runtime contract imports 收敛为一个 barrel import。
- barrel 不导出 `DefaultLearningAgentExecutor` concrete class 给 feature 层。
- 不改变 Agent Session UI、learning_sessions schema、provider 行为或正式学习来源规则。

### Leaf 13.22：Agent runtime contract diagnostics coverage

输出：

- 新增 `learningAgentRuntimeContractChecklistLines`，输出可复制的 runtime contract checklist。
- checklist 覆盖 state、goal、tool、source evidence requirement、evidence context、trace count、resume readiness、provider boundary 和 feature import boundary。
- executor 的 policy 阻断和异常失败诊断加入 runtime contract checklist。
- Agent Session 准备页的保存失败和执行失败诊断加入 runtime contract checklist，并避免重复输出。
- barrel 导出 runtime contract diagnostics，feature 层继续通过统一 contract 入口读取。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_contract_diagnostics.dart
lib/services/agent/learning_agent_runtime_contracts.dart
lib/services/agent/learning_agent_executor.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- runtime contract checklist 是纯 Dart formatter，不依赖 Flutter UI、Navigator 或数据库。
- 复制诊断能解释当前运行是否具备 state、tool、source/evidence、trace、resume 和 provider/import contract。
- 执行失败诊断不会重复显示 runtime contract checklist lines。
- 不改变 Agent Session UI、learning_sessions schema、provider 行为或正式学习来源规则。

### Leaf 13.23：Agent runtime interview explanation card

输出：

- 新增 `learningAgentRuntimeInterviewCard`，从 plan/state/trace 生成面试讲解卡片内容。
- 卡片内容说明本地 runtime 的 planner、policy、executor、state、trace 和来源约束。
- Agent Session 准备页在规则卡后展示“面试讲法：本地学习 Agent”。
- 卡片显示目标、工具、阶段、trace 数量和 4 条面试讲法。
- 卡片标注依据 `learning_agent_runtime_contracts.dart` 和 `docs/agent-runtime-architecture.md`。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/services/agent/learning_agent_runtime_contracts.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 面试讲解内容由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- Agent Session 准备页能直接看到当前计划对应的 agent 架构讲法。
- 卡片不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。
- 卡片内容有本地代码/架构文档依据提示。

### Leaf 13.24：Agent runtime interview prompts

输出：

- `LearningAgentRuntimeInterviewCard` 新增 `prompts` 字段。
- `learningAgentRuntimeInterviewCard` 生成 5 条 runtime 架构自测追问。
- 追问覆盖为什么不直接接入外部 agent 框架、如何避免胡说、executor/tool/provider 边界、session 中断恢复、后端/向量检索迁移边界。
- Agent Session 准备页的面试讲解卡展示前 4 条自测追问。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 自测追问由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- Agent Session 准备页能直接看到 runtime 架构讲解后的追问练习。
- 追问内容围绕当前 tool 和本地 runtime contract，而不是泛泛的 agent 概念。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.25：Agent runtime answer outline

输出：

- 新增 `LearningAgentInterviewPrompt`，把自测追问升级为 question + outline。
- `learningAgentRuntimeInterviewCard` 为 5 条 runtime 架构追问生成简短答题提纲。
- Agent Session 准备页在每条自测追问下展示“提纲”。
- 提纲覆盖本地 runtime 取舍、来源约束、防幻觉、executor/tool/provider 边界、恢复方案和未来迁移边界。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 提纲由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- Agent Session 准备页能直接看到追问和简短回答提纲。
- 提纲内容围绕当前 tool 和本地 runtime contract。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.26：Copyable Agent runtime interview notes

输出：

- 新增 `learningAgentRuntimeInterviewCardCopyText`，把面试讲法卡转成可复制文本。
- 复制文本包含标题、摘要、标签、讲法、自测追问、答题提纲和依据。
- Agent Session 准备页的面试讲法卡右上角新增复制按钮。
- 复制成功后显示轻量反馈，方便用户把 runtime 讲法带到外部复习或面试稿里。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 复制文本由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 复制内容覆盖完整 5 条自测追问和对应提纲，即使页面只预览前 4 条。
- UI 只新增复制动作，不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。
- 面试讲法卡仍保留代码和架构文档依据提示。

### Leaf 13.27：Agent runtime framework mapping

输出：

- 新增 `LearningAgentFrameworkMapping`，把外部 agent 框架思想映射到本地 runtime 组件。
- `learningAgentRuntimeInterviewCard` 增加 LangGraph、OpenAI Agents SDK、Parlant、AgentScope 四条框架借鉴说明。
- Agent Session 准备页的面试讲法卡展示“框架借鉴”区域。
- 复制版面试讲法同步包含框架借鉴说明，方便回答“为什么没有直接套框架，但仍按 agent 架构设计”。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 框架映射由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 映射内容明确连接外部框架思想和本地 Dart runtime contract。
- 页面展示和复制文本都覆盖 LangGraph、OpenAI Agents SDK、Parlant、AgentScope 四类借鉴。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.28：Agent runtime boundary notes

输出：

- 新增 `LearningAgentRuntimeBoundaryNote`，把当前 runtime 尚未完成的边界转成面试安全讲法。
- `learningAgentRuntimeInterviewCard` 增加自治程度、恢复能力、知识检索、框架依赖四条边界说明。
- Agent Session 准备页的面试讲法卡展示“当前边界”区域。
- 复制版面试讲法同步包含边界说明，避免把本地 runtime 夸成已经完全自治、已持久恢复或已接入向量检索的 agent。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 边界说明由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面展示和复制文本都覆盖自治程度、恢复能力、知识检索、框架依赖四类边界。
- 每条边界同时包含当前事实和可用于面试的安全讲法。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.29：Agent runtime code evidence anchors

输出：

- 新增 `LearningAgentRuntimeEvidenceAnchor`，把 runtime 架构讲法映射到本地代码文件。
- `learningAgentRuntimeInterviewCard` 增加状态机、executor、policy、trace 四条代码依据。
- Agent Session 准备页的面试讲法卡展示“代码依据”区域。
- 复制版面试讲法同步包含代码依据，方便用户把“我这样设计”的说法落到真实项目文件。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 代码依据由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面展示和复制文本都覆盖 state、executor、policy、trace 四类 runtime 依据。
- 每条依据同时包含架构 claim、代码路径和支撑理由。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.30：Agent runtime 60-second answer script

输出：

- `LearningAgentRuntimeInterviewCard` 新增 `answerScript`，生成一段可直接练习的 60 秒 runtime 面试讲法。
- 讲法动态包含当前学习目标、当前工具、runtime phase、trace 数量和证据上下文数量。
- Agent Session 准备页的面试讲法卡展示“60 秒讲法”区域。
- 复制版面试讲法同步包含 60 秒讲法，方便用户直接带到外部面试稿或复习材料。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 60 秒讲法由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面展示和复制文本都包含同一段 answer script。
- 脚本明确当前实现是本地学习 runtime，不夸大为自由聊天机器人或完全自治 agent。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.31：Agent runtime answer rubric

输出：

- 新增 `LearningAgentRuntimeAnswerRubricItem`，把 runtime 面试回答拆成可自查的评分点。
- `learningAgentRuntimeInterviewCard` 增加本地优先、来源约束、runtime contract、诚实边界四条回答检查。
- Agent Session 准备页的面试讲法卡展示“回答检查”区域。
- 复制版面试讲法同步包含回答检查，方便用户在外部复习时判断回答是否完整。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 回答检查由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面展示和复制文本都覆盖本地优先、来源约束、runtime contract、诚实边界四类检查点。
- 每条检查点同时包含达标信号和容易失分点。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.32：Copy 60-second runtime answer

输出：

- 新增 `learningAgentRuntimeAnswerScriptCopyText`，单独格式化 60 秒讲法和回答检查。
- Agent Session 准备页的“60 秒讲法”标题右侧新增复制按钮。
- 复制成功后提示“已复制 60 秒讲法和回答检查”。
- 保留整张面试讲法卡的复制按钮，用户可以选择复制完整材料或只复制短回答。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 60 秒讲法复制文本由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 单独复制内容包含 answer script、回答检查和依据提示。
- 不移除或改变完整面试讲法复制动作。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.33：Agent runtime external source references

输出：

- 新增 `LearningAgentRuntimeSourceReference`，把外部框架借鉴对应到来源标题、URL 和支撑内容。
- `learningAgentRuntimeInterviewCard` 增加 LangGraph、OpenAI Agents SDK、Parlant、AgentScope 四条外部来源。
- Agent Session 准备页的面试讲法卡展示“外部来源”区域。
- 完整复制材料包含独立“外部来源”区块；60 秒讲法复制文本把外部来源并入依据。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 外部来源由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面展示和复制文本都覆盖 LangGraph、OpenAI Agents SDK、Parlant、AgentScope 四类来源。
- 每条来源同时包含标题、URL 和支撑的架构借鉴点。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.34：Agent runtime source trust labels

输出：

- `LearningAgentRuntimeSourceReference` 增加 `sourceType` 和 `trustNote`。
- LangGraph、OpenAI Agents SDK、Parlant、AgentScope 四条来源分别标注官方文档、官方 SDK 文档、项目文档、项目仓库。
- Agent Session 准备页的“外部来源”区域展示来源类型和可信度说明。
- 完整复制材料保留独立“外部来源”区块，60 秒讲法复制文本在“依据”中包含外部来源。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 来源可信度说明由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面展示和复制文本都包含来源类型和可信度说明。
- 完整复制材料不会重复输出同一批外部来源。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.35：Agent runtime source verification metadata

输出：

- `LearningAgentRuntimeSourceReference` 增加 `verifiedAt` 和 `evidenceNote`。
- LangGraph、OpenAI Agents SDK、Parlant、AgentScope 四条来源标注 2026-07-09 调研日期。
- 外部来源引用记录 `docs/agent-runtime-architecture.md` 和 Smart Search evidence 路径。
- Agent Session 准备页的“外部来源”区域展示核验日期和证据说明。
- 完整复制材料和 60 秒讲法复制文本都包含来源核验元数据。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 来源核验元数据由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面展示和复制文本都包含核验日期、证据说明、来源类型和可信度说明。
- 核验日期对应 `docs/agent-runtime-architecture.md` 中记录的调研日期。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.36：Agent runtime interview compact sections

输出：

- Agent Session 准备页的 runtime 面试卡片新增 `_RuntimeCompactSection`。
- 回答检查、讲法要点、框架映射、当前边界、代码依据、外部来源、自测追问改为带数量和摘要的折叠 section。
- 60 秒讲法和复制入口保持默认可见，方便快速复习。
- 各 section 展开后展示完整列表，不再使用 `take(4)` 截断学习材料。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 默认页面的信息密度降低，但完整复制材料和 60 秒讲法复制文本不受影响。
- 外部来源展开后仍包含来源类型、可信度说明、核验日期、证据说明和 URL。
- 回答检查默认展开，关键面试自查信息仍优先可见。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.37：Agent runtime interview Q&A copy packet

输出：

- 新增 `learningAgentRuntimeQuestionAnswerPackCopyText`。
- Q&A 练习包包含 60 秒总答、自测问答、回答检查、代码依据、外部来源和依据说明。
- Agent Session 准备页的 runtime 面试卡片新增“复制面试 Q&A 包”按钮。
- 复制成功后显示“已复制面试 Q&A 练习包”提示。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- Q&A 包由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- Q&A 包中的外部来源仍包含来源类型、可信度说明、核验日期、证据说明和 URL。
- 完整面试材料复制和 60 秒讲法复制保持原行为。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.38：Agent runtime interview prompt evidence hints

输出：

- `LearningAgentInterviewPrompt` 增加 `evidenceHint`。
- 5 条 Agent runtime 自测追问都补充作答时可引用的代码文件、架构文档或外部来源。
- 完整面试材料复制和 Q&A 练习包复制都包含每题证据提示。
- Agent Session 准备页的自测追问展示“证据”行。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 每条自测追问都有问题、提纲和证据提示三部分。
- 证据提示由纯 Dart formatter 输出，不依赖 Flutter UI、Navigator 或数据库。
- Q&A 包可直接用于“先自答、再对照证据补齐”的面试练习。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.39：Agent runtime interview evidence coverage summary

输出：

- 新增 `learningAgentRuntimeEvidenceCoverageSummary`。
- 完整面试材料复制、60 秒讲法复制和 Q&A 练习包复制都包含“证据覆盖”摘要。
- Agent Session 准备页的 runtime 面试卡片在摘要后展示证据覆盖行。
- 覆盖摘要统计代码依据数量、外部来源数量和带证据提示的自测题数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 证据覆盖摘要由纯 Dart helper 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面和三个复制出口使用同一覆盖摘要口径。
- 覆盖摘要能帮助用户确认面试材料不是无依据讲法，而是连接到代码、外部来源和自测证据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.40：Agent runtime interview prompt sample answers

输出：

- `LearningAgentInterviewPrompt` 增加 `sampleAnswer`。
- 5 条 Agent runtime 自测追问都补充可直接练习的参考答法。
- 完整面试材料复制和 Q&A 练习包复制都包含每题参考答法。
- Agent Session 准备页的自测追问展示“参考答法”行。
- 证据覆盖摘要增加带参考答法的自测题数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 每条自测追问都有问题、提纲、参考答法和证据提示四部分。
- 参考答法围绕本地 runtime、来源约束、工具边界、恢复方案和未来迁移边界，不夸大当前能力。
- Q&A 包可直接用于“先自答、再对照参考答法和证据提示补齐”的面试练习。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.41：Agent runtime interview prompt self-check criteria

输出：

- `LearningAgentInterviewPrompt` 增加 `selfCheck`。
- 5 条 Agent runtime 自测追问都补充可自评的达标标准。
- 完整面试材料复制和 Q&A 练习包复制都包含每题自评标准。
- Agent Session 准备页的自测追问展示“自评”行。
- 证据覆盖摘要增加带自评标准的自测题数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 每条自测追问都有问题、提纲、参考答法、自评标准和证据提示五部分。
- 自评标准能帮助用户检查是否讲到核心架构点、来源约束和诚实边界。
- Q&A 包可直接用于“先自答、再按自评标准补齐”的面试练习。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.42：Agent runtime interview practice flow

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `practiceSteps`。
- 新增 `LearningAgentRuntimePracticeStep`，描述练习步骤、动作和达标信号。
- 默认练习流程包含先自答、对照参考、核对证据、压缩复述 4 步。
- 完整面试材料复制和 Q&A 练习包复制都包含练习流程。
- Agent Session 准备页的 runtime 面试卡片新增“练习流程”折叠 section。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 练习流程由纯 Dart 数据和 formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 页面和复制材料使用同一套练习步骤、动作和达标信号。
- 练习流程能把自测题、参考答法、自评标准和证据提示串成可执行学习方法。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.43：Agent runtime interview blind drill copy

输出：

- 新增 `learningAgentRuntimeBlindDrillCopyText`。
- 面试盲练稿包含证据覆盖、练习流程、盲练题、自评标准、证据提示和回答检查。
- 盲练题保留“我的回答”和“修正后答案”空位，不直接输出参考答法。
- Agent Session 准备页的 runtime 面试卡片新增“复制面试盲练稿”按钮。
- 复制成功后显示“已复制面试盲练稿”提示。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 盲练稿由纯 Dart formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 盲练稿不包含 `sampleAnswer`，避免主动回忆阶段直接暴露参考答案。
- Q&A 包、完整面试材料和 60 秒讲法复制保持原行为。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.44：Agent runtime interview copy action menu

输出：

- Agent Session 准备页的 runtime 面试卡片把完整讲法、Q&A 包、盲练稿三个复制动作收敛到一个菜单。
- 新增 `_RuntimeInterviewCopyAction`，明确三个复制动作的枚举边界。
- 新增 `_RuntimeCopyMenuItem`，统一复制菜单项图标和文本样式。
- 60 秒讲法复制按钮继续保留在“60 秒讲法”区域。

涉及文件：

```text
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 卡片标题行只保留一个“复制面试材料”菜单入口，降低窄屏拥挤风险。
- 完整讲法、Q&A 包、盲练稿和 60 秒讲法复制行为保持可用。
- 不改变任何纯 Dart formatter、Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.45：Agent runtime interview glossary terms

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `glossaryTerms`。
- 新增 `LearningAgentRuntimeGlossaryTerm`，包含术语、定义和面试用法。
- 默认术语覆盖 Planner、Policy gate、Tool registry、Executor、Trace、Runtime state。
- 完整面试材料复制和 Q&A 练习包复制都包含“术语速记”。
- Agent Session 准备页的 runtime 面试卡片新增“术语速记”折叠 section。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
```

验收：

- 术语速记由纯 Dart 数据和 formatter 生成，不依赖 Flutter UI、Navigator 或数据库。
- 每个术语都有定义和面试用法，帮助用户把 agent 架构词汇讲清楚。
- 页面和复制材料使用同一组术语数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.46：Agent runtime interview pitfall guardrails

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `pitfalls`。
- 新增 `LearningAgentRuntimePitfall`，包含风险说法、更稳妥说法和原因。
- 默认避坑覆盖外部框架依赖、完全自治、完整 RAG/vector DB、AI 输出直接入库四类容易夸大的说法。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“避坑清单”。
- Agent Session 准备页的 runtime 面试卡片新增“避坑清单”折叠 section。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每条避坑都能把 risky claim 转成 safer claim，并解释为什么这样讲更符合当前实现。
- 避坑清单由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 面试口径明确区分 design reference、current implementation 和 future migration。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.47：Agent runtime framework evolution roadmap

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `evolutionSteps`。
- 新增 `LearningAgentRuntimeEvolutionStep`，包含里程碑、当前基础、下一步升级和面试讲法。
- 默认演进路线覆盖状态图标准化、工具循环增强、来源检索升级和可观测复盘四步。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“演进路线”。
- Agent Session 准备页的 runtime 面试卡片新增“演进路线”折叠 section。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个演进步骤都说明当前已有基础、下一步升级方向和面试时如何表达。
- 演进路线由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 面试口径能回答“为什么现在不直接用重 agent 框架”和“后续如何迁移到标准 agent 架构”。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.48：Agent runtime architecture decision records

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `decisionRecords`。
- 新增 `LearningAgentRuntimeDecisionRecord`，包含决策、原因、代价和面试讲法。
- 默认架构决策覆盖 Flutter/Dart 本地 runtime、确定性 planner + policy gate、source-grounded learning 优先、trace-first runtime 四类取舍。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“架构决策”。
- Agent Session 准备页的 runtime 面试卡片新增“架构决策”折叠 section。
- 证据覆盖摘要展示架构决策数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每条架构决策都说明为什么当前先采用轻量本地 runtime，以及这个选择付出的代价。
- 面试口径能回答“为什么没有直接按成熟 agent 框架落地”。
- 架构决策由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.49：Agent runtime framework migration triggers

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `migrationTriggers`。
- 新增 `LearningAgentRuntimeMigrationTrigger`，包含触发条件、当前信号、升级动作和面试讲法。
- 默认迁移触发条件覆盖长任务恢复、工具失败路径增多、来源语义召回瓶颈、agent 决策质量评估四类升级信号。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“迁移触发条件”。
- Agent Session 准备页的 runtime 面试卡片新增“迁移触发条件”折叠 section。
- 证据覆盖摘要展示迁移触发条件数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个迁移触发条件都说明当前已有信号、需要升级的动作和面试讲法。
- 面试口径能回答“什么时候才值得从本地 runtime 升级到更重的 agent 框架”。
- 迁移触发条件由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.50：Agent runtime maturity ladder

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `maturityLevels`。
- 新增 `LearningAgentRuntimeMaturityLevel`，包含层级、已实现信号、能力缺口、下一层里程碑和面试讲法。
- 默认成熟度阶梯覆盖受控学习编排器、来源约束学习 agent、可恢复状态图 runtime、可评估 agent 系统四层。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“成熟度阶梯”。
- Agent Session 准备页的 runtime 面试卡片新增“成熟度阶梯”折叠 section。
- 证据覆盖摘要展示成熟度层级数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个成熟度层级都说明已实现信号、能力缺口、下一层里程碑和面试讲法。
- 面试口径能回答“当前 agent runtime 到底成熟到哪一层，还缺什么”。
- 成熟度阶梯由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.51：Agent runtime framework selection matrix

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `frameworkSelections`。
- 新增 `LearningAgentRuntimeFrameworkSelection`，包含框架、适合场景、当前不直接采用的原因、未来接入路径和面试讲法。
- 默认选型矩阵覆盖 LangGraph、OpenAI Agents SDK、Parlant、AgentScope。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“框架选型”。
- Agent Session 准备页的 runtime 面试卡片新增“框架选型”折叠 section。
- 证据覆盖摘要展示框架选型项数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个框架选型项都说明适合场景、当前不直接采用的原因、未来接入路径和面试讲法。
- 面试口径能回答“这些 agent 框架分别适合什么，为什么当前项目先不直接接入”。
- 框架选型矩阵由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.52：Agent runtime code walkthrough route

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `codeWalkthroughSteps`。
- 新增 `LearningAgentRuntimeCodeWalkthroughStep`，包含走读步骤、文件路径、看点和面试讲法。
- 默认代码走读路线覆盖 Agent Session 准备页、planner、tool registry、policy gate、executor、state + trace。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“代码走读路线”。
- Agent Session 准备页的 runtime 面试卡片新增“代码走读路线”折叠 section。
- 证据覆盖摘要展示代码走读步数。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个走读步骤都说明要看哪个文件、看什么实现点、面试时如何讲。
- 面试口径能按文件顺序把 runtime 从 UI 入口讲到 planner、tool、policy、executor、state 和 trace。
- 代码走读路线由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.53：Agent runtime debugging scenarios

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `debugScenarios`。
- 新增 `LearningAgentRuntimeDebugScenario`，包含场景、可能原因、排查路径、修复策略和面试讲法。
- 默认调试场景覆盖 planner 选错工具、policy gate 误拦截、executor 启动或完成失败、state/trace 不一致、来源引用或 evidence IDs 不完整。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“调试场景”。
- Agent Session 准备页的 runtime 面试卡片新增“调试场景”折叠 section。
- 证据覆盖摘要展示调试场景数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个调试场景都说明故障现象、可能原因、排查文件路径、修复策略和面试讲法。
- 调试口径能把 runtime 故障从症状追到 planner、tool registry、policy、executor、state、trace 或 evidence ID 链路。
- 调试场景由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.54：Agent runtime debugging drill copy packet

输出：

- 新增 `learningAgentRuntimeDebugDrillCopyText`，生成专门的 runtime 调试练习文本。
- 调试练习包含练习方式、证据覆盖、调试盲练、代码走读路线、代码依据和来源说明。
- 每个调试盲练题保留“我的判断”和“修正后复述”空位，方便主动回忆。
- Agent Session 准备页复制菜单新增“复制调试练习”。
- 调试练习复用 `debugScenarios`、`codeWalkthroughSteps`、`evidenceAnchors` 和 `sourceNotes`，不新增并行数据源。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 调试练习可从准备页复制菜单直接触发。
- 复制文本能帮助用户按“故障 -> 判断 -> 排查 -> 修复 -> 复述”练习 runtime 调试回答。
- 调试练习由纯 Dart formatter 生成，复用已有调试场景和代码依据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.55：Agent runtime interview demo script

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `demoSteps`。
- 新增 `LearningAgentRuntimeDemoStep`，包含演示时刻、app 操作、讲法和证据点。
- 默认演示脚本覆盖 Agent 目标入口、来源约束、受控工具执行、代码走读/调试场景、trace 复盘。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“演示脚本”。
- Agent Session 准备页的 runtime 面试卡片新增“演示脚本”折叠 section。
- 证据覆盖摘要展示演示脚本步数。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个演示步骤都说明现场该做什么、怎么讲、指向哪个证据点。
- 演示口径能把 app 内学习方法、source-grounding、tool loop、代码走读和 trace 复盘串起来。
- 演示脚本由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.56：Agent runtime source-grounding audit checklist

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `sourceGroundingChecks`。
- 新增 `LearningAgentRuntimeSourceGroundingCheck`，包含核验项、核验路径、通过信号、失败处理和面试讲法。
- 默认来源核验清单覆盖 AI 草稿边界、已核验题目、导师/面试来源片段、citation id 可读性、外部框架官方来源。
- 完整面试材料、Q&A 练习包、盲练稿和调试练习复制都包含“来源核验清单”。
- Agent Session 准备页的 runtime 面试卡片新增“来源核验清单”折叠 section。
- 证据覆盖摘要展示来源核验项数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个来源核验项都说明查哪里、怎样算通过、失败时如何处理、面试如何表达。
- 清单能把“知识正确且有来源依据”落到 review、policy、verified questions、source chunks、citation IDs 和外部来源记录。
- 来源核验清单由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.57：Agent runtime interview answer frames

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `answerFrames`。
- 新增 `LearningAgentRuntimeAnswerFrame`，包含问题类型、开场主张、要提到的证据、需要说明的边界和收束句。
- 默认回答框架覆盖项目总览、为什么不直接用重 agent 框架、如何保证来源正确、如何调试 agent 行为、未来演进。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“回答框架”。
- Agent Session 准备页的 runtime 面试卡片新增“回答框架”折叠 section。
- 证据覆盖摘要展示回答框架数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个回答框架都说明如何开场、引用哪些证据、承认哪些边界、最后如何收束。
- 回答框架能帮助用户把 runtime 材料按不同面试问题组织成稳定口径。
- 回答框架由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.58：Agent runtime interview challenge responses

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `challengeResponses`。
- 新增 `LearningAgentRuntimeChallengeResponse`，包含面试质疑、短答、可展示证据、诚实边界和拉回主线。
- 默认追问应对覆盖“这是不是只是页面流程”、为什么不用重 agent 框架、AI 如何避免胡说、是否真的理解 vibe coding 代码、如何扩展成知识库 agent。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“追问应对”。
- Agent Session 准备页的 runtime 面试卡片新增“追问应对”折叠 section。
- 证据覆盖摘要展示追问应对数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个追问应对都包含短答、证据、边界和拉回主线四部分。
- 追问应对能帮助用户面对面试质疑时不夸大实现，也不把回答停在防守状态。
- 追问应对由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.59：Agent runtime challenge drill copy packet

输出：

- 新增 `learningAgentRuntimeChallengeDrillCopyText`，生成专门的面试追问练习文本。
- 追问练习包含练习方式、证据覆盖、追问盲练、回答框架、代码依据、外部来源和依据说明。
- 每个追问盲练题保留“我的短答”和“修正后复述”空位，方便主动回忆。
- Agent Session 准备页复制菜单新增“复制追问练习”。
- 追问练习复用 `challengeResponses`、`answerFrames`、`evidenceAnchors`、`frameworkSourceReferences` 和 `sourceNotes`，不新增并行数据源。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 追问练习可从准备页复制菜单直接触发。
- 复制文本能帮助用户按“质疑 -> 短答 -> 证据 -> 边界 -> 拉回主线 -> 复述”练习面试应对。
- 追问练习由纯 Dart formatter 生成，复用已有追问应对和回答框架。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.60：Agent runtime experience stories

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `experienceStories`。
- 新增 `LearningAgentRuntimeExperienceStory`，包含面试提示、背景、行动、技术取舍、证据和结果。
- 默认项目经历覆盖从刷题 app 到学习 agent、runtime 抽象、AI 输出质量控制、trace/debug 可解释性。
- 完整面试材料、Q&A 练习包和盲练稿复制都包含“项目经历”。
- Agent Session 准备页的 runtime 面试卡片新增“项目经历”折叠 section。
- 证据覆盖摘要展示项目经历数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个项目经历都说明背景、行动、技术取舍、可展示证据和结果。
- 项目经历能帮助用户把 vibe coding 后重建项目的过程讲成真实工程故事。
- 项目经历由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.61：Agent runtime experience drill copy packet

输出：

- 新增 `learningAgentRuntimeExperienceDrillCopyText`，把项目经历生成专门的主动回忆练习材料。
- 项目经历练习包含练习方式、证据覆盖、经历提示、我的回答、背景、行动、技术取舍、证据、结果和修正后复述。
- Agent Session 准备页复制菜单新增“复制项目经历练习”。
- 项目经历练习复用已有项目经历、回答框架、代码依据、外部来源和来源说明。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 项目经历练习可从准备页复制菜单直接触发。
- 复制文本能帮助用户按“提示 -> 我的回答 -> 背景 -> 行动 -> 技术取舍 -> 证据 -> 结果 -> 复述”练习项目讲述。
- 项目经历练习由纯 Dart formatter 生成，复用已有项目经历和回答框架。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.62：Agent runtime mock interview rounds

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `mockInterviewRounds`。
- 新增 `LearningAgentRuntimeMockInterviewRound`，包含轮次、面试官问题、压力追问、预期证据和通过信号。
- 默认模拟面试轮次覆盖项目总览、Agent 架构、来源正确性、代码走读和未来演进。
- 完整面试材料、Q&A 练习包、盲练稿和 Agent Session 准备页都展示模拟面试轮次。
- 证据覆盖摘要展示模拟面试轮次数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每个模拟面试轮次都包含问题、追问、证据和通过信号。
- 模拟面试轮次能帮助用户按真实面试压力练项目讲法，而不是只背静态材料。
- 模拟面试轮次由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.63：Agent runtime mock interview drill copy packet

输出：

- 新增 `learningAgentRuntimeMockInterviewDrillCopyText`，把模拟面试轮次生成专门的主动回忆练习材料。
- 模拟面试练习包含练习方式、证据覆盖、主问题、我的主回答、压力追问、我的追问短答、预期证据、通过信号、证据核对和修正后复述。
- Agent Session 准备页复制菜单新增“复制模拟面试练习”。
- 模拟面试练习复用已有模拟面试轮次、回答框架、追问应对、项目经历、代码依据、外部来源和来源说明。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 模拟面试练习可从准备页复制菜单直接触发。
- 复制文本能帮助用户按“主回答 -> 压力追问 -> 证据核对 -> 修正复述”进行 grill-me 风格练习。
- 模拟面试练习由纯 Dart formatter 生成，复用已有面试轮次和证据材料。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.64：Agent runtime mock interview score rules

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `mockInterviewScoreRules`。
- 新增 `LearningAgentRuntimeMockInterviewScoreRule`，包含评分项、满分信号、失分信号和修复动作。
- 默认评分规则覆盖结构完整、证据可展示、边界诚实、调试路径清楚和表达可压缩。
- 完整面试材料、Q&A 练习包、盲练稿、模拟面试练习和 Agent Session 准备页都展示模拟面试评分规则。
- 证据覆盖摘要展示模拟面试评分规则数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每条模拟面试评分规则都包含满分信号、失分信号和修复动作。
- 用户练完模拟面试后能根据评分规则判断哪里没过关，并知道回到哪个材料 section 修复。
- 评分规则由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.65：Agent runtime mock interview score sheet copy packet

输出：

- 新增 `learningAgentRuntimeMockInterviewScoreSheetCopyText`，把模拟面试评分规则生成可填写的复盘表。
- 评分复盘表包含使用方式、证据覆盖、评分项、我的分数、满分信号、失分信号、我的失分原因、修复动作、修复记录和下次复测结果。
- Agent Session 准备页复制菜单新增“复制模拟评分表”。
- 评分复盘表复用已有评分规则、模拟面试轮次、回答框架、代码依据、外部来源和来源说明。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 评分复盘表可从准备页复制菜单直接触发。
- 用户完成模拟面试后能记录每项分数、失分原因、修复记录和下次复测结果。
- 评分复盘表由纯 Dart formatter 生成，复用已有评分规则和证据材料。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.66：Agent runtime mock interview repair drills

输出：

- `LearningAgentRuntimeInterviewCard` 增加 `mockInterviewRepairDrills`。
- 新增 `LearningAgentRuntimeMockInterviewRepairDrill`，包含失分症状、回看材料、练习动作、复测问题和完成信号。
- 默认修复路线覆盖回答像功能清单、证据说不出来、边界说得过满、调试路径混乱和追问时回答太长。
- 完整面试材料、Q&A 练习包、盲练稿、评分复盘表和 Agent Session 准备页都展示模拟面试修复路线。
- 证据覆盖摘要展示模拟面试修复路线数量。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 每条修复路线都包含失分症状、回看材料、练习动作、复测问题和完成信号。
- 用户能从评分复盘表进入具体修复练习，不只是记录扣分。
- 修复路线由纯 Dart 数据和 formatter 生成，页面和复制材料复用同一组数据。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

### Leaf 13.67：Agent runtime mock interview repair drill copy packet

输出：

- 新增 `learningAgentRuntimeMockInterviewRepairDrillCopyText`，把模拟面试修复路线生成专门的主动修复练习材料。
- 修复练习包含练习方式、证据覆盖、失分症状、原失败回答、回看材料、练习动作、重练回答、复测问题、复测回答、完成信号、证据核对和完成确认。
- Agent Session 准备页复制菜单新增“复制模拟修复练习”。
- 修复练习复用已有修复路线、评分规则、模拟面试轮次、回答框架、代码依据、外部来源和来源说明。

涉及文件：

```text
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 修复练习可从准备页复制菜单直接触发。
- 用户能按“失分症状 -> 回看材料 -> 重练回答 -> 复测回答 -> 完成确认”修复模拟面试问题。
- 修复练习由纯 Dart formatter 生成，复用已有修复路线和证据材料。
- 不改变 Agent Session 启动、复盘保存、trace 保存、provider 行为或 learning_sessions schema。

## Branch 14：Durable Agent Sessions

目的：把当前只在 Agent Session 准备页内存中存在的 runtime state 和 trace 升级为可持久化、可恢复、可审计的 durable checkpoint。该分支继续保持 Flutter 本地优先，并沿用 LangGraph-style checkpoint、OpenAI Agents SDK-style session/trace 的架构思想。

分支边界：

- checkpoint 是 runtime state 和有序 trace events 的原子快照。
- SQLite 是第一版 adapter，feature/executor 只依赖 checkpoint store contract。
- 恢复前仍必须经过 `LearningAgentResumePolicy`，持久化不等于允许自动继续。
- 本分支先完成单 Agent Session 恢复，不提前引入多 agent、云同步或远程后端。

### Leaf 14.1：Agent runtime checkpoint persistence foundation

输出：

- SQLite schema 升级到 v7，新增 `learning_agent_states` 和 `learning_agent_trace_events`。
- 新增 `LearningAgentCheckpoint`，保证 state 与 trace events 属于同一 session，并统一 state 的 trace event ids。
- 新增 `LearningAgentCheckpointStore` contract 和 `SqliteLearningAgentCheckpointStore` adapter。
- checkpoint 保存以 SQLite transaction 原子替换 state 和该 session 的 trace events。
- runtime provider 暴露 checkpoint store，runtime contract barrel 导出 checkpoint contract。
- 新增纯 Dart checkpoint 一致性测试。

涉及文件：

```text
lib/data/database/database_helper.dart
lib/services/agent/learning_agent_checkpoint.dart
lib/services/agent/learning_agent_checkpoint_store.dart
lib/services/agent/learning_agent_providers.dart
lib/services/agent/learning_agent_runtime_contracts.dart
test/learning_agent_checkpoint_test.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 新数据库和 v6 升级路径都会创建 checkpoint 表。
- 保存 checkpoint 时 state 与 trace events 在同一个事务中更新，不留下半份 checkpoint。
- 跨 session trace 和重复 trace id 会在进入 store 前被拒绝。
- feature/executor 后续可通过 `LearningAgentCheckpointStore` 读写 checkpoint，不直接依赖 SQLite。
- 本叶子不改变 Agent Session 当前导航、执行、完成复盘和历史展示行为。

### Leaf 14.2：Agent Session checkpoint lifecycle writes

输出：

- `LearningAgentRuntime` 通过构造注入持有 `LearningAgentCheckpointStore`，集中创建并保存 checkpoint。
- SQLite schema 升级到 v8，为 trace 增加稳定的 `sequence_index`，并迁移已有 v7 trace 顺序。
- Agent Session 在工具启动前先保存 plan checkpoint；保存失败时不启动学习工具。
- executor 返回 completed、canceled、blocked 或 failed 后都保存最新 state 和完整 trace。
- 工具结果 checkpoint 保存失败时保留结果页面状态，并提供只重试 checkpoint、不重复执行工具的恢复动作。
- 保存完成复盘时新增 `reflection_saved` trace，把 runtime state 转为 `complete`，并先保存最终 checkpoint 再写 `LearningSession` 复盘记录。
- checkpoint 保存失败诊断包含阶段、session id、state、trace 数量、失败时间和 trace 摘要。
- runtime checkpoint 单元测试验证 runtime 通过 store port 保存规范化 checkpoint。

涉及文件：

```text
lib/services/agent/learning_agent_runtime.dart
lib/services/agent/learning_agent_providers.dart
lib/features/agent/agent_session_launch_screen.dart
test/learning_agent_checkpoint_test.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- plan checkpoint 未保存成功时 executor 不会运行。
- 四类 executor 结果都使用结果 state/trace 覆盖 plan checkpoint。
- trace 使用显式 `sequence_index` 恢复原始事件顺序，跨 session trace id 冲突会让整个事务失败，不会覆盖其他会话事件。
- 结果 checkpoint 重试不会再次打开导入、核验、导师、面试、练习或复习工具。
- 完成复盘 checkpoint 的最终 phase 为 `complete`，trace 包含且只包含一条本次 `reflection_saved` 事件。
- checkpoint adapter 继续只通过 runtime/store contract 暴露，feature 不直接依赖 SQLite。
- 本叶子不声称支持工具执行过程中的中间 checkpoint，也不启用跨重启恢复 UI。

### Leaf 14.3：Cross-restart Agent Session resume

输出：

- 新增带版本号的 `LearningAgentPlanCodec`，结构化保存 readiness、memory、steps、focus points、blockers 和 session summary。
- SQLite schema 升级到 v9，`learning_agent_states` 新增 `plan_snapshot`；v8 checkpoint 可迁移但因缺少历史 plan 而不会被猜测恢复。
- `LearningAgentCheckpoint` 关联可选 plan snapshot，并拒绝 state/plan goal 不一致的数据。
- `LearningAgentCheckpointStore` 新增 `loadActive`；SQLite 在 limit 前排除 `complete` 和 `blocked`，避免终态记录挤掉未完成会话。
- `LearningAgentRuntime.resumeCheckpoint` 通过 `LearningAgentResumePolicy` 后校验 plan、tool、target 和 focus point 一致性。
- `LearningAgentRuntime.persistCheckpoint` 在写入前执行同一组兼容性检查，阻止不可恢复的 checkpoint 进入 SQLite。
- 恢复成功沿用原 session id、createdAt、state 和 trace，追加并持久化一条 `session_resumed` 事件。
- Agent 首页展示最近未完成 checkpoint、恢复状态、工具、更新时间和 trace 数量，并支持继续或确认删除。
- Agent Session 准备页接受 resumed runtime session；`reflect` 阶段直接恢复完成复盘，其他可恢复阶段由用户确认后继续执行原工具。
- runtime 面试材料同步更新恢复边界、成熟度、演进路线、代码走读、证据锚点和中断恢复参考答案，避免继续声称“没有 checkpoint/resume”。
- 新增 plan codec、旧 checkpoint 拒绝恢复和 runtime resume 单元测试。

涉及文件：

```text
lib/data/database/database_helper.dart
lib/services/agent/learning_agent_plan_codec.dart
lib/services/agent/learning_agent_checkpoint.dart
lib/services/agent/learning_agent_checkpoint_store.dart
lib/services/agent/learning_agent_resume_policy.dart
lib/services/agent/learning_agent_runtime.dart
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/services/agent/learning_agent_providers.dart
lib/services/agent/learning_agent_runtime_contracts.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
test/learning_agent_checkpoint_test.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 新 checkpoint 都包含可解码的 plan snapshot；旧 checkpoint 不会使用重新规划结果冒充原计划。
- active 查询在 SQLite 层排除 `complete/blocked` 后再应用数量限制。
- ResumePolicy 未通过、等待用户决策、缺少 plan 或 plan/tool/target/focus 不一致时，不执行恢复。
- 恢复成功保留原 session id 和历史 trace，并只新增本次 `session_resumed` trace。
- 恢复入口不会自动执行工具；用户仍在准备页明确点击继续。
- 恢复 `reflect` checkpoint 不重复执行已完成工具，可直接保存最终复盘。
- 删除未完成 checkpoint 通过外键级联删除 trace，不影响 `LearningSession` 学习历史。
- 本叶子不实现长工具内部 checkpoint、等待用户决策输入表单或多设备恢复。

### Leaf 14.4：Human-in-the-loop resume decisions

输出：

- 新增版本化 `LearningAgentUserDecisionRequest`，结构化保存 id、prompt、requestedAt、toolId 和 reason，并兼容 v8/v9 纯文本待决策值。
- `LearningAgentState.pendingUserDecision` 改为结构化请求；state、transition 和 trace recorder 增加显式 clear 语义，修复 nullable `copyWith` 无法清空的问题。
- executor 在工具中断后依次记录 `user_interrupted` 和 `user_decision_requested`，并把请求写入结果 checkpoint。
- runtime 新增 `resolveUserDecision`：继续时先保存 `user_decision_resolved`，再经 ResumePolicy 追加 `session_resumed`；结束时进入独立 `canceled` 终态。
- runtime 在持久化和解决前校验 decision tool id 与 state/plan tool 一致，避免把一个工具的决定应用到另一个工具。
- Agent 首页等待卡片提供“处理用户决策”对话框，支持可选备注、继续会话、结束会话和稍后处理。
- SQLite active query 在 limit 前排除 `complete`、`canceled` 和 `blocked`；本叶复用现有 TEXT 列，不升级 schema。
- runtime 面试材料和架构文档同步标记基础 HITL 已实现，并保留任意节点审批、长工具中间 checkpoint、分支回放和多设备并发等真实边界。
- checkpoint 测试覆盖 JSON/legacy 解码、显式清空、等待门禁、继续、结束和工具不兼容路径。

涉及文件：

```text
lib/data/database/database_helper.dart
lib/services/agent/learning_agent_user_decision.dart
lib/services/agent/learning_agent_state.dart
lib/services/agent/learning_agent_state_transition_policy.dart
lib/services/agent/learning_agent_trace.dart
lib/services/agent/learning_agent_executor.dart
lib/services/agent/learning_agent_resume_policy.dart
lib/services/agent/learning_agent_runtime.dart
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/services/agent/learning_agent_runtime_contracts.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
test/learning_agent_checkpoint_test.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 工具中断 checkpoint 同时包含结构化 pending request 和 `user_decision_requested` trace；旧纯文本 checkpoint 仍可展示和处理。
- 没有用户动作时 `resumeCheckpoint` 不追加 resume trace，也不打开工具；首页提供真实决策入口而不是禁用按钮。
- 继续操作清空 pending request，按顺序记录 resolved/resumed 两条 trace，保留原 session id，并仍需用户在准备页明确启动工具。
- 结束操作清空 pending request，记录 resolved trace，进入 `canceled`，不创建 resumed session。
- `complete/canceled/blocked` 都不会占用 active checkpoint 查询的 limit。
- 决策请求与 state/plan 工具不一致时拒绝持久化或处理。
- 当前实现不声称支持任意 graph node 审批、决策超时、长工具内部 checkpoint、分支回放或多设备并发解决。

### Leaf 14.5：Checkpoint optimistic concurrency

输出：

- SQLite schema 升级到 v10，`learning_agent_states` 新增非空 `checkpoint_revision`；v9 记录迁移后从 revision 1 起步。
- `LearningAgentCheckpoint` 携带 revision，revision 0 表示尚未持久化，并拒绝负数。
- `LearningAgentCheckpointStore.save` 返回 revision 已推进的 checkpoint；SQLite adapter 把底层 revision mismatch 转为结构化 runtime conflict。
- checkpoint 保存由无条件 `REPLACE` 改为 transaction 内的 revision read + conditional UPDATE/INSERT；state 成功推进后才替换完整 trace 集合。
- runtime 的 plan、executor result、reflection、resume 和 HITL resolved/resumed 写入都携带 expected revision。
- Agent Session 准备页持有并展示当前 revision；普通持久化失败可以原 revision 重试，revision conflict 只能返回首页读取最新 checkpoint。
- Agent 首页 checkpoint 卡片展示 revision；stale resume 或 stale decision 冲突时刷新 active checkpoint provider，不覆盖最新状态。
- runtime 面试材料增加 optimistic concurrency 术语、架构决策、代码走读、证据锚点和 SQLite 官方来源。
- checkpoint 测试覆盖 revision 单调递增和 stale runtime write 拒绝；SQLite smoke test覆盖 v9→v10 默认值、条件更新及 conflict 后 trace 保留。

涉及文件：

```text
lib/data/database/database_helper.dart
lib/services/agent/learning_agent_checkpoint.dart
lib/services/agent/learning_agent_checkpoint_store.dart
lib/services/agent/learning_agent_runtime.dart
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
test/learning_agent_checkpoint_test.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 新 checkpoint 首次保存返回 revision 1，后续每次成功保存严格加一；load/loadActive 恢复数据库 revision。
- expected revision 与数据库不一致时，state 和 trace 均不改变，并返回 expected/actual revision。
- plan、结果、复盘、resume 和 HITL 两阶段写入不丢失 revision；继续决策按 resolved/resumed 顺序推进两版。
- stale 首页卡片不能重复 resume 或重复解决决策；准备页不会通过重试覆盖较新的 checkpoint。
- v9 迁移后已有 checkpoint revision 为 1，新数据库直接包含 revision 列。
- 当前实现明确不提供自动 merge、分支 checkpoint、跨设备同步或 CRDT。

### Leaf 14.6：Durable tool-start checkpoint

输出：

- `LearningAgentExecutionContext` 新增必填 `initialState` 和 `persistToolStartCheckpoint` contract。
- executor 在 policy 通过后记录 `tool_started`，并在进入真实工具 switch 前等待 checkpoint 持久化成功。
- tool-start 保存失败抛出专用异常，不记录普通 `tool_failed`，也不打开页面或调用工具。
- Agent Session 按 plan、tool-start、result 三个 checkpoint 顺序传播 store 返回的 revision。
- tool-start 保存成功后更新 active state、trace、revision 和 `_pendingResumeSession`；失败重试沿用同一 session 的最后成功 checkpoint。
- 结果保存继续使用 tool-start 已推进的 revision，避免覆盖或丢失中间 checkpoint。
- runtime 面试材料增加 durable tool-call boundary、架构决策、代码证据、LangGraph checkpointers 官方来源和 exactly-once 边界。
- checkpoint 测试验证 tool-start 保存失败时 executor 停在工具调用前，以及 plan/tool-start/result revision 按 1、2、3 递增。

涉及文件：

```text
lib/services/agent/learning_agent_executor.dart
lib/services/agent/learning_agent_runtime_contracts.dart
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_session_launch_screen.dart
test/learning_agent_checkpoint_test.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- 所有 executor context 都显式提供初始 state 和 tool-start checkpoint callback。
- callback 严格位于 `tool_started` trace 之后、工具 switch 之前；callback 失败时真实工具不启动。
- 专用异常绕过普通 tool failure 处理，UI 显示 checkpoint 错误而不是伪造工具失败。
- plan、tool-start、result checkpoint 使用同一 session，并只使用 store 返回的最新 revision。
- tool-start 失败后重试从最后成功 checkpoint 继续；结果 checkpoint 失败仍不会重复执行工具。
- 面试材料明确区分 durable invocation boundary 与工具内部 progress checkpoint、unknown outcome、idempotency 和 exactly-once。
- 官方依据来自 LangGraph checkpointers 文档，并记录 2026-07-14 Smart Search fetch evidence。

### Leaf 14.7：Unknown tool outcome recovery

输出：

- `LearningAgentUserDecisionRequest` 存储格式升级到 v2，新增 `tool_outcome_unknown`、`confirm_tool_completed` 和 `attemptId`，兼容 v1 JSON 与旧纯文本。
- executor 在持久化 `tool_started` 时同步保存 unknown-outcome request；明确完成或失败时清除，用户中断时用 `tool_interrupted` request 覆盖。
- checkpoint 校验 unknown request 必须引用同 session、同 tool 的 `tool_started` trace。
- runtime 支持三种显式恢复动作：重新执行保持 `act`，确认已完成进入 `reflect`，结束进入 `canceled`。
- Agent 首页展示 attempt id 和三种动作，不自动猜测外部副作用结果。
- runtime 面试材料和架构文档加入 AWS/Stripe 官方幂等资料，并明确 attempt identity 不等于服务端 idempotency key。
- checkpoint 测试覆盖 v1/v2 兼容、attempt invariant、unknown request 清除、重新执行、确认完成和非法确认。

涉及文件：

```text
lib/services/agent/learning_agent_user_decision.dart
lib/services/agent/learning_agent_checkpoint.dart
lib/services/agent/learning_agent_state_transition_policy.dart
lib/services/agent/learning_agent_executor.dart
lib/services/agent/learning_agent_runtime.dart
lib/services/agent/learning_agent_state_diagnostics.dart
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_home_screen.dart
test/learning_agent_checkpoint_test.dart
docs/trellis-execution-map.md
docs/agent-runtime-architecture.md
```

验收：

- tool-start checkpoint 同时包含 `tool_started` 和指向该事件的 unknown-outcome request。
- 缺失 attempt id、attempt trace 不存在、事件类型错误或 tool id 不一致时 checkpoint 被拒绝。
- v2 JSON 保留 attempt id；v1 JSON 和旧纯文本仍可读取。
- 工具明确完成或失败后 pending request 被清除，不会在正常结果上误报未知。
- unknown outcome 可由用户重新执行、确认已完成或结束；普通 `tool_interrupted` 不允许“确认已完成”。
- 重新执行和确认完成按 resolved/resumed 顺序推进两版 revision，并保留原 session id。
- 当前只提供人工 reconciliation，不声称安全自动重试、at-most-once 或 exactly-once。
- 官方依据来自 AWS Builders’ Library 与 Stripe API 文档，并记录 2026-07-14 Smart Search fetch evidence。

### Leaf 14.8：Tool operation identity contract

输出：

- SQLite schema 升级到 v11，`learning_agent_states` 新增 nullable `active_tool_operation_id`，并提供 v10→v11 migration。
- `LearningAgentState` 持久化 active operation，并提供显式 clear 语义；state diagnostics 和首页决策对话框展示 operation/attempt 两层身份。
- `LearningAgentUserDecisionRequest` 存储格式升级到 v3，新增 `operationId`，继续读取 v1/v2 JSON 与旧纯文本。
- v2 unknown-outcome state 加载时从旧 attempt id 合成迁移用 operation id，避免已有待决策 checkpoint 在 schema 升级后失效。
- executor 首次调用生成 operation id；人工重试复用 active operation，每次真实调用继续生成新的 `tool_started` attempt id。
- tool-start checkpoint 同时保存 active operation、unknown request 和对应 attempt trace；trace detail 记录 operation identity。
- checkpoint 拒绝空 active operation、缺少 operation 的 unknown request、request/state operation 不一致，以及既有 attempt/tool trace invariant 违规。
- 用户中断和重新执行保留 active operation；完成、失败、policy 阻断、确认完成、结束会话和复盘完成清除。
- runtime 面试材料和架构文档明确 operation id 只是未来 idempotency key 候选，当前工具端尚未消费该身份。
- 测试新增 state/request roundtrip、v1/v2 兼容、legacy v2 state 升级、operation invariant、首次生成、重试复用和终态清除覆盖。

涉及文件：

```text
lib/data/database/database_helper.dart
lib/services/agent/learning_agent_state.dart
lib/services/agent/learning_agent_user_decision.dart
lib/services/agent/learning_agent_checkpoint.dart
lib/services/agent/learning_agent_trace.dart
lib/services/agent/learning_agent_executor.dart
lib/services/agent/learning_agent_runtime.dart
lib/services/agent/learning_agent_state_diagnostics.dart
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_home_screen.dart
test/learning_agent_checkpoint_test.dart
docs/agent-runtime-architecture.md
docs/trellis-execution-map.md
```

验收：

- 首次 tool-start checkpoint 中 operation id 非空，request operation 与 state active operation 相同，attempt id 指向本次 `tool_started`。
- 重新执行时 operation id 保持不变，新 attempt id 与上一次不同。
- unknown request 缺 operation、operation 与 state 不一致、attempt 缺失或 trace/tool 不一致时 checkpoint 被拒绝。
- `tool_interrupted` 和 continue decision 保留 operation；completed/failed/confirmed/canceled/reflection terminal path 清除 operation。
- v3 JSON 保留 operation/attempt；v1/v2 request 可读取，v2 unknown state 可迁移为满足新 invariant 的 state。
- 当前只建立客户端 operation identity contract，不声称服务端安全自动重试、at-most-once 或 exactly-once。
- 静态检查通过：目标文件无冲突标记和尾随空白，`git diff --check` 仅输出既有 CRLF 提示；本机无 `dart`/`flutter`，未执行 format/analyze/test。

### Leaf 14.9：Tool operation input snapshot contract

输出：

- 新增版本化 `LearningAgentToolInputSnapshot`，保存 tool、target、focus 和规范化 evidence ids，并使用可读 JSON 持久化。
- SQLite schema 升级到 v12，`learning_agent_states` 新增 nullable `active_tool_input_snapshot`，提供 v11→v12 migration。
- `LearningAgentState` 将 active operation 与 input snapshot 作为同一生命周期管理；显式 clear operation 时同步清除 snapshot。
- v11 state 若已有 active operation 但没有 snapshot，加载时从 selected tool 与 routing state 合成兼容快照。
- checkpoint 要求 active operation/snapshot 同时存在，并校验 snapshot tool/target/focus/evidence 与 state 一致。
- executor 在新的 `tool_started` 和 checkpoint callback 前比较重试输入；输入变化时记录 `tool_input_rejected`，不启动工具，也不写新的 tool-start checkpoint。
- 相同 routing input 的重试保留 operation/snapshot 并生成新 attempt；中断/continue 保留，completed/failed/confirmed/canceled/reflection terminal path 清除。
- Trace icon、state diagnostics 和首页待决策对话框展示 input contract 的可审计信息。
- 架构与面试材料加入 AWS “same client request ID, different intent” 和 Stripe 参数比较依据。
- 测试新增 snapshot normalization/roundtrip、legacy state 合成、checkpoint input invariant、相同输入重试和 changed-input pre-start rejection。

涉及文件：

```text
lib/data/database/database_helper.dart
lib/services/agent/learning_agent_tool_input_snapshot.dart
lib/services/agent/learning_agent_state.dart
lib/services/agent/learning_agent_checkpoint.dart
lib/services/agent/learning_agent_trace.dart
lib/services/agent/learning_agent_executor.dart
lib/services/agent/learning_agent_state_diagnostics.dart
lib/services/agent/learning_agent_runtime_contracts.dart
lib/services/agent/learning_agent_runtime_interview_card.dart
lib/features/agent/agent_home_screen.dart
lib/features/agent/agent_session_launch_screen.dart
test/learning_agent_checkpoint_test.dart
docs/agent-runtime-architecture.md
docs/trellis-execution-map.md
```

验收：

- snapshot JSON 字段稳定可读，tool/target/focus 去除空白，evidence ids 去空、去重并排序。
- active operation 缺 snapshot、snapshot 缺 operation，或 snapshot 与 state routing 字段不一致时 checkpoint 被拒绝。
- v11 active operation state 在 v12 加载后获得兼容 snapshot，不破坏既有待决策恢复。
- 同 operation + 同 routing input 可以进入新 attempt；operation/snapshot 不变，attempt id 变化。
- 同 operation + 不同 routing input 在 `tool_started` 前被拒绝，checkpoint callback 调用次数为 0，trace 记录具体输入差异。
- 当前 snapshot 不覆盖页面内部后续读取的数据或完整远程 request body，不提供服务端结果缓存、同 key 结果重放、安全自动重试、at-most-once 或 exactly-once。
- 静态检查通过：目标文件无冲突标记和尾随空白，新增 trace enum 已覆盖 UI switch，`git diff --check` 仅有既有 CRLF 提示；本机无 `dart`/`flutter`，未执行 format/analyze/test。

## Branch 15：Engineering Verification and Golden Path

依赖：

- Branch 14 已冻结。
- `docs/execution-roadmap-v2.md` 作为新的执行基线。

目的：

- 恢复真实 Flutter 工程门禁，消除长期只做静态文本检查的验证债务。
- 用一条可重复的黄金路径验证现有来源、核验、Agent、掌握度和复习能力。
- 本分支不增加新的 Agent 抽象。

### Leaf 15.1：Restore Flutter toolchain

输出：

- 安装或定位满足 lockfile 的 Flutter stable 与 Dart SDK。
- 记录可重复使用的命令路径，不修改项目业务代码。
- 运行 `flutter doctor -v` 并区分项目测试所需组件与可选平台组件。

验收：

- `flutter --version` 满足 Flutter >= 3.44、Dart >= 3.12。
- `dart` 与 `flutter` 命令可在当前开发会话中调用。

完成记录（2026-07-14）：

- 使用 `D:\tools\flutter` 中的 Flutter 3.44.6、Dart 3.12.2 完成后续门禁。

### Leaf 15.2：Restore analysis and test gates

输出：

- 运行 `flutter pub get`、`dart format` 检查、`flutter analyze` 和测试。
- 将失败按编译、lint、测试、环境四类记录。
- 只修复会阻断基线的错误，不顺手扩展功能。

验收：

- 项目能够完成依赖解析。
- 所有编译错误被修复。
- analyze/test 结果有可复现记录。

完成记录（2026-07-14）：

- `flutter test`：44 tests passed。
- `dart format --output=none --set-exit-if-changed lib test`：98 files，0 changed。
- `flutter analyze --no-fatal-infos`：0 errors，0 warnings，37 条既有 info lint。

### Leaf 15.3：Verify database and durable-session migrations

输出：

- 验证新数据库 schema v12。
- 验证至少一条旧版本升级路径。
- 运行 checkpoint、operation、attempt 和 input snapshot 相关测试。

验收：

- migration 不丢失既有 deck/question 数据。
- durable Agent checkpoint 可以保存、读取和解决用户决策。

完成记录（2026-07-14）：

- schema v12、旧版本升级路径以及 checkpoint/operation/attempt/input snapshot 测试均已纳入并通过完整测试套件。

### Leaf 15.4：Define the golden-path acceptance scenario

固定场景：

```text
import project material
-> inspect source chunks
-> verify knowledge and questions
-> start an interview session
-> answer and receive cited feedback
-> record a weak point
-> expose the next review action
```

验收：

- 每一步都有明确输入、输出、失败状态和来源依据。
- 场景可以由同一份固定 fixture 重复执行。

完成记录（2026-07-14）：

- 新增 `test/fixtures/golden_path/duoduo_checkpoint_fixture.json`、`test/golden_path_test.dart` 和 `docs/golden-path-acceptance.md`。
- fixture 逐行校验 Duoduo 仓库源码证据，固定 fake 模型队列，并通过真实生产服务链完成来源核验、保存、面试、评估、薄弱点与复习调度。

### Leaf 15.5：Run and stabilize the golden path

输出：

- 执行桌面或 Android 可用目标上的完整场景。
- 修复阻断流程、数据一致性或引用追溯的问题。
- 记录剩余非阻断问题到后续 branch backlog。

验收：

- 用户可以完成一次从项目材料到复习动作的完整闭环。
- Branch 15 关闭后才进入项目源码自动导入。

完成记录（2026-07-14）：

- 黄金路径测试通过，覆盖 `KnowledgeExtractionTask -> QuestionGenerationTask -> CitationVerificationTask -> SourceGroundedIngestionService -> InterviewerService -> AnswerEvaluationTask -> MasteryService -> ReviewSchedulerService`。
- 使用本机 Gradle 9.4.1 和仓库外临时镜像 init script 完成 `assembleDebug`；`app-debug.apk` 为 158,709,824 bytes，Gradle 记录 `BUILD SUCCESSFUL in 5m 53s`。
- APK 已安装到 Android 16 / API 36 模拟器 `emulator-5554`，`com.example.dlg_q/.MainActivity` 冷启动成功，学习首页完整渲染，进程保持存活。
- 启动日志无 `FATAL EXCEPTION`、`AndroidRuntime`、`E/flutter` 或 ANR；仅有 Android ashmem 弃用提示。
- 非阻断构建债务：AGP 9.0 built-in Kotlin 迁移提示、compile SDK 37 支持范围提示与 SDK XML 版本提示，留待生产升级分支处理。

Branch 15 状态：已关闭。

## Branch 16：Project Source Ingestion v1

依赖：

- Branch 15 工程门禁和黄金路径已通过。
- 本分支只做本地目录/ZIP，不提前增加 GitHub、向量库或远程 Agent runtime。

目的：

- 把手工粘贴项目材料升级为可选择、可筛选、可追溯的源码导入。
- 让后续项目理解和面试反馈能够引用真实文件路径、行号、内容 hash 与 revision。

### Leaf 16.1：Define the import and provenance contract

输出：

- `ProjectSourceSnapshot` 统一描述目录和 ZIP 导入结果。
- 每个文件保存规范路径、UTF-8 正文、字节数、行数和 SHA-256。
- 每个 `SourceChunk` 保存 `relativePath`、`startLine`、`endLine`、locator 和内容 hash。

完成记录（2026-07-14）：

- SQLite schema 升级到 v13，`sources` 新增 revision，`source_chunks` 新增结构化文件与行号字段。
- 目录 revision 使用 Git HEAD（可用时）与 snapshot hash；ZIP 使用 archive hash 与 snapshot hash。

### Leaf 16.2：Acquire a directory or ZIP

输出：

- 桌面平台使用普通文件系统目录扫描。
- ZIP 支持文件或 bytes，剥离单一公共根目录并拒绝路径穿越。
- Android 使用 `ACTION_OPEN_DOCUMENT_TREE`、持久 URI 授权、`DocumentFile` 递归枚举和 `ContentResolver.openInputStream()`。

完成记录（2026-07-14）：

- `file_picker 10.3.10` 保持与当前 AGP 9/Kotlin 兼容设置可构建；ZIP DocumentsUI 实测通过。
- 新增 `com.example.dlg_q/project_directory` 原生桥，Android 目录不再被错误转换成普通 filesystem path。
- 官方依据：[Android Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files) 要求通过 tree/document URI 与 `ContentResolver` 访问用户授权树；Smart Search evidence fetched on 2026-07-14。

### Leaf 16.3：Apply one source safety policy

输出：

- 排除生成物、依赖、缓存、凭据、私钥、不支持格式、二进制、无效 UTF-8 和空文件。
- 限制目录枚举数、候选文件数、单文件字节数、总字节数和默认选择量。
- Android 原生读取和 Dart 收集层都检查真实字节上限，未知 provider 长度不能绕过限制。

完成记录（2026-07-14）：

- SAF、ZIP 与桌面目录共同进入 `ProjectSourceImportPolicy`，没有平台专属的第二套内容规则。
- SAF bridge 只读取本次目录枚举返回的 document URI，并拒绝任意越权 URI。

### Leaf 16.4：Select files and persist provenance

输出：

- 项目导入页支持选择目录、选择 ZIP、推荐、全选、清空和逐文件 checkbox。
- 页面展示文件数、行数、字节数与 revision，单次 AI 分析限制为 40 文件/256 KB。
- 保存 `Source.uri/revision` 和结构化 chunk provenance，供后续引用核验使用。

完成记录（2026-07-14）：

- 用户可在调用 AI 前检查实际进入分析的文件；默认选择遵循导入策略上限。
- 目录和 ZIP 的来源身份不再丢失为一段无法定位的拼接文本。

### Leaf 16.5：Verify the real import paths

验收：

- 单元测试覆盖目录、ZIP、虚拟 SAF entries、安全排除、限额和 chunk 行号。
- Android 16/API 36 上真实选择目录后必须发现 fixture 中的 2 个文件，不能接受 `0/0`。
- format、analyze、完整测试、Android build/install/cold start 和运行日志均通过。

完成记录（2026-07-14）：

- `flutter test`：51 tests passed。
- `flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 37 条既有 info lint。
- Gradle 9.4.1 `assembleDebug`：`BUILD SUCCESSFUL in 2m 11s`；APK 安装和冷启动成功。
- API 36 DocumentsUI 真实授权 `Download/duoduo-directory-fixture` 后显示 `2/2`、`README.md`、`lib/main.dart`、4.9 KB 和 snapshot SHA-256。
- app 进程日志无 Flutter、PlatformChannel 或 AndroidRuntime 崩溃；只有既有 ashmem 弃用提示。
- 验收截图：`build/validation/duoduo-directory-imported-saf.png`。

Branch 16 状态：已关闭。下一步进入 Branch 17：Project Understanding and Interview Loop。

## Branch 17：Project Understanding and Interview Loop

依赖：

- Branch 16 已提供可选择、可筛选、可追溯的项目源码 chunks。
- 继续复用现有单 Agent、SQLite、citation 和 policy gate，不增加新 Agent 框架。

目的：

- 把项目源码变成面试时可讲清的架构、数据流、实现、边界和取舍。
- 每个项目结论都能打开对应文件与行号，而不是把 AI 总结当作事实来源。
- 让面试问题、反馈、薄弱点和复习动作围绕同一组项目证据运行。

### Leaf 17.1：Typed project-understanding contract

输出：

- `KnowledgePointKind` 增加 `architecture`、`data_flow`、`implementation`、`boundary` 和 `trade_off`，原有普通知识为 `concept`。
- SQLite schema 升级到 v14，`knowledge_points.kind` 为非空字段，旧数据迁移为 `concept`。
- 知识库列表、详情、搜索、导师与面试 prompt 均携带 kind。

完成记录（2026-07-14）：

- v13→v14 migration 测试确认旧知识点不丢失并获得 `concept` 默认值。
- Android API 36 覆盖安装冷启动后，真实数据库报告 `user_version=14`，并包含非空 `knowledge_points.kind` 默认列。
- 项目理解类型不再依赖自由文本 tag，后续可以稳定筛选和调度不同面试角度。

### Leaf 17.2：Source-grounded project understanding preview

输出：

- 新增 `ProjectUnderstandingTask`，项目导入与普通文章抽取分离。
- 任务只接受五种项目类型，只保留已知 chunk id，去除重复、空内容、未知类型和无有效引用的单元，最多 12 个。
- 边界和取舍只有在源码明确支持时才允许输出；框架惯例或最佳实践不能被写成项目事实。
- 知识核验页逐单元显示类型、源码 locator 和内容片段。

完成记录（2026-07-14）：

- 项目导入改为 `ProjectUnderstandingTask -> buildProjectUnderstandingDrafts -> QuestionGenerationTask`。
- 普通文本/文章仍使用 `KnowledgeExtractionTask`，没有被项目专用 taxonomy 污染。
- 新增任务清洗、空有效结果和核验页 evidence widget 测试。
- 完整测试增至 55 项；静态分析仍为 0 errors、0 warnings 和 37 条既有 info。

### Leaf 17.3：Unit approval and code walkthrough

输出：

- 在保存前允许逐个接受、编辑或删除项目理解单元。
- 删除单元时同步处理关联题目，避免保存悬空 `knowledge_point_id`。
- 按 architecture → data flow → implementation → boundary/trade-off 生成可点击的代码走读顺序。

验收：

- 用户可以只保存自己确认过且有源码依据的项目结论。
- 每一步走读都能打开对应 source chunk 和文件行号。

完成记录（2026-07-15）：

- 知识单元默认待确认；支持逐项确认、全部确认、编辑后重新确认，以及删除。
- 删除知识单元会同步把关联题目决策标为删除；保存服务再次按已批准单元过滤题目，避免悬空关联。
- 保存服务只持久化已确认、未删除且具有可读 source chunk 的知识单元；无题时仍可保存来源、chunks 和知识点，且不会创建空 deck。
- 代码走读顺序固定为 architecture → data flow → implementation → boundary → trade-off，每一步可进入详情查看 locator 和可选择的源码内容。
- `flutter test`：61 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 `assembleDebug` 成功；APK 在 `emulator-5554` 安装成功并以 `LaunchState: COLD` 冷启动，app 日志无 Flutter 或 AndroidRuntime 崩溃。

### Leaf 17.4：Evidence-focused interview loop

输出：

- 一次只展示一个项目问题，并记录当前 kind、knowledge point 和 citation chunks。
- 评价用户回答时区分事实准确、项目细节、工程判断和表达清晰度。
- 追问必须来自本轮答案缺口或已有源码证据，不生成无来源的项目事实。

验收：

- 问题、参考答案和反馈引用均可回到本项目 source chunks。
- 同一会话能从架构问题推进到实现或边界追问。

完成记录（2026-07-15）：

- 面试问题默认每次只生成 1 题；回答完成后才决定证据追问或下一个项目单元，不再预生成 6 个彼此独立的问题。
- `ProjectInterviewFlowService` 按 architecture → data flow → implementation → boundary → trade-off → concept 排序；显式指定的初始知识点可优先，随后回到稳定阶段顺序。
- `AnswerEvaluationTask` 保留事实准确、项目细节、工程判断和表达清晰度四维评分，并新增答案缺口追问契约；追问知识点和 citation 必须通过本地白名单，且每个知识单元最多追问一次。
- SQLite schema 升级到 v15，`interview_turns` 持久化当前 `knowledge_point_id`、`knowledge_point_kind` 和 citation ids；面试现场与历史复盘均显示类型和可展开的来源片段。
- `flutter test`：66 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 `assembleDebug` 成功；Android 覆盖安装后真实数据库为 `user_version=15` 且包含两个新增 provenance 列，`LaunchState: COLD` 冷启动成功，app 日志无 Flutter 或 AndroidRuntime 崩溃。

### Leaf 17.5：Weak-point and review closure

输出：

- 将低分维度映射到知识点与项目理解 kind。
- 生成带 citation 的复习项和下一次面试入口。
- 新增固定项目 fixture，覆盖导入、理解、核验、面试、薄弱点和复习调度。

验收：

- 用户完成一次项目面试后，能看到具体薄弱项目结论、源码依据和下一复习动作。
- Branch 17 关闭后再进入通用编程知识学习循环。

完成记录（2026-07-15）：

- 新增 `InterviewScoreDimension`，将事实准确、项目细节、工程判断和表达清晰度的低分映射到当前 knowledge point 与 `KnowledgePointKind`。
- SQLite schema 升级到 v16；`interview_turns` 持久化 `weak_dimensions`、`review_question_ids`、`review_due_at` 和 `next_interview_question`，旧 v15 回合迁移为空复习动作。
- `InterviewReviewClosureService` 只选择带 citation 的 verified 题目，并在同一个 SQLite transaction 中保存面试回合和复习调度；回合写入失败时题目调度同步回滚。
- 面试完成页与历史复盘展示具体薄弱维度、AI 反馈、源码依据、“开始复习”和“再次面试”入口；再次面试携带当前知识点与修复问题。
- 黄金路径改为真实扫描 Duoduo 项目目录并选择两份源码，覆盖 `ProjectSourceImportService -> ProjectUnderstandingTask -> 核验 -> 面试 -> 弱点 -> 复习调度`。
- `flutter test`：72 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 `assembleDebug` 成功；Android 覆盖安装后真实数据库为 `user_version=16` 且包含四个复习动作列，`LaunchState: COLD` 冷启动成功，app 日志无 Flutter 或 AndroidRuntime 崩溃。

Branch 17 状态：已关闭。Leaf 17.1 至 17.5 均完成，下一步进入 Branch 18：Programming Knowledge Learning Loop。

## Branch 18：Programming Knowledge Learning Loop

依赖：

- Branch 17 已提供 source-grounded knowledge point、导师、练习、复习和单 Agent runtime。
- 本分支继续使用本地 SQLite 与单 Agent，不提前引入网页爬虫、向量数据库或多 Agent 编排。

目的：

- 把官方文档和源码变成可审计、可复现的编程知识来源，而不是只靠用户手动选择可信度。
- 把零散知识点组织成有先修关系的学习路径。
- 让分层讲解、苏格拉底追问、练习、薄弱点和复习围绕同一组来源证据运行。

### Leaf 18.1：Auditable programming-source contract

输出：

- `Source` 保存发布者、许可表达式、获取时间和来源级 SHA-256，并继续保存 URI、revision 与 trust level。
- 普通文本导入支持显式选择官方文档或源码，并录入标题、规范 URI、发布者、版本/revision 和许可信息。
- 官方文档和源码进入 AI 抽取前必须通过来源契约；正文被切成带稳定行号、locator 和 SHA-256 的 snapshot chunks。
- 核验页和来源详情展示完整 provenance，许可未知时明确显示未知，不把未知许可解释为允许再分发。

验收：

- 仅选择“官方文档”或“源码”不能自动成为优先证据；缺少必需 provenance 时导入被阻断并给出具体原因。
- 保存后可以从知识点回到标题、URI、发布者、revision、获取时间、许可和内容 hash。
- v16 数据无损升级，原项目源码和普通来源继续可读。

完成记录（2026-07-15）：

- SQLite schema 升级到 v17；`sources` 新增 `publisher`、`license_expression`、`retrieved_at` 和 `content_hash`，v16 来源迁移为空 provenance 默认值且不丢失 URI、revision 或 trust level。
- 新增 `ProgrammingSourceImportService`；官方文档和源码必须提供完整 HTTP(S) URL、发布者/仓库所有者及版本/tag/commit，正文统一规范化并生成来源级与 chunk 级 SHA-256。
- 普通文本 chunk 改为带 `snapshot:Lx-Ly`、`startLine` 和 `endLine` 的行级快照；不再使用 Dart `hashCode` 充当内容完整性标识。
- 添加内容页新增“源码”可信度和来源档案；普通来源默认折叠，官方文档/源码自动展开必填字段。核验页与来源详情展示发布者、revision、获取时间、许可和 SHA-256，许可缺失明确显示“未知”。
- 外部设计依据来自 W3C PROV、RFC 9309、MDN licensing、Git objects、SPDX、Python versioned docs 和 1EdTech CASE；可复现命令与抓取结果记录于 `docs/programming-learning-research.md`。
- `flutter test`：78 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 `assembleDebug` 成功；APK 覆盖安装到 `emulator-5554`，`LaunchState: COLD` 冷启动约 3.7 秒。真实数据库为 `user_version=17` 并包含四个新列，运行日志无 Flutter、AndroidRuntime 或 ANR 崩溃。
- 移动端验收截图：`build/validation/duoduo-leaf18-ingestion-collapsed.png` 与 `build/validation/duoduo-leaf18-official-expanded-stable.png`。

### Leaf 18.2：Concept prerequisites and learning path

输出：

- 新增知识点先修关系，关系只引用已保存且有来源的 concept knowledge points。
- AI 只提出候选先修边，用户可确认、删除或反向调整；服务层去除悬空、自环、重复和环路。
- 使用稳定拓扑顺序生成“先学什么、为什么、完成信号是什么”的学习路径。

验收：

- 同一批编程知识能生成可解释、无环且可人工修改的学习顺序。
- 每个路径节点能打开对应来源、导师和已核验练习。

完成记录（2026-07-15）：

- SQLite schema 升级到 v18；新增 `knowledge_point_prerequisites`，使用复合主键、自环检查和两条级联外键保存已确认先修关系，v17 数据迁移为空关系图。
- 新增 `ConceptPrerequisiteTask` 与 `ConceptLearningPathService`；候选边只允许引用本次选择中有来源的 `concept` knowledge points，citation 必须属于关系两端概念，服务拒绝悬空引用、自环、重复边和环路。
- 知识库新增“编程学习路径”入口；最多选择 12 个有来源概念，支持 AI 分析、人工确认/取消、反向、删除和保存，并用稳定拓扑顺序展示可开始、需补先修、掌握度和已核验题信号。
- 每个路径节点可直达知识点证据详情、导师模式和该概念的已核验练习；无已核验题时练习入口明确禁用。
- 定向验证 14 tests passed；`flutter test`：84 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 `assembleDebug` 成功，APK 覆盖安装到 `emulator-5554`；真实数据库迁移到 `user_version=18`，表结构、约束和外键均已核验。
- Android 临时写入两个带来源概念、一条先修边和一条 verified question，实测证据详情、导师和已核验练习三个入口后已清理；截图为 `build/validation/duoduo-leaf18-2-learning-path.png` 与 `build/validation/duoduo-leaf18-2-verified-practice.png`。

### Leaf 18.3：Layered tutor and Socratic loop

输出：

- 编程导师按定义/直觉、工作机制、代码或文档例子、边界与常见误区分层讲解。
- 一次只提出一个苏格拉底问题，记录用户回答、依据、反馈、误区和下一问。
- 追问只能来自当前知识点、已确认先修关系、用户答案缺口和已有 source chunks。

验收：

- 用户可以从讲解进入“先回答再反馈”的连续导师轮次。
- 讲解与每次反馈均能回到来源片段；证据不足时停止扩展事实并提示补来源。

完成记录（2026-07-15）：

- SQLite schema 升级到 v19；新增 `tutor_turns`，结构化保存当前问题、用户回答、AI 反馈、参考关键点、具体误区、唯一下一问、citation、确认先修概念、证据充分状态和本轮准确度，v18 迁移为空导师轮次。
- `TutorExplanationTask` 改为定义/直觉、工作机制、代码或文档例子、边界、常见误区和面试表达分层契约；首问只能有一个，核心证据不足时清空首问并停止扩展。
- 新增 `TutorSocraticTask`；输入范围只包含当前 concept、已确认且有来源的先修 concepts、最近导师轮次和这些概念的 source chunks。伪造 citation、未确认先修片段和越界分数会被服务层过滤或规范化。
- 导师页实现“分层讲解 -> 当前问题 -> 用户回答 -> 引用反馈/误区 -> 唯一下一问”的连续回路；每轮单独持久化并更新导师 session 摘要，来源不足时显示停止卡片而不继续追问。
- 教学设计依据补充 IES `Organizing Instruction and Study to Improve Student Learning`：深层问题、主动回答和交互式构建解释作为教学原则；“一次一问”明确记录为 Duoduo 的逐轮审计约束，研究命令与证据写入 `docs/programming-learning-research.md`。
- 定向验证 16 tests passed；`flutter test`：91 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 `assembleDebug` 成功，APK 覆盖安装到 `emulator-5554`；真实数据库为 `user_version=19`，`tutor_turns` 表、session-created 索引及两条外键均已核验。
- Android 使用两个临时 source-backed concepts 和一条确认先修边验收导师入口与无 Key 诊断后已清理；截图为 `build/validation/duoduo-leaf18-3-tutor-entry.png`。完整连续轮次使用确定性 OpenAI 兼容响应通过组件测试。

### Leaf 18.4：Evidence-grounded exercises and misconception repair

输出：

- 在现有已核验题之外增加解释、代码阅读、边界判断和小型实现练习契约。
- 评价区分概念准确、推理过程、代码/文档依据和表达清晰度。
- 将错误答案归并为可读误区，并生成只引用现有来源的修复讲解与复测题。

验收：

- 用户能够围绕一个编程概念完成讲解、主动回答、练习、反馈和复测。
- 未核验题目或无引用反馈不能进入正式掌握度更新。

完成记录（2026-07-15）：

- SQLite schema 升级到 v20；新增 `programming_exercises` 与 `programming_exercise_attempts`，独立保存开放编程练习和作答，不把解释、代码阅读、边界判断或小型实现硬塞进原有 `QuestionType` 与字符串判题流程。
- `ProgrammingExercise` 保存四类练习、参考关键点、四维 rubric、`pending/verified/no_source`、citation、复测标记和父 attempt；`ProgrammingExerciseAttempt` 保存用户答案、反馈、四维分数、稳定误区代码、可读误区、修复讲解、citation、证据充分状态、正式掌握度应用状态和复测练习引用。
- 新增 `ProgrammingExerciseGenerationTask`；每种练习类型最多生成一道，只接受当前知识点 source chunks，伪造 citation、重复类型、缺少参考答案或缺少四维标准的草稿会被过滤。
- 新增 `ProgrammingExerciseEvaluationTask`；分别评价概念准确、推理过程、代码/文档依据和表达清晰。平均分低于 80 时强制返回稳定误区代码、可读误区、来源约束修复讲解和不重复原题的 source-only 复测题；证据不足时不生成复测。
- 新增独立编程练习页；支持生成、查看来源与参考关键点、人工确认来源可支撑、正式作答、四维反馈、误区修复和复测。复测题重新进入 `pending`，必须再次人工核验。
- 导师页的编程练习入口提升到“已选择有来源知识点”之后；未配置 AI Key 时仍可离线查看和核验已保存练习，生成与评价继续要求 Key。
- `MasteryService` 只接受已核验且有 citation 的练习，以及 evidence sufficient、citation 非空且 citation 属于该练习证据集合的评价；pending、no-source、越界引用、证据不足或已应用 attempt 均返回拒绝，不更新正式掌握度。
- 新增 v19 -> v20 迁移、生成任务、评价任务、掌握度门禁和完整 widget 闭环测试；`flutter test`：99 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 在跨盘符环境使用 `-Pkotlin.incremental=false` 后 `assembleDebug` 成功，APK 覆盖安装到 `emulator-5554`；真实数据库迁移到 `user_version=20`，两张新表、两个索引存在，新表 `foreign_key_check` 为空。全库仍有此前遗留的来源/知识点孤儿关系，本 Leaf 未擅自清理历史数据。
- Android 临时写入一个官方文档来源、一个 concept 和两道练习，验收导师无 Key 时的离线练习入口、待核验/已核验列表与证据核验弹窗后已全部清理；截图为 `build/validation/duoduo-leaf18-4-tutor-selected-2.png`、`build/validation/duoduo-leaf18-4-exercises.png` 与 `build/validation/duoduo-leaf18-4-verification-dialog.png`。

### Leaf 18.5：Programming weak-point and review closure

输出：

- 将导师和练习中的低分维度映射到知识点及其未掌握先修项。
- 只使用带 citation 的 verified questions 和有来源的复测任务生成复习队列。
- 新增固定官方文档 + 源码 fixture，覆盖导入、先修路径、导师、练习、误区和复习调度。

验收：

- 用户完成一次编程知识学习后，能看到具体薄弱概念、缺失先修、来源依据和下一复习动作。
- Branch 18 关闭后再进入 Branch 19 的来源排序、引用覆盖率和回归评估。

完成记录（2026-07-15）：

- SQLite schema 升级到 v21；新增 `programming_review_actions`，按导师轮次或练习 attempt 保存知识点、薄弱维度、未掌握先修项、citation、已核验题、已核验复测、到期时间和完成时间。同一 `trigger_type + trigger_id` 保持唯一，开放动作按 `completed_at + due_at` 建索引。
- 新增 `ProgrammingReviewClosureService`；导师准确度低于 80 映射为“概念准确”，练习四个低于 80 的分数分别映射到概念准确、推理过程、代码/文档依据和表达清晰。低掌握先修只接受有 citation 的已确认关系、`concept` 类型、掌握度低于 70 且自身有来源的知识点。
- 复习材料门禁只接受带 citation 的 `verified` Question，以及带 citation、`verified` 且 `isRetest=true` 的编程练习。练习评价 citation 必须属于原练习证据集合；pending、no-source、普通非复测练习、证据不足或越界引用均不能进入编程复习动作。
- 导师轮次与其复习动作在同一 SQLite transaction 中落库；完成已列入动作的复测会关闭旧动作，若新作答仍低分则以新 attempt 建立新的可审计动作。
- 复习模式新增“编程修复”区块，展示薄弱维度、缺失先修、来源片段和下一动作，并可直接打开已核验复测；可练习知识点同时接纳已核验编程练习，不再只依赖 legacy Question。
- 新增固定官方文档 + 源码 fixture，使用确定性 AI 响应覆盖来源导入、先修路径、分层导师、55 分苏格拉底轮次、开放练习、稳定误区、pending 复测拒绝、人工核验和最终编程复习队列。
- 新增 v20 -> v21 迁移、动作持久化/唯一触发器/开放索引、闭环服务、复习 UI 和 Branch 18 golden path 测试；`flutter test`：107 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Gradle 9.4.1 `assembleDebug` 成功；APK 覆盖安装到 `emulator-5554` 后真实数据库从 `user_version=20` 升级到 21，新表 12 列、开放动作索引和唯一触发器索引存在，新表 `foreign_key_check` 为空，约 4.0 秒冷启动无 Flutter 或 AndroidRuntime 崩溃。全库此前遗留的来源/知识点孤儿关系未擅自清理。
- Android 使用 `leaf18-5-validation-*` 临时来源、知识点、先修边、已核验复测和复习动作，实测“薄弱维度 -> 缺失先修 -> 来源依据 -> 开始复测”后已全部清理；截图为 `build/validation/duoduo-leaf18-5-review.png` 与 `build/validation/duoduo-leaf18-5-review-citations.png`。

Branch 18 状态：已关闭。Leaf 18.1 至 18.5 均已完成，下一步进入 Branch 19：Correctness and Evaluation。

## Branch 19：Correctness and Evaluation

依赖：

- Branch 18 已提供可审计来源、知识点、导师、面试、编程练习与复习闭环。
- 本分支先证明本地检索和来源门禁的效果，再决定是否需要 embedding、向量数据库或远程评估平台。

目的：

- 用固定真值集持续测量检索、引用和拒答质量，而不是依靠单次演示判断 Agent 是否可靠。
- 让来源可信度、相关性、主张级引用和证据不足处理成为可解释、可回归的正式契约。
- 在使用付费生产 Key 前完成提供商和模型能力验收，并移除普通偏好存储中的明文 Key 风险。

### Leaf 19.1：Fixed evaluation contract and baseline corpus

输出：

- 定义检索 `Recall@k`、MRR、主张级引用覆盖率、无依据主张率和拒答正确率。
- 增加版本化固定 fixture，覆盖知识库回答、导师反馈、面试评价和编程练习评价。
- 直接运行当前 `KnowledgeSearchService` 记录修改排序和门禁前的基线。

验收：

- 指标服务不依赖真实模型、网络或数据库，同一 fixture 每次得到相同结果。
- fixture 同时包含可回答、应拒答、缺少引用和带无依据主张的样本。
- 后续排序、提示词或模型变更必须与该基线比较，不能只替换快照掩盖回归。

完成记录（2026-07-15）：

- 新增纯 Dart `CorrectnessEvaluationService`，统一计算宏平均 `Recall@k`、MRR、主张级引用覆盖率、无依据主张率和拒答正确率；无真值检索样本不进入分母，重复排名 ID 先稳定去重。
- 新增版本化 `correctness_baseline_v1.json`，覆盖 3 个检索样本与知识回答、导师反馈、面试评价、编程练习评价 4 类共 6 个生成样本，并区分人工标注的 supporting evidence、实际 citation 和应答/拒答期望。
- 修改排序前基线固定为 `Recall@1 = 0.667`、`MRR = 0.833`、引用覆盖率 `0.875`、无依据主张率 `0.200`、拒答正确率 `0.833`；检索排名快照保留在 fixture 中，后续实现不得重写它伪造提升。
- 评估方法依据 OpenAI evaluation best practices、Stanford IR ranked retrieval、ACL ALCE citation evaluation 与 NIST AI 600-1；抓取命令和证据目录写入 `docs/programming-learning-research.md`。
- Leaf 19.1 定向 4 tests passed；首次全量验证 `flutter test` 为 110 tests passed，`flutter analyze --no-fatal-infos` 为 0 errors、0 warnings、34 条既有 info。

### Leaf 19.2：Deterministic source trust and relevance ranking

输出：

- 将词法相关性、来源可信度、核验状态和可读 source chunk 组合为可解释的排序分解。
- 对来源、片段、题目 citation 和知识点结果使用稳定 tie-break，避免标题堆词压过高质量证据。
- 把知识回答上下文选择从 UI provider 中抽成可测试的确定性服务。

验收：

- 官方文档和源码只有在与问题相关时获得优先级，低相关官方来源不能无条件排在精确匹配证据之前。
- 固定检索集的 `Recall@k` 与 MRR 不低于 19.1 基线，并记录每项排序理由。

完成记录（2026-07-15）：

- `KnowledgeSearchService` 改为词项覆盖、精确短语、标题、正文、元数据、来源可信度和题目核验状态的分项评分；可信度与核验加分按查询覆盖率缩放，避免低相关官方来源仅靠身份压过高相关结果。
- 每个 `KnowledgeSearchResult` 保存 `KnowledgeSearchScoreBreakdown` 与可读排序理由；同分时依次按覆盖词数、可信度、证据优先类型、标题和稳定实体 ID 排序，不依赖非稳定 sort 顺序。
- source chunk 必须命中自身内容、locator 或相对路径；来源标题只作为低权重元数据，防止“来源标题命中”把内容无关的首个 chunk 带入回答上下文。
- 新增 `KnowledgeAnswerContextService`，只选择直接命中片段、题目已保存 citation 或同来源的实际匹配片段；Riverpod provider 不再自行查询来源前两个 chunk 和拼装上下文。
- 19.1 的旧排名快照保持不变；新排序在同一固定集上达到 `Recall@1 = 1.000`、`MRR = 1.000`，并新增可信度缩放、稳定 tie-break、无关 chunk 排除和 citation 上下文测试。
- `flutter test`：114 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。

### Leaf 19.3：Claim-level citation coverage and refusal gate

输出：

- 将回答拆成可核验主张，并记录每个主张的 supporting citation、缺失引用和人工核验状态。
- 证据不足、引用越界或关键主张未被来源支持时拒答或降级为明确的部分回答。
- 将同一门禁应用到知识回答、导师反馈、面试参考答案和编程练习评价。

验收：

- 不能再用“一条合法 citation”掩盖同一回答里的其他无依据事实。
- 固定集的引用覆盖率提升、无依据主张率下降，且应答/拒答样本均无回归。

完成记录（2026-07-15）：

- 新增 `GroundedClaim`、`GroundedClaimEvidence`、`GroundingDisposition` 与 `GroundedClaimGate`；模型必须按 section、claim text、citation id 和原文 quote 返回主张，quote 归一化空白和大小写后必须能在本轮 source chunk 正文中逐字找到，越界 citation、伪造 quote 和无证据主张会被剔除。
- 知识回答、苏格拉底导师、面试评价和编程练习评价统一接入主张门禁。最终展示文本由通过核验的 claims 重建，不再直接信任模型整段回答；混合结果降级为 `partial`，无可用主张或显式证据不足时为 `refused`。
- Tutor 的部分/拒答轮次停止追问并将准确度归零；面试部分/拒答清空四维评分、薄弱点和下一问；编程评价部分/拒答清空评分和复测。非 `grounded` 结果不能更新正式掌握度、创建复习动作或关闭已有复测动作。
- SQLite schema 升级到 v22；`interview_turns`、`tutor_turns` 和 `programming_exercise_attempts` 保存 `grounded_claims_json` 与 `grounding_disposition`。v21 及更早历史行迁移为 `legacy + []`，不会被误当成新门禁已经通过；新记录完成 claims JSON 往返验证。
- 知识回答学习记录在向后兼容的 summary 中保存证据门禁和 claims JSON；旧 summary 仍可读取，但显示为“历史记录未审计”，不计入证据合格记录。复盘文本新增已核验主张，citation、来源缺口和主张审计保持在同一历史记录中。
- 两条既有黄金路径升级为真实主张契约：面试 fixture 覆盖两个源码 chunk，编程学习 fixture 覆盖 Tutor 反馈、参考答案、误区、练习反馈和修复讲解；构造 Turn/Attempt 时与真实 UI 一样持久化 claims 和 disposition。
- 19.1 的旧生成基线保持不变；同一固定生成集经过真实 `GroundedClaimGate` 后，主张级引用覆盖率从 `0.875` 提升到 `1.000`，无依据主张率从 `0.200` 降到 `0.000`，拒答正确率保持 `0.833` 无回退。exact quote containment 是确定性来源绑定，不等同于语义蕴含证明，模型级语义质量继续由 19.4 验收矩阵约束。
- 定向与全量验证覆盖 v21 -> v22 迁移、历史兼容、知识回答历史、四类任务、掌握度/复习副作用和两条黄金路径；`flutter test`：125 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。

### Leaf 19.4：Provider/model acceptance matrix and secure configuration

输出：

- 以能力而非陈旧模型名描述提供商：结构化 JSON、中文、代码、上下文、Chat Completions、Responses API 与费用档位。
- 对候选模型运行同一固定集，保存模型版本、协议、参数、成功率、质量、延迟和估算费用。
- 将 API Key 移出普通 `SharedPreferences`，开发 Key 与生产 Key 分离并支持清除。

验收：

- 未通过结构化输出、引用与拒答门禁的模型不能成为正式学习默认模型。
- 低额度开发 Key 完成验收前不要求用户配置生产 Key。

实现记录（2026-07-15）：

- `OpenAIService` 保留统一 `chatCompletion` 任务接口，内部新增带 requested/resolved model、协议、延迟和 provider-reported token usage 的结构化 completion result；Responses 使用 `input_text` / `input_image`、`max_output_tokens` 和 `store: false`，Chat Completions 保持兼容。
- 新增固定五项真实任务验收：严格 JSON、中文七言绝句、Dart 编程、S1 主张逐字引文绑定和无关证据拒答。五项必须全部通过；供应商级阻断错误只调用一次，后续任务标记 skipped，避免重复消耗额度。
- 验收身份固定为 provider id、去 user-info/query/fragment 的 base URL、requested model 和 protocol。报告保存 resolved model、逐项通过状态、延迟、Token、可核验费用和结构化失败类别，不保存 Key；自定义中转不套用 OpenAI 官方价格。
- 正式学习调用启用 acceptance gate；未通过同一配置验收时返回 `model_not_accepted`，验收 runner 只能用显式 bypass 执行固定测试，不能让普通任务绕过。
- API Key 改为 provider-scoped `flutter_secure_storage`；历史 `ai_api_key` / `openai_api_key` 明文值一次迁移后删除。设置页不回填 Key，留空保留，显式按钮删除。
- 设置页增加 Chat/Responses 协议切换、五项固定验收按钮、通过数、延迟、Token、费用/无单价状态、resolved model 和可行动错误提示。`client_restricted` 明确要求服务商开放 Dart/Dio，不伪装 Codex 客户端。
- OpenAI 预设依据 2026-07-15 官方 latest-model 页面更新为 GPT-5.6 `terra`、`sol`、`luna` 和 GPT-5.5，默认新配置使用 Responses；官方直连短上下文价格只用于这些可核验模型。
- 公用开发凭据可继续使用到失效，但未写入仓库、文档、测试或普通偏好。外部古诗任务验证 `gpt-5.5` 与 `gpt-5.6-sol` 可生成有效七言绝句；由于普通客户端通道仍出现 `channel:client_restricted`，该中转尚未获得 App approval。
- 新增 `docs/provider-model-acceptance.md`，记录矩阵、门禁、安全边界、外部探测结论与 OpenAI official evidence。
- `flutter test`：134 tests passed；`flutter analyze --no-fatal-infos`：0 errors、0 warnings，只有 34 条既有 info lint。
- Android 定向运行 `:flutter_secure_storage:assembleDebug` 为 `BUILD SUCCESSFUL`，27 个任务完成并生成 `flutter_secure_storage-debug.aar`。完整 App 使用缓存 Gradle 9.4.1，关闭 Kotlin 增量、使用 in-process 编译并限制单 worker，避开 Windows C:/D: 缓存路径错误；离线诊断进一步确认此前 `:app:compileDebugKotlin` 停顿实际在等待 Flutter engine Maven artifact。将本机已下载且 SHA-1 与 Gradle 内容缓存一致的 embedding 与三种 ABI artifact 暴露为 `build/` 下临时 gitignored Maven 镜像后，`:app:compileDebugKotlin` 87 个任务成功，`:app:assembleDebug` 203 个任务以 `BUILD SUCCESSFUL in 1m 42s` 完成。`app-debug.apk` 为 165,967,277 bytes，SHA-256 为 `7dd826113663bbccfd507c12dd9dbd6f38e6d7dccde3a3514f7d691bb0e57720`；ZIP 结构包含 `classes.dex` 与 `arm64-v8a`、`armeabi-v7a`、`x86_64` Flutter 库，build-tools 37 验证 v2 debug 签名通过。AGP built-in Kotlin、compile SDK 支持范围和 SDK XML 提示列为非阻断生产工具链债务。Leaf 19.4 已完成。

### Leaf 19.5：Correctness golden path and branch closure

输出：

- 增加固定正确性黄金路径，覆盖检索、上下文选择、回答、主张引用、拒答、导师、面试与练习评价。
- 在 Android 上验收来源排序理由、部分回答/拒答提示和可打开 citation。
- 汇总 Branch 19 指标变化、剩余风险与是否需要向量检索的触发证据。

验收：

- 用户能分辨“已被来源支撑的回答”“仍有来源缺口的部分回答”和“证据不足拒答”。
- Branch 19 关闭后再进入 Branch 20 的统一知识库学习 Agent，不提前引入多 Agent 或向量数据库。

完成记录（2026-07-15）：

- 新增 `correctness_closure_fixture.json`、服务黄金路径和 Widget 黄金路径，固定覆盖官方文档与冲突个人笔记的检索排序、单片段上下文选择、grounded/partial/refused 知识库回答、导师反馈、面试评价和编程练习评价；六个确定性任务响应全部按预期顺序消费。
- 正确性报告覆盖一个检索真值 case 和四个用户学习 surface；Recall@1=`1.0`、MRR=`1.0`、citation coverage=`1.0`、门禁后的 unsupported claim rate=`0.0`、refusal accuracy=`1.0`。指标用于固定回归，不把单一 fixture 冒充真实生产质量估计。
- 知识库 UI 将 `证据合格`、`部分主张未支持`、`证据不足已拒答` 分别显示，不再把 partial/refused 合并成通用“需核查”；检索结果展示紧凑的 `排序依据`，citation 抽为可独立测试并可跳转的卡片。
- Android 在 `emulator-5554` 使用 `leaf19-validation-*` 临时数据验收：完整查询 `JSON schema guarantee` 下官方 OpenAI 片段排在个人笔记之前并显示排序理由；grounded citation 可进入来源详情且高亮 `当前引用片段`；三态历史、排序和引用截图分别保存为 `build/validation/duoduo-leaf19-5-history-states.png`、`duoduo-leaf19-5-search-ranking.png`、`duoduo-leaf19-5-citation-navigation.png`。
- 验收后精确删除 2 个临时来源、2 个临时片段和 3 条临时学习 session，未删除其他用户数据；SQLite `integrity_check` 为 `ok`。清理后重新启动并进入知识库，日志无 `FATAL EXCEPTION`、`E/flutter` 或 App ANR。
- `flutter test --no-pub`：137 tests passed；`flutter analyze --no-pub --no-fatal-infos`：0 errors、0 warnings，仅 34 条既有 info lint。更新后的 Android APK 再次完成 203 个 Gradle 任务并成功安装冷启动；最终 hash 与签名终检记录在 `docs/correctness-golden-path.md` 和验收命令输出中。
- 当前本地词法 + 来源可信度排序已通过固定真值集且理由可解释，未出现语义召回、语料规模或延迟阻断，因此不引入向量检索。后续仅在同义/语义查询持续漏召回、Recall@K/MRR 回归、语料增长或延迟恶化时重新评估 hybrid/vector，并继续保留来源、locator、逐字 quote 和排序解释契约。
- 新增 `docs/correctness-golden-path.md`，集中记录固定输入、指标、Android 证据、剩余风险和向量检索触发条件。生产 Key 仍不配置；公用开发凭据未写入仓库、文档、测试或普通偏好。

Branch 19 状态：已关闭。Leaf 19.1 至 19.5 均已完成；下一步进入 Branch 20：Unified Knowledge-Base Learning Agent，先统一 planner、memory 和 source-grounding contract，不提前引入多 Agent 或向量数据库。

## Branch 20：Unified Knowledge-Base Learning Agent

依赖：

- Branch 17 和 18 已分别打通项目理解、面试、编程导师、练习和复习闭环。
- Branch 19 已将检索排序、主张引用、部分回答、拒答和正确性指标固定为可回归契约。
- 当前已有一个本地 `LearningAgentPlannerService`、runtime、tool registry、policy、checkpoint 和 memory facade；本分支不重写 runtime，而是统一其学习目标、内容范围和用户工作流。

目的：

- 让项目知识和编程知识由同一个 planner、memory 和 source-grounding contract 驱动，同时避免不同目标之间静默串线。
- 让知识库回答、导师、面试、练习、复盘和复习调度共享目标级上下文与下一动作，而不是继续依赖多个彼此独立的入口卡片。
- 保持 Flutter + Dart + SQLite 本地优先；没有远程并发、长任务或跨设备需求前，不引入多 Agent、远程图 runtime 或向量数据库。

### Leaf 20.1：Unified learning scope and routing contract

输出：

- 新增项目、编程和混合面试知识范围的正式契约，并由 `LearningAgentGoal` 确定默认范围。
- planner 在计算 readiness、待核验题、已核验题和 focus point 前统一过滤范围；项目路线不再选择通用编程概念，编程路线不再选择项目架构/数据流/实现/边界/取舍单元。
- AI 应用开发面试路线可以同时使用项目与编程知识；路线卡明确显示当前知识范围。
- 新增固定 planner 回归，覆盖跨范围题目、无知识点题目和混合目标。

验收：

- 同一个全库输入下，三个目标得到各自可解释且互不串线的 readiness、focus point 和下一步。
- 不新增数据库表，不破坏既有 checkpoint plan snapshot 解码与恢复。

完成记录（2026-07-15）：

- 新增 `LearningAgentKnowledgeScope` 的 `project`、`programming`、`mixed` 正式契约，由三个 `LearningAgentGoal` 确定默认范围；planner 在 readiness、focus point、待核验题、已核验题和下一动作路由前统一过滤知识点、题目与练习输入。
- 无 scoped `knowledgePointId` 的题目不再虚增 readiness；`LearningAgentPlan` 与 session summary 暴露计算后的知识范围，Agent 路线卡显示 `项目知识`、`编程知识` 或 `项目与编程知识`。
- 新增 4 个统一范围回归；checkpoint/恢复兼容集合 39 个测试通过。全量 `flutter test --no-pub` 为 141 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。
- Android `emulator-5554` 分别验收三种目标，UI hierarchy 与截图保存为 `build/validation/duoduo-leaf20-1-agent-default.*`、`duoduo-leaf20-1-agent-project.*`、`duoduo-leaf20-1-agent-mixed.*`；层级中知识范围唯一且与目标一致，截图无重叠或溢出。
- 更新后的 Android APK 完成 203 个 Gradle 任务；`app-debug.apk` 为 190,490,327 bytes，SHA-256 为 `9d9771a35ad00ce5155a1454ed96e16bb18daf2a02e5ebf29d18c48c02c3d329`，build-tools 37 验证 v2 debug 签名通过。最终 logcat 未发现 `FATAL EXCEPTION`、`AndroidRuntime: FATAL`、`E/flutter` 或 App ANR。
- `git diff --check` 通过；通用凭据扫描未发现长格式 API key。Leaf 20.1 未新增数据库表、迁移或 checkpoint 编码字段，既有 plan snapshot 可继续解码和恢复。Leaf 20.1 已完成。

### Leaf 20.2：Unified verified practice target

输出：

- 新增统一的 typed practice target，将带 citation 的 verified `Question` 和 `ProgrammingExercise` 纳入同一 planner 输入。
- planner readiness 和 next step 使用真实可执行练习数量，不再把“存在编程练习”误判为“没有可练习内容”。
- executor 根据 target 类型进入普通题目或开放编程练习，并继续执行各自的来源和人工核验门禁。

验收：

- 只有编程练习、只有普通题目和两者并存时，Agent 都能选择并打开正确的已核验练习。

完成记录（2026-07-15）：

- 新增 `LearningAgentPracticeTarget` 与 `question`、`programming_exercise` 两种 typed target；只有 `source_status = verified`、存在 citation、绑定知识点且内容完整的目标会进入正式 planner 输入。普通题和编程练习继续保留各自原有表、人工核验和作答/评价页面。
- `LearningAgentReadiness`、focus point、路线指标、blocker 和 practice step 统一使用真实可执行 target 数量；编程路线存在已核验练习时，下一步可以直接进入 practice，不再出现“知识点可练习但 Agent 认为没有题”的分裂状态。
- planner 先按 Leaf 20.1 的知识范围过滤，再优先选择当前 focus point；同一点同时存在两类 target 时，以 `programming_exercise` 优先并按稳定 type/point/id 排序。更完整的开放追问、到期复习和薄弱先修优先级留到 Leaf 20.5 统一处理。
- plan snapshot 在现有 version 1 JSON 中增加可选 `practice_target` 和编程练习计数；旧 snapshot 缺少新增字段时仍可解码。新 checkpoint 的 state、trace 和 tool input 使用 typed routing id，恢复时不会把普通题和编程练习混为同一 target。
- executor 在 tool-start checkpoint 前重新从 repository 读取计划 target，并比较 type、id、知识点、核验状态和 citation；目标被删除、改绑、降级为待核验或丢失引用时由 policy 明确阻断。通过后，普通题只打开精确的 `QuizScreen` 题目，编程练习打开精确 `ProgrammingExerciseScreen.initialExerciseId`。
- 新增 8 个固定回归，覆盖只有普通题、只有编程练习、两者并存的稳定选择、无引用/未核验过滤、version 1 additive codec 兼容、两种页面路由和运行时降级阻断。checkpoint/恢复集合与范围回归一并通过；全量 `flutter test --no-pub` 为 149 tests passed。
- `flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。Android APK 完成 203 个 Gradle 任务并成功安装；`app-debug.apk` 为 190,505,602 bytes，SHA-256 为 `e1d0579e4b9a19b1a968d2ef4ca1add50cc183bdf15a1ccb91b67635135f0d20`，build-tools 37 验证 v2 debug 签名通过。
- Android `emulator-5554` 使用一条临时官方来源、片段、编程知识点和已核验编程练习验收：Agent 首页显示 `已核验练习 1`、`下一步：完成已核验练习` 和 typed target；准备页显示 `本轮编程练习` 与 1 条引用；开始后打开指定 exercise。证据保存为 `build/validation/duoduo-leaf20-2-agent-programming.*`、`duoduo-leaf20-2-session.*` 和 `duoduo-leaf20-2-exercise.*`。
- 验收后精确删除临时 source、chunk、knowledge point、exercise、1 个未完成 state 和 4 条 trace；对应计数均为 0，SQLite `integrity_check` 为 `ok`。清理后冷启动日志未发现 `FATAL EXCEPTION`、`AndroidRuntime: FATAL`、`E/flutter` 或 App ANR；`git diff --check` 与通用长格式凭据扫描通过。Leaf 20.2 未新增数据库表或迁移。Leaf 20.2 已完成。

### Leaf 20.3：Shared grounded learning context

输出：

- 抽取统一的目标级 grounded context，包含知识点、来源片段、trust、locator、逐字 quote 边界和可执行 surface。
- 知识库回答、导师、面试和编程练习评价共享同一 context selection 与 evidence gate；surface 只保留任务特有输出。
- trace 和失败诊断统一记录 context ids、选择理由和被拒绝原因。

验收：

- 同一目标在四个 surface 中解析到同一组合法证据，越界 citation 在所有 surface 中一致拒绝。

完成记录（2026-07-15）：

- 新增 `GroundedLearningContext`、`GroundedLearningContextItem`、逐字 quote boundary、四类 surface、确定性 selection reason 和结构化 rejection code；每个合法 item 同时保留 `SourceChunk`、`Source`、trust level、locator 和可审计 context ID。缺目标、缺来源、空片段、缺选择理由、必需 citation 缺失和 context 上限都有稳定诊断；必需 citation 越界会让 context 不可执行。
- 新增 `GroundedLearningContextService`，知识库检索命中、知识点来源、已确认先修、面试题引用和编程练习引用都先转换为同一候选契约，再由同一 selector 去重、过滤、限制和生成 citation subset。`GroundedClaimGate.evaluateContext` 只允许 context 内、且 quote 位于边界内的 evidence。
- `KnowledgeAnswerTask`、`TutorExplanationTask`、`TutorSocraticTask`、`InterviewQuestionTask`、`AnswerEvaluationTask` 和 `ProgrammingExerciseEvaluationTask` 保留旧 `sourceChunks` 参数作为兼容入口；真实页面必须同时传入匹配 surface 的 grounded context。task 会从 context 派生合法 chunks，错误 surface、不可执行 context、越界 citation 或错误 quote 都在请求前拒绝或按既有规则降级，不会回退读取更宽的裸 chunks。
- Provider 新增 `groundedLearningContextServiceProvider` 和 `knowledgeAnswerGroundedContextProvider`；旧 `knowledgeAnswerContextChunksProvider` 改为从新 context 派生，避免破坏既有调用。知识库回答页保存回答 context；导师页把当前知识点和已确认先修来源放入同一 context；面试页为每个知识点建立 context，并为每道题生成必需 citation subset；编程练习页按已核验 exercise citation 构造评价 context。
- Agent executor 在 tutor、interview 和编程练习 policy gate 前重新读取 point、chunk 和 source，构造同一 grounded context；`policy_checked` 和 `tool_started` trace 记录 context ID、合法 chunk IDs、trust、locator、selection reason 与 rejection reason。编程练习 citation 对应的 chunk 或 source 不可读时，正式执行会被 `grounded_context_not_executable` 阻断。
- 新增 `grounded_learning_context_test.dart` 的 6 个固定回归，覆盖四 surface 合法证据一致性、trust/locator/quote boundary、缺失 source 等候选拒绝、越界 citation subset、错误 quote、请求前阻断，以及 task 不得读取 context 外裸 chunks。更新 Agent 与 widget fixtures，使测试也提供完整 source 链路，并修复导师先修过滤错误地用 `KnowledgePoint` 对象而不是 point ID 查 map 的问题。
- 全量 `flutter test --no-pub` 为 155 tests passed。`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint；`git diff --check` 与通用长格式凭据扫描通过，匹配凭据文件数为 0。Leaf 20.3 未新增数据库表、迁移或 checkpoint 格式。
- 标准 Gradle Wrapper 因当前网络无法下载 `gradle-9.1.0-all.zip` 而停在 0 字节；改用本机完整 Gradle 9.4.1、离线缓存和 `android-x64` 完成 emulator debug 构建。`assembleDebug` 成功完成 292 个 actionable tasks；APK 为 77,760,261 bytes，SHA-256 为 `2e1338d9db1a365b848336e220db19b725969206560ed68169593ddb4acbfaea`，build-tools 37 验证 v2 debug 签名通过。
- APK 已安装到 `emulator-5554`，冷启动后完成首页、Agent 和知识库页面验收；截图、UI hierarchy 与日志保存在 `build/validation/duoduo-leaf20-3-home.*`、`duoduo-leaf20-3-agent.*`、`duoduo-leaf20-3-knowledge.*` 和 `duoduo-leaf20-3-final-logcat.txt`。最终日志未发现 Fatal、Flutter error 或 ANR，SQLite `integrity_check` 为 `ok`。Leaf 20.3 已完成。

### Leaf 20.4：Unified target memory timeline

输出：

- 将知识库回答、导师、面试、编程练习、Agent reflection 和 review action 归一为 target-level memory record。
- `LearningAgentMemoryStore` 可按 goal、target 和 record type 返回最近记录、开放追问、稳定误区、薄弱维度和下一复习时间。
- 旧 session 摘要保持可读；若需要新表，先提供无损迁移和旧记录兼容策略。

验收：

- 用户打开一个知识点时能看到跨 surface 的连续学习历史，而不是分别查找多个页面。

完成记录（2026-07-15）：

- 新增 `LearningAgentMemoryRecord`、`LearningAgentMemoryTimelineBuilder` 和统一查询快照；知识库回答、导师回合、面试回合、编程练习尝试、Agent 复盘与复习动作被归一为六种 record type，并保留 source/session、target resolution、citation、追问、误区、薄弱维度和复习时间。
- `LearningAgentMemoryStore.query` 可同时按 goal、target 和 record type 过滤，返回最近记录、跨 surface 开放追问、重复两次以上的稳定误区、按证据事件去重的薄弱维度和最早下一复习时间。旧 `LearningAgentMemoryStore(index)` 构造方式仍回退到原 Agent session follow-up index，不破坏历史调用。
- 未新增表或迁移。仓储只增加现有表的全量只读查询；新知识库回答直接保存知识点 ID 与 Grounded Context ID，旧回答继续由原 summary parser 读取，并仅在 citation 与 `knowledge_point_sources` 有可审计关系时归属到知识点。旧面试 session scope 和 question/programming-exercise Agent routing 也保留显式 resolution，不伪造未知 target。
- Provider 将现有 session、turn、exercise attempt、review action、question schedule 和知识点来源组装为同一 read model；编程练习与复习动作写入后同步失效 memory provider。知识点详情新增“连续学习历史”，显示记录总数、开放追问、稳定误区、薄弱维度、下一复习时间以及六类时间线记录。
- 新增 `learning_agent_unified_memory_timeline_test.dart` 和 `learning_target_memory_timeline_widget_test.dart`，并扩展知识库 summary 回归；固定测试覆盖六 surface 归一、旧 citation 归属、练习 routing、跨 surface 追问关闭、稳定误区、薄弱维度去重、record type/goal/target 查询、旧 store 回退和 320px 宽度布局。全量 `flutter test --no-pub` 为 159 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。
- 使用本机 Gradle 9.4.1、离线缓存和 `android-x64` 属性完成 `:app:assembleDebug`，203 个 actionable tasks 以 `BUILD SUCCESSFUL in 3m 36s` 完成。APK 为 102,377,964 bytes，SHA-256 为 `47a9be60ee58804c2a001568d905ee75b9ac08415f0e362ba65d7f071d0daf17`，build-tools 37 验证 v2 debug 签名通过。
- APK 覆盖安装到 `emulator-5554` 并冷启动成功。固定前缀验收数据在真实 `user_version=22` 数据库中生成 7 条跨 surface 记录；知识点详情 UI hierarchy 与上下两段截图保存在 `build/validation/duoduo-leaf20-4-detail-top.*` 和 `duoduo-leaf20-4-detail-lower.*`，可见知识库回答、导师、面试、编程练习、Agent 复盘和复习动作，且无文本重叠。日志未发现 Fatal、Flutter error 或 ANR；`integrity_check` 为 `ok`。验收数据已清零，清理后再次冷启动成功。数据库原有的来源/知识点外键孤儿记录在验收前后相同，本 Leaf 未擅自修改历史数据。Leaf 20.4 已完成。

### Leaf 20.5：Deterministic next-action policy

输出：

- planner 使用统一优先级处理未完成 checkpoint、开放追问、证据缺口、待核验内容、薄弱先修、到期复习和新学习。
- 每个 next action 保存可读 reason、输入快照和对应 tool；恢复时继续使用原 plan snapshot，不重新漂移路由。
- 将无法执行的动作降级为明确 blocker，不用模型猜测系统状态。

验收：

- 固定输入下 next action 稳定；改变一项状态只产生预期的单一优先级变化，并可从 trace 解释。

完成记录（2026-07-15）：

- 新增正式 `LearningAgentNextAction` 契约，将未完成 checkpoint、开放追问、证据缺口、待核验内容、薄弱先修、到期复习和新学习固定为七级优先级。候选项使用稳定 canonical key、到期时间和显式 tie-break 排序；输入顺序变化不会改变选择结果。
- planner 将选中动作的可读 reason、目标、tool、blocker 和完整候选输入快照写入现有 plan snapshot；codec、`plan_created` trace 和 runtime 诊断均可解释本次选择。高优先级动作不可执行时直接成为 blocker，不会越过它猜测或执行低优先级动作。
- checkpoint 恢复继续使用 checkpoint 中保存的原 plan snapshot，不按当前数据重新规划；缺少 plan snapshot 的旧 checkpoint 显示明确恢复 blocker。恢复决策继续记录 `user_decision_resolved` 和 `session_resumed` trace，并保持原 next action、tool 和候选快照。
- 待核验编程练习成为正式 next-action target，使用 `programming_exercise:<id>` 路由。executor 在启动工具前重新读取练习并核对 pending 状态，状态漂移时阻断；通过后精确打开 `ProgrammingExerciseScreen(initialExerciseId: ...)`，并自动显示该练习的来源核验对话框。
- 新增确定性 policy、codec、trace、checkpoint 恢复、blocker、统一 memory 输入、精确导航和状态漂移回归。Agent 定向回归集 62 tests passed；全量 `flutter test --no-pub` 为 168 tests passed。`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 35 条既有 info lint。
- 使用本机 Gradle 9.4.1 完成离线 Android debug 构建，203 个 actionable tasks 成功；APK 为 102,417,632 bytes，SHA-256 为 `cff4a6a5627c5d65808da7d9e8ca7081e247f5e63fe402042e14f49c92dd525a`，build-tools 37 验证 v2 debug 签名通过。
- APK 已安装到 `emulator-5554`。Android 固定验收覆盖空状态证据缺口、pending 编程练习、精确核验对话框、工具启动 checkpoint、冷停恢复、重新执行和缺 plan snapshot blocker；证据保存在 `build/validation/duoduo-leaf20-5-*`，其中下半屏截图完整显示对应工具与阻断原因。
- 验收后精确删除 1 条临时来源、片段、知识点、练习、关联，2 个 checkpoint 和 6 条 trace。所有 `leaf20-5-validation-*` 计数及指定 session 计数均为 0；数据库保持 `user_version=22`、`integrity_check=ok`，原有 12 条历史 foreign-key check 结果逐行未变。最终冷启动成功，logcat 未发现 Fatal、Flutter error 或 App ANR；`git diff --check` 与通用长格式凭据扫描通过。Leaf 20.5 已完成。

### Leaf 20.6：Unified Agent workspace and golden path

输出：

- Agent 第一屏围绕“当前目标、当前知识范围、证据、下一动作、历史和复习”组织，原导师/面试/练习入口保留为工具目标而不是并列产品中心。
- 新增固定统一学习黄金路径，覆盖来源导入、目标路由、grounded context、导师/面试/练习、target memory、next action 和恢复。
- Android 验收项目、编程和混合面试三种目标，保存 UI hierarchy、截图、日志和清理记录。

验收：

- 用户可以从同一 Agent 工作台完成一次有来源学习、发现薄弱点、执行练习并看到下一复习动作。
- Branch 20 关闭后才根据真实远程并发、跨设备、语义召回或规模证据决定 Branch 21 的生产升级。

完成记录（2026-07-16）：

- 新增 `LearningAgentWorkspaceSnapshot` 与 workspace service/provider，将当前 plan、goal、scope、统一 memory、历史数、开放追问、待复习数量、下一复习时间和工具目标收敛为一个只读工作台契约。导师、面试、已核验练习和复习始终作为核心工具目标可见，但只有确定性 policy 选中的目标可执行，并明确区分 `nextAction`、`available`、`blocked` 和 `unavailable`。
- Agent 首页改为先展示统一 plan，再展示 checkpoint、记忆和工具目标；路线卡补充历史、待复习和下一复习时间，详细 session 依据折叠到“计划依据”。原导师、面试和复习三张并列模式卡已移除，功能入口保留为同一 planner 管理的工具目标。
- 新增固定统一黄金路径 fixture 和回归，覆盖两份可审计来源导入、项目/编程/混合三种 scope、导师/面试/编程练习评价共享 grounded context、跨 surface memory 写入、开放追问优先于到期复习、workspace 工具目标，以及 checkpoint 恢复继续使用原 plan snapshot。Agent 定向回归 65 tests passed；全量 `flutter test --no-pub` 为 171 tests passed；analyzer 为 0 errors、0 warnings，仅 35 条既有 info lint。
- 使用本机 Gradle 9.4.1、离线缓存、单 worker、关闭 Kotlin incremental 并采用 in-process compiler 完成 `android-x64` debug 构建；203 个 actionable tasks 成功。APK 为 102,409,597 bytes，SHA-256 为 `9ea1d88d92a1253dd9c7ee969399cea34041a8d07a2ccfcadcec37a090c704d2`，build-tools 37 验证 v2 debug 签名通过。
- APK 覆盖安装到 `emulator-5554` 后，以统一 `leaf20-6-validation-*` fixture 验收项目、编程和混合目标。三种范围、历史数、确定性 next action 和四个核心工具目标均由 UI hierarchy 断言；截图保存在 `build/validation/duoduo-leaf20-6-project-*`、`duoduo-leaf20-6-programming-*` 和 `duoduo-leaf20-6-mixed-*`。混合目标的“启动面试模式”进一步打开来源约束 `Agent Session`，显示同一知识点的证据、已核验题和面试讲法。
- 验收后按依赖顺序精确删除 2 个来源、2 个片段、2 个知识点、2 个关联、1 个题组、2 道题、1 个编程练习、2 个 session、1 个导师回合、1 个面试回合和 1 个练习尝试；所有临时前缀计数均为 0。设备数据库与清理副本 SHA-256 一致，保持 `user_version=22`、`integrity_check=ok`，原有 12 条 historical foreign-key check 结果逐行未变。
- 最终 Android 冷启动为 `LaunchState=COLD`，耗时约 3.19 秒；空态首页布局正常，logcat 未发现 `FATAL EXCEPTION`、`AndroidRuntime: FATAL`、`E/flutter` 或 App ANR。`git diff --check` 与通用长格式凭据扫描通过。Leaf 20.6 已完成，Branch 20 已关闭。

Branch 20 状态：已关闭。Leaf 20.1 至 20.6 均已完成；统一 planner、scope、grounded context、target memory、deterministic next action 和 Agent workspace 已形成可回归的本地优先基线。

## Branch 21：Private Alpha Productization

状态：进行中。Leaf 21.1 至 21.5 已完成；Leaf 21.6a 私测准备、Leaf 21.6b 命名模型 profile 与 Leaf 21.6c 正确性压力基准已实现；真实 Leaf 21.6 cohort 待执行。

Branch 用户结果：10 名准备 AI 应用开发面试的开发者可以独立安装 App，从自己的项目完成第一轮有来源学习，查看可审计的项目面试成果，导出或删除本地数据，并提交脱敏反馈。

约束：继续使用 Branch 20 的 Flutter + Dart + SQLite 本地 runtime。产品化不以远程 graph、云同步、向量库或多 Agent 为前置条件。

### Leaf 21.1：Private Alpha 产品契约与验收矩阵

输出：

- 固定产品承诺、首批 persona、Jobs To Be Done、激活定义、首次运行状态机、项目面试成果契约和 Private Alpha 发布门槛。
- 定义不可变本地事件 envelope、事件白名单、North Star、激活/留存/学习/可靠性指标和 10 人研究节奏。
- 使用官方来源调研 NotebookLM、ChatGPT Study Mode、Anki、RemNote、DeepWiki、Cody、HEART 与 NIST AI RMF，并记录可借鉴能力和不应复制的边界。
- 模型验收必须在 App 的普通 Dart/Dio 通道中完成严格 JSON、中文七绝、Dart 编程、逐字引用绑定和证据不足拒答五项任务；单项与整轮都必须有可记录超时。

验收：

- 产品契约、研究证据、事件模型、指标假设、发布矩阵和后续五个 Leaf 可以直接指导实现，没有把基础设施升级伪装成用户需求。
- 任何新增供应商只有五项全部通过才可成为正式学习配置；失败、超时或跳过项都不能获得 approval。

完成记录（2026-07-16）：

- 新增 `docs/private-alpha-product-research.md` 与 `docs/private-alpha-product-contract.md`。产品定位固定为“帮助开发者理解并讲清自己 AI 项目的可溯源个人学习 Agent”；激活固定为第一轮有来源学习持久化，North Star 固定为 `Weekly grounded learning closures`。
- Branch 21 重排为首次引导、本地事件与隐私、项目面试成果、可靠性与发布控制、10 人私测五个后续 Leaf。云同步、向量检索、远程 runtime 和多 Agent 移到 Alpha 后条件轨道。
- `AiModelAcceptanceRunner` 增加默认 60 秒单项超时和 4 分钟整轮上限。超时形成可持久化 `timeout` 报告并阻断后续任务，不再让设置页无限显示“验收运行中”；供应商和未知错误也记录真实等待时长。新增永不返回客户端回归。
- Android debug 构建仅在 `src/debug/AndroidManifest.xml` 允许明文 HTTP，用于验证用户提供的开发节点；正式 manifest 未放开明文流量。API Key 仍只进入系统安全存储，普通偏好中的敏感键计数为 0。
- 六组新增候选均未通过正式门槛：一组 HTTPS 节点的 Chat 首项返回无效凭据且主机复核被限流；一组 HTTP 节点的 `gpt-5.5 + Chat` 首项超时且主机结构化任务复核为 503；另一组 HTTPS 节点的 Chat/Responses 请求被 403 拒绝；后续 HTTP 节点以真实中文诗词任务测试 `gpt-5.6-sol` Responses/Chat 与 `gpt-5.5` Chat 时均快速返回空 503，鉴权模型目录也返回空 503；第五组 IP 地址候选在原 HTTP scheme 下主要返回“HTTP 请求发送到 HTTPS 端口”，另一次 Chat 返回空 503，临时 HTTPS 诊断又得到 403/421、TLS 失败和拒绝连接；第六组 IP 地址候选的 `gpt-5.6-sol` 与 `gpt-5.5` Responses 真实诗词任务同样先得到 HTTP/HTTPS scheme 错误，纠正为 HTTPS 并使用 Codex 风格 user agent 后仍在模型输出前被 Cloudflare 403 拒绝，因此也未进入 App 五项矩阵。除该次明确授权的客户端标识诊断外，其余测试未伪装客户端身份；所有测试均未持久化候选地址、凭据、配置或响应。当前不批准默认或备用模型配置。
- 当前“自定义”供应商只有一个 provider-scoped 凭据槽，不适合作为多个公共中转的长期 profile 管理。Private Alpha 发布前必须由用户自有凭据或受控服务端代理产生至少一个 App 五项全通过 profile；公用测试凭据不写入仓库、文档、fixture、普通偏好或验收产物。
- 定向模型协议与验收回归 10 项通过；全量 `flutter test --no-pub` 为 172 tests passed。`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 35 条既有 info lint。
- 离线 Gradle 9.4.1 使用单 worker、关闭 Kotlin incremental 和 in-process compiler 完成 `:app:assembleDebug`，203 个任务成功。最终 APK 为 102,415,169 bytes，SHA-256 为 `10c1247629851b38ae65a678bf103d5699be1e34f05b2e589c64f8c1681d201a`，build-tools 37 验证 v2 debug 签名通过。
- 最终 APK 覆盖安装和冷启动成功，真实数据库保持 `user_version=22`、`integrity_check=ok`；日志没有 Fatal、Flutter error、ANR 或明文流量拦截。已通过 App 清除失败的公共凭据，普通偏好敏感键计数为 0；335 个 tracked/untracked 文件的精确凭据扫描匹配数为 0，文档尾随空格与 `git diff --check` 通过。

Leaf 21.1 已完成。

### Leaf 21.2：Goal-led first run

输出：

- 实现可恢复的首次运行状态机：目标选择、模型就绪、项目导入、coverage review、第一轮 Agent 学习、成果预览。
- 每个 durable boundary 写入恢复状态，重新启动继续原 plan snapshot，不重置用户选择。
- 模型不可用时显示稳定 blocker，并允许先完成不依赖模型的本地导入和证据检查。

验收：

- 干净安装无需开发者介入即可进入第一轮已持久化 grounded turn；中断后从每个边界恢复。

完成记录（2026-07-16）：

- 新增 schema version 1 的 `FirstRunProgress`、SharedPreferences store、bootstrap/reconcile service 和 Riverpod notifier。记录只包含 step、goal、source/session ID 与时间戳，不复制 API Key、源码、模型原文、知识点或会话内容；目标、来源、核验内容和完成会话继续分别由既有偏好、SQLite repository、acceptance store 与 Agent checkpoint/runtime 持有真相。
- 启动入口新增 `FirstRunGate`，按 `Goal -> Model readiness -> Project import -> Coverage review -> First session -> Outcome preview` 六步推进。每个 durable boundary 写入后即可重启恢复；来源被删除时只回退到项目导入，已保存 source/chunks、知识点关系或完成 Agent Session 可在偏好写入中断后由现有数据重新推导。
- 老用户 bootstrap 会检查已有来源、题组、题目、学习会话和既有非敏感配置；检测到数据后只写 `legacy_user=true` 的 completed marker，不修改或删除原数据库内容。模拟器保留数据覆盖安装后生成 schema 1 completed marker，并直接进入原五标签主界面，没有被强制进入 onboarding。
- 首次运行模型页复用现有安全凭据、协议配置和五任务验收报告。未配置凭据或未通过验收时显示稳定 blocker，但“继续导入本地项目”仍可执行；coverage 页只在同一 provider/base URL/model/protocol 组合通过验收后开放 AI 生成。
- `ProjectImportScreen` 新增 typed `ProjectImportResult` 和 `localMaterialOnly` 模式。`SourceGroundedIngestionService.saveSourceMaterial` 以事务保存 source/chunks，对同一 snapshot 幂等且不读取模型；`saveReviewedContent` 可验证并复用预存材料，避免重复插入来源。新增 `ProjectLearningDraftService` 复用原 project-understanding、question-generation、citation-precheck 与 `KnowledgeReviewScreen`。
- 首次会话直接进入统一 `AgentHomeScreen`。新 `returnAfterSessionCompletion` 只回传既有 `Navigator<bool>` 完成信号；实际 plan snapshot、tool trace、reflection 和恢复语义仍由原 Agent runtime/checkpoint 保存。成果预览读取首个 verified project unit、真实 source chunk、已完成 session 摘要和 planner 下一动作，不把模型生成文本直接标记为掌握。
- 新增首次运行进度、真实 SQLite clean-install、legacy bootstrap、缺来源回退、跨 source/content/session 恢复、无模型 blocker、本地 material-only 导入和预存材料核验回归。全量 `flutter test --no-pub` 为 184 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 35 条既有 info lint。360x800 Widget 验收未发现 overflow 或运行时异常。
- 离线 Gradle 9.4.1 使用单 worker、关闭 Kotlin incremental 和 in-process compiler 完成 203 个任务，`BUILD SUCCESSFUL in 32s`。APK 为 102,480,848 bytes，SHA-256 为 `63d9b16dce740b4d8b05dc407ed8a9528730abd81b34f07db2b4a99d920e306c`，build-tools 37 验证 v2 debug 签名通过。
- APK 以 `-r` 覆盖安装到 `emulator-5554` 并保留数据，冷启动 `LaunchState=COLD`、总耗时约 4.86 秒；截图为 `build/leaf21_2_existing_user.png`。设备数据库保持 `user_version=22`、`integrity_check=ok`，logcat 未发现 Fatal、Flutter 或 SQLite 错误。新增公共凭据和地址的精确仓库扫描匹配数为 0；最新 HTTP 候选的 Responses、Chat、另一模型 Chat 和 model directory 均返回空 503，因此仍不批准默认模型。Leaf 21.2 未新增数据库表或迁移，已完成。

### Leaf 21.3：Local events and privacy controls

输出：

- 增加 schema-versioned 本地产品事件、事件检查/导出、同意设置、分范围删除和脱敏 support bundle。
- 默认事件不含源码、用户答案、模型原文、绝对私有路径、查询参数或凭据。

验收：

- 固定黄金路径产生精确事件序列；导出与数据库扫描都不包含禁止字段。

完成记录（2026-07-16）：

- 数据库升级到 schema v23，新增不可变 `product_events` 表、时间/事件索引和唯一 `dedupe_key`。新增强类型 `ProductEventName`、schema-versioned envelope、repository 和 recorder；每个事件在写入前执行属性白名单、必填字段、稳定值长度和禁止内容校验。
- 新增 schema v1 隐私偏好、匿名安装 ID、本地产品事件开关和 Agent 运行摘要单独同意。首次运行、模型验收、项目导入/核验、Agent 工作台、导师/面试/编程 grounded turn、复习、支持包和删除路径已接入正式事件；`outcome_*` 与 `feedback_submitted` 保留为 Leaf 21.4/21.6 契约。
- 新增 `PrivacyRedactor`、`SupportBundleService` 和 `LocalDataDeletionService`。事件导出不含内部 dedupe key；支持包只含版本、schema、表计数、稳定状态、验收摘要、安全事件摘要和可选的聚合 Agent 阶段/类型计数。API Key、Authorization、源码/文件内容、用户答案、模型原文、私有绝对路径和 URL 查询参数均被拒绝、移除或省略。
- 设置页新增“本地数据与隐私”，支持事件检查、JSON 导出、脱敏支持包导出、两个开关，以及学习历史、来源与学习内容、产品事件、模型配置与所有 provider 凭据、首次运行状态五种删除范围。删除产品事件会重置匿名安装 ID，并只保留新的 `data_deleted` 审计事件。
- Android 首轮删除验收发现隐私页无差别失效全部 provider 会让隐藏 Agent 标签立即补写 `agent_workspace_viewed`；刷新逻辑改为按删除范围执行。修复后先制造 3 条事件再仅删除产品事件，设备数据库最终只剩 1 条新安装 ID 下的 `data_deleted`，UI hierarchy 与截图 `build/validation/leaf21_3_privacy_after_delete.*` 一致。
- 固定 Private Alpha grounded path、属性门禁、脱敏、support bundle、范围删除、v22 -> v23 迁移和 320x800 隐私页回归均通过。Widget 测试显式关闭非目标事件记录，不再输出未初始化 SQLite 的 best-effort 噪音。全量 `flutter test --no-pub` 为 194 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint；`git diff --check` 与 credential-shaped 扫描通过。
- 使用离线 Gradle 9.4.1、单 worker、关闭 Kotlin incremental 和 in-process compiler 完成 203 个任务。最终 x86_64 debug APK 为 102,542,442 bytes，SHA-256 为 `0067eacbad3640d85f6f6eb717872b7d733521b11c3154c3b7b1b8b38ce44124`，build-tools 37 验证 v2 debug 签名通过。覆盖安装前设备为 `user_version=22`、`integrity_check=ok` 且无事件表；安装后为 v23、迁移前数据计数保持不变、foreign-key check 为空。最终冷启动约 4.87 秒，logcat 未发现 Fatal、Flutter、ANR、SQLite exception 或 database lock。
- 真实 Android 事件导出和开启 Agent 聚合摘要后的支持包均保存成功；结构化禁止字段、凭据、私有路径和带 query URL 扫描为 0。临时 JSON 与数据库副本在验收后删除，保留不含敏感内容的隐私页截图/UI hierarchy。Leaf 21.3 已完成。

### Leaf 21.4：Project interview outcome

输出：

- 基于 verified unit、grounded context、统一 memory、真实回答和复习动作构建项目面试成果 read model。
- 提供 ready、needs practice、evidence gap、not assessed 状态，以及 Markdown/纯文本导出。

验收：

- readiness 不能仅由模型生成内容触发；每条正式导出内容都能定位到保存的来源证据。

完成记录（2026-07-16）：

- 新增确定性的 `ProjectInterviewOutcomeService` 与 Riverpod read model，聚合 verified project unit、知识点来源关系、源码片段、面试/导师/编程真实回答、已核验练习、统一 memory 和未完成复习动作。Agent 首页、完整成果页与首次运行结果预览读取同一 provider，不再维护两套成果判断。
- 状态固定为 `ready`、`needs_practice`、`evidence_gap` 和 `not_assessed`。面试 ready 要求四项评分均至少 4/5、真实用户回答、完整 grounded evaluation 且没有待处理工作；替代路径只接受通过来源核验并达到掌握门槛的真实练习。模型文本、mastery 数字或未核验练习单独存在时都不能触发 ready。
- 评估引用必须属于当前单元保存的 evidence，逐字 quote 必须通过校验；越界 citation、quote mismatch 或练习证据缺陷进入 `evidence_gap`。最强证据按信任级别、关系、代码定位和稳定 ID 确定性排序；正式参考提纲只包含通过校验的 `reference_answer` claims，不混入反馈文本。
- 新增项目面试成果页、四态筛选、可展开单元详情、四维评分、用户最近回答的非事实标记、来源支持提纲与代码 locator。Markdown/纯文本导出包含 UTC generated-at、状态、理由和 `[S*]` 来源索引；无来源的单元不会导出伪造 citation。
- 接入 `outcome_viewed` 与 `outcome_exported`。页面 state signature 只抑制同一次页面实例的 rebuild 重复，重新打开页面会记录新的 view；事件只包含四态计数、导出格式和 citation 数，不保存答案、源码、模型输出、凭据或绝对路径。
- 新增四态矩阵、模型文本/mastery-only 拒绝、已核验练习门槛、citation/quote 缺陷、稳定证据排序、feedback 排除、Markdown/纯文本 locator、真实 SQLite、320px 窄屏、首次运行共享 provider 和事件隐私回归。全量 `flutter test --no-pub` 为 206 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。
- 使用离线 Gradle 9.4.1、单 worker、关闭 Kotlin incremental 并采用 in-process compiler 完成 292 个任务。x86_64 debug APK 为 78,049,433 bytes，SHA-256 为 `68f54825b8e4ce27068980c9737fd42c8a3c41e4c38bd63db425bdd035f1a7eb`，build-tools 37 验证 v2 debug 签名通过。
- APK 覆盖安装到 `emulator-5554` 后冷启动成功。真实 fixture 同时显示 `可面试 1 · 需练习 1 · 证据缺口 1 · 未评估 1`，展开 ready 单元可见 4/5 四维评分、用户回答、来源支持提纲和 `lib/agent/runtime.dart:40-46`；Android DocumentsUI 成功导出带 3 个来源索引的 Markdown。连续两次打开成果页产生两条无 dedupe key 的 `outcome_viewed`，导出产生一条 `outcome_exported`，事件扫描不含禁止字段。fixture 数据库保持 `user_version=23`、`integrity_check=ok`、foreign-key check 为空；验收后恢复安装前数据库，恢复前后 SHA-256 完全一致，并删除设备导出和临时数据库副本。

Leaf 21.4 已完成。

### Leaf 21.5：Reliability and release controls

输出：

- 增加破坏性操作前备份、恢复 UX、版本与关于页、无障碍检查、支持设备矩阵和 Alpha checklist。
- 固化安装、迁移、冷启动、中断、删除、导出、恢复、凭据扫描和截图检查。

验收：

- 选定 Android 目标上的发布练习可复现，失败都有稳定错误码和恢复路径。

完成记录（2026-07-16）：

- 新增本地 SQLite 备份服务：使用 `VACUUM INTO` 创建一致快照，限制 512 MB，检查 SQLite header、schema 12-23、`integrity_check`、必要表和外键问题数量。
- 恢复流程先 staging 和校验，再创建内部 rollback snapshot、关闭连接、替换数据库、执行正常迁移并复检；替换后的任意失败会恢复原数据库并重新打开。错误码固定为 `invalid_file`、`unsupported_schema`、`integrity_failure`、`missing_tables` 和 `restore_failure`。
- 隐私页新增数据库备份、恢复替换确认、恢复后统一 read-model 刷新，以及数据库范围删除前的“直接删除 / 备份后删除”决策。备份明确排除模型凭据/配置、首次运行状态和隐私偏好。
- 新增统一 `AppMetadata`、Private Alpha 关于页、支持范围与已知限制；应用显示版本和事件 envelope 版本都与 `pubspec.yaml` 对齐。
- 新增真实文件型 SQLite 快照、v22 -> v23 恢复迁移、无效文件拒绝、替换后失败自动回滚、恢复确认、删除前备份、320px 窄屏、200% 字体和 semantic tap action 回归。
- 新增 `docs/private-alpha-release-checklist.md`，固定 Android API 36 x86_64 Tier A 目标、API 24-35 Arm64 候选设备、构建/安装/迁移/中断/删除/导出/恢复/凭据/截图门槛和失败恢复路径。
- 全量 `flutter test --no-pub` 为 215 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。`git diff --check` 与凭据形态扫描通过。
- 离线 Gradle 9.4.1 使用单 worker、关闭 Kotlin incremental、采用 in-process compiler 和 `-Ptarget-platform=android-x64` 完成 203 个任务。APK 为 78,072,121 bytes，SHA-256 为 `ee166a61343c19b07ad31ca00b8adf3699a2f572006d72ab9ad523c3ff5fa6ab`，v2 debug 签名通过；包名为 `com.example.dlg_q`，版本为 `1.0.0+1`，min/target/compile SDK 为 24/36/37。
- APK 覆盖安装到 `emulator-5554` 后首次冷启动约 5.84 秒。About 页、隐私页、删除准备和恢复确认的截图/UI hierarchy 均通过目视与语义检查；未发现裁切、重叠或不可点击的关键操作。
- Android DocumentsUI 真实完成数据库导出、保存取消保护、直接删除、备份后删除和恢复。删除产品事件后数据库只剩新 `data_deleted` 审计事件；恢复后原两条事件无需重启即刷新，并在冷启动后继续存在。恢复数据库为 schema 23、`integrity_check=ok`，App 日志未发现 Fatal、Flutter、ANR、SQLite、锁或恢复错误。
- 验收导出与设备临时文件已删除；安装前数据库最终按 SHA-256 `65872231a9a9ad7248368d6e760a07c359f2efd43e42ab5623e3df377904a892` 逐字节恢复。

Leaf 21.5 已完成。

### Leaf 21.6a：Private Alpha cohort readiness

输出：

- 在首次运行、Agent 工作台、项目面试成果页和可见错误态提供显式反馈导出入口；导出前展示范围，脱敏诊断默认关闭并单独同意。
- 提供本地事件聚合器、运营 CLI、参与者指南、运行手册、固定报告模板和无敏感信息的 JSON CLI fixture。

验收：

- 反馈正文只进入用户确认保存的脱敏 JSON；`feedback_submitted` 只保存类别、严重程度和诊断同意状态，取消 DocumentsUI 保存不记录事件。
- 重叠事件导出按 `event_id` 去重；样本不足或观察期不足时固定返回 `insufficient_data`，不得重定义目标或把 fixture 当成 cohort 结果。

实现记录（2026-07-16）：

- 四个入口与反馈对话框完成，320px + 200% 字体回归通过；聚焦 UI 回归 9 tests passed。
- 指标聚合覆盖激活、激活时间、grounded closure、7 日第二次 closure、第二周返回 proxy、证据合规和反馈分布；固定单人导出经 CLI 同时生成 Markdown/JSON，五项正式目标均保持 `insufficient_data`。
- 全量 `flutter test --no-pub` 为 224 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。
- 当前 Gradle 9.1.0 wrapper 使用带引号的 PowerShell `-P` 参数离线完成 203 个任务；APK 为 78,086,441 bytes，SHA-256 为 `2f4235312dabe35d2f740206830818a022b3d7771c45224a6e840082b7777fde`，v2 debug 签名通过。覆盖安装后冷启动约 6.06 秒，进程正常存活。
- Android Agent 工作台反馈入口通过目视与 DocumentsUI 验收：取消保存后 `feedback_submitted=0`；确认保存后导出包含显式测试正文和 opt-in `redacted_diagnostics`，数据库恰好新增 1 条反馈事件，属性仅含 category、severity 和 diagnostic consent。导出未发现凭据形态、Authorization 或私有 Windows 路径。
- 验收后删除设备导出和临时文件，恢复安装前数据库；最终 SHA-256 为 `65872231a9a9ad7248368d6e760a07c359f2efd43e42ab5623e3df377904a892`，schema 23、`integrity_check=ok`，App 已停止。

Leaf 21.6a 的实现与 Android 准备验收已完成；它不代表真实 cohort 已运行，也不解除模型 profile `5/5` 门槛。

### Leaf 21.6b：Named long-lived model profiles

输出：

- 增加 `Grok 4.5 通道（主）` 与 `Mimo 通道（备）` 两个长期候选 profile；每个 profile 独立保存 base URL、模型、协议和 provider-scoped 安全凭据，并读取自身的固定矩阵验收报告。
- 设置页切换 profile 时只加载目标 profile，保存时只更新当前 profile。两个命名槽位默认使用 Responses，但不内置 endpoint、模型或 API Key，也不实现自动故障转移。
- 删除模型配置时清除全部 `ai_profile.*` 普通偏好和所有 provider 安全凭据，避免删除后留下隐藏的长期通道配置。

验收：

- Grok 与 Mimo 来回切换不会覆盖彼此配置或凭据；旧全局模型配置只迁移到迁移时激活的 provider，不复制到其他 profile。
- “主/备”只表示运营优先级。每个精确 `provider + sanitized base URL + model + protocol` 组合必须分别在 App 内完成 `5/5`；命名、短期可用或另一通道通过都不构成批准。

完成记录（2026-07-16）：

- `OpenAIService` 新增 `custom_grok_primary`、`custom_mimo_fallback` 和 `ai_profile.<provider>.*` 配置命名空间；设置页按 provider 加载配置、凭据状态与验收报告。新增 profile 排序、隔离、旧配置迁移、隐私删除和设置页切换回归，四个聚焦测试文件共 18 tests passed。
- 全量 `flutter test --no-pub` 为 229 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。
- Android 离线构建完成 203 个 actionable tasks，`BUILD SUCCESSFUL in 3m 45s`。APK 为 102,987,855 bytes，SHA-256 为 `73e3e6e88380eb3fa894a999ca6bf60a4d716e423faa6cf26a8eac734f3d924b`，APK Signature Scheme v2 验证通过。
- `emulator-5554` 上的 provider 菜单、Grok 主通道和 Mimo 备用通道均通过目视与 UI hierarchy 验收。两个 profile 初始均为 Responses，endpoint、模型和凭据为空，验收过程中未点击保存；设备原激活 provider 仍为 `custom`，两个新 profile 的持久化键计数均为 0。
- 保留证据为 `build/validation/leaf21_6b_provider_menu.*`、`leaf21_6b_grok.*` 和 `leaf21_6b_mimo.*`，不含 endpoint 或凭据。Smoke 仅新增 1 条 `product_events`；验收后原数据库按 SHA-256 `65872231a9a9ad7248368d6e760a07c359f2efd43e42ab5623e3df377904a892` 逐字节恢复，schema 23、`integrity_check=ok`，App 已停止，日志未发现 Fatal、Flutter、ANR 或 SQLite 错误；设备 UI dump 已删除。

Leaf 21.6b 已完成，但没有批准任何精确模型组合，也不解除 Leaf 21.6 的 `HOLD`。

### Leaf 21.6c：Correctness retrieval stress baseline

输出：

- 增加中英混合提问、64 个大语料干扰片段和冲突来源关键词堆砌三类离线检索 fixture。
- 保留纯英文查询现有行为；中文查询只扩展明确的 AI/编程双语概念，并归一化 `rollback` 与 `roll(s) ... back` 文档形态。

验收：

- 三类 case 的正确来源片段均为第一名，Recall@1 与 MRR 均为 1.0；选中上下文必须保留 locator、exact quote 和可检查的来源可信度原因。
- 不通过无条件提高官方来源优先级掩盖相关性，也不把该小 fixture 宣称为任意语言或生产规模语义检索能力。

完成记录（2026-07-17）：

- 新增 `SearchQueryTermService`，纯英文查询仍使用去重空格词项；含中文查询提取 ASCII 技术锚点并补充 mode、guarantee、conformance、transaction、atomic、rollback、retry、backoff、timeout、citation 和 evidence 的显式中英概念。现有 `KnowledgeSearchService` 的打分、信任缩放、稳定排序和解释结构保持不变。
- 首轮压力测试真实暴露 `rollback` 无法命中 SQLite 原文 `rolls them back`，导致生成文章干扰片段排在官方证据前。修复只增加 `roll back`、`rolls back`、`rolls them back` 和 `rolled back` 形态，不调整 trust 权重；旧检索、baseline 和 closure golden path 均保持通过。
- 新 fixture 固定 3 个 case、64 个生成干扰片段、冲突个人笔记、正确 evidence id、locator 和 exact quote。聚焦正确性回归 11 项通过；全量 `flutter test --no-pub` 为 240 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info。
- 当前 Arm64 debug APK 离线完成 203 个 actionable tasks，大小 140,589,086 bytes，SHA-256 为 `e8dbf4ec2c057303248a86920f552fdcb584a0b39ae5bfc271e2fb0a0078766a`，v2 签名通过且只包含 `lib/arm64-v8a/libflutter.so`。真机仍未连接，因此没有把该构建宣称为新的物理设备 UI 验收证据。

Leaf 21.6c 已完成，但真实跨语言自然改写、生产语料规模和 live-provider 一致性仍需后续独立标注集证明。

### Leaf 21.7：机器可读的 Private Alpha readiness

目标：把长发布清单中的关键外部门槛收敛为稳定、可审计的 `GO/HOLD`
判定，避免把离线 fixture、模拟器证据或共享公开中转误写成正式 Alpha
通过。

输出：

- 新增纯 Dart `PrivateAlphaReadinessService`，逐项判断自动门禁、Android
  构建、Arm64 真机、受控凭据、数据处理责任人、发布日精确 `5/5` 和真实
  cohort，并返回稳定 blocker code。
- 新增 `tool/private_alpha_readiness.dart`，从显式 JSON 证据生成 Markdown
  或 JSON；`GO` 返回 0，合法 `HOLD` 返回 2，输入错误返回 64/66。工具不读取
  密钥、不访问网络，也不操作设备。
- 当前 fixture 如实保留 `physical_device_pending`、
  `controlled_credential_required`、`data_processing_owner_required`、
  `release_day_acceptance_pending` 和 `cohort_pending`，不会把技术回归通过等同
  于正式邀请条件满足。

验收：聚焦服务测试 3 项覆盖当前 HOLD、全门槛 GO、缺失或非布尔字段拒绝；
当前 fixture 的 CLI 如实输出 HOLD 和 5 个 blocker。全量 `flutter test
--no-pub` 为 243 tests passed；`flutter analyze --no-pub --no-fatal-infos`
为 0 errors、0 warnings，仅 34 条既有 info；format、`git diff --check`、凭据
形态扫描均通过。

Leaf 21.7 已完成。正式 Alpha 仍保持 `HOLD FOR CONTROLLED CREDENTIAL`；真机
批量入口点击、发布日精确 profile `5/5` 和真实 cohort 均为外部待验收项。

### Leaf 21.8：独立来源正确性标注集 v1

目标：在不依赖网络、模型或真机的前提下，把自然改写检索、错误来源冲突和
claim 级语义支持纳入版本化正确性证据，先用失败数据决定是否需要改 ranker。

输出：

- 新增 6 个主题、18 条 canonical/中文自然改写/英文自然改写查询，以及 6 个
  同词面但结论错误的个人笔记 hard negative。三类查询分别报告 Recall@1 和
  MRR，不用汇总分数掩盖自然改写退化。
- 新增人工标注指南，将 `full`、`partial`、`none` 语义支持与 locator、exact
  quote 的机械可检查性分开；LLM judge 不作为唯一 ground truth。
- 首轮真实暴露中文“原子事务回滚”只展开 `rollback`、未展开 `rolls them
  back`，导致错误个人笔记排第一。修复让英文多词别名和中文概念共享明确
  词形，没有调高官方来源权重。

验收：三类 query variant 各 6 条，Recall@1 与 MRR 均为 1.0；claim 标注完整
覆盖 full/partial/none。聚焦检索回归 8 项通过；全量 `flutter test --no-pub`
为 246 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、
0 warnings，仅 34 条既有 info。

Leaf 21.8 已完成。该 fixture 在实现期间可见，因此只证明回归合同，不宣称为
held-out 或生产质量估计；下一阶段仍需自然采集且首次评估前冻结的查询集。

### Leaf 21.9：冻结 blind proxy 与首次未调优基线

目标：在不根据当前查询词表选题的情况下，先冻结一批新的自然问法，再记录
当前 lexical ranker 的真实首次结果；本 leaf 不允许看到结果后补 alias 调参。

输出：

- 两个 clean-context 默认探子独立给出候选题，主线程排除无效 locator 和来源
  类型不匹配案例，并通过 `smart-search fetch` 核验 6 个官方页面及关键表述。
- 冻结 tool calling、prompt injection、embedding、HTTP idempotency、Flink
  checkpoint 和 OpenTelemetry observability 六个主题，共 18 条 canonical、
  中文自然问法和英文自然问法。fixture 首次评估前 SHA-256 固定为
  `ec321abf442232fb01a682b5597994cdfff120628907f0867c08effdca14cee7`。
- 首次未调优结果：canonical Recall@1/MRR 为 1.0/1.0；中文自然问法为
  0.1667/0.1667；英文自然问法为 0.8333/0.9167。结果独立保存为只允许提升、
  不允许退化的 baseline，未据此修改检索实现。

结论：数据首次给出了明确的自然中文语义召回缺口，已满足评估通用双语或 hybrid
retrieval 的证据触发条件；不应继续靠查看 blind case 后手写同义词表。

验收：冻结文件哈希、18 条 case 和三类首次指标均由测试锁定。聚焦正确性回归
6 项通过；全量 `flutter test --no-pub` 为 247 tests passed；`flutter analyze
--no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info。

Leaf 21.9 已完成。该集合仍是 agent-authored proxy，而非真实用户自然查询；下一
leaf 应先评估可解释、离线可回退的 bilingual/hybrid retrieval 方案，再决定实现。

### Leaf 21.10：可解释 hybrid retrieval 编排合同

目标：为模型 query rewrite、本地语义候选或未来 embedding 建立同一个确定性
融合边界，同时保证无模型、失败或隐私拒绝时原 lexical search 完整可用。

架构取舍：

- FTS5 适合后续解决全量内存扫描和索引规模，但不能直接解决纯中文查询到纯英文
  chunk 的跨语言召回，因此不把它伪装成本轮正确性修复。
- 当前仓库没有 ONNX/TFLite runtime、模型资产、向量索引、ABI 和包体预算，暂不
  直接捆绑本地多语 embedding。
- 现有 Responses/Chat profile 可提供可选 query rewrite，但实时 `onChanged`
  不能直接发模型请求；后续接线必须 opt-in、debounce、取消旧请求，并只发送用户
  显式 query，不能附带来源正文、路径、历史或凭据。

输出：

- 新增 `HybridKnowledgeSearchService` 与 `SearchQueryVariantProvider` 合同。原始
  query 永远是第一分支，最多接收有限且去重的 model/local-semantic variants。
- 使用确定性 reciprocal-rank fusion；每个结果保留原 lexical breakdown，并新增
  原始、模型改写、本地语义分支排名与 RRF 分数，不伪造 exact citation。
- provider 缺失时为 lexical-only；provider 抛错时返回相同 lexical 排序并记录
  fallback；扩展方不能声明 replacement original。

验收：聚焦 hybrid、冻结 baseline 和旧 ranking 合同 8 项通过；全量 `flutter
test --no-pub` 为 251 tests passed；`flutter analyze --no-pub
--no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info。

Leaf 21.10 已完成编排合同，但尚未把任何外部模型接入实时搜索。下一 leaf 是实现
privacy-safe、默认关闭的 model query rewrite adapter 与 debounce UI orchestration，
并继续以原始 lexical branch 作为不可移除的 fallback。

### Leaf 21.11：默认关闭的 privacy-safe 模型改写搜索

目标：把 hybrid 合同接入真实知识库搜索，但只有用户显式开启后才调用已经通过
验收的当前 provider/model/protocol；本地结果不能被网络等待或失败阻塞。

输出：

- 新增独立 `SearchPreferences` store/notifier，`modelAssistedSearchEnabled`
  默认 `false`，设置页 AI 配置区提供持久化开关。
- 新增 `ModelSearchQueryVariantProvider`。请求只含搜索框 query，不存在 corpus、
  chunk、来源正文、路径、历史或答案参数；PrivacyRedactor 检测到 key、token、
  私有路径或带敏感查询参数的 URL 时，在 transport 前拒绝。
- 输出只接受完整 JSON object 或单个 fenced JSON；自然语言、数组和 malformed
  JSON 不作为 query。OpenAIService 原有 acceptance gate 未绕过，因此缺 key、
  未验收 profile 或 provider 故障都进入 hybrid fallback。
- 搜索页使用 300 ms `SearchQueryDebouncer`，只提交最后一次输入；本地 lexical
  provider 独立显示，hybrid report 返回后再融合列表。清空、下一次输入和 dispose
  都会取消旧回调，旧 query family 结果不会覆盖当前 query。
- UI 仅在真实 augmented 或 fallback 时显示状态；原始 query、lexical breakdown、
  trust、locator 和 citation 路径保持不变。

验收：adapter、strict JSON、敏感 query、默认关闭偏好、持久化、hybrid fallback、
debounce 和设置页聚焦测试 12 项通过；全量 `flutter test --no-pub` 为 258 tests
passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅
34 条既有 info。

Leaf 21.11 已完成代码与自动化验收。真机仍未连接，因此模型辅助搜索开关、输入
debounce、augmented/fallback 状态 chip 的物理设备点击与视觉验收仍为外部待办。

### Leaf 21.12：Knowledge search widget regression

输出：

- 知识库搜索输入、debounce 进度、模型增强和本地回退状态使用稳定的语义 key；
  KnowledgeBaseScreen 允许测试注入 debounce 时长，生产默认仍为 300 ms。
- 新增搜索页 widget 回归，覆盖 300 ms 语义下只提交最后输入、旧 Future 晚完成不覆盖
  当前 query、清空立即回到历史空态，以及 augmented/fallback 状态互斥展示。
- 测试直接控制 family provider 和 Completer 完成顺序，不调用真实模型、数据库或网络，
  因而能确定性验证 query-family 隔离与 stale-result 防护。

验收：新增 4 项聚焦测试通过；全量 flutter test --no-pub 为 262 tests passed；
flutter analyze --no-pub --no-fatal-infos 为 0 errors、0 warnings，仅 34 条既有
info；格式检查、git diff --check 与凭据形态扫描通过。

Leaf 21.12 已完成代码与自动化验收。最新 split arm64 debug APK 为 91,945,199
bytes，SHA-256 为 424087275110A499D37613B09F354C53325B0B8128195F573F8A522402EB1608，
v2 签名通过且原生库仅位于 lib/arm64-v8a。构建时以 project arg 禁用 Kotlin 增量缓存，
绕过 Windows 跨盘符缓存缺陷，没有修改 Gradle 源配置。当前 adb devices -l 无设备；模型辅助
搜索开关、输入 debounce 和状态 chip 的物理设备点击与视觉验收仍依赖真机连接，必须继续
遵守仅操作 Duoduo App 的边界。
### Leaf 21.13：Evidence-bound Private Alpha readiness

输出：

- readiness schema v2 把 automated gate 与 Android build 从单独布尔值升级为结构化证据：
  测试数、analyzer error/warning、format/diff 状态、完成时间、APK 相对路径、字节数、
  SHA-256、arm64-only 与 v2 signing 声明。
- 新增 release evidence verifier；CLI 只接受仓库内相对 APK 路径，读取真实文件并重新计算
  字节数和 SHA-256。APK 缺失、路径越界、身份漂移或自动化证据不完整会追加稳定 blocker，
  即使摘要布尔值被手工设为 true 也不能得到 GO。
- 当前 schema v2 fixture 绑定最新 split arm64 APK，真实身份校验通过；readiness 仍只返回
  physical device、controlled credential、data-processing owner、release-day acceptance
  与 cohort 五个外部 blocker，没有把离线证据冒充外部门禁。

验收：新增 4 项 release evidence 回归，与原 readiness 3 项合计 7 项聚焦测试通过；
全量 flutter test --no-pub 为 266 tests passed；flutter analyze --no-pub
--no-fatal-infos 为 0 errors、0 warnings，仅 34 条既有 info。机器可读 CLI 对当前
fixture 输出 HOLD，且 blocker 集合未出现 APK 证据漂移项。

Leaf 21.13 已完成代码与自动化验收。它降低了误填 GO 和错发 APK 的运营风险，但不改变
正式 Alpha 仍需受控凭据、责任人、发布日 5/5、正式 cohort 与真机复验的事实。
### Leaf 21.14：Privacy-safe release artifact scan

输出：

- readiness schema v2 新增 privacy_scan.paths，显式列出需要检查的 release evidence、
  feedback、support 或 event artifact；只接受仓库相对路径，并拒绝越界。
- 新增 privacy scanner，检测 API key shape、Authorization/API token 字段、credential
  URL query、Windows/Unix/file URL 私有绝对路径、JWT、敏感文件名、缺失/超大/不可读
  文件。相同文件与类别稳定去重。
- finding 只保存固定类别和仓库相对路径，不保存匹配原文、snippet、token、URL query、
  resolved absolute path 或 secret。readiness blocker 因此可审计而不会二次泄露。
- 当前 fixture 扫描自身为 clean；机器可读 readiness 仍只返回五个真实外部 blocker。

验收：新增 5 项 privacy scanner 回归，覆盖 clean、类别识别、无秘密输出、去重、敏感
文件、路径越界、缺失文件与 schema 解析；全量 flutter test --no-pub 为 271 tests
passed；flutter analyze --no-pub --no-fatal-infos 为 0 errors、0 warnings，仅 34 条
既有 info。当前 readiness CLI 输出 HOLD 且没有 privacy_scan blocker。

Leaf 21.14 已完成代码与自动化验收。正式发布时 operator 必须把每个实际导出 artifact
加入 privacy_scan.paths；扫描 clean 不替代参与者同意、数据责任人或人工内容审查。
### Leaf 21.15：Evidence-bound release-day model acceptance

输出：

- readiness 在 release_day_acceptance_passed=true 时强制解析结构化
  release_day_acceptance evidence；gate=false 时不要求伪造报告，继续保留明确 HOLD。
- 每个 offered profile 绑定 role、provider、sanitized HTTPS endpoint、protocol、model、
  SHA-256 profile fingerprint、完成时间、credential scope、固定五项结果与 exact APK
  SHA-256。
- verifier 要求唯一 primary；offered fallback 必须有独立报告。重复 fingerprint、endpoint
  userinfo/query/fragment、超过 24 小时或未来时间、跨 APK、shared-public credential、
  缺项/重复/失败的非 5/5 结果都会产生稳定 blocker。
- blocker 不携带 endpoint query、userinfo、credential 或模型原文。当前 release-day gate
  仍为 false，因此 readiness 保持原有五个外部 blocker，不把开发 Grok 5/5 冒充正式证据。

验收：新增 5 项 model acceptance evidence 回归，覆盖有效 primary、fallback 独立性、
新鲜度、APK 绑定、credential scope、固定五项、endpoint sanitization、fingerprint 与
schema 错误；全量 flutter test --no-pub 为 276 tests passed；flutter analyze --no-pub
--no-fatal-infos 为 0 errors、0 warnings，仅 34 条既有 info。当前 CLI 继续输出合法 HOLD。

Leaf 21.15 已完成代码与自动化验收。正式邀请仍必须由受控或参与者自有 credential 在
发布日通过同一 App 五任务矩阵，再将不含秘密的结构化报告附到 readiness evidence。
### Leaf 21.16：Anonymous owner evidence and frozen operator pack

输出：

- data_processing_owner_assigned=true 时，readiness 强制解析匿名 operator_pack evidence；
  只记录 alphaOwner、privacyReviewer、reliabilityOwner 等 role code、opaque external
  operations locator，以及 access、retention、deletion、incident-response 声明，不存姓名、
  联系方式或私有存储路径。
- 六份 repository operator blank template 已冻结为固定相对路径、必需 heading 与 SHA-256：
  recruitment register、participant guide、session worksheet、issue log、decision log、
  report template。
- verifier 检查角色/政策、locator 格式、文件存在性、章节和 exact hash。模板缺失、被填写
  或文档漂移都会阻止发布，从机器层面执行“仓库只放空白模板，实际记录在仓库外”。
- 当前 owner gate 仍为 false，因此 CLI 不伪造 owner evidence，继续保留
  data_processing_owner_required blocker。

验收：新增 4 项 operator pack 回归，覆盖当前批准模板、可注入模板合同、角色/政策缺失、
非法 locator、缺章节、hash 漂移、缺文件和无身份输出；全量 flutter test --no-pub 为
280 tests passed。flutter analyze --no-pub --no-fatal-infos 保持 0 errors、0 warnings，
仅 34 条既有 info。当前 readiness CLI 继续输出原有五个真实外部 blocker。

Leaf 21.16 已完成代码与自动化验收。机器只能验证匿名职责合同和模板完整性；实际负责人
仍必须由用户/团队指定，并在仓库外 operations record 中保存身份与访问授权。
### Leaf 21.17：Evidence-bound physical-device preflight

输出：

- physical_device_passed=true 时，readiness 强制解析 physical_device_evidence：
  completed_at 与现有 preflight JSON report；gate=false 时不要求报告，也不连接设备。
- verifier 要求 PASSED、physical、Arm64/AArch64、API 24-35、execution requested/attempted、
  install/cold-start/process 全通过、PID-filtered log error matches 为 0，并绑定 exact
  release APK SHA-256。
- 报告最大年龄 24 小时；未来、过期、旧 APK、READY/read-only、emulator、x86、API 36、
  未执行或部分失败 smoke 都会产生稳定 blocker。
- 当前 physical gate 仍为 false，CLI 继续保留 physical_device_pending；本 leaf 没有对
  真机、模拟器、其他 App、设备文件或设置执行任何操作。

验收：新增 5 项 physical-device evidence 回归，并复用 3 项 preflight 回归；覆盖有效
Arm64 physical smoke、emulator/x86/API、READY、execution、smoke failure、新鲜度、未来
时间、APK 绑定和 JSON parser。全量 flutter test --no-pub 为 285 tests passed；
flutter analyze --no-pub --no-fatal-infos 为 0 errors、0 warnings，仅 34 条既有 info。

Leaf 21.17 已完成代码与自动化验收。下一次真机连接后仍需仅针对 Duoduo App 重新执行
preflight --execute，才能生成可用于把 physical gate 设为 true 的新鲜报告。
### Leaf 21.6：Ten-user private alpha

输出：

- 观察前五次首次运行，访谈 10 名用户，按周复盘漏斗、学习成果、可靠性和反馈。
- 每轮只改变一个主要产品假设，并用 decision log 连接证据、改动和结果。

验收：

- 不重定义失败指标；发布门槛全部通过，并记录下一 Branch 的 go/no-go 决策。

启动准备记录（2026-07-16）：

- 新增匿名招募/同意登记、D0/D7/D14 session worksheet、P0-P3 issue log 和单一主要假设 decision log；所有实际填写副本必须保存在仓库外，禁止姓名、联系方式、凭据、项目名、私有路径、源码、原始回答和模型原文。
- `docs/private-alpha-operations-runbook.md` 已链接完整 operator pack，最终报告增加 evidence index。正式 cohort denominator 固定为 A01-A10，退出者保留在 invited denominator，S01-S02 仅作不计数 shakedown。
- 新增 `tool/private_alpha_device_preflight.dart`，默认只读核对 APK 哈希、设备 ABI/API、真机属性和屏幕参数；只有显式 `--execute` 且设备满足 Arm64 physical API 24-35 时，才安装、冷启动并读取 Duoduo PID 日志。工具不清空全局 logcat、不检查其他 package、不修改设备设置或共享存储。Arm64 通过、x86 emulator HOLD 和安装失败三项回归通过。
- 全量 `flutter test --no-pub` 更新为 232 tests passed；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info lint。222 个 Dart 文件格式检查无变化，`git diff --check`、文档尾随空格和凭据形态扫描通过。
- OnePlus PGP110 真机为 `arm64-v8a`、API 35、1080x2412、density 480。Arm64 APK 离线构建完成 203 个 actionable tasks，`BUILD SUCCESSFUL in 3m 45s`；APK 为 140,580,450 bytes，SHA-256 为 `08c4621fe571df06cfd4970ac35b3a2050ef397317484a4a14ede16dbaa5166e`，v2 签名通过且包含 `lib/arm64-v8a/libflutter.so`。
- 真机只读 preflight 返回 `READY`，显式 app-only smoke 返回 `PASSED`：安装、冷启动、进程存活和 PID-filtered App 日志均通过。首屏正确显示 clean-install `1/6 目标`，无裁切、重叠或 system inset 遮挡；证据保存在 `build/validation/leaf21_6_arm64_cold_start.*`，设备临时文件已删除。
- 真机无模型路径正确显示当前精确配置 blocker，同时允许导入专用测试 ZIP。App 保存了来源 locator 与 chunk 并进入 `4/6 覆盖`，AI 生成保持禁用。覆盖页反馈导出在诊断关闭时保存成功；JSON 敏感形态扫描为 0，schema 23 数据库 `integrity_check=ok`，`feedback_submitted` 属性仅含 category、severity 和 diagnostic consent。设备反馈文件与 fixture ZIP 已删除，可能暴露系统最近/下载文件名的 DocumentsUI dump 未保留。
- 2026-07-17 真机补充验收：开发用 `Grok 4.5 通道（主） + Responses + grok-4.5` 在 App 内以 66.1 秒通过 `5/5`，网关实际模型为 `grok-4.5`。另一自定义 Responses profile 虽通过短验收，但真实项目生成连续两次返回 `504`，因此未作为长任务稳定性证据。
- Grok profile 完成项目理解、练习题生成和引用预核验，生成 12 个来源绑定知识点与 12 道题；人工核验后知识库为 `待核验 0`，首次运行进入 `6/6 结果`，并保存 1 个完成的 Agent Session。当次验收暴露逐题核验缺少批量操作。
- 真机通过 Android DocumentsUI 完成 schema 23 数据库导出与恢复。恢复后模型凭据、profile、`5/5` 报告、首次运行完成状态和隐私偏好保持不变；最终数据库 `integrity_check=ok`、外键问题 0，包含 1 个来源、4 个 chunk、12 个知识点、12 道 verified 题、1 个完成会话和 33 条产品事件。最终冷启动进入主 App，PID 日志未发现 Fatal、Flutter、ANR、SQLite、integrity 或 restore failure。
- 设备导出、App 沙箱测试快照和本地数据库检查副本均已删除。Arm64 Tier B 技术门槛已完成；但当前精确 profile 使用共享公开中转，只批准开发验收。正式邀请仍为 `HOLD FOR CONTROLLED CREDENTIAL`，需要受控或参与者自有凭据、明确的数据处理责任人，并在发布日重新通过同一 `5/5`。
- 2026-07-17 完成后续批量核验 UX leaf：人工核验页可把当前仍为 `pending` 且至少一个引用片段仍可读取的题目批量写入草稿，删除题和人工切换为“无来源”的题不会被覆盖，仍需点击“保存已核验内容”；知识库待核验页在确认后使用单个 SQLite transaction 批量更新，缺失引用题继续保持 pending，并刷新题目、检索、练习、复习队列和 Agent plan read model。
- 新增纯服务、草稿组件和 SQLite 回滚回归。聚焦测试 8 项、全量 `flutter test --no-pub` 238 项全部通过；`flutter analyze --no-pub --no-fatal-infos` 为 0 errors、0 warnings，仅 34 条既有 info；`git diff --check` 与凭据形态扫描通过。
- 当前 Arm64 debug APK 使用 Gradle 203 个 actionable tasks 构建成功，大小 140,584,236 bytes，SHA-256 为 `4025a9d01222544f7fbf7aa3cec1786db62a526a35f0dd414d1896ad01e6a012`，v2 签名通过且只包含 `lib/arm64-v8a/libflutter.so`。本轮 `adb devices -l` 未列出真机，因此批量入口的设备点击验收待下次连接后补做；没有对真机执行任何操作。
- Leaf 21.6 仍未开始；上述记录只表示研究运营包可用，不表示已有参与者、访谈、激活或留存结果。

### Alpha 后条件轨道

- 只有工具需要远程并发、长任务或跨进程恢复时，才评估远程 graph runtime、服务端幂等和 result replay。
- 只有跨设备连续学习、多人协作或账户边界成为重复需求时，才评估云同步和服务器状态所有权。
- 只有固定 retrieval benchmark 在真实语料规模上失败时，才评估 embedding 与向量索引，并保留 citation、trust 和逐字 quote gate。
- 只有独立权限、隔离状态或可度量并行收益无法由现有 planner、policy、executor、memory 和 trace 表达时，才评估多 Agent。

## Out of Scope Until Trellis Branches Are Complete

以下内容在前置分支完成前不做：

- 自动 GitHub 导入。
- PDF/网页解析。
- 视频解析。
- 云同步。
- 多用户账户。
- 向量数据库。
- 完整 FSRS。
- 复杂知识图谱可视化。

## Execution Checklist

每个 leaf task 开始前确认：

- 依赖分支是否完成。
- 输入数据是否存在。
- 影响文件是否明确。
- 验收标准是否可检查。

每个 leaf task 完成后执行：

- `dart format` 或 Flutter format。
- `flutter analyze`，如果本机可用。
- 相关测试，若存在。
- 更新文档或状态。

### Leaf 21.18：Evidence-bound controlled credential

输出：

- controlled_credential_available=true 时，readiness 强制解析独立的
  controlled_credential evidence；gate=false 时不要求伪造 credential 或责任声明。
- 每个 release-day primary/offered fallback profile 必须有且只有一个 binding，绑定相同
  credential scope 与 exact profile fingerprint；额外、缺失或漂移的 binding 都会阻止发布。
- evidence 只允许 CRED-* opaque reference，以及 quota owner/limit、revocation
  capability/owner、retention 和 data-handling 声明。shared-public scope、可识别 reference、
  重复 reference 或任一控制缺失都会产生稳定 blocker。
- API key、credential-bearing URL、姓名、联系方式和 secret 原文不进入 schema 或 blocker。
  当前 credential gate 仍为 false，因此 CLI 继续保留 controlled_credential_required。

验收：新增 5 项 controlled-credential evidence 回归，覆盖有效 profile 绑定、shared-public、
非法 reference、quota/revocation/policy 缺口、release-day 依赖、fingerprint/scope 漂移、
重复 reference、重复 binding 与 schema 错误；全量 flutter test --no-pub 为 290 tests
passed。flutter analyze --no-pub --no-fatal-infos 保持 0 errors、0 warnings，仅 34 条
既有 info。当前 readiness CLI 继续输出五个真实外部 blocker。

Leaf 21.18 已完成代码与自动化验收。该门禁证明“谁控制额度、谁能撤销、按什么政策处理”
已经有匿名外部记录并绑定到发布日 profile；它不保存 credential 本体，也不替代实际责任人
授权或参与者自有 credential 的现场确认。

### Leaf 21.19：Evidence-bound formal cohort

输出：

- cohort_completed=true 时，readiness 强制解析匿名 cohort_evidence；gate=false 时继续保留
  cohort_pending，不生成参与者或研究结果。
- verifier 固定正式 denominator 为 A01-A10，拒绝 S01-S02、替换、重复、缺失或额外 code；
  A01-A05 必须为 observed，A06-A10 必须为 selfServe，退出者仍留在 denominator。
- 每个 participant 只记录 terminal invitation/consent enum、D0/D7/D14 状态、
  grounded-turn completion、learning-claim enum 与 EV-* opaque reference。completed D0/D7
  必须有 grounded closure；accepted participant 的 D0/D14 不能被记为 absent/withdrawn。
- cohort 绑定 exact release APK SHA-256 与全部 release-day profile fingerprint，并验证
  freeze/decision 时间顺序、COHORT-* freeze locator 和 REPORT-* final report locator。
  GO、CONDITIONAL GO 与 NO-GO 都可表示研究完成，不把完成偷换成指标通过。
- blocker 只包含稳定 code，不回显姓名、联系方式、凭据、私有路径、项目名、源码、回答或
  模型原文。当前 cohort gate 仍为 false，因此没有伪造正式 Alpha 结果。

验收：新增 5 项 cohort evidence 回归，覆盖有效 A01-A10、denominator/participant/track/
consent 漂移、APK/profile/release-day 绑定、时间顺序、opaque reference、D0/D7 activation、
formal phase、D14 learning outcome 与 schema 错误；全量 flutter test --no-pub 为
295 tests passed。flutter analyze --no-pub --no-fatal-infos 为 0 errors、0 warnings，
仅 34 条既有 info。当前 readiness CLI 继续输出五个真实外部 blocker。

Leaf 21.19 已完成代码与自动化验收。它只定义未来正式 cohort 的证据合同；Leaf 21.6
仍未开始，没有参与者、邀请、访谈、激活、留存或学习结果被声明为已经发生。

### Leaf 21.20：Cross-evidence release consistency

输出：

- readiness CLI 在单次运行开始时只捕获一次 evaluatedAt，并把同一时刻传给 release-day、
  physical-device 与 cohort verifier，消除 24 小时边界的同轮漂移。
- 新增 release consistency verifier，在 acceptance、controlled credential、operator pack
  和 cohort 都存在时做组合校验，而不再假设“每份 evidence 单独合法”就代表同一发布事实。
- cohort participant schema 新增实际使用的 profile fingerprint 与 credential scope；每位
  participant 的 pair 必须同时存在于 release-day acceptance 和 credential binding。
- cohort 新增 operator_record_locator，必须与 operator pack 的 external_record_locator 完全
  一致，防止两个格式合法但无关的外部记录被拼成一次发布。
- final cohort decision 只有 GO 才能得到 readiness GO；CONDITIONAL GO 与 NO-GO 产生
  release_consistency_cohort_decision_not_go，不再把研究完成偷换为发布批准。
- consistency blocker 只输出固定 code，不包含 participant code、locator 内容、profile
  endpoint、credential 或外部记录正文。当前外部 gate 均为 false，CLI 仍保持原五项 HOLD。

验收：新增 4 项 release consistency 回归，并更新 5 项 cohort evidence 回归，覆盖完整闭合
identity、NO-GO/CONDITIONAL GO、operator locator 漂移、profile fingerprint 漂移和
credential scope 漂移；全量 flutter test --no-pub 为 299 tests passed。
flutter analyze --no-pub --no-fatal-infos 为 0 errors、0 warnings，仅 34 条既有 info。
当前 readiness fixture 仍输出五个真实外部 blocker。

Leaf 21.20 已完成代码与自动化验收。机器可以证明各份匿名 evidence 属于同一个 release
identity，但不能证明外部负责人声明、访谈判断或数据处理行为本身真实执行，仍需人工审阅。

### Leaf 21.21：End-to-end readiness evaluator

输出：

- 把原先集中在 tool/private_alpha_readiness.dart main 中的 evidence parsing、异步文件验证、
  privacy scan、条件 gate、cross-evidence consistency 和 blocker 汇总提取为
  PrivateAlphaReadinessEvaluator。
- evaluator 显式接收 decoded JSON、repository root 与 evaluatedAt，返回
  PrivateAlphaReadinessReport；不写 stdout、不设置 exit code，也不读取命令行参数，因此
  时间边界和完整证据编排可以确定性测试。
- CLI 现在只负责参数/文件/JSON 输入、调用 evaluator、JSON/Markdown 输出以及
  GO=0、HOLD=2、格式错误=64、文件错误=66 的进程边界。
- 新增完整匿名 GO fixture：临时目录中生成真实 bytes/SHA-256 匹配的假 APK、clean scan
  artifact，复制六份 frozen blank templates，并生成纯假 profile、CRED/OPS/EV/REPORT
  reference、physical PASSED report 与 A01-A10 cohort。
- 同一 bundle 经全部 parser/verifier/consistency evaluator 后必须得到 GO；只把 final
  decision 改为 NO-GO 时必须得到唯一 consistency blocker 和 HOLD。fixture 不代表真实
  真机、credential、owner、participant 或研究结果。

验收：新增 2 项 evaluator 端到端回归；全量 flutter test --no-pub 为 301 tests passed。
flutter analyze --no-pub --no-fatal-infos 为 0 errors、0 warnings，仅 34 条既有 info。
当前实际 fixture 仍保持五项外部门禁为 false，并继续输出真实 HOLD。

Leaf 21.21 已完成代码与自动化验收。现在不仅每个 verifier 有单测，完整证据链也已证明能
闭合到 GO；正式发布仍只能使用真实外部 evidence，不能引用测试 fixture。

### Leaf 21.22：Readiness CLI process contract

输出：

- 把完整匿名 readiness fixture 提取到 test/support，共享 evaluator 与 CLI integration 测试，
  避免两套 evidence builder 漂移；helper 只生成临时 APK、空白模板副本与假 opaque refs。
- 新增真正启动 Dart 子进程的 CLI integration test，不绕过 tool/private_alpha_readiness.dart。
  Dart SDK 从 DART_SDK、FLUTTER_ROOT 或 flutter_tester 上级 cache 自动定位，不硬编码本机路径。
- 完整 GO bundle 以 --format json 返回 exit 0，stdout 可直接 jsonDecode，status=GO 且
  blockers=[]；同一 bundle 仅把 final decision 改为 noGo 后，以 Markdown 返回 exit 2 和
  唯一 consistency blocker。
- 非法 --format 映射 exit 64，缺失 evidence 文件映射 exit 66；错误信息仅保留稳定失败前缀。
- stdout/stderr 明确断言不含 endpoint、model、CRED-*、OPS-* 或 A01 participant code，
  锁定 CLI 不回显 evidence 内容的隐私边界。

验收：新增 2 项 CLI process integration 回归，重构但保留 2 项 evaluator 回归；聚焦
4 tests passed。全量 flutter test --no-pub 为 303 tests passed；flutter analyze
--no-pub --no-fatal-infos 为 0 errors、0 warnings，仅 34 条既有 info。当前实际 fixture
继续输出五个真实 HOLD blocker。

Leaf 21.22 已完成代码与自动化验收。CLI 的 evaluator、输出和退出码现在都有独立证据；
下一步可安全提供 schema v2 operator initializer，而不依赖人工猜测进程行为。

### Leaf 21.23：Safe readiness initializer and schema v2

输出：

- 新增 JSON Schema Draft 2020-12 artifact：
  schema/private-alpha-readiness-v2.schema.json，覆盖必需顶层字段、条件 gate object、类型、
  enum、hash、relative path、CRED/OPS/EV/COHORT/REPORT reference 与 A01-A10 结构。
- 明确 JSON Schema 只负责结构；真实 APK bytes/hash、路径 containment、隐私扫描、模板 hash、
  endpoint canonicalization、freshness、固定 cohort 与 cross-evidence consistency 仍以 Dart
  evaluator 为权威。
- 新增 PrivateAlphaReadinessInitializer 与 tool/private_alpha_readiness_init.dart。initializer
  必须接收真实 repository-relative APK 和正 tests count，实际计算 bytes/SHA-256；输出只能在
  gitignored build/ 下。
- format、diff、arm64-only 与 v2-signed 默认 false，只有显式 CLI flag 才声明通过；五个外部
  gate 永远初始化 false，不生成 physical、credential、owner、release-day 或 cohort 假证据。
- 新增 operator guide docs/private-alpha-readiness-evidence.md，并从 checklist/runbook 链接；
  说明初始化、评估、仓库外记录和 schema/evaluator 权威边界。
- Dart CLI finder 提取为共享 test support，供 readiness 与 initializer 进程测试复用。

验收：新增 4 项 initializer/schema 回归，覆盖真实临时 APK 草稿得到精确五项 HOLD、无
credential object、unsafe/output path 拒绝、initializer CLI -> readiness CLI 闭环，以及
committed Draft 2020-12 schema 的五项 conditional gate；全量 flutter test --no-pub 为
307 tests passed。flutter analyze --no-pub --no-fatal-infos 为 0 errors、0 warnings，
仅 34 条既有 info。当前实际 fixture 继续输出五个真实外部 blocker。

Leaf 21.23 已完成代码与自动化验收。operator 现在可以从真实构建身份安全创建草稿，但
initializer 不能生成 GO；所有外部门禁仍必须通过真实流程后逐项附证。
