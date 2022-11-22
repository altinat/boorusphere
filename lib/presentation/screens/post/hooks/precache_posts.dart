import 'package:boorusphere/data/repository/booru/entity/post.dart';
import 'package:boorusphere/presentation/provider/booru/extension/post.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void Function(int index, bool loadOriginal) usePrecachePosts(
  WidgetRef ref,
  IList<Post> posts,
) {
  return use(_PrecachePostsHook(ref, posts));
}

typedef _Precacher = void Function(int, bool);

class _PrecachePostsHook extends Hook<_Precacher> {
  const _PrecachePostsHook(this.ref, this.posts);

  final WidgetRef ref;
  final IList<Post> posts;

  @override
  _PrecachePostsState createState() => _PrecachePostsState();
}

class _PrecachePostsState extends HookState<_Precacher, _PrecachePostsHook> {
  _PrecachePostsState();

  WidgetRef get ref => hook.ref;
  IList<Post> get posts => hook.posts;

  bool _mounted = true;

  void _precache(
    Post post,
    bool displayOriginal,
    Map<String, String>? headers,
  ) {
    if (!post.content.isPhoto || !_mounted) return;
    precacheImage(
      ExtendedNetworkImageProvider(
        displayOriginal ? post.originalFile : post.content.url,
        headers: headers,
        // params below follows the default value on
        // the ExtendedImage.network() factory
        cache: true,
        retries: 3,
      ),
      context,
    );
  }

  @override
  _Precacher build(BuildContext context) => (i, showOG) {
        if (!_mounted) return;

        final next = i + 1;
        final prev = i - 1;

        if (prev >= 0) {
          _precache(posts[prev], showOG, posts[prev].getHeaders(ref));
        }

        if (next < posts.length) {
          _precache(posts[next], showOG, posts[prev].getHeaders(ref));
        }
      };

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  String get debugLabel => 'usePrecachePosts';
}