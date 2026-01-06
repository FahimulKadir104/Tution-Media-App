import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../providers/refresh_provider.dart';
import '../services/api_service.dart';
import '../models/tuition_post.dart';
import '../models/conversation.dart';
import 'student_profile_screen.dart';
import 'teacher_profile_screen.dart';
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import 'post_details_screen.dart';
import 'conversations_screen.dart';
import 'login_screen.dart';
import 'student_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<TuitionPost> _posts = [];
  List<TuitionPost> _respondedPosts = [];
  List<TuitionPost> _filteredPosts = [];
  List<TuitionPost> _filteredRespondedPosts = [];
  bool _isLoading = true;
  late TabController _tabController;
  final _searchController = TextEditingController();
  RefreshProvider? _refreshProvider;
  bool _isSearchVisible = false;
  Future<String?>? _displayNameFuture;
  
  // Filter and sort options
  String _statusFilter = 'ALL';
  String _sortOption = 'date';
  double _minPrice = 0;
  double _maxPrice = 50000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_filterPosts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshProvider = context.read<RefreshProvider>();
      _refreshProvider!.addListener(_loadPosts);
      _displayNameFuture = _loadDisplayName();
    });
    _loadPosts();
  }

  @override
  void dispose() {
    _refreshProvider?.removeListener(_loadPosts);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    
    List<TuitionPost> filterAndSort(List<TuitionPost> source) {
      var filtered = source.where((post) {
        // Text search
        final matchesSearch = query.isEmpty ||
            (post.subject?.toLowerCase().contains(query) ?? false) ||
            (post.description?.toLowerCase().contains(query) ?? false) ||
            (post.classLevel?.toLowerCase().contains(query) ?? false) ||
            (post.location?.toLowerCase().contains(query) ?? false);
        
        // Status filter
        final matchesStatus = _statusFilter == 'ALL' || post.status == _statusFilter;
        
        // Price filter
        final postSalary = post.salary ?? 0;
        final matchesPrice = postSalary >= _minPrice && postSalary <= _maxPrice;
        
        return matchesSearch && matchesStatus && matchesPrice;
      }).toList();
      
      // Apply sorting
      switch (_sortOption) {
        case 'price_low':
          filtered.sort((a, b) => (a.salary ?? 0).compareTo(b.salary ?? 0));
          break;
        case 'price_high':
          filtered.sort((a, b) => (b.salary ?? 0).compareTo(a.salary ?? 0));
          break;
        case 'location':
          filtered.sort((a, b) => (a.location ?? '').compareTo(b.location ?? ''));
          break;
        case 'date':
        default:
          // Already in reverse chronological order
          break;
      }
      
      return filtered;
    }
    
    setState(() {
      _filteredPosts = filterAndSort(_posts);
      _filteredRespondedPosts = filterAndSort(_respondedPosts);
    });
  }

  Future<int> _getUnreadMessageCount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || auth.token == null) return 0;

    try {
      final conversationsData = await ApiService.getConversations(auth.token!);
      final conversations = conversationsData
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList();
      return conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || auth.token == null) return;

    setState(() => _isLoading = true);

    try {
      final postsData = await ApiService.getPosts(auth.token!);
      final allPosts = postsData
          .map((p) => TuitionPost.fromJson(p as Map<String, dynamic>))
          .toList();

      List<TuitionPost> responded = [];
      final isTeacher = auth.user!.role == 'TEACHER';
      if (isTeacher) {
        final respondedData = await ApiService.getRespondedPosts(auth.token!);
        responded = respondedData
            .map((p) => TuitionPost.fromJson(p as Map<String, dynamic>))
            .toList();
      }

        final respondedIds = responded.map((p) => p.id).toSet();
        final openPosts = isTeacher
          ? allPosts.where((p) => !respondedIds.contains(p.id)).toList()
          : allPosts;

      final query = _searchController.text.toLowerCase();
      List<TuitionPost> filterList(List<TuitionPost> source) => source
          .where((post) =>
              (post.subject?.toLowerCase().contains(query) ?? false) ||
              (post.description?.toLowerCase().contains(query) ?? false) ||
              (post.classLevel?.toLowerCase().contains(query) ?? false))
          .toList();

      setState(() {
        _posts = openPosts;
        _respondedPosts = responded;
        _filteredPosts = filterList(openPosts);
        _filteredRespondedPosts = filterList(responded);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to load posts')));
      }
    }
  }

  Future<String?> _loadDisplayName() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || auth.token == null) return null;

    try {
        final profileData = auth.user!.role == 'STUDENT'
          ? await ApiService.getStudentProfile(auth.token!)
          : await ApiService.getTeacherProfile(auth.token!);

      final profileJson = (profileData['profile'] ?? profileData) as Map<String, dynamic>;
      return (profileJson['full_name'] as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // If user is missing (e.g., after logout or session expiry), redirect to login safely.
    if (auth.user == null) {
      Future.microtask(() {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isStudent = auth.user!.role == 'STUDENT';
    final isTeacher = auth.user!.role == 'TEACHER';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        leading: _isSearchVisible
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = false;
                    _searchController.clear();
                    _filterPosts();
                  });
                },
              )
            : null,
        automaticallyImplyLeading: !_isSearchVisible,
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                decoration: InputDecoration(
                  hintText: 'Search posts...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                ),
              )
            : const Text('Dashboard'),
        actions: _isSearchVisible
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearchVisible = true;
                    });
                  },
                ),
                FutureBuilder<int>(
                  future: _getUnreadMessageCount(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            if (auth.user != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ConversationsScreen(),
                                ),
                              ).then((_) => _loadPosts());
                            }
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
        bottom: isTeacher
            ? TabBar(
                controller: _tabController,
                labelStyle: const TextStyle(fontSize: 16 ),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
                unselectedLabelColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                tabs: const [
                  Tab(text: 'Open Posts'),
                  Tab(text: 'Responded Posts'),
                ],
              )
            : null,
      ),
      drawer: _buildDrawer(context, auth),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 1200 : 700),
          child: Column(
            children: [
              // Filter and Sort Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  children: [
                    // Status Filter
                    if (isStudent)
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.filter_list,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'OPEN', child: Text('Open', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'CLOSED', child: Text('Closed', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (value) {
                            setState(() => _statusFilter = value!);
                            _filterPosts();
                          },
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Sort Options
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _sortOption,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Sort',
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.sort,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'date', child: Text('Latest', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'price_low', child: Text('Price: Low', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'price_high', child: Text('Price: High', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (value) {
                          setState(() => _sortOption = value!);
                          _filterPosts();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price Filter Button
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Price Filter',
                        onPressed: () => _showPriceFilterDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isTeacher
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPostsList(_filteredPosts, isStudent: isStudent),
                              _buildPostsList(_filteredRespondedPosts, isStudent: isStudent),
                            ],
                          )
                        : _buildPostsList(_filteredPosts, isStudent: isStudent),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              onPressed: () {
                if (auth.user != null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreatePostScreen())).then((_) => _loadPosts());
                }
              },
              icon: const Icon(Icons.add, size: 28),
              label: const Text(
                'New Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 6,
            )
          : null,
    );
  }

  Widget _buildPostsList(List<TuitionPost> posts, {required bool isStudent}) {
    final auth = Provider.of<AuthProvider>(context);
    final isTeacher = auth.user!.role == 'TEACHER';
    return posts.isEmpty
        ? RefreshIndicator(
            onRefresh: _loadPosts,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 20),
                      Text(
                        isStudent
                            ? 'No posts yet. Create your first tuition post!'
                            : 'No posts available.',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadPosts,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 4,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    title: Text(post.subject ?? 'No subject',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(post.description ?? '', style: const TextStyle(fontSize: 16)),
                        if (post.responseCount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${post.responseCount} ${post.responseCount == 1 ? 'teacher responded' : 'teachers responded'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (isTeacher) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentDetailsScreen(
                                  studentId: post.studentId,
                                  studentName: post.studentName,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_pin_circle_outlined, size: 18),
                                const SizedBox(width: 6),
                                Text(post.studentName ?? post.studentEmail ?? 'Student',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (isStudent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: post.status == 'OPEN' 
                                    ? Colors.green.withOpacity(0.15) 
                                    : Colors.orange.withOpacity(0.15),
                                  border: Border.all(
                                    color: post.status == 'OPEN' 
                                      ? Colors.green.withOpacity(0.5) 
                                      : Colors.orange.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      post.status == 'OPEN' 
                                        ? Icons.check_circle 
                                        : Icons.cancel,
                                      size: 14,
                                      color: post.status == 'OPEN' 
                                        ? Colors.green 
                                        : Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      post.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: post.status == 'OPEN' 
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                post.classLevel ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${post.salary?.toStringAsFixed(0) ?? 0} BDT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.location ?? 'No Location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isStudent
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deletePost(post.id);
                              } else if (value == 'toggle') {
                                _togglePostStatus(post.id, post.status);
                              } else if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditPostScreen(post: post),
                                  ),
                                ).then((updated) {
                                  if (updated == true) _loadPosts();
                                });
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      post.status == 'OPEN' 
                                        ? Icons.cancel 
                                        : Icons.check_circle,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(post.status == 'OPEN' ? 'Close Post' : 'Open Post'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit Post'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : FilledButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PostDetailsScreen(post: post)));
                            },
                            child: const Text('View', style: TextStyle(fontSize: 16)),
                          ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PostDetailsScreen(post: post)));
                    },
                  ),
                    ),
                  ),              );
              },
            ),
          );
  }

  Future<void> _deletePost(int postId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || auth.token == null) return;

    try {
      await ApiService.deletePost(auth.token!, postId);
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to delete post')));
      }
    }
  }

  Future<void> _togglePostStatus(int postId, String currentStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || auth.token == null) return;

    final newStatus = currentStatus == 'OPEN' ? 'CLOSED' : 'OPEN';

    try {
      await ApiService.updatePostStatus(auth.token!, postId, newStatus);
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post ${newStatus.toLowerCase()} successfully'),
            backgroundColor: newStatus == 'OPEN' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update post status')),
        );
      }
    }
  }

  void _showPriceFilterDialog(BuildContext context) {
    double tempMin = _minPrice;
    double tempMax = _maxPrice;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter by Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Range: ${tempMin.toInt()} - ${tempMax.toInt()} BDT'),
              const SizedBox(height: 16),
              RangeSlider(
                values: RangeValues(tempMin, tempMax),
                min: 0,
                max: 50000,
                divisions: 100,
                labels: RangeLabels(
                  tempMin.toInt().toString(),
                  tempMax.toInt().toString(),
                ),
                onChanged: (values) {
                  setDialogState(() {
                    tempMin = values.start;
                    tempMax = values.end;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _minPrice = tempMin;
                  _maxPrice = tempMax;
                });
                _filterPosts();
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final colorScheme = Theme.of(context).colorScheme;
    final isStudent = auth.user!.role == 'STUDENT';
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            currentAccountPicture: FutureBuilder<String?>(
              future: ApiService.getProfilePicture(auth.user!.id),
              builder: (context, snapshot) {
                final profilePictureUrl = snapshot.data;
                return CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                      ? NetworkImage(profilePictureUrl)
                      : null,
                  child: profilePictureUrl == null || profilePictureUrl.isEmpty
                      ? Icon(
                          isStudent ? Icons.school : Icons.person,
                          size: 40,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                );
              },
            ),
            accountName: FutureBuilder<String?>(
              future: _displayNameFuture,
              builder: (context, snapshot) {
                final displayName = snapshot.data;
                return Text(
                  (displayName == null || displayName.isEmpty)
                      ? (auth.user?.email ?? '')
                      : displayName,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            accountEmail: Text(
              auth.user?.email ?? '',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          FutureBuilder<int>(
            future: _getUnreadMessageCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Messages'),
                trailing: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConversationsScreen(),
                    ),
                  ).then((_) => _loadPosts());
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile Settings'),
            onTap: () {
              Navigator.pop(context);
              if (isStudent) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentProfileScreen(),
                  ),
                ).then((_) => _loadPosts());
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherProfileScreen(),
                  ),
                ).then((_) => _loadPosts());
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support - Coming Soon'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Tuition Media',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.school, size: 48),
                children: [
                  const Text(
                    'Connect students with qualified teachers for personalized tutoring.',
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}