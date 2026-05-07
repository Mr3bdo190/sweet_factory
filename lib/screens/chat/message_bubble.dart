import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/full_screen_image_viewer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final String messageId;
  final String chatId;
  final bool isMe;
  final Function(Map<String, dynamic> msg) onReply;
  final Function(Map<String, dynamic> msg, String msgId) onEdit;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.messageId,
    required this.chatId,
    required this.isMe,
    required this.onReply,
    required this.onEdit,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Update read receipt if I am receiving this message and it's not read yet
    if (!widget.isMe && widget.msg['status'] != 'read') {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(widget.messageId)
          .update({'status': 'read'});
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reactions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .doc(widget.messageId)
                        .update({
                      'reactions.${FirebaseAuth.instance.currentUser!.uid}': emoji
                    });
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                );
              }).toList(),
            ),
            const Divider(color: GlassTheme.glassBorder, height: 30),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.white),
              title: const Text('Reply', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                widget.onReply(widget.msg);
              },
            ),
            if (widget.isMe && widget.msg['type'] == 'text')
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text('Edit', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit(widget.msg, widget.messageId);
                },
              ),
            if (widget.isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .doc(widget.messageId)
                      .delete();
                },
              ),
          ],
        ),
      ),
    );
  }

   Widget _buildContent() {
     if (widget.msg['type'] == 'image' && widget.msg['mediaUrl'] != null) {
       return GestureDetector(
         onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: widget.msg['mediaUrl'])));
         },
         child: Hero(
           tag: widget.msg['mediaUrl'],
           child: ClipRRect(
             borderRadius: BorderRadius.circular(12),
             child: InteractiveViewer(
               panEnabled: true,
               boundaryMargin: const EdgeInsets.all(20),
               minScale: 0.5,
               maxScale: 4.0,
               child: CachedNetworkImage(
                 imageUrl: widget.msg['mediaUrl'], 
                 width: 200, 
                 fit: BoxFit.cover,
                 placeholder: (context, url) => Container(height: 200, width: 200, color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
                 errorWidget: (context, url, error) => Container(
                   height: 200,
                   width: 200,
                   color: Colors.black12,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: const [
                       Icon(Icons.broken_image, color: Colors.white, size: 40),
                       SizedBox(height: 8),
                       Text('Failed to load', style: TextStyle(color: Colors.white)),
                     ],
                   ),
                 ),
               ),
             ),
           ),
         ),
       );
     } else if (widget.msg['type'] == 'location') {
       final parts = widget.msg['content'].toString().split(',');
       if (parts.length == 2) {
         final lat = double.tryParse(parts[0]) ?? 0.0;
         final lng = double.tryParse(parts[1]) ?? 0.0;
         return SizedBox(
           height: 150,
           width: 200,
           child: ClipRRect(
             borderRadius: BorderRadius.circular(12),
             child: IgnorePointer(
               child: FlutterMap(
                 options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15.0),
                 children: [
                   TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                   MarkerLayer(markers: [
                     Marker(point: LatLng(lat, lng), width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
                   ])
                 ],
               ),
             ),
           ),
         );
       }
       return const Text('Invalid Location Data', style: TextStyle(color: Colors.white));
     } else if (widget.msg['type'] == 'audio' && widget.msg['mediaUrl'] != null) {
       return Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           IconButton(
             icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
             onPressed: () => _audioPlayer.play(UrlSource(widget.msg['mediaUrl'])),
           ),
           const Text('Voice Message', style: TextStyle(color: Colors.white)),
         ],
       );
     }
     return Text(widget.msg['content'] ?? '', style: TextStyle(color: widget.isMe ? Colors.white : GlassTheme.textPrimary, fontSize: 16));
   }

  Widget _buildReplyPreview() {
    if (widget.msg['replyToText'] == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: GlassTheme.primaryAccent, width: 4)),
      ),
      child: Text(
        widget.msg['replyToText'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.msg['status'] ?? 'sent'; // sent, delivered, read
    final time = widget.msg['timestamp'] != null ? (widget.msg['timestamp'] as Timestamp).toDate() : DateTime.now();
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    final reactions = widget.msg['reactions'] as Map<String, dynamic>? ?? {};

    return GestureDetector(
      onLongPress: _showOptions,
      onDoubleTap: () {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .doc(widget.messageId)
            .update({
          'reactions.${FirebaseAuth.instance.currentUser!.uid}': '❤️'
        });
      },
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6).copyWith(bottom: reactions.isNotEmpty ? 16 : 6),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isMe ? GlassTheme.primaryAccent : GlassTheme.glassWhite.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(20),
                  bottomLeft: !widget.isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: widget.isMe ? null : Border.all(color: GlassTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReplyPreview(),
                  _buildContent(),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeStr, style: TextStyle(color: widget.isMe ? Colors.white70 : Colors.white54, fontSize: 10)),
                      if (widget.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          status == 'read' ? Icons.done_all : (status == 'delivered' ? Icons.done_all : Icons.check),
                          size: 14,
                          color: status == 'read' ? Colors.blueAccent : Colors.white70,
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            if (reactions.isNotEmpty)
              Positioned(
                bottom: -4,
                right: widget.isMe ? 20 : null,
                left: widget.isMe ? null : 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: GlassTheme.backgroundDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: GlassTheme.glassBorder)),
                  child: Text(reactions.values.take(3).join(' '), style: const TextStyle(fontSize: 14)),
                ),
              ).animate().scale(curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }
}
