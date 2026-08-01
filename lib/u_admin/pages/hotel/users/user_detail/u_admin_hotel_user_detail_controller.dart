part of "../../../../u_admin.dart";

enum UAdminContractLifecycle { active, upcoming, expired }

class UAdminHotelUserDetailController {
  UAdminHotelUserDetailController({required this.user});

  UUserResponse user;

  final Rx<PageState> state = PageState.initial.obs;
  final RxList<UDormBedContractResponse> contracts = <UDormBedContractResponse>[].obs;

  Future<void> init() async => read();

  Future<void> read() async {
    state.loading();
    await UServices.user.readById(
      p: UIdParams(
        id: user.id,
        selectorArgs: const UserSelectorArgs(wallet: WalletSelectorArgs(), merchant: MerchantSelectorArgs()),
      ),
      onOk: (UResponse<UUserResponse> r) {
        if (r.result != null) user = r.result!;
      },
      onError: (UEmptyResponse r) {},
      onException: (String e) {},
    );
    await UServices.hotel.readDormBedContract(
      p: UDormBedContractReadParams(
        userId: user.id,
        pageNumber: 1,
        pageSize: 100,
        selectorArgs: const ContractSelectorArgs(
          bed: DormBedSelectorArgs(room: DormRoomSelectorArgs(dorm: DormSelectorArgs())),
          invoice: InvoiceSelectorArgs(),
        ),
      ),
      onOk: (UResponse<List<UDormBedContractResponse>> r) {
        contracts.value = r.result ?? <UDormBedContractResponse>[];
        state.loaded();
      },
      onError: (UResponse<dynamic> e) => state.error(),
      onException: (String e) => state.error(),
    );
  }

  List<UWalletResponse> get wallets => user.wallets ?? <UWalletResponse>[];

  List<UMerchantResponse> get merchants => user.merchants ?? <UMerchantResponse>[];

  double get totalWalletBalance => wallets.fold(0, (double sum, UWalletResponse w) => sum + w.balance);

  int get activeContractsCount => contracts.where((UDormBedContractResponse c) => lifecycleOf(c) == UAdminContractLifecycle.active).length;

  double get totalOutstanding => contracts.fold(0, (double sum, UDormBedContractResponse c) => sum + outstandingOf(c));

  UAdminContractLifecycle lifecycleOf(UDormBedContractResponse c) {
    final DateTime now = DateTime.now();
    if (now.isBefore(c.startDate)) return UAdminContractLifecycle.upcoming;
    if (now.isAfter(c.endDate)) return UAdminContractLifecycle.expired;
    return UAdminContractLifecycle.active;
  }

  List<UDormBedInvoiceResponse> invoicesOf(UDormBedContractResponse c) => c.invoices ?? <UDormBedInvoiceResponse>[];

  int unpaidCountOf(UDormBedContractResponse c) => invoicesOf(c).length;

  double outstandingOf(UDormBedContractResponse c) => invoicesOf(c).fold(0, (double sum, UDormBedInvoiceResponse i) {
    final double remaining = (i.debtAmount + i.penaltyAmount) - i.paidAmount;
    return sum + (remaining > 0 ? remaining : 0);
  });
}
