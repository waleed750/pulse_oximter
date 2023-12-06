import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:arc_progress_bar/arc_progress_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pulse_oximter/core/api/api_consumer.dart';
import 'package:pulse_oximter/core/api/dio_consumer.dart';
import 'package:pulse_oximter/core/api/end_points.dart';
import 'package:pulse_oximter/core/internet/network_info.dart';
import 'package:pulse_oximter/core/utils/app_colors.dart';
import 'package:pulse_oximter/core/utils/app_strings.dart';
import 'package:pulse_oximter/core/utils/constants.dart';
import 'package:pulse_oximter/core/utils/hex_color.dart';
import 'package:pulse_oximter/core/utils/media_query_values.dart';
import 'package:pulse_oximter/features/widgets/custom_bio.dart';
import 'package:pulse_oximter/features/widgets/custom_circular_progress.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //!Api variables
  late final DioConsumer _apiConsumer;
  final Dio _dio = Dio();
  final wifi_checker = NetworkInfoImpl();

  bool wifiOn = true;
  var response = null;
  double _progressValueBPM = 0;
  double _oldValuebBPM = 0;
  double _progressValueOxygen = 0;
  double _oldValuebOxygen = 0;

  //!Dangerous BPM
  var _dangerousBPM = 20.0;
  var _dangerousOxygen = 20.0;
  //!Max Min values
  double maxBPM = 120;
  double minBPM = 0;
  double maxOxygen = 100;
  double minOxygen = 0;

  //*Audio
  final AudioPlayer player = AudioPlayer()
    ..setSourceAsset("assets/audio/emergency.mp3");
  bool isPlaying = false;

  late Timer _timer;

  Color bpmColor = HexColor("1ddba6");
  Color oxygenColor = HexColor("1ddba6");

  // final GlobalKey<CustomCircularProgressIndicatorState> _progressIndicatorKey =
  //   GlobalKey<CustomCircularProgressIndicatorState>();

  @override
  void initState() {
    // TODO: implement initState
    _apiConsumer = DioConsumer(client: _dio);
    //*Check Restrictions
    _dangerousBPM = sharedPreferences.getDouble(AppStrings.bpmKey)??(0.3 * maxBPM);
    _dangerousOxygen = sharedPreferences.getDouble(AppStrings.oxygenkey)??(0.3 * maxOxygen);

    //!===================
    fetchData(); // Initial fetch
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      fetchData(); // Fetch data every 2 seconds
    });

    //!Audio Player

    player.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
    // player.onPositionChanged.listen((position) async {
    //    if (isPlaying &&
    //       position.inMilliseconds >= await player.getDuration(). ~/ 2) {
    //     // Pause the audio when half of the sound is played
    //     player.pause();
    //     isPlaying = false;
    //   }
    //  });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pulse Oximeter",
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomCircularProgressIndicator(
                  progressValue: _progressValueBPM,
                  oldValue: _oldValuebBPM,
                  MIN: minBPM,
                  MAX: maxBPM,
                  title: "BPM",
                  primaryColor: bpmColor,
                ),
              ),
              Expanded(
                child: CustomCircularProgressIndicator(
                  progressValue: _progressValueOxygen,
                  oldValue: _oldValuebOxygen,
                  MIN: minOxygen,
                  MAX: maxOxygen,
                  title: "Oxyen",
                  primaryColor: oxygenColor,
                ),
              ),
            ],
          ),
          // SizedBox(
          //   height: context.height * .1,
          // ),
          // InkWell(
          //     onTap: () => fetchData(),
          //     child: CircleAvatar(
          //         radius: context.width * .1,
          //         backgroundColor: AppColors.primaryColor,
          //         child: Icon(
          //           Icons.sync,
          //           size: context.width * .08,
          //         ))),
          //!Center
          Row(
            children: [
              Expanded(
                  child: CustomBio(
                title: "BPM",
                value: _progressValueBPM,
                color: bpmColor,
              )),
              Expanded(
                  child: CustomBio(
                title: "Oxygen",
                value: _progressValueOxygen,
                color: oxygenColor,
              )),
            ],
          ),
          SizedBox(
            height: 30.0,
          ),
          //!Bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  showBPM();
                },
                child: Container(
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                        color: Colors.yellow.withAlpha(10),
                        blurRadius: 10.0,
                        spreadRadius: 0.5,
                        offset: const Offset(
                          -3.0,
                          -2.0,
                        )),
                  ]),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.yellow,
                    size: context.width * .15,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void fetchData() async {
    wifiOn = await wifi_checker.isConnected();
    if (!wifiOn) {
      setState(() {});
      return;
    }
    try {
      response = await _apiConsumer.get(EndPoints.feed,
          queryParameters: {"min": 0, "max": 120, "count": 2});
      setState(() {
        _oldValuebBPM = _progressValueBPM;
        _oldValuebOxygen = _progressValueOxygen;

        _progressValueBPM = response[0].toDouble();
        _progressValueOxygen = response[1].toDouble();
        checkDangerousColor();
      });
      debugPrint("Response : ${response}");
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
    }
  }

  void checkDangerousColor() async {
    //!Check for BPM
    if (_progressValueBPM <=  _dangerousBPM) {
      bpmColor = Colors.red.shade400;
      await playAlert();
    } else if (_progressValueBPM <= (0.6 * maxBPM)) {
      bpmColor = Colors.yellow.shade400;
    } else {
      bpmColor = AppColors.primaryColor;
    }
    //!Check for Oxygen
    //!Check for BPM
    if (_progressValueOxygen <= _dangerousOxygen) {
      oxygenColor = Colors.red.shade400;
    } else if (_progressValueOxygen <= (0.6 * maxBPM)) {
      oxygenColor = Colors.yellow.shade400;
    } else {
      oxygenColor = AppColors.primaryColor;
    }
  }

  Future<void> playAlert() async {
    String audioasset = "assets/audio/ambulance_sound.mp3";

    if(!isPlaying){

      await player.release();
      await player.play(AssetSource("audio/emergency.mp3"));
      isPlaying = true;
    }
  }

  void showBPM() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: context.width * .1,
                  height: context.height *.008,
                  margin: EdgeInsetsDirectional.symmetric(vertical: 15.0),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(20.0)
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text("Set BPM Dangerous"),
                      Slider(
                          min: minBPM,
                          max: maxBPM,
                          value: _dangerousBPM,
                          thumbColor: Colors.red.shade400,
                          activeColor: Colors.red.shade400,
                          inactiveColor: Colors.grey!.withOpacity(0.7),
                          label: "Dangerous",
                          onChanged: (value) {
                            _dangerousBPM = value;
                            setState(() {});
                          }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text("$minBPM"), Text(
                              _dangerousBPM.toStringAsPrecision(2),
                              style: TextStyle(
                                  color: Colors.red.shade400, fontSize: 24.0),
                            ),Text("$maxBPM")],
                        ),
                      ),
                    ],
                  ),
                ),
                //!Oxygen
                Expanded(
                  child: Column(
                    children: [
                      Text("Set Oxygen Dangerous"),
                      Slider(
                          min: minOxygen,
                          max: maxOxygen,
                          value: _dangerousOxygen,
                          thumbColor: Colors.red.shade400,
                          activeColor: Colors.red.shade400,
                          inactiveColor: Colors.grey!.withOpacity(0.7),
                          label: "Dangerous",
                          onChanged: (value) {
                            _dangerousOxygen = value;
                            setState(() {});
                          }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("$minBPM"),
                            Text(
                              _dangerousOxygen.toStringAsPrecision(2),
                              style: TextStyle(
                                  color: Colors.red.shade400, fontSize: 24.0),
                            ),
                            Text("$maxBPM")
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                ,Expanded(
                  child: TextButton(onPressed: (){
                      save();
                      Navigator.pop(context);
                  }, child: Text("Save",style: TextStyle(
                    fontSize: 30.0 , 
                    color: AppColors.primaryColor
                  ),)),
                )
              ],
            );
          });
        });
  }
  void save()async{
    await sharedPreferences.setDouble(AppStrings.bpmKey, _dangerousBPM);
    await sharedPreferences.setDouble(AppStrings.oxygenkey, _dangerousOxygen);
  }
}
