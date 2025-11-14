import os

# ✅ Fix for Hugging Face Spaces Streamlit permission issue
os.environ["STREAMLIT_CONFIG_DIR"] = "/tmp/.streamlit"
os.makedirs("/tmp/.streamlit", exist_ok=True)

import cv2
import pandas as pd
import datetime
from ultralytics import YOLO
import streamlit as st
import tempfile

# --- Streamlit UI ---
st.set_page_config(page_title="AI Headcount Tracker", layout="wide")
st.title("🎥 AI Headcount Tracker (Free Version)")
st.markdown("Detect and count people in real time using your webcam or video file. "
            "No cloud costs — runs locally using YOLOv8 Nano.")

# User-tweakable thresholds
CONF_THRESHOLD = st.sidebar.slider("Detection confidence threshold", 0.0, 1.0, 0.45, 0.01)
MIN_AREA = st.sidebar.slider("Minimum bbox area to count (px^2)", 1000, 50000, 8000, 500)


# --- Load YOLOv8 Nano model (lightweight and free) ---
@st.cache_resource
def load_model():
    return YOLO("yolov8n.pt")

model = load_model()

# --- Create data folder if missing ---
os.makedirs("data", exist_ok=True)
log_path = "data/attendance_log.csv"

if not os.path.exists(log_path):
    pd.DataFrame(columns=["timestamp", "headcount"]).to_csv(log_path, index=False)

# --- Stream video feed ---
start = st.button("▶️ Start Tracking")
stop_placeholder = st.empty()
frame_placeholder = st.empty()
count_placeholder = st.empty()

if start:
    # You can use a webcam (0) or replace with a video file
    #camera = cv2.VideoCapture("people3.mov")
    camera = cv2.VideoCapture(0)
    if not camera.isOpened():
        st.error("🚫 Could not open camera or video. Please check permissions or path.")
    else:
        stop = stop_placeholder.button("⏹ Stop", key="stop_button_1")

        # Sidebar debug controls (create once, outside the per-frame loop)
        show_debug = st.sidebar.checkbox("Show raw detections (debug)", key="show_raw_detections")
        sidebar_debug_placeholder = st.sidebar.empty()

        while camera.isOpened() and not stop:
            ret, frame = camera.read()
            if not ret:
                st.warning("⚠️ End of video or unable to read from camera.")
                break

            # Run model with an explicit confidence and iou threshold to reduce false positives
            results = model(frame, conf=CONF_THRESHOLD, iou=0.45, verbose=False)

            # # Draw rectangles for detected persons
            # for box in results[0].boxes:
            #     if int(box.cls[0]) == 0:
            #         x1, y1, x2, y2 = map(int, box.xyxy[0])
            #         cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            people = 0
            detections = []

            for box in results[0].boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0]) if hasattr(box, 'conf') else 0.0
                if cls == 0:  # person class
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    area = (x2 - x1) * (y2 - y1)
                    detections.append({"conf": conf, "area": area, "xy": (x1, y1, x2, y2)})
                    # Only count when above both confidence and area thresholds
                    if conf >= CONF_THRESHOLD and area >= MIN_AREA:
                        people += 1
                        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                        cv2.putText(frame, f"{conf:.2f}", (x1, y1 - 6), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,0), 1)

            frame_placeholder.image(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            count_placeholder.metric("👥 Headcount", people)

            # Optional debug: show a small table of detections for tuning thresholds
            if show_debug:
                dbg_df = pd.DataFrame(detections)
                sidebar_debug_placeholder.dataframe(dbg_df)
            else:
                sidebar_debug_placeholder.empty()

            # Log data
            timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            pd.DataFrame([[timestamp, people]], columns=["timestamp", "headcount"]).to_csv(
                log_path, mode="a", header=False, index=False
            )

            # Re-render Stop button each loop iteration
            stop = stop_placeholder.button("⏹ Stop", key=f"stop_button_{datetime.datetime.now().timestamp()}")

        camera.release()
        st.success("✅ Tracking stopped.")

# --- View logs ---
st.subheader("📊 Participation Log")
if os.path.exists(log_path):
    df = pd.read_csv(log_path)
    if not df.empty:
        st.line_chart(df, x="timestamp", y="headcount", width="stretch")
        st.dataframe(df.tail(10))
    else:
        st.info("No logs yet.")
else:
    st.info("No logs yet.")
