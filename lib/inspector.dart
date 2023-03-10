import 'api.dart';
import 'events.dart';
import 'event_manager.dart';

class Inspector extends API {
  void onSendToPropertyInspector(Function(dynamic event) callback) {
    EventManager.on(EventsReceived.sendToPropertyInspector, callback);
  }

  void sendToPlugin(String context, dynamic payload) {
    this.send(context, EventsSent.sendToPlugin, payload);
  }

  void setSettings(dynamic payload) {
    this.send(this.uuid as String, EventsSent.setSettings, payload);
  }

  void getSettings() {
    this.send(this.uuid as String, EventsSent.getSettings);
  }
}
