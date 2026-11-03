part of "../data.dart";

class UStoreService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UStoreCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  /// Public store search with distance, type and open-now filters.
  Future<(UResponse<List<UStoreResponse>>?, UEmptyResponse?, String?)> explore({
    required UStoreExploreParams p,
    Function(UResponse<List<UStoreResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Explore", p.toMap(), _Api.list(UStoreResponse.fromMap), _Api.empty, onOk, onError, onException);

  /// Public product search across stores.
  Future<(UResponse<List<UProductResponse>>?, UEmptyResponse?, String?)> searchProducts({
    required UProductSearchParams p,
    Function(UResponse<List<UProductResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Search", p.toMap(), _Api.list(UProductResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UStoreResponse>>?, UEmptyResponse?, String?)> read({
    required UStoreReadParams p,
    Function(UResponse<List<UStoreResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Read", p.toMap(), _Api.list(UStoreResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UStoreResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UStoreResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/ReadById", p.toMap(), _Api.one(UStoreResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UStoreResponse>?, UEmptyResponse?, String?)> readByCode({
    required UStoreCodeParams p,
    Function(UResponse<UStoreResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/ReadByCode", p.toMap(), _Api.one(UStoreResponse.fromMap), _Api.empty, onOk, onError, onException);

  /// The card, IBAN and owner a buyer pays to; the server counts each read.
  Future<(UResponse<UStorePaymentResponse>?, UEmptyResponse?, String?)> readPayment({
    required UIdParams p,
    Function(UResponse<UStorePaymentResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/ReadPayment", p.toMap(), _Api.one(UStorePaymentResponse.fromMap), _Api.empty, onOk, onError, onException);

  /// How many times the store's QR was scanned; only for its managers.
  Future<(UResponse<UStoreScanResponse>?, UEmptyResponse?, String?)> readScans({
    required UIdParams p,
    Function(UResponse<UStoreScanResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/ReadScans", p.toMap(), _Api.one(UStoreScanResponse.fromMap), _Api.empty, onOk, onError, onException);

  /// Sales and visits of a store for its owner and the platform.
  Future<(UResponse<UStoreReportResponse>?, UEmptyResponse?, String?)> readReport({
    required UStoreReportParams p,
    Function(UResponse<UStoreReportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/ReadReport", p.toMap(), _Api.one(UStoreReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  /// Records goods coming in, a return or waste and updates the stock.
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createStockMove({
    required UStockMoveCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Stock/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  /// The store's stock moves, newest first; pass a product for its history.
  Future<(UResponse<List<UStockMoveResponse>>?, UEmptyResponse?, String?)> readStockMoves({
    required UStockMoveReadParams p,
    Function(UResponse<List<UStockMoveResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Stock/Read", p.toMap(), _Api.list(UStockMoveResponse.fromMap), _Api.empty, onOk, onError, onException);

  /// Records a sale and takes the items out of stock; fails as a whole when one item is short.
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createSale({
    required UStoreSaleCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Sale/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  /// The store's sales, newest first; only for its managers.
  Future<(UResponse<List<UStoreSaleResponse>>?, UEmptyResponse?, String?)> readSales({
    required UStoreSaleReadParams p,
    Function(UResponse<List<UStoreSaleResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Sale/Read", p.toMap(), _Api.list(UStoreSaleResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> review({
    required UStoreReviewParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Review", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UStoreUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createType({
    required UStoreTypeCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UStoreTypeResponse>>?, UEmptyResponse?, String?)> readTypes({
    required UStoreTypeReadParams p,
    Function(UResponse<List<UStoreTypeResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Read", p.toMap(), _Api.list(UStoreTypeResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateType({
    required UStoreTypeUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteType({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createProduct({
    required UProductCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UProductResponse>>?, UEmptyResponse?, String?)> readProducts({
    required UProductReadParams p,
    Function(UResponse<List<UProductResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Read", p.toMap(), _Api.list(UProductResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UProductResponse>?, UEmptyResponse?, String?)> readProductById({
    required UIdParams p,
    Function(UResponse<UProductResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/ReadById", p.toMap(), _Api.one(UProductResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateProduct({
    required UProductUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteProduct({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
