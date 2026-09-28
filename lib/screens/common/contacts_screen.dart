import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/conversation_model.dart';
import 'chat_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _isFarmer => _authService.userModel?.role == 'farmer';
  bool get _isAdmin => _authService.userModel?.role == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Contacts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: _isFarmer
                        ? 'Search your followers...'
                        : 'Search farmers...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              // Tabs
              if (_isFarmer)
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Followers'),
                    Tab(text: 'All Customers'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _isFarmer
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildFollowersList(),
                  _buildAllCustomersList(),
                ],
              )
            : _isAdmin
                ? _buildAllUsersListForAdmin()
                : _buildAllFarmersList(),
      ),
    );
  }

  // For farmers - show their followers
  Widget _buildFollowersList() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return _buildEmptyState('No followers yet');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final followerIds = List<String>.from(data['followers'] ?? []);

        if (followerIds.isEmpty) {
          return _buildEmptyState('No followers yet');
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getUsers(followerIds),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            if (!usersSnapshot.hasData || usersSnapshot.data!.isEmpty) {
              return _buildEmptyState('No followers found');
            }

            final followers = usersSnapshot.data!
                .where((user) =>
                    _searchQuery.isEmpty ||
                    (user['fullName'] as String? ?? '')
                        .toLowerCase()
                        .contains(_searchQuery))
                .toList();

            if (followers.isEmpty) {
              return _buildEmptyState('No matching followers');
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: followers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final follower = followers[index];
                return _buildContactCard(
                  userId: follower['id'] as String,
                  name: follower['fullName'] as String? ?? 'Unknown',
                  avatar: follower['profilePicture'] as String? ?? '',
                  subtitle: follower['email'] as String? ?? '',
                  role: UserRole.customer,
                );
              },
            );
          },
        );
      },
    );
  }

  // For farmers - show all customers
  Widget _buildAllCustomersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No customers found');
        }

        final customers = snapshot.data!.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['fullName'] as String? ?? '').toLowerCase();
              return _searchQuery.isEmpty || name.contains(_searchQuery);
            })
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        if (customers.isEmpty) {
          return _buildEmptyState('No matching customers');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _buildContactCard(
              userId: customer['id'] as String,
              name: customer['fullName'] as String? ?? 'Unknown',
              avatar: customer['profilePicture'] as String? ?? '',
              subtitle: customer['email'] as String? ?? '',
              role: UserRole.customer,
            );
          },
        );
      },
    );
  }

  // For customers - show all farmers
  Widget _buildAllFarmersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('farmers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No farmers found');
        }

        final farmers = snapshot.data!.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] as String? ?? '').toLowerCase();
              final farmName = (data['farmName'] as String? ?? '').toLowerCase();
              return _searchQuery.isEmpty ||
                  name.contains(_searchQuery) ||
                  farmName.contains(_searchQuery);
            })
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        if (farmers.isEmpty) {
          return _buildEmptyState('No matching farmers');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: farmers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final farmer = farmers[index];
            final rating = (farmer['rating'] as num?)?.toDouble() ?? 0.0;
            return _buildContactCard(
              userId: farmer['id'] as String,
              name: farmer['name'] as String? ?? 'Unknown',
              avatar: farmer['avatarUrl'] as String? ?? '',
              subtitle:
                  '${farmer['farmName'] ?? ''} ${rating > 0 ? '• Rating: ${rating.toStringAsFixed(1)}' : ''}',
              role: UserRole.farmer,
            );
          },
        );
      },
    );
  }

  // For admin - show all users
  Widget _buildAllUsersListForAdmin() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Customers'),
              Tab(text: 'Farmers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAllCustomersList(),
                _buildAllFarmersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String userId,
    required String name,
    required String avatar,
    required String subtitle,
    required UserRole role,
  }) {
    final currentUserId = _authService.currentUser?.uid;
    if (userId == currentUserId) return const SizedBox.shrink();

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startConversation(userId, name, avatar, role),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role == UserRole.farmer)
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startConversation(
    String userId,
    String name,
    String avatar,
    UserRole role,
  ) async {
    try {
      final conversationId = await _chatService.createConversation(
        otherUserId: userId,
        otherUserName: name,
        otherUserAvatar: avatar,
        otherUserRole: role,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conversationId,
              otherUserName: name,
              otherUserAvatar: avatar,
              otherUserId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getUsers(List<String> userIds) async {
    final List<Map<String, dynamic>> users = [];
    
    for (final userId in userIds) {
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          users.add({'id': userId, ...userDoc.data() as Map<String, dynamic>});
        }
      } catch (e) {
        debugPrint('Error fetching user $userId: $e');
      }
    }
    
    return users;
  }
}
