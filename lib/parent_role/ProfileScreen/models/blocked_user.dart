class BlockedUser {
  final String id;
  final String name;
  final String avatarUrl;
  final String blockDate;

  const BlockedUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.blockDate,
  });
}

const List<BlockedUser> mockBlockedUsers = [
  BlockedUser(
    id: "b1",
    name: "Maximillian Jacobson",
    avatarUrl:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80",
    blockDate: "11/19/19",
  ),
  BlockedUser(
    id: "b2",
    name: "Martha Carig",
    avatarUrl:
        "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80",
    blockDate: "11/19/19",
  ),
];
