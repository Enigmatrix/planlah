class GroupInviteDto {
  String id;
  DateTime expiry;
  String url;
  num groupId;

  GroupInviteDto(this.id, this.expiry, this.url, this.groupId);

  GroupInviteDto.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        id = json['id'],
        expiry = json['expiry'],
        groupId = json['groupId'];
}

enum ExpiryOption{
  OneHour("oneHour", "1 Hour"),
  OneDay("oneDay", "1 Day"),
  Never("never", "Never");

  const ExpiryOption(this.apiText, this.userText);
  final String apiText;
  final String userText;
}

class CreateGroupInviteDto {
  ExpiryOption expiryOption;
  num groupId;

  CreateGroupInviteDto(this.expiryOption, this.groupId);

  Map<String, dynamic> toJson() => {
    'expiryOption': expiryOption.apiText,
    'groupId': groupId,
  };
}