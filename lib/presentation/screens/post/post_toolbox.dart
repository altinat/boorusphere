import 'package:auto_route/auto_route.dart';
import 'package:boorusphere/data/repository/booru/entity/post.dart';
import 'package:boorusphere/presentation/provider/download/download_state.dart';
import 'package:boorusphere/presentation/provider/favorite_post_state.dart';
import 'package:boorusphere/presentation/routes/app_router.dart';
import 'package:boorusphere/presentation/utils/extensions/buildcontext.dart';
import 'package:boorusphere/presentation/widgets/download_dialog.dart';
import 'package:boorusphere/utils/extensions/number.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PostToolbox extends HookConsumerWidget {
  const PostToolbox(this.post, {super.key});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPadding = context.mediaQuery.viewPadding;
    final safePaddingBottom = useState(viewPadding.bottom);
    if (viewPadding.bottom > safePaddingBottom.value) {
      safePaddingBottom.value = viewPadding.bottom;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      height: safePaddingBottom.value + 86,
      alignment: Alignment.bottomRight,
      padding: EdgeInsets.only(bottom: safePaddingBottom.value + 8, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PostFavoriteButton(post: post),
          PostDownloadButton(post: post),
          PostOpenLinkButton(post: post),
          PostDetailsButton(post: post),
        ],
      ),
    );
  }
}

class PostDetailsButton extends StatelessWidget {
  const PostDetailsButton({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      icon: const Icon(Icons.info),
      onPressed: () => context.router.push(PostDetailsRoute(post: post)),
    );
  }
}

class PostOpenLinkButton extends StatelessWidget {
  const PostOpenLinkButton({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      icon: const Icon(Icons.link_outlined),
      onPressed: () => launchUrlString(post.originalFile,
          mode: LaunchMode.externalApplication),
    );
  }
}

class PostFavoriteButton extends HookConsumerWidget {
  const PostFavoriteButton({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritePostStateProvider);
    final animator =
        useAnimationController(duration: const Duration(milliseconds: 300));
    final animation = useAnimation(
        ColorTween(begin: Colors.white, end: Colors.pink.shade300)
            .animate(animator));
    final isFav = favorites.contains(post);
    isFav ? animator.forward() : animator.reverse();

    return IconButton(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      icon: isFav
          ? Icon(Icons.favorite, color: animation)
          : Icon(Icons.favorite_border, color: animation),
      onPressed: () {
        if (isFav) {
          ref.read(favoritePostStateProvider.notifier).remove(post);
        } else {
          ref.read(favoritePostStateProvider.notifier).save(post);
        }
      },
    );
  }
}

class PostDownloadButton extends ConsumerWidget {
  const PostDownloadButton({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(downloadStateProvider).getProgressByPost(post);

    return Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: progress.status.isDownloading ? progress.progress.ratio : 0,
        ),
        IconButton(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          icon: Icon(progress.status.isDownloaded
              ? Icons.download_done
              : Icons.download),
          onPressed: () {
            DownloaderDialog.show(context: context, post: post);
          },
          disabledColor: context.colorScheme.primary,
        ),
      ],
    );
  }
}
