import test from 'node:test';
import assert from 'node:assert/strict';
import {
  AGENT_SESSION_LIMITS,
  AGENT_SESSION_VERSION,
  BACKUP_FORMAT,
  BACKUP_LIMITS,
  BACKUP_SECTIONS,
  BACKUP_VERSION,
  DATASETS,
  DECK_SEARCH_LIMITS,
  LIBRARY_SEARCH_LIMITS,
  LOCAL_IMPORT_LIMITS,
  LIBRARY_VERSION,
  SHELL_TEXT,
  THEME_VERSION,
  agentProgressFill,
  agentReflectionCount,
  backupCounts,
  backupFileName,
  buildAgentScript,
  buildLibraryIndex,
  byteLength,
  clampDeckQuery,
  clampLibraryQuery,
  clampReflection,
  countSources,
  createAgentSession,
  createBackup,
  createEmptyLibrary,
  createLocalSource,
  createThemeRecord,
  DAILY_GOAL_QUESTIONS,
  dailyGoalModel,
  deckCardModel,
  deckProgressFill,
  deckSearchTerms,
  extractSections,
  homeDashboardModel,
  localDayStamp,
  formatBytes,
  formatCount,
  formatImportedAt,
  foldSearchText,
  getDataset,
  highlightSegments,
  librarySearchScopes,
  librarySearchTerms,
  looksBinary,
  normalizeAgentSession,
  normalizeLocalLibrary,
  normalizeTheme,
  readBackup,
  resolveLibraryFocus,
  resolveLibrarySearch,
  resolveQuestionTarget,
  resolveTheme,
  searchDecks,
  searchLibrary,
  sectionLocator,
  sourceRevisitSearch,
  truncateExcerpt,
  validateBackupCandidate,
  validateDatasets,
  validateImportCandidate,
  verifiedQuestionCount,
} from '../landing/app/scripts/data.js';
import {
  ROUTE_TARGET_PARAMS,
  citationEvidence,
  completionReviewModel,
  createInitialProgress,
  isCorrect,
  normalizeProgress,
  parseRoute,
  routeHash,
  scoreDataset,
} from '../landing/app/scripts/app.js';

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

/* ------------------------------------------------------------------ *
 * Backup, restore, and theme: pure helpers behind the Profile surface.
 * ------------------------------------------------------------------ */

/** A populated, already-normalized state to back up. */
function sampleState() {
  const dataset = getDataset('flutter');
  const script = buildAgentScript(dataset);
  const first = dataset.questions[0];
  const progress = normalizeProgress({
    version: 1,
    activeDatasetId: dataset.id,
    datasets: {
      [dataset.id]: {
        currentIndex: 1,
        completed: false,
        answers: { [first.id]: [...first.correct] },
        submitted: { [first.id]: true },
      },
    },
  });

  const source = createLocalSource({
    name: 'notes.md',
    size: 64,
    text: '# Heading\n\nBody text for the backup fixture.\n',
    existingIds: [],
  });
  const library = { ...createEmptyLibrary(), sources: [source] };

  const agent = createAgentSession(dataset.id);
  agent.startedAt = 1_700_000_000_000;
  agent.reflections[script[0].questionId] = 'What I noticed.';
  return { progress, library, agent, dataset, script };
}

/** Round-trips a record the way the browser does: JSON out, JSON in. */
function roundTrip(record, name = 'backup.json') {
  return readBackup(JSON.stringify(record), { name, normalizeProgress });
}

test('a backup carries progress, imports, and the agent session with a format stamp', () => {
  const { progress, library, agent, script } = sampleState();
  const backup = createBackup({ progress, library, agent, exportedAt: 1_756_000_000_000 });

  assert.equal(backup.format, BACKUP_FORMAT);
  assert.equal(backup.version, BACKUP_VERSION);
  assert.equal(backup.exportedAt, 1_756_000_000_000);
  assert.deepEqual(Object.keys(backup).sort(), ['agent', 'exportedAt', 'format', 'library', 'progress', 'version']);

  assert.equal(backup.progress.activeDatasetId, 'flutter');
  assert.equal(backup.library.sources.length, 1);
  assert.equal(backup.agent.reflections[script[0].questionId], 'What I noticed.');

  assert.deepEqual(backupCounts({ progress, library, agent }), {
    answers: 1,
    sources: 1,
    sections: library.sources[0].sections.length,
    reflections: 1,
    agentDatasetId: 'flutter',
  });
});

test('a backup copies only allow-listed fields, so no token or stray key can ride along', () => {
  const { progress, library, agent } = sampleState();
  const tampered = {
    progress: { ...progress, apiKey: 'sk-not-a-real-key', authToken: 'bearer', __proto__: { polluted: true } },
    library: { ...library, credentials: { password: 'hunter2' } },
    agent: { ...agent, deviceId: 'abc-123', modelEndpoint: 'https://example.invalid' },
  };
  const serialized = JSON.stringify(createBackup({ ...tampered, exportedAt: 1 }));

  for (const secret of ['apiKey', 'authToken', 'sk-not-a-real-key', 'credentials', 'password', 'hunter2', 'deviceId', 'modelEndpoint', 'polluted']) {
    assert.equal(serialized.includes(secret), false, `backup leaked ${secret}`);
  }

  const backup = createBackup({ ...tampered, exportedAt: 1 });
  assert.deepEqual(Object.keys(backup.progress).sort(), ['activeDatasetId', 'datasets', 'version']);
  assert.deepEqual(Object.keys(backup.library).sort(), ['sources', 'version']);
  assert.deepEqual(Object.keys(backup.agent).sort(), ['completed', 'datasetId', 'hints', 'reflections', 'startedAt', 'turnIndex', 'version']);
});

test('an empty state produces a backup with a stamp but no sections', () => {
  const backup = createBackup({ exportedAt: 0 });
  assert.deepEqual(backup, { format: BACKUP_FORMAT, version: BACKUP_VERSION });
  assert.equal(roundTrip(backup).ok, false);
  assert.equal(roundTrip(backup).reason, 'shape');
});

test('backup file names are dated in UTC and fall back when no stamp is present', () => {
  assert.equal(backupFileName(1_756_000_000_000), 'anchor-demo-backup-2025-08-24.json');
  assert.equal(backupFileName(0), 'anchor-demo-backup.json');
  assert.equal(backupFileName('nonsense'), 'anchor-demo-backup.json');
});

test('a backup written by this build reads back with its counts intact', () => {
  const { progress, library, agent, script } = sampleState();
  const result = roundTrip(createBackup({ progress, library, agent, exportedAt: 1_756_000_000_000 }), 'anchor.json');

  assert.equal(result.ok, true);
  assert.equal(result.name, 'anchor.json');
  assert.equal(result.version, BACKUP_VERSION);
  assert.equal(result.exportedAt, 1_756_000_000_000);
  assert.deepEqual(result.declared, [...BACKUP_SECTIONS]);
  assert.deepEqual(result.dropped, []);
  assert.equal(result.counts.answers, 1);
  assert.equal(result.counts.sources, 1);
  assert.equal(result.counts.reflections, 1);
  assert.equal(result.sections.agent.reflections[script[0].questionId], 'What I noticed.');
  assert.ok(result.bytes > 0);
});

test('candidate files are screened on name and size before any read', () => {
  assert.deepEqual(validateBackupCandidate(fakeFile('backup.json', 200)), { ok: true, name: 'backup.json', bytes: 200 });
  assert.equal(validateBackupCandidate(fakeFile('BACKUP.JSON', 200)).ok, true);
  assert.equal(validateBackupCandidate(fakeFile('backup.md', 200)).reason, 'type');
  assert.equal(validateBackupCandidate(fakeFile('backup.json.exe', 200)).reason, 'type');
  assert.equal(validateBackupCandidate(fakeFile('backup.json', 0)).reason, 'empty');
  assert.equal(validateBackupCandidate(fakeFile('backup.json', BACKUP_LIMITS.maxBytes + 1)).reason, 'size');
  assert.equal(validateBackupCandidate(null).reason, 'type');
});

test('restore rejects empty, oversized, and unparsable payloads without throwing', () => {
  assert.equal(readBackup('', { normalizeProgress }).reason, 'empty');
  assert.equal(readBackup(null, { normalizeProgress }).reason, 'empty');
  assert.equal(readBackup('{ not json', { normalizeProgress }).reason, 'json');

  const oversized = readBackup('x'.repeat(BACKUP_LIMITS.maxBytes + 10), { normalizeProgress });
  assert.equal(oversized.reason, 'size');
  assert.ok(oversized.bytes > BACKUP_LIMITS.maxBytes);

  // Multi-byte text is measured in bytes, not characters, so the cap cannot be walked past.
  assert.equal(byteLength('锚学'), 6);
  assert.equal(byteLength(''), 0);
  assert.equal(readBackup('锚'.repeat(BACKUP_LIMITS.maxBytes / 2), { normalizeProgress }).reason, 'size');
});

test('restore rejects foreign JSON, wrong versions, and section-free payloads', () => {
  assert.equal(readBackup('[]', { normalizeProgress }).reason, 'format');
  assert.equal(readBackup('"a string"', { normalizeProgress }).reason, 'format');
  assert.equal(readBackup('42', { normalizeProgress }).reason, 'format');
  assert.equal(readBackup('null', { normalizeProgress }).reason, 'format');
  assert.equal(readBackup(JSON.stringify({ some: 'other tool' }), { normalizeProgress }).reason, 'format');
  assert.equal(readBackup(JSON.stringify({ format: 'other.app.backup', version: 1, progress: {} }), { normalizeProgress }).reason, 'format');

  const future = readBackup(JSON.stringify({ format: BACKUP_FORMAT, version: BACKUP_VERSION + 1, progress: {} }), { normalizeProgress });
  assert.equal(future.reason, 'version');
  assert.equal(future.version, BACKUP_VERSION + 1);
  assert.equal(readBackup(JSON.stringify({ format: BACKUP_FORMAT, version: '1', progress: {} }), { normalizeProgress }).reason, 'version');

  assert.equal(readBackup(JSON.stringify({ format: BACKUP_FORMAT, version: BACKUP_VERSION }), { normalizeProgress }).reason, 'shape');
  assert.equal(readBackup(JSON.stringify({ format: BACKUP_FORMAT, version: BACKUP_VERSION, progress: 'nope', library: [], agent: null }), { normalizeProgress }).reason, 'shape');
});

test('a hostile backup is normalized down to the fields this build understands', () => {
  const { library } = sampleState();
  const hostile = {
    format: BACKUP_FORMAT,
    version: BACKUP_VERSION,
    exportedAt: 'not a date',
    progress: {
      version: 1,
      activeDatasetId: '../../etc/passwd',
      datasets: {
        flutter: { currentIndex: 9_999, completed: 'yes', answers: { 'flutter-state-owner': ['state', 'injected'] }, submitted: { 'flutter-state-owner': true } },
        'not-a-dataset': { currentIndex: 0, answers: {}, submitted: {} },
      },
    },
    library: {
      version: LIBRARY_VERSION,
      sources: [
        { ...library.sources[0], name: '<img src=x onerror="alert(1)">' },
        { id: 'bogus', name: 'no sections' },
      ],
    },
    agent: { version: AGENT_SESSION_VERSION, datasetId: 'flutter', turnIndex: 4_000, completed: true, reflections: { unknown: 'x' }, hints: 'nope' },
    extraSection: { please: 'restore me' },
    __proto__: { polluted: true },
  };

  const result = readBackup(JSON.stringify(hostile), { name: 'hostile.json', normalizeProgress });
  assert.equal(result.ok, true);
  assert.deepEqual(result.declared, [...BACKUP_SECTIONS]);
  assert.equal(result.exportedAt, 0);

  // Sections outside the allow-list never become restorable state.
  assert.deepEqual(Object.keys(result.sections).sort(), ['agent', 'library', 'progress']);
  assert.equal(result.sections.extraSection, undefined);
  assert.equal({}.polluted, undefined);

  assert.equal(result.sections.progress.activeDatasetId, null);
  assert.equal(result.sections.progress.datasets['not-a-dataset'], undefined);
  assert.equal(result.sections.progress.datasets.flutter.currentIndex, 3);
  assert.deepEqual(result.sections.progress.datasets.flutter.answers['flutter-state-owner'], ['state']);

  // The markup-looking name survives as text; escaping is the renderer's job and is asserted in the
  // browser suite. What matters here is that it is stored as a plain string, unparsed.
  assert.equal(result.sections.library.sources.length, 1);
  assert.equal(typeof result.sections.library.sources[0].name, 'string');
  assert.equal(result.sections.library.sources[0].name, '<img src=x onerror="alert(1)">');

  assert.equal(result.sections.agent.turnIndex <= 3, true);
  assert.deepEqual(result.sections.agent.reflections, {});
  assert.deepEqual(result.sections.agent.hints, {});
});

test('sections a backup declares but cannot be read are reported as dropped, never merged', () => {
  const { progress } = sampleState();
  const result = readBackup(JSON.stringify({
    format: BACKUP_FORMAT,
    version: BACKUP_VERSION,
    progress,
    library: { version: 999, sources: [{ id: 'x', name: 'x.md', sections: [] }] },
    agent: { version: 999, datasetId: 'flutter' },
  }), { normalizeProgress });

  assert.equal(result.ok, true);
  assert.deepEqual(result.declared, [...BACKUP_SECTIONS]);
  assert.deepEqual(result.dropped, ['library', 'agent']);
  assert.equal(result.sections.agent, undefined);
  assert.deepEqual(result.sections.library.sources, []);
  assert.equal(result.counts.answers, 1);
  assert.equal(result.counts.sources, 0);
  assert.equal(result.counts.reflections, 0);
});

test('a partial backup restores only the sections it declares', () => {
  const { library } = sampleState();
  const result = readBackup(JSON.stringify(createBackup({ library, exportedAt: 1_756_000_000_000 })), { normalizeProgress });
  assert.equal(result.ok, true);
  assert.deepEqual(result.declared, ['library']);
  assert.deepEqual(result.dropped, []);
  assert.equal(result.sections.progress, undefined);
  assert.equal(result.sections.agent, undefined);
  assert.equal(result.counts.sources, 1);
});

test('theme normalization accepts only the palettes this build ships', () => {
  assert.equal(normalizeTheme('light'), 'light');
  assert.equal(normalizeTheme('dark'), 'dark');
  assert.equal(normalizeTheme({ version: THEME_VERSION, theme: 'dark' }), 'dark');

  for (const rejected of [null, undefined, '', 'system', 'sepia', 'DARK', 42, [], ['dark'], { theme: 'dark' }, { version: 99, theme: 'dark' }, { version: THEME_VERSION, theme: 'neon' }]) {
    assert.equal(normalizeTheme(rejected), null, `accepted ${JSON.stringify(rejected)}`);
  }

  assert.deepEqual(createThemeRecord('dark'), { version: THEME_VERSION, theme: 'dark' });
  assert.deepEqual(createThemeRecord('nonsense'), { version: THEME_VERSION, theme: 'light' });
});

test('the system hint is only a fallback: a stored choice always wins', () => {
  assert.equal(resolveTheme(null, false), 'light');
  assert.equal(resolveTheme(null, true), 'dark');
  assert.equal(resolveTheme('sepia', true), 'dark');
  assert.equal(resolveTheme('light', true), 'light');
  assert.equal(resolveTheme('dark', false), 'dark');
  assert.equal(resolveTheme({ version: THEME_VERSION, theme: 'light' }, true), 'light');
  assert.equal(resolveTheme(undefined), 'light');
});

/** A stored library holding two files, shaped exactly as `normalizeLocalLibrary` leaves it. */
function searchLibraryFixture() {
  return normalizeLocalLibrary({
    version: LIBRARY_VERSION,
    sources: [
      {
        id: 'notes-1',
        name: 'anchor-notes.md',
        bytes: 320,
        importedAt: 1_760_000_000_000,
        sectionCount: 2,
        sections: [
          { heading: 'Widget lifecycle', level: 2, line: 1, kind: 'heading', excerpt: 'My own notes about a StatefulWidget rebuild.' },
          { heading: null, level: 0, line: 9, kind: 'preamble', excerpt: 'Loose paragraph with no heading above it.' },
        ],
      },
      {
        id: 'plan-2',
        name: '计划.md',
        bytes: 210,
        importedAt: 1_760_000_001_000,
        sectionCount: 1,
        sections: [
          { heading: '复习计划', level: 1, line: 1, kind: 'heading', excerpt: '每周复习一次 Git 提交记录。' },
        ],
      },
    ],
  });
}

test('folding makes matching case-insensitive and width-insensitive without a locale branch', () => {
  assert.equal(foldSearchText('  Stateful\n  Widget  '), 'stateful widget');
  assert.equal(foldSearchText('ＪａｖａＳｃｒｉｐｔ'), 'javascript');
  assert.equal(foldSearchText('Ｇｉｔ 提交'), 'git 提交');
  assert.equal(foldSearchText(null), '');
  assert.equal(foldSearchText(undefined), '');
});

test('a query is capped and split into terms a record must all contain', () => {
  assert.deepEqual(librarySearchTerms('  Event   LOOP '), ['event', 'loop']);
  assert.deepEqual(librarySearchTerms('loop loop LOOP'), ['loop']);
  assert.deepEqual(librarySearchTerms('提交记录'), ['提交记录']);
  assert.deepEqual(librarySearchTerms(''), []);
  assert.deepEqual(librarySearchTerms('   '), []);
  assert.deepEqual(librarySearchTerms(null), []);

  const many = librarySearchTerms('a b c d e f g h i j k l');
  assert.equal(many.length, LIBRARY_SEARCH_LIMITS.maxTerms);

  const long = 'x'.repeat(LIBRARY_SEARCH_LIMITS.maxQueryChars + 40);
  assert.equal(clampLibraryQuery(long).length, LIBRARY_SEARCH_LIMITS.maxQueryChars);
  assert.equal(librarySearchTerms(long)[0].length, LIBRARY_SEARCH_LIMITS.maxQueryChars);
});

test('a deck query is capped and split by the same rules as the library search', () => {
  assert.deepEqual(deckSearchTerms('  Flutter   LIFECYCLE '), ['flutter', 'lifecycle']);
  assert.deepEqual(deckSearchTerms('运行时'), ['运行时']);
  assert.deepEqual(deckSearchTerms(''), []);
  assert.deepEqual(deckSearchTerms(null), []);

  const long = 'x'.repeat(DECK_SEARCH_LIMITS.maxQueryChars + 25);
  assert.equal(clampDeckQuery(long).length, DECK_SEARCH_LIMITS.maxQueryChars);
  assert.equal(deckSearchTerms('a b c d e f g h i').length, DECK_SEARCH_LIMITS.maxTerms);
});

test('a question counts as verified only when it carries a citation', () => {
  for (const dataset of DATASETS) {
    // Every bundled question cites a source, so the browser demo never shows an unverified deck.
    assert.equal(verifiedQuestionCount(dataset), dataset.questions.length);
  }

  assert.equal(verifiedQuestionCount({ questions: [{ citations: [] }, { citations: [{}] }] }), 1);
  assert.equal(verifiedQuestionCount({ questions: [{}, { citations: null }] }), 0);
  assert.equal(verifiedQuestionCount({}), 0);
  assert.equal(verifiedQuestionCount(null), 0);
});

test('deck progress becomes a decile class because the deployed policy forbids inline widths', () => {
  assert.equal(deckProgressFill(0, 4), 0);
  assert.equal(deckProgressFill(1, 4), 30);
  assert.equal(deckProgressFill(2, 4), 50);
  assert.equal(deckProgressFill(4, 4), 100);
  assert.equal(deckProgressFill(9, 4), 100);
  assert.equal(deckProgressFill(1, 0), 0);
});

test('one pass resolves a deck card so its badge, bar, and action cannot disagree', () => {
  const dataset = getDataset('flutter');

  const untouched = deckCardModel(dataset, {});
  assert.equal(untouched.total, dataset.questions.length);
  assert.equal(untouched.verified, dataset.questions.length);
  assert.equal(untouched.answered, 0);
  assert.equal(untouched.percent, 0);
  assert.equal(untouched.fill, 0);
  assert.equal(untouched.tier, 'start');
  assert.equal(untouched.action, 'start');
  assert.equal(untouched.startable, true);

  const halfway = deckCardModel(dataset, { answered: 2, correct: 1 });
  assert.equal(halfway.percent, 50);
  assert.equal(halfway.fill, 50);
  assert.equal(halfway.tier, 'progress');
  assert.equal(halfway.action, 'continue');

  // Answering the last question and the stored completion flag are both ways to finish a deck.
  for (const state of [{ answered: dataset.questions.length }, { completed: true }]) {
    const done = deckCardModel(dataset, state);
    assert.equal(done.completed, true);
    assert.equal(done.action, 'review');
  }
  assert.equal(deckCardModel(dataset, { answered: dataset.questions.length }).tier, 'complete');

  // Counts arriving from storage are clamped rather than trusted: a stale key cannot print 9/4.
  const overshoot = deckCardModel(dataset, { answered: 99, correct: 99 });
  assert.equal(overshoot.answered, dataset.questions.length);
  assert.equal(overshoot.correct, dataset.questions.length);
  assert.equal(overshoot.percent, 100);
  const negative = deckCardModel(dataset, { answered: -3, correct: -3 });
  assert.equal(negative.answered, 0);
  assert.equal(negative.correct, 0);
});

test('a deck with no verified question offers no start', () => {
  const unverified = deckCardModel({ id: 'draft', mark: 'DR', questions: [{ citations: [] }, {}] });
  assert.equal(unverified.verified, 0);
  assert.equal(unverified.startable, false);
  assert.equal(unverified.action, 'pending');

  const empty = deckCardModel({ id: 'empty', questions: [] });
  assert.equal(empty.total, 0);
  assert.equal(empty.percent, 0);
  assert.equal(empty.action, 'pending');
});

test('a day stamp is the device calendar date, not a UTC one', () => {
  // Built from local getters, so the stamp matches the day the learner is actually having.
  const noon = new Date(2026, 7, 29, 12, 0, 0);
  assert.equal(localDayStamp(noon.getTime()), '2026-08-29');

  // Month and day are padded, so string comparison is enough to tell one day from another.
  assert.equal(localDayStamp(new Date(2026, 0, 5, 9, 30).getTime()), '2026-01-05');

  // Local midnight belongs to the day it starts, whatever the offset does to the UTC date.
  const midnight = new Date(2026, 7, 29, 0, 0, 0);
  assert.equal(localDayStamp(midnight.getTime()), '2026-08-29');
  assert.equal(localDayStamp(new Date(2026, 7, 29, 23, 59, 59).getTime()), '2026-08-29');

  // An unusable timestamp is no day at all, which every caller reads as "nothing answered today".
  for (const bad of [null, NaN, Infinity, -1, 0, 'today', {}]) assert.equal(localDayStamp(bad), '');

  // No argument means now, which is how the shell asks whether a stored stamp is still today's.
  assert.match(localDayStamp(), /^\d{4}-\d{2}-\d{2}$/);
  assert.equal(localDayStamp(), localDayStamp(Date.now()));
});

test('the daily goal is capped by what is left to answer, so it can always be reached', () => {
  const fresh = dailyGoalModel({ answeredToday: 0, remainingQuestions: 12 });
  assert.equal(fresh.goal, DAILY_GOAL_QUESTIONS);
  assert.equal(fresh.done, 0);
  assert.equal(fresh.remaining, DAILY_GOAL_QUESTIONS);
  assert.equal(fresh.met, false);
  assert.equal(fresh.exhausted, false);
  assert.equal(fresh.percent, 0);
  assert.equal(fresh.fill, 0);

  const partway = dailyGoalModel({ answeredToday: 1, remainingQuestions: 11 });
  assert.equal(partway.remaining, DAILY_GOAL_QUESTIONS - 1);
  assert.equal(partway.met, false);
  assert.equal(partway.percent, 25);
  assert.equal(partway.fill, 30);

  const met = dailyGoalModel({ answeredToday: DAILY_GOAL_QUESTIONS, remainingQuestions: 8 });
  assert.equal(met.met, true);
  assert.equal(met.remaining, 0);
  assert.equal(met.percent, 100);
  assert.equal(met.fill, 100);

  // Only four questions left means today's target is four, not a number the bundled set cannot supply.
  const scarce = dailyGoalModel({ answeredToday: 0, remainingQuestions: 2, target: 4 });
  assert.equal(scarce.goal, 2);
  assert.equal(scarce.met, false);

  // Work already done today still counts once it has used up the last question: the goal shrinks to
  // what was reachable and reads as met, instead of a bar stuck at 2 of 4 forever.
  const finished = dailyGoalModel({ answeredToday: 2, remainingQuestions: 0 });
  assert.equal(finished.goal, 2);
  assert.equal(finished.met, true);
  assert.equal(finished.exhausted, true);
  assert.equal(finished.percent, 100);

  // Everything answered on an earlier day: no goal to show today, and the surface is told why.
  const spent = dailyGoalModel({ answeredToday: 0, remainingQuestions: 0 });
  assert.equal(spent.goal, 0);
  assert.equal(spent.met, false);
  assert.equal(spent.exhausted, true);
  assert.equal(spent.percent, 0);
  assert.equal(spent.fill, 0);

  // Counts arriving from storage are clamped, and overshooting the target still reads as done.
  const overshoot = dailyGoalModel({ answeredToday: 9, remainingQuestions: 3 });
  assert.equal(overshoot.goal, DAILY_GOAL_QUESTIONS);
  assert.equal(overshoot.percent, 100);
  assert.equal(overshoot.fill, 100);
  const negative = dailyGoalModel({ answeredToday: -5, remainingQuestions: -5 });
  assert.equal(negative.done, 0);
  assert.equal(negative.goal, 0);
  assert.deepEqual(dailyGoalModel(), dailyGoalModel({ answeredToday: 0, remainingQuestions: 0 }));
});

/** Progress lookup for the dashboard model, keyed by dataset id. Anything unlisted reads as untouched. */
function homeProgress(byId = {}) {
  return (dataset) => byId[dataset.id] ?? {};
}

test('the home dashboard sums bundled totals against this browser\'s own progress', () => {
  const zero = homeDashboardModel({ progressFor: homeProgress() });
  assert.equal(zero.summary.total, 12);
  assert.equal(zero.summary.answered, 0);
  assert.equal(zero.summary.correct, 0);
  assert.equal(zero.summary.started, 0);
  assert.equal(zero.summary.decks, DATASETS.length);
  assert.equal(zero.summary.decksComplete, 0);
  assert.equal(zero.summary.remaining, 12);
  assert.equal(zero.summary.percent, 0);

  // Every bundled deck gets a row, in bundled order, whether or not it has been touched.
  assert.deepEqual(zero.rows.map((row) => row.id), DATASETS.map((dataset) => dataset.id));
  assert.deepEqual(zero.rows.map((row) => row.remaining), [4, 4, 4]);

  const mixed = homeDashboardModel({
    progressFor: homeProgress({
      flutter: { answered: 4, correct: 3, completed: true },
      git: { answered: 1, correct: 1 },
    }),
  });
  assert.equal(mixed.summary.answered, 5);
  assert.equal(mixed.summary.correct, 4);
  assert.equal(mixed.summary.started, 2);
  assert.equal(mixed.summary.decksComplete, 1);
  assert.equal(mixed.summary.remaining, 7);
  assert.equal(mixed.summary.percent, 42);
  assert.deepEqual(mixed.rows.map((row) => row.remaining), [0, 3, 4]);
  assert.deepEqual(mixed.rows.map((row) => row.fill), [100, 30, 0]);

  // A deck can be flagged complete with nothing recorded against it, which a restored record can do.
  // The flag counts the deck as finished; the four questions are still unanswered, and `remaining` says
  // so rather than letting the flag hide work the learner could still do.
  const flagged = homeDashboardModel({ progressFor: homeProgress({ git: { completed: true } }) });
  assert.equal(flagged.rows[1].completed, true);
  assert.equal(flagged.rows[1].remaining, 4);
  assert.equal(flagged.summary.decksComplete, 1);
  assert.equal(flagged.summary.percent, 0);

  // The percentage is coverage of the bundled set, not a score: it moves on answers, not on correctness.
  const wrong = homeDashboardModel({ progressFor: homeProgress({ flutter: { answered: 4, correct: 0 } }) });
  assert.equal(wrong.summary.percent, 33);
  assert.equal(wrong.summary.correct, 0);
});

test('the home focus deck is picked from stored progress, never from a schedule', () => {
  // Nothing started: the first bundled deck, offered as a start rather than a resume.
  const fresh = homeDashboardModel({ progressFor: homeProgress() });
  assert.equal(fresh.focus.id, DATASETS[0].id);
  assert.equal(fresh.focus.action, 'start');
  assert.equal(fresh.focus.remaining, 4);

  // The deck this browser last opened wins while it still has questions left.
  const resumed = homeDashboardModel({
    activeDatasetId: 'javascript',
    progressFor: homeProgress({ flutter: { answered: 1 }, javascript: { answered: 2 } }),
  });
  assert.equal(resumed.focus.id, 'javascript');
  assert.equal(resumed.focus.action, 'continue');
  assert.equal(resumed.focus.remaining, 2);

  // Once that deck is finished the hint is stale, so the first unfinished deck in bundled order takes over.
  const stale = homeDashboardModel({
    activeDatasetId: 'javascript',
    progressFor: homeProgress({ javascript: { completed: true }, git: { answered: 1 } }),
  });
  assert.equal(stale.focus.id, DATASETS[0].id);

  // An unknown or missing hint is simply ignored; the choice stays deterministic either way.
  for (const activeDatasetId of [null, undefined, 'not-a-deck']) {
    assert.equal(homeDashboardModel({ activeDatasetId, progressFor: homeProgress() }).focus.id, DATASETS[0].id);
  }

  // Everything answered: Home still offers one deck, now as a review, and reports nothing left.
  const done = homeDashboardModel({
    progressFor: homeProgress(Object.fromEntries(DATASETS.map((dataset) => [dataset.id, { completed: true, answered: dataset.questions.length }]))),
  });
  assert.equal(done.focus.id, DATASETS[0].id);
  assert.equal(done.focus.action, 'review');
  assert.equal(done.focus.remaining, 0);
  assert.equal(done.daily.exhausted, true);

  // No practisable deck means no focus at all, rather than a card that opens an empty deck.
  const unverified = homeDashboardModel({
    datasets: [{ id: 'draft', mark: 'DR', title: { en: 'Draft', zh: '草稿' }, questions: [{ citations: [] }] }],
    progressFor: homeProgress(),
  });
  assert.equal(unverified.focus, null);
  assert.equal(unverified.rows.length, 1);
  assert.deepEqual(homeDashboardModel({ datasets: [], progressFor: homeProgress() }).focus, null);
});

test('the home daily goal is derived from the same progress, capped by what is unanswered', () => {
  const fresh = homeDashboardModel({ answeredToday: 0, progressFor: homeProgress() });
  assert.equal(fresh.daily.goal, DAILY_GOAL_QUESTIONS);
  assert.equal(fresh.daily.done, 0);
  assert.equal(fresh.daily.exhausted, false);

  const working = homeDashboardModel({ answeredToday: 2, progressFor: homeProgress({ flutter: { answered: 2 } }) });
  assert.equal(working.daily.done, 2);
  assert.equal(working.daily.remaining, DAILY_GOAL_QUESTIONS - 2);
  assert.equal(working.daily.met, false);

  // The last two bundled questions answered today: the goal is what was reachable, and it is met.
  const nearlyDone = homeDashboardModel({
    answeredToday: 2,
    progressFor: homeProgress({
      flutter: { answered: 4, completed: true },
      git: { answered: 4, completed: true },
      javascript: { answered: 4, completed: true },
    }),
  });
  assert.equal(nearlyDone.daily.goal, 2);
  assert.equal(nearlyDone.daily.met, true);
  assert.equal(nearlyDone.daily.exhausted, true);
});

test('deck search filters by the title in the language on screen', () => {
  const idle = searchDecks('   ');
  assert.deepEqual(idle.terms, []);
  assert.equal(idle.matches.length, DATASETS.length);
  assert.equal(idle.total, DATASETS.length);
  assert.deepEqual(idle.matches.map((dataset) => dataset.id), DATASETS.map((dataset) => dataset.id));

  // Folding covers case and width, so a shouted or full-width query still lands.
  assert.deepEqual(searchDecks('FLUTTER').matches.map((dataset) => dataset.id), ['flutter']);
  assert.deepEqual(searchDecks('ｇｉｔ').matches.map((dataset) => dataset.id), ['git']);

  // Every term has to appear in the same title, which is what keeps a two-word query narrow.
  assert.deepEqual(searchDecks('javascript runtime').matches.map((dataset) => dataset.id), ['javascript']);
  assert.deepEqual(searchDecks('javascript lifecycle').matches, []);

  // The title is matched in the locale on screen, so a Chinese query needs the Chinese titles.
  assert.deepEqual(searchDecks('协作', { locale: 'zh' }).matches.map((dataset) => dataset.id), ['git']);
  assert.deepEqual(searchDecks('协作', { locale: 'en' }).matches, []);
  assert.deepEqual(searchDecks('生命周期', { locale: 'zh' }).matches.map((dataset) => dataset.id), ['flutter']);

  // A summary word is deliberately not searched: the surface promises to match the deck name.
  assert.deepEqual(searchDecks('staging').matches, []);

  const missed = searchDecks('kotlin');
  assert.deepEqual(missed.matches, []);
  assert.deepEqual(missed.terms, ['kotlin']);
  assert.equal(missed.total, DATASETS.length);

  assert.deepEqual(searchDecks('flutter', { datasets: [] }).matches, []);
  assert.equal(searchDecks('flutter', { datasets: null }).total, 0);
});

test('the index covers every bundled excerpt and every imported section, kinds kept apart', () => {
  const index = buildLibraryIndex({ library: searchLibraryFixture(), locale: 'en' });
  const bundled = index.filter((record) => record.kind === 'bundled');
  const imported = index.filter((record) => record.kind === 'imported');

  assert.equal(bundled.length, countSources());
  assert.equal(imported.length, 3);
  assert.equal(index.length, bundled.length + imported.length);
  assert.equal(new Set(index.map((record) => record.id)).size, index.length);

  const first = bundled[0];
  assert.equal(first.scope, `bundled:${DATASETS[0].id}`);
  assert.equal(first.locator, DATASETS[0].questions[0].citations[0].locator);
  assert.deepEqual(first.fields.map((field) => field.field), ['name', 'locator', 'prompt', 'excerpt']);

  const section = imported[0];
  assert.equal(section.scope, 'imported:notes-1');
  assert.equal(section.scopeName, 'anchor-notes.md');
  assert.equal(section.locator, 'anchor-notes.md#widget-lifecycle');
  assert.equal(section.sectionIndex, 0);
  assert.deepEqual(section.fields.map((field) => field.field), ['name', 'heading', 'locator', 'excerpt']);

  // A heading-free section drops the heading field rather than indexing an empty string.
  assert.deepEqual(imported[1].fields.map((field) => field.field), ['name', 'locator', 'excerpt']);
});

test('the index survives malformed storage instead of throwing', () => {
  for (const library of [null, undefined, {}, { sources: null }, { sources: 'nope' }, { sources: [null] }]) {
    assert.equal(buildLibraryIndex({ library }).length, countSources());
  }

  const ragged = buildLibraryIndex({ library: { sources: [{ id: 'x', name: null, sections: [null, { excerpt: 'kept' }] }] } });
  const imported = ragged.filter((record) => record.kind === 'imported');
  assert.equal(imported.length, 2);
  assert.equal(imported[0].locator, 'source:L1');
  assert.equal(imported[1].text, 'kept');
});

test('bundled search reports the field it matched and keeps the source locator', () => {
  const index = buildLibraryIndex({ locale: 'en' });
  const found = searchLibrary(index, 'microtask');

  assert.ok(found.total >= 1);
  assert.deepEqual(found.terms, ['microtask']);
  assert.equal(found.truncated, false);
  const hit = found.matches[0];
  assert.equal(hit.record.kind, 'bundled');
  assert.equal(hit.record.scopeId, 'javascript');
  assert.ok(hit.record.locator.startsWith('javascript/'));
  assert.ok(hit.reasons.every((reason) => ['name', 'locator', 'prompt', 'excerpt'].includes(reason)));
  assert.ok(hit.reasons.includes('excerpt') || hit.reasons.includes('prompt'));

  // Every term has to land somewhere in the same record, so an unrelated second word narrows to none.
  assert.equal(searchLibrary(index, 'microtask kubernetes').total, 0);
});

test('imported text is searchable by name, heading, and excerpt in either language', () => {
  const library = searchLibraryFixture();
  const index = buildLibraryIndex({ library, locale: 'en' });

  const byName = searchLibrary(index, 'anchor-notes');
  assert.equal(byName.total, 2);
  assert.ok(byName.matches.every((hit) => hit.record.kind === 'imported'));
  assert.deepEqual(byName.matches[0].reasons, ['name', 'locator']);

  // "widget lifecycle" is genuinely in both a bundled dataset title and this file's heading, so the
  // heading hit is asserted through the filter rather than by assuming it outranks a source name.
  const byHeading = searchLibrary(index, 'widget lifecycle', { kind: 'imported' });
  assert.equal(byHeading.total, 1);
  assert.equal(byHeading.matches[0].record.locator, 'anchor-notes.md#widget-lifecycle');
  assert.equal(byHeading.matches[0].primary, 'heading');
  assert.equal(searchLibrary(index, 'widget lifecycle').matches[0].record.kind, 'bundled');

  const byExcerpt = searchLibrary(index, 'loose paragraph');
  assert.equal(byExcerpt.total, 1);
  assert.deepEqual(byExcerpt.matches[0].reasons, ['excerpt']);

  // The locator is built from the file name and the heading, so a hit on either usually shows up in
  // the locator too. Reporting all three is the honest answer, not a bug.
  const chinese = searchLibrary(index, '复习');
  assert.equal(chinese.total, 1);
  assert.equal(chinese.matches[0].record.scopeName, '计划.md');
  assert.equal(chinese.matches[0].record.locator, '计划.md#复习计划');
  assert.deepEqual(chinese.matches[0].reasons, ['heading', 'locator', 'excerpt']);
});

test('ranking is explainable: the field that matched decides the order, then the offset', () => {
  const index = [
    { id: 'a', kind: 'imported', scope: 'imported:a', fields: [{ field: 'excerpt', text: 'a token', folded: 'a token' }] },
    { id: 'b', kind: 'imported', scope: 'imported:b', fields: [{ field: 'name', text: 'token.md', folded: 'token.md' }] },
    { id: 'c', kind: 'imported', scope: 'imported:c', fields: [{ field: 'heading', text: 'A token', folded: 'a token' }] },
    { id: 'd', kind: 'imported', scope: 'imported:d', fields: [{ field: 'heading', text: 'token first', folded: 'token first' }] },
  ];
  assert.deepEqual(searchLibrary(index, 'token').matches.map((hit) => hit.record.id), ['b', 'd', 'c', 'a']);

  // Nothing matched means an empty list, and an empty query never runs a match at all.
  assert.deepEqual(searchLibrary(index, 'absent'), { terms: ['absent'], matches: [], total: 0, truncated: false });
  assert.deepEqual(searchLibrary(index, '  '), { terms: [], matches: [], total: 0, truncated: false });
  assert.deepEqual(searchLibrary(null, 'token'), { terms: ['token'], matches: [], total: 0, truncated: false });
});

test('the result list is capped and says so', () => {
  const index = Array.from({ length: LIBRARY_SEARCH_LIMITS.maxResults + 5 }, (unused, i) => ({
    id: `r${i}`,
    kind: 'imported',
    scope: 'imported:one',
    fields: [{ field: 'excerpt', text: 'token', folded: 'token' }],
  }));
  const found = searchLibrary(index, 'token');
  assert.equal(found.total, LIBRARY_SEARCH_LIMITS.maxResults + 5);
  assert.equal(found.matches.length, LIBRARY_SEARCH_LIMITS.maxResults);
  assert.equal(found.truncated, true);
});

test('the kind and scope filters narrow the same index without changing what a match means', () => {
  const library = searchLibraryFixture();
  const index = buildLibraryIndex({ library, locale: 'en' });

  const all = searchLibrary(index, 'git');
  assert.ok(all.matches.some((hit) => hit.record.kind === 'bundled'));
  assert.ok(all.matches.some((hit) => hit.record.kind === 'imported'));

  const bundledOnly = searchLibrary(index, 'git', { kind: 'bundled' });
  assert.ok(bundledOnly.total > 0);
  assert.ok(bundledOnly.matches.every((hit) => hit.record.kind === 'bundled'));

  const importedOnly = searchLibrary(index, 'git', { kind: 'imported' });
  assert.equal(importedOnly.total, 1);
  assert.equal(importedOnly.matches[0].record.scope, 'imported:plan-2');

  const scoped = searchLibrary(index, 'git', { scope: 'bundled:git' });
  assert.ok(scoped.total > 0);
  assert.ok(scoped.matches.every((hit) => hit.record.scope === 'bundled:git'));
  assert.equal(searchLibrary(index, 'git', { scope: 'imported:notes-1' }).total, 0);
});

test('scope options list every dataset and file, and a stale scope resolves away', () => {
  const library = searchLibraryFixture();
  const scopes = librarySearchScopes({ library, locale: 'en' });
  assert.deepEqual(scopes.map((entry) => entry.value), [
    'bundled:flutter',
    'bundled:git',
    'bundled:javascript',
    'imported:notes-1',
    'imported:plan-2',
  ]);
  assert.deepEqual(librarySearchScopes({ library, locale: 'zh' }).at(2).label, 'JavaScript 运行时');
  assert.deepEqual(librarySearchScopes({}).filter((entry) => entry.kind === 'imported'), []);

  assert.deepEqual(resolveLibrarySearch({ query: ' git  log ', kind: 'imported', scope: 'imported:plan-2' }, scopes), {
    query: 'git log',
    kind: 'imported',
    scope: 'imported:plan-2',
  });
  // A file this browser never imported, and a scope the kind filter excludes, both fall back to all.
  assert.equal(resolveLibrarySearch({ scope: 'imported:gone' }, scopes).scope, '');
  assert.equal(resolveLibrarySearch({ kind: 'bundled', scope: 'imported:plan-2' }, scopes).scope, '');
  assert.deepEqual(resolveLibrarySearch(null, scopes), { query: '', kind: 'all', scope: '' });
  assert.equal(resolveLibrarySearch({ kind: 'semantic' }, scopes).kind, 'all');
  assert.equal(resolveLibrarySearch({ query: 'x'.repeat(200) }, scopes).query.length, LIBRARY_SEARCH_LIMITS.maxQueryChars);
});

test('highlight segments split text without rewriting it, so the caller can escape every piece', () => {
  assert.deepEqual(highlightSegments('Event loop basics', ['loop']), [
    { text: 'Event ', match: false },
    { text: 'loop', match: true },
    { text: ' basics', match: false },
  ]);
  assert.deepEqual(highlightSegments('loop', ['loop']), [{ text: 'loop', match: true }]);
  assert.deepEqual(highlightSegments('Loop the loop', ['loop']), [
    { text: 'Loop', match: true },
    { text: ' the ', match: false },
    { text: 'loop', match: true },
  ]);
  assert.deepEqual(highlightSegments('每周复习一次', ['复习']), [
    { text: '每周', match: false },
    { text: '复习', match: true },
    { text: '一次', match: false },
  ]);

  // Reassembling the segments always returns the original collapsed text, marked or not.
  for (const terms of [[], ['loop'], ['x'], ['event', 'loop']]) {
    assert.equal(highlightSegments('Event  loop', terms).map((part) => part.text).join(''), 'Event loop');
  }
  assert.deepEqual(highlightSegments('', ['loop']), []);
  assert.deepEqual(highlightSegments('plain', null), [{ text: 'plain', match: false }]);

  // A fold that changes length would misplace the marks, so the text comes back unmarked instead.
  assert.deepEqual(highlightSegments('ﬁle', ['fi']), [{ text: 'ﬁle', match: false }]);
});

test('markup in a query or a file excerpt stays inert data, never a field of its own', () => {
  const hostile = '<script>window.__pwned = 1</script>';
  const index = buildLibraryIndex({
    library: { sources: [{ id: 'h', name: '<b>bad</b>.md', sections: [{ heading: null, line: 1, kind: 'preamble', excerpt: hostile }] }] },
  });
  const found = searchLibrary(index, 'window.__pwned');
  assert.equal(found.total, 1);
  // The text is carried verbatim as a string. Escaping is the renderer's job and is asserted end to end.
  assert.equal(found.matches[0].record.text, hostile);
  assert.equal(highlightSegments(hostile, ['script']).map((part) => part.text).join(''), hostile);
  const byName = searchLibrary(index, '<b>bad');
  assert.deepEqual(byName.matches[0].reasons, ['name', 'locator']);
  assert.equal(byName.matches[0].record.locator, '<b>bad</b>.md:L1');
});

test('library search rides in the hash without disturbing any other route', () => {
  assert.deepEqual(parseRoute('#/library'), {
    view: 'library',
    datasetId: null,
    search: { query: '', kind: 'all', scope: '' },
    focus: { sourceId: '', sectionIndex: null },
    questionId: '',
  });
  assert.deepEqual(parseRoute('#/library?q=event+loop&kind=bundled&src=bundled%3Agit').search, {
    query: 'event loop',
    kind: 'bundled',
    scope: 'bundled:git',
  });
  assert.deepEqual(parseRoute('#/library?q=%E5%A4%8D%E4%B9%A0').search.query, '复习');

  // Search state belongs to the Library alone, and junk in the query resolves to defaults.
  assert.deepEqual(parseRoute('#/profile?q=event').search, { query: '', kind: 'all', scope: '' });
  assert.deepEqual(parseRoute('#/library?kind=semantic').search.kind, 'all');
  assert.deepEqual(parseRoute('#/library?q=').search.query, '');

  // A hand-edited or truncated escape has to resolve to a route rather than throw before first paint.
  assert.equal(parseRoute('#/library?q=100%').search.query, '100%');
  assert.equal(parseRoute('#/%').view, 'home');
  assert.equal(parseRoute('#/decks/%E2%9A%A1').view, 'decks');

  assert.equal(routeHash({ view: 'library' }), '#/library');
  assert.equal(routeHash({ view: 'library', search: { query: '  ', kind: 'all', scope: '' } }), '#/library');
  assert.equal(routeHash({ view: 'library', search: { query: 'event loop' } }), '#/library?q=event+loop');
  assert.equal(routeHash({ view: 'library', search: { kind: 'imported' } }), '#/library?kind=imported');
  assert.equal(routeHash({ view: 'profile', search: { query: 'event' } }), '#/profile');
  assert.equal(routeHash({ view: 'decks', datasetId: 'git', search: { query: 'event' } }), '#/decks/git');

  // Round-tripping is what keeps `render` from rewriting the address on every pass.
  for (const hash of ['#/library', '#/library?q=event+loop', '#/library?q=%E5%A4%8D%E4%B9%A0&kind=imported', '#/library?kind=bundled&src=bundled%3Agit']) {
    assert.equal(routeHash(parseRoute(hash)), hash);
  }
});

test('an exact target rides in the hash next to the search it came from', () => {
  // A bundled result addresses one question inside the deck already in the path.
  assert.equal(parseRoute('#/decks/flutter?question=flutter-init-order').questionId, 'flutter-init-order');
  assert.equal(
    routeHash({ view: 'decks', datasetId: 'flutter', questionId: 'flutter-init-order' }),
    '#/decks/flutter?question=flutter-init-order',
  );

  // An imported result addresses one section of one source, and needs both halves to be a place.
  assert.deepEqual(parseRoute('#/library?q=notes&open=anchor-notes-abc&sec=2').focus, {
    sourceId: 'anchor-notes-abc',
    sectionIndex: 2,
  });
  assert.equal(
    routeHash({ view: 'library', search: { query: 'notes' }, focus: { sourceId: 'anchor-notes-abc', sectionIndex: 2 } }),
    '#/library?q=notes&open=anchor-notes-abc&sec=2',
  );
  assert.equal(parseRoute('#/library?open=anchor-notes-abc').focus.sourceId, '');
  assert.equal(parseRoute('#/library?sec=2').focus.sectionIndex, null);
  assert.equal(routeHash({ view: 'library', focus: { sourceId: 'only-an-id', sectionIndex: null } }), '#/library');
  assert.equal(routeHash({ view: 'library', focus: { sourceId: '', sectionIndex: 3 } }), '#/library');

  // A target belongs to the surface that can act on it, so neither one leaks onto the other.
  assert.equal(parseRoute('#/library?question=flutter-init-order').questionId, '');
  assert.equal(parseRoute('#/decks/flutter?open=anchor-notes-abc&sec=1').focus.sourceId, '');
  assert.equal(parseRoute('#/profile?open=anchor-notes-abc&sec=1').focus.sourceId, '');
  assert.equal(parseRoute('#/profile?question=flutter-init-order').questionId, '');
  assert.equal(routeHash({ view: 'profile', questionId: 'flutter-init-order' }), '#/profile');
  assert.equal(routeHash({ view: 'home', focus: { sourceId: 'anchor-notes-abc', sectionIndex: 1 } }), '#/home');

  // A question without a deck has nothing to be an index into, so it is not carried.
  assert.equal(parseRoute('#/decks?question=flutter-init-order').questionId, '');
  assert.equal(routeHash({ view: 'decks', questionId: 'flutter-init-order' }), '#/decks');

  // Only digits are a section index. Anything else degrades to no target rather than to a coerced one,
  // so a hand-edited link cannot land on a section nobody asked for.
  for (const raw of ['-1', '1.5', '+1', '1e0', 'two', '', ' ', 'NaN', 'Infinity', '1,2']) {
    const focus = parseRoute(`#/library?open=anchor-notes-abc&sec=${encodeURIComponent(raw)}`).focus;
    assert.deepEqual(focus, { sourceId: '', sectionIndex: null }, `sec=${raw} is not a section`);
  }
  assert.equal(parseRoute('#/library?open=anchor-notes-abc&sec=0').focus.sectionIndex, 0);

  // A padded or zero-filled index is read, then written back in its one canonical form, the way the
  // query and kind parameters have always been. `render` replaces the address, so it stops drifting.
  assert.equal(parseRoute('#/library?open=anchor-notes-abc&sec=%201%20').focus.sectionIndex, 1);
  assert.equal(parseRoute('#/library?open=anchor-notes-abc&sec=007').focus.sectionIndex, 7);
  assert.equal(
    routeHash(parseRoute('#/library?open=anchor-notes-abc&sec=007')),
    '#/library?open=anchor-notes-abc&sec=7',
  );

  // Ids are bounded before anything looks them up, so a padded link cannot grow the work.
  assert.equal(parseRoute(`#/library?open=${'a'.repeat(400)}&sec=1`).focus.sourceId.length, 160);
  assert.equal(parseRoute(`#/decks/flutter?question=${'a'.repeat(400)}`).questionId.length, 160);

  // A malformed escape has to resolve to a route rather than throw before the first paint.
  assert.equal(parseRoute('#/library?open=100%&sec=1').view, 'library');
  assert.equal(parseRoute('#/decks/flutter?question=100%').view, 'decks');

  // Round-tripping keeps `render` from rewriting an address that already names its target.
  for (const hash of [
    '#/decks/flutter?question=flutter-init-order',
    '#/library?open=anchor-notes-abc&sec=0',
    '#/library?q=notes&kind=imported&src=imported%3Aanchor-notes-abc&open=anchor-notes-abc&sec=2',
  ]) {
    assert.equal(routeHash(parseRoute(hash)), hash);
  }

  // The parameter names are part of the link contract, so a rename has to be a deliberate edit here.
  assert.deepEqual(ROUTE_TARGET_PARAMS, { question: 'question', source: 'open', section: 'sec' });
});

test('a bundled result resolves to the exact question its excerpt was checked against', () => {
  const dataset = getDataset('flutter');
  assert.equal(resolveQuestionTarget(dataset, 'flutter-init-order'), 1);
  assert.equal(resolveQuestionTarget(dataset, dataset.questions.at(-1).id), dataset.questions.length - 1);

  // -1 is the caller's "no target" state: the deck opens where it already was.
  assert.equal(resolveQuestionTarget(dataset, 'git-staging'), -1);
  assert.equal(resolveQuestionTarget(dataset, 'flutter-init-order-2'), -1);
  assert.equal(resolveQuestionTarget(dataset, ''), -1);
  assert.equal(resolveQuestionTarget(dataset, null), -1);
  assert.equal(resolveQuestionTarget(dataset, undefined), -1);
  assert.equal(resolveQuestionTarget(null, 'flutter-init-order'), -1);
  assert.equal(resolveQuestionTarget({}, 'flutter-init-order'), -1);
  assert.equal(resolveQuestionTarget({ questions: 'nope' }, 'flutter-init-order'), -1);

  // Whitespace is collapsed the way every other route value is, so a padded link still resolves.
  assert.equal(resolveQuestionTarget(dataset, '  flutter-init-order  '), 1);

  // Every shipped citation has to name a question this build can open, in every dataset: the index is
  // what carries the id to the link, so a record whose question is gone would offer a dead action.
  const index = buildLibraryIndex({ library: createEmptyLibrary() });
  const bundled = index.filter((record) => record.kind === 'bundled');
  assert.equal(bundled.length, countSources());
  for (const record of bundled) {
    const owner = getDataset(record.scopeId);
    const at = resolveQuestionTarget(owner, record.questionId);
    assert.ok(at >= 0, `${record.locator} names a question in ${record.scopeId}`);
    // The question it resolves to is the one whose citations actually include this passage.
    assert.ok(
      owner.questions[at].citations.some((citation) => citation.locator === record.locator),
      `${record.locator} resolves to the question citing it`,
    );
    // The hash a result writes has to parse back to the same target it was built from.
    const hash = routeHash({ view: 'decks', datasetId: record.scopeId, questionId: record.questionId });
    assert.deepEqual(
      [parseRoute(hash).datasetId, parseRoute(hash).questionId],
      [record.scopeId, record.questionId],
    );
  }

  // An imported record carries no question, so nothing can mistake it for a bundled target.
  const imported = buildLibraryIndex({
    library: { sources: [{ id: 's', name: 'notes.md', sections: [{ heading: 'A', line: 1, kind: 'heading', excerpt: 'x' }] }] },
  }).filter((record) => record.kind === 'imported');
  assert.equal(imported.length, 1);
  assert.equal(imported[0].questionId, null);
  assert.equal(resolveQuestionTarget(dataset, imported[0].questionId), -1);
});

test('an imported result resolves to the exact section, or to nothing this browser holds', () => {
  const library = {
    version: LIBRARY_VERSION,
    sources: [
      {
        id: 'notes-abc',
        name: 'notes.md',
        sections: [
          { heading: null, level: 0, line: 1, kind: 'preamble', excerpt: 'Opening text.' },
          { heading: 'Widget lifecycle', level: 2, line: 4, kind: 'heading', excerpt: 'A StatefulWidget rebuild.' },
        ],
      },
    ],
  };

  const resolved = resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 1 }, library);
  assert.equal(resolved.source.id, 'notes-abc');
  assert.equal(resolved.sectionIndex, 1);
  assert.equal(resolved.section.heading, 'Widget lifecycle');
  // The section it resolves to is the one the locator on the result names.
  assert.equal(sectionLocator(resolved.source, resolved.section), 'notes.md#widget-lifecycle');
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 0 }, library).section.kind, 'preamble');

  // Null is the surface's "no target" state: the address drops it and the library opens as it was.
  assert.equal(resolveLibraryFocus({ sourceId: 'gone', sectionIndex: 0 }, library), null);
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 2 }, library), null);
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: -1 }, library), null);
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: null }, library), null);
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 1.5 }, library), null);
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: '1' }, library).sectionIndex, 1);
  assert.equal(resolveLibraryFocus({ sourceId: '', sectionIndex: 1 }, library), null);
  assert.equal(resolveLibraryFocus({ sourceId: '  notes-abc  ', sectionIndex: 1 }, library).source.id, 'notes-abc');

  // A link shared into a browser with no imports, or damaged storage, resolves away instead of throwing.
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 0 }, createEmptyLibrary()), null);
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 0 }, null), null);
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 0 }, { sources: 'nope' }), null);
  assert.equal(resolveLibraryFocus(null, library), null);
  assert.equal(resolveLibraryFocus(undefined, library), null);
  assert.equal(resolveLibraryFocus({}, library), null);

  // A source normalization dropped for having no readable section is not addressable either.
  const stripped = normalizeLocalLibrary({ version: LIBRARY_VERSION, sources: [{ id: 'notes-abc', name: 'notes.md', sections: [] }] });
  assert.equal(resolveLibraryFocus({ sourceId: 'notes-abc', sectionIndex: 0 }, stripped), null);

  // Every record the index built for a stored source has to be addressable through its own coordinates,
  // which is what makes the action on a result a pointer rather than a guess.
  for (const record of buildLibraryIndex({ library }).filter((entry) => entry.kind === 'imported')) {
    const hit = resolveLibraryFocus({ sourceId: record.scopeId, sectionIndex: record.sectionIndex }, library);
    assert.ok(hit, `${record.locator} is addressable`);
    assert.equal(sectionLocator(hit.source, hit.section), record.locator);
    const hash = routeHash({ view: 'library', focus: { sourceId: record.scopeId, sectionIndex: record.sectionIndex } });
    assert.deepEqual(parseRoute(hash).focus, { sourceId: record.scopeId, sectionIndex: record.sectionIndex });
  }
});

test('a result action ships bilingual copy for both exact targets', () => {
  const text = SHELL_TEXT.library.search;
  for (const key of ['openBundled', 'openImported', 'openBundledLabel', 'openImportedLabel', 'announceOpened', 'announceBundledOpened']) {
    assert.ok(text[key].en.trim(), `${key} has English copy`);
    assert.ok(text[key].zh.trim(), `${key} has Chinese copy`);
    assert.notEqual(text[key].en, text[key].zh);
  }

  // The accessible name and the announcements name the target, so every placeholder has to be filled.
  for (const locale of ['en', 'zh']) {
    assert.equal(
      formatCount(text.openBundledLabel[locale], { name: 'Flutter' }).includes('{'),
      false,
    );
    assert.equal(formatCount(text.openImportedLabel[locale], { locator: 'notes.md#a' }).includes('{'), false);
    assert.equal(formatCount(text.announceOpened[locale], { name: 'notes.md', locator: 'notes.md#a' }).includes('{'), false);
    assert.equal(
      formatCount(text.announceBundledOpened[locale], { n: 2, total: 4, name: 'Flutter' }).includes('{'),
      false,
    );
  }
});

test('a review row links to the passage its answer cited', () => {
  // The locator is the query because it is the one bundled field that reads the same in both locales, so a
  // row resolves to the same record whichever language is on screen.
  assert.deepEqual(sourceRevisitSearch('flutter/widgets.md#statefulwidget', 'flutter'), {
    query: 'flutter/widgets.md#statefulwidget',
    kind: 'bundled',
    scope: 'bundled:flutter',
  });

  // Without a deck the search still runs, just across every bundled source.
  assert.deepEqual(sourceRevisitSearch('git/branching.md#merge'), {
    query: 'git/branching.md#merge',
    kind: 'bundled',
    scope: '',
  });

  // Null is the renderer's "no link" state, not an error to handle downstream.
  assert.equal(sourceRevisitSearch(''), null);
  assert.equal(sourceRevisitSearch('   '), null);
  assert.equal(sourceRevisitSearch(null, 'flutter'), null);
  assert.equal(sourceRevisitSearch(undefined), null);

  // Whitespace is collapsed the same way the Library's own input is, so the link matches what a learner
  // typing the locator by hand would get.
  assert.equal(sourceRevisitSearch('  git/branching.md   #merge  ').query, 'git/branching.md #merge');
  assert.equal(sourceRevisitSearch('flutter/widgets.md#x', '  flutter  ').scope, 'bundled:flutter');

  const long = sourceRevisitSearch('a'.repeat(LIBRARY_SEARCH_LIMITS.maxQueryChars + 40), 'git');
  assert.equal(long.query.length, LIBRARY_SEARCH_LIMITS.maxQueryChars);

  // The link is only worth offering if it lands on the passage the answer cited. Run every shipped citation
  // through the Library's own search: each has to come back as a single match, found on its locator.
  const index = buildLibraryIndex(createEmptyLibrary());
  const scopes = librarySearchScopes(index);
  for (const dataset of DATASETS) {
    for (const question of dataset.questions) {
      for (const citation of question.citations) {
        const search = sourceRevisitSearch(citation.locator, dataset.id);
        // No locator is long enough to be clamped, so no row links to a truncated query that misses.
        assert.equal(search.query, citation.locator);

        // The scope the link asks for has to be one the Library actually offers, or it resolves away.
        assert.ok(scopes.some((scope) => scope.value === search.scope), `${search.scope} is a real scope`);
        assert.deepEqual(resolveLibrarySearch(search, scopes), search);

        const found = searchLibrary(index, search.query, { kind: search.kind, scope: search.scope });
        assert.equal(found.matches.length, 1, `${citation.locator} resolves to one record`);
        assert.equal(found.matches[0].record.locator, citation.locator);
        assert.equal(found.matches[0].record.scopeId, dataset.id);
        assert.equal(found.matches[0].primary, 'locator');
      }
    }
  }
});

test('feedback and review read a citation through one shared search model', () => {
  const dataset = getDataset('flutter');
  const question = dataset.questions[0];

  // The evidence a submitted answer shows and the evidence its review row shows come from the same call, so
  // a locator cannot resolve one way under the question and another way in the review.
  const evidence = citationEvidence(question.citations, dataset.id);
  assert.equal(evidence.length, question.citations.length);
  assert.ok(evidence.length > 0);
  evidence.forEach((citation, at) => {
    assert.equal(citation.locator, question.citations[at].locator);
    assert.deepEqual(citation.excerpt, question.citations[at].excerpt);
    assert.deepEqual(citation.search, sourceRevisitSearch(citation.locator, dataset.id));
  });

  const reviewed = completionReviewModel(dataset, createInitialProgress().datasets.flutter).rows[0];
  assert.deepEqual(reviewed.citations, evidence);

  // A missing locator is the renderer's "say so instead of linking" state, and a question that ships no
  // citations at all yields nothing to render rather than throwing.
  assert.equal(citationEvidence([{ locator: '', excerpt: { en: 'x', zh: 'x' } }], 'flutter')[0].search, null);
  assert.equal(citationEvidence([{ locator: '   ' }], 'flutter')[0].search, null);
  assert.deepEqual(citationEvidence([], 'flutter'), []);
  assert.deepEqual(citationEvidence(undefined, 'flutter'), []);
  assert.deepEqual(citationEvidence(null), []);

  // Without a deck the search stays valid and simply widens to every bundled source.
  assert.equal(citationEvidence(question.citations)[0].search.scope, '');

  // Every citation a feedback panel can show has to land on the passage it names: one bundled record, matched
  // on the locator, inside the deck the answer came from.
  const index = buildLibraryIndex(createEmptyLibrary());
  const scopes = librarySearchScopes(index);
  let checked = 0;
  for (const deck of DATASETS) {
    for (const shown of deck.questions) {
      for (const citation of citationEvidence(shown.citations, deck.id)) {
        assert.ok(citation.search, `${citation.locator} offers a link`);
        assert.deepEqual(resolveLibrarySearch(citation.search, scopes), citation.search);
        const found = searchLibrary(index, citation.search.query, {
          kind: citation.search.kind,
          scope: citation.search.scope,
        });
        assert.equal(found.matches.length, 1, `${citation.locator} resolves to one record`);
        assert.equal(found.matches[0].record.locator, citation.locator);
        assert.equal(found.matches[0].record.scopeId, deck.id);
        assert.equal(found.matches[0].primary, 'locator');
        checked += 1;
      }
    }
  }
  assert.equal(checked, 12);
});

test('the feedback source link ships bilingual copy and a per-locator accessible name', () => {
  const text = SHELL_TEXT.feedback;
  for (const key of ['sourceAction', 'sourceLinkLabel', 'sourceHint', 'sourceMissing']) {
    assert.ok(text[key].en.length > 0, `${key} has English copy`);
    assert.ok(text[key].zh.length > 0, `${key} has Chinese copy`);
    assert.notEqual(text[key].en, text[key].zh);
  }

  // Two links in one panel need two names, so the locator goes into the label rather than being implied by
  // position. The placeholder is the only difference between the two locales' names.
  const locator = 'flutter/widgets.md#statefulwidget';
  for (const copy of [text.sourceLinkLabel.en, text.sourceLinkLabel.zh]) {
    assert.match(copy, /\{locator\}/);
    const named = formatCount(copy, { locator });
    assert.ok(named.includes(locator));
    assert.doesNotMatch(named, /\{locator\}/);
  }

  // The hint is what tells a learner the link stays in this browser and that back comes home, so it has to
  // name both. Nothing here points at a network destination.
  assert.match(text.sourceHint.en, /back/i);
  for (const copy of Object.values(text)) {
    assert.doesNotMatch(copy.en + copy.zh, /https?:\/\//);
  }
});

test('completion review reports each answer against the dataset', () => {
  const dataset = getDataset('flutter');
  const [first, second, third, fourth] = dataset.questions;

  const state = {
    ...createInitialProgress(),
    completed: true,
    answers: {
      [first.id]: [...first.correct],
      [second.id]: ['not-an-option'],
      [third.id]: [...third.correct],
    },
    submitted: { [first.id]: true, [second.id]: true, [third.id]: true },
  };

  const review = completionReviewModel(dataset, state);
  assert.equal(review.datasetId, 'flutter');
  assert.equal(review.rows.length, dataset.questions.length);

  // The summary is derived from the same rows the screen renders, so the count and the badges cannot drift.
  assert.deepEqual(review.summary, { total: 4, answered: 3, correct: 2, incorrect: 1, unanswered: 1 });
  assert.equal(review.summary.correct, scoreDataset(dataset, state));

  assert.deepEqual(review.rows.map((row) => row.status), ['correct', 'incorrect', 'correct', 'unanswered']);
  assert.deepEqual(review.rows.map((row) => row.number), [1, 2, 3, 4]);
  assert.deepEqual(review.rows.map((row) => row.index), [0, 1, 2, 3]);
  assert.deepEqual(review.rows.map((row) => row.questionId), dataset.questions.map((q) => q.id));
  assert.deepEqual(review.rows.map((row) => row.type), dataset.questions.map((q) => q.type));

  // Rows carry resolved options, not ids, because the screen has to print labels in the active locale.
  assert.deepEqual(review.rows[0].selected.map((option) => option.id), first.correct);
  assert.deepEqual(review.rows[0].expected.map((option) => option.id), first.correct);
  assert.ok(review.rows[0].selected.every((option) => option.label));

  // An id that is not in the option list contributes nothing to display, and the row still reads as wrong.
  assert.deepEqual(review.rows[1].selected, []);
  assert.equal(review.rows[1].answered, true);
  assert.equal(review.rows[1].correct, false);
  assert.deepEqual(review.rows[1].expected.map((option) => option.id), second.correct);

  // Nothing stored means nothing claimed: an absent answer is its own state, never reported as incorrect.
  assert.equal(review.rows[3].answered, false);
  assert.equal(review.rows[3].correct, false);
  assert.deepEqual(review.rows[3].selected, []);
  assert.deepEqual(review.rows[3].expected.map((option) => option.id), fourth.correct);

  // Every row offers the citation its question ships with, already resolved to a Library search.
  for (const [index, row] of review.rows.entries()) {
    assert.equal(row.citations.length, dataset.questions[index].citations.length);
    for (const [position, citation] of row.citations.entries()) {
      const source = dataset.questions[index].citations[position];
      assert.equal(citation.locator, source.locator);
      assert.equal(citation.excerpt, source.excerpt);
      assert.deepEqual(citation.search, sourceRevisitSearch(source.locator, 'flutter'));
    }
  }
});

test('completion review keeps multi-select order and survives damaged progress', () => {
  const dataset = getDataset('flutter');
  const multiple = dataset.questions.find((question) => question.type === 'multiple');

  // Click order does not change the row: two learners who picked the same answers read the same line.
  const reversed = completionReviewModel(dataset, {
    answers: { [multiple.id]: [...multiple.correct].reverse() },
    submitted: { [multiple.id]: true },
  });
  const reversedRow = reversed.rows.find((row) => row.questionId === multiple.id);
  assert.equal(reversedRow.status, 'correct');
  assert.deepEqual(
    reversedRow.selected.map((option) => option.id),
    multiple.options.filter((option) => multiple.correct.includes(option.id)).map((option) => option.id),
  );

  // A partial multi-select is wrong, and the row still shows what was picked so the gap is visible.
  const partial = completionReviewModel(dataset, {
    answers: { [multiple.id]: [multiple.correct[0]] },
    submitted: { [multiple.id]: true },
  });
  const partialRow = partial.rows.find((row) => row.questionId === multiple.id);
  assert.equal(partialRow.status, 'incorrect');
  assert.deepEqual(partialRow.selected.map((option) => option.id), [multiple.correct[0]]);

  // A submission flag with no stored answer, or an answer that was never submitted, both read as unanswered
  // rather than as a wrong answer to a question the learner never saw.
  const flagOnly = completionReviewModel(dataset, { answers: {}, submitted: { [multiple.id]: true } });
  assert.equal(flagOnly.rows.find((row) => row.questionId === multiple.id).status, 'unanswered');
  const draftOnly = completionReviewModel(dataset, { answers: { [multiple.id]: [...multiple.correct] }, submitted: {} });
  assert.equal(draftOnly.rows.find((row) => row.questionId === multiple.id).status, 'unanswered');

  // A restored backup or a hand-edited key can be missing whole fields; the review still renders.
  for (const damaged of [undefined, {}, { answers: null, submitted: null }, { answers: { [multiple.id]: 'state' }, submitted: { [multiple.id]: 'yes' } }]) {
    const review = completionReviewModel(dataset, damaged);
    assert.equal(review.rows.length, dataset.questions.length);
    assert.equal(review.summary.unanswered, dataset.questions.length);
    assert.equal(review.summary.correct, 0);
    assert.ok(review.rows.every((row) => row.status === 'unanswered' && row.selected.length === 0));
  }

  // No dataset is a bad route, not a crash: an empty review is what the renderer falls back on.
  const empty = completionReviewModel(undefined, {});
  assert.deepEqual(empty.rows, []);
  assert.deepEqual(empty.summary, { total: 0, answered: 0, correct: 0, incorrect: 0, unanswered: 0 });
  assert.equal(empty.datasetId, '');

  // A fully answered deck normalized from storage reports every row supported and no gap note.
  for (const deck of DATASETS) {
    const finished = normalizeProgress({
      version: 1,
      datasets: {
        [deck.id]: {
          currentIndex: deck.questions.length - 1,
          completed: true,
          answers: Object.fromEntries(deck.questions.map((q) => [q.id, [...q.correct]])),
          submitted: Object.fromEntries(deck.questions.map((q) => [q.id, true])),
        },
      },
    });
    const review = completionReviewModel(deck, finished.datasets[deck.id]);
    assert.equal(review.summary.correct, deck.questions.length);
    assert.equal(review.summary.unanswered, 0);
    assert.equal(review.summary.incorrect, 0);
    assert.ok(review.rows.every((row) => row.status === 'correct'));
    // Each row can reach its source, which is what makes the review worth reading after a perfect run.
    assert.ok(review.rows.every((row) => row.citations.length > 0 && row.citations.every((c) => c.search)));
  }
});
