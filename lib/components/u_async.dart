import "package:u/utilities.dart";

/// Loads data once and shows loading / error+retry / empty / data by itself. `UAsyncBuilder<List<User>>(load: api.users, builder: (context, users) => UserList(users))`
class UAsyncBuilder<T> extends StatefulWidget {
  /// [load] runs on start and on retry/refresh; [isEmpty] decides when to show [empty].
  const UAsyncBuilder({
    required this.load,
    required this.builder,
    super.key,
    this.loading,
    this.error,
    this.empty,
    this.isEmpty,
    this.pullToRefresh = false,
  });

  /// The async job, e.g. `() => api.getUsers()`.
  final Future<T> Function() load;

  /// Builds the screen from the loaded data.
  final Widget Function(BuildContext context, T data) builder;

  /// Shown while loading (a spinner by default).
  final Widget? loading;

  /// Shown on failure; call retry() to try again (UErrorRetry by default).
  final Widget Function(BuildContext context, Object error, VoidCallback retry)? error;

  /// Shown when [isEmpty] says the data is empty (UEmptyState by default).
  final Widget? empty;

  /// Decides "no data"; lists, maps and strings are checked automatically when null.
  final bool Function(T data)? isEmpty;

  /// Adds pull-to-refresh around the data view (the builder should return a scrollable).
  final bool pullToRefresh;

  @override
  State<UAsyncBuilder<T>> createState() => UAsyncBuilderState<T>();
}

/// State of [UAsyncBuilder]; reach it with a GlobalKey to call reload(). `key.currentState?.reload()`
class UAsyncBuilderState<T> extends State<UAsyncBuilder<T>> {
  late Future<T> _future = widget.load();

  /// Runs load() again and shows the loading view meanwhile.
  void reload() => setState(() => _future = widget.load());

  Future<void> _refresh() async {
    final Future<T> next = widget.load();
    await next;
    if (mounted) setState(() => _future = next);
  }

  bool _empty(T data) {
    if (widget.isEmpty != null) return widget.isEmpty!(data);
    if (data == null) return true;
    if (data is Iterable) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    if (data is String) return data.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return widget.loading ?? const Center(child: CircularProgressIndicator.adaptive());
      if (snapshot.hasError) return widget.error?.call(context, snapshot.error!, reload) ?? Center(child: UErrorRetry(onTap: reload));
      final T data = snapshot.data as T;
      if (_empty(data)) return widget.empty ?? const Center(child: UEmptyState());
      final Widget child = widget.builder(context, data);
      return widget.pullToRefresh ? RefreshIndicator.adaptive(onRefresh: _refresh, child: child) : child;
    },
  );
}

/// Listens to a stream and shows loading / error / data. `UStreamView<int>(stream: counter, builder: (context, v) => Text("$v"))`
class UStreamView<T> extends StatelessWidget {
  /// Shows [loading] until the first value arrives.
  const UStreamView({required this.stream, required this.builder, super.key, this.initialData, this.loading, this.error});

  /// The stream to listen to.
  final Stream<T> stream;

  /// Builds from the latest value.
  final Widget Function(BuildContext context, T data) builder;

  /// Value shown before the stream emits (skips the loading view).
  final T? initialData;

  /// Shown until the first value (a spinner by default).
  final Widget? loading;

  /// Shown when the stream reports an error.
  final Widget Function(BuildContext context, Object error)? error;

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: stream,
    initialData: initialData,
    builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
      if (snapshot.hasError) return error?.call(context, snapshot.error!) ?? Center(child: Text("${snapshot.error}"));
      if (!snapshot.hasData) return loading ?? const Center(child: CircularProgressIndicator.adaptive());
      return builder(context, snapshot.data as T);
    },
  );
}

/// Infinite-scroll list: loads page 1, then the next page near the end, with pull-to-refresh. `UPaginatedList<Post>(fetch: (page) => api.posts(page), itemBuilder: (c, p, i) => PostTile(p))`
class UPaginatedList<T> extends StatefulWidget {
  /// A page shorter than [pageSize] means there is no more data.
  const UPaginatedList({
    required this.fetch,
    required this.itemBuilder,
    super.key,
    this.pageSize = 20,
    this.firstPage = 1,
    this.separator,
    this.padding,
    this.empty,
    this.header,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  /// Loads one page; pages count from [firstPage].
  final Future<List<T>> Function(int page) fetch;

  /// Builds one row.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Items per page, used to know when the end is reached.
  final int pageSize;

  /// Number of the first page (1 by default, use 0 for zero-based APIs).
  final int firstPage;

  /// Widget between rows, e.g. `const Divider()`.
  final Widget? separator;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Shown when the first page is empty.
  final Widget? empty;

  /// Widget above the first row (scrolls with the list).
  final Widget? header;

  /// Optional scroll controller.
  final ScrollController? controller;

  /// Sizes the list to its content (inside another scrollable).
  final bool shrinkWrap;

  /// Scroll physics.
  final ScrollPhysics? physics;

  @override
  State<UPaginatedList<T>> createState() => UPaginatedListState<T>();
}

/// State of [UPaginatedList]; reach it with a GlobalKey to call refresh(). `key.currentState?.refresh()`
class UPaginatedListState<T> extends State<UPaginatedList<T>> {
  final List<T> _items = <T>[];
  late int _page = widget.firstPage;
  bool _loading = false;
  bool _done = false;
  Object? _error;

  /// Every item loaded so far.
  List<T> get items => List<T>.unmodifiable(_items);

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  /// Clears everything and loads the first page again.
  Future<void> refresh() async {
    setState(() {
      _items.clear();
      _page = widget.firstPage;
      _done = false;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _done) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<T> page = await widget.fetch(_page);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _page++;
        _done = page.length < widget.pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _error != null) return Center(child: UErrorRetry(onTap: _loadMore));
    if (_items.isEmpty && _loading) return const Center(child: CircularProgressIndicator.adaptive());
    if (_items.isEmpty && _done) {
      return RefreshIndicator.adaptive(
        onRefresh: refresh,
        child: ListView(children: <Widget>[if (widget.header != null) widget.header!, widget.empty ?? const UEmptyState().pAll(32)]),
      );
    }
    final int extra = widget.header == null ? 0 : 1;
    return RefreshIndicator.adaptive(
      onRefresh: refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification n) {
          if (n.metrics.extentAfter < 400) _loadMore();
          return false;
        },
        child: ListView.separated(
          controller: widget.controller,
          padding: widget.padding,
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          itemCount: _items.length + extra + 1,
          separatorBuilder: (BuildContext context, int index) => index < extra || index >= _items.length + extra - 1 ? const SizedBox.shrink() : (widget.separator ?? const SizedBox.shrink()),
          itemBuilder: (BuildContext context, int index) {
            if (index < extra) return widget.header!;
            final int i = index - extra;
            if (i < _items.length) return widget.itemBuilder(context, _items[i], i);
            if (_error != null) return TextButton(onPressed: _loadMore, child: Text(U.s.tryAgain));
            if (_done) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          },
        ),
      ),
    );
  }
}

/// Rebuilds with the online/offline state. `UOnlineBuilder(builder: (context, online) => online ? Feed() : OfflinePage())`
class UOnlineBuilder extends StatelessWidget {
  /// Uses the connectivity state that initU() starts watching.
  const UOnlineBuilder({required this.builder, super.key});

  /// Builds with true when online.
  final Widget Function(BuildContext context, bool online) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: UNetwork.onlineStream,
    initialData: UNetwork.isOnline,
    builder: (BuildContext context, AsyncSnapshot<bool> s) => builder(context, s.data ?? true),
  );
}

/// Shows a slim "No internet" bar above [child] while offline. `UOfflineBanner(child: HomePage())`
class UOfflineBanner extends StatelessWidget {
  /// [message] defaults to a localized "no internet" text.
  const UOfflineBanner({required this.child, super.key, this.message, this.color});

  /// The page under the banner.
  final Widget child;

  /// Banner text.
  final String? message;

  /// Banner color (the theme's error color by default).
  final Color? color;

  @override
  Widget build(BuildContext context) => UOnlineBuilder(
    builder: (BuildContext context, bool online) => Column(
      children: <Widget>[
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: online
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: color ?? Theme.of(context).colorScheme.error,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 6,
                        children: <Widget>[
                          Icon(Icons.wifi_off, size: 16, color: Theme.of(context).colorScheme.onError),
                          Text(message ?? U.s.noInternet, style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}
