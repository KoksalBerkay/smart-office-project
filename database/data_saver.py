import csv
import paho.mqtt.client as mqtt


def save_to_db(_file_name: str, timestamp: str, value: str, threshold: str, state: str):
    with open(_file_name + '.csv', 'a', newline='') as new_file:
        csv_writer = csv.writer(new_file)
        data = [timestamp, value, threshold, state]
        csv_writer.writerow(data)



def on_message(client, userdata, message):
    _topic_type = str(message.topic).split('\\')[0]  # ex: temp\5d4ad7f4-1918-4210-942f-2489709c4411
    _uuid = str(message.topic).split('\\')[1]
    message = message.payload.decode('utf-8').split('/')
    _timestamp = message[0]  # ex: 1684060875
    _value = message[1]
    _threshold = message[2]
    _state = message[3]

    save_to_db(_uuid + '_' + _topic_type, _timestamp, _value, _threshold, _state)


client = mqtt.Client()

client.connect("localhost")

client.subscribe("#")

client.on_message = on_message

client.loop_forever()
