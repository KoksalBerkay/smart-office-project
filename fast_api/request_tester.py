import requests

if __name__ == '__main__':

    UUID = '1c4d9d56-409f-4432-87ca-4ecf4b899210xd'
    
    r = requests.post(url='http://192.168.1.97:8000/get_data/', json={'uuid': UUID, 'data_type': 'light'})
    print(r.text, r.status_code)
