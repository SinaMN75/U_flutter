part of "../data.dart";

class UserFlowStatus {
  final String currentStep;
  final int totalSteps;
  final List<UserFlowStep> steps;
  final FlowMetadata? metadata;

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
    metadata: json["metadata"] != null ? FlowMetadata.fromJson(json["metadata"]) : null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "currentStep": currentStep,
    "totalSteps": totalSteps,
    "steps": steps.map((UserFlowStep e) => e.toJson()).toList(),
    "metadata": metadata?.toJson(),
  };
}

/// Metadata for the entire flow
class FlowMetadata {
  final String? flowId;
  final String? flowName;
  final String? version;
  final DateTime? lastUpdated;
  final String? timezone;

  FlowMetadata({
    this.flowId,
    this.flowName,
    this.version,
    this.lastUpdated,
    this.timezone,
  });

  factory FlowMetadata.fromJson(Map<String, dynamic> json) => FlowMetadata(
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

/// Represents a single step in the multi-step wizard
class UserFlowStep {
  final String stepId;
  final int number;
  final String title;
  final String? description;
  final String? icon;
  final String? backgroundImageUrl;
  final List<UserFlowField> fields;
  final List<UserFlowFileRequirement> files;
  final StepNavigation? navigation;
  final List<FieldGroup>? fieldGroups;

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
    navigation: json["navigation"] != null ? StepNavigation.fromJson(json["navigation"]) : null,
    fieldGroups: json["fieldGroups"] != null ? (json["fieldGroups"] as List<dynamic>).map((dynamic e) => FieldGroup.fromJson(e)).toList() : null,
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
    "fieldGroups": fieldGroups?.map((FieldGroup e) => e.toJson()).toList(),
  };
}

/// Configuration for step navigation
class StepNavigation {
  final String? enableNextCondition;
  final String? nextButtonLabel;
  final String? previousButtonLabel;
  final String? conditionalNextStep;
  final String? conditionalNextCondition;

  StepNavigation({
    this.enableNextCondition,
    this.nextButtonLabel,
    this.previousButtonLabel,
    this.conditionalNextStep,
    this.conditionalNextCondition,
  });

  factory StepNavigation.fromJson(Map<String, dynamic> json) => StepNavigation(
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

/// Group multiple fields together in a visual section
class FieldGroup {
  final String groupId;
  final String title;
  final String? description;
  final List<String> fieldNames;
  final String? layout;
  final int? columns;

  FieldGroup({
    required this.groupId,
    required this.title,
    required this.fieldNames,
    this.description,
    this.layout,
    this.columns,
  });

  factory FieldGroup.fromJson(Map<String, dynamic> json) => FieldGroup(
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

/// Represents a single form field with complete configuration
class UserFlowField {
  final String fieldName;
  final String label;
  final FieldType type;
  final bool isRequired;
  final String? hint;
  final String? placeholder;
  final String? defaultValue;
  final bool isDisabled;
  final bool isReadOnly;
  final bool isHidden;
  final ValidationRules? validation;
  final List<SelectOption>? options;
  final DynamicOptionsConfig? dynamicOptions;
  final DependencyRule? dependency;
  final VisibilityRule? visibility;
  final String? apiEndpoint;
  final String? httpMethod;
  final Map<String, String>? apiHeaders;
  final ApiAction? onApiResponse;
  final int? debounceMs;
  final bool autoSave;
  final String? cssClass;
  final FieldWidth width;
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
    this.width = FieldWidth.full,
    this.order = 0,
  });

  factory UserFlowField.fromJson(Map<String, dynamic> json) => UserFlowField(
    fieldName: json["fieldName"],
    label: json["label"],
    type: FieldType.values.firstWhere(
      (FieldType e) => e.name == json["type"],
      orElse: () => FieldType.text,
    ),
    isRequired: json["isRequired"] ?? true,
    hint: json["hint"],
    placeholder: json["placeholder"],
    defaultValue: json["defaultValue"],
    isDisabled: json["isDisabled"] ?? false,
    isReadOnly: json["isReadOnly"] ?? false,
    isHidden: json["isHidden"] ?? false,
    validation: json["validation"] != null ? ValidationRules.fromJson(json["validation"]) : null,
    options: json["options"] != null ? (json["options"] as List<dynamic>).map((dynamic e) => SelectOption.fromJson(e)).toList() : null,
    dynamicOptions: json["dynamicOptions"] != null ? DynamicOptionsConfig.fromJson(json["dynamicOptions"]) : null,
    dependency: json["dependency"] != null ? DependencyRule.fromJson(json["dependency"]) : null,
    visibility: json["visibility"] != null ? VisibilityRule.fromJson(json["visibility"]) : null,
    apiEndpoint: json["apiEndpoint"],
    httpMethod: json["httpMethod"] ?? "PUT",
    apiHeaders: json["apiHeaders"] != null ? Map<String, String>.from(json["apiHeaders"]) : null,
    onApiResponse: json["onApiResponse"] != null ? ApiAction.fromJson(json["onApiResponse"]) : null,
    debounceMs: json["debounceMs"],
    autoSave: json["autoSave"] ?? true,
    cssClass: json["cssClass"],
    width: FieldWidth.values.firstWhere(
      (FieldWidth e) => e.name == json["width"],
      orElse: () => FieldWidth.full,
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
    "options": options?.map((SelectOption e) => e.toJson()).toList(),
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

/// Dynamic options loaded from API
class DynamicOptionsConfig {
  final String apiUrl;
  final String? responsePath;
  final String valueField;
  final String textField;
  final bool enableSearch;
  final int minCharsForSearch;

  DynamicOptionsConfig({
    required this.apiUrl,
    this.responsePath,
    this.valueField = "value",
    this.textField = "text",
    this.enableSearch = false,
    this.minCharsForSearch = 2,
  });

  factory DynamicOptionsConfig.fromJson(Map<String, dynamic> json) => DynamicOptionsConfig(
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

/// Action to perform after API response
class ApiAction {
  final ActionType type;
  final Map<String, dynamic>? parameters;

  ApiAction({
    required this.type,
    this.parameters,
  });

  factory ApiAction.fromJson(Map<String, dynamic> json) => ApiAction(
    type: ActionType.values.firstWhere(
      (ActionType e) => e.name == json["type"],
      orElse: () => ActionType.showToast,
    ),
    parameters: json["parameters"],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "type": type.name,
    "parameters": parameters,
  };
}

enum ActionType {
  updateField,
  showToast,
  enableStep,
  disableField,
  triggerNavigation,
  refreshOptions,
}

/// Validation rules for a field
class ValidationRules {
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

  ValidationRules({
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

  factory ValidationRules.fromJson(Map<String, dynamic> json) => ValidationRules(
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

/// Option for select, radio, checkbox group fields
class SelectOption {
  final String value;
  final String text;
  final bool isDefault;
  final bool isDisabled;
  final String? group;
  final String? icon;

  SelectOption({
    required this.value,
    required this.text,
    this.isDefault = false,
    this.isDisabled = false,
    this.group,
    this.icon,
  });

  factory SelectOption.fromJson(Map<String, dynamic> json) => SelectOption(
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

/// Field dependency configuration
class DependencyRule {
  final String dependsOnField;
  final String dependsOnValue;
  final ComparisonOperator operator;
  final String? optionsApiEndpoint;
  final String? apiMethod;

  DependencyRule({
    required this.dependsOnField,
    required this.dependsOnValue,
    this.operator = ComparisonOperator.equals,
    this.optionsApiEndpoint,
    this.apiMethod = "GET",
  });

  factory DependencyRule.fromJson(Map<String, dynamic> json) => DependencyRule(
    dependsOnField: json["dependsOnField"],
    dependsOnValue: json["dependsOnValue"],
    operator: ComparisonOperator.values.firstWhere(
      (ComparisonOperator e) => e.name == json["operator"],
      orElse: () => ComparisonOperator.equals,
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

/// Visibility rule for fields
class VisibilityRule {
  final String dependsOnField;
  final String dependsOnValue;
  final ComparisonOperator operator;
  final List<VisibilityRule>? multipleConditions;
  final LogicalOperator logicalOperator;

  VisibilityRule({
    required this.dependsOnField,
    required this.dependsOnValue,
    this.operator = ComparisonOperator.equals,
    this.multipleConditions,
    this.logicalOperator = LogicalOperator.and,
  });

  factory VisibilityRule.fromJson(Map<String, dynamic> json) => VisibilityRule(
    dependsOnField: json["dependsOnField"],
    dependsOnValue: json["dependsOnValue"],
    operator: ComparisonOperator.values.firstWhere(
      (ComparisonOperator e) => e.name == json["operator"],
      orElse: () => ComparisonOperator.equals,
    ),
    multipleConditions: json["multipleConditions"] != null ? (json["multipleConditions"] as List<dynamic>).map((dynamic e) => VisibilityRule.fromJson(e)).toList() : null,
    logicalOperator: LogicalOperator.values.firstWhere(
      (LogicalOperator e) => e.name == json["logicalOperator"],
      orElse: () => LogicalOperator.and,
    ),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    "dependsOnField": dependsOnField,
    "dependsOnValue": dependsOnValue,
    "operator": operator.name,
    "multipleConditions": multipleConditions?.map((VisibilityRule e) => e.toJson()).toList(),
    "logicalOperator": logicalOperator.name,
  };
}

enum ComparisonOperator {
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

enum LogicalOperator {
  and,
  or,
}

/// File upload configuration
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

enum FieldType {
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

enum FieldWidth {
  full,
  half,
  third,
  quarter,
  auto,
}

class PredefinedValidationPatterns {
  static const String iranianNationalCode = r"^[0-9]{10}$";
  static const String iranianMobilePhone = r"^09[0-9]{9}$";
  static const String iranianPhoneNumber = r"^0[0-9]{2,3}[0-9]{7,8}$";
  static const String iranianPostalCode = r"^[0-9]{10}$";
  static const String email = r"^[^@\s]+@[^@\s]+\.[^@\s]+$";
  static const String url = r"^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$";
  static const String iban = r"^[A-Z]{2}[0-9]{2}[A-Z0-9]{1,30}$";
  static const String creditCard = r"^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})$";
}
