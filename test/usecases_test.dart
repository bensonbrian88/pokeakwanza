import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stynext/core/architecture/result.dart';
import 'package:stynext/core/architecture/repositories.dart';
import 'package:stynext/domain/usecases/usecases.dart';
import 'package:stynext/models/product.dart';

class MockProductRepo extends Mock implements ProductRepository {}
class MockAuthRepo extends Mock implements AuthRepository {}
class MockCartRepo extends Mock implements CartRepository {}
class MockOrderRepo extends Mock implements OrderRepository {}

void main() {
  group('FetchProductsUseCase', () {
    test('returns products on success', () async {
      final repo = MockProductRepo();
      final usecase = FetchProductsUseCase(repo);
      final products = [Product(id: 1, name: 'A', price: 10.0)];
      when(() => repo.getProducts(page: any(named: 'page'), search: any(named: 'search'), categoryId: any(named: 'categoryId'), perPage: any(named: 'perPage')))
          .thenAnswer((_) async => Success(products));
      final res = await usecase.call(page: 1);
      expect(res.isSuccess, true);
      expect(res.getOrNull(), products);
    });
  });

  group('LoginUseCase', () {
    test('returns token map on success', () async {
      final repo = MockAuthRepo();
      final usecase = LoginUseCase(repo);
      when(() => repo.login(any(), any()))
          .thenAnswer((_) async => Success({'token': 'abc'}));
      final res = await usecase.call(email: 'e', password: 'p');
      expect(res.isSuccess, true);
      expect(res.getOrNull()?['token'], 'abc');
    });
  });

  group('AddToCartUseCase', () {
    test('returns success map', () async {
      final repo = MockCartRepo();
      final usecase = AddToCartUseCase(repo);
      when(() => repo.addToCart(productId: any(named: 'productId'), quantity: any(named: 'quantity')))
          .thenAnswer((_) async => Success({'success': true}));
      final res = await usecase.call(productId: 1, quantity: 2);
      expect(res.isSuccess, true);
      expect(res.getOrNull()?['success'], true);
    });
  });

  group('CreateOrderUseCase', () {
    test('returns order response', () async {
      final repo = MockOrderRepo();
      final usecase = CreateOrderUseCase(repo);
      when(() => repo.createOrder(any()))
          .thenAnswer((_) async => Success({'success': true, 'order_id': 123}));
      final res = await usecase.call({'items': []});
      expect(res.isSuccess, true);
      expect(res.getOrNull()?['order_id'], 123);
    });
  });
}
