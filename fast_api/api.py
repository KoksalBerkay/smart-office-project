import os
import uvicorn
import pandas as pd
from typing import Optional
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import RedirectResponse
from colorama import init

init()

os.system('cls & title Smartoffice API')


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
async def get_data(request_payload: RequestPayload) -> dict:
    _request_payload = dict(request_payload)
    _uuid_list = os.listdir('db')

    _start_timestamp = _request_payload['start_timestamp']
    _stop_timestamp = _request_payload['stop_timestamp']

    print(_start_timestamp, _stop_timestamp)

    if not (_request_payload['uuid'] in _uuid_list):
        return create_exception('BAD_UUID', 'Please provide a UUID value that is in use.')

    if not (_request_payload['data_type'] in ('light', 'temp', 'humidity', 'motion')):
        return create_exception('BAD_DATA_TYPE', 'Please provide a valid data type.')

    if _start_timestamp and len(str(_start_timestamp)) != 13:
        return create_exception('BAD_START_TIMESTAMP', 'Please provide start_timestamp value in milliseconds.')

    if _stop_timestamp and len(str(_stop_timestamp)) != 13:
        return create_exception('BAD_STOP_TIMESTAMP', 'Please provide stop_timestamp value in milliseconds.')

    # table = pq.read_table(f"db/{_request_payload['uuid']}/{_request_payload['data_type']}.parquet")
    data_frame = pd.read_parquet(f"db/{_request_payload['uuid']}/{_request_payload['data_type']}.parquet")

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

    return result_dict


if __name__ == "__main__":
    uvicorn.run(app, port=8000)
