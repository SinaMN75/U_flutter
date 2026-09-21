part of "../data.dart";

class UUserSelectorArgs {
  final UCategorySelectorArgs? category;
  final UMediaSelectorArgs? media;
  final UTxnSelectorArgs? txns;
  final UAddressSelectorArgs? address;
  final UWalletSelectorArgs? wallet;
  final UMerchantSelectorArgs? merchant;
  final UBankAccountSelectorArgs? bankAccount;
  final USimCardSelectorArgs? simCard;

  const UUserSelectorArgs({
    this.category,
    this.media,
    this.txns,
    this.address,
    this.wallet,
    this.merchant,
    this.bankAccount,
    this.simCard,
  });

  factory UUserSelectorArgs.fromJson(String str) => UUserSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UUserSelectorArgs.fromMap(Map<String, dynamic> json) => UUserSelectorArgs(
    category: json["category"] == null ? null : UCategorySelectorArgs.fromMap(json["category"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
    txns: json["txns"] == null ? null : UTxnSelectorArgs.fromMap(json["txns"]),
    address: json["address"] == null ? null : UAddressSelectorArgs.fromMap(json["address"]),
    wallet: json["wallet"] == null ? null : UWalletSelectorArgs.fromMap(json["wallet"]),
    merchant: json["merchant"] == null ? null : UMerchantSelectorArgs.fromMap(json["merchant"]),
    bankAccount: json["bankAccount"] == null ? null : UBankAccountSelectorArgs.fromMap(json["bankAccount"]),
    simCard: json["simCard"] == null ? null : USimCardSelectorArgs.fromMap(json["simCard"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "category": category?.toMap(),
    "media": media?.toMap(),
    "txns": txns?.toMap(),
    "address": address?.toMap(),
    "wallet": wallet?.toMap(),
    "merchant": merchant?.toMap(),
    "bankAccount": bankAccount?.toMap(),
    "simCard": simCard?.toMap(),
  };
}

class UParkingReportSelectorArgs {
  final UUserSelectorArgs? creator;
  final UVehicleSelectorArgs? vehicle;
  final UParkingSelectorArgs? parking;

  const UParkingReportSelectorArgs({this.creator, this.vehicle, this.parking});

  factory UParkingReportSelectorArgs.fromJson(String str) => UParkingReportSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingReportSelectorArgs.fromMap(Map<String, dynamic> json) => UParkingReportSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    vehicle: json["vehicle"] == null ? null : UVehicleSelectorArgs.fromMap(json["vehicle"]),
    parking: json["parking"] == null ? null : UParkingSelectorArgs.fromMap(json["parking"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "vehicle": vehicle?.toMap(),
    "parking": parking?.toMap(),
  };
}

class UVasSelectorArgs {
  final UUserSelectorArgs? creator;
  final UWalletTxnSelectorArgs? walletTxn;
  final UTxnSelectorArgs? txn;

  const UVasSelectorArgs({this.creator, this.walletTxn, this.txn});

  factory UVasSelectorArgs.fromJson(String str) => UVasSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UVasSelectorArgs.fromMap(Map<String, dynamic> json) => UVasSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    walletTxn: json["walletTxn"] == null ? null : UWalletTxnSelectorArgs.fromMap(json["walletTxn"]),
    txn: json["txn"] == null ? null : UTxnSelectorArgs.fromMap(json["txn"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "walletTxn": walletTxn?.toMap(),
    "txn": txn?.toMap(),
  };
}

class UCategorySelectorArgs {
  final UUserSelectorArgs? creator;
  final UMediaSelectorArgs? media;
  final UCategorySelectorArgs? children;
  final int? childrenDebt;

  const UCategorySelectorArgs({this.creator, this.media, this.children, this.childrenDebt});

  factory UCategorySelectorArgs.fromJson(String str) => UCategorySelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UCategorySelectorArgs.fromMap(Map<String, dynamic> json) => UCategorySelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
    children: json["children"] == null ? null : UCategorySelectorArgs.fromMap(json["children"]),
    childrenDebt: json["childrenDebt"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "media": media?.toMap(),
    "children": children?.toMap(),
    "childrenDebt": childrenDebt,
  };
}

class UContentSelectorArgs {
  final UUserSelectorArgs? creator;
  final UMediaSelectorArgs? media;

  const UContentSelectorArgs({this.creator, this.media});

  factory UContentSelectorArgs.fromJson(String str) => UContentSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UContentSelectorArgs.fromMap(Map<String, dynamic> json) => UContentSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "media": media?.toMap(),
  };
}

class UTerminalSelectorArgs {
  final UUserSelectorArgs? creator;
  final UMerchantSelectorArgs? merchant;
  final UTerminalBrandSelectorArgs? terminalBrand;
  final UTerminalBrokerSelectorArgs? terminalBroker;
  final bool? agreement;

  const UTerminalSelectorArgs({
    this.creator,
    this.merchant,
    this.agreement,
    this.terminalBrand,
    this.terminalBroker,
  });

  factory UTerminalSelectorArgs.fromJson(String str) => UTerminalSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalSelectorArgs.fromMap(Map<String, dynamic> json) => UTerminalSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    merchant: json["merchant"] == null ? null : UMerchantSelectorArgs.fromMap(json["merchant"]),
    terminalBrand: json["terminalBrand"] == null ? null : UTerminalBrandSelectorArgs.fromMap(json["terminalBrand"]),
    terminalBroker: json["terminalBroker"] == null ? null : UTerminalBrokerSelectorArgs.fromMap(json["terminalBroker"]),
    agreement: json["agreement"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "merchant": merchant?.toMap(),
    "terminalBrand": terminalBrand?.toMap(),
    "terminalBroker": terminalBroker?.toMap(),
    "agreement": agreement,
  };
}

class UMerchantSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;
  final UTerminalSelectorArgs? terminal;

  const UMerchantSelectorArgs({this.creator, this.user, this.terminal});

  factory UMerchantSelectorArgs.fromJson(String str) => UMerchantSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMerchantSelectorArgs.fromMap(Map<String, dynamic> json) => UMerchantSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
    terminal: json["terminal"] == null ? null : UTerminalSelectorArgs.fromMap(json["terminal"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "user": user?.toMap(),
    "terminal": terminal?.toMap(),
  };
}

class UMoadiSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;

  const UMoadiSelectorArgs({this.creator, this.user});

  factory UMoadiSelectorArgs.fromJson(String str) => UMoadiSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMoadiSelectorArgs.fromMap(Map<String, dynamic> json) => UMoadiSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "user": user?.toMap(),
  };
}

class UWalletTxnSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? sender;
  final UUserSelectorArgs? receiver;

  const UWalletTxnSelectorArgs({this.creator, this.sender, this.receiver});

  factory UWalletTxnSelectorArgs.fromJson(String str) => UWalletTxnSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletTxnSelectorArgs.fromMap(Map<String, dynamic> json) => UWalletTxnSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    sender: json["sender"] == null ? null : UUserSelectorArgs.fromMap(json["sender"]),
    receiver: json["receiver"] == null ? null : UUserSelectorArgs.fromMap(json["receiver"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "sender": sender?.toMap(),
    "receiver": receiver?.toMap(),
  };
}

class UNotificationSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;

  const UNotificationSelectorArgs({this.creator, this.user});

  factory UNotificationSelectorArgs.fromJson(String str) => UNotificationSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UNotificationSelectorArgs.fromMap(Map<String, dynamic> json) => UNotificationSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "user": user?.toMap(),
  };
}

class UTicketSelectorArgs {
  final UUserSelectorArgs? creator;
  final UMediaSelectorArgs? media;

  const UTicketSelectorArgs({this.creator, this.media});

  factory UTicketSelectorArgs.fromJson(String str) => UTicketSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTicketSelectorArgs.fromMap(Map<String, dynamic> json) => UTicketSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "media": media?.toMap(),
  };
}

class UProductSelectorArgs {
  final UUserSelectorArgs? creator;
  final String? userId;
  final UProductSelectorArgs? children;
  final UCategorySelectorArgs? category;
  final UMediaSelectorArgs? media;
  final bool? childrenCount;
  final bool? commentsCount;
  final bool? isFollowing;
  final int? childrenDebt;

  const UProductSelectorArgs({
    this.creator,
    this.userId,
    this.children,
    this.category,
    this.media,
    this.childrenCount,
    this.commentsCount,
    this.isFollowing,
    this.childrenDebt,
  });

  factory UProductSelectorArgs.fromJson(String str) => UProductSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UProductSelectorArgs.fromMap(Map<String, dynamic> json) => UProductSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    userId: json["userId"],
    children: json["children"] == null ? null : UProductSelectorArgs.fromMap(json["children"]),
    category: json["category"] == null ? null : UCategorySelectorArgs.fromMap(json["category"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
    childrenCount: json["childrenCount"],
    commentsCount: json["commentsCount"],
    isFollowing: json["isFollowing"],
    childrenDebt: json["childrenDebt"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "userId": userId,
    "children": children?.toMap(),
    "category": category?.toMap(),
    "media": media?.toMap(),
    "childrenCount": childrenCount,
    "commentsCount": commentsCount,
    "isFollowing": isFollowing,
    "childrenDebt": childrenDebt,
  };
}

class UCommentSelectorArgs {
  final UUserSelectorArgs? creator;
  final UCommentSelectorArgs? children;
  final UUserSelectorArgs? user;
  final UMediaSelectorArgs? media;

  const UCommentSelectorArgs({this.creator, this.children, this.user, this.media});

  factory UCommentSelectorArgs.fromJson(String str) => UCommentSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UCommentSelectorArgs.fromMap(Map<String, dynamic> json) => UCommentSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    children: json["children"] == null ? null : UCommentSelectorArgs.fromMap(json["children"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "children": children?.toMap(),
    "user": user?.toMap(),
    "media": media?.toMap(),
  };
}

class UTxnSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;

  const UTxnSelectorArgs({this.creator, this.user});

  factory UTxnSelectorArgs.fromJson(String str) => UTxnSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTxnSelectorArgs.fromMap(Map<String, dynamic> json) => UTxnSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "user": user?.toMap(),
  };
}

class UMediaSelectorArgs {
  final UUserSelectorArgs? creator;

  const UMediaSelectorArgs({this.creator});

  factory UMediaSelectorArgs.fromMap(Map<String, dynamic> json) => UMediaSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UMediaSelectorArgs.fromJson(String str) => UMediaSelectorArgs.fromMap(json.decode(str));
}

class UParkingSelectorArgs {
  final UUserSelectorArgs? creator;

  const UParkingSelectorArgs({this.creator});

  factory UParkingSelectorArgs.fromMap(Map<String, dynamic> json) => UParkingSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UParkingSelectorArgs.fromJson(String str) => UParkingSelectorArgs.fromMap(json.decode(str));
}

class UVehicleSelectorArgs {
  final UUserSelectorArgs? creator;

  const UVehicleSelectorArgs({this.creator});

  factory UVehicleSelectorArgs.fromMap(Map<String, dynamic> json) => UVehicleSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UVehicleSelectorArgs.fromJson(String str) => UVehicleSelectorArgs.fromMap(json.decode(str));
}

class UBankAccountSelectorArgs {
  final UUserSelectorArgs? creator;

  const UBankAccountSelectorArgs({this.creator});

  factory UBankAccountSelectorArgs.fromMap(Map<String, dynamic> json) => UBankAccountSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UBankAccountSelectorArgs.fromJson(String str) => UBankAccountSelectorArgs.fromMap(json.decode(str));
}

class UAddressSelectorArgs {
  final UUserSelectorArgs? creator;

  const UAddressSelectorArgs({this.creator});

  factory UAddressSelectorArgs.fromMap(Map<String, dynamic> json) => UAddressSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UAddressSelectorArgs.fromJson(String str) => UAddressSelectorArgs.fromMap(json.decode(str));
}

class UWalletSelectorArgs {
  final UUserSelectorArgs? creator;

  const UWalletSelectorArgs({this.creator});

  factory UWalletSelectorArgs.fromMap(Map<String, dynamic> json) => UWalletSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UWalletSelectorArgs.fromJson(String str) => UWalletSelectorArgs.fromMap(json.decode(str));
}

class USimCardSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;

  const USimCardSelectorArgs({this.creator, this.user});

  factory USimCardSelectorArgs.fromJson(String str) => USimCardSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory USimCardSelectorArgs.fromMap(Map<String, dynamic> json) => USimCardSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "user": user?.toMap(),
  };
}

class UDormBedContractSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;
  final UDormBedSelectorArgs? bed;
  final UDormBedInvoiceSelectorArgs? invoice;

  const UDormBedContractSelectorArgs({
    this.creator,
    this.user,
    this.bed,
    this.invoice,
  });

  factory UDormBedContractSelectorArgs.fromJson(String str) => UDormBedContractSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedContractSelectorArgs.fromMap(Map<String, dynamic> json) => UDormBedContractSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
    bed: json["bed"] == null ? null : UDormBedSelectorArgs.fromMap(json["bed"]),
    invoice: json["invoice"] == null ? null : UDormBedInvoiceSelectorArgs.fromMap(json["invoice"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "user": user?.toMap(),
    "bed": bed?.toMap(),
    "invoice": invoice?.toMap(),
  };
}

class UDormBedInvoiceSelectorArgs {
  final UDormBedContractSelectorArgs? contract;
  final UUserSelectorArgs? creator;

  const UDormBedInvoiceSelectorArgs({
    this.contract,
    this.creator,
  });

  factory UDormBedInvoiceSelectorArgs.fromJson(String str) => UDormBedInvoiceSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedInvoiceSelectorArgs.fromMap(Map<String, dynamic> json) => UDormBedInvoiceSelectorArgs(
    contract: json["contract"] == null ? null : UDormBedContractSelectorArgs.fromMap(json["contract"]),
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "contract": contract?.toMap(),
    "creator": creator?.toMap(),
  };
}

class UHotelSelectorArgs {
  final UUserSelectorArgs? creator;
  final UHotelRoomSelectorArgs? rooms;
  final UHotelReservationSelectorArgs? reservations;
  final UCommentSelectorArgs? comments;
  final UMediaSelectorArgs? media;

  const UHotelSelectorArgs({this.creator, this.rooms, this.reservations, this.comments, this.media});

  factory UHotelSelectorArgs.fromJson(String str) => UHotelSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelSelectorArgs.fromMap(Map<String, dynamic> json) => UHotelSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    rooms: json["rooms"] == null ? null : UHotelRoomSelectorArgs.fromMap(json["rooms"]),
    reservations: json["reservations"] == null ? null : UHotelReservationSelectorArgs.fromMap(json["reservations"]),
    comments: json["comments"] == null ? null : UCommentSelectorArgs.fromMap(json["comments"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "rooms": rooms?.toMap(),
    "reservations": reservations?.toMap(),
    "comments": comments?.toMap(),
    "media": media?.toMap(),
  };
}

class UHotelRoomSelectorArgs {
  final UUserSelectorArgs? creator;
  final UHotelSelectorArgs? hotel;
  final UHotelReservationSelectorArgs? reservations;
  final UMediaSelectorArgs? media;

  const UHotelRoomSelectorArgs({this.creator, this.hotel, this.reservations, this.media});

  factory UHotelRoomSelectorArgs.fromJson(String str) => UHotelRoomSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomSelectorArgs.fromMap(Map<String, dynamic> json) => UHotelRoomSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    hotel: json["hotel"] == null ? null : UHotelSelectorArgs.fromMap(json["hotel"]),
    reservations: json["reservations"] == null ? null : UHotelReservationSelectorArgs.fromMap(json["reservations"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "hotel": hotel?.toMap(),
    "reservations": reservations?.toMap(),
    "media": media?.toMap(),
  };
}

class UHotelReservationSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;
  final UHotelRoomSelectorArgs? room;
  final UHotelSelectorArgs? hotel;
  final UHotelInvoiceSelectorArgs? invoice;

  const UHotelReservationSelectorArgs({this.creator, this.user, this.room, this.hotel, this.invoice});

  factory UHotelReservationSelectorArgs.fromJson(String str) => UHotelReservationSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationSelectorArgs.fromMap(Map<String, dynamic> json) => UHotelReservationSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
    room: json["room"] == null ? null : UHotelRoomSelectorArgs.fromMap(json["room"]),
    hotel: json["hotel"] == null ? null : UHotelSelectorArgs.fromMap(json["hotel"]),
    invoice: json["invoice"] == null ? null : UHotelInvoiceSelectorArgs.fromMap(json["invoice"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "user": user?.toMap(),
    "room": room?.toMap(),
    "hotel": hotel?.toMap(),
    "invoice": invoice?.toMap(),
  };
}

class UHotelInvoiceSelectorArgs {
  final UUserSelectorArgs? creator;
  final UHotelReservationSelectorArgs? reservation;

  const UHotelInvoiceSelectorArgs({this.creator, this.reservation});

  factory UHotelInvoiceSelectorArgs.fromJson(String str) => UHotelInvoiceSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelInvoiceSelectorArgs.fromMap(Map<String, dynamic> json) => UHotelInvoiceSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    reservation: json["reservation"] == null ? null : UHotelReservationSelectorArgs.fromMap(json["reservation"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "reservation": reservation?.toMap(),
  };
}

class UDormSelectorArgs {
  final UUserSelectorArgs? creator;
  final UDormRoomSelectorArgs? rooms;
  final UDormBedSelectorArgs? beds;
  final UCommentSelectorArgs? comments;
  final UMediaSelectorArgs? media;

  const UDormSelectorArgs({this.creator, this.rooms, this.beds, this.comments, this.media});

  factory UDormSelectorArgs.fromJson(String str) => UDormSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormSelectorArgs.fromMap(Map<String, dynamic> json) => UDormSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    rooms: json["rooms"] == null ? null : UDormRoomSelectorArgs.fromMap(json["rooms"]),
    beds: json["beds"] == null ? null : UDormBedSelectorArgs.fromMap(json["beds"]),
    comments: json["comments"] == null ? null : UCommentSelectorArgs.fromMap(json["comments"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "rooms": rooms?.toMap(),
    "beds": beds?.toMap(),
    "comments": comments?.toMap(),
    "media": media?.toMap(),
  };
}

class UDormRoomSelectorArgs {
  final UUserSelectorArgs? creator;
  final UDormSelectorArgs? dorm;
  final UDormBedSelectorArgs? beds;
  final UMediaSelectorArgs? media;

  const UDormRoomSelectorArgs({this.creator, this.dorm, this.beds, this.media});

  factory UDormRoomSelectorArgs.fromJson(String str) => UDormRoomSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormRoomSelectorArgs.fromMap(Map<String, dynamic> json) => UDormRoomSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    dorm: json["dorm"] == null ? null : UDormSelectorArgs.fromMap(json["dorm"]),
    beds: json["beds"] == null ? null : UDormBedSelectorArgs.fromMap(json["beds"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "dorm": dorm?.toMap(),
    "beds": beds?.toMap(),
    "media": media?.toMap(),
  };
}

class UBlogSelectorArgs {
  final UUserSelectorArgs? creator;
  final UMediaSelectorArgs? media;
  final UCategorySelectorArgs? category;
  final UCommentSelectorArgs? comments;
  final bool? commentsCount;
  final String? userId;
  final UBlogSelectorArgs? children;
  final bool childrenCount;
  final int childrenDebt;

  const UBlogSelectorArgs({
    this.creator,
    this.media,
    this.category,
    this.comments,
    this.commentsCount,
    this.userId,
    this.children,
    this.childrenCount = false,
    this.childrenDebt = 0,
  });

  factory UBlogSelectorArgs.fromJson(String str) => UBlogSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBlogSelectorArgs.fromMap(Map<String, dynamic> json) => UBlogSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
    category: json["category"] == null ? null : UCategorySelectorArgs.fromMap(json["category"]),
    comments: json["comments"] == null ? null : UCommentSelectorArgs.fromMap(json["comments"]),
    commentsCount: json["commentsCount"],
    userId: json["userId"],
    children: json["children"] == null ? null : UBlogSelectorArgs.fromMap(json["children"]),
    childrenCount: json["childrenCount"] ?? false,
    childrenDebt: json["childrenDebt"] ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "media": media?.toMap(),
    "category": category?.toMap(),
    "comments": comments?.toMap(),
    "commentsCount": commentsCount,
    "userId": userId,
    "children": children?.toMap(),
    "childrenCount": childrenCount,
    "childrenDebt": childrenDebt,
  };
}

class UDormBedSelectorArgs {
  final UUserSelectorArgs? creator;
  final UDormRoomSelectorArgs? room;
  final UMediaSelectorArgs? media;
  final UDormBedContractSelectorArgs? contract;

  const UDormBedSelectorArgs({this.creator, this.room, this.media, this.contract});

  factory UDormBedSelectorArgs.fromJson(String str) => UDormBedSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedSelectorArgs.fromMap(Map<String, dynamic> json) => UDormBedSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    room: json["room"] == null ? null : UDormRoomSelectorArgs.fromMap(json["room"]),
    media: json["media"] == null ? null : UMediaSelectorArgs.fromMap(json["media"]),
    contract: json["contract"] == null ? null : UDormBedContractSelectorArgs.fromMap(json["contract"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "room": room?.toMap(),
    "media": media?.toMap(),
    "contract": contract?.toMap(),
  };
}

class UParkingTariffSelectorArgs {
  final UUserSelectorArgs? creator;

  const UParkingTariffSelectorArgs({this.creator});

  factory UParkingTariffSelectorArgs.fromMap(Map<String, dynamic> json) => UParkingTariffSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UParkingTariffSelectorArgs.fromJson(String str) => UParkingTariffSelectorArgs.fromMap(json.decode(str));
}

class UParkingPlateFlagSelectorArgs {
  final UUserSelectorArgs? creator;

  const UParkingPlateFlagSelectorArgs({this.creator});

  factory UParkingPlateFlagSelectorArgs.fromMap(Map<String, dynamic> json) => UParkingPlateFlagSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UParkingPlateFlagSelectorArgs.fromJson(String str) => UParkingPlateFlagSelectorArgs.fromMap(json.decode(str));
}

class UParkingShiftSelectorArgs {
  final UUserSelectorArgs? creator;

  const UParkingShiftSelectorArgs({this.creator});

  factory UParkingShiftSelectorArgs.fromMap(Map<String, dynamic> json) => UParkingShiftSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UParkingShiftSelectorArgs.fromJson(String str) => UParkingShiftSelectorArgs.fromMap(json.decode(str));
}

class UTerminalBrandSelectorArgs {
  final UUserSelectorArgs? creator;

  const UTerminalBrandSelectorArgs({this.creator});

  factory UTerminalBrandSelectorArgs.fromMap(Map<String, dynamic> json) => UTerminalBrandSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UTerminalBrandSelectorArgs.fromJson(String str) => UTerminalBrandSelectorArgs.fromMap(json.decode(str));
}

class UTerminalBrokerSelectorArgs {
  final UUserSelectorArgs? creator;

  const UTerminalBrokerSelectorArgs({this.creator});

  factory UTerminalBrokerSelectorArgs.fromMap(Map<String, dynamic> json) => UTerminalBrokerSelectorArgs(creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]));

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap()};

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerSelectorArgs.fromJson(String str) => UTerminalBrokerSelectorArgs.fromMap(json.decode(str));
}

class UParkingSubscriptionSelectorArgs {
  final UUserSelectorArgs? creator;
  final UVehicleSelectorArgs? vehicle;

  const UParkingSubscriptionSelectorArgs({this.creator, this.vehicle});

  factory UParkingSubscriptionSelectorArgs.fromMap(Map<String, dynamic> json) => UParkingSubscriptionSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    vehicle: json["vehicle"] == null ? null : UVehicleSelectorArgs.fromMap(json["vehicle"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap(), "vehicle": vehicle?.toMap()};

  String toJson() => json.encode(toMap());

  factory UParkingSubscriptionSelectorArgs.fromJson(String str) => UParkingSubscriptionSelectorArgs.fromMap(json.decode(str));
}

class UParkingStaffSelectorArgs {
  final UUserSelectorArgs? creator;
  final UUserSelectorArgs? user;

  const UParkingStaffSelectorArgs({this.creator, this.user});

  factory UParkingStaffSelectorArgs.fromMap(Map<String, dynamic> json) => UParkingStaffSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{"creator": creator?.toMap(), "user": user?.toMap()};

  String toJson() => json.encode(toMap());

  factory UParkingStaffSelectorArgs.fromJson(String str) => UParkingStaffSelectorArgs.fromMap(json.decode(str));
}

class UApiLogSelectorArgs {
  final UUserSelectorArgs? creator;

  const UApiLogSelectorArgs({
    this.creator,
  });

  factory UApiLogSelectorArgs.fromJson(String str) => UApiLogSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UApiLogSelectorArgs.fromMap(Map<String, dynamic> json) => UApiLogSelectorArgs(
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
  };
}

class UGoldTxnSelectorArgs {
  final UUserSelectorArgs? user;
  final UUserSelectorArgs? creator;

  const UGoldTxnSelectorArgs({
    this.user,
    this.creator,
  });

  factory UGoldTxnSelectorArgs.fromJson(String str) => UGoldTxnSelectorArgs.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldTxnSelectorArgs.fromMap(Map<String, dynamic> json) => UGoldTxnSelectorArgs(
    user: json["user"] == null ? null : UUserSelectorArgs.fromMap(json["user"]),
    creator: json["creator"] == null ? null : UUserSelectorArgs.fromMap(json["creator"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "user": user?.toMap(),
    "creator": creator?.toMap(),
  };
}
