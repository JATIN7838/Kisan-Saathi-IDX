import serial
import time
import pandas as pd
import geocoder


def is_sensor_connected():
    try:
        ser = serial.Serial(
            port='/dev/ttyUSB0',
            baudrate=9600,
            bytesize=8,
            parity=serial.PARITY_NONE,
            stopbits=1,
            timeout=1
        )
        ser.close()
        return True
    except serial.SerialException:
        return False


def calculate_crc(data):
    crc = 0xFFFF
    for pos in data:
        crc ^= pos
        for _ in range(8):
            if crc & 1:
                crc >>= 1
                crc ^= 0xA001
            else:
                crc >>= 1
    return crc.to_bytes(2, byteorder='little')


def read_registers(start_address, num_registers):
    try:
        ser = serial.Serial(
            port='/dev/ttyUSB0',
            baudrate=9600,
            bytesize=8,
            parity=serial.PARITY_NONE,
            stopbits=1,
            timeout=1
        )
        query = bytearray([0x01, 0x03, (start_address >> 8) & 0xFF, start_address & 0xFF,
                           (num_registers >> 8) & 0xFF, num_registers & 0xFF])
        query += calculate_crc(query)
        ser.write(query)
        time.sleep(0.1)
        response = ser.read(5 + 2 * num_registers)
        ser.close()
        return response
    except serial.SerialException:
        return []


def fetch_sensor_values():
    parameters = {
        "pH": {"address": 0x0006, "scale": 0.01},
        "Moist(%)": {"address": 0x0012, "scale": 0.1},
        "Temp °C": {"address": 0x0013, "scale": 0.1},
        "Conduct(µS/cm)": {"address": 0x0015, "scale": 1},
        "N(mg/kg)": {"address": 0x001E, "scale": 1},
        "P(mg/kg)": {"address": 0x001F, "scale": 1},
        "K(mg/kg)": {"address": 0x0020, "scale": 1}
    }

    results = {}
    for param, details in parameters.items():
        response = read_registers(details["address"], 1)
        if len(response) > 5 and response[1] == 0x03:
            value = (response[3] << 8) | response[4]
            scaled_value = value * details["scale"]
            results[param] = f"{scaled_value:.2f}"
        else:
            results[param] = "Error"
    return results
