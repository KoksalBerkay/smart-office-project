## Usage
- download [mosquitto](https://mosquitto.org/download/)
- go to `C:\Program Files\mosquitto`
- create `test.conf` and paste this code in
    ```conf
    listener 1883
    allow_anonymous true
    ```
- write `.\mosquitto -v -c test.conf` in cmd
- start `data_saver.py`
- run `publisher.py` and look at generated `.csv` files