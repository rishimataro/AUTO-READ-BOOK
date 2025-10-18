import cv2
import numpy as np
import os


# --- Sắp xếp 4 điểm: top-left, top-right, bottom-right, bottom-left ---
def order_points(pts):
    pts = np.array(pts, dtype="float32")
    s = pts.sum(axis=1)
    diff = np.diff(pts, axis=1)
    rect = np.zeros((4, 2), dtype="float32")
    rect[0] = pts[np.argmin(s)]  # top-left
    rect[2] = pts[np.argmax(s)]  # bottom-right
    rect[1] = pts[np.argmin(diff)]  # top-right
    rect[3] = pts[np.argmax(diff)]  # bottom-left
    return rect


# --- Tính kích thước đầu ra cho warp perspective ---
def find_dest(pts):
    (tl, tr, br, bl) = pts
    widthA = np.linalg.norm(br - bl)
    widthB = np.linalg.norm(tr - tl)
    maxWidth = max(int(widthA), int(widthB))
    heightA = np.linalg.norm(tr - br)
    heightB = np.linalg.norm(tl - bl)
    maxHeight = max(int(heightA), int(heightB))
    dst = np.array(
        [[0, 0], [maxWidth, 0], [maxWidth, maxHeight], [0, maxHeight]], dtype="float32"
    )
    return dst


# --- Bóc tách & hiệu chỉnh tài liệu ---
def document_scan_with_steps(orig: np.ndarray):
    if orig is None:
        raise ValueError("Ảnh input không hợp lệ!")

    # B1: Morphological Close
    kernel = np.ones((5, 5), np.uint8)
    morph = cv2.morphologyEx(orig, cv2.MORPH_CLOSE, kernel, iterations=3)

    # B2: GrabCut
    mask = np.zeros(orig.shape[:2], np.uint8)
    bgdModel = np.zeros((1, 65), np.float64)
    fgdModel = np.zeros((1, 65), np.float64)
    h, w = orig.shape[:2]
    rect = (20, 20, w - 40, h - 40)
    cv2.grabCut(orig, mask, rect, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_RECT)
    mask2 = np.where((mask == 2) | (mask == 0), 0, 1).astype("uint8")
    grab = orig * mask2[:, :, np.newaxis]

    # B3: Edge Detection
    gray = cv2.cvtColor(grab, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (11, 11), 0)
    edges = cv2.Canny(blur, 0, 200)
    kernel2 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    dil = cv2.dilate(edges, kernel2)

    # B4: Tìm contour & góc
    cnts, _ = cv2.findContours(dil, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:5]
    corners = None
    for c in cnts:
        epsilon = 0.02 * cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, epsilon, True)
        if len(approx) == 4:
            corners = approx
            break

    if corners is not None:
        corners = corners.reshape(4, 2)
        ordered = order_points(corners)
        dst = find_dest(ordered)
        M = cv2.getPerspectiveTransform(ordered, dst)
        warped = cv2.warpPerspective(
            orig, M, (int(dst[2][0]), int(dst[2][1])), flags=cv2.INTER_LINEAR
        )
    else:
        warped = orig.copy()

    return warped


# --- Hàm lưu ảnh (tách riêng) ---
def save_image(image, path):
    """
    Lưu ảnh an toàn, có kiểm tra và log.
    """
    # Kiểm tra dữ liệu ảnh hợp lệ
    if image is None or not hasattr(image, "size") or image.size == 0:
        print(f"Không thể lưu {path}: ảnh rỗng hoặc không hợp lệ.")
        return False

    # Đảm bảo thư mục tồn tại
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)

    # Ghi file
    success = cv2.imwrite(path, image)
    if success:
        print(f"Đã lưu: {path}")
    else:
        print(f"Lỗi khi lưu ảnh: {path}")
    return success


# --- Quét và tách đôi 2 trang, trả về 2 ảnh trái và phải ---
def document_scan(orig):
    warped = document_scan_with_steps(orig)
    h, w = warped.shape[:2]
    mid_idx = w // 2
    left_page = warped[:, :mid_idx]
    right_page = warped[:, mid_idx:]
    return left_page, right_page


def test_document_scan(input_path: str, output_dir: str = "./output_test"):
    """
    Hàm test cho document_scan() và save_image().
    - input_path: đường dẫn ảnh đầu vào
    - output_dir: thư mục để lưu kết quả
    """

    # Kiểm tra ảnh đầu vào
    if not os.path.exists(input_path):
        print(f"Không tìm thấy ảnh đầu vào: {input_path}")
        return

    print(f"Đang đọc ảnh: {input_path}")
    orig = cv2.imread(input_path)
    if orig is None:
        print("Không thể đọc ảnh (cv2.imread trả về None).")
        return

    # Xử lý ảnh
    print("Đang xử lý và cắt đôi trang...")
    left_page, right_page = document_scan(orig)

    # Đảm bảo thư mục tồn tại
    os.makedirs(output_dir, exist_ok=True)

    # Tạo tên file
    left_path = os.path.join(output_dir, "page_left.jpg")
    right_path = os.path.join(output_dir, "page_right.jpg")

    # Lưu ảnh bằng hàm save_image
    print("Đang lưu ảnh kết quả...")
    save_image(left_page, left_path)
    save_image(right_page, right_path)

    print("Hoàn thành! Hai ảnh được lưu tại:")
    print(f"   ├─ {left_path}")
    print(f"   └─ {right_path}")
