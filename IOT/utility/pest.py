import tkinter as tk
from tkinter import Label, Button
from picamera2 import Picamera2
from PIL import Image, ImageTk
import base64
import requests
import os

class DiseaseIdentificationApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Plant Disease Detection")
        self.root.attributes("-fullscreen", True)

        # Initialize Camera
        self.picam2 = Picamera2()
        self.picam2.configure(self.picam2.create_still_configuration(main={"size": (1920, 1080)}))
        self.picam2.start()

        # Video Frame (Full Screen)
        self.video_label = Label(root)
        self.video_label.pack(expand=True, fill="both")

        # Frame to Hold Buttons (Side-by-Side)
        self.button_frame = tk.Frame(root)
        self.button_frame.place(relx=0.5, rely=0.88, anchor="center")

        # Take Snapshot Button
        self.capture_button = Button(self.button_frame, text="📷 Take Snapshot", font=("Helvetica", 14, "bold"),
                                     bg="green", fg="white", command=self.capture_image)
        self.capture_button.pack(side=tk.LEFT, padx=10, ipadx=10, ipady=5)

        # Close Button
        self.close_button = Button(self.button_frame, text="❌ Close", font=("Helvetica", 14, "bold"),
                                   bg="red", fg="white", command=self.exit_app)
        self.close_button.pack(side=tk.LEFT, padx=10, ipadx=10, ipady=5)

        # Label for showing response
        self.response_label = Label(root, text="", font=("Helvetica", 18), fg="black", wraplength=600, justify="center")
        self.response_label.pack_forget()  # Initially hidden

        # Retake Snapshot Button (Initially Hidden)
        self.retake_button = Button(root, text="🔄 Retake Snapshot", font=("Helvetica", 14, "bold"),
                                    bg="blue", fg="white", command=self.show_camera_view)
        self.retake_button.pack_forget()

        # Start Camera Preview Update
        self.update_preview()

    def update_preview(self):
        """Updates the live camera preview."""
        frame = self.picam2.capture_array()
        frame_resized = Image.fromarray(frame).resize((480, 320))  # Resize for UI
        img = ImageTk.PhotoImage(image=frame_resized)
        self.video_label.imgtk = img
        self.video_label.configure(image=img)
        self.root.after(100, self.update_preview)

    def capture_image(self):
        """Captures an image, hides camera, and identifies disease."""
        image_path = "ss.png"
        self.picam2.capture_file(image_path)

        # Hide Camera and Buttons
        self.video_label.pack_forget()
        self.button_frame.place_forget()

        # Show Processing Message
        self.response_label.config(text="Processing Image...", fg="blue")
        self.response_label.pack(expand=True)
        self.root.update_idletasks() 
        
        # Process Image after Delay
        self.root.after(100, self.identify_disease)

    def identify_disease(self):
        """Encodes the image, sends it to OpenAI API, and displays the response."""
        base64_image = self.encode_image("ss.png")
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer sk-proj-iuclZ2CJ8ffszc1QAxkBT3BlbkFJDFdCsxgIl4WdORCD30zv"
        }
        payload = {
            "model": "gpt-4o-mini",
            "max_tokens": 100,
            "messages": [
                {
                    "role": "system",
                    "content": [
                        {
                            "type": "text",
                            "text": "Your task is to name the plant disease and provide 3 pesticides or herbicides. Keep it short and crisp in 100 tokens. Answer in Hindi language."
                        }
                    ]
                }, {
                    "role": "user",
                    "content": [
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/png;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
        }
        try:
            response = requests.post(
                "https://api.openai.com/v1/chat/completions", headers=headers, json=payload)
            msg_content = response.json().get('choices', [{}])[0].get('message', {}).get('content', 'Unable to process...')
        except Exception as e:
            msg_content = f"Error: {str(e)}"

        # Show Only the Response
        self.response_label.config(text=msg_content, fg="black",padx=30)
        self.response_label.pack(expand=True)

        # Show Retake Button
        self.retake_button.pack(pady=20)

    def show_camera_view(self):
        """Restores camera view and hides response UI."""
        self.response_label.pack_forget()
        self.retake_button.pack_forget()

        self.video_label.pack(expand=True, fill="both")
        self.button_frame.place(relx=0.5, rely=0.88, anchor="center")

    @staticmethod
    def encode_image(image_path):
        """Encodes an image to Base64 format."""
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')

    def exit_app(self):
        """Closes the application and stops the camera."""
        self.picam2.close()
        self.root.destroy()


# Run the Application
if __name__ == "__main__":
    if os.environ.get('DISPLAY', '') == '':
        os.environ.__setitem__('DISPLAY', ':0.0')
    
    root = tk.Tk()
    app = DiseaseIdentificationApp(root)
    root.mainloop()
