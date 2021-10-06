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
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/utils/Utils.dart';

class UserData {


  final String uuid;
  bool overThirteen;

  Set<UserRole> roles;
  Map<String, List<String>> interests;
  Map<String, Set<String>>  favorites;
  List<String> positiveTags;
  List<String> negativeTags;
  Map<String, dynamic> privacySettings;
  Set<String> fcmTokens;
  bool registeredVoter;
  String votePlace;
  bool voterByMail;
  bool voted;

  UserData({this.uuid, this.privacySettings, this.roles, this.overThirteen, this.interests, this.favorites, this.positiveTags, this.negativeTags, this.fcmTokens, this.registeredVoter = false, this.votePlace, this.voterByMail, this.voted = false});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return (json != null) ? UserData(
        uuid: json['uuid'],
        overThirteen: json['over13'],
        privacySettings: json['privacySettings'],
        roles: UserRole.setFromJson(json["roles"]),
        interests: serializeInterests(json['interests']),
        favorites: serializeFavorites(json['favorites']),
        positiveTags: AppJson.castToStringList(json['positiveInterestTags']),
        negativeTags: AppJson.castToStringList(json['negativeInterestTags']),
        fcmTokens: (json['fcmTokens'] != null) ? Set.from(json['fcmTokens']) : null,
        registeredVoter: json['registered_voter'] ?? false,
        votePlace: json['vote_place'],
        voterByMail: json['voter_by_mail'],
        voted: json['voted'] ?? false
    ) : null;
  }

  void loadFromUserData(UserData data){
    overThirteen = data.overThirteen;
    privacySettings = data.privacySettings;
    roles = data.roles;
    interests = data.interests;
    favorites = data.favorites;
    positiveTags = data.positiveTags;
    negativeTags = data.negativeTags;
    fcmTokens = data.fcmTokens;
    registeredVoter = data.registeredVoter;
    votePlace = data.votePlace;
    voterByMail = data.voterByMail;
    voted = data.voted;
  }

  toJson() {
    return {
      "uuid": uuid,
      "over13": overThirteen,
      "privacySettings": privacySettings,
      "roles": roles != null ? roles.map((role) => role.toString()).toList() : null,
      "interests": deserializeInterests(interests),
      "positiveInterestTags": positiveTags,
      "negativeInterestTags": negativeTags,
      "favorites": deserializeFavorites(favorites),
      "fcmTokens": (fcmTokens != null) ? List.from(fcmTokens) : null,
      "registered_voter": registeredVoter,
      "vote_place": votePlace,
      "voter_by_mail": voterByMail,
      "voted": voted
    };
  }

  toShortJson() {
    return {
      "uuid": uuid,
      "over13": overThirteen,
      "privacySettings": privacySettings,
      "roles": roles != null ? roles.map((role) => role.toString()).toList() : null,
      "interests": deserializeInterests(interests),
      "positiveInterestTags": positiveTags,
      "negativeInterestTags": negativeTags,
      "favorites": deserializeFavorites(favorites),
      "registered_voter": registeredVoter,
      "vote_place": votePlace,
      "voter_by_mail": voterByMail,
      "voted": voted
    };
  }

  // Privacy

  int get privacyLevel {
    return (privacySettings != null) ? privacySettings['level'] : null;
  }

  set privacyLevel(int value) {
    if (privacySettings == null) {
      privacySettings = Map();
    }
    privacySettings['level'] = value;
  }

  // Interests

  //switch the whole category (no subCategories ) //Athletics/Recreation/Entertainment/etc
  switchCategory(String categoryName){
    if(categoryName!=null){
      if(interests.containsKey(categoryName)){
        interests.remove(categoryName);
      } else {
        interests[categoryName] = []; //Empty list of subcategories represent that the whole category is selected
      }
    }
  }

  void updateCategories(List<String> newCategoriesSelection){
    List<String> categoriesToBeRemoved = [];
    if(newCategoriesSelection!=null){
      newCategoriesSelection.forEach((element) {
        if(!interests.containsKey(element)){
          interests[element] = [];
        }
      });
      if(interests?.isNotEmpty??false){
        interests.forEach((key, value) {
          if(!newCategoriesSelection.contains(key)){
            categoriesToBeRemoved.add(key);
          }
        });
        if(categoriesToBeRemoved.isNotEmpty){
          categoriesToBeRemoved.forEach((element) {
            interests.removeWhere((key, value) => key == element);
          });
        }
      }
    }
  }

  //Only sports got sub categories for now
  switchInterestSubCategory(String interestCategory, String subCategory){
    List<String> subCategories = interests[interestCategory];
    if(subCategories==null){
      subCategories = [];
      interests[interestCategory] = subCategories;
    }

    //Switch
    if(subCategories.contains(subCategory)){
      subCategories.remove(subCategory);
    } else {
      subCategories.add(subCategory);
    }
  }

  List<String> getInterestSubCategories(String interestCategory){
    if(interests!=null && interests.isNotEmpty){
      return interests[interestCategory];
    }

    return null;
  }

  void updateSubCategories(String interestCategory, List<String> newSubCategories){
    if(interests.containsKey(interestCategory)){
      interests[interestCategory] = newSubCategories;
    }
  }

  void deleteInterests(){
    interests = Map<String, List<String>>();
    positiveTags = [];
    negativeTags = [];
  }

  //Interest Serialization
  static Map<String,List<String>> serializeInterests(List<dynamic> jsonData){
    Map<String,List<String>> result = new Map();
    if(jsonData!=null && jsonData.isNotEmpty){
      jsonData.forEach((dynamic category){
        String categoryName =  category["category"];
        List  subCategories = category["subcategories"];
        result[categoryName] = AppJson.castToStringList(subCategories);
      });
    }
    return result;
  }

  static List<dynamic> deserializeInterests(Map<String,List<String>> interests){
    List<dynamic> result = [];
    if(interests!=null){
      interests.forEach((categoryName, subCategories){
        result.add({"category": categoryName, "subcategories": subCategories});
      });
    }

    return result;
  }

  //Favorites
  void addFavorite(String favoriteType, String uuid){
    if(favoriteType==null || uuid==null)
      return;

    if(favorites==null)
      favorites = new Map();

    Set typeValues = favorites[favoriteType];
    if(typeValues==null){
      typeValues = new Set<String>();
      favorites[favoriteType] = typeValues;
    }
    typeValues.add(uuid);
  }

  void addAllFavorites(String favoriteType, Set<String> uiuds) {
    if (AppString.isStringEmpty(favoriteType) || AppCollection.isCollectionEmpty(uiuds)) {
      return;
    }
    if (favorites == null) {
      favorites = Map();
    }
    Set<String> typeValues = favorites[favoriteType];
    if (typeValues == null) {
      typeValues = Set<String>();
      favorites[favoriteType] = typeValues;
    }
    typeValues.addAll(uiuds);
  }

  void removeFavorite(String favoriteType, String uuid){
    if(favoriteType==null || uuid==null || favorites == null)
      return;

    Set typeValues = favorites[favoriteType];
    if(typeValues==null)
      return;

    typeValues.remove(uuid);
  }

  void removeAllFavorites(String favoriteType, Set<String> uiuds) {
    if (AppString.isStringEmpty(favoriteType) || (favorites == null || favorites.isEmpty) || AppCollection.isCollectionEmpty(uiuds)) {
      return;
    }

    Set typeValues = favorites[favoriteType];
    if (typeValues == null) {
      return;
    }
    typeValues.removeAll(uiuds);
  }

  bool isFavorite(Favorite favorite){
    if(favorites==null || favorite==null || AppString.isStringEmpty(favorite.favoriteId))
      return false;

    Set favoritesOfType = favorites[favorite.favoriteKey];
    return favoritesOfType != null ? favoritesOfType.contains(favorite.favoriteId) : false;
  }

  Set<String> getFavorites(String favoriteKey){
    return  favorites!=null? favorites[favoriteKey]: null;
  }

  //Favorites serialization
  static Map<String,Set<String>> serializeFavorites(Map jsonData){
    if(jsonData!=null && jsonData.isNotEmpty){
      Map<String, Set<String>> result = jsonData.map<String, Set<String>>((key, value) => MapEntry(key, Set<String>.from(value)));
      return result;
    }

    return null;
  }

  static Map<String,dynamic> deserializeFavorites(Map<String,Set<String>> favorites){
    if(favorites!=null && favorites.isNotEmpty){
      Map<String,dynamic> result = favorites.map((key,value)=>MapEntry(key, value.toList()));
      return result;
    }

    return null;
  }

  //Tags
  addPositiveTag(String tag){
    if(positiveTags==null) {
      positiveTags = [];
    }
    positiveTags.add(tag);
  }

  addNegativeTag(String tag){
    if(negativeTags!=null) {
      negativeTags = [];
    }
    negativeTags.add(tag);
  }

  removeTag(String tag){
    negativeTags?.remove(tag);
    positiveTags?.remove(tag);
  }

  void updatePositiveTags(List<String> newTagsSelection){
      positiveTags = newTagsSelection;
  }

  bool containsTag(String tag){
    return (positiveTags?.contains(tag)??false) || (negativeTags?.contains(tag)??false);
  }
}
