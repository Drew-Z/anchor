import 'dart:convert';

import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/ai/tasks/project_understanding_task.dart';
import 'package:dlg_q/services/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectUnderstandingTask', () {
    test('keeps typed units with valid project evidence only', () async {
      final openai = _FakeOpenAIService({
        'units': [
          {
            'kind': 'architecture',
            'title': ' Provider orchestration ',
            'summary': ' Riverpod providers connect tasks and repositories. ',
            'tags': ['Riverpod', 'Riverpod'],
            'difficulty': 3,
            'interview_relevance': 5,
            'source_chunk_ids': ['chunk-a', 'invented'],
          },
          {
            'kind': 'architecture',
            'title': 'Provider orchestration',
            'summary': 'Duplicate title.',
            'source_chunk_ids': ['chunk-a'],
          },
          {
            'kind': 'boundary',
            'title': 'Local-first boundary',
            'summary': 'State is persisted in SQLite.',
            'source_chunk_ids': ['missing'],
          },
          {
            'kind': 'unknown',
            'title': 'Unsupported type',
            'summary': 'Should be discarded.',
            'source_chunk_ids': ['chunk-a'],
          },
        ],
      });
      final task = ProjectUnderstandingTask(openai);
      final result = await task.run(sourceChunks: [_chunk('chunk-a')]);

      expect(result.isSuccess, isTrue);
      expect(result.requireData.units, hasLength(1));
      final unit = result.requireData.units.single;
      expect(unit.kind, KnowledgePointKind.architecture);
      expect(unit.title, 'Provider orchestration');
      expect(unit.sourceChunkIds, ['chunk-a']);
      expect(unit.tags, ['Riverpod']);
      expect(openai.systemPrompt, contains('architecture、data_flow'));
      expect(openai.userContent, contains('relative_path: lib/app.dart'));
      expect(openai.userContent, contains('locator: lib/app.dart:1-2'));
      expect(openai.temperature, 0.1);
    });

    test('rejects a response without valid cited units', () async {
      final task = ProjectUnderstandingTask(
        _FakeOpenAIService({
          'units': [
            {
              'kind': 'trade_off',
              'title': 'Uncited trade-off',
              'summary': 'No known evidence.',
              'source_chunk_ids': ['missing'],
            },
          ],
        }),
      );

      final result = await task.run(sourceChunks: [_chunk('chunk-a')]);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('有效源码引用'));
    });
  });
}

SourceChunk _chunk(String id) {
  return SourceChunk(
    id: id,
    sourceId: 'source-1',
    chunkIndex: 0,
    content: 'final provider = Provider((ref) => Repository());',
    locator: 'lib/app.dart:1-2',
    relativePath: 'lib/app.dart',
    startLine: 1,
    endLine: 2,
    contentHash: 'hash',
    createdAt: DateTime(2026, 7, 14),
  );
}

class _FakeOpenAIService extends OpenAIService {
  final Object response;
  String systemPrompt = '';
  String userContent = '';
  double? temperature;

  _FakeOpenAIService(this.response);

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    this.systemPrompt = systemPrompt;
    this.userContent = userContent;
    this.temperature = temperature;
    return jsonEncode(response);
  }
}
