import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
import 'models/checklist_item.dart';
import 'models/hike.dart';
import 'models/hike_day.dart';
import 'models/join_request.dart';
import 'models/message.dart';
import 'models/profile_ref.dart';
import 'models/review.dart';

/// User-facing error for join flows; its message is safe to show directly.
class JoinException implements Exception {
  JoinException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads hikes from Supabase. When no client is configured (UI preview / tests)
/// it serves the sample set below, which mirrors the Figma copy.
class HikesRepository {
  HikesRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  String? get currentUserId => _client?.auth.currentUser?.id;

  String get currentUserName {
    final u = _client?.auth.currentUser;
    final meta = u?.userMetadata;
    return (meta?['display_name'] as String?)?.trim().isNotEmpty == true
        ? meta!['display_name'] as String
        : 'Хтось';
  }

  static const _organizerSelect =
      'organizer:profiles!hikes_organizer_id_fkey(id, display_name, avatar_url)';

  /// The "Зараз збираються" feed on Home — open hikes, soonest first.
  Future<List<Hike>> fetchGathering() async {
    if (_client == null) return _sample;
    final rows = await _client
        .from('hikes')
        .select('*, $_organizerSelect')
        .neq('status', 'draft')
        .eq('is_hidden', false)
        .order('start_date', ascending: true)
        .limit(20);
    return rows.map((r) => Hike.fromMap(r)).toList();
  }

  /// Search / browse with optional type filter and text query, paginated.
  Future<List<Hike>> search({
    HikeType? type,
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    if (_client == null) {
      final q = (query ?? '').trim().toLowerCase();
      return _sample.where((h) {
        final okType = type == null || h.type == type;
        final okText = q.isEmpty ||
            h.title.toLowerCase().contains(q) ||
            (h.region ?? '').toLowerCase().contains(q);
        return okType && okText;
      }).toList();
    }
    var req = _client
        .from('hikes')
        .select('*, $_organizerSelect')
        .neq('status', 'draft')
        .eq('is_hidden', false);
    if (type != null) req = req.eq('type', type.name);
    final q = (query ?? '').trim();
    if (q.isNotEmpty) {
      req = req.or('title.ilike.%$q%,region.ilike.%$q%,location.ilike.%$q%');
    }
    final rows = await req
        .order('start_date', ascending: true)
        .range(offset, offset + limit - 1);
    return rows.map((r) => Hike.fromMap(r)).toList();
  }

  Future<Hike> fetchById(String id) async {
    if (_client == null) {
      return _sample.firstWhere((h) => h.id == id, orElse: () => _sample.first);
    }
    final row = await _client
        .from('hikes')
        .select('*, $_organizerSelect')
        .eq('id', id)
        .single();
    return Hike.fromMap(row);
  }

  /// Creates a hike organized by the current user. The DB trigger auto-adds
  /// the organizer as an approved participant. Returns the new hike id.
  Future<String> createHike({
    required HikeType type,
    required String title,
    String? summary,
    String? description,
    String? region,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    HikeDifficulty difficulty = HikeDifficulty.moderate,
    int durationDays = 1,
    int maxParticipants = 8,
    int priceCents = 0,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      throw StateError('Треба увійти, щоб створити похід.');
    }
    String? d(DateTime? x) => x?.toIso8601String().split('T').first;
    final row = await client
        .from('hikes')
        .insert({
          'organizer_id': uid,
          'type': type.name,
          'title': title,
          'summary': summary,
          'description': description,
          'region': region,
          'location': location,
          'start_date': d(startDate),
          'end_date': d(endDate),
          'difficulty': difficulty.name,
          'duration_days': durationDays,
          'max_participants': maxParticipants,
          'price_cents': type == HikeType.shared ? 0 : priceCents,
          'status': 'open',
        })
        .select('id')
        .single();
    AppLog.I.info('hikes', 'createHike', {'title': title, 'type': type.name});
    return row['id'] as String;
  }

  /// Pending join requests across all hikes the current user organizes.
  Future<List<JoinRequest>> fetchIncomingRequests() async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return const [];
    final hikes =
        await client.from('hikes').select('id, title').eq('organizer_id', uid);
    if (hikes.isEmpty) return const [];
    final titles = {for (final h in hikes) h['id'] as String: h['title'] as String};
    final rows = await client
        .from('hike_participants')
        .select(
            '*, applicant:profiles!hike_participants_user_id_fkey(id, display_name, avatar_url)')
        .inFilter('hike_id', titles.keys.toList())
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return rows.map((r) {
      final a = r['applicant'];
      return JoinRequest(
        id: r['id'] as String,
        hikeId: r['hike_id'] as String,
        hikeTitle: titles[r['hike_id']] ?? '',
        applicant: a is Map<String, dynamic>
            ? ProfileRef.fromMap(a)
            : const ProfileRef(id: '', displayName: ''),
        status: r['status'] as String,
      );
    }).toList();
  }

  /// Organizer approves/rejects a request and notifies the applicant.
  Future<void> respondToRequest({
    required JoinRequest request,
    required bool approve,
  }) async {
    final client = _client;
    if (client == null) return;
    final status = approve ? 'approved' : 'rejected';
    await client
        .from('hike_participants')
        .update({'status': status}).eq('id', request.id);
    AppLog.I.info('hikes', 'respondToRequest',
        {'requestId': request.id, 'status': status});
    try {
      await client.functions.invoke('notify', body: {
        'userIds': [request.applicant.id],
        'title': approve ? 'Тебе взяли в похід 🎉' : 'Відповідь на заявку',
        'message': approve
            ? 'Організатор підтвердив участь у «${request.hikeTitle}»'
            : 'На жаль, у «${request.hikeTitle}» цього разу не вийшло.',
        'email': true,
        'data': {'hikeId': request.hikeId},
      });
    } catch (e, s) {
      AppLog.I.error('hikes', 'notify applicant failed', error: e, stackTrace: s);
    }
  }

  /// Sends a join request for the current user (status: pending) and pings the
  /// organizer through the `notify` edge function (OneSignal push + email).
  Future<void> requestToJoin(String hikeId) async {
    final client = _client;
    if (client == null) return; // preview / offline no-op
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Треба увійти, щоб приєднатися до походу.');
    }
    AppLog.I.info('hikes', 'requestToJoin', {'hikeId': hikeId});

    // Already have a participation row? Give a friendly message, don't re-insert.
    final existing = await client
        .from('hike_participants')
        .select('status')
        .eq('hike_id', hikeId)
        .eq('user_id', uid)
        .maybeSingle();
    if (existing != null) {
      final status = existing['status'] as String?;
      throw JoinException(switch (status) {
        'approved' => 'Ти вже учасник цього походу.',
        'rejected' => 'На жаль, у цей похід тебе не взяли.',
        _ => 'Заявку вже надіслано — очікуй підтвердження організатора.',
      });
    }

    try {
      await client.from('hike_participants').insert({
        'hike_id': hikeId,
        'user_id': uid,
        'role': 'member',
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      // 23505 = unique violation (race: requested twice quickly).
      if (e.code == '23505') {
        throw JoinException(
            'Заявку вже надіслано — очікуй підтвердження організатора.');
      }
      rethrow;
    }

    // Notify the organizer. A failure here must not fail the join itself.
    try {
      final hike = await client
          .from('hikes')
          .select('title, organizer_id')
          .eq('id', hikeId)
          .single();
      final me = await client
          .from('profiles')
          .select('display_name')
          .eq('id', uid)
          .single();
      await client.functions.invoke('notify', body: {
        'userIds': [hike['organizer_id']],
        'title': 'Нова заявка на похід',
        'message':
            '${me['display_name']} хоче приєднатися до «${hike['title']}»',
        'email': true,
        'data': {'hikeId': hikeId},
      });
    } catch (e, s) {
      // Best-effort — log but don't fail the join.
      AppLog.I.warn('hikes', 'organizer notify failed', {'error': e.toString()});
      AppLog.I.error('hikes', 'notify error', error: e, stackTrace: s);
    }
  }

  /// Day-by-day itinerary for a hike.
  Future<List<HikeDay>> fetchItinerary(String hikeId) async {
    if (_client == null) return _sampleItinerary[hikeId] ?? const [];
    final rows = await _client
        .from('hike_itinerary')
        .select()
        .eq('hike_id', hikeId)
        .order('day_num', ascending: true);
    return rows.map((r) => HikeDay.fromMap(r)).toList();
  }

  // --- favorites -------------------------------------------------------------
  final Set<String> _localFavorites = {};

  Future<Set<String>> favoriteHikeIds() async {
    final client = _client;
    if (client == null) return _localFavorites;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return {};
    final rows =
        await client.from('favorites').select('hike_id').eq('user_id', uid);
    return rows.map((r) => r['hike_id'] as String).toSet();
  }

  Future<List<Hike>> fetchFavoriteHikes() async {
    final client = _client;
    if (client == null) {
      return _sample.where((h) => _localFavorites.contains(h.id)).toList();
    }
    final uid = client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await client
        .from('favorites')
        .select('hike:hikes(*, $_organizerSelect)')
        .eq('user_id', uid);
    return rows
        .map((r) => r['hike'])
        .whereType<Map<String, dynamic>>()
        .map(Hike.fromMap)
        .toList();
  }

  Future<bool> toggleFavorite(String hikeId) async {
    final client = _client;
    if (client == null) {
      _localFavorites.contains(hikeId)
          ? _localFavorites.remove(hikeId)
          : _localFavorites.add(hikeId);
      return _localFavorites.contains(hikeId);
    }
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Треба увійти.');
    final existing = await client
        .from('favorites')
        .select('hike_id')
        .eq('user_id', uid)
        .eq('hike_id', hikeId)
        .maybeSingle();
    if (existing == null) {
      await client.from('favorites').insert({'user_id': uid, 'hike_id': hikeId});
      return true;
    }
    await client
        .from('favorites')
        .delete()
        .eq('user_id', uid)
        .eq('hike_id', hikeId);
    return false;
  }

  // --- messages --------------------------------------------------------------
  /// Hikes the current user is an approved member of — the conversation list.
  Future<List<Hike>> fetchMemberHikes() async {
    final client = _client;
    if (client == null) return _sample.take(2).toList();
    final uid = client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await client
        .from('hike_participants')
        .select('hike:hikes(*, $_organizerSelect)')
        .eq('user_id', uid)
        .eq('status', 'approved');
    return rows
        .map((r) => r['hike'])
        .whereType<Map<String, dynamic>>()
        .map(Hike.fromMap)
        .toList();
  }

  Future<List<Message>> fetchMessages(String hikeId) async {
    final client = _client;
    if (client == null) return _sampleMessages;
    final rows = await client
        .from('messages')
        .select(
            '*, sender:profiles!messages_sender_id_fkey(id, display_name, avatar_url)')
        .eq('hike_id', hikeId)
        .order('created_at', ascending: true);
    return rows.map((r) => Message.fromMap(r)).toList();
  }

  Future<void> sendMessage(String hikeId, String body) async {
    final client = _client;
    if (client == null) return;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Треба увійти.');
    await client
        .from('messages')
        .insert({'hike_id': hikeId, 'sender_id': uid, 'body': body});
  }

  /// Uploads a chat attachment to the `chat` bucket and returns its public URL.
  /// Path: {hikeId}/{uid}/{ts}_{filename}
  Future<String> uploadChatAttachment(
    String hikeId,
    Uint8List bytes,
    String filename, {
    String? contentType,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) throw StateError('Треба увійти.');
    final safe = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$hikeId/$uid/${ts}_$safe';
    await client.storage.from('chat').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
              contentType: contentType, upsert: false),
        );
    return client.storage.from('chat').getPublicUrl(path);
  }

  /// Sends an image or file message (attachment already uploaded).
  Future<void> sendAttachmentMessage(
    String hikeId, {
    required String kind, // 'image' | 'file'
    required String attachmentUrl,
    required String attachmentName,
    String body = '',
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) throw StateError('Треба увійти.');
    await client.from('messages').insert({
      'hike_id': hikeId,
      'sender_id': uid,
      'kind': kind,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'body': body,
    });
  }

  /// Shares a contact card (name + phone/handle) into the chat.
  Future<void> sendContactMessage(
    String hikeId, {
    required String name,
    required String handle,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) throw StateError('Треба увійти.');
    await client.from('messages').insert({
      'hike_id': hikeId,
      'sender_id': uid,
      'kind': 'contact',
      'body': '',
      'meta': {'name': name, 'handle': handle},
    });
  }

  /// Broadcasts a lightweight "typing" ping on the hike channel.
  void broadcastTyping(RealtimeChannel channel) {
    channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'uid': currentUserId, 'name': currentUserName},
    );
  }

  /// Subscribes to new messages for a hike via Supabase Realtime. [onChange]
  /// fires on every insert; returns null when Supabase isn't configured.
  RealtimeChannel? subscribeToMessages(
    String hikeId,
    void Function() onChange, {
    void Function(String name)? onTyping,
  }) {
    final client = _client;
    if (client == null) return null;
    final myId = currentUserId;
    var channel = client.channel('public:messages:$hikeId').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'hike_id',
            value: hikeId,
          ),
          callback: (_) => onChange(),
        );
    if (onTyping != null) {
      channel = channel.onBroadcast(
        event: 'typing',
        callback: (payload) {
          if (payload['uid'] == myId) return; // ignore self
          onTyping((payload['name'] as String?) ?? 'Хтось');
        },
      );
    }
    return channel.subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client?.removeChannel(channel);
  }

  static final Map<String, List<HikeDay>> _sampleItinerary = {
    'sample-borzhava': const [
      HikeDay(dayNum: 1, title: 'Підйом на полонину', description: 'Старт зі Львова, підхід і табір.'),
      HikeDay(dayNum: 2, title: 'Хребет Боржави', description: 'Світанок на хребті, спуск, повернення.'),
    ],
  };

  static final List<Message> _sampleMessages = [
    Message(
      id: 'm1',
      hikeId: 'sample-borzhava',
      senderId: 's1',
      body: 'Всім привіт! Виїзд нічним потягом, збір на вокзалі о 21:30.',
      createdAt: DateTime(2026, 8, 12, 18, 30),
      sender: const ProfileRef(id: 's1', displayName: 'Олег Сокіл'),
    ),
    Message(
      id: 'm2',
      hikeId: 'sample-borzhava',
      senderId: 's2',
      body: 'Супер, буду. Палиці можу позичити ще одному.',
      createdAt: DateTime(2026, 8, 12, 19, 5),
      sender: const ProfileRef(id: 's2', displayName: 'Марта Лісова'),
    ),
  ];

  // --- reviews ---------------------------------------------------------------
  Future<List<Review>> fetchReviews(String subjectId) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('reviews')
        .select(
            '*, author:profiles!reviews_author_id_fkey(id, display_name, avatar_url)')
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);
    return rows.map((r) => Review.fromMap(r)).toList();
  }

  Future<void> addReview({
    required String subjectId,
    String? hikeId,
    required int rating,
    String? body,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) throw StateError('Треба увійти.');
    await client.from('reviews').upsert({
      'subject_id': subjectId,
      'author_id': uid,
      'hike_id': hikeId,
      'rating': rating,
      'body': body,
    }, onConflict: 'author_id,subject_id,hike_id');
    AppLog.I.info('reviews', 'addReview', {'subjectId': subjectId, 'rating': rating});
  }

  /// Aggregate rating for a person: average stars + how many reviews.
  Future<({double average, int count})> fetchUserRating(String userId) async {
    final client = _client;
    if (client == null) return (average: 0.0, count: 0);
    final rows = await client
        .from('reviews')
        .select('rating')
        .eq('subject_id', userId);
    if (rows.isEmpty) return (average: 0.0, count: 0);
    final sum = rows.fold<int>(0, (a, r) => a + (r['rating'] as int? ?? 0));
    return (average: sum / rows.length, count: rows.length);
  }

  /// Approved participants of a hike (who's going), including the organizer's
  /// members. Newest-approved first is not important here — order by join time.
  Future<List<ProfileRef>> fetchApprovedParticipants(String hikeId) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('hike_participants')
        .select(
            'member:profiles!hike_participants_user_id_fkey(id, display_name, avatar_url)')
        .eq('hike_id', hikeId)
        .eq('status', 'approved')
        .order('created_at', ascending: true);
    return rows
        .map((r) => r['member'])
        .whereType<Map<String, dynamic>>()
        .map(ProfileRef.fromMap)
        .toList();
  }

  /// Public profile of any user (id, name, avatar, bio, default role).
  Future<({ProfileRef profile, String? bio, String role})?> fetchProfile(
      String userId) async {
    final client = _client;
    if (client == null) return null;
    final row = await client
        .from('profiles')
        .select('id, display_name, avatar_url, bio, default_role')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return (
      profile: ProfileRef.fromMap(row),
      bio: row['bio'] as String?,
      role: (row['default_role'] as String?) ?? 'campmate',
    );
  }

  /// The current user's participation status for a hike, or null if none.
  /// One of: 'approved', 'pending', 'rejected'.
  Future<String?> fetchMyParticipation(String hikeId) async {
    final client = _client;
    if (client == null) return null;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await client
        .from('hike_participants')
        .select('status')
        .eq('hike_id', hikeId)
        .eq('user_id', uid)
        .maybeSingle();
    return row?['status'] as String?;
  }

  /// Whether the current user may leave a review about [subjectId] for [hikeId]
  /// (approved participant of a hike that has already happened). Mirrors the
  /// server-side RLS so the UI can hide the action instead of failing an insert.
  Future<bool> canReview({
    required String subjectId,
    required String hikeId,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null || uid == subjectId) return false;
    final row = await client
        .from('hike_participants')
        .select('status, hike:hikes(start_date, end_date)')
        .eq('hike_id', hikeId)
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null || row['status'] != 'approved') return false;
    final hike = row['hike'] as Map<String, dynamic>?;
    final ends = (hike?['end_date'] ?? hike?['start_date']) as String?;
    if (ends == null) return false;
    final endDate = DateTime.tryParse(ends);
    if (endDate == null) return false;
    return !endDate.isAfter(DateTime.now());
  }

  /// File a moderation report about a hike, user, or message.
  Future<void> addReport({
    required String targetType, // 'hike' | 'user' | 'message'
    required String targetId,
    String? hikeId,
    required String reason, // spam|scam|unsafe|harassment|other
    String? details,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      throw StateError('Треба увійти, щоб поскаржитися.');
    }
    try {
      await client.from('reports').insert({
        'reporter_id': uid,
        'target_type': targetType,
        'target_id': targetId,
        'hike_id': hikeId,
        'reason': reason,
        'details': details,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw StateError('Ти вже надсилав(-ла) цю скаргу.');
      }
      rethrow;
    }
    AppLog.I.info('reports', 'addReport', {'targetType': targetType, 'reason': reason});
  }

  /// Gear checklist for a hike (current user). Falls back to the sample set.
  Future<List<ChecklistItem>> fetchChecklist(String hikeId) async {
    final client = _client;
    if (client == null) return _sampleChecklist;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return _sampleChecklist;
    final rows = await client
        .from('checklist_items')
        .select()
        .eq('hike_id', hikeId)
        .eq('user_id', uid)
        .order('created_at', ascending: true);
    final items = rows.map((r) => ChecklistItem.fromMap(r)).toList();
    return items.isEmpty ? _sampleChecklist : items;
  }

  Future<void> setChecklistStatus(String itemId, ChecklistStatus status) async {
    final client = _client;
    if (client == null) return;
    await client
        .from('checklist_items')
        .update({'status': status.value}).eq('id', itemId);
  }

  /// The soonest approved hike the current user is part of (for the backpack).
  Future<Hike?> fetchMyCurrentHike() async {
    final client = _client;
    if (client == null) return _sample.first;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await client
        .from('hike_participants')
        .select('hike:hikes(*, $_organizerSelect)')
        .eq('user_id', uid)
        .eq('status', 'approved');
    final hikes = rows
        .map((r) => r['hike'])
        .whereType<Map<String, dynamic>>()
        .map(Hike.fromMap)
        .toList()
      ..sort((a, b) => (a.startDate ?? DateTime(2100))
          .compareTo(b.startDate ?? DateTime(2100)));
    return hikes.isEmpty ? null : hikes.first;
  }

  /// Seeds a default gear checklist for (hike, user) if none exists yet.
  Future<void> ensureChecklist(String hikeId) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    final existing = await client
        .from('checklist_items')
        .select('id')
        .eq('hike_id', hikeId)
        .eq('user_id', uid)
        .limit(1);
    if (existing.isNotEmpty) return;
    await client.from('checklist_items').insert([
      for (final i in _sampleChecklist)
        {
          'hike_id': hikeId,
          'user_id': uid,
          'category': i.category,
          'name': i.name,
          'spec': i.spec,
          'status': ChecklistStatus.todo.value,
        }
    ]);
  }

  Future<void> addChecklistItem({
    required String hikeId,
    required String category,
    required String name,
    String? spec,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    await client.from('checklist_items').insert({
      'hike_id': hikeId,
      'user_id': uid,
      'category': category,
      'name': name,
      'spec': spec,
      'status': ChecklistStatus.todo.value,
    });
  }

  static const List<ChecklistItem> _sampleChecklist = [
    ChecklistItem(
        id: 'c1',
        category: 'Ночівля',
        name: 'Спальник',
        spec: 'Comfort +5°C',
        status: ChecklistStatus.packed),
    ChecklistItem(
        id: 'c2',
        category: 'Ночівля',
        name: 'Каремат',
        spec: 'надувний/піна',
        status: ChecklistStatus.packed),
    ChecklistItem(
        id: 'c3',
        category: 'Ночівля',
        name: 'Намет',
        spec: 'двомісний',
        status: ChecklistStatus.todo,
        actionLabel: 'Орендувати'),
    ChecklistItem(
        id: 'c4',
        category: 'Одяг',
        name: 'Дощовик',
        spec: 'мембранна куртка',
        status: ChecklistStatus.packed),
    ChecklistItem(
        id: 'c5',
        category: 'Одяг',
        name: 'Трекінгові черевики',
        spec: 'з міцним протектором',
        status: ChecklistStatus.packed),
    ChecklistItem(
        id: 'c6',
        category: 'Спорядження',
        name: 'Наплічник',
        spec: '60–80 л',
        status: ChecklistStatus.packed),
    ChecklistItem(
        id: 'c7',
        category: 'Спорядження',
        name: 'Палиці',
        spec: 'телескопічні',
        status: ChecklistStatus.shared,
        actionLabel: 'Позичити',
        actionNote: 'у Марти'),
    ChecklistItem(
        id: 'c8',
        category: 'Спорядження',
        name: 'Ліхтар',
        spec: 'налобний + батарейки',
        status: ChecklistStatus.packed),
  ];

  // --- sample data (matches the design mock) --------------------------------
  static final _oleg = const ProfileRef(id: 's1', displayName: 'Олег Сокіл');
  static final _marta = const ProfileRef(id: 's2', displayName: 'Марта Лісова');
  static final _andrii = const ProfileRef(id: 's3', displayName: 'Андрій Вітер');

  static final List<Hike> _sample = [
    Hike(
      id: 'sample-borzhava',
      type: HikeType.shared,
      title: 'Олег шукає ще двох на Боржаву',
      summary: 'Маршрут перевірено цього тижня, їдемо нічним потягом зі Львова',
      region: 'Боржава',
      location: 'Львів',
      startDate: DateTime(2026, 8, 14),
      endDate: DateTime(2026, 8, 18),
      difficulty: HikeDifficulty.moderate,
      durationDays: 5,
      includes: ['Спільний трансфер', 'Газ і пальник', 'Груповий намет'],
      highlights: ['Спокійний темп', 'Багаття ввечері', 'Без комісії організатору'],
      organizer: _oleg,
    ),
    Hike(
      id: 'sample-pikui',
      type: HikeType.shared,
      title: 'Марта йде вперше й хоче спокійний темп',
      summary:
          'Шукаю компанію зі Львова для нескладного підйому та довгих розмов біля багаття',
      region: 'Пікуй',
      location: 'Львів',
      startDate: DateTime(2026, 8, 15),
      endDate: DateTime(2026, 8, 17),
      difficulty: HikeDifficulty.easy,
      durationDays: 3,
      organizer: _marta,
    ),
    Hike(
      id: 'sample-svydovets',
      type: HikeType.shared,
      title: 'На Свидовець уже є група',
      summary: 'Залишилось ще одне місце. Беремо намети, пальники та гарний настрій',
      region: 'Свидовець',
      startDate: DateTime(2026, 8, 19),
      endDate: DateTime(2026, 8, 21),
      difficulty: HikeDifficulty.moderate,
      durationDays: 3,
      organizer: _andrii,
    ),
  ];
}
