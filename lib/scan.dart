import 'dart:async';
import 'dart:convert';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ScanScreen extends StatefulWidget {
  @override
  _ScanState createState() => new _ScanState();
}

class _ScanState extends State<ScanScreen> {
  String _barcode = '';
  String _locationSelected;
  bool _isLocationSelected = false;
  List locations = List(); //edited line

  final String url = "http://192.168.254.123:8000/api";

  
  @override
  initState() {
    super.initState();
    this.getLocations();
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
                child: new DropdownButton(
                  isExpanded: true,
                  items: locations.map((item) {
                    return new DropdownMenuItem(
                      child: new Text(item['name']),
                      value: item['id'].toString(),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != '') {
                      setState(() {
                        _locationSelected = newVal;
                        _isLocationSelected = true;
                      });
                    }
                  },
                  value: _locationSelected,
                  isDense: true,
                  hint: new Text("Select Location", textAlign: TextAlign.center),
                ),
              )
              ,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: (_isLocationSelected)  ? RaisedButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    splashColor: Colors.blueGrey,
                    onPressed: scan,
                    child: const Text('START CAMERA SCAN')
                ) : const Text('Select location to enable camera scan.'),
              )
              ,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(_barcode, textAlign: TextAlign.center,),
              )
              ,
            ],
          ),
        ));
  }

  Future getLocations() async {
    var res = await http.get(url + '/location/get', headers: {"Accept": "application/json"});
    var locationsRes = json.decode(res.body);
    
    // print('locationRes length');
    // print(locationsRes.length);
    if (locationsRes.length > 0) {
      setState(() {
        locations = locationsRes['data']  ?? null;
      });
    }
  }

  Future scan() async {
    try {
      ScanResult result = await BarcodeScanner.scan();
      print('--------------------- scan --------------------');
     
      if(result.type == ResultType.Barcode) {
        print(result.rawContent);
        setState(() => this._barcode = result.rawContent);
        var splitString = result.rawContent.split(':');
        print(splitString);
        if (splitString != null && splitString[0] != null) {
          final httpResponse = await http.get(url + '/log/create?user_id=' + splitString[0] + '&location_id=' + _locationSelected);

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
          this._barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this._barcode = 'Unknown error: $e');
      }
    } on FormatException{
      setState(() => this._barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this._barcode = 'Unknown error: $e');
    }
  }
}