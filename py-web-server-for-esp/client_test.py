import requests

url = 'http://localhost:5000/'
data = {'bool_value': 'True'}
response = requests.post(url, data=data)
print(response.text)
