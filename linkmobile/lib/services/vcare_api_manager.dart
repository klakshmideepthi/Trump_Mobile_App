import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/plan_model.dart';

// MARK: - Data Models

/// Device Compatibility Models
class DeviceCompatibilityData {
  final String? band12Compatible;
  final String? bands;
  final String? chipsetModel;
  final String? chipsetName;
  final String? chipsetVendor;
  final String? compatibility;
  final String? description;
  final String? deviceType;
  final String? dualBandWifi;
  final String? esim;
  final String? gprs;
  final String? hdVoice;
  final String? hsdpa;
  final String? hspa;
  final String? imei;
  final String? ims;
  final String? ipv6;
  final String? lte;
  final String? lteAdvanced;
  final String? lteCategory;
  final String? manufacturer;
  final String? marketingName;
  final String? model;
  final String? name;
  final String? networkCompatible;
  final String? networkTechnology;
  final String? nonStandalone5G;
  final String? osName;
  final String? passpoint;
  final String? primaryHardwareType;
  final String? remoteSimUnlock;
  final String? roamingIms;
  final String? simSize;
  final String? simSlots;
  final String? standalone5G;
  final String? statusCode;
  final String? tac;
  final String? technologyOnTheDevice;
  final String? tmobileApproved;
  final String? umts;
  final String? volte;
  final String? volteCompatible;
  final String? volteEmergencyCalling;
  final String? vonrCompatible;
  final String? vowifi;
  final String? wifi;
  final String? wifiCallingVersion;
  final String? wifiCompatible;
  final String? wlan;
  final String? yearReleased;

  DeviceCompatibilityData({
    this.band12Compatible,
    this.bands,
    this.chipsetModel,
    this.chipsetName,
    this.chipsetVendor,
    this.compatibility,
    this.description,
    this.deviceType,
    this.dualBandWifi,
    this.esim,
    this.gprs,
    this.hdVoice,
    this.hsdpa,
    this.hspa,
    this.imei,
    this.ims,
    this.ipv6,
    this.lte,
    this.lteAdvanced,
    this.lteCategory,
    this.manufacturer,
    this.marketingName,
    this.model,
    this.name,
    this.networkCompatible,
    this.networkTechnology,
    this.nonStandalone5G,
    this.osName,
    this.passpoint,
    this.primaryHardwareType,
    this.remoteSimUnlock,
    this.roamingIms,
    this.simSize,
    this.simSlots,
    this.standalone5G,
    this.statusCode,
    this.tac,
    this.technologyOnTheDevice,
    this.tmobileApproved,
    this.umts,
    this.volte,
    this.volteCompatible,
    this.volteEmergencyCalling,
    this.vonrCompatible,
    this.vowifi,
    this.wifi,
    this.wifiCallingVersion,
    this.wifiCompatible,
    this.wlan,
    this.yearReleased,
  });

  factory DeviceCompatibilityData.fromJson(Map<String, dynamic> json) {
    return DeviceCompatibilityData(
      band12Compatible: json['BAND12COMPATIBLE']?.toString(),
      bands: json['BANDS']?.toString(),
      chipsetModel: json['CHIPSETMODEL']?.toString(),
      chipsetName: json['CHIPSETNAME']?.toString(),
      chipsetVendor: json['CHIPSETVENDOR']?.toString(),
      compatibility: json['COMPATIBILITY']?.toString(),
      description: json['DESCRIPTION']?.toString(),
      deviceType: json['DEVICETYPE']?.toString(),
      dualBandWifi: json['DUALBANDWIFI']?.toString(),
      esim: json['ESIM']?.toString(),
      gprs: json['GPRS']?.toString(),
      hdVoice: json['HDVOICE']?.toString(),
      hsdpa: json['HSDPA']?.toString(),
      hspa: json['HSPA']?.toString(),
      imei: json['IMEI']?.toString(),
      ims: json['IMS']?.toString(),
      ipv6: json['IPV6']?.toString(),
      lte: json['LTE']?.toString(),
      lteAdvanced: json['LTEADVANCED']?.toString(),
      lteCategory: json['LTECATEGORY']?.toString(),
      manufacturer: json['MANUFACTURER']?.toString(),
      marketingName: json['MARKETINGNAME']?.toString(),
      model: json['MODEL']?.toString(),
      name: json['NAME']?.toString(),
      networkCompatible: json['NETWORKCOMPATIBLE']?.toString(),
      networkTechnology: json['NETWORKTECHNOLOGY']?.toString(),
      nonStandalone5G: json['NONSTANDALONE5G']?.toString(),
      osName: json['OSNAME']?.toString(),
      passpoint: json['PASSPOINT']?.toString(),
      primaryHardwareType: json['PRIMARYHARDWARETYPE']?.toString(),
      remoteSimUnlock: json['REMOTESIMUNLOCK']?.toString(),
      roamingIms: json['ROAMINGIMS']?.toString(),
      simSize: json['SIMSIZE']?.toString(),
      simSlots: json['SIMSLOTS']?.toString(),
      standalone5G: json['STANDALONE5G']?.toString(),
      statusCode: json['STATUSCODE']?.toString(),
      tac: json['TAC']?.toString(),
      technologyOnTheDevice: json['TECHNOLOGYONTHEDEVICE']?.toString(),
      tmobileApproved: json['TMOBILEAPPROVED']?.toString(),
      umts: json['UMTS']?.toString(),
      volte: json['VOLTE']?.toString(),
      volteCompatible: json['VOLTECOMPATIBLE']?.toString(),
      volteEmergencyCalling: json['VOLTEEMERGENCYCALLING']?.toString(),
      vonrCompatible: json['VONRCOMPATIBLE']?.toString(),
      vowifi: json['VOWIFI']?.toString(),
      wifi: json['WIFI']?.toString(),
      wifiCallingVersion: json['WIFICALLINGVERSION']?.toString(),
      wifiCompatible: json['WIFICOMPATIBLE']?.toString(),
      wlan: json['WLAN']?.toString(),
      yearReleased: json['YEARRELEASED']?.toString(),
    );
  }

  bool get isCompatible {
    if (compatibility == null) return false;
    final comp = compatibility!.toUpperCase();
    if (comp.contains('NOT COMPATIBLE') || comp.contains('RED')) return false;
    return comp.contains('FULLY COMPATIBLE') ||
        comp.contains('COMPATIBLE') ||
        comp.contains('GREEN') ||
        comp.contains('YES');
  }

  String get compatibilityMessage {
    return compatibility ?? 'Compatibility status unknown';
  }

  bool get supportsESIM {
    if (esim == null) return true; // Default to true if unknown
    return esim!.toUpperCase() == 'YES';
  }

  bool get supportsPhysicalSIM {
    if (esim != null && esim!.toUpperCase() == 'NO') {
      return true; // If no eSIM, physical SIM should be available
    }
    if (simSlots != null) {
      return simSlots!.toUpperCase() == 'YES';
    }
    return true; // Default to true if unknown
  }

  /// Convert QueryDeviceData to DeviceCompatibilityData
  static DeviceCompatibilityData? fromQueryDeviceData(QueryDeviceData queryData) {
    final deviceInfoList = queryData.result?.deviceInfo;
    if (deviceInfoList == null || deviceInfoList.isEmpty) return null;
    final deviceInfo = deviceInfoList.first;

    // Extract values from nested structure
    String? esim;
    String? simSlots;
    String? compatibility;
    String? manufacturer = deviceInfo.manufacturer;
    String? marketingName = deviceInfo.marketingName;
    String? model = deviceInfo.model;
    String? imei = deviceInfo.imei;
    String? networkTechnology;
    String? band12Compatible;
    String? volteCompatible;
    String? wifiCompatible;

    // Extract values from device groups
    if (deviceInfo.deviceGroup != null) {
      for (final group in deviceInfo.deviceGroup!) {
        final groupName = group.deviceGroupName;
        final specifications = group.specification;
        
        if (specifications == null) continue;

        switch (groupName) {
          case 'SimSpecifications':
            for (final spec in specifications) {
              final name = spec.specificationName;
              final value = spec.specificationValue;
              if (name == 'eSIM') {
                esim = value;
              } else if (name == 'SIMSlots') {
                simSlots = value;
              }
            }
            break;

          case 'NetworkCompatibility':
            for (final spec in specifications) {
              final name = spec.specificationName;
              final value = spec.specificationValue;
              if (name == 'compatibility') {
                compatibility = value;
              } else if (name == 'NetworkTechnology') {
                networkTechnology = value;
              } else if (name == 'Band12Compatible') {
                band12Compatible = value;
              } else if (name == 'VoLTECompatible') {
                volteCompatible = value;
              } else if (name == 'WiFiCompatible') {
                wifiCompatible = value;
              }
            }
            break;
        }
      }
    }

    return DeviceCompatibilityData(
      band12Compatible: band12Compatible,
      bands: null,
      chipsetModel: null,
      chipsetName: null,
      chipsetVendor: null,
      compatibility: compatibility,
      description: queryData.description,
      deviceType: null,
      dualBandWifi: null,
      esim: esim,
      gprs: null,
      hdVoice: null,
      hsdpa: null,
      hspa: null,
      imei: imei,
      ims: null,
      ipv6: null,
      lte: null,
      lteAdvanced: null,
      lteCategory: null,
      manufacturer: manufacturer,
      marketingName: marketingName,
      model: model,
      name: deviceInfo.name,
      networkCompatible: null,
      networkTechnology: networkTechnology,
      nonStandalone5G: null,
      osName: null,
      passpoint: null,
      primaryHardwareType: null,
      remoteSimUnlock: null,
      roamingIms: null,
      simSize: null,
      simSlots: simSlots,
      standalone5G: null,
      statusCode: queryData.statusCode,
      tac: deviceInfo.tac,
      technologyOnTheDevice: null,
      tmobileApproved: null,
      umts: null,
      volte: null,
      volteCompatible: volteCompatible,
      volteEmergencyCalling: null,
      vonrCompatible: null,
      vowifi: null,
      wifi: null,
      wifiCallingVersion: null,
      wifiCompatible: wifiCompatible,
      wlan: null,
      yearReleased: null,
    );
  }
}

/// Nested response model for get_query_device action
class QueryDeviceResponse {
  final QueryDeviceData? data;
  final String msg;
  final String msgCode;
  final String token;

  QueryDeviceResponse({
    this.data,
    required this.msg,
    required this.msgCode,
    required this.token,
  });

  factory QueryDeviceResponse.fromJson(Map<String, dynamic> json) {
    return QueryDeviceResponse(
      data: json['data'] != null
          ? QueryDeviceData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      msg: json['msg'] as String? ?? '',
      msgCode: json['msg_code'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }
}

/// Nested data structure for get_query_device
class QueryDeviceData {
  final String? description;
  final String? referenceNo;
  final QueryDeviceResult? result;
  final String? statusCode;

  QueryDeviceData({
    this.description,
    this.referenceNo,
    this.result,
    this.statusCode,
  });

  factory QueryDeviceData.fromJson(Map<String, dynamic> json) {
    return QueryDeviceData(
      description: json['DESCRIPTION']?.toString(),
      referenceNo: json['REFRENCENO']?.toString(),
      result: json['RESULT'] != null
          ? QueryDeviceResult.fromJson(json['RESULT'] as Map<String, dynamic>)
          : null,
      statusCode: json['STATUSCODE']?.toString(),
    );
  }
}

/// Device result from get_query_device
class QueryDeviceResult {
  final List<DeviceInfo>? deviceInfo;

  QueryDeviceResult({
    this.deviceInfo,
  });

  factory QueryDeviceResult.fromJson(Map<String, dynamic> json) {
    final deviceInfoList = json['deviceInfo'] as List<dynamic>?;
    return QueryDeviceResult(
      deviceInfo: deviceInfoList
          ?.map((item) => DeviceInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Device information from get_query_device
class DeviceInfo {
  final List<DeviceGroup>? deviceGroup;
  final String? imei;
  final String? manufacturer;
  final String? marketingName;
  final String? model;
  final String? name;
  final String? tac;

  DeviceInfo({
    this.deviceGroup,
    this.imei,
    this.manufacturer,
    this.marketingName,
    this.model,
    this.name,
    this.tac,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    final deviceGroupList = json['deviceGroup'] as List<dynamic>?;
    return DeviceInfo(
      deviceGroup: deviceGroupList
          ?.map((item) => DeviceGroup.fromJson(item as Map<String, dynamic>))
          .toList(),
      imei: json['imei']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      marketingName: json['marketingName']?.toString(),
      model: json['model']?.toString(),
      name: json['name']?.toString(),
      tac: json['tac']?.toString(),
    );
  }
}

/// Device group containing specifications
class DeviceGroup {
  final String? deviceGroupName;
  final List<Specification>? specification;

  DeviceGroup({
    this.deviceGroupName,
    this.specification,
  });

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    final specList = json['specification'] as List<dynamic>?;
    return DeviceGroup(
      deviceGroupName: json['deviceGroupName']?.toString(),
      specification: specList
          ?.map((item) => Specification.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Specification item
class Specification {
  final String? specificationName;
  final String? specificationValue;

  Specification({
    this.specificationName,
    this.specificationValue,
  });

  factory Specification.fromJson(Map<String, dynamic> json) {
    return Specification(
      specificationName: json['specificationName']?.toString(),
      specificationValue: json['specificationValue']?.toString(),
    );
  }
}

/// Port-In Validation Models
class PortInValidationData {
  final String? description;
  final String? portInStatus;
  final int? statusCode;
  final String? mdn;
  final String? oldServiceProvider;
  final String? msg;
  final String? msgCode;

  PortInValidationData({
    this.description,
    this.portInStatus,
    this.statusCode,
    this.mdn,
    this.oldServiceProvider,
    this.msg,
    this.msgCode,
  });

  factory PortInValidationData.fromJson(Map<String, dynamic> json) {
    // Extract portInStatus - check multiple possible locations
    String? portInStatus = json['PORTINSTATUS']?.toString();
    
    // If PORTINSTATUS is not found, check nested RESULT.responseDetails.eligibilityFlag
    if (portInStatus == null || portInStatus.isEmpty) {
      final result = json['RESULT'] as Map<String, dynamic>?;
      if (result != null) {
        final responseDetails = result['responseDetails'] as Map<String, dynamic>?;
        if (responseDetails != null) {
          final eligibilityFlag = responseDetails['eligibilityFlag']?.toString();
          if (eligibilityFlag != null) {
            // If eligibilityFlag is "true", set portInStatus to "Eligible"
            if (eligibilityFlag.toLowerCase() == 'true') {
              portInStatus = 'Eligible';
            } else {
              portInStatus = 'Not Eligible';
            }
          }
        }
      }
    }
    
    return PortInValidationData(
      description: json['DESCRIPTION']?.toString() ?? json['description']?.toString(),
      portInStatus: portInStatus,
      statusCode: json['STATUSCODE'] is int
          ? json['STATUSCODE'] as int?
          : json['STATUSCODE'] is String
              ? int.tryParse(json['STATUSCODE'] as String)
              : null,
      mdn: json['mdn']?.toString() ?? json['MDN']?.toString(),
      oldServiceProvider: json['old_service_provider']?.toString(),
      msg: json['msg']?.toString(),
      msgCode: json['msg_code']?.toString(),
    );
  }
}

/// Port-In List Response Models
class PortInListRecord {
  final int? accountNumber;
  final String? addressOne;
  final String? addressTwo;
  final String? attemptCount;
  final String? businessName;
  final String? carrier;
  final String? carrierResponse;
  final String? city;
  final int? customerId;
  final String? enrollmentId;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final int? newEsn;
  final int? numberToPort;
  final int? oldEsn;
  final String? oldMdn;
  final int? password;
  final int? portId;
  final int? portSubscriberId;
  final String? portinCompany;
  final String? portinStatus;
  final String? requestDatetime;
  final String? resolutionDescription;
  final String? responseDatetime;
  final String? returnUrl;
  final String? source;
  final String? ssn;
  final String? state;
  final String? status;
  final String? streetDirection;
  final String? streetName;
  final String? streetNumber;
  final String? uiccid;
  final int? zipcode;

  PortInListRecord({
    this.accountNumber,
    this.addressOne,
    this.addressTwo,
    this.attemptCount,
    this.businessName,
    this.carrier,
    this.carrierResponse,
    this.city,
    this.customerId,
    this.enrollmentId,
    this.firstName,
    this.lastName,
    this.middleName,
    this.newEsn,
    this.numberToPort,
    this.oldEsn,
    this.oldMdn,
    this.password,
    this.portId,
    this.portSubscriberId,
    this.portinCompany,
    this.portinStatus,
    this.requestDatetime,
    this.resolutionDescription,
    this.responseDatetime,
    this.returnUrl,
    this.source,
    this.ssn,
    this.state,
    this.status,
    this.streetDirection,
    this.streetName,
    this.streetNumber,
    this.uiccid,
    this.zipcode,
  });

  factory PortInListRecord.fromJson(Map<String, dynamic> json) {
    return PortInListRecord(
      accountNumber: json['account_number'] is int
          ? json['account_number'] as int?
          : json['account_number'] is String
              ? int.tryParse(json['account_number'] as String)
              : null,
      addressOne: json['address_one']?.toString(),
      addressTwo: json['address_two']?.toString(),
      attemptCount: json['attempt_count']?.toString(),
      businessName: json['business_name']?.toString(),
      carrier: json['carrier']?.toString(),
      carrierResponse: json['carrier_response']?.toString(),
      city: json['city']?.toString(),
      customerId: json['customer_id'] is int
          ? json['customer_id'] as int?
          : json['customer_id'] is String
              ? int.tryParse(json['customer_id'] as String)
              : null,
      enrollmentId: json['enrollment_id']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      middleName: json['middle_name']?.toString(),
      newEsn: json['new_esn'] is int
          ? json['new_esn'] as int?
          : json['new_esn'] is String
              ? int.tryParse(json['new_esn'] as String)
              : null,
      numberToPort: json['number_to_port'] is int
          ? json['number_to_port'] as int?
          : json['number_to_port'] is String
              ? int.tryParse(json['number_to_port'] as String)
              : null,
      oldEsn: json['old_esn'] is int
          ? json['old_esn'] as int?
          : json['old_esn'] is String
              ? int.tryParse(json['old_esn'] as String)
              : null,
      oldMdn: json['old_mdn']?.toString(),
      password: json['password'] is int
          ? json['password'] as int?
          : json['password'] is String
              ? int.tryParse(json['password'] as String)
              : null,
      portId: json['port_id'] is int
          ? json['port_id'] as int?
          : json['port_id'] is String
              ? int.tryParse(json['port_id'] as String)
              : null,
      portSubscriberId: json['port_subscriber_id'] is int
          ? json['port_subscriber_id'] as int?
          : json['port_subscriber_id'] is String
              ? int.tryParse(json['port_subscriber_id'] as String)
              : null,
      portinCompany: json['portin_company']?.toString(),
      portinStatus: json['portin_status']?.toString(),
      requestDatetime: json['request_datetime']?.toString(),
      resolutionDescription: json['resolution_description']?.toString(),
      responseDatetime: json['response_datetime']?.toString(),
      returnUrl: json['return_url']?.toString(),
      source: json['source']?.toString(),
      ssn: json['ssn']?.toString(),
      state: json['state']?.toString(),
      status: json['status']?.toString(),
      streetDirection: json['street_direction']?.toString(),
      streetName: json['street_name']?.toString(),
      streetNumber: json['street_number']?.toString(),
      uiccid: json['uiccid']?.toString(),
      zipcode: json['zipcode'] is int
          ? json['zipcode'] as int?
          : json['zipcode'] is String
              ? int.tryParse(json['zipcode'] as String)
              : null,
    );
  }
}

class PortInListResponse {
  final List<PortInListRecord> records;
  final String msg;
  final String msgCode;
  final String token;

  PortInListResponse({
    required this.records,
    required this.msg,
    required this.msgCode,
    required this.token,
  });

  factory PortInListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final recordsList = data?['records'] as List<dynamic>?;
    
    return PortInListResponse(
      records: recordsList != null
          ? recordsList
              .map((item) => PortInListRecord.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      msg: json['msg'] as String? ?? '',
      msgCode: json['msg_code'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }
}

/// Port-In Query Response Models
class PortInQueryRecord {
  final String? portinStatus;
  final String? carrierResponse;
  final String? resolutionDescription;
  final String? requestDatetime;
  final String? responseDatetime;
  final String? status;

  PortInQueryRecord({
    this.portinStatus,
    this.carrierResponse,
    this.resolutionDescription,
    this.requestDatetime,
    this.responseDatetime,
    this.status,
  });

  factory PortInQueryRecord.fromJson(Map<String, dynamic> json) {
    return PortInQueryRecord(
      portinStatus: json['portin_status']?.toString(),
      carrierResponse: json['carrier_response']?.toString(),
      resolutionDescription: json['resolution_description']?.toString(),
      requestDatetime: json['request_datetime']?.toString(),
      responseDatetime: json['response_datetime']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class PortInQueryResponse {
  final PortInQueryRecord? record;
  final String msg;
  final String msgCode;
  final String token;

  PortInQueryResponse({
    this.record,
    required this.msg,
    required this.msgCode,
    required this.token,
  });

  factory PortInQueryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final recordsList = data?['records'] as List<dynamic>?;
    
    return PortInQueryResponse(
      record: recordsList != null && recordsList.isNotEmpty
          ? PortInQueryRecord.fromJson(recordsList.first as Map<String, dynamic>)
          : null,
      msg: json['msg'] as String? ?? '',
      msgCode: json['msg_code'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }
}

/// Port-In Submit Response Models
class PortInSubmitResponse {
  final String data;
  final String msg;
  final String msgCode;

  PortInSubmitResponse({
    required this.data,
    required this.msg,
    required this.msgCode,
  });

  factory PortInSubmitResponse.fromJson(Map<String, dynamic> json) {
    return PortInSubmitResponse(
      data: json['data']?.toString() ?? '',
      msg: json['msg'] as String? ?? '',
      msgCode: json['msg_code'] as String? ?? '',
    );
  }
}

/// Service Availability Models
class ServiceAvailabilityData {
  final String? enrollmentId;
  final String? zipCode;
  final String? city;
  final String? state;
  final String? externalTransactionId;

  ServiceAvailabilityData({
    this.enrollmentId,
    this.zipCode,
    this.city,
    this.state,
    this.externalTransactionId,
  });

  factory ServiceAvailabilityData.fromJson(Map<String, dynamic> json) {
    return ServiceAvailabilityData(
      enrollmentId: json['enrollment_id']?.toString(),
      zipCode: json['zip_code'] is int
          ? json['zip_code'].toString()
          : json['zip_code']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      externalTransactionId: json['external_transaction_id']?.toString(),
    );
  }
}

/// Create Customer Response Models
class CreateCustomerLineData {
  final int? custId;
  final int? customerId;
  final String? enrollmentId;
  final String? enrollmentType;
  final String? invoiceNumber;
  final String? mdn;
  final String? msid;
  final String? msl;

  CreateCustomerLineData({
    this.custId,
    this.customerId,
    this.enrollmentId,
    this.enrollmentType,
    this.invoiceNumber,
    this.mdn,
    this.msid,
    this.msl,
  });

  factory CreateCustomerLineData.fromJson(Map<String, dynamic> json) {
    return CreateCustomerLineData(
      custId: json['cust_id'] as int?,
      customerId: json['customer_id'] as int?,
      enrollmentId: json['enrollment_id']?.toString(),
      enrollmentType: json['enrollment_type']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      mdn: json['mdn']?.toString(),
      msid: json['msid']?.toString(),
      msl: json['msl']?.toString(),
    );
  }
}

class CreateCustomerLineResponse {
  final CreateCustomerLineData? data;
  final String msg;
  final String msgCode;

  CreateCustomerLineResponse({
    this.data,
    required this.msg,
    required this.msgCode,
  });

  factory CreateCustomerLineResponse.fromJson(Map<String, dynamic> json) {
    return CreateCustomerLineResponse(
      data: json['data'] != null
          ? CreateCustomerLineData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      msg: json['msg'] as String? ?? '',
      msgCode: json['msg_code'] as String? ?? '',
    );
  }
}

class CreateCustomerResponse {
  final List<CreateCustomerLineResponse>? data;
  final String msg;
  final String msgCode;
  final String? externalTransactionId;
  final String token;

  CreateCustomerResponse({
    this.data,
    required this.msg,
    required this.msgCode,
    this.externalTransactionId,
    required this.token,
  });

  factory CreateCustomerResponse.fromJson(Map<String, dynamic> json) {
    return CreateCustomerResponse(
      data: json['data'] != null
          ? (json['data'] as List<dynamic>)
              .map((item) => CreateCustomerLineResponse.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      msg: json['msg'] as String? ?? '',
      msgCode: json['msg_code'] as String? ?? '',
      externalTransactionId: json['external_transaction_id']?.toString(),
      token: json['token'] as String? ?? '',
    );
  }
}

/// USPS Address Validation Models
class USPSAddressData {
  final String? address1;
  final String? address2;
  final String? carrierRoute;
  final String? centralDeliveryPoint;
  final String? city;
  final String? dpvConfirmation;
  final String? dpvFalse;
  final String? dpvFootnotes;
  final String? footnotes;
  final String? state;
  final String? zip4;
  final String? zip5;

  USPSAddressData({
    this.address1,
    this.address2,
    this.carrierRoute,
    this.centralDeliveryPoint,
    this.city,
    this.dpvConfirmation,
    this.dpvFalse,
    this.dpvFootnotes,
    this.footnotes,
    this.state,
    this.zip4,
    this.zip5,
  });

  factory USPSAddressData.fromJson(Map<String, dynamic> json) {
    return USPSAddressData(
      address1: json['Address1']?.toString(),
      address2: json['Address2']?.toString(),
      carrierRoute: json['CarrierRoute']?.toString(),
      centralDeliveryPoint: json['CentralDeliveryPoint']?.toString(),
      city: json['City']?.toString(),
      dpvConfirmation: json['DPVConfirmation']?.toString(),
      dpvFalse: json['DPVFalse']?.toString(),
      dpvFootnotes: json['DPVFootnotes']?.toString(),
      footnotes: json['Footnotes']?.toString(),
      state: json['State']?.toString(),
      zip4: json['Zip4']?.toString(),
      zip5: json['Zip5']?.toString(),
    );
  }
}

/// VCare API Manager for handling authentication and API calls to vcareapi.com
/// Matches the implementation from VCareAPIManager.swift
class VCareAPIManager {
  static final VCareAPIManager _instance = VCareAPIManager._internal();
  factory VCareAPIManager() => _instance;
  VCareAPIManager._internal();

  // API Credentials - matching Swift implementation
  final String _vendorId = 'LinkUpMobileIncDeepthi';
  final String _username = 'LinkUpMobileIncDeepthi8x7dUser';
  final String _password = 'LinkUpMoffrh9p874wmu';
  final String _pin = '713330914440';
  final String _baseURL = 'https://www.vcareapi.com:8080';

  /// Generate a unique external transaction ID for API calls
  /// Format: {OrderID}{Action}{Timestamp}
  static String generateTransactionId(String orderId, String action) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '${orderId}${action}$timestamp';
  }

  /// Generate a random unique transaction ID
  /// Format: alphanumeric characters and numbers only (as required by API)
  static String generateRandomTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Generate random alphanumeric string (10 characters)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randomString = String.fromCharCodes(
      Iterable.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    
    // Combine random string with timestamp for uniqueness
    return '${randomString}$timestamp';
  }

  /// Authenticate and get access token
  /// Always generates a fresh token for each API call (matching Swift implementation)
  Future<String> authenticate() async {
    // Prepare request body
    final parameters = {
      'vendor_id': _vendorId,
      'username': _username,
      'password': _password,
      'pin': _pin,
    };

    try {
      final uri = Uri.parse('$_baseURL/authenticate');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(parameters),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'Authentication failed with status code: ${response.statusCode}');
      }

      // Parse response
      final responseString = response.body;
      print('✅ VCare API Authentication Response: $responseString');

      // Try to parse JSON response to extract token
      try {
        final json = jsonDecode(responseString) as Map<String, dynamic>;
        if (json.containsKey('token')) {
          final token = json['token'] as String;
          return token;
        } else if (json.containsKey('access_token')) {
          final token = json['access_token'] as String;
          return token;
        }
      } catch (e) {
        // If JSON parsing fails, try as plain text
        if (responseString.isNotEmpty) {
          return responseString.trim();
        }
      }

      throw Exception('Failed to parse token from response');
    } catch (e) {
      print('❌ Authentication failed: $e');
      rethrow;
    }
  }

  /// Make an authenticated API request
  Future<http.Response> makeAuthenticatedRequest({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    // Ensure we have a valid token
    final token = await authenticate();

    // Build URL
    final fullEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$_baseURL$fullEndpoint');

    try {
      // Create request
      final request = http.Request(method, uri);
      request.headers['Content-Type'] = 'application/json';
      // Use "token" header as per API documentation (not Authorization: Bearer)
      request.headers['token'] = token;

      if (body != null) {
        request.body = jsonEncode(body);
      }

      // Make request
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        // If unauthorized, try again once with fresh token
        return makeAuthenticatedRequest(
          endpoint: endpoint,
          method: method,
          body: body,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'API request failed with status code: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      print('❌ API request failed: $e');
      rethrow;
    }
  }

  /// Make an authenticated POST request with JSON body
  Future<http.Response> post({
    required String endpoint,
    required Map<String, dynamic> parameters,
  }) async {
    return makeAuthenticatedRequest(
      endpoint: endpoint,
      method: 'POST',
      body: parameters,
    );
  }

  /// Make an authenticated GET request
  Future<http.Response> get(String endpoint) async {
    return makeAuthenticatedRequest(
      endpoint: endpoint,
      method: 'GET',
    );
  }

  /// Get list of available plans
  /// Matches the Swift implementation's getPlanList method
  Future<List<Plan>> getPlanList({
    required String zipCode,
    String enrollmentType = 'NON_LIFELINE',
    String isFamilyPlan = 'N',
    String? planId,
    String agentId = 'Sushil',
    String? externalTransactionId,
    String source = 'WEBSITE',
  }) async {
    // Validate zip code (must be 5 digits)
    if (zipCode.length != 5 || !RegExp(r'^\d{5}$').hasMatch(zipCode)) {
      throw Exception('Invalid zip code. Must be exactly 5 digits.');
    }

    // Prepare parameters
    final parameters = <String, dynamic>{
      'action': 'plan_list',
      'zip_code': zipCode,
      'enrollment_type': enrollmentType,
      'is_family_plan': isFamilyPlan,
      'agent_id': agentId,
      'source': source,
      'plan_id': planId ?? '',
    };

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/plan',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 Plans API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;

      // First check if this is an error response (no data field)
      final msgCode = json['msg_code'] as String?;
      if (msgCode != null && msgCode != 'RESTAPI000') {
        final msg = json['msg'] as String? ?? 'Unknown error';
        final token = json['token'] as String? ?? '';
        
        print('❌ Plans API Error Response:');
        print('   msg_code: $msgCode');
        print('   msg: $msg');
        print('   token: $token');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        throw Exception(msg);
      }

      // Decode response - handle both string and int for plan_id, plan_price, etc.
      final dataList = json['data'] as List<dynamic>?;
      if (dataList == null) {
        print('⚠️ No plans found in response');
        return [];
      }

      final List<Plan> plans = [];
      for (final item in dataList) {
        try {
          plans.add(Plan.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          print('⚠️ Failed to parse plan: $e');
        }
      }

      print('✅ Plans API Success:');
      print('   msg_code: $msgCode');
      print('   plans count: ${plans.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Print each plan's details
      if (plans.isNotEmpty) {
        print('📋 Plans Details:');
        for (var i = 0; i < plans.length; i++) {
          final plan = plans[i];
          print('   Plan ${i + 1}:');
          print('      plan_id: ${plan.planId}');
          print('      plan_name: ${plan.planName}');
          print('      plan_price: ${plan.planPrice}');
          print('      total_plan_price: ${plan.totalPlanPrice}');
          print('      ──────────────────────────────────────────────');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      return plans;
    } catch (e) {
      print('❌ Failed to get plan list: $e');
      rethrow;
    }
  }

  /// Get city and state from ZIP code
  /// Matches the Swift implementation's getCityState method
  Future<({String city, String state})> getCityState({
    required String zipCode,
    String agentId = 'Sushil',
    String source = 'API',
  }) async {
    // Validate zip code (must be 5 digits)
    if (zipCode.length != 5 || !RegExp(r'^\d{5}$').hasMatch(zipCode)) {
      throw Exception('Invalid zip code. Must be exactly 5 digits.');
    }

    // Prepare parameters
    final parameters = <String, dynamic>{
      'action': 'get_city_state',
      'zip_code': zipCode,
      'agent_id': agentId,
      'source': source,
    };

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/address',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 City/State API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;

      final msgCode = json['msg_code'] as String?;
      if (msgCode == 'RESTAPI000') {
        final dataDict = json['data'] as Map<String, dynamic>?;
        if (dataDict != null) {
          final city = dataDict['city'] as String? ?? '';
          final state = dataDict['state'] as String? ?? '';
          print('✅ City/State API Success:');
          print('   city: $city');
          print('   state: $state');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return (city: city, state: state);
        }
      }

      final msg = json['msg'] as String? ?? 'Failed to get city and state';
      print('❌ City/State API Error: $msg');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      throw Exception(msg);
    } catch (e) {
      print('❌ Failed to get city and state: $e');
      rethrow;
    }
  }

  /// Check device compatibility by IMEI
  Future<DeviceCompatibilityData> checkDeviceCompatibility({
    required String imei,
    required String carrier,
    String agentId = 'Sushil',
    String source = 'API',
    String? externalTransactionId,
  }) async {
    // Validate IMEI (should be 15 digits)
    final digitsOnly = imei.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length != 15) {
      throw Exception('Invalid IMEI. Must be exactly 15 digits.');
    }

    // Determine action based on carrier
    final action = carrier.toUpperCase() == 'TMB'
        ? 'get_query_device'
        : 'check_device_compatibility';

    // Prepare parameters
    final parameters = <String, dynamic>{
      'action': action,
      'agent_id': agentId,
      'source': source,
      'carrier': carrier,
      'imei': digitsOnly,
    };

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/inventory',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 Device Compatibility API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;
      
      // Print formatted API response structure for debugging
      print('📦 Parsed API Response JSON Structure:');
      print('   msg_code: ${json['msg_code']}');
      print('   msg: ${json['msg']}');
      print('   data: ${json.containsKey('data') ? 'present' : 'missing'}');
      if (json.containsKey('data') && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>?;
        print('   data fields: ${data?.keys.toList().join(', ')}');
        if (data != null) {
          data.forEach((key, value) {
            if (value is Map) {
              print('   $key: Map with keys [${(value as Map).keys.toList().join(', ')}]');
            } else if (value is List) {
              print('   $key: List with ${(value as List).length} items');
            } else {
              print('   $key: $value');
            }
          });
        }
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final msgCode = json['msg_code'] as String?;
      if (msgCode != 'RESTAPI000') {
        final msg = json['msg'] as String? ?? 'Failed to check device compatibility';
        print('❌ Device Compatibility API Error: $msg');
        throw Exception(msg);
      }

      DeviceCompatibilityData? compatibilityData;

      // First, check if data has flat structure with COMPATIBILITY, NAME, etc. at top level
      final data = json['data'] as Map<String, dynamic>?;
      
      // Print detailed structure information for debugging
      print('🔍 Parsing API Response Structure:');
      print('   Data keys: ${data?.keys.toList()}');
      if (data != null && data.containsKey('RESULT')) {
        final result = data['RESULT'] as Map<String, dynamic>?;
        print('   RESULT keys: ${result?.keys.toList()}');
        if (result != null && result.containsKey('deviceInfo')) {
          print('   ✅ Found RESULT.deviceInfo (nested structure)');
        } else if (result != null && result.containsKey('responseDetails')) {
          print('   ✅ Found RESULT.responseDetails (alternative nested structure)');
        }
      }
      
      // Check if this looks like a flat structure (has COMPATIBILITY, NAME, IMEI at top level)
      final isFlatStructure = data != null && 
          (data.containsKey('COMPATIBILITY') || 
           data.containsKey('NAME') || 
           data.containsKey('IMEI'));
      
      // Check if this looks like nested structure (has RESULT.deviceInfo)
      final nestedResult = data?['RESULT'] as Map<String, dynamic>?;
      final isNestedStructure = nestedResult?['deviceInfo'] != null;
      
      print('   Structure detection:');
      print('   - isFlatStructure: $isFlatStructure');
      print('   - isNestedStructure: $isNestedStructure');

      if (isFlatStructure && !isNestedStructure) {
        // Try flat structure first if it looks like flat format
        print('✅ Device Compatibility API Response (Flat Structure):');
        print('   msg_code: $msgCode');
        print('   msg: ${json['msg']}');
        
        try {
          compatibilityData = DeviceCompatibilityData.fromJson(data!);
        } catch (e) {
          print('⚠️ Failed to parse flat structure: $e');
        }
      } else if (isNestedStructure) {
        // Try nested structure (QueryDeviceResponse format)
        try {
          final queryResponse = QueryDeviceResponse.fromJson(json);
          print('✅ Query Device API Response:');
          print('   msg_code: ${queryResponse.msgCode}');
          print('   msg: ${queryResponse.msg}');

          if (queryResponse.msgCode == 'RESTAPI000' && queryResponse.data != null) {
            print('📋 Attempting to parse nested QueryDeviceData...');
            compatibilityData = DeviceCompatibilityData.fromQueryDeviceData(queryResponse.data!);
            if (compatibilityData != null) {
              print('   ✅ Successfully parsed nested structure');
            } else {
              print('   ❌ fromQueryDeviceData returned null (no deviceInfo found)');
            }
          }
        } catch (e) {
          print('⚠️ Failed to decode as nested structure: $e');
        }
      }

      // Fall back to flat structure if nested parsing failed or returned null
      if (compatibilityData == null && data != null) {
        print('⚠️ Trying flat structure parsing as fallback...');
        try {
          print('✅ Device Compatibility API Response (Flat Structure):');
          print('   msg_code: $msgCode');
          print('   msg: ${json['msg']}');

          compatibilityData = DeviceCompatibilityData.fromJson(data);
          
          print('📋 Parsed flat structure data:');
          print('   COMPATIBILITY: ${compatibilityData?.compatibility}');
          print('   NAME: ${compatibilityData?.name}');
          print('   MODEL: ${compatibilityData?.model}');
          print('   MANUFACTURER: ${compatibilityData?.manufacturer}');
          print('   IMEI: ${compatibilityData?.imei}');
          print('   ESIM: ${compatibilityData?.esim}');
          print('   SIMSLOTS: ${compatibilityData?.simSlots}');
          
          // Try to extract additional info from nested RESULT structure if available
          // This handles the case where response has both flat fields and nested RESULT.responseDetails
          if (compatibilityData != null) {
            final result = data['RESULT'] as Map<String, dynamic>?;
            if (result != null) {
              try {
                final responseDetails = result['responseDetails'] as Map<String, dynamic>?;
                if (responseDetails != null) {
                  final inquireResponse = responseDetails['inquireDeviceStatusResponse'] as Map<String, dynamic>?;
                  if (inquireResponse != null) {
                    final deviceStatus = inquireResponse['deviceStatusDetails'] as Map<String, dynamic>?;
                    if (deviceStatus != null) {
                      // Extract manufacturer if not already set
                      if (compatibilityData.manufacturer == null || compatibilityData.manufacturer!.isEmpty) {
                        final manufacturer = deviceStatus['manufacturer'] as Map<String, dynamic>?;
                        if (manufacturer != null) {
                          final make = manufacturer['make']?.toString();
                          if (make != null && make.isNotEmpty) {
                            // Create new instance with manufacturer extracted
                            compatibilityData = DeviceCompatibilityData(
                              band12Compatible: compatibilityData.band12Compatible,
                              bands: compatibilityData.bands,
                              chipsetModel: compatibilityData.chipsetModel,
                              chipsetName: compatibilityData.chipsetName,
                              chipsetVendor: compatibilityData.chipsetVendor,
                              compatibility: compatibilityData.compatibility,
                              description: compatibilityData.description,
                              deviceType: compatibilityData.deviceType,
                              dualBandWifi: compatibilityData.dualBandWifi,
                              esim: compatibilityData.esim,
                              gprs: compatibilityData.gprs,
                              hdVoice: compatibilityData.hdVoice,
                              hsdpa: compatibilityData.hsdpa,
                              hspa: compatibilityData.hspa,
                              imei: compatibilityData.imei,
                              ims: compatibilityData.ims,
                              ipv6: compatibilityData.ipv6,
                              lte: compatibilityData.lte,
                              lteAdvanced: compatibilityData.lteAdvanced,
                              lteCategory: compatibilityData.lteCategory,
                              manufacturer: make,
                              marketingName: compatibilityData.marketingName,
                              model: deviceStatus['model']?.toString() ?? compatibilityData.model,
                              name: compatibilityData.name,
                              networkCompatible: compatibilityData.networkCompatible,
                              networkTechnology: compatibilityData.networkTechnology,
                              nonStandalone5G: compatibilityData.nonStandalone5G,
                              osName: compatibilityData.osName,
                              passpoint: compatibilityData.passpoint,
                              primaryHardwareType: compatibilityData.primaryHardwareType,
                              remoteSimUnlock: compatibilityData.remoteSimUnlock,
                              roamingIms: compatibilityData.roamingIms,
                              simSize: compatibilityData.simSize,
                              simSlots: compatibilityData.simSlots,
                              standalone5G: compatibilityData.standalone5G,
                              statusCode: compatibilityData.statusCode,
                              tac: compatibilityData.tac,
                              technologyOnTheDevice: compatibilityData.technologyOnTheDevice,
                              tmobileApproved: compatibilityData.tmobileApproved,
                              umts: compatibilityData.umts,
                              volte: compatibilityData.volte,
                              volteCompatible: compatibilityData.volteCompatible,
                              volteEmergencyCalling: compatibilityData.volteEmergencyCalling,
                              vonrCompatible: compatibilityData.vonrCompatible,
                              vowifi: compatibilityData.vowifi,
                              wifi: compatibilityData.wifi,
                              wifiCallingVersion: compatibilityData.wifiCallingVersion,
                              wifiCompatible: compatibilityData.wifiCompatible,
                              wlan: compatibilityData.wlan,
                              yearReleased: compatibilityData.yearReleased,
                            );
                          }
                        }
                      }
                      
                      // Try to extract model if not set
                      if ((compatibilityData.model == null || compatibilityData.model!.isEmpty) &&
                          compatibilityData.name != null) {
                        // NAME might contain model (e.g., "SAMSNG SM-G973U1")
                        final nameParts = compatibilityData.name!.split(' ');
                        if (nameParts.length > 1) {
                          // Assume last part is model
                          compatibilityData = DeviceCompatibilityData(
                            band12Compatible: compatibilityData.band12Compatible,
                            bands: compatibilityData.bands,
                            chipsetModel: compatibilityData.chipsetModel,
                            chipsetName: compatibilityData.chipsetName,
                            chipsetVendor: compatibilityData.chipsetVendor,
                            compatibility: compatibilityData.compatibility,
                            description: compatibilityData.description,
                            deviceType: compatibilityData.deviceType,
                            dualBandWifi: compatibilityData.dualBandWifi,
                            esim: compatibilityData.esim,
                            gprs: compatibilityData.gprs,
                            hdVoice: compatibilityData.hdVoice,
                            hsdpa: compatibilityData.hsdpa,
                            hspa: compatibilityData.hspa,
                            imei: compatibilityData.imei,
                            ims: compatibilityData.ims,
                            ipv6: compatibilityData.ipv6,
                            lte: compatibilityData.lte,
                            lteAdvanced: compatibilityData.lteAdvanced,
                            lteCategory: compatibilityData.lteCategory,
                            manufacturer: compatibilityData.manufacturer,
                            marketingName: compatibilityData.marketingName,
                            model: nameParts.last,
                            name: compatibilityData.name,
                            networkCompatible: compatibilityData.networkCompatible,
                            networkTechnology: compatibilityData.networkTechnology,
                            nonStandalone5G: compatibilityData.nonStandalone5G,
                            osName: compatibilityData.osName,
                            passpoint: compatibilityData.passpoint,
                            primaryHardwareType: compatibilityData.primaryHardwareType,
                            remoteSimUnlock: compatibilityData.remoteSimUnlock,
                            roamingIms: compatibilityData.roamingIms,
                            simSize: compatibilityData.simSize,
                            simSlots: compatibilityData.simSlots,
                            standalone5G: compatibilityData.standalone5G,
                            statusCode: compatibilityData.statusCode,
                            tac: compatibilityData.tac,
                            technologyOnTheDevice: compatibilityData.technologyOnTheDevice,
                            tmobileApproved: compatibilityData.tmobileApproved,
                            umts: compatibilityData.umts,
                            volte: compatibilityData.volte,
                            volteCompatible: compatibilityData.volteCompatible,
                            volteEmergencyCalling: compatibilityData.volteEmergencyCalling,
                            vonrCompatible: compatibilityData.vonrCompatible,
                            vowifi: compatibilityData.vowifi,
                            wifi: compatibilityData.wifi,
                            wifiCallingVersion: compatibilityData.wifiCallingVersion,
                            wifiCompatible: compatibilityData.wifiCompatible,
                            wlan: compatibilityData.wlan,
                            yearReleased: compatibilityData.yearReleased,
                          );
                        }
                      }
                    }
                  }
                }
              } catch (e3) {
                // Silently continue if we can't extract nested info
                print('⚠️ Could not extract additional info from nested structure: $e3');
              }
            }
          }
        } catch (e2) {
          print('❌ Failed to decode as both nested and flat structure: $e2');
          throw Exception('Failed to parse device compatibility data: $e2');
        }
      }

      if (compatibilityData == null) {
        throw Exception('Failed to parse device compatibility data');
      }

      print('✅ Device Compatibility API Success:');
      print('   Device: ${compatibilityData.marketingName ?? compatibilityData.model ?? "Unknown"}');
      print('   Manufacturer: ${compatibilityData.manufacturer ?? "Unknown"}');
      print('   Compatibility: ${compatibilityData.compatibility ?? "Unknown"}');
      print('   Is Compatible: ${compatibilityData.isCompatible}');
      print('   Supports eSIM: ${compatibilityData.supportsESIM}');
      print('   Supports Physical SIM: ${compatibilityData.supportsPhysicalSIM}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return compatibilityData;
    } catch (e) {
      print('❌ Failed to check device compatibility: $e');
      rethrow;
    }
  }

  /// Validate port-in eligibility for a phone number
  Future<PortInValidationData> validatePortIn({
    required String mdn,
    required String carrier,
    String? zipCode,
    String agentId = 'Sushil',
    String source = 'API',
    String? externalTransactionId,
  }) async {
    print('🔍 ========================================');
    print('🔍 VALIDATE PORT-IN API CALL');
    print('🔍 ========================================');
    
    // Validate MDN (should be 10 digits, remove formatting)
    final digitsOnly = mdn.replaceAll(RegExp(r'[^0-9]'), '');
    print('📱 Input MDN: $mdn');
    print('📱 Cleaned MDN (digits only): $digitsOnly');
    
    if (digitsOnly.length != 10) {
      print('❌ Invalid phone number length: ${digitsOnly.length} (expected 10)');
      throw Exception('Invalid phone number. Must be exactly 10 digits.');
    }

    // Prepare parameters
    final parameters = <String, dynamic>{
      'action': 'validate_portin',
      'mdn': digitsOnly,
      'carrier': carrier,
      'agent_id': agentId,
      'source': source,
    };

    if (zipCode != null && zipCode.isNotEmpty) {
      parameters['zip_code'] = zipCode;
    }

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    print('📤 Request Parameters:');
    parameters.forEach((key, value) {
      print('   $key: $value');
    });
    print('🔍 ========================================');

    try {
      // Make authenticated request
      print('📡 Making authenticated POST request to /inventory...');
      final response = await post(
        endpoint: '/inventory',
        parameters: parameters,
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');

      // Print raw API response
      final responseString = response.body;
      print('📡 Port-In Validation API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      print('🔍 Parsing JSON response...');
      final json = jsonDecode(responseString) as Map<String, dynamic>;
      
      print('📋 Parsed JSON Structure:');
      print('   Keys: ${json.keys.toList()}');
      json.forEach((key, value) {
        if (value is Map) {
          print('   $key: Map with keys [${(value as Map).keys.toList().join(', ')}]');
        } else if (value is List) {
          print('   $key: List with ${(value as List).length} items');
        } else {
          print('   $key: $value');
        }
      });

      final msgCode = json['msg_code'] as String?;
      final msg = json['msg'] as String?;
      
      print('📋 Response Summary:');
      print('   msg_code: $msgCode');
      print('   msg: $msg');
      
      if (msgCode == 'RESTAPI000') {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          print('✅ Success response (msg_code = RESTAPI000)');
          print('📋 Data object keys: ${data.keys.toList()}');
          print('📋 Data object content:');
          data.forEach((key, value) {
            if (key == 'RESULT' && value is Map) {
              print('   $key: Map with keys [${(value as Map).keys.toList().join(', ')}]');
              final result = value as Map<String, dynamic>;
              if (result.containsKey('responseDetails')) {
                final responseDetails = result['responseDetails'] as Map<String, dynamic>?;
                if (responseDetails != null) {
                  print('      responseDetails keys: [${responseDetails.keys.toList().join(', ')}]');
                  final eligibilityFlag = responseDetails['eligibilityFlag'];
                  print('      eligibilityFlag: $eligibilityFlag');
                }
              }
            } else {
              print('   $key: $value');
            }
          });
          
          print('🔍 Parsing validation data from JSON...');
          final validationData = PortInValidationData.fromJson(data);
          print('✅ Parsed validation data:');
          print('   portInStatus: ${validationData.portInStatus ?? "null"}');
          print('   (extracted from eligibilityFlag if available)');
          print('✅ Port-In Validation API Success:');
          print('   PORTINSTATUS: ${validationData.portInStatus ?? "null"}');
          print('   DESCRIPTION: ${validationData.description ?? "null"}');
          print('   STATUSCODE: ${validationData.statusCode ?? -1}');
          print('   MDN: ${validationData.mdn ?? "null"}');
          print('   OLD_SERVICE_PROVIDER: ${validationData.oldServiceProvider ?? "null"}');
          print('   MSG: ${validationData.msg ?? "null"}');
          print('   MSG_CODE: ${validationData.msgCode ?? "null"}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return validationData;
        } else {
          print('⚠️ Success response but data is null');
        }
      } else {
        print('❌ Error response (msg_code != RESTAPI000)');
      }

      // Extract error message
      var errorMessage = msg ?? 'Validation failed';
      if (json['errors'] != null) {
        final errors = json['errors'] as List<dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          print('❌ Errors array found:');
          for (var i = 0; i < errors.length; i++) {
            print('   Error $i: ${errors[i]}');
          }
          final firstError = errors.first.toString();
          final errorParts = firstError.split('|');
          if (errorParts.isNotEmpty) {
            errorMessage = errorParts.first.trim();
          }
        }
      }

      print('❌ Port-In Validation API Error:');
      print('   msg_code: $msgCode');
      print('   msg: $errorMessage');
      print('   Full error response: $json');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('❌ Exception in validatePortIn:');
      print('   Error: $e');
      print('   Stack Trace:');
      print(stackTrace);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Check service availability for a zip code
  Future<ServiceAvailabilityData> checkServiceAvailability({
    required String zipCode,
    String enrollmentType = 'NON_LIFELINE',
    String isEnrollment = 'Y',
    String agentId = 'Sushil',
    String source = 'WEBSITE',
    String? externalTransactionId,
  }) async {
    // Validate zip code (must be 5 digits)
    if (zipCode.length != 5 || !RegExp(r'^\d{5}$').hasMatch(zipCode)) {
      throw Exception('Invalid zip code. Must be exactly 5 digits.');
    }

    // Prepare parameters
    final parameters = <String, dynamic>{
      'action': 'check_service_availability',
      'zip_code': zipCode,
      'enrollment_type': enrollmentType,
      'is_enrollment': isEnrollment,
      'agent_id': agentId,
      'source': source,
    };

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/enrollment',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 Service Availability API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;

      final msgCode = json['msg_code'] as String?;
      if (msgCode == 'RESTAPI000') {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          final availabilityData = ServiceAvailabilityData.fromJson(data);
          print('✅ Service Availability API Success:');
          print('   enrollment_id: ${availabilityData.enrollmentId ?? "nil"}');
          print('   city: ${availabilityData.city ?? "nil"}');
          print('   state: ${availabilityData.state ?? "nil"}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return availabilityData;
        }
      }

      var errorMessage = json['msg'] as String? ?? 'Service availability check failed';
      if (msgCode != 'RESTAPI000') {
        if (errorMessage.contains('We do not provide services')) {
          errorMessage = 'Services are not available for this zip code.';
        } else if (errorMessage.contains('Invalid zip code')) {
          errorMessage = 'Invalid zip code. Please enter a valid 5-digit zip code.';
        }
      }

      print('❌ Service Availability API Error: $errorMessage');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Failed to check service availability: $e');
      rethrow;
    }
  }

  /// Create customer prepaid multiline order
  Future<CreateCustomerResponse> createCustomerPrepaidMultiline({
    required String enrollmentId,
    int? orderId,
    required int planId,
    required Map<String, dynamic> customerInfo,
    String agentId = 'Sushil',
    String source = 'API',
    String? externalTransactionId,
  }) async {
    // Build the lines array - for now, single line order
    final line = <String, dynamic>{
      'enrollment_id': enrollmentId,
      'plan_id': planId,
      'activation_type': customerInfo['activation_type'] ?? 'NEWACTIVATION',
      'enrollment_type': customerInfo['enrollment_type'] ?? 'SHIPMENT',
      'carrier': customerInfo['carrier'] ?? 'TMBRLY',
      'email': customerInfo['email'] ?? '',
      'first_name': customerInfo['first_name'] ?? '',
      'last_name': customerInfo['last_name'] ?? '',
      'service_address_one': customerInfo['service_address_one'] ?? '',
      'service_city': customerInfo['service_city'] ?? '',
      'service_state': customerInfo['service_state'] ?? '',
      'service_zip': customerInfo['service_zip'] ?? '',
      'billing_address_one': customerInfo['billing_address_one'] ?? '',
      'billing_city': customerInfo['billing_city'] ?? '',
      'billing_state': customerInfo['billing_state'] ?? '',
      'billing_zip': customerInfo['billing_zip'] ?? '',
      'notify_bill_via_text': customerInfo['notify_bill_via_text'] ?? 'Y',
      'notify_bill_via_email': customerInfo['notify_bill_via_email'] ?? 'Y',
    };

    if (orderId != null) {
      line['order_id'] = orderId;
    }

    if (customerInfo['password'] != null && (customerInfo['password'] as String).isNotEmpty) {
      line['password'] = customerInfo['password'];
    }

    if (customerInfo['middle_initial'] != null &&
        (customerInfo['middle_initial'] as String).isNotEmpty) {
      line['middle_initial'] = customerInfo['middle_initial'];
    }

    if (customerInfo['alternate_phone_number'] != null &&
        (customerInfo['alternate_phone_number'] as String).isNotEmpty) {
      line['alternate_phone_number'] = customerInfo['alternate_phone_number'];
    }

    if (customerInfo['service_address_two'] != null &&
        (customerInfo['service_address_two'] as String).isNotEmpty) {
      line['service_address_two'] = customerInfo['service_address_two'];
    }

    if (customerInfo['billing_address_two'] != null &&
        (customerInfo['billing_address_two'] as String).isNotEmpty) {
      line['billing_address_two'] = customerInfo['billing_address_two'];
    }

    // SIM type
    if (customerInfo['is_esim'] != null) {
      line['is_esim'] = customerInfo['is_esim'];
    }

    // Port-in information (if activation_type is PORTIN)
    final activationType = line['activation_type'] as String;
    if (activationType == 'PORTIN') {
      if (customerInfo['port_current_carrier'] != null) {
        line['port_current_carrier'] = customerInfo['port_current_carrier'];
      }
      if (customerInfo['port_first_name'] != null) {
        line['port_first_name'] = customerInfo['port_first_name'];
      }
      if (customerInfo['port_last_name'] != null) {
        line['port_last_name'] = customerInfo['port_last_name'];
      }
      if (customerInfo['port_address_one'] != null) {
        line['port_address_one'] = customerInfo['port_address_one'];
      }
      if (customerInfo['port_address_two'] != null) {
        line['port_address_two'] = customerInfo['port_address_two'];
      }
      if (customerInfo['port_city'] != null) {
        line['port_city'] = customerInfo['port_city'];
      }
      if (customerInfo['port_state'] != null) {
        line['port_state'] = customerInfo['port_state'];
      }
      if (customerInfo['port_zip_code'] != null) {
        line['port_zip_code'] = customerInfo['port_zip_code'];
      }
      if (customerInfo['port_account_number'] != null) {
        line['port_account_number'] = customerInfo['port_account_number'];
      }
      if (customerInfo['port_account_password'] != null) {
        line['port_account_password'] = customerInfo['port_account_password'];
      }
      if (customerInfo['port_number'] != null) {
        line['port_number'] = customerInfo['port_number'];
      }
      if (customerInfo['port_ssn'] != null) {
        line['port_ssn'] = customerInfo['port_ssn'];
      }
    }

    // Shipping ID (if available)
    if (customerInfo['shipping_id'] != null) {
      line['shipping_id'] = customerInfo['shipping_id'];
    }

    // Security questions (if available)
    if (customerInfo['security_questions_answers'] != null) {
      line['security_questions_answers'] = customerInfo['security_questions_answers'];
    }

    // Build request parameters
    final parameters = <String, dynamic>{
      'lines': [line],
      'parent_enrollment_id': enrollmentId,
      'action': 'create_customer_prepaid_multiline',
      'source': source,
      'sub_source': 'plans',
      'request_name': 'customer',
      'agent_id': agentId,
    };

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    if (customerInfo['coupon_code'] != null &&
        (customerInfo['coupon_code'] as String).isNotEmpty) {
      parameters['coupon_code'] = customerInfo['coupon_code'];
    }

    try {
      // Create request with 50 second timeout
      final token = await authenticate();
      final uri = Uri.parse('$_baseURL/customer');

      // Print request for debugging
      print('📡 Create Customer API Request:');
      print(jsonEncode(parameters));
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['token'] = token;
      request.body = jsonEncode(parameters);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 50));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'API request failed with status code: ${response.statusCode}');
      }

      // Print raw response
      final responseString = response.body;
      print('📡 Create Customer API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;
      final createResponse = CreateCustomerResponse.fromJson(json);

      print('✅ Create Customer API Response:');
      print('   msg_code: ${createResponse.msgCode}');
      print('   msg: ${createResponse.msg}');

      if (createResponse.msgCode == 'RESTAPI000') {
        if (createResponse.data != null) {
          for (var i = 0; i < createResponse.data!.length; i++) {
            final lineResponse = createResponse.data![i];
            if (lineResponse.data != null) {
              print('   Line ${i + 1}:');
              print('      cust_id: ${lineResponse.data!.custId ?? -1}');
              print('      enrollment_id: ${lineResponse.data!.enrollmentId ?? "nil"}');
              print('      mdn: ${lineResponse.data!.mdn ?? "nil"}');
            }
          }
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return createResponse;
      } else {
        print('❌ Create Customer API Error: ${createResponse.msg}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(createResponse.msg);
      }
    } catch (e) {
      print('❌ Failed to create customer: $e');
      rethrow;
    }
  }

  /// Validate address with USPS
  Future<USPSAddressData> validateAddressUSPS({
    String? enrollmentId,
    required String addressOne,
    String addressTwo = '',
    required String city,
    required String state,
    required String zipCode,
    String agentId = 'Sushil',
    String source = 'WEBSITE',
  }) async {
    // Validate required fields
    if (addressOne.isEmpty || city.isEmpty || state.isEmpty) {
      throw Exception('Address, city, and state are required.');
    }

    // Validate zip code (must be 5 digits)
    if (zipCode.length != 5 || !RegExp(r'^\d{5}$').hasMatch(zipCode)) {
      throw Exception('Invalid zip code. Must be exactly 5 digits.');
    }

    // Prepare parameters
    final parameters = <String, dynamic>{
      'address_one': addressOne,
      'address_two': addressTwo,
      'city': city.toUpperCase(),
      'state': state.toUpperCase(),
      'zip_code': zipCode,
      'action': 'address_validation_usps',
      'agent_id': agentId,
      'source': source,
    };

    // Add enrollment_id if provided
    if (enrollmentId != null && enrollmentId.isNotEmpty) {
      parameters['enrollment_id'] = enrollmentId;
    }

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/address',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 USPS Address Validation API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;

      final msgCode = json['msg_code'] as String?;
      if (msgCode == 'RESTAPI000') {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          final addressData = USPSAddressData.fromJson(data);
          print('✅ USPS Address Validation API Success:');
          print('   Validated Address:');
          print('      Address1: ${addressData.address1 ?? "nil"}');
          print('      Address2: ${addressData.address2 ?? "nil"}');
          print('      City: ${addressData.city ?? "nil"}');
          print('      State: ${addressData.state ?? "nil"}');
          print('      Zip5: ${addressData.zip5 ?? "nil"}');
          print('      Zip4: ${addressData.zip4 ?? "nil"}');
          print('      DPVConfirmation: ${addressData.dpvConfirmation ?? "nil"}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return addressData;
        }
      }

      // Extract detailed error message from errors array if available
      var errorMessage = json['msg'] as String? ?? 'Address validation failed';
      if (json['errors'] != null) {
        final errors = json['errors'] as List<dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          errorMessage = errors.first.toString();
        }
      }

      print('❌ USPS Address Validation API Error:');
      print('   msg_code: $msgCode');
      print('   msg: ${json['msg']}');
      if (json['errors'] != null) {
        print('   errors: ${json['errors']}');
      }
      print('   Final error message: $errorMessage');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Failed to validate address: $e');
      rethrow;
    }
  }

  /// Get list of port-in orders for an enrollment
  /// This API is used to fetch the port_subscriber_id needed for submit_portin
  Future<PortInListResponse> getPortInList({
    required String enrollId,
    String agentId = 'Sushil',
    String source = 'WEBSITE',
    String? externalTransactionId,
    String getChildList = 'N',
  }) async {
    print('🔍 ========================================');
    print('🔍 GET PORT-IN LIST API CALL');
    print('🔍 ========================================');

    // Prepare parameters
    final parameters = <String, dynamic>{
      'action': 'get_list',
      'enroll_id': enrollId,
      'source': source,
      'agent_id': agentId,
    };

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    if (getChildList.isNotEmpty) {
      parameters['get_child_list'] = getChildList;
    }

    print('📤 Request Parameters:');
    parameters.forEach((key, value) {
      print('   $key: $value');
    });
    print('🔍 ========================================');

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/port',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 Get Port-In List API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;
      final listResponse = PortInListResponse.fromJson(json);

      print('✅ Get Port-In List API Response:');
      print('   msg_code: ${listResponse.msgCode}');
      print('   msg: ${listResponse.msg}');
      print('   records count: ${listResponse.records.length}');

      if (listResponse.msgCode == 'RESTAPI000') {
        if (listResponse.records.isNotEmpty) {
          final record = listResponse.records.first;
          print('   First record:');
          print('      enrollment_id: ${record.enrollmentId ?? "nil"}');
          print('      port_subscriber_id: ${record.portSubscriberId ?? "nil"}');
          print('      portin_status: ${record.portinStatus ?? "nil"}');
        } else {
          print('   ⚠️ No records found');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return listResponse;
      } else {
        print('❌ Get Port-In List API Error: ${listResponse.msg}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(listResponse.msg);
      }
    } catch (e) {
      print('❌ Failed to get port-in list: $e');
      rethrow;
    }
  }

  /// Submit port-in request
  /// This API is called after creating a customer with PORTIN activation_type
  Future<PortInSubmitResponse> submitPortIn({
    required String enrollmentId,
    required int portinEnrollmentId,
    required String firstName,
    required String lastName,
    required String zipCode,
    required String city,
    required String state,
    required String addressOne,
    required String accountNumber,
    required String passwordPin,
    String? addressTwo,
    String? portCurrentCarrier,
    String agentId = 'Sushil',
    String source = 'WEBSITE',
    String? externalTransactionId,
  }) async {
    print('🔍 ========================================');
    print('🔍 SUBMIT PORT-IN API CALL');
    print('🔍 ========================================');

    // Prepare parameters
    final parameters = <String, dynamic>{
      'enrollment_id': enrollmentId,
      'portin_enrollment_id': portinEnrollmentId.toString(),
      'action': 'submit_portin',
      'agent_id': agentId,
      'source': source,
      'first_name': firstName,
      'last_name': lastName,
      'zip_code': zipCode,
      'city': city,
      'state': state,
      'address_one': addressOne,
      'account_number': accountNumber,
      'password_pin': passwordPin,
      'request_name': 'port',
    };

    if (addressTwo != null && addressTwo.isNotEmpty) {
      parameters['address_two'] = addressTwo;
    }

    if (portCurrentCarrier != null && portCurrentCarrier.isNotEmpty) {
      parameters['port_current_carrier'] = portCurrentCarrier;
    }

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    print('📤 Request Parameters:');
    parameters.forEach((key, value) {
      print('   $key: $value');
    });
    print('🔍 ========================================');

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/port',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 Submit Port-In API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;
      final submitResponse = PortInSubmitResponse.fromJson(json);

      print('✅ Submit Port-In API Response:');
      print('   msg_code: ${submitResponse.msgCode}');
      print('   msg: ${submitResponse.msg}');
      print('   data: ${submitResponse.data}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (submitResponse.msgCode == 'RESTAPI000') {
        return submitResponse;
      } else {
        print('❌ Submit Port-In API Error: ${submitResponse.msg}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(submitResponse.msg);
      }
    } catch (e) {
      print('❌ Failed to submit port-in: $e');
      rethrow;
    }
  }

  /// Query port-in status
  /// This API is used to check the status of a port-in request
  Future<PortInQueryResponse> queryPortIn({
    required String enrollmentId,
    String agentId = 'Sushil',
    String source = 'WEBSITE',
    String? externalTransactionId,
  }) async {
    print('🔍 ========================================');
    print('🔍 QUERY PORT-IN API CALL');
    print('🔍 ========================================');

    // Prepare parameters
    final parameters = <String, dynamic>{
      'action': 'query_portin',
      'enroll_id': enrollmentId,
      'source': source,
      'agent_id': agentId,
    };

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    print('📤 Request Parameters:');
    parameters.forEach((key, value) {
      print('   $key: $value');
    });
    print('🔍 ========================================');

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/port',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 Query Port-In API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;
      final queryResponse = PortInQueryResponse.fromJson(json);

      print('✅ Query Port-In API Response:');
      print('   msg_code: ${queryResponse.msgCode}');
      print('   msg: ${queryResponse.msg}');
      
      if (queryResponse.record != null) {
        print('   Port-In Status:');
        print('      portin_status: ${queryResponse.record!.portinStatus ?? "nil"}');
        print('      carrier_response: ${queryResponse.record!.carrierResponse ?? "nil"}');
        print('      status: ${queryResponse.record!.status ?? "nil"}');
        print('      resolution_description: ${queryResponse.record!.resolutionDescription ?? "nil"}');
      } else {
        print('   ⚠️ No port-in record found');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (queryResponse.msgCode == 'RESTAPI000') {
        return queryResponse;
      } else {
        print('❌ Query Port-In API Error: ${queryResponse.msg}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(queryResponse.msg);
      }
    } catch (e) {
      print('❌ Failed to query port-in: $e');
      rethrow;
    }
  }

  /// Update port-in information
  /// This API is used to update and resubmit port-in information when there are errors
  Future<PortInSubmitResponse> updatePortIn({
    required String enrollmentId,
    required int portinEnrollmentId,
    required String firstName,
    required String lastName,
    required String zipCode,
    required String city,
    required String state,
    required String addressOne,
    required String accountNumber,
    required String passwordPin,
    String? addressTwo,
    String? portCurrentCarrier,
    String agentId = 'Sushil',
    String source = 'WEBSITE',
    String? externalTransactionId,
  }) async {
    print('🔍 ========================================');
    print('🔍 UPDATE PORT-IN API CALL');
    print('🔍 ========================================');

    // Prepare parameters (same as submit_portin but with action: 'update_portin')
    final parameters = <String, dynamic>{
      'enrollment_id': enrollmentId,
      'portin_enrollment_id': portinEnrollmentId.toString(),
      'action': 'update_portin',
      'agent_id': agentId,
      'source': source,
      'first_name': firstName,
      'last_name': lastName,
      'zip_code': zipCode,
      'city': city,
      'state': state,
      'address_one': addressOne,
      'account_number': accountNumber,
      'password_pin': passwordPin,
      'request_name': 'port',
    };

    if (addressTwo != null && addressTwo.isNotEmpty) {
      parameters['address_two'] = addressTwo;
    }

    if (portCurrentCarrier != null && portCurrentCarrier.isNotEmpty) {
      parameters['port_current_carrier'] = portCurrentCarrier;
    }

    if (externalTransactionId != null) {
      parameters['external_transaction_id'] = externalTransactionId;
    }

    print('📤 Request Parameters:');
    parameters.forEach((key, value) {
      print('   $key: $value');
    });
    print('🔍 ========================================');

    try {
      // Make authenticated request
      final response = await post(
        endpoint: '/port',
        parameters: parameters,
      );

      // Print raw API response
      final responseString = response.body;
      print('📡 Update Port-In API Raw Response:');
      print(responseString);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response
      final json = jsonDecode(responseString) as Map<String, dynamic>;
      final updateResponse = PortInSubmitResponse.fromJson(json);

      print('✅ Update Port-In API Response:');
      print('   msg_code: ${updateResponse.msgCode}');
      print('   msg: ${updateResponse.msg}');
      print('   data: ${updateResponse.data}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (updateResponse.msgCode == 'RESTAPI000') {
        return updateResponse;
      } else {
        print('❌ Update Port-In API Error: ${updateResponse.msg}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(updateResponse.msg);
      }
    } catch (e) {
      print('❌ Failed to update port-in: $e');
      rethrow;
    }
  }
}
