import 'package:flutter/material.dart';

void main() {
  var json = {
    "_id": "66221c",
    "type": "direct",
    "avatar": "",
    "participants": [
      {
        "userId": {
          "_id": "user1",
          "username": "Chemestry",
          "avatar": {
            "public_id": "sfefg4koa5dfmby8lex7.png",
            "url":
                "https://res.cloudinary.com/dat3kh4o6/raw/upload/v1776454447/sfefg4koa5dfmby8lex7.png",
          },
        },
      },
      {"userId": "current_user_id"},
    ],
  };

  String? avatar = json['avatar'] as String?;
  if (avatar != null && avatar.isEmpty) {
    avatar = null;
  }

  String title = json['name'] as String? ?? '';

  if (json['type'] == 'direct' && (title.isEmpty || avatar == null)) {
    var rawParticipants = json['participants'] as List;
    var otherParticipant = rawParticipants.firstWhere((p) {
      var id = p['userId'] is Map ? p['userId']['_id'] : p['userId'];
      return id != 'current_user_id';
    }, orElse: () => null);

    if (otherParticipant != null && otherParticipant['userId'] is Map) {
      var userData = otherParticipant['userId'] as Map;
      if (title.isEmpty) title = userData['username'] ?? '';
      avatar ??= userData['avatar'] is Map
          ? userData['avatar']['url']
          : userData['avatar'];
    }
  }

  debugPrint("Final Title: \$title");
  debugPrint("Final Avatar: \$avatar");
}
