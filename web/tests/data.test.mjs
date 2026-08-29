import test from 'node:test';
import assert from 'node:assert/strict';
import {
  AGENT_SESSION_LIMITS,
  AGENT_SESSION_VERSION,
  DATASETS,
  LOCAL_IMPORT_LIMITS,
  LIBRARY_VERSION,
  agentProgressFill,
  agentReflectionCount,
  buildAgentScript,
  clampReflection,
  createAgentSession,
  createEmptyLibrary,
  createLocalSource,
  extractSections,
  formatBytes,
  formatImportedAt,
  getDataset,
  looksBinary,
  normalizeAgentSession,
  normalizeLocalLibrary,
  sectionLocator,
  truncateExcerpt,
  validateDatasets,
  validateImportCandidate,
} from '../landing/app/scripts/data.js';
import { createInitialProgress, isCorrect, normalizeProgress, scoreDataset } from '../landing/app/scripts/app.js';

/** Stand-in for the parts of `File` the import path actually reads. */
function fakeFile(name, size = 1024) {
  return { name, size };
}

test('demo ships three bilingual datasets and twelve valid questions', () => {
  assert.deepEqual(validateDatasets(), []);
  assert.equal(DATASETS.length, 3);
  assert.equal(DATASETS.reduce((count, dataset) => count + dataset.questions.length, 0), 12);
  assert.deepEqual(new Set(DATASETS.flatMap((dataset) => dataset.questions.map((question) => question.type))), new Set(['single', 'multiple', 'boolean']));
});

test('answer comparison ignores selection order but rejects partial answers', () => {
  const question = DATASETS[0].questions[2];
  assert.equal(isCorrect(question, [...question.correct].reverse()), true);
  assert.equal(isCorrect(question, [question.correct[0]]), false);
});

test('malformed or stale progress resets without throwing', () => {
  assert.deepEqual(normalizeProgress(null), createInitialProgress());
  assert.deepEqual(normalizeProgress({ version: 99, datasets: {} }), createInitialProgress());
});

test('progress normalization removes unknown options and clamps the question index', () => {
  const normalized = normalizeProgress({
    version: 1,
    activeDatasetId: 'flutter',
    datasets: {
      flutter: {
        currentIndex: 999,
        completed: false,
        answers: { 'flutter-state-owner': ['state', 'unknown'] },
        submitted: { 'flutter-state-owner': true },
      },
    },
  });
  assert.equal(normalized.datasets.flutter.currentIndex, 3);
  assert.deepEqual(normalized.datasets.flutter.answers['flutter-state-owner'], ['state']);
  assert.equal(normalized.datasets.flutter.submitted['flutter-state-owner'], true);
});

test('score includes only submitted correct answers', () => {
  const dataset = DATASETS[0];
  const state = {
    currentIndex: 0,
    completed: false,
    answers: {
      [dataset.questions[0].id]: dataset.questions[0].correct,
      [dataset.questions[1].id]: dataset.questions[1].correct,
    },
    submitted: { [dataset.questions[0].id]: true },
  };
  assert.equal(scoreDataset(dataset, state), 1);
});

test('markdown headings become sections and text before the first heading is kept', () => {
  const { sections, truncated } = extractSections([
    'Intro line before any heading.',
    '',
    '# Anchor overview',
    'Anchor keeps every question attached to its evidence.',
    '',
    '## Storage',
    'Records live in a local database.',
  ].join('\n'));

  assert.equal(truncated, false);
  assert.deepEqual(sections.map((section) => section.kind), ['preamble', 'heading', 'heading']);
  assert.deepEqual(sections.map((section) => section.heading), [null, 'Anchor overview', 'Storage']);
  assert.deepEqual(sections.map((section) => section.level), [0, 1, 2]);
  assert.equal(sections[1].excerpt, 'Anchor keeps every question attached to its evidence.');
  assert.equal(sections[2].line, 6);
});

test('hashes inside fenced code blocks are not treated as headings', () => {
  const { sections } = extractSections([
    '# Real heading',
    '```bash',
    '# not a heading',
    'flutter test',
    '```',
    '~~~',
    '## also not a heading',
    '~~~',
  ].join('\n'));

  assert.equal(sections.length, 1);
  assert.equal(sections[0].heading, 'Real heading');
  assert.match(sections[0].excerpt, /not a heading/);
});

test('plain text without headings still yields one inspectable section', () => {
  const { sections } = extractSections('Just a paragraph of notes.\nA second line.');
  assert.equal(sections.length, 1);
  assert.equal(sections[0].kind, 'document');
  assert.equal(sections[0].heading, null);
  assert.equal(sections[0].excerpt, 'Just a paragraph of notes. A second line.');
  assert.equal(extractSections('   \n\n  ').sections.length, 0);
});

test('section count and excerpt length are capped for browser storage', () => {
  const many = Array.from({ length: LOCAL_IMPORT_LIMITS.maxSections + 6 }, (_, index) => `# Heading ${index}\nBody ${index}`).join('\n');
  const { sections, truncated } = extractSections(many);
  assert.equal(sections.length, LOCAL_IMPORT_LIMITS.maxSections);
  assert.equal(truncated, true);

  const long = truncateExcerpt('a'.repeat(600), 480);
  assert.equal(long.truncated, true);
  assert.ok(long.text.length <= 481, `excerpt was ${long.text.length} characters`);
  assert.deepEqual(truncateExcerpt('short'), { text: 'short', truncated: false });
});

test('import validation rejects unsupported types, oversized files, and a full library', () => {
  assert.deepEqual(validateImportCandidate(fakeFile('notes.md'), { sourceCount: 0 }), { ok: true, reason: null });
  assert.deepEqual(validateImportCandidate(fakeFile('NOTES.MARKDOWN'), { sourceCount: 0 }), { ok: true, reason: null });
  assert.equal(validateImportCandidate(fakeFile('deck.pdf'), { sourceCount: 0 }).reason, 'type');
  assert.equal(validateImportCandidate(fakeFile('archive.md.zip'), { sourceCount: 0 }).reason, 'type');
  assert.equal(validateImportCandidate(fakeFile('empty.txt', 0), { sourceCount: 0 }).reason, 'empty');
  assert.equal(validateImportCandidate(fakeFile('big.txt', LOCAL_IMPORT_LIMITS.maxBytes + 1), { sourceCount: 0 }).reason, 'size');
  assert.equal(validateImportCandidate(fakeFile('ok.txt'), { sourceCount: LOCAL_IMPORT_LIMITS.maxSources }).reason, 'full');
  assert.equal(validateImportCandidate(null, { sourceCount: 0 }).reason, 'type');
});

test('binary-looking text is detected without throwing on ordinary prose', () => {
  assert.equal(looksBinary('Ordinary notes with punctuation — and CJK 锚学.'), false);
  assert.equal(looksBinary('ok\r\ntabs\tand newlines\n'), false);
  assert.equal(looksBinary(`plain${String.fromCharCode(0)}bytes`), true);
});

test('imported sources get unique ids and stable locators', () => {
  const first = createLocalSource({ name: '锚学 notes.md', size: 40, text: '# 概念\n内容', importedAt: 1_756_000_000_000 });
  const second = createLocalSource({
    name: '锚学 notes.md',
    size: 40,
    text: '# 概念\n内容',
    importedAt: 1_756_000_000_000,
    existingIds: [first.id],
  });

  assert.notEqual(first.id, second.id);
  assert.equal(first.sectionCount, 1);
  assert.equal(sectionLocator(first, first.sections[0]), `${first.name}#概念`);
  assert.match(sectionLocator(first, { kind: 'document', line: 3 }), /:L3$/);
  assert.equal(formatImportedAt(1_756_000_000_000), '2025-08-24 01:46 UTC');
  assert.equal(formatBytes(2048), '2.0 KB');
  assert.equal(formatBytes(512), '512 B');
});

test('malformed or stale local library recovers without throwing', () => {
  const empty = createEmptyLibrary();
  assert.deepEqual(empty, { version: LIBRARY_VERSION, sources: [] });
  assert.deepEqual(normalizeLocalLibrary(null), empty);
  assert.deepEqual(normalizeLocalLibrary('not json'), empty);
  assert.deepEqual(normalizeLocalLibrary({ version: 99, sources: [{ id: 'a', name: 'a', sections: [] }] }), empty);
  assert.deepEqual(normalizeLocalLibrary({ version: LIBRARY_VERSION, sources: 'nope' }), empty);

  const valid = createLocalSource({ name: 'keep.md', size: 20, text: '# Keep\nBody' });
  const normalized = normalizeLocalLibrary({
    version: LIBRARY_VERSION,
    sources: [valid, { ...valid }, { id: '', name: 'no id', sections: [] }, null, { id: 'x', name: 'x', sections: [] }],
  });
  assert.equal(normalized.sources.length, 1);
  assert.equal(normalized.sources[0].id, valid.id);
  assert.equal(normalized.sources[0].sections[0].heading, 'Keep');
  assert.ok(normalized.sources.length <= LOCAL_IMPORT_LIMITS.maxSources);
});

test('the guided agent script is derived from bundled dataset content only', () => {
  const dataset = getDataset('flutter');
  const script = buildAgentScript(dataset);

  assert.equal(script.length, dataset.questions.length);
  assert.deepEqual(script.map((turn) => turn.index), [0, 1, 2, 3]);
  assert.deepEqual(
    script.map((turn) => turn.questionId),
    dataset.questions.map((question) => question.id),
  );

  for (const [index, turn] of script.entries()) {
    const question = dataset.questions[index];
    assert.equal(turn.prompt, question.prompt);
    assert.equal(turn.explanation, question.explanation);
    assert.equal(turn.citation, question.citations[0]);
    assert.equal(turn.focus, question.citations[0].locator);
    assert.equal(turn.hints, question.tutorHints);
    assert.ok(turn.hints.length > 0);
  }

  // A dataset always yields the same turns, which is what lets the surface call the session scripted.
  assert.deepEqual(buildAgentScript(dataset), script);
  assert.deepEqual(buildAgentScript(null), []);
});

test('a new agent session starts empty at the first turn', () => {
  const session = createAgentSession('git');
  assert.deepEqual(session, {
    version: AGENT_SESSION_VERSION,
    datasetId: 'git',
    turnIndex: 0,
    completed: false,
    reflections: {},
    hints: {},
    startedAt: 0,
  });
});

test('malformed or stale agent sessions fall back to no session', () => {
  assert.equal(normalizeAgentSession(null), null);
  assert.equal(normalizeAgentSession('not json'), null);
  assert.equal(normalizeAgentSession([]), null);
  assert.equal(normalizeAgentSession({ version: 99, datasetId: 'flutter' }), null);
  assert.equal(normalizeAgentSession({ version: AGENT_SESSION_VERSION, datasetId: 'not-a-dataset' }), null);
  assert.equal(normalizeAgentSession({ version: AGENT_SESSION_VERSION }), null);
});

test('agent session normalization drops unknown turns and clamps the resume point', () => {
  const dataset = getDataset('javascript');
  const script = buildAgentScript(dataset);
  const session = normalizeAgentSession({
    version: AGENT_SESSION_VERSION,
    datasetId: dataset.id,
    turnIndex: 999,
    completed: true,
    startedAt: -5,
    reflections: {
      [script[0].questionId]: '  kept  ',
      [script[1].questionId]: '   ',
      'question-that-no-longer-exists': 'dropped',
      [script[2].questionId]: 42,
    },
    hints: {
      [script[0].questionId]: 99,
      [script[1].questionId]: 0,
      'question-that-no-longer-exists': 3,
    },
  });

  assert.deepEqual(Object.keys(session.reflections), [script[0].questionId]);
  assert.equal(session.reflections[script[0].questionId], '  kept  ');
  assert.equal(session.hints[script[0].questionId], script[0].hints.length);
  assert.deepEqual(Object.keys(session.hints), [script[0].questionId]);
  assert.equal(session.startedAt, 0);

  // One reflection means the furthest honest resume point is the second turn.
  assert.equal(session.turnIndex, 1);
  assert.equal(session.completed, false);
  assert.equal(agentReflectionCount(session, script), 1);
});

test('an agent session is only complete when every turn has a reflection', () => {
  const dataset = getDataset('git');
  const script = buildAgentScript(dataset);
  const reflections = Object.fromEntries(script.map((turn) => [turn.questionId, 'said out loud']));

  const complete = normalizeAgentSession({
    version: AGENT_SESSION_VERSION,
    datasetId: dataset.id,
    turnIndex: script.length - 1,
    completed: true,
    reflections,
  });
  assert.equal(complete.completed, true);
  assert.equal(complete.turnIndex, script.length - 1);
  assert.equal(agentReflectionCount(complete, script), script.length);

  const claimed = normalizeAgentSession({
    version: AGENT_SESSION_VERSION,
    datasetId: dataset.id,
    turnIndex: script.length - 1,
    completed: true,
    reflections: { [script[0].questionId]: 'only one' },
  });
  assert.equal(claimed.completed, false);
  assert.equal(claimed.turnIndex, 1);
});

test('reflections are capped for storage and progress reports as a decile', () => {
  const max = AGENT_SESSION_LIMITS.maxReflectionChars;
  assert.equal(clampReflection('a'.repeat(max + 50)).length, max);
  assert.equal(clampReflection('spaced  out '), 'spaced  out ');
  assert.equal(clampReflection(null), '');

  const dataset = getDataset('flutter');
  const script = buildAgentScript(dataset);
  const stored = normalizeAgentSession({
    version: AGENT_SESSION_VERSION,
    datasetId: dataset.id,
    turnIndex: 0,
    reflections: { [script[0].questionId]: 'b'.repeat(max + 200) },
  });
  assert.equal(stored.reflections[script[0].questionId].length, max);

  assert.equal(agentProgressFill(0, 4), 0);
  assert.equal(agentProgressFill(1, 4), 30);
  assert.equal(agentProgressFill(2, 4), 50);
  assert.equal(agentProgressFill(4, 4), 100);
  assert.equal(agentProgressFill(9, 4), 100);
  assert.equal(agentProgressFill(-3, 4), 0);
  assert.equal(agentProgressFill(1, 0), 0);
  assert.equal(agentReflectionCount(null, script), 0);
});
