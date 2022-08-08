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

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.text.format.DateUtils;
import android.util.Log;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.maps.android.ui.IconGenerator;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.Formatter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.lang.Exception;

import androidx.core.content.ContextCompat;
import androidx.security.crypto.MasterKeys;
import androidx.security.crypto.EncryptedSharedPreferences;
import edu.illinois.rokwire.maps.MapMarkerViewType;

import static android.view.View.GONE;
import static android.view.View.VISIBLE;

public class Utils {

    public static void showDialog(Context context, String title, String message,
                                  DialogInterface.OnClickListener positiveListener, String positiveText,
                                  DialogInterface.OnClickListener negativeListener, String negativeText,
                                  boolean cancelable) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title);
        builder.setMessage(message);
        builder.setCancelable(cancelable);

        if (positiveListener != null)
            builder.setPositiveButton(positiveText, positiveListener);

        if (negativeListener != null)
            builder.setNegativeButton(negativeText, negativeListener);

        AlertDialog alertDialog = builder.create();
        alertDialog.show();
    }

    public static class DateTime {

        static Date getDateTime(String dateTimeString) {
            if (dateTimeString == null || dateTimeString.isEmpty()) {
                return null;
            }
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
            Date dateTime = null;
            try {
                dateTime = dateFormat.parse(dateTimeString);
            } catch (ParseException e) {
                Log.e("Error", "Failed to parse '" + dateTimeString + "' to date time");
                e.printStackTrace();
            }
            return dateTime;
        }

        static String formatEventTime(Context context, Date dateTime) {
            if (dateTime == null) {
                return null;
            }
            Calendar calendarDate = Calendar.getInstance();
            int minutes = calendarDate.get(Calendar.MINUTE);
            Calendar today = Calendar.getInstance();
            calendarDate.setTime(dateTime);
            boolean zeroMins = (minutes == 0);
            boolean currentYear = calendarDate.get(Calendar.YEAR) == today.get(Calendar.YEAR);
            final String defaultStringFormat = String.format("%sMMM dd h%s a", (currentYear ? "" : "yy, "), (zeroMins ? "" : ":mm"));
            String defaultValue = new SimpleDateFormat(defaultStringFormat, Locale.getDefault()).format(dateTime);
            SimpleDateFormat dateFormat;
            String datePrefix;
            String timeSuffix;
            String format = zeroMins ? "h a" : "h:mm a";
            dateFormat = new SimpleDateFormat(format, Locale.getDefault());
            timeSuffix = dateFormat.format(dateTime);
            boolean isToday = DateUtils.isToday(dateTime.getTime());
            if (isToday) {
                datePrefix = context.getString(R.string.today) + " " + context.getString(R.string.at);
            } else if (calendarDate.after(today)) {
                int dateDayOfYear = calendarDate.get(Calendar.DAY_OF_YEAR);
                int todayDateOfYear = today.get(Calendar.DAY_OF_YEAR);
                int dateDiff = (dateDayOfYear - todayDateOfYear);
                boolean sameYear = (today.get(Calendar.YEAR) == calendarDate.get(Calendar.YEAR));
                if ((dateDiff == 1) && sameYear) {
                    datePrefix = context.getString(R.string.tomorrow) + " " + context.getString(R.string.at);
                } else if ((dateDiff < 7) && sameYear) {
                    dateFormat = new SimpleDateFormat("EEEE", Locale.getDefault());
                    datePrefix = dateFormat.format(dateTime) + " " + context.getString(R.string.at);
                } else {
                    return defaultValue;
                }
            } else {
                return defaultValue;
            }
            return String.format("%s %s", datePrefix, timeSuffix);
        }

        public static long getCurrentTimeMillisSince1970() {
            return System.currentTimeMillis();
        }
    }

    public static class Explore {

        public static HashMap optLocation(HashMap explore) {
            if (explore == null) {
                return null;
            }

            Object locationObj = explore.get("location");
            if (locationObj instanceof HashMap) {
                return (HashMap) locationObj;
            }

            Object lotEntranceObj = explore.get("entrance");
            if (lotEntranceObj instanceof HashMap) {
                return (HashMap) lotEntranceObj;
            }

            Object sectionObj = explore.get("coursesection");
            if (sectionObj instanceof HashMap) {
                HashMap sectionMap = (HashMap) sectionObj;
                Object buildingObj = sectionMap.get("building");
                if (buildingObj instanceof HashMap) {
                    return (HashMap) buildingObj;
                }
            }

            return null;
        }

        public static Integer optLocationFloor(HashMap explore) {
            if (explore == null) {
                return null;
            }
            HashMap location = optLocation(explore);
            return optFloor(location);
        }

        public static Integer optFloor(HashMap location) {
            if (location == null) {
                return null;
            }
            Object floorObj = location.get("floor");
            if (floorObj instanceof Integer) {
                return (Integer) floorObj;
            }
            return null;
        }

        public static LatLng optLocationLatLng(HashMap explore) {
            if (explore == null) {
                return null;
            }
            ExploreType exploreType = getExploreType(explore);
            if (exploreType == ExploreType.PARKING) {
                // Json Example:
                // {"lot_id":"647b7211-9cdf-412b-a682-1fdb68897f86","lot_name":"SFC - E-14 Lot - Illinois","lot_address1":"1800 S. First Street, Champaign, IL 61820","total_spots":"1710","entrance":{"latitude":40.096691,"longitude":-88.238179},"polygon":[{"latitude":40.097938,"longitude":-88.241409},{"latitude":40.09793,"longitude":-88.238657},{"latitude":40.094742,"longitude":-88.238651},{"latitude":40.094733,"longitude":-88.240223},{"latitude":40.095148,"longitude":-88.240245},{"latitude":40.095181,"longitude":-88.24113},{"latitude":40.095636,"longitude":-88.241135},{"latitude":40.095636,"longitude":-88.241393}],"spots_sold":0,"spots_pre_sold":0}
                Object lotEntranceObj = explore.get("entrance");
                if (lotEntranceObj instanceof HashMap) {
                    HashMap lotEntranceMap = (HashMap)lotEntranceObj;
                    return optLatLng(lotEntranceMap);
                }
            } else if (exploreType == ExploreType.STUDENT_COURSE) {
                Object sectionObj = explore.get("coursesection");
                if (sectionObj instanceof HashMap) {
                    HashMap sectionMap = (HashMap)sectionObj;

                    Object buildingObj = sectionMap.get("building");
                    if (buildingObj instanceof HashMap) {
                        HashMap buildingMap = (HashMap)buildingObj;

                        return optLatLng(buildingMap);
                    }
                }
            } else {
                HashMap location = optLocation(explore);
                return optLatLng(location);
            }
            return null;
        }

        public static LatLng optLatLng(HashMap location) {
            if (location == null) {
                return null;
            }
            Object latObj = location.get("latitude");
            Object lngObj = location.get("longitude");
            if (!(latObj instanceof Double) || !(lngObj instanceof Double)) {
                return null;
            }
            return new LatLng((Double) latObj, (Double) lngObj);
        }

        public static Integer optMarkerLocationFloor(Marker marker) {
            JSONObject tag = optMarkerTagJson(marker);
            Object markerRawData = (tag != null) ? tag.opt("raw_data") : null;
            HashMap exploreMap = null;
            if (markerRawData instanceof HashMap) {
                exploreMap = (HashMap) markerRawData;
            } else if (markerRawData instanceof ArrayList) {
                ArrayList explores = (ArrayList) markerRawData;
                if (explores.size() > 0) {
                    Object exploreObj = explores.get(0);
                    if (exploreObj instanceof HashMap) {
                        exploreMap = (HashMap) exploreObj;
                    }
                }
            }
            return optLocationFloor(exploreMap);
        }

        public static boolean optSingleExploreMarker(Marker marker) {
            JSONObject markerTagJson = optMarkerTagJson(marker);
            if (markerTagJson == null) {
                return false;
            }
            return markerTagJson.optBoolean("single_explore", false);
        }

        public static MarkerOptions constructMarkerOptions(Context context, Object markerRawObject, View markerLayoutView, View markerGroupLayoutView, IconGenerator iconGenerator) {
            if (markerRawObject == null || markerLayoutView == null || markerGroupLayoutView == null || iconGenerator == null) {
                return null;
            }
            MapMarkerViewType mapMarkerViewType;
            HashMap singleExploreMap = null;
            ArrayList groupExploresJson = null;
            if (markerRawObject instanceof HashMap) {
                mapMarkerViewType = MapMarkerViewType.SINGLE;
                singleExploreMap = (HashMap) markerRawObject;
            } else if (markerRawObject instanceof ArrayList) {
                mapMarkerViewType = MapMarkerViewType.GROUP;
                groupExploresJson = (ArrayList) markerRawObject;
                Object singleObject = groupExploresJson.get(0);
                if (singleObject instanceof HashMap) {
                    singleExploreMap = (HashMap) singleObject;
                }
            } else {
                mapMarkerViewType = MapMarkerViewType.UNKNOWN;
            }
            if (mapMarkerViewType == MapMarkerViewType.UNKNOWN) {
                return null;
            }
            LatLng markerLocation = optLocationLatLng(singleExploreMap);
            if (markerLocation == null) {
                return null;
            }
            String markerTitle = getMarkerTitle(mapMarkerViewType, singleExploreMap, groupExploresJson);
            MarkerOptions markerOptions = new MarkerOptions();
            markerOptions.position(markerLocation);
            markerOptions.zIndex(1);
            markerOptions.title(markerTitle);
            ExploreType exploreType = getExploreType(markerRawObject);
            Bitmap markerIcon;
            if (mapMarkerViewType == MapMarkerViewType.SINGLE) {
                String markerSnippet = getMarkerSnippet(context, singleExploreMap);
                if (markerSnippet != null && !markerSnippet.isEmpty()) {
                    markerOptions.snippet(markerSnippet);
                }
                int iconResource = getSingleExploreIconResource(exploreType);
                TextView markerTitleView = markerLayoutView.findViewById(R.id.markerTitleView);
                markerTitleView.setText(markerTitle);
                TextView markerSnippetView = markerLayoutView.findViewById(R.id.markerSnippetView);
                markerSnippetView.setText(markerSnippet);
                boolean snippetViewVisible = ((markerSnippet != null) && !markerSnippet.isEmpty());
                markerSnippetView.setVisibility(snippetViewVisible ? VISIBLE : GONE);
                ImageView iconImageView = markerLayoutView.findViewById(R.id.markerIconView);
                iconImageView.setImageResource(iconResource);
                iconGenerator.setContentView(markerLayoutView);
                markerIcon = iconGenerator.makeIcon();
            } else {
                TextView markerTitleView = markerGroupLayoutView.findViewById(R.id.markerGroupTitleView);
                markerTitleView.setText(markerTitle);
                String descrLabel = getGroupExploresDescrLabel(context, markerTitle, exploreType);
                TextView markerDescrView = markerGroupLayoutView.findViewById(R.id.markerGroupDescrView);
                markerDescrView.setText(descrLabel);
                ImageView markerCircleView = markerGroupLayoutView.findViewById(R.id.markerGroupCircleView);
                Drawable circleViewBackground = markerCircleView.getBackground();
                if (circleViewBackground instanceof GradientDrawable) {
                    int exploreGroupColor = getExploreColorResource(exploreType);
                    GradientDrawable gradientDrawable = (GradientDrawable) circleViewBackground;
                    gradientDrawable.setColor(ContextCompat.getColor(context, exploreGroupColor));
                }
                iconGenerator.setContentView(markerGroupLayoutView);
                markerIcon = iconGenerator.makeIcon();
            }
            if (markerIcon != null) {
                markerOptions.icon(BitmapDescriptorFactory.fromBitmap(markerIcon));
            }
            return markerOptions;
        }

        public static void updateCustomMarkerAppearance(Context context, Marker marker,
                                                        boolean singleExploreMarker, float currentCameraZoom, float previousCameraZoom,
                                                        View markerLayoutView, View markerGroupLayoutView, IconGenerator iconGenerator) {
            if (marker == null) {
                return;
            }
            float minCurrentZoom = Math.min(currentCameraZoom, previousCameraZoom);
            float maxCurrentZoom = Math.max(currentCameraZoom, previousCameraZoom);
            boolean changeMarkerIcon = false;
            //Check if title threshold passed
            if ((minCurrentZoom <= Constants.FIRST_THRESHOLD_MARKER_ZOOM) &&
                    (Constants.FIRST_THRESHOLD_MARKER_ZOOM < maxCurrentZoom)) {
                boolean passedFirstThreshold = (currentCameraZoom >= Constants.FIRST_THRESHOLD_MARKER_ZOOM);
                if (singleExploreMarker) {
                    int textVisibility = passedFirstThreshold ? View.VISIBLE : View.GONE;
                    View textFrameView = markerLayoutView.findViewById(R.id.markerTextFrame);
                    textFrameView.setVisibility(textVisibility);
                    if (passedFirstThreshold) {
                        String shortTitle = Utils.Explore.optExploreMarkerShortTitle(marker);
                        TextView markerTitleView = markerLayoutView.findViewById(R.id.markerTitleView);
                        String markerTitle = marker.getTitle();
                        markerTitleView.setText(shortTitle != null ? shortTitle : markerTitle);
                    }
                } else {
                    ImageView markerGroupCircleView = markerGroupLayoutView.findViewById(R.id.markerGroupCircleView);
                    int imageViewSize = context.getResources().getDimensionPixelSize(passedFirstThreshold ? R.dimen.group_marker_image_size_first : R.dimen.group_marker_image_size_zero);
                    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(imageViewSize, imageViewSize);
                    markerGroupCircleView.setLayoutParams(layoutParams);
                    TextView markerGroupTitleView = markerGroupLayoutView.findViewById(R.id.markerGroupTitleView);
                    String markerTitle = marker.getTitle();
                    markerGroupTitleView.setText(markerTitle);
                }
                changeMarkerIcon = true;
            }
            //Check if snippet threshold passed
            if ((minCurrentZoom <= Constants.SECOND_THRESHOLD_MARKER_ZOOM) &&
                    (Constants.SECOND_THRESHOLD_MARKER_ZOOM < maxCurrentZoom)) {
                boolean passedSecondThreshold = (currentCameraZoom > Constants.SECOND_THRESHOLD_MARKER_ZOOM);
                if (singleExploreMarker) {
                    TextView markerTitleView = markerLayoutView.findViewById(R.id.markerTitleView);
                    String markerTitle = marker.getTitle();
                    String shortTitle = Utils.Explore.optExploreMarkerShortTitle(marker);
                    markerTitleView.setText(passedSecondThreshold ? markerTitle : shortTitle);
                } else {
                    ImageView markerGroupCircleView = markerGroupLayoutView.findViewById(R.id.markerGroupCircleView);
                    int imageViewSize = context.getResources().getDimensionPixelSize(passedSecondThreshold ? R.dimen.group_marker_image_size_second : R.dimen.group_marker_image_size_first);
                    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(imageViewSize, imageViewSize);
                    markerGroupCircleView.setLayoutParams(layoutParams);
                    TextView markerGroupTitleView = markerGroupLayoutView.findViewById(R.id.markerGroupTitleView);
                    String markerTitle = marker.getTitle();
                    markerGroupTitleView.setText(markerTitle);
                    TextView groupDescrView = markerGroupLayoutView.findViewById(R.id.markerGroupDescrView);
                    String markerDescription = Utils.Explore.optExploreMarkerDescrLabel(marker);
                    groupDescrView.setText(markerDescription);
                    int descrVisibility = passedSecondThreshold ? View.VISIBLE : View.GONE;
                    groupDescrView.setVisibility(descrVisibility);
                }
                changeMarkerIcon = true;
            }
            //Change Marker icon only if needed
            if (changeMarkerIcon) {
                iconGenerator.setContentView(singleExploreMarker ? markerLayoutView : markerGroupLayoutView);
                Bitmap icon = iconGenerator.makeIcon();
                marker.setIcon(BitmapDescriptorFactory.fromBitmap(icon));
            }
        }

        public static JSONObject constructMarkerTagJson(Context context, String markerTitle, Object markerRawData) {
            boolean singleExploreMarker = (markerRawData instanceof HashMap);
            String shortTitle = (markerTitle != null && markerTitle.length() > Constants.MARKER_TITLE_MAX_SYMBOLS_NUMBER) ?
                    String.format("%s...", markerTitle.substring(0, 15)) : markerTitle;
            JSONObject markerTagJson = new JSONObject();
            try {
                markerTagJson.put("title", markerTitle);
                markerTagJson.put("short_title", shortTitle);
                markerTagJson.put("raw_data", markerRawData);
                markerTagJson.put("single_explore", singleExploreMarker);
                if (!singleExploreMarker) {
                    ExploreType exploreType = getExploreType(markerRawData);
                    markerTagJson.put("description", getGroupExploresDescrLabel(context, markerTitle, exploreType));
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return markerTagJson;
        }

        public static Object optExploreMarkerRawData(Marker marker) {
            JSONObject markerTagJson = optMarkerTagJson(marker);
            return (markerTagJson != null) ? markerTagJson.opt("raw_data") : null;
        }

        private static String optExploreMarkerShortTitle(Marker marker) {
            JSONObject markerTagJson = optMarkerTagJson(marker);
            return (markerTagJson != null) ? markerTagJson.optString("short_title", null) : null;
        }

        private static String optExploreMarkerDescrLabel(Marker marker) {
            JSONObject markerTagJson = optMarkerTagJson(marker);
            return (markerTagJson != null) ? markerTagJson.optString("description", null) : null;
        }

        public static HashMap createLocationMap(LatLng latLng) {
            if (latLng == null) {
                return null;
            }
            HashMap<String, Object> location = new HashMap<>();
            location.put("latitude", latLng.latitude);
            location.put("longitude", latLng.longitude);
            return location;
        }

        public static ExploreType getExploreType(Object explore) {
            HashMap singleExplore = null;
            if (explore instanceof HashMap) {
                singleExplore = (HashMap) explore;
            } else if (explore instanceof ArrayList) {
                ArrayList explores = (ArrayList) explore;
                if (explores.size() > 0) {
                    Object firstExploreObj = explores.get(0);
                    if (firstExploreObj instanceof HashMap) {
                        singleExplore = (HashMap) firstExploreObj;
                    }
                }
            }
            if (singleExplore == null) {
                return ExploreType.UNKNOWN;
            }
            if (singleExplore.get("eventId") != null) {
                return ExploreType.EVENT;
            } else if (singleExplore.get("DiningOptionID") != null) {
                return ExploreType.DINING;
            } else if (singleExplore.get("campus_name") != null) {
                return ExploreType.LAUNDRY;
            } else if (singleExplore.get("lot_id") != null) {
                return ExploreType.PARKING;
            } else if (singleExplore.get("coursetitle") != null) {
                return ExploreType.STUDENT_COURSE;
            } else {
                return ExploreType.UNKNOWN;
            }
        }

        public static List<LatLng> getExplorePolygon(Object explore) {
            if (getExploreType(explore) != ExploreType.PARKING) {
                return null;
            }
            HashMap parkingLot = (HashMap) explore;
            Object polygonObject = parkingLot.get("polygon");
            if (!(polygonObject instanceof List)) {
                return null;
            }
            List<HashMap> polygonMaps = (List) polygonObject;
            if (polygonMaps.isEmpty()) {
                return null;
            }
            List<LatLng> polygonPoints = new ArrayList<>();
            for (HashMap point : polygonMaps) {
                double latitude = Utils.Map.getValueFromPath(point, "latitude", 0.0d);
                double longitude = Utils.Map.getValueFromPath(point, "longitude", 0.0d);
                LatLng latLng = new LatLng(latitude, longitude);
                polygonPoints.add(latLng);
            }
            return polygonPoints;
        }

        public static int getExploreColorResource(ExploreType exploreType) {
            int colorResource;
            switch (exploreType) {
                case EVENT:
                    colorResource = R.color.illinois_orange;
                    break;
                case DINING:
                    colorResource = R.color.mongo;
                    break;
                default:
                    colorResource = R.color.teal;
                    break;
            }
            return colorResource;
        }

        private static String getMarkerTitle(MapMarkerViewType mapMarkerViewType, HashMap singleExploreMap, ArrayList groupExploresList) {
            String markerTitle;
            if (mapMarkerViewType == MapMarkerViewType.SINGLE) {
                ExploreType exporeType = getExploreType(singleExploreMap);
                if (exporeType == ExploreType.PARKING) {
                    // Json Example:
                    // {"lot_id":"647b7211-9cdf-412b-a682-1fdb68897f86","lot_name":"SFC - E-14 Lot - Illinois","lot_address1":"1800 S. First Street, Champaign, IL 61820","total_spots":"1710","entrance":{"latitude":40.096691,"longitude":-88.238179},"polygon":[{"latitude":40.097938,"longitude":-88.241409},{"latitude":40.09793,"longitude":-88.238657},{"latitude":40.094742,"longitude":-88.238651},{"latitude":40.094733,"longitude":-88.240223},{"latitude":40.095148,"longitude":-88.240245},{"latitude":40.095181,"longitude":-88.24113},{"latitude":40.095636,"longitude":-88.241135},{"latitude":40.095636,"longitude":-88.241393}],"spots_sold":0,"spots_pre_sold":0}
                    markerTitle = (String) singleExploreMap.get("lot_name");
                } if (exporeType == ExploreType.STUDENT_COURSE) {
                    markerTitle = (String) singleExploreMap.get("coursetitle");
                } else {
                    markerTitle = (String) singleExploreMap.get("title");
                }
            } else {
                markerTitle = String.valueOf(groupExploresList.size());
            }
            return markerTitle;
        }

        private static String getMarkerSnippet(Context context, HashMap exploreMap) {
            if (exploreMap == null) {
                return null;
            }

            ExploreType exporeType = getExploreType(exploreMap);
            if (exporeType == ExploreType.EVENT) {
                String startDateToString = (String) exploreMap.get("startDateLocal");
                if (startDateToString != null && !startDateToString.isEmpty()) {
                    Date eventStartDate = DateTime.getDateTime(startDateToString);
                    return DateTime.formatEventTime(context, eventStartDate);
                }
            }
            else if (exporeType == ExploreType.LAUNDRY) {
                return (String) exploreMap.get("status");
            }
            else if (exporeType == ExploreType.STUDENT_COURSE) {
                Object sectionObj = exploreMap.get("coursesection");
                if (sectionObj instanceof HashMap) {
                    String result = "";
                    HashMap sectionMap = (HashMap)sectionObj;

                    String building = (String) sectionMap.get("buildingname");
                    if (building != null) {
                        if (0 < result.length()) {
                            result += " ";
                        }
                        result += building;
                    }

                    String room = (String) sectionMap.get("room");
                    if (room != null) {
                        if (0 < result.length()) {
                            result += " ";
                        }
                        result += "(" + room + ")";
                    }

                    String instructionType = (String) sectionMap.get("instructiontype");
                    if (instructionType != null) {
                        if (0 < result.length()) {
                            result += " ";
                        }
                        result += instructionType;
                    }

                    return result;
                }
            }

            return null;
        }

        private static int getSingleExploreIconResource(ExploreType exploreType) {
            int iconResource;
            switch (exploreType) {
                case EVENT:
                    iconResource = R.drawable.marker_event;
                    break;
                case DINING:
                    iconResource = R.drawable.marker_dining;
                    break;
                default:
                    iconResource = R.drawable.marker_default_teal;
                    break;
            }
            return iconResource;
        }

        private static String getGroupExploresDescrLabel(Context context, String exploresCountString, ExploreType exploreType) {
            String groupDescrLabel = "";
            if (exploresCountString != null) {
                String typeSuffix;
                switch (exploreType) {
                    case EVENT:
                        typeSuffix = context.getString(R.string.events);
                        break;
                    case DINING:
                        typeSuffix = context.getString(R.string.dinings);
                        break;
                    case LAUNDRY:
                        typeSuffix = context.getString(R.string.laundries);
                        break;
                    case PARKING:
                        typeSuffix = context.getString(R.string.parkings);
                        break;
                    case STUDENT_COURSE:
                        typeSuffix = context.getString(R.string.student_courses);
                        break;
                    default:
                        typeSuffix = context.getString(R.string.explores);
                        break;
                }
                groupDescrLabel = exploresCountString + " " + typeSuffix;
            }
            return groupDescrLabel;
        }

        private static JSONObject optMarkerTagJson(Marker marker) {
            if (marker == null) {
                return null;
            }
            Object markerTag = marker.getTag();
            if (!(markerTag instanceof JSONObject)) {
                return null;
            }
            return (JSONObject) markerTag;
        }
    }

    public static class Location {

        public static Double getDistanceBetween(LatLng firstLatLng, LatLng secondLatLng) {
            if (firstLatLng == null || secondLatLng == null) {
                return null;
            }
            android.location.Location firstLocation = new android.location.Location("firstLatLng");
            firstLocation.setLatitude(firstLatLng.latitude);
            firstLocation.setLongitude(firstLatLng.longitude);
            android.location.Location secondLocation = new android.location.Location("secondLatLng");
            secondLocation.setLatitude(secondLatLng.latitude);
            secondLocation.setLongitude(secondLatLng.longitude);
            float distance = firstLocation.distanceTo(secondLocation);
            return (double) distance;
        }
    }

    public static class Map {

        public static String getValueFromPath(Object object, String path, String defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof String) ? (String)valueObject : defaultValue;
        }

        public static int getValueFromPath(Object object, String path, int defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Integer) ? (Integer) valueObject : defaultValue;
        }

        public static long getValueFromPath(Object object, String path, long defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Long) ? (Long) valueObject : defaultValue;
        }

        public static double getValueFromPath(Object object, String path, double defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Double) ? (Double) valueObject : defaultValue;
        }

        public static boolean getValueFromPath(Object object, String path, boolean defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Boolean) ? (Boolean) valueObject : defaultValue;
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

        public static String nullIfEmpty(String value) {
            if (isEmpty(value)) {
                return null;
            }
            return value;
        }

        public static byte[] hexStringToByteArray(String s) {
            if(s != null) {
                int len = s.length();
                byte[] data = new byte[len / 2];
                for (int i = 0; i < len; i += 2) {
                    data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                            + Character.digit(s.charAt(i + 1), 16));
                }
                return data;
            }
            return null;
        }

        public static String byteArrayToHexString(byte[] bytes){
            if(bytes != null) {
                Formatter formatter = new Formatter();
                for (byte b : bytes) {
                    formatter.format("%02x", b);
                }
                return formatter.toString();
            }
            return null;
        }
    }

    public static class Guid {
        public static byte[] bytesFromUUID(UUID uuid) {
            ByteBuffer bb = ByteBuffer.wrap(new byte[16]);
            bb.putLong(uuid.getMostSignificantBits());
            bb.putLong(uuid.getLeastSignificantBits());

            return bb.array();
        }

        public static UUID UUIDFromBytes(byte[] bytes) {
            ByteBuffer byteBuffer = ByteBuffer.wrap(bytes);
            long high = byteBuffer.getLong();
            long low = byteBuffer.getLong();

            return new UUID(high, low);
        }
    }

    public static class Base64 {

        public static byte[] decode(String value) {
            if (value != null) {
                return android.util.Base64.decode(value, android.util.Base64.NO_WRAP);
            } else {
                return null;
            }
        }

        public static String encode(byte[] bytes) {
            if (bytes != null) {
                return android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP);
            } else {
                return null;
            }
        }
    }

    public static class AppSharedPrefs {

        public static boolean getBool(Context context, String key, boolean defaults) {
            if ((context == null) || Str.isEmpty(key)) {
                return defaults;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(Constants.DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            return sharedPreferences.getBoolean(key, defaults);
        }

        public static void saveBool(Context context, String key, boolean value) {
            if ((context == null) || Str.isEmpty(key)) {
                return;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(Constants.DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.putBoolean(key, value);
            editor.apply();
        }
    }

    public static class AppSecureSharedPrefs {

        public static String getString(Context context, String key, String defaults) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        Constants.SECURE_SHARED_PREFS_FILE_NAME,
                        MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC),
                        context,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    return sharedPreferences.getString(key, defaults);
                }
                catch (Exception e) {
                    Log.e("Error", "Failed to create EncryptedSharedPreferences");
                    e.printStackTrace();
                }
            }
            return defaults;
        }

        public static void saveString(Context context, String key, String value) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        Constants.SECURE_SHARED_PREFS_FILE_NAME,
                        MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC),
                        context,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    SharedPreferences.Editor editor = sharedPreferences.edit();
                    editor.putString(key, value);
                    editor.apply();
                }
                catch (Exception e) {
                    Log.e("Error", "Failed to create EncryptedSharedPreferences");
                    e.printStackTrace();
                }
            }
        }

    }

    public enum ExploreType {
        EVENT, DINING, LAUNDRY, PARKING, STUDENT_COURSE, UNKNOWN
    }
}
