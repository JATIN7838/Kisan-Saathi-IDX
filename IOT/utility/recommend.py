import pandas as pd
import geocoder
from datetime import datetime
from utility.fb import FirebaseManager
import json
import http.client


class API:
    def __init__(self,weather_api_key):
        self.baseUrl = 'http://api.weatherapi.com/v1'
        self.apiKey = weather_api_key
        self.currentWeather = '/current.json'
        self.forecastWeather = '/forecast.json'
        self.days = '1'
        self.aqi = 'yes'
        self.alerts = 'no'

    def getCurrentWeather(self, latitude, longitude):
        uri = f'{self.baseUrl}{self.currentWeather}?key={self.apiKey}&q={latitude},{longitude}'
        connection = http.client.HTTPSConnection("api.weatherapi.com")
        connection.request("GET", uri)
        response = connection.getresponse()
        if response.status == 200:
            data = json.loads(response.read().decode("utf-8"))
            return data
        else:
            return 'error'


def fetch_quality(lat, long):
    df_quality = pd.read_csv("/home/jatin/Desktop/coding/datasets/water quality.csv")
    df_quality['distance'] = ((df_quality['Latitude'] - lat)
                              ** 2 + (df_quality['Longitude'] - long) ** 2) ** 0.5
    return int(df_quality.sort_values('distance').reset_index(drop=True).loc[0, 'WQL Category'])


def fetch_groundwater_rainfall(lat, long):
    df_rain = pd.read_csv('/home/jatin/Desktop/coding/datasets/district rainfall.csv')
    df_rain['distance'] = ((df_rain['Latitude'] - lat) **
                           2 + (df_rain['Longitude'] - long) ** 2) ** 0.5
    df_rain = df_rain.sort_values('distance').reset_index(drop=True)
    return int(df_rain.loc[0, 'Groundwater']), int(df_rain.loc[0, 'Rainfall'])


def generate_table(crops, lat, long):
    crops = {i: {'Rainfall': 0, 'Groundwater': 0, 'Water Quality': 0}
             for i in crops}
    df_npk = pd.read_csv("/home/jatin/Desktop/coding/datasets/crop data.csv")
    for crop in crops:
        rain_req = int(
            df_npk[df_npk['Crop'] == crop].reset_index().loc[0, 'rainfall_category'])
        gnd, rain_curr = fetch_groundwater_rainfall(lat, long)
        water_quality = fetch_quality(lat, long)
        if rain_req == 2:
            if gnd == 2:
                crops[crop]['Groundwater'] = 1
            elif gnd == 1:
                crops[crop]['Groundwater'] = 0
            else:
                crops[crop]['Groundwater'] = -1
            if rain_curr == 2:
                crops[crop]['Rainfall'] = 1
            elif rain_curr == 1:
                crops[crop]['Rainfall'] = 0
            else:
                crops[crop]['Rainfall'] = -1
        elif rain_req == 1:
            if gnd == 2:
                crops[crop]['Groundwater'] = 1
            elif gnd == 1:
                crops[crop]['Groundwater'] = 0
            else:
                crops[crop]['Groundwater'] = -1
            if rain_curr == 2:
                crops[crop]['Rainfall'] = 1
            elif rain_curr == 1:
                crops[crop]['Rainfall'] = 0
            else:
                crops[crop]['Rainfall'] = -1
        else:
            if gnd == 2:
                crops[crop]['Groundwater'] = 1
            elif gnd == 1:
                crops[crop]['Groundwater'] = 1
            else:
                crops[crop]['Groundwater'] = 1
            if rain_curr == 2:
                crops[crop]['Rainfall'] = 1
            elif rain_curr == 1:
                crops[crop]['Rainfall'] = 1
            else:
                crops[crop]['Rainfall'] = 1
        if water_quality == 2:
            crops[crop]['Water Quality'] = 1
        elif water_quality == 1:
            crops[crop]['Water Quality'] = 0
        else:
            crops[crop]['Water Quality'] = -1

    crops_dict = {key: sum(value.values()) for key, value in crops.items()}
    crops_dict = dict(
        sorted(crops_dict.items(), key=lambda x: x[1], reverse=True))
    crops_dict = {crop: crops[crop] for crop in crops_dict.keys()}
    for value in crops_dict.values():
        for key in value:
            if value[key] == 1:
                value[key] = 'Good'
            elif value[key] == 0:
                value[key] = 'Moderate'
            else:
                value[key] = 'Bad'
    return crops_dict


def arrange_crops_sustain(params, df_npk, crops):
    n, p, k = params[0], params[1], params[2]
    crop_dict = {i: 0 for i in crops}
    for crop in crop_dict:
        crop_dict[crop] = {'N': 0, 'P': 0, 'K': 0}
        df_crop = df_npk[df_npk['Crop'] == crop].copy().reset_index(drop=True)
        if df_crop.loc[0, 'N_min'] <= n and df_crop.loc[0, 'N_max'] >= n:
            crop_dict[crop]['N'] += 2
        if df_crop.loc[0, 'P_min'] <= p and df_crop.loc[0, 'P_max'] >= p:
            crop_dict[crop]['P'] += 1
        if df_crop.loc[0, 'K_min'] <= k and df_crop.loc[0, 'K_max'] >= k:
            crop_dict[crop]['K'] += 1.5
    crop_dict = {key: sum(value.values()) for key, value in crop_dict.items()}
    crop_dict = dict(
        sorted(crop_dict.items(), key=lambda x: x[1], reverse=True))
    crops = list(crop_dict.keys())
    return crops


def recommend_crops(params, approach=0):
    api = API()
    geo = geocoder.ip('me')
    firebase=FirebaseManager()
    lat, long = geo.geojson['features'][0]['properties']['lat'], geo.geojson['features'][0]['properties']['lng']
    weather_data = api.getCurrentWeather(lat, long)
    humidity = weather_data['current']['humidity']
    temp, ph = params[3], params[4]
    df_npk = pd.read_csv("/home/jatin/Desktop/coding/datasets/crop data.csv")
    df_npk = df_npk.iloc[:, :-3].copy()
    df_npk['Sowing_min'].unique()
    month_dict = {'January': 1, 'February': 2, 'March': 3, 'April': 4, 'May': 5, 'June': 6,
                  'July': 7, 'August': 8, 'September': 9, 'October': 10, 'November': 11, 'December': 12, 'all': 0}
    df_npk['Sowing_min'] = df_npk['Sowing_min'].map(month_dict)
    df_npk['Sowing_max'] = df_npk['Sowing_max'].map(month_dict)
    current_month = datetime.now().month
    df_npk = df_npk[(df_npk['Sowing_min'] <= current_month) & (
        df_npk['Sowing_max'] >= current_month)].reset_index(drop=True)
    crop_dict = {i: 0 for i in df_npk['Crop']}
    for crop in crop_dict:
        crop_dict[crop] = {'temperature': 0, 'humidity': 0, 'ph': 0}
        df = df_npk[df_npk['Crop'] == crop].reset_index(drop=True)
        if df.loc[0, f'temperature_min'] <= temp and df.loc[0, f'temperature_max'] >= temp:
            crop_dict[crop]['temperature'] += 1
        if df.loc[0, f'humidity_min'] <= humidity and df.loc[0, f'humidity_max'] >= humidity:
            crop_dict[crop]['humidity'] += 1
        if df.loc[0, f'ph_min'] <= ph and df.loc[0, f'ph_max'] >= ph:
            crop_dict[crop]['ph'] += 1
    crop_dict = {key: sum(value.values()) for key, value in crop_dict.items()}
    crop_dict = dict(
        sorted(crop_dict.items(), key=lambda x: x[1], reverse=True))
    crops = list(crop_dict.keys())
    if approach == 0:
        crops = arrange_crops_sustain(params, df_npk, list(crop_dict.keys()))
    crops=crops[:5]
    crop_data= generate_table(crops, lat, long)
    df_cost=pd.read_csv('/home/jatin/Desktop/coding/datasets/crop capital.csv')
    for crop in crops:
        cc=df_cost[df_cost['Crop']==crop].reset_index(drop=True)
        if len(cc)==0:
            print(crop)
            continue
        crop_data[crop]['Cost']=int(cc.loc[0,'Cost per area'])
        crop_data[crop]['Income']=int(cc.loc[0,'MSP']*cc.loc[0,'Yield per area'])
    crop_data['timestamp']=datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    firebase.set_document('IOT','Crop Recommendation',crop_data)
    return generate_table(crops, lat, long)