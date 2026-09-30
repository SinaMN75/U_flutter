part of "u_process.dart";

/// Loads, fills and sends the steps of a server-driven process (KYC, onboarding).
class UProcessController {
  UProcessController({this.onCompleted});

  /// Called when the input is complete.
  final VoidCallback? onCompleted;

  /// Upload progress 0-100.
  final URxInt progress = 0.obs;

  void _complete() {
    if (onCompleted != null) {
      onCompleted!();
    } else {
      dismiss();
    }
  }

  /// Closes the process page.
  void dismiss() => UNavigator.back();

  /// Id of the process.
  late String processId;

  /// Current step from the server.
  final URxn<UProcessStepGet> processStep = URxn<UProcessStepGet>();

  /// Answers of the current step.
  late UProcessStepSend processStepSend;

  /// Loading state.
  final URxState state = URxState();

  /// Starts a process by id.
  void init({required String processId}) {
    this.processId = processId;
    read();
  }

  /// Loads the current step.
  void read() {
    state.loading();
    UServices.process.get(
      processId: processId,
      onOk: (UResponse<UProcessStepGet> response) {
        if (response.status == Usc.processCompleted.number) {
          _complete();
        } else {
          _applyStep(response.result!);
          state.loaded();
        }
      },
      onError: (UEmptyResponse response) => state.error(),
      onException: (String response) {
        UToast.error(message: response);
        state.error();
      },
    );
  }

  /// Sends the current step's answers.
  void send() {
    ULoading.show();
    UServices.process.send(
      p: processStepSend,
      onOk: (UResponse<UProcessStepGet> response) {
        ULoading.dismiss();
        if (response.status == Usc.processCompleted.number || response.result == null) {
          _complete();
          return;
        }
        _applyStep(response.result!);
      },
      onError: (UEmptyResponse response) {
        UToast.error(message: response.message);
        ULoading.dismiss();
      },
      onException: (String response) {
        UToast.error(message: response);
        ULoading.dismiss();
      },
      onProgress: progress.call,
    );
  }

  void _applyStep(UProcessStepGet step) {
    processStep(step);
    processStepSend = UProcessStepSend(
      processId: processId,
      stepId: step.id,
      fields: List<UProcessField>.from(
        (step.fields ?? <UProcessField>[]).map(
          (UProcessField f) => UProcessField(
            label: f.label,
            type: f.type,
            required: f.required,
            key: f.key,
            value: f.value,
            textFieldConfig: f.textFieldConfig,
            fileConfig: f.fileConfig,
            dropDownConfig: f.dropDownConfig,
            options: f.options,
          ),
        ),
      ),
    );
  }
}
