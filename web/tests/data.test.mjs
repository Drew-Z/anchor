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
  LOCAL_IMPORT_LIMITS,
  LIBRARY_VERSION,
  THEME_VERSION,
  agentProgressFill,
  agentReflectionCount,
  backupCounts,
  backupFileName,
  buildAgentScript,
  byteLength,
  clampReflection,
  createAgentSession,
  createBackup,
  createEmptyLibrary,
  createLocalSource,
  createThemeRecord,
  extractSections,
  formatBytes,
  formatImportedAt,
  getDataset,
  looksBinary,
  normalizeAgentSession,
  normalizeLocalLibrary,
  normalizeTheme,
  readBackup,
  resolveTheme,
  sectionLocator,
  truncateExcerpt,
  validateBackupCandidate,
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
