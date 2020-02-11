import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attributes.g.dart';

// Attributes of a credential.
class Attributes extends UnmodifiableMapView<AttributeType, TranslatedValue> {
  List<AttributeType> sortedAttributeTypes;

  Attributes(Map<AttributeType, TranslatedValue> map)
      : assert(map != null),
        super(map) {
    // Pre-calculate an ordered list of attributeTypes, initially on index, finally on displayIndex
    sortedAttributeTypes = keys.toList();
    sortedAttributeTypes.sort((a1, a2) => a1.index.compareTo(a2.index));
    if (sortedAttributeTypes.every((a) => a.displayIndex != null)) {
      sortedAttributeTypes.sort((a1, a2) => (a1.displayIndex).compareTo(a2.displayIndex));
    }
  }

  factory Attributes.fromRaw({IrmaConfiguration irmaConfiguration, Map<String, TranslatedValue> rawAttributes}) {
    return Attributes(rawAttributes.map<AttributeType, TranslatedValue>((k, v) {
      return MapEntry(irmaConfiguration.attributeTypes[k], v);
    }));
  }
}

class ConDisCon<T> extends UnmodifiableListView<DisCon<T>> {
  ConDisCon(Iterable<DisCon<T>> list)
      : assert(list != null),
        super(list);

  // This can't be a contructor due to dart-lang/sdk#26391
  static ConDisCon<T> fromRaw<R, T>(List<List<List<R>>> rawConDisCon, T Function(R) fromRaw) {
    return ConDisCon<T>(rawConDisCon.map((rawDisCon) {
      return DisCon<T>(rawDisCon.map((rawCon) {
        return Con<T>(rawCon.map((elem) {
          return fromRaw(elem);
        }));
      }));
    }));
  }
}

class DisCon<T> extends UnmodifiableListView<Con<T>> {
  DisCon(Iterable<Con<T>> list)
      : assert(list != null),
        super(list);
}

class ConCon<T> extends UnmodifiableListView<Con<T>> {
  ConCon(Iterable<Con<T>> list)
      : assert(list != null),
        super(list);
}

class Con<T> extends UnmodifiableListView<T> {
  Con(Iterable<T> list)
      : assert(list != null),
        super(list);
}

@JsonSerializable()
class AttributeRequest {
  AttributeRequest({this.type, this.value, this.notNull});

  @JsonKey(name: 'Type')
  String type;

  @JsonKey(name: 'Value')
  String value;

  @JsonKey(name: 'NotNull')
  bool notNull;

  factory AttributeRequest.fromJson(Map<String, dynamic> json) => _$AttributeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeRequestToJson(this);
}

@JsonSerializable()
class AttributeIdentifier {
  AttributeIdentifier({this.type, this.credentialHash});

  @JsonKey(name: 'Type')
  String type;

  @JsonKey(name: 'CredentialHash')
  String credentialHash;

  factory AttributeIdentifier.fromJson(Map<String, dynamic> json) => _$AttributeIdentifierFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeIdentifierToJson(this);

  AttributeIdentifier.fromCredentialAttribute(CredentialAttribute credentialAttribute) {
    type = credentialAttribute.attributeType.fullId;
    credentialHash = credentialAttribute.credential.hash;
  }
}

class CredentialAttribute {
  Credential credential;
  AttributeType attributeType;
  TranslatedValue value;

  CredentialAttribute({
    @required this.credential,
    @required this.attributeType,
    @required this.value,
  })  : assert(credential != null),
        assert(attributeType != null),
        assert(value != null);

  CredentialAttribute.fromAttributeIdentifier(
      IrmaConfiguration irmaConfiguration, Credentials credentials, AttributeIdentifier attributeIdentifier) {
    credential = credentials[attributeIdentifier.credentialHash];
    attributeType = irmaConfiguration.attributeTypes[attributeIdentifier.type];
    value = credential.attributes[attributeType];
  }
}

@JsonSerializable()
class DisclosedAttribute {
  const DisclosedAttribute({
    this.rawValue,
    this.value,
    this.identifier,
    this.status,
    this.issuanceTime,
  });

  @JsonKey(name: 'rawValue')
  final String rawValue;

  @JsonKey(name: 'value')
  final TranslatedValue value;

  @JsonKey(name: 'id')
  final String identifier;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'issuancetime')
  final int issuanceTime;

  factory DisclosedAttribute.fromJson(Map<String, dynamic> json) => _$DisclosedAttributeFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosedAttributeToJson(this);
}
