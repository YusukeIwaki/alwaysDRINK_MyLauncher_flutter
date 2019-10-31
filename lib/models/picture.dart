class Picture {
  Picture({
    this.smallUrl,
    this.largeUrl,
  });

  String smallUrl;
  String largeUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Picture &&
              runtimeType == other.runtimeType &&
              smallUrl == other.smallUrl &&
              largeUrl == other.largeUrl;

  @override
  int get hashCode =>
      smallUrl.hashCode ^
      largeUrl.hashCode;

  @override
  String toString() {
    return 'Picture{smallUrl: $smallUrl, largeUrl: $largeUrl}';
  }
}
