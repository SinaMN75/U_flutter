part of "u_process.dart";

/// Drives a server-defined multi-step process: loads the current step, holds an
/// editable copy of its fields, and submits them. App-agnostic — when the
/// backend reports the process is finished it calls [onCompleted]; if none was
/// supplied it simply closes the current screen ([UNavigator.back]).
class UProcessController {
  UProcessController({this.onCompleted});

  /// Invoked when the backend reports the whole process is complete. When null,
  /// the process screen is popped so any process is reusable with zero config.
  final VoidCallback? onCompleted;

  // Single place that decides the "process finished" behavior.
  void _complete() {
    if (onCompleted != null)
      onCompleted!();
    else
      UNavigator.back();
  }

  late String processId;

  final Rxn<UProcessStepGet> processStep = Rxn<UProcessStepGet>();
  late UProcessStepSend processStepSend;
  final RxState state = RxState();

  void init({required String processId}) {
    this.processId = processId;
    read();
  }

  void read() {
    state.loading();
    UServices.process.get(
      processId: processId,
      onOk: (UResponse<UProcessStepGet> response) {
        // Backend signals the process is done -> hand control back to the host.
        if (response.status == Usc.processCompleted.number)
          _complete();
        else {
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

  void send() {
    ULoading.show();
    UServices.process.send(
      p: processStepSend,
      onOk: (UResponse<UProcessStepGet> response) {
        ULoading.dismiss();
        // A submit can also finish the process; guard against a null next step.
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
    );
  }

  void _applyStep(UProcessStepGet step) {
    processStep(step);
    // Rebuild an independent send payload so edits never mutate the fetched step.
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
