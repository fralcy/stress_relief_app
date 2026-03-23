/// Thông tin một host LAN được tìm thấy qua UDP discovery.
class LanHostInfo {
  final String ip;
  final int wsPort;
  final String displayName;
  final int avatarIndex;

  const LanHostInfo({
    required this.ip,
    required this.wsPort,
    required this.displayName,
    this.avatarIndex = 0,
  });

  @override
  String toString() => 'LanHostInfo($displayName @ $ip:$wsPort)';

  @override
  bool operator ==(Object other) =>
      other is LanHostInfo && other.ip == ip && other.wsPort == wsPort;

  @override
  int get hashCode => Object.hash(ip, wsPort);
}
