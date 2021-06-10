/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

class NotificationService {
  
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();
  
  static NotificationService get instance {
    return _instance;
  }

  Map<String, Set<NotificationsListener>> _listeners = Map();

  void subscribe(NotificationsListener listener, names) {
    if (names is List) {
      for (String name in names) {
        if (name is String) {
          _subscribe(listener, name);
        }
      }
    }
    else if (names is String) {
      _subscribe(listener, names);
    }
  }

  void _subscribe(NotificationsListener listener, String name) {
    if ((listener != null) && (name != null)) {
      Set<NotificationsListener> listenersForName = _listeners[name];
      if (listenersForName == null) {
        _listeners[name] = listenersForName = Set<NotificationsListener>();
      }
      listenersForName.add(listener);
    }
  }

  void unsubscribe(NotificationsListener listener, { dynamic names }) {
    if (names is List) {
      for (String name in names) {
        if (name is String) {
          _unsubscribe(listener, name);
        }
      }
    }
    else if (names is String) {
      _unsubscribe(listener, names);
    }
    else if (names == null) {
      _unsubscribeAll(listener);
    }
  }

  void _unsubscribe(NotificationsListener listener, String name) {
    if ((listener != null) && (name != null)) {
      // Unsubscribe for 'name'
      Set<NotificationsListener> listenersForName = _listeners[name];
      if (listenersForName != null) {
        listenersForName.remove(listener);
      }
    }
  }

  void _unsubscribeAll(NotificationsListener listener) {
    // Remove all subscriptions of listener
    for (Set<NotificationsListener> listenersForName in _listeners.values) {
      listenersForName.remove(listener);
    }
  }

  void notify(String name, [dynamic param]) {
    Set<NotificationsListener> listenersForName = _listeners[name];
    if (listenersForName != null) {
      for (NotificationsListener listener in listenersForName) {
        listener.onNotification(name, param);
      }
    }
  }

}

abstract class NotificationsListener {
  void onNotification(String name, dynamic param);
}
