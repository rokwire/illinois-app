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

package edu.illinois.rokwire;

import java.util.HashMap;

public class Utils {

    public static class Map {

        // Value for Path

        public static String getValueFromPath(Object object, String path, String defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof String) ? (String)valueObject : defaultValue;
        }

        public static int getValueFromPath(Object object, String path, int defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Integer) ? (Integer) valueObject : defaultValue;
        }

        private static Object getValueFromPath(Object object, String path) {
            if (!(object instanceof java.util.Map) || Str.isEmpty(path)) {
                return null;
            }
            java.util.Map map = (java.util.Map) object;
            int dotFirstIndex = path.indexOf(".");
            while (dotFirstIndex != -1) {
                String subPath = path.substring(0, dotFirstIndex);
                path = path.substring(dotFirstIndex + 1);
                Object innerObject = (map != null) ? map.get(subPath) : null;
                map = (innerObject instanceof HashMap) ? (HashMap) innerObject : null;
                dotFirstIndex = path.indexOf(".");
            }
            Object generalValue = (map != null) ? map.get(path) : null;
            return getPlatformValue(generalValue);
        }

        private static Object getPlatformValue(Object object) {
            if (object instanceof HashMap) {
                HashMap hashMap = (HashMap) object;
                return hashMap.get("android");
            } else {
                return object;
            }
        }
    }

    public static class Str {
        public static boolean isEmpty(String value) {
            return (value == null) || value.isEmpty();
        }
    }
}
