part of "u_process.dart";

class UProcessController {
  UProcessController({this.onCompleted});

  final VoidCallback? onCompleted;

  void _complete() {
    if (onCompleted != null)
      onCompleted!();
    else
      dismiss();
  }

  void dismiss() => UNavigator.back();

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
