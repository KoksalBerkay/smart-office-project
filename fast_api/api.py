import os
import uvicorn
import pandas as pd
from typing import Optional
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import RedirectResponse, JSONResponse
from colorama import init

init()

os.system('clear & xdotool getactivewindow set_window --name Smartoffice\ API')


def create_exception(error_name: str, error_description: str) -> dict:
    return {'error': error_name, 'error_description': error_description}


class RequestPayload(BaseModel):
    uuid: str
    data_type: str
    start_timestamp: Optional[int] = 0
    stop_timestamp: Optional[int] = 0


app = FastAPI()


@app.get('/', include_in_schema=False)
def redirect_to_docs():
    response = RedirectResponse(url="/docs")
    return response


@app.post('/get_data/')
async def get_data(request_payload: RequestPayload) -> JSONResponse:
    _request_payload = dict(request_payload)
    _uuid_list = os.listdir('/home/ikl/Desktop/db_and_api/database/db')

    _start_timestamp = _request_payload['start_timestamp']
    _stop_timestamp = _request_payload['stop_timestamp']

    # print(_start_timestamp, _stop_timestamp)
        
    if not (_request_payload['uuid'] in _uuid_list):
        return JSONResponse(content=create_exception('BAD_UUID', 'Please provide a UUID value that is in use.'), status_code=400)

    if not (_request_payload['data_type'] in ('light', 'temp', 'humidity', 'motion')):
        return JSONResponse(content=create_exception('BAD_DATA_TYPE', 'Please provide a valid data type.'), status_code=400)

    if _start_timestamp and len(str(_start_timestamp)) != 13:
        return JSONResponse(content=create_exception('BAD_START_TIMESTAMP', 'Please provide start_timestamp value in milliseconds.'), status_code=400)

    if _stop_timestamp and len(str(_stop_timestamp)) != 13:
        return JSONResponse(content=create_exception('BAD_STOP_TIMESTAMP', 'Please provide stop_timestamp value in milliseconds.'), status_code=400)

    # table = pq.read_table(f"db/{_request_payload['uuid']}/{_request_payload['data_type']}.parquet")
    data_frame = pd.read_parquet(f"/home/ikl/Desktop/db_and_api/database/db/{_request_payload['uuid']}/{_request_payload['data_type']}.parquet")

    # print(data_frame.columns)

    # print(data_frame)

    if _start_timestamp and _stop_timestamp:
        filtered_columns = [col for col in data_frame.columns if _start_timestamp <= int(col) <= _stop_timestamp]
    elif _start_timestamp or _stop_timestamp:
        if _start_timestamp:
            filtered_columns = [col for col in data_frame.columns if _start_timestamp <= int(col)]
        else:
            filtered_columns = [col for col in data_frame.columns if int(col) <= _stop_timestamp]
    else:
        filtered_columns = [col for col in data_frame.columns]

    # print(filtered_columns, len(filtered_columns))

    result_dict = {}

    for col in filtered_columns:
        column_data = data_frame[col].tolist()
        result_dict[col] = column_data
    
    # print(result_dict)

    return JSONResponse(content=result_dict, status_code=200)



if __name__ == "__main__":
    uvicorn.run(app, host='192.168.1.97', port=8000)
