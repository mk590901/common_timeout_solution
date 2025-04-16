import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';

// BLoC Event
abstract class AppEvent {}

class InitializeApp extends AppEvent {
  final BuildContext context;
  InitializeApp(this.context);
}

class ResetTimeout extends AppEvent {}

class TimeoutExpired extends AppEvent {}

// BLoC State
enum GadgetType { phone, tablet }

class AppState {
  final GadgetType deviceType;
  final String screenType;
  final bool isTimedOut;
  AppState(this.deviceType, this.screenType, {this.isTimedOut = false});
}

// BLoC
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
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return BlocProvider(
          create: (context) => AppBloc()..add(InitializeApp(context)),
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
  const TimeoutWrapper({Key? key, required this.child}) : super(key: key);

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
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkboxValue = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Block back button
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return Stack(
            children: [
              // Main content
              Scaffold(
                appBar: AppBar(
                  title: Text('Idle Timeout App'),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: state.isTimedOut
                          ? null
                          : () {
                        context.read<AppBloc>().add(ResetTimeout());
                      },
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device: ${state.deviceType == GadgetType.phone ? "Phone" : "Tablet"}',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        Text(
                          'ScreenType: ${state.screenType}',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        SizedBox(height: 16.sp),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Enter text',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: state.isTimedOut
                              ? null
                              : (value) {
                            context.read<AppBloc>().add(ResetTimeout());
                          },
                        ),
                        SizedBox(height: 16.sp),
                        DropdownButtonFormField<String>(
                          value: 'Option 1',
                          items: ['Option 1', 'Option 2', 'Option 3']
                              .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                              .toList(),
                          onChanged: state.isTimedOut
                              ? null
                              : (value) {
                            context.read<AppBloc>().add(ResetTimeout());
                          },
                          decoration: InputDecoration(
                            labelText: 'Select option',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16.sp),
                        CheckboxListTile(
                          title: Text('Enable feature', style: TextStyle(fontSize: 14.sp)),
                          value: _checkboxValue,
                          onChanged: state.isTimedOut
                              ? null
                              : (value) {
                            setState(() {
                              _checkboxValue = value ?? false;
                            });
                            context.read<AppBloc>().add(ResetTimeout());
                          },
                        ),
                        SizedBox(height: 16.sp),
                        ElevatedButton(
                          onPressed: state.isTimedOut
                              ? null
                              : () {
                            context.read<AppBloc>().add(ResetTimeout());
                          },
                          child: Text('Press Me', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Timeout overlay
              if (state.isTimedOut) TimeoutScreen(),
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
              'Session Timed Out',
              style: TextStyle(fontSize: 20.sp, color: Colors.white),
            ),
            SizedBox(height: 16.sp),
            ElevatedButton(
              onPressed: () {
                context.read<AppBloc>().add(ResetTimeout());
              },
              child: Text('Unlock App', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
