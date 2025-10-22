/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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

import 'package:illinois/model/Assistant.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

///////////////////////////////
/// Message

extension MessageUI on Message {

  List<dynamic>? get structElements {
    List<dynamic>? elements;
    if (structOutput != null) {
      List<AssistantStructOutputItem>? items = structOutput?.items;
      if ((items != null) && items.isNotEmpty) {
        elements = <dynamic>[];
        for (AssistantStructOutputItem item in items) {
          if (item.type == AssistantStructOutputItemType.event) {
            ListUtils.add(elements, Event2.fromJson(item.data));
          } else if (item.type == AssistantStructOutputItemType.dining_hall_details) {
            ListUtils.add(elements, Dining.fromJson(item.data));
          } else if (item.type == AssistantStructOutputItemType.menu_items) {
            ListUtils.add(elements, DiningProductItem.fromJson(item.data));
          } else if (item.type == AssistantStructOutputItemType.nutrition_info) {
            ListUtils.add(elements, DiningNutritionItem.fromJson(item.data));
          } else if (item.type == AssistantStructOutputItemType.campus_building) {
            ListUtils.add(elements, Building.fromJson(item.data));
          }
        }
      }
    }
    return elements;
  }

  String get providerDisplayString =>
    provider?.displayString ?? Localization().getStringEx('model.assistant.provider.unknown.label', 'Unknown');

}

extension AssistantProviderUI on AssistantProvider {

  String get displayString {
    switch (this) {
      case AssistantProvider.google: return Localization().getStringEx('model.assistant.provider.google.label', 'Google');
      case AssistantProvider.grok: return Localization().getStringEx('model.assistant.provider.grok.label', 'Grok');
      case AssistantProvider.perplexity: return Localization().getStringEx('model.assistant.provider.perplexity.label', 'Perplexity');
      case AssistantProvider.openai: return Localization().getStringEx('model.assistant.provider.openai.label', 'Illinois');
    }
  }

  static AssistantProvider? fromCode(String? code) {
    switch (code) {
      case 'google_assistant': return AssistantProvider.google;
      case 'grok_assistant': return AssistantProvider.grok;
      case 'perplexity_assistant': return AssistantProvider.perplexity;
      case 'openai_assistant': return AssistantProvider.openai;
      default: return null;
    }
  }

  static List<AssistantProvider>? listFromCodes(Iterable<String>? codes) {
    if (codes != null) {
      List<AssistantProvider> providers = <AssistantProvider>[];
      for (String code in codes) {
        AssistantProvider? provider = fromCode(code);
        if (provider != null) {
          providers.add(provider);
        }
      }
      return providers;
    }
    else {
      return null;
    }
  }
}

extension AssistantSettingsUI on AssistantSettings {

  String? get localizedTermsText => _getTermsText(locale: _localeCode);
  String? get localizedUnavailableText => _getUnavailableText(locale: _localeCode);

  String? _getTermsText({required String locale}) => JsonUtils.stringValue(termsTextJson?[locale]) ;
  String? _getUnavailableText({required String locale}) => JsonUtils.stringValue(unavailableTextJson?[locale]);
  String get _localeCode => Localization().currentLocale?.languageCode ?? Localization().defaultLocale?.languageCode ?? 'en';
}