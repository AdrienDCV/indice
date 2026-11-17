import 'package:flutter/material.dart';

class PaginatedListView extends StatefulWidget {
  const PaginatedListView({
    super.key,
    this.header = const [],
    required this.itemCount,
    required this.itemBuilder,
    this.footer,
    required this.onLoadMore,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  static const loadMoreDistance = 300.0;

  final List<Widget> header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? footer;
  final VoidCallback onLoadMore;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearTheEnd);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreNearTheEnd() {
    if (_scrollController.position.extentAfter <
        PaginatedListView.loadMoreDistance) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final footer = widget.footer;
    return CustomScrollView(
      controller: _scrollController,
      physics: widget.physics,
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverList.list(children: widget.header),
              SliverList.builder(
                itemCount: widget.itemCount,
                itemBuilder: widget.itemBuilder,
              ),
              if (footer != null) SliverToBoxAdapter(child: footer),
            ],
          ),
        ),
      ],
    );
  }
}
