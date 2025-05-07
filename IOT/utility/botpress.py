import requests
import json
import time

def sendMessage(user_input):
    url = "https://chat.botpress.cloud/8f7710f7-6ea8-4e44-a0fb-9b0361685760/messages"

    payload = { "payload": { "type": "text", "text": user_input },
                "conversationId": "ok"}
    headers = {
        "accept": "application/json",
        "x-user-key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Im9rIiwiaWF0IjoxNzM4ODk3NDMwfQ.FLt6Oga2eAl3TMNxtH5HNgMx_wTOoz0VOM9o7iTnE7c",
        "content-type": "application/json"
    }
    response = requests.post(url, json=payload, headers=headers)

def receiveResponse():
    url = "https://chat.botpress.cloud/8f7710f7-6ea8-4e44-a0fb-9b0361685760/conversations/ok/messages"
    headers = {
        "accept": "application/json",
        "x-user-key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Im9rIiwiaWF0IjoxNzM4ODk3NDMwfQ.FLt6Oga2eAl3TMNxtH5HNgMx_wTOoz0VOM9o7iTnE7c"
        }
    response = requests.get(url, headers=headers)
    data = json.loads(response.text)
    # Extract the last message's tex
    last_message_text = data["messages"][0]["payload"]["text"]
    # Print the extracted text
    return last_message_text

def waitForResponse(user_input):
    for _ in range(20):  # Try 10 times
        bot_reply = receiveResponse()
        if bot_reply and bot_reply != user_input:  # Ensure it's a bot response
            return bot_reply
        time.sleep(2)  # Wait 2 seconds before retrying
    return "No response received after waiting."


def recommend_fertilizers(translated_string,n,p,k):
    if n=='Error' or n=='error':
        user_input=translated_string
    else:
        user_input=f'{translated_string}. My soil parameters are : Nitrogen = {n} mg/kg, Phosphorus = {p} mg/kg, Potassium = {k} mg/kg'
    sendMessage(user_input)
    bot_reply = waitForResponse(user_input)
    return bot_reply