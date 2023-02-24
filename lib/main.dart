import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(
    meuapp(),
  );
}

class meuapp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: pagina1(),
    );
  }
}

class pagina1 extends StatefulWidget {
  @override
  State<pagina1> createState() => _pagina1State();
}

class _pagina1State extends State<pagina1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Acende LED"),
      ),
      drawer: Drawer(
        child: menu(),
      ),
      body: Container(
        child: conteudoPagina1(),
      ),
    );
  }
}

class menu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlutterLogo(),
        Text("Desenvolvido por:"),
        Text("Bruno Rodrigues"),
        Icon(
          Icons.copyright,
        ),
      ],
    );
  }
}

class conteudoPagina1 extends StatefulWidget {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  BluetoothDevice? _connectedDevice;
  late List<BluetoothService> _services;
  bool ligaLED = false;
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  State<conteudoPagina1> createState() => _conteudoPagina1State();
}

class _conteudoPagina1State extends State<conteudoPagina1> {
  //metodo para preencher os dispositivos encontrados
  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildView(),
    );
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = <Container>[];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  primary: Colors.white,
                  backgroundColor: Colors.blue,
                  onSurface: Colors.grey,
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    if (e.toString() != 'already_connected') {
                      throw e;
                    }
                  } finally {
                    widget._services = await device.discoverServices();
                  }
                  setState(() {
                    widget._connectedDevice = device;
                  });
                },
                child: Text(
                  'Conectar',
                ),
              ),
              // Divider(),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }
  /*
/// Envia a informação pelo BLE
  ListView _buildConnectDeviceView() {
    List<Container> containers = <Container>[];
//principal alteração é dentro da estrutura de repetição for
    for (BluetoothService service in widget._services) {
      List<Widget> characteristicsWidget = <Widget>[];
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristic.value.listen((value) {
          print(value);
        });

        if (characteristic.properties.write) {
          characteristicsWidget.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        characteristic.uuid.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ..._buildReadWriteNotifyButton(characteristic),
                    ],
                  ),
                  Divider(),
                ],
              ),
            ),
          );
        }
      }

      containers.add(
        Container(
          child: ExpansionTile(
            title: Text(service.uuid.toString()),
            children: characteristicsWidget,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }
*/

  ListView _buildConnectDeviceView() {
    List<Container> containers = <Container>[];
//principal alteração é dentro da estrutura de repetição for
    for (BluetoothService service in widget._services) {
      List<Widget> characteristicsWidget = <Widget>[];
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristic.value.listen((value) {
          print(value);
        });

        characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      characteristic.uuid.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ..._buildReadWriteNotifyButton(characteristic),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('Valor do Contador: ' +
                        widget.readValues[characteristic.uuid].toString()),
                  ],
                ),
                Divider(),
              ],
            ),
          ),
        );
      }

      containers.add(
        Container(
          child: ExpansionTile(
            title: Text(service.uuid.toString()),
            children: characteristicsWidget,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    if (widget._connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

/* //Enviar valor pelo BLE
  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    ////se a caracteristica do bluetooth for escrita, envia dados para o dispositivo
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline),
                    Switch(
                      value: widget.ligaLED,
                      onChanged: (value) {
                        setState(() {
                          widget.ligaLED = value;
                          if (value) {
                            characteristic.write(utf8.encode('1'));
                          } else {
                           characteristic.write(utf8.encode('0'));
                            
                          }
                        });
                      },
                    ),
                    Text("Luz"),
                  ],
                ),
              )),
        ),
      );
    }
    return buttons;
  }*/

//Ler valor do BLE
  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Colors.blue,
                onSurface: Colors.grey,
              ),
              child: Text(
                'READ',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                    print(value);
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }

    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Colors.blue,
                onSurface: Colors.grey,
              ),
              child: Text(
                'NOTIFY',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                    print(value);
                  });
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }
    return buttons;
  }
}
