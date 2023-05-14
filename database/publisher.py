import time
import random
from uuid import uuid4
import paho.mqtt.publish as publish


def generate_random_data() -> str:
    timestamp = str(time.time()).split('.')[0]
    value = str(random.randint(25, 30))
    threshold = str(random.randint(25, 30))
    state = random.choice(['0', '1'])

    example_data = '/'.join([timestamp, value, threshold, state])

    return example_data


host = "localhost"

if __name__ == '__main__':

    _uuid = str(uuid4())

    for _ in range(20):
        topic_type = random.choice(['temp', 'light'])
        publish.single(topic=f"{topic_type}\\{_uuid}", payload=generate_random_data(), hostname=host)
