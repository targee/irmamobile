import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'log_entry.g.dart';

@JsonSerializable()
class LogsEvent extends Event {
  LogsEvent({required this.logEntries});

  @JsonKey(name: 'LogEntries')
  final List<LogEntry> logEntries;

  factory LogsEvent.fromJson(Map<String, dynamic> json) => _$LogsEventFromJson(json);
}

@JsonSerializable()
class LoadLogsEvent extends Event {
  LoadLogsEvent({required this.max, this.before});

  @JsonKey(name: 'Before')
  final int? before;

  @JsonKey(name: 'Max')
  final int max;

  Map<String, dynamic> toJson() => _$LoadLogsEventToJson(this);
}

enum LogEntryType {
  disclosing,
  signing,
  issuing,
  removal,
}

LogEntryType _toLogEntryType(String type) {
  return LogEntryType.values.firstWhere(
    (v) => v.toString() == 'LogEntryType.$type',
  );
}

DateTime _epochSecondsToDateTime(int secondsSinceEpoch) =>
    DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);

@JsonSerializable()
class LogEntry {
  const LogEntry({
    required this.id,
    required this.type,
    required this.time,
    required this.issuedCredentials,
    required this.disclosedAttributes,
    required this.removedCredentials,
    this.serverName,
    this.signedMessage,
  });

  @JsonKey(name: 'ID')
  final int id;

  @JsonKey(name: 'Type', fromJson: _toLogEntryType)
  final LogEntryType type;

  @JsonKey(name: 'Time', fromJson: _epochSecondsToDateTime)
  final DateTime time;

  @JsonKey(name: 'ServerName')
  // Due to some legacy log entries, serverName might be null sometimes. This should be fixed in irmago.
  final RequestorInfo? serverName;

  @JsonKey(name: 'IssuedCredentials')
  final List<RawCredential> issuedCredentials;

  @JsonKey(name: 'DisclosedCredentials')
  final List<List<DisclosedAttribute>> disclosedAttributes;

  @JsonKey(name: 'RemovedCredentials')
  final Map<String, Map<String, TranslatedValue>> removedCredentials;

  @JsonKey(name: 'SignedMessage')
  final SignedMessage? signedMessage;

  factory LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);
}

@JsonSerializable()
class SignedMessage {
  SignedMessage({required this.message});

  @JsonKey(name: 'message')
  final String message;

  factory SignedMessage.fromJson(Map<String, dynamic> json) => _$SignedMessageFromJson(json);
  Map<String, dynamic> toJson() => _$SignedMessageToJson(this);
}
