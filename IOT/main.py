from datetime import datetime
import tkinter as tk
from tkinter import StringVar, ttk
import os
from utility.npk_logic import fetch_sensor_values, is_sensor_connected
from utility.recommend import recommend_crops
from utility.usb_mic import VoiceRecorder
from utility.botpress import recommend_fertilizers
from utility.fb import FirebaseManager
class SoilAnalysisApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Soil Analysis")
        self.root.attributes("-fullscreen", True)
        self.firebase = FirebaseManager()

        # Variables to store sensor values
        self.param_vars = {
            "pH": StringVar(),
            "Moist(%)": StringVar(),
            "Temp °C": StringVar(),
            "Conduct(µS/cm)": StringVar(),
            "N(mg/kg)": StringVar(),
            "P(mg/kg)": StringVar(),
            "K(mg/kg)": StringVar()
        }

        # Initialize countdown
        self.title = tk.Label(root, text="Starting...", font=("Helvetica", 18, "bold"), anchor="center")
        self.title.pack(pady=(100, 20))
        self.countdown(5)

    def countdown(self, seconds):
        if seconds > 0:
            self.title.config(text=f"Starting in {seconds} seconds...")
            self.root.after(1000, self.countdown, seconds - 1)
        else:
            self.npk_sensor_screen()

    def npk_sensor_screen(self):
        for widget in self.root.winfo_children():
            widget.destroy()
        self.title = tk.Label(self.root, text="Soil Analysis", font=("Helvetica", 18, "bold"), anchor="center")
        self.title.grid(row=0, column=0, columnspan=4, pady=(10, 20))
        left_params = ["pH", "Moist(%)", "Temp °C", "Conduct(µS/cm)"]
        right_params = ["N(mg/kg)", "P(mg/kg)", "K(mg/kg)"]

        for i, param in enumerate(left_params):
            tk.Label(self.root, text=param, font=("Helvetica", 14, "bold"), anchor="w").grid(
                row=i + 1, column=0, padx=3, pady=5, sticky="w"
            )
            tk.Label(self.root, textvariable=self.param_vars[param], font=("Helvetica", 14), anchor="w").grid(
                row=i + 1, column=1, padx=3, pady=5, sticky="w"
            )

        for i, param in enumerate(right_params):
            tk.Label(self.root, text=param, font=("Helvetica", 14, "bold"), anchor="w").grid(
                row=i + 1, column=2, padx=3, pady=5, sticky="w"
            )
            tk.Label(self.root, textvariable=self.param_vars[param], font=("Helvetica", 14), anchor="w").grid(
                row=i + 1, column=3, padx=3, pady=5, sticky="w"
            )

        # Buttons
        button_frame = tk.Frame(self.root)
        button_frame.grid(row=len(left_params) + 1, column=0, columnspan=4, pady=(20, 10))

        recommend_button = tk.Button(button_frame, text="Recommend Crops", font=("Helvetica", 14), bg="blue", fg="white",
                                      command=self.recommend_screen)
        recommend_button.pack(side=tk.LEFT, padx=10)

        fertilizer_button = tk.Button(button_frame, text="Fertilizers", font=("Helvetica", 14), bg="green", fg="white",
                                       command=self.fertilizer_screen)
        fertilizer_button.pack(side=tk.LEFT, padx=10)


        exit_button = tk.Button(button_frame, text="Close", font=("Helvetica", 14), bg="red", fg="white",
                                 command=self.exit_app)
        exit_button.pack(side=tk.LEFT, padx=10)
        self.update_npk_values()

    def update_npk_values(self):
        if is_sensor_connected():
            sensor_values = fetch_sensor_values()
            for param, value in sensor_values.items():
                self.param_vars[param].set(value)
        else:
            for param in self.param_vars.keys():
                self.param_vars[param].set("Error")
        self.root.after(5000, self.update_npk_values)


    def fertilizer_screen(self):
        for widget in self.root.winfo_children():
            widget.destroy()
        title = tk.Label(self.root, text="Record Fertilizer Request", font=("Helvetica", 18, "bold"), anchor="center")
        title.pack(pady=(10, 20))
        recorder = VoiceRecorder()
        is_recording = [False]  # Use a mutable variable to track recording state
        def toggle_recording():
            if not is_recording[0]:
                is_recording[0] = True
                record_button.config(text="Stop Recording", bg="red", state=tk.NORMAL)
                recorder.start_recording()
                self.root.after(20, record_loop)
            else:
                is_recording[0] = False
                recorder.stop_recording()
                record_button.config(state=tk.DISABLED,bg='grey',fg='grey')  # Disable button while translating
                loading_label.config(text="Loading...",fg="blue")
                self.root.after(60, process_translation)

        def record_loop():
            if is_recording[0]:
                try:
                    recorder.record_audio()
                except Exception as e:
                    print(f"Error during recording: {e}")
                self.root.after(20, record_loop)

        def process_translation():
            translated_text = recorder.translate_audio()
            loading_label.config(text="Generating Response...", fg="blue")
            resp=recommend_fertilizers(translated_text,self.param_vars["N(mg/kg)"].get(),self.param_vars["P(mg/kg)"].get(),self.param_vars["K(mg/kg)"].get())
            self.firebase.set_document('IOT','Fertilizer Recommendation',{
                'timestamp':datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'user_query':translated_text+'N:'+self.param_vars["N(mg/kg)"].get()+'P:'+self.param_vars["P(mg/kg)"].get()+'K:'+self.param_vars["K(mg/kg)"].get(),
                'bot_response':resp
            })
            loading_label.config(text="Response:", fg="green")
            result_text.config(state=tk.NORMAL)  # Enable editing
            result_text.delete(1.0, tk.END)  # Clear previous text
            result_text.insert(tk.END, resp)  # Insert new text
            result_text.config(state=tk.DISABLED)  # Disable editing again
            record_button.config(text="Start Recording", bg="green", state=tk.NORMAL)

        button_frame = tk.Frame(self.root)
        button_frame.pack(pady=10)

        back_button = tk.Button(button_frame, text="Back", font=("Helvetica", 14), bg="blue", fg="white",
                                command=self.npk_sensor_screen)
        back_button.pack(side=tk.LEFT, padx=10)

        record_button = tk.Button(button_frame, text="Start Recording", font=("Helvetica", 14), bg="green", fg="white",
                                command=toggle_recording)
        record_button.pack(side=tk.LEFT, padx=10)
        loading_label = tk.Label(self.root, text="", font=("Helvetica", 14), fg="blue")
        loading_label.pack(pady=10)
        result_frame = tk.Frame(self.root)
        result_frame.pack(padx=20, pady=(10, 20), fill=tk.BOTH, expand=True)
        scrollbar = tk.Scrollbar(result_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        result_text = tk.Text(result_frame, font=("Helvetica", 14), wrap=tk.WORD, height=10, width=60, 
                            yscrollcommand=scrollbar.set, padx=10, pady=10)
        result_text.pack(fill=tk.BOTH, expand=True)
        scrollbar.config(command=result_text.yview)
        result_text.config(state=tk.DISABLED)
        def on_touch_scroll(event):
            result_text.yview_scroll(-1 * (event.delta // 120), "units")
        def on_touch_drag(event):
            result_text.yview_scroll(-1 * (event.y - on_touch_drag.start_y) // 2, "units")
            on_touch_drag.start_y = event.y
        def on_touch_start(event):
            on_touch_drag.start_y = event.y
        result_text.bind("<MouseWheel>", on_touch_scroll)  # Windows/Linux scroll
        result_text.bind("<ButtonPress-1>", on_touch_start)  # Touch start
        result_text.bind("<B1-Motion>", on_touch_drag)



    def recommend_screen(self):
        for widget in self.root.winfo_children():
            widget.destroy()

        # Recommend Crops Title
        title = tk.Label(self.root, text="Crop Recommendations", font=("Helvetica", 18, "bold"), anchor="center")
        title.pack(pady=(10, 10))

        # Fetch recommendations
        params = [
            float(self.param_vars["N(mg/kg)"].get() if self.param_vars["N(mg/kg)"].get() != "Error" else 0),
            float(self.param_vars["P(mg/kg)"].get() if self.param_vars["P(mg/kg)"].get() != "Error" else 0),
            float(self.param_vars["K(mg/kg)"].get() if self.param_vars["K(mg/kg)"].get() != "Error" else 0),
            float(self.param_vars["Temp °C"].get() if self.param_vars["Temp °C"].get() != "Error" else 0),
            float(self.param_vars["pH"].get() if self.param_vars["pH"].get() != "Error" else 0)
        ]
        recommendations = recommend_crops(params)

        # Display Recommendations in a Table
        table = ttk.Treeview(self.root, columns=("Crop", "Rainfall", "Gndwater", "GndQuality"), show="headings", height=min(len(recommendations), 8))

        # Set column widths and alignment
        table.column("Crop", anchor="center", width=100)
        table.column("Rainfall", anchor="center", width=100)
        table.column("Gndwater", anchor="center", width=100)
        table.column("GndQuality", anchor="center", width=100)

        table.heading("Crop", text="Crop", anchor="center")
        table.heading("Rainfall", text="Rainfall", anchor="center")
        table.heading("Gndwater", text="Gndwater", anchor="center")
        table.heading("GndQuality", text="GndQuality", anchor="center")

        # Insert rows dynamically
        for crop, details in recommendations.items():
            table.insert("", "end", values=(crop, details["Rainfall"], details["Groundwater"], details["Water Quality"]))

        table.pack(expand=False, fill="x", padx=10, pady=(10, 10))

        # Buttons
        button_frame = tk.Frame(self.root)
        button_frame.pack(pady=(10, 20))

        back_button = tk.Button(button_frame, text="Back to NPK Values", font=("Helvetica", 14), bg="green", fg="white",
                                command=self.npk_sensor_screen)
        back_button.pack(side=tk.LEFT, padx=10)

        exit_button = tk.Button(button_frame, text="Close", font=("Helvetica", 14), bg="red", fg="white",
                                command=self.exit_app)
        exit_button.pack(side=tk.LEFT, padx=10)

    def exit_app(self):
        self.root.destroy()


# Run the Application
if __name__ == "__main__":
    if os.environ.get('DISPLAY', '') == '':
        os.environ.__setitem__('DISPLAY', ':0.0')
    root = tk.Tk()
    app = SoilAnalysisApp(root)
    root.mainloop()
