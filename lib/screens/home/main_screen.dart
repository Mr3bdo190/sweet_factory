import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/post_card.dart';
import 'create_post_screen.dart';
import '../../services/presence_service.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _documentLimit = 10; // هنجيب 10 بوستات في المرة الواحدة

  @override
  void initState() {
    super.initState();
    PresenceService().init(); // تشغيل الرادار

    _fetchInitialPosts();
    // ... باقي الكود
    // مراقبة النزول لآخر الشاشة عشان نجيب بوستات جديدة
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchMorePosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // تحميل أول مجموعة من البوستات
  Future<void> _fetchInitialPosts() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(_documentLimit)
          .get();

      setState(() {
        _posts = snapshot.docs;
        _isLoading = false;
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        if (snapshot.docs.length < _documentLimit) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // يفضل هنا طباعة الخطأ أو إظهار توست
    }
  }

  // تحميل المجموعة اللي بعدها لما تنزل لتحت
  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_documentLimit)
          .get();

      setState(() {
        _posts.addAll(snapshot.docs);
        _isLoadingMore = false;
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        if (snapshot.docs.length < _documentLimit) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  // ميزة سحب الشاشة للتحديث
  Future<void> _onRefresh() async {
    setState(() {
      _hasMore = true;
      _lastDocument = null;
      _posts.clear();
    });
    await _fetchInitialPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: GlassTheme.backgroundDark.withValues(alpha: 0.9),
        elevation: 0,
        title: const Text(
          'Wateny',
          style: TextStyle(
            color: GlassTheme.primaryAccent,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: GlassTheme.primaryAccent,
        backgroundColor: GlassTheme.backgroundDark,
        onRefresh: _onRefresh,
        child: _isLoading && _posts.isEmpty
            ? const Center(
                child:
                    CircularProgressIndicator(color: GlassTheme.primaryAccent))
            : _posts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          'No posts yet.\nBe the first to share something!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: GlassTheme.textSecondary, fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics:
                        const AlwaysScrollableScrollPhysics(), // عشان الـ Refresh يشتغل دايماً
                    itemCount: _posts.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: GlassTheme.primaryAccent)),
                        );
                      }

                      final postData =
                          _posts[index].data() as Map<String, dynamic>;
                      final postId = _posts[index].id;

                      return PostCard(post: postData, postId: postId);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: GlassTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()))
              .then((value) =>
                  _onRefresh()); // يعمل تحديث تلقائي لما ترجع من إضافة بوست
        },
      ),
    );
  }
}
