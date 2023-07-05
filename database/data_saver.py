import os
import time
import threading
import pandas as pd
import paho.mqtt.client as mqtt

os.system('clear & xdotool getactivewindow set_window --name Smartoffice\ Datasaver')


class TempDatas:
    temp, light, humidity, motion  = 1, 1, 1, 1
    


def calculate_spaces(strng_data: str) -> str:
    max_len = 7
    return (max_len - len(strng_data)) * ' '
    

def calculate_percent(first_number: int, last_number: int) -> float:
    return abs(round((((last_number - first_number) / first_number) * 100), 2))



def save_to_db(_file_name: str, timestamp: str, value: str, threshold: str, state: str):
    file_path = 'db/' + _file_name + '.parquet'

    try:
        # table = pq.read_table(file_path)
        # df = table.to_pandas()

        df = pd.read_parquet(file_path)

        df[timestamp] = [value, threshold, state]

        # table = pa.Table.from_pandas(df)

        # pq.write_table(table, file_path)

        df.to_parquet(file_path)
         
    except FileNotFoundError:
        data = {timestamp: [value, threshold, state]}
        new_frame = pd.DataFrame(data)
        new_frame.to_parquet(file_path)
        

def on_message(client, userdata, message):
    _topic_type = str(message.topic).split('/')[1]  # ex: temp\5d4ad7f4-1918-4210-942f-2489709c4411
    _uuid = str(message.topic).split('/')[2]
    _message = message.payload.decode('utf-8').split('/')
    changed = True
    
    try:
        os.mkdir('db/' + _uuid)
    except FileExistsError:
        changed = False
        
    
    try:
        #  _timestamp = message[0]  # ex: 1684060875
        #  _value = _message[1]
        #  _threshold = _message[2]
        #  _state = _message[3]
        _timestamp = str(int(time.time() * 1000))
        _value = str(round(float(_message[0]), 2))
        _threshold = str(round(float(_message[1]), 2))
        _state = _message[2]
        
        
        if not ('nan' in (_value, _threshold, _state)):
            print(f'Timestamp: {_timestamp} | Value: {_value + calculate_spaces(_value)} | Threshold: {_threshold + calculate_spaces(_threshold)} | State: {_state}')
            
            save_to_db(_uuid + '/' + _topic_type, _timestamp, _value, _threshold, _state)
            
    except ValueError:
        print("Threshold changed! New threshold value: " + message.payload.decode('utf-8'))

if __name__ == '__main__':
    mqtt_client = mqtt.Client()
    
    mqtt_client.username_pw_set('admin', '13p%*0K9mvZ#V')

    mqtt_client.connect('localhost')

    mqtt_client.subscribe('#')

    mqtt_client.on_message = on_message

    mqtt_client.loop_forever()
