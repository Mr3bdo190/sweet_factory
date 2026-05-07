import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/glass_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'create_post_screen.dart';
import '../../widgets/post_card.dart';
import '../../widgets/stories_bar.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  static const int _limit = 15;
  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadPosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      QuerySnapshot querySnapshot;
      if (_lastDocument == null) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(_limit)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .startAfterDocument(_lastDocument!)
            .limit(_limit)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _posts.addAll(querySnapshot.docs);
          _lastDocument = querySnapshot.docs.last;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts.clear();
      _isLoading = false;
      _hasMore = true;
      _lastDocument = null;
    });
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: GlassTheme.primaryAccent,
        backgroundColor: GlassTheme.backgroundDark,
        onRefresh: _refreshPosts,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Stories Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                child: const StoriesBar(),
              ),
            ),
            
            // Create Post Card
            SliverToBoxAdapter(
              child: _buildCreatePostCard(),
            ),
            
            // Posts
            if (_posts.isEmpty && !_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: GlassTheme.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: TextStyle(color: GlassTheme.textSecondary, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to share something!',
                        style: TextStyle(color: GlassTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _posts.length) {
                      final post = _posts[index].data() as Map<String, dynamic>;
                      return PostCard(
                        post: post,
                        postId: _posts[index].id,
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                  childCount: _hasMore ? _posts.length + 1 : _posts.length,
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const CreatePostScreen())
          );
        },
        backgroundColor: GlassTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    return AppBar(
      backgroundColor: GlassTheme.backgroundDark,
      elevation: 0,
      title: const Text(
        'Wateny',
        style: TextStyle(
          color: GlassTheme.primaryAccent,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlassTheme.surfaceLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, color: GlassTheme.textPrimary),
          ),
          onPressed: () {
            // TODO: Implement search
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlassTheme.surfaceLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu, color: GlassTheme.textPrimary),
          ),
          onPressed: () {
            // TODO: Show menu
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCreatePostCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassTheme.glassBorderLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: GlassTheme.primaryAccent,
            backgroundImage: user?.photoURL != null 
                ? CachedNetworkImageProvider(user!.photoURL!) 
                : null,
            child: user?.photoURL == null 
                ? const Icon(Icons.person, color: Colors.white, size: 20) 
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const CreatePostScreen())
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: GlassTheme.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  "What's on your mind?",
                  style: TextStyle(
                    color: GlassTheme.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.image, color: GlassTheme.accentPink),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const CreatePostScreen())
              );
            },
          ),
        ],
      ),
    );
  }
}