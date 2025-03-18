import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class API {
  final baseUrl = 'http://api.weatherapi.com/v1';
  final apiKey = dotenv.env['weather']!;
  final currentWeather = '/current.json';
  final forecastWeather = '/forecast.json';
  String location = '';
  String days = '1';
  String aqi = 'yes';
  String alerts = 'no';
  API({required this.location});
  Future<dynamic> getCurrentWeather({required location}) async {
    var uri = Uri.parse('$baseUrl$currentWeather?key=$apiKey&q=$location');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data;
    } else {
      return 'error';
    }
  }

  Future<dynamic> getForecastWeather({required location}) async {
    var uri = Uri.parse(
        '$baseUrl$forecastWeather?key=$apiKey&q=$location&days=$days&aqi=$aqi&alerts=$alerts');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data;
    } else {
      return 'error';
    }
  }

  final Map<String, Map> cropState = {
    'wheat': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'barley': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'mustard': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'linseed': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'peas': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'gram': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'lentil': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'rice': {'Haryana': 1, 'Punjab': 0, 'UP': 1},
    'maize': {'Haryana': 1, 'Punjab': 0, 'UP': 1},
    'pigeonpeas': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'mothbeans': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'mungbean': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'blackgram': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'cotton': {'Haryana': 1, 'Punjab': 1, 'UP': 0},
    'jute': {'Haryana': 0, 'Punjab': 0, 'UP': 0},
    'sorghum': {'Haryana': 1, 'Punjab': 0, 'UP': 1},
    'pearl Millet': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'finger Millet': {'Haryana': 0, 'Punjab': 1, 'UP': 1},
    'soybean': {'Haryana': 1, 'Punjab': 0, 'UP': 1},
    'groundnut': {'Haryana': 1, 'Punjab': 0, 'UP': 1},
    'watermelon': {'Haryana': 1, 'Punjab': 0, 'UP': 1},
    'muskmelon': {'Haryana': 1, 'Punjab': 0, 'UP': 1},
    'cucumber': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'chickpea': {'Haryana': 1, 'Punjab': 1, 'UP': 1},
    'kidney Beans': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'pomegranate': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'banana': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'mango': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'grapes': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'apple': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'orange': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'papaya': {'Haryana': 0, 'Punjab': 0, 'UP': 1},
    'coconut': {'Haryana': 0, 'Punjab': 0, 'UP': 0},
    'coffee': {'Haryana': 0, 'Punjab': 0, 'UP': 0}
  };
  String canGrow(String crop, String location) {
    final Map<String, Map> cropStateLowercase = {};

    cropState.forEach((crop, states) {
      cropStateLowercase[crop.toLowerCase()] =
          states.map((state, value) => MapEntry(state.toLowerCase(), value));
    });
    if (cropState[crop.toLowerCase()] == null ||
        cropState[crop.toLowerCase()]![location] == null) {
      return 'No such crop found. Please try again.';
    }
    return cropState[crop.toLowerCase()]![location] == 1
        ? 'Yes you can'
        : 'No you cannot';
  }

  final functions = [
    {
      "type": "function",
      "function": {
        "name": "CropRegistration",
        "description":
            "Register or list a new crop with the farmer. They have to tell the crop, sowing date, and source of irrigation.",
        "parameters": {
          "type": "object",
          "properties": {
            "crop": {
              "type": "string",
              "description":
                  "The crop name, e.g. wheat, barley, etc. If not provided, then use 'null' as default."
            },
            "sowingDate": {
              "type": "string",
              "description":
                  "The date of sowing the crop, can be relative or in any format. If not provided, then use 'null' as default."
            },
            "SourceOfIrrigation": {
              "type": "string",
              "description":
                  "The source of irrigation used for the crop. If not provided, then use 'null' as default."
            },
          },
          "required": ["crop", "sowingDate", "SourceOfIrrigation"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "PestDiseaseRemedy",
        "description":
            "The farmer wants to know the remedy for a pest or disease in their crop or wants to see if the crop is healthy.",
        "parameters": {}
      }
    },
    {
      "type": "function",
      "function": {
        "name": "RecordCropLoss",
        "description":
            "Register a crop loss event as told by the farmer. They have to tell crop, and the percentage of loss.",
        "parameters": {
          "type": "object",
          "properties": {
            "crop": {
              "type": "string",
              "description":
                  "wheat,barley,mustard,linseed,peas,gram,lentil,rice,maize,pigeonpeas,mothbeans,mungbean,blackgram,cotton,jute,sorghum,pearl millet,coffee,etc. If not provided then use 'null' as default.",
              'default': 'null',
            },
            "loss": {
              "type": "number",
              "description":
                  "The percentage of loss of the crop. If not provided then use 'null' as default.",
              'default': 'null',
            }
          },
          "required": ["crop", "loss"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "getCurrentWeather",
        "description": "Get the current weather in a given location",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description": "The city and state, e.g. San Francisco, CA"
            },
          },
          "required": ["location"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "getForecastWeather",
        "description": "Get the forecast weather in a given location",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description": "The city and state, e.g. San Francisco, CA"
            },
          },
          "required": ["location"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "whatToGrow",
        "description":
            "The farmer wants to know what crops to grow at their location.",
        "parameters": {
          "type": "object",
          "properties": {
            "district": {
              "type": "string",
              "description":
                  "The district of Haryana state e.g. Rohtak, Gurgaon, Hisar, Ambala, Kurukshetra etc. that belongs to india. If not provided then use 'null' as default.",
              "default": "null"
            },
            "village": {
              "type": "string",
              "description":
                  "The village inside a district state e.g. Nasirpur, Hasanpur, Tejan etc. that belongs to india. If not provided then use 'null' as default.",
              "default": "null"
            }
          },
          "required": ["district", "village"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "canGrow",
        "description":
            "The farmer wants to know whether he can grow a given crop at a given location.",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description":
                  "State, e.g. Haryana. If not provided then use 'null' as default.",
              "default": "null"
            },
            "crop": {
              "type": "string",
              "description":
                  "wheat,barley,mustard,linseed,peas,gram,lentil,rice,maize,pigeonpeas,mothbeans,mungbean,blackgram,cotton,jute,sorghum,pearl millet,finger millet,soybean,groundnut,watermelon,muskmelon,cucumber,chickpeakidney,beans,pomegranate,banana,mango,grapes,watermelon,muskmelon,apple,orange,papaya,coconut,coffee. If not provided then use 'null' as default.",
              'default': 'null',
            },
          },
          "required": ["location", "crop"]
        }
      }
    },
  ];
}

class PredictionService {
  final String? predictionEndpoint = dotenv.env['endpoint'];
  final String predictionKey = dotenv.env['predict']!;

  Future<String> makePrediction(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final headers = {
      'Prediction-Key': predictionKey,
      'Content-Type': 'application/octet-stream',
    };

    try {
      final response = await http.post(
        Uri.parse(predictionEndpoint!),
        headers: headers,
        body: bytes,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final prediction = responseData['predictions'][0];
        if (prediction['probability'] >= 0.6 &&
            prediction['tagName'].toString().toLowerCase() != 'negative') {
          return prediction['tagName'];
        } else {
          return 'error: Wrong crop provided. Please try again.';
        }
      } else {
        return 'error: error in prediction service';
      }
    } catch (e) {
      return 'error: $e';
    }
  }
}
