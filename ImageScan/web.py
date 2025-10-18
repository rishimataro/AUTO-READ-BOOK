from fastapi import FastAPI, UploadFile, File
from fastapi.responses import StreamingResponse
from handle import document_scan
import cv2
import io
import numpy as np
import zipfile

app = FastAPI()


@app.post("/document_scan")
async def api_document_scan(file: UploadFile = File(...)):
    img_bytes = await file.read()
    np_arr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    left, right = document_scan(img)

    # tạo zip trong bộ nhớ
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w") as zipf:
        _, buf_left = cv2.imencode(".png", left)
        _, buf_right = cv2.imencode(".png", right)
        zipf.writestr("page_left.png", buf_left.tobytes())
        zipf.writestr("page_right.png", buf_right.tobytes())
    zip_buffer.seek(0)

    # trả zip file để tải về
    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={"Content-Disposition": "attachment; filename=pages.zip"},
    )
