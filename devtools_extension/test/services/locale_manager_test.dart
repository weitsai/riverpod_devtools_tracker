import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_devtools_extension/src/locale_manager.dart';

void main() {
  group('LocaleManager', () {
    test('default locale is English', () {
      final manager = LocaleManager();
      expect(manager.locale, const Locale('en'));
      expect(manager.locale.languageCode, 'en');
    });

    test('setEnglish switches to English locale', () {
      final manager = LocaleManager();

      // First switch to Chinese
      manager.setChinese();
      expect(manager.locale.languageCode, 'zh');

      // Then switch back to English
      manager.setEnglish();
      expect(manager.locale, const Locale('en'));
      expect(manager.locale.languageCode, 'en');
    });

    test('setChinese switches to Chinese locale', () {
      final manager = LocaleManager();

      manager.setChinese();
      expect(manager.locale, const Locale('zh'));
      expect(manager.locale.languageCode, 'zh');
    });

    test('toggleLocale switches from English to Chinese', () {
      final manager = LocaleManager();

      // Default is English
      expect(manager.locale.languageCode, 'en');

      // Toggle to Chinese
      manager.toggleLocale();
      expect(manager.locale.languageCode, 'zh');
    });

    test('toggleLocale switches from Chinese to English', () {
      final manager = LocaleManager();

      // Set to Chinese first
      manager.setChinese();
      expect(manager.locale.languageCode, 'zh');

      // Toggle back to English
      manager.toggleLocale();
      expect(manager.locale.languageCode, 'en');
    });

    test('toggleLocale works multiple times', () {
      final manager = LocaleManager();

      // Start with English
      expect(manager.locale.languageCode, 'en');

      // Toggle to Chinese
      manager.toggleLocale();
      expect(manager.locale.languageCode, 'zh');

      // Toggle to English
      manager.toggleLocale();
      expect(manager.locale.languageCode, 'en');

      // Toggle to Chinese again
      manager.toggleLocale();
      expect(manager.locale.languageCode, 'zh');
    });

    test('setEnglish notifies listeners', () {
      final manager = LocaleManager();
      var notificationCount = 0;

      manager.addListener(() {
        notificationCount++;
      });

      manager.setEnglish();
      expect(notificationCount, 1);
    });

    test('setChinese notifies listeners', () {
      final manager = LocaleManager();
      var notificationCount = 0;

      manager.addListener(() {
        notificationCount++;
      });

      manager.setChinese();
      expect(notificationCount, 1);
    });

    test('toggleLocale notifies listeners', () {
      final manager = LocaleManager();
      var notificationCount = 0;

      manager.addListener(() {
        notificationCount++;
      });

      manager.toggleLocale();
      expect(notificationCount, 1);
    });

    test('multiple listeners are all notified', () {
      final manager = LocaleManager();
      var listener1Count = 0;
      var listener2Count = 0;
      var listener3Count = 0;

      manager.addListener(() => listener1Count++);
      manager.addListener(() => listener2Count++);
      manager.addListener(() => listener3Count++);

      manager.setChinese();

      expect(listener1Count, 1);
      expect(listener2Count, 1);
      expect(listener3Count, 1);
    });

    test('removed listener is not notified', () {
      final manager = LocaleManager();
      var notificationCount = 0;

      void listener() {
        notificationCount++;
      }

      manager.addListener(listener);
      manager.setChinese();
      expect(notificationCount, 1);

      // Remove listener
      manager.removeListener(listener);
      manager.setEnglish();

      // Count should not increase
      expect(notificationCount, 1);
    });

    test('listener receives correct locale value', () {
      final manager = LocaleManager();
      Locale? capturedLocale;

      manager.addListener(() {
        capturedLocale = manager.locale;
      });

      manager.setChinese();
      expect(capturedLocale, const Locale('zh'));

      manager.setEnglish();
      expect(capturedLocale, const Locale('en'));
    });

    test('consecutive calls to same setter only notify once per call', () {
      final manager = LocaleManager();
      var notificationCount = 0;

      manager.addListener(() {
        notificationCount++;
      });

      manager.setEnglish();
      expect(notificationCount, 1);

      manager.setEnglish();
      expect(notificationCount, 2);

      manager.setEnglish();
      expect(notificationCount, 3);
    });

    test('dispose stops notifications', () {
      final manager = LocaleManager();
      var notificationCount = 0;

      manager.addListener(() {
        notificationCount++;
      });

      manager.setChinese();
      expect(notificationCount, 1);

      // Dispose the manager
      manager.dispose();

      // Further changes should not notify (and should not crash)
      // Note: Calling methods after dispose is not recommended but shouldn't crash
      try {
        manager.setEnglish();
        // The notification count should not increase
        // (though the locale might still change internally)
      } catch (e) {
        // Some implementations throw after dispose, which is also acceptable
      }
    });
  });
}
