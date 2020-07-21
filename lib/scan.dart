import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ScanScreen extends StatefulWidget {
  @override
  _ScanState createState() => new _ScanState();
}

class _ScanState extends State<ScanScreen> {
  String barcode = "";

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text('QR Code Scanner'),
        ),
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: RaisedButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    splashColor: Colors.blueGrey,
                    onPressed: scan,
                    child: const Text('START CAMERA SCAN')
                ),
              )
              ,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(barcode, textAlign: TextAlign.center,),
              )
              ,
            ],
          ),
        ));
  }

  Future scan() async {
    try {
      ScanResult result = await BarcodeScanner.scan();
      print('--------------------- scan --------------------');
     
      if(result.type == ResultType.Barcode) {
        print(result.rawContent);
        setState(() => this.barcode = result.rawContent);
        var splitString = result.rawContent.split(':');
        print(splitString);
        if (splitString != null && splitString[0] != null) {
          // perform parsing data to api
          // final http.Response httpSend = await http.get('http://192.168.254.123:8000/api/log/create?user_id=' + splitString[0])
          // .then((response) {
          //   if (response.data.result == false) {
          //     print('user id not found!');
          //   } else {
          //     print('user id log added.');
          //   }
          // })

          final httpResponse = await http.get('http://192.168.254.123:8000/api/log/create?user_id=' + splitString[0]);

          if (httpResponse.statusCode == 200) {
            // If the server did return a 200 OK response,
            // then parse the JSON.
            print(httpResponse);
          } else {
            // If the server did not return a 200 OK response,
            // then throw an exception.
            throw Exception('User ID not found.');
          }
        }

      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException{
      setState(() => this.barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }
}