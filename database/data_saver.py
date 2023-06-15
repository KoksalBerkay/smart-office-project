import os
import time
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import paho.mqtt.client as mqtt


def calculate_spaces(strng_data: str) -> str:
    max_len = 7
    return (max_len - len(strng_data)) * ' '


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
    _topic_type = str(message.topic).split('\\')[0]  # ex: temp\5d4ad7f4-1918-4210-942f-2489709c4411
    _uuid = str(message.topic).split('\\')[1]
    _message = message.payload.decode('utf-8').split('/')
    
    try:
        os.mkdir('db/' + _uuid)
    except FileExistsError:
        pass
    
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

    mqtt_client.connect('localhost')

    mqtt_client.subscribe('#')

    mqtt_client.on_message = on_message

    mqtt_client.loop_forever()
