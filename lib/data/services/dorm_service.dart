part of "../data.dart";

class UDormService {
  Future<(UEmptyResponse?, UEmptyResponse?, String?)> settleDormBedContract({
    required UDormBedContractSettleParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedContract/Settle", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> renewDormBedContract({
    required UDormBedContractRenewParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedContract/Renew", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> transferDormBedContract({
    required UDormBedContractTransferParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedContract/Transfer", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> splitDormBedInvoice({
    required UDormBedInvoiceSplitParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/Split", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDormDashboardResponse>?, UEmptyResponse?, String?)> readDormDashboard({
    required UDashboardRangeParams p,
    Function(UResponse<UDormDashboardResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/Dashboard/Read", p.toMap(), _Api.one(UDormDashboardResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> receiveDormBedInvoice({
    required UInvoiceReceiveParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/Receive", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDorm({
    required UDormCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/Dorm/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UDormResponse>>?, UEmptyResponse?, String?)> readDorms({
    required UDormReadParams p,
    Function(UResponse<List<UDormResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/Dorm/Read", p.toMap(), _Api.list(UDormResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDormResponse>?, UEmptyResponse?, String?)> readDormById({
    required UIdParams p,
    Function(UResponse<UDormResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/Dorm/ReadById", p.toMap(), _Api.one(UDormResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDorm({
    required UDormUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/Dorm/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDorm({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/Dorm/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDormRoom({
    required UDormRoomCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormRoom/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UDormRoomResponse>>?, UEmptyResponse?, String?)> readDormRooms({
    required UDormRoomReadParams p,
    Function(UResponse<List<UDormRoomResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormRoom/Read", p.toMap(), _Api.list(UDormRoomResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDormRoomResponse>?, UEmptyResponse?, String?)> readDormRoomById({
    required UIdParams p,
    Function(UResponse<UDormRoomResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormRoom/ReadById", p.toMap(), _Api.one(UDormRoomResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDormRoom({
    required UDormRoomUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormRoom/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDormRoom({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormRoom/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDormBed({
    required UDormBedCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBed/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UDormBedResponse>>?, UEmptyResponse?, String?)> readDormBeds({
    required UDormBedReadParams p,
    Function(UResponse<List<UDormBedResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBed/Read", p.toMap(), _Api.list(UDormBedResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDormBedResponse>?, UEmptyResponse?, String?)> readDormBedById({
    required UIdParams p,
    Function(UResponse<UDormBedResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBed/ReadById", p.toMap(), _Api.one(UDormBedResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDormBed({
    required UDormBedUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBed/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDormBed({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBed/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createDormBedContract({
    required UDormBedContractCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedContract/Create", p.toMap(), _Api.raw<String>(), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UDormBedContractResponse>>?, UResponse<dynamic>?, String?)> readDormBedContract({
    required UDormBedContractReadParams p,
    Function(UResponse<List<UDormBedContractResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedContract/Read", p.toMap(), _Api.list(UDormBedContractResponse.fromMap), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateDormBedContract({
    required UDormBedContractUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedContract/Update", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<dynamic>?, UResponse<dynamic>?, String?)> deleteDormBedContract({
    required UIdParams p,
    Function(UResponse<dynamic> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedContract/Delete", p.toMap(), _Api.dyn, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createDormBedInvoice({
    required UDormBedInvoiceCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/Create", p.toMap(), _Api.raw<String>(), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UDormBedInvoiceResponse>>?, UResponse<dynamic>?, String?)> readDormBedInvoice({
    required UDormBedInvoiceReadParams p,
    Function(UResponse<List<UDormBedInvoiceResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/Read", p.toMap(), _Api.list(UDormBedInvoiceResponse.fromMap), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateDormBedInvoice({
    required UDormBedInvoiceUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/Update", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<dynamic>?, UResponse<dynamic>?, String?)> deleteDormBedInvoice({
    required UIdParams p,
    Function(UResponse<dynamic> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/Delete", p.toMap(), _Api.dyn, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> payDormBedInvoice({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/Pay", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UDormBedInvoiceChartResponse>>?, UEmptyResponse?, String?)> readDormBedInvoiceChartData({
    Function(UResponse<List<UDormBedInvoiceChartResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Dorm/DormBedInvoice/ChartData", <String, dynamic>{}, _Api.list(UDormBedInvoiceChartResponse.fromMap), _Api.empty, onOk, onError, onException);
}
