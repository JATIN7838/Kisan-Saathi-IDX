import tkinter as tk
from tkinter import Label, Button, Text, Scrollbar
from PIL import Image, ImageTk
import cv2
import numpy as np
from picamera2 import Picamera2
from openai import OpenAI
import io
import threading
import os, dotenv, base64

dotenv.load_dotenv()
client = OpenAI(api_key=os.getenv("openAI"))

if os.environ.get('DISPLAY', '') == '':
    os.environ.__setitem__('DISPLAY', ':0.0')

# Global Variables
running = True
current_frame = None
rotate_flag = False
mirror_flag = False
current_colormap_index = 0

# Colormaps
colormaps = [
    cv2.COLORMAP_JET, cv2.COLORMAP_TURBO, cv2.COLORMAP_VIRIDIS,
    cv2.COLORMAP_PLASMA, cv2.COLORMAP_INFERNO, cv2.COLORMAP_HOT,
    cv2.COLORMAP_MAGMA, cv2.COLORMAP_COOL, cv2.COLORMAP_BONE
]
colormap_names = [
    "JET", "TURBO", "VIRIDIS", "PLASMA", "INFERNO", "HOT", "MAGMA", "COOL", "BONE"
]

# Setup Camera
rgb_cam = Picamera2(camera_num=0)  # RGB camera
nir_cam = Picamera2(camera_num=1)  # Near-IR (NoIR) camera

# Configure both cameras
rgb_cam.preview_configuration.main.size = (1920, 1080)
rgb_cam.preview_configuration.main.format = "RGB888"
rgb_cam.configure(rgb_cam.preview_configuration)

nir_cam.preview_configuration.main.size = (1920, 1080)
nir_cam.preview_configuration.main.format = "RGB888"
nir_cam.configure(nir_cam.preview_configuration)

# Start both cameras
rgb_cam.start()
nir_cam.start()

# Main GUI Window
root = tk.Tk()
root.title("Live Monitoring")
root.geometry("480x320")
root.configure(bg="black")
root.attributes("-fullscreen", True)

# ----- Frames -----
main_frame = tk.Frame(root, bg="black")
rgb_frame = tk.Frame(root, bg="black")
ndvi_frame = tk.Frame(root, bg="black")
result_frame = tk.Frame(root, bg="white")

# ----------------- MAIN MENU ----------------- #
def show_main_menu():
    for f in (rgb_frame, ndvi_frame, result_frame):
        f.pack_forget()
    main_frame.pack(fill="both", expand=True)

Label(main_frame, text="Live Monitoring", font=("Arial", 20), bg="black", fg="white").pack(pady=30)

Button(main_frame, text="RGB", font=("Arial", 14), bg="green", fg="white", width=15, height=2,
       command=lambda: switch_to_rgb()).pack(pady=10)

Button(main_frame, text="Near IR", font=("Arial", 14), bg="blue", fg="white", width=15, height=2,
       command=lambda: switch_to_ndvi()).pack(pady=10)

Button(main_frame, text="Close", font=("Arial", 14), bg="red", fg="white", width=15, height=2,
       command=root.destroy).pack(pady=10)

# ----------------- RGB MODE ----------------- #
img_label_rgb = Label(rgb_frame, bg="black")
img_label_rgb.place(x=0, y=0, width=480, height=270)

processing_label = Label(rgb_frame, text="", font=("Arial", 14), fg="white", bg="black")
processing_label.place(x=190, y=280)

def update_rgb():
    global current_frame
    if not running or processing_label.cget("text") == "Processing...":
        return
    frame = rgb_cam.capture_array()
    current_frame = frame.copy()
    resized = cv2.resize(frame, (480, 270))
    image = Image.fromarray(resized)
    photo = ImageTk.PhotoImage(image)
    img_label_rgb.config(image=photo)
    img_label_rgb.image = photo
    img_label_rgb.after(30, update_rgb)

def capture_and_analyze():
    processing_label.config(text="Processing...")
    capture_btn_rgb.place_forget()
    close_btn_rgb.place_forget()

    def worker():
        rgb_image = cv2.cvtColor(current_frame, cv2.COLOR_BGR2RGB)
        buffer = io.BytesIO()
        Image.fromarray(rgb_image).save(buffer, format="JPEG")
        img_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "user", "content": [
                    {"type": "text", "text": "Does this plant show signs of any disease, pest, or water stress? If yes, provide diagnosis and remedy."},
                    {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + img_base64}}
                ]}
            ],
            max_tokens=1000
        )
        diagnosis = response.choices[0].message.content
        result_text.delete("1.0", tk.END)
        result_text.insert(tk.END, diagnosis)
        rgb_frame.pack_forget()
        result_frame.pack(fill="both", expand=True)
        capture_btn_rgb.place(x=90, y=280)
        close_btn_rgb.place(x=300, y=280)
        processing_label.config(text="")

    threading.Thread(target=worker).start()

capture_btn_rgb = Button(rgb_frame, text="Capture", font=("Arial", 14), bg="green", fg="white", command=capture_and_analyze)
capture_btn_rgb.place(x=90, y=280)

close_btn_rgb = Button(rgb_frame, text="⮌", font=("Arial", 14), bg="red", fg="white", command=show_main_menu)
close_btn_rgb.place(x=300, y=280)

# ----------------- RESULT FRAME ----------------- #
result_text = Text(result_frame, wrap=tk.WORD, font=("Arial", 12), bg="white", fg="black")
result_text.place(x=10, y=10, width=460, height=260)
scrollbar = Scrollbar(result_frame, command=result_text.yview)
scrollbar.place(x=470, y=10, height=260)
result_text.config(yscrollcommand=scrollbar.set)
Button(result_frame, text="Go Back", font=("Arial", 14), bg="blue", fg="white", command=show_main_menu).place(x=180, y=280)

# ----------------- NDVI MODE ----------------- #
img_label_ndvi = Label(ndvi_frame, bg="black")
img_label_ndvi.place(x=0, y=0, width=480, height=270)

def contrast_stretch(im):
    in_min, in_max = np.percentile(im, 5), np.percentile(im, 95)
    stretched = np.clip((im - in_min) * 255.0 / (in_max - in_min), 0, 255)
    return stretched.astype(np.uint8)

def calc_ndvi(image):
    b, g, r = cv2.split(image)
    nir = r.astype(float)
    vis = b.astype(float)
    ndvi = (nir - vis) / (nir + vis + 1e-6)
    return np.clip(ndvi, -1.0, 1.0)

def update_ndvi():
    if not running:
        return
    frame = nir_cam.capture_array()
    ndvi = calc_ndvi(frame)
    ndvi_img = contrast_stretch(ndvi)
    color_mapped = cv2.applyColorMap(ndvi_img, colormaps[current_colormap_index])
    resized = cv2.resize(color_mapped, (480, 270))
    if rotate_flag: resized = cv2.rotate(resized, cv2.ROTATE_180)
    if mirror_flag: resized = cv2.flip(resized, 1)
    img = ImageTk.PhotoImage(Image.fromarray(resized))
    img_label_ndvi.config(image=img)
    img_label_ndvi.image = img
    img_label_ndvi.after(100, update_ndvi)

def toggle_rotate():  global rotate_flag; rotate_flag = not rotate_flag
def toggle_mirror():  global mirror_flag; mirror_flag = not mirror_flag
def toggle_colormap():
    global current_colormap_index
    current_colormap_index = (current_colormap_index + 1) % len(colormaps)
    colormap_button.config(text=colormap_names[current_colormap_index])

Button(ndvi_frame, text="⟳", command=toggle_rotate, font=("Arial", 14), bg="blue", fg="white", width=6, height=2).place(x=20, y=280)
colormap_button = Button(ndvi_frame, text=colormap_names[current_colormap_index], command=toggle_colormap,
                         font=("Arial", 14), bg="green", fg="white", width=10, height=2)
colormap_button.place(x=100, y=280)
Button(ndvi_frame, text="Flip", command=toggle_mirror, font=("Arial", 14), bg="blue", fg="white", width=6, height=2).place(x=220, y=280)
Button(ndvi_frame, text="⮌", command=show_main_menu, font=("Arial", 14), bg="red", fg="white", width=6, height=2).place(x=300, y=280)

# ----------------- Navigation Functions ----------------- #
def switch_to_rgb():
    main_frame.pack_forget()
    rgb_frame.pack(fill="both", expand=True)
    update_rgb()

def switch_to_ndvi():
    main_frame.pack_forget()
    ndvi_frame.pack(fill="both", expand=True)
    update_ndvi()

# Start with main screen
show_main_menu()
root.mainloop()
