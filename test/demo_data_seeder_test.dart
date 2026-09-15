import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/seeders/demo_data_seeder.dart';

void main() {
  sqfliteFfiInit();

  test('demo seed uses the current prerequisite and source schemas', () async {
    final databaseHelper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(databaseHelper.close);

    await DemoDataSeeder(databaseHelper).seedVueCoreDemo();
    final database = await databaseHelper.database;

    final prerequisiteRows = await database.query(
      'knowledge_point_prerequisites',
    );
    expect(prerequisiteRows, hasLength(2));
    expect(
      prerequisiteRows.first.keys,
      containsAll([
        'knowledge_point_id',
        'prerequisite_knowledge_point_id',
        'rationale',
        'citation_ids',
        'created_at',
      ]),
    );

    final sourceRows = await database.query('knowledge_point_sources');
    expect(sourceRows, hasLength(4));
    expect(sourceRows.first.keys, contains('source_chunk_id'));
    expect(sourceRows.first.keys, isNot(contains('source_id')));
  });
}
