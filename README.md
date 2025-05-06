# **Kisan Sathi - AI-Powered Agricultural Assistance Platform**

Kisan Sathi is an AI-powered agricultural assistant designed to help farmers with crop management, loss assessment, recommendations, government schemes, and return on investment (ROI) estimation. It integrates **voice-based interaction, geotagging, AI classification, GIS, and multilingual support** for an enhanced farming experience.
![image](https://github.com/user-attachments/assets/6ec1a43b-643d-49ff-b9e8-83a8ebd42f29)

## 🚀 **Features & Functionalities**

### **🌾 Crop Registration**  
- Farmers can **use a voice assistant** to answer queries like:  
  - "Kitne din pehle maine kheti kari thi?" *(How many days ago did I cultivate my field?)*  
  - "Maine kya boya tha?" *(What did I plant?)*  
  - "Source of irrigation kya hai?" *(What is the source of irrigation?)*  
- After answering, the user must **upload a field image**.  
- The image will be **geotagged** and stored with the provided details in the backend.  
- **Admin Panel**: Stores and displays all crop registrations with images and location details.

 ![image](https://github.com/user-attachments/assets/4e3b430c-5a20-48f8-a2d7-de732ae94d15)

### **🌱 Crop Loss Assessment**  
- Farmers can **report crop loss using voice input**, e.g.:  
  - *"Mera nuksan ho gaya"* *(I have suffered a loss)*  
- The system asks additional queries regarding the crop condition.  
- Farmers must **upload an image** of the affected crop.  
- AI-based classification identifies **crop diseases** and informs the farmer.  
- The image and assessment are stored in the backend.  
- **Admin Panel**: Displays reported losses along with images and diagnosis.  

### **🌿 Crop Recommendation System**  
- Farmers can ask:  
  - *"Main kya uga sakta hu?"* *(What can I grow?)*  
- The system considers:  
  - **User-provided location** *(if given)*  
  - **Automatic location access** *(if permission granted)*  
  - **Season, water usage, soil type, and other factors**  
- Based on this data, the system **recommends the best crops** for the farmer’s land. 

![image](https://github.com/user-attachments/assets/9cd58fd0-9322-45cd-8288-1bc889dec0ea)

### **🏦 Government Scheme Suggestions**  
- Farmers can **ask about available schemes**.  
- Based on the query, the system provides **the top 3 most relevant government schemes** for the farmer.  

![image](https://github.com/user-attachments/assets/6a378606-6624-4851-8305-f5d1b77891f2)

### **💰 ROI Estimation**  
- Farmers can calculate their **expected return on investment (ROI)** based on:  
  - **Crop Name**  
  - **Cultivated Area** (in hectares or other units)  
  - **Season**  
  - **Location**  
  - **Optional Soil Health and Water Quality Tests**  
- The system estimates the **expected investment, return, and yield**.

![image](https://github.com/user-attachments/assets/aa5b4cbd-e2aa-461e-a1e1-58686a7be13d)

## **📍 Google Maps Integration**  
- Farmers can search for **nearby agricultural essentials**:  
  - **Fertilizers**  
  - **Pesticides**  
  - **Farming equipment and supplies**  
- Users can set a **custom range** to filter nearby shops.

![image](https://github.com/user-attachments/assets/8e0b988b-f15e-432d-9949-d63b8ed36b53)

### **🌍 Admin Panel & GIS Integration**  
- **Admin Panel** Features:  
  - **Crop Registrations**: View farmer-submitted data with images & geotagging.  
  - **Crop Loss Reports**: View reported crop diseases and losses with images.  
  - **GIS Integration**: **Google Earth Engine (GEE)** is used for **real-time mapping and analytics** of registered crops & losses.

## **🔧 Technologies Used**  
- **Voice Assistant** (for hands-free user interaction)  
- **AI-based Image Classification** (for crop disease detection)  
- **Geotagging** (for mapping and spatial analysis)  
- **Google Earth Engine (GEE)** (for GIS and remote sensing integration)  
- **Google Maps API** (for location-based suggestions)  
- **Admin Dashboard** (for managing user data and reports)  
- **Multilingual Support** (Available in multiple languages for diverse users)  
- **Text-to-Speech (TTS) and Speech-to-Text (STT)** (Available throughout the application for seamless voice interactions) 

## **📌 How to Use**  
1. **Register Your Crop**: Answer voice-based queries & upload an image.  
2. **Report Crop Loss**: Describe the issue via voice, upload an image & get an AI diagnosis.  
3. **Get Crop Recommendations**: Ask what to grow & receive suggestions based on location, season, and soil conditions.  
4. **Find Government Schemes**: Ask about relevant schemes & receive the top 3 suggestions.  
5. **Calculate ROI**: Provide crop details, area, and other factors to get investment and return estimates.  
6. **Locate Agricultural Shops**: Search for fertilizers, pesticides, or equipment using Google Maps.  
7. **Admin Panel**: Manage all farmer submissions, view reports, and access GIS insights.
