import os
import uvicorn
import pyarrow.parquet as pq
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import RedirectResponse
from colorama import init; init()


os.system('cls & title Smartoffice API')


def create_exception(error_name: str, error_description: str) -> dict:
    return {'error': error_name, 'error_description': error_description}


class RequestPayload(BaseModel):
    uuid: str
    data_type: str
    start_timestamp: str


app = FastAPI()

@app.get("/", include_in_schema=False)
def redirect_to_docs():
    response = RedirectResponse(url="/docs")
    return response

@app.post("/get_data/")
async def get_data(request_payload: RequestPayload) -> dict:
    _request_payload = dict(request_payload)
    _uuid_list = os.listdir('db')

    if not (_request_payload['uuid'] in _uuid_list):
        return create_exception('BAD_UUID', 'Please provide a UUID value that is in use.')
    
    if not (_request_payload['data_type'] in ('light', 'temp', 'humidity', 'motion')):
        return create_exception('BAD_DATA_TYPE', 'Please provide a valid data type.')

    if len(_request_payload['start_timestamp']) != 13:
        return create_exception('BAD_TIMESTAMP', 'Please provide timestamp in milliseconds.')

    table = pq.read_table(f"db/{_request_payload['uuid']}/{_request_payload['data_type']}.parquet")

    # data_frame = table.to_pandas()
    
    # print(data_frame.columns)  

    # print(data_frame)

    filtered_columns = [col for col in table.schema.names if int(col) >= int(_request_payload['start_timestamp'])]

    print(filtered_columns, len(filtered_columns))

    result_dict = {}

    for col in filtered_columns:
        column_data = table[col].to_pandas().tolist()
        result_dict[col] = column_data

    print(result_dict)

    return result_dict


if __name__ == "__main__":
    uvicorn.run(app, port=8000)
