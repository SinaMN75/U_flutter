part of "../data.dart";

class UCafeService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createCafe({
    required UCafeCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCafeResponse>>?, UEmptyResponse?, String?)> readCafes({
    required UCafeReadParams p,
    Function(UResponse<List<UCafeResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Read", p.toMap(), _Api.list(UCafeResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UCafeResponse>?, UEmptyResponse?, String?)> readCafeById({
    required UIdParams p,
    Function(UResponse<UCafeResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/ReadById", p.toMap(), _Api.one(UCafeResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateCafe({
    required UCafeUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteCafe({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createMenu({
    required UMenuCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Menu/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UMenuResponse>>?, UEmptyResponse?, String?)> readMenus({
    required UMenuReadParams p,
    Function(UResponse<List<UMenuResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Menu/Read", p.toMap(), _Api.list(UMenuResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UMenuResponse>?, UEmptyResponse?, String?)> openMenu({
    required UMenuOpenParams p,
    Function(UResponse<UMenuResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Menu/Open", p.toMap(), _Api.one(UMenuResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateMenu({
    required UMenuUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Menu/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteMenu({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Menu/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createMenuItem({
    required UMenuItemCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/MenuItem/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateMenuItem({
    required UMenuItemUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/MenuItem/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteMenuItem({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/MenuItem/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UMenuOrderResponse>?, UEmptyResponse?, String?)> createOrder({
    required UMenuOrderCreateParams p,
    Function(UResponse<UMenuOrderResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Order/Create", p.toMap(), _Api.one(UMenuOrderResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UMenuOrderResponse>>?, UEmptyResponse?, String?)> readOrders({
    required UMenuOrderReadParams p,
    Function(UResponse<List<UMenuOrderResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Order/Read", p.toMap(), _Api.list(UMenuOrderResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> payOrder({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Order/Pay", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> setOrderStatus({
    required UMenuOrderStatusParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Order/SetStatus", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> cancelOrder({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Cafe/Order/Cancel", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
