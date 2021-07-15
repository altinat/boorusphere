import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../provider/common.dart';
import '../components/home_bar.dart';
import '../components/home_drawer.dart';
import '../components/sliver_thumbnails.dart';

class Home extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final scrollController = useMemoized(() {
      return AutoScrollController(axis: Axis.vertical);
    });
    final api = useProvider(apiProvider);
    final pageLoading = useProvider(pageLoadingProvider);
    final errorMessage = useProvider(errorMessageProvider);

    useEffect(() {
      void loadMore() {
        // Infinite page with scroll detection
        final threshold = MediaQuery.of(context).size.height / 6;
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - threshold) {
          api.loadMore();
        }
      }

      scrollController.addListener(loadMore);
      return () => scrollController.removeListener(loadMore);
    }, [scrollController]);

    return Scaffold(
      drawer: HomeDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top +
                      AppBar().preferredSize.height,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(10),
                sliver: SliverThumbnails(
                  autoScrollController: scrollController,
                ),
              ),
              SliverVisibility(
                visible: errorMessage.state.isNotEmpty,
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.search_off),
                        ),
                        Text(errorMessage.state, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              SliverVisibility(
                visible: pageLoading.state,
                sliver: SliverToBoxAdapter(
                  child: Container(
                    height: 192,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 128,
                      child: LinearProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          HomeBar(),
        ],
      ),
    );
  }
}
