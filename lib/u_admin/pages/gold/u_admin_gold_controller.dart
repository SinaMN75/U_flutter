part of "../../u_admin.dart";

class UAdminGoldController extends UBaseController {
  final Rxn<UGoldAccountResponse> account = Rxn<UGoldAccountResponse>();
  final Rxn<UGoldQuoteResponse> quote = Rxn<UGoldQuoteResponse>();
  final RxList<UGoldBalanceResponse> balances = <UGoldBalanceResponse>[].obs;

  final RxState ordersState = RxState();
  final RxList<UGoldOrderResponse> orders = <UGoldOrderResponse>[].obs;
  String? ordersCursor;

  final RxState txnsState = RxState();
  final RxList<UGoldTransactionResponse> txns = <UGoldTransactionResponse>[].obs;
  String? txnsCursor;

  final RxState limitsState = RxState();
  final Rxn<UGoldTradeLimitsResponse> limits = Rxn<UGoldTradeLimitsResponse>();
  final Rxn<UGoldCreditFacilitiesResponse> credit = Rxn<UGoldCreditFacilitiesResponse>();

  final RxState tokensState = RxState();
  final RxList<UGoldApiTokenResponse> tokens = <UGoldApiTokenResponse>[].obs;

  final TextEditingController tokenLabelController = TextEditingController();
  final TextEditingController tokenScopesController = TextEditingController(text: "trade,read");
  final TextEditingController tokenIpsController = TextEditingController();

  void init() {
    readOverview();
    readOrders();
    readTransactions();
    readLimits();
    readTokens();
  }

  Future<void> readOverview() async {
    state.loading();
    await UServices.gold.readAccount(
      onOk: (UResponse<UGoldAccountResponse> r) => account.value = r.result,
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    await UServices.gold.readQuote(
      p: UGoldQuoteParams(),
      onOk: (UResponse<UGoldQuoteResponse> r) => quote.value = r.result,
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    await UServices.gold.readBalances(
      onOk: (UResponse<List<UGoldBalanceResponse>> r) {
        balances.value = r.result ?? <UGoldBalanceResponse>[];
        state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  Future<void> readOrders({bool more = false}) async {
    if (!more) {
      ordersCursor = null;
      orders.clear();
    }
    ordersState.loading();
    await UServices.gold.readOrders(
      p: UGoldReadOrdersParams(cursor: ordersCursor, limit: pageSize),
      onOk: (UResponse<UGoldOrderListResponse> r) {
        orders.addAll(r.result?.items ?? <UGoldOrderResponse>[]);
        ordersCursor = r.result?.nextCursor;
        orders.isEmpty ? ordersState.emptying() : ordersState.loaded();
      },
      onError: (UEmptyResponse e) => ordersState.error(),
      onException: (String e) => ordersState.error(),
    );
  }

  Future<void> readTransactions({bool more = false}) async {
    if (!more) {
      txnsCursor = null;
      txns.clear();
    }
    txnsState.loading();
    await UServices.gold.readTransactions(
      p: UGoldReadTransactionsParams(cursor: txnsCursor, limit: pageSize),
      onOk: (UResponse<UGoldTransactionListResponse> r) {
        txns.addAll(r.result?.items ?? <UGoldTransactionResponse>[]);
        txnsCursor = r.result?.nextCursor;
        txns.isEmpty ? txnsState.emptying() : txnsState.loaded();
      },
      onError: (UEmptyResponse e) => txnsState.error(),
      onException: (String e) => txnsState.error(),
    );
  }

  Future<void> readLimits() async {
    limitsState.loading();
    await UServices.gold.readTradeLimits(
      onOk: (UResponse<UGoldTradeLimitsResponse> r) => limits.value = r.result,
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    await UServices.gold.readCreditFacilities(
      onOk: (UResponse<UGoldCreditFacilitiesResponse> r) {
        credit.value = r.result;
        limitsState.loaded();
      },
      onError: (UEmptyResponse e) => limitsState.error(),
      onException: (String e) => limitsState.error(),
    );
  }

  Future<void> readTokens() async {
    tokensState.loading();
    await UServices.gold.readApiTokens(
      onOk: (UResponse<List<UGoldApiTokenResponse>> r) {
        tokens.value = r.result ?? <UGoldApiTokenResponse>[];
        tokens.isEmpty ? tokensState.emptying() : tokensState.loaded();
      },
      onError: (UEmptyResponse e) => tokensState.error(),
      onException: (String e) => tokensState.error(),
    );
  }

  void createToken() {
    final List<String> scopes = tokenScopesController.text.split(",").map((String s) => s.trim()).where((String s) => s.isNotEmpty).toList();
    final List<String> ips = tokenIpsController.text.split(",").map((String s) => s.trim()).where((String s) => s.isNotEmpty).toList();
    if (scopes.isEmpty) {
      UToast.error(message: U.s.scopes);
      return;
    }
    ULoading.show();
    UServices.gold.createApiToken(
      p: UGoldCreateApiTokenParams(scopes: scopes, label: tokenLabelController.text.trim(), ipWhitelist: ips.isEmpty ? null : ips),
      onOk: (UResponse<UGoldApiTokenResponse> r) {
        ULoading.dismiss();
        final String? raw = r.result?.rawToken;
        if (raw != null) {
          UClipboard.set(raw);
          UToast.success(message: U.s.copyThisTokenNowItIsShownOnlyOnce);
        }
        okCallback(r.message, readTokens);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        errorCallBack(e.message, readTokens);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void deleteToken(String id) {
    ULoading.show();
    UServices.gold.deleteApiToken(
      p: UGoldDeleteApiTokenParams(tokenId: id),
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        okCallback(r.message, readTokens);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        errorCallBack(e.message, readTokens);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }
}
