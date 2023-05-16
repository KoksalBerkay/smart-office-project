import os
import csv
from datetime import datetime, timezone


def get_now() -> str:
	return str(datetime.now()).split(".")[0]
	

def get_base_text(text_type: str) -> str:
	return f'[{text_type}] [{get_now()}] ' 


def print_csv_content(f_name: str) -> None:
	with open(f_name, 'r', newline='') as f:
		csv_reader = csv.reader(f)
		
		for line in csv_reader:
			timestamp = line[0]
			value = line[1]
			threshold = line[2]
			state = 'ACIK' if line[3] == '1' else 'KAPALI'
				
			readable_time = '[' + str(datetime.fromtimestamp(int(timestamp), tz=timezone.utc)).split('+')[0] +  ']'
			print(get_base_text('LOG') + f'|| DEGER TURU: {value_type.capitalize()} | DEGER: {value} | ESIK DEGER: {threshold} | DURUM: {state}')

user_uuid = input(get_base_text('INPUT') + 'Verilerine bakmak istediğiniz kullanıcının UUID değerini yazınız: ').strip().lower()

if not (user_uuid in os.listdir('db')):
	print(get_base_text('ERROR') + 'Veritabanında girilen UUID ile alakalı bir veri bulunamadı. Lütfen geçerli bir UUID değeri ile tekrar deneyin.')
	exit()


view_type = input(get_base_text('INPUT') + 'Tek bir değer görmek için \'s\', Tüm değerleri sıra sıra görmek için \'a\' yazınız: ').strip().lower()

if view_type == 'a':
	for file_name in os.listdir('db/' + user_uuid):
		value_type = file_name.split('.')[0]
		
		folder_name = f'db/{user_uuid}/{file_name}'
		
		print_csv_content(folder_name)

		print('-' * 125)
		
		input(get_base_text('INPUT') + 'Sonraki değer türünü görmek için ENTER tuşuna basınız.')
			
elif view_type == 's':
	value_type = input(f'[INPUT] [{get_now()}] Görmek istediğiniz veri türünü yazınız (humidity, light, motion, temp): ').lower()
	f_name = f'db/{user_uuid}/{value_type}.csv'
	try:
		print_csv_content(f_name)
	except FileNotFoundError:
		print(get_base_text('ERROR') + 'Lütfen geçerli veri türlerinden (humidity, light, motion, temp) birini giriniz.')
else:
	print(get_base_text('ERROR') + 'Lütfen değer olarak \'s\' veya \'a\' yazınız.')
	
