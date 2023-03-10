import 'dart:convert';
import 'dart:io';

import 'event_manager.dart';
import 'events.dart';
import 'plugin_arguments.dart';
import 'logger.dart';
import 'events/did_receive_settings_event.dart';

abstract class API {
  int? _port;
  String? uuid;
  Info? _info;
  WebSocket? _websocket;

  Future<void> connect(PluginArguments arguments) async {
    this._port = arguments.port;
    this.uuid = arguments.pluginUuid;
    this._info = arguments.info;

    if (_websocket != null) {
      this._websocket?.close();
      this._websocket = null;
    }

    this._websocket = await WebSocket.connect('ws://127.0.0.1:$_port');

    this._websocket!.add(jsonEncode({"uuid": this.uuid, "event": "registerPlugin"}));

    EventManager.on(EventsSent.logMessage, (message) {
      this.logMessage(message as String);
    });

    EventManager.emit(EventsReceived.connected, {
      "uuid": this.uuid,
      "info": this._info,
    });

    this._websocket!.listen((socketEvent) {
      var data = jsonDecode(socketEvent);
      Logger.debug(data);
      if (data != null) {
        var action = data['action'];
        var event = data['event'];
        var message = action != null ? '${action}.${event}' : event;

        if (message != null) {
          switch (event) {
            case EventsReceived.didReceiveSettings:
              EventManager.emit<DidReceiveSettingsEvent>(message, DidReceiveSettingsEvent.fromJson(data));
              break;
            default:
              EventManager.emit(message, data);
          }
        }
      }
    });
  }

  void send(String context, String event, [dynamic payload]) {
    if (_websocket == null) {
      throw Exception('WebSocket is not connected');
    }

    var message = jsonEncode({
      "context": context,
      "event": event,
      "payload": payload,
    });

    this._websocket?.add(message);
  }

  void logMessage(String message) {
    this.send(this.uuid!, EventsSent.logMessage, {
      "message": message,
    });
  }

  void setGlobalSettings(dynamic payload) {
    this.send(this.uuid!, EventsSent.setGlobalSettings, payload);
  }

  void getGlobalSettings() {
    this.send(this.uuid!, EventsSent.getGlobalSettings, null);
  }

  void openUrl(String url) {
    this.send(this.uuid!, EventsSent.openUrl, {
      "url": url,
    });
  }

  void onConnected(Function(dynamic event) callback) {
    EventManager.on(EventsReceived.connected, callback);
  }

  void onDidReceiveGlobalSettings(Function(dynamic event) callback) {
    EventManager.on(EventsReceived.didReceiveGlobalSettings, callback);
  }

  void onDidReceiveSettings(String action, Function(dynamic event) callback) {
    EventManager.on(action + EventsReceived.didReceiveSettings, callback);
  }
}
