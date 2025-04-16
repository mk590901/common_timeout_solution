import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';

// String constants
class AppStrings {
  static const String sessionTimedOut = 'Session Timed Out';
  static const String unlockApp = 'Unlock App';
  static const String appTitle = 'Idle Timeout App';
  static const String enterText = 'Enter text';
  static const String selectOption = 'Select option';
  static const String enableFeature = 'Enable feature';
  static const String pressMe = 'Press Me';
}

// Form BLoC
abstract class FormEvent {}

class UpdateTextInput extends FormEvent {
  final String textInput;
  UpdateTextInput(this.textInput);
}

class UpdateDropdownValue extends FormEvent {
  final String dropdownValue;
  UpdateDropdownValue(this.dropdownValue);
}

class UpdateCheckboxValue extends FormEvent {
  final bool checkboxValue;
  UpdateCheckboxValue(this.checkboxValue);
}

class FormState {
  final String textInput;
  final String dropdownValue;
  final bool checkboxValue;

  FormState({
    this.textInput = '',
    this.dropdownValue = 'Option 1',
    this.checkboxValue = false,
  });

  FormState copyWith({
    String? textInput,
    String? dropdownValue,
    bool? checkboxValue,
  }) {
    return FormState(
      textInput: textInput ?? this.textInput,
      dropdownValue: dropdownValue ?? this.dropdownValue,
      checkboxValue: checkboxValue ?? this.checkboxValue,
    );
  }
}

class FormBloc extends Bloc<FormEvent, FormState> {
  FormBloc() : super(FormState()) {
    on<UpdateTextInput>((event, emit) {
      emit(state.copyWith(textInput: event.textInput));
    });
    on<UpdateDropdownValue>((event, emit) {
      emit(state.copyWith(dropdownValue: event.dropdownValue));
    });
    on<UpdateCheckboxValue>((event, emit) {
      emit(state.copyWith(checkboxValue: event.checkboxValue));
    });
  }
}

// App BLoC
abstract class AppEvent {}

class InitializeApp extends AppEvent {
  final BuildContext context;
  InitializeApp(this.context);
}

class ResetTimeout extends AppEvent {}

class TimeoutExpired extends AppEvent {}

enum GadgetType { phone, tablet }

class AppState {
  final GadgetType deviceType;
  final String screenType;
  final bool isTimedOut;
  AppState(this.deviceType, this.screenType, {this.isTimedOut = false});
}

class AppBloc extends Bloc<AppEvent, AppState> {
  Timer? _timeoutTimer;
  final Duration timeoutDuration = Duration(seconds: 5);

  AppBloc() : super(AppState(GadgetType.phone, 'Unknown')) {
    on<InitializeApp>(_onInitializeApp);
    on<ResetTimeout>(_onResetTimeout);
    on<TimeoutExpired>(_onTimeoutExpired);
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(timeoutDuration, () {
      add(TimeoutExpired());
    });
  }

  void _onInitializeApp(InitializeApp event, Emitter<AppState> emit) {
    final screenType = Device.screenType;
    final isTablet = screenType == ScreenType.tablet;
    final deviceType = isTablet ? GadgetType.tablet : GadgetType.phone;

    if (isTablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    _startTimeoutTimer();
    emit(AppState(deviceType, screenType.toString()));
  }

  void _onResetTimeout(ResetTimeout event, Emitter<AppState> emit) {
    _startTimeoutTimer();
    emit(AppState(state.deviceType, state.screenType, isTimedOut: false));
  }

  void _onTimeoutExpired(TimeoutExpired event, Emitter<AppState> emit) {
    _timeoutTimer?.cancel();
    emit(AppState(state.deviceType, state.screenType, isTimedOut: true));
  }

  @override
  Future<void> close() {
    _timeoutTimer?.cancel();
    return super.close();
  }
}

// App
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AppBloc()..add(InitializeApp(context))),
            BlocProvider(create: (context) => FormBloc()),
          ],
          child: MaterialApp(
            home: TimeoutWrapper(child: HomeScreen()),
          ),
        );
      },
    );
  }
}

// Timeout Wrapper
class TimeoutWrapper extends StatelessWidget {
  final Widget child;
  const TimeoutWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        if (state.isTimedOut) {
          return child;
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            context.read<AppBloc>().add(ResetTimeout());
          },
          onPanUpdate: (_) {
            context.read<AppBloc>().add(ResetTimeout());
          },
          child: child,
        );
      },
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !context.read<AppBloc>().state.isTimedOut,
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          return Stack(
            children: [
              // Main content
              Scaffold(
                appBar: AppBar(
                  title: Text(AppStrings.appTitle),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: appState.isTimedOut
                          ? null
                          : () {
                        context.read<AppBloc>().add(ResetTimeout());
                      },
                    ),
                  ],
                ),
                body: BlocBuilder<FormBloc, FormState>(
                  builder: (context, formState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16.sp),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device: ${appState.deviceType == GadgetType.phone ? "Phone" : "Tablet"}',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            Text(
                              'ScreenType: ${appState.screenType}',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            SizedBox(height: 16.sp),
                            TextField(
                              controller: TextEditingController(text: formState.textInput)
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(offset: formState.textInput.length),
                                ),
                              decoration: InputDecoration(
                                labelText: AppStrings.enterText,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: appState.isTimedOut
                                  ? null
                                  : (value) {
                                context.read<FormBloc>().add(UpdateTextInput(value));
                                context.read<AppBloc>().add(ResetTimeout());
                              },
                            ),
                            SizedBox(height: 16.sp),
                            DropdownButtonFormField<String>(
                              value: formState.dropdownValue,
                              items: ['Option 1', 'Option 2', 'Option 3']
                                  .map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ))
                                  .toList(),
                              onChanged: appState.isTimedOut
                                  ? null
                                  : (value) {
                                context.read<FormBloc>().add(UpdateDropdownValue(value!));
                                context.read<AppBloc>().add(ResetTimeout());
                              },
                              decoration: InputDecoration(
                                labelText: AppStrings.selectOption,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16.sp),
                            CheckboxListTile(
                              title: Text(AppStrings.enableFeature, style: TextStyle(fontSize: 14.sp)),
                              value: formState.checkboxValue,
                              onChanged: appState.isTimedOut
                                  ? null
                                  : (value) {
                                context.read<FormBloc>().add(UpdateCheckboxValue(value ?? false));
                                context.read<AppBloc>().add(ResetTimeout());
                              },
                            ),
                            SizedBox(height: 16.sp),
                            ElevatedButton(
                              onPressed: appState.isTimedOut
                                  ? null
                                  : () {
                                context.read<AppBloc>().add(ResetTimeout());
                              },
                              child: Text(AppStrings.pressMe, style: TextStyle(fontSize: 14.sp)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Timeout overlay
              if (appState.isTimedOut) TimeoutScreen(),
            ],
          );
        },
      ),
    );
  }
}

// Timeout Screen
class TimeoutScreen extends StatelessWidget {
  const TimeoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.sessionTimedOut,
              style: TextStyle(fontSize: 20.sp, color: Colors.white),
            ),
            SizedBox(height: 16.sp),
            ElevatedButton(
              onPressed: () {
                context.read<AppBloc>().add(ResetTimeout());
              },
              child: Text(AppStrings.unlockApp, style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
