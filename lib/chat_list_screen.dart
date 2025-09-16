import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet."));
          }

          var chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index];
              var otherParticipantId =
                  chat['participants'].firstWhere((id) => id != currentUserId);
              var lastMessage = chat['lastMessage'];
              var unreadCount = chat['unreadCount'][currentUserId] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherParticipantId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  var userData = userSnapshot.data!;
                  var otherParticipantName = userData['username'] ?? "Unknown";
                  var role = userData[
                      'role']; // Determine role (e.g., 'Tutor' or 'Student')

                  return FutureBuilder<DocumentSnapshot>(
                    future: role == 'Tutor'
                        ? FirebaseFirestore.instance
                            .collection('qualifications')
                            .doc(otherParticipantId)
                            .get()
                        : FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherParticipantId)
                            .get(),
                    builder: (context, profileSnapshot) {
                      String profileImageUrl =
                          'assets/blank_profile.png'; // Default placeholder
                      if (profileSnapshot.hasData &&
                          profileSnapshot.data!.exists) {
                        var profileData = profileSnapshot.data!.data()
                            as Map<String, dynamic>;
                        if (profileData.containsKey('profileImageUrl') &&
                            profileData['profileImageUrl'] != null) {
                          profileImageUrl = profileData['profileImageUrl'];
                        }
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(profileImageUrl),
                        ),
                        title: Text(otherParticipantName),
                        subtitle: Text(lastMessage),
                        trailing: unreadCount > 0
                            ? CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              )
                            : null,
                        onTap: () {
                          print(otherParticipantId);
                          print(role == 'Tutor'
                              ? otherParticipantName
                              : chat['participantNames'].firstWhere(
                                  (name) => name != otherParticipantName));
                          print(role == 'Student'
                              ? otherParticipantName
                              : chat['participantNames'].firstWhere(
                                  (name) => name != otherParticipantName));

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                tutorId: otherParticipantId,
                                tutorName: role == 'Tutor'
                                    ? otherParticipantName
                                    : chat['participantNames'].firstWhere(
                                        (name) => name != otherParticipantName),
                                studentName: role == 'Student'
                                    ? otherParticipantName
                                    : chat['participantNames'].firstWhere(
                                        (name) => name != otherParticipantName),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
