part of "../data.dart";

class UserFlowStatus {
  final String currentStep;
  final int totalSteps;
  final List<UserFlowStep> steps;
  final UFlowMetadata? metadata;

  UserFlowStatus({
    required this.currentStep,
    required this.totalSteps,
    required this.steps,
    this.metadata,
  });

  factory UserFlowStatus.fromJson(Map<String, dynamic> json) => UserFlowStatus(
    currentStep: json["currentStep"],
    totalSteps: json["totalSteps"],
    steps: (json["steps"] as List<dynamic>).map((dynamic e) => UserFlowStep.fromJson(e)).toList(),
    metadata: json["metadata"] != null ? UFlowMetadata.fromJson(json["metadata"]) : null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "currentStep": currentStep,
    "totalSteps": totalSteps,
    "steps": steps.map((UserFlowStep e) => e.toJson()).toList(),
    "metadata": metadata?.toJson(),
  };
}

class UFlowMetadata {
  final String? flowId;
  final String? flowName;
  final String? version;
  final DateTime? lastUpdated;
  final String? timezone;

  UFlowMetadata({
    this.flowId,
    this.flowName,
    this.version,
    this.lastUpdated,
    this.timezone,
  });

  factory UFlowMetadata.fromJson(Map<String, dynamic> json) => UFlowMetadata(
    flowId: json["flowId"],
    flowName: json["flowName"],
    version: json["version"],
    lastUpdated: json["lastUpdated"] != null ? DateTime.parse(json["lastUpdated"]) : null,
    timezone: json["timezone"],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "flowId": flowId,
    "flowName": flowName,
    "version": version,
    "lastUpdated": lastUpdated?.toIso8601String(),
    "timezone": timezone,
  };
}

class UserFlowStep {
  final String stepId;
  final int number;
  final String title;
  final String? description;
  final String? icon;
  final String? backgroundImageUrl;
  final List<UserFlowField> fields;
  final List<UserFlowFileRequirement> files;
  final UStepNavigation? navigation;
  final List<UFieldGroup>? fieldGroups;

  UserFlowStep({
    required this.stepId,
    required this.number,
    required this.title,
    required this.fields,
    required this.files,
    this.description,
    this.icon,
    this.backgroundImageUrl,
    this.navigation,
    this.fieldGroups,
  });

  factory UserFlowStep.fromJson(Map<String, dynamic> json) => UserFlowStep(
    stepId: json["stepId"],
    number: json["number"],
    title: json["title"],
    description: json["description"],
    icon: json["icon"],
    backgroundImageUrl: json["backgroundImageUrl"],
    fields: (json["fields"] as List<dynamic>).map((dynamic e) => UserFlowField.fromJson(e)).toList(),
    files: (json["files"] as List<dynamic>).map((dynamic e) => UserFlowFileRequirement.fromJson(e)).toList(),
    navigation: json["navigation"] != null ? UStepNavigation.fromJson(json["navigation"]) : null,
    fieldGroups: json["fieldGroups"] != null ? (json["fieldGroups"] as List<dynamic>).map((dynamic e) => UFieldGroup.fromJson(e)).toList() : null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "stepId": stepId,
    "number": number,
    "title": title,
    "description": description,
    "icon": icon,
    "backgroundImageUrl": backgroundImageUrl,
    "fields": fields.map((UserFlowField e) => e.toJson()).toList(),
    "files": files.map((UserFlowFileRequirement e) => e.toJson()).toList(),
    "navigation": navigation?.toJson(),
    "fieldGroups": fieldGroups?.map((UFieldGroup e) => e.toJson()).toList(),
  };
}

class UStepNavigation {
  final String? enableNextCondition;
  final String? nextButtonLabel;
  final String? previousButtonLabel;
  final String? conditionalNextStep;
  final String? conditionalNextCondition;

  UStepNavigation({
    this.enableNextCondition,
    this.nextButtonLabel,
    this.previousButtonLabel,
    this.conditionalNextStep,
    this.conditionalNextCondition,
  });

  factory UStepNavigation.fromJson(Map<String, dynamic> json) => UStepNavigation(
    enableNextCondition: json["enableNextCondition"],
    nextButtonLabel: json["nextButtonLabel"],
    previousButtonLabel: json["previousButtonLabel"],
    conditionalNextStep: json["conditionalNextStep"],
    conditionalNextCondition: json["conditionalNextCondition"],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "enableNextCondition": enableNextCondition,
    "nextButtonLabel": nextButtonLabel,
    "previousButtonLabel": previousButtonLabel,
    "conditionalNextStep": conditionalNextStep,
    "conditionalNextCondition": conditionalNextCondition,
  };
}

class UFieldGroup {
  final String groupId;
  final String title;
  final String? description;
  final List<String> fieldNames;
  final String? layout;
  final int? columns;

  UFieldGroup({
    required this.groupId,
    required this.title,
    required this.fieldNames,
    this.description,
    this.layout,
    this.columns,
  });

  factory UFieldGroup.fromJson(Map<String, dynamic> json) => UFieldGroup(
    groupId: json["groupId"],
    title: json["title"],
    description: json["description"],
    fieldNames: List<String>.from(json["fieldNames"]),
    layout: json["layout"],
    columns: json["columns"],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "groupId": groupId,
    "title": title,
    "description": description,
    "fieldNames": fieldNames,
    "layout": layout,
    "columns": columns,
  };
}

class UserFlowField {
  final String fieldName;
  final String label;
  final UFieldType type;
  final bool isRequired;
  final String? hint;
  final String? placeholder;
  final String? defaultValue;
  final bool isDisabled;
  final bool isReadOnly;
  final bool isHidden;
  final UValidationRules? validation;
  final List<USelectOption>? options;
  final UDynamicOptionsConfig? dynamicOptions;
  final UDependencyRule? dependency;
  final UVisibilityRule? visibility;
  final String? apiEndpoint;
  final String? httpMethod;
  final Map<String, String>? apiHeaders;
  final UApiAction? onApiResponse;
  final int? debounceMs;
  final bool autoSave;
  final String? cssClass;
  final UFieldWidth width;
  final int order;

  UserFlowField({
    required this.fieldName,
    required this.label,
    required this.type,
    this.isRequired = true,
    this.hint,
    this.placeholder,
    this.defaultValue,
    this.isDisabled = false,
    this.isReadOnly = false,
    this.isHidden = false,
    this.validation,
    this.options,
    this.dynamicOptions,
    this.dependency,
    this.visibility,
    this.apiEndpoint,
    this.httpMethod = "PUT",
    this.apiHeaders,
    this.onApiResponse,
    this.debounceMs,
    this.autoSave = true,
    this.cssClass,
    this.width = UFieldWidth.full,
    this.order = 0,
  });

  factory UserFlowField.fromJson(Map<String, dynamic> json) => UserFlowField(
    fieldName: json["fieldName"],
    label: json["label"],
    type: UFieldType.values.firstWhere(
      (UFieldType e) => e.name == json["type"],
      orElse: () => UFieldType.text,
    ),
    isRequired: json["isRequired"] ?? true,
    hint: json["hint"],
    placeholder: json["placeholder"],
    defaultValue: json["defaultValue"],
    isDisabled: json["isDisabled"] ?? false,
    isReadOnly: json["isReadOnly"] ?? false,
    isHidden: json["isHidden"] ?? false,
    validation: json["validation"] != null ? UValidationRules.fromJson(json["validation"]) : null,
    options: json["options"] != null ? (json["options"] as List<dynamic>).map((dynamic e) => USelectOption.fromJson(e)).toList() : null,
    dynamicOptions: json["dynamicOptions"] != null ? UDynamicOptionsConfig.fromJson(json["dynamicOptions"]) : null,
    dependency: json["dependency"] != null ? UDependencyRule.fromJson(json["dependency"]) : null,
    visibility: json["visibility"] != null ? UVisibilityRule.fromJson(json["visibility"]) : null,
    apiEndpoint: json["apiEndpoint"],
    httpMethod: json["httpMethod"] ?? "PUT",
    apiHeaders: json["apiHeaders"] != null ? Map<String, String>.from(json["apiHeaders"]) : null,
    onApiResponse: json["onApiResponse"] != null ? UApiAction.fromJson(json["onApiResponse"]) : null,
    debounceMs: json["debounceMs"],
    autoSave: json["autoSave"] ?? true,
    cssClass: json["cssClass"],
    width: UFieldWidth.values.firstWhere(
      (UFieldWidth e) => e.name == json["width"],
      orElse: () => UFieldWidth.full,
    ),
    order: json["order"] ?? 0,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "fieldName": fieldName,
    "label": label,
    "type": type.name,
    "isRequired": isRequired,
    "hint": hint,
    "placeholder": placeholder,
    "defaultValue": defaultValue,
    "isDisabled": isDisabled,
    "isReadOnly": isReadOnly,
    "isHidden": isHidden,
    "validation": validation?.toJson(),
    "options": options?.map((USelectOption e) => e.toJson()).toList(),
    "dynamicOptions": dynamicOptions?.toJson(),
    "dependency": dependency?.toJson(),
    "visibility": visibility?.toJson(),
    "apiEndpoint": apiEndpoint,
    "httpMethod": httpMethod,
    "apiHeaders": apiHeaders,
    "onApiResponse": onApiResponse?.toJson(),
    "debounceMs": debounceMs,
    "autoSave": autoSave,
    "cssClass": cssClass,
    "width": width.name,
    "order": order,
  };
}

class UDynamicOptionsConfig {
  final String apiUrl;
  final String? responsePath;
  final String valueField;
  final String textField;
  final bool enableSearch;
  final int minCharsForSearch;

  UDynamicOptionsConfig({
    required this.apiUrl,
    this.responsePath,
    this.valueField = "value",
    this.textField = "text",
    this.enableSearch = false,
    this.minCharsForSearch = 2,
  });

  factory UDynamicOptionsConfig.fromJson(Map<String, dynamic> json) => UDynamicOptionsConfig(
    apiUrl: json["apiUrl"],
    responsePath: json["responsePath"],
    valueField: json["valueField"] ?? "value",
    textField: json["textField"] ?? "text",
    enableSearch: json["enableSearch"] ?? false,
    minCharsForSearch: json["minCharsForSearch"] ?? 2,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "apiUrl": apiUrl,
    "responsePath": responsePath,
    "valueField": valueField,
    "textField": textField,
    "enableSearch": enableSearch,
    "minCharsForSearch": minCharsForSearch,
  };
}

class UApiAction {
  final UActionType type;
  final Map<String, dynamic>? parameters;

  UApiAction({
    required this.type,
    this.parameters,
  });

  factory UApiAction.fromJson(Map<String, dynamic> json) => UApiAction(
    type: UActionType.values.firstWhere(
      (UActionType e) => e.name == json["type"],
      orElse: () => UActionType.showToast,
    ),
    parameters: json["parameters"],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "type": type.name,
    "parameters": parameters,
  };
}

enum UActionType {
  updateField,
  showToast,
  enableStep,
  disableField,
  triggerNavigation,
  refreshOptions,
}

class UValidationRules {
  final int? minLength;
  final int? maxLength;
  final int? min;
  final int? max;
  final int? exactLength;
  final String? regexPattern;
  final String? regexErrorMessage;
  final String? matchField;
  final String? customErrorMessage;
  final String? customValidatorFunction;
  final String? minDate;
  final String? maxDate;
  final bool disableFutureDates;
  final bool disablePastDates;

  UValidationRules({
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.exactLength,
    this.regexPattern,
    this.regexErrorMessage,
    this.matchField,
    this.customErrorMessage,
    this.customValidatorFunction,
    this.minDate,
    this.maxDate,
    this.disableFutureDates = false,
    this.disablePastDates = false,
  });

  factory UValidationRules.fromJson(Map<String, dynamic> json) => UValidationRules(
    minLength: json["minLength"],
    maxLength: json["maxLength"],
    min: json["min"],
    max: json["max"],
    exactLength: json["exactLength"],
    regexPattern: json["regexPattern"],
    regexErrorMessage: json["regexErrorMessage"],
    matchField: json["matchField"],
    customErrorMessage: json["customErrorMessage"],
    customValidatorFunction: json["customValidatorFunction"],
    minDate: json["minDate"],
    maxDate: json["maxDate"],
    disableFutureDates: json["disableFutureDates"] ?? false,
    disablePastDates: json["disablePastDates"] ?? false,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "minLength": minLength,
    "maxLength": maxLength,
    "min": min,
    "max": max,
    "exactLength": exactLength,
    "regexPattern": regexPattern,
    "regexErrorMessage": regexErrorMessage,
    "matchField": matchField,
    "customErrorMessage": customErrorMessage,
    "customValidatorFunction": customValidatorFunction,
    "minDate": minDate,
    "maxDate": maxDate,
    "disableFutureDates": disableFutureDates,
    "disablePastDates": disablePastDates,
  };
}

class USelectOption {
  final String value;
  final String text;
  final bool isDefault;
  final bool isDisabled;
  final String? group;
  final String? icon;

  USelectOption({
    required this.value,
    required this.text,
    this.isDefault = false,
    this.isDisabled = false,
    this.group,
    this.icon,
  });

  factory USelectOption.fromJson(Map<String, dynamic> json) => USelectOption(
    value: json["value"],
    text: json["text"],
    isDefault: json["isDefault"] ?? false,
    isDisabled: json["isDisabled"] ?? false,
    group: json["group"],
    icon: json["icon"],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "value": value,
    "text": text,
    "isDefault": isDefault,
    "isDisabled": isDisabled,
    "group": group,
    "icon": icon,
  };
}

class UDependencyRule {
  final String dependsOnField;
  final String dependsOnValue;
  final UComparisonOperator operator;
  final String? optionsApiEndpoint;
  final String? apiMethod;

  UDependencyRule({
    required this.dependsOnField,
    required this.dependsOnValue,
    this.operator = UComparisonOperator.equals,
    this.optionsApiEndpoint,
    this.apiMethod = "GET",
  });

  factory UDependencyRule.fromJson(Map<String, dynamic> json) => UDependencyRule(
    dependsOnField: json["dependsOnField"],
    dependsOnValue: json["dependsOnValue"],
    operator: UComparisonOperator.values.firstWhere(
      (UComparisonOperator e) => e.name == json["operator"],
      orElse: () => UComparisonOperator.equals,
    ),
    optionsApiEndpoint: json["optionsApiEndpoint"],
    apiMethod: json["apiMethod"] ?? "GET",
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "dependsOnField": dependsOnField,
    "dependsOnValue": dependsOnValue,
    "operator": operator.name,
    "optionsApiEndpoint": optionsApiEndpoint,
    "apiMethod": apiMethod,
  };
}

class UVisibilityRule {
  final String dependsOnField;
  final String dependsOnValue;
  final UComparisonOperator operator;
  final List<UVisibilityRule>? multipleConditions;
  final ULogicalOperator logicalOperator;

  UVisibilityRule({
    required this.dependsOnField,
    required this.dependsOnValue,
    this.operator = UComparisonOperator.equals,
    this.multipleConditions,
    this.logicalOperator = ULogicalOperator.and,
  });

  factory UVisibilityRule.fromJson(Map<String, dynamic> json) => UVisibilityRule(
    dependsOnField: json["dependsOnField"],
    dependsOnValue: json["dependsOnValue"],
    operator: UComparisonOperator.values.firstWhere(
      (UComparisonOperator e) => e.name == json["operator"],
      orElse: () => UComparisonOperator.equals,
    ),
    multipleConditions: json["multipleConditions"] != null ? (json["multipleConditions"] as List<dynamic>).map((dynamic e) => UVisibilityRule.fromJson(e)).toList() : null,
    logicalOperator: ULogicalOperator.values.firstWhere(
      (ULogicalOperator e) => e.name == json["logicalOperator"],
      orElse: () => ULogicalOperator.and,
    ),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "dependsOnField": dependsOnField,
    "dependsOnValue": dependsOnValue,
    "operator": operator.name,
    "multipleConditions": multipleConditions?.map((UVisibilityRule e) => e.toJson()).toList(),
    "logicalOperator": logicalOperator.name,
  };
}

enum UComparisonOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  isEmpty,
  isNotEmpty,
  matchesRegex,
}

enum ULogicalOperator {
  and,
  or,
}

class UserFlowFileRequirement {
  final String fileKey;
  final String label;
  final UFileType allowedFileType;
  final int maxFileSizeMB;
  final List<String>? allowedExtensions;
  final bool isRequired;
  final int? maxCount;
  final int? minCount;
  final String uploadApiEndpoint;
  final String? uploadMethod;
  final Map<String, String>? additionalFormData;
  final bool compressImage;
  final double? imageQuality;
  final int? resizeToWidth;
  final int? resizeToHeight;
  final String? cropAspectRatio;
  final bool useCamera;
  final String? deleteApiEndpoint;
  final String? previewUrlTemplate;

  UserFlowFileRequirement({
    required this.fileKey,
    required this.label,
    required this.allowedFileType,
    required this.uploadApiEndpoint,
    this.maxFileSizeMB = 5,
    this.allowedExtensions,
    this.isRequired = true,
    this.maxCount = 1,
    this.minCount,
    this.uploadMethod = "POST",
    this.additionalFormData,
    this.compressImage = false,
    this.imageQuality,
    this.resizeToWidth,
    this.resizeToHeight,
    this.cropAspectRatio,
    this.useCamera = false,
    this.deleteApiEndpoint,
    this.previewUrlTemplate,
  });

  factory UserFlowFileRequirement.fromJson(Map<String, dynamic> json) => UserFlowFileRequirement(
    fileKey: json["fileKey"],
    label: json["label"],
    allowedFileType: UFileType.values.firstWhere(
      (UFileType e) => e.name == json["allowedFileType"],
      orElse: () => UFileType.any,
    ),
    maxFileSizeMB: json["maxFileSizeMB"] ?? 5,
    allowedExtensions: json["allowedExtensions"] != null ? List<String>.from(json["allowedExtensions"]) : null,
    isRequired: json["isRequired"] ?? true,
    maxCount: json["maxCount"] ?? 1,
    minCount: json["minCount"],
    uploadApiEndpoint: json["uploadApiEndpoint"],
    uploadMethod: json["uploadMethod"] ?? "POST",
    additionalFormData: json["additionalFormData"] != null ? Map<String, String>.from(json["additionalFormData"]) : null,
    compressImage: json["compressImage"] ?? false,
    imageQuality: json["imageQuality"]?.toDouble(),
    resizeToWidth: json["resizeToWidth"],
    resizeToHeight: json["resizeToHeight"],
    cropAspectRatio: json["cropAspectRatio"],
    useCamera: json["useCamera"] ?? false,
    deleteApiEndpoint: json["deleteApiEndpoint"],
    previewUrlTemplate: json["previewUrlTemplate"],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "fileKey": fileKey,
    "label": label,
    "allowedFileType": allowedFileType.name,
    "maxFileSizeMB": maxFileSizeMB,
    "allowedExtensions": allowedExtensions,
    "isRequired": isRequired,
    "maxCount": maxCount,
    "minCount": minCount,
    "uploadApiEndpoint": uploadApiEndpoint,
    "uploadMethod": uploadMethod,
    "additionalFormData": additionalFormData,
    "compressImage": compressImage,
    "imageQuality": imageQuality,
    "resizeToWidth": resizeToWidth,
    "resizeToHeight": resizeToHeight,
    "cropAspectRatio": cropAspectRatio,
    "useCamera": useCamera,
    "deleteApiEndpoint": deleteApiEndpoint,
    "previewUrlTemplate": previewUrlTemplate,
  };
}

enum UFieldType {
  text,
  textarea,
  number,
  email,
  tel,
  password,
  url,
  select,
  multiSelect,
  radio,
  radioCard,
  checkbox,
  checkboxGroup,
  date,
  dateTime,
  time,
  month,
  week,
  range,
  color,
  file,
  multiFile,
  location,
  addressAutocomplete,
  phoneWithCountry,
  rating,
  toggle,
  button,
  creditCard,
  expiryDate,
  cvv,
  nationalCode,
  postalCode,
  iban,
  hidden,
}

enum UFileType {
  image,
  video,
  audio,
  document,
  archive,
  any,
}

enum UFieldWidth {
  full,
  half,
  third,
  quarter,
  auto,
}

class UPredefinedValidationPatterns {
  static const String iranianNationalCode = r"^[0-9]{10}$";
  static const String iranianMobilePhone = r"^09[0-9]{9}$";
  static const String iranianPhoneNumber = r"^0[0-9]{2,3}[0-9]{7,8}$";
  static const String iranianPostalCode = r"^[0-9]{10}$";
  static const String email = r"^[^@\s]+@[^@\s]+\.[^@\s]+$";
  static const String url = r"^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$";
  static const String iban = r"^[A-Z]{2}[0-9]{2}[A-Z0-9]{1,30}$";
  static const String creditCard = r"^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})$";
}
