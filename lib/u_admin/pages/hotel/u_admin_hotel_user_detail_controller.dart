part of "../../u_admin.dart";

enum UAdminHotelContractLifecycle { active, upcoming, expired }

/// One hotel user: wallets, merchants, dorm contracts and payments.
class UAdminHotelUserDetailController extends UAdminBaseController {
  late UUserResponse user;
  List<UDormBedContractResponse> contracts = <UDormBedContractResponse>[];

  void init({required UUserResponse user}) {
    this.user = user;
    read();
  }

  Future<void> read() async {
    state.loading();
    user =
        (await UServices.user.readById(
          p: UIdParams(
            id: user.id,
            selectorArgs: const UUserSelectorArgs(wallet: UWalletSelectorArgs(), merchant: UMerchantSelectorArgs()),
          ),
        )).$1?.result ??
        user;
    final (UResponse<List<UDormBedContractResponse>>? r, _, _) = await UServices.hotel.readDormBedContract(
      p: UDormBedContractReadParams(
        userId: user.id,
        pageNumber: 1,
        pageSize: 100,
        selectorArgs: const UDormBedContractSelectorArgs(
          bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs(dorm: UDormSelectorArgs())),
          invoice: UDormBedInvoiceSelectorArgs(),
        ),
      ),
    );
    if (r == null) {
      state.error();
      return;
    }
    contracts = r.result ?? <UDormBedContractResponse>[];
    state.loaded();
  }

  List<UWalletResponse> get wallets => user.wallets ?? <UWalletResponse>[];

  List<UMerchantResponse> get merchants => user.merchants ?? <UMerchantResponse>[];

  double get totalWalletBalance => wallets.fold(0, (double sum, UWalletResponse w) => sum + w.balance);

  UAdminHotelContractLifecycle lifecycleOf(UDormBedContractResponse c) {
    final DateTime now = DateTime.now();
    if (now.isBefore(c.startDate)) return UAdminHotelContractLifecycle.upcoming;
    if (now.isAfter(c.endDate)) return UAdminHotelContractLifecycle.expired;
    return UAdminHotelContractLifecycle.active;
  }

  double outstandingOf(UDormBedContractResponse c) =>
      (c.invoices ?? <UDormBedInvoiceResponse>[]).fold(0, (double sum, UDormBedInvoiceResponse i) => sum + max(i.debtAmount + i.penaltyAmount - i.paidAmount, 0));
}
