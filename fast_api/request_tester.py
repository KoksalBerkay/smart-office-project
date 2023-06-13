import requests

if __name__ == '__main__':

    UUID = '55c8862c-03e6-4b75-9707-1974a6d17163'
    
    r = requests.post(url='http://127.0.0.1:8000/get_data/', json={'uuid': UUID, 'data_type': 'light', 'start_timestamp': '1686298620788'})
    print(r.text, r.status_code)
