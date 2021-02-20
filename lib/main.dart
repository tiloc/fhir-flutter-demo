// @dart=2.9
import 'package:fhir_flutter_demo/hf_instrument.dart';
import 'package:fhir_flutter_demo/phq9_instrument.dart';
import 'package:fhir_flutter_demo/prapare_instrument.dart';
import 'package:fhir_flutter_demo/response_state.dart';
import 'package:fhir_flutter_demo/survey_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:research_package/ui.dart';
import 'package:simple_html_css/simple_html_css.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => ResponseModel(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: [
        Locale('en'),
        Locale('da'),
      ],
      localizationsDelegates: [
        // A class which loads the translations from JSON files
        RPLocalizations.delegate,
        // Built-in localization of basic text for Cupertino widgets
        GlobalCupertinoLocalizations.delegate,
        // Built-in localization of basic text for Material widgets
        GlobalMaterialLocalizations.delegate,
        // Built-in localization for text direction LTR/RTL
        GlobalWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'FHIR Questionnaire Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SurveyPage(Phq9Instrument.phq9Instrument))),
                child: Text('Launch PHQ9 survey'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SurveyPage(HFInstrument.hfInstrument))),
                child: Text('Launch HF survey'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SurveyPage(PrapareInstrument.prapareInstrument))),
                child: Text('Launch PRAPARE survey'),
              ),
            ],
          ),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Consumer<ResponseModel>(
                  builder: (context, response, child) {
                    if (response.response == null) {
                      return Text('No response yet');
                    } else {
                      return HTML.toRichText(
                          context, response.response.text.div);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
