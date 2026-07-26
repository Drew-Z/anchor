import '../database/database_helper.dart';
import '../models/product_event.dart';

class ProductEventRepository {
  final DatabaseHelper _databaseHelper;

  ProductEventRepository(this._databaseHelper);

  Future<bool> insert(ProductEvent event) {
    return _databaseHelper.insertProductEvent(event);
  }

  Future<List<ProductEvent>> getEvents({int? limit}) {
    return _databaseHelper.getProductEvents(limit: limit);
  }

  Future<int> count() {
    return _databaseHelper.countProductEvents();
  }

  Future<int> deleteAll() {
    return _databaseHelper.deleteAllProductEvents();
  }
}
