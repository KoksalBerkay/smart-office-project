import csv
import time

timestamp = str(time.time()).split('.')[0]

def save_to_db(timestamp: str, topic_type: str, value: str, threshold: str, state: str):
    with open('database.csv', 'a', newline='') as new_file:
        csv_writer = csv.writer(new_file)
        data = [timestamp, topic_type, value, threshold, state]
        csv_writer.writerow(data)

save_to_db(timestamp, 'light', '60', '40', 'true')  # -> 1683895752,temp,25.3,26.4,true
