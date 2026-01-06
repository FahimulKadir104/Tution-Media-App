import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/refresh_provider.dart';
import '../models/tuition_post.dart';
import '../models/response.dart';
import '../models/conversation.dart';
import 'chat_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final TuitionPost post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  PostDetailsScreenState createState() => PostDetailsScreenState();
}

class PostDetailsScreenState extends State<PostDetailsScreen> {
  List<Response> _responses = [];
  bool _isLoading = true;
  bool _hasResponded = false;
  final _proposedSalaryController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user!.role == 'TEACHER') {
      try {
        final hasRespondedData = await ApiService.hasResponded(auth.token!, widget.post.id);
        if (mounted) setState(() => _hasResponded = hasRespondedData['hasResponded'] ?? false);
      } catch (e) { /* ignore */ }
    }
    await _loadResponses();
  }

  Future<void> _loadResponses() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = widget.post.studentId == auth.user!.id;
    if (isOwner) {
      try {
        final responsesData = await ApiService.getResponses(auth.token!, widget.post.id);
        if (mounted) {
          setState(() {
            _responses = responsesData.map((r) => Response.fromJson(r as Map<String, dynamic>)).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respond() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final responseData = {
      'proposed_salary': double.tryParse(_proposedSalaryController.text),
      'message': _messageController.text,
    };
    try {
      await ApiService.respondToPost(auth.token!, widget.post.id, responseData);
      final convo = await _ensureConversation();
      Provider.of<RefreshProvider>(context, listen: false).notifyRefresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application sent successfully'), behavior: SnackBarBehavior.floating),
      );
      if (convo != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send response'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = Provider.of<AuthProvider>(context);
    final isTeacher = auth.user!.role == 'TEACHER';
    final isOwner = widget.post.studentId == auth.user!.id;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back Button
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Header Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.post.subject ?? 'Details',
                                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Posted on ${widget.post.location ?? "Remote"}',
                                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.post.salary} BDT',
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Info Grid
                          _buildSectionHeader(context, 'Post Highlights'),
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (context, constraints) {
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: constraints.maxWidth > 400 ? 4 : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.5,
                              children: [
                                _buildGridInfo(colorScheme, Icons.calendar_month, '${widget.post.daysPerWeek} Days', 'Schedule'),
                                _buildGridInfo(colorScheme, Icons.school, widget.post.classLevel ?? 'Any', 'Level'),
                                _buildGridInfo(colorScheme, Icons.location_on, widget.post.location ?? 'Remote', 'Area'),
                                _buildGridInfo(colorScheme, Icons.timer_outlined, 'Recently', 'Posted'),
                              ],
                            );
                          }),
                          const SizedBox(height: 32),

                          _buildSectionHeader(context, 'Requirement Details'),
                          const SizedBox(height: 12),
                          Text(
                            widget.post.description ?? 'No description provided.',
                            style: textTheme.bodyLarge?.copyWith(height: 1.6, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 48),

                          // Dynamic Role Content
                          if (isTeacher)
                            _hasResponded 
                                ? _buildAppliedState(colorScheme) 
                                : _buildApplicationForm(colorScheme, textTheme),

                          if (isOwner && _responses.isNotEmpty)
                            _buildResponsesSection(colorScheme, textTheme),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildGridInfo(ColorScheme colorScheme, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(fontSize: 10, color: colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildApplicationForm(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Interested in this post?'),
        const SizedBox(height: 16),
        TextField(
          controller: _proposedSalaryController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Proposed Salary', Icons.attach_money),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: _inputDecoration('Short message to student...', Icons.chat_bubble_outline),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _respond,
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Send Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  Widget _buildResponsesSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Applied Tutors'),
        const SizedBox(height: 16),
        ..._responses.map((res) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: (res.profilePictureUrl != null && res.profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(res.profilePictureUrl!)
                      : null,
                  child: (res.profilePictureUrl == null || res.profilePictureUrl!.isEmpty)
                      ? Text(
                          (res.teacherName ?? res.teacherEmail ?? 'T')[0].toUpperCase(),
                          style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.teacherName ?? res.teacherEmail ?? 'Tutor',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${res.proposedSalary?.toStringAsFixed(0) ?? '-'} BDT',
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(res.message ?? '', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final convo = await _ensureConversation();
                    Provider.of<RefreshProvider>(context, listen: false).notifyRefresh();
                    if (!mounted) return;
                    if (convo != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(conversation: convo),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Chat'),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Future<Conversation?> _ensureConversation() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return null;

    try {
      final startResp = await ApiService.startConversation(auth.token!, widget.post.id);
      final convoId = startResp['conversationId'];

      final conversationsData = await ApiService.getConversations(auth.token!);
      final all = conversationsData
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList();

      Conversation? convo;
      if (convoId != null) {
        for (final c in all) {
          if (c.id == convoId) {
            convo = c;
            break;
          }
        }
      }
      if (convo == null) {
        for (final c in all) {
          if (c.postId == widget.post.id) {
            convo = c;
            break;
          }
        }
      }

      return convo;
    } catch (_) {
      return null;
    }
  }

  Widget _buildAppliedState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 48),
          const SizedBox(height: 12),
          const Text('Application Sent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('The student will be notified of your interest.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}