import test from 'node:test';
import assert from 'node:assert/strict';
import { DATASETS, validateDatasets } from '../landing/app/scripts/data.js';
import { createInitialProgress, isCorrect, normalizeProgress, scoreDataset } from '../landing/app/scripts/app.js';

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
