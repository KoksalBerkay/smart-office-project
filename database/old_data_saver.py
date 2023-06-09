import os
import csv
import time
import paho.mqtt.client as mqtt


def calculate_spaces(strng_data: str) -> str:
    max_len = 7
    return (max_len - len(strng_data)) * ' '


def save_to_db(_file_name: str, timestamp: str, value: str, threshold: str, state: str):
    with open('db/' + _file_name + '.csv', 'a', newline='') as new_file:
        csv_writer = csv.writer(new_file)
        data = [timestamp, value, threshold, state]
        csv_writer.writerow(data)


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
        _timestamp = str(time.time()).split('.')[0]
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
